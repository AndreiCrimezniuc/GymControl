import 'dart:convert';

import 'package:gymboss/config/api_config.dart';
import 'package:gymboss/data/local/local_store.dart';
import 'package:gymboss/data/services/auth/authenticated_client.dart';
import 'package:gymboss/data/sync/network_failure.dart';
import 'package:gymboss/domain/models/measurements/body_measurement.dart';

class MeasurementsRepository {
  static const _cacheCollection = 'body_measurements';
  static const _cacheKey = 'body_measurements:list';

  final AuthenticatedClient _client;
  final LocalStore _store = LocalStore.instance;
  final String _base = '${ApiConfig.apiBaseUrl}/api/v1/measurements';

  MeasurementsRepository({required AuthenticatedClient client})
    : _client = client;

  Future<List<BodyMeasurement>> list() async {
    try {
      final response = await _client
          .get(Uri.parse(_base))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw Exception('GET /measurements HTTP ${response.statusCode}');
      }
      final raw =
          (jsonDecode(response.body) as List).cast<Map<String, dynamic>>();
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

  Future<BodyMeasurement> save(BodyMeasurement measurement) async {
    final response = await _client
        .post(Uri.parse(_base), body: jsonEncode(measurement.toJson()))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 201) {
      throw Exception('POST /measurements HTTP ${response.statusCode}');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final saved = BodyMeasurement.fromJson(json);
    await _store.putDoc(_cacheCollection, saved.id, json);
    final ids = _store.getListIds(_cacheKey).toList()..remove(saved.id);
    await _store.putListIds(_cacheKey, [saved.id, ...ids]);
    return saved;
  }

  Future<void> delete(String id) async {
    final response = await _client
        .delete(Uri.parse('$_base/$id'))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 204) {
      throw Exception('DELETE /measurements/$id HTTP ${response.statusCode}');
    }
    await _store.deleteDoc(_cacheCollection, id);
    await _store.removeFromList(_cacheKey, id);
  }
}
