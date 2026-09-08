import 'package:gymboss/domain/models/json_readers.dart';

class StreakData {
  final int currentStreakWeeks;
  final List<int> activeWeeks;

  const StreakData({
    required this.currentStreakWeeks,
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
      currentStreakWeeks: jsonInt(
        json['current_streak_weeks'],
        min: 0,
        max: 5200,
      ),
      activeWeeks: weeks,
    );
  }

  /// The next visible four-week landmark, expressed as an absolute target.
  /// Showing "12 weeks" for a 9-week streak is unambiguous; "3 weeks" looked
  /// like the current streak had somehow gone backwards.
  int get nextMilestoneWeeks => ((currentStreakWeeks ~/ 4) + 1) * 4;

  static const empty = StreakData(currentStreakWeeks: 0, activeWeeks: []);
}
