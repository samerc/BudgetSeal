import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _key = 'app_font';

/// Available font families.
const appFonts = <String, String>{
  'DM Sans': 'DM Sans',
  'Inter': 'Inter',
  'Poppins': 'Poppins',
  'Nunito': 'Nunito',
  'Rubik': 'Rubik',
  'Space Grotesk': 'Space Grotesk',
};

final fontProvider =
    NotifierProvider<FontNotifier, String>(FontNotifier.new);

class FontNotifier extends Notifier<String> {
  @override
  String build() {
    _load();
    return 'Inter';
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getString(_key);
    if (val != null && appFonts.containsKey(val)) {
      state = val;
    }
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
    'Poppins' => GoogleFonts.poppinsTextTheme(base),
    'Nunito' => GoogleFonts.nunitoTextTheme(base),
    'Rubik' => GoogleFonts.rubikTextTheme(base),
    'DM Sans' => GoogleFonts.dmSansTextTheme(base),
    'Space Grotesk' => GoogleFonts.spaceGroteskTextTheme(base),
    _ => GoogleFonts.interTextTheme(base),
  };
}

/// Get a TextStyle from the selected font.
TextStyle fontStyle(String fontName, {
  double? fontSize,
  FontWeight? fontWeight,
  Color? color,
}) {
  return switch (fontName) {
    'Poppins' => GoogleFonts.poppins(fontSize: fontSize, fontWeight: fontWeight, color: color),
    'Nunito' => GoogleFonts.nunito(fontSize: fontSize, fontWeight: fontWeight, color: color),
    'Rubik' => GoogleFonts.rubik(fontSize: fontSize, fontWeight: fontWeight, color: color),
    'DM Sans' => GoogleFonts.dmSans(fontSize: fontSize, fontWeight: fontWeight, color: color),
    'Space Grotesk' => GoogleFonts.spaceGrotesk(fontSize: fontSize, fontWeight: fontWeight, color: color),
    _ => GoogleFonts.inter(fontSize: fontSize, fontWeight: fontWeight, color: color),
  };
}
