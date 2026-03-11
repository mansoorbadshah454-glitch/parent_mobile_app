import 'package:flutter/material.dart';

class ThemeColors {
  // Instagram style gradient colors
  static const Color instaPurple = Color(0xFF833AB4);
  static const Color instaRed = Color(0xFFFD1D1D);
  static const Color instaOrange = Color(0xFFF56040);
  static const Color instaYellow = Color(0xFFFCAF45);
  
  static const LinearGradient instagramGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      instaPurple,
      instaRed,
      instaOrange,
      instaYellow,
    ],
  );

  static const Color primaryText = Color(0xFF2E3B55);
  static const Color secondaryText = Color(0xFF757575);
  static const Color surfaceColor = Colors.white;
  static const Color backgroundColor = Color(0xFFF7F9FC); // Very light grey blue
}
