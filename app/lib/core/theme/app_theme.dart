import 'package:flutter/material.dart';

/// MatricQuest SA design tokens.
///
/// Energetic-but-credible: a deep teal/indigo base (study, focus) with a warm amber accent used
/// only for XP/reward moments, so gamification reads as a highlight rather than the whole app
/// looking like a kids' game. Correctness feedback never relies on colour alone (section 15) —
/// every success/error state pairs colour with an icon and text.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF0F6E5C); // deep teal — focus, trust
  static const Color primaryDark = Color(0xFF0A4A3E);
  static const Color secondary = Color(
    0xFFFF9F1C,
  ); // warm amber — reserved for XP/reward moments
  static const Color surfaceLight = Color(0xFFF7FAF9);
  static const Color surfaceDark = Color(0xFF10181A);
  static const Color success = Color(0xFF1E8E5A);
  static const Color error = Color(0xFFD64550);
  static const Color warning = Color(0xFFE0A100);
}

class AppTheme {
  AppTheme._();

  static ThemeData light() => _base(Brightness.light);
  static ThemeData dark() => _base(Brightness.dark);

  static ThemeData _base(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
      secondary: AppColors.secondary,
      error: AppColors.error,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark
          ? AppColors.surfaceDark
          : AppColors.surfaceLight,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      // Large tap targets by default (section 15: accessibility, min 48x48).
      materialTapTargetSize: MaterialTapTargetSize.padded,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: colorScheme.onSurface,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: isDark ? const Color(0xFF17232A) : Colors.white,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF1B2830) : const Color(0xFFEFF5F3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      textTheme: Typography.material2021(platform: TargetPlatform.android).black
          .apply(
            bodyColor: colorScheme.onSurface,
            displayColor: colorScheme.onSurface,
          ),
    );
  }
}

/// Semantic status colours + icon pairing so correctness is never colour-only (section 15).
class FeedbackStyle {
  FeedbackStyle._();

  static const correctIcon = Icons.check_circle_rounded;
  static const incorrectIcon = Icons.cancel_rounded;
  static const partialIcon = Icons.adjust_rounded;
}
