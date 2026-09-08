import 'package:gymboss/domain/models/json_readers.dart';

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
    weightKg: j['weight_kg'] == null
        ? null
        : jsonDouble(j['weight_kg'], min: 0, max: 1000),
    heightCm: j['height_cm'] == null
        ? null
        : jsonDouble(j['height_cm'], min: 0, max: 300),
    dontAskWeight: jsonBool(j['dont_ask_weight']),
    updatedAt: DateTime.tryParse(jsonString(j['updated_at'])) ?? DateTime(2000),
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
  final double medianScore;
  final double relativeToMedian;
  final double rankProgress;
  final String? nextRank;
  final double ratioToNext;

  const ExerciseRank({
    required this.exerciseId,
    required this.exerciseName,
    required this.weightKg,
    required this.reps,
    required this.oneRmKg,
    required this.percentile,
    required this.rank,
    this.medianScore = 0,
    this.relativeToMedian = 0,
    this.rankProgress = 0,
    this.nextRank,
    this.ratioToNext = 0,
  });

  factory ExerciseRank.fromJson(Map<String, dynamic> j) {
    final exerciseId = jsonString(j['exercise_id']);
    final exerciseName = jsonString(j['exercise_name']);
    if (exerciseId.isEmpty || exerciseName.isEmpty) {
      throw const FormatException('rank identity is missing');
    }
    return ExerciseRank(
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      weightKg: jsonDouble(j['weight_kg'], min: 0, max: 2000),
      reps: jsonInt(j['reps'], min: 0, max: 1000),
      oneRmKg: jsonDouble(j['one_rm_kg'], min: 0, max: 3000),
      percentile: jsonDouble(j['percentile'], min: 0, max: 100),
      rank: jsonString(j['rank'], 'E'),
      medianScore: jsonDouble(j['median_score'], min: 0),
      relativeToMedian: jsonDouble(j['relative_to_median'], min: 0, max: 100),
      rankProgress: jsonDouble(j['rank_progress'], min: 0, max: 1),
      nextRank: jsonNullableString(j['next_rank']),
      ratioToNext: jsonDouble(j['ratio_to_next'], min: 0, max: 100),
    );
  }
}

class UserRanks {
  final RankProfile profile;
  final List<ExerciseRank> exerciseRanks;
  final String? overallRank;
  final double? overallPct;
  final double? overallRatio;

  const UserRanks({
    required this.profile,
    required this.exerciseRanks,
    this.overallRank,
    this.overallPct,
    this.overallRatio,
  });

  factory UserRanks.fromJson(Map<String, dynamic> j) {
    final profile = jsonMap(j['profile']);
    return UserRanks(
      profile: RankProfile.fromJson(profile ?? const {}),
      exerciseRanks: jsonObjectList(j['exercise_ranks'], ExerciseRank.fromJson),
      overallRank: j['overall_rank'] is String
          ? j['overall_rank'] as String
          : null,
      overallPct: j['overall_pct'] == null
          ? null
          : jsonDouble(j['overall_pct'], min: 0, max: 100),
      overallRatio: j['overall_ratio'] == null
          ? null
          : jsonDouble(j['overall_ratio'], min: 0, max: 100),
    );
  }

  static UserRanks get empty => UserRanks(
    profile: RankProfile(dontAskWeight: false, updatedAt: DateTime(2000)),
    exerciseRanks: const [],
  );
}
