import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import 'package:gymboss/config/api_config.dart';
import 'package:gymboss/data/local/local_store.dart';
import 'package:gymboss/data/local/mutation.dart';
import 'package:gymboss/data/services/auth/authenticated_client.dart';
import 'package:gymboss/data/sync/connectivity_service.dart';
import 'package:gymboss/data/sync/network_failure.dart';
import 'package:gymboss/data/sync/sync_service.dart';
import 'package:gymboss/domain/models/workouts/workout.dart';

/// Offline-first workouts repository.
///
/// Reads return cached data when the network is unavailable; owned-workout
/// writes (create/update/delete/log/visibility) apply optimistically to the
/// local cache and are queued in the outbox to sync when connectivity returns.
/// Operations that inherently need the server (public browsing, copy, import,
/// share) surface a clear offline error when there's no connection.
class WorkoutsRepository {
  static const _collection = 'workout';
  static const _ownedKey = 'workouts:owned';
  static const _publicKey = 'workouts:public';
  static const _uuid = Uuid();
  static bool _handlersRegistered = false;

  final AuthenticatedClient _client;
  final LocalStore _store = LocalStore.instance;
  final String _base = '${ApiConfig.apiBaseUrl}/api/v1/workouts';

  WorkoutsRepository({required AuthenticatedClient client}) : _client = client {
    _registerHandlers();
  }

  // ── Reads (cache fallback) ─────────────────────────────────────────────────

  Future<List<Workout>> listOwned() => _cachedList(_base, _ownedKey);
  Future<List<Workout>> listPublic() =>
      _cachedList('$_base/public', _publicKey);

