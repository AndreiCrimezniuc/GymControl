import 'package:flutter/cupertino.dart';
import 'package:gymboss/data/repositories/exercises_repository.dart';
import 'package:gymboss/domain/models/exercises/exercise_catalog.dart';
import 'package:gymboss/ui/core/theme/theme_controller.dart';
import 'package:gymboss/ui/core/ui/widgets/app_page.dart';
import 'package:gymboss/ui/menu_options_list/exercises/widgets/muscle_illustration.dart';

/// Full-screen catalog picker that pops the chosen [ExerciseCatalogItem].
/// Shared by the workout editor and the in-session runner.
class ExercisePicker extends StatefulWidget {
  final ExercisesRepository repo;
  const ExercisePicker({super.key, required this.repo});

  @override
  State<ExercisePicker> createState() => _ExercisePickerState();
}

class _ExercisePickerState extends State<ExercisePicker> {
  bool _loading = true;
  List<ExerciseCatalogItem> _all = [];
  String _query = '';
  String? _muscleGroup;
  bool _showFilters = false;

  List<String> get _muscleGroups =>
      _all
          .map((exercise) => exercise.muscleGroup)
          .where((group) => group.isNotEmpty)
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
      final items = await widget.repo.getCatalog();
      if (mounted) {
        setState(() {
          _all = items;
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
                  (_muscleGroup == null ||
                      exercise.muscleGroup == _muscleGroup),
            )
            .toList();
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
                              color: _muscleGroup != null ? c.accent : c.card,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color:
                                    _muscleGroup != null ? c.accent : c.border,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  CupertinoIcons.slider_horizontal_3,
                                  size: 16,
                                  color:
                                      _muscleGroup != null
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
                                        _muscleGroup != null
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
                  if (_showFilters)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: Row(
                        children: [
                          _MuscleTag(
                            label: 'All',
                            selected: _muscleGroup == null,
                            onTap: () => setState(() => _muscleGroup = null),
                          ),
                          for (final group in _muscleGroups) ...[
                            const SizedBox(width: 7),
                            _MuscleTag(
                              label: group,
                              selected: _muscleGroup == group,
                              onTap: () => setState(() => _muscleGroup = group),
                            ),
                          ],
                        ],
                      ),
                    ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final e = filtered[i];
                        return GestureDetector(
                          onTap: () => Navigator.of(context).pop(e),
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
                                        e.muscleGroup,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: c.textSecondary,
                                          fontFamily: 'Rubik',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  CupertinoIcons.add_circled,
                                  size: 20,
                                  color: c.accent,
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
