import 'package:flutter_test/flutter_test.dart';
import 'package:gymboss/ui/core/theme/app_colors.dart';
import 'package:gymboss/ui/core/theme/theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(const {}));

  test('keeps independent accent choices for light and dark themes', () async {
    final theme = ThemeController();
    await theme.restored;

    expect(theme.isDark, isFalse);
    expect(theme.accent, AppAccent.red);

    await theme.toggle();
    expect(theme.accent, AppAccent.red);

    await theme.setAccent(AppAccent.green);
    expect(theme.colors.accent, AppAccent.green.color(isDark: true));

    await theme.toggle();
    expect(theme.accent, AppAccent.red);

    await theme.setAccent(AppAccent.purple);
    expect(theme.colors.accent, AppAccent.purple.color(isDark: false));

    theme.dispose();

    final restoredTheme = ThemeController();
    await restoredTheme.restored;
    expect(restoredTheme.isDark, isFalse);
    expect(restoredTheme.accent, AppAccent.purple);

    await restoredTheme.toggle();
    expect(restoredTheme.accent, AppAccent.green);
    restoredTheme.dispose();
  });

  test('ignores an unknown stored accent value', () async {
    SharedPreferences.setMockInitialValues(const {
      'app_theme_accent_light': 'orange',
    });

    final theme = ThemeController();
    await theme.restored;

    expect(theme.accent, AppAccent.red);
    theme.dispose();
  });
}
