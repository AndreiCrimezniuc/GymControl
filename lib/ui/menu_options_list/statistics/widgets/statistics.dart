import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:gymboss/data/repositories/ranking_repository.dart';
import 'package:gymboss/data/repositories/sessions_repository.dart';
import 'package:gymboss/data/repositories/workouts_repository.dart';
import 'package:gymboss/data/services/auth/authenticated_client.dart';
import 'package:gymboss/domain/models/ranking/rank_data.dart';
import 'package:gymboss/domain/models/streak/streak_data.dart';
import 'package:gymboss/domain/models/workouts/workout.dart';
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
  StatsSummary _summary = StatsSummary.empty;
  List<ActivityPoint> _activity = const [];
  String _period = 'all';

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
        _workoutsRepo.statsSummary(period: _period),
        _workoutsRepo.activity(period: _period),
      ]);
      if (!mounted) return;
      setState(() {
        _streak = results[0] as StreakData;
        _ranks = results[1] as UserRanks;
        _workouts = (results[2] as List).length;
        _summary = results[3] as StatsSummary;
        _activity = results[4] as List<ActivityPoint>;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _setPeriod(String period) async {
    if (period == _period) return;
    setState(() => _period = period);
    try {
      final results = await Future.wait([
        _workoutsRepo.statsSummary(period: period),
        _workoutsRepo.activity(period: period),
      ]);
      if (mounted) {
        setState(() {
          _summary = results[0] as StatsSummary;
          _activity = results[1] as List<ActivityPoint>;
        });
      }
    } catch (_) {}
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
                        _MetricsBlock(summary: _summary),
                        const SizedBox(height: 24),
                        const _SectionLabel('Training Load'),
                        const SizedBox(height: 12),
                        _TrainingLoadCard(points: _activity),
                        const SizedBox(height: 24),
                        const _SectionLabel('Workout Calendar'),
                        const SizedBox(height: 12),
                        _ActivityCalendar(points: _activity),
                        const SizedBox(height: 24),
                        const _SectionLabel('Training Trends'),
                        const SizedBox(height: 12),
                        _ActivityChart(points: _activity),
                        const SizedBox(height: 24),
                        _MonthlyChart(
                          summary: _summary,
                          period: _period,
                          onPeriod: _setPeriod,
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

class _TrainingLoadCard extends StatelessWidget {
  final List<ActivityPoint> points;

  const _TrainingLoadCard({required this.points});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final now = DateTime.now();
    final currentStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 27));
    final previousStart = currentStart.subtract(const Duration(days: 28));
    final current = _totals(currentStart, now.add(const Duration(days: 1)));
    final previous = _totals(previousStart, currentStart);
    final change =
        previous.volume <= 0
            ? null
            : ((current.volume - previous.volume) / previous.volume * 100)
                .round();
    final status = switch (change) {
      null => 'Building your baseline',
      > 25 => 'Load increased quickly',
      < -25 => 'Load is trending down',
      _ => 'Load is progressing steadily',
    };
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.border),
        boxShadow: c.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  status,
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (change != null)
                Text(
                  '${change >= 0 ? '+' : ''}$change%',
                  style: TextStyle(
                    color: c.accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Last 28 days compared with the previous 28 days',
            style: TextStyle(color: c.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _LoadMetric(
                label: 'Volume',
                value: _compact(current.volume),
                suffix: 'kg',
              ),
              _LoadMetric(
                label: 'Sessions',
                value: '${current.workouts}',
                suffix: '',
              ),
              _LoadMetric(
                label: 'Time',
                value: (current.seconds / 3600).toStringAsFixed(1),
                suffix: 'h',
              ),
            ],
          ),
        ],
      ),
    );
  }

  ({double volume, int workouts, int seconds}) _totals(
    DateTime start,
    DateTime end,
  ) {
    var volume = 0.0;
    var workouts = 0;
    var seconds = 0;
    for (final point in points) {
      final date = DateTime.tryParse(point.date);
      if (date == null || date.isBefore(start) || !date.isBefore(end)) continue;
      volume += point.volumeKg;
      workouts += point.workouts;
      seconds += point.durationSeconds;
    }
    return (volume: volume, workouts: workouts, seconds: seconds);
  }

  String _compact(double value) =>
      value >= 1000
          ? '${(value / 1000).toStringAsFixed(value >= 10000 ? 0 : 1)}k'
          : value.toStringAsFixed(0);
}

