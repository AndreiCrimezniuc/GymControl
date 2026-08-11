import 'package:flutter/widgets.dart';

/// Full colour palette for one theme (light or dark). Read it from context via
/// `context.colors` (see theme_controller.dart). The light palette uses a
/// graphite neutral scale with a restrained signal-red accent. The dark palette
/// intentionally keeps its existing instrument-like character.
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
      color: isDark ? const Color(0x66000000) : const Color(0x1419191B),
      blurRadius: isDark ? 24 : 16,
      offset: Offset(0, isDark ? 8 : 7),
    ),
  ];

  static const light = AppColors(
    isDark: false,
    bg: Color(0xFFF5F5F3),
    bgTop: Color(0xFFFAFAF8),
    bgBottom: Color(0xFFF2F2EF),
    card: Color(0xFFFFFFFF),
    iconBg: Color(0xFFECECEA),
    border: Color(0xFFDCDCD8),
    pillBorder: Color(0xFFD2D2CE),
    textPrimary: Color(0xFF19191B),
    textSecondary: Color(0xFF6D6D72),
    textOnAccent: Color(0xFFFFFFFF),
    accent: Color(0xFFC83C36),
    accentPressed: Color(0xFFA42E29),
    ringTrack: Color(0xFFE3E3DF),
    navInactive: Color(0xFF8A8A8F),
    invBg: Color(0xFF19191B),
    invText: Color(0xFFFFFFFF),
  );

  static const dark = AppColors(
    isDark: true,
    // Cooler, flatter neutrals (dropped the brown cast) so dark surfaces read
    // as engineered rather than warm — a more grown-up, "instrument" feel.
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
    accentPressed: Color(0xFFA82A24),
    ringTrack: Color(0xFF26262B),
    navInactive: Color(0xFF6A6A73),
    invBg: Color(0xFFEDEDEF),
    invText: Color(0xFF121212),
  );
}
