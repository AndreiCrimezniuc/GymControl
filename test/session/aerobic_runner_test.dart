import 'dart:convert';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymboss/ui/menu_options_list/workouts/session/aerobic_runner.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('AerobicSessionController', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('counts up while running and freezes when paused', () {
      fakeAsync((async) {
        final c = AerobicSessionController();
        c.start();
        async.elapse(const Duration(seconds: 5));
        expect(c.totalSeconds, 5);
        expect(c.running, isTrue);

        c.pause();
        async.elapse(const Duration(seconds: 5));
        expect(c.totalSeconds, 5); // frozen
        expect(c.running, isFalse);

        c.toggle(); // resume
        async.elapse(const Duration(seconds: 3));
        expect(c.totalSeconds, 8);
        c.dispose();
      });
    });

    test('laps record splits and reset the current lap', () {
      fakeAsync((async) {
        final c = AerobicSessionController();
        c.start();
        async.elapse(const Duration(seconds: 30));
        c.lap();
        expect(c.laps, [30]);
        expect(c.currentLapSeconds, 0);

        async.elapse(const Duration(seconds: 20));
        c.lap();
        expect(c.laps, [30, 20]);
        expect(c.totalSeconds, 50);
        c.dispose();
      });
    });

    test('an empty lap is ignored', () {
      fakeAsync((async) {
        final c = AerobicSessionController();
        c.start();
        c.lap(); // 0s elapsed -> ignored
        expect(c.laps, isEmpty);
        c.dispose();
      });
    });

    test('reset clears everything', () {
      fakeAsync((async) {
        final c = AerobicSessionController();
        c.start();
        async.elapse(const Duration(seconds: 12));
        c.lap();
        c.reset();
        expect(c.totalSeconds, 0);
        expect(c.laps, isEmpty);
        expect(c.running, isFalse);
        c.dispose();
      });
    });

    test('fmt renders mm:ss and h:mm:ss', () {
      expect(AerobicSessionController.fmt(65), '01:05');
      expect(AerobicSessionController.fmt(3661), '1:01:01');
    });

    testWidgets('restores a running session using wall-clock time', (
      tester,
    ) async {
      var now = DateTime(2026, 1, 1, 12);
      final first = AerobicSessionController(now: () => now);
      first.begin(workoutId: 'run-1', workoutName: 'Easy run');
      await tester.pump();
      now = now.add(const Duration(seconds: 4));
      first.dispose();

      final restored = AerobicSessionController(now: () => now);
      await restored.restore();
      expect(restored.isActive, isTrue);
      expect(restored.running, isTrue);
      expect(restored.workoutId, 'run-1');
      expect(restored.totalSeconds, greaterThanOrEqualTo(4));
      restored.dispose();
    });

    testWidgets('pauses a forgotten running draft after four idle hours', (
      tester,
    ) async {
      final now = DateTime(2026, 9, 10, 12);
      SharedPreferences.setMockInitialValues({
        'active_aerobic_session_v1': jsonEncode({
          'workout_id': 'run-1',
          'workout_name': 'Easy run',
          'session_id': 'session-1',
          'started_at': now.subtract(const Duration(days: 2)).toIso8601String(),
          'accumulated': 0,
          'lap_base': 0,
          'laps': [],
          'running': true,
          'running_since': now
              .subtract(const Duration(days: 2))
              .toIso8601String(),
          'last_interaction_at': now
              .subtract(const Duration(days: 2))
              .toIso8601String(),
        }),
      });
      final restored = AerobicSessionController(now: () => now);

      await restored.restore();

      expect(restored.isActive, isTrue);
      expect(restored.running, isFalse);
      expect(restored.totalSeconds, const Duration(hours: 4).inSeconds);
      restored.dispose();
    });
  });
}
