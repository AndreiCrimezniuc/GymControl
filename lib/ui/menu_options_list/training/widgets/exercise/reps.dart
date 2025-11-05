import "package:flutter/cupertino.dart";

class RepsWidget extends StatelessWidget {
  final int reps;
  final VoidCallback onTap;

  const RepsWidget({super.key, required this.reps, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            const Text("Reps", style: TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            Text(
              "$reps",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
