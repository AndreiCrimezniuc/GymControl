import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;

import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import 'package:gymboss/config/api_config.dart';
import 'package:gymboss/data/local/exercise_media_cache.dart';
import 'package:gymboss/data/local/bundled_catalog_snapshot.dart';
import 'package:gymboss/data/local/local_store.dart';
import 'package:gymboss/data/local/mutation.dart';
import 'package:gymboss/data/services/auth/authenticated_client.dart';
import 'package:gymboss/data/sync/connectivity_service.dart';
import 'package:gymboss/data/sync/network_failure.dart';
import 'package:gymboss/data/sync/sync_service.dart';
import 'package:gymboss/domain/models/exercises/exercise_catalog.dart';
import 'package:gymboss/domain/models/exercises/exercise_catalog_policy.dart';
import 'package:gymboss/domain/models/json_readers.dart';

class ExercisesRepository {
  static const _catalogCollection = 'exercise';
  static const _catalogKey = 'exercises:catalog';
  static const _uuid = Uuid();
  static bool _handlersRegistered = false;

  final AuthenticatedClient _client;
  final Future<bool> Function() _isOnline;
  final LocalStore _store = LocalStore.instance;
  final String _base = '${ApiConfig.apiBaseUrl}/api/v1/exercises';

  ExercisesRepository({
    required AuthenticatedClient client,
    Future<bool> Function()? isOnline,
  }) : _client = client,
       _isOnline = isOnline ?? ConnectivityService.instance.isOnline {
    _registerHandlers();
  }

  Future<List<ExerciseCatalogItem>> getCatalog({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _store.hasList(_catalogKey)) {
      final cached = _cachedCatalog();
      unawaited(_refreshCatalogInBackground());
      return cached;
    }
    if (!await _isOnline()) {
      return _store.hasList(_catalogKey)
          ? _cachedCatalog()
          : _installBundledCatalogSnapshot();
    }
    try {
      return await _refreshCatalog();
    } on Object catch (error) {
      // Connectivity signals are advisory: a captive portal or a just-failed
      // server must not make a first-ever launch useless. Keep the built-in
      // snapshot available until a real catalog response arrives.
      if (isTransientNetworkFailure(error) && !_store.hasList(_catalogKey)) {
        return _installBundledCatalogSnapshot();
      }
      rethrow;
    }
  }

  Future<List<ExerciseCatalogItem>> _installBundledCatalogSnapshot() async {
    for (final doc in bundledCatalogSnapshot) {
      await _store.putDoc(_catalogCollection, '${doc['id']}', doc);
    }
    await _store.putListIds(
      _catalogKey,
      bundledCatalogSnapshot.map((doc) => '${doc['id']}').toList(),
    );
    return _cachedCatalog();
  }

  Future<List<ExerciseCatalogItem>> _refreshCatalog() async {
    try {
      final resp = await _client
          .get(Uri.parse(_base))
          .timeout(const Duration(seconds: 20));
      if (resp.statusCode != 200) {
        throw Exception('GET /exercises HTTP ${resp.statusCode}');
      }
      final decoded = jsonDecode(resp.body);
      if (decoded is! List) {
        throw const FormatException('catalog is not a list');
      }
      final raw = jsonObjectList(
        decoded,
        (item) => item,
        maxItems: 10000,
      ).where((item) => item['id'] is num).toList(growable: false);
      final curated = ExerciseCatalogPolicy.curate(
        raw.map(ExerciseCatalogItem.fromJson),
      );
      final visibleIds = curated.map((exercise) => '${exercise.id}').toSet();
      final visibleRaw = raw
          .where((doc) => visibleIds.contains('${doc['id']}'))
          .toList(growable: false);
      for (final doc in visibleRaw) {
        await _store.putDoc(_catalogCollection, '${doc['id']}', doc);
      }
      await _store.putListIds(
        _catalogKey,
        visibleRaw.map((doc) => '${doc['id']}').toList(),
      );
      unawaited(ExerciseMediaCache.warm(curated));
      return curated;
    } on Object catch (error) {
      if (isTransientNetworkFailure(error) && _store.hasList(_catalogKey)) {
        return _cachedCatalog();
      }
      rethrow;
    }
  }

