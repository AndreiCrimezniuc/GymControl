import "package:gymboss/data/repositories/trainings.dart";
import "package:gymboss/domain/models/trainigs/trainigs.dart";

class TrainingsService {
  final TrainingsRepository repository;

  TrainingsService({required this.repository});

  Future<List<Trainings>> fetchAllTrainings() async {
    return await repository.getTrainings();
  }

  Future<void> addTraining(Trainings training) async {
    await repository.saveTraining(training);
  }
}
