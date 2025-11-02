import 'package:gymboss/domain/models/trainigs/exercise.dart';

class Trainings {
  final String id;
  final String name;
  final List<Exercise> exercises;
  final TrainingComplexity complexity;
  @override
  String toString() {
    return 'Trainings(id: $id, name: $name, exercises: $exercises)';
  }

  factory Trainings.empty() {
    return const Trainings(
      id: '',
      name: '',
      complexity: TrainingComplexity.easy,
      exercises: [],
    );
  }

  bool isEmpty() {
    return id == "";
  }

  const Trainings({
    required this.id,
    required this.name,
    required this.complexity,
    required this.exercises,
  });
}

enum TrainingComplexity { easy, medium, hard }
