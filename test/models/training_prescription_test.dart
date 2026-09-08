import 'package:flutter_test/flutter_test.dart';
import 'package:gymboss/domain/models/training/training_prescription.dart';
import 'package:gymboss/domain/models/workouts/workout.dart';

void main() {
  test('one rep max formulas preserve a performed single', () {
    for (final formula in OneRmFormula.values) {
      expect(formula.estimate(100, 1), 100);
    }
  });

  test(
    'double progression adds weight only after rep range at sane effort',
    () {
      const rule = ProgressionRule(
        type: ProgressionRuleType.doubleProgression,
        incrementKg: 2.5,
        minReps: 6,
        maxReps: 10,
      );
      final advance = rule.suggest(
        previousWeightKg: 80,
        completedReps: [10, 10, 10],
        rpe: [8, 8.5, 8],
      );
      expect(advance.weightKg, 82.5);
      expect(advance.targetReps, 6);

      final hold = rule.suggest(
        previousWeightKg: 80,
        completedReps: [10, 10, 10],
        rpe: [9, 9, 9],
      );
      expect(hold.weightKg, 80);
      expect(hold.reason, 'hold_for_effort');
    },
  );

  test('minimum-energy workout removes optional work and failure sets', () {
    final workout = Workout(
      id: 'w',
      name: 'Day',
      comment: '',
      visibility: 'private',
      owned: true,
      shareCode: '',
      exerciseCount: 3,
      timesPerformed: 0,
      exercises: List.generate(
        3,
        (index) => WorkoutExercise(
          exerciseId: index + 1,
          name: 'E$index',
          imageUrl: '',
          muscleGroup: 'Chest',
          isOptional: index == 2,
          restSeconds: 90,
          comment: '',
          sets: const [
            WorkoutSet(difficulty: 'medium', weightKg: 100, reps: 8),
            WorkoutSet(
              difficulty: 'medium',
              weightKg: 100,
              reps: 8,
              setType: 'failure',
            ),
          ],
        ),
      ),
    );
    final adapted = workout.forEnergy(EnergyMode.minimum);
    expect(adapted.exercises.length, 2);
    expect(adapted.exercises.first.sets.length, 2);
    expect(adapted.exercises.first.sets.first.weightKg, 82);
  });

  test('assistance subtracts from bodyweight and never becomes negative', () {
    expect(
      effectiveLoadKg(mode: LoadMode.assisted, enteredKg: 30, bodyweightKg: 80),
      50,
    );
    expect(
      effectiveLoadKg(
        mode: LoadMode.assisted,
        enteredKg: 100,
        bodyweightKg: 80,
      ),
      0,
    );
  });
}
