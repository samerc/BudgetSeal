import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgetseal/core/database/app_database.dart';
import 'package:budgetseal/core/database/daos/ledger_dao.dart';
import 'package:budgetseal/core/engine/allocation_engine.dart';
import 'package:budgetseal/core/engine/period_engine.dart';

void main() {
  group('budgetPeriodFor', () {
    test('starts on the start day of this month once it has passed', () {
      final p = budgetPeriodFor(25, DateTime(2026, 3, 27));
      expect(p.start, DateTime(2026, 3, 25));
      expect(p.end, DateTime(2026, 4, 25));
    });

    test('falls back to last month before the start day', () {
      final p = budgetPeriodFor(25, DateTime(2026, 3, 10));
      expect(p.start, DateTime(2026, 2, 25));
      expect(p.end, DateTime(2026, 3, 25));
    });

    test('clamps day 31 to short months', () {
      final p = budgetPeriodFor(31, DateTime(2026, 2, 28, 12));
      expect(p.start, DateTime(2026, 2, 28));
      expect(p.end, DateTime(2026, 3, 31));
    });

    test('crosses the year boundary', () {
      final p = budgetPeriodFor(15, DateTime(2026, 1, 3));
      expect(p.start, DateTime(2025, 12, 15));
      expect(p.end, DateTime(2026, 1, 15));
    });
  });

  group('watchSpendingInPeriod', () {
    late AppDatabase db;
    late AllocationEngine engine;
    const hh = 'hh';
    const acc = 'acc';
    const alloc = 'alloc';
    const cat = 'cat';

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      engine = AllocationEngine(db);
      await db.into(db.households).insert(HouseholdsCompanion.insert(
          id: hh, name: 'H', createdByDeviceId: 'd'));
      await db.into(db.accounts).insert(AccountsCompanion.insert(
          id: acc,
          householdId: hh,
          name: 'Bank',
          type: 'bank',
          currency: 'USD',
          deviceId: 'd'));
      await db.into(db.allocations).insert(AllocationsCompanion.insert(
          id: alloc,
          householdId: hh,
          name: 'Food',
          categoryId: cat,
          deviceId: 'd'));
      await db.into(db.categories).insert(CategoriesCompanion.insert(
          id: cat,
          householdId: hh,
          name: 'Food',
          allocationId: const Value(alloc)));
    });

    tearDown(() async => db.close());

    Future<String> spend(double amount, DateTime date) =>
        engine.recordTransaction(
          householdId: hh,
          accountId: acc,
          type: 'expense',
          lines: [
            TxLine(
                amount: amount,
                currency: 'USD',
                categoryId: cat,
                accountId: acc),
          ],
          baseCurrency: 'USD',
          date: date,
        );

    test('counts only consumption inside the period, by transaction date',
        () async {
      await engine.fundAllocation(
          allocationId: alloc,
          amount: 500,
          currency: 'USD',
          deviceId: 'd');
      await spend(30, DateTime(2026, 3, 1)); // first second of the period
      await spend(20, DateTime(2026, 3, 15));
      await spend(99, DateTime(2026, 2, 28)); // previous period
      await spend(99, DateTime(2026, 4, 1)); // next period

      final result = await LedgerDao(db)
          .watchSpendingInPeriod(
              hh, DateTime(2026, 3, 1), DateTime(2026, 4, 1))
          .first;
      // Funding is not spending; neighbours are outside the range.
      expect(result[alloc]?['USD'], closeTo(50, 0.001));
    });

    test('an unlinked subcategory spends from its parent envelope', () async {
      await db.into(db.categories).insert(CategoriesCompanion.insert(
          id: 'sub',
          householdId: hh,
          name: 'Snacks',
          parentId: const Value(cat)));
      await engine.recordTransaction(
        householdId: hh,
        accountId: acc,
        type: 'expense',
        lines: [
          TxLine(
              amount: 12, currency: 'USD', categoryId: 'sub', accountId: acc),
        ],
        baseCurrency: 'USD',
        date: DateTime(2026, 3, 5),
      );

      final result = await LedgerDao(db)
          .watchSpendingInPeriod(
              hh, DateTime(2026, 3, 1), DateTime(2026, 4, 1))
          .first;
      expect(result[alloc]?['USD'], closeTo(12, 0.001));
    });

    test('ignores deleted transactions', () async {
      final id = await spend(40, DateTime(2026, 3, 10));
      await (db.update(db.transactions)..where((t) => t.id.equals(id)))
          .write(const TransactionsCompanion(deleted: Value(true)));

      final result = await LedgerDao(db)
          .watchSpendingInPeriod(
              hh, DateTime(2026, 3, 1), DateTime(2026, 4, 1))
          .first;
      expect(result[alloc], isNull);
    });
  });
}
