import 'package:flutter_test/flutter_test.dart';
import 'package:gymboss/domain/models/ranking/rank_data.dart';
import 'package:gymboss/ui/menu_options_list/ranking/widgets/ranking.dart';

void main() {
  test('enriched passport entry parses cohort progression', () {
    final rank = ExerciseRank.fromJson({
      'exercise_id': 'bench_press',
      'exercise_name': 'Bench Press',
      'weight_kg': 100,
      'reps': 5,
      'one_rm_kg': 116.7,
      'percentile': 72,
      'rank': 'B',
      'median_score': 8.1,
      'relative_to_median': 1.1,
      'rank_progress': .5,
      'next_rank': 'A',
      'ratio_to_next': .1,
    });
    expect(rank.relativeToMedian, 1.1);
    expect(rank.rankProgress, .5);
    expect(rank.nextRank, 'A');
  });

  test('rank progress is relative to the current tier', () {
    expect(rankProgressForRatio('B', 1.0), 0);
    expect(rankProgressForRatio('B', 1.1), closeTo(.5, .0001));
    expect(rankProgressForRatio('B', 1.2), 1);
    expect(rankProgressForRatio('SS', 2.4), 1);
  });
}
