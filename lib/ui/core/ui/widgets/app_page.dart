import 'package:flutter/cupertino.dart';
import 'package:gymboss/ui/core/theme/theme_controller.dart';
import 'package:gymboss/ui/core/ui/widgets/app_scaffold.dart';
import 'package:gymboss/ui/core/ui/widgets/pressable.dart';

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
            padding: const EdgeInsets.fromLTRB(4, 4, 12, 8),
            child: Row(
              children: [
                Pressable(
                  onTap: () => Navigator.of(context).maybePop(),
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: Center(child: Icon(CupertinoIcons.chevron_back, size: 24, color: c.textPrimary)),
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
                // Enforce a 44x44 minimum hit area for every header action.
                for (final action in actions)
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                    child: Center(child: action),
                  ),
              ],
            ),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}
