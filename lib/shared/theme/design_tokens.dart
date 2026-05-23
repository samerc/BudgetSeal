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
  static const double xxl = 32;

  /// Between sections (e.g. card groups on a screen).
  static const double sectionGap = lg;

  /// Between a section header and its first card.
  static const double headerToCard = sm;
}

// ── Card tokens ─────────────────────────────────────────────────────────────
abstract final class CardTokens {
  static const double radius = 16;
  static const double paddingH = 16;
  static const double paddingV = 14;
  static const EdgeInsets padding =
      EdgeInsets.symmetric(horizontal: paddingH, vertical: paddingV);
  static final BorderRadius borderRadius =
      BorderRadius.circular(radius);
}

// ── Border radius scale ─────────────────────────────────────────────────────
abstract final class RadiusTokens {
  /// Small elements: chips, badges, input fields
  static const double sm = 8;

  /// Medium elements: banners, inline containers, buttons
  static const double md = 12;

  /// Standard cards and sheets
  static const double lg = 16;

  /// Pill-shaped chips and toggle buttons
  static const double pill = 20;

  /// Bottom sheets and modals
  static const double sheet = 24;
}

// ── Animation durations ─────────────────────────────────────────────────────
abstract final class Durations {
  /// Quick feedback (tap, toggle)
  static const Duration fast = Duration(milliseconds: 150);

  /// Standard transitions (expand, fade)
  static const Duration standard = Duration(milliseconds: 250);

  /// Emphasized motion (page transitions, large reveals)
  static const Duration emphasis = Duration(milliseconds: 350);
}

// ── Category icon tokens ────────────────────────────────────────────────────
abstract final class CategoryIconTokens {
  /// Large circle used in transaction list rows and detail screens.
  static const double listSize = 48;

  /// Small circle used in compact displays (e.g. dashboard recent txs).
  static const double compactSize = 36;

  /// Hero size used in transaction entry / edit screens.
  static const double heroSize = 64;
}

// ── Typography roles ────────────────────────────────────────────────────────
/// Use these with fontStyle() from font_provider.dart for consistent text.
abstract final class TypographyTokens {
  // Screen title: 28 / w800 (Cashew-inspired: large bold)
  static const double screenTitleSize = 28;
  static const FontWeight screenTitleWeight = FontWeight.w800;

  // Section header: 13 / w700 / letterSpacing 0.8
  static const double sectionHeaderSize = 13;
  static const FontWeight sectionHeaderWeight = FontWeight.w700;
  static const double sectionHeaderLetterSpacing = 0.8;

  // Card title: 15 / w600
  static const double cardTitleSize = 15;
  static const FontWeight cardTitleWeight = FontWeight.w600;

  // Amount large: 24 / w700
  static const double amountLargeSize = 24;
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

  // Mini label: 10 / w500 — subtle secondary info (e.g., "/ $120" under amounts)
  static const double miniSize = 10;
  static const FontWeight miniWeight = FontWeight.w500;

  // Amount display: 18 / w800 — hero amounts on dashboard cards
  static const double amountDisplaySize = 18;
  static const FontWeight amountDisplayWeight = FontWeight.w800;

  // Transaction row title: 15 / w600
  static const double txTitleSize = 15;
  static const FontWeight txTitleWeight = FontWeight.w600;

  // Transaction row subtitle: 12 / w400
  static const double txSubtitleSize = 12;
  static const FontWeight txSubtitleWeight = FontWeight.w400;

  // Date group header: 14 / w600
  static const double dateHeaderSize = 14;
  static const FontWeight dateHeaderWeight = FontWeight.w600;
}

// ── Input validation limits ──────────────────────────────────────────────────
abstract final class InputLimits {
  /// Max characters for name/title fields (account, category, envelope, etc.)
  static const int nameMaxLength = 100;

  /// Max characters for note/description fields
  static const int noteMaxLength = 500;

  /// Max transaction/balance amount (1 billion)
  static const double maxAmount = 1e9;
}
