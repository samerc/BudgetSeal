import '../database/daos/ledger_dao.dart';
import 'period_engine.dart' show budgetPeriodFor;

/// Average spending per envelope and currency over [history] (one map per
/// budget period, oldest first), counted from the first period with any
/// spending for that envelope — a new envelope isn't averaged down by
/// months before it existed. Rounded up to whole units.
Map<String, Map<String, double>> averageSpending(
    List<Map<String, Map<String, double>>> history) {
  final out = <String, Map<String, double>>{};
  final ids = {for (final h in history) ...h.keys};
  for (final id in ids) {
    final first = history.indexWhere(
        (h) => (h[id]?.values ?? const <double>[]).any((v) => v > 0));
    if (first < 0) continue;
    final n = history.length - first;
    final sums = <String, double>{};
    for (final h in history.skip(first)) {
      h[id]?.forEach((c, v) {
        if (v > 0) sums[c] = (sums[c] ?? 0) + v;
      });
    }
    out[id] = {for (final e in sums.entries) e.key: (e.value / n).ceilToDouble()};
  }
  return out;
}

/// [averageSpending] over the [periods] budget periods before the current
/// one (the Fund screen's "Usually spends" and the Web Companion's).
Future<Map<String, Map<String, double>>> recentAverageSpending(
    LedgerDao dao, String householdId, int periodStartDay,
    {int periods = 3}) async {
  final history = <Map<String, Map<String, double>>>[];
  var p = budgetPeriodFor(periodStartDay);
  for (var k = 0; k < periods; k++) {
    p = budgetPeriodFor(
        periodStartDay, p.start.subtract(const Duration(days: 1)));
    history.insert(
        0, await dao.watchSpendingInPeriod(householdId, p.start, p.end).first);
  }
  return averageSpending(history);
}
