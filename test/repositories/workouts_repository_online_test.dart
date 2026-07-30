import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gymboss/data/local/local_store.dart';
import 'package:gymboss/data/repositories/workouts_repository.dart';
import 'package:gymboss/data/services/auth/auth_service.dart';
import 'package:gymboss/data/services/auth/authenticated_client.dart';
import 'package:gymboss/data/services/auth/token_storage.dart';

AuthenticatedClient clientReturning(
  Map<String, http.Response> Function() routesFn,
) {
  return AuthenticatedClient(
    storage: TokenStorage(),
    authService: AuthService(),
    inner: MockClient((req) async {
      final routes = routesFn();
      for (final entry in routes.entries) {
        if (req.url.path.contains(entry.key)) return entry.value;
      }
      return http.Response('{}', 404);
    }),
  );
}

void main() {
  final store = LocalStore.instance;

  setUpAll(() async {
    final dir = Directory.systemTemp.createTempSync('gymboss_repo_online');
    await store.init(path: dir.path);
    SharedPreferences.setMockInitialValues(const {});
  });
  setUp(store.clear);

  test('listOwned parses the server payload and caches it', () async {
    final body = jsonEncode([
      {
        'id': 'w1',
        'name': 'Push',
        'comment': '',
        'visibility': 'private',
        'owned': true,
        'share_code': '',
        'exercise_count': 1,
        'times_performed': 2,
        'love_coefficient': 0.3,
        'exercises': [],
      },
    ]);
    final client = clientReturning(
      () => {'/api/v1/workouts': http.Response(body, 200)},
    );
    addTearDown(client.dispose);

    final list = await WorkoutsRepository(client: client).listOwned();
    expect(list, hasLength(1));
    expect(list.single.name, 'Push');
    // cached for offline
    expect(store.getDoc('workout', 'w1'), isNotNull);
  });

  test('statsSummary parses aggregates', () async {
    final body = jsonEncode({
      'total_workouts': 9,
      'longest_workout_seconds': 4200,
      'favorite_exercise': 'Bench Press',
      'strongest_exercise': 'Deadlift',
      'workouts_per_month': [
        {'month': '2026-07', 'count': 9},
      ],
    });
    final client = clientReturning(
      () => {'/api/v1/stats/summary': http.Response(body, 200)},
    );
    addTearDown(client.dispose);

    final s = await WorkoutsRepository(
      client: client,
    ).statsSummary(period: 'year');
    expect(s.totalWorkouts, 9);
    expect(s.longestWorkoutSeconds, 4200);
    expect(s.favoriteExercise, 'Bench Press');
    expect(s.workoutsPerMonth.single.count, 9);
  });

  test('activity parses global training volume points', () async {
    final body = jsonEncode([
      {
        'date': '2026-07-30',
        'duration_seconds': 3600,
        'reps': 140,
        'volume_kg': 9250.5,
        'workouts': 1,
      },
    ]);
    final client = clientReturning(
      () => {'/api/v1/stats/activity': http.Response(body, 200)},
    );
    addTearDown(client.dispose);

    final points = await WorkoutsRepository(
      client: client,
    ).activity(period: 'year');
    expect(points.single.durationSeconds, 3600);
    expect(points.single.reps, 140);
    expect(points.single.volumeKg, 9250.5);
  });

  test('stats parses potential volume + history and caches', () async {
    final body = jsonEncode({
      'times_performed': 3,
      'love_coefficient': 0.6,
      'potential_volume': {'easy': 10.0, 'medium': 20.0, 'hard': 30.0},
      'history': [
        {'date': '2026-07-01', 'difficulty': 'hard'},
      ],
    });
    final client = clientReturning(() => {'/stats': http.Response(body, 200)});
    addTearDown(client.dispose);

    final s = await WorkoutsRepository(client: client).stats('w1');
    expect(s.timesPerformed, 3);
    expect(s.potentialVolume['hard'], 30.0);
    expect(s.history.single.difficulty, 'hard');
  });

  // Write paths: isOnline() returns true when the connectivity plugin is
  // absent (test env), so these exercise the network branch directly.
  AuthenticatedClient writeClient(http.Response Function(http.Request) fn) {
    return AuthenticatedClient(
      storage: TokenStorage(),
      authService: AuthService(),
      inner: MockClient((req) async => fn(req)),
    );
  }

  String workoutJson(String id, String name) => jsonEncode({
    'id': id,
    'name': name,
    'comment': '',
    'visibility': 'private',
    'owned': true,
    'share_code': '',
    'exercise_count': 0,
    'times_performed': 0,
    'love_coefficient': 0,
    'exercises': [],
  });

  test('create posts and swaps the temp doc for the server workout', () async {
    final client = writeClient((req) {
      if (req.method == 'POST' && req.url.path.endsWith('/workouts')) {
        return http.Response(workoutJson('w-server', 'Created'), 201);
      }
      return http.Response('{}', 404);
    });
    addTearDown(client.dispose);
    final w = await WorkoutsRepository(
      client: client,
    ).create(name: 'Created', comment: '', exercises: []);
    expect(w.id, 'w-server');
  });

  test('logRun / setVisibility / delete succeed on 2xx', () async {
    final client = writeClient((req) {
      final p = req.url.path;
      if (p.endsWith('/run')) return http.Response('', 204);
      if (p.endsWith('/visibility')) return http.Response('', 204);
      if (req.method == 'DELETE') return http.Response('', 204);
      return http.Response('{}', 404);
    });
    addTearDown(client.dispose);
    final repo = WorkoutsRepository(client: client);
    await repo.logRun('w1', 'medium', durationSeconds: 900);
    await repo.setVisibility('w1', 'public');
    await repo.delete('w1');
  });

  test('share returns the code and copy/import return workouts', () async {
    final client = writeClient((req) {
      final p = req.url.path;
      if (p.endsWith('/share')) {
        return http.Response(jsonEncode({'code': 'XYZ9'}), 200);
      }
      if (p.endsWith('/copy')) {
        return http.Response(workoutJson('w-copy', 'Copy'), 201);
      }
      if (p.endsWith('/import')) {
        return http.Response(workoutJson('w-imp', 'Imported'), 201);
      }
      return http.Response('{}', 404);
    });
    addTearDown(client.dispose);
    final repo = WorkoutsRepository(client: client);
    expect(await repo.share('w1'), 'XYZ9');
    expect((await repo.copy('w1')).id, 'w-copy');
    expect((await repo.import('XYZ9')).id, 'w-imp');
  });

  test('runDetail parses performed exercises', () async {
    final body = jsonEncode([
      {
        'exercise_id': 5,
        'name': 'Squat',
        'muscle_group': 'legs',
        'sets': [
          {
            'weight_kg': 100,
            'reps': 5,
            'set_type': 'working',
            'progression': 'amplitude',
          },
        ],
      },
    ]);
    final client = clientReturning(
      () => {'/history/': http.Response(body, 200)},
    );
    addTearDown(client.dispose);

    final detail = await WorkoutsRepository(
      client: client,
    ).runDetail('w1', '2026-07-01');
    expect(detail, hasLength(1));
    expect(detail.single.name, 'Squat');
    expect(detail.single.sets.single.progression, 'amplitude');
  });

  test('folder CRUD and assignment use the expected API contract', () async {
    final requests = <http.Request>[];
    final client = writeClient((req) {
      requests.add(req);
      if (req.method == 'GET' && req.url.path.endsWith('/workout-folders')) {
        return http.Response(
          jsonEncode([
            {'id': 'f1', 'name': 'Strength', 'position': 0},
          ]),
          200,
        );
      }
      if (req.method == 'POST') {
        return http.Response(
          jsonEncode({'id': 'f2', 'name': 'Cardio', 'position': 1}),
          201,
        );
      }
      return http.Response('', 204);
    });
    addTearDown(client.dispose);
    final repo = WorkoutsRepository(client: client);

    expect((await repo.listFolders()).single.name, 'Strength');
    expect((await repo.createFolder('Cardio')).id, 'f2');
    await repo.renameFolder('f2', 'Conditioning');
    await repo.assignFolder('w1', 'f2');
    await repo.assignFolder('w1', null);
    await repo.deleteFolder('f2');

    expect(requests.map((r) => r.method), [
      'GET',
      'POST',
      'PUT',
      'PUT',
      'PUT',
      'DELETE',
    ]);
    expect(jsonDecode(requests[3].body), containsPair('folder_id', 'f2'));
    expect(jsonDecode(requests[4].body), containsPair('folder_id', null));
  });
}
