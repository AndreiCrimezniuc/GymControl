class RankProfile {
  final double? weightKg;
  final double? heightCm;
  final bool dontAskWeight;
  final DateTime updatedAt;

  const RankProfile({
    this.weightKg,
    this.heightCm,
    required this.dontAskWeight,
    required this.updatedAt,
  });

  factory RankProfile.fromJson(Map<String, dynamic> j) => RankProfile(
    weightKg: (j['weight_kg'] as num?)?.toDouble(),
    heightCm: (j['height_cm'] as num?)?.toDouble(),
    dontAskWeight: (j['dont_ask_weight'] as bool?) ?? false,
    updatedAt:
        DateTime.tryParse(j['updated_at'] as String? ?? '') ?? DateTime(2000),
  );

  RankProfile copyWith({
    double? weightKg,
    double? heightCm,
    bool? dontAskWeight,
  }) => RankProfile(
    weightKg: weightKg ?? this.weightKg,
    heightCm: heightCm ?? this.heightCm,
    dontAskWeight: dontAskWeight ?? this.dontAskWeight,
    updatedAt: updatedAt,
  );
}

class ExerciseRank {
  final String exerciseId;
  final String exerciseName;
  final double weightKg;
  final int reps;
  final double oneRmKg;
  final double percentile;
  final String rank;

  const ExerciseRank({
    required this.exerciseId,
    required this.exerciseName,
    required this.weightKg,
    required this.reps,
    required this.oneRmKg,
    required this.percentile,
    required this.rank,
  });

  factory ExerciseRank.fromJson(Map<String, dynamic> j) => ExerciseRank(
    exerciseId: j['exercise_id'] as String,
    exerciseName: j['exercise_name'] as String,
    weightKg: (j['weight_kg'] as num).toDouble(),
    reps: j['reps'] as int,
    oneRmKg: (j['one_rm_kg'] as num).toDouble(),
    percentile: (j['percentile'] as num).toDouble(),
    rank: j['rank'] as String,
  );
}

class UserRanks {
  final RankProfile profile;
  final List<ExerciseRank> exerciseRanks;
  final String? overallRank;
  final double? overallPct;

  const UserRanks({
    required this.profile,
    required this.exerciseRanks,
    this.overallRank,
    this.overallPct,
  });

  factory UserRanks.fromJson(Map<String, dynamic> j) => UserRanks(
    profile: RankProfile.fromJson(j['profile'] as Map<String, dynamic>),
    exerciseRanks:
        (j['exercise_ranks'] as List<dynamic>)
            .map((e) => ExerciseRank.fromJson(e as Map<String, dynamic>))
            .toList(),
    overallRank: j['overall_rank'] as String?,
    overallPct: (j['overall_pct'] as num?)?.toDouble(),
  );

  static UserRanks get empty => UserRanks(
    profile: RankProfile(dontAskWeight: false, updatedAt: DateTime(2000)),
    exerciseRanks: const [],
  );
}
