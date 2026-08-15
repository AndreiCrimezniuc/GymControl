import 'package:flutter_test/flutter_test.dart';
import 'package:gymboss/domain/models/workouts/workout.dart';

void main() {
  group('Workout.fromJson', () {
    final json = {
      'id': 'w1',
      'name': 'Push Day',
      'comment': 'chest',
      'visibility': 'public',
      'owned': true,
      'share_code': 'ABC123',
      'folder_id': 'folder-1',
      'exercise_count': 2,
      'times_performed': 4,
      'love_coefficient': 0.5,
      'exercises': [
        {
          'exercise_id': 10,
          'name': 'Bench Press',
          'image_url': '/img/a.png',
          'image_url2': '/img/b.png',
          'muscle_group': 'chest',
          'rest_seconds': 120,
          'comment': 'touch chest',
          'is_optional': true,
          'alternative_group_id': '18f96d91-3b70-4528-9675-f0d7afe51cd2',
          'sets': [
            {'difficulty': 'medium', 'weight_kg': 60, 'reps': 10},
            {'difficulty': 'hard', 'weight_kg': 70, 'reps': 8},
          ],
        },
        {
          'exercise_id': 11,
          'name': 'Dips',
          'muscle_group': 'chest',
          'sets': [],
        },
      ],
    };

    test('parses scalar fields and getters', () {
      final w = Workout.fromJson(json);
      expect(w.id, 'w1');
      expect(w.name, 'Push Day');
      expect(w.isPublic, isTrue);
      expect(w.owned, isTrue);
      expect(w.timesPerformed, 4);
      expect(w.folderId, 'folder-1');
      expect(w.loveScore, 5); // 0.5 * 10
      expect(w.exercises, hasLength(2));
    });

    test('muscleGroups is de-duplicated and order-preserving', () {
      final w = Workout.fromJson(json);
      expect(w.muscleGroups, ['chest']);
    });

    test('exercise + set parsing with defaults', () {
      final w = Workout.fromJson(json);
      final ex = w.exercises.first;
      expect(ex.exerciseId, 10);
      expect(ex.restSeconds, 120);
      expect(ex.imageUrl2, '/img/b.png');
      expect(ex.isOptional, isTrue);
      expect(ex.alternativeGroupId, '18f96d91-3b70-4528-9675-f0d7afe51cd2');
      expect(ex.toJson()['is_optional'], isTrue);
      expect(ex.sets, hasLength(2));
      expect(ex.setsFor('hard'), hasLength(1));
      expect(ex.setsFor('easy'), isEmpty);
      // default rest when missing
      expect(w.exercises[1].restSeconds, 90);
    });

    test('WorkoutSet round-trips through toJson/copyWith', () {
      const s = WorkoutSet(difficulty: 'medium', weightKg: 50, reps: 12);
      final j = s.toJson();
      expect(j['weight_kg'], 50);
      final c = s.copyWith(reps: 15);
      expect(c.reps, 15);
      expect(c.difficulty, 'medium');
    });

    test('tolerates an empty payload', () {
      final w = Workout.fromJson(const {});
      expect(w.id, '');
      expect(w.exercises, isEmpty);
      expect(w.muscleGroups, isEmpty);
    });
  });

  group('performed logs', () {
    test('PerformedExerciseLog volume excludes warmups', () {
      final e = PerformedExerciseLog.fromJson({
        'exercise_id': 1,
        'name': 'Squat',
        'muscle_group': 'legs',
        'sets': [
          {'weight_kg': 100, 'reps': 5, 'set_type': 'working'},
          {'weight_kg': 40, 'reps': 10, 'set_type': 'warmup'},
          {
            'weight_kg': 90,
            'reps': 5,
            'set_type': 'failure',
            'progression': 'meo',
          },
        ],
      });
      // 100*5 + 90*5 = 950 (warmup excluded)
      expect(e.volumeKg, 950);
      expect(e.sets[2].progression, 'meo');
    });
  });

  group('WorkoutStats.fromJson', () {
    test('parses potential volume, average duration and history', () {
      final s = WorkoutStats.fromJson({
        'times_performed': 3,
        'love_coefficient': 0.8,
        'average_duration_seconds': 3720,
        'potential_volume': {'easy': 100.0, 'medium': 200.0, 'hard': 300.0},
        'history': [
          {'date': '2026-07-01', 'difficulty': 'medium'},
        ],
      });
      expect(s.timesPerformed, 3);
      expect(s.loveScore, 8);
      expect(s.potentialVolume['hard'], 300.0);
      expect(s.averageDurationSeconds, 3720);
      expect(s.history, hasLength(1));
      expect(s.history.first.difficulty, 'medium');
    });
  });

  test('WorkoutFolder parses the API payload', () {
    final folder = WorkoutFolder.fromJson({
      'id': 'folder-1',
      'name': 'Strength',
      'position': 2,
    });
    expect(folder.id, 'folder-1');
    expect(folder.name, 'Strength');
    expect(folder.position, 2);
  });
}
