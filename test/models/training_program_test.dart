import 'package:flutter_test/flutter_test.dart';
import 'package:gymboss/domain/models/programs/training_program.dart';
import 'package:gymboss/domain/models/workouts/workout.dart';

Workout routine(String id, String type) => Workout(
  id: id,
  name: id,
  comment: '',
  type: type,
  visibility: 'private',
  owned: true,
  shareCode: '',
  exerciseCount: 0,
  timesPerformed: 0,
  exercises: const [],
);

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

  test('aerobic program schedules only aerobic workouts', () {
    final program = TrainingProgram.progressiveTemplate(
      name: 'Runner',
      goal: 'Base',
      startsOn: DateTime(2026, 9, 14),
      workouts: [routine('strength', 'gym'), routine('run', 'aerobic')],
      sessionsPerWeek: 3,
      kind: 'aerobic',
    );

    expect(program.kind, 'aerobic');
    expect(program.schedule, isNotEmpty);
    expect(program.schedule.every((item) => item.workoutId == 'run'), isTrue);
  });

  test('strength program never schedules aerobic workouts', () {
    final program = TrainingProgram.progressiveTemplate(
      name: 'Build',
      goal: 'Strength',
      startsOn: DateTime(2026, 9, 14),
      workouts: [routine('strength', 'gym'), routine('run', 'aerobic')],
      sessionsPerWeek: 3,
    );

    expect(program.kind, 'gym');
    expect(program.schedule, isNotEmpty);
    expect(
      program.schedule.every((item) => item.workoutId == 'strength'),
      isTrue,
    );
  });
}
