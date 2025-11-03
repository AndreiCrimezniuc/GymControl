import 'package:flutter/material.dart';

class MainGradient {
  static const LinearGradient purpleBlueGradient = LinearGradient(
    colors: [
      Color(0xFF8B5CF6), // фиолетовый (примерно violet-500)
      Color(0xFF3B82F6), // синий (примерно blue-500)
      Color(0xFF06B6D4), // голубой (примерно cyan-500)
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static final BoxShadow blueShadow = BoxShadow(
    color: const Color(0xFF3B82F6).withOpacity(0.4),
    blurRadius: 10,
    offset: const Offset(0, 4),
  );

  static final BoxDecoration purpleBlueButtonBackground = BoxDecoration(
    gradient: purpleBlueGradient,
    boxShadow: [blueShadow],
    borderRadius: BorderRadius.circular(12),
  );
}


