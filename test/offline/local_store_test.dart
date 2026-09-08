import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gymboss/data/local/local_store.dart';
import 'package:gymboss/data/local/mutation.dart';
import 'package:hive/hive.dart';

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

  test('sequence ids stay unique during a burst', () {
    final values = List.generate(10000, (_) => store.nextSeq());
    expect(values.toSet(), hasLength(values.length));
    for (var index = 1; index < values.length; index++) {
      expect(values[index], greaterThan(values[index - 1]));
    }
  });

  test('one corrupt cache entry does not poison documents or lists', () async {
    final docs = Hive.box<String>('docs');
    final lists = Hive.box<String>('lists');
    await docs.put('anonymous|workout/broken', '{not json');
    await lists.put('anonymous|workouts:broken', '{not json');

    expect(store.getDoc('workout', 'broken'), isNull);
    expect(store.getListIds('workouts:broken'), isEmpty);
  });

  test('one corrupt outbox entry does not block later mutations', () async {
    final outbox = Hive.box<String>('outbox');
    await outbox.put('anonymous|broken', '{not json');
    await store.enqueue(
      Mutation(
        id: 'healthy',
        seq: store.nextSeq(),
        kind: 'workout.update',
        args: const {'id': 'w1'},
      ),
    );

    expect(store.pending().map((mutation) => mutation.id), ['healthy']);
  });

  test('dead letters are durable but excluded from the replay queue', () async {
    await store.enqueue(
      Mutation(
        id: 'dead',
        seq: 1,
        kind: 'workout.update',
        args: const {},
        deadLetter: true,
      ),
    );
    await store.enqueue(
      Mutation(id: 'live', seq: 2, kind: 'workout.update', args: const {}),
    );

    expect(store.pending().map((mutation) => mutation.id), ['live']);
    expect(store.deadLetters().map((mutation) => mutation.id), ['dead']);

    await store.retryDeadLetters();
    expect(store.deadLetters(), isEmpty);
    expect(store.pending().map((mutation) => mutation.id), ['dead', 'live']);
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

  test('cancelPendingFor finds nested string and numeric references', () async {
    await store.enqueue(
      Mutation(
        id: 'nested-string',
        seq: 1,
        kind: 'workout.create',
        args: {
          'exercises': [
            {
              'folder': {'id': 'local:nested'},
            },
          ],
        },
      ),
    );
    await store.enqueue(
      Mutation(
        id: 'nested-int',
        seq: 2,
        kind: 'workout.create',
        args: {
          'exercises': [
            {'exercise_id': -42},
          ],
        },
      ),
    );

    await store.cancelPendingFor('local:nested');
    expect(store.pending().map((mutation) => mutation.id), ['nested-int']);

    await store.cancelPendingFor('-42');
    expect(store.pending(), isEmpty);
  });

  test('cache and outbox are isolated between authenticated users', () async {
    await store.setScope('user-a', migrateLegacy: false);
    await store.clear();
    await store.putDoc('workout', 'w1', {'id': 'w1', 'name': 'Private A'});
    await store.enqueue(
      Mutation(id: 'a1', seq: 1, kind: 'workout.update', args: {'id': 'w1'}),
    );

    await store.setScope('user-b', migrateLegacy: false);
    await store.clear();
    expect(store.getDoc('workout', 'w1'), isNull);
    expect(store.pending(), isEmpty);

    await store.setScope('user-a', migrateLegacy: false);
    expect(store.getDoc('workout', 'w1')?['name'], 'Private A');
    expect(store.pending().single.id, 'a1');
  });

  test(
    'remapId updates foreign-key references in docs and mutations',
    () async {
      await store.putDoc('workout-folder', 'local:folder', {
        'id': 'local:folder',
        'name': 'Strength',
      });
      await store.putListIds('workout-folders', ['local:folder']);
      await store.putDoc('workout', 'w1', {
        'id': 'w1',
        'folder_id': 'local:folder',
      });
      await store.enqueue(
        Mutation(
          id: 'assign',
          seq: 1,
          kind: 'workout.assignFolder',
          args: {'id': 'w1', 'folderId': 'local:folder'},
        ),
      );

      await store.remapId('workout-folder', 'local:folder', 'folder-1', {
        'id': 'folder-1',
        'name': 'Strength',
      });

      expect(store.getDoc('workout', 'w1')?['folder_id'], 'folder-1');
      expect(store.pending().single.args['folderId'], 'folder-1');
      expect(store.getListIds('workout-folders'), ['folder-1']);
    },
  );

  test(
    'remapId preserves numeric exercise ids in nested workout data',
    () async {
      await store.putDoc('workout', 'w1', {
        'id': 'w1',
        'exercises': [
          {'exercise_id': -42, 'name': 'Custom press'},
        ],
      });
      await store.enqueue(
        Mutation(
          id: 'create-workout',
          seq: 1,
          kind: 'workout.create',
          args: {
            'exercises': [
              {'exercise_id': -42},
            ],
          },
        ),
      );

      await store.remapId('exercise', '-42', '731', {
        'id': 731,
        'name': 'Custom press',
      });

      final exercise =
          (store.getDoc('workout', 'w1')!['exercises'] as List).single as Map;
      expect(exercise['exercise_id'], 731);
      final pendingExercise =
          (store.pending().single.args['exercises'] as List).single as Map;
      expect(pendingExercise['exercise_id'], 731);
    },
  );
}
