import 'package:flutter/cupertino.dart';
import 'package:gymboss/ui/core/theme/theme_controller.dart';
import 'package:gymboss/ui/core/ui/widgets/pressable.dart';

class GoogleIcon extends StatelessWidget {
  const GoogleIcon({super.key});
  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _GoogleLogoPainter());
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    final segments = [
      (0.0, 1.0472, const Color(0xFF4285F4)),
      (1.0472, 2.0944, const Color(0xFF34A853)),
      (2.0944, 4.1888, const Color(0xFFFBBC05)),
      (4.1888, 6.2832, const Color(0xFFEA4335)),
    ];
    for (final (start, end, color) in segments) {
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.2
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.75),
        start - 1.5708,
        end - start,
        false,
        paint,
      );
    }
    final gPaint = Paint()..color = const Color(0xFF4285F4);
    canvas.drawRect(
      Rect.fromLTWH(cx, cy - r * 0.18, r * 0.85, r * 0.36),
      gPaint,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

class SocialButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final VoidCallback? onTap;
  final bool loading;

  const SocialButton({
    super.key,
    required this.label,
    required this.icon,
    this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      semanticLabel: label,
      onTap: loading ? null : onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: c.iconBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.border, width: 1),
        ),
        child: loading
            ? const Center(child: CupertinoActivityIndicator())
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(width: 22, height: 22, child: icon),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary,
                      fontFamily: 'Rubik',
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
