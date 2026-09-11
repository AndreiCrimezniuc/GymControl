import 'dart:async';
import 'dart:convert';
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

  Future<void> recordSession({DateTime? performedAt, String? sessionId}) async {
    final now = performedAt ?? DateTime.now();
    final sessionDate =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    final durableId = sessionId?.trim().isNotEmpty == true
        ? sessionId!.trim()
        : 'legacy:$sessionDate';
    await _store.enqueue(
      Mutation(
        id: 'session:$durableId',
        seq: _store.nextSeq(),
        kind: 'session.record',
        args: {'session_date': sessionDate, 'session_id': durableId},
      ),
    );
    SyncService.instance.flushSoon();
  }

  Future<StreakData> getStreakData({bool forceRefresh = false}) async {
    final cached = _store.getDoc(_streakCollection, _streakId);
    if (!forceRefresh && cached != null) {
      unawaited(_refreshStreakInBackground());
      return StreakData.fromJson(cached);
    }
    if (!await _isOnline()) {
      return cached == null ? StreakData.empty : StreakData.fromJson(cached);
    }
    try {
      return await _refreshStreak();
    } on Object catch (error) {
      if (isTransientNetworkFailure(error) && cached != null) {
        return StreakData.fromJson(cached);
      }
      rethrow;
    }
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
      if (!await _isOnline()) return;
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
            .post(Uri.parse('$_base/sessions'), body: jsonEncode(mutation.args))
            .timeout(const Duration(seconds: 10));
        return syncOutcomeForStatus(response.statusCode, success: 204);
      } on Object {
        return const SyncOutcome.retry();
      }
    });
  }
}
