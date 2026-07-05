import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import 'package:gymboss/ui/core/theme/theme_controller.dart';

/// The circular streak indicator: a track ring with an accent progress arc,
/// a big number and a caption in the centre.
class StreakRing extends StatelessWidget {
  final int value;
  final String caption;
  final double progress; // 0..1
  final double size;
  final VoidCallback? onTap;

  const StreakRing({
    super.key,
    required this.value,
    required this.caption,
    required this.progress,
    this.size = 220,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _RingPainter(
            progress: progress.clamp(0.0, 1.0),
            track: c.ringTrack,
            accent: c.accent,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$value',
                  style: TextStyle(
                    fontFamily: 'Rubik',
                    fontSize: size * 0.29,
                    fontWeight: FontWeight.w700,
                    height: 1,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  caption.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'Rubik',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.5,
                    color: c.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color track;
  final Color accent;

  _RingPainter({required this.progress, required this.track, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 6.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - stroke) / 2;

    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0) {
      final arcPaint = Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        arcPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.track != track || old.accent != accent;
}
