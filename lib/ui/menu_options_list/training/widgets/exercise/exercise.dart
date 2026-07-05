import 'package:flutter/cupertino.dart';
import 'package:gymboss/domain/models/trainings/exercise.dart';
import 'package:gymboss/ui/core/theme/theme_controller.dart';
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
    final c = context.colors;
    return SingleChildScrollView(
      child: Container(
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.status ? c.accent : c.border,
            width: widget.status ? 1.5 : 1,
          ),
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
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: c.textPrimary,
                        fontFamily: 'Rubik',
                      ),
                    ),
                    if (widget.status)
                      Text(
                        "Current Exercise",
                        style: TextStyle(fontSize: 12, color: c.accent, fontFamily: 'Rubik'),
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
                              Text("Reps", style: TextStyle(fontSize: 12, color: c.textSecondary, fontFamily: 'Rubik')),
                              const SizedBox(height: 8),
                              Text(
                                "${set.reps}",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: c.textPrimary,
                                  fontFamily: 'Rubik',
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
                              Text("Weight (kg)", style: TextStyle(fontSize: 12, color: c.textSecondary, fontFamily: 'Rubik')),
                              const SizedBox(height: 8),
                              Text(
                                "${set.weight.toInt()}",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: c.textPrimary,
                                  fontFamily: 'Rubik',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => _removeSet(index),
                        child: const Icon(
                          CupertinoIcons.clear_circled,
                          color: CupertinoColors.systemRed,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                color: c.iconBg,
                padding: const EdgeInsets.symmetric(vertical: 12),
                borderRadius: BorderRadius.circular(12),
                onPressed: _addSet,
                child: Text(
                  "Add set",
                  style: TextStyle(fontSize: 16, color: c.textPrimary, fontFamily: 'Rubik'),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: widget.status ? c.accent : c.iconBg,
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
                    style: TextStyle(
                      fontSize: 16,
                      color: widget.status ? c.textOnAccent : c.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Rubik',
                    ),
                  ),
                ),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: c.iconBg,
                  borderRadius: BorderRadius.circular(16),
                  onPressed: () {
                    if (widget.status) {
                      widget.onComplete();
                    }
                  },
                  child: Text(
                    "Skip",
                    style: TextStyle(fontSize: 16, color: c.textSecondary, fontFamily: 'Rubik'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
