enum SignalTrend { baseline, rising, stable, easing }

class SignalTrailInsight {
  final SignalTrend trend;
  final double? changePercent;
  final bool plateau;
  final double current;
  final double peak;

  const SignalTrailInsight({
    required this.trend,
    required this.changePercent,
    required this.plateau,
    required this.current,
    required this.peak,
  });

  factory SignalTrailInsight.analyze(Iterable<double> source) {
    final values = source.where((value) => value.isFinite).toList();
    if (values.isEmpty) {
      return const SignalTrailInsight(
        trend: SignalTrend.baseline,
        changePercent: null,
        plateau: false,
        current: 0,
        peak: 0,
      );
    }
    final current = values.last;
    final peak = values.reduce((a, b) => a > b ? a : b);
    if (values.length < 2 || values.first.abs() < .001) {
      return SignalTrailInsight(
        trend: SignalTrend.baseline,
        changePercent: null,
        plateau: false,
        current: current,
        peak: peak,
      );
    }
    final recent = values.length > 3
        ? values.sublist(values.length - 3)
        : values;
    final recentMin = recent.reduce((a, b) => a < b ? a : b);
    final recentMax = recent.reduce((a, b) => a > b ? a : b);
    final recentAverage = recent.reduce((a, b) => a + b) / recent.length;
    final plateau =
        recent.length >= 3 &&
        recentAverage.abs() > .001 &&
        (recentMax - recentMin) / recentAverage.abs() <= .025;
    final change = (current - values.first) / values.first.abs() * 100;
    final trend = plateau
        ? SignalTrend.stable
        : change > 2
        ? SignalTrend.rising
        : change < -5
        ? SignalTrend.easing
        : SignalTrend.stable;
    return SignalTrailInsight(
      trend: trend,
      changePercent: change,
      plateau: plateau,
      current: current,
      peak: peak,
    );
  }
}

enum OrbitStatus { baseline, recovery, ready, balanced, returning }

class TrainingDaySignal {
  final DateTime date;
  final int workouts;
  final double volume;

  const TrainingDaySignal({
    required this.date,
    required this.workouts,
    required this.volume,
  });
}

class RecoveryOrbitInsight {
  final OrbitStatus status;
  final int activeDays;
  final int? daysSinceTraining;
  final double currentLoad;
  final double previousLoad;

  const RecoveryOrbitInsight({
    required this.status,
    required this.activeDays,
    required this.daysSinceTraining,
    required this.currentLoad,
    required this.previousLoad,
  });

  factory RecoveryOrbitInsight.analyze({
    required Iterable<TrainingDaySignal> days,
    required DateTime now,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    final normalized = days
        .where((day) => day.workouts > 0)
        .map(
          (day) => TrainingDaySignal(
            date: DateTime(day.date.year, day.date.month, day.date.day),
            workouts: day.workouts,
            volume: day.volume,
          ),
        )
        .where((day) => !day.date.isAfter(today))
        .toList();
    if (normalized.isEmpty) {
      return const RecoveryOrbitInsight(
        status: OrbitStatus.baseline,
        activeDays: 0,
        daysSinceTraining: null,
        currentLoad: 0,
        previousLoad: 0,
      );
    }
    normalized.sort((a, b) => a.date.compareTo(b.date));
    final last = normalized.last.date;
    final gap = today.difference(last).inDays;
    final currentStart = today.subtract(const Duration(days: 6));
    final previousStart = currentStart.subtract(const Duration(days: 7));
    var currentLoad = 0.0;
    var previousLoad = 0.0;
    final activeDates = <DateTime>{};
    for (final day in normalized) {
      if (!day.date.isBefore(currentStart)) {
        currentLoad += day.volume;
      } else if (!day.date.isBefore(previousStart)) {
        previousLoad += day.volume;
      }
      if (today.difference(day.date).inDays < 14) activeDates.add(day.date);
    }
    final status = gap >= 5
        ? OrbitStatus.returning
        : gap >= 3
        ? OrbitStatus.balanced
        : previousLoad > 0 && currentLoad > previousLoad * 1.25
        ? OrbitStatus.recovery
        : gap <= 1
        ? OrbitStatus.ready
        : OrbitStatus.balanced;
    return RecoveryOrbitInsight(
      status: status,
      activeDays: activeDates.length,
      daysSinceTraining: gap,
      currentLoad: currentLoad,
      previousLoad: previousLoad,
    );
  }
}
