import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gymboss/data/local/local_store.dart';
import 'package:gymboss/data/local/mutation.dart';
import 'package:gymboss/data/services/auth/auth_service.dart';
import 'package:gymboss/data/services/auth/authenticated_client.dart';
import 'package:gymboss/data/services/auth/token_storage.dart';
import 'package:gymboss/data/sync/sync_service.dart';

void main() {
  final store = LocalStore.instance;
  late AuthenticatedClient client;

  setUpAll(() async {
    final dir = Directory.systemTemp.createTempSync('gymboss_sync_test');
    await store.init(path: dir.path);
    SharedPreferences.setMockInitialValues(const {});
  });

  setUp(() async {
    await store.clear();
    client = AuthenticatedClient(
      storage: TokenStorage(),
      authService: AuthService(),
      inner: MockClient(
        (_) async => throw StateError('HTTP must not be called'),
      ),
    );
  });

  tearDown(() => client.dispose());

  SyncService service() => SyncService(
    store: store,
    isOnline: () async => true,
    onlineChanges: const Stream<bool>.empty(),
  )..bind(client);

  test(
    'unknown mutation remains durable until its handler registers',
    () async {
      await store.enqueue(
        Mutation(id: 'm1', seq: 1, kind: 'late.kind', args: const {}),
      );
      final sync = service();
      addTearDown(sync.dispose);

      await sync.flush();
      expect(store.pending().map((m) => m.id), ['m1']);

      sync.registerHandler(
        'late.kind',
        (_, _) async => const SyncOutcome.done(),
      );
      await sync.flush();
      expect(store.pending(), isEmpty);
    },
  );

  test('permanently rejected mutation is retained as a dead-letter', () async {
    await store.enqueue(
      Mutation(id: 'm1', seq: 1, kind: 'bad.kind', args: const {}),
    );
    final sync = service();
    addTearDown(sync.dispose);
    sync.registerHandler('bad.kind', (_, _) async => const SyncOutcome.drop());

    await sync.flush();

    expect(store.pending(), hasLength(1));
    expect(store.pending().single.retries, greaterThanOrEqualTo(1));
  });
}
