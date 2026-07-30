import 'package:flutter_test/flutter_test.dart';
import 'package:gymboss/domain/models/exercises/exercise_catalog.dart';

void main() {
  const dips = ExerciseCatalogItem(
    id: 171,
    name: 'Parallel Bar Dips',
    muscleGroup: 'Arms',
    equipment: 'Bodyweight',
    category: 'strength',
    level: 'beginner',
    force: 'push',
    imageUrl: '',
    imageUrl2: '',
    instructions: '',
    aliases: ['dips', 'deeps', 'брусья', 'отжимания на брусьях'],
  );

  test('exercise search matches canonical name and aliases', () {
    expect(dips.matchesSearch('parallel'), isTrue);
    expect(dips.matchesSearch('deeps'), isTrue);
    expect(dips.matchesSearch('БРУСЬЯ'), isTrue);
    expect(dips.matchesSearch('bench press'), isFalse);
  });
}
