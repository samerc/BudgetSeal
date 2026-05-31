import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/spending_heatmap.dart';
import 'database_provider.dart';
import 'household_provider.dart';

/// Provides daily income/expense totals for a given year.
/// Used by the spending heatmap widget.
final dailySpendingProvider =
    FutureProvider.family<List<DaySpending>, int>((ref, year) async {
  final db = ref.watch(databaseProvider);
  final householdId = ref.watch(currentHouseholdIdProvider);
  if (householdId == null) return [];

  final start = DateTime(year, 1, 1);
  final end = DateTime(year + 1, 1, 1);

  final txs = await (db.select(db.transactions)
        ..where((t) => t.householdId.equals(householdId))
        ..where((t) => t.deleted.equals(false))
        ..where((t) => t.status.isNull())
        ..where((t) => t.createdAt.isBiggerOrEqualValue(start))
        ..where((t) => t.createdAt.isSmallerThanValue(end))
        ..where((t) => t.type.isIn(['income', 'expense'])))
      .get();

  // Group by date
  final Map<String, DaySpending> days = {};
  for (final tx in txs) {
    final d = tx.createdAt.toLocal();
    final key = '${d.year}-${d.month}-${d.day}';
    final existing = days[key];
    // tx.amount is already stored in base currency by recordTransaction
    final amount = tx.amount;
    if (existing != null) {
      days[key] = DaySpending(
        date: DateTime(d.year, d.month, d.day),
        income: existing.income + (tx.type == 'income' ? amount : 0),
        expense: existing.expense + (tx.type == 'expense' ? amount : 0),
      );
    } else {
      days[key] = DaySpending(
        date: DateTime(d.year, d.month, d.day),
        income: tx.type == 'income' ? amount : 0,
        expense: tx.type == 'expense' ? amount : 0,
      );
    }
  }

  return days.values.toList()..sort((a, b) => a.date.compareTo(b.date));
});
