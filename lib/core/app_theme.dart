import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light([Color seedColor = const Color(0xff386a20)]) =>
      _build(Brightness.light, seedColor);

  static ThemeData dark([Color seedColor = const Color(0xff386a20)]) =>
      _build(Brightness.dark, seedColor);

  static ThemeData _build(Brightness brightness, Color seedColor) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surfaceContainer,
        indicatorColor: colorScheme.secondaryContainer,
      ),
    );
  }
}
