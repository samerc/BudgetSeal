import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/theme/app_colors.dart';

const _key = 'accent_color';

/// Accent color options: 'system' for Material You dynamic color,
/// or a hex string like '#2563EB' for a fixed color.
final accentColorProvider =
    NotifierProvider<AccentColorNotifier, String>(AccentColorNotifier.new);

class AccentColorNotifier extends Notifier<String> {
  @override
  String build() {
    _load();
    return 'default'; // Royal Blue (#2563EB)
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.getString(_key);
      if (val != null) state = val;
    } catch (_) {}
  }

  Future<void> setColor(String value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, value);
  }

  /// Whether this is the Material You dynamic system color.
  bool get isSystem => state == 'system';

  /// Resolve the accent color. If 'system', returns null (caller uses dynamic).
  /// If 'default', returns the built-in Royal Blue.
  /// Otherwise, parses the hex string.
  Color? resolve() {
    if (state == 'system') return null;
    if (state == 'default') return AppColors.accent;
    return AppColors.fromHex(state);
  }
}

/// Predefined accent color options for the picker.
const accentColorOptions = <String, String>{
  'default': '#2563EB', // Royal Blue
  '#6366F1': '#6366F1', // Indigo
  '#8B5CF6': '#8B5CF6', // Violet
  '#EC4899': '#EC4899', // Pink
  '#EF4444': '#EF4444', // Red
  '#F97316': '#F97316', // Orange
  '#EAB308': '#EAB308', // Yellow
  '#22C55E': '#22C55E', // Green
  '#14B8A6': '#14B8A6', // Teal
  '#06B6D4': '#06B6D4', // Cyan
};
