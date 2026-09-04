import 'package:flutter/material.dart';

/// Colors taken from the approved Bahantabay mockups.
abstract final class AppColors {
  static const floodBlue = Color(0xFF1B4F72);
  static const scaffoldBackground = Color(0xFFF4F6FB);
  static const mapSurface = Color(0xFFE6F1FB);
  static const warning = Color(0xFFE8A33D);
  static const floodRed = Color(0xFFD64545);

  static const ink = Color(0xFF1B2340);
  static const mutedText = Color(0xFF555555);
  static const surface = Colors.white;
  static const errorText = Color(0xFFC23C3C);

  static const safeBackground = floodBlue;
  static const safeForeground = surface;
  static const warningBackground = warning;
  static const warningForeground = ink;
  static const notPassableBackground = floodRed;
  static const notPassableForeground = surface;
}
