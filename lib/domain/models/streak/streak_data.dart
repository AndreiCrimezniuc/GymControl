import 'package:gymboss/domain/models/json_readers.dart';

class StreakData {
  final int currentStreakWorkouts;
  final int longestStreakWorkouts;
  final int daysUntilBreak;
  final String? lastWorkoutDate;
  final List<String> activeDates;
  final List<int> activeWeeks;

  const StreakData({
    required this.currentStreakWorkouts,
    this.longestStreakWorkouts = 0,
    this.daysUntilBreak = 0,
    this.lastWorkoutDate,
    this.activeDates = const [],
    required this.activeWeeks,
  });

  factory StreakData.fromJson(Map<String, dynamic> json) {
    final rawWeeks = json['active_weeks'];
    final weeks = rawWeeks is List
        ? rawWeeks
              .whereType<num>()
              .where((value) => value.toDouble().isFinite)
              .map((value) => value.toInt())
              .where((value) => value >= 0)
              .take(5200)
              .toList()
        : <int>[];
    return StreakData(
      currentStreakWorkouts: jsonInt(
        json['current_streak_workouts'] ?? json['current_streak_weeks'],
        min: 0,
        max: 100000,
      ),
      longestStreakWorkouts: jsonInt(
        json['longest_streak_workouts'],
        min: 0,
        max: 100000,
      ),
      daysUntilBreak: jsonInt(json['days_until_break'], min: 0, max: 7),
      lastWorkoutDate: jsonNullableString(json['last_workout_date']),
      activeDates: jsonStringList(json['active_dates'], maxItems: 366),
      activeWeeks: weeks,
    );
  }

  int get nextMilestoneWorkouts {
    for (final target in const [3, 7, 15, 30, 50, 100]) {
      if (currentStreakWorkouts < target) return target;
    }
    return ((currentStreakWorkouts ~/ 100) + 1) * 100;
  }

  static const empty = StreakData(currentStreakWorkouts: 0, activeWeeks: []);
}
