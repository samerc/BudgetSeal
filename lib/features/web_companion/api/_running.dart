import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/budget_impact_provider.dart';
import '../../../core/database/transfer_amounts.dart';

/// Per transaction touching [account]: its signed effect on that account (in
/// the account's currency) and the account balance right after it. Replays
/// the account's whole posted history from its initial balance, oldest first
/// (createdAt, then id — the list's order reversed), with the same rules as
/// the app's `_applyTxToRunning()`: income/expense lines count on their own
/// account (header account when a line has none), a transfer takes the amount
/// from the source and adds amount × rate to the destination.
Future<Map<String, ({double effect, double balance})>> accountRunning(
    AppDatabase db, Account account) async {
  final id = account.id;
  final lineTx = db.selectOnly(db.transactionLines)
    ..addColumns([db.transactionLines.transactionId])
    ..where(db.transactionLines.accountId.equals(id));
  final txs = await (db.select(db.transactions)
        ..where((t) =>
            t.householdId.equals(account.householdId) &
            t.deleted.equals(false) &
            t.status.isNull() &
            (t.accountId.equals(id) |
                t.destinationAccountId.equals(id) |
                t.id.isInQuery(lineTx)))
        ..orderBy([
          (t) => OrderingTerm.asc(t.createdAt),
          (t) => OrderingTerm.asc(t.id),
        ]))
      .get();
  final byTx =
      await db.transactionsDao.linesByTransaction(txs.map((t) => t.id));

  var balance = account.initialBalance;
  final out = <String, ({double effect, double balance})>{};
  for (final t in txs) {
    var effect = 0.0;
    if (t.type == 'transfer') {
      if (t.accountId == id) effect -= t.amount;
      if (t.destinationAccountId == id) {
        effect += t.receivedAmount;
      }
    } else {
      final sign = t.type == 'income' ? 1.0 : -1.0;
      final txLines = byTx[t.id] ?? const [];
      if (txLines.isEmpty) {
        if (t.accountId == id) effect = sign * t.amount;
      } else {
        for (final l in txLines) {
          if ((l.accountId ?? t.accountId) == id) effect += sign * l.amount;
        }
      }
    }
    balance += effect;
    out[t.id] = (effect: effect, balance: balance);
  }
  return out;
}

/// Every account's balance right after each posted transaction (same rules
/// as [accountRunning]): transaction id → {account id → balance after}, for
/// the accounts that transaction touched. One replay of the whole history.
Future<Map<String, Map<String, double>>> allAccountsRunning(
    AppDatabase db, String householdId) async {
  final accounts = await (db.select(db.accounts)
        ..where((a) => a.householdId.equals(householdId)))
      .get();
  final balance = {for (final a in accounts) a.id: a.initialBalance};
  final txs = await (db.select(db.transactions)
        ..where((t) =>
            t.householdId.equals(householdId) &
            t.deleted.equals(false) &
            t.status.isNull())
        ..orderBy([
          (t) => OrderingTerm.asc(t.createdAt),
          (t) => OrderingTerm.asc(t.id),
        ]))
      .get();
  final lines = await (db.select(db.transactionLines).join([
    innerJoin(db.transactions,
        db.transactions.id.equalsExp(db.transactionLines.transactionId)),
  ])
        ..where(db.transactions.householdId.equals(householdId) &
            db.transactions.deleted.equals(false) &
            db.transactions.status.isNull()))
      .map((r) => r.readTable(db.transactionLines))
      .get();
  final byTx = <String, List<TransactionLine>>{};
  for (final l in lines) {
    (byTx[l.transactionId] ??= []).add(l);
  }

  final out = <String, Map<String, double>>{};
  for (final t in txs) {
    final touched = <String, double>{};
    void add(String? id, double v) {
      if (id == null) return;
      balance[id] = (balance[id] ?? 0) + v;
      touched[id] = balance[id]!;
    }

    if (t.type == 'transfer') {
      add(t.accountId, -t.amount);
      add(t.destinationAccountId, t.receivedAmount);
    } else {
      final sign = t.type == 'income' ? 1.0 : -1.0;
      final txLines = byTx[t.id] ?? const [];
      if (txLines.isEmpty) {
        add(t.accountId, sign * t.amount);
      } else {
        for (final l in txLines) {
          add(l.accountId ?? t.accountId, sign * l.amount);
        }
      }
    }
    out[t.id] = touched;
  }
  return out;
}

/// Extra fields for transaction rows, as the app's list shows them:
/// `impact` (the envelope an expense spent from and its balance right after)
/// and `balanceAfter` (the account's balance right after; a transfer's
/// destination, `accountCount` when several accounts were touched).
Future<Map<String, dynamic> Function(Transaction)> txRowExtras(
    AppDatabase db,
    String householdId,
    List<Transaction> txs,
    Map<String, Account> acctMap) async {
  if (txs.isEmpty) return (_) => const <String, dynamic>{};
  final impacts = await envelopeImpactQuery(db, householdId).getSingle();
  final after = await allAccountsRunning(db, householdId);
  return (t) {
    final out = <String, dynamic>{};
    final touched = after[t.id];
    if (touched != null && touched.isNotEmpty) {
      final dest = t.destinationAccountId;
      final id = t.type == 'transfer' && touched.containsKey(dest)
          ? dest
          : touched.length == 1
              ? touched.keys.first
              : null;
      out['balanceAfter'] = id == null
          ? {'accountCount': touched.length}
          : {
              'accountId': id,
              'accountName': acctMap[id]?.name,
              'currency': acctMap[id]?.currency,
              'balance': touched[id],
            };
    }
    final impact = impacts[t.id];
    if (impact != null) {
      out['impact'] = {
        'envelopeId': impact.allocationId,
        'name': impact.name,
        'currency': impact.currency,
        'balanceAfter': impact.balanceAfter,
        'balanceNow': impact.balanceNow,
        'latest': impact.isLatest,
        'count': impact.envelopeCount,
      };
    }
    return out;
  };
}
