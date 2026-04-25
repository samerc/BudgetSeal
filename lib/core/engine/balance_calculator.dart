import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../database/daos/accounts_dao.dart';
import '../database/daos/ledger_dao.dart';

/// Computes all balances dynamically from the ledger — nothing is stored.
///
/// Core invariant (per currency):
///   Sum(account balances) = Unallocated + Sum(allocation balances)
class BalanceCalculator {
  final AppDatabase _db;
  final AccountsDao _accountsDao;
  final LedgerDao _ledgerDao;

  BalanceCalculator(this._db)
      : _accountsDao = AccountsDao(_db),
        _ledgerDao = LedgerDao(_db);

  // ─── Batch: all account balances in ~7 queries total ───────────────────────

  /// Compute balances for ALL non-archived accounts in one pass.
  /// Returns `Map<accountId, balance>`.
  Future<Map<String, double>> allAccountBalances(String householdId) async {
    // 1. All non-archived accounts
    final accounts = await (_db.select(_db.accounts)
          ..where((t) =>
              t.householdId.equals(householdId) & t.archived.equals(false)))
        .get();

    final balances = <String, double>{
      for (final a in accounts) a.id: a.initialBalance,
    };
    final accountIds = balances.keys.toList();
    if (accountIds.isEmpty) return balances;

    // 2. All transaction_lines with per-line accountId referencing these accounts
    final allLines = await (_db.select(_db.transactionLines)
          ..where((l) => l.accountId.isIn(accountIds)))
        .get();

    // 3. Parent transactions for those lines (to get type)
    final lineTxIds = allLines.map((l) => l.transactionId).toSet();
    List<Transaction> lineTxList = [];
    if (lineTxIds.isNotEmpty) {
      lineTxList = await (_db.select(_db.transactions)
            ..where((t) => t.id.isIn(lineTxIds) & t.deleted.equals(false)))
          .get();
    }
    final txMap = {for (final t in lineTxList) t.id: t};

    for (final line in allLines) {
      final tx = txMap[line.transactionId];
      if (tx == null || line.accountId == null) continue;
      final acctId = line.accountId!;
      if (!balances.containsKey(acctId)) continue;
      if (tx.type == 'income') {
        balances[acctId] = balances[acctId]! + line.amount;
      } else if (tx.type == 'expense') {
        balances[acctId] = balances[acctId]! - line.amount;
      }
    }

    // 4. All header-level income/expense transactions for these accounts
    final headerTxs = await (_db.select(_db.transactions)
          ..where((t) =>
              t.accountId.isIn(accountIds) &
              t.deleted.equals(false) &
              t.type.isIn(['income', 'expense'])))
        .get();

    // 5. All transaction_lines for those header txs (to check which have per-line accounts)
    final headerTxIds = headerTxs.map((t) => t.id).toSet();
    List<TransactionLine> headerLines = [];
    if (headerTxIds.isNotEmpty) {
      headerLines = await (_db.select(_db.transactionLines)
            ..where((l) => l.transactionId.isIn(headerTxIds)))
          .get();
    }
    final txsWithPerLineAccounts = <String>{};
    for (final l in headerLines) {
      if (l.accountId != null) txsWithPerLineAccounts.add(l.transactionId);
    }

    for (final tx in headerTxs) {
      if (txsWithPerLineAccounts.contains(tx.id)) continue; // already counted via lines
      if (!balances.containsKey(tx.accountId)) continue;
      if (tx.type == 'income') {
        balances[tx.accountId] = balances[tx.accountId]! + tx.amount;
      } else if (tx.type == 'expense') {
        balances[tx.accountId] = balances[tx.accountId]! - tx.amount;
      }
    }

    // 6. All outgoing transfers
    final transfersFrom = await (_db.select(_db.transactions)
          ..where(
              (t) => t.accountId.isIn(accountIds) & t.deleted.equals(false) & t.type.equals('transfer')))
        .get();
    for (final tx in transfersFrom) {
      if (!balances.containsKey(tx.accountId)) continue;
      balances[tx.accountId] = balances[tx.accountId]! - tx.amount;
    }

    // 7. All incoming transfers
    final transfersTo = await (_db.select(_db.transactions)
          ..where((t) =>
              t.destinationAccountId.isIn(accountIds) &
              t.deleted.equals(false) &
              t.type.equals('transfer')))
        .get();
    for (final tx in transfersTo) {
      final dest = tx.destinationAccountId;
      if (dest == null || !balances.containsKey(dest)) continue;
      balances[dest] = balances[dest]! + tx.amount * tx.exchangeRateToBase;
    }

    return balances;
  }

  // ─── Batch: all allocation balances in 1 query ─────────────────────────────

  /// Compute balances for ALL non-archived allocations grouped by currency.
  /// Returns `Map<allocationId, Map<currency, balance>>`.
  Future<Map<String, Map<String, double>>> allAllocationBalancesByCurrency(
      String householdId) async {
    final allocs = await (_db.select(_db.allocations)
          ..where((t) =>
              t.householdId.equals(householdId) & t.archived.equals(false)))
        .get();
    final allocIds = allocs.map((a) => a.id).toList();
    if (allocIds.isEmpty) return {};

    final entries = await _ledgerDao.getAllForHousehold(allocIds);

    final result = <String, Map<String, double>>{};
    for (final e in entries) {
      result.putIfAbsent(e.allocationId, () => {});
      result[e.allocationId]![e.currency] =
          (result[e.allocationId]![e.currency] ?? 0) + e.amount;
    }
    return result;
  }

