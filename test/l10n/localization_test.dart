import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gymboss/l10n/app_localizations.dart';
import 'package:gymboss/ui/core/locale/locale_controller.dart';

void main() {
  test('English and Russian both resolve the settings keys', () async {
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    final ru = await AppLocalizations.delegate.load(const Locale('ru'));

    expect(en.settingsTitle, 'Settings');
    expect(ru.settingsTitle, 'Настройки');
    expect(en.labelDarkMode, 'Dark Mode');
    expect(ru.labelDarkMode, 'Тёмная тема');
    expect(en.logOut, 'Log Out');
    expect(ru.logOut, 'Выйти');
  });

  test('every supported locale is loadable', () async {
    for (final locale in LocaleController.supported) {
      expect(AppLocalizations.delegate.isSupported(locale), isTrue);
      final l = await AppLocalizations.delegate.load(locale);
      expect(l.settingsTitle, isNotEmpty);
    }
  });
}
