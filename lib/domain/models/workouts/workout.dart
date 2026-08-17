const workoutDifficulties = ['easy', 'medium', 'hard'];

class WorkoutSet {
  final String difficulty; // easy | medium | hard
  final double weightKg;
  final int reps;
  final String setType; // warmup | working | failure | dropset

  const WorkoutSet({
    required this.difficulty,
    required this.weightKg,
    required this.reps,
    this.setType = 'working',
  });

  factory WorkoutSet.fromJson(Map<String, dynamic> j) => WorkoutSet(
    difficulty: (j['difficulty'] as String?) ?? 'medium',
    weightKg: (j['weight_kg'] as num?)?.toDouble() ?? 0,
    reps: (j['reps'] as num?)?.toInt() ?? 0,
    setType: (j['set_type'] as String?) ?? 'working',
  );

  Map<String, dynamic> toJson() => {
    'difficulty': difficulty,
    'weight_kg': weightKg,
    'reps': reps,
    'set_type': setType,
  };

  WorkoutSet copyWith({
    String? difficulty,
    double? weightKg,
    int? reps,
    String? setType,
  }) => WorkoutSet(
    difficulty: difficulty ?? this.difficulty,
    weightKg: weightKg ?? this.weightKg,
    reps: reps ?? this.reps,
    setType: setType ?? this.setType,
  );
}

class WorkoutExercise {
  final int exerciseId;
  final String name;
  final String imageUrl;
  final String imageUrl2;
  final String muscleGroup;
  final String exerciseType;
  final String? trainingGroupId;
  final String trainingGroupType;
  final bool isOptional;
  final String? alternativeGroupId;
  final int restSeconds;
  final String comment;
  final List<WorkoutSet> sets;

  const WorkoutExercise({
    required this.exerciseId,
    required this.name,
    required this.imageUrl,
    this.imageUrl2 = "",
    required this.muscleGroup,
    this.exerciseType = 'weight_reps',
    this.trainingGroupId,
    this.trainingGroupType = '',
    this.isOptional = false,
    this.alternativeGroupId,
    required this.restSeconds,
    required this.comment,
    required this.sets,
  });

  factory WorkoutExercise.fromJson(Map<String, dynamic> j) => WorkoutExercise(
    exerciseId: (j['exercise_id'] as num?)?.toInt() ?? 0,
    name: (j['name'] as String?) ?? '',
    imageUrl: (j['image_url'] as String?) ?? '',
    imageUrl2: (j['image_url2'] as String?) ?? '',
    muscleGroup: (j['muscle_group'] as String?) ?? '',
    exerciseType: (j['exercise_type'] as String?) ?? 'weight_reps',
    trainingGroupId: j['training_group_id'] as String?,
    trainingGroupType: (j['training_group_type'] as String?) ?? '',
    isOptional: (j['is_optional'] as bool?) ?? false,
    alternativeGroupId: j['alternative_group_id'] as String?,
    restSeconds: (j['rest_seconds'] as num?)?.toInt() ?? 90,
    comment: (j['comment'] as String?) ?? '',
    sets:
        ((j['sets'] as List?) ?? [])
            .map((e) => WorkoutSet.fromJson(e as Map<String, dynamic>))
            .toList(),
  );

  Map<String, dynamic> toJson() => {
    'exercise_id': exerciseId,
    'exercise_type': exerciseType,
    'training_group_id': trainingGroupId,
    'training_group_type': trainingGroupType,
    'is_optional': isOptional,
    'alternative_group_id': alternativeGroupId,
    'rest_seconds': restSeconds,
    'comment': comment,
    'sets': sets.map((s) => s.toJson()).toList(),
  };

  List<WorkoutSet> setsFor(String difficulty) =>
      sets.where((s) => s.difficulty == difficulty).toList();

  WorkoutExercise copyWith({
    int? restSeconds,
    String? comment,
    List<WorkoutSet>? sets,
  }) => WorkoutExercise(
    exerciseId: exerciseId,
    name: name,
    imageUrl: imageUrl,
    imageUrl2: imageUrl2,
    muscleGroup: muscleGroup,
    exerciseType: exerciseType,
    trainingGroupId: trainingGroupId,
    trainingGroupType: trainingGroupType,
    isOptional: isOptional,
    alternativeGroupId: alternativeGroupId,
    restSeconds: restSeconds ?? this.restSeconds,
    comment: comment ?? this.comment,
    sets: sets ?? this.sets,
  );
}

