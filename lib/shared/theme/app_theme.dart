import 'package:flutter/material.dart';

import '../../core/providers/font_provider.dart';
import 'app_colors.dart';
import 'design_tokens.dart';

/// Build the light theme. [accentColor] is the mode's accent (a pair's deep
/// tone); [accentFill] its soft fill (nav indicator, tonal buttons).
ThemeData buildLightTheme(String fontName,
        [Color? accentColor, Color? accentFill]) =>
    _buildTheme(fontName, accentColor ?? AppColors.accent, _Variant.light,
        accentFill);

/// Build the dark theme ([accentColor]: a pair's bright tone).
ThemeData buildDarkTheme(String fontName,
        [Color? accentColor, Color? accentFill]) =>
    _buildTheme(fontName, accentColor ?? AppColors.accent, _Variant.dark,
        accentFill);

/// Build the black (AMOLED) theme — dark with a pure black background.
ThemeData buildBlackTheme(String fontName,
        [Color? accentColor, Color? accentFill]) =>
    _buildTheme(fontName, accentColor ?? AppColors.accent, _Variant.black,
        accentFill);

enum _Variant { light, dark, black }

/// Single theme builder. BudgetSeal surfaces are warm neutrals (paper in
/// light, night in dark) — the accent lives in fills, text and the brand
/// banner, not in a tint over every surface.
ThemeData _buildTheme(String fontName, Color accent, _Variant v,
    [Color? accentFill]) {
  final isLight = v == _Variant.light;
  final brightness = isLight ? Brightness.light : Brightness.dark;
  final textTheme = buildTextTheme(fontName, brightness);
  TextStyle fs(double? sz, FontWeight? fw, Color? c) =>
      fontStyle(fontName, fontSize: sz, fontWeight: fw, color: c);

  // Seed scheme for the secondary/tertiary roles Material widgets use.
  final seed = ColorScheme.fromSeed(seedColor: accent, brightness: brightness);

  final light = AppColors.lightenPastel;
  final dark = AppColors.darkenPastel;

  final surfaces = switch (v) {
    _Variant.light => const SurfaceColors(
        bg: AppColors.background,
        card: AppColors.surface,
        container: AppColors.surfaceVariant,
        popup: Color(0xFFFBFAF7),
        nav: AppColors.surface,
        border: Color(0x0F000000),
        cardBorder: Colors.transparent,
        cardShadow: [
          BoxShadow(color: Color(0x143C2D0A), blurRadius: 18, spreadRadius: 2),
        ],
      ),
    _Variant.dark => const SurfaceColors(
        bg: AppColors.darkBackground,
        card: AppColors.darkSurface,
        container: AppColors.darkSurfaceVariant,
        popup: Color(0xFF22232B),
        nav: Color(0xFF18191F),
        border: Color(0x13FFFFFF),
        cardBorder: Colors.transparent,
        cardShadow: [],
      ),
    _Variant.black => SurfaceColors(
        bg: AppColors.blackBackground,
        card: AppColors.blackSurface,
        container: AppColors.blackSurfaceVariant,
        popup: const Color(0xFF17181D),
        nav: const Color(0xFF0A0A0C),
        border: const Color(0x13FFFFFF),
        cardBorder: Colors.white.withValues(alpha: 0.08),
        cardShadow: const [],
      ),
  };
  final onAccent = AppColors.inkOn(accent);

  final textPrimary =
      isLight ? AppColors.textPrimary : AppColors.darkTextPrimary;
  final textSecondary =
      isLight ? AppColors.textSecondary : AppColors.darkTextSecondary;
  final textHint = isLight ? AppColors.textHint : AppColors.darkTextHint;

  // Tonal button fill and nav indicator: soft versions of the accent.
  final indicator =
      accentFill ?? (isLight ? light(accent, 0.6) : dark(accent, 0.6));
  final splash = isLight
      ? dark(light(accent, 0.8), 0.2).withValues(alpha: 0.5)
      : dark(light(accent, 0.86), 0.1).withValues(alpha: 0.2);

  final colorScheme = seed.copyWith(
    primary: accent,
    onPrimary: onAccent,
    surface: surfaces.card,
    error: AppColors.overspent,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    extensions: [surfaces],
    scaffoldBackgroundColor: surfaces.bg,
    canvasColor: surfaces.bg,
    splashColor: splash,
    highlightColor: Colors.transparent,
    appBarTheme: AppBarTheme(
      backgroundColor: surfaces.bg,
      foregroundColor: textPrimary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: fs(20, FontWeight.w700, textPrimary),
    ),
    cardTheme: CardThemeData(
      color: surfaces.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CardTokens.radius),
        side: surfaces.cardBorder == Colors.transparent
            ? BorderSide.none
            : BorderSide(color: surfaces.cardBorder),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
    ),
    // Cashew TextInput: filled, borderless in every state, radius 15.
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaces.container,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(RadiusTokens.input),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(RadiusTokens.input),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(RadiusTokens.input),
        borderSide: BorderSide.none,
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(RadiusTokens.input),
        borderSide: const BorderSide(color: AppColors.overspent, width: 1.5),
      ),
      contentPadding: const EdgeInsetsDirectional.fromSTEB(18, 14, 12, 14),
      labelStyle: fs(null, null, textSecondary),
      hintStyle: fs(null, null, textHint),
    ),
    textSelectionTheme: TextSelectionThemeData(cursorColor: accent),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: onAccent,
        minimumSize: const Size.fromHeight(52),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RadiusTokens.button)),
        elevation: 0,
        textStyle: fs(15, FontWeight.w700, null),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RadiusTokens.button)),
        // Transparent like before: many screens set their own foreground
        // (e.g. white on onboarding gradients), so no global fill here.
        side: BorderSide(color: accent.withValues(alpha: 0.4)),
        foregroundColor: accent,
        textStyle: fs(15, FontWeight.w700, null),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RadiusTokens.button)),
        textStyle: fs(14, FontWeight.w700, null),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: accent,
      foregroundColor: onAccent,
      elevation: 2,
      highlightElevation: 4,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.fab)),
    ),
    // Cashew openPopup: radius 25, tinted popup surface, dimmed barrier.
    dialogTheme: DialogThemeData(
      backgroundColor: surfaces.popup,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.dialog)),
      titleTextStyle: fs(21, FontWeight.w700, textPrimary),
      contentTextStyle: fs(15.5, FontWeight.w400, textSecondary),
    ),
    // Cashew openBottomSheet: no drag handle, tinted, max width 650.
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: surfaces.popup,
      modalBackgroundColor: surfaces.popup,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      modalElevation: 0,
      showDragHandle: false,
      modalBarrierColor: Colors.black.withValues(alpha: 0.4),
      constraints: const BoxConstraints(maxWidth: 650),
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(RadiusTokens.sheet)),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: surfaces.popup,
      surfaceTintColor: Colors.transparent,
      elevation: 3,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.md)),
      textStyle: fs(15, FontWeight.w500, textPrimary),
    ),
    // Cashew openSnackbar: light popup surface, dark text, accent action.
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: surfaces.popup,
      elevation: 6,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.snackbar)),
      contentTextStyle: fs(15, FontWeight.w600, textPrimary),
      actionTextColor: accent,
      closeIconColor: textPrimary,
    ),
    // Cashew bottom nav: tinted bar, soft pastel pill, 13px labels.
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surfaces.nav,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 80,
      indicatorColor: indicator,
      indicatorShape: const StadiumBorder(),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => fs(
          13,
          states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w400,
          textPrimary,
        ),
      ),
      iconTheme: WidgetStatePropertyAll(IconThemeData(color: textPrimary)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: surfaces.container,
      side: BorderSide.none,
      shape: const StadiumBorder(),
      labelStyle: fs(13, FontWeight.w600, textPrimary),
    ),
    dividerTheme: DividerThemeData(
      color: surfaces.border,
      thickness: 1,
      space: 1,
    ),
    textTheme: textTheme.copyWith(
      displaySmall: fs(TypographyTokens.screenTitleSize,
              TypographyTokens.screenTitleWeight, textPrimary)
          .copyWith(fontFamily: TypographyTokens.displayFamily),
      titleLarge: fs(20, FontWeight.w700, textPrimary),
      titleMedium: fs(TypographyTokens.cardTitleSize,
          TypographyTokens.cardTitleWeight, textPrimary),
      bodyLarge: fs(TypographyTokens.bodySize, TypographyTokens.bodyWeight,
          textPrimary),
      bodyMedium: fs(TypographyTokens.bodySize, TypographyTokens.bodyWeight,
          textPrimary),
      bodySmall: fs(TypographyTokens.captionSize,
          TypographyTokens.captionWeight, textSecondary),
      labelSmall: fs(TypographyTokens.overlineSize,
          TypographyTokens.overlineWeight, textHint),
    ),
  );
}

// ── Keep old names as aliases for backward compatibility ─────────────────────
final appTheme = buildLightTheme('Nunito Sans');
final appDarkTheme = buildDarkTheme('Nunito Sans');
