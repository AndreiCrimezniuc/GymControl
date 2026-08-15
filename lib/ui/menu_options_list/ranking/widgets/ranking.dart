import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:gymboss/data/repositories/ranking_repository.dart';
import 'package:gymboss/data/services/auth/authenticated_client.dart';
import 'package:gymboss/domain/models/ranking/rank_data.dart';
import 'package:gymboss/ui/core/theme/theme_controller.dart';
import 'package:gymboss/ui/core/ui/widgets/app_page.dart';

// ── Rank tier color / label helpers (tier colours are intentional) ────────────

Color _rankColor(String rank) {
  switch (rank) {
    case 'SS':
      return const Color(0xFF7C3AED);
    case 'S':
      return const Color(0xFFEAB308);
    case 'A':
      return const Color(0xFFEF4444);
    case 'B':
      return const Color(0xFFF97316);
    case 'C':
      return const Color(0xFF22C55E);
    case 'D':
      return const Color(0xFF3B82F6);
    default:
      return const Color(0xFF9CA3AF);
  }
}

String _rankTitle(String rank) {
  switch (rank) {
    case 'SS':
      return 'Legend';
    case 'S':
      return 'Elite';
    case 'A':
      return 'Expert';
    case 'B':
      return 'Advanced';
    case 'C':
      return 'Intermediate';
    case 'D':
      return 'Beginner';
    default:
      return 'Novice';
  }
}

String _nextRank(String rank) {
  const order = ['E', 'D', 'C', 'B', 'A', 'S', 'SS'];
  final i = order.indexOf(rank);
  return i >= 0 && i < order.length - 1 ? order[i + 1] : 'SS';
}

double _nextThreshold(String rank) {
  switch (rank) {
    case 'E':
      return 30;
    case 'D':
      return 50;
    case 'C':
      return 70;
    case 'B':
      return 85;
    case 'A':
      return 95;
    case 'S':
      return 99;
    default:
      return 100;
  }
}

// ── Rank Screen ───────────────────────────────────────────────────────────────

class Ranking extends StatefulWidget {
  const Ranking({super.key});

  @override
  State<Ranking> createState() => _RankingState();
}

class _RankingState extends State<Ranking> {
  late final RankingRepository _repo;
  UserRanks? _ranks;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repo = RankingRepository(client: context.read<AuthenticatedClient>());
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ranks = await _repo.getUserRanks();
      if (mounted) {
        setState(() {
          _ranks = ranks;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Rank',
      body:
          _loading
              ? const Center(child: CupertinoActivityIndicator())
              : _error != null
              ? _ErrorView(error: _error!, onRetry: _load)
              : _RankContent(ranks: _ranks!, repo: _repo, onRefresh: _load),
    );
  }
}

// ── Main content ─────────────────────────────────────────────────────────────

class _RankContent extends StatelessWidget {
  final UserRanks ranks;
  final RankingRepository repo;
  final VoidCallback onRefresh;

  const _RankContent({
    required this.ranks,
    required this.repo,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
          children: [
            _OverallHero(ranks: ranks),
            const SizedBox(height: 20),
            if (ranks.profile.weightKg == null) ...[
              _WeightNudge(repo: repo, onDone: onRefresh),
              const SizedBox(height: 16),
            ],
            if (ranks.exerciseRanks.isEmpty)
              const _NoLiftsCard()
            else
              ...ranks.exerciseRanks.map(
                (er) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ExerciseCard(er: er),
                ),
              ),
            const SizedBox(height: 8),
            _MotivationalQuote(ranks: ranks),
          ],
        ),
        Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: _RecordLiftButton(repo: repo, onDone: onRefresh),
        ),
      ],
    );
  }
}

// ── Overall hero ──────────────────────────────────────────────────────────────

class _OverallHero extends StatelessWidget {
  final UserRanks ranks;
  const _OverallHero({required this.ranks});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final overall = ranks.overallRank;
    final pct = ranks.overallPct;

    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'YOUR RANK',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: c.textSecondary,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          if (overall == null) ...[
            const _UnlockedBadge(),
          ] else ...[
            _BigRankBadge(rank: overall),
            const SizedBox(height: 12),
            Text(
              '${_rankTitle(overall)} · Top ${(100 - pct!).toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _rankColor(overall),
              ),
            ),
            const SizedBox(height: 16),
            _OverallProgressBar(rank: overall, pct: pct),
          ],
        ],
      ),
    );
  }
}

