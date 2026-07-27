import 'package:flutter_test/flutter_test.dart';
import 'package:gymboss/ui/menu_options_list/workouts/session/workout_session_controller.dart';

void main() {
  group('live session edits', () {
    test('addExercise appends an exercise with one empty set', () {
      final c = WorkoutSessionController();
      c.addExercise(exerciseId: 7, name: 'Squat', muscleGroup: 'legs');
      expect(c.groups, hasLength(1));
      expect(c.groups.single.exerciseId, 7);
      expect(c.groups.single.sets, hasLength(1));
      expect(c.totalSets, 1);
    });

    test('addSet clones the last set and bumps the total', () {
      final c = WorkoutSessionController();
      c.addExercise(exerciseId: 1, name: 'Bench', muscleGroup: 'chest');
      final g = c.groups.single;
      g.sets.first.weight = '60';
      g.sets.first.reps = '8';

      c.addSet(g);
      expect(g.sets, hasLength(2));
      expect(g.sets.last.weight, '60'); // seeded from previous
      expect(g.sets.last.reps, '8');
      expect(c.totalSets, 2);
    });

    test('removeSet drops the set and decrements the total', () {
      final c = WorkoutSessionController();
      c.addExercise(exerciseId: 1, name: 'Bench', muscleGroup: 'chest');
      final g = c.groups.single;
      c.addSet(g);
      expect(c.totalSets, 2);

      c.removeSet(g, g.sets.last);
      expect(g.sets, hasLength(1));
      expect(c.totalSets, 1);
    });

    test('removeExercise removes all of its sets from the total', () {
      final c = WorkoutSessionController();
      c.addExercise(exerciseId: 1, name: 'Bench', muscleGroup: 'chest');
      c.addExercise(exerciseId: 2, name: 'Row', muscleGroup: 'back');
      final first = c.groups.first;
      c.addSet(first); // first now has 2 sets; total = 3
      expect(c.totalSets, 3);

      c.removeExercise(first);
      expect(c.groups, hasLength(1));
      expect(c.groups.single.exerciseId, 2);
      expect(c.totalSets, 1);
    });

    test('moveExercise reorders and clamps at the ends', () {
      final c = WorkoutSessionController();
      c.addExercise(exerciseId: 1, name: 'Bench', muscleGroup: 'chest');
      c.addExercise(exerciseId: 2, name: 'Row', muscleGroup: 'back');
      c.addExercise(exerciseId: 3, name: 'Squat', muscleGroup: 'legs');
      final row = c.groups[1];

      c.moveExercise(row, -1); // Row -> index 0
      expect(c.groups.map((g) => g.exerciseId), [2, 1, 3]);

      c.moveExercise(row, 1); // back to index 1
      expect(c.groups.map((g) => g.exerciseId), [1, 2, 3]);

      // clamp: moving the first up is a no-op
      c.moveExercise(c.groups.first, -1);
      expect(c.groups.map((g) => g.exerciseId), [1, 2, 3]);
    });

    test('adding an exercise detaches any running exercise timer', () {
      final c = WorkoutSessionController();
      c.addExercise(exerciseId: 1, name: 'Bench', muscleGroup: 'chest');
      c.startExerciseTimer(1, 60);
      expect(c.exTimerKey, 1);

      c.addExercise(exerciseId: 2, name: 'Row', muscleGroup: 'back');
      expect(c.exTimerKey, isNull); // indices shifted -> timer cleared
      c.stopExerciseTimer();
    });
  });
}
