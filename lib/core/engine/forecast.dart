import 'dart:math' as math;

import '../../shared/utils/calendar_days.dart';
import '../database/app_database.dart';
import 'recurring_engine.dart' show advanceRecurringDate, recurringAmountOn;
import 'sinking_fund.dart' show FundPayment;

/// Where a forecast item comes from.
enum ForecastKind { bill, income, planned, estimate }

/// One dated movement in the forecast, in one currency: negative = out.
class ForecastEvent {
  final DateTime date;
  final String title;
  final double amount;
  final String currency;
  final ForecastKind kind;

  const ForecastEvent(this.date, this.title, this.amount, this.currency,
      this.kind);

  bool get isIncome => amount > 0;
}

/// A planned payment's part in one currency (planned payments can be
/// split over currencies).
class PlannedPart {
  final DateTime date;
  final String title;
  final String type; // 'income' | 'expense'
  final double amount;
  final String currency;
  const PlannedPart(this.date, this.title, this.type, this.amount, this.currency);
}

/// A sinking fund as the forecast needs it: what it holds, what it still
/// needs this period, and its upcoming payments.
class ForecastFund {
  final Map<String, double> balances;
  final Map<String, double> thisPeriod;
  final List<FundPayment> upcoming;
  const ForecastFund(this.balances, this.thisPeriod, this.upcoming);
}

/// An income received (an estimate's sample).
class PastIncome {
  final DateTime date;
  final double amount;
  final String currency;
  const PastIncome(this.date, this.amount, this.currency);
}

/// One currency's forecast.
class CurrencyForecast {
  final String currency;

  /// Money in the accounts today.
  final double start;

  /// Every movement from today to the horizon, by date.
  final List<ForecastEvent> events;

  /// The balance at the end of each day, today first.
  final List<double> daily;
  final DateTime today;

  final double lowest;
  final DateTime lowestOn;

  /// The next income (scheduled, else estimated), or null.
  final ForecastEvent? nextIncome;

  /// What's due before the next income (or the next 30 days without one).
  final double dueBefore;

  /// Money set aside in sinking funds and not needed before then, plus
  /// what's still to set aside this period.
  final double reserved;

  /// Days from today to the next income (at least 1).
  final int daysLeft;

  /// Per day until the next income: cash − due − reserved, ÷ days; never
  /// below 0 ([short] says by how much it falls short).
  final double safeToSpend;
  final double short;

  const CurrencyForecast({
    required this.currency,
    required this.start,
    required this.events,
    required this.daily,
    required this.today,
    required this.lowest,
    required this.lowestOn,
    required this.nextIncome,
    required this.dueBefore,
    required this.reserved,
    required this.daysLeft,
    required this.safeToSpend,
    required this.short,
  });

  bool get hasEstimate => events.any((e) => e.kind == ForecastKind.estimate);
}

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