  Future<List<Workout>> _cachedList(String url, String key) async {
    try {
      final resp = await _client
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 20));
      if (resp.statusCode != 200) {
        throw Exception('GET $url HTTP ${resp.statusCode}');
      }
      final raw = (jsonDecode(resp.body) as List).cast<Map<String, dynamic>>();
      for (final doc in raw) {
        final id = doc['id'] as String?;
        if (id != null) await _store.putDoc(_collection, id, doc);
      }
      await _store.putListIds(key, raw.map((d) => d['id'] as String).toList());
      return raw.map(Workout.fromJson).toList();
    } on Object catch (e) {
      if (isTransientNetworkFailure(e) && _store.hasList(key)) {
        return _store
            .getListDocs(_collection, key)
            .map(Workout.fromJson)
            .toList();
      }
      rethrow;
    }
  }

  Future<Workout> get(String id) async {
    try {
      final resp = await _client
          .get(Uri.parse('$_base/$id'))
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        throw Exception('GET workout HTTP ${resp.statusCode}');
      }
      final doc = jsonDecode(resp.body) as Map<String, dynamic>;
      await _store.putDoc(_collection, id, doc);
      return Workout.fromJson(doc);
    } on Object catch (e) {
      final cached = _store.getDoc(_collection, id);
      if (isTransientNetworkFailure(e) && cached != null) {
        return Workout.fromJson(cached);
      }
      rethrow;
    }
  }

  Future<WorkoutStats> stats(String id) async {
    try {
      final resp = await _client
          .get(Uri.parse('$_base/$id/stats'))
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        throw Exception('GET stats HTTP ${resp.statusCode}');
      }
      final doc = jsonDecode(resp.body) as Map<String, dynamic>;
      await _store.putDoc('workout_stats', id, doc);
      return WorkoutStats.fromJson(doc);
    } on Object catch (e) {
      final cached = _store.getDoc('workout_stats', id);
      if (isTransientNetworkFailure(e) && cached != null) {
        return WorkoutStats.fromJson(cached);
      }
      rethrow;
    }
  }

  Future<List<PerformedExerciseLog>> runDetail(String id, String date) async {
    final resp = await _client
        .get(Uri.parse('$_base/$id/history/$date'))
        .timeout(const Duration(seconds: 15));
    if (resp.statusCode != 200) {
      throw Exception('GET run detail HTTP ${resp.statusCode}');
    }
    final list = jsonDecode(resp.body) as List<dynamic>;
    return list
        .map((e) => PerformedExerciseLog.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Writes (optimistic + outbox) ───────────────────────────────────────────

  Future<Workout> create({
    required String name,
    required String comment,
    required List<WorkoutExercise> exercises,
  }) async {
    final serverExercises = exercises.map((e) => e.toJson()).toList();
    final clientRequestId = _uuid.v4();
    // Optimistic local doc with a temp id and full display fields.
    final tempId = 'local:${_uuid.v4()}';
    final doc = _localWorkoutDoc(
      id: tempId,
      name: name,
      comment: comment,
      exercises: exercises,
    );
    await _store.putDoc(_collection, tempId, doc);
    await _store.prependToList(_ownedKey, tempId);

    if (await ConnectivityService.instance.isOnline()) {
      try {
        return await _networkCreate(
          name,
          comment,
          serverExercises,
          clientRequestId: clientRequestId,
          replaceTempId: tempId,
        );
      } on Object catch (e) {
        if (!isTransientNetworkFailure(e)) {
          // Real rejection (e.g. validation) — roll back the optimistic doc.
          await _store.deleteDoc(_collection, tempId);
          await _store.removeFromList(_ownedKey, tempId);
          rethrow;
        }
      }
    }
    await _enqueue('workout.create', {
      'tempId': tempId,
      'client_request_id': clientRequestId,
      'name': name,
      'comment': comment,
      'exercises': serverExercises,
    });
    return Workout.fromJson(doc);
  }

  Future<Workout> update(
    String id, {
    required String name,
    required String comment,
    required List<WorkoutExercise> exercises,
  }) async {
    final serverExercises = exercises.map((e) => e.toJson()).toList();
    final doc = _localWorkoutDoc(
      id: id,
      name: name,
      comment: comment,
      exercises: exercises,
      base: _store.getDoc(_collection, id),
    );
    await _store.putDoc(_collection, id, doc);

    if (!id.startsWith('local:') &&
        await ConnectivityService.instance.isOnline()) {
      try {
        final resp = await _client
            .put(
              Uri.parse('$_base/$id'),
              body: _encode(name, comment, serverExercises),
            )
            .timeout(const Duration(seconds: 20));
        if (resp.statusCode != 200) {
          throw Exception(_err(resp.body, resp.statusCode));
        }
        final fresh = jsonDecode(resp.body) as Map<String, dynamic>;
        await _store.putDoc(_collection, id, fresh);
        return Workout.fromJson(fresh);
      } on Object catch (e) {
        if (!isTransientNetworkFailure(e)) {
          rethrow;
        }
      }
    }
    await _enqueue('workout.update', {
      'id': id,
      'name': name,
      'comment': comment,
      'exercises': serverExercises,
    });
    return Workout.fromJson(doc);
  }

  Future<void> delete(String id) async {
    await _store.deleteDoc(_collection, id);
    await _store.removeFromList(_ownedKey, id);
    if (id.startsWith('local:')) {
      // Never reached the server — cancel its queued create/update.
      await _store.cancelPendingFor(id);
      return;
    }
    if (await ConnectivityService.instance.isOnline()) {
      try {
        final resp = await _client
            .delete(Uri.parse('$_base/$id'))
            .timeout(const Duration(seconds: 15));
        if (resp.statusCode != 204) {
          throw Exception('DELETE HTTP ${resp.statusCode}');
        }
        return;
      } on Object catch (e) {
        if (!isTransientNetworkFailure(e)) {
          rethrow;
        }
      }
    }
    await _enqueue('workout.delete', {'id': id});
  }

  Future<void> logRun(String id, String difficulty) async {
    final operationId = _uuid.v4();
    if (!id.startsWith('local:') &&
        await ConnectivityService.instance.isOnline()) {
      try {
        final resp = await _client
            .post(
              Uri.parse('$_base/$id/run'),
              body: jsonEncode({
                'difficulty': difficulty,
                'operation_id': operationId,
              }),
            )
            .timeout(const Duration(seconds: 15));
        if (resp.statusCode != 204) {
          throw Exception('RUN HTTP ${resp.statusCode}');
        }
        return;
      } on Object catch (e) {
        if (!isTransientNetworkFailure(e)) {
          rethrow;
        }
      }
    }
    await _enqueue('workout.run', {
      'id': id,
      'difficulty': difficulty,
      'operation_id': operationId,
    });
  }

  Future<void> setVisibility(String id, String visibility) async {
    final doc = _store.getDoc(_collection, id);
    if (doc != null) {
      doc['visibility'] = visibility;
      await _store.putDoc(_collection, id, doc);
    }
    if (!id.startsWith('local:') &&
        await ConnectivityService.instance.isOnline()) {
      try {
        final resp = await _client
            .put(
              Uri.parse('$_base/$id/visibility'),
              body: jsonEncode({'visibility': visibility}),
            )
            .timeout(const Duration(seconds: 15));
        if (resp.statusCode != 204) {
          throw Exception('VISIBILITY HTTP ${resp.statusCode}');
        }
        return;
      } on Object catch (e) {
        if (!isTransientNetworkFailure(e)) {
          rethrow;
        }
      }
    }
    await _enqueue('workout.visibility', {'id': id, 'visibility': visibility});
  }

  // ── Online-only (need a live server round-trip) ────────────────────────────

  Future<Workout> copy(String id) async {
    final resp = await _client
        .post(Uri.parse('$_base/$id/copy'))
        .timeout(const Duration(seconds: 15));
    if (resp.statusCode != 201) {
      throw Exception(_err(resp.body, resp.statusCode));
    }
    return Workout.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
  }

  Future<String> share(String id) async {
    final resp = await _client
        .post(Uri.parse('$_base/$id/share'))
        .timeout(const Duration(seconds: 15));
    if (resp.statusCode != 200) {
      throw Exception('SHARE HTTP ${resp.statusCode}');
    }
    return (jsonDecode(resp.body) as Map<String, dynamic>)['code'] as String? ??
        '';
  }

  Future<Workout> import(String code) async {
    final resp = await _client
        .post(Uri.parse('$_base/import'), body: jsonEncode({'code': code}))
        .timeout(const Duration(seconds: 15));
    if (resp.statusCode != 201) {
      throw Exception(_err(resp.body, resp.statusCode));
    }
    return Workout.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
  }

  // ── Internals ──────────────────────────────────────────────────────────────

  Future<Workout> _networkCreate(
    String name,
    String comment,
    List<Map<String, dynamic>> exercises, {
    required String clientRequestId,
    required String replaceTempId,
  }) async {
    final resp = await _client
        .post(
          Uri.parse(_base),
          body: _encode(
            name,
            comment,
            exercises,
            clientRequestId: clientRequestId,
          ),
        )
        .timeout(const Duration(seconds: 20));
    if (resp.statusCode != 201) {
      throw Exception(_err(resp.body, resp.statusCode));
    }
    final fresh = jsonDecode(resp.body) as Map<String, dynamic>;
    await _store.remapId(
      _collection,
      replaceTempId,
      fresh['id'] as String,
      fresh,
    );
    return Workout.fromJson(fresh);
  }

  Future<void> _enqueue(String kind, Map<String, dynamic> args) async {
    await _store.enqueue(
      Mutation(id: _uuid.v4(), seq: _store.nextSeq(), kind: kind, args: args),
    );
    SyncService.instance.flushSoon();
  }

  void _registerHandlers() {
    if (_handlersRegistered) return;
    _handlersRegistered = true;
    final s = SyncService.instance;
    final base = _base;

    s.registerHandler('workout.create', (client, m) async {
      try {
        final resp = await client
            .post(Uri.parse(base), body: _encodeArgs(m.args))
            .timeout(const Duration(seconds: 20));
        if (resp.statusCode == 201) {
          final fresh = jsonDecode(resp.body) as Map<String, dynamic>;
          return SyncOutcome.done(
            collection: _collection,
            remapFromId: m.args['tempId'] as String,
            remapToId: fresh['id'] as String,
            realDoc: fresh,
          );
        }
        return _isClientError(resp.statusCode)
            ? const SyncOutcome.drop()
            : const SyncOutcome.retry();
      } on Object catch (e) {
        return isTransientNetworkFailure(e)
            ? const SyncOutcome.retry()
            : const SyncOutcome.drop();
      }
    });

    s.registerHandler('workout.update', (client, m) async {
      final id = m.args['id'] as String;
      if (id.startsWith('local:')) {
        return const SyncOutcome.retry(); // create hasn't synced yet
      }
      return _replay(
        () => client
            .put(Uri.parse('$base/$id'), body: _encodeArgs(m.args))
            .timeout(const Duration(seconds: 20)),
        ok: 200,
      );
    });

    s.registerHandler('workout.delete', (client, m) async {
      final id = m.args['id'] as String;
      return _replay(
        () => client
            .delete(Uri.parse('$base/$id'))
            .timeout(const Duration(seconds: 15)),
        ok: 204,
      );
    });

    s.registerHandler('workout.run', (client, m) async {
      final id = m.args['id'] as String;
      if (id.startsWith('local:')) return const SyncOutcome.retry();
      return _replay(
        () => client
            .post(
              Uri.parse('$base/$id/run'),
              body: jsonEncode({
                'difficulty': m.args['difficulty'],
                'operation_id': m.args['operation_id'],
              }),
            )
            .timeout(const Duration(seconds: 15)),
        ok: 204,
      );
    });

    s.registerHandler('workout.visibility', (client, m) async {
      final id = m.args['id'] as String;
      if (id.startsWith('local:')) return const SyncOutcome.retry();
      return _replay(
        () => client
            .put(
              Uri.parse('$base/$id/visibility'),
              body: jsonEncode({'visibility': m.args['visibility']}),
            )
            .timeout(const Duration(seconds: 15)),
        ok: 204,
      );
    });
  }

  static Future<SyncOutcome> _replay(
    Future<http.Response> Function() call, {
    required int ok,
  }) async {
    try {
      final resp = await call();
      if (resp.statusCode == ok) return const SyncOutcome.done();
      return _isClientError(resp.statusCode)
          ? const SyncOutcome.drop()
          : const SyncOutcome.retry();
    } on Object catch (e) {
      return isTransientNetworkFailure(e)
          ? const SyncOutcome.retry()
          : const SyncOutcome.drop();
    }
  }

  /// Builds a full, display-ready workout document from editor inputs so an
  /// offline-created/edited workout renders correctly before it syncs.
  Map<String, dynamic> _localWorkoutDoc({
    required String id,
    required String name,
    required String comment,
    required List<WorkoutExercise> exercises,
    Map<String, dynamic>? base,
  }) => {
    'id': id,
    'name': name,
    'comment': comment,
    'visibility': base?['visibility'] ?? 'private',
    'owned': true,
    'share_code': base?['share_code'] ?? '',
    'exercise_count': exercises.length,
    'times_performed': base?['times_performed'] ?? 0,
    'love_coefficient': base?['love_coefficient'] ?? 0,
    'exercises':
        exercises
            .map(
              (e) => {
                'exercise_id': e.exerciseId,
                'name': e.name,
                'image_url': e.imageUrl,
                'image_url2': e.imageUrl2,
                'muscle_group': e.muscleGroup,
                'rest_seconds': e.restSeconds,
                'comment': e.comment,
                'sets': e.sets.map((s) => s.toJson()).toList(),
              },
            )
            .toList(),
  };

  static String _encode(
    String name,
    String comment,
    List<Map<String, dynamic>> exercises, {
    String? clientRequestId,
  }) => jsonEncode({
    'name': name,
    'comment': comment,
    'exercises': exercises,
    if (clientRequestId != null) 'client_request_id': clientRequestId,
  });

  static String _encodeArgs(Map<String, dynamic> args) => jsonEncode({
    'name': args['name'],
    'comment': args['comment'],
    'exercises': args['exercises'],
    'client_request_id': args['client_request_id'],
  });

  static bool _isClientError(int code) => code >= 400 && code < 500;

  /// A failure caused by the network being unavailable (as opposed to an HTTP
  /// status error the server actually returned). Kept dart:io-free for web.
  static String _err(String body, int code) {
    try {
      return (jsonDecode(body) as Map<String, dynamic>)['error'] as String? ??
          'HTTP $code';
    } catch (_) {
      return 'HTTP $code';
    }
  }
}
