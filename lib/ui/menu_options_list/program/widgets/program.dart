import 'package:flutter/cupertino.dart';

class Program extends StatefulWidget {
  const Program({super.key});

  @override
  State<StatefulWidget> createState() => _ProgramState();
}

class _ProgramState extends State<Program> {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: const Text("Program")),
      child: const Center(
        child: Text(
          "Program Section",
          style: TextStyle(color: CupertinoColors.systemRed),
        ),
      ),
    );
  }
}
