import 'package:flutter/widgets.dart';

/// Full colour palette for one theme (light or dark). Read it from context via
/// `context.colors` (see theme_controller.dart). Tuned to the "design 5" look:
/// near-white / pure-black backgrounds, a bright red accent, and a high-contrast
/// inverse surface for the primary action button.
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

  static const light = AppColors(
    isDark: false,
    bg: Color(0xFFFCFAF8),
    bgTop: Color(0xFFFCFAF8),
    bgBottom: Color(0xFFFCFAF8),
    card: Color(0xFFF4EFEC),
    iconBg: Color(0xFFF0E7E4),
    // Borders tinted toward the accent so surfaces read as defined contours in
    // the light theme instead of washing out against the warm background.
    border: Color(0xFFEBD5D0),
    pillBorder: Color(0xFFE4C7C1),
    textPrimary: Color(0xFF141312),
    // Darkened from #8B8480 (~3.5:1) to meet WCAG AA 4.5:1 for small text on bg/card.
    textSecondary: Color(0xFF736C67),
    textOnAccent: Color(0xFFFFFFFF),
    accent: Color(0xFFDE3B34),
    accentPressed: Color(0xFFC2332D),
    ringTrack: Color(0xFFEAE0DB),
    navInactive: Color(0xFFB0A6A2),
    invBg: Color(0xFF121212),
    invText: Color(0xFFFFFFFF),
  );

  static const dark = AppColors(
    isDark: true,
    bg: Color(0xFF0B0A0A),
    bgTop: Color(0xFF0B0A0A),
    bgBottom: Color(0xFF0B0A0A),
    card: Color(0xFF171111),
    iconBg: Color(0xFF221818),
    border: Color(0xFF241B1B),
    pillBorder: Color(0xFF332626),
    textPrimary: Color(0xFFF3EEEE),
    textSecondary: Color(0xFF8E8383),
    textOnAccent: Color(0xFFFFFFFF),
    accent: Color(0xFFE0413A),
    accentPressed: Color(0xFFC2332D),
    ringTrack: Color(0xFF2A2020),
    navInactive: Color(0xFF6A5E5E),
    invBg: Color(0xFFF2ECE8),
    invText: Color(0xFF121212),
  );
}
