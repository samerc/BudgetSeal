import 'package:budgetseal/core/database/app_database.dart';
import 'package:budgetseal/core/providers/database_provider.dart';
import 'package:budgetseal/core/providers/getting_started_provider.dart';
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
    await db.into(db.accounts).insert(AccountsCompanion.insert(
        id: 'a', householdId: hh, name: 'Cash', type: 'cash',
        currency: 'USD', deviceId: 't'));
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  // Riverpod 3 pauses providers nobody listens to.
  Future<GettingStarted> read() {
    container.listen(gettingStartedProvider, (_, __) {});
    return container.read(gettingStartedProvider.future);
  }

  Future<void> addTx(String id, String type, {String? status}) =>
      db.into(db.transactions).insert(TransactionsCompanion.insert(
          id: id,
          householdId: hh,
          type: type,
          accountId: 'a',
          amount: 10,
          currency: 'USD',
          status: Value(status),
          createdBy: 't',
          deviceId: 't'));

  test('steps tick from real data', () async {
    var gs = await read();
    expect(gs.doneCount, 0);

    // A planned income doesn't count — it hasn't happened yet.
    await addTx('p', 'income', status: 'planned');
    await addTx('i', 'income');
    await db.into(db.allocations).insert(AllocationsCompanion.insert(
        id: 'env', householdId: hh, name: 'Food', categoryId: 'env',
        deviceId: 't'));
    container.invalidate(gettingStartedProvider);
    gs = await read();
    expect([gs.income, gs.envelopes, gs.funded, gs.expense],
        [true, true, false, false]);

    await db.into(db.allocationLedger).insert(AllocationLedgerCompanion.insert(
        id: 'l', allocationId: 'env', entryType: 'funding', amount: 10,
        currency: 'USD', deviceId: 't'));
    await addTx('e', 'expense');
    container.invalidate(gettingStartedProvider);
    gs = await read();
    expect(gs.allDone, isTrue);
  });
}
