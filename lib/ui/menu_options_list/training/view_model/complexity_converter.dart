import 'package:gymboss/domain/models/trainings/trainings.dart';

class ComplexityConverter {
  TrainingEntity hardToMedium(TrainingEntity training) {
    final updatedExercises = training.exercises.map((exercise) {
      final updatedSets = exercise.sets.map((set) {
        return set.copyWith(weight: set.weight * 0.8);
      }).toList();

      return exercise.copyWith(sets: updatedSets);
    }).toList();

    return training.copyWith(exercises: updatedExercises);
  }
}
