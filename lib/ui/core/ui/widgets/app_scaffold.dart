import 'package:flutter/widgets.dart';
import 'package:gymboss/ui/core/theme/theme_controller.dart';
import 'package:gymboss/ui/core/ui/widgets/offline_banner.dart';

/// Full-screen ambient background + SafeArea, with
/// an app-wide offline/pending-sync status strip above the content.
class AppScaffold extends StatelessWidget {
  final Widget child;
  final bool safeArea;
  const AppScaffold({super.key, required this.child, this.safeArea = true});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // The banner is zero-height when online and synced, so it never shifts
    // layout in the happy path; when shown it sits just under the safe-area top.
    final content = Column(
      children: [const OfflineBanner(), Expanded(child: child)],
    );
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
                    c.textPrimary.withValues(
                      alpha: c.usesLightForeground ? 0.045 : 0.16,
                    ),
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
