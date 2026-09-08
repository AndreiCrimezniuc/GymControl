import 'package:flutter/widgets.dart';

enum AppAccent { blue, red, purple, green }

extension AppAccentColors on AppAccent {
  Color color({required bool isDark}) => switch ((this, isDark)) {
    (AppAccent.blue, false) => const Color(0xFF3156D9),
    (AppAccent.blue, true) => const Color(0xFF4161C8),
    (AppAccent.red, false) => const Color(0xFFB83B36),
    (AppAccent.red, true) => const Color(0xFFCE3630),
    (AppAccent.purple, false) => const Color(0xFF6946BD),
    (AppAccent.purple, true) => const Color(0xFF7546C7),
    (AppAccent.green, false) => const Color(0xFF19724B),
    (AppAccent.green, true) => const Color(0xFF217A52),
  };

  Color pressedColor({required bool isDark}) => switch ((this, isDark)) {
    (AppAccent.blue, false) => const Color(0xFF2444B7),
    (AppAccent.blue, true) => const Color(0xFF3450AA),
    (AppAccent.red, false) => const Color(0xFF962E2A),
    (AppAccent.red, true) => const Color(0xFFA82A24),
    (AppAccent.purple, false) => const Color(0xFF53349D),
    (AppAccent.purple, true) => const Color(0xFF5F35A8),
    (AppAccent.green, false) => const Color(0xFF115C3B),
    (AppAccent.green, true) => const Color(0xFF176441),
  };

  Color secondaryColor({required bool isDark}) => switch ((this, isDark)) {
    (AppAccent.blue, false) => const Color(0xFF3E566F),
    (AppAccent.blue, true) => const Color(0xFF91A7F4),
    (AppAccent.red, false) => const Color(0xFF72504F),
    (AppAccent.red, true) => const Color(0xFFF08A84),
    (AppAccent.purple, false) => const Color(0xFF625674),
    (AppAccent.purple, true) => const Color(0xFFB99BEF),
    (AppAccent.green, false) => const Color(0xFF45665A),
    (AppAccent.green, true) => const Color(0xFF76C69C),
  };
}

/// Full colour palette for one theme (light or dark). Read it from context via
/// `context.colors` (see theme_controller.dart). The light palette uses a
/// architectural neutral appearance. Surfaces use restrained transparency and
/// a precise selectable signal colour: strict enough for training data, but
/// with a subtle near-future edge.
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

  AppColors withAccent(AppAccent selected) => AppColors(
    isDark: isDark,
    bg: bg,
    bgTop: bgTop,
    bgBottom: bgBottom,
    card: card,
    iconBg: iconBg,
    border: border,
    pillBorder: pillBorder,
    textPrimary: textPrimary,
    textSecondary: textSecondary,
    textOnAccent: textOnAccent,
    accent: selected.color(isDark: isDark),
    accentSecondary: selected.secondaryColor(isDark: isDark),
    accentPressed: selected.pressedColor(isDark: isDark),
    ringTrack: ringTrack,
    navInactive: navInactive,
    invBg: invBg,
    invText: invText,
  );

  /// Whether system chrome and artwork need light foreground content.
  ///
  /// Theme selection and canvas luminance are deliberately separate: the
  /// light appearance is a cool architectural canvas with restrained cobalt.
  bool get usesLightForeground => bg.computeLuminance() < 0.45;

  /// A soft, background-tinted card shadow for gentle depth.
  List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: usesLightForeground
          ? const Color(0x260F0808)
          : const Color(0x1F211B19),
      blurRadius: usesLightForeground ? 20 : 18,
      offset: const Offset(0, 6),
    ),
  ];

  static const light = AppColors(
    isDark: false,
    bg: Color(0xFFF1F3F5),
    bgTop: Color(0xFFFCFCF9),
    bgBottom: Color(0xFFE5EAF1),
    card: Color(0xF7FFFFFF),
    iconBg: Color(0xFFE7EBF0),
    border: Color(0x3D243246),
    pillBorder: Color(0x52243246),
    textPrimary: Color(0xFF111820),
    textSecondary: Color(0xFF526071),
    textOnAccent: Color(0xFFFFFFFF),
    accent: Color(0xFFB83B36),
    accentSecondary: Color(0xFF72504F),
    accentPressed: Color(0xFF962E2A),
    ringTrack: Color(0x30243246),
    navInactive: Color(0xFF697585),
    invBg: Color(0xFF121A24),
    invText: Color(0xFFFFFFFF),
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
