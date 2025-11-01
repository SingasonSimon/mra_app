import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Teal Color Palette (Primary Brand Color)
  static const Color teal50 = Color(0xFFF0FDFA);   // Very light teal backgrounds
  static const Color teal100 = Color(0xFFCCFBF1);  // Light teal cards/badges
  static const Color teal200 = Color(0xFF99F6E4);  // Borders and accents
  static const Color teal500 = Color(0xFF14B8A6);  // Primary buttons and headers
  static const Color teal600 = Color(0xFF0D9488);  // Hover states
  static const Color teal700 = Color(0xFF0F766E); // Darker text on light backgrounds
  static const Color teal900 = Color(0xFF134E4A);  // Dark text for headings

  // Blue Color Palette (Secondary Color)
  static const Color blue50 = Color(0xFFEFF6FF);    // Light information backgrounds
  static const Color blue100 = Color(0xFFDBEAFE);   // Light blue icons/badges
  static const Color blue200 = Color(0xFFBFDBFE);  // Borders
  static const Color blue500 = Color(0xFF3B82F6);  // Secondary buttons
  static const Color blue600 = Color(0xFF2563EB);  // Secondary button hovers
  static const Color blue700 = Color(0xFF1D4ED8);  // Darker secondary text
  static const Color blue900 = Color(0xFF1E3A8A);   // Headings

  // Semantic Colors - Success (Green/Teal)
  static const Color successBg = teal100;
  static const Color successText = teal600;
  static const Color successTextDark = teal700;

  // Semantic Colors - Warning (Yellow/Orange)
  static const Color yellow100 = Color(0xFFFEF3C7); // Warning badge backgrounds
  static const Color yellow500 = Color(0xFFEAB308); // Warning indicators
  static const Color yellow700 = Color(0xFFA16207); // Warning text
  static const Color orange100 = Color(0xFFFFEDD5); // Alert backgrounds
  static const Color orange600 = Color(0xFFEA580C);  // Alert text

  // Semantic Colors - Error/Danger (Red)
  static const Color red50 = Color(0xFFFEF2F2);      // Error backgrounds
  static const Color red100 = Color(0xFFFEE2E2);   // Error badges
  static const Color red200 = Color(0xFFFECACA);   // Error borders
  static const Color red500 = Color(0xFFEF4444);    // Emergency buttons
  static const Color red600 = Color(0xFFDC2626);    // Emergency button hovers
  static const Color red700 = Color(0xFFB91C1C);    // Darker error text
  static const Color red800 = Color(0xFF991B1B);    // Alert text
  static const Color red900 = Color(0xFF7F1D1D);    // Dark error text

  // Neutral Colors - Gray Scale
  static const Color white = Color(0xFFFFFFFF);     // Primary background
  static const Color gray50 = Color(0xFFF9FAFB);     // Light background
  static const Color gray100 = Color(0xFFF3F4F6);    // Card backgrounds
  static const Color gray200 = Color(0xFFE5E7EB);   // Borders
  static const Color gray400 = Color(0xFF9CA3AF);   // Disabled/muted icons
  static const Color gray500 = Color(0xFF6B7280);    // Secondary text
  static const Color gray600 = Color(0xFF4B5563);    // Body text
  static const Color gray700 = Color(0xFF374151);    // Strong body text
  static const Color gray900 = Color(0xFF111827);    // Headings and primary text

  // Special Colors - Purple
  static const Color purple100 = Color(0xFFF3E8FF);  // Caregiver badges
  static const Color purple600 = Color(0xFF9333EA);  // Caregiver icons

  // Legacy aliases for backward compatibility
  static const Color primary = teal500;
  static const Color primaryLight = teal600;
  static const Color primaryDark = teal700;
  static const Color secondary = blue500;
  static const Color error = red500;
  static const Color textPrimary = gray900;
  static const Color textSecondary = gray600;
  static const Color background = gray50;
  static const Color darkGreenBackground = teal900;
  static const Color darkGreenSurface = teal600;

  // Get Poppins text theme
  static TextTheme get _textTheme => GoogleFonts.poppinsTextTheme();

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: teal500,
      primary: teal500,
      secondary: blue500,
      error: red500,
      brightness: Brightness.light,
      background: gray50,
      surface: white,
    );

    final textTheme = _textTheme.copyWith(
      displayLarge: _textTheme.displayLarge?.copyWith(color: gray900),
      displayMedium: _textTheme.displayMedium?.copyWith(color: gray900),
      displaySmall: _textTheme.displaySmall?.copyWith(color: gray900),
      headlineLarge: _textTheme.headlineLarge?.copyWith(color: gray900),
      headlineMedium: _textTheme.headlineMedium?.copyWith(color: gray900),
      headlineSmall: _textTheme.headlineSmall?.copyWith(color: gray900),
      titleLarge: _textTheme.titleLarge?.copyWith(color: gray900),
      titleMedium: _textTheme.titleMedium?.copyWith(color: gray900),
      titleSmall: _textTheme.titleSmall?.copyWith(color: gray900),
      bodyLarge: _textTheme.bodyLarge?.copyWith(color: gray600),
      bodyMedium: _textTheme.bodyMedium?.copyWith(color: gray600),
      bodySmall: _textTheme.bodySmall?.copyWith(color: gray500),
      labelLarge: _textTheme.labelLarge?.copyWith(color: gray700),
      labelMedium: _textTheme.labelMedium?.copyWith(color: gray600),
      labelSmall: _textTheme.labelSmall?.copyWith(color: gray500),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: GoogleFonts.poppins().fontFamily,
      textTheme: textTheme,
      scaffoldBackgroundColor: gray50,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: teal500,
        foregroundColor: white,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: teal500,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: white,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: gray200, width: 1),
        ),
        color: white,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: teal500,
        foregroundColor: white,
        elevation: 2,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: teal500,
          foregroundColor: white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: teal600,
          side: const BorderSide(color: teal200, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: gray100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: teal500, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: red500, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return teal500;
          return gray400;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return teal100;
          return gray200;
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: gray900,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
      ),
    );
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: teal500,
      primary: teal600,
      secondary: blue500,
      error: red500,
      brightness: Brightness.dark,
      background: gray900,
      surface: const Color(0xFF1F2937), // gray-800 equivalent
    );

    final textTheme = _textTheme.copyWith(
      displayLarge: _textTheme.displayLarge?.copyWith(color: white),
      displayMedium: _textTheme.displayMedium?.copyWith(color: white),
      displaySmall: _textTheme.displaySmall?.copyWith(color: white),
      headlineLarge: _textTheme.headlineLarge?.copyWith(color: white),
      headlineMedium: _textTheme.headlineMedium?.copyWith(color: white),
      headlineSmall: _textTheme.headlineSmall?.copyWith(color: white),
      titleLarge: _textTheme.titleLarge?.copyWith(color: white),
      titleMedium: _textTheme.titleMedium?.copyWith(color: white),
      titleSmall: _textTheme.titleSmall?.copyWith(color: white),
      bodyLarge: _textTheme.bodyLarge?.copyWith(color: gray200),
      bodyMedium: _textTheme.bodyMedium?.copyWith(color: const Color(0xFFD1D5DB)), // gray300 equivalent
      bodySmall: _textTheme.bodySmall?.copyWith(color: gray400),
      labelLarge: _textTheme.labelLarge?.copyWith(color: gray200),
      labelMedium: _textTheme.labelMedium?.copyWith(color: const Color(0xFFD1D5DB)),
      labelSmall: _textTheme.labelSmall?.copyWith(color: gray400),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: GoogleFonts.poppins().fontFamily,
      textTheme: textTheme,
      scaffoldBackgroundColor: gray900,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF1F2937), // gray-800
        foregroundColor: white,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: teal500,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: white,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: gray700, width: 1),
        ),
        color: const Color(0xFF1F2937),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: teal500,
        foregroundColor: white,
        elevation: 2,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: teal500,
          foregroundColor: white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1F2937),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: gray700, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: teal500, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF1F2937),
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
      ),
    );
  }

  // Gradient helpers
  static LinearGradient get tealGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [teal500, teal600],
  );

  static LinearGradient get blueGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [blue500, blue600],
  );

  static LinearGradient get redGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [red500, red600],
  );
}

