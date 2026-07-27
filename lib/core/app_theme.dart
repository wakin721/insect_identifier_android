import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  const AppTheme._();

  static const Color defaultSeedColor = Color(0xff386a20);

  static ThemeData light([Color seedColor = defaultSeedColor]) {
    return fromColorScheme(ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    ));
  }

  static ThemeData dark([Color seedColor = defaultSeedColor]) {
    return fromColorScheme(ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    ));
  }

  static ThemeData fromColorScheme(ColorScheme colorScheme) {
    final isDark = colorScheme.brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: colorScheme.brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark
          ? colorScheme.surface
          : colorScheme.surfaceContainerLow,
      appBarTheme: AppBarTheme(
        backgroundColor: isDark
            ? colorScheme.surface
            : colorScheme.surfaceContainerLow,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surfaceContainerHigh,
        indicatorColor: colorScheme.secondaryContainer,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        clipBehavior: Clip.antiAlias,
        color: colorScheme.surfaceContainer,
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
    );
  }
}
