import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the user's language choice and persists it. A null [locale] means
/// "follow the system locale" (the CupertinoApp default when locale is null).
class LocaleController extends ChangeNotifier {
  static const _prefsKey = 'app_locale';

  /// Locales the app ships translations for.
  static const supported = <Locale>[Locale('en'), Locale('ru')];

  Locale? _locale;
  Locale? get locale => _locale;

  LocaleController() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey);
    if (code != null && code.isNotEmpty) {
      _locale = Locale(code);
      notifyListeners();
    }
  }

  /// Sets the language, or clears it (null) to follow the system.
  Future<void> setLocale(Locale? locale) async {
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(_prefsKey);
    } else {
      await prefs.setString(_prefsKey, locale.languageCode);
    }
  }
}
