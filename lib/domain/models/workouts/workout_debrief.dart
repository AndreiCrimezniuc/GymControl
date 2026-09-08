enum DebriefMomentum { baseline, rising, steady, easing }

class DebriefSetSnapshot {
  final String exerciseName;
  final double weightKg;
  final int reps;
  final String setType;
  final double? previousWeightKg;
  final int? previousReps;
  final double? previousBestWeightKg;
  final bool countsWeight;
  final bool passportBenchmark;

  const DebriefSetSnapshot({
    required this.exerciseName,
    required this.weightKg,
    required this.reps,
    required this.setType,
    this.previousWeightKg,
    this.previousReps,
    this.previousBestWeightKg,
    required this.countsWeight,
    required this.passportBenchmark,
  });
}

/// A local, deterministic summary calculated before sync. It deliberately uses
/// only completed working data, so the reward screen is instant and remains
/// available when the device is offline.
class WorkoutDebrief {
  final int durationSeconds;
  final int completedSets;
  final int workingSets;
  final double volumeKg;
  final double? previousVolumeKg;
  final double? volumeChangePercent;
  final int personalRecords;
  final int passportEntries;
  final String strongestExercise;
  final double strongestEstimateKg;
  final double strongestWeightKg;
  final int strongestReps;

  const WorkoutDebrief({
    required this.durationSeconds,
    required this.completedSets,
    required this.workingSets,
    required this.volumeKg,
    required this.previousVolumeKg,
    required this.volumeChangePercent,
    required this.personalRecords,
    required this.passportEntries,
    required this.strongestExercise,
    required this.strongestEstimateKg,
    required this.strongestWeightKg,
    required this.strongestReps,
  });

  DebriefMomentum get momentum {
    final change = volumeChangePercent;
    if (change == null) return DebriefMomentum.baseline;
    if (change > 2) return DebriefMomentum.rising;
    if (change < -12) return DebriefMomentum.easing;
    return DebriefMomentum.steady;
  }

  static WorkoutDebrief calculate({
    required Iterable<DebriefSetSnapshot> sets,
    required int durationSeconds,
  }) {
    final completed = sets.toList(growable: false);
    final working = completed
        .where((set) => set.setType != 'warmup')
        .toList(growable: false);
    var volume = 0.0;
    var comparableVolume = 0.0;
    var previousVolume = 0.0;
    var comparableSets = 0;
    var strongestEstimate = 0.0;
    var strongestWeight = 0.0;
    var strongestReps = 0;
    var strongestExercise = '';
    final currentBestByExercise = <String, double>{};
    final previousBestByExercise = <String, double?>{};
    final passportExercises = <String>{};

    for (final set in working) {
      if (set.passportBenchmark) passportExercises.add(set.exerciseName);
      if (!set.countsWeight || set.weightKg <= 0 || set.reps <= 0) continue;
      volume += set.weightKg * set.reps;
      final previousWeight = set.previousWeightKg;
      final previousReps = set.previousReps;
      if (previousWeight != null &&
          previousWeight > 0 &&
          previousReps != null &&
          previousReps > 0) {
        comparableVolume += set.weightKg * set.reps;
        previousVolume += previousWeight * previousReps;
        comparableSets++;
      }
      final estimate = set.weightKg * (1 + set.reps / 30);
      if (estimate > strongestEstimate) {
        strongestEstimate = estimate;
        strongestWeight = set.weightKg;
        strongestReps = set.reps;
        strongestExercise = set.exerciseName;
      }
      final currentBest = currentBestByExercise[set.exerciseName] ?? 0;
      if (set.weightKg > currentBest) {
        currentBestByExercise[set.exerciseName] = set.weightKg;
      }
      previousBestByExercise[set.exerciseName] = set.previousBestWeightKg;
    }

    var records = 0;
    for (final entry in currentBestByExercise.entries) {
      final previous = previousBestByExercise[entry.key];
      if (previous == null || previous <= 0 || entry.value > previous + .01) {
        records++;
      }
    }
    final hasComparison = comparableSets > 0 && previousVolume > 0;
    final change = hasComparison
        ? (comparableVolume - previousVolume) / previousVolume * 100
        : null;

    return WorkoutDebrief(
      durationSeconds: durationSeconds,
      completedSets: completed.length,
      workingSets: working.length,
      volumeKg: volume,
      previousVolumeKg: hasComparison ? previousVolume : null,
      volumeChangePercent: change,
      personalRecords: records,
      passportEntries: passportExercises.length,
      strongestExercise: strongestExercise,
      strongestEstimateKg: strongestEstimate,
      strongestWeightKg: strongestWeight,
      strongestReps: strongestReps,
    );
  }
}
