import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insect_identifier/core/app_theme.dart';

void main() {
  test('flat dynamic surfaces remain distinct from the page background', () {
    const flatSurface = Color(0xfff8f8f8);
    final flatDynamicScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xff6750a4),
    ).copyWith(
      surface: flatSurface,
      surfaceContainerLowest: flatSurface,
      surfaceContainerLow: flatSurface,
      surfaceContainer: flatSurface,
      surfaceContainerHigh: flatSurface,
      surfaceContainerHighest: flatSurface,
    );

    final theme = AppTheme.fromColorScheme(flatDynamicScheme);

    expect(theme.scaffoldBackgroundColor, flatSurface);
    expect(theme.cardTheme.color, isNot(flatSurface));
    expect(theme.navigationBarTheme.backgroundColor, isNot(flatSurface));
  });

  test('cards retain a visible outline in dynamic color themes', () {
    final theme = AppTheme.fromColorScheme(
      ColorScheme.fromSeed(seedColor: const Color(0xff006b5f)),
    );

    final shape = theme.cardTheme.shape! as RoundedRectangleBorder;
    expect(shape.side.style, BorderStyle.solid);
    expect((shape.side.color.toARGB32() >> 24) & 0xff, greaterThan(0));
  });
}
