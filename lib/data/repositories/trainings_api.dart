import 'dart:convert';
import 'package:gymboss/config/api_config.dart';
import 'package:gymboss/core/errors/app_error.dart';
import 'package:gymboss/data/apimodels/trainings/trainings.dart';
import 'package:gymboss/data/repositories/trainings.dart';
import 'package:gymboss/data/services/auth/authenticated_client.dart';
import 'package:gymboss/domain/models/trainings/trainings.dart';

class TrainingsApiRepository implements TrainingsRepository {
  final AuthenticatedClient _client;
  final String _base = '${ApiConfig.apiBaseUrl}/api/v1';

  TrainingsApiRepository({required AuthenticatedClient client})
      : _client = client;

  @override
  Future<List<TrainingEntity>> getTrainings() async {
    final resp = await _client
        .get(Uri.parse('$_base/trainings'))
        .timeout(const Duration(seconds: 10));

    if (resp.statusCode != 200) {
      throw AppError(
        AppErrorCode.dataLoadFailed,
        message: 'GET /trainings HTTP ${resp.statusCode}: ${resp.body}',
      )..log();
    }

    try {
      final list = jsonDecode(resp.body) as List<dynamic>;
      return list
          .map((e) => TrainingsModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, s) {
      throw AppError(AppErrorCode.dataParseError, message: e.toString(), cause: e)..log(s);
    }
  }

  @override
  Future<void> saveTraining(TrainingEntity training) async {
    final body = jsonEncode({
      'name': training.name,
      'complexity': training.complexity.name,
      'exercises': training.exercises
          .map((e) => {
                'id': e.id,
                'name': e.name,
                'sets': e.sets
                    .map((s) => {'weight': s.weight, 'reps': s.reps})
                    .toList(),
              })
          .toList(),
    });

    final resp = await _client
        .post(Uri.parse('$_base/trainings'), body: body)
        .timeout(const Duration(seconds: 10));

    if (resp.statusCode != 201) {
      throw AppError(
        AppErrorCode.dataSaveFailed,
        message: 'POST /trainings HTTP ${resp.statusCode}: ${resp.body}',
      )..log();
    }
  }
}
