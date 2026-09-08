/// Maps only unambiguous catalog movements to Strength Passport benchmarks.
/// Keeping this allow-list deliberately narrow prevents an incline, Smith or
/// dumbbell variation from being compared with a standard barbell lift.
String? passportExerciseIdForName(String exerciseName) {
  final normalized = exerciseName
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[_–—]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ');
  return switch (normalized) {
    'bench press' ||
    'bench press - powerlifting' ||
    'barbell bench press' ||
    'barbell bench press - medium grip' => 'bench_press',
    'squat' ||
    'back squat' ||
    'barbell back squat' ||
    'barbell full squat' => 'squat',
    'deadlift' || 'conventional deadlift' || 'barbell deadlift' => 'deadlift',
    'overhead press' ||
    'barbell overhead press' ||
    'military press' ||
    'standing military press' => 'overhead_press',
    'barbell row' || 'bent over barbell row' => 'barbell_row',
    _ => null,
  };
}
