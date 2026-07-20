import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:gymboss/data/repositories/exercises_repository.dart';
import 'package:gymboss/data/services/auth/authenticated_client.dart';
import 'package:gymboss/domain/models/exercises/exercise_catalog.dart';
import 'package:gymboss/ui/core/theme/app_colors.dart';
import 'package:gymboss/ui/core/theme/theme_controller.dart';
import 'package:gymboss/ui/core/ui/widgets/app_page.dart';
import 'package:gymboss/ui/core/ui/widgets/net_image.dart';
import 'package:gymboss/ui/core/ui/widgets/pressable.dart';
import 'package:gymboss/ui/core/ui/widgets/skeleton.dart';
import 'package:gymboss/ui/core/units/units_controller.dart';
import 'package:gymboss/ui/menu_options_list/exercises/widgets/muscle_illustration.dart';

class Exercises extends StatefulWidget {
  const Exercises({super.key});

  @override
  State<Exercises> createState() => _ExercisesState();
}

class _ExercisesState extends State<Exercises> {
  late final ExercisesRepository _repo;
  final _searchCtrl = TextEditingController();

  bool _loading = true;
  String? _error;
  List<ExerciseCatalogItem> _all = [];
  String _group = 'All';
  String _query = '';

  @override
  void initState() {
    super.initState();
    _repo = ExercisesRepository(client: context.read<AuthenticatedClient>());
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({bool spinner = true}) async {
    if (spinner) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final items = await _repo.getCatalog();
      if (mounted) {
        setState(() {
          _all = items;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (spinner) _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  List<String> get _groups {
    final s =
        _all
            .map((e) => e.muscleGroup)
            .where((g) => g.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return ['All', ...s];
  }

  List<ExerciseCatalogItem> get _filtered =>
      _all.where((e) {
        final mg = _group == 'All' || e.muscleGroup == _group;
        final q =
            _query.isEmpty ||
            e.name.toLowerCase().contains(_query.toLowerCase());
        return mg && q;
      }).toList();

  void _openCreate() {
    showCupertinoModalPopup<void>(
      context: context,
      builder:
          (_) => _CreateExerciseSheet(repo: _repo, onCreated: (_) => _load()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppPage(
      title: 'Exercises',
      actions: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _openCreate,
          child: Icon(CupertinoIcons.add_circled, size: 24, color: c.accent),
        ),
      ],
      body:
          _loading
              ? const SkeletonList()
              : _error != null
              ? _ErrorView(error: _error!, onRetry: _load)
              : _buildList(c),
    );
  }

  Widget _buildList(AppColors c) {
    final filtered = _filtered;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
          child: CupertinoSearchTextField(
            controller: _searchCtrl,
            placeholder: 'Search ${_all.length} exercises',
            backgroundColor: c.card,
            style: TextStyle(color: c.textPrimary, fontFamily: 'Rubik'),
            placeholderStyle: TextStyle(
              color: c.textSecondary,
              fontFamily: 'Rubik',
            ),
            itemColor: c.textSecondary,
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 36,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: _groups.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final g = _groups[i];
              final active = g == _group;
              return GestureDetector(
                onTap: () => setState(() => _group = g),
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: active ? c.accent : c.card,
                    borderRadius: BorderRadius.circular(12),
                    border: active ? null : Border.all(color: c.border),
                  ),
                  child: Text(
                    g,
                    style: TextStyle(
                      fontSize: 13,
                      color: active ? c.textOnAccent : c.textSecondary,
                      fontFamily: 'Rubik',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: CustomScrollView(
            slivers: [
              CupertinoSliverRefreshControl(
                onRefresh: () => _load(spinner: false),
              ),
              if (filtered.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'No exercises found',
                      style: TextStyle(
                        color: c.textSecondary,
                        fontFamily: 'Rubik',
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  sliver: SliverList.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder:
                        (_, i) =>
                            _ExerciseTile(entry: filtered[i], repo: _repo),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  final ExerciseCatalogItem entry;
  final ExercisesRepository repo;
  const _ExerciseTile({required this.entry, required this.repo});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap:
          () => Navigator.of(context, rootNavigator: true).push(
            CupertinoPageRoute(
              builder: (_) => ExerciseDetailScreen(entry: entry, repo: repo),
            ),
          ),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.border),
          boxShadow: c.cardShadow,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 52,
              height: 52,
              child: ExerciseVisual(
                name: entry.name,
                muscleGroup: entry.muscleGroup,
                equipment: entry.equipment,
                category: entry.category,
                imageUrl: entry.imageUrl,
                imageUrl2: entry.imageUrl2,
                figurePadding: 5,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: c.textPrimary,
                      fontFamily: 'Rubik',
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    [
                      entry.muscleGroup,
                      entry.equipment,
                    ].where((s) => s.isNotEmpty).join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: c.textSecondary,
                      fontFamily: 'Rubik',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(CupertinoIcons.arrow_right, size: 16, color: c.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final String url;
  final double size;
  const _Thumb({required this.url, this.size = 52});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: size,
        height: size,
        color: c.iconBg,
        child:
            url.isEmpty
                ? Icon(CupertinoIcons.photo, color: c.textSecondary, size: 20)
                : NetImage(
                  url: url,
                  fit: BoxFit.cover,
                  width: size,
                  height: size,
                  fallback:
                      (_) => Icon(
                        CupertinoIcons.photo,
                        color: c.textSecondary,
                        size: 20,
                      ),
                ),
      ),
    );
  }
}

// ── Detail ────────────────────────────────────────────────────────────────────

class ExerciseDetailScreen extends StatefulWidget {
  final ExerciseCatalogItem entry;
  final ExercisesRepository repo;
  const ExerciseDetailScreen({
    super.key,
    required this.entry,
    required this.repo,
  });

  @override
  State<ExerciseDetailScreen> createState() => ExerciseDetailScreenState();
}

class ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  ExerciseStats? _stats;
  bool _loadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final s = await widget.repo.getStats(widget.entry.id);
      if (mounted) {
        setState(() {
          _stats = s;
          _loadingStats = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingStats = false);
    }
  }

  void _logSet() {
    showCupertinoModalPopup<void>(
      context: context,
      builder:
          (_) => _LogSetSheet(
            repo: widget.repo,
            exerciseId: widget.entry.id,
            onLogged: _loadStats,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final e = widget.entry;
    return AppPage(
      title: e.name,
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              children: [
                AspectRatio(
                  aspectRatio: 4 / 3,
                  child: ExerciseVisual(
                    name: e.name,
                    muscleGroup: e.muscleGroup,
                    equipment: e.equipment,
                    category: e.category,
                    imageUrl: e.imageUrl,
                    imageUrl2: e.imageUrl2,
                    animate: true,
                    radius: 16,
                    figurePadding: 20,
                  ),
                ),
                if (e.imageUrl.contains('everkinetic')) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Illustration © Everkinetic · CC BY-SA 3.0',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      color: c.textSecondary,
                      fontFamily: 'Rubik',
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (e.muscleGroup.isNotEmpty)
                      _Chip(e.muscleGroup, accent: true),
                    if (e.equipment.isNotEmpty) _Chip(e.equipment),
                    if (e.level.isNotEmpty) _Chip(e.level),
                    if (e.force.isNotEmpty) _Chip(e.force),
                  ],
                ),
                if (e.instructions.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _SectionLabel('How to'),
                  const SizedBox(height: 8),
                  Text(
                    e.instructions,
                    style: TextStyle(
                      fontSize: 13,
                      color: c.textSecondary,
                      height: 1.5,
                      fontFamily: 'Rubik',
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                _SectionLabel('Your Stats'),
                const SizedBox(height: 12),
                if (_loadingStats)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CupertinoActivityIndicator(),
                    ),
                  )
                else
                  _StatsBlock(stats: _stats),
                const SizedBox(height: 12),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
            child: Pressable(
              onTap: _logSet,
              child: Container(
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.accent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.plus, size: 18, color: c.textOnAccent),
                    const SizedBox(width: 8),
                    Text(
                      'LOG A SET',
                      style: TextStyle(
                        fontFamily: 'Rubik',
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color: c.textOnAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsBlock extends StatelessWidget {
  final ExerciseStats? stats;
  const _StatsBlock({required this.stats});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final units = context.units;
    final s = stats;
    if (s == null || !s.hasData) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.border),
        ),
        child: Column(
          children: [
            Icon(CupertinoIcons.chart_bar, size: 28, color: c.textSecondary),
            const SizedBox(height: 10),
            Text(
              'No data yet',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
                fontFamily: 'Rubik',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Log a set below to start tracking\ntimes done, volume and progression.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: c.textSecondary,
                height: 1.5,
                fontFamily: 'Rubik',
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            _StatCard(value: '${s.timesPerformed}', label: 'TIMES DONE'),
            const SizedBox(width: 10),
            _StatCard(value: '${s.totalSets}', label: 'TOTAL SETS'),
            const SizedBox(width: 10),
            _StatCard(value: '${s.totalReps}', label: 'TOTAL REPS'),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _StatCard(
              value: '${units.format(s.maxWeightKg)} ${units.label}',
              label: 'MAX WEIGHT',
            ),
            const SizedBox(width: 10),
            _StatCard(
              value: units.formatVolume(s.maxVolumeKg),
              label: 'MAX VOLUME',
            ),
            const SizedBox(width: 10),
            _StatCard(value: s.rank ?? '—', label: 'RANK'),
          ],
        ),
        const SizedBox(height: 12),
        _LoveBar(score: s.loveScore),
        if (s.progression.length >= 2) ...[
          const SizedBox(height: 16),
          _SectionLabel('Progression'),
          const SizedBox(height: 10),
          _ProgressionChart(points: s.progression),
        ],
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: c.textPrimary,
                fontFamily: 'Rubik',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                letterSpacing: 0.5,
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

class _LoveBar extends StatelessWidget {
  final int score; // 0..10
  const _LoveBar({required this.score});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          Icon(CupertinoIcons.heart_fill, size: 18, color: c.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Love coefficient  ·  $score/10',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
                    fontFamily: 'Rubik',
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: Stack(
                    children: [
                      Container(height: 6, color: c.iconBg),
                      FractionallySizedBox(
                        widthFactor: (score / 10).clamp(0.0, 1.0),
                        child: Container(height: 6, color: c.accent),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressionChart extends StatelessWidget {
  final List<ExerciseProgressionPoint> points;
  const _ProgressionChart({required this.points});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final data =
        points.length > 12 ? points.sublist(points.length - 12) : points;
    final maxW = data
        .map((e) => e.topWeightKg)
        .fold<double>(1, (a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: SizedBox(
        height: 90,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children:
              data.map((p) {
                final h = (p.topWeightKg / maxW * 70).clamp(4.0, 70.0);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          p.topWeightKg.toStringAsFixed(0),
                          style: TextStyle(
                            fontSize: 8,
                            color: c.textSecondary,
                            fontFamily: 'Rubik',
                          ),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          height: h,
                          decoration: BoxDecoration(
                            color: c.accent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  final bool accent;
  const _Chip(this.text, {this.accent = false});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: accent ? c.accent : c.iconBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: accent ? c.textOnAccent : c.textSecondary,
          fontFamily: 'Rubik',
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      fontFamily: 'Rubik',
      color: context.colors.textPrimary,
    ),
  );
}

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
          const Text('⚠️', style: TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
          Text(
            'Could not load exercises',
            style: TextStyle(color: c.textPrimary, fontFamily: 'Rubik'),
          ),
          const SizedBox(height: 16),
          CupertinoButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

// ── Log set sheet ─────────────────────────────────────────────────────────────

class _LogSetSheet extends StatefulWidget {
  final ExercisesRepository repo;
  final int exerciseId;
  final VoidCallback onLogged;
  const _LogSetSheet({
    required this.repo,
    required this.exerciseId,
    required this.onLogged,
  });

  @override
  State<_LogSetSheet> createState() => _LogSetSheetState();
}

class _LogSetSheetState extends State<_LogSetSheet> {
  final _weightCtrl = TextEditingController();
  final _repsCtrl = TextEditingController(text: '10');
  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    final units = context.unitsController;
    final w = double.tryParse(_weightCtrl.text) ?? 0;
    final r = int.tryParse(_repsCtrl.text) ?? 0;
    if (r <= 0) {
      setState(() => _error = 'Enter reps');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repo.logSet(
        widget.exerciseId,
        weightKg: units.toKg(w),
        reps: r,
      );
      if (mounted) {
        Navigator.pop(context);
        widget.onLogged();
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
            'Log a set',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
              fontFamily: 'Rubik',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _Field(
                  controller: _weightCtrl,
                  label: 'Weight (${context.units.label})',
                  placeholder: '60',
                  decimal: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Field(
                  controller: _repsCtrl,
                  label: 'Reps',
                  placeholder: '10',
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFEF4444),
                fontFamily: 'Rubik',
              ),
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
                            'Save',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: c.textOnAccent,
                              fontFamily: 'Rubik',
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

// ── Create custom exercise sheet ──────────────────────────────────────────────

const _muscleGroups = [
  'Chest',
  'Back',
  'Legs',
  'Shoulders',
  'Arms',
  'Core',
  'Other',
];

class _CreateExerciseSheet extends StatefulWidget {
  final ExercisesRepository repo;
  final void Function(ExerciseCatalogItem) onCreated;
  const _CreateExerciseSheet({required this.repo, required this.onCreated});

  @override
  State<_CreateExerciseSheet> createState() => _CreateExerciseSheetState();
}

class _CreateExerciseSheetState extends State<_CreateExerciseSheet> {
  final _nameCtrl = TextEditingController();
  final _imageCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _group = 'Chest';
  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Enter a name');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final item = await widget.repo.createCustom(
        name: name,
        description: _descCtrl.text.trim(),
        imageUrl: _imageCtrl.text.trim(),
        muscleGroup: _group,
      );
      if (mounted) {
        Navigator.pop(context);
        widget.onCreated(item);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final img = _imageCtrl.text.trim();
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
            'New exercise',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
              fontFamily: 'Rubik',
            ),
          ),
          const SizedBox(height: 16),
          _Field(
            controller: _nameCtrl,
            label: 'Name',
            placeholder: 'My Cable Crossover',
          ),
          const SizedBox(height: 12),
          Text(
            'MUSCLE GROUP',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: c.textSecondary,
              fontFamily: 'Rubik',
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                _muscleGroups.map((g) {
                  final active = g == _group;
                  return GestureDetector(
                    onTap: () => setState(() => _group = g),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: active ? c.accent : c.iconBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        g,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: active ? c.textOnAccent : c.textSecondary,
                          fontFamily: 'Rubik',
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
          const SizedBox(height: 12),
          _Field(
            controller: _imageCtrl,
            label: 'Image URL',
            placeholder: 'https://…/photo.jpg',
            onChanged: (_) => setState(() {}),
          ),
          if (img.isNotEmpty) ...[
            const SizedBox(height: 10),
            Center(child: _Thumb(url: img, size: 90)),
          ],
          const SizedBox(height: 12),
          _Field(
            controller: _descCtrl,
            label: 'Description',
            placeholder: 'How to perform it…',
            maxLines: 3,
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFEF4444),
                fontFamily: 'Rubik',
              ),
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
                            'Create',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: c.textOnAccent,
                              fontFamily: 'Rubik',
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

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String placeholder;
  final bool decimal;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  const _Field({
    required this.controller,
    required this.label,
    required this.placeholder,
    this.decimal = false,
    this.maxLines = 1,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final numeric = label.contains('kg') || label == 'Reps' || decimal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: c.textSecondary,
            fontFamily: 'Rubik',
          ),
        ),
        const SizedBox(height: 6),
        CupertinoTextField(
          controller: controller,
          placeholder: placeholder,
          maxLines: maxLines,
          onChanged: onChanged,
          keyboardType:
              numeric
                  ? TextInputType.numberWithOptions(decimal: decimal)
                  : TextInputType.text,
          style: TextStyle(
            color: c.textPrimary,
            fontSize: 15,
            fontFamily: 'Rubik',
          ),
          placeholderStyle: TextStyle(color: c.textSecondary, fontSize: 15),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: c.iconBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: c.border),
          ),
        ),
      ],
    );
  }
}
