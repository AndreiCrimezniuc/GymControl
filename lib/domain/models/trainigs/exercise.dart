class Exercise {
  final int id;
  final String name;
  final List<ExerciseSet> sets;
  final ExerciseHistory? history;

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

  ExerciseSet({required this.weight, required this.reps});
}

class ExerciseHistory {
  final DateTime date;
  final List<ExerciseSet> completedSets;

  ExerciseHistory({required this.date, required this.completedSets});
}
