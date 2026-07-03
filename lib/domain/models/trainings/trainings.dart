import 'package:gymboss/domain/models/trainings/exercise.dart';

class TrainingEntity {
  final String id;
  final String name;
  final List<Exercise> exercises;
  final TrainingComplexity complexity;
  @override
  String toString() {
    return 'Trainings(id: $id, name: $name, exercises: $exercises)';
  }

  TrainingEntity copyWith({
    String? id,
    String? name,
    List<Exercise>? exercises,
    TrainingComplexity? complexity,
  }) {
    return TrainingEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      exercises: exercises ?? this.exercises,
      complexity: complexity ?? this.complexity,
    );
  }

  factory TrainingEntity.empty() {
    return const TrainingEntity(
      id: '',
      name: '',
      complexity: TrainingComplexity.easy,
      exercises: [],
    );
  }

  bool isEmpty() {
    return id == "";
  }

  const TrainingEntity({
    required this.id,
    required this.name,
    required this.complexity,
    required this.exercises,
  });
}

enum TrainingComplexity { easy, medium, hard }
