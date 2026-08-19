import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gymboss/data/local/local_store.dart';
import 'package:gymboss/data/repositories/ranking_repository.dart';
import 'package:gymboss/data/repositories/sessions_repository.dart';
import 'package:gymboss/data/services/auth/auth_service.dart';
import 'package:gymboss/data/services/auth/authenticated_client.dart';
import 'package:gymboss/data/services/auth/token_storage.dart';

void main() {
  final store = LocalStore.instance;

  setUpAll(() async {
    final directory = Directory.systemTemp.createTempSync(
      'gymboss_ranking_sessions',
    );
    await store.init(path: directory.path);
    SharedPreferences.setMockInitialValues(const {});
  });
  setUp(store.clear);

  test('profile, lift, and session writes queue without network', () async {
    final client = AuthenticatedClient(
      storage: TokenStorage(),
      authService: AuthService(),
      inner: MockClient((_) async => throw const SocketException('offline')),
    );
    addTearDown(client.dispose);
    final ranking = RankingRepository(
      client: client,
      isOnline: () async => false,
    );
    final sessions = SessionsRepository(
      client: client,
      isOnline: () async => false,
    );

    final profile = await ranking.updateProfile(weightKg: 82, heightCm: 180);
    await ranking.recordLift(exerciseId: 'bench', weightKg: 100, reps: 5);
    await sessions.recordSession();

    expect(profile.weightKg, 82);
    expect((await ranking.getProfile()).heightCm, 180);
    expect((await sessions.getStreakData()).currentStreakWeeks, 0);
    expect(store.pending().map((mutation) => mutation.kind), [
      'ranking.profile',
      'ranking.lift',
      'session.record',
    ]);
  });
}
