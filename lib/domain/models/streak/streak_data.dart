class StreakData {
  final int currentStreakWeeks;
  final List<int> activeWeeks;

  const StreakData({
    required this.currentStreakWeeks,
    required this.activeWeeks,
  });

  factory StreakData.fromJson(Map<String, dynamic> json) {
    final rawWeeks = json['active_weeks'];
    final weeks = rawWeeks == null
        ? <int>[]
        : (rawWeeks as List<dynamic>).map((e) => (e as num).toInt()).toList();
    return StreakData(
      currentStreakWeeks: (json['current_streak_weeks'] as num?)?.toInt() ?? 0,
      activeWeeks: weeks,
    );
  }

  /// The next visible four-week landmark, expressed as an absolute target.
  /// Showing "12 weeks" for a 9-week streak is unambiguous; "3 weeks" looked
  /// like the current streak had somehow gone backwards.
  int get nextMilestoneWeeks => ((currentStreakWeeks ~/ 4) + 1) * 4;

  static const empty = StreakData(currentStreakWeeks: 0, activeWeeks: []);
}
