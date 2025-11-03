import 'package:flutter/material.dart';

Widget bulletPoint(int index) {
  return Container(
    width: 24,
    height: 24,
    decoration: const BoxDecoration(
      color: Colors.blue,
      shape: BoxShape.circle,
    ),
    alignment: Alignment.center,
    child: Text(
      "${index + 1}",
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
    ),
  );
}

