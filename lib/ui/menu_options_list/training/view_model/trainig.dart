import "package:gymboss/data/services/trainigs/trainings.dart";
import "package:gymboss/domain/models/trainigs/trainigs.dart";

class TrainingViewModel {
  final TrainingsService trainingsService;

  TrainingViewModel({required this.trainingsService});

  List<Trainings> trainings = [];
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
