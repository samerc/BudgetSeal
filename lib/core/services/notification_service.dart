import 'package:drift/drift.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/s_lookup.dart';
import '../database/app_database.dart';
import '../database/daos/allocations_dao.dart';
import '../database/daos/ledger_dao.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  /// Expose the plugin so DailyReminderService can share the same instance.
  static FlutterLocalNotificationsPlugin get plugin => _plugin;

  static const _channelId = 'budgetseal_alerts';
  static const _channelName = 'BudgetSeal Alerts';
  static const _channelDesc = 'Low envelope and upcoming bill alerts from BudgetSeal';

  static const _envelopeNotifId = 1001;
  static const _billNotifId = 1002;
  static const _budgetWarningNotifId = 1003;

  static const _envelopeCooldownKey = 'notif_last_check_envelopes';
  static const _billCooldownKey = 'notif_last_check_bills';
  static const _budgetWarningCooldownKey = 'notif_last_check_budget_warning';
  static const _cooldownHours = 24;

  /// Threshold at which a budget warning notification is sent (80%).
  static const _budgetWarningThreshold = 0.80;

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
    );
  }

  /// Check if enough time has passed since the last check for a given key.
  static Future<bool> _shouldCheck(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final lastCheck = prefs.getString(key);
    if (lastCheck != null) {
      final last = DateTime.tryParse(lastCheck);
      if (last != null &&
          DateTime.now().difference(last).inHours < _cooldownHours) {
        return false;
      }
    }
    await prefs.setString(key, DateTime.now().toIso8601String());
    return true;
  }

  /// Check all envelopes and show a single grouped notification if any are overspent.
  static Future<void> checkEnvelopes(
      AppDatabase db, String householdId) async {
    if (!await _shouldCheck(_envelopeCooldownKey)) return;

    final dao = AllocationsDao(db);
    final ledgerDao = LedgerDao(db);

    final allocations = await dao.watchAll(householdId).first;
    if (allocations.isEmpty) return;

    // Batch-fetch all balances in one query
    final allBalances = await ledgerDao.getAllBalances(
        allocations.map((a) => a.allocation.id).toList());

    final overspent = <String>[];
    for (final awc in allocations) {
      final balances = allBalances[awc.allocation.id] ?? {};
      final hasNegative = balances.values.any((v) => v < -0.01);
      if (hasNegative) {
        overspent.add(awc.allocation.name);
      }
    }

    if (overspent.isEmpty) return;

    final l = currentS();
    final body = overspent.length == 1
        ? l.notifSingleOverspent(overspent.first)
        : l.notifMultipleOverspent(
            overspent.length,
            overspent.take(3).join(', '),
            overspent.length > 3
                ? l.notifAndMore(overspent.length - 3)
                : '');

    await _plugin.show(
      id: _envelopeNotifId,
      title: l.notifLowEnvelopesTitle,
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

  /// Check envelopes approaching their budget limit and warn before overspending.
  ///
  /// Fires for spending envelopes at >= 80% of target but not yet overspent.
  /// Shows days remaining in the current period.
  static Future<void> checkBudgetWarnings(
      AppDatabase db, String householdId) async {
    if (!await _shouldCheck(_budgetWarningCooldownKey)) return;

    final dao = AllocationsDao(db);
    final ledgerDao = LedgerDao(db);

    final allocations = await dao.watchAll(householdId).first;
    if (allocations.isEmpty) return;

    // Fetch household to get period start day
    final household = await (db.select(db.households)
          ..where((h) => h.id.equals(householdId)))
        .getSingleOrNull();
    if (household == null) return;

    final periodStartDay = household.periodStartDay;
    final now = DateTime.now();

    // Compute next period start (= end of current period).
    // Clamp day to the actual days in the target month to avoid overflow
    // (e.g., periodStartDay=31 in February → clamp to 28).
    int targetYear = now.year;
    int targetMonth = now.day >= periodStartDay ? now.month + 1 : now.month;
    if (targetMonth > 12) { targetMonth = 1; targetYear++; }
    final daysInTarget = DateTime(targetYear, targetMonth + 1, 0).day;
    final clampedDay = periodStartDay > daysInTarget ? daysInTarget : periodStartDay;
    final nextPeriodStart = DateTime(targetYear, targetMonth, clampedDay);
    final daysLeft = nextPeriodStart.difference(now).inDays;
    if (daysLeft <= 0) return; // At or past period boundary — skip

    // Batch-fetch all balances
    final allBalances = await ledgerDao.getAllBalances(
        allocations.map((a) => a.allocation.id).toList());

    final warnings = <String>[];
    for (final awc in allocations) {
      final alloc = awc.allocation;
      // Only spending envelopes with a target
      if (alloc.type != 'spending' || alloc.archived) continue;
      final target = alloc.targetAmount;
      final targetCcy = alloc.targetCurrency;
      if (target == null || target <= 0 || targetCcy == null) continue;

      final balances = allBalances[alloc.id] ?? {};
      final balance = balances[targetCcy] ?? 0.0;

      // Skip already overspent (handled by checkEnvelopes)
      if (balance < -0.01) continue;

      // spent = target - remaining balance
      final spent = target - balance;
      if (spent <= 0) continue;

      final pct = spent / target;
      if (pct >= _budgetWarningThreshold && pct < 1.0) {
        final percentInt = (pct * 100).round();
        warnings.add(currentS().notifBudgetWarning(
          alloc.name,
          percentInt.toString(),
          daysLeft.toString(),
        ));
      }
    }

    if (warnings.isEmpty) return;

    final l = currentS();
    final body = warnings.length <= 2
        ? warnings.join('\n')
        : '${warnings.take(2).join('\n')}\n${l.notifAndMore(warnings.length - 2)}';

    await _plugin.show(
      id: _budgetWarningNotifId,
      title: l.notifBudgetWarningTitle,
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
    if (!await _shouldCheck(_billCooldownKey)) return;

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

    final l = currentS();
    final body = titles.length == 1
        ? l.notifSingleDue(titles.first)
        : l.notifMultipleDue(
            titles.length,
            titles.take(3).join(', '),
            titles.length > 3 ? l.notifBillsAndMore : '');

    await _plugin.show(
      id: _billNotifId,
      title: l.notifUpcomingBillsTitle,
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
