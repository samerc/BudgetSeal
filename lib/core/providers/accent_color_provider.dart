import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/theme/app_colors.dart';
import '../../shared/theme/brand_palette.dart';

const _key = 'accent_color';

/// Accent color setting: an [AccentPair] id from [brandPalette] (default
/// 'gold'), or 'system' for the Material You wallpaper color.
final accentColorProvider =
    NotifierProvider<AccentColorNotifier, String>(AccentColorNotifier.new);

class AccentColorNotifier extends Notifier<String> {
  @override
  String build() {
    _load();
    return defaultAccentId;
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.getString(_key);
      if (val == null) return;
      if (val == 'system' || accentPairById(val) != null) {
        state = val;
        return;
      }
      // Older versions stored 'default' (Royal Blue) or a hex color: move
      // to the closest palette pair.
      final legacy =
          val == 'default' ? const Color(0xFF2563EB) : AppColors.fromHex(val);
      state = nearestAccentPair(legacy).id;
      await prefs.setString(_key, state);
    } catch (_) {}
  }

  Future<void> setColor(String value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, value);
  }

  /// Whether this is the Material You dynamic system color.
  bool get isSystem => state == 'system';

  /// The selected pair, or null for 'system'.
  AccentPair? get pair =>
      isSystem ? null : (accentPairById(state) ?? brandPalette.first);
}
