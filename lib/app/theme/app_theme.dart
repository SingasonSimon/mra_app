import 'package:flutter/material.dart';

class AppTheme {
  // Modern professional green color palette
  static const Color primary = Color(0xFF2E7D32); // Deep forest green
  static const Color primaryLight = Color(0xFF4CAF50); // Medium green
  static const Color primaryDark = Color(0xFF1B5E20); // Dark forest green
  static const Color accentGreen = Color(0xFF66BB6A); // Accent green for links/CTAs
  static const Color secondary = Color(0xFF81C784);
  static const Color error = Color(0xFFE57373);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color background = Color(0xFFFAFAFA);
  
  // Dark green theme colors for auth screens
  static const Color darkGreenBackground = Color(0xFF1B5E20); // Deep forest green background
  static const Color darkGreenSurface = Color(0xFF2E7D32); // Button green

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: secondary,
      error: error,
      brightness: Brightness.light,
      background: background,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
      textTheme: Typography.blackMountainView.copyWith(
        bodyLarge: const TextStyle(color: textPrimary),
        bodyMedium: const TextStyle(color: textSecondary),
      ),
    );
  }

  static ThemeData dark() {
    const darkPrimary = Color(0xFF66BB6A);
    const darkBackground = Color(0xFF1B5E20);
    const darkSurface = Color(0xFF2E7D32);
    const darkText = Color(0xFFE0E0E0);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: darkPrimary,
      primary: darkPrimary,
      secondary: secondary,
      error: error,
      brightness: Brightness.dark,
      background: darkBackground,
      surface: darkSurface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: darkBackground,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: darkSurface,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: darkPrimary,
        foregroundColor: Colors.white,
      ),
      textTheme: Typography.whiteMountainView.copyWith(
        bodyLarge: const TextStyle(color: darkText),
        bodyMedium: TextStyle(color: darkText.withOpacity(0.7)),
      ),
    );
  }
}


