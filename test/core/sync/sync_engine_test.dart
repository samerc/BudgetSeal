import 'dart:convert';

import 'package:budgetseal/core/database/app_database.dart';
import 'package:budgetseal/core/sync/sync_engine.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// Two devices (in-memory databases) that sync through the JSON file.
void main() {
  late AppDatabase a;
  late AppDatabase b;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    a = AppDatabase.forTesting(NativeDatabase.memory());
    b = AppDatabase.forTesting(NativeDatabase.memory());
    for (final db in [a, b]) {
      await db.into(db.households).insert(HouseholdsCompanion.insert(
          id: 'hh', name: 'Home', createdByDeviceId: 't',
          lastModified: Value(DateTime(2026, 1, 1))));
    }
  });

  tearDown(() async {
    await a.close();
    await b.close();
  });

  /// Pushes [from]'s file into [to], as `SyncNotifier.sync()` does.
  Future<int> sync(AppDatabase from, AppDatabase to) async =>
      SyncEngine(to).mergeFromJson(await SyncEngine(from).exportToJson());

  Future<void> addAccount(AppDatabase db, {String name = 'Bank',
      DateTime? modified}) =>
      db.into(db.accounts).insert(AccountsCompanion.insert(
          id: 'acc', householdId: 'hh', name: name, type: 'bank',
          currency: 'USD', deviceId: 'x',
          lastModified: Value(modified ?? DateTime(2026, 1, 1))));

  Future<void> addTx(AppDatabase db, {DateTime? modified}) async {
    await db.into(db.transactions).insert(TransactionsCompanion.insert(
        id: 'tx', householdId: 'hh', type: 'expense', accountId: 'acc',
        amount: 5, currency: 'USD', createdBy: 'a', deviceId: 'a',
        lastModified: Value(modified ?? DateTime(2026, 1, 1))));
    await db.into(db.transactionLines).insert(TransactionLinesCompanion.insert(
        id: 'l1', transactionId: 'tx', amount: 5, currency: 'USD'));
  }

  test('a transaction made on one device merges into the other', () async {
    await addAccount(a);
    await addTx(a);

    expect(await sync(a, b), greaterThan(0));
    expect(await b.select(b.transactions).get(), hasLength(1));
    expect(await b.select(b.transactionLines).get(), hasLength(1));
  });

  test('every table merges', () async {
    await addAccount(a);
    await addTx(a);
    await a.into(a.users).insert(UsersCompanion.insert(
        id: 'u', householdId: 'hh', name: 'Sam', deviceId: 'a'));
    await a.into(a.allocations).insert(AllocationsCompanion.insert(
        id: 'env', householdId: 'hh', name: 'Food', categoryId: 'cat',
        deviceId: 'a'));
    await a.into(a.categories).insert(CategoriesCompanion.insert(
        id: 'cat', householdId: 'hh', name: 'Food'));
    await a.into(a.allocationLedger).insert(AllocationLedgerCompanion.insert(
        id: 'led', allocationId: 'env', entryType: 'funding', amount: 10,
        currency: 'USD', deviceId: 'a'));
    await a.into(a.recurringTransactions).insert(
        RecurringTransactionsCompanion.insert(
            id: 'rec', householdId: 'hh', type: 'expense', amount: 9,
            currency: 'USD', accountId: 'acc', frequency: 'monthly',
            nextDueDate: DateTime(2026, 2, 1)));
    await a.into(a.transactionTemplates).insert(
        TransactionTemplatesCompanion.insert(
            id: 'tpl', householdId: 'hh', title: 'Coffee', type: 'expense',
            amount: 3, currency: 'USD', accountId: const Value('acc')));
    await a.into(a.fxRates).insert(FxRatesCompanion.insert(
        id: 'fx', fromCurrency: 'EUR', toCurrency: 'USD', rate: 1.1));
    await a.into(a.objectives).insert(ObjectivesCompanion.insert(
        id: 'obj', householdId: 'hh', name: 'Trip', type: 'goal',
        targetCurrency: 'USD', deviceId: 'a'));

    await sync(a, b);

    for (final t in b.allTables) {
      final count = await b.customSelect(
          'SELECT COUNT(*) AS c FROM ${t.actualTableName}').getSingle();
      expect(count.data['c'], 1, reason: t.actualTableName);
    }
    // Nothing new the second time.
    expect(await sync(a, b), 0);
  });

  test('the newer edit wins in both directions', () async {
    await addAccount(a, name: 'Old', modified: DateTime(2026, 1, 1));
    await addAccount(b, name: 'New', modified: DateTime(2026, 3, 1));

    expect(await sync(a, b), 0); // older file doesn't overwrite
    expect((await b.select(b.accounts).getSingle()).name, 'New');

    await sync(b, a);
    expect((await a.select(a.accounts).getSingle()).name, 'New');
  });

  test('a delete reaches the other device', () async {
    await addAccount(a);
    await addTx(a);
    await sync(a, b);

    await (a.update(a.transactions)..where((t) => t.id.equals('tx')))
        .write(TransactionsCompanion(
            deleted: const Value(true),
            lastModified: Value(DateTime(2026, 2, 1))));
    await sync(a, b);

    expect((await b.select(b.transactions).getSingle()).deleted, isTrue);
  });

  test('dates are written in UTC and read back as the same moment', () async {
    final when = DateTime(2026, 5, 4, 23, 30);
    await addAccount(a, modified: when);

    final file = jsonDecode(await SyncEngine(a).exportToJson())
        as Map<String, dynamic>;
    final stamp = (file['accounts'] as List).single['lastModified'] as String;
    expect(stamp, endsWith('Z'));

    await sync(a, b);
    expect((await b.select(b.accounts).getSingle()).lastModified, when);
  });

  test('a file without time zones (older app) still merges', () async {
    await addAccount(a, name: 'Old', modified: DateTime(2026, 1, 1));
    final file = jsonDecode(await SyncEngine(b).exportToJson())
        as Map<String, dynamic>;
    file['accounts'] = [
      {
        ...(jsonDecode(await SyncEngine(a).exportToJson())
            as Map<String, dynamic>)['accounts'][0] as Map<String, dynamic>,
        'name': 'Renamed',
        'lastModified': '2026-02-01T10:00:00.000',
      }
    ];
    expect(await SyncEngine(a).mergeFromJson(jsonEncode(file)), 1);
    final acc = await a.select(a.accounts).getSingle();
    expect(acc.name, 'Renamed');
    expect(acc.lastModified, DateTime(2026, 2, 1, 10));
  });
}
