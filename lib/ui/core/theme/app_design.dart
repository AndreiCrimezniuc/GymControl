import 'package:flutter/widgets.dart';

/// Shared geometry and motion for the ChatGPT-inspired interface.
abstract final class AppDesign {
  static const double pagePadding = 18;
  static const double radiusSmall = 12;
  static const double radiusControl = 16;
  static const double radiusCard = 22;
  static const double radiusSheet = 28;
  static const double hairline = 0.75;
  static const double glassBlur = 22;

  static const Duration quick = Duration(milliseconds: 160);
  static const Duration standard = Duration(milliseconds: 240);

  static const Curve curve = Curves.easeOutCubic;
}
