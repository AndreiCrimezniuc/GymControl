import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_colors.dart';

/// Holds the active light/dark selection, persists it, and notifies listeners
/// so the whole app rebuilds on toggle.
class ThemeController extends ChangeNotifier {
  static const _prefsKey = 'app_theme_dark';
  static const _lightAccentPrefsKey = 'app_theme_accent_light';
  static const _darkAccentPrefsKey = 'app_theme_accent_dark';

  bool _isDark = false;
  AppAccent _lightAccent = AppAccent.red;
  AppAccent _darkAccent = AppAccent.red;
  var _localChangeRevision = 0;
  late final Future<void> restored;

  ThemeController() {
    restored = _restore();
  }

  bool get isDark => _isDark;
  AppAccent get accent => _isDark ? _darkAccent : _lightAccent;
  AppAccent get lightAccent => _lightAccent;
  AppAccent get darkAccent => _darkAccent;
  AppColors get colors =>
      (_isDark ? AppColors.dark : AppColors.light).withAccent(accent);

  Future<void> _restore() async {
    final revision = _localChangeRevision;
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getBool(_prefsKey);
    final lightAccent = _parseAccent(prefs.getString(_lightAccentPrefsKey));
    final darkAccent = _parseAccent(prefs.getString(_darkAccentPrefsKey));
    if (revision != _localChangeRevision) return;

    final nextIsDark = stored ?? _isDark;
    final nextLightAccent = lightAccent ?? _lightAccent;
    final nextDarkAccent = darkAccent ?? _darkAccent;
    if (nextIsDark != _isDark ||
        nextLightAccent != _lightAccent ||
        nextDarkAccent != _darkAccent) {
      _isDark = nextIsDark;
      _lightAccent = nextLightAccent;
      _darkAccent = nextDarkAccent;
      notifyListeners();
    }
  }

  Future<void> toggle() async {
    _localChangeRevision++;
    _isDark = !_isDark;
    final value = _isDark;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (_isDark == value) await prefs.setBool(_prefsKey, value);
  }

  Future<void> setAccent(AppAccent value) async {
    if (value == accent) return;
    _localChangeRevision++;
    final changingDarkAccent = _isDark;
    if (changingDarkAccent) {
      _darkAccent = value;
    } else {
      _lightAccent = value;
    }
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final current = changingDarkAccent ? _darkAccent : _lightAccent;
    if (current == value) {
      await prefs.setString(
        changingDarkAccent ? _darkAccentPrefsKey : _lightAccentPrefsKey,
        value.name,
      );
    }
  }

  /// Applies the account-level appearance preference after sign-in. Local
  /// storage still makes the first frame instant; the account copy then keeps
  /// another device from silently reverting the user's design choice.
  Future<void> applyRemote({
    required bool isDark,
    required AppAccent lightAccent,
    required AppAccent darkAccent,
  }) async {
    _localChangeRevision++;
    final changed =
        _isDark != isDark ||
        _lightAccent != lightAccent ||
        _darkAccent != darkAccent;
    _isDark = isDark;
    _lightAccent = lightAccent;
    _darkAccent = darkAccent;
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setBool(_prefsKey, isDark),
      prefs.setString(_lightAccentPrefsKey, lightAccent.name),
      prefs.setString(_darkAccentPrefsKey, darkAccent.name),
    ]);
    if (changed) notifyListeners();
  }

  static AppAccent? _parseAccent(String? value) {
    for (final accent in AppAccent.values) {
      if (accent.name == value) return accent;
    }
    return null;
  }
}

/// Convenience access: `context.colors` (rebuilds on theme change) and
/// `context.themeController` (for actions like toggling).
extension ThemeContext on BuildContext {
  AppColors get colors => watch<ThemeController>().colors;
  ThemeController get themeController => read<ThemeController>();
}