class _LoadMetric extends StatelessWidget {
  final String label;
  final String value;
  final String suffix;

  const _LoadMetric({
    required this.label,
    required this.value,
    required this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: c.textSecondary, fontSize: 10)),
          const SizedBox(height: 3),
          Text.rich(
            TextSpan(
              text: value,
              children: [
                if (suffix.isNotEmpty)
                  TextSpan(
                    text: ' $suffix',
                    style: TextStyle(color: c.textSecondary, fontSize: 10),
                  ),
              ],
            ),
            style: TextStyle(
              color: c.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityCalendar extends StatefulWidget {
  final List<ActivityPoint> points;
  const _ActivityCalendar({required this.points});

  @override
  State<_ActivityCalendar> createState() => _ActivityCalendarState();
}

class _ActivityCalendarState extends State<_ActivityCalendar> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final latest =
        widget.points.isEmpty
            ? DateTime.now()
            : DateTime.tryParse(widget.points.last.date) ?? DateTime.now();
    _month = DateTime(latest.year, latest.month);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final byDate = {for (final point in widget.points) point.date: point};
    final first = DateTime(_month.year, _month.month);
    final days = DateTime(_month.year, _month.month + 1, 0).day;
    final leading = first.weekday - 1;
    final monthNames = const [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size.square(32),
                onPressed:
                    () => setState(() {
                      _month = DateTime(_month.year, _month.month - 1);
                    }),
                child: const Icon(CupertinoIcons.chevron_left, size: 17),
              ),
              Expanded(
                child: Text(
                  '${monthNames[_month.month - 1]} ${_month.year}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: c.textPrimary,
                  ),
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size.square(32),
                onPressed:
                    () => setState(() {
                      _month = DateTime(_month.year, _month.month + 1);
                    }),
                child: const Icon(CupertinoIcons.chevron_right, size: 17),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children:
                const ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                    .map(
                      (day) => Expanded(
                        child: Text(
                          day,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 10),
                        ),
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 5),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 5,
              crossAxisSpacing: 5,
            ),
            itemCount: ((leading + days + 6) ~/ 7) * 7,
            itemBuilder: (_, index) {
              final day = index - leading + 1;
              if (day < 1 || day > days) return const SizedBox.shrink();
              final key =
                  '${_month.year.toString().padLeft(4, '0')}-'
                  '${_month.month.toString().padLeft(2, '0')}-'
                  '${day.toString().padLeft(2, '0')}';
              final point = byDate[key];
              final active = point != null && point.workouts > 0;
              return Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? c.accent : c.iconBg,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: active ? c.accent : c.border),
                ),
                child: Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                    color: active ? c.textOnAccent : c.textSecondary,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ActivityChart extends StatefulWidget {
  final List<ActivityPoint> points;
  const _ActivityChart({required this.points});

  @override
  State<_ActivityChart> createState() => _ActivityChartState();
}

class _ActivityChartState extends State<_ActivityChart> {
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final recent =
        widget.points.length > 16
            ? widget.points.sublist(widget.points.length - 16)
            : widget.points;
    final values = recent.map((point) => point.volumeKg).toList();
    final maxValue =
        values.isEmpty
            ? 1.0
            : values.fold<double>(1, (max, value) => value > max ? value : max);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: c.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  CupertinoIcons.chart_bar_fill,
                  size: 17,
                  color: c.accent,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Working volume',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: c.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 130,
            child:
                values.isEmpty
                    ? Center(
                      child: Text(
                        'Finish a workout to see trends',
                        style: TextStyle(color: c.textSecondary),
                      ),
                    )
                    : Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children:
                          values
                              .map(
                                (value) => Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 2,
                                    ),
                                    child: Container(
                                      height: (value / maxValue * 110).clamp(
                                        4.0,
                                        110.0,
                                      ),
                                      decoration: BoxDecoration(
                                        color: c.accent,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                    ),
          ),
          const SizedBox(height: 8),
          Text(
            'Weight × reps per training day · warmups excluded',
            style: TextStyle(fontSize: 11, color: c.textSecondary),
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
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Record a lift in the Rank screen to start\ntracking your strength progress.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: c.textSecondary, height: 1.5),
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
              ),
            ),
            Text(unit, style: TextStyle(fontSize: 10, color: c.textSecondary)),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(fontSize: 11, color: c.textSecondary)),
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
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Rank ${r.rank}',
                      style: TextStyle(fontSize: 11, color: c.textSecondary),
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

