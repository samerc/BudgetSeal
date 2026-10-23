import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgetseal/core/database/app_database.dart';
import 'package:budgetseal/core/database/daos/ledger_dao.dart';
import 'package:budgetseal/core/engine/allocation_engine.dart';
import 'package:budgetseal/core/engine/budget_history.dart';

/// The month close and the track record report call an envelope "held" or
/// "over" from its balance at the end of the period.
void main() {
  late AppDatabase db;
  late AllocationEngine engine;
  const hh = 'hh';

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    engine = AllocationEngine(db);
    await db.into(db.households).insert(HouseholdsCompanion.insert(
        id: hh, name: 'Home', createdByDeviceId: 't'));
    await db.into(db.accounts).insert(AccountsCompanion.insert(
        id: 'acc', householdId: hh, name: 'Cash', type: 'cash',
        currency: 'USD', deviceId: 't'));
    for (final id in ['food', 'fuel', 'idle']) {
      await db.into(db.allocations).insert(AllocationsCompanion.insert(
          id: id, householdId: hh, name: id, categoryId: 'cat-$id',
          deviceId: 't'));
      await db.into(db.categories).insert(CategoriesCompanion.insert(
          id: 'cat-$id', householdId: hh, name: id,
          allocationId: Value(id)));
    }
  });

  tearDown(() => db.close());

  Future<void> spend(String cat, double amount, DateTime date) =>
      engine.recordTransaction(
        householdId: hh,
        accountId: 'acc',
        type: 'expense',
        lines: [TxLine(amount: amount, currency: 'USD', categoryId: cat)],
        baseCurrency: 'USD',
        date: date,
      );

  test('held, over and idle from the closing balance', () async {
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 1));
    final end = now.add(const Duration(days: 1));
    await engine.fundAllocation(
        allocationId: 'food', amount: 100, currency: 'USD', deviceId: 't');
    await engine.fundAllocation(
        allocationId: 'fuel', amount: 50, currency: 'USD', deviceId: 't');
    await spend('cat-food', 60, now);
    await spend('cat-fuel', 80, now);
    // After the period: not counted.
    await spend('cat-food', 70, end.add(const Duration(days: 2)));

    final stats = await envelopePeriodStats(LedgerDao(db),
        householdId: hh, start: start, end: end, currency: 'USD');

    expect(stats['food']!.funded, 100);
    expect(stats['food']!.spent, 60);
    expect(stats['food']!.endBalance, closeTo(40, 0.001));
    expect(stats['food']!.outcome, EnvelopeOutcome.held);
    expect(stats['fuel']!.outcome, EnvelopeOutcome.over);
    expect(stats['fuel']!.endBalance, closeTo(-30, 0.001));
    expect(stats.containsKey('idle'), isFalse);
  });
}
