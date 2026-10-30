import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _key = 'hide_amounts';

/// Hide amounts: every amount reads "$•••" (showing the app to someone,
/// a screenshot). This phone only; app.dart passes it to the formatter.
final hideAmountsProvider =
    NotifierProvider<HideAmountsNotifier, bool>(HideAmountsNotifier.new);

class HideAmountsNotifier extends Notifier<bool> {
  @override
  bool build() {
    _load();
    return false;
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
