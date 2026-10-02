import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../l10n/s_lookup.dart';
import '../../shared/utils/format_number.dart'
    show currencyDecimals, formatAmount, isRealRate;
import '../database/app_database.dart';
import '../database/daos/ledger_dao.dart';
import '../fx/fx_service.dart' show latestCachedRate;
import 'balance_calculator.dart';

enum OverspendOption { useUnallocated, allowNegative, cancel }

/// A line is in a different currency from its account and no exchange rate
/// between the two is known (none entered, none cached).
class CurrencyConversionException implements Exception {
  final String from;
  final String to;
  const CurrencyConversionException(this.from, this.to);

  @override
  String toString() => 'CurrencyConversionException: no rate $from → $to';
}

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
          note: currentS().engineAutoCovered,
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
    await _db.transaction(() async {
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
    });
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
    return _db.transaction(() async {
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
        note: Value(currentS().engineDirectIncome),
        deviceId: deviceId,
      ));

      return txId;
    });
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
    if (type != 'transfer' && lines.isEmpty) {
      throw ArgumentError('income/expense must have at least one line');
    }
    if (lines.any((l) => l.amount < 0)) {
      throw ArgumentError('line amounts must be non-negative');
    }
    if (lines.any((l) => l.amount > 1e9)) {
      throw ArgumentError('line amount exceeds maximum (1 billion)');
    }
    if (lines.any((l) => l.exchangeRateToBase <= 0)) {
      throw ArgumentError('exchange rate must be positive');
    }
    lines = await _toAccountCurrencies(lines, accountId, baseCurrency);

    final txId = _uuid.v4();

    await _db.transaction(() async {
    // Total in base currency (sum of each line converted via its rate).
    // Skip lines with bogus rate (different currency but rate=1.0 means not set).
    final totalBaseAmount = lines.fold(0.0, (sum, l) {
      if (l.currency == baseCurrency) return sum + l.amount;
      if ((l.exchangeRateToBase - 1.0).abs() < 0.001) return sum; // rate not set
      return sum + l.baseAmount;
    });
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

    // For expenses: create a ledger consumption entry per categorised line,
    // in the line's (= its account's) currency.
    if (type == 'expense') {
      // Pre-fetch category→allocation mappings in batch to avoid N+1
      // queries per line.
      final categoryIds = lines
          .where((l) => l.categoryId != null)
          .map((l) => l.categoryId!)
          .toSet();
      final catAllocMap = <String, String>{};

      if (categoryIds.isNotEmpty) {
        // Batch fetch categories
        final cats = await (_db.select(_db.categories)
              ..where((c) => c.id.isIn(categoryIds)))
            .get();
        final unlinkedCatIds = <String>[];
        for (final cat in cats) {
          if (cat.allocationId != null) {
            catAllocMap[cat.id] = cat.allocationId!;
          } else {
            unlinkedCatIds.add(cat.id);
          }
        }
        // A subcategory without its own link spends from its parent's
        // envelope (linking "Transport" covers Fuel, Parking…).
        final parentOf = {
          for (final cat in cats)
            if (cat.allocationId == null && cat.parentId != null)
              cat.id: cat.parentId!,
        };
        if (parentOf.isNotEmpty) {
          final parents = await (_db.select(_db.categories)
                ..where((c) => c.id.isIn(parentOf.values.toSet())))
              .get();
          final parentAlloc = {
            for (final p in parents)
              if (p.allocationId != null) p.id: p.allocationId!,
          };
          parentOf.forEach((childId, parentId) {
            final allocId = parentAlloc[parentId];
            if (allocId != null) {
              catAllocMap[childId] = allocId;
              unlinkedCatIds.remove(childId);
            }
          });
        }
        // Legacy fallback: categories without allocationId
        if (unlinkedCatIds.isNotEmpty) {
          final legacyAllocs = await (_db.select(_db.allocations)
                ..where((a) => a.categoryId.isIn(unlinkedCatIds)))
              .get();
          for (final a in legacyAllocs) {
            catAllocMap[a.categoryId] = a.id;
          }
        }
        // An archived (or deleted) envelope no longer takes spending — the
        // line stays unbudgeted instead of draining a hidden envelope.
        if (catAllocMap.isNotEmpty) {
          final live = await (_db.select(_db.allocations)
                ..where((a) => a.id.isIn(catAllocMap.values.toSet()))
                ..where((a) => a.archived.equals(false))
                ..where((a) => a.deleted.equals(false)))
              .map((a) => a.id)
              .get();
          final liveIds = live.toSet();
          catAllocMap.removeWhere((_, allocId) => !liveIds.contains(allocId));
        }
      }

      for (final line in lines) {
        if (line.categoryId != null) {
          final allocationId = catAllocMap[line.categoryId!];
          if (allocationId != null) {
            // Debit in the currency actually spent. Converting into the
            // envelope's currency would leave the account side in one
            // currency and the envelope side in another, breaking
            // Sum(accounts) = Unallocated + Sum(envelopes) per currency.
            // A foreign-currency debit shows as "other currency" debt on
            // the envelope until it is funded in that currency.
            final debitAmount = -line.amount;
            final debitCurrency = line.currency;
            final debitRate = line.exchangeRateToBase;

            final lineAccountId = line.accountId ?? accountId;
            await _ledgerDao.appendEntry(AllocationLedgerCompanion.insert(
              id: _uuid.v4(),
              allocationId: allocationId,
              sourceTransactionId: Value(txId),
              sourceAccountId: Value(lineAccountId),
              entryType: 'consumption',
              amount: debitAmount,
              currency: debitCurrency,
              exchangeRateToBase: Value(debitRate),
              note: Value(line.note.isNotEmpty ? line.note : note),
              deviceId: deviceId,
            ));
          }
        }
      }
    }

    }); // end db.transaction

    return txId;
  }

  /// Soft-delete a transaction and reverse its allocation ledger entries.
  ///
  /// Sets the `deleted` flag instead of removing the row, so that sync
  /// can detect the deletion and avoid re-importing the transaction.
  /// Ledger entries are still hard-deleted (they are reconstructable).
  Future<void> deleteTransaction(String txId) async {
    await _db.transaction(() async {
      // 1. Remove any allocation ledger entries linked to this transaction.
      await _ledgerDao.deleteByTransactionId(txId);

      // 2. Soft-delete the transaction (keep row for sync).
      await (_db.update(_db.transactions)
            ..where((t) => t.id.equals(txId)))
          .write(TransactionsCompanion(
              deleted: const Value(true),
              // Sync merges by lastModified — without it the delete never
              // reaches other devices.
              lastModified: Value(DateTime.now())));
    });
  }

  /// Every line is stored in its account's currency, so account balances
  /// (which sum line amounts) never mix currencies. A line entered in another
  /// currency (e.g. €50 on a USD card) is converted here — with the rate
  /// entered on the line, or the latest cached rate — and the original
  /// amount is kept in the line note. Throws [CurrencyConversionException]
  /// when no rate is known.
  Future<List<TxLine>> _toAccountCurrencies(
      List<TxLine> lines, String accountId, String baseCurrency) async {
    final ids = {for (final l in lines) l.accountId ?? accountId};
    final accounts = await (_db.select(_db.accounts)
          ..where((a) => a.id.isIn(ids)))
        .get();
    final currencyOf = {for (final a in accounts) a.id: a.currency};

    final out = <TxLine>[];
    for (final l in lines) {
      final acctCurrency = currencyOf[l.accountId ?? accountId];
      if (acctCurrency == null || acctCurrency == l.currency) {
        out.add(l);
        continue;
      }
      final lineToBase =
          isRealRate(l.currency, baseCurrency, l.exchangeRateToBase)
              ? (l.currency == baseCurrency ? 1.0 : l.exchangeRateToBase)
              : await latestCachedRate(_db, l.currency, baseCurrency);
      final acctToBase = await latestCachedRate(_db, acctCurrency, baseCurrency);
      if (lineToBase == null || acctToBase == null) {
        throw CurrencyConversionException(l.currency, acctCurrency);
      }
      final scale = math.pow(10, currencyDecimals(acctCurrency)).toDouble();
      final converted = (l.amount * lineToBase / acctToBase * scale).round() /
          scale;
      final original = formatAmount(l.amount, currency: l.currency);
      out.add(TxLine(
        amount: converted,
        currency: acctCurrency,
        categoryId: l.categoryId,
        accountId: l.accountId,
        exchangeRateToBase: acctToBase,
        note: l.note.isEmpty ? original : '${l.note} ($original)',
      ));
    }
    return out;
  }

  /// Withdraw funds from an allocation back to Unallocated.
  Future<void> withdrawFromAllocation({
    required String allocationId,
    required double amount,
    required String currency,
    String deviceId = 'local',
    String note = '',
  }) async {
    // Validate sufficient balance in this currency
    final balances = await _ledgerDao.getBalanceByCurrency(allocationId);
    final available = balances[currency] ?? 0;
    if (amount > available + 0.005) {
      throw StateError(
          'Insufficient balance: $currency ${available.toStringAsFixed(2)} '
          'available, ${amount.toStringAsFixed(2)} requested');
    }

    await _ledgerDao.appendEntry(AllocationLedgerCompanion.insert(
      id: _uuid.v4(),
      allocationId: allocationId,
      entryType: 'withdrawal',
      amount: -amount, // negative = money leaving the allocation
      currency: currency,
      note: Value(note.isNotEmpty ? note : currentS().engineWithdrawn),
      deviceId: deviceId,
    ));
  }

}
