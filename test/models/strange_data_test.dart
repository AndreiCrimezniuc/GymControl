import 'package:flutter_test/flutter_test.dart';
import 'package:gymboss/domain/models/ranking/rank_data.dart';

void main() {
  test('strength passport remains readable with malformed legacy entries', () {
    final ranks = UserRanks.fromJson({
      'profile': 'invalid',
      'exercise_ranks': [
        null,
        'invalid',
        {
          'exercise_id': 'bench-press',
          'exercise_name': 'Bench Press',
          'weight_kg': double.nan,
          'reps': -20,
          'one_rm_kg': double.infinity,
          'percentile': 250,
          'rank': null,
          'rank_progress': 5,
        },
      ],
      'overall_pct': -12,
    });

    expect(ranks.profile.weightKg, isNull);
    expect(ranks.exerciseRanks, hasLength(1));
    final lift = ranks.exerciseRanks.single;
    expect(lift.exerciseId, 'bench-press');
    expect(lift.weightKg, 0);
    expect(lift.reps, 0);
    expect(lift.oneRmKg, 0);
    expect(lift.percentile, 100);
    expect(lift.rank, 'E');
    expect(lift.rankProgress, 1);
    expect(ranks.overallPct, 0);
  });
}
