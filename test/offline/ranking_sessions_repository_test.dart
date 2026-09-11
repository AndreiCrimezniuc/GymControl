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

    final profile = await ranking.updateProfile(
      weightKg: 82,
      heightCm: 180,
      appearanceDark: true,
      lightAccent: 'purple',
      darkAccent: 'green',
      locale: 'ru',
      unit: 'lb',
      oneRmFormula: 'wathan',
      deloadFactor: .6,
      weightPromptedAt: DateTime.utc(2026, 9, 9),
    );
    await ranking.recordLift(exerciseId: 'bench', weightKg: 100, reps: 5);
    await sessions.recordSession();

    expect(profile.weightKg, 82);
    expect((await ranking.getProfile()).heightCm, 180);
    expect((await ranking.getProfile(forceRefresh: true)).heightCm, 180);
    expect(profile.appearanceDark, isTrue);
    expect(profile.lightAccent, 'purple');
    expect(profile.darkAccent, 'green');
    expect(profile.locale, 'ru');
    expect(profile.unit, 'lb');
    expect(profile.oneRmFormula, 'wathan');
    expect(profile.deloadFactor, .6);
    expect(profile.weightPromptedAt, DateTime.utc(2026, 9, 9));
    expect((await sessions.getStreakData()).currentStreakWorkouts, 0);
    expect(store.pending().map((mutation) => mutation.kind), [
      'ranking.profile',
      'ranking.lift',
      'session.record',
    ]);
  });

  test(
    'cached passport and streak survive a false-positive network refresh',
    () async {
      await store.putDoc('ranking', 'profile', {
        'weight_kg': 82,
        'updated_at': '2026-09-11T00:00:00.000Z',
      });
      await store.putDoc('ranking', 'me', {
        'profile': {'weight_kg': 82, 'updated_at': '2026-09-11T00:00:00.000Z'},
        'exercise_ranks': [],
      });
      await store.putDoc('session_stats', 'streak', {
        'current_streak_workouts': 7,
        'active_weeks': [],
      });
      final client = AuthenticatedClient(
        storage: TokenStorage(),
        authService: AuthService(),
        inner: MockClient((_) async => throw const SocketException('offline')),
      );
      addTearDown(client.dispose);
      final ranking = RankingRepository(
        client: client,
        isOnline: () async => true,
      );
      final sessions = SessionsRepository(
        client: client,
        isOnline: () async => true,
      );

      expect((await ranking.getProfile(forceRefresh: true)).weightKg, 82);
      expect(
        (await ranking.getUserRanks(forceRefresh: true)).profile.weightKg,
        82,
      );
      expect(
        (await sessions.getStreakData(
          forceRefresh: true,
        )).currentStreakWorkouts,
        7,
      );
    },
  );
}
