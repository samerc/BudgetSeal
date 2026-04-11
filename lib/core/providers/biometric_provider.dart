import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _key = 'biometric_lock_enabled';

final biometricLockProvider =
    NotifierProvider<BiometricNotifier, bool>(BiometricNotifier.new);

class BiometricNotifier extends Notifier<bool> {
  @override
  bool build() {
    _load();
    return false;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_key) ?? false;
  }

  Future<void> enable() async {
    state = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }

  Future<void> disable() async {
    state = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, false);
  }
}
