import 'package:flutter/material.dart';

import '../../core/providers/font_provider.dart';
import 'app_colors.dart';

/// Build the light theme with the given font name.
ThemeData buildLightTheme(String fontName) {
  final textTheme = buildTextTheme(fontName);
  final fs = (double? sz, FontWeight? fw, Color? c) =>
      fontStyle(fontName, fontSize: sz, fontWeight: fw, color: c);

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      brightness: Brightness.light,
      primary: AppColors.accent,
      secondary: AppColors.accent,
      surface: AppColors.surface,
      error: AppColors.overspent,
    ),
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: fs(20, FontWeight.w700, AppColors.textPrimary),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.accent, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: fs(null, null, AppColors.textSecondary),
      hintStyle: fs(null, null, AppColors.textHint),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
        textStyle: fs(15, FontWeight.w600, null),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.accent.withValues(alpha: 0.12),
      labelTextStyle: WidgetStatePropertyAll(
        fs(11, FontWeight.w500, null),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: Colors.grey.shade200,
      thickness: 1,
      space: 1,
    ),
    textTheme: textTheme.copyWith(
      displaySmall: fs(28, FontWeight.w700, AppColors.textPrimary),
      titleLarge: fs(20, FontWeight.w700, AppColors.textPrimary),
      titleMedium: fs(16, FontWeight.w600, AppColors.textPrimary),
      bodyMedium: fs(14, null, AppColors.textPrimary),
      bodySmall: fs(12, null, AppColors.textSecondary),
      labelSmall: fs(11, null, AppColors.textHint),
    ),
  );
}

/// Build the dark theme with the given font name.
ThemeData buildDarkTheme(String fontName) {
  final textTheme = buildTextTheme(fontName, Brightness.dark);
  final fs = (double? sz, FontWeight? fw, Color? c) =>
      fontStyle(fontName, fontSize: sz, fontWeight: fw, color: c);

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      brightness: Brightness.dark,
      primary: AppColors.accent,
      secondary: AppColors.accent,
      surface: AppColors.darkSurface,
      error: AppColors.overspent,
    ),
    scaffoldBackgroundColor: AppColors.darkBackground,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.darkBackground,
      foregroundColor: AppColors.darkTextPrimary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: fs(20, FontWeight.w700, AppColors.darkTextPrimary),
    ),
    cardTheme: CardThemeData(
      color: AppColors.darkSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.darkSurfaceVariant),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkSurfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.accent, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: fs(null, null, AppColors.darkTextSecondary),
      hintStyle: fs(null, null, AppColors.darkTextHint),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
        textStyle: fs(15, FontWeight.w600, null),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.darkSurface,
      indicatorColor: AppColors.accent.withValues(alpha: 0.2),
      labelTextStyle: WidgetStatePropertyAll(
        fs(11, FontWeight.w500, null),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.darkSurfaceVariant,
      thickness: 1,
      space: 1,
    ),
    textTheme: textTheme.copyWith(
      displaySmall: fs(28, FontWeight.w700, AppColors.darkTextPrimary),
      titleLarge: fs(20, FontWeight.w700, AppColors.darkTextPrimary),
      titleMedium: fs(16, FontWeight.w600, AppColors.darkTextPrimary),
      bodyMedium: fs(14, null, AppColors.darkTextPrimary),
      bodySmall: fs(12, null, AppColors.darkTextSecondary),
      labelSmall: fs(11, null, AppColors.darkTextHint),
    ),
  );
}

// ── Keep old names as aliases for backward compatibility ─────────────────────
final appTheme = buildLightTheme('Inter');
final appDarkTheme = buildDarkTheme('Inter');
