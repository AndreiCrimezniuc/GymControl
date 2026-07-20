import 'dart:convert';
import 'package:gymboss/config/api_config.dart';
import 'package:gymboss/core/errors/app_error.dart';
import 'package:gymboss/data/services/auth/authenticated_client.dart';
import 'package:gymboss/domain/models/ranking/rank_data.dart';

class RankingRepository {
  final AuthenticatedClient _client;
  final String _base;

  RankingRepository({required AuthenticatedClient client})
    : _client = client,
      _base = '${ApiConfig.apiBaseUrl}/api/v1/rankings';

  Future<RankProfile> getProfile() async {
    final resp = await _client
        .get(Uri.parse('$_base/profile'))
        .timeout(const Duration(seconds: 10));
    if (resp.statusCode != 200) {
      throw AppError(
        AppErrorCode.dataLoadFailed,
        message: 'GET /rankings/profile HTTP ${resp.statusCode}',
      );
    }
    return RankProfile.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
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

    final resp = await _client
        .put(Uri.parse('$_base/profile'), body: jsonEncode(body))
        .timeout(const Duration(seconds: 10));
    if (resp.statusCode != 200) {
      throw AppError(
        AppErrorCode.dataSaveFailed,
        message: 'PUT /rankings/profile HTTP ${resp.statusCode}',
      );
    }
    return RankProfile.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
  }

  Future<void> recordLift({
    required String exerciseId,
    required double weightKg,
    required int reps,
  }) async {
    final resp = await _client
        .post(
          Uri.parse('$_base/lifts'),
          body: jsonEncode({
            'exercise_id': exerciseId,
            'weight_kg': weightKg,
            'reps': reps,
          }),
        )
        .timeout(const Duration(seconds: 10));
    if (resp.statusCode != 204) {
      throw AppError(
        AppErrorCode.dataSaveFailed,
        message: 'POST /rankings/lifts HTTP ${resp.statusCode}',
      );
    }
  }

  Future<UserRanks> getUserRanks() async {
    final resp = await _client
        .get(Uri.parse('$_base/me'))
        .timeout(const Duration(seconds: 10));
    if (resp.statusCode != 200) {
      throw AppError(
        AppErrorCode.dataLoadFailed,
        message: 'GET /rankings/me HTTP ${resp.statusCode}',
      );
    }
    return UserRanks.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
  }
}
