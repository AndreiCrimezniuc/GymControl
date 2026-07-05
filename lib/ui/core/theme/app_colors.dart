import 'package:flutter/widgets.dart';

/// Full colour palette for one theme (light or dark). Read it from context via
/// `context.colors` (see theme_controller.dart).
class AppColors {
  final bool isDark;

  // Page background (subtle vertical gradient).
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
  });

  static const light = AppColors(
    isDark: false,
    bg: Color(0xFFFBF5F3),
    bgTop: Color(0xFFF7E9E5),
    bgBottom: Color(0xFFFDF8F6),
    card: Color(0xFFF7E7E3),
    iconBg: Color(0xFFF0D6D1),
    border: Color(0xFFEBD9D4),
    pillBorder: Color(0xFFE3CFC9),
    textPrimary: Color(0xFF1B1A1A),
    textSecondary: Color(0xFF8C8480),
    textOnAccent: Color(0xFFFFFFFF),
    accent: Color(0xFFD23B36),
    accentPressed: Color(0xFFB93330),
    ringTrack: Color(0xFFE9DAD5),
    navInactive: Color(0xFFB3A8A4),
  );

  static const dark = AppColors(
    isDark: true,
    bg: Color(0xFF120C0C),
    bgTop: Color(0xFF1A1010),
    bgBottom: Color(0xFF0C0808),
    card: Color(0xFF1C1313),
    iconBg: Color(0xFF281B1B),
    border: Color(0xFF2C1F1F),
    pillBorder: Color(0xFF3A2A2A),
    textPrimary: Color(0xFFF5EEEE),
    textSecondary: Color(0xFF988D8D),
    textOnAccent: Color(0xFFFFFFFF),
    accent: Color(0xFFD8433E),
    accentPressed: Color(0xFFB93330),
    ringTrack: Color(0xFF332525),
    navInactive: Color(0xFF6E6060),
  );
}
