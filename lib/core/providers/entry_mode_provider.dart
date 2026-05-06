import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _key = 'entry_mode';

/// 'assisted' = step-by-step wizard, 'classic' = single-form
final entryModeProvider =
    NotifierProvider<EntryModeNotifier, String>(EntryModeNotifier.new);

class EntryModeNotifier extends Notifier<String> {
  @override
  String build() {
    _load();
    return 'assisted';
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = prefs.getString(_key) ?? 'assisted';
    } catch (_) {}
  }

  Future<void> setMode(String mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode);
  }
}
