import 'package:gymboss/domain/models/trainings/exercise.dart';

class ExerciseModel extends Exercise {
  ExerciseModel({
    required super.id,
    required super.name,
    List<ExerciseSet>? sets,
    super.history,
  }) : super(sets: sets ?? const []);

  factory ExerciseModel.fromJson(Map<String, dynamic> json) {
    return ExerciseModel(
      id: json['id'],
      name: json['name'],
      sets:
          (json['sets'] as List<dynamic>?)
              ?.map(
                (e) => ExerciseSet(
                  weight: e['weight'].toDouble(),
                  reps: e['reps'],
                ),
              )
              .toList() ??
          [],
      history: json['history'] != null
          ? ExerciseHistory(
              date: DateTime.parse(json['history']['date']),
              completedSets: (json['history']['completedSets'] as List)
                  .map(
                    (e) => ExerciseSet(
                      weight: e['weight'].toDouble(),
                      reps: e['reps'],
                    ),
                  )
                  .toList(),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sets': sets.map((e) => {'weight': e.weight, 'reps': e.reps}).toList(),
      'history': history != null
          ? {
              'date': history!.date.toIso8601String(),
              'completedSets': history!.completedSets
                  .map((e) => {'weight': e.weight, 'reps': e.reps})
                  .toList(),
            }
          : null,
    };
  }
}
