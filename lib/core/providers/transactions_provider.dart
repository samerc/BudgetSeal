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

/// Emits all transactions for the current household, newest-first,
/// each annotated with the running account balance at that point in time.
final transactionEntriesProvider =
    StreamProvider<List<TransactionEntry>>((ref) async* {
  final db = ref.watch(databaseProvider);
  final householdId = ref.watch(currentHouseholdIdProvider);
  if (householdId == null) {
    yield [];
    return;
  }

  // Watch transactions oldest-first so we can build running balances in one pass.
  final txStream = (db.select(db.transactions)
        ..where((t) => t.householdId.equals(householdId))
        ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
      .watch();

  await for (final txList in txStream) {
    // Fetch all accounts for initial balances and name lookup.
    final accounts = await (db.select(db.accounts)
          ..where((a) => a.householdId.equals(householdId)))
        .get();
    final accountMap = {for (final a in accounts) a.id: a};

    // Fetch all transaction lines in one query.
    final allLines = await (db.select(db.transactionLines)
          ..where((l) => l.transactionId.isIn(txList.map((t) => t.id))))
        .get();
    final linesByTx = <String, List<TransactionLine>>{};
    for (final line in allLines) {
      linesByTx.putIfAbsent(line.transactionId, () => []).add(line);
    }

    // Seed running balances from initial account balances.
    final Map<String, double> running = {
      for (final a in accounts) a.id: a.initialBalance,
    };

    // Process oldest → newest, updating running balance per account.
    // For income/expense: each line may reference a different account,
    // so distribute amounts to each line's account individually.
    final result = <TransactionEntry>[];
    for (final tx in txList) {
      final txLines = linesByTx[tx.id] ?? [];

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
            // Legacy transactions without lines.
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
      // Build per-line account name map.
      final lineAcctNames = <String, String>{};
      for (final line in txLines) {
        final id = line.accountId ?? tx.accountId;
        if (!lineAcctNames.containsKey(id)) {
          lineAcctNames[id] = accountMap[id]?.name ?? '';
        }
      }

      result.add(TransactionEntry(
        tx: tx,
        lines: txLines,
        accountBalanceAfter: running[tx.accountId] ?? 0,
        accountName: accountMap[tx.accountId]?.name ?? '',
        lineAccountNames: lineAcctNames,
      ));
    }

    // Display newest-first.
    yield result.reversed.toList();
  }
});
