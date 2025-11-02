import 'package:flutter/cupertino.dart';

class ButtonWithDestination extends StatelessWidget {
  final Widget destionation;

  const ButtonWithDestination({super.key, required this.destionation});

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      child: const Text("Auth"),
      onPressed: () {
        Navigator.push(
          context,
          CupertinoPageRoute(builder: (context) => destionation),
        );
      },
    );
  }
}
