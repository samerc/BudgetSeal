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

  // ─── Batch: all account balances in two queries ────────────────────────────

  /// Compute balances for ALL non-archived accounts in one pass.
  /// Returns `Map<accountId, balance>`.
  Future<Map<String, double>> allAccountBalances(String householdId) async {
    final accounts = await (_db.select(_db.accounts)
          ..where((t) =>
              t.householdId.equals(householdId) &
              t.archived.equals(false) &
              t.deleted.equals(false)))
        .get();
    final moved = await _movements(householdId);
    return {
      for (final a in accounts) a.id: a.initialBalance + (moved[a.id] ?? 0),
    };
  }

  /// What posted transactions moved in and out of each account, summed in
  /// SQL (a long history is tens of thousands of rows):
  /// - income/expense lines on their own account;
  /// - income/expense with no per-line account on the header account;
  /// - a transfer takes `amount` from the source and adds
  ///   `amount × exchangeRateToBase` (the source→destination rate) to the
  ///   destination.
  Future<Map<String, double>> _movements(String householdId) async {
    final rows = await _db.customSelect(
      '''SELECT id, SUM(v) AS total FROM (
           SELECT tl.account_id AS id,
                  CASE WHEN t.type = 'income' THEN tl.amount ELSE -tl.amount END AS v
             FROM transaction_lines tl
             JOIN transactions t ON t.id = tl.transaction_id
            WHERE t.household_id = ?1 AND t.deleted = 0 AND t.status IS NULL
              AND t.type IN ('income', 'expense') AND tl.account_id IS NOT NULL
           UNION ALL
           SELECT t.account_id,
                  CASE WHEN t.type = 'income' THEN t.amount ELSE -t.amount END
             FROM transactions t
            WHERE t.household_id = ?1 AND t.deleted = 0 AND t.status IS NULL
              AND t.type IN ('income', 'expense')
              AND NOT EXISTS (SELECT 1 FROM transaction_lines tl
                               WHERE tl.transaction_id = t.id
                                 AND tl.account_id IS NOT NULL)
           UNION ALL
           SELECT t.account_id, -t.amount
             FROM transactions t
            WHERE t.household_id = ?1 AND t.deleted = 0 AND t.status IS NULL
              AND t.type = 'transfer'
           UNION ALL
           SELECT t.destination_account_id, t.amount * t.exchange_rate_to_base
             FROM transactions t
            WHERE t.household_id = ?1 AND t.deleted = 0 AND t.status IS NULL
              AND t.type = 'transfer' AND t.destination_account_id IS NOT NULL
         ) GROUP BY id''',
      variables: [Variable.withString(householdId)],
      readsFrom: {_db.transactions, _db.transactionLines},
    ).get();
    return {
      for (final r in rows)
        r.read<String>('id'): r.read<double?>('total') ?? 0,
    };
  }

  // ─── Batch: all allocation balances in 1 query ─────────────────────────────

  /// Compute balances for ALL non-archived allocations grouped by currency.
  /// Returns `Map<allocationId, Map<currency, balance>>`.
  Future<Map<String, Map<String, double>>> allAllocationBalancesByCurrency(
      String householdId) async {
    final allocs = await (_db.select(_db.allocations)
          ..where((t) =>
              t.householdId.equals(householdId) &
              t.archived.equals(false) &
              t.deleted.equals(false)))
        .get();
    final allocIds = allocs.map((a) => a.id).toList();
    if (allocIds.isEmpty) return {};

    return _ledgerDao.getAllBalances(allocIds);
  }

  // ─── Single-account (kept for detail screens) ──────────────────────────────

  /// Compute balance for a single account (used by account detail screen;
  /// archived accounts too).
  Future<double> accountBalance(String accountId) async {
    final account = await _accountsDao.getById(accountId);
    if (account == null) return 0.0;
    final moved = await _movements(account.householdId);
    return account.initialBalance + (moved[accountId] ?? 0);
  }

  // ─── Unallocated (now uses batch methods) ──────────────────────────────────

  /// Compute unallocated pool per currency for a household.
  Future<Map<String, double>> unallocatedByCurrency(String householdId) async {
    // 1. Batch account balances
    final accounts = await (_db.select(_db.accounts)
          ..where((t) =>
              t.householdId.equals(householdId) &
              t.archived.equals(false) &
              t.deleted.equals(false)))
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
