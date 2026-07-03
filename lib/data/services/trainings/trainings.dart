import "package:gymboss/data/repositories/trainings.dart";
import "package:gymboss/domain/models/trainings/trainings.dart";

class TrainingsService {
  final TrainingsRepository repository;

  TrainingsService({required this.repository});

  Future<List<TrainingEntity>> fetchAllTrainings() async {
    return await repository.getTrainings();
  }

  Future<void> addTraining(TrainingEntity training) async {
    await repository.saveTraining(training);
  }
}
