import 'package:flutter_test/flutter_test.dart';
import 'package:gymboss/domain/models/workouts/workout.dart';

void main() {
  group('StatsSummary.fromJson', () {
    test('parses a full payload', () {
      final s = StatsSummary.fromJson({
        'total_workouts': 12,
        'longest_workout_seconds': 3600,
        'favorite_exercise': 'Bench Press',
        'strongest_exercise': 'Deadlift',
        'workouts_per_month': [
          {'month': '2026-06', 'count': 5},
          {'month': '2026-07', 'count': 7},
        ],
      });
      expect(s.totalWorkouts, 12);
      expect(s.longestWorkoutSeconds, 3600);
      expect(s.favoriteExercise, 'Bench Press');
      expect(s.strongestExercise, 'Deadlift');
      expect(s.workoutsPerMonth, hasLength(2));
      expect(s.workoutsPerMonth[1].month, '2026-07');
      expect(s.workoutsPerMonth[1].count, 7);
    });

    test('tolerates missing/empty fields', () {
      final s = StatsSummary.fromJson(const {});
      expect(s.totalWorkouts, 0);
      expect(s.favoriteExercise, '');
      expect(s.workoutsPerMonth, isEmpty);
    });

    test('empty constant is zeroed', () {
      expect(StatsSummary.empty.totalWorkouts, 0);
      expect(StatsSummary.empty.workoutsPerMonth, isEmpty);
    });
  });
}
