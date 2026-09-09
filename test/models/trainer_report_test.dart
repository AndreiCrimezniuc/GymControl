import 'package:flutter_test/flutter_test.dart';
import 'package:gymboss/domain/models/insights/trainer_report.dart';
import 'package:gymboss/domain/models/workouts/workout_debrief.dart';

WorkoutDebrief debrief({int records = 0, double? change}) => WorkoutDebrief(
  durationSeconds: 3600,
  completedSets: 12,
  workingSets: 10,
  volumeKg: 1000,
  previousVolumeKg: change == null ? null : 1000,
  volumeChangePercent: change,
  personalRecords: records,
  passportEntries: 0,
  strongestExercise: 'Bench Press',
  strongestEstimateKg: 100,
  strongestWeightKg: 80,
  strongestReps: 8,
);

void main() {
  test('a personal record takes priority over volume signals', () {
    expect(
      TrainerReport.fromDebrief(debrief(records: 1, change: -20)).kind,
      TrainerReportKind.breakthrough,
    );
  });

  test('large output drop recommends recovery', () {
    expect(
      TrainerReport.fromDebrief(debrief(change: -12)).kind,
      TrainerReportKind.recover,
    );
  });

  test('new history establishes a baseline without inventing a trend', () {
    expect(
      TrainerReport.fromDebrief(debrief()).kind,
      TrainerReportKind.establish,
    );
  });
}
