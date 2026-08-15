import 'package:flutter_test/flutter_test.dart';
import 'package:gymboss/domain/models/exercises/exercise_catalog.dart';
import 'package:gymboss/domain/models/exercises/exercise_catalog_policy.dart';

void main() {
  ExerciseCatalogItem exercise(String name, {String category = 'strength'}) =>
      ExerciseCatalogItem(
        id: name.hashCode,
        name: name,
        muscleGroup: 'Chest',
        equipment: 'barbell',
        category: category,
        level: 'beginner',
        force: 'push',
        imageUrl: '',
        imageUrl2: '',
        instructions: '',
      );

  test('curated catalog keeps common movements and removes rare variants', () {
    final result = ExerciseCatalogPolicy.curate([
      exercise('Dumbbell Bench Press'),
      exercise('Bench Press with Chains'),
      exercise('Cable Judo Flip'),
    ]);

    expect(result.map((item) => item.name), ['Dumbbell Bench Press']);
  });

  test('custom exercises are never hidden by default curation', () {
    expect(
      ExerciseCatalogPolicy.isVisible(
        exercise('My unusual rehab drill', category: 'custom'),
      ),
      isTrue,
    );
  });
}
