import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _key = 'number_format_prefs';

enum ThousandsSeparator {
  comma(','),
  period('.'),
  space(' '),
  none('');

  final String char;
  const ThousandsSeparator(this.char);

  String get label => switch (this) {
        comma => 'Comma (1,000)',
        period => 'Period (1.000)',
        space => 'Space (1 000)',
        none => 'None (1000)',
      };
}

enum DecimalSeparator {
  period('.'),
  comma(',');

  final String char;
  const DecimalSeparator(this.char);

  String get label => switch (this) {
        period => 'Period (0.50)',
        comma => 'Comma (0,50)',
      };
}

enum NegativeFormat {
  minus,
  parentheses;

  String get label => switch (this) {
        minus => '-\$100',
        parentheses => '(\$100)',
      };
}

class NumberFormatPrefs {
  final ThousandsSeparator thousands;
  final DecimalSeparator decimal;
  final NegativeFormat negative;

  const NumberFormatPrefs({
    this.thousands = ThousandsSeparator.comma,
    this.decimal = DecimalSeparator.period,
    this.negative = NegativeFormat.minus,
  });

  Map<String, dynamic> toJson() => {
        'thousands': thousands.index,
        'decimal': decimal.index,
        'negative': negative.index,
      };

  factory NumberFormatPrefs.fromJson(Map<String, dynamic> json) {
    final tIdx = (json['thousands'] as int? ?? 0).clamp(0, ThousandsSeparator.values.length - 1);
    final dIdx = (json['decimal'] as int? ?? 0).clamp(0, DecimalSeparator.values.length - 1);
    final nIdx = (json['negative'] as int? ?? 0).clamp(0, NegativeFormat.values.length - 1);
    return NumberFormatPrefs(
      thousands: ThousandsSeparator.values[tIdx],
      decimal: DecimalSeparator.values[dIdx],
      negative: NegativeFormat.values[nIdx],
    );
  }
}

class NumberFormatNotifier extends Notifier<NumberFormatPrefs> {
  @override
  NumberFormatPrefs build() {
    _load();
    return const NumberFormatPrefs();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json != null) {
      try {
        state = NumberFormatPrefs.fromJson(
            jsonDecode(json) as Map<String, dynamic>);
      } catch (e) {
        debugPrint('Failed to load number_format prefs: $e');
      }
    }
  }

  Future<void> update(NumberFormatPrefs format) async {
    state = format;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(format.toJson()));
  }
}

final numberFormatProvider =
    NotifierProvider<NumberFormatNotifier, NumberFormatPrefs>(
        NumberFormatNotifier.new);
