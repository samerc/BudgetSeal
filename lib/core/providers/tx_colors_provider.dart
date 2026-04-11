import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _key = 'tx_colors';

class TxColors {
  final Color income;
  final Color expense;
  final Color transfer;

  const TxColors({
    this.income = const Color(0xFF10B981),
    this.expense = const Color(0xFFEF4444),
    this.transfer = const Color(0xFF6366F1),
  });

  Color forType(String type) => switch (type) {
        'income' => income,
        'expense' => expense,
        'transfer' => transfer,
        _ => transfer,
      };

  Map<String, int> toJson() => {
        'income': income.toARGB32(),
        'expense': expense.toARGB32(),
        'transfer': transfer.toARGB32(),
      };

  factory TxColors.fromJson(Map<String, dynamic> json) => TxColors(
        income: Color(json['income'] as int),
        expense: Color(json['expense'] as int),
        transfer: Color(json['transfer'] as int),
      );
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
      } catch (_) {}
    }
  }

  Future<void> update(TxColors colors) async {
    state = colors;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(colors.toJson()));
  }
}
