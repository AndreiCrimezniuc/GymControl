import 'package:gymboss/domain/models/trainings/trainings.dart';
import 'package:gymboss/domain/models/trainings/exercise.dart';

abstract class TrainingsRepository {
  Future<List<TrainingEntity>> getTrainings();
  Future<void> saveTraining(TrainingEntity trainings);
}

class TrainingsRepositoryImpl implements TrainingsRepository {
  final List<TrainingEntity> _mockData = [
    TrainingEntity(
      id: '1',
      name: 'Hard',
      complexity: TrainingComplexity.hard,
      exercises: [
        Exercise(
          id: 1,
          name: 'Bench Press',
          sets: [
            ExerciseSet(weight: 80, reps: 10),
            ExerciseSet(weight: 85, reps: 8),
          ],
        ),
        Exercise(
          id: 2,
          name: 'Squats',
          sets: [
            ExerciseSet(weight: 100, reps: 12),
            ExerciseSet(weight: 80, reps: 12),
            ExerciseSet(weight: 60, reps: 12),
          ],
        ),
      ],
    ),
    TrainingEntity(
      id: '2',
      name: 'Medium',
      complexity: TrainingComplexity.hard,
      exercises: [Exercise(id: 3, name: 'Pull Ups', sets: [])],
    ),
  ];

  @override
  Future<List<TrainingEntity>> getTrainings() async {
    await Future.delayed(const Duration(milliseconds: 500)); // имитация API
    return _mockData;
  }

  @override
  Future<void> saveTraining(TrainingEntity trainings) async {
    _mockData.add(trainings);
    await Future.delayed(const Duration(milliseconds: 200));
  }
}
