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

  /// Compute balance for a single account.
  ///
  /// For income/expense transactions, we look at *transaction_lines* to find
  /// lines that reference this account (multi-account support). Each line's
  /// amount is in the line's native currency and directly affects the account.
  ///
  /// For transfers, we use the transaction-level amount since transfers
  /// don't use split lines.
  Future<double> accountBalance(String accountId) async {
    final account = await _accountsDao.getById(accountId);
    if (account == null) return 0.0;

    double balance = account.initialBalance;

    // 1. Handle income/expense via transaction_lines (per-line accounts).
    //    Join lines → transactions to get the type.
    final lines = await (_db.select(_db.transactionLines)
          ..where((l) => l.accountId.equals(accountId)))
        .get();

    if (lines.isNotEmpty) {
      // Fetch parent transactions for these lines to know the type.
      final txIds = lines.map((l) => l.transactionId).toSet();
      final txs = await (_db.select(_db.transactions)
            ..where((t) => t.id.isIn(txIds)))
          .get();
      final txMap = {for (final t in txs) t.id: t};

      for (final line in lines) {
        final tx = txMap[line.transactionId];
        if (tx == null) continue;
        if (tx.type == 'income') {
          balance += line.amount;
        } else if (tx.type == 'expense') {
          balance -= line.amount;
        }
        // Transfers are handled below, not via lines.
      }
    }

    // 2. Handle legacy income/expense transactions that have NO lines with
    //    accountId set (pre-migration data, or lines without per-line accounts).
    final headerTxs = await (_db.select(_db.transactions)
          ..where((t) =>
              t.accountId.equals(accountId) &
              t.type.isIn(['income', 'expense'])))
        .get();

    for (final tx in headerTxs) {
      // Check if this transaction's lines already reference specific accounts.
      // If so, we already counted them above. Only count header-level if
      // no lines reference any account for this transaction.
      final txLines = await (_db.select(_db.transactionLines)
            ..where((l) => l.transactionId.equals(tx.id)))
          .get();

      final hasPerLineAccounts =
          txLines.any((l) => l.accountId != null);

      if (!hasPerLineAccounts) {
        // Legacy: no per-line accounts, use header amount.
        if (tx.type == 'income') {
          balance += tx.amount;
        } else if (tx.type == 'expense') {
          balance -= tx.amount;
        }
      }
      // If lines DO have accountId set, they were already handled in step 1.
    }

    // 3. Handle transfers (always use transaction-level fields).
    //    Source: deduct amount (in source currency).
    //    Destination: add amount * exchangeRate (converted to dest currency).
    //    For same-currency transfers, exchangeRate = 1.0 so both sides are equal.
    final transfersFrom = await (_db.select(_db.transactions)
          ..where((t) =>
              t.accountId.equals(accountId) & t.type.equals('transfer')))
        .get();
    for (final tx in transfersFrom) {
      balance -= tx.amount;
    }

    final transfersTo = await (_db.select(_db.transactions)
          ..where((t) =>
              t.destinationAccountId.equals(accountId) &
              t.type.equals('transfer')))
        .get();
    for (final tx in transfersTo) {
      balance += tx.amount * tx.exchangeRateToBase;
    }

    return balance;
  }

  /// Compute allocation balance broken down by currency.
  Future<Map<String, double>> allocationBalanceByCurrency(
      String allocationId) async {
    return _ledgerDao.getBalanceByCurrency(allocationId);
  }

  /// Compute unallocated pool per currency for a household.
  ///
  /// Unallocated[currency] =
  ///   Sum(account.balance for accounts with that currency)
  ///   - Sum(ledger net amount for that currency across all allocations)
  Future<Map<String, double>> unallocatedByCurrency(String householdId) async {
    // 1. Get all accounts and their balances
    final allAccounts = await (_db.select(_db.accounts)
          ..where((t) =>
              t.householdId.equals(householdId) & t.archived.equals(false)))
        .get();

    final Map<String, double> accountTotals = {};
    for (final acc in allAccounts) {
      final bal = await accountBalance(acc.id);
      accountTotals[acc.currency] =
          (accountTotals[acc.currency] ?? 0.0) + bal;
    }

    // 2. Get all allocations and sum ledger balances per currency
    final allAllocs = await (_db.select(_db.allocations)
          ..where((t) =>
              t.householdId.equals(householdId) & t.archived.equals(false)))
        .get();

    final Map<String, double> allocTotals = {};
    for (final alloc in allAllocs) {
      final balances = await _ledgerDao.getBalanceByCurrency(alloc.id);
      for (final entry in balances.entries) {
        allocTotals[entry.key] =
            (allocTotals[entry.key] ?? 0.0) + entry.value;
      }
    }

    // 3. Unallocated = account totals - allocation totals (per currency)
    final Map<String, double> unallocated = {};
    final allCurrencies = {
      ...accountTotals.keys,
      ...allocTotals.keys,
    };
    for (final currency in allCurrencies) {
      unallocated[currency] =
          (accountTotals[currency] ?? 0.0) - (allocTotals[currency] ?? 0.0);
    }
    return unallocated;
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
