import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _key = 'tx_list_settings';

/// Settings that control the transaction list appearance.
class TxListSettings {
  /// Compact = single line (name + amount). Expanded = multi-line (+ note + account).
  final bool compact;

  /// Show account label on each transaction row.
  final bool showAccount;

  /// Show category icon circle.
  final bool showCategoryIcon;

  /// Show transaction time alongside date.
  final bool showTime;

  /// What to display in the date group header total.
  /// 'dayTotal' | 'none'
  final String dateBannerTotal;

  const TxListSettings({
    this.compact = false,
    this.showAccount = false,
    this.showCategoryIcon = true,
    this.showTime = false,
    this.dateBannerTotal = 'dayTotal',
  });

  TxListSettings copyWith({
    bool? compact,
    bool? showAccount,
    bool? showCategoryIcon,
    bool? showTime,
    String? dateBannerTotal,
  }) =>
      TxListSettings(
        compact: compact ?? this.compact,
        showAccount: showAccount ?? this.showAccount,
        showCategoryIcon: showCategoryIcon ?? this.showCategoryIcon,
        showTime: showTime ?? this.showTime,
        dateBannerTotal: dateBannerTotal ?? this.dateBannerTotal,
      );

  Map<String, dynamic> toJson() => {
        'compact': compact,
        'showAccount': showAccount,
        'showCategoryIcon': showCategoryIcon,
        'showTime': showTime,
        'dateBannerTotal': dateBannerTotal,
      };

  factory TxListSettings.fromJson(Map<String, dynamic> j) => TxListSettings(
        compact: j['compact'] as bool? ?? false,
        showAccount: j['showAccount'] as bool? ?? false,
        showCategoryIcon: j['showCategoryIcon'] as bool? ?? true,
        showTime: j['showTime'] as bool? ?? false,
        dateBannerTotal: j['dateBannerTotal'] as String? ?? 'dayTotal',
      );
}

class TxListSettingsNotifier extends Notifier<TxListSettings> {
  @override
  TxListSettings build() {
    _load();
    return const TxListSettings();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) {
        state = TxListSettings.fromJson(
            jsonDecode(raw) as Map<String, dynamic>);
      }
    } catch (_) {}
  }

  Future<void> update(TxListSettings Function(TxListSettings) fn) async {
    state = fn(state);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(state.toJson()));
  }
}

final txListSettingsProvider =
    NotifierProvider<TxListSettingsNotifier, TxListSettings>(
        TxListSettingsNotifier.new);
