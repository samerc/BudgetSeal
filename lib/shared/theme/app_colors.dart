import 'package:flutter/material.dart';

import 'brand_palette.dart';

abstract final class AppColors {
  // ── Brand (same in all themes) ────────────────────────────
  static const primary = Color(0xFF1C1D24); // "night" brand surface
  static const primaryLight = Color(0xFF2A2B33);

  /// The active accent for the current theme mode: the selected pair's deep
  /// tone in light mode, its bright tone in dark/black (see [AccentPair]).
  /// Set via [setAccent] from app.dart — all references pick it up on rebuild.
  static Color accent = brandPalette.first.deep;
  static Color accentLight = brandPalette.first.lightFill;

  /// Text/icon color on an [accent] fill (white on deep tones, dark ink on
  /// bright ones). Use instead of `Colors.white` on accent backgrounds.
  static Color onAccent = Colors.white;

  /// The bright brand tone in every mode — for filled brand surfaces (the
  /// "Ready to assign" banner, the envelope seal). Text on it: [brandInk].
  static Color accentBright = brandPalette.first.bright;

  /// The selected palette pair (null when following the system color).
  static AccentPair? accentPair = brandPalette.first;
  static Color _system = brandPalette.first.deep;

  /// Whether the active theme is dark/black. Set from the MaterialApp
  /// builder in app.dart so context-free colors (e.g. default transaction
  /// colors) can adapt to the theme.
  static bool isDark = false;

  /// Select the accent: a palette [pair], or the Material You [system] color
  /// when [pair] is null. Call [applyMode] afterwards (app.dart does both).
  static void setAccent(AccentPair? pair, {Color? system}) {
    accentPair = pair;
    if (system != null) _system = system;
    applyMode(isDark);
  }

  /// Resolve [accent] and friends for light or dark mode.
  static void applyMode(bool dark) {
    isDark = dark;
    final pair = accentPair;
    if (pair != null) {
      accent = pair.accentFor(dark);
      accentLight = pair.fillFor(dark);
      accentBright = pair.bright;
    } else {
      accent = dark ? lightenPastel(_system, 0.3) : _system;
      accentLight = dark ? darkenPastel(_system, 0.7) : lightenPastel(_system, 0.85);
      accentBright = lightenPastel(_system, 0.25);
    }
    onAccent = inkOn(accent);
  }

  /// Readable text color on [bg]: [brandInk] on light fills, white on dark.
  static Color inkOn(Color bg) =>
      bg.computeLuminance() > 0.35 ? brandInk : Colors.white;

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

  /// The [n]th variant of a repeated chart color (n = 0 is [c] itself):
  /// alternately lighter and darker for the first four repeats, then a hue
  /// shift — so any number of repeats stays distinct and never washes out.
  static Color repeatShade(Color c, int n) {
    if (n == 0) return c;
    if (n <= 4) {
      return n.isOdd
          ? lightenPastel(c, 0.22 * ((n + 1) ~/ 2))
          : darkenPastel(c, 0.2 * (n ~/ 2));
    }
    final hsl = HSLColor.fromColor(c);
    return hsl.withHue((hsl.hue + 37.0 * (n - 4)) % 360).toColor();
  }

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
        _ThemeMode.dark => const Color(0xFF121318),
        _ThemeMode.light => const Color(0xFFF7F5F1),
      };
  static Color sf(BuildContext c) =>
      _s(c)?.card ??
      switch (_mode(c)) {
        _ThemeMode.black => const Color(0xFF111216),
        _ThemeMode.dark => const Color(0xFF1C1D24),
        _ThemeMode.light => const Color(0xFFFFFFFF),
      };
  static Color sfv(BuildContext c) =>
      _s(c)?.container ??
      switch (_mode(c)) {
        _ThemeMode.black => const Color(0xFF1A1B20),
        _ThemeMode.dark => const Color(0xFF25262E),
        _ThemeMode.light => const Color(0xFFEFECE6),
      };

  /// Accent for text (section headers, links). The accent is already tuned
  /// per mode (bright in dark, deep in light), so this is just [accent].
  static Color accentText(BuildContext c) => accent;

  /// Background for popups, dialogs and bottom sheets.
  static Color popup(BuildContext c) => _s(c)?.popup ?? sf(c);

  static Color tp(BuildContext c) => switch (_mode(c)) {
        _ThemeMode.black => darkTextPrimary,
        _ThemeMode.dark => darkTextPrimary,
        _ThemeMode.light => textPrimary,
      };
  static Color ts(BuildContext c) => switch (_mode(c)) {
        _ThemeMode.black => darkTextSecondary,
        _ThemeMode.dark => darkTextSecondary,
        _ThemeMode.light => textSecondary,
      };
  static Color th(BuildContext c) => switch (_mode(c)) {
        _ThemeMode.black => darkTextHint,
        _ThemeMode.dark => darkTextHint,
        _ThemeMode.light => textHint,
      };

  /// Hairline borders and dividers — deliberately faint (Cashew style).
  static Color bd(BuildContext c) =>
      _s(c)?.border ??
      switch (_mode(c)) {
        _ThemeMode.black => const Color(0xFF26272C),
        _ThemeMode.dark => const Color(0xFF2E3038),
        _ThemeMode.light => const Color(0xFFE7E3DB),
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
  static const background = Color(0xFFF7F5F1);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFEFECE6);
  static const textPrimary = Color(0xFF1C1A16);
  static const textSecondary = Color(0xFF6B655B);
  static const textHint = Color(0xFFA29C91);

  // Dark const values (used by theme definitions)
  static const darkBackground = Color(0xFF121318);
  static const darkSurface = Color(0xFF1C1D24);
  static const darkSurfaceVariant = Color(0xFF25262E);
  static const darkTextPrimary = Color(0xFFF2EEE6);
  static const darkTextSecondary = Color(0xFFA8A49B);
  static const darkTextHint = Color(0xFF6E6A63);

  // Black (AMOLED) const values
  static const blackBackground = Color(0xFF000000);
  static const blackSurface = Color(0xFF111216);
  static const blackSurfaceVariant = Color(0xFF1A1B20);

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
