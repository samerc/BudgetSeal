import 'package:flutter/material.dart';

import 'app_colors.dart';

extension ThemeColorsExt on BuildContext {
  ThemeColors get colors {
    final isDark = Theme.of(this).brightness == Brightness.dark;
    return isDark ? ThemeColors.dark : ThemeColors.light;
  }
}

class ThemeColors {
  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;
  final Color border;

  const ThemeColors({
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
    required this.border,
  });

  static const light = ThemeColors(
    background: AppColors.background,
    surface: AppColors.surface,
    surfaceVariant: AppColors.surfaceVariant,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    textHint: AppColors.textHint,
    border: Color(0xFFE2E8F0),
  );

  static const dark = ThemeColors(
    background: AppColors.darkBackground,
    surface: AppColors.darkSurface,
    surfaceVariant: AppColors.darkSurfaceVariant,
    textPrimary: AppColors.darkTextPrimary,
    textSecondary: AppColors.darkTextSecondary,
    textHint: AppColors.darkTextHint,
    border: AppColors.darkSurfaceVariant,
  );
}
