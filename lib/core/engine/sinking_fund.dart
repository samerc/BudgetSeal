import 'dart:math' as math;

import '../../shared/utils/format_number.dart' show currencyDecimals;
import 'period_engine.dart' show budgetPeriodFor;

/// One payment a sinking fund saves for: a planned payment, an occurrence
/// of a yearly/quarterly recurring bill, or one already paid from the fund.
/// [amounts] holds one part per currency (school fees paid half in USD and
/// half in LBP), never converted.
class FundPayment {
  final String title;
  final DateTime date;
  final Map<String, double> amounts;
  final List<String> accountIds;

  /// The plan behind it (editable, postable); null for bills and paid ones.
  final String? planId;

  /// The recurring bill it comes from.
  final String? recurringId;

  /// The posted transaction, once paid.
  final String? txId;

  const FundPayment({
    required this.title,
    required this.date,
    required this.amounts,
    this.accountIds = const [],
    this.planId,
    this.recurringId,
    this.txId,
  });

  bool get paid => txId != null;
}

/// How a fund that fell behind catches up.
enum BehindMode {
  /// Ask each time (stored as null).
  ask,

  /// Raise the monthly amount until the next payment.
  spread,

  /// Put the shortfall in now, then the steady amount.
  topUp;

  static BehindMode parse(String? v) => switch (v) {
        'spread' => spread,
        'topup' => topUp,
        _ => ask,
      };

  String? get stored => switch (this) {
        spread => 'spread',
        topUp => 'topup',
        ask => null,
      };
}

/// A run of budget periods that each need the same amounts.
class FundPlanStep {
  /// First and last period start of the run.
  final DateTime from;
  final DateTime to;
  final Map<String, double> amounts;

  const FundPlanStep(this.from, this.to, this.amounts);
}

/// What a sinking fund needs, per currency.
class FundPlan {
  /// Unpaid payments, soonest first (overdue ones included).
  final List<FundPayment> upcoming;

  /// This period's full share when spreading the shortfall (or simply the
  /// share when on track).
  final Map<String, double> spread;

  /// This period's full share when topping up now.
  final Map<String, double> topUp;

  /// How far behind the steady plan the fund still is, after what went in
  /// this period (only currencies behind).
  final Map<String, double> behind;

  /// What went in during this period.
  final Map<String, double> funded;

  /// The monthly plan from this period on, when spreading.
  final List<FundPlanStep> spreadSteps;

  /// The monthly plan from this period on, after topping up.
  final List<FundPlanStep> topUpSteps;

  const FundPlan({
    required this.upcoming,
    required this.spread,
    required this.topUp,
    required this.behind,
    required this.funded,
    required this.spreadSteps,
    required this.topUpSteps,
  });

  FundPayment? get next => upcoming.isEmpty ? null : upcoming.first;
  bool get isBehind => behind.isNotEmpty;

  /// This period's share for [mode] (asking = spread until the user picks).
  Map<String, double> share(BehindMode mode) =>
      mode == BehindMode.topUp ? topUp : spread;

  List<FundPlanStep> steps(BehindMode mode) =>
      mode == BehindMode.topUp ? topUpSteps : spreadSteps;

  /// What is still to put in this period: the share less what went in.
  Map<String, double> remaining(BehindMode mode) {
    final out = <String, double>{};
    share(mode).forEach((c, v) {
      final left = _roundUp(v - (funded[c] ?? 0), c);
      if (left > 0) out[c] = left;
    });
    return out;
  }
}

