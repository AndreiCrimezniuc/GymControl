import 'package:flutter/cupertino.dart';

class Exercises extends StatefulWidget {
  const Exercises({super.key});

  @override
  State<StatefulWidget> createState() => _ExercisesState();
}

class _ExercisesState extends State<Exercises> {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: const Text("Exercises")),
      child: const Text("Exercises Section"),
    );
  }
}
