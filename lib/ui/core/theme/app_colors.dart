import 'package:flutter/widgets.dart';

/// Full colour palette for one theme (light or dark). Read it from context via
/// `context.colors` (see theme_controller.dart). Tuned to the "design 5" look:
/// near-white / pure-black backgrounds, a bright red accent, and a high-contrast
/// inverse surface for the primary action button. The light palette is a warm,
/// premium neutral system; the dark palette intentionally keeps its cooler,
/// instrument-like character.
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
      color: isDark ? const Color(0x66000000) : const Color(0x123A2F29),
      blurRadius: isDark ? 24 : 18,
      offset: Offset(0, isDark ? 8 : 7),
    ),
  ];

  static const light = AppColors(
    isDark: false,
    // Warm paper rather than pure white reduces glare and gives the app a
    // quieter, more premium character without sacrificing contrast.
    bg: Color(0xFFF7F4EF),
    bgTop: Color(0xFFFBF8F3),
    bgBottom: Color(0xFFF7F4EF),
    card: Color(0xFFFFFCF8),
    // Soft accent surface used for fields, icon wells and inactive controls.
    iconBg: Color(0xFFF3DDD8),
    border: Color(0xFFE4DDD4),
    pillBorder: Color(0xFFD6CCC0),
    textPrimary: Color(0xFF1B1A18),
    textSecondary: Color(0xFF706B64),
    textOnAccent: Color(0xFFFFFFFF),
    // Muted brick red: energetic enough for workout actions, sophisticated
    // enough to use across large surfaces and metrics.
    accent: Color(0xFFB64038),
    accentPressed: Color(0xFF94342E),
    ringTrack: Color(0xFFE7DED4),
    navInactive: Color(0xFFA89F96),
    invBg: Color(0xFF1B1A18),
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
