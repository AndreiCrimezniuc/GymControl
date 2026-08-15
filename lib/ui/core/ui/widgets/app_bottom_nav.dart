import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gymboss/ui/core/theme/theme_controller.dart';
import 'package:gymboss/ui/core/theme/app_design.dart';

class BottomNavItem {
  final IconData icon;
  final VoidCallback? onTap;
  const BottomNavItem({required this.icon, this.onTap});
}

/// Bottom navigation bar. The active item is tinted with the accent colour and
/// placed on a floating glass dock; the rest are muted.
class AppBottomNav extends StatelessWidget {
  final List<BottomNavItem> items;
  final int activeIndex;

  const AppBottomNav({
    super.key,
    required this.items,
    required this.activeIndex,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 4, 14, 10),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(AppDesign.radiusCard),
        border: Border.all(color: c.border, width: AppDesign.hairline),
        boxShadow: c.cardShadow,
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (var i = 0; i < items.length; i++)
            _NavButton(
              icon: items[i].icon,
              active: i == activeIndex,
              accent: c.accent,
              inactive: c.navInactive,
              onTap: items[i].onTap,
            ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final bool active;
  final Color accent;
  final Color inactive;
  final VoidCallback? onTap;

  const _NavButton({
    required this.icon,
    required this.active,
    required this.accent,
    required this.inactive,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap:
          onTap == null
              ? null
              : () {
                if (!active) HapticFeedback.selectionClick();
                onTap!();
              },
      child: AnimatedContainer(
        duration: AppDesign.quick,
        width: 44,
        height: 34,
        decoration: BoxDecoration(
          color:
              active ? accent.withValues(alpha: 0.14) : const Color(0x00000000),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(icon, size: 21, color: active ? accent : inactive),
      ),
    );
  }
}
