import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  const AppTheme._();

  static const Color defaultSeedColor = Color(0xff984061);

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
          : colorScheme.surfaceContainerLowest,
      appBarTheme: AppBarTheme(
        backgroundColor: isDark
            ? colorScheme.surface
            : colorScheme.surfaceContainerLowest,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        indicatorColor: colorScheme.secondaryContainer,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        clipBehavior: Clip.antiAlias,
        color: colorScheme.surfaceContainerHigh,
        elevation: 1,
        margin: EdgeInsets.zero,
      ),
    );
  }
}
