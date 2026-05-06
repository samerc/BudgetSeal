import 'package:flutter/material.dart';

import '../../core/providers/font_provider.dart';
import 'app_colors.dart';
import 'design_tokens.dart';

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
        borderRadius: BorderRadius.circular(CardTokens.radius),
        side: BorderSide(color: Colors.grey.shade200.withValues(alpha: 0.7)),
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
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      labelTextStyle: WidgetStatePropertyAll(
        fs(11, FontWeight.w600, null),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: Colors.grey.shade200,
      thickness: 1,
      space: 1,
    ),
    textTheme: textTheme.copyWith(
      displaySmall: fs(TypographyTokens.screenTitleSize, TypographyTokens.screenTitleWeight, AppColors.textPrimary),
      titleLarge: fs(20, FontWeight.w700, AppColors.textPrimary),
      titleMedium: fs(TypographyTokens.cardTitleSize, TypographyTokens.cardTitleWeight, AppColors.textPrimary),
      bodyLarge: fs(TypographyTokens.bodySize, TypographyTokens.bodyWeight, AppColors.textPrimary),
      bodyMedium: fs(TypographyTokens.bodySize, TypographyTokens.bodyWeight, AppColors.textPrimary),
      bodySmall: fs(TypographyTokens.captionSize, TypographyTokens.captionWeight, AppColors.textSecondary),
      labelSmall: fs(TypographyTokens.overlineSize, TypographyTokens.overlineWeight, AppColors.textHint),
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
        borderRadius: BorderRadius.circular(CardTokens.radius),
        // No border in dark mode — uses surface elevation only
        side: BorderSide.none,
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
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      labelTextStyle: WidgetStatePropertyAll(
        fs(11, FontWeight.w600, null),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.darkSurfaceVariant,
      thickness: 1,
      space: 1,
    ),
    textTheme: textTheme.copyWith(
      displaySmall: fs(TypographyTokens.screenTitleSize, TypographyTokens.screenTitleWeight, AppColors.darkTextPrimary),
      titleLarge: fs(20, FontWeight.w700, AppColors.darkTextPrimary),
      titleMedium: fs(TypographyTokens.cardTitleSize, TypographyTokens.cardTitleWeight, AppColors.darkTextPrimary),
      bodyLarge: fs(TypographyTokens.bodySize, TypographyTokens.bodyWeight, AppColors.darkTextPrimary),
      bodyMedium: fs(TypographyTokens.bodySize, TypographyTokens.bodyWeight, AppColors.darkTextPrimary),
      bodySmall: fs(TypographyTokens.captionSize, TypographyTokens.captionWeight, AppColors.darkTextSecondary),
      labelSmall: fs(TypographyTokens.overlineSize, TypographyTokens.overlineWeight, AppColors.darkTextHint),
    ),
  );
}

/// Build the black (AMOLED) theme — same as dark but with pure black surfaces.
ThemeData buildBlackTheme(String fontName) {
  final dark = buildDarkTheme(fontName);
  return dark.copyWith(
    scaffoldBackgroundColor: AppColors.blackBackground,
    colorScheme: dark.colorScheme.copyWith(
      surface: AppColors.blackSurface,
    ),
    appBarTheme: dark.appBarTheme.copyWith(
      backgroundColor: AppColors.blackBackground,
    ),
    cardTheme: dark.cardTheme.copyWith(
      color: AppColors.blackSurface,
    ),
    inputDecorationTheme: dark.inputDecorationTheme.copyWith(
      fillColor: AppColors.blackSurfaceVariant,
    ),
    navigationBarTheme: dark.navigationBarTheme.copyWith(
      backgroundColor: AppColors.blackSurface,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.blackSurfaceVariant,
      thickness: 1,
      space: 1,
    ),
  );
}

// ── Keep old names as aliases for backward compatibility ─────────────────────
final appTheme = buildLightTheme('Plus Jakarta Sans');
final appDarkTheme = buildDarkTheme('Plus Jakarta Sans');
