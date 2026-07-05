import 'package:flutter/cupertino.dart';
import 'package:gymboss/ui/core/theme/theme_controller.dart';
import 'package:gymboss/ui/core/ui/widgets/app_scaffold.dart';

/// A themed inner page: warm gradient background, a header row with a back
/// button + title (and optional trailing actions), and a body that fills the
/// remaining space. The body supplies its own scrolling.
class AppPage extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget> actions;

  const AppPage({
    super.key,
    required this.title,
    required this.body,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 16, 8),
            child: Row(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).maybePop(),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(CupertinoIcons.chevron_back,
                        size: 24, color: c.textPrimary),
                  ),
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Rubik',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: c.textPrimary,
                    ),
                  ),
                ),
                ...actions,
              ],
            ),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}
