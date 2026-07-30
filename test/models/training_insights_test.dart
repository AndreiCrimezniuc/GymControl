import 'package:flutter_test/flutter_test.dart';
import 'package:gymboss/domain/models/exercises/exercise_catalog.dart';
import 'package:gymboss/domain/models/measurements/body_measurement.dart';
import 'package:gymboss/domain/models/workouts/workout.dart';

void main() {
  test('planned set preserves its programming type', () {
    final set = WorkoutSet.fromJson({
      'difficulty': 'medium',
      'weight_kg': 42.5,
      'reps': 12,
      'set_type': 'dropset',
    });

    expect(set.setType, 'dropset');
    expect(set.toJson()['set_type'], 'dropset');
    expect(set.copyWith(setType: 'warmup').setType, 'warmup');
  });

  test(
    'exercise insights parse records, history metadata and richer catalog',
    () {
      final catalog = ExerciseCatalogItem.fromJson({
        'id': 5,
        'name': 'Cable row',
        'exercise_type': 'weight_reps',
        'secondary_muscles': ['Biceps', 'Rear Delts'],
      });
      final stats = ExerciseStats.fromJson({
        'exercise_id': 5,
        'total_sets': 1,
        'estimated_one_rm_kg': 120,
        'max_set_volume_kg': 600,
        'records': [
          {
            'type': 'estimated_1rm',
            'date': '2026-07-30',
            'weight_kg': 100,
            'reps': 6,
            'value': 120,
          },
        ],
      });
      final history = ExerciseHistorySession.fromJson({
        'date': '2026-07-30',
        'workout_name': 'Pull',
        'sets': [
          {'weight_kg': 100, 'reps': 6, 'set_type': 'working'},
        ],
      });

      expect(catalog.secondaryMuscles, ['Biceps', 'Rear Delts']);
      expect(stats.estimatedOneRmKg, 120);
      expect(stats.records.single.type, 'estimated_1rm');
      expect(history.workoutName, 'Pull');
      expect(history.sets.single.reps, 6);
    },
  );

  test('activity and body measurement contracts tolerate partial data', () {
    final point = ActivityPoint.fromJson({
      'date': '2026-07-30',
      'duration_seconds': 3600,
      'reps': 125,
      'workouts': 1,
    });
    final measurement = BodyMeasurement.fromJson({
      'id': 'm1',
      'measured_at': '2026-07-30',
      'weight_kg': 82.4,
      'waist_cm': 81,
    });

    expect(point.durationSeconds, 3600);
    expect(point.reps, 125);
    expect(measurement.weightKg, 82.4);
    expect(measurement.bodyFatPercent, isNull);
    expect(measurement.toJson()['waist_cm'], 81);
  });
}
