import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

// ─── Dark Theme ──────────────────────────────────────────────────────────────

final appDarkTheme = ThemeData(
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
    titleTextStyle: GoogleFonts.inter(
      color: AppColors.darkTextPrimary,
      fontSize: 20,
      fontWeight: FontWeight.w700,
    ),
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
    labelStyle: GoogleFonts.inter(color: AppColors.darkTextSecondary),
    hintStyle: GoogleFonts.inter(color: AppColors.darkTextHint),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: AppColors.accent,
      foregroundColor: Colors.white,
      minimumSize: const Size.fromHeight(52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
      textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
    ),
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: AppColors.darkSurface,
    indicatorColor: AppColors.accent.withValues(alpha: 0.2),
    labelTextStyle: WidgetStatePropertyAll(
      GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500),
    ),
  ),
  dividerTheme: const DividerThemeData(
    color: AppColors.darkSurfaceVariant,
    thickness: 1,
    space: 1,
  ),
  textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
    displaySmall: GoogleFonts.inter(
        color: AppColors.darkTextPrimary, fontWeight: FontWeight.w700, fontSize: 28),
    titleLarge: GoogleFonts.inter(
        color: AppColors.darkTextPrimary, fontWeight: FontWeight.w700, fontSize: 20),
    titleMedium: GoogleFonts.inter(
        color: AppColors.darkTextPrimary, fontWeight: FontWeight.w600, fontSize: 16),
    bodyMedium: GoogleFonts.inter(
        color: AppColors.darkTextPrimary, fontSize: 14),
    bodySmall: GoogleFonts.inter(
        color: AppColors.darkTextSecondary, fontSize: 12),
    labelSmall: GoogleFonts.inter(
        color: AppColors.darkTextHint, fontSize: 11),
  ),
);

// ─── Light Theme ─────────────────────────────────────────────────────────────

final appTheme = ThemeData(
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
    titleTextStyle: GoogleFonts.inter(
      color: AppColors.textPrimary,
      fontSize: 20,
      fontWeight: FontWeight.w700,
    ),
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
    labelStyle: GoogleFonts.inter(color: AppColors.textSecondary),
    hintStyle: GoogleFonts.inter(color: AppColors.textHint),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: AppColors.accent,
      foregroundColor: Colors.white,
      minimumSize: const Size.fromHeight(52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
      textStyle: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: AppColors.surface,
    indicatorColor: AppColors.accent.withValues(alpha: 0.12),
    labelTextStyle: WidgetStatePropertyAll(
      GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500),
    ),
  ),
  dividerTheme: DividerThemeData(
    color: Colors.grey.shade200,
    thickness: 1,
    space: 1,
  ),
  textTheme: GoogleFonts.interTextTheme().copyWith(
    displaySmall: GoogleFonts.inter(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w700,
      fontSize: 28,
    ),
    titleLarge: GoogleFonts.inter(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w700,
      fontSize: 20,
    ),
    titleMedium: GoogleFonts.inter(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w600,
      fontSize: 16,
    ),
    bodyMedium: GoogleFonts.inter(
      color: AppColors.textPrimary,
      fontSize: 14,
    ),
    bodySmall: GoogleFonts.inter(
      color: AppColors.textSecondary,
      fontSize: 12,
    ),
    labelSmall: GoogleFonts.inter(
      color: AppColors.textHint,
      fontSize: 11,
    ),
  ),
);
