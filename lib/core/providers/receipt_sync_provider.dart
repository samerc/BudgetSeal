import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefKey = 'sync_receipts_enabled';

class ReceiptSyncNotifier extends Notifier<bool> {
  @override
  bool build() {
    _load();
    return true; // default: enabled
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getBool(_prefKey) ?? true;
    state = value;
  }

  Future<void> enable() async {
    state = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, true);
  }

  Future<void> disable() async {
    state = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, false);
  }

  Future<void> toggle() async {
    if (state) {
      await disable();
    } else {
      await enable();
    }
  }
}

final receiptSyncProvider =
    NotifierProvider<ReceiptSyncNotifier, bool>(ReceiptSyncNotifier.new);
