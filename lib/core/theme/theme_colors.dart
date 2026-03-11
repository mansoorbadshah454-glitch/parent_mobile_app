import 'package:flutter/material.dart';

class ThemeColors {
  // Purple theme colors
  static const Color primaryPurple = Color(0xFF673AB7);
  static const Color deepPurple = Color(0xFF512DA8);
  static const Color darkerPurple = Color(0xFF311B92);
  static const Color lightPurple = Color(0xFFD1C4E9);
  
  static const LinearGradient purpleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      deepPurple,
      primaryPurple,
    ],
  );

  static const Color primaryText = Color(0xFF2E3B55);
  static const Color secondaryText = Color(0xFF757575);
  static const Color surfaceColor = Colors.white;
  static const Color backgroundColor = Color(0xFFF3F2F7);
}
