import 'package:budgetseal/core/database/app_database.dart';
import 'package:budgetseal/core/providers/allocations_provider.dart';
import 'package:budgetseal/core/providers/database_provider.dart';
import 'package:budgetseal/core/providers/household_provider.dart';
import 'package:budgetseal/core/providers/seal_provider.dart';
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
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<void> envelope(String id, String type, double? target) =>
      db.into(db.allocations).insert(AllocationsCompanion.insert(
          id: id,
          householdId: hh,
          name: id,
          categoryId: id,
          type: Value(type),
          targetAmount: Value(target),
          targetCurrency: const Value('USD'),
          deviceId: 't'));

  Future<void> ledger(String id, String env, String type, double amount) =>
      db.into(db.allocationLedger).insert(AllocationLedgerCompanion.insert(
          id: id,
          allocationId: env,
          entryType: type,
          amount: amount,
          currency: 'USD',
          deviceId: 't'));

  test('spending seals on funding, flexible on balance', () async {
    await envelope('food', 'spending', 100);
    await envelope('trip', 'flexible', 500);
    await envelope('misc', 'spending', null); // no target: never sealed

    // Food funded in full, then partly spent — still sealed.
    await ledger('f1', 'food', 'funding', 100);
    await ledger('f2', 'food', 'consumption', -40);
    // Trip funded 300 of 500 — not sealed yet.
    await ledger('t1', 'trip', 'funding', 300);
    await ledger('m1', 'misc', 'funding', 50);

    container.listen(householdProvider, (_, __) {});
    container.listen(allocationsProvider, (_, __) {});
    container.listen(sealedEnvelopesProvider, (_, __) {});
    await container.read(householdProvider.future);
    expect(await container.read(sealedEnvelopesProvider.future), {'food'});

    await ledger('t2', 'trip', 'funding', 200);
    container.invalidate(sealedEnvelopesProvider);
    // The allocations stream picks up the new ledger row first.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(await container.read(sealedEnvelopesProvider.future),
        {'food', 'trip'});
  });
}