class _UnlockedBadge extends StatelessWidget {
  const _UnlockedBadge();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: c.border, width: 2),
          ),
          child: Center(
            child: Text(
              '?',
              style: TextStyle(fontSize: 36, color: c.textSecondary),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Record 3+ exercises\nto unlock your rank',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: c.textSecondary, height: 1.5),
        ),
      ],
    );
  }
}

class _BigRankBadge extends StatelessWidget {
  final String rank;
  const _BigRankBadge({required this.rank});

  @override
  Widget build(BuildContext context) {
    final color = _rankColor(rank);
    final isSS = rank == 'SS';
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color, width: 2.5),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 16),
        ],
      ),
      child: Center(
        child:
            isSS
                ? ShaderMask(
                  shaderCallback:
                      (bounds) => const LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFF3B82F6)],
                      ).createShader(bounds),
                  child: Text(
                    rank,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: CupertinoColors.white,
                    ),
                  ),
                )
                : Text(
                  rank,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
      ),
    );
  }
}

class _OverallProgressBar extends StatelessWidget {
  final String rank;
  final double pct;
  const _OverallProgressBar({required this.rank, required this.pct});

  static const _order = ['E', 'D', 'C', 'B', 'A', 'S', 'SS'];
  static const _thresholds = [0.0, 30.0, 50.0, 70.0, 85.0, 95.0, 99.0, 100.0];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fill = (pct / 100).clamp(0.0, 1.0);
    return Column(
      children: [
        LayoutBuilder(
          builder: (_, constraints) {
            final w = constraints.maxWidth;
            return Stack(
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: c.iconBg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: fill,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_rankColor('D'), _rankColor(rank)],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                for (int i = 1; i < _thresholds.length - 1; i++)
                  Positioned(
                    left: w * _thresholds[i] / 100 - 1,
                    child: Container(width: 1.5, height: 8, color: c.card),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children:
              _order
                  .map(
                    (r) => Text(
                      r,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: r == rank ? _rankColor(r) : c.textSecondary,
                      ),
                    ),
                  )
                  .toList(),
        ),
        const SizedBox(height: 4),
        if (rank != 'SS')
          Text(
            '${(_nextThreshold(rank) - pct).toStringAsFixed(1)} points to ${_nextRank(rank)} rank',
            style: TextStyle(fontSize: 11, color: c.textSecondary),
          ),
      ],
    );
  }
}

// ── Exercise card ─────────────────────────────────────────────────────────────

class _ExerciseCard extends StatelessWidget {
  final ExerciseRank er;
  const _ExerciseCard({required this.er});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = _rankColor(er.rank);
    final fill = (er.percentile / 100).clamp(0.0, 1.0);
    final toNext =
        er.rank != 'SS'
            ? '${(_nextThreshold(er.rank) - er.percentile).toStringAsFixed(1)}% to ${_nextRank(er.rank)}'
            : '🏆 Max rank!';

    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _SmallRankBadge(rank: er.rank),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  er.exerciseName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${er.weightKg.toStringAsFixed(1)} kg × ${er.reps}  ·  est. 1RM: ${er.oneRmKg.toStringAsFixed(1)} kg',
                  style: TextStyle(fontSize: 11, color: c.textSecondary),
                ),
                const SizedBox(height: 8),
                _MiniProgressBar(fill: fill, color: color),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Top ${(100 - er.percentile).toStringAsFixed(1)}%',
                      style: TextStyle(fontSize: 10, color: color),
                    ),
                    Text(
                      toNext,
                      style: TextStyle(fontSize: 10, color: c.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallRankBadge extends StatelessWidget {
  final String rank;
  const _SmallRankBadge({required this.rank});

  @override
  Widget build(BuildContext context) {
    final color = _rankColor(rank);
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Center(
        child: Text(
          rank,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _MiniProgressBar extends StatelessWidget {
  final double fill;
  final Color color;
  const _MiniProgressBar({required this.fill, required this.color});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: Stack(
        children: [
          Container(height: 5, color: c.iconBg),
          FractionallySizedBox(
            widthFactor: fill.clamp(0.0, 1.0),
            child: Container(height: 5, color: color),
          ),
        ],
      ),
    );
  }
}

// ── No lifts card ─────────────────────────────────────────────────────────────

class _NoLiftsCard extends StatelessWidget {
  const _NoLiftsCard();

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
          const Text('🏋', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 12),
          Text(
            'No lifts recorded yet',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap the button below to add your first lift\nand discover where you rank globally.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: c.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }
}

// ── Weight nudge ──────────────────────────────────────────────────────────────

class _WeightNudge extends StatelessWidget {
  final RankingRepository repo;
  final VoidCallback onDone;
  const _WeightNudge({required this.repo, required this.onDone});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: () => _showWeightSheet(context, repo: repo, onDone: onDone),
      child: Container(
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.accent, width: 1),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Text('⚖️', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add your weight',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: c.textPrimary,
                    ),
                  ),
                  Text(
                    'Required for accurate strength rankings',
                    style: TextStyle(fontSize: 11, color: c.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(CupertinoIcons.chevron_right, color: c.accent, size: 14),
          ],
        ),
      ),
    );
  }
}

