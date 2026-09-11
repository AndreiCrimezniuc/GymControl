import 'package:gymboss/domain/models/json_readers.dart';

const workoutDifficulties = ['easy', 'medium', 'hard'];

class WorkoutSet {
  final String difficulty; // easy | medium | hard
  final double weightKg;
  final int reps;
  final String setType; // warmup | working | failure | dropset
  final int? restSeconds; // null inherits the exercise default

  const WorkoutSet({
    required this.difficulty,
    required this.weightKg,
    required this.reps,
    this.setType = 'working',
    this.restSeconds,
  });

  factory WorkoutSet.fromJson(Map<String, dynamic> j) => WorkoutSet(
    difficulty: jsonString(j['difficulty'], 'medium'),
    weightKg: jsonDouble(j['weight_kg'], min: 0, max: 2000),
    reps: jsonInt(j['reps'], min: 0, max: 10000),
    setType: jsonString(j['set_type'], 'working'),
    restSeconds: j['rest_seconds'] == null
        ? null
        : jsonInt(j['rest_seconds'], min: 0, max: 3600),
  );

  Map<String, dynamic> toJson() => {
    'difficulty': difficulty,
    'weight_kg': weightKg,
    'reps': reps,
    'set_type': setType,
    if (restSeconds != null) 'rest_seconds': restSeconds,
  };

