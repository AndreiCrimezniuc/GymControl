import 'package:flutter/widgets.dart';
import 'package:gymboss/ui/core/theme/theme_controller.dart';

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
          borderRadius: BorderRadius.circular(27),
          border: filled ? null : Border.all(color: c.pillBorder, width: 1.5),
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            fontFamily: 'Rubik',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: filled ? c.textOnAccent : c.textPrimary,
          ),
        ),
      ),
    );
  }
}
