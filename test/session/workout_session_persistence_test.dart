import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gymboss/data/repositories/exercises_repository.dart';
import 'package:gymboss/data/repositories/ranking_repository.dart';
import 'package:gymboss/data/repositories/sessions_repository.dart';
import 'package:gymboss/data/repositories/workouts_repository.dart';
import 'package:gymboss/data/services/auth/auth_service.dart';
import 'package:gymboss/data/services/auth/authenticated_client.dart';
import 'package:gymboss/data/services/auth/token_storage.dart';
import 'package:gymboss/domain/models/workouts/workout.dart';
import 'package:gymboss/ui/core/units/units_controller.dart';
import 'package:gymboss/ui/menu_options_list/workouts/session/workout_session_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('active workout survives a controller restart', () async {
    SharedPreferences.setMockInitialValues({});
    final httpClient = MockClient((request) async {
      if (request.url.path.endsWith('/stats')) {
        return http.Response('{"max_weight_kg":100}', 200);
      }
      if (request.url.path.endsWith('/history')) {
        return http.Response('[]', 200);
      }
      return http.Response('{}', 200);
    });
    final client = AuthenticatedClient(
      storage: TokenStorage(),
      authService: AuthService(),
      inner: httpClient,
    );
    final exercises = ExercisesRepository(
      client: client,
      isOnline: () async => true,
    );
    final workouts = WorkoutsRepository(
      client: client,
      isOnline: () async => true,
    );
    final sessions = SessionsRepository(
      client: client,
      isOnline: () async => true,
    );
    final ranking = RankingRepository(
      client: client,
      isOnline: () async => true,
    );
    final units = UnitsController();
    final workout = Workout(
      id: 'workout-1',
      name: 'Push',
      comment: '',
      visibility: 'private',
      owned: true,
      shareCode: '',
      exerciseCount: 1,
      timesPerformed: 0,
      exercises: const [
        WorkoutExercise(
          exerciseId: 7,
          name: 'Bench Press',
          imageUrl: '',
          muscleGroup: 'Chest',
          restSeconds: 90,
          comment: '',
          plannedRepMin: 3,
          plannedRepMax: 8,
          sets: [WorkoutSet(difficulty: 'medium', weightKg: 80, reps: 5)],
        ),
      ],
    );

    final original = WorkoutSessionController();
    original.start(
      workout: workout,
      difficulty: 'normal',
      exercises: exercises,
      ranking: ranking,
      sessions: sessions,
      workouts: workouts,
      units: units,
    );
    final set = original.groups.single.sets.single;
    set.weight = '82.5';
    original.toggleSet(set);
    original.minimize();
    await Future<void>.delayed(const Duration(milliseconds: 400));
    original.dispose();

    final restored = WorkoutSessionController();
    expect(
      await restored.restore(
        exercises: exercises,
        ranking: ranking,
        sessions: sessions,
        workouts: workouts,
        units: units,
      ),
      isTrue,
    );
    expect(restored.workout?.id, 'workout-1');
    expect(restored.groups.single.sets.single.weight, '82.5');
    expect(restored.groups.single.sets.single.done, isTrue);
    expect(restored.groups.single.plannedRepMin, 3);
    expect(restored.groups.single.plannedRepMax, 8);
    expect(restored.isMinimized, isTrue);

    restored.clear();
    restored.dispose();
    units.dispose();
    client.dispose();
  });

  test(
    'stale active workout restores as a paused draft without idle time',
    () async {
      var now = DateTime(2026, 9, 10, 12);
      SharedPreferences.setMockInitialValues({
        'active_workout_session_v1': jsonEncode({
          'version': 2,
          'active': true,
          'workout': {
            'id': 'stale-workout',
            'name': 'Stale workout',
            'exercises': [],
          },
          'difficulty': 'normal',
          'started_at': now.subtract(const Duration(days: 3)).toIso8601String(),
          'groups': [],
        }),
      });
      final httpClient = MockClient((_) async => http.Response('{}', 200));
      final client = AuthenticatedClient(
        storage: TokenStorage(),
        authService: AuthService(),
        inner: httpClient,
      );
      final exercises = ExercisesRepository(
        client: client,
        isOnline: () async => false,
      );
      final workouts = WorkoutsRepository(
        client: client,
        isOnline: () async => false,
      );
      final sessions = SessionsRepository(
        client: client,
        isOnline: () async => false,
      );
      final ranking = RankingRepository(
        client: client,
        isOnline: () async => false,
      );
      final units = UnitsController();
      final controller = WorkoutSessionController(now: () => now);

      expect(
        await controller.restore(
          exercises: exercises,
          ranking: ranking,
          sessions: sessions,
          workouts: workouts,
          units: units,
        ),
        isTrue,
      );
      expect(controller.isActive, isTrue);
      expect(controller.isPausedForInactivity, isTrue);
      expect(controller.elapsedSeconds, const Duration(hours: 4).inSeconds);
      controller.resume();
      now = now.add(const Duration(minutes: 30));
      expect(
        controller.elapsedSeconds,
        const Duration(hours: 4, minutes: 30).inSeconds,
      );
      now = now.add(const Duration(hours: 4, minutes: 1));
      expect(controller.autoPauseIfIdle(), isTrue);
      expect(controller.isPausedForInactivity, isTrue);
      expect(controller.elapsedSeconds, const Duration(hours: 8).inSeconds);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('active_workout_session_v1'), isNotNull);

      controller.clear();
      controller.dispose();
      units.dispose();
      client.dispose();
    },
  );
}
