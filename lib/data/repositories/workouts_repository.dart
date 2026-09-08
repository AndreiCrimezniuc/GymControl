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
import 'package:gymboss/domain/models/json_readers.dart';
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
  static const _folderCollection = 'workout-folder';
  static const _ownedKey = 'workouts:owned';
  static const _publicKey = 'workouts:public';
  static const _foldersKey = 'workout-folders';
  static const _uuid = Uuid();
  static bool _handlersRegistered = false;

  final AuthenticatedClient _client;
  final Future<bool> Function() _isOnline;
  final LocalStore _store = LocalStore.instance;
  final String _base = '${ApiConfig.apiBaseUrl}/api/v1/workouts';

  WorkoutsRepository({
    required AuthenticatedClient client,
    Future<bool> Function()? isOnline,
  }) : _client = client,
       _isOnline = isOnline ?? ConnectivityService.instance.isOnline {
    _registerHandlers();
  }

  // ── Reads (cache fallback) ─────────────────────────────────────────────────

  Future<List<Workout>> listOwned({bool forceRefresh = false}) =>
      _cachedList(_base, _ownedKey, forceRefresh: forceRefresh);
  Future<List<Workout>> listPublic({bool forceRefresh = false}) =>
      _cachedList('$_base/public', _publicKey, forceRefresh: forceRefresh);

  Future<List<WorkoutFolder>> listFolders({bool forceRefresh = false}) async {
    if (!forceRefresh && _store.hasList(_foldersKey)) {
      final cached = _cachedFolders();
      unawaited(_refreshFoldersInBackground());
      return cached;
    }
    if (!await _isOnline() && _store.hasList(_foldersKey)) {
      return _cachedFolders();
    }
    return _refreshFolders();
  }

  Future<List<WorkoutFolder>> _refreshFolders() async {
    try {
      final response = await _client
          .get(Uri.parse('${ApiConfig.apiBaseUrl}/api/v1/workout-folders'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        throw Exception(_err(response.body, response.statusCode));
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! List) {
        throw const FormatException('folders is not a list');
      }
      final raw = jsonObjectList(
        decoded,
        (item) => item,
        maxItems: 10000,
      ).where((item) => item['id'] is String).toList(growable: false);
      for (final folder in raw) {
        await _store.putDoc(_folderCollection, folder['id'] as String, folder);
      }
      await _store.putListIds(
        _foldersKey,
        raw.map((folder) => folder['id'] as String).toList(),
      );
      return raw.map(WorkoutFolder.fromJson).toList();
    } on Object catch (error) {
      if (isTransientNetworkFailure(error) && _store.hasList(_foldersKey)) {
        return _cachedFolders();
      }
      rethrow;
    }
  }

  Future<void> _refreshFoldersInBackground() async {
    try {
      if (!await _isOnline()) return;
      await _refreshFolders();
    } catch (_) {
      // Keep the last durable snapshot and retry later.
    }
  }

  List<WorkoutFolder> _cachedFolders() => _store
      .getListDocs(_folderCollection, _foldersKey)
      .map(WorkoutFolder.fromJson)
      .toList();

  Future<WorkoutFolder> createFolder(String name) async {
    final tempId = 'local:${_uuid.v4()}';
    final doc = {
      'id': tempId,
      'name': name,
      'position': _store.getListIds(_foldersKey).length,
    };
    await _store.putDoc(_folderCollection, tempId, doc);
    await _store.putListIds(_foldersKey, [
      ..._store.getListIds(_foldersKey),
      tempId,
    ]);
    final clientRequestId = _uuid.v4();
    await _enqueue('folder.create', {
      'tempId': tempId,
      'name': name,
      'client_request_id': clientRequestId,
    });
    return WorkoutFolder.fromJson(doc);
  }

  Future<void> renameFolder(String id, String name) async {
    final cached = _store.getDoc(_folderCollection, id);
    if (cached != null) {
      await _store.putDoc(_folderCollection, id, {...cached, 'name': name});
    }
    await _enqueue('folder.rename', {'id': id, 'name': name});
  }

  Future<void> deleteFolder(String id) async {
    await _store.deleteDoc(_folderCollection, id);
    await _store.removeFromList(_foldersKey, id);
    for (final workoutId in _store.getListIds(_ownedKey).toList()) {
      final workout = _store.getDoc(_collection, workoutId);
      if (workout?['folder_id'] == id) {
        await _store.deleteDoc(_collection, workoutId);
        await _store.removeFromList(_ownedKey, workoutId);
      }
    }
    if (id.startsWith('local:')) {
      await _store.cancelPendingFor(id);
      return;
    }
    await _enqueue('folder.delete', {'id': id});
  }

  Future<void> assignFolder(String workoutId, String? folderId) async {
    final cached = _store.getDoc(_collection, workoutId);
    if (cached != null) {
      await _store.putDoc(_collection, workoutId, {
        ...cached,
        'folder_id': folderId,
      });
    }
    await _enqueue('workout.assignFolder', {
      'id': workoutId,
      'folderId': folderId,
    });
  }

  Future<List<Workout>> _cachedList(
    String url,
    String key, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _store.hasList(key)) {
      final cached = _readCachedWorkouts(key);
      unawaited(_refreshWorkoutListInBackground(url, key));
      return cached;
    }
    if (!await _isOnline() && _store.hasList(key)) {
      return _readCachedWorkouts(key);
    }
    return _refreshWorkoutList(url, key);
  }

  Future<List<Workout>> _refreshWorkoutList(String url, String key) async {
    try {
      final raw = <Map<String, dynamic>>[];
      var cursor = '';
      final seenCursors = <String>{};
      var pages = 0;
      do {
        if (++pages > 100) break;
        final baseUri = Uri.parse(url);
        final pageUri = baseUri.replace(
          queryParameters: {
            ...baseUri.queryParameters,
            'limit': '100',
            if (cursor.isNotEmpty) 'cursor': cursor,
          },
        );
        final resp = await _client
            .get(pageUri)
            .timeout(const Duration(seconds: 20));
        if (resp.statusCode != 200) {
          throw Exception('GET $pageUri HTTP ${resp.statusCode}');
        }
        final decoded = jsonDecode(resp.body);
        if (decoded is! List) {
          throw const FormatException('workouts page is not a list');
        }
        raw.addAll(
          jsonObjectList(
            decoded,
            (item) => item,
            maxItems: 100,
          ).where((item) => item['id'] is String),
        );
        final next = resp.headers['x-next-cursor'] ?? '';
        if (next.isEmpty || !seenCursors.add(next)) {
          cursor = '';
        } else {
          cursor = next;
        }
      } while (cursor.isNotEmpty);

      for (final doc in raw) {
        final id = doc['id'] as String?;
        if (id != null) await _store.putDoc(_collection, id, doc);
      }
      await _store.putListIds(key, raw.map((d) => d['id'] as String).toList());
      return raw.map(Workout.fromJson).toList();
    } on Object catch (e) {
      if (isTransientNetworkFailure(e) && _store.hasList(key)) {
        return _readCachedWorkouts(key);
      }
      rethrow;
    }
  }

  Future<void> _refreshWorkoutListInBackground(String url, String key) async {
    try {
      if (!await _isOnline()) return;
      await _refreshWorkoutList(url, key);
    } catch (_) {
      // Keep the last durable snapshot and retry later.
    }
  }

  List<Workout> _readCachedWorkouts(String key) =>
      _store.getListDocs(_collection, key).map(Workout.fromJson).toList();

  Future<Workout> get(String id, {bool forceRefresh = false}) async {
    final cached = _store.getDoc(_collection, id);
    if (!forceRefresh && cached != null) {
      unawaited(_refreshWorkoutInBackground(id));
      return Workout.fromJson(cached);
    }
    if (!await _isOnline()) {
      throw Exception('Workout is not available offline yet');
    }
    return _refreshWorkout(id);
  }

  Future<Workout> _refreshWorkout(String id) async {
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

  Future<void> _refreshWorkoutInBackground(String id) async {
    try {
      if (await _isOnline()) await _refreshWorkout(id);
    } catch (_) {}
  }

  /// Statistics-screen summary. Cached so it renders offline; [period] is
  /// 'year' or 'all'.
  Future<StatsSummary> statsSummary({
    String period = 'all',
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'summary_$period';
    final cached = _store.getDoc('stats_summary', cacheKey);
    if (!forceRefresh && cached != null) {
      unawaited(_refreshStatsSummaryInBackground(period));
      return StatsSummary.fromJson(cached);
    }
    if (!await _isOnline()) return StatsSummary.empty;
    return _refreshStatsSummary(period);
  }

  Future<StatsSummary> _refreshStatsSummary(String period) async {
    final url = '${ApiConfig.apiBaseUrl}/api/v1/stats/summary?period=$period';
    final cacheKey = 'summary_$period';
    try {
      final resp = await _client
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        throw Exception('GET stats/summary HTTP ${resp.statusCode}');
      }
      final doc = jsonDecode(resp.body) as Map<String, dynamic>;
      await _store.putDoc('stats_summary', cacheKey, doc);
      return StatsSummary.fromJson(doc);
    } on Object catch (e) {
      final cached = _store.getDoc('stats_summary', cacheKey);
      if (isTransientNetworkFailure(e) && cached != null) {
        return StatsSummary.fromJson(cached);
      }
      rethrow;
    }
  }

  Future<void> _refreshStatsSummaryInBackground(String period) async {
    try {
      if (await _isOnline()) await _refreshStatsSummary(period);
    } catch (_) {}
  }

  Future<List<ActivityPoint>> activity({
    String period = 'all',
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'activity_$period';
    final cached = _store.getDoc('stats_activity', cacheKey);
    if (!forceRefresh && cached != null) {
      unawaited(_refreshActivityInBackground(period));
      return _activityFromCache(cached);
    }
    if (!await _isOnline()) return const [];
    return _refreshActivity(period);
  }

  Future<List<ActivityPoint>> _refreshActivity(String period) async {
    final cacheKey = 'activity_$period';
    final uri = Uri.parse(
      '${ApiConfig.apiBaseUrl}/api/v1/stats/activity?period=$period',
    );
    try {
      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw Exception('GET stats/activity HTTP ${response.statusCode}');
      }
      final raw = (jsonDecode(response.body) as List)
          .cast<Map<String, dynamic>>();
      await _store.putDoc('stats_activity', cacheKey, {'items': raw});
      return raw.map(ActivityPoint.fromJson).toList();
    } on Object catch (error) {
      final cached = _store.getDoc('stats_activity', cacheKey);
      if (isTransientNetworkFailure(error) && cached != null) {
        return _activityFromCache(cached);
      }
      rethrow;
    }
  }

  Future<void> _refreshActivityInBackground(String period) async {
    try {
      if (await _isOnline()) await _refreshActivity(period);
    } catch (_) {}
  }

  List<ActivityPoint> _activityFromCache(Map<String, dynamic> cached) =>
      ((cached['items'] as List?) ?? const [])
          .map((item) => ActivityPoint.fromJson(item as Map<String, dynamic>))
          .toList();

  Future<WorkoutStats> stats(String id, {bool forceRefresh = false}) async {
    final cached = _store.getDoc('workout_stats', id);
    if (!forceRefresh && cached != null) {
      unawaited(_refreshWorkoutStatsInBackground(id));
      return WorkoutStats.fromJson(cached);
    }
    if (!await _isOnline()) return WorkoutStats.empty;
    return _refreshWorkoutStats(id);
  }

  Future<WorkoutStats> _refreshWorkoutStats(String id) async {
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

  Future<void> _refreshWorkoutStatsInBackground(String id) async {
    try {
      if (await _isOnline()) await _refreshWorkoutStats(id);
    } catch (_) {}
  }

  Future<List<PerformedExerciseLog>> runDetail(
    String id,
    String date, {
    String sessionId = '',
    bool forceRefresh = false,
  }) async {
    final cacheId = '$id:$date:${sessionId.isEmpty ? 'legacy' : sessionId}';
    final cached = _store.getDoc('workout_run_detail', cacheId);
    if (!forceRefresh && cached != null) {
      unawaited(_refreshRunDetailInBackground(id, date, sessionId));
      return _runDetailFromCache(cached);
    }
    if (!await _isOnline()) return const [];
    return _refreshRunDetail(id, date, sessionId);
  }

  Future<List<PerformedExerciseLog>> _refreshRunDetail(
    String id,
    String date,
    String sessionId,
  ) async {
    final cacheId = '$id:$date:${sessionId.isEmpty ? 'legacy' : sessionId}';
    try {
      final uri = Uri.parse('$_base/$id/history/$date').replace(
        queryParameters: sessionId.isEmpty ? null : {'session_id': sessionId},
      );
      final resp = await _client.get(uri).timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        throw Exception('GET run detail HTTP ${resp.statusCode}');
      }
      final list = jsonDecode(resp.body) as List<dynamic>;
      await _store.putDoc('workout_run_detail', cacheId, {'items': list});
      return list
          .map((e) => PerformedExerciseLog.fromJson(e as Map<String, dynamic>))
          .toList();
    } on Object catch (error) {
      final cached = _store.getDoc('workout_run_detail', cacheId);
      if (isTransientNetworkFailure(error) && cached != null) {
        return _runDetailFromCache(cached);
      }
      rethrow;
    }
  }

  Future<void> _refreshRunDetailInBackground(
    String id,
    String date,
    String sessionId,
  ) async {
    try {
      if (await _isOnline()) await _refreshRunDetail(id, date, sessionId);
    } catch (_) {}
  }

  List<PerformedExerciseLog> _runDetailFromCache(Map<String, dynamic> cached) =>
      ((cached['items'] as List?) ?? const [])
          .map((e) => PerformedExerciseLog.fromJson(e as Map<String, dynamic>))
          .toList();

  Future<WorkoutSuggestion> requestAiSuggestion(String id) async {
    final response = await _client
        .post(Uri.parse('$_base/$id/ai-suggest'))
        .timeout(const Duration(seconds: 45));
    if (response.statusCode != 200) {
      throw Exception(_err(response.body, response.statusCode));
    }
    return WorkoutSuggestion.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  // ── Writes (optimistic + outbox) ───────────────────────────────────────────

  Future<Workout> create({
    required String name,
    required String comment,
    required List<WorkoutExercise> exercises,
    double deloadFactor = 0.70,
    String type = 'gym',
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
      type: type,
    );
    doc['deload_factor'] = deloadFactor;
    await _store.putDoc(_collection, tempId, doc);
    await _store.prependToList(_ownedKey, tempId);

    await _enqueue('workout.create', {
      'tempId': tempId,
      'client_request_id': clientRequestId,
      'name': name,
      'comment': comment,
      'deload_factor': deloadFactor,
      'type': type,
      'exercises': serverExercises,
    });
    return Workout.fromJson(doc);
  }

  Future<Workout> update(
    String id, {
    required String name,
    required String comment,
    required List<WorkoutExercise> exercises,
    double deloadFactor = 0.70,
    String type = 'gym',
  }) async {
    final serverExercises = exercises.map((e) => e.toJson()).toList();
    final doc = _localWorkoutDoc(
      id: id,
      name: name,
      comment: comment,
      exercises: exercises,
      type: type,
      base: _store.getDoc(_collection, id),
    );
    doc['deload_factor'] = deloadFactor;
    await _store.putDoc(_collection, id, doc);

    await _enqueue('workout.update', {
      'id': id,
      'name': name,
      'comment': comment,
      'deload_factor': deloadFactor,
      'type': type,
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
    await _enqueue('workout.delete', {'id': id});
  }

  Future<void> logRun(
    String id,
    String difficulty, {
    int durationSeconds = 0,
    String? sessionId,
    DateTime? performedAt,
  }) async {
    final operationId = _uuid.v4();
    final localNow = performedAt ?? DateTime.now();
    final now =
        '${localNow.year.toString().padLeft(4, '0')}-'
        '${localNow.month.toString().padLeft(2, '0')}-'
        '${localNow.day.toString().padLeft(2, '0')}';
    final cachedStats = _store.getDoc('workout_stats', id);
    if (cachedStats != null) {
      final history = List<Map<String, dynamic>>.from(
        (cachedStats['history'] as List? ?? const []).map(
          (item) => Map<String, dynamic>.from(item as Map),
        ),
      );
      history.insert(0, {
        'date': now,
        'difficulty': difficulty,
        'session_id': sessionId ?? '',
      });
      if (history.length > 30) history.removeRange(30, history.length);
      await _store.putDoc('workout_stats', id, {
        ...cachedStats,
        'times_performed':
            ((cachedStats['times_performed'] as num?)?.toInt() ?? 0) + 1,
        'history': history,
      });
    }
    final cachedWorkout = _store.getDoc(_collection, id);
    if (cachedWorkout != null) {
      await _store.putDoc(_collection, id, {
        ...cachedWorkout,
        'times_performed':
            ((cachedWorkout['times_performed'] as num?)?.toInt() ?? 0) + 1,
      });
    }
    await _enqueue('workout.run', {
      'id': id,
      'difficulty': difficulty,
      'duration_seconds': durationSeconds,
      'operation_id': operationId,
      'session_id': sessionId,
      'performed_at': now,
    });
  }

  Future<void> setVisibility(String id, String visibility) async {
    final doc = _store.getDoc(_collection, id);
    if (doc != null) {
      doc['visibility'] = visibility;
      await _store.putDoc(_collection, id, doc);
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
    final folderBase = '${ApiConfig.apiBaseUrl}/api/v1/workout-folders';

    s.registerHandler('folder.create', (client, m) async {
      try {
        final response = await client
            .post(
              Uri.parse(folderBase),
              body: jsonEncode({
                'name': m.args['name'],
                'client_request_id': m.args['client_request_id'],
              }),
            )
            .timeout(const Duration(seconds: 15));
        if (response.statusCode == 201) {
          final fresh = jsonDecode(response.body) as Map<String, dynamic>;
          return SyncOutcome.done(
            collection: _folderCollection,
            remapFromId: m.args['tempId'] as String,
            remapToId: fresh['id'] as String,
            realDoc: fresh,
          );
        }
        return isPermanentSyncStatus(response.statusCode)
            ? const SyncOutcome.drop()
            : const SyncOutcome.retry();
      } on Object {
        return const SyncOutcome.retry();
      }
    });

    s.registerHandler('folder.rename', (client, m) async {
      final id = m.args['id'] as String;
      if (id.startsWith('local:')) return const SyncOutcome.retry();
      return _replay(
        () => client
            .put(
              Uri.parse('$folderBase/$id'),
              body: jsonEncode({'name': m.args['name']}),
            )
            .timeout(const Duration(seconds: 15)),
        ok: 204,
      );
    });

    s.registerHandler('folder.delete', (client, m) async {
      final id = m.args['id'] as String;
      return _replay(
        () => client
            .delete(Uri.parse('$folderBase/$id'))
            .timeout(const Duration(seconds: 15)),
        ok: 204,
      );
    });

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
        return isPermanentSyncStatus(resp.statusCode)
            ? const SyncOutcome.drop()
            : const SyncOutcome.retry();
      } on Object {
        return const SyncOutcome.retry();
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
                'duration_seconds': m.args['duration_seconds'] ?? 0,
                'operation_id': m.args['operation_id'],
                'session_id': m.args['session_id'],
                'performed_at': m.args['performed_at'],
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

    s.registerHandler('workout.assignFolder', (client, m) async {
      final id = m.args['id'] as String;
      final folderId = m.args['folderId'] as String?;
      if (id.startsWith('local:') ||
          (folderId?.startsWith('local:') ?? false)) {
        return const SyncOutcome.retry();
      }
      return _replay(
        () => client
            .put(
              Uri.parse('$base/$id/folder'),
              body: jsonEncode({'folder_id': folderId}),
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
      return syncOutcomeForStatus(resp.statusCode, success: ok);
    } on Object {
      return const SyncOutcome.retry();
    }
  }

  /// Builds a full, display-ready workout document from editor inputs so an
  /// offline-created/edited workout renders correctly before it syncs.
  Map<String, dynamic> _localWorkoutDoc({
    required String id,
    required String name,
    required String comment,
    required List<WorkoutExercise> exercises,
    String type = 'gym',
    Map<String, dynamic>? base,
  }) => {
    'id': id,
    'name': name,
    'comment': comment,
    'type': type,
    'visibility': base?['visibility'] ?? 'private',
    'owned': true,
    'share_code': base?['share_code'] ?? '',
    'exercise_count': exercises.length,
    'times_performed': base?['times_performed'] ?? 0,
    'folder_id': base?['folder_id'],
    'exercises': exercises
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

  static String _encodeArgs(Map<String, dynamic> args) => jsonEncode({
    'name': args['name'],
    'comment': args['comment'],
    'exercises': args['exercises'],
    if (args['deload_factor'] != null) 'deload_factor': args['deload_factor'],
    if (args['type'] != null) 'type': args['type'],
    'client_request_id': args['client_request_id'],
  });

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
