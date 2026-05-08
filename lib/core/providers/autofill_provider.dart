import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Which fields to auto-fill from the last transaction with the same category
/// or same title (Associated Titles).
class AutofillSettings {
  final bool account;
  final bool title;
  final bool amount;
  final bool category;
  final bool overrideExisting;

  const AutofillSettings({
    this.account = true,
    this.title = true,
    this.amount = false,
    this.category = true,
    this.overrideExisting = false,
  });

  AutofillSettings copyWith({
    bool? account,
    bool? title,
    bool? amount,
    bool? category,
    bool? overrideExisting,
  }) =>
      AutofillSettings(
        account: account ?? this.account,
        title: title ?? this.title,
        amount: amount ?? this.amount,
        category: category ?? this.category,
        overrideExisting: overrideExisting ?? this.overrideExisting,
      );

  Map<String, dynamic> toJson() => {
        'account': account,
        'title': title,
        'amount': amount,
        'category': category,
        'overrideExisting': overrideExisting,
      };

  factory AutofillSettings.fromJson(Map<String, dynamic> json) =>
      AutofillSettings(
        account: json['account'] as bool? ?? true,
        title: json['title'] as bool? ?? true,
        amount: json['amount'] as bool? ?? false,
        category: json['category'] as bool? ?? true,
        overrideExisting: json['overrideExisting'] as bool? ?? false,
      );
}

const _key = 'autofill_settings';

class AutofillNotifier extends Notifier<AutofillSettings> {
  @override
  AutofillSettings build() {
    _load();
    return const AutofillSettings();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json != null) {
      try {
        state = AutofillSettings.fromJson(
            jsonDecode(json) as Map<String, dynamic>);
      } catch (_) {}
    }
  }

  Future<void> update(AutofillSettings settings) async {
    state = settings;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(settings.toJson()));
  }
}

final autofillProvider =
    NotifierProvider<AutofillNotifier, AutofillSettings>(AutofillNotifier.new);
