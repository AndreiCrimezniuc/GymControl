import 'package:flutter/cupertino.dart';
import 'package:gymboss/ui/core/theme/theme_controller.dart';
import 'package:gymboss/ui/core/theme/app_design.dart';
import 'package:gymboss/ui/core/ui/widgets/app_glass_surface.dart';

/// A menu row card: a tinted icon tile, a title + subtitle, and a chevron.
class MenuCard extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const MenuCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AppGlassSurface(
        radius: AppDesign.radiusCard,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: c.iconBg,
                borderRadius: BorderRadius.circular(AppDesign.radiusSmall),
              ),
              child: Icon(icon, size: 22, color: iconColor ?? c.textSecondary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.25,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.3,
                      color: c.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_forward,
              size: 18,
              color: c.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
