import 'package:flutter/widgets.dart';

/// Full colour palette for one theme (light or dark). Read it from context via
/// `context.colors` (see theme_controller.dart). Tuned to the "design 5" look:
/// near-white / pure-black backgrounds, a bright red accent, and a high-contrast
/// inverse surface for the primary action button. The light palette is a cool,
/// athletic system; the dark palette intentionally keeps its instrument-like
/// character.
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
      color: isDark ? const Color(0x66000000) : const Color(0x12203B49),
      blurRadius: isDark ? 24 : 16,
      offset: Offset(0, isDark ? 8 : 7),
    ),
  ];

  static const light = AppColors(
    isDark: false,
    bg: Color(0xFFF3F6F8),
    bgTop: Color(0xFFF8FAFB),
    bgBottom: Color(0xFFF3F6F8),
    card: Color(0xFFFFFFFF),
    // Pale cyan surface used for fields, icon wells and inactive controls.
    iconBg: Color(0xFFDCEFF1),
    border: Color(0xFFD9E1E6),
    pillBorder: Color(0xFFC7D5DC),
    textPrimary: Color(0xFF172026),
    textSecondary: Color(0xFF64737D),
    textOnAccent: Color(0xFFFFFFFF),
    accent: Color(0xFF087E8B),
    accentPressed: Color(0xFF05636E),
    ringTrack: Color(0xFFDDE7EB),
    navInactive: Color(0xFF91A0A9),
    invBg: Color(0xFF172026),
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
