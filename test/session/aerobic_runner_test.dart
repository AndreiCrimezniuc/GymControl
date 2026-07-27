import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymboss/ui/menu_options_list/workouts/session/aerobic_runner.dart';

void main() {
  group('AerobicSessionController', () {
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
  });
}
