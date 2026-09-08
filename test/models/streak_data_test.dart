import 'package:flutter_test/flutter_test.dart';
import 'package:gymboss/domain/models/streak/streak_data.dart';

void main() {
  test('next streak milestone follows workout-chain landmarks', () {
    expect(
      const StreakData(
        currentStreakWorkouts: 9,
        activeWeeks: [],
      ).nextMilestoneWorkouts,
      15,
    );
    expect(
      const StreakData(
        currentStreakWorkouts: 30,
        activeWeeks: [],
      ).nextMilestoneWorkouts,
      50,
    );
  });

  test('ignores malformed and negative legacy week entries', () {
    final streak = StreakData.fromJson({
      'current_streak_weeks': double.infinity,
      'active_weeks': [1, 'bad', -1, double.nan, 3],
    });

    expect(streak.currentStreakWorkouts, 0);
    expect(streak.activeWeeks, [1, 3]);
  });
}
