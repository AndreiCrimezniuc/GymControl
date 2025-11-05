import 'package:flutter/cupertino.dart';

class WeightWidget extends StatelessWidget {
  final double weight;
  final VoidCallback onTap;

  const WeightWidget({super.key, required this.weight, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            const Text("Weight (kg)", style: TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            Text(
              "${weight.toInt()}",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