/// Plans a sinking fund: the smallest steady amount each budget period that
/// has every payment covered by its date — for each payment, what is due up
/// to it less what is saved, over the fundings left before it (the period it
/// falls in counts: money goes in at the start of a period) — recalculated
/// every period, in each currency on its own.
///
/// Balances come from the ledger: [balanceAtStart] is the fund at the start
/// of this period plus what was paid from it since (so a payment made this
/// period still counts as due this period), [funded] what went in this
/// period. [anchor] is the period start the steady plan is measured from
/// (the fund's first period, at most a year back) with [balanceAtAnchor];
/// [payments] holds the paid ones from [anchor] on and every unpaid one.
/// Behind = what following the plan from [anchor] would hold now, less what
/// the fund holds.
FundPlan planSinkingFund({
  required List<FundPayment> payments,
  required Map<String, double> balanceAtStart,
  required Map<String, double> funded,
  required DateTime anchor,
  required Map<String, double> balanceAtAnchor,
  required int startDay,
  DateTime? now,
}) {
  now ??= DateTime.now();
  final current = budgetPeriodFor(startDay, now).start;
  int index(DateTime d) {
    final p = budgetPeriodFor(startDay, d).start;
    return (p.year - current.year) * 12 + p.month - current.month;
  }

  DateTime periodAt(int i) {
    final m = DateTime(current.year, current.month + i, 1);
    final last = DateTime(m.year, m.month + 1, 0).day;
    return DateTime(m.year, m.month, startDay.clamp(1, last));
  }

  final upcoming = payments.where((p) => !p.paid).toList()
    ..sort((a, b) => a.date.compareTo(b.date));
  final paidNow = payments.where((p) => p.paid && index(p.date) == 0);
  final currencies = <String>{
    for (final p in upcoming) ...p.amounts.keys,
    for (final p in paidNow) ...p.amounts.keys,
  };

  // Payments by period index, per currency (an overdue unpaid one is due
  // now).
  final due = <String, List<({int at, double amount})>>{
    for (final c in currencies)
      c: [
        for (final p in payments)
          if ((p.amounts[c] ?? 0) > 0)
            (
              at: p.paid ? index(p.date) : math.max(index(p.date), 0),
              amount: p.amounts[c]!,
            ),
      ]..sort((a, b) => a.at.compareTo(b.at)),
  };

  double levelNeed(String c, double balance, int k) {
    var cum = 0.0;
    var need = 0.0;
    for (final p in due[c]!) {
      if (p.at < k) continue;
      cum += p.amount;
      need = math.max(need, (cum - balance) / (p.at - k + 1));
    }
    return need;
  }

  double paidIn(String c, int k) => [
        for (final p in due[c]!)
          if (p.at == k) p.amount,
      ].fold(0.0, (a, b) => a + b);

  // Shares from this period on, from a starting balance: one step per run
  // of equal amounts, up to the last payment.
  final lastAt = upcoming.isEmpty
      ? 0
      : upcoming.map((p) => math.max(index(p.date), 0)).reduce(math.max);
  List<FundPlanStep> stepsFrom(Map<String, double> start,
      Map<String, double> first) {
    final bal = {for (final c in currencies) c: start[c] ?? 0.0};
    final steps = <FundPlanStep>[];
    for (var k = 0; k <= lastAt; k++) {
      final amounts = <String, double>{};
      for (final c in currencies) {
        // This period: the share, or more if more already went in.
        final need = k == 0
            ? math.max(first[c] ?? 0, funded[c] ?? 0)
            : levelNeed(c, bal[c]!, k);
        bal[c] = bal[c]! + need - paidIn(c, k);
        final v = _roundUp(need, c);
        if (v > 0) amounts[c] = v;
      }
      if (amounts.isEmpty) continue;
      final last = steps.isEmpty ? null : steps.last;
      if (last != null &&
          index(last.to) == k - 1 &&
          _same(last.amounts, amounts)) {
        steps[steps.length - 1] = FundPlanStep(last.from, periodAt(k), amounts);
      } else {
        steps.add(FundPlanStep(periodAt(k), periodAt(k), amounts));
      }
    }
    return steps;
  }

  // The steady plan since [anchor], had every period been funded.
  final from = math.min(index(anchor), 0);
  final ideal = {for (final c in currencies) c: balanceAtAnchor[c] ?? 0.0};
  for (var k = from; k < 0; k++) {
    for (final c in currencies) {
      ideal[c] = ideal[c]! + levelNeed(c, ideal[c]!, k) - paidIn(c, k);
    }
  }

  final spread = <String, double>{};
  final topUp = <String, double>{};
  final behind = <String, double>{};
  for (final c in currencies) {
    final actual = balanceAtStart[c] ?? 0.0;
    final steady = levelNeed(c, ideal[c]!, 0);
    final short = ideal[c]! - actual;
    // Behind only by more than a rounding slip: 1 % of the share, at least
    // one unit of the currency. What went in this period counts toward it.
    final slip = math.max(1.0, steady * 0.01);
    spread[c] = levelNeed(c, actual, 0);
    topUp[c] = short > slip ? short + steady : spread[c]!;
    final still = short - (funded[c] ?? 0);
    if (still > slip) behind[c] = _roundUp(still, c);
  }

  return FundPlan(
    upcoming: upcoming,
    spread: _rounded(spread),
    topUp: _rounded(topUp),
    behind: behind,
    funded: funded,
    spreadSteps: stepsFrom(balanceAtStart, spread),
    topUpSteps: stepsFrom(balanceAtStart, topUp),
  );
}

