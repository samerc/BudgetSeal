import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/theme/app_colors.dart';

const _key = 'tx_colors';

class TxColors {
  /// User-chosen colors; null means "use the theme-adaptive default".
  final Color? customIncome;
  final Color? customExpense;
  final Color? customTransfer;

  const TxColors({Color? income, Color? expense, Color? transfer})
      : customIncome = income,
        customExpense = expense,
        customTransfer = transfer;

  // Cashew's softened amount colors, brighter on dark surfaces.
  Color get income => customIncome ??
      (AppColors.isDark ? const Color(0xFF62CA77) : const Color(0xFF59A849));
  Color get expense => customExpense ??
      (AppColors.isDark ? const Color(0xFFDA7272) : const Color(0xFFCA5A5A));
  Color get transfer => customTransfer ??
      (AppColors.isDark ? const Color(0xFF8395FF) : const Color(0xFF6577E0));

  Color forType(String type) => switch (type) {
        'income' => income,
        'expense' => expense,
        'transfer' => transfer,
        _ => transfer,
      };

  Map<String, int> toJson() => {
        if (customIncome != null) 'income': customIncome!.toARGB32(),
        if (customExpense != null) 'expense': customExpense!.toARGB32(),
        if (customTransfer != null) 'transfer': customTransfer!.toARGB32(),
      };

  factory TxColors.fromJson(Map<String, dynamic> json) {
    Color? read(String k) {
      final v = json[k];
      if (v is! int) return null;
      // Colors saved before adaptive defaults existed: treat the old fixed
      // defaults as "not customized" so they pick up the new palette.
      if (_legacyDefaults.contains(v)) return null;
      return Color(v);
    }

    return TxColors(
      income: read('income'),
      expense: read('expense'),
      transfer: read('transfer'),
    );
  }

  static const _legacyDefaults = {0xFF10B981, 0xFFEF4444, 0xFF6366F1};
}

final txColorsProvider =
    NotifierProvider<TxColorsNotifier, TxColors>(TxColorsNotifier.new);

class TxColorsNotifier extends Notifier<TxColors> {
  @override
  TxColors build() {
    _load();
    return const TxColors();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json != null) {
      try {
        state = TxColors.fromJson(
            jsonDecode(json) as Map<String, dynamic>);
      } catch (e) {
        debugPrint('Failed to load tx_colors prefs: $e');
      }
    }
  }

  Future<void> update(TxColors colors) async {
    state = colors;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(colors.toJson()));
  }
}
