import 'package:uuid/uuid.dart';

import 'package:gymboss/domain/models/json_readers.dart';
import 'package:gymboss/domain/models/workouts/workout.dart';

class TrainingPhase {
  final String id;
  final String name;
  final int position;
  final int weeks;
  final double intensity;

  const TrainingPhase({
    required this.id,
    required this.name,
    required this.position,
    required this.weeks,
    required this.intensity,
  });

  factory TrainingPhase.fromJson(Map<String, dynamic> json) => TrainingPhase(
    id: jsonString(json['id']),
    name: jsonString(json['name']),
    position: jsonInt(json['position'], min: 0, max: 100),
    weeks: jsonInt(json['weeks'], fallback: 1, min: 1, max: 52),
    intensity: jsonDouble(json['intensity'], fallback: 1, min: .3, max: 1.2),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'position': position,
    'weeks': weeks,
    'intensity': intensity,
  };
}

class ScheduledWorkout {
  final String id;
  final String? phaseId;
  final String workoutId;
  final String workoutName;
  final String plannedOn;
  final String status;
  final String? sessionId;
  final String note;

  const ScheduledWorkout({
    required this.id,
    required this.phaseId,
    required this.workoutId,
    required this.workoutName,
    required this.plannedOn,
    this.status = 'planned',
    this.sessionId,
    this.note = '',
  });

  DateTime? get date => DateTime.tryParse(plannedOn);

  factory ScheduledWorkout.fromJson(Map<String, dynamic> json) =>
      ScheduledWorkout(
        id: jsonString(json['id']),
        phaseId: jsonNullableString(json['phase_id']),
        workoutId: jsonString(json['workout_id']),
        workoutName: jsonString(json['workout_name']),
        plannedOn: jsonString(json['planned_on']),
        status: jsonString(json['status'], 'planned'),
        sessionId: jsonNullableString(json['session_id']),
        note: jsonString(json['note']),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'phase_id': phaseId,
    'workout_id': workoutId,
    'workout_name': workoutName,
    'planned_on': plannedOn,
    'status': status,
    'session_id': sessionId,
    'note': note,
  };
}

class TrainingProgram {
  static const _uuid = Uuid();
  final String id;
  final String name;
  final String goal;
  final String? startsOn;
  final String status;
  final List<TrainingPhase> phases;
  final List<ScheduledWorkout> schedule;

  const TrainingProgram({
    required this.id,
    required this.name,
    required this.goal,
    required this.startsOn,
    required this.status,
    required this.phases,
    required this.schedule,
  });

  factory TrainingProgram.fromJson(Map<String, dynamic> json) =>
      TrainingProgram(
        id: jsonString(json['id']),
        name: jsonString(json['name']),
        goal: jsonString(json['goal']),
        startsOn: jsonNullableString(json['starts_on']),
        status: jsonString(json['status'], 'draft'),
        phases: jsonObjectList(
          json['phases'],
          TrainingPhase.fromJson,
          maxItems: 20,
        ),
        schedule: jsonObjectList(
          json['schedule'],
          ScheduledWorkout.fromJson,
          maxItems: 1000,
        ),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'goal': goal,
    'starts_on': startsOn,
    'status': status,
    'phases': phases.map((phase) => phase.toJson()).toList(),
    'schedule': schedule.map((item) => item.toJson()).toList(),
  };

  int get totalWeeks => phases.fold(0, (sum, phase) => sum + phase.weeks);

  ScheduledWorkout? nextWorkout(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    ScheduledWorkout? next;
    for (final item in schedule) {
      final date = item.date;
      if (item.status == 'planned' && date != null && !date.isBefore(today)) {
        final nextDate = next?.date;
        if (nextDate == null || date.isBefore(nextDate)) next = item;
      }
    }
    return next;
  }

  static TrainingProgram progressiveTemplate({
    required String name,
    required String goal,
    required DateTime startsOn,
    required List<Workout> workouts,
    required int sessionsPerWeek,
  }) {
    final id = _uuid.v4();
    final phases = <TrainingPhase>[
      TrainingPhase(
        id: _uuid.v4(),
        name: 'Foundation',
        position: 0,
        weeks: 4,
        intensity: .75,
      ),
      TrainingPhase(
        id: _uuid.v4(),
        name: 'Build',
        position: 1,
        weeks: 4,
        intensity: .9,
      ),
      TrainingPhase(
        id: _uuid.v4(),
        name: 'Realization',
        position: 2,
        weeks: 2,
        intensity: 1,
      ),
      TrainingPhase(
        id: _uuid.v4(),
        name: 'Deload',
        position: 3,
        weeks: 1,
        intensity: .7,
      ),
    ];
    final selected = workouts
        .where((workout) => workout.type != 'aerobic')
        .toList();
    final schedule = <ScheduledWorkout>[];
    var phaseOffset = 0;
    var workoutIndex = 0;
    final frequency = sessionsPerWeek.clamp(2, 7);
    for (final phase in phases) {
      for (var week = 0; week < phase.weeks; week++) {
        for (var session = 0; session < frequency; session++) {
          if (selected.isEmpty) break;
          final dayInWeek = (session * 7 / frequency).round().clamp(0, 6);
          final workout = selected[workoutIndex++ % selected.length];
          final date = startsOn.add(
            Duration(days: (phaseOffset + week) * 7 + dayInWeek),
          );
          schedule.add(
            ScheduledWorkout(
              id: _uuid.v4(),
              phaseId: phase.id,
              workoutId: workout.id,
              workoutName: workout.name,
              plannedOn: _date(date),
            ),
          );
        }
      }
      phaseOffset += phase.weeks;
    }
    return TrainingProgram(
      id: id,
      name: name.trim(),
      goal: goal.trim(),
      startsOn: _date(startsOn),
      status: 'active',
      phases: phases,
      schedule: schedule,
    );
  }

  static String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}
