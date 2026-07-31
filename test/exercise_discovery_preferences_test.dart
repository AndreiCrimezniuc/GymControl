import 'package:flutter_test/flutter_test.dart';
import 'package:gymboss/ui/menu_options_list/exercises/exercise_discovery_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late ExerciseDiscoveryPreferences preferences;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    preferences = ExerciseDiscoveryPreferences();
  });

  test('recent exercises are deduplicated and move to the front', () async {
    await preferences.recordRecent(1);
    await preferences.recordRecent(2);
    await preferences.recordRecent(1);

    expect(await preferences.recentIds(), [1, 2]);
  });

  test('favorite exercises can be added and removed', () async {
    expect(await preferences.toggleFavorite(7), {7});
    expect(await preferences.favoriteIds(), {7});
    expect(await preferences.toggleFavorite(7), isEmpty);
    expect(await preferences.favoriteIds(), isEmpty);
  });

  test('recent exercise history is bounded', () async {
    for (var id = 0; id <= ExerciseDiscoveryPreferences.recentLimit; id++) {
      await preferences.recordRecent(id);
    }

    final ids = await preferences.recentIds();
    expect(ids, hasLength(ExerciseDiscoveryPreferences.recentLimit));
    expect(ids.first, ExerciseDiscoveryPreferences.recentLimit);
    expect(ids, isNot(contains(0)));
  });
}
