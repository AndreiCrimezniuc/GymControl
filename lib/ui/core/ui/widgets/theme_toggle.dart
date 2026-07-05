import 'package:flutter/cupertino.dart';
import 'package:gymboss/ui/core/theme/theme_controller.dart';

/// Small moon/sun button that toggles the app theme. Shows the icon of the
/// mode you'll switch *to* (moon in light mode, sun in dark mode).
class ThemeToggle extends StatelessWidget {
  const ThemeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.themeController.toggle(),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: c.border),
        ),
        child: Icon(
          c.isDark ? CupertinoIcons.sun_max_fill : CupertinoIcons.moon_fill,
          size: 18,
          color: c.isDark ? const Color(0xFFF5C451) : c.textSecondary,
        ),
      ),
    );
  }
}
