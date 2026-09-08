import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gymboss/domain/models/training/training_prescription.dart';

class TrainingPreferencesController extends ChangeNotifier {
  static const _formulaKey = 'training_one_rm_formula';
  OneRmFormula _formula = OneRmFormula.epley;
  late final Future<void> ready;

  TrainingPreferencesController() {
    ready = _restore();
  }

  OneRmFormula get formula => _formula;

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_formulaKey);
    _formula = OneRmFormula.values.firstWhere(
      (item) => item.name == value,
      orElse: () => OneRmFormula.epley,
    );
    notifyListeners();
  }

  Future<void> setFormula(OneRmFormula value) async {
    if (value == _formula) return;
    _formula = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_formulaKey, value.name);
  }
}
