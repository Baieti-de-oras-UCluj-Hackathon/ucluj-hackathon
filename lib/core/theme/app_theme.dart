import 'package:flutter/material.dart';

import 'color_tokens.dart';
import 'typography_tokens.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get themeData {
    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: ColorTokens.surface,
      canvasColor: ColorTokens.surface,
      splashFactory: NoSplash.splashFactory,
      colorScheme: const ColorScheme.dark(
        primary: ColorTokens.accent,
        onPrimary: ColorTokens.onAccent,
        surface: ColorTokens.surface,
        onSurface: ColorTokens.textPrimary,
        error: ColorTokens.negative,
      ),
      textTheme: base.textTheme.copyWith(
        displayLarge: TypographyTokens.displayHero,
        headlineLarge: TypographyTokens.headline,
        bodyMedium: TypographyTokens.body,
        labelSmall: TypographyTokens.sectionLabel,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: ColorTokens.surface,
        foregroundColor: ColorTokens.textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: const CardThemeData(
        color: ColorTokens.surfaceHigh,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
          side: BorderSide(color: Color(0x22FFFFFF)),
        ),
      ),
    );
  }
}
