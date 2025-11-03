import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gymboss/domain/models/trainigs/exercise.dart';
import 'package:gymboss/ui/core/ui/colors/main_gradient.dart';
import 'package:gymboss/ui/core/ui/icons/icons_training.dart';
import 'package:gymboss/ui/menu_options_list/training/widgets/bullet_point.dart';

class TrainingExercise extends StatefulWidget {
  const TrainingExercise({
    super.key,
    required this.name,
    required this.status,
    required this.exerciseSet,
  });

  final String name;
  final bool status;
  final List<ExerciseSet> exerciseSet;

  @override
  State<TrainingExercise> createState() => _TrainingExerciseState();
}

class _TrainingExerciseState extends State<TrainingExercise> {
  late List<ExerciseSet> _sets = [];

  @override
  void initState() {
    super.initState();
    _sets = List.from(widget.exerciseSet);
  }

  void _updateReps(int index, int newReps) {
    setState(() {
      _sets[index] = ExerciseSet(weight: _sets[index].weight, reps: newReps);
    });
  }

  void _updateWeight(int index, double newWeight) {
    setState(() {
      _sets[index] = ExerciseSet(weight: newWeight, reps: _sets[index].reps);
    });
  }

  void _removeSet(int index) {
    setState(() {
      _sets.removeAt(index);
    });
  }

  void _showPicker({
    required BuildContext context,
    required String title,
    required List<Widget> options,
    required int initialIndex,
    required Function(int) onSelected,
  }) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 250,
        color: CupertinoColors.systemGrey6,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: CupertinoColors.systemGrey5,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Text("Done"),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 36.0,
                scrollController: FixedExtentScrollController(
                  initialItem: initialIndex,
                ),
                onSelectedItemChanged: onSelected,
                children: options,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        decoration: BoxDecoration(
          color: Color.fromRGBO(99, 32, 36, 1),
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
              children: List.generate(_sets.length, (index) {
                final set = _sets[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      SizedBox(width: 40, child: bulletPoint(index)),

                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            _showPicker(
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
                            _showPicker(
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: CupertinoColors.activeBlue,
              child: Text(
                "Add set",
                style: TextStyle(fontSize: 16, color: CupertinoColors.black),
              ),
              onPressed: () {
                setState(() {
                  _sets.add(ExerciseSet(weight: 0, reps: 10));
                });
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  decoration: MainGradient
                      .purpleBlueButtonBackground, // твой градиент и тень
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    color: Colors.transparent, // важно!
                    borderRadius: BorderRadius.circular(16),
                    onPressed: () {},
                    child: Text(
                      "Complete",
                      style: const TextStyle(
                        fontSize: 16,
                        color: CupertinoColors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                CupertinoButton(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  color: CupertinoColors.black,
                  child: Text(
                    "Skip",
                    style: TextStyle(
                      fontSize: 16,
                      color: CupertinoColors.white,
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _sets.add(ExerciseSet(weight: 0, reps: 10));
                    });
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
