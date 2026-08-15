import 'package:flutter/widgets.dart';
import 'package:gymboss/ui/core/theme/theme_controller.dart';
import 'package:gymboss/ui/core/theme/app_design.dart';

/// A rounded pill button — filled (accent) or outlined — with an uppercase,
/// letter-spaced label. Used for the START / PROGRAM / STATS row.
class PillButton extends StatelessWidget {
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const PillButton({
    super.key,
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? c.accent : const Color(0x00000000),
          borderRadius: BorderRadius.circular(AppDesign.radiusControl),
          border:
              filled
                  ? null
                  : Border.all(color: c.pillBorder, width: AppDesign.hairline),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
            color: filled ? c.textOnAccent : c.textPrimary,
          ),
        ),
      ),
    );
  }
}
