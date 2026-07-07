import 'dart:convert';
import 'package:gymboss/config/api_config.dart';
import 'package:gymboss/data/services/auth/authenticated_client.dart';
import 'package:gymboss/domain/models/exercises/exercise_catalog.dart';

class ExercisesRepository {
  final AuthenticatedClient _client;
  final String _base = '${ApiConfig.apiBaseUrl}/api/v1/exercises';

  ExercisesRepository({required AuthenticatedClient client}) : _client = client;

  Future<List<ExerciseCatalogItem>> getCatalog() async {
    final resp = await _client.get(Uri.parse(_base)).timeout(const Duration(seconds: 20));
    if (resp.statusCode != 200) {
      throw Exception('GET /exercises HTTP ${resp.statusCode}');
    }
    final list = jsonDecode(resp.body) as List<dynamic>;
    return list.map((e) => ExerciseCatalogItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ExerciseStats> getStats(int id) async {
    final resp = await _client.get(Uri.parse('$_base/$id/stats')).timeout(const Duration(seconds: 15));
    if (resp.statusCode != 200) {
      throw Exception('GET /exercises/$id/stats HTTP ${resp.statusCode}');
    }
    return ExerciseStats.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
  }

  Future<void> logSet(int id, {required double weightKg, required int reps, String setType = 'working'}) async {
    final resp = await _client.post(
      Uri.parse('$_base/$id/log'),
      body: jsonEncode({'weight_kg': weightKg, 'reps': reps, 'set_type': setType}),
    ).timeout(const Duration(seconds: 15));
    if (resp.statusCode != 204 && resp.statusCode != 200) {
      throw Exception('POST /exercises/$id/log HTTP ${resp.statusCode}: ${resp.body}');
    }
  }

  Future<ExerciseCatalogItem> createCustom({
    required String name,
    String description = '',
    String imageUrl = '',
    String muscleGroup = '',
  }) async {
    final resp = await _client.post(
      Uri.parse(_base),
      body: jsonEncode({
        'name': name,
        'description': description,
        'image_url': imageUrl,
        'muscle_group': muscleGroup,
      }),
    ).timeout(const Duration(seconds: 15));
    if (resp.statusCode != 201) {
      String msg = 'HTTP ${resp.statusCode}';
      try {
        msg = (jsonDecode(resp.body) as Map<String, dynamic>)['error'] as String? ?? msg;
      } catch (_) {}
      throw Exception(msg);
    }
    return ExerciseCatalogItem.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
  }
}
