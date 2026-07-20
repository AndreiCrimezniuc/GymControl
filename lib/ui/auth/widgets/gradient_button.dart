import 'package:flutter/cupertino.dart';
import 'package:gymboss/ui/core/theme/theme_controller.dart';

class GradientButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onTap;

  const GradientButton({
    super.key,
    required this.label,
    this.loading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: loading ? c.iconBg : c.accent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: loading
              ? const CupertinoActivityIndicator(color: CupertinoColors.white)
              : Text(
                  label,
                  style: TextStyle(
                    color: c.textOnAccent,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Rubik',
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ),
    );
  }
}
