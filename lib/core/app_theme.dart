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
    final pageBackground = isDark
        ? colorScheme.surface
        : colorScheme.surfaceContainerLowest;
    final cardBackground = _ensureSurfaceContrast(
      background: pageBackground,
      candidate: colorScheme.surfaceContainerHigh,
      tint: colorScheme.primary,
      foreground: colorScheme.onSurface,
      tintOpacity: isDark ? .16 : .10,
    );
    final navigationBackground = _ensureSurfaceContrast(
      background: pageBackground,
      candidate: colorScheme.surfaceContainerHighest,
      tint: colorScheme.primary,
      foreground: colorScheme.onSurface,
      tintOpacity: isDark ? .22 : .16,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: colorScheme.brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: pageBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: pageBackground,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: navigationBackground,
        indicatorColor: colorScheme.secondaryContainer,
        elevation: 3,
      ),
      cardTheme: CardThemeData(
        clipBehavior: Clip.antiAlias,
        color: cardBackground,
        elevation: 1,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: .55),
          ),
        ),
      ),
    );
  }

  static Color _ensureSurfaceContrast({
    required Color background,
    required Color candidate,
    required Color tint,
    required Color foreground,
    required double tintOpacity,
  }) {
    if (_colorDistanceSquared(background, candidate) >= 18 * 18) {
      return candidate;
    }

    final tinted = Color.alphaBlend(
      tint.withValues(alpha: tintOpacity),
      background,
    );
    if (_colorDistanceSquared(background, tinted) >= 18 * 18) {
      return tinted;
    }

    return Color.alphaBlend(
      foreground.withValues(alpha: .10),
      background,
    );
  }

  static int _colorDistanceSquared(Color first, Color second) {
    final firstValue = first.toARGB32();
    final secondValue = second.toARGB32();
    final red = ((firstValue >> 16) & 0xff) - ((secondValue >> 16) & 0xff);
    final green = ((firstValue >> 8) & 0xff) - ((secondValue >> 8) & 0xff);
    final blue = (firstValue & 0xff) - (secondValue & 0xff);
    return red * red + green * green + blue * blue;
  }
}
