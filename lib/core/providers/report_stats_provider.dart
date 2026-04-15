import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/utils/format_number.dart';
import 'household_provider.dart';
import 'transactions_provider.dart';

/// Pre-aggregated monthly statistics, computed once per data change in O(N).
class MonthlyStats {
  final double income;
  final double expense;
  final Map<String, double> categorySpend; // categoryId → amount

  const MonthlyStats({
    required this.income,
    required this.expense,
    this.categorySpend = const {},
  });

  double get net => income - expense;
}

class ReportStats {
  /// Monthly aggregates keyed by first-of-month DateTime.
  final Map<DateTime, MonthlyStats> monthly;

  const ReportStats({required this.monthly});

  /// Average monthly expense over [lookback] months prior to [month].
  double typicalMonthlySpend(DateTime month, {int lookback = 6}) {
    double total = 0;
    int counted = 0;
    for (int i = 1; i <= lookback; i++) {
      final m = DateTime(month.year, month.month - i, 1);
      final s = monthly[m];
      if (s != null && s.expense > 0) {
        total += s.expense;
        counted++;
      }
    }
    return counted > 0 ? total / counted : 0;
  }

  /// Monthly stats for a range of months (e.g., last 6 months for trend).
  List<MapEntry<DateTime, MonthlyStats>> monthRange(int count) {
    final now = DateTime.now();
    final result = <MapEntry<DateTime, MonthlyStats>>[];
    for (int i = count - 1; i >= 0; i--) {
      final m = DateTime(now.year, now.month - i, 1);
      result.add(MapEntry(
          m, monthly[m] ?? const MonthlyStats(income: 0, expense: 0)));
    }
    return result;
  }
}

double _safeBaseAmount(TransactionEntry e, String baseCurrency) {
  if (e.lines.isNotEmpty) {
    double sum = 0;
    for (final l in e.lines) {
      if (!isRealRate(l.currency, baseCurrency, l.exchangeRateToBase)) continue;
      sum += l.amount * l.exchangeRateToBase;
    }
    return sum;
  }
  if (!isRealRate(e.tx.currency, baseCurrency, e.tx.exchangeRateToBase)) return 0;
  return e.tx.amount * e.tx.exchangeRateToBase;
}

/// Single-pass O(N) aggregation of all transactions into monthly buckets.
final reportStatsProvider = Provider<AsyncValue<ReportStats>>((ref) {
  final baseCurrency =
      ref.watch(currentHouseholdIdProvider) != null
          ? (ref.watch(householdProvider).value?.baseCurrency ?? 'USD')
          : 'USD';
  final txAsync = ref.watch(transactionEntriesProvider);

  return txAsync.whenData((entries) {
    final monthly = <DateTime, _MutableMonth>{};

    for (final e in entries) {
      if (e.tx.type == 'transfer') continue;
      final d = e.tx.createdAt;
      final key = DateTime(d.year, d.month, 1);
      final m = monthly.putIfAbsent(key, () => _MutableMonth());
      final amt = _safeBaseAmount(e, baseCurrency);

      if (e.tx.type == 'income') {
        m.income += amt;
      } else if (e.tx.type == 'expense') {
        m.expense += amt;
        final catId = e.tx.categoryId;
        if (catId != null) {
          m.categorySpend[catId] = (m.categorySpend[catId] ?? 0) + amt;
        }
      }
    }

    final result = monthly.map((k, v) => MapEntry(
        k,
        MonthlyStats(
          income: v.income,
          expense: v.expense,
          categorySpend: Map.unmodifiable(v.categorySpend),
        )));

    return ReportStats(monthly: result);
  });
});

class _MutableMonth {
  double income = 0;
  double expense = 0;
  final categorySpend = <String, double>{};
}
