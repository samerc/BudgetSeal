import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import 'database_provider.dart';
import 'household_provider.dart';

/// A transaction annotated with running account balance and display metadata.
class TransactionEntry {
  final Transaction tx;
  final List<TransactionLine> lines;
  final double accountBalanceAfter;

  /// Display name of the source account.
  final String accountName;

  /// Per-line account names (for multi-account display).
  final Map<String, String> lineAccountNames;

  const TransactionEntry({
    required this.tx,
    required this.lines,
    required this.accountBalanceAfter,
    required this.accountName,
    this.lineAccountNames = const {},
  });

  /// Unique account names involved in this transaction's lines.
  List<String> get involvedAccountNames {
    final names = <String>{};
    for (final line in lines) {
      final id = line.accountId ?? tx.accountId;
      final name = lineAccountNames[id];
      if (name != null) names.add(name);
    }
    if (names.isEmpty && accountName.isNotEmpty) {
      names.add(accountName);
    }
    return names.toList();
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Update running balances for a single transaction.
void _applyTxToRunning(
  Transaction tx,
  List<TransactionLine> txLines,
  Map<String, double> running,
) {
  switch (tx.type) {
    case 'income':
    case 'expense':
      final sign = tx.type == 'income' ? 1.0 : -1.0;
      if (txLines.isNotEmpty) {
        for (final line in txLines) {
          final acctId = line.accountId ?? tx.accountId;
          running[acctId] = (running[acctId] ?? 0) + sign * line.amount;
        }
      } else {
        running[tx.accountId] =
            (running[tx.accountId] ?? 0) + sign * tx.amount;
      }
    case 'transfer':
      running[tx.accountId] = (running[tx.accountId] ?? 0) - tx.amount;
      final dest = tx.destinationAccountId;
      if (dest != null) {
        running[dest] = (running[dest] ?? 0) + tx.amount;
      }
  }
}

/// Build a [TransactionEntry] from a transaction and its context.
TransactionEntry _buildEntry(
  Transaction tx,
  List<TransactionLine> txLines,
  Map<String, Account> accountMap,
  Map<String, double> running,
) {
  final lineAcctNames = <String, String>{};
  for (final line in txLines) {
    final id = line.accountId ?? tx.accountId;
    if (!lineAcctNames.containsKey(id)) {
      lineAcctNames[id] = accountMap[id]?.name ?? '';
    }
  }
  return TransactionEntry(
    tx: tx,
    lines: txLines,
    accountBalanceAfter: running[tx.accountId] ?? 0,
    accountName: accountMap[tx.accountId]?.name ?? '',
    lineAccountNames: lineAcctNames,
  );
}

/// Fetch accounts and transaction lines for a set of transactions.
Future<({Map<String, Account> accountMap, Map<String, List<TransactionLine>> linesByTx})>
    _fetchRelated(AppDatabase db, String householdId, List<Transaction> txList) async {
  final accounts = await (db.select(db.accounts)
        ..where((a) => a.householdId.equals(householdId)))
      .get();
  final accountMap = {for (final a in accounts) a.id: a};

  final allLines = txList.isEmpty
      ? <TransactionLine>[]
      : await (db.select(db.transactionLines)
            ..where((l) => l.transactionId.isIn(txList.map((t) => t.id))))
          .get();
  final linesByTx = <String, List<TransactionLine>>{};
  for (final line in allLines) {
    linesByTx.putIfAbsent(line.transactionId, () => []).add(line);
  }

  return (accountMap: accountMap, linesByTx: linesByTx);
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/// Emits ALL transactions for the current household, newest-first,
/// each annotated with the running account balance at that point in time.
///
/// Keep this for screens that need the full dataset (reports, category trends).
final transactionEntriesProvider =
    StreamProvider<List<TransactionEntry>>((ref) async* {
  final db = ref.watch(databaseProvider);
  final householdId = ref.watch(currentHouseholdIdProvider);
  if (householdId == null) {
    yield [];
    return;
  }

  final txStream = (db.select(db.transactions)
        ..where((t) => t.householdId.equals(householdId))
        ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
      .watch();

  await for (final txList in txStream) {
    final related = await _fetchRelated(db, householdId, txList);

    final running = <String, double>{
      for (final a in related.accountMap.values) a.id: a.initialBalance,
    };

    final result = <TransactionEntry>[];
    for (final tx in txList) {
      final txLines = related.linesByTx[tx.id] ?? [];
      _applyTxToRunning(tx, txLines, running);
      result.add(_buildEntry(tx, txLines, related.accountMap, running));
    }

    yield result.reversed.toList();
  }
});

/// Emits transactions for a single month, newest-first, with correct running
/// balances. The month's transactions are queried at the SQL level so we never
/// load the full history into Dart.
///
/// Running balances are computed by replaying all prior transactions (fetched
/// once per emission) and then the target month's transactions.
final monthlyTransactionsProvider = StreamProvider.family<
    List<TransactionEntry>, ({int year, int month})>((ref, param) async* {
  final db = ref.watch(databaseProvider);
  final householdId = ref.watch(currentHouseholdIdProvider);
  if (householdId == null) {
    yield [];
    return;
  }

  final dao = db.transactionsDao;
  final monthStream = dao.watchByMonth(householdId, param.year, param.month);

  await for (final monthTxList in monthStream) {
    final related = await _fetchRelated(db, householdId, monthTxList);

    // Build running balances from initial balances + all prior transactions.
    final running = <String, double>{
      for (final a in related.accountMap.values) a.id: a.initialBalance,
    };

    final priorTxList =
        await dao.getBeforeMonth(householdId, param.year, param.month);
    // We only need the lines for prior transactions to update running balances.
    final priorLines = priorTxList.isEmpty
        ? <TransactionLine>[]
        : await (db.select(db.transactionLines)
              ..where(
                  (l) => l.transactionId.isIn(priorTxList.map((t) => t.id))))
            .get();
    final priorLinesByTx = <String, List<TransactionLine>>{};
    for (final line in priorLines) {
      priorLinesByTx.putIfAbsent(line.transactionId, () => []).add(line);
    }
    for (final tx in priorTxList) {
      _applyTxToRunning(tx, priorLinesByTx[tx.id] ?? [], running);
    }

    // Now process the target month's transactions.
    final result = <TransactionEntry>[];
    for (final tx in monthTxList) {
      final txLines = related.linesByTx[tx.id] ?? [];
      _applyTxToRunning(tx, txLines, running);
      result.add(_buildEntry(tx, txLines, related.accountMap, running));
    }

    yield result.reversed.toList();
  }
});

/// Current month's transactions — convenience alias for dashboard use.
/// Returns the same [AsyncValue] as [monthlyTransactionsProvider] for this
/// calendar month.
final currentMonthTransactionsProvider =
    Provider<AsyncValue<List<TransactionEntry>>>((ref) {
  final now = DateTime.now();
  return ref.watch(
      monthlyTransactionsProvider((year: now.year, month: now.month)));
});

/// Emits the most recent N transactions (default 10), newest-first.
/// Ideal for the dashboard's "Recent Transactions" section.
final recentTransactionsProvider =
    StreamProvider<List<TransactionEntry>>((ref) async* {
  final db = ref.watch(databaseProvider);
  final householdId = ref.watch(currentHouseholdIdProvider);
  if (householdId == null) {
    yield [];
    return;
  }

  final recentStream = db.transactionsDao.watchRecent(householdId, limit: 10);

  await for (final txList in recentStream) {
    final related = await _fetchRelated(db, householdId, txList);

    // For recent transactions we don't need precise running balances —
    // we just show the current account balance as a reasonable approximation.
    // Full balance computation would require loading ALL prior transactions,
    // defeating the purpose. Use 0.0 as a placeholder; the dashboard UI
    // doesn't display accountBalanceAfter for the recent list.
    final result = <TransactionEntry>[];
    for (final tx in txList) {
      final txLines = related.linesByTx[tx.id] ?? [];
      final lineAcctNames = <String, String>{};
      for (final line in txLines) {
        final id = line.accountId ?? tx.accountId;
        if (!lineAcctNames.containsKey(id)) {
          lineAcctNames[id] = related.accountMap[id]?.name ?? '';
        }
      }
      result.add(TransactionEntry(
        tx: tx,
        lines: txLines,
        accountBalanceAfter: 0,
        accountName: related.accountMap[tx.accountId]?.name ?? '',
        lineAccountNames: lineAcctNames,
      ));
    }

    yield result;
  }
});
