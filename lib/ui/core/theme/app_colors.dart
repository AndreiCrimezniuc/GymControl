import 'package:flutter/widgets.dart';

/// Full colour palette for one theme (light or dark). Read it from context via
/// `context.colors` (see theme_controller.dart). The light palette uses a
/// umber appearance. Surfaces use alpha rather than fake gradients so content
/// feels layered and translucent.
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
  final Color accentSecondary;
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
    required this.accentSecondary,
    required this.accentPressed,
    required this.ringTrack,
    required this.navInactive,
    required this.invBg,
    required this.invText,
  });

  /// Whether system chrome and artwork need light foreground content.
  ///
  /// Theme selection and canvas luminance are deliberately separate: the
  /// optional "light" appearance is the low-luminance umber treatment.
  bool get usesLightForeground => bg.computeLuminance() < 0.45;

  /// A soft, background-tinted card shadow for gentle depth.
  List<BoxShadow> get cardShadow => [
    BoxShadow(
      color:
          usesLightForeground
              ? const Color(0x260F0808)
              : const Color(0x160F0808),
      blurRadius: usesLightForeground ? 20 : 16,
      offset: const Offset(0, 6),
    ),
  ];

  static const light = AppColors(
    isDark: false,
    bg: Color(0xFF573535),
    bgTop: Color(0xFF573535),
    bgBottom: Color(0xFF4F3030),
    card: Color(0xDE664747),
    iconBg: Color(0xB8705050),
    border: Color(0x33FFFFFF),
    pillBorder: Color(0x4AFFFFFF),
    textPrimary: Color(0xFFF8F4F2),
    textSecondary: Color(0xFFD2C2BF),
    textOnAccent: Color(0xFFFFFFFF),
    accent: Color(0xFFF15B57),
    accentSecondary: Color(0xFFFFB4AE),
    accentPressed: Color(0xFFD94340),
    ringTrack: Color(0x42FFFFFF),
    navInactive: Color(0xFFC0ADAA),
    invBg: Color(0xFFF8F4F2),
    invText: Color(0xFF3B2928),
  );

  static const dark = AppColors(
    isDark: true,
    bg: Color(0xFF0A0A0B),
    bgTop: Color(0xFF0A0A0B),
    bgBottom: Color(0xFF0A0A0B),
    card: Color(0xFF141416),
    iconBg: Color(0xFF1C1C20),
    border: Color(0xFF232327),
    pillBorder: Color(0xFF33333A),
    textPrimary: Color(0xFFEDEDEF),
    textSecondary: Color(0xFF8A8A93),
    textOnAccent: Color(0xFFFFFFFF),
    accent: Color(0xFFCE3630),
    accentSecondary: Color(0xFFF08A84),
    accentPressed: Color(0xFFA82A24),
    ringTrack: Color(0xFF26262B),
    navInactive: Color(0xFF6A6A73),
    invBg: Color(0xFFEDEDEF),
    invText: Color(0xFF121212),
  );
}
