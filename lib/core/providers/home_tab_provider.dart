import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _key = 'home_tab_index';

/// The tab names matching MainScreen's tab order.
const homeTabLabels = ['Home', 'Activity', 'Budget', 'Reports', 'More'];

class HomeTabNotifier extends Notifier<int> {
  @override
  int build() {
    _load();
    return 0;
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final idx = prefs.getInt(_key) ?? 0;
      if (idx != state && idx >= 0 && idx < homeTabLabels.length) {
        state = idx;
      }
    } catch (_) {}
  }

  Future<void> set(int index) async {
    if (index < 0 || index >= homeTabLabels.length) return;
    state = index;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, index);
  }
}

final homeTabProvider = NotifierProvider<HomeTabNotifier, int>(HomeTabNotifier.new);