// ── Key metrics ───────────────────────────────────────────────────────────────

class _MetricsBlock extends StatelessWidget {
  final StatsSummary summary;
  const _MetricsBlock({required this.summary});

  static String _fmtDuration(int seconds) {
    if (seconds <= 0) return '—';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Highlights'),
        const SizedBox(height: 12),
        _MetricRow(
          icon: CupertinoIcons.time,
          title: 'Longest workout',
          value: _fmtDuration(summary.longestWorkoutSeconds),
        ),
        _MetricRow(
          icon: CupertinoIcons.heart_fill,
          title: 'Favorite exercise',
          value:
              summary.favoriteExercise.isEmpty ? '—' : summary.favoriteExercise,
        ),
        _MetricRow(
          icon: CupertinoIcons.bolt_fill,
          title: 'Strongest (vs bodyweight)',
          value:
              summary.strongestExercise.isEmpty
                  ? '—'
                  : summary.strongestExercise,
        ),
      ],
    );
  }
}

class _MetricRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  const _MetricRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: c.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(fontSize: 13, color: c.textSecondary),
            ),
          ),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: c.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Workouts per month ────────────────────────────────────────────────────────

class _MonthlyChart extends StatelessWidget {
  final StatsSummary summary;
  final String period;
  final ValueChanged<String> onPeriod;
  const _MonthlyChart({
    required this.summary,
    required this.period,
    required this.onPeriod,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final data = summary.workoutsPerMonth;
    final maxCount = data.fold<int>(1, (m, e) => e.count > m ? e.count : m);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const _SectionLabel('Workouts per month'),
            const Spacer(),
            _PeriodToggle(period: period, onPeriod: onPeriod),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 160,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.border),
          ),
          child:
              data.isEmpty
                  ? Center(
                    child: Text(
                      'No sessions yet',
                      style: TextStyle(color: c.textSecondary),
                    ),
                  )
                  : Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final m in data)
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                '${m.count}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: c.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
                                height: 90 * (m.count / maxCount),
                                decoration: BoxDecoration(
                                  color: c.accent,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                m.month.length >= 7
                                    ? m.month.substring(5)
                                    : m.month,
                                style: TextStyle(
                                  fontSize: 9,
                                  color: c.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
        ),
      ],
    );
  }
}

class _PeriodToggle extends StatelessWidget {
  final String period;
  final ValueChanged<String> onPeriod;
  const _PeriodToggle({required this.period, required this.onPeriod});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget seg(String value, String label) {
      final on = period == value;
      return GestureDetector(
        onTap: () => onPeriod(value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: on ? c.accent : c.iconBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: on ? c.textOnAccent : c.textSecondary,
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        seg('year', 'Year'),
        const SizedBox(width: 6),
        seg('all', 'All'),
      ],
    );
  }
}
