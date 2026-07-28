import 'package:flutter_test/flutter_test.dart';
import 'package:gymboss/ui/core/input/numeric_limit_formatter.dart';

void main() {
  test('workout values are clamped at the persistence boundary', () {
    expect(clampWorkoutInteger('1000000', minimum: 1), 999);
    expect(clampWorkoutInteger('-4', minimum: 1), 1);
    expect(clampWorkoutDecimal('999.5'), 999);
  });

  test('integer formatter rejects a fourth digit', () {
    const formatter = NumericLimitFormatter();
    const oldValue = TextEditingValue(text: '999');
    const newValue = TextEditingValue(text: '9999');
    expect(formatter.formatEditUpdate(oldValue, newValue), oldValue);
  });

  test('decimal formatter accepts a value within the limit', () {
    const formatter = NumericLimitFormatter(allowDecimal: true);
    const oldValue = TextEditingValue(text: '99');
    const newValue = TextEditingValue(text: '99.5');
    expect(formatter.formatEditUpdate(oldValue, newValue), newValue);
  });
}
