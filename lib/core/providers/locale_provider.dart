import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _key = 'app_locale';

/// Supported locales: system (null), en, ar, fr.
final localeProvider =
    NotifierProvider<LocaleNotifier, String?>(LocaleNotifier.new);

class LocaleNotifier extends Notifier<String?> {
  @override
  String? build() {
    _load();
    return null; // system default
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.getString(_key);
      if (val == 'en' || val == 'ar' || val == 'fr') {
        state = val;
      }
    } catch (_) {}
  }

  Future<void> setLocale(String? locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(_key);
    } else {
      await prefs.setString(_key, locale);
    }
  }

  /// Resolve to a Flutter Locale, or null for system default.
  Locale? get resolvedLocale =>
      state != null ? Locale(state!) : null;
}
