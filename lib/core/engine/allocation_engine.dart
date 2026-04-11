import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../database/daos/ledger_dao.dart';
import 'balance_calculator.dart';

enum OverspendOption { useUnallocated, allowNegative, cancel }

/// One categorised line within a transaction.
/// A simple transaction has one line; a split has many.
/// Each line can draw from a different account (multi-account support).
class TxLine {
  final double amount;
  final String currency;
  final String? categoryId;
  final String? accountId;
  final double exchangeRateToBase;
  final String note;

  const TxLine({
    required this.amount,
    required this.currency,
    this.categoryId,
    this.accountId,
    this.exchangeRateToBase = 1.0,
    this.note = '',
  });

  /// Amount converted to the household's base currency.
  double get baseAmount => amount * exchangeRateToBase;
}

class OverspendInfo {
  final String allocationId;
  final String currency;
  final double shortfall;
  final double unallocatedAvailable;

  const OverspendInfo({
    required this.allocationId,
    required this.currency,
    required this.shortfall,
    required this.unallocatedAvailable,
  });
}

/// Central engine — all money flow passes through here.
/// Screens call engine methods; never write to ledger/transactions directly.
class AllocationEngine {
  final AppDatabase _db;
  final LedgerDao _ledgerDao;
  final BalanceCalculator _calculator;
  final _uuid = const Uuid();

  AllocationEngine(this._db)
      : _ledgerDao = LedgerDao(_db),
        _calculator = BalanceCalculator(_db);

  Future<String> recordIncome({
    required String householdId,
    required String accountId,
    required double amount,
    required String currency,
    required double exchangeRateToBase,
    required String createdBy,
    required String deviceId,
    String note = '',
  }) async {
    final txId = _uuid.v4();
    await _db.into(_db.transactions).insert(TransactionsCompanion.insert(
          id: txId,
          householdId: householdId,
          type: 'income',
          accountId: accountId,
          amount: amount,
          currency: currency,
          exchangeRateToBase: Value(exchangeRateToBase),
          createdBy: createdBy,
          deviceId: deviceId,
          note: Value(note),
        ));
    return txId;
  }

  Future<({String? txId, OverspendInfo? overspend})> recordExpense({
    required String householdId,
    required String accountId,
    required String allocationId,
    required double amount,
    required String currency,
    required double exchangeRateToBase,
    required String createdBy,
    required String deviceId,
    String? categoryId,
    String note = '',
  }) async {
    // Check allocation balance
    final balances =
        await _calculator.allocationBalanceByCurrency(allocationId);
    final currentBalance = balances[currency] ?? 0.0;

    if (currentBalance < amount) {
      final shortfall = amount - currentBalance;
      final unallocated = await _calculator.unallocatedByCurrency(householdId);
      return (
        txId: null,
        overspend: OverspendInfo(
          allocationId: allocationId,
          currency: currency,
          shortfall: shortfall,
          unallocatedAvailable: unallocated[currency] ?? 0.0,
        ),
      );
    }

    return (
      txId: await _commitExpense(
        householdId: householdId,
        accountId: accountId,
        allocationId: allocationId,
        amount: amount,
        currency: currency,
        exchangeRateToBase: exchangeRateToBase,
        createdBy: createdBy,
        deviceId: deviceId,
        categoryId: categoryId,
        note: note,
      ),
      overspend: null,
    );
  }

  /// Force-commit an expense even if allocation is insufficient.
  Future<String> forceCommitExpense({
    required String householdId,
    required String accountId,
    required String allocationId,
    required double amount,
    required String currency,
    required double exchangeRateToBase,
    required String createdBy,
    required String deviceId,
    String? categoryId,
    String note = '',
    bool coverFromUnallocated = false,
  }) async {
    if (coverFromUnallocated) {
      final balances =
          await _calculator.allocationBalanceByCurrency(allocationId);
      final currentBalance = balances[currency] ?? 0.0;
      final shortfall = amount - currentBalance;
      if (shortfall > 0) {
        await fundAllocation(
          allocationId: allocationId,
          amount: shortfall,
          currency: currency,
          deviceId: deviceId,
          note: 'Auto-covered from Unallocated',
        );
      }
    }
    return _commitExpense(
      householdId: householdId,
      accountId: accountId,
      allocationId: allocationId,
      amount: amount,
      currency: currency,
      exchangeRateToBase: exchangeRateToBase,
      createdBy: createdBy,
      deviceId: deviceId,
      categoryId: categoryId,
      note: note,
    );
  }

