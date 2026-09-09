import 'package:flutter_test/flutter_test.dart';
import 'package:gymboss/domain/models/programs/training_program.dart';

void main() {
  test('next workout is chronological even when server data is unordered', () {
    const program = TrainingProgram(
      id: 'program',
      name: 'Build',
      goal: 'Strength',
      startsOn: '2026-09-01',
      status: 'active',
      phases: [],
      schedule: [
        ScheduledWorkout(
          id: 'later',
          phaseId: null,
          workoutId: 'two',
          workoutName: 'Later',
          plannedOn: '2026-09-12',
        ),
        ScheduledWorkout(
          id: 'past',
          phaseId: null,
          workoutId: 'zero',
          workoutName: 'Past',
          plannedOn: '2026-09-08',
        ),
        ScheduledWorkout(
          id: 'next',
          phaseId: null,
          workoutId: 'one',
          workoutName: 'Next',
          plannedOn: '2026-09-10',
        ),
      ],
    );

    expect(program.nextWorkout(DateTime(2026, 9, 9))?.id, 'next');
  });
}
