import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gymboss/data/local/local_store.dart';
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
  final store = LocalStore.instance;

  setUpAll(() async {
    final directory = Directory.systemTemp.createTempSync(
      'gymboss_completion_pipeline',
    );
    await store.init(path: directory.path);
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues(const {});
    await store.clear();
  });

  test(
    'completed benchmark workout updates every local-first record',
    () async {
      final client = AuthenticatedClient(
        storage: TokenStorage(),
        authService: AuthService(),
        inner: MockClient((_) async => throw const SocketException('offline')),
      );
      addTearDown(client.dispose);
      final exercises = ExercisesRepository(
        client: client,
        isOnline: () async => false,
      );
      final ranking = RankingRepository(
        client: client,
        isOnline: () async => false,
      );
      final sessions = SessionsRepository(
        client: client,
        isOnline: () async => false,
      );
      final workouts = WorkoutsRepository(
        client: client,
        isOnline: () async => false,
      );
      final units = UnitsController();
      addTearDown(units.dispose);
      final controller = WorkoutSessionController();
      addTearDown(controller.dispose);

      controller.start(
        workout: const Workout(
          id: 'w1',
          name: 'Bench day',
          comment: '',
          visibility: 'private',
          owned: true,
          shareCode: '',
          exerciseCount: 1,
          timesPerformed: 0,
          exercises: [
            WorkoutExercise(
              exerciseId: 7,
              name: 'Barbell Bench Press - Medium Grip',
              imageUrl: '',
              muscleGroup: 'Chest',
              restSeconds: 90,
              comment: '',
              sets: [WorkoutSet(difficulty: 'medium', weightKg: 80, reps: 5)],
            ),
          ],
        ),
        difficulty: 'normal',
        exercises: exercises,
        ranking: ranking,
        sessions: sessions,
        workouts: workouts,
        units: units,
      );
      controller.toggleSet(controller.groups.single.sets.single);

      await controller.finish(save: true);

      expect(store.pending().map((mutation) => mutation.kind), [
        'exercise.logSet',
        'ranking.lift',
        'workout.run',
        'session.record',
      ]);
      final dated = store.pending().where(
        (mutation) =>
            mutation.kind == 'exercise.logSet' ||
            mutation.kind == 'workout.run' ||
            mutation.kind == 'session.record',
      );
      expect(
        dated
            .map(
              (mutation) =>
                  mutation.args['performed_at'] ??
                  mutation.args['session_date'],
            )
            .toSet(),
        hasLength(1),
      );
    },
  );
}
