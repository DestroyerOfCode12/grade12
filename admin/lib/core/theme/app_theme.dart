import 'package:flutter/material.dart';

/// Same brand seed colour as the learner app (mobile `AppColors.primary`) for visual continuity
/// across the two products, but laid out as a dense, data-first desktop tool rather than a
/// touch-first consumer app — wide data tables, compact rows, no oversized tap targets.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF0F6E5C);
  static const Color secondary = Color(0xFFFF9F1C);
  static const Color success = Color(0xFF1E8E5A);
  static const Color error = Color(0xFFD64550);
  static const Color warning = Color(0xFFE0A100);
  static const Color surfaceLight = Color(0xFFF7FAF9);
  static const Color sidebar = Color(0xFF0A4A3E);
}

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      secondary: AppColors.secondary,
      error: AppColors.error,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.surfaceLight,
      visualDensity: VisualDensity.compact,
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(
          colorScheme.surfaceContainerHigh,
        ),
        dataRowMinHeight: 44,
        dataRowMaxHeight: 52,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFEFF5F3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
    );
  }
}

/// Colour + icon pairing per content_status, used everywhere a status pill is shown so the
/// meaning never relies on colour alone (same accessibility rule as the learner app).
class StatusStyle {
  StatusStyle._();

  static Color colorFor(String status) => switch (status) {
    'draft' => Colors.grey,
    'in_review' => AppColors.warning,
    'approved' => Colors.blue,
    'published' => AppColors.success,
    'rejected' => AppColors.error,
    'archived' => Colors.blueGrey,
    _ => Colors.grey,
  };

  static IconData iconFor(String status) => switch (status) {
    'draft' => Icons.edit_note_rounded,
    'in_review' => Icons.hourglass_top_rounded,
    'approved' => Icons.thumb_up_alt_rounded,
    'published' => Icons.public_rounded,
    'rejected' => Icons.block_rounded,
    'archived' => Icons.archive_rounded,
    _ => Icons.help_outline_rounded,
  };
}
