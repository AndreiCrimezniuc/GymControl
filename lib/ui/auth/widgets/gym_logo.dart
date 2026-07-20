import 'package:flutter/cupertino.dart';
import 'package:gymboss/ui/core/theme/theme_controller.dart';

class GymLogo extends StatelessWidget {
  const GymLogo({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: c.border, width: 1.5),
          ),
          child: Center(
            child: SizedBox(
              width: 46,
              height: 46,
              child: CustomPaint(painter: _GymBossLogoPainter(c.accent)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              'GYM',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: c.textPrimary,
                fontFamily: 'Rubik',
                letterSpacing: 2,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'BOSS',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: c.accent,
                fontFamily: 'Rubik',
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Your fitness companion',
          style: TextStyle(
            fontSize: 14,
            color: c.textSecondary,
            fontFamily: 'Rubik',
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _GymBossLogoPainter extends CustomPainter {
  final Color color;
  const _GymBossLogoPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final center = Offset(s / 2, s / 2);

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.055;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, s * 0.43, strokePaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s * 0.13, s * 0.38, s * 0.16, s * 0.24),
        Radius.circular(s * 0.04),
      ),
      fillPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s * 0.29, s * 0.455, s * 0.42, s * 0.09),
        Radius.circular(s * 0.02),
      ),
      fillPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s * 0.71, s * 0.38, s * 0.16, s * 0.24),
        Radius.circular(s * 0.04),
      ),
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(_GymBossLogoPainter old) => old.color != color;
}
