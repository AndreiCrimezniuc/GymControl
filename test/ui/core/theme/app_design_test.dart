import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymboss/ui/core/theme/app_colors.dart';
import 'package:gymboss/ui/core/theme/app_design.dart';

void main() {
  test('light selection owns the high-contrast umber appearance', () {
    expect(AppColors.light.isDark, isFalse);
    expect(AppColors.light.bg, const Color(0xFF573535));
    expect(AppColors.light.usesLightForeground, isTrue);
    expect(AppColors.light.card.a, lessThan(1));
    expect(AppColors.light.iconBg.a, lessThan(1));
    expect(AppColors.light.border.a, greaterThanOrEqualTo(0.2));
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
