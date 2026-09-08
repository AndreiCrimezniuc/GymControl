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
    expect(restored.isMinimized, isTrue);

    restored.clear();
    restored.dispose();
    units.dispose();
    client.dispose();
  });
}
