import 'dart:async';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:gymboss/config/api_config.dart';
import 'package:gymboss/core/errors/app_error.dart';
import 'package:gymboss/data/local/local_store.dart';
import 'package:gymboss/data/local/mutation.dart';
import 'package:gymboss/data/services/auth/authenticated_client.dart';
import 'package:gymboss/data/sync/connectivity_service.dart';
import 'package:gymboss/data/sync/network_failure.dart';
import 'package:gymboss/data/sync/sync_service.dart';
import 'package:gymboss/domain/models/streak/streak_data.dart';

class SessionsRepository {
  static const _uuid = Uuid();
  static const _streakCollection = 'session_stats';
  static const _streakId = 'streak';
  static bool _handlersRegistered = false;
  final AuthenticatedClient _client;
  final Future<bool> Function() _isOnline;
  final LocalStore _store = LocalStore.instance;
  final String _base = '${ApiConfig.apiBaseUrl}/api/v1';

  SessionsRepository({
    required AuthenticatedClient client,
    Future<bool> Function()? isOnline,
  }) : _client = client,
       _isOnline = isOnline ?? ConnectivityService.instance.isOnline {
    _registerHandlers();
  }

  Future<void> recordSession() async {
    if (await _isOnline()) {
      try {
        final resp = await _client
            .post(Uri.parse('$_base/sessions'))
            .timeout(const Duration(seconds: 10));
        if (resp.statusCode == 204) return;
        throw AppError(
          AppErrorCode.dataSaveFailed,
          message: 'POST /sessions HTTP ${resp.statusCode}',
        )..log();
      } on Object catch (error) {
        if (!isTransientNetworkFailure(error)) rethrow;
      }
    }
    // Home can be rebuilt repeatedly while offline. One pending heartbeat is
    // enough; the endpoint records presence rather than an individual workout.
    if (_store.pending().any((mutation) => mutation.kind == 'session.record')) {
      return;
    }
    await _store.enqueue(
      Mutation(
        id: _uuid.v4(),
        seq: _store.nextSeq(),
        kind: 'session.record',
        args: const {},
      ),
    );
    SyncService.instance.flushSoon();
  }

  Future<StreakData> getStreakData() async {
    final cached = _store.getDoc(_streakCollection, _streakId);
    if (cached != null) {
      if (await _isOnline()) unawaited(_refreshStreakInBackground());
      return StreakData.fromJson(cached);
    }
    if (!await _isOnline()) return StreakData.empty;
    return _refreshStreak();
  }

  Future<StreakData> _refreshStreak() async {
    final resp = await _client
        .get(Uri.parse('$_base/sessions/streak'))
        .timeout(const Duration(seconds: 10));
    if (resp.statusCode != 200) {
      throw AppError(
        AppErrorCode.dataLoadFailed,
        message: 'GET /sessions/streak HTTP ${resp.statusCode}',
      )..log();
    }
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    await _store.putDoc(_streakCollection, _streakId, body);
    return StreakData.fromJson(body);
  }

  Future<void> _refreshStreakInBackground() async {
    try {
      await _refreshStreak();
    } catch (_) {}
  }

  void _registerHandlers() {
    if (_handlersRegistered) return;
    _handlersRegistered = true;
    SyncService.instance.registerHandler('session.record', (
      client,
      mutation,
    ) async {
      try {
        final response = await client
            .post(Uri.parse('$_base/sessions'))
            .timeout(const Duration(seconds: 10));
        if (response.statusCode == 204) return const SyncOutcome.done();
        return response.statusCode >= 500
            ? const SyncOutcome.retry()
            : const SyncOutcome.drop();
      } on Object catch (error) {
        return isTransientNetworkFailure(error)
            ? const SyncOutcome.retry()
            : const SyncOutcome.drop();
      }
    });
  }
}
