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
import 'package:gymboss/domain/models/exercises/exercise_catalog.dart';

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

  Future<List<ExerciseCatalogItem>> getCatalog() async {
    if (!await _isOnline() && _store.hasList(_catalogKey)) {
      return _cachedCatalog();
    }
    try {
      final resp = await _client
          .get(Uri.parse(_base))
          .timeout(const Duration(seconds: 20));
      if (resp.statusCode != 200) {
        throw Exception('GET /exercises HTTP ${resp.statusCode}');
      }
      final raw = (jsonDecode(resp.body) as List).cast<Map<String, dynamic>>();
      for (final doc in raw) {
        await _store.putDoc(_catalogCollection, '${doc['id']}', doc);
      }
      await _store.putListIds(
        _catalogKey,
        raw.map((doc) => '${doc['id']}').toList(),
      );
      return raw.map(ExerciseCatalogItem.fromJson).toList();
    } on Object catch (error) {
      if (isTransientNetworkFailure(error) && _store.hasList(_catalogKey)) {
        return _cachedCatalog();
      }
      rethrow;
    }
  }

  List<ExerciseCatalogItem> _cachedCatalog() =>
      _store
          .getListDocs(_catalogCollection, _catalogKey)
          .map(ExerciseCatalogItem.fromJson)
          .toList();

  Future<ExerciseStats> getStats(int id) async {
    final cached = _store.getDoc('exercise_stats', '$id');
    if (!await _isOnline() && cached != null) {
      return ExerciseStats.fromJson(cached);
    }
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
      if (isTransientNetworkFailure(error) && cached != null) {
        return ExerciseStats.fromJson(cached);
      }
      rethrow;
    }
  }

  Future<List<ExerciseHistorySession>> getHistory(int id) async {
    final cached = _store.getDoc('exercise_history', '$id');
    if (!await _isOnline() && cached != null) {
      return _historyFromCache(cached);
    }
    try {
      final response = await _client
          .get(Uri.parse('$_base/$id/history'))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw Exception(
          'GET /exercises/$id/history HTTP ${response.statusCode}',
        );
      }
      final raw =
          (jsonDecode(response.body) as List).cast<Map<String, dynamic>>();
      await _store.putDoc('exercise_history', '$id', {'items': raw});
      return raw.map(ExerciseHistorySession.fromJson).toList();
    } on Object catch (error) {
      if (isTransientNetworkFailure(error) && cached != null) {
        return _historyFromCache(cached);
      }
      rethrow;
    }
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
    String? operationId,
    String? sessionId,
  }) async {
    operationId ??= _uuid.v4();
    final args = {
      'exerciseId': id,
      'weight_kg': weightKg,
      'reps': reps,
      'set_type': setType,
      'progression': progression,
      'operation_id': operationId,
      'session_id': sessionId,
    };
    if (await _isOnline()) {
      try {
        final resp = await _postLog(_client, args);
        if (resp.statusCode == 204 || resp.statusCode == 200) {
          return;
        }
        throw Exception(
          'POST /exercises/$id/log HTTP ${resp.statusCode}: ${resp.body}',
        );
      } on Object catch (error) {
        if (!isTransientNetworkFailure(error)) {
          rethrow;
        }
      }
    }
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

  Future<ExerciseCatalogItem> createCustom({
    required String name,
    String description = '',
    String imageUrl = '',
    String muscleGroup = '',
    String equipment = '',
    String exerciseType = 'weight_reps',
    List<String> secondaryMuscles = const [],
  }) async {
    final resp = await _client
        .post(
          Uri.parse(_base),
          body: jsonEncode({
            'name': name,
            'description': description,
            'image_url': imageUrl,
            'muscle_group': muscleGroup,
            'equipment': equipment,
            'exercise_type': exerciseType,
            'secondary_muscles': secondaryMuscles,
          }),
        )
        .timeout(const Duration(seconds: 15));
    if (resp.statusCode != 201) {
      String msg = 'HTTP ${resp.statusCode}';
      try {
        msg =
            (jsonDecode(resp.body) as Map<String, dynamic>)['error']
                as String? ??
            msg;
      } catch (_) {}
      throw Exception(msg);
    }
    return ExerciseCatalogItem.fromJson(
      jsonDecode(resp.body) as Map<String, dynamic>,
    );
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
        return resp.statusCode >= 400 && resp.statusCode < 500
            ? const SyncOutcome.drop()
            : const SyncOutcome.retry();
      } on Object catch (error) {
        return isTransientNetworkFailure(error)
            ? const SyncOutcome.retry()
            : const SyncOutcome.drop();
      }
    });
  }

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
          'operation_id': args['operation_id'],
          'session_id': args['session_id'],
        }),
      )
      .timeout(const Duration(seconds: 15));
}
