import 'package:budgetseal/core/database/app_database.dart';
import 'package:budgetseal/core/providers/budget_impact_provider.dart';
import 'package:budgetseal/core/providers/database_provider.dart';
import 'package:budgetseal/core/providers/household_provider.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const hh = 'hh';
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)]);
    container.read(currentHouseholdIdProvider.notifier).set(hh);
    await db.into(db.households).insert(HouseholdsCompanion.insert(
        id: hh, name: 'Home', createdByDeviceId: 't'));
    await db.into(db.allocations).insert(AllocationsCompanion.insert(
        id: 'food',
        householdId: hh,
        name: 'Food',
        categoryId: 'food',
        deviceId: 't'));
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<void> tx(String id, DateTime at, {bool deleted = false}) =>
      db.into(db.transactions).insert(TransactionsCompanion.insert(
          id: id,
          householdId: hh,
          type: 'expense',
          accountId: 'a',
          amount: 10,
          currency: 'USD',
          createdAt: Value(at),
          deleted: Value(deleted),
          createdBy: 't',
          deviceId: 't'));

  Future<void> ledger(String id, String type, double amount, DateTime at,
          {String? tx}) =>
      db.into(db.allocationLedger).insert(AllocationLedgerCompanion.insert(
          id: id,
          allocationId: 'food',
          sourceTransactionId: Value(tx),
          entryType: type,
          amount: amount,
          currency: 'USD',
          createdAt: Value(at),
          deviceId: 't'));

  test('balance right after each expense, by transaction date', () async {
    final d = DateTime(2026, 10, 1, 9);
    await ledger('fund', 'funding', 100, d);
    // Recorded today but dated Oct 5; the second one dated Oct 3.
    await tx('t1', DateTime(2026, 10, 5));
    await ledger('c1', 'consumption', -40, DateTime(2026, 10, 20), tx: 't1');
    await tx('t2', DateTime(2026, 10, 3));
    await ledger('c2', 'consumption', -70, DateTime(2026, 10, 21), tx: 't2');
    // A deleted expense counts for nothing.
    await tx('t3', DateTime(2026, 10, 4), deleted: true);
    await ledger('c3', 'consumption', -500, DateTime(2026, 10, 21), tx: 't3');

    container.listen(txEnvelopeImpactProvider, (_, __) {});
    final m = await container.read(txEnvelopeImpactProvider.future);
    expect(m['t2']!.balanceAfter, closeTo(30, 0.001));
    expect(m['t1']!.balanceAfter, closeTo(-10, 0.001));
    expect(m['t1']!.overspent, isTrue);
    expect(m['t1']!.balanceNow, closeTo(-10, 0.001));
    expect(m['t1']!.name, 'Food');
    expect(m.containsKey('t3'), isFalse);
  });
}