  Future<String> _commitExpense({
    required String householdId,
    required String accountId,
    required String allocationId,
    required double amount,
    required String currency,
    required double exchangeRateToBase,
    required String createdBy,
    required String deviceId,
    String? categoryId,
    String note = '',
  }) async {
    final txId = _uuid.v4();
    await _db.into(_db.transactions).insert(TransactionsCompanion.insert(
          id: txId,
          householdId: householdId,
          type: 'expense',
          accountId: accountId,
          amount: amount,
          currency: currency,
          exchangeRateToBase: Value(exchangeRateToBase),
          createdBy: createdBy,
          deviceId: deviceId,
          categoryId: Value(categoryId),
          note: Value(note),
        ));

    await _ledgerDao.appendEntry(AllocationLedgerCompanion.insert(
      id: _uuid.v4(),
      allocationId: allocationId,
      sourceTransactionId: Value(txId),
      sourceAccountId: Value(accountId),
      entryType: 'consumption',
      amount: -amount,
      currency: currency,
      exchangeRateToBase: Value(exchangeRateToBase),
      note: Value(note),
      deviceId: deviceId,
    ));
    return txId;
  }

  /// Transfer between accounts. Does NOT affect allocation ledger.
  Future<String> recordTransfer({
    required String householdId,
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    required String currency,
    required double exchangeRateToBase,
    required String createdBy,
    required String deviceId,
    String note = '',
    DateTime? date,
  }) async {
    final txId = _uuid.v4();
    await _db.into(_db.transactions).insert(TransactionsCompanion.insert(
          id: txId,
          householdId: householdId,
          type: 'transfer',
          accountId: fromAccountId,
          destinationAccountId: Value(toAccountId),
          amount: amount,
          currency: currency,
          exchangeRateToBase: Value(exchangeRateToBase),
          createdBy: createdBy,
          deviceId: deviceId,
          note: Value(note),
          createdAt: Value(date ?? DateTime.now()),
        ));
    return txId;
  }

  /// Move funds from Unallocated pool into an allocation.
  Future<void> fundAllocation({
    required String allocationId,
    required double amount,
    required String currency,
    required String deviceId,
    double exchangeRateToBase = 1.0,
    String note = '',
  }) async {
    await _ledgerDao.appendEntry(AllocationLedgerCompanion.insert(
      id: _uuid.v4(),
      allocationId: allocationId,
      entryType: 'funding',
      amount: amount,
      currency: currency,
      exchangeRateToBase: Value(exchangeRateToBase),
      note: Value(note),
      deviceId: deviceId,
    ));
  }

  /// Shortcut: income credited directly to a specific allocation.
  Future<String> recordIncomeDirectToAllocation({
    required String householdId,
    required String accountId,
    required String allocationId,
    required double amount,
    required String currency,
    required double exchangeRateToBase,
    required String createdBy,
    required String deviceId,
    String note = '',
  }) async {
    final txId = await recordIncome(
      householdId: householdId,
      accountId: accountId,
      amount: amount,
      currency: currency,
      exchangeRateToBase: exchangeRateToBase,
      createdBy: createdBy,
      deviceId: deviceId,
      note: note,
    );

    await _ledgerDao.appendEntry(AllocationLedgerCompanion.insert(
      id: _uuid.v4(),
      allocationId: allocationId,
      sourceTransactionId: Value(txId),
      entryType: 'funding',
      amount: amount,
      currency: currency,
      exchangeRateToBase: Value(exchangeRateToBase),
      note: Value('Direct from income'),
      deviceId: deviceId,
    ));

    return txId;
  }

