import 'dart:convert';
import 'package:gymboss/config/api_config.dart';
import 'package:gymboss/data/services/auth/authenticated_client.dart';
import 'package:gymboss/domain/models/workouts/workout.dart';

class WorkoutsRepository {
  final AuthenticatedClient _client;
  final String _base = '${ApiConfig.apiBaseUrl}/api/v1/workouts';

  WorkoutsRepository({required AuthenticatedClient client}) : _client = client;

  Future<List<Workout>> listOwned() => _list(_base);
  Future<List<Workout>> listPublic() => _list('$_base/public');

  Future<List<Workout>> _list(String url) async {
    final resp = await _client.get(Uri.parse(url)).timeout(const Duration(seconds: 20));
    if (resp.statusCode != 200) {
      throw Exception('GET $url HTTP ${resp.statusCode}');
    }
    final list = jsonDecode(resp.body) as List<dynamic>;
    return list.map((e) => Workout.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Workout> get(String id) async {
    final resp = await _client.get(Uri.parse('$_base/$id')).timeout(const Duration(seconds: 15));
    if (resp.statusCode != 200) throw Exception('GET workout HTTP ${resp.statusCode}');
    return Workout.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
  }

  Future<WorkoutStats> stats(String id) async {
    final resp = await _client.get(Uri.parse('$_base/$id/stats')).timeout(const Duration(seconds: 15));
    if (resp.statusCode != 200) throw Exception('GET stats HTTP ${resp.statusCode}');
    return WorkoutStats.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
  }

  Future<List<PerformedExerciseLog>> runDetail(String id, String date) async {
    final resp = await _client.get(Uri.parse('$_base/$id/history/$date')).timeout(const Duration(seconds: 15));
    if (resp.statusCode != 200) throw Exception('GET run detail HTTP ${resp.statusCode}');
    final list = jsonDecode(resp.body) as List<dynamic>;
    return list.map((e) => PerformedExerciseLog.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Workout> create({
    required String name,
    required String comment,
    required List<WorkoutExercise> exercises,
  }) async {
    final resp = await _client
        .post(Uri.parse(_base), body: _encode(name, comment, exercises))
        .timeout(const Duration(seconds: 20));
    if (resp.statusCode != 201) throw Exception(_err(resp.body, resp.statusCode));
    return Workout.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
  }

  Future<Workout> update(
    String id, {
    required String name,
    required String comment,
    required List<WorkoutExercise> exercises,
  }) async {
    final resp = await _client
        .put(Uri.parse('$_base/$id'), body: _encode(name, comment, exercises))
        .timeout(const Duration(seconds: 20));
    if (resp.statusCode != 200) throw Exception(_err(resp.body, resp.statusCode));
    return Workout.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    final resp = await _client.delete(Uri.parse('$_base/$id')).timeout(const Duration(seconds: 15));
    if (resp.statusCode != 204) throw Exception('DELETE HTTP ${resp.statusCode}');
  }

  Future<Workout> copy(String id) async {
    final resp = await _client.post(Uri.parse('$_base/$id/copy')).timeout(const Duration(seconds: 15));
    if (resp.statusCode != 201) throw Exception(_err(resp.body, resp.statusCode));
    return Workout.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
  }

  Future<String> share(String id) async {
    final resp = await _client.post(Uri.parse('$_base/$id/share')).timeout(const Duration(seconds: 15));
    if (resp.statusCode != 200) throw Exception('SHARE HTTP ${resp.statusCode}');
    return (jsonDecode(resp.body) as Map<String, dynamic>)['code'] as String? ?? '';
  }

  Future<Workout> import(String code) async {
    final resp = await _client
        .post(Uri.parse('$_base/import'), body: jsonEncode({'code': code}))
        .timeout(const Duration(seconds: 15));
    if (resp.statusCode != 201) throw Exception(_err(resp.body, resp.statusCode));
    return Workout.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
  }

  Future<void> setVisibility(String id, String visibility) async {
    final resp = await _client
        .put(Uri.parse('$_base/$id/visibility'), body: jsonEncode({'visibility': visibility}))
        .timeout(const Duration(seconds: 15));
    if (resp.statusCode != 204) throw Exception('VISIBILITY HTTP ${resp.statusCode}');
  }

  Future<void> logRun(String id, String difficulty) async {
    final resp = await _client
        .post(Uri.parse('$_base/$id/run'), body: jsonEncode({'difficulty': difficulty}))
        .timeout(const Duration(seconds: 15));
    if (resp.statusCode != 204) throw Exception('RUN HTTP ${resp.statusCode}');
  }

  String _encode(String name, String comment, List<WorkoutExercise> exercises) => jsonEncode({
        'name': name,
        'comment': comment,
        'exercises': exercises.map((e) => e.toJson()).toList(),
      });

  String _err(String body, int code) {
    try {
      return (jsonDecode(body) as Map<String, dynamic>)['error'] as String? ?? 'HTTP $code';
    } catch (_) {
      return 'HTTP $code';
    }
  }
}
