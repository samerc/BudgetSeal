import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgetseal/core/database/app_database.dart';
import 'package:budgetseal/core/engine/allocation_engine.dart';
import 'package:budgetseal/core/engine/envelope_for_category.dart';

/// The add screen previews the envelope with [envelopeForCategory]; it must
/// name the same envelope the engine then debits.
void main() {
  late AppDatabase db;
  late AllocationEngine engine;
  const hh = 'hh';

  Future<void> envelope(String id, {String? categoryId, bool archived = false}) =>
      db.into(db.allocations).insert(AllocationsCompanion.insert(
            id: id,
            householdId: hh,
            name: id,
            categoryId: categoryId ?? 'cat-$id',
            archived: Value(archived),
            deviceId: 't',
          ));

  Future<void> category(String id, {String? allocationId, String? parentId}) =>
      db.into(db.categories).insert(CategoriesCompanion.insert(
            id: id,
            householdId: hh,
            name: id,
            allocationId: Value(allocationId),
            parentId: Value(parentId),
          ));

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    engine = AllocationEngine(db);
    await db.into(db.households).insert(HouseholdsCompanion.insert(
        id: hh, name: 'Home', createdByDeviceId: 't'));
    await db.into(db.accounts).insert(AccountsCompanion.insert(
        id: 'acc', householdId: hh, name: 'Cash', type: 'cash',
        currency: 'USD', deviceId: 't'));

    await envelope('food');
    await envelope('transport');
    await envelope('legacy', categoryId: 'old');
    await envelope('gone', archived: true);
    await category('groceries', allocationId: 'food'); // own link
    await category('car', allocationId: 'transport');
    await category('fuel', parentId: 'car'); // parent's envelope
    await category('old'); // legacy envelope keyed by category
    await category('hobby', allocationId: 'gone'); // archived: none
    await category('gifts'); // no envelope at all
  });

  tearDown(() => db.close());

  test('preview names the envelope the engine debits', () async {
    final cats = {for (final c in await db.select(db.categories).get()) c.id: c};
    final live = await (db.select(db.allocations)
          ..where((a) => a.archived.equals(false) & a.deleted.equals(false)))
        .get();

    for (final catId in ['groceries', 'fuel', 'old', 'hobby', 'gifts']) {
      final txId = await engine.recordTransaction(
        householdId: hh,
        accountId: 'acc',
        type: 'expense',
        lines: [TxLine(amount: 5, currency: 'USD', categoryId: catId)],
        baseCurrency: 'USD',
      );
      final debit = await (db.select(db.allocationLedger)
            ..where((l) =>
                l.sourceTransactionId.equals(txId) &
                l.entryType.equals('consumption')))
          .getSingleOrNull();
      expect(
        envelopeForCategory(catId, categoriesById: cats, liveAllocations: live),
        debit?.allocationId,
        reason: catId,
      );
    }
    expect(
        envelopeForCategory('fuel', categoriesById: cats, liveAllocations: live),
        'transport');
    expect(
        envelopeForCategory('hobby', categoriesById: cats, liveAllocations: live),
        isNull);
  });
}
