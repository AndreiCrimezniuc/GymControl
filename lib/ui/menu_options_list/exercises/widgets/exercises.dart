import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:gymboss/data/repositories/exercises_repository.dart';
import 'package:gymboss/data/services/auth/authenticated_client.dart';
import 'package:gymboss/domain/models/exercises/exercise_catalog.dart';
import 'package:gymboss/domain/models/insights/training_signal.dart';
import 'package:gymboss/ui/core/theme/app_colors.dart';
import 'package:gymboss/ui/core/theme/theme_controller.dart';
import 'package:gymboss/ui/core/ui/widgets/app_page.dart';
import 'package:gymboss/ui/core/ui/widgets/net_image.dart';
import 'package:gymboss/ui/core/ui/widgets/skeleton.dart';
import 'package:gymboss/ui/core/units/units_controller.dart';
import 'package:gymboss/ui/menu_options_list/exercises/widgets/muscle_illustration.dart';
import 'package:gymboss/l10n/app_localizations.dart';

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
  String _equipment = 'All';
  String _source = 'all';
  String _sort = 'name';
  bool _filtersOpen = false;

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

  Future<void> _load({bool spinner = true, bool forceRefresh = false}) async {
    if (spinner) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final items = await _repo.getCatalog(forceRefresh: forceRefresh);
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

  List<String> get _equipmentFilters {
    final values =
        _all
            .map((exercise) => exercise.equipment)
            .where((equipment) => equipment.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return ['All', ...values];
  }

  List<ExerciseCatalogItem> get _filtered {
    final items = _all.where((e) {
      final mg = _group == 'All' || e.muscleGroup == _group;
      final equipment = _equipment == 'All' || e.equipment == _equipment;
      final custom = e.category.toLowerCase() == 'custom';
      final source =
          _source == 'all' || (_source == 'custom' ? custom : !custom);
      final q = _query.isEmpty || e.matchesSearch(_query);
      return mg && equipment && source && q;
    }).toList();
    switch (_sort) {
      case 'muscle':
        items.sort(
          (a, b) => '${a.muscleGroup}\u0000${a.name}'.compareTo(
            '${b.muscleGroup}\u0000${b.name}',
          ),
        );
      case 'equipment':
        items.sort(
          (a, b) => '${a.equipment}\u0000${a.name}'.compareTo(
            '${b.equipment}\u0000${b.name}',
          ),
        );
      default:
        items.sort((a, b) => a.name.compareTo(b.name));
    }
    return items;
  }

  void _openCreate() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => _CreateExerciseSheet(
        repo: _repo,
        onCreated: (_) => _load(forceRefresh: true),
      ),
    );
  }

  Future<void> _pickSort() async {
    final selected = await showCupertinoModalPopup<String>(
      context: context,
      builder: (sheetContext) => CupertinoActionSheet(
        title: Text(AppLocalizations.of(context).sortExercises),
        actions: [
          for (final option in const [
            ('name', 'Name'),
            ('muscle', 'Muscle group'),
            ('equipment', 'Equipment'),
          ])
            CupertinoActionSheetAction(
              isDefaultAction: _sort == option.$1,
              onPressed: () => Navigator.pop(sheetContext, option.$1),
              child: Text(option.$2),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(sheetContext),
          child: Text(AppLocalizations.of(context).cancel),
        ),
      ),
    );
    if (selected != null && mounted) setState(() => _sort = selected);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppPage(
      title: AppLocalizations.of(context).exercises,
      actions: [
        CupertinoButton(
          padding: EdgeInsets.zero,
          minimumSize: const Size(44, 44),
          onPressed: () => setState(() => _filtersOpen = !_filtersOpen),
          child: Icon(
            CupertinoIcons.slider_horizontal_3,
            size: 22,
            color: _filtersOpen || _equipment != 'All' || _source != 'all'
                ? c.accent
                : c.textSecondary,
          ),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _openCreate,
          child: Icon(CupertinoIcons.add_circled, size: 24, color: c.accent),
        ),
      ],
      body: _loading
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
            placeholder: AppLocalizations.of(
              context,
            ).searchExercises(_all.length),
            backgroundColor: c.card,
            style: TextStyle(color: c.textPrimary),
            placeholderStyle: TextStyle(color: c.textSecondary),
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
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (_filtersOpen) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 36,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: _equipmentFilters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, index) {
                final value = _equipmentFilters[index];
                return _DiscoveryChip(
                  label: value == 'All' ? 'All equipment' : value,
                  selected: value == _equipment,
                  onTap: () => setState(() => _equipment = value),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: CupertinoSlidingSegmentedControl<String>(
                    groupValue: _source,
                    backgroundColor: c.iconBg,
                    thumbColor: c.card,
                    children: {
                      'all': Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(AppLocalizations.of(context).all),
                      ),
                      'catalog': Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(AppLocalizations.of(context).catalog),
                      ),
                      'custom': Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(AppLocalizations.of(context).myExercises),
                      ),
                    },
                    onValueChanged: (value) =>
                        setState(() => _source = value ?? 'all'),
                  ),
                ),
                const SizedBox(width: 10),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: const Size(44, 36),
                  color: c.card,
                  onPressed: _pickSort,
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.arrow_up_arrow_down,
                        size: 15,
                        color: c.textPrimary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Sort',
                        style: TextStyle(color: c.textPrimary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${filtered.length} result${filtered.length == 1 ? '' : 's'}',
              style: TextStyle(color: c.textSecondary, fontSize: 12),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: CustomScrollView(
            slivers: [
              CupertinoSliverRefreshControl(
                onRefresh: () => _load(spinner: false, forceRefresh: true),
              ),
              if (filtered.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      AppLocalizations.of(context).noExercisesFound,
                      style: TextStyle(color: c.textSecondary),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  sliver: SliverList.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) =>
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

class _DiscoveryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DiscoveryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? c.accent : c.card,
          borderRadius: BorderRadius.circular(12),
          border: selected ? null : Border.all(color: c.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? c.textOnAccent : c.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
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
      onTap: () => Navigator.of(context, rootNavigator: true).push(
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
                    style: TextStyle(fontSize: 12, color: c.textSecondary),
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
        child: url.isEmpty
            ? Icon(CupertinoIcons.photo, color: c.textSecondary, size: 20)
            : NetImage(
                url: url,
                fit: BoxFit.cover,
                width: size,
                height: size,
                fallback: (_) => Icon(
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
  List<ExerciseHistorySession> _history = const [];
  bool _loadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final results = await Future.wait([
        widget.repo.getStats(widget.entry.id),
        widget.repo.getHistory(widget.entry.id),
      ]);
      if (mounted) {
        setState(() {
          _stats = results[0] as ExerciseStats;
          _history = results[1] as List<ExerciseHistorySession>;
          _loadingStats = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingStats = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final e = widget.entry;
    return AppPage(
      title: e.name,
      body: ListView(
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
              style: TextStyle(fontSize: 10, color: c.textSecondary),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (e.muscleGroup.isNotEmpty) _Chip(e.muscleGroup, accent: true),
              if (e.equipment.isNotEmpty) _Chip(e.equipment),
              if (e.level.isNotEmpty) _Chip(e.level),
              if (e.force.isNotEmpty) _Chip(e.force),
              if (e.exerciseType.isNotEmpty)
                _Chip(_exerciseTypeLabel(e.exerciseType)),
              for (final muscle in e.secondaryMuscles)
                _Chip('Secondary: $muscle'),
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
              ),
            ),
          ],
          const SizedBox(height: 20),
          _SectionLabel(AppLocalizations.of(context).yourStats),
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
          if (_history.isNotEmpty) ...[
            const SizedBox(height: 22),
            _SectionLabel('Complete History'),
            const SizedBox(height: 10),
            _ExerciseHistory(items: _history),
          ],
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

String _exerciseTypeLabel(String value) => switch (value) {
  'bodyweight_reps' => 'Bodyweight · reps',
  'reps_only' => 'Reps only',
  'duration' => 'Duration',
  'distance_duration' => 'Distance · duration',
  _ => 'Weight · reps',
};

class _StatsBlock extends StatelessWidget {
  final ExerciseStats? stats;
  const _StatsBlock({required this.stats});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final units = context.units;
    final l10n = AppLocalizations.of(context);
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
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: c.accent.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: c.accent.withValues(alpha: 0.25)),
              ),
              child: Icon(
                CupertinoIcons.shield_lefthalf_fill,
                size: 24,
                color: c.accent,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.recordStartsHere,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.recordStartsBody,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: c.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            const _LockedStatsPreview(),
          ],
        ),
      );
    }

    return Column(
      children: [
        _MasteryPanel(stats: s),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = (constraints.maxWidth - 10) / 2;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _MetricCard(
                  width: width,
                  icon: CupertinoIcons.bolt_fill,
                  value: '${units.format(s.estimatedOneRmKg)} ${units.label}',
                  label: l10n.estimatedOneRm,
                  detail: l10n.currentPowerMark,
                ),
                _MetricCard(
                  width: width,
                  icon: CupertinoIcons.arrow_up_right,
                  value: '${units.format(s.maxWeightKg)} ${units.label}',
                  label: l10n.heaviestSet,
                  detail: l10n.sessionsLogged(s.timesPerformed),
                ),
                _MetricCard(
                  width: width,
                  icon: CupertinoIcons.layers_alt_fill,
                  value: '${s.totalSets}',
                  label: l10n.workingSets,
                  detail: l10n.totalReps(s.totalReps),
                ),
                _MetricCard(
                  width: width,
                  icon: CupertinoIcons.chart_bar_alt_fill,
                  value: units.formatVolume(s.maxSetVolumeKg),
                  label: l10n.bestSetVolume,
                  detail: l10n.peakSingleSetWork,
                ),
              ],
            );
          },
        ),
        if (s.records.isNotEmpty) ...[
          const SizedBox(height: 16),
          _SectionLabel(AppLocalizations.of(context).personalRecords),
          const SizedBox(height: 10),
          _RecordsGrid(records: s.records),
        ],
        if (s.progression.length >= 2) ...[
          const SizedBox(height: 16),
          _SectionLabel(AppLocalizations.of(context).signalTrail),
          const SizedBox(height: 10),
          _ProgressionChart(points: s.progression),
        ],
      ],
    );
  }
}

