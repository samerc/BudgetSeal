import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelf/shelf.dart';

import '../../../core/providers/database_provider.dart';
import '../../../core/providers/household_provider.dart';
import '_validation.dart';

// ── GET /api/reports/cashflow?year=&month= ────────────────────────────────────

Handler cashflowReportHandler(Ref ref) {
  return (Request request) async {
    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null) return forbidden();

    final params = request.url.queryParameters;
    final now = DateTime.now();
    final year = int.tryParse(params['year'] ?? '') ?? now.year;
    final month =
        (int.tryParse(params['month'] ?? '') ?? now.month).clamp(1, 12);

    final db = ref.read(databaseProvider);

    try {
      final start = DateTime(year, month, 1);
      final end = DateTime(year, month + 1, 1);

      final txs = await (db.select(db.transactions)
            ..where((t) =>
                t.householdId.equals(householdId) &
                t.deleted.equals(false) &
                t.type.isIn(['income', 'expense']) &
                t.createdAt.isBiggerOrEqualValue(start) &
                t.createdAt.isSmallerThanValue(end))
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .get();

      final household = await (db.select(db.households)
            ..where((h) => h.id.equals(householdId)))
          .getSingleOrNull();

      double totalIncome = 0;
      double totalExpense = 0;
      final daysInMonth = end.difference(start).inDays;
      final dailyIncome = List<double>.filled(daysInMonth, 0);
      final dailyExpense = List<double>.filled(daysInMonth, 0);

      for (final tx in txs) {
        final dayIdx = tx.createdAt.day - 1;
        if (dayIdx >= 0 && dayIdx < daysInMonth) {
          if (tx.type == 'income') {
            totalIncome += tx.amount;
            dailyIncome[dayIdx] += tx.amount;
          } else {
            totalExpense += tx.amount;
            dailyExpense[dayIdx] += tx.amount;
          }
        }
      }

      return ok({
        'year': year,
        'month': month,
        'currency': household?.baseCurrency ?? 'USD',
        'income': totalIncome,
        'expense': totalExpense,
        'net': totalIncome - totalExpense,
        'daily': List.generate(
          daysInMonth,
          (i) => {
            'day': i + 1,
            'income': dailyIncome[i],
            'expense': dailyExpense[i],
          },
        ),
      });
    } catch (e) {
      return serverError(e);
    }
  };
}

// ── GET /api/reports/by-category?year=&month= ─────────────────────────────────

Handler byCategoryReportHandler(Ref ref) {
  return (Request request) async {
    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null) return forbidden();

    final params = request.url.queryParameters;
    final now = DateTime.now();
    final year = int.tryParse(params['year'] ?? '') ?? now.year;
    final month =
        (int.tryParse(params['month'] ?? '') ?? now.month).clamp(1, 12);

    final db = ref.read(databaseProvider);

    try {
      final start = DateTime(year, month, 1);
      final end = DateTime(year, month + 1, 1);

      final txs = await (db.select(db.transactions)
            ..where((t) =>
                t.householdId.equals(householdId) &
                t.deleted.equals(false) &
                t.type.equals('expense') &
                t.createdAt.isBiggerOrEqualValue(start) &
                t.createdAt.isSmallerThanValue(end)))
          .get();

      if (txs.isEmpty) {
        return ok({'year': year, 'month': month, 'items': []});
      }

      final txIds = txs.map((t) => t.id).toList();
      final lines = await (db.select(db.transactionLines)
            ..where((l) => l.transactionId.isIn(txIds)))
          .get();

      final categories = await (db.select(db.categories)
            ..where((c) => c.householdId.equals(householdId)))
          .get();
      final catMap = {for (final c in categories) c.id: c};

      final Map<String, double> categoryTotals = {};

      // Aggregate per-line amounts (each line already in its native currency;
      // multiply by exchangeRateToBase to get base-currency value)
      for (final line in lines) {
        if (line.categoryId != null) {
          categoryTotals[line.categoryId!] =
              (categoryTotals[line.categoryId!] ?? 0) +
                  line.amount * line.exchangeRateToBase;
        }
      }

      // Transactions with a header-level categoryId and no per-line categories
      final txsWithLines = lines.map((l) => l.transactionId).toSet();
      for (final tx in txs) {
        if (!txsWithLines.contains(tx.id) && tx.categoryId != null) {
          categoryTotals[tx.categoryId!] =
              (categoryTotals[tx.categoryId!] ?? 0) + tx.amount;
        }
      }

      final household = await (db.select(db.households)
            ..where((h) => h.id.equals(householdId)))
          .getSingleOrNull();

      final sorted = categoryTotals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return ok({
        'year': year,
        'month': month,
        'currency': household?.baseCurrency ?? 'USD',
        'items': sorted.map((e) {
          final cat = catMap[e.key];
          return {
            'categoryId': e.key,
            'name': cat?.name ?? 'Unknown',
            'icon': cat?.icon ?? 'category',
            'colorHex': cat?.colorHex ?? '#607D8B',
            'total': e.value,
          };
        }).toList(),
      });
    } catch (e) {
      return serverError(e);
    }
  };
}
