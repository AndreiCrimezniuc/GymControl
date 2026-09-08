import 'package:flutter_test/flutter_test.dart';
import 'package:gymboss/domain/models/workouts/workout_debrief.dart';

void main() {
  test('debrief compares working volume and detects records', () {
    final debrief = WorkoutDebrief.calculate(
      durationSeconds: 2700,
      sets: const [
        DebriefSetSnapshot(
          exerciseName: 'Bench Press',
          weightKg: 60,
          reps: 10,
          setType: 'warmup',
          countsWeight: true,
          passportBenchmark: true,
        ),
        DebriefSetSnapshot(
          exerciseName: 'Bench Press',
          weightKg: 100,
          reps: 6,
          setType: 'working',
          previousWeightKg: 95,
          previousReps: 6,
          previousBestWeightKg: 97.5,
          countsWeight: true,
          passportBenchmark: true,
        ),
        DebriefSetSnapshot(
          exerciseName: 'Row',
          weightKg: 70,
          reps: 8,
          setType: 'working',
          previousWeightKg: 70,
          previousReps: 8,
          previousBestWeightKg: 75,
          countsWeight: true,
          passportBenchmark: false,
        ),
      ],
    );

    expect(debrief.completedSets, 3);
    expect(debrief.workingSets, 2);
    expect(debrief.volumeKg, 1160);
    expect(debrief.previousVolumeKg, 1130);
    expect(debrief.volumeChangePercent, closeTo(2.6548, .001));
    expect(debrief.personalRecords, 1);
    expect(debrief.passportEntries, 1);
    expect(debrief.strongestExercise, 'Bench Press');
    expect(debrief.strongestEstimateKg, 120);
    expect(debrief.momentum, DebriefMomentum.rising);
  });

  test('debrief has a baseline when no previous sets are available', () {
    final debrief = WorkoutDebrief.calculate(
      durationSeconds: 60,
      sets: const [
        DebriefSetSnapshot(
          exerciseName: 'Squat',
          weightKg: 80,
          reps: 5,
          setType: 'working',
          countsWeight: true,
          passportBenchmark: true,
        ),
      ],
    );

    expect(debrief.previousVolumeKg, isNull);
    expect(debrief.volumeChangePercent, isNull);
    expect(debrief.personalRecords, 1);
    expect(debrief.momentum, DebriefMomentum.baseline);
  });

  test(
    'comparison excludes newly added sets without a matching previous set',
    () {
      final debrief = WorkoutDebrief.calculate(
        durationSeconds: 1800,
        sets: const [
          DebriefSetSnapshot(
            exerciseName: 'Squat',
            weightKg: 100,
            reps: 5,
            setType: 'working',
            previousWeightKg: 100,
            previousReps: 5,
            countsWeight: true,
            passportBenchmark: true,
          ),
          DebriefSetSnapshot(
            exerciseName: 'Squat',
            weightKg: 90,
            reps: 5,
            setType: 'working',
            countsWeight: true,
            passportBenchmark: true,
          ),
        ],
      );

      expect(debrief.volumeKg, 950);
      expect(debrief.previousVolumeKg, 500);
      expect(debrief.volumeChangePercent, 0);
      expect(debrief.momentum, DebriefMomentum.steady);
    },
  );
}
