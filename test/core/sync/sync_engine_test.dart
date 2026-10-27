import 'dart:convert';

import 'package:budgetseal/core/database/app_database.dart';
import 'dart:io';

import 'package:budgetseal/core/engine/allocation_engine.dart';
import 'package:budgetseal/core/engine/recurring_engine.dart';
import 'package:budgetseal/core/providers/sync_provider.dart';
import 'package:budgetseal/core/services/household_members.dart';
import 'package:budgetseal/core/sync/cloud_provider.dart';
import 'package:budgetseal/core/sync/log_sync.dart';
import 'package:budgetseal/core/sync/op_log.dart';
import 'package:budgetseal/core/sync/sync_encryption.dart';
import 'package:budgetseal/core/sync/sync_engine.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'log_sync_test.dart' show MemoryStore;

/// Two devices (in-memory databases) that sync through their change logs,
/// and the readable snapshot file (export / restore).
void main() {
  late AppDatabase a;
  late AppDatabase b;
  late MemoryStore store;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    store = MemoryStore();
    DeviceIdentity.debugSet('dev-a');
    a = AppDatabase.forTesting(NativeDatabase.memory());
    await a.customSelect('SELECT 1').get();
    DeviceIdentity.debugSet('dev-b');
    b = AppDatabase.forTesting(NativeDatabase.memory());
    await b.customSelect('SELECT 1').get();
    DeviceIdentity.debugSet('local');
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

  /// [from] syncs, then [to]: what [to] applied.
  Future<int> sync(AppDatabase from, AppDatabase to) async {
    await LogSync(from).sync(store);
    return LogSync(to).sync(store);
  }

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

  test('the same row added on both: the later one wins on both', () async {
    await addAccount(a, name: 'Old');
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await addAccount(b, name: 'New');

    await sync(a, b);
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

    await SyncEngine(b).restoreFromJson(jsonEncode(file));
    expect((await b.select(b.accounts).getSingle()).lastModified, when);
  });

  group('recurring bill due on both devices', () {
    Future<void> seed(AppDatabase db) async {
      await addAccount(db);
      await db.into(db.allocations).insert(AllocationsCompanion.insert(
          id: 'env', householdId: 'hh', name: 'Rent', categoryId: 'cat',
          deviceId: 'x', lastModified: Value(DateTime(2026, 1, 1))));
      await db.into(db.categories).insert(CategoriesCompanion.insert(
          id: 'cat', householdId: 'hh', name: 'Rent',
          allocationId: const Value('env'),
          lastModified: Value(DateTime(2026, 1, 1))));
      final due = DateTime.now().subtract(const Duration(days: 1));
      await db.into(db.recurringTransactions).insert(
          RecurringTransactionsCompanion.insert(
              id: 'rec', householdId: 'hh', type: 'expense', amount: 500,
              currency: 'USD', accountId: 'acc',
              categoryId: const Value('cat'), frequency: 'monthly',
              nextDueDate: DateTime(due.year, due.month, due.day),
              lastModified: Value(DateTime(2026, 1, 1))));
    }

    Future<void> expectOnePosting(AppDatabase db) async {
      final txs = await (db.select(db.transactions)
            ..where((t) => t.createdBy.equals('user')))
          .get();
      expect(txs, hasLength(1));
      expect(await db.select(db.transactionLines).get(), hasLength(1));
      expect(await db.select(db.allocationLedger).get(), hasLength(1));
    }

    test('posted by both before syncing → one transaction', () async {
      await seed(a);
      await seed(b);
      expect(await RecurringEngine(a).processRecurring(), 1);
      expect(await RecurringEngine(b).processRecurring(), 1);

      await sync(a, b);
      await sync(b, a);
      await expectOnePosting(a);
      await expectOnePosting(b);
    });

    test('paid early on one, auto-posted on the other', () async {
      await seed(a);
      await seed(b);
      await RecurringEngine(a).postNow('rec');
      await RecurringEngine(b).processRecurring();

      await sync(b, a);
      await sync(a, b);
      await expectOnePosting(a);
      await expectOnePosting(b);
    });

    test('paid on another day → dated that day, still one posting', () async {
      await seed(a);
      final rec = await (a.select(a.recurringTransactions)).getSingle();
      final paid = DateTime.now().subtract(const Duration(days: 3));
      await RecurringEngine(a).postNow('rec', on: paid);
      final tx = await (a.select(a.transactions)).getSingle();
      expect(tx.createdAt,
          DateTime(paid.year, paid.month, paid.day, 12));
      expect(tx.id, RecurringEngine.occurrenceId('rec', rec.nextDueDate));
      // The occurrence is paid: launching later doesn't post it again.
      await RecurringEngine(a).processRecurring();
      await expectOnePosting(a);
    });

    test('already synced → not posted again', () async {
      await seed(a);
      await seed(b);
      await RecurringEngine(a).processRecurring();
      // B gets the transaction but not (yet) the advanced due date.
      await LogSync(b).apply([
        for (final op in await loadOps(a))
          if (op.table != 'recurring_transactions') op,
      ]);

      await RecurringEngine(b).processRecurring();
      await expectOnePosting(b);
    });
  });

  group('deleted transactions', () {
    Future<String> spend(AppDatabase db) async {
      await addAccount(db);
      await db.into(db.allocations).insert(AllocationsCompanion.insert(
          id: 'env', householdId: 'hh', name: 'Food', categoryId: 'cat',
          deviceId: 'x', lastModified: Value(DateTime(2026, 1, 1))));
      await db.into(db.categories).insert(CategoriesCompanion.insert(
          id: 'cat', householdId: 'hh', name: 'Food',
          allocationId: const Value('env'),
          lastModified: Value(DateTime(2026, 1, 1))));
      return AllocationEngine(db).recordTransaction(
          householdId: 'hh', accountId: 'acc', type: 'expense',
          lines: [TxLine(amount: 12, currency: 'USD', categoryId: 'cat')],
          baseCurrency: 'USD');
    }

    test("their envelope rows don't come back from the other device",
        () async {
      final id = await spend(a);
      await sync(a, b);
      expect(await b.select(b.allocationLedger).get(), hasLength(1));

      await AllocationEngine(a).deleteTransaction(id);
      await sync(b, a); // B's file still has the ledger row
      expect(await a.select(a.allocationLedger).get(), isEmpty);

      await sync(a, b);
      expect((await b.select(b.transactions).getSingle()).deleted, isTrue);
      expect(await b.select(b.allocationLedger).get(), isEmpty);
    });

    test('purged ones stay purged', () async {
      final id = await spend(a);
      await AllocationEngine(a).deleteTransaction(id);
      await sync(a, b);

      // Health Check → Purge on A.
      await (a.delete(a.transactionLines)
            ..where((l) => l.transactionId.equals(id)))
          .go();
      await (a.delete(a.transactions)..where((t) => t.id.equals(id))).go();

      await sync(b, a);
      expect(await a.select(a.transactions).get(), isEmpty);
      expect(await a.select(a.transactionLines).get(), isEmpty);
    });
  });

  test('a snapshot without time zones (older app) still restores', () async {
    await addAccount(a, name: 'Old', modified: DateTime(2026, 1, 1));
    final file = jsonDecode(await SyncEngine(a).exportToJson())
        as Map<String, dynamic>;
    file['accounts'] = [
      {
        ...(file['accounts'] as List)[0] as Map<String, dynamic>,
        'name': 'Renamed',
        'lastModified': '2026-02-01T10:00:00.000',
      }
    ];
    await SyncEngine(b).restoreFromJson(jsonEncode(file));
    final acc = await b.select(b.accounts).getSingle();
    expect(acc.name, 'Renamed');
    expect(acc.lastModified, DateTime(2026, 2, 1, 10));
  });

  group('sync errors', () {
    test('a wrong password says so, not "corrupted"', () async {
      await SyncEncryption.setPassword('right');
      final file = await SyncEncryption.encrypt('{}');
      await expectLater(SyncEncryption.decrypt(file, password: 'wrong'),
          throwsA(isA<SyncPasswordException>()));
      await SyncEncryption.clearPassword();
      await expectLater(SyncEngine(a).restoreFromJson(file),
          throwsA(isA<SyncPasswordException>()
              .having((e) => e.missing, 'missing', isTrue)));
    });

    test('users read a message, never the raw exception', () {
      expect(syncErrorText(const SyncPasswordException(missing: false)),
          contains('Wrong sync password'));
      expect(syncErrorText(const SocketException('Failed host lookup')),
          contains('Network'));
      expect(syncErrorText(const CloudAuthException()),
          contains('signed out'));
      final raw = syncErrorText(
          StateError('SqliteException(1): no such column: fetched_at'));
      expect(raw, isNot(contains('Sqlite')));
    });
  });
}
