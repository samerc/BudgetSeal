import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show debugPrint;
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
      final baseCurrency = baseCurrencyMap[rec.householdId] ?? 'USD';
      // Generate all missed occurrences (e.g. user hasn't opened app in weeks).
      var currentDue = rec.nextDueDate;
      // Legacy rows have no anchor: the current due day is the best guess.
      final anchorDay = rec.anchorDay ?? currentDue.day;
      while (!currentDue.isAfter(today)) {
        // Stop if past end date.
        if (rec.endDate != null && currentDue.isAfter(rec.endDate!)) {
          break;
        }
        try {
          await _generateTransaction(rec, currentDue, baseCurrency);
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

      await (_db.update(_db.recurringTransactions)
            ..where((r) => r.id.equals(rec.id)))
          .write(RecurringTransactionsCompanion(
        lastGeneratedDate: Value(today),
        nextDueDate: Value(currentDue),
        anchorDay: Value(anchorDay),
        // Bump so the advanced due date syncs; otherwise the other device
        // still sees the old due date and re-posts the same bill (duplicate).
        lastModified: Value(DateTime.now()),
      ));
    }
    return generated;
  }

  /// Resolve the effective amount for a recurring transaction on a given date,
  /// taking price history into account for subscriptions.
  double _getAmountForDate(RecurringTransaction rec, DateTime date) {
    if (rec.priceHistory == null || rec.priceHistory!.isEmpty) {
      return rec.amount;
    }
    try {
      final history = (jsonDecode(rec.priceHistory!) as List)
          .map((e) => e as Map<String, dynamic>)
          .toList()
        ..sort((a, b) => (a['from'] as String).compareTo(b['from'] as String));

      double activeAmount = rec.amount;
      for (final entry in history) {
        final from = DateTime.parse(entry['from'] as String);
        if (!date.isBefore(from)) {
          activeAmount = (entry['amount'] as num).toDouble();
        }
      }
      return activeAmount;
    } catch (_) {
      return rec.amount;
    }
  }

  Future<void> _generateTransaction(RecurringTransaction rec, [DateTime? forDate, String? baseCurrencyOverride]) async {
    final householdId = rec.householdId;
    final effectiveDate = forDate ?? rec.nextDueDate;
    final amount = _getAmountForDate(rec, effectiveDate);

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
}
