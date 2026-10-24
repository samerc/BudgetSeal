import 'dart:convert';
import 'dart:ui' show DartPluginRegistrant;

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../l10n/s_lookup.dart';
import '../database/app_database.dart';
import '../database/daos/allocations_dao.dart';
import '../database/daos/ledger_dao.dart';
import '../engine/recurring_engine.dart' show recurringAmountOn;
import '../../features/recurring/recurring_format.dart' show billRemindDefault;
import '../../shared/utils/calendar_days.dart';
import '../../shared/utils/format_number.dart';
import 'daily_reminder_service.dart';

/// A notification action tapped while the app wasn't in the foreground
/// ("Remind me tomorrow" never opens the app). Runs in its own isolate.
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse r) {
  if (r.actionId != NotificationService.actionSnooze) return;
  DartPluginRegistrant.ensureInitialized();
  NotificationService.snoozeBill(r, FlutterLocalNotificationsPlugin());
}

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  /// Expose the plugin so DailyReminderService can share the same instance.
  static FlutterLocalNotificationsPlugin get plugin => _plugin;

  static const _channelId = 'budgetseal_alerts';

  // Channel name/description show in Android's notification settings,
  // so they follow the app language.
  static NotificationDetails _alertDetails() {
    final l = currentS();
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        l.notifAlertsChannel,
        channelDescription: l.notifAlertsChannelDesc,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );
  }

  static const _envelopeNotifId = 1001;
  static const _budgetWarningNotifId = 1003;

  static const _envelopeCooldownKey = 'notif_last_check_envelopes';
  static const _budgetWarningCooldownKey = 'notif_last_check_budget_warning';
  static const _cooldownHours = 24;

  /// Threshold at which a budget warning notification is sent (80%).
  static const _budgetWarningThreshold = 0.80;

  /// Route a tapped notification asks for (its payload). `app.dart` listens
  /// and pushes it, then resets this to null.
  static final openRoute = ValueNotifier<String?>(null);

  static const routeAddTransaction = '/add-transaction';
  static const routeUpcomingBills = '/upcoming-bills';
  static const routeFunding = '/funding';

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    final ios = DarwinInitializationSettings(notificationCategories: [
      DarwinNotificationCategory(billCategory, actions: [
        DarwinNotificationAction.plain(actionLog, currentS().billNotifLogIt,
            options: {DarwinNotificationActionOption.foreground}),
        DarwinNotificationAction.plain(
            actionSnooze, currentS().billNotifSnooze),
      ]),
    ]);
    await _plugin.initialize(
      settings: InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (r) {
        if (r.actionId == actionSnooze) {
          snoozeBill(r, _plugin);
        } else if (r.payload?.startsWith('/') ?? false) {
          openRoute.value = r.payload;
        }
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
    // Cold start from a notification tap.
    final launch = await _plugin.getNotificationAppLaunchDetails();
    final payload = launch?.notificationResponse?.payload;
    if ((launch?.didNotificationLaunchApp ?? false) &&
        (payload?.startsWith('/') ?? false)) {
      openRoute.value = payload;
    }
  }

  /// All alert checks (envelope alerts have a 24h cooldown; bill reminders
  /// are rescheduled) — at launch and on every resume, so a phone that keeps
  /// the app in memory still gets them.
  static Future<void> runChecks(AppDatabase db, String householdId) async {
    await checkEnvelopes(db, householdId);
    await checkBudgetWarnings(db, householdId);
    await scheduleBills(db, householdId);
  }

  static const _permissionAskedKey = 'notif_permission_asked';

  /// Android 13+ needs a runtime grant before any alert can show. Ask once,
  /// on the first launch with a budget (iOS asks during [init]).
  static Future<void> requestPermissionOnce() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_permissionAskedKey) ?? false) return;
    await prefs.setBool(_permissionAskedKey, true);
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
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
      payload: routeFunding,
      notificationDetails: _alertDetails(),
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
      payload: routeFunding,
      notificationDetails: _alertDetails(),
    );
  }

  // ---------------------------------------------------------------------------
  // Bill reminders: one notification per bill on its lead day (the bill's
  // "Remind me"), with "Log it" and "Remind me tomorrow".
  // ---------------------------------------------------------------------------

  static const _billChannelId = 'budgetseal_bills';
  static const _billState = 'notif_bill_state';
  static const _billLabels = 'notif_bill_labels';
  static const _billBaseId = 20000;
  static const _billHour = 9;
  static const billCategory = 'bill';
  static const actionLog = 'log';
  static const actionSnooze = 'snooze';

  /// Stable notification id per bill (FNV-1a of its id).
  static int billNotifId(String billId) {
    var h = 0x811c9dc5;
    for (final c in billId.codeUnits) {
      h = ((h ^ c) * 0x01000193) & 0xffffffff;
    }
    return _billBaseId + h % 50000;
  }

  /// [labels]: Log it, Remind me tomorrow, channel name, channel description
  /// (saved so the background snooze can build the same notification).
  static NotificationDetails _billDetails(List<String> labels) =>
      NotificationDetails(
        android: AndroidNotificationDetails(
          _billChannelId,
          labels[2],
          channelDescription: labels[3],
          importance: Importance.high,
          priority: Priority.high,
          actions: [
            AndroidNotificationAction(actionLog, labels[0],
                showsUserInterface: true, cancelNotification: true),
            AndroidNotificationAction(actionSnooze, labels[1],
                cancelNotification: true),
          ],
        ),
        iOS: const DarwinNotificationDetails(categoryIdentifier: billCategory),
      );

  /// The text of one bill's reminder, as read on [day].
  static String billReminderBody(
      RecurringTransaction r, DateTime due, DateTime day) {
    final l = currentS();
    final amount =
        formatAmount(recurringAmountOn(r, due), currency: r.currency);
    final days = calendarDaysBetween(day, due);
    final when = days < 0
        ? l.billNotifOverdue(amount, -days)
        : days == 0
            ? l.billNotifDueToday(amount)
            : days == 1
                ? l.billNotifDueTomorrow(amount)
                : l.billNotifDueInDays(amount, days);
    return r.askFirst ? '$when ${l.billNotifConfirm}' : when;
  }

  static Map<String, dynamic> _readBillState(SharedPreferences prefs) {
    try {
      return Map<String, dynamic>.from(
          jsonDecode(prefs.getString(_billState) ?? '{}') as Map);
    } catch (_) {
      return {};
    }
  }

  /// Schedules every bill's next reminder, and shows now the ones whose time
  /// passed without one (the app wasn't running, or the bill was just
  /// added). Runs at launch and on every resume. Each occurrence of a bill
  /// is reminded once, plus its snoozes.
  static Future<void> scheduleBills(
      AppDatabase db, String householdId) async {
    await DailyReminderService.ensureTz();
    final prefs = await SharedPreferences.getInstance();
    final l = currentS();
    final labels = [
      l.billNotifLogIt,
      l.billNotifSnooze,
      l.billNotifChannel,
      l.billNotifChannelDesc,
    ];
    await prefs.setStringList(_billLabels, labels);
    final state = _readBillState(prefs);

    final rows = await (db.select(db.recurringTransactions)
          ..where((t) =>
              t.householdId.equals(householdId) &
              t.enabled.equals(true) &
              t.deleted.equals(false)))
        .get();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final live = rows.map((r) => r.id).toSet();
    // Bills deleted or turned off: drop their pending reminder.
    for (final id in state.keys) {
      if (!live.contains(id)) await _plugin.cancel(id: billNotifId(id));
    }

    final next = <String, dynamic>{};
    for (final r in rows) {
      final notifId = billNotifId(r.id);
      final due = DateTime(
          r.nextDueDate.year, r.nextDueDate.month, r.nextDueDate.day);
      if (r.remindDays == -1 ||
          (r.endDate != null && due.isAfter(r.endDate!))) {
        await _plugin.cancel(id: notifId);
        continue;
      }
      final occurrence = due.toIso8601String().substring(0, 10);
      final prev = state[r.id] is Map
          ? Map<String, dynamic>.from(state[r.id] as Map)
          : <String, dynamic>{};
      final same = prev['due'] == occurrence;
      final prevAt = DateTime.tryParse(prev['at'] as String? ?? '');
      if (same && prevAt != null && !prevAt.isAfter(now)) {
        next[r.id] = prev; // already reminded for this occurrence
        continue;
      }
      final lead = r.remindDays ?? billRemindDefault;
      final snoozed = same && prev['snooze'] == true && prevAt != null;
      final at = snoozed
          ? prevAt
          : DateTime(due.year, due.month, due.day - lead, _billHour);
      final title = r.title.isNotEmpty ? r.title : l.subUntitled;
      if (at.isAfter(now)) {
        if (at.difference(now).inDays > 60) continue; // a later run does it
        final body =
            billReminderBody(r, due, DateTime(at.year, at.month, at.day));
        await _plugin.zonedSchedule(
          id: notifId,
          title: title,
          body: body,
          payload: _billPayload(r.id),
          scheduledDate: tz.TZDateTime.from(at, tz.local),
          notificationDetails: _billDetails(labels),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
        next[r.id] = {
          'due': occurrence,
          'at': at.toIso8601String(),
          't': title,
          'b': body,
          if (snoozed) 'snooze': true,
        };
      } else {
        // Missed while the app was closed (or just added): remind now.
        // Bills more than a week overdue are left to Upcoming bills.
        if (!due.isBefore(today.subtract(const Duration(days: 7)))) {
          final body = billReminderBody(r, due, today);
          await _plugin.show(
            id: notifId,
            title: title,
            body: body,
            payload: _billPayload(r.id),
            notificationDetails: _billDetails(labels),
          );
        }
        next[r.id] = {
          'due': occurrence,
          'at': now.toIso8601String(),
          't': title,
          'b': billReminderBody(r, due, today),
        };
      }
    }
    await prefs.setString(_billState, jsonEncode(next));
  }

  static String _billPayload(String billId) =>
      Uri(path: routeUpcomingBills, queryParameters: {'bill': billId})
          .toString();

  /// "Remind me tomorrow": the same reminder again in 24 hours. Also runs
  /// in the background isolate (the button doesn't open the app), so it only
  /// uses the plugin and SharedPreferences; the next [scheduleBills] keeps
  /// the snoozed time.
  static Future<void> snoozeBill(
      NotificationResponse r, FlutterLocalNotificationsPlugin plugin) async {
    try {
      final billId = Uri.tryParse(r.payload ?? '')?.queryParameters['bill'];
      if (billId == null) return;
      final prefs = await SharedPreferences.getInstance();
      final labels = prefs.getStringList(_billLabels);
      if (labels == null || labels.length < 4) return;
      final state = _readBillState(prefs);
      final prev = state[billId] is Map
          ? Map<String, dynamic>.from(state[billId] as Map)
          : <String, dynamic>{};
      final title = prev['t'] as String?;
      if (title == null) return;
      // Same clock time tomorrow (a 24h Duration drifts across DST).
      final now = DateTime.now();
      final at = DateTime(
          now.year, now.month, now.day + 1, now.hour, now.minute, now.second);
      tz_data.initializeTimeZones();
      await plugin.zonedSchedule(
        id: r.id ?? billNotifId(billId),
        title: title,
        body: prev['b'] as String?,
        payload: r.payload,
        scheduledDate: tz.TZDateTime.from(at.toUtc(), tz.UTC),
        notificationDetails: _billDetails(labels),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
      state[billId] = {...prev, 'at': at.toIso8601String(), 'snooze': true};
      await prefs.setString(_billState, jsonEncode(state));
    } catch (e) {
      debugPrint('[Notifications] Snooze failed: $e');
    }
  }
}
