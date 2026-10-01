import 'package:drift/drift.dart';

import '../../shared/utils/format_number.dart' show isRealRate;
import '../database/app_database.dart';

/// Calculates the "Age of Money" metric using FIFO matching.
///
/// Money comes in as opening balances and income; every expense, oldest
/// first, spends the oldest money still left. An expense's age is the
/// weighted number of days between when the money it spent arrived and when
/// it was spent. The metric is the average age of the last [_window]
/// expenses, or `null` without enough data.
///
/// All expenses are replayed (not just the last few) — otherwise the recent
/// expenses would be matched against the very first income ever recorded.
const _window = 10;

Future<int?> calculateAgeOfMoney(AppDatabase db, String householdId) async {
  final txs = await (db.select(db.transactions)
        ..where((t) =>
            t.householdId.equals(householdId) &
            t.deleted.equals(false) &
            t.status.isNull() &
            t.type.isIn(['income', 'expense']))
        ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
      .get();
  final expenseCount = txs.where((t) => t.type == 'expense').length;
  if (expenseCount == 0) return null;

  final household = await (db.select(db.households)
        ..where((h) => h.id.equals(householdId)))
      .getSingleOrNull();
  final baseCurrency = household?.baseCurrency ?? 'USD';

  // Opening balances are the oldest money: dated when the account was added,
  // or at the first transaction if that is earlier (backdated entries).
  final accounts = await (db.select(db.accounts)
        ..where((a) =>
            a.householdId.equals(householdId) & a.deleted.equals(false)))
      .get();
  final firstTx = txs.first.createdAt;
  final pool = <_IncomeBucket>[
    for (final a in accounts)
      if (a.initialBalance > 0 && a.currency == baseCurrency)
        _IncomeBucket(
            date: a.createdAt.isBefore(firstTx) ? a.createdAt : firstTx,
            remaining: a.initialBalance),
  ]..sort((x, y) => x.date.compareTo(y.date));

  double baseAmount(Transaction t) =>
      isRealRate(t.currency, baseCurrency, t.exchangeRateToBase)
          ? t.amount * t.exchangeRateToBase
          : 0;

  final skipBefore = expenseCount - _window; // only the last N are averaged
  var expenseIndex = 0;
  var start = 0; // first bucket that may still have money
  int totalAgeDays = 0;
  int matchedCount = 0;

  for (final t in txs) {
    if (t.type == 'income') {
      final amount = baseAmount(t);
      if (amount > 0) {
        pool.add(_IncomeBucket(date: t.createdAt, remaining: amount));
      }
      continue;
    }

    double needed = baseAmount(t);
    double weightedDays = 0;
    double covered = 0;
    for (var i = start; i < pool.length && needed > 0; i++) {
      final bucket = pool[i];
      if (bucket.remaining <= 0) continue;
      final take = bucket.remaining < needed ? bucket.remaining : needed;
      weightedDays += take * t.createdAt.difference(bucket.date).inDays.abs();
      covered += take;
      bucket.remaining -= take;
      needed -= take;
    }
    while (start < pool.length && pool[start].remaining <= 0) {
      start++;
    }

    if (expenseIndex >= skipBefore && covered > 0) {
      totalAgeDays += (weightedDays / covered).round();
      matchedCount++;
    }
    expenseIndex++;
  }

  if (matchedCount == 0) return null;
  return (totalAgeDays / matchedCount).round();
}

class _IncomeBucket {
  final DateTime date;
  double remaining;

  _IncomeBucket({required this.date, required this.remaining});
}
