import 'package:flutter_test/flutter_test.dart';
import 'package:gymboss/ui/menu_options_list/exercises/widgets/exercises.dart';

void main() {
  test('exercise mastery grows predictably from completed working sets', () {
    expect(exerciseMasteryLevel(0), 1);
    expect(exerciseMasteryLevel(8), 3);
    expect(exerciseMasteryLevel(9), 4);
    expect(exerciseMasteryProgress(5), closeTo(.2, .0001));
  });
}
