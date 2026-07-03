import 'package:gymboss/domain/models/trainigs/trainigs.dart';
import 'package:gymboss/data/apimodels/trainigs/exercise.dart';

class TrainingsModel extends Trainings {
  TrainingsModel({
    required super.id,
    required super.name,
    required super.complexity,
    required List<ExerciseModel> super.exercises,
  });

  factory TrainingsModel.fromJson(Map<String, dynamic> json) {
    return TrainingsModel(
      id: json['id'],
      name: json['name'],
      complexity: json['complexity'],
      exercises: (json['exercises'] as List<dynamic>)
          .map((e) => ExerciseModel.fromJson(e))
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
