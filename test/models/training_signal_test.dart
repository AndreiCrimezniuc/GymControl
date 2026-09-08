import 'package:flutter_test/flutter_test.dart';
import 'package:gymboss/domain/models/insights/training_signal.dart';

void main() {
  test('signal trail distinguishes growth and a recent plateau', () {
    final rising = SignalTrailInsight.analyze([80, 85, 91]);
    expect(rising.trend, SignalTrend.rising);
    expect(rising.changePercent, closeTo(13.75, .001));
    expect(rising.plateau, isFalse);

    final plateau = SignalTrailInsight.analyze([80, 100, 101, 100]);
    expect(plateau.trend, SignalTrend.stable);
    expect(plateau.plateau, isTrue);
    expect(plateau.peak, 101);
  });

  test('recovery orbit is derived only from recent training rhythm', () {
    final now = DateTime(2026, 9, 8);
    final insight = RecoveryOrbitInsight.analyze(
      now: now,
      days: [
        TrainingDaySignal(
          date: now.subtract(const Duration(days: 8)),
          workouts: 1,
          volume: 1000,
        ),
        TrainingDaySignal(
          date: now.subtract(const Duration(days: 1)),
          workouts: 1,
          volume: 1500,
        ),
      ],
    );

    expect(insight.status, OrbitStatus.recovery);
    expect(insight.activeDays, 2);
    expect(insight.daysSinceTraining, 1);
  });

  test('recovery orbit stays empty before the first workout', () {
    final insight = RecoveryOrbitInsight.analyze(
      now: DateTime(2026, 9, 8),
      days: const [],
    );
    expect(insight.status, OrbitStatus.baseline);
    expect(insight.daysSinceTraining, isNull);
  });
}
