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
    final filtered = _query.isEmpty
        ? _all
        : _all
              .where((e) => e.name.toLowerCase().contains(_query.toLowerCase()))
              .toList();
    return AppPage(
      title: 'Pick exercise',
      body: _loading
          ? const Center(child: CupertinoActivityIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
                  child: CupertinoSearchTextField(
                    placeholder: 'Search ${_all.length} exercises',
                    backgroundColor: c.card,
                    style: TextStyle(color: c.textPrimary, fontFamily: 'Rubik'),
                    onChanged: (v) => setState(() => _query = v),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
