import 'package:flutter/material.dart';

abstract class AppTheme {
  // Professional teal-blue — appropriate for a healthcare context.
  // Full design system (typography scale, custom components, dark mode)
  // implemented in Step 7.
  static const _seed = Color(0xFF1A6B8A);

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.light,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
      filled: true,
    ),
    // TODO(step-7): extend with full typography scale, card theme, etc.
  );
}
