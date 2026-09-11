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
import 'package:gymboss/domain/models/measurements/body_measurement.dart';

class MeasurementsRepository {
  static const _cacheCollection = 'body_measurements';
  static const _cacheKey = 'body_measurements:list';
  static const _uuid = Uuid();
  static bool _handlersRegistered = false;

  final AuthenticatedClient _client;
  final Future<bool> Function() _isOnline;
  final LocalStore _store = LocalStore.instance;
  final String _base = '${ApiConfig.apiBaseUrl}/api/v1/measurements';

  MeasurementsRepository({
    required AuthenticatedClient client,
    Future<bool> Function()? isOnline,
  }) : _client = client,
       _isOnline = isOnline ?? ConnectivityService.instance.isOnline {
    _registerHandlers();
  }

  Future<List<BodyMeasurement>> list({bool forceRefresh = false}) async {
    if (!forceRefresh && _store.hasList(_cacheKey)) {
      final cached = _cachedList();
      unawaited(_refreshInBackground());
      return cached;
    }
    if (!await _isOnline()) return _cachedList();
    return _refresh();
  }

  Future<List<BodyMeasurement>> _refresh() async {
    try {
      final response = await _client
          .get(Uri.parse(_base))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw Exception('GET /measurements HTTP ${response.statusCode}');
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! List) {
        throw const FormatException('measurements is not a list');
      }
      final raw = jsonObjectList(
        decoded,
        (item) => item,
        maxItems: 2000,
      ).where((item) => item['id'] is String).toList(growable: false);
      for (final item in raw) {
        await _store.putDoc(_cacheCollection, item['id'] as String, item);
      }
      await _store.putListIds(
        _cacheKey,
        raw.map((item) => item['id'] as String).toList(),
      );
      return raw.map(BodyMeasurement.fromJson).toList();
    } on Object catch (error) {
      if (isTransientNetworkFailure(error) && _store.hasList(_cacheKey)) {
        return _store
            .getListDocs(_cacheCollection, _cacheKey)
            .map(BodyMeasurement.fromJson)
            .toList();
      }
      rethrow;
    }
  }

  Future<void> _refreshInBackground() async {
    try {
      if (!await _isOnline()) return;
      await _refresh();
    } catch (_) {
      // The durable snapshot remains usable until the next refresh.
    }
  }

  List<BodyMeasurement> _cachedList() => _store
      .getListDocs(_cacheCollection, _cacheKey)
      .map(BodyMeasurement.fromJson)
      .toList();

  Future<BodyMeasurement> save(BodyMeasurement measurement) async {
    final tempId = 'local:${_uuid.v4()}';
    final local = {...measurement.toJson(), 'id': tempId};
    await _store.putDoc(_cacheCollection, tempId, local);
    await _store.prependToList(_cacheKey, tempId);
    await _enqueue('measurement.create', {
      'tempId': tempId,
      ...measurement.toJson(),
    });
    return BodyMeasurement.fromJson(local);
  }

  Future<void> delete(String id) async {
    await _store.deleteDoc(_cacheCollection, id);
    await _store.removeFromList(_cacheKey, id);
    if (id.startsWith('local:')) {
      await _store.cancelPendingFor(id);
      return;
    }
    await _enqueue('measurement.delete', {'id': id});
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
    SyncService.instance.registerHandler('measurement.create', (
      client,
      mutation,
    ) async {
      try {
        final body = Map<String, dynamic>.from(mutation.args)..remove('tempId');
        final response = await client
            .post(Uri.parse(_base), body: jsonEncode(body))
            .timeout(const Duration(seconds: 15));
        if (response.statusCode == 201) {
          final fresh = jsonDecode(response.body) as Map<String, dynamic>;
          return SyncOutcome.done(
            collection: _cacheCollection,
            remapFromId: mutation.args['tempId'] as String,
            remapToId: fresh['id'] as String,
            realDoc: fresh,
          );
        }
        return _outcomeFor(response);
      } on Object {
        return const SyncOutcome.retry();
      }
    });
    SyncService.instance.registerHandler('measurement.delete', (
      client,
      mutation,
    ) async {
      try {
        final response = await client
            .delete(Uri.parse('$_base/${mutation.args['id']}'))
            .timeout(const Duration(seconds: 15));
        if (response.statusCode == 204 || response.statusCode == 404) {
          return const SyncOutcome.done();
        }
        return _outcomeFor(response);
      } on Object {
        return const SyncOutcome.retry();
      }
    });
  }

  static SyncOutcome _outcomeFor(http.Response response) =>
      syncOutcomeForStatus(response.statusCode, success: -1);
}
