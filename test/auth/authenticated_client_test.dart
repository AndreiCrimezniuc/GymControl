import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gymboss/core/errors/app_error.dart';
import 'package:gymboss/data/services/auth/auth_service.dart';
import 'package:gymboss/data/services/auth/authenticated_client.dart';
import 'package:gymboss/data/services/auth/token_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(const {}));

  test('transient refresh failure preserves secure tokens', () async {
    final storage = TokenStorage();
    await storage.save('expired-access', 'still-valid-refresh');
    final client = AuthenticatedClient(
      storage: storage,
      authService: AuthService(
        client: MockClient((_) async => throw const SocketException('offline')),
      ),
      inner: MockClient((_) async => http.Response('', 401)),
    );
    addTearDown(client.dispose);

    await expectLater(
      client.get(Uri.parse('https://api.test/private')),
      throwsA(
        isA<AppError>().having(
          (error) => error.errorCode,
          'code',
          AppErrorCode.networkUnavailable,
        ),
      ),
    );
    expect(await storage.getAccessToken(), 'expired-access');
    expect(await storage.getRefreshToken(), 'still-valid-refresh');
  });

  test('rejected refresh clears secure tokens and expires session', () async {
    final storage = TokenStorage();
    await storage.save('expired-access', 'revoked-refresh');
    final client = AuthenticatedClient(
      storage: storage,
      authService: AuthService(
        client: MockClient(
          (_) async => http.Response('{"error":"expired"}', 401),
        ),
      ),
      inner: MockClient((_) async => http.Response('', 401)),
    );
    addTearDown(client.dispose);

    await expectLater(
      client.get(Uri.parse('https://api.test/private')),
      throwsA(
        isA<AppError>().having(
          (error) => error.errorCode,
          'code',
          AppErrorCode.authTokenExpired,
        ),
      ),
    );
    expect(await storage.getAccessToken(), isNull);
    expect(await storage.getRefreshToken(), isNull);
  });
}
