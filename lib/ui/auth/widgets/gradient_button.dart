import 'package:flutter/cupertino.dart';
import 'package:gymboss/ui/core/ui/colors/main_gradient.dart';

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
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: loading
            ? MainGradient.darkDisabledButtonBackground
            : MainGradient.purpleBlueButtonBackground,
        child: Center(
          child: loading
              ? const CupertinoActivityIndicator(color: CupertinoColors.white)
              : Text(
                  label,
                  style: const TextStyle(
                    color: CupertinoColors.white,
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
