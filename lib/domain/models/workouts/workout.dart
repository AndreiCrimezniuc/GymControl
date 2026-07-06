const workoutDifficulties = ['easy', 'medium', 'hard'];

class WorkoutSet {
  final String difficulty; // easy | medium | hard
  final double weightKg;
  final int reps;

  const WorkoutSet({required this.difficulty, required this.weightKg, required this.reps});

  factory WorkoutSet.fromJson(Map<String, dynamic> j) => WorkoutSet(
        difficulty: (j['difficulty'] as String?) ?? 'medium',
        weightKg: (j['weight_kg'] as num?)?.toDouble() ?? 0,
        reps: (j['reps'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {'difficulty': difficulty, 'weight_kg': weightKg, 'reps': reps};

  WorkoutSet copyWith({String? difficulty, double? weightKg, int? reps}) => WorkoutSet(
        difficulty: difficulty ?? this.difficulty,
        weightKg: weightKg ?? this.weightKg,
        reps: reps ?? this.reps,
      );
}

class WorkoutExercise {
  final int exerciseId;
  final String name;
  final String imageUrl;
  final String muscleGroup;
  final int restSeconds;
  final String comment;
  final List<WorkoutSet> sets;

  const WorkoutExercise({
    required this.exerciseId,
    required this.name,
    required this.imageUrl,
    required this.muscleGroup,
    required this.restSeconds,
    required this.comment,
    required this.sets,
  });

  factory WorkoutExercise.fromJson(Map<String, dynamic> j) => WorkoutExercise(
        exerciseId: (j['exercise_id'] as num?)?.toInt() ?? 0,
        name: (j['name'] as String?) ?? '',
        imageUrl: (j['image_url'] as String?) ?? '',
        muscleGroup: (j['muscle_group'] as String?) ?? '',
        restSeconds: (j['rest_seconds'] as num?)?.toInt() ?? 90,
        comment: (j['comment'] as String?) ?? '',
        sets: ((j['sets'] as List?) ?? [])
            .map((e) => WorkoutSet.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'exercise_id': exerciseId,
        'rest_seconds': restSeconds,
        'comment': comment,
        'sets': sets.map((s) => s.toJson()).toList(),
      };

  List<WorkoutSet> setsFor(String difficulty) =>
      sets.where((s) => s.difficulty == difficulty).toList();

  WorkoutExercise copyWith({int? restSeconds, String? comment, List<WorkoutSet>? sets}) => WorkoutExercise(
        exerciseId: exerciseId,
        name: name,
        imageUrl: imageUrl,
        muscleGroup: muscleGroup,
        restSeconds: restSeconds ?? this.restSeconds,
        comment: comment ?? this.comment,
        sets: sets ?? this.sets,
      );
}

class Workout {
  final String id;
  final String name;
  final String comment;
  final String visibility; // private | public
  final bool owned;
  final String shareCode;
  final int exerciseCount;
  final int timesPerformed;
  final double loveCoefficient; // 0..1
  final List<WorkoutExercise> exercises;

  const Workout({
    required this.id,
    required this.name,
    required this.comment,
    required this.visibility,
    required this.owned,
    required this.shareCode,
    required this.exerciseCount,
    required this.timesPerformed,
    required this.loveCoefficient,
    required this.exercises,
  });

  bool get isPublic => visibility == 'public';
  int get loveScore => (loveCoefficient * 10).round().clamp(0, 10);

  factory Workout.fromJson(Map<String, dynamic> j) => Workout(
        id: (j['id'] as String?) ?? '',
        name: (j['name'] as String?) ?? '',
        comment: (j['comment'] as String?) ?? '',
        visibility: (j['visibility'] as String?) ?? 'private',
        owned: (j['owned'] as bool?) ?? false,
        shareCode: (j['share_code'] as String?) ?? '',
        exerciseCount: (j['exercise_count'] as num?)?.toInt() ?? 0,
        timesPerformed: (j['times_performed'] as num?)?.toInt() ?? 0,
        loveCoefficient: (j['love_coefficient'] as num?)?.toDouble() ?? 0,
        exercises: ((j['exercises'] as List?) ?? [])
            .map((e) => WorkoutExercise.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  /// Distinct muscle groups across the workout's exercises, for card chips.
  List<String> get muscleGroups {
    final seen = <String>{};
    final out = <String>[];
    for (final e in exercises) {
      if (e.muscleGroup.isNotEmpty && seen.add(e.muscleGroup)) out.add(e.muscleGroup);
    }
    return out;
  }
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

class WorkoutStats {
  final int timesPerformed;
  final double loveCoefficient;
  final Map<String, double> potentialVolume; // difficulty -> tonnage
  final List<WorkoutRunPoint> history;

  const WorkoutStats({
    required this.timesPerformed,
    required this.loveCoefficient,
    required this.potentialVolume,
    required this.history,
  });

  int get loveScore => (loveCoefficient * 10).round().clamp(0, 10);

  factory WorkoutStats.fromJson(Map<String, dynamic> j) {
    final pv = (j['potential_volume'] as Map<String, dynamic>?) ?? const {};
    return WorkoutStats(
      timesPerformed: (j['times_performed'] as num?)?.toInt() ?? 0,
      loveCoefficient: (j['love_coefficient'] as num?)?.toDouble() ?? 0,
      potentialVolume: {
        'easy': (pv['easy'] as num?)?.toDouble() ?? 0,
        'medium': (pv['medium'] as num?)?.toDouble() ?? 0,
        'hard': (pv['hard'] as num?)?.toDouble() ?? 0,
      },
      history: ((j['history'] as List?) ?? [])
          .map((e) => WorkoutRunPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