/// The forecast for each currency in [cash] (roadmap #4; user's
/// decisions): recurring bills and incomes ([recurring], their future
/// dates and price changes), planned payments ([planned]) — anything
/// overdue counts today — and, for a currency with no scheduled income, an
/// estimate from the last three months' incomes ([pastIncome]) on their
/// usual day. Transfers between accounts are left out. Currencies are
/// never mixed. "Safe to spend today" is cash until the next income: what
/// the accounts hold, less what's due before it and what the sinking funds
/// ([funds]) keep for later, per day.
Map<String, CurrencyForecast> buildForecast({
  required DateTime now,
  required Map<String, double> cash,
  List<RecurringTransaction> recurring = const [],
  List<PlannedPart> planned = const [],
  List<ForecastFund> funds = const [],
  List<PastIncome> pastIncome = const [],
  int days = 90,
}) {
  final today = _day(now);
  final horizon = today.add(Duration(days: days));
  final events = <String, List<ForecastEvent>>{};
  void add(ForecastEvent e) {
    if (e.date.isAfter(horizon)) return;
    (events[e.currency] ??= []).add(e);
  }

  for (final r in recurring) {
    if (!r.enabled || r.deleted || r.type == 'transfer') continue;
    var d = r.nextDueDate;
    for (var i = 0; i < 400 && !_day(d).isAfter(horizon); i++) {
      if (r.endDate != null && _day(d).isAfter(_day(r.endDate!))) break;
      final amount = recurringAmountOn(r, d);
      final when = _day(d).isBefore(today) ? today : _day(d);
      add(ForecastEvent(when, r.title.isNotEmpty ? r.title : r.note,
          r.type == 'income' ? amount : -amount, r.currency,
          r.type == 'income' ? ForecastKind.income : ForecastKind.bill));
      d = advanceRecurringDate(d, r.frequency, r.interval,
          anchorDay: r.anchorDay);
    }
  }
  for (final p in planned) {
    final when = _day(p.date).isBefore(today) ? today : _day(p.date);
    add(ForecastEvent(when, p.title,
        p.type == 'income' ? p.amount : -p.amount, p.currency,
        ForecastKind.planned));
  }

  // No scheduled income in a currency: the last three months' average, on
  // the day it usually came.
  final currencies = {...cash.keys, ...events.keys};
  for (final c in currencies) {
    if ((events[c] ?? const []).any((e) => e.isIncome)) continue;
    final since = today.subtract(const Duration(days: 92));
    final past = [
      for (final p in pastIncome)
        if (p.currency == c && !p.date.isBefore(since) && p.amount > 0) p,
    ];
    if (past.isEmpty) continue;
    final monthly = past.fold(0.0, (s, p) => s + p.amount) / 3;
    // The usual day: of the bigger incomes, the middle one's day.
    final big = [for (final p in past) if (p.amount >= monthly / 2) p.date.day]
      ..sort();
    final day = big.isEmpty ? past.last.date.day : big[big.length ~/ 2];
    for (var m = 0; m <= days ~/ 28 + 1; m++) {
      final first = DateTime(today.year, today.month + m);
      final last = DateTime(first.year, first.month + 1, 0).day;
      final d = DateTime(first.year, first.month, math.min(day, last));
      if (d.isAfter(today)) {
        add(ForecastEvent(d, '', monthly, c, ForecastKind.estimate));
      }
    }
  }

  final out = <String, CurrencyForecast>{};
  for (final c in currencies) {
    final list = (events[c] ?? <ForecastEvent>[])
      ..sort((a, b) => a.date.compareTo(b.date));
    final start = cash[c] ?? 0;
    final daily = <double>[];
    var balance = start;
    var i = 0;
    var lowest = start;
    var lowestOn = today;
    for (var d = 0; d <= days; d++) {
      final day = today.add(Duration(days: d));
      while (i < list.length && !list[i].date.isAfter(day)) {
        balance += list[i++].amount;
      }
      daily.add(balance);
      if (balance < lowest) {
        lowest = balance;
        lowestOn = day;
      }
    }

    final next = list.where((e) => e.isIncome && e.date.isAfter(today)).firstOrNull;
    final until = next?.date ?? today.add(const Duration(days: 30));
    final daysLeft = math.max(1, calendarDaysBetween(today, until));
    final dueBefore = -list
        .where((e) => !e.isIncome && e.date.isBefore(until))
        .fold(0.0, (s, e) => s + e.amount);
    var reserved = 0.0;
    for (final f in funds) {
      final paidBefore = f.upcoming
          .where((p) => p.date.isBefore(until))
          .fold(0.0, (s, p) => s + (p.amounts[c] ?? 0));
      reserved += math.max(0, (f.balances[c] ?? 0) - paidBefore) +
          (f.thisPeriod[c] ?? 0);
    }
    final free = start - dueBefore - reserved;
    out[c] = CurrencyForecast(
      currency: c,
      start: start,
      events: list,
      daily: daily,
      today: today,
      lowest: lowest,
      lowestOn: lowestOn,
      nextIncome: next,
      dueBefore: dueBefore,
      reserved: reserved,
      daysLeft: daysLeft,
      safeToSpend: math.max(0, free) / daysLeft,
      short: free < 0 ? -free : 0,
    );
  }
  return out;
}
