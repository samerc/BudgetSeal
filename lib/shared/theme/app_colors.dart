import 'package:flutter/material.dart';

abstract final class AppColors {
  // ── Brand (same in all themes) ────────────────────────────
  static const primary = Color(0xFF1A2B4A);
  static const primaryLight = Color(0xFF2A3F6A);

  /// The active accent color. Defaults to Royal Blue (#2563EB).
  /// Updated at runtime via [setAccentColor] when the user picks a
  /// custom color or Material You resolves the system accent.
  static Color accent = const Color(0xFF2563EB);
  static const defaultAccent = Color(0xFF2563EB);
  static Color accentLight = const Color(0xFFDBEAFE);

  /// Whether the active theme is dark/black. Set from the MaterialApp
  /// builder in app.dart so context-free colors (e.g. default transaction
  /// colors) can adapt to the theme.
  static bool isDark = false;

  /// Call this from app.dart after resolving the accent color
  /// (from provider + DynamicColorBuilder). All 340+ references to
  /// AppColors.accent automatically pick up the new value on rebuild.
  static void setAccentColor(Color color) {
    accent = color;
    // Derive a light tint from the accent
    accentLight = Color.alphaBlend(
      color.withValues(alpha: 0.12),
      const Color(0xFFFFFFFF),
    );
  }

  // ── Semantic (same in all themes) ─────────────────────────
  static const healthy = Color(0xFF059669);
  static const healthyLight = Color(0xFFD1FAE5);
  static const caution = Color(0xFFD97706);
  static const cautionLight = Color(0xFFFEF3C7);
  static const overspent = Color(0xFFDC2626);
  static const overspentLight = Color(0xFFFEE2E2);

  // ── Pastel helpers (Cashew color model) ───────────────────
  /// Blend [amount] of white over [c] — a lighter, softer version of [c].
  static Color lightenPastel(Color c, double amount) =>
      Color.alphaBlend(Colors.white.withValues(alpha: amount), c);

  /// Blend [amount] of black over [c] — a darker, muted version of [c].
  static Color darkenPastel(Color c, double amount) =>
      Color.alphaBlend(Colors.black.withValues(alpha: amount), c);

