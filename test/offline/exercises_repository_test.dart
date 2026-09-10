import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gymboss/data/local/local_store.dart';
import 'package:gymboss/data/local/mutation.dart';
import 'package:gymboss/data/repositories/exercises_repository.dart';
import 'package:gymboss/data/services/auth/auth_service.dart';
import 'package:gymboss/data/services/auth/authenticated_client.dart';
import 'package:gymboss/data/services/auth/token_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final store = LocalStore.instance;
  late AuthenticatedClient client;
  late ExercisesRepository repository;

  setUpAll(() async {
    final dir = Directory.systemTemp.createTempSync('gymboss_exercises_test');
    await store.init(path: dir.path);
    SharedPreferences.setMockInitialValues(const {});
  });

  setUp(() async {
    await store.clear();
    client = AuthenticatedClient(
      storage: TokenStorage(),
      authService: AuthService(),
      inner: MockClient((_) async => throw const SocketException('offline')),
    );
    repository = ExercisesRepository(client: client);
  });

  tearDown(() => client.dispose());

  test('catalog falls back to its durable snapshot offline', () async {
    await store.putDoc('exercise', '42', {
      'id': 42,
      'name': 'Bench Press',
      'muscle_group': 'Chest',
      'equipment': 'Barbell',
      'category': 'strength',
      'level': 'intermediate',
      'force': 'push',
      'image_url': '/api/v1/exercise-images/0042-relaxation.png',
      'image_url2': '/api/v1/exercise-images/0042-tension.png',
      'instructions': '',
    });
    await store.putListIds('exercises:catalog', ['42']);

    var requests = 0;
    final offlineClient = AuthenticatedClient(
      storage: TokenStorage(),
      authService: AuthService(),
      inner: MockClient((_) async {
        requests++;
        throw const SocketException('offline');
      }),
    );
    addTearDown(offlineClient.dispose);
    final offlineRepository = ExercisesRepository(
      client: offlineClient,
      isOnline: () async => false,
    );

    final catalog = await offlineRepository.getCatalog();

    expect(catalog.single.name, 'Bench Press');
    expect(requests, 0, reason: 'known-offline reads must not wait for HTTP');
  });

  test('first-ever offline launch installs the bundled core catalog', () async {
    final offlineRepository = ExercisesRepository(
      client: client,
      isOnline: () async => false,
    );

    final catalog = await offlineRepository.getCatalog();

    expect(catalog, isNotEmpty);
    expect(catalog.map((exercise) => exercise.name), contains('Bench Press'));
    expect(store.hasList('exercises:catalog'), isTrue);
    expect(store.getDoc('exercise', '1')?['name'], 'Bench Press');
  });

  test('performed set is kept in the outbox when the network fails', () async {
    await repository.logSet(
      42,
      weightKg: 100,
      reps: 5,
      sessionId: 'session-1',
      workoutId: 'workout-1',
      workoutName: 'Push',
    );

    final mutation = store.pending().single;
    expect(mutation.kind, 'exercise.logSet');
    expect(mutation.args['exerciseId'], 42);
    expect(mutation.args['weight_kg'], 100);
    expect(mutation.args['reps'], 5);
    expect(store.getDoc('exercise_stats', '42')?['total_sets'], 1);
    final history = store.getDoc('exercise_history', '42')?['items'] as List;
    expect((history.single as Map)['workout_name'], 'Push');
  });

  test(
    'offline exercise stats aggregate by day and count distinct sessions',
    () async {
      final date = DateTime(2026, 9, 7);
      await repository.logSet(
        42,
        weightKg: 100,
        reps: 5,
        sessionId: 'session-1',
        performedAt: date,
      );
      await repository.logSet(
        42,
        weightKg: 110,
        reps: 3,
        sessionId: 'session-1',
        performedAt: date,
      );
      await repository.logSet(
        42,
        weightKg: 80,
        reps: 10,
        sessionId: 'session-2',
        performedAt: date,
      );

      final stats = store.getDoc('exercise_stats', '42')!;
      expect(stats['times_performed'], 2);
      expect(stats['total_sets'], 3);
      expect(stats['max_volume_kg'], 1630);
      final progression = stats['progression'] as List;
      expect(progression, hasLength(1));
      expect((progression.single as Map)['top_weight_kg'], 110);
      expect((progression.single as Map)['top_reps'], 10);
      expect((progression.single as Map)['volume_kg'], 1630);
      expect(store.getDoc('exercise_history', '42')!['items'], hasLength(2));
    },
  );

  test('cached stats do not wait for a stalled network check', () async {
    await store.putDoc('exercise_stats', '42', {
      'exercise_id': 42,
      'total_sets': 12,
      'total_reps': 60,
    });
    final stalledConnectivity = Completer<bool>();
    final stats = await ExercisesRepository(
      client: client,
      isOnline: () => stalledConnectivity.future,
    ).getStats(42).timeout(const Duration(milliseconds: 100));

    expect(stats.totalSets, 12);
  });

  test('custom exercise is immediately available and queued offline', () async {
    final item =
        await ExercisesRepository(
          client: client,
          isOnline: () async => false,
        ).createCustom(
          name: 'Cable chaos',
          muscleGroup: 'Back',
          equipment: 'Cable',
        );

    expect(item.id, isNegative);
    expect(item.name, 'Cable chaos');
    expect(store.getListIds('exercises:catalog'), contains('${item.id}'));
    expect(store.getDoc('exercise', '${item.id}')?['name'], 'Cable chaos');
    final mutation = store.pending().single;
    expect(mutation.kind, 'exercise.createCustom');
    expect(mutation.args['client_request_id'], isA<String>());
    expect((mutation.args['client_request_id'] as String), isNotEmpty);
    expect(mutation.args['tempId'], '${item.id}');
  });

  test('archiving a temp exercise never drops a dependent workout', () async {
    final offline = ExercisesRepository(
      client: client,
      isOnline: () async => false,
    );
    final item = await offline.createCustom(
      name: 'Temporary lift',
      muscleGroup: 'Other',
    );
    await store.enqueue(
      Mutation(
        id: 'dependent-workout',
        seq: store.nextSeq(),
        kind: 'workout.create',
        args: {
          'exercises': [
            {'exercise_id': item.id},
          ],
        },
      ),
    );

    await offline.archiveCustom(item.id);

    expect(store.pending().map((mutation) => mutation.kind), [
      'exercise.createCustom',
      'workout.create',
      'exercise.archiveCustom',
    ]);
  });

  test('archiving an unreferenced temp exercise cancels its create', () async {
    final offline = ExercisesRepository(
      client: client,
      isOnline: () async => false,
    );
    final item = await offline.createCustom(
      name: 'Disposable',
      muscleGroup: 'Other',
    );

    await offline.archiveCustom(item.id);

    expect(store.pending(), isEmpty);
  });
}
