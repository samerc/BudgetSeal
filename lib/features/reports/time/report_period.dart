import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/report_stats_provider.dart';
import '../../../core/providers/transactions_provider.dart';
import '../../../shared/utils/format_number.dart';
import '../../../shared/utils/note_text.dart';

/// How far back the Reports hub (and the reports it opens) look.
enum ReportSpan { month, months3, months6, months12, year, custom }

class ReportSpanState {
  final ReportSpan span;

  /// First and last bucket (1st of month) for [ReportSpan.custom].
  final DateTime? customFrom;
  final DateTime? customTo;
  const ReportSpanState(this.span, {this.customFrom, this.customTo});
}

class ReportSpanNotifier extends Notifier<ReportSpanState> {
  @override
  ReportSpanState build() => const ReportSpanState(ReportSpan.months6);

  void set(ReportSpan span) => state = ReportSpanState(span);
  void setCustom(DateTime from, DateTime to) => state = ReportSpanState(
      ReportSpan.custom,
      customFrom: DateTime(from.year, from.month, 1),
      customTo: DateTime(to.year, to.month, 1));
}

final reportSpanProvider =
    NotifierProvider<ReportSpanNotifier, ReportSpanState>(
        ReportSpanNotifier.new);

/// A run of report buckets (calendar months, or budget periods keyed by the
/// month they start in — see [reportBucketFor]).
class ReportPeriod {
  final List<DateTime> buckets;
  final int? startDay;
  const ReportPeriod(this.buckets, this.startDay);

  DateTime get start => reportRangeFor(buckets.first, startDay).start;
  DateTime get end => reportRangeFor(buckets.last, startDay).end;
  int get length => buckets.length;

  /// The same number of buckets just before this one.
  ReportPeriod get previous => ReportPeriod([
        for (var i = length; i > 0; i--)
          DateTime(buckets.first.year, buckets.first.month - i, 1),
      ], startDay);

  ({DateTime start, DateTime end}) range(DateTime bucket) =>
      reportRangeFor(bucket, startDay);
}

final reportPeriodProvider = Provider<ReportPeriod>((ref) {
  final s = ref.watch(reportSpanProvider);
  final startDay = ref.watch(reportsStartDayProvider);
  final now = reportBucketFor(DateTime.now(), startDay);
  List<DateTime> back(int n) => [
        for (var i = n - 1; i >= 0; i--) DateTime(now.year, now.month - i, 1),
      ];
  final buckets = switch (s.span) {
    ReportSpan.month => back(1),
    ReportSpan.months3 => back(3),
    ReportSpan.months6 => back(6),
    ReportSpan.months12 => back(12),
    ReportSpan.year => back(now.month),
    ReportSpan.custom => () {
        final from = s.customFrom ?? now;
        final to = s.customTo ?? now;
        final n = (to.year - from.year) * 12 + to.month - from.month + 1;
        return [
          for (var i = 0; i < n.clamp(1, 120); i++)
            DateTime(from.year, from.month + i, 1),
        ];
      }(),
  };
  return ReportPeriod(buckets, startDay);
});

/// A line's amount in the base currency, or null when it has no real rate
/// (currencies never mix: such lines are left out of base totals).
double? baseOf(double amount, String currency, double rate, String base) {
  if (!isRealRate(currency, base, rate)) return null;
  return currency == base ? amount : amount * rate;
}

/// Everything the time reports need from one pass over the transactions.
class PeriodTotals {
  double income = 0;
  double spent = 0;
  final byCategory = <String?, double>{};
  final incomeByBucket = <DateTime, double>{};
  final spentByBucket = <DateTime, double>{};

  /// bucket → category → spent.
  final categoryByBucket = <DateTime, Map<String?, double>>{};

  /// Lower-cased title → (shown title, count, total).
  final places = <String, ({String title, int count, double total})>{};
  final weekdaySpent = List<double>.filled(7, 0); // Monday = 0
  final hourCount = List<int>.filled(24, 0);
  int payments = 0;
  final spendDays = <DateTime>{};
  final biggest = <({TransactionEntry entry, double amount})>[];

  /// Account id → (in, out) in the account's own currency.
  final accountFlow = <String, ({double inflow, double outflow})>{};

  /// Currency → spent in that currency (not converted).
  final spentByCurrency = <String, double>{};

  double get kept => income - spent;
}