  WorkoutSet copyWith({
    String? difficulty,
    double? weightKg,
    int? reps,
    String? setType,
    int? restSeconds,
  }) => WorkoutSet(
    difficulty: difficulty ?? this.difficulty,
    weightKg: weightKg ?? this.weightKg,
    reps: reps ?? this.reps,
    setType: setType ?? this.setType,
    restSeconds: restSeconds ?? this.restSeconds,
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
  final String progressionRuleType;
  final double progressionIncrementKg;
  final int progressionRepMin;
  final int progressionRepMax;
  final double progressionTargetRpe;
  final double progressionPercentOneRm;

  /// Optional planning guardrail for repetitions in this workout only.
  /// This is deliberately separate from a progression rule's rep range.
  final int? plannedRepMin;
  final int? plannedRepMax;
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
    this.progressionRuleType = 'manual',
    this.progressionIncrementKg = 2.5,
    this.progressionRepMin = 6,
    this.progressionRepMax = 10,
    this.progressionTargetRpe = 8.5,
    this.progressionPercentOneRm = 75,
    this.plannedRepMin,
    this.plannedRepMax,
    required this.restSeconds,
    required this.comment,
    required this.sets,
  });

  factory WorkoutExercise.fromJson(Map<String, dynamic> j) => WorkoutExercise(
    exerciseId: (j['exercise_id'] as num?)?.toInt() ?? 0,
    name: jsonString(j['name']),
    imageUrl: jsonString(j['image_url']),
    imageUrl2: jsonString(j['image_url2']),
    muscleGroup: jsonString(j['muscle_group']),
    exerciseType: jsonString(j['exercise_type'], 'weight_reps'),
    trainingGroupId: jsonNullableString(j['training_group_id']),
    trainingGroupType: jsonString(j['training_group_type']),
    isOptional: jsonBool(j['is_optional']),
    alternativeGroupId: jsonNullableString(j['alternative_group_id']),
    progressionRuleType: jsonString(
      (j['progression'] as Map?)?['type'],
      'manual',
    ),
    progressionIncrementKg: jsonDouble(
      (j['progression'] as Map?)?['increment_kg'],
      fallback: 2.5,
    ),
    progressionRepMin: jsonInt(
      (j['progression'] as Map?)?['rep_min'],
      fallback: 6,
    ),
    progressionRepMax: jsonInt(
      (j['progression'] as Map?)?['rep_max'],
      fallback: 10,
    ),
    progressionTargetRpe: jsonDouble(
      (j['progression'] as Map?)?['target_rpe'],
      fallback: 8.5,
    ),
    progressionPercentOneRm: jsonDouble(
      (j['progression'] as Map?)?['percent_1rm'],
      fallback: 75,
    ),
    plannedRepMin: j['planned_rep_min'] == null
        ? null
        : jsonInt(j['planned_rep_min'], min: 1, max: 1000),
    plannedRepMax: j['planned_rep_max'] == null
        ? null
        : jsonInt(j['planned_rep_max'], min: 1, max: 1000),
    restSeconds: jsonInt(j['rest_seconds'], fallback: 90, min: 0, max: 86400),
    comment: jsonString(j['comment']),
    sets: jsonObjectList(j['sets'], WorkoutSet.fromJson, maxItems: 100),
  );

  Map<String, dynamic> toJson() => {
    'exercise_id': exerciseId,
    'name': name,
    'image_url': imageUrl,
    'image_url2': imageUrl2,
    'muscle_group': muscleGroup,
    'exercise_type': exerciseType,
    'training_group_id': trainingGroupId,
    'training_group_type': trainingGroupType,
    'is_optional': isOptional,
    'alternative_group_id': alternativeGroupId,
    'progression': {
      'type': progressionRuleType,
      'increment_kg': progressionIncrementKg,
      'rep_min': progressionRepMin,
      'rep_max': progressionRepMax,
      'target_rpe': progressionTargetRpe,
      'percent_1rm': progressionPercentOneRm,
    },
    if (plannedRepMin != null) 'planned_rep_min': plannedRepMin,
    if (plannedRepMax != null) 'planned_rep_max': plannedRepMax,
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
    int? plannedRepMin,
    int? plannedRepMax,
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
    progressionRuleType: progressionRuleType,
    progressionIncrementKg: progressionIncrementKg,
    progressionRepMin: progressionRepMin,
    progressionRepMax: progressionRepMax,
    progressionTargetRpe: progressionTargetRpe,
    progressionPercentOneRm: progressionPercentOneRm,
    plannedRepMin: plannedRepMin ?? this.plannedRepMin,
    plannedRepMax: plannedRepMax ?? this.plannedRepMax,
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'comment': comment,
    'type': type,
    'visibility': visibility,
    'owned': owned,
    'share_code': shareCode,
    'exercise_count': exerciseCount,
    'times_performed': timesPerformed,
    'deload_factor': deloadFactor,
    'exercises': exercises.map((exercise) => exercise.toJson()).toList(),
    'folder_id': folderId,
  };

  factory Workout.fromJson(Map<String, dynamic> j) => Workout(
    id: jsonString(j['id']),
    name: jsonString(j['name']),
    comment: jsonString(j['comment']),
    type: jsonString(j['type'], 'gym'),
    visibility: jsonString(j['visibility'], 'private'),
    owned: jsonBool(j['owned']),
    shareCode: jsonString(j['share_code']),
    exerciseCount: jsonInt(j['exercise_count'], min: 0, max: 75),
    timesPerformed: jsonInt(j['times_performed'], min: 0),
    deloadFactor: jsonDouble(
      j['deload_factor'],
      fallback: 0.70,
      min: 0.1,
      max: 1,
    ),
    exercises: jsonObjectList(
      j['exercises'],
      WorkoutExercise.fromJson,
      maxItems: 75,
    ),
    folderId: jsonNullableString(j['folder_id']),
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
  final String sessionId;
  const WorkoutRunPoint({
    required this.date,
    required this.difficulty,
    this.sessionId = '',
  });

  factory WorkoutRunPoint.fromJson(Map<String, dynamic> j) => WorkoutRunPoint(
    date: (j['date'] as String?) ?? '',
    difficulty: (j['difficulty'] as String?) ?? '',
    sessionId: (j['session_id'] as String?) ?? '',
  );
}

class PerformedSetLog {
  final double weightKg;
  final int reps;
  final String setType;
  final String
  progression; // '' | weight | amplitude | efficiency | meo | dropset
  final double? rpe;
  const PerformedSetLog({
    required this.weightKg,
    required this.reps,
    required this.setType,
    this.progression = '',
    this.rpe,
  });

