import 'package:flutter/material.dart';

/// U Cluj (Universitatea Cluj) color palette
/// Official club colors: black, white, and golden yellow
class ColorTokens {
  const ColorTokens._();

  // Background surfaces – deep charcoal/black (U Cluj's dark identity)
  static const Color surface = Color(0xFF0A0A0A);
  static const Color surfaceLow = Color(0xFF141414);
  static const Color surfaceHigh = Color(0xFF1E1E1E);

  // Accent – U Cluj golden yellow (#F5C518 → slightly warmer)
  static const Color accent = Color(0xFFF5C518);
  static const Color accentStrong = Color(0xFFD4A800);
  static const Color onAccent = Color(0xFF0A0A0A);

  // Secondary accent – U Cluj blue (used in badge details)
  static const Color accentBlue = Color(0xFF003DA5);

  // Text – pure white and grey
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF9A9A9A);
  static const Color divider = Color(0x33FFFFFF);

  static const Color negative = Color(0xFFFF5252);
  static const Color positive = Color(0xFF69F0AE);
}
