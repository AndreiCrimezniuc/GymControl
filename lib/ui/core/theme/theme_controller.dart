import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_colors.dart';

/// Holds the active light/dark selection, persists it, and notifies listeners
/// so the whole app rebuilds on toggle.
class ThemeController extends ChangeNotifier {
  static const _prefsKey = 'app_theme_dark';

  bool _isDark = false;

  ThemeController() {
    _restore();
  }

  bool get isDark => _isDark;
  AppColors get colors => _isDark ? AppColors.dark : AppColors.light;

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getBool(_prefsKey);
    if (stored != null && stored != _isDark) {
      _isDark = stored;
      notifyListeners();
    }
  }

  Future<void> toggle() async {
    _isDark = !_isDark;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, _isDark);
  }
}

/// Convenience access: `context.colors` (rebuilds on theme change) and
/// `context.themeController` (for actions like toggling).
extension ThemeContext on BuildContext {
  AppColors get colors => watch<ThemeController>().colors;
  ThemeController get themeController => read<ThemeController>();
}
