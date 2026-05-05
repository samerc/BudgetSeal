/// Design tokens for PocketPlan's visual consistency system.
/// All spacing uses a 4-point grid. All cards share one style.
library;

import 'package:flutter/material.dart';

// ── Spacing scale (multiples of 4) ──────────────────────────────────────────
abstract final class Spacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;

  /// Between sections (e.g. card groups on a screen).
  static const double sectionGap = lg;

  /// Between a section header and its first card.
  static const double headerToCard = sm;
}

// ── Card tokens ─────────────────────────────────────────────────────────────
abstract final class CardTokens {
  static const double radius = 14;
  static const double paddingH = 16;
  static const double paddingV = 14;
  static const EdgeInsets padding =
      EdgeInsets.symmetric(horizontal: paddingH, vertical: paddingV);
  static final BorderRadius borderRadius =
      BorderRadius.circular(radius);
}

// ── Typography roles ────────────────────────────────────────────────────────
/// Use these with fontStyle() from font_provider.dart for consistent text.
abstract final class TypographyTokens {
  // Screen title: 24 / w800
  static const double screenTitleSize = 24;
  static const FontWeight screenTitleWeight = FontWeight.w800;

  // Section header: 13 / w700 / letterSpacing 0.8
  static const double sectionHeaderSize = 13;
  static const FontWeight sectionHeaderWeight = FontWeight.w700;
  static const double sectionHeaderLetterSpacing = 0.8;

  // Card title: 15 / w600
  static const double cardTitleSize = 15;
  static const FontWeight cardTitleWeight = FontWeight.w600;

  // Amount large: 22 / w700
  static const double amountLargeSize = 22;
  static const FontWeight amountLargeWeight = FontWeight.w700;

  // Amount regular: 15 / w700
  static const double amountRegularSize = 15;
  static const FontWeight amountRegularWeight = FontWeight.w700;

  // Amount small: 13 / w600
  static const double amountSmallSize = 13;
  static const FontWeight amountSmallWeight = FontWeight.w600;

  // Body: 14 / w400
  static const double bodySize = 14;
  static const FontWeight bodyWeight = FontWeight.w400;

  // Caption: 12 / w500
  static const double captionSize = 12;
  static const FontWeight captionWeight = FontWeight.w500;

  // Overline: 11 / w600
  static const double overlineSize = 11;
  static const FontWeight overlineWeight = FontWeight.w600;
}
