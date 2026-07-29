import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gymboss/data/local/local_store.dart';
import 'package:gymboss/data/repositories/workouts_repository.dart';
import 'package:gymboss/data/services/auth/auth_service.dart';
import 'package:gymboss/data/services/auth/authenticated_client.dart';
import 'package:gymboss/data/services/auth/token_storage.dart';

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
        'love_coefficient': 0,
        'exercises': <Object>[],
      });
      await store.putListIds('workouts:owned', ['w1']);

      final client = AuthenticatedClient(
        storage: TokenStorage(),
        authService: AuthService(),
        inner: MockClient((_) async => throw const SocketException('offline')),
      );
      addTearDown(client.dispose);

      final workouts = await WorkoutsRepository(client: client).listOwned();

      expect(workouts, hasLength(1));
      expect(workouts.single.name, 'Offline push');
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

    final folders = await WorkoutsRepository(client: client).listFolders();

    expect(folders, hasLength(1));
    expect(folders.single.name, 'Strength');
  });
}
