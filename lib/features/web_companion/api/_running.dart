import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';

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
  final lines = txs.isEmpty
      ? <TransactionLine>[]
      : await (db.select(db.transactionLines)
            ..where((l) => l.transactionId.isIn(txs.map((t) => t.id))))
          .get();
  final byTx = <String, List<TransactionLine>>{};
  for (final l in lines) {
    (byTx[l.transactionId] ??= []).add(l);
  }

  var balance = account.initialBalance;
  final out = <String, ({double effect, double balance})>{};
  for (final t in txs) {
    var effect = 0.0;
    if (t.type == 'transfer') {
      if (t.accountId == id) effect -= t.amount;
      if (t.destinationAccountId == id) effect += t.amount * t.exchangeRateToBase;
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