/// Occurrences of a recurring bill from [next] until [until]: yearly or
/// every 3+ months only (monthly bills fit a normal spending envelope).
List<DateTime> fundBillDates({
  required String frequency,
  required int interval,
  required DateTime next,
  DateTime? endDate,
  required DateTime until,
  int? anchorDay,
}) {
  final months = switch (frequency) {
    'yearly' => 12 * interval,
    'monthly' when interval >= 3 => interval,
    _ => 0,
  };
  if (months == 0) return const [];
  final day = anchorDay ?? next.day;
  final out = <DateTime>[];
  for (var i = 0;; i++) {
    final m = DateTime(next.year, next.month + months * i, 1);
    final last = DateTime(m.year, m.month + 1, 0).day;
    final d = DateTime(m.year, m.month, i == 0 ? next.day : math.min(day, last));
    if (d.isAfter(until) || (endDate != null && d.isAfter(endDate))) break;
    out.add(d);
  }
  return out;
}

/// Whether a recurring bill can be saved for in a fund.
bool isFundBill(String frequency, int interval) =>
    frequency == 'yearly' || (frequency == 'monthly' && interval >= 3);

/// "Copy from last year": the fund's payments of the past year (paid, or
/// still planned) a year later, for a new schedule. Ones that would fall in
/// the past are left out; [alreadyPlanned] marks a copy whose date is within
/// two weeks of a plan the fund already has.
List<({FundPayment payment, bool alreadyPlanned})> copyFromLastYear(
  List<FundPayment> payments, {
  DateTime? now,
}) {
  now ??= DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yearAgo = DateTime(today.year - 1, today.month, today.day);
  final plans = payments.where((p) => p.planId != null).toList();
  final out = <({FundPayment payment, bool alreadyPlanned})>[];
  for (final p in payments) {
    if (p.recurringId != null) continue; // bills repeat on their own
    if (p.date.isBefore(yearAgo)) continue;
    final last = DateTime(p.date.year + 1, p.date.month + 1, 0).day;
    final date = DateTime(
        p.date.year + 1, p.date.month, math.min(p.date.day, last));
    if (!date.isAfter(today)) continue;
    final dup = plans.any((q) => q.date.difference(date).inDays.abs() <= 14);
    out.add((
      payment: FundPayment(
        title: p.title,
        date: date,
        amounts: p.amounts,
        accountIds: p.accountIds,
      ),
      alreadyPlanned: dup,
    ));
  }
  out.sort((a, b) => a.payment.date.compareTo(b.payment.date));
  return out;
}

/// Rounds a share up to the currency's smallest unit, so steady payments
/// never fall short by a cent.
double _roundUp(double v, String currency) {
  if (v <= 0.000001) return 0;
  final f = math.pow(10, currencyDecimals(currency)).toDouble();
  return (v * f - 1e-6).ceilToDouble() / f;
}

Map<String, double> _rounded(Map<String, double> m) => {
      for (final e in m.entries)
        if (_roundUp(e.value, e.key) > 0) e.key: _roundUp(e.value, e.key),
    };

bool _same(Map<String, double> a, Map<String, double> b) =>
    a.length == b.length &&
    a.entries.every((e) => ((b[e.key] ?? -1) - e.value).abs() < 0.0001);
