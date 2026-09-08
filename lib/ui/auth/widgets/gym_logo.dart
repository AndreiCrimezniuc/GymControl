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
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            color: const Color(0xFF111113),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: c.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset(
            'assets/branding/gymcontrol-logo.png',
            fit: BoxFit.cover,
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
                letterSpacing: 2,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'CONTROL',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: c.accent,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'TRAIN WITH INTENT',
          style: TextStyle(
            fontSize: 14,
            color: c.textSecondary,
            letterSpacing: 2.1,
          ),
        ),
      ],
    );
  }
}
