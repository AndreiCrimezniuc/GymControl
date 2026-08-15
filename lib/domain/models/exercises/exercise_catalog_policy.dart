import 'package:gymboss/domain/models/exercises/exercise_catalog.dart';

/// Product-owned default catalog.
///
/// The upstream dataset contains hundreds of competition drills, tiny
/// variations and equipment-specific curiosities. Keeping an explicit list
/// makes search useful and prevents an upstream data refresh from silently
/// changing the product. Custom exercises are always retained.
abstract final class ExerciseCatalogPolicy {
  static bool isVisible(ExerciseCatalogItem exercise) {
    if (exercise.category.trim().toLowerCase() == 'custom') return true;
    return _defaults.contains(_normalize(exercise.name));
  }

  static List<ExerciseCatalogItem> curate(
    Iterable<ExerciseCatalogItem> exercises,
  ) => exercises.where(isVisible).toList(growable: false);

  static String _normalize(String value) =>
      value
          .trim()
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

  static final Set<String> _defaults =
      <String>{
        // Chest
        'bench press',
        'barbell bench press medium grip',
        'dumbbell bench press',
        'incline barbell bench press medium grip',
        'incline dumbbell press',
        'decline barbell bench press',
        'dumbbell flyes',
        'incline dumbbell flyes',
        'cable crossover',
        'cable chest press',
        'machine bench press',
        'butterfly',
        'pushups',
        'push up wide',
        'push ups close triceps position',
        'dips triceps version',

        // Back
        'barbell deadlift',
        'romanian deadlift',
        'sumo deadlift',
        'rack pulls',
        'bent over barbell row',
        'bent over two dumbbell row',
        'one arm dumbbell row',
        't bar row with handle',
        'seated cable rows',
        'wide grip lat pulldown',
        'close grip front lat pulldown',
        'straight arm pulldown',
        'pullups',
        'chin up',
        'face pull',
        'hyperextensions with no hyperextension bench',

        // Legs and glutes
        'squat',
        'barbell squat',
        'barbell full squat',
        'front barbell squat',
        'goblet squat',
        'bodyweight squat',
        'hack squat',
        'leg press',
        'leg extensions',
        'lying leg curls',
        'seated leg curl',
        'barbell lunge',
        'dumbbell lunges',
        'dumbbell rear lunge',
        'split squat with dumbbells',
        'barbell walking lunge',
        'barbell step ups',
        'barbell hip thrust',
        'barbell glute bridge',
        'single leg glute bridge',
        'glute kickback',
        'good morning',
        'standing calf raises',
        'seated calf raise',
        'calf press on the leg press machine',
        'thigh abductor',
        'thigh adductor',

        // Shoulders
        'barbell shoulder press',
        'seated barbell military press',
        'standing military press',
        'dumbbell shoulder press',
        'seated dumbbell press',
        'arnold dumbbell press',
        'side lateral raise',
        'front dumbbell raise',
        'reverse flyes',
        'reverse machine flyes',
        'barbell rear delt row',
        'upright barbell row',
        'barbell shrug',
        'dumbbell shrug',
        'external rotation with cable',
        'external rotation with band',

        // Arms
        'barbell curl',
        'ez bar curl',
        'dumbbell bicep curl',
        'dumbbell alternate bicep curl',
        'hammer curls',
        'alternate hammer curl',
        'incline dumbbell curl',
        'concentration curls',
        'preacher curl',
        'cable preacher curl',
        'standing biceps cable curl',
        'close grip barbell bench press',
        'ez bar skullcrusher',
        'lying triceps press',
        'seated triceps press',
        'standing dumbbell triceps extension',
        'dumbbell one arm triceps extension',
        'tricep dumbbell kickback',
        'triceps pushdown',
        'triceps pushdown rope attachment',
        'cable rope overhead triceps extension',
        'bench dips',

        // Core
        'plank',
        'side bridge',
        'crunches',
        'cable crunch',
        'reverse crunch',
        'hanging leg raise',
        'flat bench lying leg raise',
        'dead bug',
        'russian twist',
        'pallof press',
        'ab crunch machine',
        'weighted crunches',
        'sit up',

        // Conditioning and kettlebell staples
        'air bike',
        'fast skipping',
        'wind sprints',
        'kettlebell sumo high pull',
        'one arm kettlebell swings',
        'kettlebell goblet squat',
        'kettlebell one legged deadlift',
        'kettlebell turkish get up squat style',
        'farmers walk',
      }.map(_normalize).toSet();
}
