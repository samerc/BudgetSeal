import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgetseal/core/database/app_database.dart';
import 'package:budgetseal/core/engine/allocation_engine.dart';
import 'package:budgetseal/core/engine/balance_calculator.dart';
import 'package:uuid/uuid.dart';

void main() {
  late AppDatabase db;
  late BalanceCalculator calculator;
  late AllocationEngine engine;
  const uuid = Uuid();

  late String householdId;
  late String accountId;
  late String accountId2;
  late String categoryId;
  late String allocationId;
  late String allocationId2;
  late String categoryId2;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    calculator = BalanceCalculator(db);
    engine = AllocationEngine(db);

    householdId = uuid.v4();
    await db.into(db.households).insert(HouseholdsCompanion.insert(
          id: householdId,
          name: 'Test Household',
          createdByDeviceId: 'test-device',
        ));

    accountId = uuid.v4();
    await db.into(db.accounts).insert(AccountsCompanion.insert(
          id: accountId,
          householdId: householdId,
          name: 'Checking',
          type: 'bank',
          currency: 'USD',
          initialBalance: const Value(1000.0),
          deviceId: 'test-device',
        ));

    accountId2 = uuid.v4();
    await db.into(db.accounts).insert(AccountsCompanion.insert(
          id: accountId2,
          householdId: householdId,
          name: 'Cash',
          type: 'cash',
          currency: 'USD',
          initialBalance: const Value(200.0),
          deviceId: 'test-device',
        ));

    allocationId = uuid.v4();
    categoryId = uuid.v4();
    await db.into(db.allocations).insert(AllocationsCompanion.insert(
          id: allocationId,
          householdId: householdId,
          name: 'Groceries',
          categoryId: categoryId,
          deviceId: 'test-device',
        ));
    await db.into(db.categories).insert(CategoriesCompanion.insert(
          id: categoryId,
          householdId: householdId,
          name: 'Groceries',
          allocationId: Value(allocationId),
        ));

    allocationId2 = uuid.v4();
    categoryId2 = uuid.v4();
    await db.into(db.allocations).insert(AllocationsCompanion.insert(
          id: allocationId2,
          householdId: householdId,
          name: 'Transport',
          categoryId: categoryId2,
          deviceId: 'test-device',
        ));
    await db.into(db.categories).insert(CategoriesCompanion.insert(
          id: categoryId2,
          householdId: householdId,
          name: 'Transport',
          allocationId: Value(allocationId2),
        ));
  });

  tearDown(() async => db.close());

  // ---------------------------------------------------------------------------
  // Account balance computation
  // ---------------------------------------------------------------------------
  group('accountBalance', () {
    test('returns initial balance when no transactions exist', () async {
      final bal = await calculator.accountBalance(accountId);
      expect(bal, 1000.0);
    });

    test('income increases account balance', () async {
      await engine.recordTransaction(
        householdId: householdId,
        accountId: accountId,
        type: 'income',
        lines: [
          TxLine(amount: 500, currency: 'USD', accountId: accountId),
        ],
        baseCurrency: 'USD',
        deviceId: 'test-device',
      );

      final bal = await calculator.accountBalance(accountId);
      expect(bal, 1500.0);
    });

    test('expense decreases account balance', () async {
      await engine.fundAllocation(
        allocationId: allocationId,
        amount: 500,
        currency: 'USD',
        deviceId: 'test-device',
      );

      await engine.recordTransaction(
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
        deviceId: 'test-device',
      );

      final bal = await calculator.accountBalance(accountId);
      expect(bal, 925.0);
    });

    test('transfer decreases source and increases destination', () async {
      await engine.recordTransfer(
        householdId: householdId,
        fromAccountId: accountId,
        toAccountId: accountId2,
        amount: 300,
        currency: 'USD',
        exchangeRateToBase: 1.0,
        createdBy: 'user',
        deviceId: 'test-device',
      );

      final balSource = await calculator.accountBalance(accountId);
      final balDest = await calculator.accountBalance(accountId2);

      expect(balSource, 700.0, reason: '1000 - 300');
      expect(balDest, 500.0, reason: '200 + 300');
    });

    test('multiple transactions accumulate correctly', () async {
      // Income +500
      await engine.recordTransaction(
        householdId: householdId,
        accountId: accountId,
        type: 'income',
        lines: [
          TxLine(amount: 500, currency: 'USD', accountId: accountId),
        ],
        baseCurrency: 'USD',
        deviceId: 'test-device',
      );

      // Fund allocation and expense -80
      await engine.fundAllocation(
        allocationId: allocationId,
        amount: 500,
        currency: 'USD',
        deviceId: 'test-device',
      );
      await engine.recordTransaction(
        householdId: householdId,
        accountId: accountId,
        type: 'expense',
        lines: [
          TxLine(
            amount: 80,
            currency: 'USD',
            categoryId: categoryId,
            accountId: accountId,
          ),
        ],
        baseCurrency: 'USD',
        deviceId: 'test-device',
      );

      // Transfer out -150
      await engine.recordTransfer(
        householdId: householdId,
        fromAccountId: accountId,
        toAccountId: accountId2,
        amount: 150,
        currency: 'USD',
        exchangeRateToBase: 1.0,
        createdBy: 'user',
        deviceId: 'test-device',
      );

      // 1000 + 500 - 80 - 150 = 1270
      final bal = await calculator.accountBalance(accountId);
      expect(bal, 1270.0);
    });

    test('returns 0 for a nonexistent account', () async {
      final bal = await calculator.accountBalance('does-not-exist');
      expect(bal, 0.0);
    });
  });

  // ---------------------------------------------------------------------------
  // Allocation balance computation
  // ---------------------------------------------------------------------------
  group('allocationBalanceByCurrency', () {
    test('returns empty map for unfunded allocation', () async {
      final bal = await calculator.allocationBalanceByCurrency(allocationId);
      expect(bal, isEmpty);
    });

    test('funding increases allocation balance', () async {
      await engine.fundAllocation(
        allocationId: allocationId,
        amount: 200,
        currency: 'USD',
        deviceId: 'test-device',
      );

      final bal = await calculator.allocationBalanceByCurrency(allocationId);
      expect(bal['USD'], 200.0);
    });

    test('expense consumption decreases allocation balance', () async {
      await engine.fundAllocation(
        allocationId: allocationId,
        amount: 200,
        currency: 'USD',
        deviceId: 'test-device',
      );

      await engine.recordTransaction(
        householdId: householdId,
        accountId: accountId,
        type: 'expense',
        lines: [
          TxLine(
            amount: 60,
            currency: 'USD',
            categoryId: categoryId,
            accountId: accountId,
          ),
        ],
        baseCurrency: 'USD',
        deviceId: 'test-device',
      );

      final bal = await calculator.allocationBalanceByCurrency(allocationId);
      expect(bal['USD'], 140.0);
    });

    test('multiple funding and consumption operations net correctly', () async {
      await engine.fundAllocation(
        allocationId: allocationId,
        amount: 300,
        currency: 'USD',
        deviceId: 'test-device',
      );
      await engine.fundAllocation(
        allocationId: allocationId,
        amount: 100,
        currency: 'USD',
        deviceId: 'test-device',
      );

      await engine.recordTransaction(
        householdId: householdId,
        accountId: accountId,
        type: 'expense',
        lines: [
          TxLine(
            amount: 50,
            currency: 'USD',
            categoryId: categoryId,
            accountId: accountId,
          ),
        ],
        baseCurrency: 'USD',
        deviceId: 'test-device',
      );
      await engine.recordTransaction(
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

      // 300 + 100 - 50 - 120 = 230
      final bal = await calculator.allocationBalanceByCurrency(allocationId);
      expect(bal['USD'], 230.0);
    });
  });

  // ---------------------------------------------------------------------------
  // Unallocated balance = total account balances - sum(allocation balances)
  // ---------------------------------------------------------------------------
  group('unallocatedByCurrency', () {
    test('equals total account balances when nothing is allocated', () async {
      final unallocated = await calculator.unallocatedByCurrency(householdId);
      // 1000 (checking) + 200 (cash) = 1200
      expect(unallocated['USD'], 1200.0);
    });

    test('decreases when allocations are funded', () async {
      await engine.fundAllocation(
        allocationId: allocationId,
        amount: 400,
        currency: 'USD',
        deviceId: 'test-device',
      );
      await engine.fundAllocation(
        allocationId: allocationId2,
        amount: 100,
        currency: 'USD',
        deviceId: 'test-device',
      );

      final unallocated = await calculator.unallocatedByCurrency(householdId);
      // 1200 total - 400 - 100 = 700
      expect(unallocated['USD'], 700.0);
    });

    test('income increases unallocated (money not yet assigned)', () async {
      await engine.fundAllocation(
        allocationId: allocationId,
        amount: 400,
        currency: 'USD',
        deviceId: 'test-device',
      );

      await engine.recordTransaction(
        householdId: householdId,
        accountId: accountId,
        type: 'income',
        lines: [
          TxLine(amount: 500, currency: 'USD', accountId: accountId),
        ],
        baseCurrency: 'USD',
        deviceId: 'test-device',
      );

      final unallocated = await calculator.unallocatedByCurrency(householdId);
      // (1000 + 500 + 200) - 400 = 1300
      expect(unallocated['USD'], 1300.0);
    });

    test('expense from allocation does not change unallocated', () async {
      await engine.fundAllocation(
        allocationId: allocationId,
        amount: 400,
        currency: 'USD',
        deviceId: 'test-device',
      );

      final unallocatedBefore =
          await calculator.unallocatedByCurrency(householdId);

      await engine.recordTransaction(
        householdId: householdId,
        accountId: accountId,
        type: 'expense',
        lines: [
          TxLine(
            amount: 50,
            currency: 'USD',
            categoryId: categoryId,
            accountId: accountId,
          ),
        ],
        baseCurrency: 'USD',
        deviceId: 'test-device',
      );

      final unallocatedAfter =
          await calculator.unallocatedByCurrency(householdId);

      // Expense debits both account balance (-50) and allocation balance (-50).
      // So unallocated = (account_total - 50) - (alloc_total - 50) = unchanged.
      expect(unallocatedAfter['USD'], unallocatedBefore['USD'],
          reason:
              'Categorised expense reduces both account and allocation equally');
    });

    test('invariant holds after complex sequence of operations', () async {
      // Income.
      await engine.recordTransaction(
        householdId: householdId,
        accountId: accountId,
        type: 'income',
        lines: [
          TxLine(amount: 2000, currency: 'USD', accountId: accountId),
        ],
        baseCurrency: 'USD',
        deviceId: 'test-device',
      );

      // Fund allocations.
      await engine.fundAllocation(
        allocationId: allocationId,
        amount: 800,
        currency: 'USD',
        deviceId: 'test-device',
      );
      await engine.fundAllocation(
        allocationId: allocationId2,
        amount: 300,
        currency: 'USD',
        deviceId: 'test-device',
      );

      // Expenses.
      await engine.recordTransaction(
        householdId: householdId,
        accountId: accountId,
        type: 'expense',
        lines: [
          TxLine(
            amount: 150,
            currency: 'USD',
            categoryId: categoryId,
            accountId: accountId,
          ),
        ],
        baseCurrency: 'USD',
        deviceId: 'test-device',
      );
      await engine.recordTransaction(
        householdId: householdId,
        accountId: accountId2,
        type: 'expense',
        lines: [
          TxLine(
            amount: 40,
            currency: 'USD',
            categoryId: categoryId2,
            accountId: accountId2,
          ),
        ],
        baseCurrency: 'USD',
        deviceId: 'test-device',
      );

      // Transfer between accounts.
      await engine.recordTransfer(
        householdId: householdId,
        fromAccountId: accountId,
        toAccountId: accountId2,
        amount: 250,
        currency: 'USD',
        exchangeRateToBase: 1.0,
        createdBy: 'user',
        deviceId: 'test-device',
      );

      // Check the invariant:
      //   sum(account balances) = unallocated + sum(allocation balances)
      final bal1 = await calculator.accountBalance(accountId);
      final bal2 = await calculator.accountBalance(accountId2);
      final totalAccounts = bal1 + bal2;

      final allocBal1 =
          await calculator.allocationBalanceByCurrency(allocationId);
      final allocBal2 =
          await calculator.allocationBalanceByCurrency(allocationId2);
      final totalAllocations =
          (allocBal1['USD'] ?? 0) + (allocBal2['USD'] ?? 0);

      final unallocated = await calculator.unallocatedByCurrency(householdId);
      final unallocatedUsd = unallocated['USD'] ?? 0;

      expect(totalAccounts, closeTo(unallocatedUsd + totalAllocations, 0.001),
          reason:
              'Core invariant: account_sum = unallocated + allocation_sum');

      // Also verify via the built-in check.
      final ok = await calculator.checkInvariant(householdId);
      expect(ok, isTrue);
    });
  });
}