  /// Theme-aware pastel: lightens [c] in light mode, darkens it in dark/black.
  /// Use for solid fills derived from a category/envelope/accent color.
  /// [inverse] flips the direction (darken in light, lighten in dark) — for
  /// text/glyphs drawn on top of a pastel fill.
  static Color pastel(
    BuildContext context,
    Color c, {
    double light = 0.55,
    double dark = 0.35,
    bool inverse = false,
  }) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final lighten = isLight != inverse;
    return lighten
        ? lightenPastel(c, isLight ? light : dark)
        : darkenPastel(c, isLight ? light : dark);
  }

  // ── Theme-aware surface/text colors ────────────────────────
  // Call these from build() methods where you have a BuildContext.
  // Surfaces are accent-tinted and come from the [SurfaceColors] theme
  // extension; the fallbacks below cover plain ThemeData (e.g. tests).
  static Color bg(BuildContext c) =>
      _s(c)?.bg ??
      switch (_mode(c)) {
        _ThemeMode.black => const Color(0xFF000000),
        _ThemeMode.dark => const Color(0xFF0F1219),
        _ThemeMode.light => const Color(0xFFF5F6FA),
      };
  static Color sf(BuildContext c) =>
      _s(c)?.card ??
      switch (_mode(c)) {
        _ThemeMode.black => const Color(0xFF121212),
        _ThemeMode.dark => const Color(0xFF1A1F2E),
        _ThemeMode.light => const Color(0xFFFFFFFF),
      };
  static Color sfv(BuildContext c) =>
      _s(c)?.container ??
      switch (_mode(c)) {
        _ThemeMode.black => const Color(0xFF1E1E1E),
        _ThemeMode.dark => const Color(0xFF242B3D),
        _ThemeMode.light => const Color(0xFFF0F1F5),
      };

  /// Background for popups, dialogs and bottom sheets.
  /// Accent for text (section headers, links): lifted in dark themes so the
  /// saturated accent stays readable on near-black surfaces.
  static Color accentText(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark
          ? lightenPastel(accent, 0.3)
          : accent;

  static Color popup(BuildContext c) => _s(c)?.popup ?? sf(c);

  static Color tp(BuildContext c) => switch (_mode(c)) {
        _ThemeMode.black => const Color(0xFFF1F5F9),
        _ThemeMode.dark => const Color(0xFFF1F5F9),
        _ThemeMode.light => const Color(0xFF0F172A),
      };
  static Color ts(BuildContext c) => switch (_mode(c)) {
        _ThemeMode.black => const Color(0xFF8899B0),
        _ThemeMode.dark => const Color(0xFF8899B0),
        _ThemeMode.light => const Color(0xFF64748B),
      };
  static Color th(BuildContext c) => switch (_mode(c)) {
        _ThemeMode.black => const Color(0xFF4A5568),
        _ThemeMode.dark => const Color(0xFF5A6B82),
        _ThemeMode.light => const Color(0xFF94A3B8),
      };

  /// Hairline borders and dividers — deliberately faint (Cashew style).
  static Color bd(BuildContext c) =>
      _s(c)?.border ??
      switch (_mode(c)) {
        _ThemeMode.black => const Color(0xFF2A2A2A),
        _ThemeMode.dark => const Color(0xFF2A3348),
        _ThemeMode.light => const Color(0xFFE2E8F0),
      };

  /// Card border: only the black theme keeps a faint edge; light and dark
  /// cards are borderless (tinted surface + soft shadow).
  static Color cardBorder(BuildContext c) =>
      _s(c)?.cardBorder ?? Colors.transparent;

  /// Soft card shadow (light mode only; empty in dark/black).
  static List<BoxShadow> cardShadow(BuildContext c) =>
      _s(c)?.cardShadow ?? const [];

  static SurfaceColors? _s(BuildContext c) =>
      Theme.of(c).extension<SurfaceColors>();

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
  static const blackSurface = Color(0xFF121212);
  static const blackSurfaceVariant = Color(0xFF1E1E1E);

  /// Parse a hex color string (e.g. '#FF5733' or 'FF5733') to a Color.
  /// Results are cached to avoid re-parsing during rebuilds.
  static final _hexCache = <String, Color>{};
  static Color fromHex(String hex) {
    return _hexCache.putIfAbsent(hex, () {
      final h = hex.replaceAll('#', '');
      // tryParse + fallback: a malformed colorHex from a synced/imported file
      // must not throw FormatException on every render and brick the screen.
      final v = int.tryParse('FF$h', radix: 16);
      return Color(v ?? 0xFF607D8B);
    });
  }
}

enum _ThemeMode { light, dark, black }

/// Accent-derived surface palette, computed once per theme build
/// (see app_theme.dart) and read via [AppColors.bg]/[AppColors.sf]/etc.
@immutable
class SurfaceColors extends ThemeExtension<SurfaceColors> {
  const SurfaceColors({
    required this.bg,
    required this.card,
    required this.container,
    required this.popup,
    required this.nav,
    required this.border,
    required this.cardBorder,
    required this.cardShadow,
  });

  /// Scaffold background.
  final Color bg;

  /// Cards and list surfaces.
  final Color card;

  /// Secondary containers: chips, input fills, inline panels.
  final Color container;

  /// Dialogs, bottom sheets, menus.
  final Color popup;

  /// Bottom navigation bar.
  final Color nav;

  /// Hairline borders and dividers.
  final Color border;

  /// Card edge (transparent except in black mode).
  final Color cardBorder;

  final List<BoxShadow> cardShadow;

  @override
  SurfaceColors copyWith({
    Color? bg,
    Color? card,
    Color? container,
    Color? popup,
    Color? nav,
    Color? border,
    Color? cardBorder,
    List<BoxShadow>? cardShadow,
  }) =>
      SurfaceColors(
        bg: bg ?? this.bg,
        card: card ?? this.card,
        container: container ?? this.container,
        popup: popup ?? this.popup,
        nav: nav ?? this.nav,
        border: border ?? this.border,
        cardBorder: cardBorder ?? this.cardBorder,
        cardShadow: cardShadow ?? this.cardShadow,
      );

  @override
  SurfaceColors lerp(SurfaceColors? other, double t) {
    if (other == null) return this;
    return SurfaceColors(
      bg: Color.lerp(bg, other.bg, t)!,
      card: Color.lerp(card, other.card, t)!,
      container: Color.lerp(container, other.container, t)!,
      popup: Color.lerp(popup, other.popup, t)!,
      nav: Color.lerp(nav, other.nav, t)!,
      border: Color.lerp(border, other.border, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      cardShadow: BoxShadow.lerpList(cardShadow, other.cardShadow, t) ?? [],
    );
  }
}
