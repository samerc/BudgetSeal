import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'text_reader.dart';

/// A notification kept from a bank app, waiting in "To review".
class AlertItem {
  final String id;
  final String app;
  final String appName;
  final String title;
  final String text;
  final DateTime at;

  const AlertItem({
    required this.id,
    required this.app,
    required this.appName,
    required this.title,
    required this.text,
    required this.at,
  });

  /// What the reader reads: the title, then the text.
  String get fullText => [title, text].where((t) => t.isNotEmpty).join('\n');

  Map<String, Object?> toJson() => {
        'id': id,
        'app': app,
        'appName': appName,
        'title': title,
        'text': text,
        'at': at.millisecondsSinceEpoch,
      };

  factory AlertItem.fromJson(Map<String, dynamic> m) => AlertItem(
        id: m['id'] as String,
        app: m['app'] as String,
        appName: m['appName'] as String? ?? m['app'] as String,
        title: m['title'] as String? ?? '',
        text: m['text'] as String? ?? '',
        at: DateTime.fromMillisecondsSinceEpoch((m['at'] as num).toInt()),
      );
}

/// Bank alerts (roadmap #2, Android): `AlertListener.kt` keeps the
/// notifications of the apps the user picked; [collect] moves them into
/// the "To review" inbox (kept on this phone only — not synced: they are
/// this phone's notifications). Nothing is recorded until the user adds
/// one (user's decision: an inbox to confirm).
class BankAlerts {
  static const _channel = MethodChannel('budgetseal/alerts');
  static const _inboxKey = 'capture_inbox';
  static const _indexKey = 'alert_amount_index';

  static bool get supported => !kIsWeb && Platform.isAndroid;

  /// Whether access is on, the apps seen so far (package → name; no
  /// content), and the ones picked.
  static Future<({bool enabled, Map<String, String> seen, List<String> apps})>
      status() async {
    final m = await _channel.invokeMapMethod<String, Object?>('status') ?? {};
    return (
      enabled: m['enabled'] == true,
      seen: {
        for (final e in (m['seen'] as Map? ?? const {}).entries)
          e.key as String: e.value as String,
      },
      apps: [for (final a in m['apps'] as List? ?? const []) a as String],
    );
  }

  static Future<void> setApps(List<String> apps) =>
      _channel.invokeMethod('setApps', apps);

  static Future<void> openSettings() => _channel.invokeMethod('openSettings');

  /// Moves what the listener kept into the inbox. Returns how many arrived.
  static Future<int> collect() async {
    if (!supported) return 0;
    try {
      final raw = await _channel.invokeMethod<String>('take') ?? '[]';
      final incoming = [
        for (final m in (jsonDecode(raw) as List).cast<Map<String, dynamic>>())
          AlertItem.fromJson(m),
      ];
      if (incoming.isEmpty) return 0;
      final items = await inbox();
      final ids = {for (final i in items) i.id};
      final added = [for (final i in incoming) if (ids.add(i.id)) i];
      await _save([...items, ...added]);
      return added.length;
    } catch (e) {
      debugPrint('[BankAlerts] Collect failed: $e');
      return 0;
    }
  }

  /// The inbox, newest first.
  static Future<List<AlertItem>> inbox() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final list = [
        for (final m in (jsonDecode(prefs.getString(_inboxKey) ?? '[]') as List)
            .cast<Map<String, dynamic>>())
          AlertItem.fromJson(m),
      ]..sort((a, b) => b.at.compareTo(a.at));
      return list;
    } catch (e) {
      debugPrint('[BankAlerts] Inbox unreadable: $e');
      return [];
    }
  }

  static Future<void> _save(List<AlertItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _inboxKey, jsonEncode([for (final i in items) i.toJson()]));
  }

  static Future<void> remove(String id) async =>
      _save([for (final i in await inbox()) if (i.id != id) i]);

  static Future<void> restore(AlertItem item) async {
    final items = await inbox();
    if (items.any((i) => i.id == item.id)) return;
    await _save([...items, item]);
  }

  /// Which of the amounts in [app]'s messages is the payment (learned).
  static Future<int> amountIndex(String app) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final m = jsonDecode(prefs.getString(_indexKey) ?? '{}') as Map;
      return (m[app] as num?)?.toInt() ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// A payment from [app] read from [text] was saved as [amount]: when
  /// that's not the amount the reader took first but another one in the
  /// message, remember its place for this app (user's decision: learn from
  /// fixes, per bank).
  static Future<void> learnAmount(
      String app, String text, double amount) async {
    final amounts = capturedAmounts(text);
    final k = amounts.indexWhere((a) => (a.amount - amount).abs() < 0.005);
    if (k < 0) return;
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> m;
    try {
      m = (jsonDecode(prefs.getString(_indexKey) ?? '{}') as Map)
          .cast<String, dynamic>();
    } catch (_) {
      m = {};
    }
    if ((m[app] as num?)?.toInt() == k || (k == 0 && !m.containsKey(app))) {
      return;
    }
    m[app] = k;
    await prefs.setString(_indexKey, jsonEncode(m));
  }
}

/// The "To review" inbox; reading it first collects what's new.
final alertInboxProvider =
    AsyncNotifierProvider<AlertInbox, List<AlertItem>>(AlertInbox.new);

class AlertInbox extends AsyncNotifier<List<AlertItem>> {
  @override
  Future<List<AlertItem>> build() async {
    await BankAlerts.collect();
    return BankAlerts.inbox();
  }

  Future<void> dismiss(AlertItem item) async {
    await BankAlerts.remove(item.id);
    ref.invalidateSelf();
  }

  Future<void> undoDismiss(AlertItem item) async {
    await BankAlerts.restore(item);
    ref.invalidateSelf();
  }
}
