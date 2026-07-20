import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gymboss/data/local/local_store.dart';
import 'package:gymboss/data/local/mutation.dart';

void main() {
  final store = LocalStore.instance;

  setUpAll(() async {
    final dir = Directory.systemTemp.createTempSync('gymboss_offline_test');
    await store.init(path: dir.path);
  });

  setUp(() async => store.clear());

  test('document cache round-trips', () async {
    await store.putDoc('workout', 'w1', {'id': 'w1', 'name': 'Push'});
    expect(store.getDoc('workout', 'w1')!['name'], 'Push');
    await store.deleteDoc('workout', 'w1');
    expect(store.getDoc('workout', 'w1'), isNull);
  });

  test('list snapshot hydrates referenced docs in order', () async {
    await store.putDoc('workout', 'a', {'id': 'a'});
    await store.putDoc('workout', 'b', {'id': 'b'});
    await store.putListIds('workouts:owned', ['b', 'a']);
    expect(store.getListDocs('workout', 'workouts:owned').map((d) => d['id']), [
      'b',
      'a',
    ]);

    await store.prependToList('workouts:owned', 'a'); // moves 'a' to front
    expect(store.getListIds('workouts:owned'), ['a', 'b']);
    await store.removeFromList('workouts:owned', 'b');
    expect(store.getListIds('workouts:owned'), ['a']);
  });

  test('outbox preserves seq order and removal', () async {
    await store.enqueue(
      Mutation(id: 'm2', seq: 2, kind: 'workout.update', args: {'id': 'x'}),
    );
    await store.enqueue(
      Mutation(id: 'm1', seq: 1, kind: 'workout.create', args: {'tempId': 'x'}),
    );
    expect(store.pending().map((m) => m.id), ['m1', 'm2']);
    await store.removeMutation('m1');
    expect(store.pending().map((m) => m.id), ['m2']);
  });

  test(
    'remapId reconciles temp id across docs, lists, and pending mutations',
    () async {
      await store.putDoc('workout', 'local:tmp', {
        'id': 'local:tmp',
        'name': 'New',
      });
      await store.putListIds('workouts:owned', ['local:tmp', 'other']);
      await store.enqueue(
        Mutation(
          id: 'u1',
          seq: 5,
          kind: 'workout.update',
          args: {'id': 'local:tmp', 'name': 'Edited'},
        ),
      );

      await store.remapId('workout', 'local:tmp', 'srv-99', {
        'id': 'srv-99',
        'name': 'New',
      });

      expect(store.getDoc('workout', 'local:tmp'), isNull);
      expect(store.getDoc('workout', 'srv-99')!['name'], 'New');
      expect(store.getListIds('workouts:owned'), ['srv-99', 'other']);
      expect(store.pending().single.args['id'], 'srv-99');
    },
  );

  test('cancelPendingFor drops queued work for a temp id', () async {
    await store.enqueue(
      Mutation(
        id: 'c1',
        seq: 1,
        kind: 'workout.create',
        args: {'tempId': 'local:z'},
      ),
    );
    await store.enqueue(
      Mutation(
        id: 'u1',
        seq: 2,
        kind: 'workout.update',
        args: {'id': 'local:z'},
      ),
    );
    await store.enqueue(
      Mutation(id: 'k1', seq: 3, kind: 'workout.update', args: {'id': 'keep'}),
    );

    await store.cancelPendingFor('local:z');

    expect(store.pending().map((m) => m.id), ['k1']);
  });
}
