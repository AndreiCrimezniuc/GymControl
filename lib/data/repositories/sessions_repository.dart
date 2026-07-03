import 'dart:convert';
import 'package:gymboss/config/api_config.dart';
import 'package:gymboss/core/errors/app_error.dart';
import 'package:gymboss/data/services/auth/authenticated_client.dart';
import 'package:gymboss/domain/models/streak/streak_data.dart';

class SessionsRepository {
  final AuthenticatedClient _client;
  final String _base = '${ApiConfig.apiBaseUrl}/api/v1';

  SessionsRepository({required AuthenticatedClient client}) : _client = client;

  Future<void> recordSession() async {
    final resp = await _client
        .post(Uri.parse('$_base/sessions'))
        .timeout(const Duration(seconds: 10));
    if (resp.statusCode != 204) {
      throw AppError(
        AppErrorCode.dataSaveFailed,
        message: 'POST /sessions HTTP ${resp.statusCode}',
      )..log();
    }
  }

  Future<StreakData> getStreakData() async {
    final resp = await _client
        .get(Uri.parse('$_base/sessions/streak'))
        .timeout(const Duration(seconds: 10));
    if (resp.statusCode != 200) {
      throw AppError(
        AppErrorCode.dataLoadFailed,
        message: 'GET /sessions/streak HTTP ${resp.statusCode}',
      )..log();
    }
    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    return StreakData.fromJson(json);
  }
}
