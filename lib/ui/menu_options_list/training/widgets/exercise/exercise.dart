import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gymboss/domain/models/trainings/exercise.dart';
import 'package:gymboss/ui/core/ui/colors/main_dark_blue.dart';
import 'package:gymboss/ui/core/ui/colors/main_gradient.dart';
import 'package:gymboss/ui/core/ui/icons/icons_training.dart';
import 'package:gymboss/ui/menu_options_list/training/view_model/exercise_view_model.dart';
import 'package:gymboss/ui/menu_options_list/training/widgets/bullet_point.dart';
import 'package:gymboss/ui/menu_options_list/training/widgets/exercise/show_picker.dart';

class TrainingExercise extends StatefulWidget {
  const TrainingExercise({
    super.key,
    required this.name,
    required this.status,
    required this.exerciseSet,
    required this.onSkip,
    required this.onComplete,
    required this.onSetAsCurrent,
    required this.onHistoryChanged,
  });

  final String name;
  final bool status;
  final VoidCallback onSkip;
  final VoidCallback onComplete;
  final VoidCallback onSetAsCurrent;
  final VoidCallback onHistoryChanged;
  final List<ExerciseSet> exerciseSet;

  @override
  State<TrainingExercise> createState() => TrainingExerciseState();
}

// Export для доступа из других файлов
class TrainingExerciseState extends State<TrainingExercise> {
  late ExerciseViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ExerciseViewModel(initialSets: widget.exerciseSet);
  }

  void undo() {
    if (_viewModel.undo()) {
      setState(() {});
      widget.onHistoryChanged();
    }
  }

  bool get canUndo => _viewModel.canUndo;

  void _updateReps(int index, int newReps) {
    _viewModel.updateReps(index, newReps);
    setState(() {});
    widget.onHistoryChanged();
  }

  void _updateWeight(int index, double newWeight) {
    _viewModel.updateWeight(index, newWeight);
    setState(() {});
    widget.onHistoryChanged();
  }

  void _removeSet(int index) {
    _viewModel.removeSet(index);
    setState(() {});
    widget.onHistoryChanged();
  }

  void _addSet() {
    _viewModel.addSet();
    setState(() {});
    widget.onHistoryChanged();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        decoration: BoxDecoration(
          color: widget.status ? Color.fromRGBO(99, 32, 36, 1) : mainDarkBlue,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Image.asset(
                  widget.status
                      ? IconsTraining.dumbellActive
                      : IconsTraining.dumbellPassive,
                  width: 48,
                  height: 48,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (widget.status)
                      const Text(
                        "Current Exercise",
                        style: TextStyle(
                          fontSize: 12,
                          color: CupertinoColors.activeGreen,
                        ),
                      ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            Column(
              children: List.generate(_viewModel.sets.length, (index) {
                final set = _viewModel.sets[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      SizedBox(width: 40, child: bulletPoint(index)),

                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            showPicker(
                              context: context,
                              title: "Reps",
                              options: List.generate(
                                50,
                                (i) => Center(child: Text("${i + 1}")),
                              ),
                              initialIndex: set.reps - 1,
                              onSelected: (val) => _updateReps(index, val + 1),
                            );
                          },
                          child: Column(
                            children: [
                              const Text(
                                "Reps",
                                style: TextStyle(fontSize: 12),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "${set.reps}",
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            showPicker(
                              context: context,
                              title: "Weight (kg)",
                              options: List.generate(
                                200,
                                (i) => Center(child: Text("$i")),
                              ),
                              initialIndex: set.weight.toInt(),
                              onSelected: (val) =>
                                  _updateWeight(index, val.toDouble()),
                            );
                          },
                          child: Column(
                            children: [
                              const Text(
                                "Weight (kg)",
                                style: TextStyle(fontSize: 12),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "${set.weight.toInt()}",
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: const Icon(
                          CupertinoIcons.clear_circled,
                          color: CupertinoColors.systemRed,
                        ),
                        onPressed: () => _removeSet(index),
                      ),
                    ],
                  ),
                );
              }),
            ),

            const SizedBox(height: 16),

            // ➕ Кнопка добавить сет
            CupertinoButton(
              color: mainDarkBlue,
              padding: EdgeInsets.zero,
              child: SizedBox(
                width: 400,
                child: Center(
                  child: Text(
                    "Add set",
                    style: TextStyle(
                      fontSize: 16,
                      color: CupertinoColors.white,
                    ),
                  ),
                ),
              ),
              onPressed: _addSet,
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                //Skip button
                Container(
                  decoration: widget.status
                      ? MainGradient.purpleBlueButtonBackground
                      : MainGradient.darkDisabledButtonBackground,
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    color: Colors.transparent, // важно!
                    borderRadius: BorderRadius.circular(16),
                    onPressed: () {
                      if (widget.status) {
                        widget.onComplete();
                      } else {
                        widget.onSetAsCurrent();
                      }
                    },
                    child: Text(
                      widget.status ? "Complete" : "Completed",
                      style: const TextStyle(
                        fontSize: 16,
                        color: CupertinoColors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                //Complete button
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  color: mainDarkBlue,
                  child: Text(
                    "Skip",
                    style: TextStyle(
                      fontSize: 16,
                      color: CupertinoColors.white,
                    ),
                  ),
                  onPressed: () {
                    if (widget.status) {
                      widget.onComplete();
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