  factory PerformedSetLog.fromJson(Map<String, dynamic> j) => PerformedSetLog(
    weightKg: (j['weight_kg'] as num?)?.toDouble() ?? 0,
    reps: (j['reps'] as num?)?.toInt() ?? 0,
    setType: (j['set_type'] as String?) ?? 'working',
    progression: (j['progression'] as String?) ?? '',
    rpe: (j['rpe'] as num?)?.toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'weight_kg': weightKg,
    'reps': reps,
    'set_type': setType,
    'progression': progression,
    if (rpe != null) 'rpe': rpe,
  };
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
        sets: jsonObjectList(
          j['sets'],
          PerformedSetLog.fromJson,
          maxItems: 500,
        ),
      );

  Map<String, dynamic> toJson() => {
    'exercise_id': exerciseId,
    'name': name,
    'muscle_group': muscleGroup,
    'sets': sets.map((set) => set.toJson()).toList(growable: false),
  };

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
    date: jsonString(json['date']),
    durationSeconds: jsonInt(json['duration_seconds'], min: 0),
    reps: jsonInt(json['reps'], min: 0),
    volumeKg: jsonDouble(json['volume_kg'], min: 0),
    workingSets: jsonInt(json['working_sets'], min: 0),
    hardSets: jsonInt(json['hard_sets'], min: 0),
    averageRpe: jsonDouble(json['average_rpe'], min: 0, max: 10),
    rpeSets: jsonInt(json['rpe_sets'], min: 0),
    distanceKm: jsonDouble(json['distance_km'], min: 0),
    workouts: jsonInt(json['workouts'], min: 0),
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
    totalWorkouts: jsonInt(j['total_workouts'], min: 0),
    longestWorkoutSeconds: jsonInt(
      j['longest_workout_seconds'],
      min: 0,
      max: 604800,
    ),
    favoriteExercise: jsonString(j['favorite_exercise']),
    strongestExercise: jsonString(j['strongest_exercise']),
    workoutsPerMonth: jsonObjectList(
      j['workouts_per_month'],
      MonthlyCount.fromJson,
      maxItems: 1200,
    ),
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

  static const empty = WorkoutStats(
    timesPerformed: 0,
    potentialVolume: {'easy': 0, 'medium': 0, 'hard': 0},
    history: [],
  );

  factory WorkoutStats.fromJson(Map<String, dynamic> j) {
    final pv = (j['potential_volume'] as Map<String, dynamic>?) ?? const {};
    return WorkoutStats(
      timesPerformed: (j['times_performed'] as num?)?.toInt() ?? 0,
      potentialVolume: {
        'easy': (pv['easy'] as num?)?.toDouble() ?? 0,
        'medium': (pv['medium'] as num?)?.toDouble() ?? 0,
        'hard': (pv['hard'] as num?)?.toDouble() ?? 0,
      },
      history: jsonObjectList(
        j['history'],
        WorkoutRunPoint.fromJson,
        // The server deliberately bounds a portable per-program timeline at
        // 5,000 sessions. Keep the same contract locally so cache hydration
        // never silently drops older sessions that were successfully fetched.
        maxItems: 5000,
      ),
      averageDurationSeconds:
          (j['average_duration_seconds'] as num?)?.toInt() ?? 0,
    );
  }
}

class WorkoutSuggestion {
  final String summary;
  final List<String> highlights;
  final List<String> cautions;
  final List<String> nextFocus;

  const WorkoutSuggestion({
    required this.summary,
    required this.highlights,
    required this.cautions,
    required this.nextFocus,
  });

  factory WorkoutSuggestion.fromJson(Map<String, dynamic> json) =>
      WorkoutSuggestion(
        summary: json['summary'] as String? ?? '',
        highlights: _stringList(json['highlights']),
        cautions: _stringList(json['cautions']),
        nextFocus: _stringList(json['next_focus']),
      );

  static List<String> _stringList(Object? value) =>
      (value as List? ?? const []).whereType<String>().toList();
}
