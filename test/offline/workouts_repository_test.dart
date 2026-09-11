import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gymboss/data/local/local_store.dart';
import 'package:gymboss/data/repositories/workouts_repository.dart';
import 'package:gymboss/data/services/auth/auth_service.dart';
import 'package:gymboss/data/services/auth/authenticated_client.dart';
import 'package:gymboss/data/services/auth/token_storage.dart';
import 'package:gymboss/domain/models/workouts/workout.dart';

void main() {
  final store = LocalStore.instance;

  setUpAll(() async {
    final dir = Directory.systemTemp.createTempSync('gymboss_repo_test');
    await store.init(path: dir.path);
    SharedPreferences.setMockInitialValues(const {});
  });

  setUp(store.clear);

  test(
    'owned workouts fall back to durable cache on network failure',
    () async {
      await store.putDoc('workout', 'w1', {
        'id': 'w1',
        'name': 'Offline push',
        'comment': '',
        'visibility': 'private',
        'owned': true,
        'share_code': '',
        'exercise_count': 0,
        'times_performed': 0,
        'exercises': <Object>[],
      });
      await store.putListIds('workouts:owned', ['w1']);

      var requests = 0;
      final client = AuthenticatedClient(
        storage: TokenStorage(),
        authService: AuthService(),
        inner: MockClient((_) async {
          requests++;
          throw const SocketException('offline');
        }),
      );
      addTearDown(client.dispose);

      final workouts = await WorkoutsRepository(
        client: client,
        isOnline: () async => false,
      ).listOwned();

      expect(workouts, hasLength(1));
      expect(workouts.single.name, 'Offline push');
      expect(requests, 0, reason: 'known-offline reads must not wait for HTTP');
    },
  );

  test('workout folders fall back to durable cache offline', () async {
    await store.putDoc('workout-folder', 'f1', {
      'id': 'f1',
      'name': 'Strength',
      'position': 0,
    });
    await store.putListIds('workout-folders', ['f1']);

    final client = AuthenticatedClient(
      storage: TokenStorage(),
      authService: AuthService(),
      inner: MockClient((_) async => throw const SocketException('offline')),
    );
    addTearDown(client.dispose);

    final folders = await WorkoutsRepository(
      client: client,
      isOnline: () async => false,
    ).listFolders();

    expect(folders, hasLength(1));
    expect(folders.single.name, 'Strength');
  });

  test('cached workout renders without waiting for connectivity', () async {
    await store.putDoc('workout', 'w1', {
      'id': 'w1',
      'name': 'Instant cache',
      'exercises': <Object>[],
    });
    final client = AuthenticatedClient(
      storage: TokenStorage(),
      authService: AuthService(),
      inner: MockClient((_) async => throw const SocketException('offline')),
    );
    addTearDown(client.dispose);
    final stalledConnectivity = Completer<bool>();
    final workout = await WorkoutsRepository(
      client: client,
      isOnline: () => stalledConnectivity.future,
    ).get('w1').timeout(const Duration(milliseconds: 100));

    expect(workout.name, 'Instant cache');
  });

  test('forced offline refresh keeps every cached workout insight', () async {
    await store.putDoc('stats_summary', 'summary_all', {
      'total_workouts': 9,
      'workouts_per_month': [],
    });
    await store.putDoc('stats_activity', 'activity_all', {
      'items': [
        {
          'date': '2026-09-11',
          'duration_seconds': 900,
          'reps': 24,
          'volume_kg': 1200,
          'workouts': 1,
        },
      ],
    });
    await store.putDoc('workout_stats', 'w1', {
      'times_performed': 4,
      'potential_volume': {},
      'history': [],
    });
    await store.putDoc('workout_run_detail', 'w1:2026-09-11:s1', {
      'items': [
        {
          'exercise_id': 42,
          'name': 'Dips',
          'muscle_group': 'Chest',
          'sets': [],
        },
      ],
    });
    final client = AuthenticatedClient(
      storage: TokenStorage(),
      authService: AuthService(),
      inner: MockClient((_) async => throw const SocketException('offline')),
    );
    addTearDown(client.dispose);
    final repository = WorkoutsRepository(
      client: client,
      isOnline: () async => false,
    );

    expect(
      (await repository.statsSummary(forceRefresh: true)).totalWorkouts,
      9,
    );
    expect(await repository.activity(forceRefresh: true), hasLength(1));
    expect(
      (await repository.stats('w1', forceRefresh: true)).timesPerformed,
      4,
    );
    expect(
      await repository.runDetail(
        'w1',
        '2026-09-11',
        sessionId: 's1',
        forceRefresh: true,
      ),
      hasLength(1),
    );
  });

  test(
    'a compact cached card never starts as an empty offline workout',
    () async {
      await store.putDoc('workout', 'w1', {
        'id': 'w1',
        'name': 'Needs a full plan',
        'exercises': [
          {'exercise_id': 42, 'name': 'Dips', 'sets': []},
        ],
      });
      final client = AuthenticatedClient(
        storage: TokenStorage(),
        authService: AuthService(),
        inner: MockClient((_) async => throw const SocketException('offline')),
      );
      addTearDown(client.dispose);
      final repository = WorkoutsRepository(
        client: client,
        isOnline: () async => false,
      );

      await expectLater(
        repository.get('w1', forceRefresh: true),
        throwsA(isA<WorkoutPlanUnavailableOffline>()),
      );
    },
  );

  test('completed run updates cache before background sync', () async {
    await store.putDoc('workout', 'w1', {
      'id': 'w1',
      'name': 'Push',
      'times_performed': 2,
      'exercises': <Object>[],
    });
    await store.putDoc('workout_stats', 'w1', {
      'times_performed': 2,
      'potential_volume': <String, Object>{},
      'history': <Object>[],
    });
    final client = AuthenticatedClient(
      storage: TokenStorage(),
      authService: AuthService(),
      inner: MockClient((_) async => throw const SocketException('offline')),
    );
    addTearDown(client.dispose);
    await WorkoutsRepository(
      client: client,
      isOnline: () async => false,
    ).logRun('w1', 'normal', durationSeconds: 900);

    expect(store.getDoc('workout', 'w1')?['times_performed'], 3);
    expect(store.getDoc('workout_stats', 'w1')?['times_performed'], 3);
    expect(store.pending().single.kind, 'workout.run');
  });

  test('retrying one durable session cannot double-count its run', () async {
    await store.putDoc('workout', 'w1', {
      'id': 'w1',
      'name': 'Run',
      'times_performed': 0,
      'exercises': <Object>[],
    });
    await store.putDoc('workout_stats', 'w1', {
      'times_performed': 0,
      'potential_volume': <String, Object>{},
      'history': <Object>[],
    });
    final client = AuthenticatedClient(
      storage: TokenStorage(),
      authService: AuthService(),
      inner: MockClient((_) async => throw const SocketException('offline')),
    );
    addTearDown(client.dispose);
    final repository = WorkoutsRepository(
      client: client,
      isOnline: () async => false,
    );
    const sessionId = '10000000-0000-0000-0000-000000000001';

    await repository.logRun('w1', 'normal', sessionId: sessionId);
    await repository.logRun('w1', 'normal', sessionId: sessionId);

    expect(store.getDoc('workout', 'w1')?['times_performed'], 1);
    expect(store.getDoc('workout_stats', 'w1')?['times_performed'], 1);
    expect(store.pending(), hasLength(1));
    expect(store.pending().single.args['operation_id'], sessionId);
  });

  test(
    'folder creation and assignment accumulate in the outbox offline',
    () async {
      await store.putDoc('workout', 'w1', {
        'id': 'w1',
        'name': 'Push',
        'comment': '',
        'visibility': 'private',
        'owned': true,
        'share_code': '',
        'exercise_count': 0,
        'times_performed': 0,
        'exercises': <Object>[],
      });
      await store.putListIds('workouts:owned', ['w1']);
      final client = AuthenticatedClient(
        storage: TokenStorage(),
        authService: AuthService(),
        inner: MockClient((_) async => throw const SocketException('offline')),
      );
      addTearDown(client.dispose);
      final repository = WorkoutsRepository(
        client: client,
        isOnline: () async => false,
      );

      final folder = await repository.createFolder('Strength');
      await repository.assignFolder('w1', folder.id);

      expect(folder.id, startsWith('local:'));
      expect(store.getDoc('workout', 'w1')?['folder_id'], folder.id);
      expect(store.pending().map((mutation) => mutation.kind), [
        'folder.create',
        'workout.assignFolder',
      ]);
    },
  );

  test('offline workout preserves advanced programming metadata', () async {
    final client = AuthenticatedClient(
      storage: TokenStorage(),
      authService: AuthService(),
      inner: MockClient((_) async => throw const SocketException('offline')),
    );
    addTearDown(client.dispose);
    final repository = WorkoutsRepository(
      client: client,
      isOnline: () async => false,
    );
    const exercise = WorkoutExercise(
      exerciseId: 7,
      name: 'Bench press',
      imageUrl: '/bench.png',
      imageUrl2: '/bench-2.png',
      muscleGroup: 'Chest',
      exerciseType: 'weight_reps',
      trainingGroupId: 'circuit-a',
      trainingGroupType: 'circuit',
      isOptional: true,
      alternativeGroupId: 'choice-a',
      progressionRuleType: 'double_progression',
      progressionIncrementKg: 2.5,
      progressionRepMin: 6,
      progressionRepMax: 10,
      progressionTargetRpe: 8,
      restSeconds: 90,
      comment: 'Controlled pause',
      sets: [WorkoutSet(difficulty: 'medium', weightKg: 80, reps: 8)],
    );

    final created = await repository.create(
      name: 'Offline advanced',
      comment: '',
      exercises: const [exercise],
    );
    final restored = await repository.get(created.id);
    final actual = restored.exercises.single;

    expect(actual.isOptional, isTrue);
    expect(actual.alternativeGroupId, 'choice-a');
    expect(actual.trainingGroupId, 'circuit-a');
    expect(actual.trainingGroupType, 'circuit');
    expect(actual.progressionRuleType, 'double_progression');
    expect(actual.progressionTargetRpe, 8);
    expect(actual.imageUrl2, '/bench-2.png');
  });

  test(
    'a workout created offline opens and starts from its complete local plan',
    () async {
      final client = AuthenticatedClient(
        storage: TokenStorage(),
        authService: AuthService(),
        inner: MockClient((_) async => throw const SocketException('offline')),
      );
      addTearDown(client.dispose);
      final repository = WorkoutsRepository(
        client: client,
        isOnline: () async => false,
      );
      const exercise = WorkoutExercise(
        exerciseId: 42,
        name: 'Dips',
        imageUrl: '',
        muscleGroup: 'Chest',
        exerciseType: 'weight_reps',
        restSeconds: 90,
        comment: '',
        sets: [WorkoutSet(difficulty: 'medium', weightKg: 20, reps: 8)],
      );

      final created = await repository.create(
        name: 'Dips day',
        comment: '',
        exercises: const [exercise],
      );
      final reopened = await repository.get(created.id, forceRefresh: true);

      expect(reopened.id, created.id);
      expect(reopened.exercises, hasLength(1));
      expect(reopened.exercises.single.name, 'Dips');
      expect(reopened.exercises.single.sets.single.reps, 8);
    },
  );

  test('completed session corrections remain durable offline', () async {
    await store.putDoc('session_stats', 'streak', {'current_streak': 5});
    await store.putDoc('workout_stats', 'w1', {'times_performed': 1});
    final client = AuthenticatedClient(
      storage: TokenStorage(),
      authService: AuthService(),
      inner: MockClient((_) async => throw const SocketException('offline')),
    );
    addTearDown(client.dispose);
    final repository = WorkoutsRepository(
      client: client,
      isOnline: () async => false,
    );

    await repository.replaceCompletedSession(
      workoutId: 'w1',
      sessionId: '10000000-0000-0000-0000-000000000001',
      performedAt: '2026-01-02',
      difficulty: 'normal',
      exercises: const [
        PerformedExerciseLog(
          exerciseId: 7,
          name: 'Bench press',
          muscleGroup: 'Chest',
          sets: [PerformedSetLog(weightKg: 80, reps: 5, setType: 'working')],
        ),
      ],
    );

    final mutation = store.pending().single;
    expect(mutation.kind, 'workout.editCompleted');
    expect(mutation.args['operation_id'], isNotEmpty);
    expect(store.getDoc('workout_stats', 'w1'), isNull);
    expect(store.getDoc('session_stats', 'streak'), isNull);
  });
}