  /// Record a transaction entered from the UI.
  ///
  /// Each line can reference a different account (multi-account support).
  /// The transaction-level amount is the total converted to base currency.
  /// The transaction-level accountId is the first line's account (primary).
  ///
  /// For expense transactions, creates allocation ledger consumption entries
  /// for each line that has a category with an associated allocation.
  Future<String> recordTransaction({
    required String householdId,
    required String accountId,
    required String type, // 'income' | 'expense' | 'transfer'
    required List<TxLine> lines,
    required String baseCurrency,
    String? destinationAccountId,
    String note = '',
    String deviceId = 'local',
    DateTime? date,
  }) async {
    assert(type == 'transfer' || lines.isNotEmpty,
        'income/expense must have at least one line');
    assert(lines.every((l) => l.amount >= 0), 'line amounts must be non-negative');

    final txId = _uuid.v4();
    // Total in base currency (sum of each line converted via its rate).
    final totalBaseAmount =
        lines.fold(0.0, (sum, l) => sum + l.baseAmount);
    final singleCategoryId =
        lines.length == 1 ? lines.first.categoryId : null;
    final effectiveDate = date ?? DateTime.now();

    await _db.into(_db.transactions).insert(TransactionsCompanion.insert(
          id: txId,
          householdId: householdId,
          type: type,
          accountId: accountId,
          destinationAccountId: Value(destinationAccountId),
          amount: totalBaseAmount,
          currency: baseCurrency,
          categoryId: Value(singleCategoryId),
          note: Value(note),
          createdBy: 'user',
          deviceId: deviceId,
          createdAt: Value(effectiveDate),
        ));

    for (final line in lines) {
      await _db.into(_db.transactionLines).insert(
            TransactionLinesCompanion.insert(
              id: _uuid.v4(),
              transactionId: txId,
              categoryId: Value(line.categoryId),
              accountId: Value(line.accountId ?? accountId),
              amount: line.amount,
              currency: line.currency,
              exchangeRateToBase: Value(line.exchangeRateToBase),
              note: Value(line.note),
            ),
          );
    }

    // For expenses: create a ledger consumption entry per categorised line.
    if (type == 'expense') {
      for (final line in lines) {
        if (line.categoryId != null) {
          final allocationId = await _allocationIdForCategory(line.categoryId!);
          if (allocationId != null) {
            final lineAccountId = line.accountId ?? accountId;
            await _ledgerDao.appendEntry(AllocationLedgerCompanion.insert(
              id: _uuid.v4(),
              allocationId: allocationId,
              sourceTransactionId: Value(txId),
              sourceAccountId: Value(lineAccountId),
              entryType: 'consumption',
              amount: -line.amount, // debit in line's currency
              currency: line.currency,
              exchangeRateToBase: Value(line.exchangeRateToBase),
              note: Value(line.note.isNotEmpty ? line.note : note),
              deviceId: deviceId,
            ));
          }
        }
      }
    }

    return txId;
  }

  /// Delete a transaction and reverse its allocation ledger entries.
  ///
  /// Runs inside a database transaction so that the deletion of the
  /// transaction, its lines, and the related ledger entries are atomic.
  Future<void> deleteTransaction(String txId) async {
    await _db.transaction(() async {
      // 1. Remove any allocation ledger entries linked to this transaction.
      await _ledgerDao.deleteByTransactionId(txId);

      // 2. Remove transaction lines (cascade should handle this, but be explicit).
      await (_db.delete(_db.transactionLines)
            ..where((l) => l.transactionId.equals(txId)))
          .go();

      // 3. Remove the transaction itself.
      await (_db.delete(_db.transactions)
            ..where((t) => t.id.equals(txId)))
          .go();
    });
  }

  /// Look up the allocation (envelope) linked to a category.
  /// Uses categories.allocationId (many categories → one envelope).
  /// Falls back to legacy allocations.categoryId for backward compatibility.
  Future<String?> _allocationIdForCategory(String categoryId) async {
    // Primary: check category.allocationId.
    final cat = await (_db.select(_db.categories)
          ..where((c) => c.id.equals(categoryId))
          ..limit(1))
        .getSingleOrNull();
    if (cat?.allocationId != null) return cat!.allocationId;

    // Fallback: legacy 1:1 via allocations.categoryId.
    final results = await (_db.select(_db.allocations)
          ..where((a) => a.categoryId.equals(categoryId))
          ..limit(1))
        .get();
    return results.isEmpty ? null : results.first.id;
  }
}
