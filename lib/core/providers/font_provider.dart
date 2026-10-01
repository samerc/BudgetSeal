import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _key = 'app_font';

/// Default font for new installs — closest free match to Cashew's Avenir.
const defaultAppFont = 'Nunito Sans';

/// Available font families.
const appFonts = <String, String>{
  'Nunito Sans': 'Nunito Sans',
  'Plus Jakarta Sans': 'Plus Jakarta Sans',
  'DM Sans': 'DM Sans',
  'Inter': 'Inter',
  'Poppins': 'Poppins',
  'Nunito': 'Nunito',
  'Rubik': 'Rubik',
  'Space Grotesk': 'Space Grotesk',
};

/// Optical size correction per font. Fonts with a small x-height (Nunito
/// Sans) read smaller than others at the same point size, so their text is
/// scaled up to match the visual size of Cashew's Avenir. Applied globally in
/// app.dart on top of the user's Text Size preference.
double fontOpticalScale(String fontName) => switch (fontName) {
      'Nunito Sans' || 'Nunito' => 1.1,
      _ => 1.0,
    };

final fontProvider =
    NotifierProvider<FontNotifier, String>(FontNotifier.new);

class FontNotifier extends Notifier<String> {
  @override
  String build() {
    _load();
    return defaultAppFont;
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.getString(_key);
      if (val != null && appFonts.containsKey(val)) {
        state = val;
      }
    } catch (_) {}
  }

  Future<void> setFont(String font) async {
    state = font;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, font);
  }
}

/// Build a TextTheme from the selected font name.
TextTheme buildTextTheme(String fontName, [Brightness brightness = Brightness.light]) {
  final base = brightness == Brightness.dark
      ? ThemeData.dark().textTheme
      : ThemeData.light().textTheme;

  return switch (fontName) {
    'Plus Jakarta Sans' => GoogleFonts.plusJakartaSansTextTheme(base),
    'Inter' => GoogleFonts.interTextTheme(base),
    'Poppins' => GoogleFonts.poppinsTextTheme(base),
    'Nunito Sans' => GoogleFonts.nunitoSansTextTheme(base),
    'Nunito' => GoogleFonts.nunitoTextTheme(base),
    'Rubik' => GoogleFonts.rubikTextTheme(base),
    'DM Sans' => GoogleFonts.dmSansTextTheme(base),
    'Space Grotesk' => GoogleFonts.spaceGroteskTextTheme(base),
    _ => GoogleFonts.nunitoSansTextTheme(base),
  };
}

/// Get a TextStyle from the selected font.
TextStyle fontStyle(String fontName, {
  double? fontSize,
  FontWeight? fontWeight,
  Color? color,
}) {
  return switch (fontName) {
    'Plus Jakarta Sans' => GoogleFonts.plusJakartaSans(fontSize: fontSize, fontWeight: fontWeight, color: color),
    'Inter' => GoogleFonts.inter(fontSize: fontSize, fontWeight: fontWeight, color: color),
    'Poppins' => GoogleFonts.poppins(fontSize: fontSize, fontWeight: fontWeight, color: color),
    'Nunito Sans' => GoogleFonts.nunitoSans(fontSize: fontSize, fontWeight: fontWeight, color: color),
    'Nunito' => GoogleFonts.nunito(fontSize: fontSize, fontWeight: fontWeight, color: color),
    'Rubik' => GoogleFonts.rubik(fontSize: fontSize, fontWeight: fontWeight, color: color),
    'DM Sans' => GoogleFonts.dmSans(fontSize: fontSize, fontWeight: fontWeight, color: color),
    'Space Grotesk' => GoogleFonts.spaceGrotesk(fontSize: fontSize, fontWeight: fontWeight, color: color),
    _ => GoogleFonts.nunitoSans(fontSize: fontSize, fontWeight: fontWeight, color: color),
  };
}
