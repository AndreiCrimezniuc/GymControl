import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymboss/ui/core/theme/app_colors.dart';
import 'package:gymboss/ui/core/theme/app_design.dart';

void main() {
  test('light selection uses a warm high-contrast canvas', () {
    expect(AppColors.light.isDark, isFalse);
    expect(AppColors.light.bg, const Color(0xFFF5F3F0));
    expect(AppColors.light.usesLightForeground, isFalse);
    expect(AppColors.light.card.a, lessThan(1));
    // Controls use an opaque secondary material so translucent layers are not
    // stacked on top of one another.
    expect(AppColors.light.iconBg.a, 1);
    expect(AppColors.light.border.a, greaterThanOrEqualTo(0.1));
    expect(
      _contrast(AppColors.light.accent, AppColors.light.bg),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrast(AppColors.light.textOnAccent, AppColors.light.accent),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrast(AppColors.light.accentSecondary, AppColors.light.bg),
      greaterThanOrEqualTo(4.5),
    );
  });

  test('dark selection keeps the original graphite palette', () {
    expect(AppColors.dark.isDark, isTrue);
    expect(AppColors.dark.bg, const Color(0xFF0A0A0B));
    expect(AppColors.dark.card, const Color(0xFF141416));
    expect(AppColors.dark.accent, const Color(0xFFCE3630));
    expect(AppColors.dark.usesLightForeground, isTrue);
  });

  test('surface geometry follows the shared rounded hierarchy', () {
    expect(AppDesign.radiusSmall, lessThan(AppDesign.radiusControl));
    expect(AppDesign.radiusControl, lessThan(AppDesign.radiusCard));
    expect(AppDesign.radiusCard, lessThan(AppDesign.radiusSheet));
    expect(AppDesign.hairline, lessThan(1));
  });
}

double _contrast(Color first, Color second) {
  final high = [first.computeLuminance(), second.computeLuminance()]..sort();
  return (high.last + 0.05) / (high.first + 0.05);
}
