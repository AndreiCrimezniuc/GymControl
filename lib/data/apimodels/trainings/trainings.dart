import 'package:gymboss/domain/models/trainings/trainings.dart';
import 'package:gymboss/data/apimodels/trainings/exercise.dart';

class TrainingsModel extends TrainingEntity {
  TrainingsModel({
    required super.id,
    required super.name,
    required super.complexity,
    required List<ExerciseModel> super.exercises,
  });

  factory TrainingsModel.fromJson(Map<String, dynamic> json) {
    return TrainingsModel(
      id: json['id'] as String,
      name: json['name'] as String,
      complexity: TrainingComplexity.values.firstWhere(
        (c) => c.name == (json['complexity'] as String),
        orElse: () => TrainingComplexity.easy,
      ),
      exercises: (json['exercises'] as List<dynamic>)
          .map((e) => ExerciseModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'complexity': complexity,
      'name': name,
      'exercises': exercises.map((e) => (e as ExerciseModel).toJson()).toList(),
    };
  }
}
