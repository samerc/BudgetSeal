import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgetseal/core/database/app_database.dart';
import 'package:budgetseal/core/database/daos/ledger_dao.dart';
import 'package:budgetseal/core/engine/allocation_engine.dart';
import 'package:budgetseal/core/engine/balance_calculator.dart';
import 'package:uuid/uuid.dart';

void main() {
  late AppDatabase db;
  late AllocationEngine engine;
  late LedgerDao ledgerDao;
  late BalanceCalculator calc;
  const uuid = Uuid();

  late String householdId;
  late String accountId;
  late String allocationId;
  late String categoryId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    engine = AllocationEngine(db);
    ledgerDao = LedgerDao(db);
    calc = BalanceCalculator(db);

    householdId = uuid.v4();
    accountId = uuid.v4();
    allocationId = uuid.v4();
    categoryId = uuid.v4();

    await db.into(db.households).insert(HouseholdsCompanion.insert(
      id: householdId,
      name: 'Test Household',
      createdByDeviceId: 'test-device',
    ));
    await db.into(db.accounts).insert(AccountsCompanion.insert(
      id: accountId,
      householdId: householdId,
      name: 'Test Account',
      currency: 'USD',
      type: 'cash',
      deviceId: 'test-device',
    ));
    await db.into(db.allocations).insert(AllocationsCompanion.insert(
      id: allocationId,
      householdId: householdId,
      name: 'Test Envelope',
      categoryId: categoryId,
      deviceId: 'test-device',
    ));
    await db.into(db.categories).insert(CategoriesCompanion.insert(
      id: categoryId,
      householdId: householdId,
      name: 'Test Category',
      allocationId: Value(allocationId),
    ));
  });

  tearDown(() async => db.close());

  Future<void> addIncome(double amount) async {
    await engine.recordIncome(
      householdId: householdId,
      accountId: accountId,
      amount: amount,
      currency: 'USD',
      exchangeRateToBase: 1.0,
      createdBy: 'user',
      deviceId: 'test',
    );
  }

  Future<void> fund(double amount) async {
    await engine.fundAllocation(
      allocationId: allocationId,
      amount: amount,
      currency: 'USD',
      deviceId: 'test',
    );
  }

  // ── Zero and extreme amounts ──────────────────────────────────

  group('Edge cases — zero and extreme amounts', () {
    test('zero amount income does not change balance', () async {
      await addIncome(0);
      final balances = await calc.allAccountBalances(householdId);
      final bal = balances[accountId] ?? 0.0;
      expect(bal, closeTo(0.0, 0.001));
    });

    test('very small amount (0.001) is preserved', () async {
      await addIncome(0.001);
      final balances = await calc.allAccountBalances(householdId);
      expect(balances[accountId] ?? 0.0, closeTo(0.001, 0.0001));
    });

    test('very large amount (999999999) is preserved', () async {
      await addIncome(999999999);
      final balances = await calc.allAccountBalances(householdId);
      expect(balances[accountId] ?? 0.0, closeTo(999999999, 1));
    });
  });

  // ── Balance invariant ─────────────────────────────────────────

  group('Edge cases — balance invariant', () {
    test('invariant holds: acct = unallocated + allocations', () async {
      await addIncome(1000);
      await fund(400);

      // Expense 150
      await engine.recordExpense(
        householdId: householdId,
        accountId: accountId,
        allocationId: allocationId,
        amount: 150,
        currency: 'USD',
        exchangeRateToBase: 1.0,
        createdBy: 'user',
        deviceId: 'test',
      );

      final acctBals = await calc.allAccountBalances(householdId);
      final unalloc = await calc.unallocatedByCurrency(householdId);
      final allocBal = await ledgerDao.getBalanceByCurrency(allocationId);

      final acctUsd = acctBals[accountId] ?? 0.0;
      final unallocUsd = unalloc['USD'] ?? 0.0;
      final allocUsd = allocBal['USD'] ?? 0.0;

      expect(acctUsd, closeTo(850, 0.001)); // 1000 - 150
      expect(unallocUsd + allocUsd, closeTo(acctUsd, 0.001));
      expect(allocUsd, closeTo(250, 0.001)); // 400 - 150
    });

    test('invariant holds after delete', () async {
      await addIncome(500);
      await fund(300);

      final result = await engine.recordExpense(
        householdId: householdId,
        accountId: accountId,
        allocationId: allocationId,
        amount: 100,
        currency: 'USD',
        exchangeRateToBase: 1.0,
        createdBy: 'user',
        deviceId: 'test',
      );

      await engine.deleteTransaction(result.txId!);

      final acctBals = await calc.allAccountBalances(householdId);
      expect(acctBals[accountId] ?? 0.0, closeTo(500, 0.001));

      final allocBal = await ledgerDao.getBalanceByCurrency(allocationId);
      expect(allocBal['USD'] ?? 0.0, closeTo(300, 0.001));
    });
  });

  // ── Rapid operations ──────────────────────────────────────────

  group('Edge cases — rapid operations', () {
    test('20 rapid incomes accumulate correctly', () async {
      for (var i = 0; i < 20; i++) {
        await addIncome(10);
      }
      final bals = await calc.allAccountBalances(householdId);
      expect(bals[accountId] ?? 0.0, closeTo(200, 0.001));
    });

    test('fund then withdraw returns to zero', () async {
      await addIncome(500);
      await fund(200);
      await engine.withdrawFromAllocation(
        allocationId: allocationId,
        amount: 200,
        currency: 'USD',
        deviceId: 'test',
      );
      final allocBal = await ledgerDao.getBalanceByCurrency(allocationId);
      expect(allocBal['USD'] ?? 0.0, closeTo(0.0, 0.001));
    });
  });

  // ── Empty / nonexistent data ──────────────────────────────────

  group('Edge cases — empty and nonexistent data', () {
    test('balance of nonexistent account returns 0', () async {
      final bals = await calc.allAccountBalances('nonexistent-household');
      expect(bals['nonexistent-id'], isNull);
    });

    test('allocation balance of nonexistent ID returns empty', () async {
      final bal = await ledgerDao.getBalanceByCurrency('nonexistent-id');
      expect(bal, isEmpty);
    });

    test('unallocated for empty household returns empty', () async {
      final unalloc = await calc.unallocatedByCurrency('empty-household');
      expect(unalloc, isEmpty);
    });

    test('withdraw from empty allocation throws StateError', () async {
      expect(
        () => engine.withdrawFromAllocation(
          allocationId: allocationId,
          amount: 100,
          currency: 'USD',
          deviceId: 'test',
        ),
        throwsA(isA<StateError>()),
      );
    });
  });

  // ── Special characters ────────────────────────────────────────

  group('Edge cases — special characters in data', () {
    test('unicode note is stored and retrieved correctly', () async {
      final txId = await engine.recordIncome(
        householdId: householdId,
        accountId: accountId,
        amount: 50,
        currency: 'USD',
        exchangeRateToBase: 1.0,
        createdBy: 'user',
        deviceId: 'test',
        note: 'مصروف يومي 🎉 café résumé',
      );

      final tx = await (db.select(db.transactions)
            ..where((t) => t.id.equals(txId)))
          .getSingleOrNull();
      expect(tx, isNotNull);
      expect(tx!.note, 'مصروف يومي 🎉 café résumé');
    });

    test('category with quotes and special chars stored correctly', () async {
      final id = uuid.v4();
      await db.into(db.categories).insert(CategoriesCompanion.insert(
        id: id,
        householdId: householdId,
        name: "Food & Drink's — 50% off",
        icon: const Value('🍕'),
      ));

      final cat = await (db.select(db.categories)
            ..where((c) => c.id.equals(id)))
          .getSingleOrNull();
      expect(cat, isNotNull);
      expect(cat!.name, "Food & Drink's — 50% off");
      expect(cat.icon, '🍕');
    });

    test('SQL injection attempt in note is safely stored as plain text', () async {
      final txId = await engine.recordIncome(
        householdId: householdId,
        accountId: accountId,
        amount: 10,
        currency: 'USD',
        exchangeRateToBase: 1.0,
        createdBy: 'user',
        deviceId: 'test',
        note: "'; DROP TABLE transactions; --",
      );

      final tx = await (db.select(db.transactions)
            ..where((t) => t.id.equals(txId)))
          .getSingleOrNull();
      expect(tx, isNotNull);
      expect(tx!.note, "'; DROP TABLE transactions; --");

      // Verify table still exists
      final all = await db.select(db.transactions).get();
      expect(all, isNotEmpty);
    });
  });

  // ── Overspend handling ────────────────────────────────────────

  group('Edge cases — overspend', () {
    test('expense exceeding allocation balance returns overspend info', () async {
      await fund(50);
      final result = await engine.recordExpense(
        householdId: householdId,
        accountId: accountId,
        allocationId: allocationId,
        amount: 100,
        currency: 'USD',
        exchangeRateToBase: 1.0,
        createdBy: 'user',
        deviceId: 'test',
      );
      expect(result.overspend, isNotNull);
      expect(result.overspend!.shortfall, closeTo(50, 0.001));
    });

    test('force commit with cover from unallocated works', () async {
      await addIncome(1000);
      await fund(10);

      final txId = await engine.forceCommitExpense(
        householdId: householdId,
        accountId: accountId,
        allocationId: allocationId,
        amount: 50,
        currency: 'USD',
        exchangeRateToBase: 1.0,
        createdBy: 'user',
        deviceId: 'test',
        coverFromUnallocated: true,
      );

      expect(txId, isNotNull);
      final allocBal = await ledgerDao.getBalanceByCurrency(allocationId);
      expect(allocBal['USD'] ?? 0.0, closeTo(0.0, 0.001));
    });
  });
}
