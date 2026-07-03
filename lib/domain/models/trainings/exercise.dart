class Exercise {
  final int id;
  final String name;
  final List<ExerciseSet> sets;
  final ExerciseHistory? history;

  Exercise copyWith({
    int? id,
    String? name,
    List<ExerciseSet>? sets,
    ExerciseHistory? history,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      sets: sets ?? this.sets,
      history: history ?? this.history,
    );
  }

  Exercise({
    required this.id,
    required this.name,
    this.sets = const [],
    this.history,
  });

  int get totalSets => sets.length;
}

class ExerciseSet {
  final double weight;
  final int reps;

  ExerciseSet copyWith({double? weight, int? reps}) {
    return ExerciseSet(weight: weight ?? this.weight, reps: reps ?? this.reps);
  }

  ExerciseSet({required this.weight, required this.reps});
}

class ExerciseHistory {
  final DateTime date;
  final List<ExerciseSet> completedSets;

  ExerciseHistory({required this.date, required this.completedSets});
}
