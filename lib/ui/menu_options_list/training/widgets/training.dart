import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:gymboss/data/repositories/trainings_api.dart';
import 'package:gymboss/data/services/auth/authenticated_client.dart';
import 'package:gymboss/data/services/trainings/trainings.dart';
import 'package:gymboss/domain/models/trainings/trainings.dart';
import 'package:gymboss/ui/core/theme/theme_controller.dart';
import 'package:gymboss/ui/core/ui/widgets/app_page.dart';
import 'package:gymboss/ui/menu_options_list/training/view_model/training_view_model.dart';
import 'package:gymboss/ui/menu_options_list/training/widgets/exercise/exercise.dart';

class Training extends StatefulWidget {
  const Training({super.key});

  @override
  State<Training> createState() => _TrainingState();
}

class _TrainingState extends State<Training> {
  late final TrainingViewModel viewModel;
  List<TrainingEntity> trainings = [];
  bool isLoading = true;
  String? error;
  TrainingComplexity currentComplexity = TrainingComplexity.hard;
  TrainingEntity currentTraining = TrainingEntity.empty();
  int currentExerciseIndex = 0;
  final Map<int, GlobalKey<TrainingExerciseState>> _exerciseKeys = {};

  @override
  void initState() {
    super.initState();
    viewModel = TrainingViewModel(
      trainingsService: TrainingsService(
        repository: TrainingsApiRepository(
          client: context.read<AuthenticatedClient>(),
        ),
      ),
    );
    loadTrainings();
  }

  Future<void> loadTrainings() async {
    setState(() => isLoading = true);
    try {
      trainings = await viewModel.trainingsService.fetchAllTrainings();
      currentExerciseIndex = 0;
      currentTraining = trainings.firstWhere(
        (item) => item.complexity == currentComplexity,
        orElse: () => TrainingEntity.empty(),
      );
      _exerciseKeys.clear(); // Очищаем ключи при загрузке новой тренировки
      error = null;
    } catch (e) {
      error = e.toString();
    } finally {
      setState(() => isLoading = false);
    }
  }

  void completeExercise() {
    nextExercise();
    //sendStatistics();
  }

  void nextExercise() {
    if (currentExerciseIndex < currentTraining.exercises.length - 1) {
      setState(() {
        currentExerciseIndex++;
      });
    } else {
      showCupertinoDialog(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: const Text("Done!"),
          content: const Text("You've finished this training."),
          actions: [
            CupertinoDialogAction(
              child: const Text("OK"),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }
  }

  void setExerciseAsCurrent(int index) {
    setState(() {
      currentExerciseIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppPage(
      title: 'Training',
      actions: [
        Text(
          '${currentExerciseIndex + 1} / ${currentTraining.exercises.length}',
          style: TextStyle(
            color: c.textSecondary,
            fontFamily: 'Rubik',
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _ComplexityChip(
                  label: 'Hard',
                  active: currentComplexity == TrainingComplexity.hard,
                  onTap: () {
                    currentComplexity = TrainingComplexity.hard;
                    loadTrainings();
                  },
                ),
                const SizedBox(width: 8),
                _ComplexityChip(
                  label: 'Medium',
                  active: currentComplexity == TrainingComplexity.medium,
                  onTap: () {
                    currentComplexity = TrainingComplexity.medium;
                    loadTrainings();
                  },
                ),
                const SizedBox(width: 8),
                _ComplexityChip(
                  label: 'Easy',
                  active: currentComplexity == TrainingComplexity.easy,
                  onTap: () {
                    currentComplexity = TrainingComplexity.easy;
                    loadTrainings();
                  },
                ),
                const Spacer(),
                Builder(
                  builder: (context) {
                    final key = _exerciseKeys[currentExerciseIndex];
                    final canUndo = key?.currentState?.canUndo ?? false;
                    return CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      onPressed: canUndo
                          ? () {
                              key!.currentState!.undo();
                              setState(() {});
                            }
                          : null,
                      child: Icon(
                        CupertinoIcons.arrow_counterclockwise,
                        color: canUndo ? c.accent : c.textSecondary,
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 12),

              Expanded(
                child: Builder(
                  builder: (context) {
                    if (isLoading) {
                      return const Center(child: CupertinoActivityIndicator());
                    }

                    if (error != null) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Error: $error'),
                            const SizedBox(height: 8),
                            CupertinoButton(
                              onPressed: loadTrainings,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }

                    if (currentTraining.isEmpty()) {
                      return const Center(child: Text('No trainings found'));
                    }

                    return Column(
                      children: [
                        Expanded(
                          child: ListView.separated(
                            itemCount: currentTraining.exercises.length,
                            separatorBuilder: (_, __) => Container(
                              height: 1,
                              color: CupertinoColors.systemGrey4,
                            ),
                            itemBuilder: (context, idx) {
                              final t = currentTraining.exercises[idx];
                              if (!_exerciseKeys.containsKey(idx)) {
                                _exerciseKeys[idx] =
                                    GlobalKey<TrainingExerciseState>();
                              }
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                child: TrainingExercise(
                                  key: _exerciseKeys[idx],
                                  name: t.name,
                                  status: idx == currentExerciseIndex,
                                  exerciseSet: t.sets,
                                  onSkip: completeExercise,
                                  onComplete: completeExercise,
                                  onSetAsCurrent: () =>
                                      setExerciseAsCurrent(idx),
                                  onHistoryChanged: () => setState(() {}),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
    );
  }
}

class _ComplexityChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _ComplexityChip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? c.accent : c.card,
          borderRadius: BorderRadius.circular(12),
          border: active ? null : Border.all(color: c.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            fontFamily: 'Rubik',
            color: active ? c.textOnAccent : c.textSecondary,
          ),
        ),
      ),
    );
  }
}
