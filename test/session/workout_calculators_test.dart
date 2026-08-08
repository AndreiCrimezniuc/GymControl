import 'package:flutter_test/flutter_test.dart';
import 'package:gymboss/ui/menu_options_list/workouts/session/workout_calculators.dart';

void main() {
  test(
    'warm-up calculator creates increasing unique sets below working load',
    () {
      final sets = calculateWarmupSets(100);
      expect(sets.map((set) => set.weight), [20, 40, 60, 80, 90]);
      expect(sets.map((set) => set.reps), [10, 8, 5, 3, 1]);
    },
  );

  test('plate calculator returns plates for each side', () {
    final load = calculatePlates(100);
    expect(load.perSide, {25: 1, 15: 1});
    expect(load.remainder, 0);
  });

  test('plate calculator exposes unloadable remainder', () {
    final load = calculatePlates(23);
    expect(load.perSide, {1.25: 1});
    expect(load.remainder, 0.25);
  });
}
