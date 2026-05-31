import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _key = 'use_arabic_digits';

/// Whether to display Arabic-Indic numerals (٠١٢٣٤٥٦٧٨٩) instead of
/// Western numerals (0123456789). Only relevant when locale is Arabic.
final arabicDigitsProvider =
    NotifierProvider<ArabicDigitsNotifier, bool>(ArabicDigitsNotifier.new);

class ArabicDigitsNotifier extends Notifier<bool> {
  @override
  bool build() {
    _load();
    return false; // default: Western numerals
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.getBool(_key);
      if (val != null) state = val;
    } catch (_) {}
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, state);
  }
}
