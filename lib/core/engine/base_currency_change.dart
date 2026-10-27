import 'dart:convert';

import 'package:drift/drift.dart';

import '../database/app_database.dart';

/// A rate within this of 1.0 reads as "no rate" (see `isRealRate`), so a
/// converted rate that lands there is nudged just outside it.
const _noRateBand = 0.001;

double _nudge(double r) => (r - 1.0).abs() < _noRateBand
    ? (r >= 1.0 ? 1.0011 : 0.9989)
    : r;

/// The rate to the new base [to] for a row in [currency] whose rate to the
/// old base [from] was [oldRate], given 1 [from] = [rate] [to]. A row that
/// had no rate keeps none (unless it is now in the base itself).
double convertedRateToBase(
    String currency, double oldRate, String from, String to, double rate) {
  if (currency == to) return 1.0;
  if (currency == from) return _nudge(rate);
  if ((oldRate - 1.0).abs() < _noRateBand) return 1.0;
  return _nudge(oldRate * rate);
}

/// Change the household's base currency from [from] to [to] and convert
/// what is stored relative to it, so totals from before the change stay
/// right. [rate] is 1 [from] = [rate] [to] — one rate for all of history,
/// since past rates aren't kept. All or nothing.
///
/// - Lines and envelope ledger rows: their rate to base is converted.
/// - A transaction whose lines carry their accounts (the usual kind) keeps
///   its total in the base currency: it is added up again from the
///   converted lines, in [to].
/// - A transaction without per-line accounts keeps its amount (account
///   balances read it); only its rate to base is converted.
/// - Transfers are left alone: their rate is source → destination, not to
///   base, and balances depend on it.
///
/// On a shared budget every update here syncs like any other change, and
/// the change is added to `households.baseHistory`: a transaction another
/// phone recorded against [from] before it heard of this is converted with
/// [rate] when it arrives (`settleTransactions()`).
Future<void> changeBaseCurrency(AppDatabase db, String householdId,
    String from, String to, double rate) async {
  assert(rate > 0 && from != to);
  final now = DateTime.now();
  await db.transaction(() async {
    final household = await (db.select(db.households)
          ..where((h) => h.id.equals(householdId)))
        .getSingle();
    final history = [
      ...baseChanges(household.baseHistory),
      (from: from, to: to, rate: rate),
    ];
    final txs = await (db.select(db.transactions)
          ..where((t) => t.householdId.equals(householdId)))
        .get();
    final txIds = txs.map((t) => t.id).toSet();
    final lines = (await db.select(db.transactionLines).get())
        .where((l) => txIds.contains(l.transactionId))
        .toList();
    final ledger = await db.select(db.allocationLedger).get();

    final newRate = {
      for (final l in lines)
        l.id: convertedRateToBase(
            l.currency, l.exchangeRateToBase, from, to, rate),
    };
    final linesByTx = <String, List<TransactionLine>>{};
    for (final l in lines) {
      (linesByTx[l.transactionId] ??= []).add(l);
    }

    await db.batch((b) {
      for (final l in lines) {
        b.update(
            db.transactionLines,
            TransactionLinesCompanion(
                exchangeRateToBase: Value(newRate[l.id]!)),
            where: (x) => x.id.equals(l.id));
      }
      for (final t in txs) {
        if (t.type == 'transfer') continue;
        final own = linesByTx[t.id] ?? const <TransactionLine>[];
        final TransactionsCompanion change;
        if (own.isNotEmpty && own.every((l) => l.accountId != null)) {
          // As recordTransaction adds it up: lines without a rate are left
          // out of the base total.
          var total = 0.0;
          for (final l in own) {
            final r = newRate[l.id]!;
            if (l.currency == to) {
              total += l.amount;
            } else if ((r - 1.0).abs() >= _noRateBand) {
              total += l.amount * r;
            }
          }
          change = TransactionsCompanion(
            amount: Value(total),
            currency: Value(to),
            exchangeRateToBase: const Value(1.0),
            lastModified: Value(now),
          );
        } else {
          change = TransactionsCompanion(
            exchangeRateToBase: Value(convertedRateToBase(
                t.currency, t.exchangeRateToBase, from, to, rate)),
            lastModified: Value(now),
          );
        }
        b.update(db.transactions, change, where: (x) => x.id.equals(t.id));
      }
      for (final e in ledger) {
        b.update(
            db.allocationLedger,
            AllocationLedgerCompanion(
              exchangeRateToBase: Value(convertedRateToBase(
                  e.currency, e.exchangeRateToBase, from, to, rate)),
            ),
            where: (x) => x.id.equals(e.id));
      }
      b.update(
          db.households,
          HouseholdsCompanion(
            baseCurrency: Value(to),
            baseHistory: Value(jsonEncode([
              for (final c in history)
                {'from': c.from, 'to': c.to, 'rate': c.rate},
            ])),
            lastModified: Value(now),
          ),
          where: (x) => x.id.equals(householdId));
    });
  });
}

/// `households.baseHistory`, oldest first.
List<({String from, String to, double rate})> baseChanges(String? json) {
  if (json == null || json.isEmpty) return const [];
  try {
    return [
      for (final m in (jsonDecode(json) as List).cast<Map<String, dynamic>>())
        (
          from: m['from'] as String,
          to: m['to'] as String,
          rate: (m['rate'] as num).toDouble(),
        ),
    ];
  } catch (_) {
    return const [];
  }
}

/// The steps that take a transaction recorded against base [from] to
/// [to] by [history]: the changes from the last one that left [from]
/// onwards, or null when [history] doesn't lead from one to the other.
List<({String from, String to, double rate})>? basePath(
    List<({String from, String to, double rate})> history,
    String from,
    String to) {
  final start = history.lastIndexWhere((c) => c.from == from);
  if (start < 0) return null;
  final steps = history.sublist(start);
  for (var i = 1; i < steps.length; i++) {
    if (steps[i].from != steps[i - 1].to) return null;
  }
  return steps.last.to == to ? steps : null;
}
