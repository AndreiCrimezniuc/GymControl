import 'package:flutter/widgets.dart';
import 'package:gymboss/ui/core/theme/theme_controller.dart';
import 'package:gymboss/ui/core/ui/widgets/offline_banner.dart';

/// Full-screen themed page background (vertical warm gradient) + SafeArea, with
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
      children: [
        const OfflineBanner(),
        Expanded(child: child),
      ],
    );
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [c.bgTop, c.bgBottom],
        ),
      ),
      child: safeArea ? SafeArea(child: content) : content,
    );
  }
}
