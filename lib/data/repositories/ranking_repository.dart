import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:gymboss/config/api_config.dart';
import 'package:gymboss/core/errors/app_error.dart';
import 'package:gymboss/data/local/local_store.dart';
import 'package:gymboss/data/local/mutation.dart';
import 'package:gymboss/data/services/auth/authenticated_client.dart';
import 'package:gymboss/data/sync/connectivity_service.dart';
import 'package:gymboss/data/sync/sync_service.dart';
import 'package:gymboss/domain/models/ranking/rank_data.dart';

class RankingRepository {
  static const _uuid = Uuid();
  static const _collection = 'ranking';
  static bool _handlersRegistered = false;
  final AuthenticatedClient _client;
  final Future<bool> Function() _isOnline;
  final LocalStore _store = LocalStore.instance;
  final String _base;

  RankingRepository({
    required AuthenticatedClient client,
    Future<bool> Function()? isOnline,
  }) : _client = client,
       _isOnline = isOnline ?? ConnectivityService.instance.isOnline,
       _base = '${ApiConfig.apiBaseUrl}/api/v1/rankings' {
    _registerHandlers();
  }

  Future<RankProfile> getProfile({bool forceRefresh = false}) async {
    final cached = _store.getDoc(_collection, 'profile');
    if (!forceRefresh && cached != null) {
      unawaited(_refreshProfileInBackground());
      return RankProfile.fromJson(cached);
    }
    if (!await _isOnline()) {
      return RankProfile(dontAskWeight: false, updatedAt: DateTime(2000));
    }
    return _refreshProfile();
  }

  Future<RankProfile> _refreshProfile() async {
    final resp = await _client
        .get(Uri.parse('$_base/profile'))
        .timeout(const Duration(seconds: 10));
    if (resp.statusCode != 200) {
      throw AppError(
        AppErrorCode.dataLoadFailed,
        message: 'GET /rankings/profile HTTP ${resp.statusCode}',
      );
    }
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    await _store.putDoc(_collection, 'profile', body);
    return RankProfile.fromJson(body);
  }

  Future<void> _refreshProfileInBackground() async {
    try {
      if (!await _isOnline()) return;
      await _refreshProfile();
    } catch (_) {}
  }

  Future<RankProfile> updateProfile({
    double? weightKg,
    double? heightCm,
    bool? dontAskWeight,
  }) async {
    final body = <String, dynamic>{};
    if (weightKg != null) body['weight_kg'] = weightKg;
    if (heightCm != null) body['height_cm'] = heightCm;
    if (dontAskWeight != null) body['dont_ask_weight'] = dontAskWeight;

    final previous = _store.getDoc(_collection, 'profile') ?? const {};
    final local = {
      ...previous,
      ...body,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    await _store.putDoc(_collection, 'profile', local);
    // Profiles are local-first too: changing body measurements must never
    // stall behind a network probe. SyncService reconciles on connectivity.
    await _enqueue('ranking.profile', body);
    return RankProfile.fromJson(local);
  }

  Future<void> recordLift({
    required String exerciseId,
    required double weightKg,
    required int reps,
  }) async {
    final body = {
      'exercise_id': exerciseId,
      'weight_kg': weightKg,
      'reps': reps,
    };
    // The completed set is authoritative locally. Passport synchronization is
    // asynchronous so logging a lift feels identical online and offline.
    await _enqueue('ranking.lift', body);
  }

  Future<UserRanks> getUserRanks({bool forceRefresh = false}) async {
    final cached = _store.getDoc(_collection, 'me');
    if (!forceRefresh && cached != null) {
      unawaited(_refreshUserRanksInBackground());
      return UserRanks.fromJson(cached);
    }
    if (!await _isOnline()) return UserRanks.empty;
    return _refreshUserRanks();
  }

  Future<UserRanks> _refreshUserRanks() async {
    final resp = await _client
        .get(Uri.parse('$_base/me'))
        .timeout(const Duration(seconds: 10));
    if (resp.statusCode != 200) {
      throw AppError(
        AppErrorCode.dataLoadFailed,
        message: 'GET /rankings/me HTTP ${resp.statusCode}',
      );
    }
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    await _store.putDoc(_collection, 'me', body);
    return UserRanks.fromJson(body);
  }

  Future<void> _refreshUserRanksInBackground() async {
    try {
      if (!await _isOnline()) return;
      await _refreshUserRanks();
    } catch (_) {}
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
    SyncService.instance.registerHandler(
      'ranking.profile',
      (client, mutation) => _replay(
        () => client
            .put(Uri.parse('$_base/profile'), body: jsonEncode(mutation.args))
            .timeout(const Duration(seconds: 10)),
        ok: 200,
      ),
    );
    SyncService.instance.registerHandler(
      'ranking.lift',
      (client, mutation) => _replay(
        () => client
            .post(Uri.parse('$_base/lifts'), body: jsonEncode(mutation.args))
            .timeout(const Duration(seconds: 10)),
        ok: 204,
      ),
    );
  }

  static Future<SyncOutcome> _replay(
    Future<http.Response> Function() call, {
    required int ok,
  }) async {
    try {
      final response = await call();
      return syncOutcomeForStatus(response.statusCode, success: ok);
    } on Object {
      return const SyncOutcome.retry();
    }
  }
}
