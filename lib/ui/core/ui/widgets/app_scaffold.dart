import 'package:flutter/widgets.dart';
import 'package:gymboss/ui/core/theme/theme_controller.dart';

/// Full-screen themed page background (vertical warm gradient) + SafeArea.
class AppScaffold extends StatelessWidget {
  final Widget child;
  final bool safeArea;
  const AppScaffold({super.key, required this.child, this.safeArea = true});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [c.bgTop, c.bgBottom],
        ),
      ),
      child: safeArea ? SafeArea(child: child) : child,
    );
  }
}
