import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/utils/format_number.dart';
import '../engine/period_engine.dart' show budgetPeriodFor;
import 'household_provider.dart';
import 'transactions_provider.dart';

/// Reports by budget period instead of calendar month (only matters when
/// the period start day isn't 1). Persisted.
class ReportsByPeriodNotifier extends Notifier<bool> {
  static const _key = 'reports_budget_period';

  @override
  bool build() {
    SharedPreferences.getInstance().then((p) {
      final v = p.getBool(_key) ?? false;
      if (v != state) state = v;
    });
    return false;
  }

  Future<void> set(bool v) async {
    state = v;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_key, v);
  }
}

final reportsByPeriodProvider =
    NotifierProvider<ReportsByPeriodNotifier, bool>(ReportsByPeriodNotifier.new);

/// The period start day reports use, or null for calendar months.
final reportsStartDayProvider = Provider<int?>((ref) {
  final byPeriod = ref.watch(reportsByPeriodProvider);
  final day = ref.watch(householdProvider).value?.periodStartDay ?? 1;
  return byPeriod && day != 1 ? day : null;
});

/// Report bucket for [d]: its calendar month, or (with [startDay]) the month
/// its budget period starts in. Keyed by the 1st of that month.
DateTime reportBucketFor(DateTime d, int? startDay) {
  if (startDay == null) return DateTime(d.year, d.month, 1);
  final s = budgetPeriodFor(startDay, d).start;
  return DateTime(s.year, s.month, 1);
}

/// Date range of the bucket keyed [month] (from [reportBucketFor]).
({DateTime start, DateTime end}) reportRangeFor(DateTime month, int? startDay) {
  if (startDay == null) {
    return (start: month, end: DateTime(month.year, month.month + 1, 1));
  }
  final days = DateTime(month.year, month.month + 1, 0).day;
  return budgetPeriodFor(
      startDay, DateTime(month.year, month.month, startDay.clamp(1, days)));
}

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
  List<MapEntry<DateTime, MonthlyStats>> monthRange(int count, {DateTime? from}) {
    final ref = from ?? DateTime.now();
    final result = <MapEntry<DateTime, MonthlyStats>>[];
    for (int i = count - 1; i >= 0; i--) {
      final m = DateTime(ref.year, ref.month - i, 1);
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

/// Base-currency amount per category id for one transaction. A split
/// transaction has no header category, so it spreads over its lines'
/// categories instead of landing in "Uncategorized". Lines without a real
/// exchange rate are skipped (see [isRealRate]).
Map<String?, double> baseAmountByCategory(
    TransactionEntry e, String baseCurrency) {
  if (e.lines.isEmpty) {
    return {e.tx.categoryId: _safeBaseAmount(e, baseCurrency)};
  }
  final out = <String?, double>{};
  for (final l in e.lines) {
    if (!isRealRate(l.currency, baseCurrency, l.exchangeRateToBase)) continue;
    final id = l.categoryId ?? e.tx.categoryId;
    out[id] = (out[id] ?? 0) + l.amount * l.exchangeRateToBase;
  }
  return out;
}

/// Single-pass O(N) aggregation of all transactions into monthly buckets.
final reportStatsProvider = Provider<AsyncValue<ReportStats>>((ref) {
  final baseCurrency =
      ref.watch(currentHouseholdIdProvider) != null
          ? (ref.watch(householdProvider).value?.baseCurrency ?? 'USD')
          : 'USD';
  final txAsync = ref.watch(transactionEntriesProvider);
  final startDay = ref.watch(reportsStartDayProvider);

  return txAsync.whenData((entries) {
    final monthly = <DateTime, _MutableMonth>{};

    for (final e in entries) {
      if (e.tx.type == 'transfer') continue;
      final key = reportBucketFor(e.tx.createdAt.toLocal(), startDay);
      final m = monthly.putIfAbsent(key, () => _MutableMonth());
      final amt = _safeBaseAmount(e, baseCurrency);

      if (e.tx.type == 'income') {
        m.income += amt;
      } else if (e.tx.type == 'expense') {
        m.expense += amt;
        baseAmountByCategory(e, baseCurrency).forEach((catId, a) {
          if (catId != null) {
            m.categorySpend[catId] = (m.categorySpend[catId] ?? 0) + a;
          }
        });
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
