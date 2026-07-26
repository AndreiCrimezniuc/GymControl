import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gymboss/data/local/local_store.dart';
import 'package:gymboss/data/repositories/exercises_repository.dart';
import 'package:gymboss/data/services/auth/auth_service.dart';
import 'package:gymboss/data/services/auth/authenticated_client.dart';
import 'package:gymboss/data/services/auth/token_storage.dart';

AuthenticatedClient client(http.Response Function(http.Request) fn) =>
    AuthenticatedClient(
      storage: TokenStorage(),
      authService: AuthService(),
      inner: MockClient((req) async => fn(req)),
    );

void main() {
  final store = LocalStore.instance;

  setUpAll(() async {
    final dir = Directory.systemTemp.createTempSync('gymboss_ex_online');
    await store.init(path: dir.path);
    SharedPreferences.setMockInitialValues(const {});
  });
  setUp(store.clear);

  test('getCatalog parses and caches the catalog', () async {
    final body = jsonEncode([
      {'id': 1, 'name': 'Bench Press', 'muscle_group': 'chest'},
      {'id': 2, 'name': 'Squat', 'muscle_group': 'legs'},
    ]);
    final c = client((req) => http.Response(body, 200));
    addTearDown(c.dispose);
    final catalog = await ExercisesRepository(client: c).getCatalog();
    expect(catalog, hasLength(2));
    expect(catalog.first.name, 'Bench Press');
    expect(
      store.hasList('exercises:catalog') ||
          store.getDoc('exercise_catalog', '1') != null,
      isTrue,
    );
  });

  test('getStats parses per-exercise stats', () async {
    final body = jsonEncode({
      'exercise_id': 1,
      'times_performed': 5,
      'total_sets': 20,
      'total_reps': 150,
      'max_weight_kg': 100.0,
      'max_volume_kg': 2000.0,
      'love_coefficient': 0.4,
    });
    final c = client((req) => http.Response(body, 200));
    addTearDown(c.dispose);
    final stats = await ExercisesRepository(client: c).getStats(1);
    expect(stats.maxWeightKg, 100.0);
    expect(stats.totalSets, 20);
  });

  test('logSet posts a set (online branch)', () async {
    var posted = false;
    final c = client((req) {
      if (req.method == 'POST' && req.url.path.contains('/log')) {
        posted = true;
        return http.Response('', 204);
      }
      return http.Response('{}', 404);
    });
    addTearDown(c.dispose);
    await ExercisesRepository(client: c).logSet(
      1,
      weightKg: 80,
      reps: 5,
      setType: 'working',
      progression: 'amplitude',
    );
    expect(posted, isTrue);
  });
}
