import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show ValueNotifier, debugPrint;
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../fx/fx_service.dart' show latestCachedRate;
import 'allocation_engine.dart';

/// The next occurrence after [from]. Calendar arithmetic throughout (a
/// 24-hour Duration drifts across DST changes). Monthly and yearly dates
/// clamp to the end of short months and return to [anchorDay] (defaults to
/// [from]'s day) afterwards: Jan 31 → Feb 28 → Mar 31.
DateTime advanceRecurringDate(DateTime from, String frequency, int interval,
    {int? anchorDay}) {
  final n = interval > 0 ? interval : 1;
  DateTime clamped(int year, int month) {
    final first = DateTime(year, month); // normalises month overflow
    final lastDay = DateTime(first.year, first.month + 1, 0).day;
    final day = (anchorDay ?? from.day).clamp(1, lastDay);
    return DateTime(first.year, first.month, day, from.hour, from.minute,
        from.second);
  }

  return switch (frequency) {
    'daily' => DateTime(from.year, from.month, from.day + n, from.hour,
        from.minute, from.second),
    'weekly' => DateTime(from.year, from.month, from.day + 7 * n, from.hour,
        from.minute, from.second),
    'monthly' => clamped(from.year, from.month + n),
    'yearly' => clamped(from.year + n, from.month),
    _ => DateTime(from.year, from.month, from.day + 30 * n, from.hour,
        from.minute, from.second),
  };
}

/// Manages recurring transactions: checks for due items on app start
/// and generates actual transactions.
/// The effective amount of a recurring item on [date], for a recurring transaction on a given date,
/// taking a subscription's price history into account (also used by the
/// upcoming-bill views, so they show the price that will be charged).
double recurringAmountOn(RecurringTransaction rec, DateTime date) {
  if (rec.priceHistory == null || rec.priceHistory!.isEmpty) {
    return rec.amount;
  }
  try {
    final history = (jsonDecode(rec.priceHistory!) as List)
        .map((e) => e as Map<String, dynamic>)
        .toList()
      ..sort((a, b) => (a['from'] as String).compareTo(b['from'] as String));

    double activeAmount = rec.amount;
    for (var i = 0; i < history.length; i++) {
      final from = DateTime.parse(history[i]['from'] as String);
      if (!date.isBefore(from)) {
        // From the latest change on, the price is the item's `amount` — what
        // the edit screens show and write. (They append a history entry with
        // it; an edit that didn't — older app versions — still charges it.)
        activeAmount = i == history.length - 1
            ? rec.amount
            : (history[i]['amount'] as num).toDouble();
      }
    }
    return activeAmount;
  } catch (_) {
    return rec.amount;
  }
}

/// A bill, subscription or planned payment whose account (or, for a
/// transfer, its destination) is deleted or archived: posting it would debit
/// the envelope with no visible account going down — Ready to assign would
/// grow by the payment. Refused instead.
class AccountUnavailableException implements Exception {
  final String accountId;
  const AccountUnavailableException(this.accountId);
  @override
  String toString() => 'AccountUnavailableException($accountId)';
}

/// A bill past its end date (a cancelled subscription): Post now refuses it.
class RecurringEndedException implements Exception {
  final String recurringId;
  const RecurringEndedException(this.recurringId);
  @override
  String toString() => 'RecurringEndedException($recurringId)';
}

/// Throws [AccountUnavailableException] when [accountId] or
/// [destinationAccountId] is missing, deleted or archived.
Future<void> ensureAccountsUsable(AppDatabase db, String accountId,
    [String? destinationAccountId]) async {
  for (final id in [
    accountId,
    if (destinationAccountId != null) destinationAccountId,
  ]) {
    final a = await (db.select(db.accounts)..where((a) => a.id.equals(id)))
        .getSingleOrNull();
    if (a == null || a.deleted || a.archived) {
      throw AccountUnavailableException(id);
    }
  }
}

