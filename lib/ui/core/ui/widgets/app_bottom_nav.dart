import 'package:flutter/material.dart';
import 'package:gymboss/ui/core/theme/theme_controller.dart';

class BottomNavItem {
  final IconData icon;
  final VoidCallback? onTap;
  const BottomNavItem({required this.icon, this.onTap});
}

/// Bottom navigation bar. The active item is tinted with the accent colour and
/// underlined; the rest are muted.
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
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.border)),
      ),
      padding: const EdgeInsets.only(top: 10, bottom: 8),
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
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24, color: active ? accent : inactive),
          const SizedBox(height: 5),
          Container(
            width: 18,
            height: 2,
            decoration: BoxDecoration(
              color: active ? accent : const Color(0x00000000),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }
}
