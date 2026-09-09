import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gymboss/domain/models/training/training_prescription.dart';
import 'package:gymboss/ui/core/training/training_preferences_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(const {}));

  test('remote training preferences become the durable local copy', () async {
    final preferences = TrainingPreferencesController();
    await preferences.ready;

    await preferences.applyRemote(
      formula: OneRmFormula.wathan,
      deloadFactor: .6,
    );
    expect(preferences.formula, OneRmFormula.wathan);
    expect(preferences.deloadFactor, .6);

    preferences.dispose();
    final restored = TrainingPreferencesController();
    await restored.ready;
    expect(restored.formula, OneRmFormula.wathan);
    expect(restored.deloadFactor, .6);
    restored.dispose();
  });

  test('deload factor is constrained to a safe range', () async {
    final preferences = TrainingPreferencesController();
    await preferences.setDeloadFactor(2);
    expect(preferences.deloadFactor, 1);
    await preferences.setDeloadFactor(0);
    expect(preferences.deloadFactor, .1);
    preferences.dispose();
  });
}
