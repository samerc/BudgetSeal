import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import 'database_provider.dart';
import 'family_provider.dart';
import 'household_provider.dart';
import '../database/transfer_amounts.dart';

/// A transaction annotated with running account balance and display metadata.
class TransactionEntry {
  final Transaction tx;
  final List<TransactionLine> lines;
  final double accountBalanceAfter;

  /// Display name of the source account.
  final String accountName;

  /// Currency of the source account (may differ from tx.currency).
  final String accountCurrency;

  /// Display name of the destination account (transfers only).
  final String? destinationAccountName;

  /// Currency of the destination account (transfers only).
  final String? destinationAccountCurrency;

  /// Running balance of the destination account after this transfer.
  final double? destinationAccountBalanceAfter;

  /// Per-line account names (for multi-account display).
  final Map<String, String> lineAccountNames;

  /// Spent from another member's private envelope (roadmap #5): shown as
  /// "Private" with the amount only — its note and categories are blanked.
  final bool isPrivate;

  const TransactionEntry({
    required this.tx,
    required this.lines,
    required this.accountBalanceAfter,
    required this.accountName,
    this.accountCurrency = 'USD',
    this.destinationAccountName,
    this.destinationAccountCurrency,
    this.destinationAccountBalanceAfter,
    this.lineAccountNames = const {},
    this.isPrivate = false,
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
        running[dest] = (running[dest] ?? 0) + tx.receivedAmount;
      }
  }
}

/// Build a [TransactionEntry] from a transaction and its context.
TransactionEntry _buildEntry(
  Transaction tx,
  List<TransactionLine> txLines,
  Map<String, Account> accountMap,
  Map<String, double> running, [
  Set<String> hiddenCategories = const {},
]) {
  // Every line in a hidden category: show it as "Private", amount only.
  final private = hiddenCategories.isNotEmpty &&
      tx.type != 'transfer' &&
      txLines.isNotEmpty &&
      txLines.every((l) => hiddenCategories.contains(l.categoryId));
  if (private) {
    tx = tx.copyWith(note: '', categoryId: const Value(null));
    txLines = [
      for (final l in txLines)
        l.copyWith(note: '', categoryId: const Value(null)),
    ];
  }
  final lineAcctNames = <String, String>{};
  for (final line in txLines) {
    final id = line.accountId ?? tx.accountId;
    if (!lineAcctNames.containsKey(id)) {
      lineAcctNames[id] = accountMap[id]?.name ?? '';
    }
  }
  final destAcct = tx.destinationAccountId != null
      ? accountMap[tx.destinationAccountId]
      : null;

  // For single-line transactions with a per-line account, use the line's
  // account for display (name, currency, running balance).
  final effectiveAccountId =
      (txLines.length == 1 && txLines.first.accountId != null)
          ? txLines.first.accountId!
          : tx.accountId;
  final effectiveAcct = accountMap[effectiveAccountId];

  return TransactionEntry(
    tx: tx,
    lines: txLines,
    accountBalanceAfter: running[effectiveAccountId] ?? 0,
    accountName: effectiveAcct?.name ?? accountMap[tx.accountId]?.name ?? '',
    accountCurrency: effectiveAcct?.currency ?? tx.currency,
    destinationAccountName: destAcct?.name,
    destinationAccountCurrency: destAcct?.currency,
    destinationAccountBalanceAfter: tx.destinationAccountId != null
        ? running[tx.destinationAccountId] ?? 0
        : null,
    lineAccountNames: lineAcctNames,
    isPrivate: private,
  );
}

