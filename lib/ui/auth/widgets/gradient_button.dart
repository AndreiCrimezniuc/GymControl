import 'package:flutter/cupertino.dart';
import 'package:gymboss/ui/core/theme/theme_controller.dart';
import 'package:gymboss/ui/core/theme/app_design.dart';
import 'package:gymboss/ui/core/ui/widgets/pressable.dart';

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
    return Pressable(
      semanticLabel: label,
      onTap: loading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: loading ? c.iconBg : c.invBg,
          borderRadius: BorderRadius.circular(AppDesign.radiusControl),
          boxShadow: loading ? null : c.cardShadow,
        ),
        child: Center(
          child:
              loading
                  ? const CupertinoActivityIndicator(
                    color: CupertinoColors.white,
                  )
                  : Text(
                    label,
                    style: TextStyle(
                      color: c.invText,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
        ),
      ),
    );
  }
}
