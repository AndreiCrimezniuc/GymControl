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

  static const empty = StreakData(currentStreakWeeks: 0, activeWeeks: []);
}
