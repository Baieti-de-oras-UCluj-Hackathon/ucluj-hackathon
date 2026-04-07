import 'package:flutter/material.dart';

import 'color_tokens.dart';

class TypographyTokens {
  const TypographyTokens._();

  static const TextStyle displayHero = TextStyle(
    fontSize: 52,
    height: 1.0,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.5,
    color: ColorTokens.textPrimary,
  );

  static const TextStyle headline = TextStyle(
    fontSize: 34,
    height: 1.0,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.8,
    color: ColorTokens.textPrimary,
  );

  static const TextStyle sectionLabel = TextStyle(
    fontSize: 11,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.8,
    color: ColorTokens.textMuted,
  );

  static const TextStyle body = TextStyle(
    fontSize: 15,
    height: 1.45,
    fontWeight: FontWeight.w400,
    color: ColorTokens.textPrimary,
  );

  static const TextStyle navLabel = TextStyle(
    fontSize: 10,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.4,
  );
}
