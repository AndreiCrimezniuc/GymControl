import 'package:flutter_test/flutter_test.dart';
import 'package:gymboss/ui/menu_options_list/workouts/session/workout_session_controller.dart';

SessionSet _set({String type = 'working', bool done = false}) => SessionSet(
  exerciseId: 1,
  restSeconds: 60,
  plannedWeightKg: 50,
  plannedReps: 10,
  weight: '50',
  reps: '10',
  type: type,
  done: done,
);

void main() {
  group('set type selection', () {
    test('setTypes lists the explicit options in order', () {
      expect(setTypes, ['warmup', 'working', 'failure', 'dropset']);
    });

    test('setSetType applies a valid explicit choice', () {
      final c = WorkoutSessionController();
      final s = _set(type: 'working');
      c.setSetType(s, 'failure');
      expect(s.type, 'failure');
    });

    test('setSetType ignores unknown values', () {
      final c = WorkoutSessionController();
      final s = _set(type: 'working');
      c.setSetType(s, 'superset');
      expect(s.type, 'working');
    });

    test('setSetType is a no-op once the set is logged', () {
      final c = WorkoutSessionController();
      final s = _set(type: 'working', done: true);
      c.setSetType(s, 'warmup');
      expect(s.type, 'working');
    });

    test('setSetType notifies listeners only on a real change', () {
      final c = WorkoutSessionController();
      var notifications = 0;
      c.addListener(() => notifications++);
      final s = _set(type: 'working');

      c.setSetType(s, 'working'); // same value -> no notify
      expect(notifications, 0);

      c.setSetType(s, 'warmup'); // real change -> notify
      expect(notifications, 1);
    });

    test('cycleSetType walks through every supported type', () {
      final c = WorkoutSessionController();
      final s = _set(type: 'warmup');
      c.cycleSetType(s);
      expect(s.type, 'working');
      c.cycleSetType(s);
      expect(s.type, 'failure');
      c.cycleSetType(s);
      expect(s.type, 'dropset');
      c.cycleSetType(s);
      expect(s.type, 'warmup');
    });

    test('cycleSetType is a no-op once logged', () {
      final c = WorkoutSessionController();
      final s = _set(type: 'working', done: true);
      c.cycleSetType(s);
      expect(s.type, 'working');
    });
  });

  group('set progression tag', () {
    test('progressionTypes lists the supported annotations', () {
      expect(progressionTypes, [
        'weight',
        'amplitude',
        'efficiency',
        'meo',
        'dropset',
      ]);
    });

    test('setProgression applies a valid tag and can clear it', () {
      final c = WorkoutSessionController();
      final s = _set();
      c.setProgression(s, 'amplitude');
      expect(s.progression, 'amplitude');
      c.setProgression(s, ''); // clear
      expect(s.progression, '');
    });

    test('setProgression ignores unknown values', () {
      final c = WorkoutSessionController();
      final s = _set();
      c.setProgression(s, 'telekinesis');
      expect(s.progression, '');
    });

    test('setProgression is a no-op once the set is logged', () {
      final c = WorkoutSessionController();
      final s = _set(done: true);
      c.setProgression(s, 'meo');
      expect(s.progression, '');
    });
  });
}