/// Totals for [period] in [base] currency. Transfers only count in
/// [PeriodTotals.accountFlow].
PeriodTotals periodTotals(
    List<TransactionEntry> entries, ReportPeriod period, String base) {
  final t = PeriodTotals();
  final start = period.start, end = period.end;
  for (final e in entries) {
    final d = e.tx.createdAt.toLocal();
    if (d.isBefore(start) || !d.isBefore(end)) continue;
    final bucket = reportBucketFor(d, period.startDay);
    final type = e.tx.type;

    void flow(String accountId, double inflow, double outflow) {
      final f = t.accountFlow[accountId] ?? (inflow: 0.0, outflow: 0.0);
      t.accountFlow[accountId] =
          (inflow: f.inflow + inflow, outflow: f.outflow + outflow);
    }

    if (type == 'transfer') {
      flow(e.tx.accountId, 0, e.tx.amount);
      final dest = e.tx.destinationAccountId;
      if (dest != null) {
        final destCur = e.destinationAccountCurrency;
        final credit = destCur != null &&
                destCur != e.tx.currency &&
                e.tx.exchangeRateToBase > 0
            ? e.tx.amount * e.tx.exchangeRateToBase
            : e.tx.amount;
        flow(dest, credit, 0);
      }
      continue;
    }

    // Lines (or the header for a line-less row).
    final lines = e.lines.isNotEmpty
        ? [
            for (final l in e.lines)
              (
                amount: l.amount,
                currency: l.currency,
                rate: l.exchangeRateToBase,
                category: l.categoryId ?? e.tx.categoryId,
                account: l.accountId ?? e.tx.accountId,
              )
          ]
        : [
            (
              amount: e.tx.amount,
              currency: e.tx.currency,
              rate: e.tx.exchangeRateToBase,
              category: e.tx.categoryId,
              account: e.tx.accountId,
            )
          ];
    double txBase = 0;
    for (final l in lines) {
      if (type == 'income') {
        flow(l.account, l.amount, 0);
      } else {
        flow(l.account, 0, l.amount);
        t.spentByCurrency[l.currency] =
            (t.spentByCurrency[l.currency] ?? 0) + l.amount;
      }
      final b = baseOf(l.amount, l.currency, l.rate, base);
      if (b == null) continue;
      txBase += b;
      if (type == 'expense') {
        t.byCategory[l.category] = (t.byCategory[l.category] ?? 0) + b;
        final m = t.categoryByBucket.putIfAbsent(bucket, () => {});
        m[l.category] = (m[l.category] ?? 0) + b;
      }
    }

    if (type == 'income') {
      t.income += txBase;
      t.incomeByBucket[bucket] = (t.incomeByBucket[bucket] ?? 0) + txBase;
    } else if (type == 'expense') {
      t.spent += txBase;
      t.spentByBucket[bucket] = (t.spentByBucket[bucket] ?? 0) + txBase;
      if (txBase <= 0) continue;
      t.payments++;
      t.weekdaySpent[d.weekday - 1] += txBase;
      t.hourCount[d.hour]++;
      t.spendDays.add(DateTime(d.year, d.month, d.day));
      t.biggest.add((entry: e, amount: txBase));
      final title = _title(e.tx.note);
      // Goal savings and loan payments ("[obj:…]") aren't places.
      if (title.isNotEmpty && !e.tx.note.contains('[obj:')) {
        final key = title.toLowerCase();
        final p = t.places[key];
        t.places[key] = (
          title: p?.title ?? title,
          count: (p?.count ?? 0) + 1,
          total: (p?.total ?? 0) + txBase,
        );
      }
    }
  }
  t.biggest.sort((a, b) => b.amount.compareTo(a.amount));
  if (t.biggest.length > 20) t.biggest.removeRange(20, t.biggest.length);
  return t;
}

String _title(String note) {
  final n = visibleNote(note).trim();
  final dash = n.indexOf(' — ');
  return (dash >= 0 ? n.substring(0, dash) : n).trim();
}

/// Days in [start, end) up to today (a period still running counts only
/// the days so far).
int elapsedDays(DateTime start, DateTime end) {
  final today = DateTime.now();
  final stop = end.isAfter(today)
      ? DateTime(today.year, today.month, today.day + 1)
      : end;
  final days = DateTime.utc(stop.year, stop.month, stop.day)
      .difference(DateTime.utc(start.year, start.month, start.day))
      .inDays;
  return days < 0 ? 0 : days;
}

/// Net worth just before each of [dates]: today's balances of the accounts
/// in [base] currency with every later transaction undone. Accounts in
/// other currencies are left out (never converted). [balances]: account id →
/// (balance now, currency).
List<double> netWorthAt(
  List<TransactionEntry> entries,
  Map<String, ({double balance, String currency})> balances,
  String base,
  List<DateTime> dates,
) {
  final now = balances.values
      .where((a) => a.currency == base)
      .fold(0.0, (t, a) => t + a.balance);
  bool counts(String? id) => balances[id]?.currency == base;
  // What each transaction did to base-currency accounts.
  final effects = <({DateTime date, double delta})>[];
  for (final e in entries) {
    var d = 0.0;
    if (e.tx.type == 'transfer') {
      if (counts(e.tx.accountId)) d -= e.tx.amount;
      final dest = e.tx.destinationAccountId;
      if (counts(dest)) {
        final destCur = balances[dest]!.currency;
        d += destCur != e.tx.currency && e.tx.exchangeRateToBase > 0
            ? e.tx.amount * e.tx.exchangeRateToBase
            : e.tx.amount;
      }
    } else {
      final sign = e.tx.type == 'income' ? 1.0 : -1.0;
      if (e.lines.isEmpty) {
        if (counts(e.tx.accountId)) d += sign * e.tx.amount;
      } else {
        for (final l in e.lines) {
          if (counts(l.accountId ?? e.tx.accountId)) d += sign * l.amount;
        }
      }
    }
    if (d != 0) effects.add((date: e.tx.createdAt.toLocal(), delta: d));
  }
  return [
    for (final cut in dates)
      now -
          effects
              .where((x) => !x.date.isBefore(cut))
              .fold(0.0, (t, x) => t + x.delta),
  ];
}
