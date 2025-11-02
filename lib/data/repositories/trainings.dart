import 'package:gymboss/domain/models/trainigs/trainigs.dart';
import 'package:gymboss/domain/models/trainigs/exercise.dart';

abstract class TrainingsRepository {
  Future<List<Trainings>> getTrainings();
  Future<void> saveTraining(Trainings trainings);
}

class TrainingsRepositoryImpl implements TrainingsRepository {
  final List<Trainings> _mockData = [
    Trainings(
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
    Trainings(
      id: '2',
      name: 'Medium',
      complexity: TrainingComplexity.hard,
      exercises: [Exercise(id: 3, name: 'Pull Ups', sets: [])],
    ),
  ];

  @override
  Future<List<Trainings>> getTrainings() async {
    await Future.delayed(const Duration(milliseconds: 500)); // имитация API
    return _mockData;
  }

  @override
  Future<void> saveTraining(Trainings trainings) async {
    _mockData.add(trainings);
    await Future.delayed(const Duration(milliseconds: 200));
  }
}
