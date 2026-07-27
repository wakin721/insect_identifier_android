import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static const Color defaultSeedColor = Color(0xff386a20);

  static ThemeData light([Color seedColor = defaultSeedColor]) {
    return fromColorScheme(
      ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.light,
      ),
    );
  }

  static ThemeData dark([Color seedColor = defaultSeedColor]) {
    return fromColorScheme(
      ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.dark,
      ),
    );
  }

  static ThemeData fromColorScheme(ColorScheme colorScheme) {
    return ThemeData(
      useMaterial3: true,
      brightness: colorScheme.brightness,
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
      cardTheme: CardThemeData(
        clipBehavior: Clip.antiAlias,
        color: colorScheme.surfaceContainerLow,
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
    );
  }
}
