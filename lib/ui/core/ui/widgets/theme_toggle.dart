import 'package:flutter/cupertino.dart';
import 'package:gymboss/ui/core/theme/theme_controller.dart';
import 'package:gymboss/ui/core/theme/app_design.dart';
import 'package:gymboss/ui/core/ui/widgets/pressable.dart';

/// Small moon/sun button that toggles the app theme. Shows the icon of the
/// mode you'll switch *to* (moon in light mode, sun in dark mode).
class ThemeToggle extends StatelessWidget {
  const ThemeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      semanticLabel: c.isDark ? 'Use light appearance' : 'Use dark appearance',
      haptic: true,
      onTap: () => context.themeController.toggle(),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.border, width: AppDesign.hairline),
          boxShadow: c.cardShadow,
        ),
        child: Icon(
          c.isDark ? CupertinoIcons.sun_max_fill : CupertinoIcons.moon_fill,
          size: 18,
          color: c.textSecondary,
        ),
      ),
    );
  }
}
