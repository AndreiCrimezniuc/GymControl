import 'dart:convert';

import 'package:gymboss/config/api_config.dart';
import 'package:gymboss/data/services/auth/authenticated_client.dart';

class HistoryImportPreview {
  final int rows;
  final int sessions;
  final int createdExercises;
  final List<String> unknownExercises;

  const HistoryImportPreview({
    required this.rows,
    required this.sessions,
    required this.createdExercises,
    required this.unknownExercises,
  });

  factory HistoryImportPreview.fromJson(Map<String, dynamic> json) =>
      HistoryImportPreview(
        rows: (json['rows'] as num?)?.toInt() ?? 0,
        sessions: (json['sessions'] as num?)?.toInt() ?? 0,
        createdExercises: (json['created_exercises'] as num?)?.toInt() ?? 0,
        unknownExercises: (json['unknown_exercises'] as List? ?? const [])
            .whereType<String>()
            .toList(growable: false),
      );
}

class AccountDataRepository {
  final AuthenticatedClient _client;
  final String _base = '${ApiConfig.apiBaseUrl}/api/v1/account';

  AccountDataRepository({required AuthenticatedClient client})
    : _client = client;

  Future<List<int>> exportCsv() async {
    final response = await _client
        .get(Uri.parse('$_base/export?format=csv'))
        .timeout(const Duration(seconds: 30));
    _assertSuccess(response.statusCode, response.body);
    return response.bodyBytes;
  }

  Future<List<int>> exportJson() async {
    final response = await _client
        .get(Uri.parse('$_base/export'))
        .timeout(const Duration(seconds: 30));
    _assertSuccess(response.statusCode, response.body);
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    return utf8.encode(const JsonEncoder.withIndent('  ').convert(decoded));
  }

  Future<HistoryImportPreview> importRows(
    List<Map<String, dynamic>> rows, {
    required bool dryRun,
  }) async {
    final response = await _client
        .post(
          Uri.parse('$_base/import-history'),
          body: jsonEncode({'dry_run': dryRun, 'rows': rows}),
        )
        .timeout(const Duration(seconds: 60));
    _assertSuccess(response.statusCode, response.body);
    return HistoryImportPreview.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  static void _assertSuccess(int status, String body) {
    if (status >= 200 && status < 300) return;
    var message = 'HTTP $status';
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['message'] is String) {
        message = decoded['message'] as String;
      }
    } catch (_) {}
    throw StateError(message);
  }
}
