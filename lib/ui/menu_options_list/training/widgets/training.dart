import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gymboss/data/repositories/trainings.dart';
import 'package:gymboss/data/services/trainigs/trainings.dart';
import 'package:gymboss/domain/models/trainigs/trainigs.dart';
import 'package:gymboss/ui/menu_options_list/training/view_model/trainig.dart';
import 'package:gymboss/ui/menu_options_list/training/widgets/exercise.dart';

class Training extends StatefulWidget {
  const Training({super.key});

  @override
  State<Training> createState() => _TrainingState();
}

class _TrainingState extends State<Training> {
  late final TrainingViewModel viewModel;
  List<Trainings> trainings = [];
  bool isLoading = true;
  String? error;
  TrainingComplexity currentComplexity = TrainingComplexity.hard;
  Trainings currentTraining = Trainings.empty();

  @override
  void initState() {
    super.initState();
    viewModel = TrainingViewModel(
      trainingsService: TrainingsService(repository: TrainingsRepositoryImpl()),
    );
    loadTrainings();
  }

  Future<void> loadTrainings() async {
    setState(() => isLoading = true);
    try {
      trainings = await viewModel.trainingsService.fetchAllTrainings();
      currentTraining = trainings.firstWhere(
        (item) => item.complexity == currentComplexity,
        orElse: () => Trainings.empty(), // 🔹 если хочешь избежать null
      );
      error = null;
    } catch (e) {
      error = e.toString();
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text("Training")),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------- H1 ----------
              const Text(
                "Schedule",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: CupertinoColors.black,
                ),
              ),
              const SizedBox(height: 6),

              // ---------- H2 / subtitle ----------
              const Text(
                "Your personal training schedule",
                style: TextStyle(fontSize: 16, color: CupertinoColors.black),
              ),
              const SizedBox(height: 12),

              // ---------- Filters / controls (пример) ----------
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
                    onPressed: loadTrainings,
                    child: const Text("Medium"),
                  ),
                  const SizedBox(width: 8),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    onPressed: loadTrainings,
                    child: const Text("Easy"),
                  ),
                  const Spacer(),

                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    onPressed: loadTrainings,
                    child: const Icon(CupertinoIcons.lab_flask_solid),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ---------- Content area (под заголовками) ----------
              // Expanded гарантирует, что этот блок займет всё оставшееся пространство,
              // и внутри можно безопасно показывать индикатор, ошибку или список.
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

                    // Контент: список тренировок (скроллится внутри Expanded)
                    if (currentTraining.isEmpty()) {
                      return const Center(child: Text('No trainings found'));
                    }

                    return ListView.separated(
                      itemCount: currentTraining.exercises.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: CupertinoColors.systemGrey4,
                      ),
                      itemBuilder: (context, idx) {
                        final t = currentTraining.exercises[idx];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TrainingExercise(
                                name: t.name,
                                status: true,
                                exerciseSet: t.sets,
                              ),
                            ],
                          ),
                        );
                      },
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
