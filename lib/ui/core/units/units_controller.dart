import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the user's weight unit (kg or lb), persists it, and converts between
/// the stored metric (always kg on the backend) and the display unit.
class UnitsController extends ChangeNotifier {
  static const _prefsKey = 'app_units_lb';
  static const _kgToLb = 2.2046226218;

  bool _lb = false;

  UnitsController() {
    _restore();
  }

  bool get isLb => _lb;
  String get label => _lb ? 'lb' : 'kg';

  /// kg (stored) → value in the display unit.
  double fromKg(double kg) => _lb ? kg * _kgToLb : kg;

  /// value in the display unit → kg (for storage).
  double toKg(double value) => _lb ? value / _kgToLb : value;

  /// Formats a stored-kg value in the display unit (no unit suffix).
  String format(double kg, {int? decimals}) {
    final v = fromKg(kg);
    final d = decimals ?? (v.abs() % 1 == 0 ? 0 : 1);
    return v.toStringAsFixed(d);
  }

  /// Formats a tonnage/volume in the display unit with thousands grouping and a
  /// unit suffix, e.g. "5 240 kg" (kept in kg/lb, never tonnes).
  String formatVolume(double kg) {
    final v = fromKg(kg).round();
    final s = v.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return '$buf $label';
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getBool(_prefsKey);
    if (stored != null && stored != _lb) {
      _lb = stored;
      notifyListeners();
    }
  }

  Future<void> setLb(bool value) async {
    if (_lb == value) return;
    _lb = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, _lb);
  }
}

extension UnitsContext on BuildContext {
  UnitsController get units => watch<UnitsController>();
  UnitsController get unitsController => read<UnitsController>();
}
