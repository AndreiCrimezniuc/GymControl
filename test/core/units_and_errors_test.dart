import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gymboss/core/errors/app_error.dart';
import 'package:gymboss/ui/core/units/units_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UnitsController', () {
    setUp(() => SharedPreferences.setMockInitialValues(const {}));

    test('defaults to kg with identity conversions', () {
      final u = UnitsController();
      expect(u.isLb, isFalse);
      expect(u.label, 'kg');
      expect(u.fromKg(100), 100);
      expect(u.toKg(100), 100);
    });

    test('converts to/from lb when enabled', () async {
      final u = UnitsController();
      await u.setLb(true);
      expect(u.isLb, isTrue);
      expect(u.label, 'lb');
      // 100 kg ~= 220.46 lb; round-trips back to ~100 kg
      expect(u.fromKg(100), closeTo(220.46, 0.1));
      expect(u.toKg(u.fromKg(100)), closeTo(100, 0.001));
    });

    test('format and formatVolume include the unit label', () {
      final u = UnitsController();
      expect(u.format(60.0), isNotEmpty);
      expect(u.formatVolume(1234.0), contains('kg'));
    });
  });

  group('AppErrorCode', () {
    test('every code has a stable code string and a user message', () {
      for (final e in AppErrorCode.values) {
        expect(e.code, isNotEmpty, reason: '$e code');
        expect(e.userMessage, isNotEmpty, reason: '$e message');
      }
    });

    test('codes are unique', () {
      final codes = AppErrorCode.values.map((e) => e.code).toSet();
      expect(codes.length, AppErrorCode.values.length);
    });
  });
}