  Future<void> _refreshCatalogInBackground() async {
    try {
      if (!await _isOnline()) return;
      await _refreshCatalog();
    } catch (_) {
      // A durable snapshot is already on screen; refresh again on the next
      // launch, connectivity event, or explicit pull-to-refresh.
    }
  }

  List<ExerciseCatalogItem> _cachedCatalog() => ExerciseCatalogPolicy.curate(
    _store
        .getListDocs(_catalogCollection, _catalogKey)
        .map(ExerciseCatalogItem.fromJson),
  );

  Future<ExerciseStats> getStats(int id, {bool forceRefresh = false}) async {
    final cached = _store.getDoc('exercise_stats', '$id');
    if (!forceRefresh && cached != null) {
      unawaited(_refreshStatsInBackground(id));
      return ExerciseStats.fromJson(cached);
    }
    // Pull-to-refresh asks for newer data; it must never erase a usable local
    // record just because the device is offline.
    if (!await _isOnline()) {
      return cached == null ? _emptyStats(id) : ExerciseStats.fromJson(cached);
    }
    return _refreshStats(id);
  }

  Future<ExerciseStats> _refreshStats(int id) async {
    try {
      final resp = await _client
          .get(Uri.parse('$_base/$id/stats'))
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        throw Exception('GET /exercises/$id/stats HTTP ${resp.statusCode}');
      }
      final doc = jsonDecode(resp.body) as Map<String, dynamic>;
      await _store.putDoc('exercise_stats', '$id', doc);
      return ExerciseStats.fromJson(doc);
    } on Object catch (error) {
      final cached = _store.getDoc('exercise_stats', '$id');
      if (isTransientNetworkFailure(error) && cached != null) {
        return ExerciseStats.fromJson(cached);
      }
      rethrow;
    }
  }

  Future<void> _refreshStatsInBackground(int id) async {
    try {
      if (await _isOnline()) await _refreshStats(id);
    } catch (_) {}
  }

  ExerciseStats _emptyStats(int id) =>
      ExerciseStats.fromJson({'exercise_id': id});

  Future<List<ExerciseHistorySession>> getHistory(
    int id, {
    bool forceRefresh = false,
  }) async {
    final cached = _store.getDoc('exercise_history', '$id');
    if (!forceRefresh && cached != null) {
      unawaited(_refreshHistoryInBackground(id));
      return _historyFromCache(cached);
    }
    if (!await _isOnline()) {
      return cached == null ? const [] : _historyFromCache(cached);
    }
    return _refreshHistory(id);
  }

  Future<String> getPersistentNote(
    int exerciseId, {
    bool forceRefresh = false,
  }) async {
    final cached = _store.getDoc('exercise_note', '$exerciseId');
    if (!forceRefresh && cached != null) {
      unawaited(_refreshNote(exerciseId).catchError((_) => ''));
      return jsonString(cached['note']);
    }
    if (!await _isOnline()) return jsonString(cached?['note']);
    try {
      return await _refreshNote(exerciseId);
    } on Object catch (error) {
      if (isTransientNetworkFailure(error) && cached != null) {
        return jsonString(cached['note']);
      }
      rethrow;
    }
  }

  Future<String> _refreshNote(int exerciseId) async {
    final response = await _client
        .get(Uri.parse('$_base/$exerciseId/note'))
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception(
        'GET /exercises/$exerciseId/note HTTP ${response.statusCode}',
      );
    }
    final doc = jsonDecode(response.body) as Map<String, dynamic>;
    await _store.putDoc('exercise_note', '$exerciseId', doc);
    return jsonString(doc['note']);
  }

  Future<void> savePersistentNote(int exerciseId, String note) async {
    final normalized = String.fromCharCodes(note.trim().runes.take(2000));
    await _store.putDoc('exercise_note', '$exerciseId', {'note': normalized});
    await _store.enqueue(
      Mutation(
        id: 'exercise-note:$exerciseId',
        seq: _store.nextSeq(),
        kind: 'exercise.note',
        args: {'exerciseId': exerciseId, 'note': normalized},
      ),
    );
    SyncService.instance.flushSoon();
  }

  Future<List<ExerciseHistorySession>> _refreshHistory(int id) async {
    try {
      final response = await _client
          .get(Uri.parse('$_base/$id/history'))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw Exception(
          'GET /exercises/$id/history HTTP ${response.statusCode}',
        );
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! List) {
        throw const FormatException('history is not a list');
      }
      final raw = jsonObjectList(decoded, (item) => item, maxItems: 100);
      await _store.putDoc('exercise_history', '$id', {'items': raw});
      return raw.map(ExerciseHistorySession.fromJson).toList();
    } on Object catch (error) {
      final cached = _store.getDoc('exercise_history', '$id');
      if (isTransientNetworkFailure(error) && cached != null) {
        return _historyFromCache(cached);
      }
      rethrow;
    }
  }

  Future<void> _refreshHistoryInBackground(int id) async {
    try {
      if (await _isOnline()) await _refreshHistory(id);
    } catch (_) {}
  }

  List<ExerciseHistorySession> _historyFromCache(Map<String, dynamic> cached) =>
      ((cached['items'] as List?) ?? const [])
          .map(
            (item) =>
                ExerciseHistorySession.fromJson(item as Map<String, dynamic>),
          )
          .toList();

  Future<void> logSet(
    int id, {
    required double weightKg,
    required int reps,
    String setType = 'working',
    String progression = '',
    double? rpe,
    int durationSeconds = 0,
    double distanceKm = 0,
    String? operationId,
    String? sessionId,
    String? workoutId,
    String? workoutName,
    DateTime? performedAt,
  }) async {
    operationId ??= _uuid.v4();
    final date = performedAt ?? DateTime.now();
    final performedDate =
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    final args = {
      'exerciseId': id,
      'weight_kg': weightKg,
      'reps': reps,
      'set_type': setType,
      'progression': progression,
      'rpe': rpe,
      'duration_seconds': durationSeconds,
      'distance_km': distanceKm,
      'operation_id': operationId,
      'session_id': sessionId,
      'performed_at': performedDate,
    };
    await _cacheLoggedSet(
      id,
      args,
      workoutId: workoutId,
      workoutName: workoutName,
    );
    // Logging is local-first even when a network interface exists. This keeps
    // finishing a workout instant on captive portals and flaky gym Wi-Fi; the
    // durable outbox owns delivery and retry.
    await _store.enqueue(
      Mutation(
        id: _uuid.v4(),
        seq: _store.nextSeq(),
        kind: 'exercise.logSet',
        args: args,
      ),
    );
    SyncService.instance.flushSoon();
  }

  Future<void> _cacheLoggedSet(
    int exerciseId,
    Map<String, dynamic> set, {
    String? workoutId,
    String? workoutName,
  }) async {
    final sessionId = set['session_id'] as String? ?? _uuid.v4();
    final date =
        set['performed_at'] as String? ??
        DateTime.now().toIso8601String().split('T').first;
    final history =
        _store.getDoc('exercise_history', '$exerciseId') ??
        {'items': <Map<String, dynamic>>[]};
    final items = List<Map<String, dynamic>>.from(
      (history['items'] as List? ?? const []).map(
        (item) => Map<String, dynamic>.from(item as Map),
      ),
    );
    var sessionIndex = items.indexWhere(
      (item) => item['session_id'] == sessionId,
    );
    final wasExistingSession = sessionIndex >= 0;
    if (sessionIndex < 0) {
      items.insert(0, {
        'date': date,
        'workout_id': workoutId ?? '',
        'workout_name': workoutName ?? '',
        'session_id': sessionId,
        'sets': <Map<String, dynamic>>[],
      });
      if (items.length > 100) items.removeRange(100, items.length);
      sessionIndex = 0;
    }
    final historySets =
        List<Map<String, dynamic>>.from(
          (items[sessionIndex]['sets'] as List? ?? const []).map(
            (item) => Map<String, dynamic>.from(item as Map),
          ),
        )..add({
          'weight_kg': set['weight_kg'],
          'reps': set['reps'],
          'set_type': set['set_type'],
          'progression': set['progression'],
          'rpe': set['rpe'],
        });
    items[sessionIndex]['sets'] = historySets;
    await _store.putDoc('exercise_history', '$exerciseId', {'items': items});

    if (set['set_type'] == 'warmup') return;
    final stats =
        _store.getDoc('exercise_stats', '$exerciseId') ??
        {
          'exercise_id': exerciseId,
          'progression': <Map<String, dynamic>>[],
          'records': <Map<String, dynamic>>[],
        };
    final weight = (set['weight_kg'] as num?)?.toDouble() ?? 0;
    final reps = (set['reps'] as num?)?.toInt() ?? 0;
    final oneRm = reps <= 1 ? weight : weight * (1 + reps / 30);
    final progression = List<Map<String, dynamic>>.from(
      (stats['progression'] as List? ?? const []).map(
        (item) => Map<String, dynamic>.from(item as Map),
      ),
    );
    final dayIndex = progression.indexWhere((item) => item['date'] == date);
    if (dayIndex < 0) {
      progression.add({
        'date': date,
        'top_weight_kg': weight,
        'top_reps': reps,
        'volume_kg': weight * reps,
      });
    } else {
      final day = progression[dayIndex];
      progression[dayIndex] = {
        ...day,
        'top_weight_kg': math.max(
          (day['top_weight_kg'] as num?)?.toDouble() ?? 0,
          weight,
        ),
        'top_reps': math.max((day['top_reps'] as num?)?.toInt() ?? 0, reps),
        'volume_kg':
            ((day['volume_kg'] as num?)?.toDouble() ?? 0) + weight * reps,
      };
    }
    progression.sort((a, b) => '${a['date']}'.compareTo('${b['date']}'));
    if (progression.length > 1000) {
      progression.removeRange(0, progression.length - 1000);
    }
    final dayVolume = progression
        .where((item) => item['date'] == date)
        .map((item) => (item['volume_kg'] as num?)?.toDouble() ?? 0)
        .fold<double>(0, math.max);
    final timesPerformed =
        ((stats['times_performed'] as num?)?.toInt() ?? 0) +
        (wasExistingSession ? 0 : 1);
    final totalSets = ((stats['total_sets'] as num?)?.toInt() ?? 0) + 1;
    await _store.putDoc('exercise_stats', '$exerciseId', {
      ...stats,
      'exercise_id': exerciseId,
      'times_performed': timesPerformed,
      'total_sets': totalSets,
      'avg_sets_per_workout': timesPerformed == 0
          ? 0
          : totalSets / timesPerformed,
      'total_reps': ((stats['total_reps'] as num?)?.toInt() ?? 0) + reps,
      'max_weight_kg': math.max(
        (stats['max_weight_kg'] as num?)?.toDouble() ?? 0,
        weight,
      ),
      'max_set_volume_kg': math.max(
        (stats['max_set_volume_kg'] as num?)?.toDouble() ?? 0,
        weight * reps,
      ),
      'max_volume_kg': math.max(
        (stats['max_volume_kg'] as num?)?.toDouble() ?? 0,
        dayVolume,
      ),
      'estimated_one_rm_kg': math.max(
        (stats['estimated_one_rm_kg'] as num?)?.toDouble() ?? 0,
        oneRm,
      ),
      'progression': progression,
      '_local_session_id': sessionId,
    });
  }

  Future<ExerciseCatalogItem> createCustom({
    required String name,
    String description = '',
    String imageUrl = '',
    String muscleGroup = '',
    String equipment = '',
    String exerciseType = 'weight_reps',
    String loadMode = 'total',
    List<String> secondaryMuscles = const [],
  }) async {
    final clientRequestId = _uuid.v4();
    final body = <String, dynamic>{
      'name': name,
      'description': description,
      'image_url': imageUrl,
      'muscle_group': muscleGroup,
      'equipment': equipment,
      'exercise_type': exerciseType,
      'load_mode': loadMode,
      'secondary_muscles': secondaryMuscles,
      'client_request_id': clientRequestId,
    };
    // Negative ids can be used everywhere an exercise id is expected while
    // remaining disjoint from server-issued positive ids. A random 60-bit value
    // avoids collisions when several creates happen inside one clock tick.
    final tempId = -int.parse(
      clientRequestId.replaceAll('-', '').substring(0, 15),
      radix: 16,
    );
    final doc = <String, dynamic>{
      'id': tempId,
      ...body,
      'category': 'custom',
      'level': '',
      'force': '',
      'image_url2': '',
      'instructions': description,
      'aliases': const <String>[],
      'is_custom': true,
    };
    await _cacheCustom(doc);
    await _store.enqueue(
      Mutation(
        id: _uuid.v4(),
        seq: _store.nextSeq(),
        kind: 'exercise.createCustom',
        args: {'tempId': '$tempId', ...body},
      ),
    );
    SyncService.instance.flushSoon();
    return ExerciseCatalogItem.fromJson(doc);
  }

  Future<ExerciseCatalogItem> updateCustom({
    required int id,
    required String name,
    required String description,
    required String imageUrl,
    required String muscleGroup,
    required String equipment,
    required String exerciseType,
    required String loadMode,
    required List<String> secondaryMuscles,
  }) async {
    final current =
        _store.getDoc(_catalogCollection, '$id') ?? <String, dynamic>{};
    final body = <String, dynamic>{
      'name': name.trim(),
      'description': description.trim(),
      'instructions': description.trim(),
      'image_url': imageUrl.trim(),
      'image_url2': imageUrl.trim(),
      'muscle_group': muscleGroup,
      'equipment': equipment,
      'exercise_type': exerciseType,
      'load_mode': loadMode,
      'secondary_muscles': secondaryMuscles,
    };
    final doc = <String, dynamic>{
      ...current,
      ...body,
      'id': id,
      'category': 'custom',
      'is_custom': true,
    };
    await _cacheCustom(doc);
    await _store.enqueue(
      Mutation(
        id: 'exercise-update:$id',
        seq: _store.nextSeq(),
        kind: 'exercise.updateCustom',
        args: {'exerciseId': id, ...body},
      ),
    );
    SyncService.instance.flushSoon();
    return ExerciseCatalogItem.fromJson(doc);
  }

  Future<void> archiveCustom(int id) async {
    await _store.deleteDoc(_catalogCollection, '$id');
    await _store.removeFromList(_catalogKey, '$id');
    if (id < 0) {
      final dependedOn = _store.hasPendingReference(
        '$id',
        ignoringKinds: const {
          'exercise.createCustom',
          'exercise.updateCustom',
          'exercise.note',
        },
      );
      if (!dependedOn) {
        await _store.cancelPendingFor('$id');
        return;
      }
      // Preserve create -> dependent workout/log -> archive ordering. The
      // normal temp-id remap rewrites this archive mutation to the server id.
    }
    await _store.enqueue(
      Mutation(
        id: 'exercise-archive:$id',
        seq: _store.nextSeq(),
        kind: 'exercise.archiveCustom',
        args: {'exerciseId': id},
      ),
    );
    SyncService.instance.flushSoon();
  }

  Future<void> mergeCustom(int sourceId, int targetId) async {
    if (sourceId == targetId) return;
    await _store.deleteDoc(_catalogCollection, '$sourceId');
    await _store.removeFromList(_catalogKey, '$sourceId');
    await _store.enqueue(
      Mutation(
        id: 'exercise-merge:$sourceId',
        seq: _store.nextSeq(),
        kind: 'exercise.mergeCustom',
        args: {'exerciseId': sourceId, 'targetExerciseId': targetId},
      ),
    );
    SyncService.instance.flushSoon();
  }

  Future<void> _cacheCustom(Map<String, dynamic> doc) async {
    final id = '${doc['id']}';
    await _store.putDoc(_catalogCollection, id, doc);
    await _store.prependToList(_catalogKey, id);
  }

  void _registerHandlers() {
    if (_handlersRegistered) {
      return;
    }
    _handlersRegistered = true;
    SyncService.instance.registerHandler('exercise.logSet', (
      client,
      mutation,
    ) async {
      try {
        final resp = await _postLog(client, mutation.args);
        if (resp.statusCode == 204 || resp.statusCode == 200) {
          return const SyncOutcome.done();
        }
        return syncOutcomeForStatus(resp.statusCode, success: -1);
      } on Object {
        return const SyncOutcome.retry();
      }
    });
    SyncService.instance.registerHandler('exercise.createCustom', (
      client,
      mutation,
    ) async {
      try {
        final resp = await _postCustom(client, mutation.args);
        if (resp.statusCode == 201) {
          final doc = jsonDecode(resp.body) as Map<String, dynamic>;
          await _store.remapId(
            _catalogCollection,
            '${mutation.args['tempId']}',
            '${doc['id']}',
            doc,
          );
          return const SyncOutcome.done();
        }
        return syncOutcomeForStatus(resp.statusCode, success: 201);
      } on Object {
        return const SyncOutcome.retry();
      }
    });
    SyncService.instance.registerHandler('exercise.note', (
      client,
      mutation,
    ) async {
      try {
        final response = await client
            .put(
              Uri.parse('$_base/${mutation.args['exerciseId']}/note'),
              body: jsonEncode({'note': mutation.args['note'] ?? ''}),
            )
            .timeout(const Duration(seconds: 10));
        return syncOutcomeForStatus(response.statusCode, success: 204);
      } on Object {
        return const SyncOutcome.retry();
      }
    });
    SyncService.instance.registerHandler('exercise.updateCustom', (
      client,
      mutation,
    ) async {
      try {
        final args = mutation.args;
        final response = await client
            .put(
              Uri.parse('$_base/${args['exerciseId']}'),
              body: jsonEncode({
                'name': args['name'],
                'description': args['description'] ?? '',
                'image_url': args['image_url'] ?? '',
                'muscle_group': args['muscle_group'] ?? '',
                'equipment': args['equipment'] ?? '',
                'exercise_type': args['exercise_type'] ?? 'weight_reps',
                'load_mode': args['load_mode'] ?? 'total',
                'secondary_muscles':
                    args['secondary_muscles'] ?? const <String>[],
              }),
            )
            .timeout(const Duration(seconds: 15));
        return syncOutcomeForStatus(response.statusCode, success: 200);
      } on Object {
        return const SyncOutcome.retry();
      }
    });
    SyncService.instance.registerHandler('exercise.archiveCustom', (
      client,
      mutation,
    ) async {
      try {
        final response = await client
            .delete(Uri.parse('$_base/${mutation.args['exerciseId']}'))
            .timeout(const Duration(seconds: 15));
        return syncOutcomeForStatus(response.statusCode, success: 204);
      } on Object {
        return const SyncOutcome.retry();
      }
    });
    SyncService.instance.registerHandler('exercise.mergeCustom', (
      client,
      mutation,
    ) async {
      try {
        final response = await client
            .post(
              Uri.parse('$_base/${mutation.args['exerciseId']}/merge'),
              body: jsonEncode({
                'target_exercise_id': mutation.args['targetExerciseId'],
              }),
            )
            .timeout(const Duration(seconds: 20));
        return syncOutcomeForStatus(response.statusCode, success: 204);
      } on Object {
        return const SyncOutcome.retry();
      }
    });
  }

  static Future<http.Response> _postCustom(
    AuthenticatedClient client,
    Map<String, dynamic> args,
  ) => client
      .post(
        Uri.parse('${ApiConfig.apiBaseUrl}/api/v1/exercises'),
        body: jsonEncode({
          'name': args['name'],
          'description': args['description'] ?? '',
          'image_url': args['image_url'] ?? '',
          'muscle_group': args['muscle_group'] ?? '',
          'equipment': args['equipment'] ?? '',
          'exercise_type': args['exercise_type'] ?? 'weight_reps',
          'load_mode': args['load_mode'] ?? 'total',
          'secondary_muscles': args['secondary_muscles'] ?? const <String>[],
          'client_request_id': args['client_request_id'],
        }),
      )
      .timeout(const Duration(seconds: 15));

  static Future<http.Response> _postLog(
    AuthenticatedClient client,
    Map<String, dynamic> args,
  ) => client
      .post(
        Uri.parse(
          '${ApiConfig.apiBaseUrl}/api/v1/exercises/${args['exerciseId']}/log',
        ),
        body: jsonEncode({
          'weight_kg': args['weight_kg'],
          'reps': args['reps'],
          'set_type': args['set_type'],
          'progression': args['progression'] ?? '',
          if (args['rpe'] != null) 'rpe': args['rpe'],
          if ((args['duration_seconds'] as int? ?? 0) > 0)
            'duration_seconds': args['duration_seconds'],
          if ((args['distance_km'] as double? ?? 0) > 0)
            'distance_km': args['distance_km'],
          'operation_id': args['operation_id'],
          'session_id': args['session_id'],
          'performed_at': args['performed_at'],
        }),
      )
      .timeout(const Duration(seconds: 15));
}
