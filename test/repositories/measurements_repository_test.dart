import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gymboss/data/local/local_store.dart';
import 'package:gymboss/data/repositories/measurements_repository.dart';
import 'package:gymboss/data/services/auth/auth_service.dart';
import 'package:gymboss/data/services/auth/authenticated_client.dart';
import 'package:gymboss/data/services/auth/token_storage.dart';
import 'package:gymboss/domain/models/measurements/body_measurement.dart';

void main() {
  final store = LocalStore.instance;

  setUpAll(() async {
    final directory = Directory.systemTemp.createTempSync(
      'gymboss_measurements',
    );
    await store.init(path: directory.path);
    SharedPreferences.setMockInitialValues(const {});
  });
  setUp(store.clear);

  test('list is cached and save commits immediately to the outbox', () async {
    final payload = {
      'id': 'm1',
      'measured_at': '2026-07-30',
      'weight_kg': 82.5,
      'waist_cm': 81,
      'note': '',
    };
    final client = AuthenticatedClient(
      storage: TokenStorage(),
      authService: AuthService(),
      inner: MockClient((request) async {
        if (request.method == 'GET') {
          return http.Response(jsonEncode([payload]), 200);
        }
        if (request.method == 'POST') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['measured_at'], '2026-07-30');
          expect(body['waist_cm'], 81);
          return http.Response(jsonEncode(payload), 201);
        }
        return http.Response('', 204);
      }),
    );
    addTearDown(client.dispose);
    final repository = MeasurementsRepository(
      client: client,
      isOnline: () async => true,
    );

    final items = await repository.list();
    expect(items.single.weightKg, 82.5);
    final saved = await repository.save(
      const BodyMeasurement(
        id: '',
        measuredAt: '2026-07-30',
        weightKg: 82.5,
        waistCm: 81,
      ),
    );
    expect(saved.id, startsWith('local:'));
    expect(store.pending().single.kind, 'measurement.create');

    expect(store.getDoc('body_measurements', saved.id), isNotNull);
  });

  test('save is optimistic and queued while offline', () async {
    final client = AuthenticatedClient(
      storage: TokenStorage(),
      authService: AuthService(),
      inner: MockClient((_) async => throw const SocketException('offline')),
    );
    addTearDown(client.dispose);
    final repository = MeasurementsRepository(
      client: client,
      isOnline: () async => false,
    );

    final saved = await repository.save(
      const BodyMeasurement(id: '', measuredAt: '2026-08-19', weightKg: 81),
    );

    expect(saved.id, startsWith('local:'));
    expect((await repository.list()).single.weightKg, 81);
    expect(store.pending().single.kind, 'measurement.create');

    await repository.delete(saved.id);
    expect(await repository.list(), isEmpty);
    expect(store.pending(), isEmpty);
  });
}