  // ─── Single-account (kept for detail screens) ──────────────────────────────

  /// Compute balance for a single account (used by account detail screen).
  Future<double> accountBalance(String accountId) async {
    final account = await _accountsDao.getById(accountId);
    if (account == null) return 0.0;

    double balance = account.initialBalance;

    // 1. Per-line accounts
    final lines = await (_db.select(_db.transactionLines)
          ..where((l) => l.accountId.equals(accountId)))
        .get();

    if (lines.isNotEmpty) {
      final txIds = lines.map((l) => l.transactionId).toSet();
      final txs = await (_db.select(_db.transactions)
            ..where((t) => t.id.isIn(txIds) & t.deleted.equals(false)))
          .get();
      final txMap2 = {for (final t in txs) t.id: t};

      for (final line in lines) {
        final tx = txMap2[line.transactionId];
        if (tx == null) continue;
        if (tx.type == 'income') {
          balance += line.amount;
        } else if (tx.type == 'expense') {
          balance -= line.amount;
        }
      }
    }

    // 2. Legacy header-level income/expense
    final headerTxs = await (_db.select(_db.transactions)
          ..where((t) =>
              t.accountId.equals(accountId) &
              t.deleted.equals(false) &
              t.type.isIn(['income', 'expense'])))
        .get();

    // Batch-check which have per-line accounts
    final headerIds = headerTxs.map((t) => t.id).toSet();
    List<TransactionLine> hLines = [];
    if (headerIds.isNotEmpty) {
      hLines = await (_db.select(_db.transactionLines)
            ..where((l) => l.transactionId.isIn(headerIds)))
          .get();
    }
    final perLineSet = <String>{};
    for (final l in hLines) {
      if (l.accountId != null) perLineSet.add(l.transactionId);
    }

    for (final tx in headerTxs) {
      if (perLineSet.contains(tx.id)) continue;
      if (tx.type == 'income') {
        balance += tx.amount;
      } else if (tx.type == 'expense') {
        balance -= tx.amount;
      }
    }

    // 3. Transfers
    final transfersFrom = await (_db.select(_db.transactions)
          ..where((t) =>
              t.accountId.equals(accountId) & t.deleted.equals(false) & t.type.equals('transfer')))
        .get();
    for (final tx in transfersFrom) {
      balance -= tx.amount;
    }

    final transfersTo = await (_db.select(_db.transactions)
          ..where((t) =>
              t.destinationAccountId.equals(accountId) &
              t.deleted.equals(false) &
              t.type.equals('transfer')))
        .get();
    for (final tx in transfersTo) {
      balance += tx.amount * tx.exchangeRateToBase;
    }

    return balance;
  }

  // ─── Unallocated (now uses batch methods) ──────────────────────────────────

  /// Compute unallocated pool per currency for a household.
  Future<Map<String, double>> unallocatedByCurrency(String householdId) async {
    // 1. Batch account balances
    final accounts = await (_db.select(_db.accounts)
          ..where((t) =>
              t.householdId.equals(householdId) & t.archived.equals(false)))
        .get();
    final accountBalances = await allAccountBalances(householdId);

    final Map<String, double> accountTotals = {};
    for (final acc in accounts) {
      final bal = accountBalances[acc.id] ?? 0;
      accountTotals[acc.currency] =
          (accountTotals[acc.currency] ?? 0.0) + bal;
    }

    // 2. Batch allocation balances
    final allocBalances = await allAllocationBalancesByCurrency(householdId);
    final Map<String, double> allocTotals = {};
    for (final allocEntry in allocBalances.values) {
      for (final entry in allocEntry.entries) {
        allocTotals[entry.key] = (allocTotals[entry.key] ?? 0.0) + entry.value;
      }
    }

    // 3. Unallocated = account totals - allocation totals (per currency)
    final Map<String, double> unallocated = {};
    final allCurrencies = {...accountTotals.keys, ...allocTotals.keys};
    for (final currency in allCurrencies) {
      unallocated[currency] =
          (accountTotals[currency] ?? 0.0) - (allocTotals[currency] ?? 0.0);
    }
    return unallocated;
  }

  /// Compute allocation balance broken down by currency (single allocation).
  Future<Map<String, double>> allocationBalanceByCurrency(
      String allocationId) async {
    return _ledgerDao.getBalanceByCurrency(allocationId);
  }

  /// Verify the core invariant. Returns true if balanced.
  Future<bool> checkInvariant(String householdId) async {
    final unallocated = await unallocatedByCurrency(householdId);
    bool balanced = true;
    for (final entry in unallocated.entries) {
      if (entry.value < -0.001) {
        assert(false,
            'Invariant violation: Unallocated[${entry.key}] = ${entry.value}');
        balanced = false;
      }
    }
    return balanced;
  }
}
