import 'package:flutter/widgets.dart';
import 'package:gymboss/ui/core/theme/theme_controller.dart';

/// Full-screen ambient background + SafeArea. Offline persistence and sync are
/// intentionally invisible: user actions always operate on local data, while
/// the durable outbox retries in the background.
class AppScaffold extends StatelessWidget {
  final Widget child;
  final bool safeArea;
  const AppScaffold({super.key, required this.child, this.safeArea = true});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final content = child;
    final body = Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [c.bgTop, c.bg, c.bgBottom],
              stops: const [0, 0.48, 1],
            ),
          ),
        ),
        if (!c.isDark)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _AmbientField(lineColor: c.border, accent: c.accent),
              ),
            ),
          ),
        if (c.isDark)
          Positioned(
            top: -120,
            right: -100,
            child: IgnorePointer(
              child: Container(
                width: 310,
                height: 310,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      c.textPrimary.withValues(alpha: 0.045),
                      c.textPrimary.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        safeArea ? SafeArea(child: content) : content,
      ],
    );
    return ColoredBox(color: c.bg, child: body);
  }
}

/// A quiet gravitational-lensing field: an invisible mass bends pale paths
/// into an incomplete Einstein ring. It disappears entirely in dark mode.
class _AmbientField extends CustomPainter {
  final Color lineColor;
  final Color accent;
  const _AmbientField({required this.lineColor, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final contour = Paint()
      ..color = lineColor.withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 0.85;
    final whisper = Paint()
      ..color = lineColor.withValues(alpha: 0.07)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 0.7;
    final caustic = Paint()
      ..color = accent.withValues(alpha: 0.075)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 0.8;
    final signal = Paint()
      ..color = accent.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.45;

    // The off-screen centre remains invisible. Only the displaced light paths
    // reveal it, so the reference stays scientific rather than illustrative.
    final lensCenter = Offset(size.width * 1.06, size.height * 0.48);
    for (var i = 0; i < 4; i++) {
      canvas.drawArc(
        Rect.fromCenter(
          center: lensCenter,
          width: size.width * (1.50 + i * 0.14),
          height: size.height * (0.74 + i * 0.047),
        ),
        2.02 + i * 0.018,
        3.64 - i * 0.014,
        false,
        i == 1 ? contour : whisper,
      );
    }

    // A single dashed caustic hints at where the lens folds the light field.
    final causticPath = Path()
      ..moveTo(-size.width * 0.10, size.height * 0.60)
      ..cubicTo(
        size.width * 0.08,
        size.height * 0.72,
        size.width * 0.18,
        size.height * 0.94,
        size.width * 0.70,
        size.height * 1.04,
      );
    _drawDashedPath(canvas, causticPath, caustic);

    // One displaced cobalt fragment is the lensed signal — the only sharp
    // event in an otherwise nearly monochrome field.
    canvas.drawArc(
      Rect.fromCenter(
        center: lensCenter,
        width: size.width * 1.64,
        height: size.height * 0.787,
      ),
      4.08,
      0.20,
      false,
      signal,
    );
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + 5).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += 13;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AmbientField oldDelegate) =>
      oldDelegate.lineColor != lineColor || oldDelegate.accent != accent;
}
