import 'package:gymboss/domain/models/workouts/workout_debrief.dart';

/// A short, explainable coaching conclusion generated on device. It is a
/// decision aid, not medical advice and intentionally has no network or model
/// dependency: finishing a workout must always produce the same report.
enum TrainerReportKind { establish, breakthrough, build, hold, recover }

class TrainerReport {
  final TrainerReportKind kind;
  final int personalRecords;
  final int passportEntries;
  final double? volumeChangePercent;

  const TrainerReport({
    required this.kind,
    required this.personalRecords,
    required this.passportEntries,
    required this.volumeChangePercent,
  });

  factory TrainerReport.fromDebrief(WorkoutDebrief debrief) {
    final change = debrief.volumeChangePercent;
    final kind = debrief.personalRecords > 0
        ? TrainerReportKind.breakthrough
        : change != null && change <= -12
        ? TrainerReportKind.recover
        : change != null && change >= 2
        ? TrainerReportKind.build
        : change == null
        ? TrainerReportKind.establish
        : TrainerReportKind.hold;
    return TrainerReport(
      kind: kind,
      personalRecords: debrief.personalRecords,
      passportEntries: debrief.passportEntries,
      volumeChangePercent: change,
    );
  }
}
