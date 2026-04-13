import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _key = 'currency_symbol_overrides';

/// Lets users override the display symbol for any currency.
/// e.g. 'LBP' → 'LBP' instead of the default 'ل.ل'
class CurrencySymbolNotifier extends Notifier<Map<String, String>> {
  @override
  Map<String, String> build() {
    _load();
    return {};
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json != null) {
      try {
        final map = (jsonDecode(json) as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, v as String));
        state = map;
      } catch (e) {
        debugPrint('Failed to load currency_symbol prefs: $e');
      }
    }
  }

  Future<void> setOverride(String currencyCode, String symbol) async {
    final updated = {...state, currencyCode: symbol};
    state = updated;
    await _save(updated);
  }

  Future<void> removeOverride(String currencyCode) async {
    final updated = {...state}..remove(currencyCode);
    state = updated;
    await _save(updated);
  }

  Future<void> _save(Map<String, String> overrides) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(overrides));
  }
}

final currencySymbolProvider =
    NotifierProvider<CurrencySymbolNotifier, Map<String, String>>(
        CurrencySymbolNotifier.new);
