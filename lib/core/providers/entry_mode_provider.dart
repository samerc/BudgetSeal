import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _key = 'entry_mode';

/// 'one' = one-screen add (default), 'assisted' = step-by-step wizard,
/// 'classic' = single form
final entryModeProvider =
    NotifierProvider<EntryModeNotifier, String>(EntryModeNotifier.new);

class EntryModeNotifier extends Notifier<String> {
  @override
  String build() {
    _load();
    return 'one';
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = prefs.getString(_key) ?? 'one';
    } catch (_) {}
  }

  Future<void> setMode(String mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode);
  }
}
