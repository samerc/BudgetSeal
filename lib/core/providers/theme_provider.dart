import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _key = 'theme_mode';

/// Supported theme modes: system, light, dark, black (AMOLED).
/// 'black' uses Flutter's dark Brightness but with pure black scaffolding.
final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, String>(ThemeModeNotifier.new);

class ThemeModeNotifier extends Notifier<String> {
  @override
  String build() {
    _load();
    return 'system';
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.getString(_key);
      if (val == 'light' || val == 'dark' || val == 'black' || val == 'system') {
        state = val!;
      } else {
        state = 'system';
      }
    } catch (_) {}
  }

  Future<void> setMode(String mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode);
  }

  /// Convert to Flutter's ThemeMode (black maps to dark).
  ThemeMode get flutterThemeMode => switch (state) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        'black' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  /// Whether the current mode is the AMOLED black variant.
  bool get isBlackMode => state == 'black';
}
