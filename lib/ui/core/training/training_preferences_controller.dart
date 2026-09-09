import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gymboss/domain/models/training/training_prescription.dart';

class TrainingPreferencesController extends ChangeNotifier {
  static const _formulaKey = 'training_one_rm_formula';
  static const _deloadFactorKey = 'training_deload_factor';
  OneRmFormula _formula = OneRmFormula.epley;
  double _deloadFactor = .70;
  late final Future<void> ready;

  TrainingPreferencesController() {
    ready = _restore();
  }

  OneRmFormula get formula => _formula;
  double get deloadFactor => _deloadFactor;

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_formulaKey);
    _formula = OneRmFormula.values.firstWhere(
      (item) => item.name == value,
      orElse: () => OneRmFormula.epley,
    );
    final factor = prefs.getDouble(_deloadFactorKey);
    if (factor != null && factor >= .1 && factor <= 1) {
      _deloadFactor = factor;
    }
    notifyListeners();
  }

  Future<void> setFormula(OneRmFormula value) async {
    if (value == _formula) return;
    _formula = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_formulaKey, value.name);
  }

  Future<void> setDeloadFactor(double value) async {
    final next = value.clamp(.1, 1).toDouble();
    if ((next - _deloadFactor).abs() < .0001) return;
    _deloadFactor = next;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_deloadFactorKey, next);
  }

  Future<void> applyRemote({
    required OneRmFormula formula,
    required double deloadFactor,
  }) async {
    final factor = deloadFactor.clamp(.1, 1).toDouble();
    final changed =
        formula != _formula || (factor - _deloadFactor).abs() >= .0001;
    _formula = formula;
    _deloadFactor = factor;
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString(_formulaKey, formula.name),
      prefs.setDouble(_deloadFactorKey, factor),
    ]);
    if (changed) notifyListeners();
  }
}
