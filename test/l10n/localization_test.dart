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
    expect(en.labelAccentColor, 'Accent Color');
    expect(ru.labelAccentColor, 'Цвет акцента');
    expect(en.accentPurple, 'Purple');
    expect(ru.accentGreen, 'Зелёный');
    expect(en.logOut, 'Log Out');
    expect(ru.logOut, 'Выйти');
    expect(en.strengthPassport, 'Strength Passport');
    expect(ru.strengthPassport, 'Силовой паспорт');
    expect(ru.resumeSummary('12:34', 3, 8), contains('3/8 подходов'));
    expect(ru.recordStartsHere, 'Ваша история начинается здесь');
    expect(ru.passportGuideTitle, 'КАК РАБОТАЕТ ПАСПОРТ');
    expect(ru.passportTierProgress('0.12', 'A', 50), contains('50%'));
    expect(ru.aiSuggest, 'AI-РАЗБОР');
    expect(ru.previousCompact('80×5'), 'БЫЛО 80×5');
  });

  test('every supported locale is loadable', () async {
    for (final locale in LocaleController.supported) {
      expect(AppLocalizations.delegate.isSupported(locale), isTrue);
      final l = await AppLocalizations.delegate.load(locale);
      expect(l.settingsTitle, isNotEmpty);
    }
  });
}