/// The oldest missed occurrence a launch still posts: one year back. A due
/// date moved years back would otherwise flood the history with hundreds of
/// payments; older occurrences are skipped (not posted).
DateTime catchUpCutoff(DateTime today) =>
    DateTime(today.year - 1, today.month, today.day);

/// How many occurrences of a bill due on [nextDue] are due by [today] and
/// would post at the next launch (at most a year's worth, see
/// [catchUpCutoff]). The edit sheet asks before moving a due date back
/// past a few of them.
int catchUpCount(RecurringTransaction rec, DateTime nextDue, DateTime today) {
  final anchorDay = rec.anchorDay ?? nextDue.day;
  final cutoff = catchUpCutoff(today);
  var d = nextDue;
  var n = 0;
  var steps = 0;
  while (!d.isAfter(today) && steps++ < 100000) {
    if (rec.endDate != null && d.isAfter(rec.endDate!)) break;
    if (!d.isBefore(cutoff)) n++;
    d = advanceRecurringDate(d, rec.frequency, rec.interval,
        anchorDay: anchorDay);
  }
  return n;
}

class RecurringEngine {
  final AppDatabase _db;
  final AllocationEngine _allocationEngine;
  final _uuid = const Uuid();

  RecurringEngine(this._db) : _allocationEngine = AllocationEngine(_db);

  /// Check all enabled recurring transactions and generate any that are due.
  /// Returns the number of transactions generated.
  Future<int> processRecurring() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final due = await (_db.select(_db.recurringTransactions)
          ..where((r) =>
              r.enabled.equals(true) &
              r.deleted.equals(false) &
              r.nextDueDate.isSmallerOrEqualValue(today)))
        .get();

    // Pre-fetch base currencies for all households to avoid per-iteration queries.
    final householdIds = due.map((r) => r.householdId).toSet();
    final baseCurrencyMap = <String, String>{};
    for (final hId in householdIds) {
      final household = await (_db.select(_db.households)
            ..where((h) => h.id.equals(hId)))
          .getSingleOrNull();
      baseCurrencyMap[hId] = household?.baseCurrency ?? 'USD';
    }