/// Fetch accounts and transaction lines for a set of transactions.
Future<({Map<String, Account> accountMap, Map<String, List<TransactionLine>> linesByTx})>
    _fetchRelated(AppDatabase db, String householdId, List<Transaction> txList) async {
  final accounts = await (db.select(db.accounts)
        ..where((a) => a.householdId.equals(householdId)))
      .get();
  final accountMap = {for (final a in accounts) a.id: a};

  final linesByTx =
      await db.transactionsDao.linesByTransaction(txList.map((t) => t.id));

  return (accountMap: accountMap, linesByTx: linesByTx);
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/// Emits ALL transactions for the current household, newest-first,
/// each annotated with the running account balance at that point in time.
///
/// Keep this for screens that need the full dataset (reports, category trends).
///
/// Incremental: it watches a cheap signal (how many rows, the newest
/// `last_modified`) and on a change reads only the rows modified since —
/// every write moves `last_modified` (the bump triggers), so edits,
/// deletes and planned payments being posted all come through — with their
/// lines, merged into the rows it already has. Fewer rows than before (a
/// purge) reads everything again; so does a sync merge, which can change
/// rows without moving the stamp (the sync invalidates this provider).
/// Running balances are replayed each time (cheap arithmetic). Saving one
/// expense with three years of history: ~0.5 s → see data.md.
final transactionEntriesProvider =
    StreamProvider<List<TransactionEntry>>((ref) async* {
  final db = ref.watch(databaseProvider);
  final householdId = ref.watch(currentHouseholdIdProvider);
  // Other members' private envelopes: their spending shows as "Private".
  final hidden = hiddenCategoriesFromKey(ref.watch(hiddenCategoryKeyProvider));
  if (householdId == null) {
    yield [];
    return;
  }

  final signal = db.customSelect(
    'SELECT COUNT(*) AS n, MAX(last_modified) AS m FROM transactions '
    'WHERE household_id = ?',
    variables: [Variable.withString(householdId)],
    readsFrom: {db.transactions},
  ).watch();

  // Posted, live rows by id, with their lines.
  Map<String, (Transaction, List<TransactionLine>)>? rows;
  var count = 0;
  int? since; // seconds: the newest last_modified seen

  await for (final s in signal) {
    final n = s.first.read<int>('n');
    final m = s.first.read<int?>('m');
    if (rows == null || n < count || since == null) {
      final all = await (db.select(db.transactions)
            ..where((t) =>
                t.householdId.equals(householdId) &
                t.deleted.equals(false) &
                t.status.isNull()))
          .get();
      final lines =
          await db.transactionsDao.linesByTransaction(all.map((t) => t.id));
      rows = {for (final t in all) t.id: (t, lines[t.id] ?? const [])};
    } else if (m != null && m >= since) {
      // Same second included: stamps are whole seconds.
      final changed = await (db.select(db.transactions)
            ..where((t) =>
                t.householdId.equals(householdId) &
                t.lastModified.isBiggerOrEqualValue(
                    DateTime.fromMillisecondsSinceEpoch(since! * 1000))))
          .get();
      final live = [
        for (final t in changed)
          if (!t.deleted && t.status == null) t,
      ];
      for (final t in changed) {
        if (t.deleted || t.status != null) rows.remove(t.id);
      }
      final lines =
          await db.transactionsDao.linesByTransaction(live.map((t) => t.id));
      for (final t in live) {
        rows[t.id] = (t, lines[t.id] ?? const []);
      }
    }
    count = n;
    since = m;

    final accounts = await (db.select(db.accounts)
          ..where((a) => a.householdId.equals(householdId)))
        .get();
    final accountMap = {for (final a in accounts) a.id: a};
    final ordered = rows.values.toList()
      ..sort((a, b) {
        final c = a.$1.createdAt.compareTo(b.$1.createdAt);
        return c != 0 ? c : a.$1.id.compareTo(b.$1.id);
      });
    final running = <String, double>{
      for (final a in accountMap.values) a.id: a.initialBalance,
    };
    final result = <TransactionEntry>[];
    for (final (tx, txLines) in ordered) {
      _applyTxToRunning(tx, txLines, running);
      result.add(_buildEntry(tx, txLines, accountMap, running, hidden));
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
  // Other members' private envelopes: their spending shows as "Private".
  final hidden = hiddenCategoriesFromKey(ref.watch(hiddenCategoryKeyProvider));
  if (householdId == null) {
    yield [];
    return;
  }

  final dao = db.transactionsDao;
  final monthStream = dao.watchByMonth(householdId, param.year, param.month);

  await for (final monthTxList in monthStream) {
    final related = await _fetchRelated(db, householdId, monthTxList);

    // Compute running balances up to this month using SQL aggregation
    // instead of loading all prior transactions into memory.
    final monthStart = DateTime(param.year, param.month, 1);
    final running =
        await dao.getRunningBalancesBeforeDate(householdId, monthStart);

    // Now process the target month's transactions.
    final result = <TransactionEntry>[];
    for (final tx in monthTxList) {
      final txLines = related.linesByTx[tx.id] ?? [];
      _applyTxToRunning(tx, txLines, running);
      result.add(
          _buildEntry(tx, txLines, related.accountMap, running, hidden));
    }

    yield result.reversed.toList();
  }
});

/// One transaction (detail screen) without replaying the whole history —
/// running balances are not computed (0). Null when deleted or missing.
final transactionByIdProvider =
    StreamProvider.family<TransactionEntry?, String>((ref, id) async* {
  final db = ref.watch(databaseProvider);
  final householdId = ref.watch(currentHouseholdIdProvider);
  // Other members' private envelopes: their spending shows as "Private".
  final hidden = hiddenCategoriesFromKey(ref.watch(hiddenCategoryKeyProvider));
  if (householdId == null) {
    yield null;
    return;
  }
  final txStream = (db.select(db.transactions)
        ..where((t) => t.id.equals(id) & t.deleted.equals(false)))
      .watchSingleOrNull();
  await for (final tx in txStream) {
    if (tx == null) {
      yield null;
      continue;
    }
    final related = await _fetchRelated(db, householdId, [tx]);
    yield _buildEntry(tx, related.linesByTx[tx.id] ?? [], related.accountMap,
        const {}, hidden);
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
  // Other members' private envelopes: their spending shows as "Private".
  final hidden = hiddenCategoriesFromKey(ref.watch(hiddenCategoryKeyProvider));
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
    final result = [
      for (final tx in txList)
        _buildEntry(tx, related.linesByTx[tx.id] ?? [], related.accountMap,
            const {}, hidden),
    ];

    yield result;
  }
});
