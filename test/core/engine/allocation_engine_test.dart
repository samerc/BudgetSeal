import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgetseal/core/database/app_database.dart';
import 'package:budgetseal/core/database/daos/ledger_dao.dart';
import 'package:budgetseal/core/engine/allocation_engine.dart';
import 'package:uuid/uuid.dart';

void main() {
  late AppDatabase db;
  late AllocationEngine engine;
  late LedgerDao ledgerDao;
  const uuid = Uuid();

  // Shared seed IDs.
  late String householdId;
  late String accountId;
  late String accountId2;
  late String categoryId;
  late String allocationId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    engine = AllocationEngine(db);
    ledgerDao = LedgerDao(db);

    // Seed a household.
    householdId = uuid.v4();
    await db.into(db.households).insert(HouseholdsCompanion.insert(
          id: householdId,
          name: 'Test Household',
          createdByDeviceId: 'test-device',
        ));

    // Seed two accounts.
    accountId = uuid.v4();
    await db.into(db.accounts).insert(AccountsCompanion.insert(
          id: accountId,
          householdId: householdId,
          name: 'Checking',
          type: 'bank',
          currency: 'USD',
          deviceId: 'test-device',
        ));

    accountId2 = uuid.v4();
    await db.into(db.accounts).insert(AccountsCompanion.insert(
          id: accountId2,
          householdId: householdId,
          name: 'Savings',
          type: 'bank',
          currency: 'USD',
          deviceId: 'test-device',
        ));

    // Seed an allocation (envelope).
    allocationId = uuid.v4();
    categoryId = uuid.v4();

    await db.into(db.allocations).insert(AllocationsCompanion.insert(
          id: allocationId,
          householdId: householdId,
          name: 'Groceries',
          categoryId: categoryId,
          deviceId: 'test-device',
        ));

    // Seed a category that links to the allocation.
    await db.into(db.categories).insert(CategoriesCompanion.insert(
          id: categoryId,
          householdId: householdId,
          name: 'Groceries',
          allocationId: Value(allocationId),
        ));
  });

  tearDown(() async => db.close());

  // ---------------------------------------------------------------------------
  // Helper: fund the allocation so expenses can be recorded against it.
  // ---------------------------------------------------------------------------
  Future<void> fundAllocation(double amount) async {
    await engine.fundAllocation(
      allocationId: allocationId,
      amount: amount,
      currency: 'USD',
      deviceId: 'test-device',
    );
  }

  // ---------------------------------------------------------------------------
  // recordExpense — creates ledger entries
  // ---------------------------------------------------------------------------
  group('recordExpense', () {
    test('creates a transaction and a consumption ledger entry', () async {
      await fundAllocation(500);

      final result = await engine.recordExpense(
        householdId: householdId,
        accountId: accountId,
        allocationId: allocationId,
        amount: 42.50,
        currency: 'USD',
        exchangeRateToBase: 1.0,
        createdBy: 'user',
        deviceId: 'test-device',
        categoryId: categoryId,
        note: 'Weekly shop',
      );

      expect(result.txId, isNotNull, reason: 'Should return a transaction ID');
      expect(result.overspend, isNull);

      // Verify the transaction row exists.
      final tx = await (db.select(db.transactions)
            ..where((t) => t.id.equals(result.txId!)))
          .getSingleOrNull();
      expect(tx, isNotNull);
      expect(tx!.type, 'expense');
      expect(tx.amount, 42.50);

      // Verify a consumption ledger entry was created.
      final entries = await (db.select(db.allocationLedger)
            ..where((l) => l.sourceTransactionId.equals(result.txId!)))
          .get();
      expect(entries, hasLength(1));
      expect(entries.first.entryType, 'consumption');
      expect(entries.first.amount, -42.50);
      expect(entries.first.allocationId, allocationId);
    });

    test('returns overspend info when allocation balance is insufficient',
        () async {
      await fundAllocation(20);

      final result = await engine.recordExpense(
        householdId: householdId,
        accountId: accountId,
        allocationId: allocationId,
        amount: 50,
        currency: 'USD',
        exchangeRateToBase: 1.0,
        createdBy: 'user',
        deviceId: 'test-device',
      );

      expect(result.txId, isNull, reason: 'Should NOT create a transaction');
      expect(result.overspend, isNotNull);
      expect(result.overspend!.shortfall, 30.0);
    });
  });

  // ---------------------------------------------------------------------------
  // recordIncome — should NOT create ledger entries
  // ---------------------------------------------------------------------------
  group('recordIncome', () {
    test('creates a transaction but no ledger entries', () async {
      final txId = await engine.recordIncome(
        householdId: householdId,
        accountId: accountId,
        amount: 3000,
        currency: 'USD',
        exchangeRateToBase: 1.0,
        createdBy: 'user',
        deviceId: 'test-device',
        note: 'Salary',
      );

      // Transaction exists.
      final tx = await (db.select(db.transactions)
            ..where((t) => t.id.equals(txId)))
          .getSingleOrNull();
      expect(tx, isNotNull);
      expect(tx!.type, 'income');
      expect(tx.amount, 3000);

      // No ledger entries linked to this transaction.
      final entries = await (db.select(db.allocationLedger)
            ..where((l) => l.sourceTransactionId.equals(txId)))
          .get();
      expect(entries, isEmpty,
          reason: 'Plain income should not touch the allocation ledger');
    });
  });

  // ---------------------------------------------------------------------------
  // recordTransfer — moves money between accounts, no ledger entries
  // ---------------------------------------------------------------------------
  group('recordTransfer', () {
    test('creates a transfer transaction with source and destination', () async {
      final txId = await engine.recordTransfer(
        householdId: householdId,
        fromAccountId: accountId,
        toAccountId: accountId2,
        amount: 200,
        currency: 'USD',
        exchangeRateToBase: 1.0,
        createdBy: 'user',
        deviceId: 'test-device',
        note: 'Move to savings',
      );

      final tx = await (db.select(db.transactions)
            ..where((t) => t.id.equals(txId)))
          .getSingleOrNull();
      expect(tx, isNotNull);
      expect(tx!.type, 'transfer');
      expect(tx.accountId, accountId);
      expect(tx.destinationAccountId, accountId2);
      expect(tx.amount, 200);

      // Transfers should NOT create allocation ledger entries.
      final entries = await (db.select(db.allocationLedger)
            ..where((l) => l.sourceTransactionId.equals(txId)))
          .get();
      expect(entries, isEmpty,
          reason: 'Transfers do not affect the allocation ledger');
    });
  });

  // ---------------------------------------------------------------------------
  // deleteTransaction — reverses ledger entries
  // ---------------------------------------------------------------------------
  group('deleteTransaction', () {
    test('removes the transaction, its lines, and its ledger entries', () async {
      await fundAllocation(500);

      // Record an expense via recordTransaction (which creates lines + ledger).
      final txId = await engine.recordTransaction(
        householdId: householdId,
        accountId: accountId,
        type: 'expense',
        lines: [
          TxLine(
            amount: 75,
            currency: 'USD',
            categoryId: categoryId,
            accountId: accountId,
          ),
        ],
        baseCurrency: 'USD',
        note: 'Dinner',
        deviceId: 'test-device',
      );

      // Confirm data exists before deletion.
      var tx = await (db.select(db.transactions)
            ..where((t) => t.id.equals(txId)))
          .getSingleOrNull();
      expect(tx, isNotNull);

      var lines = await (db.select(db.transactionLines)
            ..where((l) => l.transactionId.equals(txId)))
          .get();
      expect(lines, hasLength(1));

      var ledger = await (db.select(db.allocationLedger)
            ..where((l) => l.sourceTransactionId.equals(txId)))
          .get();
      expect(ledger, hasLength(1));

      // Delete the transaction.
      await engine.deleteTransaction(txId);

      // Transaction should be soft-deleted (deleted = true).
      tx = await (db.select(db.transactions)
            ..where((t) => t.id.equals(txId)))
          .getSingleOrNull();
      expect(tx, isNotNull, reason: 'Transaction row should still exist');
      expect(tx!.deleted, isTrue, reason: 'Transaction should be soft-deleted');

      // Lines are preserved for sync/audit (only ledger entries are removed).
      lines = await (db.select(db.transactionLines)
            ..where((l) => l.transactionId.equals(txId)))
          .get();
      expect(lines, hasLength(1), reason: 'Transaction lines should be preserved');

      ledger = await (db.select(db.allocationLedger)
            ..where((l) => l.sourceTransactionId.equals(txId)))
          .get();
      expect(ledger, isEmpty, reason: 'Ledger entries should be deleted');
    });

    test('deletion restores allocation balance', () async {
      await fundAllocation(500);

      final balBefore =
          await ledgerDao.getBalanceByCurrency(allocationId);
      expect(balBefore['USD'], 500);

      final txId = await engine.recordTransaction(
        householdId: householdId,
        accountId: accountId,
        type: 'expense',
        lines: [
          TxLine(
            amount: 120,
            currency: 'USD',
            categoryId: categoryId,
            accountId: accountId,
          ),
        ],
        baseCurrency: 'USD',
        deviceId: 'test-device',
      );

      final balAfterExpense =
          await ledgerDao.getBalanceByCurrency(allocationId);
      expect(balAfterExpense['USD'], 380);

      await engine.deleteTransaction(txId);

      final balAfterDelete =
          await ledgerDao.getBalanceByCurrency(allocationId);
      expect(balAfterDelete['USD'], 500,
          reason: 'Balance should be restored after deleting the expense');
    });
  });

  // ---------------------------------------------------------------------------
  // recordTransaction with multiple lines (split transactions)
  // ---------------------------------------------------------------------------
  group('split / multi-line transactions', () {
    test('creates one ledger entry per categorised line', () async {
      // Create a second category + allocation for the split.
      final allocId2 = uuid.v4();
      final catId2 = uuid.v4();

      await db.into(db.allocations).insert(AllocationsCompanion.insert(
            id: allocId2,
            householdId: householdId,
            name: 'Dining',
            categoryId: catId2,
            deviceId: 'test-device',
          ));
      await db.into(db.categories).insert(CategoriesCompanion.insert(
            id: catId2,
            householdId: householdId,
            name: 'Dining',
            allocationId: Value(allocId2),
          ));

      // Fund both allocations.
      await fundAllocation(500);
      await engine.fundAllocation(
        allocationId: allocId2,
        amount: 300,
        currency: 'USD',
        deviceId: 'test-device',
      );

      final txId = await engine.recordTransaction(
        householdId: householdId,
        accountId: accountId,
        type: 'expense',
        lines: [
          TxLine(
            amount: 40,
            currency: 'USD',
            categoryId: categoryId,
            accountId: accountId,
          ),
          TxLine(
            amount: 25,
            currency: 'USD',
            categoryId: catId2,
            accountId: accountId,
          ),
        ],
        baseCurrency: 'USD',
        note: 'Split meal',
        deviceId: 'test-device',
      );

      // Two ledger entries (one per categorised line).
      final entries = await (db.select(db.allocationLedger)
            ..where((l) => l.sourceTransactionId.equals(txId)))
          .get();
      expect(entries, hasLength(2));

      // Verify amounts.
      final amounts = entries.map((e) => e.amount).toSet();
      expect(amounts, containsAll([-40.0, -25.0]));

      // Verify correct allocations were debited.
      final allocIds = entries.map((e) => e.allocationId).toSet();
      expect(allocIds, containsAll([allocationId, allocId2]));

      // Two transaction lines were created.
      final lines = await (db.select(db.transactionLines)
            ..where((l) => l.transactionId.equals(txId)))
          .get();
      expect(lines, hasLength(2));

      // Header transaction amount is the base-currency total.
      final tx = await (db.select(db.transactions)
            ..where((t) => t.id.equals(txId)))
          .getSingle();
      expect(tx.amount, 65.0, reason: 'Total = 40 + 25');
    });

    test('uncategorised lines do not produce ledger entries', () async {
      await fundAllocation(500);

      final txId = await engine.recordTransaction(
        householdId: householdId,
        accountId: accountId,
        type: 'expense',
        lines: [
          TxLine(
            amount: 10,
            currency: 'USD',
            categoryId: categoryId,
            accountId: accountId,
          ),
          // This line has no category — should NOT create a ledger entry.
          const TxLine(
            amount: 5,
            currency: 'USD',
            categoryId: null,
            accountId: null,
          ),
        ],
        baseCurrency: 'USD',
        deviceId: 'test-device',
      );

      final entries = await (db.select(db.allocationLedger)
            ..where((l) => l.sourceTransactionId.equals(txId)))
          .get();
      expect(entries, hasLength(1),
          reason: 'Only the categorised line should produce a ledger entry');
      expect(entries.first.amount, -10.0);
    });

    test('income transaction does not produce ledger entries', () async {
      final txId = await engine.recordTransaction(
        householdId: householdId,
        accountId: accountId,
        type: 'income',
        lines: [
          TxLine(
            amount: 2000,
            currency: 'USD',
            categoryId: categoryId,
            accountId: accountId,
          ),
        ],
        baseCurrency: 'USD',
        deviceId: 'test-device',
      );

      final entries = await (db.select(db.allocationLedger)
            ..where((l) => l.sourceTransactionId.equals(txId)))
          .get();
      expect(entries, isEmpty,
          reason: 'Income should never create consumption entries');
    });

    test('multi-account split assigns correct accountId per line', () async {
      await fundAllocation(500);

      final txId = await engine.recordTransaction(
        householdId: householdId,
        accountId: accountId,
        type: 'expense',
        lines: [
          TxLine(
            amount: 30,
            currency: 'USD',
            categoryId: categoryId,
            accountId: accountId,
          ),
          TxLine(
            amount: 20,
            currency: 'USD',
            categoryId: categoryId,
            accountId: accountId2,
          ),
        ],
        baseCurrency: 'USD',
        deviceId: 'test-device',
      );

      final lines = await (db.select(db.transactionLines)
            ..where((l) => l.transactionId.equals(txId)))
          .get();
      expect(lines, hasLength(2));

      final lineAccounts = lines.map((l) => l.accountId).toSet();
      expect(lineAccounts, containsAll([accountId, accountId2]));

      // Both ledger entries should reference their respective accounts.
      final ledger = await (db.select(db.allocationLedger)
            ..where((l) => l.sourceTransactionId.equals(txId)))
          .get();
      final ledgerAccounts = ledger.map((e) => e.sourceAccountId).toSet();
      expect(ledgerAccounts, containsAll([accountId, accountId2]));
    });
  });

  // ---------------------------------------------------------------------------
  // forceCommitExpense — cover shortfall from unallocated
  // ---------------------------------------------------------------------------
  group('forceCommitExpense', () {
    test('coverFromUnallocated funds the shortfall before committing',
        () async {
      // Fund allocation with only 10 but need 50.
      await fundAllocation(10);

      // Record income so there is unallocated money.
      await engine.recordIncome(
        householdId: householdId,
        accountId: accountId,
        amount: 1000,
        currency: 'USD',
        exchangeRateToBase: 1.0,
        createdBy: 'user',
        deviceId: 'test-device',
      );

      final txId = await engine.forceCommitExpense(
        householdId: householdId,
        accountId: accountId,
        allocationId: allocationId,
        amount: 50,
        currency: 'USD',
        exchangeRateToBase: 1.0,
        createdBy: 'user',
        deviceId: 'test-device',
        coverFromUnallocated: true,
      );

      // Transaction was created.
      final tx = await (db.select(db.transactions)
            ..where((t) => t.id.equals(txId)))
          .getSingleOrNull();
      expect(tx, isNotNull);
      expect(tx!.amount, 50);

      // Allocation balance should be: 10 (initial fund) + 40 (auto-cover) - 50 (expense) = 0
      final bal = await ledgerDao.getBalanceByCurrency(allocationId);
      expect(bal['USD'] ?? 0.0, closeTo(0.0, 0.001));
    });
  });

  // ---------------------------------------------------------------------------
  // recordIncomeDirectToAllocation
  // ---------------------------------------------------------------------------
  group('recordIncomeDirectToAllocation', () {
    test('creates both a transaction and a funding ledger entry', () async {
      final txId = await engine.recordIncomeDirectToAllocation(
        householdId: householdId,
        accountId: accountId,
        allocationId: allocationId,
        amount: 150,
        currency: 'USD',
        exchangeRateToBase: 1.0,
        createdBy: 'user',
        deviceId: 'test-device',
        note: 'Gift earmarked for groceries',
      );

      // Income transaction exists.
      final tx = await (db.select(db.transactions)
            ..where((t) => t.id.equals(txId)))
          .getSingleOrNull();
      expect(tx, isNotNull);
      expect(tx!.type, 'income');

      // A funding ledger entry was created for this allocation.
      final entries = await (db.select(db.allocationLedger)
            ..where((l) => l.sourceTransactionId.equals(txId)))
          .get();
      expect(entries, hasLength(1));
      expect(entries.first.entryType, 'funding');
      expect(entries.first.amount, 150);
      expect(entries.first.allocationId, allocationId);
    });
  });
}
