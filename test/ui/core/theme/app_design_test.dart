import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymboss/ui/core/theme/app_colors.dart';
import 'package:gymboss/ui/core/theme/app_design.dart';

void main() {
  test('umber theme keeps the reference background and translucent layers', () {
    expect(AppColors.dark.bg, const Color(0xFF573535));
    expect(AppColors.dark.card.a, lessThan(1));
    expect(AppColors.dark.iconBg.a, lessThan(1));
    expect(AppColors.dark.border.a, lessThan(0.2));
  });

  test('surface geometry follows the shared rounded hierarchy', () {
    expect(AppDesign.radiusSmall, lessThan(AppDesign.radiusControl));
    expect(AppDesign.radiusControl, lessThan(AppDesign.radiusCard));
    expect(AppDesign.radiusCard, lessThan(AppDesign.radiusSheet));
    expect(AppDesign.hairline, lessThan(1));
  });
}
