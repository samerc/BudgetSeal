import 'package:flutter/material.dart';

abstract final class AppColors {
  // ── Brand (same in all themes) ────────────────────────────
  static const primary = Color(0xFF1A2B4A);
  static const primaryLight = Color(0xFF2A3F6A);
  static const accent = Color(0xFF2563EB);
  static const accentLight = Color(0xFFDBEAFE);

  // ── Semantic (same in all themes) ─────────────────────────
  static const healthy = Color(0xFF059669);
  static const healthyLight = Color(0xFFD1FAE5);
  static const caution = Color(0xFFD97706);
  static const cautionLight = Color(0xFFFEF3C7);
  static const overspent = Color(0xFFDC2626);
  static const overspentLight = Color(0xFFFEE2E2);

  // ── Theme-aware surface/text colors ────────────────────────
  // Call these from build() methods where you have a BuildContext.
  static Color bg(BuildContext c) => switch (_mode(c)) {
        _ThemeMode.black => const Color(0xFF000000),
        _ThemeMode.dark  => const Color(0xFF0F1219),
        _ThemeMode.light => const Color(0xFFF5F6FA),
      };
  static Color sf(BuildContext c) => switch (_mode(c)) {
        _ThemeMode.black => const Color(0xFF0D0D0D),
        _ThemeMode.dark  => const Color(0xFF1A1F2E),
        _ThemeMode.light => const Color(0xFFFFFFFF),
      };
  static Color sfv(BuildContext c) => switch (_mode(c)) {
        _ThemeMode.black => const Color(0xFF1A1A1A),
        _ThemeMode.dark  => const Color(0xFF242B3D),
        _ThemeMode.light => const Color(0xFFF0F1F5),
      };
  static Color tp(BuildContext c) => switch (_mode(c)) {
        _ThemeMode.black => const Color(0xFFF1F5F9),
        _ThemeMode.dark  => const Color(0xFFF1F5F9),
        _ThemeMode.light => const Color(0xFF0F172A),
      };
  static Color ts(BuildContext c) => switch (_mode(c)) {
        _ThemeMode.black => const Color(0xFF8899B0),
        _ThemeMode.dark  => const Color(0xFF8899B0),
        _ThemeMode.light => const Color(0xFF64748B),
      };
  static Color th(BuildContext c) => switch (_mode(c)) {
        _ThemeMode.black => const Color(0xFF4A5568),
        _ThemeMode.dark  => const Color(0xFF5A6B82),
        _ThemeMode.light => const Color(0xFF94A3B8),
      };
  static Color bd(BuildContext c) => switch (_mode(c)) {
        _ThemeMode.black => const Color(0xFF222222),
        _ThemeMode.dark  => const Color(0xFF2A3348),
        _ThemeMode.light => const Color(0xFFE2E8F0),
      };

  /// Card border: faint edge in dark/black modes, subtle in light.
  static Color cardBorder(BuildContext c) => switch (_mode(c)) {
        _ThemeMode.black => Colors.white.withValues(alpha: 0.07),
        _ThemeMode.dark  => Colors.white.withValues(alpha: 0.05),
        _ThemeMode.light => const Color(0xFFE8EBF0),
      };

  static _ThemeMode _mode(BuildContext c) {
    final brightness = Theme.of(c).brightness;
    if (brightness == Brightness.light) return _ThemeMode.light;
    // Distinguish black from dark using scaffold color
    final scaffoldColor = Theme.of(c).scaffoldBackgroundColor;
    if (scaffoldColor == const Color(0xFF000000)) return _ThemeMode.black;
    return _ThemeMode.dark;
  }

  // ── Legacy const values (for const contexts / hint styles) ─
  // These return light-mode values. Use the methods above when possible.
  static const background = Color(0xFFF5F6FA);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFF0F1F5);
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const textHint = Color(0xFF94A3B8);

  // Dark const values (used by theme definitions)
  static const darkBackground = Color(0xFF0F1219);
  static const darkSurface = Color(0xFF1A1F2E);
  static const darkSurfaceVariant = Color(0xFF242B3D);
  static const darkTextPrimary = Color(0xFFF1F5F9);
  static const darkTextSecondary = Color(0xFF8899B0);
  static const darkTextHint = Color(0xFF5A6B82);

  // Black (AMOLED) const values
  static const blackBackground = Color(0xFF000000);
  static const blackSurface = Color(0xFF0D0D0D);
  static const blackSurfaceVariant = Color(0xFF1A1A1A);

  /// Parse a hex color string (e.g. '#FF5733' or 'FF5733') to a Color.
  /// Results are cached to avoid re-parsing during rebuilds.
  static final _hexCache = <String, Color>{};
  static Color fromHex(String hex) {
    return _hexCache.putIfAbsent(hex, () {
      final h = hex.replaceAll('#', '');
      return Color(int.parse('FF$h', radix: 16));
    });
  }
}

enum _ThemeMode { light, dark, black }
