import 'package:flutter_test/flutter_test.dart';
import 'package:gymboss/domain/models/ranking/passport_lift_matcher.dart';

void main() {
  test('maps the five canonical barbell benchmarks', () {
    expect(
      passportExerciseIdForName('Barbell Bench Press - Medium Grip'),
      'bench_press',
    );
    expect(passportExerciseIdForName('Barbell Full Squat'), 'squat');
    expect(passportExerciseIdForName('Barbell Deadlift'), 'deadlift');
    expect(
      passportExerciseIdForName('Standing Military Press'),
      'overhead_press',
    );
    expect(passportExerciseIdForName('Bent Over Barbell Row'), 'barbell_row');
  });

  test('does not compare materially different exercise variants', () {
    expect(passportExerciseIdForName('Dumbbell Bench Press'), isNull);
    expect(passportExerciseIdForName('Smith Machine Bench Press'), isNull);
    expect(passportExerciseIdForName('Stiff-Legged Barbell Deadlift'), isNull);
    expect(passportExerciseIdForName('Front Squat'), isNull);
  });
}
