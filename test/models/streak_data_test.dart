import 'package:flutter_test/flutter_test.dart';
import 'package:gymboss/domain/models/streak/streak_data.dart';

void main() {
  test('next streak milestone is an absolute four-week target', () {
    expect(
      const StreakData(
        currentStreakWeeks: 9,
        activeWeeks: [],
      ).nextMilestoneWeeks,
      12,
    );
    expect(
      const StreakData(
        currentStreakWeeks: 12,
        activeWeeks: [],
      ).nextMilestoneWeeks,
      16,
    );
  });

  test('ignores malformed and negative legacy week entries', () {
    final streak = StreakData.fromJson({
      'current_streak_weeks': double.infinity,
      'active_weeks': [1, 'bad', -1, double.nan, 3],
    });

    expect(streak.currentStreakWeeks, 0);
    expect(streak.activeWeeks, [1, 3]);
  });
}
