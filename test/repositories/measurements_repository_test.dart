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

  test('list and save use the body measurement API contract', () async {
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
    final repository = MeasurementsRepository(client: client);

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
    expect(saved.id, 'm1');
  });
}