class Workout {
  final String id;
  final String name;
  final String comment;
  final String type; // gym | aerobic
  final String visibility; // private | public
  final bool owned;
  final String shareCode;
  final int exerciseCount;
  final int timesPerformed;
  final double deloadFactor; // deload weight multiplier vs Normal (e.g. 0.70)
  final List<WorkoutExercise> exercises;
  final String? folderId;

  const Workout({
    required this.id,
    required this.name,
    required this.comment,
    this.type = 'gym',
    required this.visibility,
    required this.owned,
    required this.shareCode,
    required this.exerciseCount,
    required this.timesPerformed,
    this.deloadFactor = 0.70,
    required this.exercises,
    this.folderId,
  });

  bool get isPublic => visibility == 'public';
  factory Workout.fromJson(Map<String, dynamic> j) => Workout(
    id: (j['id'] as String?) ?? '',
    name: (j['name'] as String?) ?? '',
    comment: (j['comment'] as String?) ?? '',
    type: (j['type'] as String?) ?? 'gym',
    visibility: (j['visibility'] as String?) ?? 'private',
    owned: (j['owned'] as bool?) ?? false,
    shareCode: (j['share_code'] as String?) ?? '',
    exerciseCount: (j['exercise_count'] as num?)?.toInt() ?? 0,
    timesPerformed: (j['times_performed'] as num?)?.toInt() ?? 0,
    deloadFactor: (j['deload_factor'] as num?)?.toDouble() ?? 0.70,
    exercises:
        ((j['exercises'] as List?) ?? [])
            .map((e) => WorkoutExercise.fromJson(e as Map<String, dynamic>))
            .toList(),
    folderId: j['folder_id'] as String?,
  );

  /// Distinct muscle groups across the workout's exercises, for card chips.
  List<String> get muscleGroups {
    final seen = <String>{};
    final out = <String>[];
    for (final e in exercises) {
      if (e.muscleGroup.isNotEmpty && seen.add(e.muscleGroup)) {
        out.add(e.muscleGroup);
      }
    }
    return out;
  }

  Workout copyWith({List<WorkoutExercise>? exercises}) => Workout(
    id: id,
    name: name,
    comment: comment,
    type: type,
    visibility: visibility,
    owned: owned,
    shareCode: shareCode,
    exerciseCount: exercises?.length ?? exerciseCount,
    timesPerformed: timesPerformed,
    deloadFactor: deloadFactor,
    exercises: exercises ?? this.exercises,
    folderId: folderId,
  );
}

class WorkoutFolder {
  final String id;
  final String name;
  final int position;

  const WorkoutFolder({
    required this.id,
    required this.name,
    required this.position,
  });

  factory WorkoutFolder.fromJson(Map<String, dynamic> json) => WorkoutFolder(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    position: (json['position'] as num?)?.toInt() ?? 0,
  );
}

class WorkoutRunPoint {
  final String date;
  final String difficulty;
  const WorkoutRunPoint({required this.date, required this.difficulty});

  factory WorkoutRunPoint.fromJson(Map<String, dynamic> j) => WorkoutRunPoint(
    date: (j['date'] as String?) ?? '',
    difficulty: (j['difficulty'] as String?) ?? '',
  );
}

class PerformedSetLog {
  final double weightKg;
  final int reps;
  final String setType;
  final String
  progression; // '' | weight | amplitude | efficiency | meo | dropset
  const PerformedSetLog({
    required this.weightKg,
    required this.reps,
    required this.setType,
    this.progression = '',
  });

  factory PerformedSetLog.fromJson(Map<String, dynamic> j) => PerformedSetLog(
    weightKg: (j['weight_kg'] as num?)?.toDouble() ?? 0,
    reps: (j['reps'] as num?)?.toInt() ?? 0,
    setType: (j['set_type'] as String?) ?? 'working',
    progression: (j['progression'] as String?) ?? '',
  );
}

class PerformedExerciseLog {
  final int exerciseId;
  final String name;
  final String muscleGroup;
  final List<PerformedSetLog> sets;
  const PerformedExerciseLog({
    required this.exerciseId,
    required this.name,
    required this.muscleGroup,
    required this.sets,
  });

  factory PerformedExerciseLog.fromJson(Map<String, dynamic> j) =>
      PerformedExerciseLog(
        exerciseId: (j['exercise_id'] as num?)?.toInt() ?? 0,
        name: (j['name'] as String?) ?? '',
        muscleGroup: (j['muscle_group'] as String?) ?? '',
        sets:
            ((j['sets'] as List?) ?? [])
                .map((e) => PerformedSetLog.fromJson(e as Map<String, dynamic>))
                .toList(),
      );