// ── Motivational quote ────────────────────────────────────────────────────────

class _MotivationalQuote extends StatelessWidget {
  final UserRanks ranks;
  const _MotivationalQuote({required this.ranks});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final rank = ranks.overallRank ?? 'E';
    final quotes = {
      'E': 'Every champion was once a beginner. Start now.',
      'D': 'Consistency beats talent. Keep showing up.',
      'C': 'You\'re in the top half. Push harder.',
      'B': 'Advanced territory. You\'re doing great.',
      'A': 'Expert level. The elite tier awaits.',
      'S': 'Elite athlete. One step from legendary.',
      'SS': 'You are legendary. Inspire others.',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        quotes[rank] ?? 'Keep training.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          color: c.textSecondary,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

// ── Record lift button ────────────────────────────────────────────────────────

class _RecordLiftButton extends StatelessWidget {
  final RankingRepository repo;
  final VoidCallback onDone;
  const _RecordLiftButton({required this.repo, required this.onDone});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed:
          () => _showRecordLiftSheet(context, repo: repo, onDone: onDone),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: c.accent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: c.accent.withValues(alpha: 0.35), blurRadius: 12),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.plus_circle_fill,
              color: c.textOnAccent,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'Record Lift',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: c.textOnAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Record lift sheet ─────────────────────────────────────────────────────────

const _kExercises = [
  ('bench_press', 'Bench Press'),
  ('squat', 'Squat'),
  ('deadlift', 'Deadlift'),
  ('overhead_press', 'Overhead Press'),
  ('barbell_row', 'Barbell Row'),
];

void _showRecordLiftSheet(
  BuildContext context, {
  required RankingRepository repo,
  required VoidCallback onDone,
}) {
  showCupertinoModalPopup<void>(
    context: context,
    builder: (_) => _RecordLiftSheet(repo: repo, onDone: onDone),
  );
}

class _RecordLiftSheet extends StatefulWidget {
  final RankingRepository repo;
  final VoidCallback onDone;
  const _RecordLiftSheet({required this.repo, required this.onDone});

  @override
  State<_RecordLiftSheet> createState() => _RecordLiftSheetState();
}

class _RecordLiftSheetState extends State<_RecordLiftSheet> {
  int _exIdx = 0;
  final _weightCtrl = TextEditingController();
  final _repsCtrl = TextEditingController(text: '5');
  bool _saving = false;
  String? _error;

  double get _estOneRM {
    final w = double.tryParse(_weightCtrl.text) ?? 0;
    final r = int.tryParse(_repsCtrl.text) ?? 0;
    if (w <= 0 || r <= 0) return 0;
    return w * (1 + r / 30.0);
  }

  Future<void> _save() async {
    final w = double.tryParse(_weightCtrl.text);
    final r = int.tryParse(_repsCtrl.text);
    if (w == null || r == null || w <= 0 || r <= 0) {
      setState(() => _error = 'Enter valid weight and reps');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repo.recordLift(
        exerciseId: _kExercises[_exIdx].$1,
        weightKg: w,
        reps: r,
      );
      if (mounted) {
        Navigator.pop(context);
        widget.onDone();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final orm = _estOneRM;
    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Record Lift',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          const _SheetLabel('Exercise'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: c.iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: CupertinoPicker(
              itemExtent: 36,
              scrollController: FixedExtentScrollController(
                initialItem: _exIdx,
              ),
              onSelectedItemChanged: (i) => setState(() => _exIdx = i),
              children:
                  _kExercises
                      .map(
                        (e) => Center(
                          child: Text(
                            e.$2,
                            style: TextStyle(
                              color: c.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      )
                      .toList(),
            ).frame(height: 120),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SheetLabel('Weight (kg)'),
                    const SizedBox(height: 6),
                    _SheetField(
                      controller: _weightCtrl,
                      placeholder: '100',
                      isDecimal: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SheetLabel('Reps'),
                    const SizedBox(height: 6),
                    _SheetField(controller: _repsCtrl, placeholder: '5'),
                  ],
                ),
              ),
            ],
          ),
          if (orm > 0) ...[
            const SizedBox(height: 10),
            Text(
              'Est. 1RM: ${orm.toStringAsFixed(1)} kg',
              style: TextStyle(fontSize: 12, color: c.textSecondary),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(fontSize: 12, color: Color(0xFFEF4444)),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _saving ? null : _save,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: _saving ? c.iconBg : c.accent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child:
                      _saving
                          ? const CupertinoActivityIndicator()
                          : Text(
                            'Save PR',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: c.textOnAccent,
                            ),
                          ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetLabel extends StatelessWidget {
  final String text;
  const _SheetLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: context.colors.textSecondary,
      letterSpacing: 0.5,
    ),
  );
}

class _SheetField extends StatefulWidget {
  final TextEditingController controller;
  final String placeholder;
  final bool isDecimal;
  const _SheetField({
    required this.controller,
    required this.placeholder,
    this.isDecimal = false,
  });

  @override
  State<_SheetField> createState() => _SheetFieldState();
}

class _SheetFieldState extends State<_SheetField> {
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return CupertinoTextField(
      controller: widget.controller,
      placeholder: widget.placeholder,
      keyboardType:
          widget.isDecimal
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.number,
      style: TextStyle(color: c.textPrimary, fontSize: 15),
      placeholderStyle: TextStyle(color: c.textSecondary, fontSize: 15),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: c.iconBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.border),
      ),
      onChanged: (_) => setState(() {}),
    );
  }
}

// ── Weight entry sheet (shared by nudge + settings) ───────────────────────────

void _showWeightSheet(
  BuildContext context, {
  required RankingRepository repo,
  required VoidCallback onDone,
  double? initialWeight,
  double? initialHeight,
}) {
  showCupertinoModalPopup<void>(
    context: context,
    builder:
        (_) => _WeightSheet(
          repo: repo,
          onDone: onDone,
          initialWeight: initialWeight,
          initialHeight: initialHeight,
        ),
  );
}

class _WeightSheet extends StatefulWidget {
  final RankingRepository repo;
  final VoidCallback onDone;
  final double? initialWeight;
  final double? initialHeight;
  const _WeightSheet({
    required this.repo,
    required this.onDone,
    this.initialWeight,
    this.initialHeight,
  });