    int generated = 0;
    for (final rec in due) {
      // Already past its end date (an end date set before the due date, or
      // a cancelled subscription): switch it off instead of leaving it due.
      if (rec.endDate != null && rec.nextDueDate.isAfter(rec.endDate!)) {
        await _switchOff(rec.id);
        continue;
      }
      // Its account (or a transfer's destination) was deleted or archived:
      // posting would debit the envelope with no visible account going down
      // (Ready to assign would grow). Switched off; the user can switch it
      // back on after moving it to another account.
      final accounts = await (_db.select(_db.accounts)
            ..where((a) => a.id.isIn([
                  rec.accountId,
                  if (rec.type == 'transfer' &&
                      rec.destinationAccountId != null)
                    rec.destinationAccountId!,
                ])))
          .get();
      if (accounts.any((a) => a.deleted || a.archived)) {
        await _switchOff(rec.id);
        continue;
      }
      // Account not here (yet — sync): wait, don't post into nothing.
      if (accounts.every((a) => a.id != rec.accountId)) continue;
      // Ask-first bills wait for the user to confirm the amount (Upcoming
      // bills → Confirm); they stay due and show as "to confirm".
      if (rec.askFirst) continue;
      final baseCurrency = baseCurrencyMap[rec.householdId] ?? 'USD';
      // Generate all missed occurrences (e.g. user hasn't opened app in weeks).
      var currentDue = rec.nextDueDate;
      // Legacy rows have no anchor: the current due day is the best guess.
      final anchorDay = rec.anchorDay ?? currentDue.day;
      // Occurrences more than a year old are skipped, not posted (a due
      // date moved years back must not flood the history).
      final cutoff = catchUpCutoff(today);
      while (currentDue.isBefore(cutoff)) {
        currentDue = advanceRecurringDate(
            currentDue, rec.frequency, rec.interval,
            anchorDay: anchorDay);
      }
      while (!currentDue.isAfter(today)) {
        // Stop if past end date.
        if (rec.endDate != null && currentDue.isAfter(rec.endDate!)) {
          break;
        }
        try {
          await _generateTransaction(rec, currentDue, baseCurrency,
              occurrence: currentDue);
        } catch (e) {
          // Leave this occurrence due (it shows as overdue and retries next
          // launch) and carry on with the other bills.
          debugPrint('[Recurring] Posting ${rec.id} failed: $e');
          break;
        }
        generated++;
        currentDue = advanceRecurringDate(
            currentDue, rec.frequency, rec.interval,
            anchorDay: anchorDay);
      }
      // Its last occurrence is posted: the series has ended (as `_advance`
      // does for Post now / Skip).
      final ended = rec.endDate != null && currentDue.isAfter(rec.endDate!);

      await (_db.update(_db.recurringTransactions)
            ..where((r) => r.id.equals(rec.id)))
          .write(RecurringTransactionsCompanion(
        lastGeneratedDate: Value(today),
        nextDueDate: Value(currentDue),
        anchorDay: Value(anchorDay),
        enabled: ended ? const Value(false) : const Value.absent(),
        // Bump so the advanced due date syncs; otherwise the other device
        // still sees the old due date and re-posts the same bill (duplicate).
        lastModified: Value(DateTime.now()),
      ));
    }
    if (generated > 0) postedNotice.value += generated;
    return generated;
  }

  /// Bills posted by the last [processRecurring] run at launch/resume; the
  /// main screen shows "N bills posted" and resets it.
  static final postedNotice = ValueNotifier<int>(0);

  /// Upcoming bills → Post now: record the next occurrence today and move
  /// the due date on (paying a bill early).
  /// [on] = the day it was paid (an overdue bill paid on its due date, or
  /// yesterday's payment); today when null. Another day is recorded at noon.
  /// [amount] replaces the bill's amount for this one payment (confirming
  /// an ask-first bill whose amount changes).
  Future<void> postNow(String recurringId,
      {DateTime? on, double? amount}) async {
    final rec = await (_db.select(_db.recurringTransactions)
          ..where((r) => r.id.equals(recurringId)))
        .getSingle();
    // A finished series (cancelled subscription) is not paid again.
    if (rec.endDate != null && rec.nextDueDate.isAfter(rec.endDate!)) {
      await _switchOff(rec.id);
      throw RecurringEndedException(rec.id);
    }
    await ensureAccountsUsable(_db, rec.accountId,
        rec.type == 'transfer' ? rec.destinationAccountId : null);
    final now = DateTime.now();
    final paid = on == null ||
            (on.year == now.year && on.month == now.month && on.day == now.day)
        ? now
        : DateTime(on.year, on.month, on.day, 12);
    // Keyed on the occurrence it pays, so the other device can't post
    // that occurrence again before it has synced the new due date. The
    // user asked for this payment, so an occurrence they deleted earlier
    // is brought back (launch never does that — see [_generateTransaction]).
    await _generateTransaction(rec, paid, null,
        occurrence: rec.nextDueDate, amount: amount, revive: true);
    await _advance(rec);
  }

  Future<void> _switchOff(String id) async {
    await (_db.update(_db.recurringTransactions)
          ..where((r) => r.id.equals(id)))
        .write(RecurringTransactionsCompanion(
            enabled: const Value(false),
            lastModified: Value(DateTime.now())));
  }

  /// Upcoming bills → Skip: move the due date on without posting.
  Future<void> skipNext(String recurringId) async {
    final rec = await (_db.select(_db.recurringTransactions)
          ..where((r) => r.id.equals(recurringId)))
        .getSingle();
    await _advance(rec);
  }

  Future<void> _advance(RecurringTransaction rec) async {
    final anchorDay = rec.anchorDay ?? rec.nextDueDate.day;
    final next = advanceRecurringDate(
        rec.nextDueDate, rec.frequency, rec.interval,
        anchorDay: anchorDay);
    final ended = rec.endDate != null && next.isAfter(rec.endDate!);
    await (_db.update(_db.recurringTransactions)
          ..where((r) => r.id.equals(rec.id)))
        .write(RecurringTransactionsCompanion(
      nextDueDate: Value(next),
      anchorDay: Value(anchorDay),
      enabled: ended ? const Value(false) : const Value.absent(),
      lastModified: Value(DateTime.now()),
    ));
  }

  /// Fixed id for one occurrence of [rec]: two devices that post the same
  /// bill before syncing write the same rows instead of a duplicate.
  static String occurrenceId(String recurringId, DateTime due) =>
      'rec:$recurringId:${due.year}-${due.month.toString().padLeft(2, '0')}'
      '-${due.day.toString().padLeft(2, '0')}';

  /// Posts one occurrence under its fixed [occurrenceId]. An occurrence that
  /// already exists — posted before, or by the other phone and synced — is
  /// not posted again; a deleted one stays deleted, so launch never brings
  /// back a payment the user deleted. With [revive] (the user explicitly
  /// tapped Post now), a deleted occurrence is brought back instead: the
  /// same row is undeleted and rewritten in place (an edit, so two phones
  /// doing it still end with one transaction).
  Future<void> _generateTransaction(RecurringTransaction rec, DateTime forDate,
      String? baseCurrencyOverride,
      {required DateTime occurrence, double? amount, bool revive = false}) async {
    final id = occurrenceId(rec.id, occurrence);
    if (revive) {
      final old = await (_db.select(_db.transactions)
            ..where((t) => t.id.equals(id)))
          .getSingleOrNull();
      if (old != null && old.deleted) {
        await _db.transaction(() async {
          // Its lines go first, so the edit below rewrites them (and the
          // envelope debit the delete removed) under a new revision.
          await (_db.delete(_db.transactionLines)
                ..where((l) => l.transactionId.equals(id)))
              .go();
          await (_db.update(_db.transactions)..where((t) => t.id.equals(id)))
              .write(TransactionsCompanion(
                  deleted: const Value(false),
                  lastModified: Value(DateTime.now())));
          await _post(rec, forDate, baseCurrencyOverride,
              amount: amount, editing: id);
        });
        return;
      }
    }
    await _post(rec, forDate, baseCurrencyOverride, amount: amount, id: id);
  }

  Future<void> _post(RecurringTransaction rec, DateTime forDate,
      String? baseCurrencyOverride,
      {double? amount, String? id, String? editing}) async {
    final householdId = rec.householdId;
    final effectiveDate = forDate;
    amount ??= recurringAmountOn(rec, effectiveDate);

    // Use pre-fetched base currency, or fall back to household query.
    final String baseCurrency;
    if (baseCurrencyOverride != null) {
      baseCurrency = baseCurrencyOverride;
    } else {
      final household = await (_db.select(_db.households)
            ..where((h) => h.id.equals(householdId)))
          .getSingleOrNull();
      baseCurrency = household?.baseCurrency ?? 'USD';
    }

    // Rates come from the local cache (any age): this runs at app start and
    // must not wait on the network. Without one, an expense/income posts
    // with no rate (flagged "No rate" in the UI); a transfer between
    // currencies waits (it would move the wrong amount).
    if (rec.type == 'transfer' && rec.destinationAccountId != null) {
      final dest = await (_db.select(_db.accounts)
            ..where((a) => a.id.equals(rec.destinationAccountId!)))
          .getSingleOrNull();
      final destCurrency = dest?.currency ?? rec.currency;
      final transferRate =
          await latestCachedRate(_db, rec.currency, destCurrency);
      if (transferRate == null) {
        throw CurrencyConversionException(rec.currency, destCurrency);
      }
      await _allocationEngine.recordTransfer(
        householdId: householdId,
        fromAccountId: rec.accountId,
        toAccountId: rec.destinationAccountId!,
        amount: amount,
        currency: rec.currency,
        exchangeRateToBase: transferRate,
        createdBy: 'recurring',
        deviceId: 'local',
        note: rec.title.isNotEmpty ? rec.title : rec.note,
        date: effectiveDate,
        id: id,
        editing: editing,
      );
    } else {
      final rate = await latestCachedRate(_db, rec.currency, baseCurrency);
      final lines = [
        TxLine(
          amount: amount,
          currency: rec.currency,
          categoryId: rec.categoryId,
          accountId: rec.accountId,
          exchangeRateToBase: rate ?? 1.0,
        ),
      ];
      await _allocationEngine.recordTransaction(
        householdId: householdId,
        accountId: rec.accountId,
        type: rec.type,
        lines: lines,
        baseCurrency: baseCurrency,
        note: rec.title.isNotEmpty ? rec.title : rec.note,
        date: effectiveDate,
        id: id,
        editing: editing,
      );
    }
  }

  /// Get all recurring transactions for a household.
  Future<List<RecurringTransaction>> getAll(String householdId,
      {bool excludeSubscriptions = false}) async {
    return (_db.select(_db.recurringTransactions)
          ..where((r) {
            final base =
                r.householdId.equals(householdId) & r.deleted.equals(false);
            if (excludeSubscriptions) {
              return base & r.isSubscription.equals(false);
            }
            return base;
          })
          ..orderBy([(r) => OrderingTerm.asc(r.nextDueDate)]))
        .get();
  }

  /// Create a new recurring transaction.
  Future<String> create({
    required String householdId,
    required String type,
    required String title,
    required double amount,
    required String currency,
    required String accountId,
    String? destinationAccountId,
    String? categoryId,
    required String frequency,
    int interval = 1,
    required DateTime startDate,
    DateTime? endDate,
    String note = '',
    bool isSubscription = false,
    String? priceHistory,
    bool askFirst = false,
    int? remindDays,
  }) async {
    final id = _uuid.v4();
    await _db.into(_db.recurringTransactions).insert(
          RecurringTransactionsCompanion.insert(
            id: id,
            householdId: householdId,
            type: type,
            title: Value(title),
            amount: amount,
            currency: currency,
            accountId: accountId,
            destinationAccountId: Value(destinationAccountId),
            categoryId: Value(categoryId),
            note: Value(note),
            frequency: frequency,
            interval: Value(interval),
            nextDueDate: startDate,
            anchorDay: Value(startDate.day),
            endDate: Value(endDate),
            isSubscription: Value(isSubscription),
            priceHistory: Value(priceHistory),
            askFirst: Value(askFirst),
            remindDays: Value(remindDays),
          ),
        );
    return id;
  }

  /// Delete a recurring transaction.
  Future<void> delete(String id) async {
    await (_db.update(_db.recurringTransactions)
          ..where((r) => r.id.equals(id)))
        .write(RecurringTransactionsCompanion(
            deleted: const Value(true),
            lastModified: Value(DateTime.now())));
  }

  /// Toggle enabled state.
  Future<void> toggleEnabled(String id, bool enabled) async {
    await (_db.update(_db.recurringTransactions)
          ..where((r) => r.id.equals(id)))
        .write(RecurringTransactionsCompanion(
            enabled: Value(enabled), lastModified: Value(DateTime.now())));
  }

  /// Bill settings: ask before posting, and reminder lead days (null =
  /// default, -1 = off). Moves last_modified so it syncs.
  Future<void> setBillOptions(String id,
      {required bool askFirst, required int? remindDays}) async {
    await (_db.update(_db.recurringTransactions)
          ..where((r) => r.id.equals(id)))
        .write(RecurringTransactionsCompanion(
            askFirst: Value(askFirst),
            remindDays: Value(remindDays),
            lastModified: Value(DateTime.now())));
  }

  /// Set (or clear, with null) the last date a recurring item runs — a
  /// subscription's cancellation date. Moves last_modified so it syncs.
  Future<void> setEndDate(String id, DateTime? endDate) async {
    await (_db.update(_db.recurringTransactions)
          ..where((r) => r.id.equals(id)))
        .write(RecurringTransactionsCompanion(
            endDate: Value(endDate), lastModified: Value(DateTime.now())));
  }
}
