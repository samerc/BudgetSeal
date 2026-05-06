import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelf/shelf.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/household_provider.dart';
import '_validation.dart';

/// Same logic as `isRealRate()` in format_number.dart:
/// Returns false when a foreign-currency line has the default 1.0 rate,
/// meaning the user never set a real exchange rate.
bool _isRealRate(String lineCurrency, String baseCurrency, double rate) {
  if (lineCurrency == baseCurrency) return true;
  return (rate - 1.0).abs() >= 0.001;
}

/// Compute the safe base-currency amount for a transaction.
/// Uses line-level data when available, applying isRealRate check.
double _safeBaseAmount(
  Transaction tx,
  List<TransactionLine> lines,
  String baseCurrency,
) {
  if (lines.isNotEmpty) {
    double sum = 0;
    for (final l in lines) {
      if (!_isRealRate(l.currency, baseCurrency, l.exchangeRateToBase)) {
        continue;
      }
      sum += l.amount * l.exchangeRateToBase;
    }
    return sum;
  }
  // No lines — fall back to header, still with rate check
  if (!_isRealRate(tx.currency, baseCurrency, tx.exchangeRateToBase)) return 0;
  return tx.amount * tx.exchangeRateToBase;
}

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
      final baseCurrency = household?.baseCurrency ?? 'USD';

      final accounts = await (db.select(db.accounts)
            ..where((a) => a.householdId.equals(householdId)))
          .get();
      final categories = await (db.select(db.categories)
            ..where((c) => c.householdId.equals(householdId)))
          .get();
      final catMap = {for (final c in categories) c.id: c};
      final acctMap = {for (final a in accounts) a.id: a};

      // Batch-fetch all lines for these transactions
      final txIds = txs.map((t) => t.id).toList();
      final allLines = txIds.isNotEmpty
          ? await (db.select(db.transactionLines)
                ..where((l) => l.transactionId.isIn(txIds)))
              .get()
          : <TransactionLine>[];
      final linesByTx = <String, List<TransactionLine>>{};
      for (final l in allLines) {
        linesByTx.putIfAbsent(l.transactionId, () => []).add(l);
      }

      double totalIncome = 0;
      double totalExpense = 0;
      final daysInMonth = end.difference(start).inDays;
      final dailyIncome = List<double>.filled(daysInMonth, 0);
      final dailyExpense = List<double>.filled(daysInMonth, 0);

      for (final tx in txs) {
        final amt = _safeBaseAmount(
          tx,
          linesByTx[tx.id] ?? [],
          baseCurrency,
        );
        final dayIdx = tx.createdAt.day - 1;
        if (dayIdx >= 0 && dayIdx < daysInMonth) {
          if (tx.type == 'income') {
            totalIncome += amt;
            dailyIncome[dayIdx] += amt;
          } else {
            totalExpense += amt;
            dailyExpense[dayIdx] += amt;
          }
        }
      }

      final expenseTxsSorted = txs
          .where((t) => t.type == 'expense')
          .toList()
        ..sort((a, b) {
          final aAmt = _safeBaseAmount(a, linesByTx[a.id] ?? [], baseCurrency);
          final bAmt = _safeBaseAmount(b, linesByTx[b.id] ?? [], baseCurrency);
          return bAmt.compareTo(aAmt);
        });

      return ok({
        'year': year,
        'month': month,
        'currency': baseCurrency,
        'income': totalIncome,
        'expense': totalExpense,
        'net': totalIncome - totalExpense,
        'transactionCount': txs.length,
        'topExpenses': expenseTxsSorted.take(5).map((t) {
          final amt =
              _safeBaseAmount(t, linesByTx[t.id] ?? [], baseCurrency);
          return <String, dynamic>{
            'amount': amt,
            'note': t.note,
            'date': t.createdAt.toIso8601String(),
            'accountName': acctMap[t.accountId]?.name,
            'categoryName':
                t.categoryId != null ? catMap[t.categoryId]?.name : null,
            'categoryIcon':
                t.categoryId != null ? catMap[t.categoryId]?.icon : null,
          };
        }).toList(),
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

    final typeFilter = params['type'] ?? 'expense';
    if (!['income', 'expense'].contains(typeFilter)) {
      return badRequest('type must be income or expense');
    }

    final db = ref.read(databaseProvider);

    try {
      final start = DateTime(year, month, 1);
      final end = DateTime(year, month + 1, 1);

      final household = await (db.select(db.households)
            ..where((h) => h.id.equals(householdId)))
          .getSingleOrNull();
      final baseCurrency = household?.baseCurrency ?? 'USD';

      final txs = await (db.select(db.transactions)
            ..where((t) =>
                t.householdId.equals(householdId) &
                t.deleted.equals(false) &
                t.type.equals(typeFilter) &
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

      // Aggregate per-line amounts, skipping lines with bogus rates
      for (final line in lines) {
        if (line.categoryId != null &&
            _isRealRate(line.currency, baseCurrency, line.exchangeRateToBase)) {
          categoryTotals[line.categoryId!] =
              (categoryTotals[line.categoryId!] ?? 0) +
                  line.amount * line.exchangeRateToBase;
        }
      }

      // Transactions with a header-level categoryId and no per-line categories
      final txsWithLines = lines.map((l) => l.transactionId).toSet();
      for (final tx in txs) {
        if (!txsWithLines.contains(tx.id) && tx.categoryId != null) {
          if (_isRealRate(tx.currency, baseCurrency, tx.exchangeRateToBase)) {
            categoryTotals[tx.categoryId!] =
                (categoryTotals[tx.categoryId!] ?? 0) + tx.amount;
          }
        }
      }

      final sorted = categoryTotals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return ok({
        'year': year,
        'month': month,
        'currency': baseCurrency,
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
