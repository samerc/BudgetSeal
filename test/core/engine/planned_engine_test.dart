import 'package:budgetseal/core/database/app_database.dart';
import 'package:budgetseal/core/engine/allocation_engine.dart';
import 'package:budgetseal/core/engine/planned_engine.dart';
import 'package:budgetseal/core/sync/sync_engine.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  Future<void> seed(AppDatabase db) async {
    await db.into(db.households).insert(HouseholdsCompanion.insert(
        id: 'hh', name: 'Home', createdByDeviceId: 't',
        lastModified: Value(DateTime(2026, 1, 1))));
    for (final (id, cur) in [('usd', 'USD'), ('eur', 'EUR')]) {
      await db.into(db.accounts).insert(AccountsCompanion.insert(
          id: id, householdId: 'hh', name: id, type: 'bank', currency: cur,
          deviceId: 'x', lastModified: Value(DateTime(2026, 1, 1))));
    }
    await db.into(db.allocations).insert(AllocationsCompanion.insert(
        id: 'env', householdId: 'hh', name: 'Rent', categoryId: 'cat',
        deviceId: 'x', lastModified: Value(DateTime(2026, 1, 1))));
    await db.into(db.categories).insert(CategoriesCompanion.insert(
        id: 'cat', householdId: 'hh', name: 'Rent',
        allocationId: const Value('env'),
        lastModified: Value(DateTime(2026, 1, 1))));
  }

  Future<String> plan(AppDatabase db,
          {String type = 'expense',
          String account = 'usd',
          String? dest,
          String currency = 'USD',
          DateTime? date}) =>
      PlannedEngine(db).save(
        householdId: 'hh',
        type: type,
        accountId: account,
        destinationAccountId: dest,
        amount: 800,
        currency: currency,
        categoryId: type == 'expense' ? 'cat' : null,
        note: 'Rent',
        date: date ?? DateTime(2026, 3, 1),
        createdBy: 'user',
        deviceId: 'x',
      );

  Future<String> post(AppDatabase db, String id,
          {RateLookup? rate, DateTime? now}) =>
      PlannedEngine(db).post(id,
          baseCurrency: 'USD',
          rate: rate ?? (from, to) async => null,
          createdBy: 'user',
          deviceId: 'x',
          now: now ?? DateTime(2026, 3, 10));

  Future<List<Transaction>> posted(AppDatabase db) =>
      (db.select(db.transactions)
            ..where((t) => t.status.isNull() & t.deleted.equals(false)))
          .get();

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await seed(db);
  });

  tearDown(() => db.close());

  test('a plan has one line and no envelope rows', () async {
    final id = await plan(db);
    final tx = await (db.select(db.transactions)
          ..where((t) => t.id.equals(id)))
        .getSingle();
    expect(tx.status, 'planned');
    expect(await db.select(db.transactionLines).get(), hasLength(1));
    expect(await db.select(db.allocationLedger).get(), isEmpty);
  });

  test('editing replaces the plan', () async {
    final id = await plan(db);
    final newId = await PlannedEngine(db).save(
        replaceId: id, householdId: 'hh', type: 'expense', accountId: 'usd',
        amount: 900, currency: 'USD', categoryId: 'cat',
        date: DateTime(2026, 4, 1), createdBy: 'user', deviceId: 'x');
    final live = await (db.select(db.transactions)
          ..where((t) => t.deleted.equals(false)))
        .get();
    expect(live.single.id, newId);
    expect(live.single.amount, 900);
    expect((await db.select(db.transactionLines).get()).single.transactionId,
        newId);
  });

  test('posting records the payment and removes the plan', () async {
    final id = await plan(db);
    final txId = await post(db, id);

    expect(txId, PlannedEngine.postedId(id));
    final tx = (await posted(db)).single;
    expect(tx.id, txId);
    expect(tx.createdAt, DateTime(2026, 3, 1)); // planned date, already past
    expect((await db.select(db.allocationLedger).get()).single.amount, -800);
    final planRow = await (db.select(db.transactions)
          ..where((t) => t.id.equals(id)))
        .getSingle();
    expect(planRow.deleted, isTrue);
  });

  test('posting twice (or two taps at once) posts once', () async {
    final id = await plan(db);
    await Future.wait([post(db, id), post(db, id)]);
    await post(db, id);
    expect(await posted(db), hasLength(1));
    expect(await db.select(db.allocationLedger).get(), hasLength(1));
  });

  test('a plan posted on two devices before syncing → one payment', () async {
    final other = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(other.close);
    await seed(other);
    final id = await plan(db);
    await SyncEngine(other).mergeFromJson(await SyncEngine(db).exportToJson());

    await post(db, id);
    await post(other, id);
    await SyncEngine(db).mergeFromJson(await SyncEngine(other).exportToJson());
    await SyncEngine(other).mergeFromJson(await SyncEngine(db).exportToJson());

    expect(await posted(db), hasLength(1));
    expect(await posted(other), hasLength(1));
  });

  test('paid early → dated today, not in the future', () async {
    final id = await plan(db, date: DateTime(2026, 5, 1));
    await post(db, id, now: DateTime(2026, 3, 10, 9));
    expect((await posted(db)).single.createdAt, DateTime(2026, 3, 10, 9));
  });

  test('a foreign line takes the rate given when posting', () async {
    final id = await plan(db, account: 'eur', currency: 'EUR');
    await post(db, id, rate: (from, to) async => from == 'EUR' ? 1.1 : null);
    final line = (await db.select(db.transactionLines).get())
        .firstWhere((l) => l.transactionId != id);
    expect(line.exchangeRateToBase, 1.1);
  });

  test('a cross-currency transfer without a rate fails and keeps the plan',
      () async {
    final id = await plan(db, type: 'transfer', dest: 'eur');
    await expectLater(
        post(db, id), throwsA(isA<CurrencyConversionException>()));
    expect(await posted(db), isEmpty);
    final planRow = await (db.select(db.transactions)
          ..where((t) => t.id.equals(id)))
        .getSingle();
    expect(planRow.deleted, isFalse);
  });
}
