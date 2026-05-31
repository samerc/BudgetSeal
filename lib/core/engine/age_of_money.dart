import 'package:drift/drift.dart';

import '../database/app_database.dart';

/// Calculates the "Age of Money" metric using FIFO matching.
///
/// Takes the last 10 expense transactions and, for each one, walks through
/// income transactions chronologically to find which income funded that
/// expense. The age for each expense is the number of days between the
/// covering income's date and the expense's date. Returns the average age
/// in days, or `null` if there is not enough data.
Future<int?> calculateAgeOfMoney(AppDatabase db, String householdId) async {
  // Get last 10 expense transactions, newest first.
  final expenses = await (db.select(db.transactions)
        ..where((t) =>
            t.householdId.equals(householdId) & t.deleted.equals(false) & t.status.isNull() & t.type.equals('expense'))
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
        ..limit(10))
      .get();

  if (expenses.isEmpty) return null;

  // Get all income transactions, oldest first (FIFO order).
  final incomes = await (db.select(db.transactions)
        ..where((t) =>
            t.householdId.equals(householdId) & t.deleted.equals(false) & t.status.isNull() & t.type.equals('income'))
        ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
      .get();

  if (incomes.isEmpty) return null;

  // Build a list of income "buckets" with remaining amounts (FIFO pool).
  // We use base-currency amounts so multi-currency households work correctly.
  final pool = incomes
      .map((i) => _IncomeBucket(
            date: i.createdAt,
            remaining: i.amount * i.exchangeRateToBase,
          ))
      .toList();

  // Process expenses from oldest to newest so FIFO ordering is correct.
  // (We fetched newest-first, so reverse.)
  final orderedExpenses = expenses.reversed.toList();

  int totalAgeDays = 0;
  int matchedCount = 0;

  for (final expense in orderedExpenses) {
    double needed = expense.amount * expense.exchangeRateToBase;

    // Walk through the income pool, consuming from the oldest first.
    double weightedDays = 0;
    double covered = 0;

    for (final bucket in pool) {
      if (needed <= 0) break;
      if (bucket.remaining <= 0) continue;

      final take = bucket.remaining < needed ? bucket.remaining : needed;
      final ageDays =
          expense.createdAt.difference(bucket.date).inDays.abs();

      weightedDays += take * ageDays;
      covered += take;
      bucket.remaining -= take;
      needed -= take;
    }

    if (covered > 0) {
      totalAgeDays += (weightedDays / covered).round();
      matchedCount++;
    }
  }

  if (matchedCount == 0) return null;
  return (totalAgeDays / matchedCount).round();
}

class _IncomeBucket {
  final DateTime date;
  double remaining;

  _IncomeBucket({required this.date, required this.remaining});
}
