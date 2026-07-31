import 'package:flutter/cupertino.dart';
import 'package:gymboss/data/repositories/exercises_repository.dart';
import 'package:gymboss/domain/models/exercises/exercise_catalog.dart';
import 'package:gymboss/ui/core/theme/theme_controller.dart';
import 'package:gymboss/ui/core/ui/widgets/app_page.dart';
import 'package:gymboss/ui/core/ui/widgets/pressable.dart';
import 'package:gymboss/ui/menu_options_list/exercises/exercise_discovery_preferences.dart';
import 'package:gymboss/ui/menu_options_list/exercises/widgets/muscle_illustration.dart';

/// Full-screen catalog picker that pops the chosen [ExerciseCatalogItem].
/// Shared by the workout editor and the in-session runner.
class ExercisePicker extends StatefulWidget {
  final ExercisesRepository repo;
  final Set<int> excludedIds;
  final String? suggestedMuscle;

  const ExercisePicker({
    super.key,
    required this.repo,
    this.excludedIds = const {},
    this.suggestedMuscle,
  });

  @override
  State<ExercisePicker> createState() => _ExercisePickerState();
}

class _ExercisePickerState extends State<ExercisePicker> {
  bool _loading = true;
  List<ExerciseCatalogItem> _all = [];
  String _query = '';
  String? _muscleGroup;
  bool _showFilters = false;
  String? _equipment;
  String _scope = 'all';
  final _preferences = ExerciseDiscoveryPreferences();
  List<int> _recentIds = const [];
  Set<int> _favoriteIds = const {};

