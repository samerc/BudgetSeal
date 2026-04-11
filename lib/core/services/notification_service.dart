import 'package:drift/drift.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../database/app_database.dart';
import '../database/daos/allocations_dao.dart';
import '../database/daos/ledger_dao.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'pocketplan_alerts';
  static const _channelName = 'PocketPlan Alerts';
  static const _channelDesc = 'Low envelope and upcoming bill alerts';

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
    );
  }

  static Future<void> showLowEnvelope(String name, double balance) async {
    final id = name.hashCode & 0x7FFFFFFF;
    await _plugin.show(
      id: id,
      title: 'Low Envelope: $name',
      body: '$name balance is \$${balance.toStringAsFixed(2)}. Consider adding funds.',
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

  static Future<void> showUpcomingBill(String title, DateTime dueDate) async {
    final id = '$title${dueDate.toIso8601String()}'.hashCode & 0x7FFFFFFF;
    final daysUntil = dueDate.difference(DateTime.now()).inDays;
    final urgency = daysUntil <= 0
        ? 'due today'
        : 'due in $daysUntil day${daysUntil == 1 ? '' : 's'}';

    await _plugin.show(
      id: id,
      title: 'Upcoming: $title',
      body: '$title is $urgency.',
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

  static Future<void> checkEnvelopes(
      AppDatabase db, String householdId) async {
    final dao = AllocationsDao(db);
    final ledgerDao = LedgerDao(db);

    final allocations = await dao.watchAll(householdId).first;
    for (final awc in allocations) {
      final balances =
          await ledgerDao.getBalanceByCurrency(awc.allocation.id);
      final total = balances.values.fold(0.0, (a, b) => a + b);
      if (total < 0) {
        await showLowEnvelope(awc.allocation.name, total);
      }
    }
  }

  static Future<void> checkRecurring(
      AppDatabase db, String householdId) async {
    final now = DateTime.now();
    final cutoff = now.add(const Duration(days: 2));

    final rows = await (db.select(db.recurringTransactions)
          ..where((t) => t.householdId.equals(householdId))
          ..where((t) => t.enabled.equals(true))
          ..where((t) => t.nextDueDate.isSmallerOrEqualValue(cutoff)))
        .get();

    for (final r in rows) {
      final title =
          r.title.isNotEmpty ? r.title : '${r.type} (${r.currency})';
      await showUpcomingBill(title, r.nextDueDate);
    }
  }
}
