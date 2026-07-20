class ExerciseCatalogItem {
  final int id;
  final String name;
  final String muscleGroup;
  final String equipment;
  final String category;
  final String level;
  final String force;
  final String imageUrl;
  final String imageUrl2;
  final String instructions;

  const ExerciseCatalogItem({
    required this.id,
    required this.name,
    required this.muscleGroup,
    required this.equipment,
    required this.category,
    required this.level,
    required this.force,
    required this.imageUrl,
    required this.imageUrl2,
    required this.instructions,
  });

  factory ExerciseCatalogItem.fromJson(Map<String, dynamic> j) => ExerciseCatalogItem(
        id: j['id'] as int,
        name: (j['name'] as String?) ?? '',
        muscleGroup: (j['muscle_group'] as String?) ?? '',
        equipment: (j['equipment'] as String?) ?? '',
        category: (j['category'] as String?) ?? '',
        level: (j['level'] as String?) ?? '',
        force: (j['force'] as String?) ?? '',
        imageUrl: (j['image_url'] as String?) ?? '',
        imageUrl2: (j['image_url2'] as String?) ?? '',
        instructions: (j['instructions'] as String?) ?? '',
      );
}

class ExerciseProgressionPoint {
  final String date;
  final double topWeightKg;
  const ExerciseProgressionPoint({required this.date, required this.topWeightKg});

  factory ExerciseProgressionPoint.fromJson(Map<String, dynamic> j) => ExerciseProgressionPoint(
        date: (j['date'] as String?) ?? '',
        topWeightKg: (j['top_weight_kg'] as num?)?.toDouble() ?? 0,
      );
}

class ExerciseStats {
  final int exerciseId;
  final int timesPerformed;
  final int totalSets;
  final int totalReps;
  final double avgSetsPerWorkout;
  final double maxWeightKg;
  final double maxVolumeKg;
  final double loveCoefficient; // 0..1
  final String? rank;
  final List<ExerciseProgressionPoint> progression;

  const ExerciseStats({
    required this.exerciseId,
    required this.timesPerformed,
    required this.totalSets,
    required this.totalReps,
    required this.avgSetsPerWorkout,
    required this.maxWeightKg,
    required this.maxVolumeKg,
    required this.loveCoefficient,
    required this.rank,
    required this.progression,
  });

  factory ExerciseStats.fromJson(Map<String, dynamic> j) => ExerciseStats(
        exerciseId: (j['exercise_id'] as num?)?.toInt() ?? 0,
        timesPerformed: (j['times_performed'] as num?)?.toInt() ?? 0,
        totalSets: (j['total_sets'] as num?)?.toInt() ?? 0,
        totalReps: (j['total_reps'] as num?)?.toInt() ?? 0,
        avgSetsPerWorkout: (j['avg_sets_per_workout'] as num?)?.toDouble() ?? 0,
        maxWeightKg: (j['max_weight_kg'] as num?)?.toDouble() ?? 0,
        maxVolumeKg: (j['max_volume_kg'] as num?)?.toDouble() ?? 0,
        loveCoefficient: (j['love_coefficient'] as num?)?.toDouble() ?? 0,
        rank: j['rank'] as String?,
        progression: ((j['progression'] as List?) ?? [])
            .map((e) => ExerciseProgressionPoint.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  bool get hasData => totalSets > 0;
  int get loveScore => (loveCoefficient * 10).round().clamp(0, 10); // 0..10
}
