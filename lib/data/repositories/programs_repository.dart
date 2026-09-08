import 'dart:async';
import 'dart:convert';

import 'package:gymboss/config/api_config.dart';
import 'package:gymboss/data/local/local_store.dart';
import 'package:gymboss/data/local/mutation.dart';
import 'package:gymboss/data/services/auth/authenticated_client.dart';
import 'package:gymboss/data/sync/connectivity_service.dart';
import 'package:gymboss/data/sync/network_failure.dart';
import 'package:gymboss/data/sync/sync_service.dart';
import 'package:gymboss/domain/models/json_readers.dart';
import 'package:gymboss/domain/models/programs/training_program.dart';

class ProgramsRepository {
  static const _collection = 'training_program';
  static const _listKey = 'training_programs';
  static bool _handlersRegistered = false;

  final AuthenticatedClient _client;
  final Future<bool> Function() _isOnline;
  final LocalStore _store = LocalStore.instance;
  final String _base = '${ApiConfig.apiBaseUrl}/api/v1/programs';

  ProgramsRepository({
    required AuthenticatedClient client,
    Future<bool> Function()? isOnline,
  }) : _client = client,
       _isOnline = isOnline ?? ConnectivityService.instance.isOnline {
    _registerHandlers();
  }

  Future<List<TrainingProgram>> list({bool forceRefresh = false}) async {
    if (!forceRefresh && _store.hasList(_listKey)) {
      final cached = _cached();
      unawaited(_refresh().catchError((_) => cached));
      return cached;
    }
    if (!await _isOnline()) return _cached();
    return _refresh();
  }

  List<TrainingProgram> _cached() => _store
      .getListDocs(_collection, _listKey)
      .map(TrainingProgram.fromJson)
      .toList();

  Future<List<TrainingProgram>> _refresh() async {
    try {
      final response = await _client
          .get(Uri.parse(_base))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw Exception('GET /programs HTTP ${response.statusCode}');
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! List) throw const FormatException('program list');
      final docs = jsonObjectList(decoded, (item) => item, maxItems: 50);
      for (final doc in docs) {
        await _store.putDoc(_collection, jsonString(doc['id']), doc);
      }
      await _store.putListIds(
        _listKey,
        docs.map((doc) => jsonString(doc['id'])).toList(),
      );
      return docs.map(TrainingProgram.fromJson).toList();
    } on Object catch (error) {
      if (isTransientNetworkFailure(error) && _store.hasList(_listKey)) {
        return _cached();
      }
      rethrow;
    }
  }

  Future<void> save(TrainingProgram program) async {
    final doc = program.toJson();
    await _store.putDoc(_collection, program.id, doc);
    await _store.prependToList(_listKey, program.id);
    await _store.enqueue(
      Mutation(
        id: 'program-save:${program.id}',
        seq: _store.nextSeq(),
        kind: 'program.save',
        args: doc,
      ),
    );
    SyncService.instance.flushSoon();
  }

  Future<void> delete(String id) async {
    await _store.deleteDoc(_collection, id);
    await _store.removeFromList(_listKey, id);
    await _store.enqueue(
      Mutation(
        id: 'program-delete:$id',
        seq: _store.nextSeq(),
        kind: 'program.delete',
        args: {'id': id},
      ),
    );
    SyncService.instance.flushSoon();
  }

  void _registerHandlers() {
    if (_handlersRegistered) return;
    _handlersRegistered = true;
    SyncService.instance.registerHandler('program.save', (
      client,
      mutation,
    ) async {
      try {
        final response = await client
            .put(
              Uri.parse('$_base/${mutation.args['id']}'),
              body: jsonEncode(mutation.args),
            )
            .timeout(const Duration(seconds: 20));
        return syncOutcomeForStatus(response.statusCode, success: 200);
      } on Object {
        return const SyncOutcome.retry();
      }
    });
    SyncService.instance.registerHandler('program.delete', (
      client,
      mutation,
    ) async {
      try {
        final response = await client
            .delete(Uri.parse('$_base/${mutation.args['id']}'))
            .timeout(const Duration(seconds: 15));
        return syncOutcomeForStatus(response.statusCode, success: 204);
      } on Object {
        return const SyncOutcome.retry();
      }
    });
  }
}
