import 'dart:math' as math;

import 'package:gymboss/domain/models/workouts/workout.dart';

enum OneRmFormula { epley, brzycki, wathan }

extension OneRmFormulaMath on OneRmFormula {
  String get label => switch (this) {
    OneRmFormula.epley => 'Epley',
    OneRmFormula.brzycki => 'Brzycki',
    OneRmFormula.wathan => 'Wathan',
  };

  double estimate(double weightKg, int reps) {
    if (!weightKg.isFinite || weightKg <= 0 || reps <= 0) return 0;
    if (reps == 1) return weightKg;
    final safeReps = reps.clamp(1, 30);
    return switch (this) {
      OneRmFormula.epley => weightKg * (1 + safeReps / 30),
      OneRmFormula.brzycki => weightKg * 36 / (37 - safeReps),
      OneRmFormula.wathan =>
        100 * weightKg / (48.8 + 53.8 * math.exp(-0.075 * safeReps)),
    };
  }
}

enum ProgressionRuleType {
  none,
  fixedIncrement,
  doubleProgression,
  percentOneRm,
}

class ProgressionRule {
  final ProgressionRuleType type;
  final double incrementKg;
  final int minReps;
  final int maxReps;
  final double percentOneRm;
  final double maxRpeToAdvance;

  const ProgressionRule({
    this.type = ProgressionRuleType.none,
    this.incrementKg = 2.5,
    this.minReps = 6,
    this.maxReps = 10,
    this.percentOneRm = 75,
    this.maxRpeToAdvance = 8.5,
  });

  ProgressionSuggestion suggest({
    required double previousWeightKg,
    required List<int> completedReps,
    List<double?> rpe = const [],
    double estimatedOneRmKg = 0,
    double roundingKg = 0.5,
  }) {
    double round(double value) =>
        roundingKg <= 0 ? value : (value / roundingKg).round() * roundingKg;
    if (type == ProgressionRuleType.percentOneRm && estimatedOneRmKg > 0) {
      return ProgressionSuggestion(
        weightKg: round(estimatedOneRmKg * percentOneRm / 100),
        targetReps: minReps,
        advanced: true,
        reason: 'percent_1rm',
      );
    }
    if (previousWeightKg <= 0 || completedReps.isEmpty) {
      return ProgressionSuggestion(
        weightKg: previousWeightKg,
        targetReps: minReps,
        advanced: false,
        reason: 'not_enough_data',
      );
    }
    final acceptableEffort = rpe.whereType<double>().every(
      (value) => value <= maxRpeToAdvance,
    );
    if (type == ProgressionRuleType.fixedIncrement) {
      return ProgressionSuggestion(
        weightKg: round(previousWeightKg + incrementKg),
        targetReps: completedReps.reduce(math.min),
        advanced: true,
        reason: 'completed',
      );
    }
    if (type == ProgressionRuleType.doubleProgression) {
      final reachedTop = completedReps.every((value) => value >= maxReps);
      if (reachedTop && acceptableEffort) {
        return ProgressionSuggestion(
          weightKg: round(previousWeightKg + incrementKg),
          targetReps: minReps,
          advanced: true,
          reason: 'rep_range_complete',
        );
      }
      return ProgressionSuggestion(
        weightKg: previousWeightKg,
        targetReps: math.min(maxReps, completedReps.reduce(math.min) + 1),
        advanced: false,
        reason: acceptableEffort ? 'add_rep' : 'hold_for_effort',
      );
    }
    return ProgressionSuggestion(
      weightKg: previousWeightKg,
      targetReps: completedReps.reduce(math.min),
      advanced: false,
      reason: 'manual',
    );
  }
}

class ProgressionSuggestion {
  final double weightKg;
  final int targetReps;
  final bool advanced;
  final String reason;

  const ProgressionSuggestion({
    required this.weightKg,
    required this.targetReps,
    required this.advanced,
    required this.reason,
  });
}

enum EnergyMode { full, reduced, minimum }

extension EnergyWorkout on Workout {
  Workout forEnergy(EnergyMode mode) {
    if (mode == EnergyMode.full || type == 'aerobic') return this;
    final required = exercises
        .where((exercise) => !exercise.isOptional)
        .toList();
    final keep = mode == EnergyMode.reduced
        ? required.take(math.max(2, (required.length * .65).ceil())).toList()
        : required.take(2).toList();
    final weightFactor = mode == EnergyMode.reduced ? .9 : .82;
    final setLimit = mode == EnergyMode.reduced ? 3 : 2;
    final adapted = keep.map((exercise) {
      final warmups = exercise.sets
          .where((set) => set.setType == 'warmup')
          .take(1);
      final working = exercise.sets
          .where((set) => set.setType != 'warmup')
          .take(setLimit)
          .map(
            (set) => set.copyWith(
              weightKg: set.weightKg * weightFactor,
              setType: set.setType == 'failure' ? 'working' : set.setType,
            ),
          );
      return exercise.copyWith(sets: [...warmups, ...working]);
    }).toList();
    return copyWith(exercises: adapted);
  }
}

enum LoadMode {
  total,
  perHand,
  bodyweight,
  assisted,
  repsOnly,
  duration,
  distanceDuration,
  weightedDuration,
}

double effectiveLoadKg({
  required LoadMode mode,
  required double enteredKg,
  double bodyweightKg = 0,
}) => switch (mode) {
  LoadMode.perHand => enteredKg * 2,
  LoadMode.bodyweight => bodyweightKg + enteredKg,
  LoadMode.assisted => math.max(0, bodyweightKg - enteredKg),
  LoadMode.repsOnly || LoadMode.duration || LoadMode.distanceDuration => 0,
  _ => enteredKg,
};
