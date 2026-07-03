import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:gymboss/ui/core/ui/colors/main_gradient.dart';

class GymLogo extends StatelessWidget {
  const GymLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: const Color(0xFF0D1F2D),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF1E3A50), width: 1.5),
            boxShadow: [MainGradient.blueShadow],
          ),
          child: const Center(
            child: SizedBox(
              width: 46,
              height: 46,
              child: CustomPaint(painter: _GymBossLogoPainter()),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            const Text(
              'GYM',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0D1F2D),
                fontFamily: 'Rubik',
                letterSpacing: 2,
              ),
            ),
            const SizedBox(width: 4),
            ShaderMask(
              shaderCallback: (bounds) =>
                  MainGradient.purpleBlueGradient.createShader(bounds),
              child: const Text(
                'BOSS',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  fontFamily: 'Rubik',
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Your fitness companion',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF546A7B),
            fontFamily: 'Rubik',
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _GymBossLogoPainter extends CustomPainter {
  const _GymBossLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const color = Color(0xFF06B6D4);
    final s = size.width;
    final center = Offset(s / 2, s / 2);

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.055;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Outer control ring
    canvas.drawCircle(center, s * 0.43, strokePaint);

    // Left weight plate
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s * 0.13, s * 0.38, s * 0.16, s * 0.24),
        Radius.circular(s * 0.04),
      ),
      fillPaint,
    );

    // Bar
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s * 0.29, s * 0.455, s * 0.42, s * 0.09),
        Radius.circular(s * 0.02),
      ),
      fillPaint,
    );

    // Right weight plate
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s * 0.71, s * 0.38, s * 0.16, s * 0.24),
        Radius.circular(s * 0.04),
      ),
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(_GymBossLogoPainter old) => false;
}
