import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:gymboss/ui/core/theme/theme_controller.dart';
import 'package:gymboss/ui/core/ui/widgets/pressable.dart';

class WarmupSetPlan {
  final double weight;
  final int reps;
  const WarmupSetPlan(this.weight, this.reps);
}

List<WarmupSetPlan> calculateWarmupSets(
  double workingWeight, {
  double barWeight = 20,
  double increment = 2.5,
}) {
  if (workingWeight <= 0) return const [];
  final candidates = <WarmupSetPlan>[
    if (barWeight > 0 && barWeight < workingWeight)
      WarmupSetPlan(barWeight, 10),
    for (final step in const [(0.40, 8), (0.60, 5), (0.80, 3), (0.90, 1)])
      WarmupSetPlan(
        (workingWeight * step.$1 / increment).round() * increment,
        step.$2,
      ),
  ];
  final seen = <double>{};
  return candidates
      .where(
        (set) =>
            set.weight > 0 &&
            set.weight < workingWeight &&
            seen.add(set.weight),
      )
      .toList();
}

class PlateLoad {
  final Map<double, int> perSide;
  final double remainder;
  const PlateLoad(this.perSide, this.remainder);
}

PlateLoad calculatePlates(
  double totalWeight, {
  double barWeight = 20,
  List<double> plates = const [25, 20, 15, 10, 5, 2.5, 1.25],
}) {
  var side = math.max(0, (totalWeight - barWeight) / 2);
  final result = <double, int>{};
  for (final plate in plates) {
    final count = (side / plate).floor();
    if (count > 0) {
      result[plate] = count;
      side -= count * plate;
    }
  }
  return PlateLoad(result, double.parse(side.toStringAsFixed(2)));
}

Future<List<WarmupSetPlan>?> showWarmupCalculator(
  BuildContext context, {
  required double initialWeight,
}) => showCupertinoModalPopup<List<WarmupSetPlan>>(
  context: context,
  builder: (_) => _WarmupCalculator(initialWeight: initialWeight),
);

Future<void> showPlateCalculator(
  BuildContext context, {
  required double initialWeight,
}) => showCupertinoModalPopup<void>(
  context: context,
  builder: (_) => _PlateCalculator(initialWeight: initialWeight),
);

class _WarmupCalculator extends StatefulWidget {
  final double initialWeight;
  const _WarmupCalculator({required this.initialWeight});

  @override
  State<_WarmupCalculator> createState() => _WarmupCalculatorState();
}

class _WarmupCalculatorState extends State<_WarmupCalculator> {
  late final TextEditingController _weight = TextEditingController(
    text: widget.initialWeight > 0 ? '${widget.initialWeight}' : '',
  );
  final _bar = TextEditingController(text: '20');

  @override
  void dispose() {
    _weight.dispose();
    _bar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final sets = calculateWarmupSets(
      double.tryParse(_weight.text) ?? 0,
      barWeight: double.tryParse(_bar.text) ?? 20,
    );
    return _Sheet(
      title: 'Warm-up calculator',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _NumberField(
                  controller: _weight,
                  label: 'Working kg',
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _NumberField(
                  controller: _bar,
                  label: 'Bar kg',
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (final set in sets)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: c.iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Text(
                    '${set.weight.toStringAsFixed(set.weight % 1 == 0 ? 0 : 1)} kg',
                    style: TextStyle(
                      color: c.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '× ${set.reps}',
                    style: TextStyle(color: c.textSecondary),
                  ),
                ],
              ),
            ),
          Pressable(
            onTap: sets.isEmpty ? null : () => Navigator.pop(context, sets),
            child: Container(
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: sets.isEmpty ? c.iconBg : c.accent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'ADD ${sets.length} WARM-UP SETS',
                style: TextStyle(
                  color: sets.isEmpty ? c.textSecondary : c.textOnAccent,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlateCalculator extends StatefulWidget {
  final double initialWeight;
  const _PlateCalculator({required this.initialWeight});

  @override
  State<_PlateCalculator> createState() => _PlateCalculatorState();
}

class _PlateCalculatorState extends State<_PlateCalculator> {
  late final TextEditingController _weight = TextEditingController(
    text: widget.initialWeight > 0 ? '${widget.initialWeight}' : '',
  );
  final _bar = TextEditingController(text: '20');

  @override
  void dispose() {
    _weight.dispose();
    _bar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final load = calculatePlates(
      double.tryParse(_weight.text) ?? 0,
      barWeight: double.tryParse(_bar.text) ?? 20,
    );
    return _Sheet(
      title: 'Plate calculator',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _NumberField(
                  controller: _weight,
                  label: 'Total kg',
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _NumberField(
                  controller: _bar,
                  label: 'Bar kg',
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'EACH SIDE',
            style: TextStyle(color: c.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (final entry in load.perSide.entries)
                Container(
                  width: 70,
                  height: 70,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.accent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: c.accent),
                  ),
                  child: Text(
                    '${entry.key} kg\n× ${entry.value}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: c.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          if (load.remainder > 0) ...[
            const SizedBox(height: 14),
            Text(
              'Cannot load ${load.remainder} kg per side with selected plates',
              style: TextStyle(color: c.textSecondary, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _Sheet extends StatelessWidget {
  final String title;
  final Widget child;
  const _Sheet({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: c.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final ValueChanged<String> onChanged;
  const _NumberField({
    required this.controller,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => CupertinoTextField(
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    placeholder: label,
    onChanged: onChanged,
    padding: const EdgeInsets.all(13),
  );
}
