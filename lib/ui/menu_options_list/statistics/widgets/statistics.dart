import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:gymboss/data/repositories/ranking_repository.dart';
import 'package:gymboss/data/repositories/sessions_repository.dart';
import 'package:gymboss/data/repositories/workouts_repository.dart';
import 'package:gymboss/data/services/auth/authenticated_client.dart';
import 'package:gymboss/domain/models/ranking/rank_data.dart';
import 'package:gymboss/domain/models/streak/streak_data.dart';
import 'package:gymboss/ui/core/theme/theme_controller.dart';
import 'package:gymboss/ui/core/ui/widgets/app_page.dart';
import 'package:gymboss/ui/core/ui/widgets/skeleton.dart';

class Statistics extends StatefulWidget {
  const Statistics({super.key});

  @override
  State<Statistics> createState() => _StatisticsState();
}

class _StatisticsState extends State<Statistics> {
  late final SessionsRepository _sessions;
  late final RankingRepository _ranking;
  late final WorkoutsRepository _workoutsRepo;

  bool _loading = true;
  StreakData _streak = StreakData.empty;
  UserRanks _ranks = UserRanks.empty;
  int _workouts = 0;

  @override
  void initState() {
    super.initState();
    final client = context.read<AuthenticatedClient>();
    _sessions = SessionsRepository(client: client);
    _ranking = RankingRepository(client: client);
    _workoutsRepo = WorkoutsRepository(client: client);
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _sessions.getStreakData(),
        _ranking.getUserRanks(),
        _workoutsRepo.listOwned(),
      ]);
      if (!mounted) return;
      setState(() {
        _streak = results[0] as StreakData;
        _ranks = results[1] as UserRanks;
        _workouts = (results[2] as List).length;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ranks = _ranks.exerciseRanks;
    return AppPage(
      title: 'Statistics',
      body:
          _loading
              ? const SkeletonList()
              : CustomScrollView(
                slivers: [
                  CupertinoSliverRefreshControl(onRefresh: _load),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        Row(
                          children: [
                            _StatTile(
                              value: '${_streak.currentStreakWeeks}',
                              unit:
                                  _streak.currentStreakWeeks == 1
                                      ? 'week'
                                      : 'weeks',
                              title: 'Streak',
                              icon: CupertinoIcons.flame_fill,
                            ),
                            const SizedBox(width: 10),
                            _StatTile(
                              value: '$_workouts',
                              unit: 'routines',
                              title: 'Workouts',
                              icon: CupertinoIcons.calendar,
                            ),
                            const SizedBox(width: 10),
                            _StatTile(
                              value: '${ranks.length}',
                              unit: 'lifts',
                              title: 'Ranked',
                              icon: CupertinoIcons.chart_bar_fill,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        if (ranks.isEmpty)
                          const _EmptyState()
                        else ...[
                          const _SectionLabel('Estimated 1RM'),
                          const SizedBox(height: 12),
                          _OneRmChart(ranks: ranks),
                          const SizedBox(height: 24),
                          const _SectionLabel('Personal Records'),
                          const SizedBox(height: 12),
                          _RecordsList(ranks: ranks),
                        ],
                        const SizedBox(height: 16),
                      ]),
                    ),
                  ),
                ],
              ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text('📊', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 12),
          Text(
            'No stats yet',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
              fontFamily: 'Rubik',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Record a lift in the Rank screen to start\ntracking your strength progress.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: c.textSecondary,
              fontFamily: 'Rubik',
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        fontFamily: 'Rubik',
        color: context.colors.textPrimary,
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String unit;
  final String title;
  final IconData icon;

  const _StatTile({
    required this.value,
    required this.unit,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: c.accent, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
                fontFamily: 'Rubik',
              ),
            ),
            Text(
              unit,
              style: TextStyle(
                fontSize: 10,
                color: c.textSecondary,
                fontFamily: 'Rubik',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                color: c.textSecondary,
                fontFamily: 'Rubik',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OneRmChart extends StatelessWidget {
  final List<ExerciseRank> ranks;
  const _OneRmChart({required this.ranks});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final maxOrm = ranks
        .map((e) => e.oneRmKg)
        .fold<double>(1, (a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 110,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children:
                  ranks.map((r) {
                    final barH = (r.oneRmKg / maxOrm * 80).clamp(6.0, 80.0);
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              r.oneRmKg.toStringAsFixed(0),
                              style: TextStyle(
                                fontSize: 9,
                                color: c.textSecondary,
                                fontFamily: 'Rubik',
                              ),
                            ),
                            const SizedBox(height: 3),
                            Container(
                              height: barH,
                              decoration: BoxDecoration(
                                color: c.accent,
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children:
                ranks
                    .map(
                      (r) => Expanded(
                        child: Center(
                          child: Text(
                            _short(r.exerciseName),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 9,
                              color: c.textSecondary,
                              fontFamily: 'Rubik',
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
          ),
        ],
      ),
    );
  }

  static String _short(String name) {
    final parts = name.split(' ');
    if (parts.length == 1) return parts.first;
    return parts.map((p) => p.isEmpty ? '' : p[0]).join().toUpperCase();
  }
}

class _RecordsList extends StatelessWidget {
  final List<ExerciseRank> ranks;
  const _RecordsList({required this.ranks});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: ranks.length,
        separatorBuilder:
            (_, __) => Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              color: c.border,
            ),
        itemBuilder: (_, i) {
          final r = ranks[i];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(CupertinoIcons.star_fill, size: 16, color: c.accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    r.exerciseName,
                    style: TextStyle(
                      fontSize: 14,
                      color: c.textPrimary,
                      fontFamily: 'Rubik',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${r.weightKg.toStringAsFixed(0)} kg × ${r.reps}',
                      style: TextStyle(
                        fontSize: 14,
                        color: c.textPrimary,
                        fontFamily: 'Rubik',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Rank ${r.rank}',
                      style: TextStyle(
                        fontSize: 11,
                        color: c.textSecondary,
                        fontFamily: 'Rubik',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
