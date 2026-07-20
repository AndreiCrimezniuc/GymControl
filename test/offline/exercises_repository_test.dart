import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gymboss/data/local/local_store.dart';
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

    final catalog = await repository.getCatalog();

    expect(catalog.single.name, 'Bench Press');
  });

  test('performed set is kept in the outbox when the network fails', () async {
    await repository.logSet(42, weightKg: 100, reps: 5);

    final mutation = store.pending().single;
    expect(mutation.kind, 'exercise.logSet');
    expect(mutation.args['exerciseId'], 42);
    expect(mutation.args['weight_kg'], 100);
    expect(mutation.args['reps'], 5);
  });
}