// Icon mapping from Lucide to Material Icons
class AppIcons {
  // Navigation Icons
  static const IconData home = Icons.home_rounded;
  static const IconData pill = Icons.medication;
  static const IconData barChart3 = Icons.bar_chart;
  static const IconData user = Icons.person;

  // Action Icons
  static const IconData plus = Icons.add_rounded;
  static const IconData edit = Icons.edit_rounded;
  static const IconData trash2 = Icons.delete_rounded;
  static const IconData arrowLeft = Icons.arrow_back_rounded;
  static const IconData chevronRight = Icons.chevron_right_rounded;
  static const IconData search = Icons.search_rounded;

  // Medical/Health Icons
  static const IconData heart = Icons.favorite_rounded;
  static const IconData bell = Icons.notifications_rounded;
  static const IconData calendar = Icons.calendar_today_rounded;
  static const IconData clock = Icons.access_time_rounded;
  static const IconData alertCircle = Icons.error_outline_rounded;

  // Status Icons
  static const IconData check = Icons.check_circle_rounded;
  static const IconData x = Icons.close_rounded;
  static const IconData trendingUp = Icons.trending_up_rounded;

  // Communication Icons
  static const IconData phone = Icons.phone_rounded;
  static const IconData share2 = Icons.share_rounded;
  static const IconData users = Icons.people_rounded;

  // Feature Icons
  static const IconData camera = Icons.camera_alt_rounded;
  static const IconData mapPin = Icons.location_on_rounded;
  static const IconData shield = Icons.shield_rounded;
  static const IconData settings = Icons.settings_rounded;
  static const IconData moon = Icons.dark_mode_rounded;
  static const IconData logOut = Icons.logout_rounded;
}