  List<String> get _muscleGroups =>
      _all
          .map((exercise) => exercise.muscleGroup)
          .where((group) => group.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

  List<String> get _equipmentOptions =>
      _all
          .map((exercise) => exercise.equipment)
          .where((equipment) => equipment.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        widget.repo.getCatalog(),
        _preferences.recentIds(),
        _preferences.favoriteIds(),
      ]);
      final items = results[0] as List<ExerciseCatalogItem>;
      if (mounted) {
        setState(() {
          _all = items;
          _recentIds = results[1] as List<int>;
          _favoriteIds = results[2] as Set<int>;
          if (widget.suggestedMuscle != null &&
              items.any(
                (exercise) => exercise.muscleGroup == widget.suggestedMuscle,
              )) {
            _muscleGroup = widget.suggestedMuscle;
          }
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final filtered =
        _all
            .where(
              (exercise) =>
                  exercise.matchesSearch(_query) &&
                  !widget.excludedIds.contains(exercise.id) &&
                  (_muscleGroup == null ||
                      exercise.muscleGroup == _muscleGroup) &&
                  (_equipment == null || exercise.equipment == _equipment) &&
                  (_scope != 'recent' || _recentIds.contains(exercise.id)) &&
                  (_scope != 'favorites' || _favoriteIds.contains(exercise.id)),
            )
            .toList();
    if (_scope == 'recent') {
      filtered.sort(
        (a, b) => _recentIds.indexOf(a.id).compareTo(_recentIds.indexOf(b.id)),
      );
    }
    return AppPage(
      title: 'Pick exercise',
      body:
          _loading
              ? const Center(child: CupertinoActivityIndicator())
              : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: CupertinoSearchTextField(
                            placeholder: 'Search ${_all.length} exercises',
                            backgroundColor: c.card,
                            style: TextStyle(
                              color: c.textPrimary,
                              fontFamily: 'Rubik',
                            ),
                            onChanged:
                                (value) => setState(() => _query = value),
                          ),
                        ),
                        const SizedBox(width: 8),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(44, 44),
                          onPressed:
                              () =>
                                  setState(() => _showFilters = !_showFilters),
                          child: Container(
                            height: 36,
                            padding: const EdgeInsets.symmetric(horizontal: 11),
                            decoration: BoxDecoration(
                              color:
                                  _muscleGroup != null || _equipment != null
                                      ? c.accent
                                      : c.card,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color:
                                    _muscleGroup != null || _equipment != null
                                        ? c.accent
                                        : c.border,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  CupertinoIcons.slider_horizontal_3,
                                  size: 16,
                                  color:
                                      _muscleGroup != null || _equipment != null
                                          ? c.textOnAccent
                                          : c.textPrimary,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'Filter',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color:
                                        _muscleGroup != null ||
                                                _equipment != null
                                            ? c.textOnAccent
                                            : c.textPrimary,
                                    fontFamily: 'Rubik',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                    child: Row(
                      children: [
                        _MuscleTag(
                          label: 'All',
                          selected: _scope == 'all',
                          onTap: () => setState(() => _scope = 'all'),
                        ),
                        const SizedBox(width: 7),
                        _MuscleTag(
                          label: 'Recent',
                          selected: _scope == 'recent',
                          onTap: () => setState(() => _scope = 'recent'),
                        ),
                        const SizedBox(width: 7),
                        _MuscleTag(
                          label: 'Favorites',
                          selected: _scope == 'favorites',
                          onTap: () => setState(() => _scope = 'favorites'),
                        ),
                      ],
                    ),
                  ),
                  if (_showFilters)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                          child: Row(
                            children: [
                              _MuscleTag(
                                label: 'All',
                                selected: _muscleGroup == null,
                                onTap:
                                    () => setState(() => _muscleGroup = null),
                              ),
                              for (final group in _muscleGroups) ...[
                                const SizedBox(width: 7),
                                _MuscleTag(
                                  label: group,
                                  selected: _muscleGroup == group,
                                  onTap:
                                      () =>
                                          setState(() => _muscleGroup = group),
                                ),
                              ],
                            ],
                          ),
                        ),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                          child: Row(
                            children: [
                              _MuscleTag(
                                label: 'Any equipment',
                                selected: _equipment == null,
                                onTap: () => setState(() => _equipment = null),
                              ),
                              for (final equipment in _equipmentOptions) ...[
                                const SizedBox(width: 7),
                                _MuscleTag(
                                  label: equipment,
                                  selected: _equipment == equipment,
                                  onTap:
                                      () => setState(
                                        () => _equipment = equipment,
                                      ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Row(
                      children: [
                        Text(
                          '${filtered.length} result${filtered.length == 1 ? '' : 's'}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: c.textSecondary,
                            fontFamily: 'Rubik',
                          ),
                        ),
                        if (_muscleGroup != null || _equipment != null) ...[
                          const Spacer(),
                          Text(
                            [
                              if (_muscleGroup != null) _muscleGroup!,
                              if (_equipment != null) _equipment!,
                            ].join(' · '),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: c.accent,
                              fontFamily: 'Rubik',
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Expanded(
                    child:
                        filtered.isEmpty
                            ? _PickerEmpty(query: _query)
                            : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                              itemCount: filtered.length,
                              separatorBuilder:
                                  (_, __) => const SizedBox(height: 8),
                              itemBuilder: (_, i) {
                                final e = filtered[i];
                                return GestureDetector(
                                  onTap: () => _select(e),
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: c.card,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: c.border),
                                    ),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 44,
                                          height: 44,
                                          child: ExerciseVisual(
                                            name: e.name,
                                            muscleGroup: e.muscleGroup,
                                            equipment: e.equipment,
                                            category: e.category,
                                            imageUrl: e.imageUrl,
                                            imageUrl2: e.imageUrl2,
                                            radius: 10,
                                            figurePadding: 5,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                e.name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  color: c.textPrimary,
                                                  fontFamily: 'Rubik',
                                                ),
                                              ),
                                              Text(
                                                [e.muscleGroup, e.equipment]
                                                    .where(
                                                      (value) =>
                                                          value.isNotEmpty,
                                                    )
                                                    .join(' · '),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: c.textSecondary,
                                                  fontFamily: 'Rubik',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Pressable(
                                          semanticLabel:
                                              _favoriteIds.contains(e.id)
                                                  ? 'Remove ${e.name} from favorites'
                                                  : 'Add ${e.name} to favorites',
                                          onTap: () => _toggleFavorite(e.id),
                                          child: SizedBox(
                                            width: 44,
                                            height: 44,
                                            child: Icon(
                                              _favoriteIds.contains(e.id)
                                                  ? CupertinoIcons.star_fill
                                                  : CupertinoIcons.star,
                                              size: 20,
                                              color:
                                                  _favoriteIds.contains(e.id)
                                                      ? c.accent
                                                      : c.textSecondary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
    );
  }

  Future<void> _select(ExerciseCatalogItem exercise) async {
    await _preferences.recordRecent(exercise.id);
    if (!mounted) return;
    Navigator.of(context).pop(exercise);
  }

  Future<void> _toggleFavorite(int id) async {
    final ids = await _preferences.toggleFavorite(id);
    if (mounted) setState(() => _favoriteIds = ids);
  }
}

class _PickerEmpty extends StatelessWidget {
  final String query;

  const _PickerEmpty({required this.query});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.search, size: 34, color: c.textSecondary),
            const SizedBox(height: 12),
            Text(
              'No exercises found',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: c.textPrimary,
                fontFamily: 'Rubik',
              ),
            ),
            const SizedBox(height: 6),
            Text(
              query.trim().isEmpty
                  ? 'Try another muscle filter.'
                  : 'Try a shorter name or another muscle filter.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
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

class _MuscleTag extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _MuscleTag({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? colors.accent : colors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? colors.accent : colors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? colors.textOnAccent : colors.textPrimary,
            fontFamily: 'Rubik',
          ),
        ),
      ),
    );
  }
}
