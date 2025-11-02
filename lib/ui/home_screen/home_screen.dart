import "package:flutter/cupertino.dart";
import "package:gymboss/ui/core/ui/button/simple_button.dart";
import "package:gymboss/ui/menu_options/widgets/menu_options.dart";

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text("Gym Boss")),
      backgroundColor: theme.scaffoldBackgroundColor,
      child: Center(child: ButtonWithDestination(destionation: MenuOptions())),
    );
  }
}
