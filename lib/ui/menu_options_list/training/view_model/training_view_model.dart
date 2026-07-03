import "package:gymboss/data/services/trainings/trainings.dart";
import "package:gymboss/domain/models/trainings/trainings.dart";

class TrainingViewModel {
  final TrainingsService trainingsService;

  TrainingViewModel({required this.trainingsService});

  List<TrainingEntity> trainings = [];
  bool isLoading = false;
  String? error;

  Future<void> loadTrainings() async {
    isLoading = true;

    try {
      trainings = await trainingsService.fetchAllTrainings();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
    }
  }
}
