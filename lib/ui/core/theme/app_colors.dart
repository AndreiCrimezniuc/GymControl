import 'package:flutter/widgets.dart';

/// Full colour palette for one theme (light or dark). Read it from context via
/// `context.colors` (see theme_controller.dart). The light palette uses a
/// warm neutral scale inspired by ChatGPT's umber appearance. Surfaces use
/// alpha rather than fake gradients so content feels layered and translucent.
class AppColors {
  final bool isDark;

  // Page background (flat).
  final Color bg;
  final Color bgTop;
  final Color bgBottom;

  // Surfaces
  final Color card;
  final Color iconBg;
  final Color border;
  final Color pillBorder;

  // Text
  final Color textPrimary;
  final Color textSecondary;
  final Color textOnAccent;

  // Accents / misc
  final Color accent;
  final Color accentPressed;
  final Color ringTrack;
  final Color navInactive;

  // High-contrast inverse surface (primary action button).
  final Color invBg;
  final Color invText;

  const AppColors({
    required this.isDark,
    required this.bg,
    required this.bgTop,
    required this.bgBottom,
    required this.card,
    required this.iconBg,
    required this.border,
    required this.pillBorder,
    required this.textPrimary,
    required this.textSecondary,
    required this.textOnAccent,
    required this.accent,
    required this.accentPressed,
    required this.ringTrack,
    required this.navInactive,
    required this.invBg,
    required this.invText,
  });

  /// A soft, background-tinted card shadow for gentle depth.
  List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: isDark ? const Color(0x260F0808) : const Color(0x160F0808),
      blurRadius: isDark ? 20 : 16,
      offset: const Offset(0, 6),
    ),
  ];

  static const light = AppColors(
    isDark: false,
    bg: Color(0xFFF3ECE9),
    bgTop: Color(0xFFF8F3F0),
    bgBottom: Color(0xFFECE1DD),
    card: Color(0xCCFFFFFF),
    iconBg: Color(0x99FFFFFF),
    border: Color(0x24705A55),
    pillBorder: Color(0x38705A55),
    textPrimary: Color(0xFF2C2422),
    textSecondary: Color(0xFF756966),
    textOnAccent: Color(0xFFFFFFFF),
    accent: Color(0xFFB4473F),
    accentPressed: Color(0xFF91372F),
    ringTrack: Color(0x52705A55),
    navInactive: Color(0xFF8B7D79),
    invBg: Color(0xFF332927),
    invText: Color(0xFFFFFFFF),
  );

  static const dark = AppColors(
    isDark: true,
    bg: Color(0xFF573535),
    bgTop: Color(0xFF573535),
    bgBottom: Color(0xFF4F3030),
    card: Color(0xB85A3D3C),
    iconBg: Color(0x80664747),
    border: Color(0x1FFFFFFF),
    pillBorder: Color(0x33FFFFFF),
    textPrimary: Color(0xFFF8F4F2),
    textSecondary: Color(0xFFBFAEAC),
    textOnAccent: Color(0xFFFFFFFF),
    accent: Color(0xFFF0A09A),
    accentPressed: Color(0xFFD9827B),
    ringTrack: Color(0x2EFFFFFF),
    navInactive: Color(0xFFA99491),
    invBg: Color(0xFFF8F4F2),
    invText: Color(0xFF3B2928),
  );
}
