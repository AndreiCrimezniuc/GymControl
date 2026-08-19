import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:gymboss/ui/core/theme/app_design.dart';
import 'package:gymboss/ui/core/theme/theme_controller.dart';
import 'package:gymboss/ui/core/ui/widgets/pressable.dart';

/// A restrained frosted surface: translucent fill, hairline border and the
/// shallow shadow used by ChatGPT's floating panels.
class AppGlassSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final Color? color;
  final bool blur;
  final VoidCallback? onTap;

  const AppGlassSurface({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.radius = AppDesign.radiusCard,
    this.color,
    this.blur = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final highContrast = MediaQuery.maybeOf(context)?.highContrast ?? false;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final fill = color ?? colors.card;
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: highContrast ? fill.withValues(alpha: 1) : fill,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: colors.border, width: AppDesign.hairline),
        boxShadow: colors.cardShadow,
      ),
      child: child,
    );
    final clipped = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child:
          blur && !highContrast
              ? BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: AppDesign.glassBlur,
                  sigmaY: AppDesign.glassBlur,
                ),
                child: content,
              )
              : content,
    );
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child:
          onTap == null
              ? clipped
              : Pressable(
                onTap: onTap,
                scale: reduceMotion ? 1 : 0.985,
                child: clipped,
              ),
    );
  }
}