  @override
  State<_WeightSheet> createState() => _WeightSheetState();
}

class _WeightSheetState extends State<_WeightSheet> {
  late final TextEditingController _weightCtrl;
  late final TextEditingController _heightCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _weightCtrl = TextEditingController(
      text:
          widget.initialWeight != null
              ? widget.initialWeight!.toStringAsFixed(1)
              : '',
    );
    _heightCtrl = TextEditingController(
      text:
          widget.initialHeight != null
              ? widget.initialHeight!.toStringAsFixed(0)
              : '',
    );
  }

  Future<void> _save() async {
    final w = double.tryParse(_weightCtrl.text);
    final h = double.tryParse(_heightCtrl.text);
    setState(() => _saving = true);
    try {
      await widget.repo.updateProfile(weightKg: w, heightCm: h);
      if (mounted) {
        Navigator.pop(context);
        widget.onDone();
      }
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Body Metrics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Used to compute your relative strength score.',
            style: TextStyle(fontSize: 12, color: c.textSecondary),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SheetLabel('Weight (kg)'),
                    const SizedBox(height: 6),
                    _SheetField(
                      controller: _weightCtrl,
                      placeholder: '80',
                      isDecimal: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SheetLabel('Height (cm)'),
                    const SizedBox(height: 6),
                    _SheetField(
                      controller: _heightCtrl,
                      placeholder: '175',
                      isDecimal: false,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _saving ? null : _save,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: _saving ? c.iconBg : c.accent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child:
                      _saving
                          ? const CupertinoActivityIndicator()
                          : Text(
                            'Save',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: c.textOnAccent,
                            ),
                          ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 8),
          Text(
            'Could not load rankings',
            style: TextStyle(fontSize: 15, color: c.textPrimary),
          ),
          const SizedBox(height: 16),
          CupertinoButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

extension on Widget {
  Widget frame({double? height}) => SizedBox(height: height, child: this);
}
