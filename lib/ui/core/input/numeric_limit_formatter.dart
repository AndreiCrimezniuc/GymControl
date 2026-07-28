import 'package:flutter/services.dart';

const double maxWorkoutNumericValue = 999;

double clampWorkoutDecimal(String value) =>
    (double.tryParse(value.trim().replaceAll(',', '.')) ?? 0).clamp(
      0,
      maxWorkoutNumericValue,
    );

int clampWorkoutInteger(String value, {int minimum = 0}) =>
    (int.tryParse(value.trim()) ?? minimum).clamp(
      minimum,
      maxWorkoutNumericValue.toInt(),
    );

class NumericLimitFormatter extends TextInputFormatter {
  final bool allowDecimal;

  const NumericLimitFormatter({this.allowDecimal = false});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;
    final pattern = allowDecimal
        ? RegExp(r'^\d{0,3}(?:[.,]\d*)?$')
        : RegExp(r'^\d{0,3}$');
    if (!pattern.hasMatch(text)) return oldValue;
    final parsed = double.tryParse(text.replaceAll(',', '.'));
    return parsed == null || parsed <= maxWorkoutNumericValue
        ? newValue
        : oldValue;
  }
}
