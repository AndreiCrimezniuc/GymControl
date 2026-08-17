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
  final String exerciseType;
  final List<String> secondaryMuscles;
  final List<String> aliases;

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
    this.exerciseType = 'weight_reps',
    this.secondaryMuscles = const [],
    this.aliases = const [],
  });

  factory ExerciseCatalogItem.fromJson(Map<String, dynamic> j) =>
      ExerciseCatalogItem(
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
        exerciseType: (j['exercise_type'] as String?) ?? 'weight_reps',
        secondaryMuscles:
            ((j['secondary_muscles'] as List?) ?? const [])
                .whereType<String>()
                .toList(),
        aliases:
            ((j['aliases'] as List?) ?? const []).whereType<String>().toList(),
      );

  bool matchesSearch(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    return <String>[
      name,
      muscleGroup,
      equipment,
      category,
      level,
      ...secondaryMuscles,
      ...aliases,
    ].any((value) => value.toLowerCase().contains(normalized));
  }
}

class ExerciseProgressionPoint {
  final String date;
  final double topWeightKg;
  final int topReps;
  final double volumeKg;
  const ExerciseProgressionPoint({
    required this.date,
    required this.topWeightKg,
    this.topReps = 0,
    this.volumeKg = 0,
  });

  factory ExerciseProgressionPoint.fromJson(Map<String, dynamic> j) =>
      ExerciseProgressionPoint(
        date: (j['date'] as String?) ?? '',
        topWeightKg: (j['top_weight_kg'] as num?)?.toDouble() ?? 0,
        topReps: (j['top_reps'] as num?)?.toInt() ?? 0,
        volumeKg: (j['volume_kg'] as num?)?.toDouble() ?? 0,
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
  final double estimatedOneRmKg;
  final double maxSetVolumeKg;
  final String? rank;
  final List<ExerciseProgressionPoint> progression;
  final List<ExerciseRecord> records;

  const ExerciseStats({
    required this.exerciseId,
    required this.timesPerformed,
    required this.totalSets,
    required this.totalReps,
    required this.avgSetsPerWorkout,
    required this.maxWeightKg,
    required this.maxVolumeKg,
    this.estimatedOneRmKg = 0,
    this.maxSetVolumeKg = 0,
    required this.rank,
    required this.progression,
    this.records = const [],
  });

  factory ExerciseStats.fromJson(Map<String, dynamic> j) => ExerciseStats(
    exerciseId: (j['exercise_id'] as num?)?.toInt() ?? 0,
    timesPerformed: (j['times_performed'] as num?)?.toInt() ?? 0,
    totalSets: (j['total_sets'] as num?)?.toInt() ?? 0,
    totalReps: (j['total_reps'] as num?)?.toInt() ?? 0,
    avgSetsPerWorkout: (j['avg_sets_per_workout'] as num?)?.toDouble() ?? 0,
    maxWeightKg: (j['max_weight_kg'] as num?)?.toDouble() ?? 0,
    maxVolumeKg: (j['max_volume_kg'] as num?)?.toDouble() ?? 0,
    estimatedOneRmKg: (j['estimated_one_rm_kg'] as num?)?.toDouble() ?? 0,
    maxSetVolumeKg: (j['max_set_volume_kg'] as num?)?.toDouble() ?? 0,
    rank: j['rank'] as String?,
    progression:
        ((j['progression'] as List?) ?? [])
            .map(
              (e) =>
                  ExerciseProgressionPoint.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
    records:
        ((j['records'] as List?) ?? const [])
            .map((e) => ExerciseRecord.fromJson(e as Map<String, dynamic>))
            .toList(),
  );

  bool get hasData => totalSets > 0;
}

class ExerciseRecord {
  final String type;
  final String date;
  final double weightKg;
  final int reps;
  final double value;

  const ExerciseRecord({
    required this.type,
    required this.date,
    required this.weightKg,
    required this.reps,
    required this.value,
  });

  factory ExerciseRecord.fromJson(Map<String, dynamic> json) => ExerciseRecord(
    type: json['type'] as String? ?? '',
    date: json['date'] as String? ?? '',
    weightKg: (json['weight_kg'] as num?)?.toDouble() ?? 0,
    reps: (json['reps'] as num?)?.toInt() ?? 0,
    value: (json['value'] as num?)?.toDouble() ?? 0,
  );
}

class ExerciseHistorySet {
  final double weightKg;
  final int reps;
  final String setType;
  final String progression;
  final double? rpe;

  const ExerciseHistorySet({
    required this.weightKg,
    required this.reps,
    required this.setType,
    required this.progression,
    this.rpe,
  });

  factory ExerciseHistorySet.fromJson(Map<String, dynamic> json) =>
      ExerciseHistorySet(
        weightKg: (json['weight_kg'] as num?)?.toDouble() ?? 0,
        reps: (json['reps'] as num?)?.toInt() ?? 0,
        setType: json['set_type'] as String? ?? 'working',
        progression: json['progression'] as String? ?? '',
        rpe: (json['rpe'] as num?)?.toDouble(),
      );
}

class ExerciseHistorySession {
  final String date;
  final String workoutId;
  final String workoutName;
  final String sessionId;
  final List<ExerciseHistorySet> sets;

  const ExerciseHistorySession({
    required this.date,
    required this.workoutId,
    required this.workoutName,
    this.sessionId = '',
    required this.sets,
  });

  factory ExerciseHistorySession.fromJson(Map<String, dynamic> json) =>
      ExerciseHistorySession(
        date: json['date'] as String? ?? '',
        workoutId: json['workout_id'] as String? ?? '',
        workoutName: json['workout_name'] as String? ?? '',
        sessionId: json['session_id'] as String? ?? '',
        sets:
            ((json['sets'] as List?) ?? const [])
                .map(
                  (e) => ExerciseHistorySet.fromJson(e as Map<String, dynamic>),
                )
                .toList(),
      );
}
