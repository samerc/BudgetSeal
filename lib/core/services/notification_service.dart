import 'package:drift/drift.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/app_database.dart';
import '../database/daos/allocations_dao.dart';
import '../database/daos/ledger_dao.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'pocketplan_alerts';
  static const _channelName = 'PocketPlan Alerts';
  static const _channelDesc = 'Low envelope and upcoming bill alerts';

  static const _envelopeNotifId = 1001;
  static const _billNotifId = 1002;

  static const _cooldownKey = 'notif_last_check';
  static const _cooldownHours = 6;

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
    );
  }

  /// Check if enough time has passed since the last notification check.
  static Future<bool> _shouldCheck() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCheck = prefs.getString(_cooldownKey);
    if (lastCheck != null) {
      final last = DateTime.tryParse(lastCheck);
      if (last != null &&
          DateTime.now().difference(last).inHours < _cooldownHours) {
        return false;
      }
    }
    await prefs.setString(_cooldownKey, DateTime.now().toIso8601String());
    return true;
  }

  /// Check all envelopes and show a single grouped notification if any are overspent.
  static Future<void> checkEnvelopes(
      AppDatabase db, String householdId) async {
    if (!await _shouldCheck()) return;

    final dao = AllocationsDao(db);
    final ledgerDao = LedgerDao(db);

    final allocations = await dao.watchAll(householdId).first;
    final overspent = <String>[];

    for (final awc in allocations) {
      final balances =
          await ledgerDao.getBalanceByCurrency(awc.allocation.id);
      final total = balances.values.fold(0.0, (a, b) => a + b);
      if (total < 0) {
        overspent.add(awc.allocation.name);
      }
    }

    if (overspent.isEmpty) return;

    final body = overspent.length == 1
        ? '${overspent.first} is overspent. Consider adding funds.'
        : '${overspent.length} envelopes are overspent: ${overspent.take(3).join(', ')}${overspent.length > 3 ? ' and ${overspent.length - 3} more' : ''}.';

    await _plugin.show(
      id: _envelopeNotifId,
      title: 'Low Envelopes',
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  /// Check upcoming bills and show a single grouped notification.
  static Future<void> checkRecurring(
      AppDatabase db, String householdId) async {
    final now = DateTime.now();
    final cutoff = now.add(const Duration(days: 2));

    final rows = await (db.select(db.recurringTransactions)
          ..where((t) => t.householdId.equals(householdId))
          ..where((t) => t.enabled.equals(true))
          ..where((t) => t.nextDueDate.isSmallerOrEqualValue(cutoff)))
        .get();

    if (rows.isEmpty) return;

    final titles = rows
        .map((r) => r.title.isNotEmpty ? r.title : r.type)
        .toList();

    final body = titles.length == 1
        ? '${titles.first} is due soon.'
        : '${titles.length} bills due: ${titles.take(3).join(', ')}${titles.length > 3 ? ' and more' : ''}.';

    await _plugin.show(
      id: _billNotifId,
      title: 'Upcoming Bills',
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}
