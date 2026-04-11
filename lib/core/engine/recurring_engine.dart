import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import 'allocation_engine.dart';

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
          ..where(
              (r) => r.enabled.equals(true) & r.nextDueDate.isSmallerOrEqualValue(today)))
        .get();

    int generated = 0;
    for (final rec in due) {
      // Generate all missed occurrences (e.g. user hasn't opened app in weeks).
      var currentDue = rec.nextDueDate;
      while (!currentDue.isAfter(today)) {
        // Stop if past end date.
        if (rec.endDate != null && currentDue.isAfter(rec.endDate!)) {
          break;
        }
        await _generateTransaction(rec, currentDue);
        generated++;
        currentDue = _advanceDate(currentDue, rec.frequency, rec.interval);
      }

      await (_db.update(_db.recurringTransactions)
            ..where((r) => r.id.equals(rec.id)))
          .write(RecurringTransactionsCompanion(
        lastGeneratedDate: Value(today),
        nextDueDate: Value(currentDue),
      ));
    }
    return generated;
  }

  Future<void> _generateTransaction(RecurringTransaction rec, [DateTime? forDate]) async {
    final householdId = rec.householdId;

    // Determine base currency from household.
    final household = await (_db.select(_db.households)
          ..where((h) => h.id.equals(householdId)))
        .getSingleOrNull();
    final baseCurrency = household?.baseCurrency ?? 'USD';

    if (rec.type == 'transfer' && rec.destinationAccountId != null) {
      await _allocationEngine.recordTransfer(
        householdId: householdId,
        fromAccountId: rec.accountId,
        toAccountId: rec.destinationAccountId!,
        amount: rec.amount,
        currency: rec.currency,
        exchangeRateToBase: 1.0,
        createdBy: 'recurring',
        deviceId: 'local',
        note: rec.title.isNotEmpty ? rec.title : rec.note,
        date: forDate ?? rec.nextDueDate,
      );
    } else {
      final lines = [
        TxLine(
          amount: rec.amount,
          currency: rec.currency,
          categoryId: rec.categoryId,
          accountId: rec.accountId,
        ),
      ];
      await _allocationEngine.recordTransaction(
        householdId: householdId,
        accountId: rec.accountId,
        type: rec.type,
        lines: lines,
        baseCurrency: baseCurrency,
        note: rec.title.isNotEmpty ? rec.title : rec.note,
        date: forDate ?? rec.nextDueDate,
      );
    }
  }

  DateTime _advanceDate(DateTime from, String frequency, int interval) {
    return switch (frequency) {
      'daily' => from.add(Duration(days: interval)),
      'weekly' => from.add(Duration(days: 7 * interval)),
      'monthly' => DateTime(from.year, from.month + interval, from.day),
      'yearly' => DateTime(from.year + interval, from.month, from.day),
      _ => from.add(Duration(days: 30 * interval)),
    };
  }

  /// Get all recurring transactions for a household.
  Future<List<RecurringTransaction>> getAll(String householdId) async {
    return (_db.select(_db.recurringTransactions)
          ..where((r) => r.householdId.equals(householdId))
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
            endDate: Value(endDate),
          ),
        );
    return id;
  }

  /// Delete a recurring transaction.
  Future<void> delete(String id) async {
    await (_db.delete(_db.recurringTransactions)
          ..where((r) => r.id.equals(id)))
        .go();
  }

  /// Toggle enabled state.
  Future<void> toggleEnabled(String id, bool enabled) async {
    await (_db.update(_db.recurringTransactions)
          ..where((r) => r.id.equals(id)))
        .write(RecurringTransactionsCompanion(enabled: Value(enabled)));
  }
}