  double get volumeKg => sets
      .where((s) => s.setType != 'warmup')
      .fold(0.0, (a, s) => a + s.weightKg * s.reps);
}

class MonthlyCount {
  final String month; // YYYY-MM
  final int count;
  const MonthlyCount({required this.month, required this.count});

  factory MonthlyCount.fromJson(Map<String, dynamic> j) => MonthlyCount(
    month: (j['month'] as String?) ?? '',
    count: (j['count'] as num?)?.toInt() ?? 0,
  );
}

class ActivityPoint {
  final String date;
  final int durationSeconds;
  final int reps;
  final double volumeKg;
  final int workingSets;
  final int hardSets;
  final double averageRpe;
  final int rpeSets;
  final double distanceKm;
  final int workouts;

  const ActivityPoint({
    required this.date,
    required this.durationSeconds,
    required this.reps,
    required this.volumeKg,
    this.workingSets = 0,
    this.hardSets = 0,
    this.averageRpe = 0,
    this.rpeSets = 0,
    this.distanceKm = 0,
    required this.workouts,
  });

  factory ActivityPoint.fromJson(Map<String, dynamic> json) => ActivityPoint(
    date: json['date'] as String? ?? '',
    durationSeconds: (json['duration_seconds'] as num?)?.toInt() ?? 0,
    reps: (json['reps'] as num?)?.toInt() ?? 0,
    volumeKg: (json['volume_kg'] as num?)?.toDouble() ?? 0,
    workingSets: (json['working_sets'] as num?)?.toInt() ?? 0,
    hardSets: (json['hard_sets'] as num?)?.toInt() ?? 0,
    averageRpe: (json['average_rpe'] as num?)?.toDouble() ?? 0,
    rpeSets: (json['rpe_sets'] as num?)?.toInt() ?? 0,
    distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0,
    workouts: (json['workouts'] as num?)?.toInt() ?? 0,
  );
}

/// Aggregates behind the statistics screen (from GET /stats/summary).
class StatsSummary {
  final int totalWorkouts;
  final int longestWorkoutSeconds;
  final String favoriteExercise;
  final String strongestExercise;
  final List<MonthlyCount> workoutsPerMonth;

  const StatsSummary({
    required this.totalWorkouts,
    required this.longestWorkoutSeconds,
    required this.favoriteExercise,
    required this.strongestExercise,
    required this.workoutsPerMonth,
  });

  static const empty = StatsSummary(
    totalWorkouts: 0,
    longestWorkoutSeconds: 0,
    favoriteExercise: '',
    strongestExercise: '',
    workoutsPerMonth: [],
  );

  factory StatsSummary.fromJson(Map<String, dynamic> j) => StatsSummary(
    totalWorkouts: (j['total_workouts'] as num?)?.toInt() ?? 0,
    longestWorkoutSeconds: (j['longest_workout_seconds'] as num?)?.toInt() ?? 0,
    favoriteExercise: (j['favorite_exercise'] as String?) ?? '',
    strongestExercise: (j['strongest_exercise'] as String?) ?? '',
    workoutsPerMonth:
        ((j['workouts_per_month'] as List?) ?? [])
            .map((e) => MonthlyCount.fromJson(e as Map<String, dynamic>))
            .toList(),
  );
}

class WorkoutStats {
  final int timesPerformed;
  final Map<String, double> potentialVolume; // difficulty -> tonnage
  final List<WorkoutRunPoint> history;
  final int averageDurationSeconds;

  const WorkoutStats({
    required this.timesPerformed,
    required this.potentialVolume,
    required this.history,
    this.averageDurationSeconds = 0,
  });

  factory WorkoutStats.fromJson(Map<String, dynamic> j) {
    final pv = (j['potential_volume'] as Map<String, dynamic>?) ?? const {};
    return WorkoutStats(
      timesPerformed: (j['times_performed'] as num?)?.toInt() ?? 0,
      potentialVolume: {
        'easy': (pv['easy'] as num?)?.toDouble() ?? 0,
        'medium': (pv['medium'] as num?)?.toDouble() ?? 0,
        'hard': (pv['hard'] as num?)?.toDouble() ?? 0,
      },
      history:
          ((j['history'] as List?) ?? [])
              .map((e) => WorkoutRunPoint.fromJson(e as Map<String, dynamic>))
              .toList(),
      averageDurationSeconds:
          (j['average_duration_seconds'] as num?)?.toInt() ?? 0,
    );
  }
}
