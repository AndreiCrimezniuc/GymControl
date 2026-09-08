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
}
