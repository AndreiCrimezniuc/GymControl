import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:gymboss/data/repositories/trainings_api.dart';
import 'package:gymboss/data/services/auth/authenticated_client.dart';
import 'package:gymboss/data/services/trainings/trainings.dart';
import 'package:gymboss/domain/models/trainings/trainings.dart';
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
    final theme = CupertinoTheme.of(context);
    return CupertinoPageScaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      navigationBar: const CupertinoNavigationBar(middle: Text("Training")),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Schedule",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: CupertinoColors.black,
                    ),
                  ),

                  Text(
                    '${currentExerciseIndex + 1} /${currentTraining.exercises.length.toString()}  ',
                    style: TextStyle(color: CupertinoColors.black),
                  ),
                ],
              ),

              const SizedBox(height: 6),
              const SizedBox(height: 2),
              Row(
                children: [
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    onPressed: () {
                      currentComplexity = TrainingComplexity.hard;
                      loadTrainings();
                    },
                    child: const Text("Hard"),
                  ),
                  const SizedBox(width: 8),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    onPressed: () {
                      currentComplexity = TrainingComplexity.medium;
                      loadTrainings();
                    },
                    child: const Text("Medium"),
                  ),
                  const SizedBox(width: 8),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    onPressed: () {
                      currentComplexity = TrainingComplexity.easy;
                      loadTrainings();
                    },
                    child: const Text("Easy"),
                  ),
                  const Spacer(),

                  Builder(
                    builder: (context) {
                      final key = _exerciseKeys[currentExerciseIndex];
                      final canUndo = key?.currentState?.canUndo ?? false;
                      return CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        onPressed: canUndo
                            ? () {
                                key!.currentState!.undo();
                                setState(() {});
                              }
                            : null,
                        child: Icon(
                          CupertinoIcons.arrow_counterclockwise,
                          color: canUndo ? null : CupertinoColors.systemGrey,
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
      ),
    );
  }
}
