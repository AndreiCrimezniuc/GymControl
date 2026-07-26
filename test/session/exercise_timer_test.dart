import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymboss/ui/menu_options_list/workouts/session/workout_session_controller.dart';

void main() {
  // The timer's completion fires haptics / system sounds through platform
  // channels, so we need an initialized binding to absorb those no-ops.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('per-exercise timer', () {
    test('start attaches the timer to a card and counts down', () {
      fakeAsync((async) {
        final c = WorkoutSessionController();
        c.startExerciseTimer(2, 60);
        expect(c.exTimerKey, 2);
        expect(c.exTimerLeft, 60);
        expect(c.exTimerTotal, 60);
        expect(c.exTimerRunning, isTrue);

        async.elapse(const Duration(seconds: 5));
        expect(c.exTimerLeft, 55);
        c.stopExerciseTimer();
      });
    });

    test('pause freezes the countdown; resume continues it', () {
      fakeAsync((async) {
        final c = WorkoutSessionController();
        c.startExerciseTimer(1, 60);
        async.elapse(const Duration(seconds: 10));
        expect(c.exTimerLeft, 50);

        c.pauseExerciseTimer();
        expect(c.exTimerRunning, isFalse);
        async.elapse(const Duration(seconds: 10));
        expect(c.exTimerLeft, 50); // frozen

        c.resumeExerciseTimer();
        expect(c.exTimerRunning, isTrue);
        async.elapse(const Duration(seconds: 10));
        expect(c.exTimerLeft, 40);
        c.stopExerciseTimer();
      });
    });

    test('reset returns to the configured total and pauses', () {
      fakeAsync((async) {
        final c = WorkoutSessionController();
        c.startExerciseTimer(1, 45);
        async.elapse(const Duration(seconds: 20));
        expect(c.exTimerLeft, 25);

        c.resetExerciseTimer();
        expect(c.exTimerLeft, 45);
        expect(c.exTimerRunning, isFalse);
        c.stopExerciseTimer();
      });
    });

    test('adjust changes both the remaining time and the reset target', () {
      fakeAsync((async) {
        final c = WorkoutSessionController();
        c.startExerciseTimer(1, 60);
        c.pauseExerciseTimer();
        c.adjustExerciseTimer(15);
        expect(c.exTimerLeft, 75);
        expect(c.exTimerTotal, 75);
        c.adjustExerciseTimer(-30);
        expect(c.exTimerLeft, 45);
        expect(c.exTimerTotal, 45);
        c.stopExerciseTimer();
      });
    });

    test('counts down to zero and stops running', () {
      fakeAsync((async) {
        final c = WorkoutSessionController();
        c.startExerciseTimer(1, 3);
        async.elapse(const Duration(seconds: 3));
        expect(c.exTimerLeft, 0);
        expect(c.exTimerRunning, isFalse);
        c.stopExerciseTimer();
      });
    });

    test('stop detaches the timer', () {
      fakeAsync((async) {
        final c = WorkoutSessionController();
        c.startExerciseTimer(1, 60);
        c.stopExerciseTimer();
        expect(c.exTimerKey, isNull);
        expect(c.exTimerRunning, isFalse);
        async.elapse(const Duration(seconds: 5));
        expect(c.exTimerLeft, 0); // no ticking after stop
      });
    });

    test('duration is clamped to a sane range', () {
      fakeAsync((async) {
        final c = WorkoutSessionController();
        c.startExerciseTimer(1, 0); // below min -> clamps to 1
        expect(c.exTimerTotal, 1);
        c.stopExerciseTimer();
      });
    });
  });
}
