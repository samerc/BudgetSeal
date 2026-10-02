import 'package:flutter/material.dart';

/// One user-selectable accent color, tuned as a pair so it reads well in
/// every theme: [bright] for dark/black mode (and for filled brand surfaces —
/// the "Ready to assign" banner, the envelope seal — in every mode), [deep]
/// for text/icons/buttons in light mode, plus a soft fill per mode.
@immutable
class AccentPair {
  const AccentPair(
    this.id, {
    required this.bright,
    required this.deep,
    required this.lightFill,
    required this.darkFill,
  });

  /// Stored in SharedPreferences ('accent_color').
  final String id;
  final Color bright;
  final Color deep;
  final Color lightFill;
  final Color darkFill;

  Color accentFor(bool dark) => dark ? bright : deep;
  Color fillFor(bool dark) => dark ? darkFill : lightFill;
}

/// Ink drawn on [AccentPair.bright] fills — the bright tones are all light
/// enough that white text on them fails contrast.
const brandInk = Color(0xFF1A1508);

const defaultAccentId = 'gold';

/// The BudgetSeal palette (Gold is the brand default).
const brandPalette = <AccentPair>[
  AccentPair('gold',
      bright: Color(0xFFE3AD45),
      deep: Color(0xFF8A5E0F),
      lightFill: Color(0xFFF6E7C6),
      darkFill: Color(0xFF2F2A1E)),
  AccentPair('wax',
      bright: Color(0xFFEC8A7A),
      deep: Color(0xFFA2342A),
      lightFill: Color(0xFFF8DDD7),
      darkFill: Color(0xFF352220)),
  AccentPair('copper',
      bright: Color(0xFFEE9E62),
      deep: Color(0xFFA2501A),
      lightFill: Color(0xFFF9E3D0),
      darkFill: Color(0xFF34271D)),
  AccentPair('sage',
      bright: Color(0xFF93CC86),
      deep: Color(0xFF3D7A2F),
      lightFill: Color(0xFFDFEFD9),
      darkFill: Color(0xFF232E21)),
  AccentPair('teal',
      bright: Color(0xFF5CC7B6),
      deep: Color(0xFF0E6E66),
      lightFill: Color(0xFFD5EDE8),
      darkFill: Color(0xFF1C2F2C)),
  AccentPair('sapphire',
      bright: Color(0xFF86ABF5),
      deep: Color(0xFF2753B8),
      lightFill: Color(0xFFDDE7FB),
      darkFill: Color(0xFF1F2739)),
  AccentPair('plum',
      bright: Color(0xFFC79AEA),
      deep: Color(0xFF7339A6),
      lightFill: Color(0xFFECDEF7),
      darkFill: Color(0xFF2A2134)),
  AccentPair('rose',
      bright: Color(0xFFF294B4),
      deep: Color(0xFFA83463),
      lightFill: Color(0xFFF9DEE8),
      darkFill: Color(0xFF34212B)),
];

AccentPair? accentPairById(String id) {
  for (final p in brandPalette) {
    if (p.id == id) return p;
  }
  return null;
}

/// Closest palette entry to an arbitrary color (by hue) — migrates the old
/// single-hex accent setting to a pair.
AccentPair nearestAccentPair(Color c) {
  final hsl = HSLColor.fromColor(c);
  if (hsl.saturation < 0.15) return brandPalette.first;
  AccentPair best = brandPalette.first;
  var bestDist = double.infinity;
  for (final p in brandPalette) {
    final h = HSLColor.fromColor(p.deep).hue;
    final d = (hsl.hue - h).abs();
    final dist = d > 180 ? 360 - d : d;
    if (dist < bestDist) {
      bestDist = dist;
      best = p;
    }
  }
  return best;
}