int exerciseMasteryLevel(int totalSets) =>
    1 + math.sqrt(math.max(0, totalSets)).floor();

double exerciseMasteryProgress(int totalSets) {
  final level = exerciseMasteryLevel(totalSets);
  final floor = (level - 1) * (level - 1);
  final ceiling = level * level;
  return ((totalSets - floor) / math.max(1, ceiling - floor)).clamp(0, 1);
}

String _masteryTitle(AppLocalizations l10n, int level) => switch (level) {
  <= 2 => l10n.masteryInitiate,
  <= 5 => l10n.masteryTrained,
  <= 9 => l10n.masteryProven,
  <= 14 => l10n.masteryVeteran,
  _ => l10n.masteryMaster,
};

class _MasteryPanel extends StatelessWidget {
  final ExerciseStats stats;
  const _MasteryPanel({required this.stats});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context);
    final level = exerciseMasteryLevel(stats.totalSets);
    final progress = exerciseMasteryProgress(stats.totalSets);
    final rank = stats.rank;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.invBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.accent.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: c.accent.withValues(alpha: 0.12),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: c.accent.withValues(alpha: 0.65)),
            ),
            child: Text(
              rank ?? '$level',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w900,
                color: c.isDark ? c.textPrimary : c.invText,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rank == null
                      ? l10n.masteryLevel(level)
                      : l10n.rankAndLevel(rank, level),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: c.accentSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _masteryTitle(l10n, level),
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: c.invText,
                  ),
                ),
                const SizedBox(height: 9),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Stack(
                    children: [
                      Container(
                        height: 5,
                        color: c.invText.withValues(alpha: 0.12),
                      ),
                      FractionallySizedBox(
                        widthFactor: progress,
                        child: Container(height: 5, color: c.accent),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  l10n.setsToNextLevel(
                    level * level - stats.totalSets,
                    level + 1,
                  ),
                  style: TextStyle(
                    fontSize: 10,
                    color: c.invText.withValues(alpha: 0.62),
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

class _MetricCard extends StatelessWidget {
  final double width;
  final IconData icon;
  final String value;
  final String label;
  final String detail;

  const _MetricCard({
    required this.width,
    required this.icon,
    required this.value,
    required this.label,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: width,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: c.accent),
          const SizedBox(height: 9),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w800,
              letterSpacing: .7,
              color: c.textSecondary,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10, color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _LockedStatsPreview extends StatelessWidget {
  const _LockedStatsPreview();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: c.iconBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          Icon(CupertinoIcons.lock_fill, size: 14, color: c.textSecondary),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              l10n.lockedStatsPreview,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: .6,
                color: c.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordsGrid extends StatelessWidget {
  final List<ExerciseRecord> records;
  const _RecordsGrid({required this.records});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final units = context.units;
    String label(ExerciseRecord record) => switch (record.type) {
      'weight' => 'Heaviest',
      'reps' => 'Most reps',
      'set_volume' => 'Set volume',
      _ => 'Estimated 1RM',
    };
    String value(ExerciseRecord record) => switch (record.type) {
      'reps' => '${record.reps} reps',
      'set_volume' => units.formatVolume(record.value),
      _ => '${units.format(record.value)} ${units.label}',
    };

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: records
          .map(
            (record) => Container(
              width: (MediaQuery.sizeOf(context).width - 48) / 2,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: c.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(CupertinoIcons.rosette, size: 18, color: c.accent),
                  const SizedBox(height: 7),
                  Text(
                    value(record),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: c.textPrimary,
                    ),
                  ),
                  Text(
                    '${label(record)} · ${record.date}',
                    style: TextStyle(fontSize: 10, color: c.textSecondary),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ExerciseHistory extends StatelessWidget {
  final List<ExerciseHistorySession> items;
  const _ExerciseHistory({required this.items});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final units = context.units;
    return Column(
      children: items
          .map(
            (session) => Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: c.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        session.date,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: c.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      if (session.workoutName.isNotEmpty)
                        Flexible(
                          child: Text(
                            session.workoutName,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: c.textSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...session.sets.asMap().entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '${entry.key + 1}. '
                        '${units.format(entry.value.weightKg)} ${units.label} × '
                        '${entry.value.reps} · ${entry.value.setType}',
                        style: TextStyle(fontSize: 12, color: c.textSecondary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ProgressionChart extends StatefulWidget {
  final List<ExerciseProgressionPoint> points;
  const _ProgressionChart({required this.points});

  @override
  State<_ProgressionChart> createState() => _ProgressionChartState();
}

class _ProgressionChartState extends State<_ProgressionChart> {
  String _metric = 'weight';
  String _period = 'all';

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final now = DateTime.now();
    final days = switch (_period) {
      '1m' => 31,
      '3m' => 93,
      '1y' => 366,
      _ => null,
    };
    final data = widget.points.where((point) {
      if (days == null) return true;
      final date = DateTime.tryParse(point.date);
      return date != null && now.difference(date).inDays <= days;
    }).toList();
    final values = data
        .map(
          (point) => switch (_metric) {
            'volume' => point.volumeKg,
            'reps' => point.topReps.toDouble(),
            _ => point.topWeightKg,
          },
        )
        .toList();
    final insight = SignalTrailInsight.analyze(values);
    final l10n = AppLocalizations.of(context);
    final signalTitle = switch (insight.trend) {
      SignalTrend.baseline => l10n.signalBaseline,
      SignalTrend.rising => l10n.signalRising,
      SignalTrend.stable => l10n.signalStable,
      SignalTrend.easing => l10n.signalEasing,
    };
    final signalBody = insight.plateau
        ? l10n.signalPlateauBody
        : insight.changePercent == null
        ? l10n.signalBaselineBody
        : l10n.signalDelta(insight.changePercent!.round());
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CupertinoSlidingSegmentedControl<String>(
            groupValue: _metric,
            children: {
              'weight': Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Text(AppLocalizations.of(context).labelWeight),
              ),
              'volume': Text(AppLocalizations.of(context).volume),
              'reps': Text(AppLocalizations.of(context).repetitions),
            },
            onValueChanged: (value) =>
                setState(() => _metric = value ?? 'weight'),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 3,
                height: 36,
                decoration: BoxDecoration(
                  color: c.accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      signalTitle,
                      style: TextStyle(
                        color: c.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      signalBody,
                      style: TextStyle(
                        color: c.textSecondary,
                        fontSize: 11,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              if (insight.changePercent != null)
                Text(
                  '${insight.changePercent! >= 0 ? '+' : ''}'
                  '${insight.changePercent!.round()}%',
                  style: TextStyle(
                    color: insight.changePercent! >= 0
                        ? c.accent
                        : c.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 130,
            width: double.infinity,
            child: values.length < 2
                ? Center(
                    child: Text(
                      l10n.notEnoughSignalData,
                      style: TextStyle(color: c.textSecondary),
                    ),
                  )
                : CustomPaint(
                    painter: _SignalTrailPainter(
                      values: values,
                      lineColor: c.accent,
                      gridColor: c.border,
                      fillColor: c.accent.withValues(alpha: 0.18),
                      plateau: insight.plateau,
                    ),
                  ),
          ),
          const SizedBox(height: 10),
          CupertinoSlidingSegmentedControl<String>(
            groupValue: _period,
            children: {
              '1m': const Text('1M'),
              '3m': const Text('3M'),
              '1y': const Text('1Y'),
              'all': Text(AppLocalizations.of(context).all),
            },
            onValueChanged: (value) => setState(() => _period = value ?? 'all'),
          ),
        ],
      ),
    );
  }
}

class _SignalTrailPainter extends CustomPainter {
  final List<double> values;
  final Color lineColor;
  final Color gridColor;
  final Color fillColor;
  final bool plateau;

  const _SignalTrailPainter({
    required this.values,
    required this.lineColor,
    required this.gridColor,
    required this.fillColor,
    required this.plateau,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final range = (maxValue - minValue).abs() < 0.001
        ? 1.0
        : maxValue - minValue;
    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final y =
          size.height -
          6 -
          ((values[i] - minValue) / range * (size.height - 18));
      points.add(Offset(x, y));
    }
    if (plateau) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(size.width * .62, 0, size.width, size.height),
          const Radius.circular(10),
        ),
        Paint()..color = lineColor.withValues(alpha: .06),
      );
    }
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    final area = Path.from(path)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = ui.Gradient.linear(Offset.zero, Offset(0, size.height), [
          fillColor,
          fillColor.withValues(alpha: 0),
        ]),
    );
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, paint);
    canvas.drawCircle(
      points.last,
      9,
      Paint()..color = lineColor.withValues(alpha: .14),
    );
    canvas.drawCircle(points.first, 3, Paint()..color = lineColor);
    canvas.drawCircle(points.last, 4.5, Paint()..color = lineColor);
  }

  @override
  bool shouldRepaint(covariant _SignalTrailPainter oldDelegate) =>
      oldDelegate.values != values ||
      oldDelegate.lineColor != lineColor ||
      oldDelegate.gridColor != gridColor ||
      oldDelegate.fillColor != fillColor ||
      oldDelegate.plateau != plateau;
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
            AppLocalizations.of(context).couldNotLoadExercises,
            style: TextStyle(color: c.textPrimary),
          ),
          const SizedBox(height: 16),
          CupertinoButton(
            onPressed: onRetry,
            child: Text(AppLocalizations.of(context).retry),
          ),
        ],
      ),
    );
  }
}

// ── Create custom exercise sheet ──────────────────────────────────────────────

const _muscleGroups = [
  'Chest',
  'Lats',
  'Upper Back',
  'Lower Back',
  'Front Delts',
  'Side Delts',
  'Rear Delts',
  'Biceps',
  'Triceps',
  'Forearms',
  'Quadriceps',
  'Hamstrings',
  'Glutes',
  'Calves',
  'Abs',
  'Obliques',
  'Other',
];

const _equipmentOptions = [
  'Barbell',
  'Dumbbell',
  'Machine',
  'Cable',
  'Smith Machine',
  'Kettlebell',
  'Resistance Band',
  'Bodyweight',
  'Other',
];

const _exerciseTypes = {
  'weight_reps': 'Weight · reps',
  'bodyweight_reps': 'Bodyweight · reps',
  'reps_only': 'Reps only',
  'duration': 'Duration',
  'distance_duration': 'Distance · duration',
};

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
  final Set<String> _secondary = {};
  String _equipment = 'Barbell';
  String _exerciseType = 'weight_reps';
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
        equipment: _equipment,
        exerciseType: _exerciseType,
        secondaryMuscles: _secondary.toList(),
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
      child: SingleChildScrollView(
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
              AppLocalizations.of(context).newExercise,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _Field(
              controller: _nameCtrl,
              label: AppLocalizations.of(context).name,
              placeholder: 'My Cable Crossover',
            ),
            const SizedBox(height: 12),
            Text(
              'MUSCLE GROUP',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: c.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _muscleGroups.map((g) {
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
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Text(
              'SECONDARY MUSCLES',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: c.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: _muscleGroups.where((group) => group != _group).map((
                group,
              ) {
                final selected = _secondary.contains(group);
                return GestureDetector(
                  onTap: () => setState(() {
                    selected ? _secondary.remove(group) : _secondary.add(group);
                  }),
                  child: _ChoiceChip(label: group, selected: selected),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Text(
              'EQUIPMENT',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: c.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: _equipmentOptions
                  .map(
                    (equipment) => GestureDetector(
                      onTap: () => setState(() => _equipment = equipment),
                      child: _ChoiceChip(
                        label: equipment,
                        selected: equipment == _equipment,
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            Text(
              'TRACKING TYPE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: c.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: _exerciseTypes.entries
                  .map(
                    (entry) => GestureDetector(
                      onTap: () => setState(() => _exerciseType = entry.key),
                      child: _ChoiceChip(
                        label: entry.value,
                        selected: entry.key == _exerciseType,
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            _Field(
              controller: _imageCtrl,
              label: AppLocalizations.of(context).imageUrl,
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
              label: AppLocalizations.of(context).description,
              placeholder: 'How to perform it…',
              maxLines: 3,
            ),
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
                    child: _saving
                        ? const CupertinoActivityIndicator()
                        : Text(
                            'Create',
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
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  const _ChoiceChip({required this.label, required this.selected});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: selected ? c.accent : c.iconBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: selected ? c.textOnAccent : c.textSecondary,
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String placeholder;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  const _Field({
    required this.controller,
    required this.label,
    required this.placeholder,
    this.maxLines = 1,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: c.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        CupertinoTextField(
          controller: controller,
          placeholder: placeholder,
          maxLines: maxLines,
          onChanged: onChanged,
          keyboardType: TextInputType.text,
          style: TextStyle(color: c.textPrimary, fontSize: 15),
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
