import 'dart:math';

import 'package:budgetseal/core/database/app_database.dart';
import 'package:budgetseal/core/engine/allocation_engine.dart';
import 'package:budgetseal/core/engine/balance_calculator.dart';
import 'package:budgetseal/core/services/household_members.dart';
import 'package:budgetseal/core/sync/log_sync.dart';
import 'package:budgetseal/core/sync/op_log.dart';
import 'package:budgetseal/core/sync/sync_encryption.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// A shared folder in memory (Drive in the app).
class MemoryStore implements LogStore {
  final files = <String, String>{};
  final versions = <String, int>{};
  int writes = 0;

  @override
  Future<Map<String, String>> list() async =>
      {for (final e in versions.entries) e.key: '${e.value}'};

  @override
  Future<String?> read(String name) async => files[name];

  @override
  Future<void> write(String name, String content) async {
    writes++;
    files[name] = content;
    versions[name] = (versions[name] ?? 0) + 1;
  }
}

Future<AppDatabase> phone(String id) async {
  DeviceIdentity.debugSet(id);
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  await db.customSelect('SELECT 1').get(); // opens: the log's clock takes the id
  addTearDown(db.close);
  return db;
}

Future<Map<String, List<Map<String, Object?>>>> dump(AppDatabase db) async => {
      for (final t in opLogTables)
        t: [
          for (final r
              in await db.customSelect('SELECT * FROM $t ORDER BY id').get())
            r.data,
        ],
    };

Future<void> household(AppDatabase db) async {
  await db.into(db.households).insert(HouseholdsCompanion.insert(
      id: 'h', name: 'Home', createdByDeviceId: 'a'));
  for (final (id, cur) in [('bank', 'USD'), ('cash', 'USD'), ('lbp', 'LBP')]) {
    await db.into(db.accounts).insert(AccountsCompanion.insert(
        id: id, householdId: 'h', name: id, type: 'bank', currency: cur,
        initialBalance: const Value(1000), deviceId: 'a'));
  }
  await db.into(db.categories).insert(
      CategoriesCompanion.insert(id: 'food', householdId: 'h', name: 'Food'));
}

Future<Account> account(AppDatabase db, String id) =>
    (db.select(db.accounts)..where((a) => a.id.equals(id))).getSingle();

Future<void> later() => Future<void>.delayed(const Duration(milliseconds: 3));

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  tearDown(() => DeviceIdentity.debugSet('local'));

  test('a second phone joins and gets the same budget', () async {
    final store = MemoryStore();
    final a = await phone('phone-a');
    await household(a);
    await AllocationEngine(a).recordTransaction(
      householdId: 'h', accountId: 'bank', type: 'expense',
      lines: const [TxLine(amount: 12.5, currency: 'USD', categoryId: 'food')],
      baseCurrency: 'USD');
    await LogSync(a).sync(store);

    final b = await phone('phone-b');
    await LogSync(b).replaceFrom(store);
    expect(await dump(b), await dump(a));
    expect(await LogSync(b).householdIdsIn(store), {'h'});
    // B's own log stays empty: what it received isn't its change.
    final mine = await b.customSelect(
        "SELECT COUNT(*) AS n FROM sync_ops WHERE device = 'phone-b'").getSingle();
    expect(mine.read<int>('n'), 0);
  });

  test('edits to different fields of one row both stick', () async {
    final store = MemoryStore();
    final a = await phone('phone-a');
    await household(a);
    await LogSync(a).sync(store);
    final b = await phone('phone-b');
    await LogSync(b).replaceFrom(store);

    // Offline at the same time: A renames, B archives.
    await (a.update(a.accounts)..where((x) => x.id.equals('cash')))
        .write(const AccountsCompanion(name: Value('Wallet')));
    await (b.update(b.accounts)..where((x) => x.id.equals('cash')))
        .write(const AccountsCompanion(archived: Value(true)));
    await LogSync(a).sync(store);
    await LogSync(b).sync(store);
    await LogSync(a).sync(store);

    for (final db in [a, b]) {
      final cash = await account(db, 'cash');
      expect(cash.name, 'Wallet');
      expect(cash.archived, isTrue);
    }
    expect(await dump(b), await dump(a));
  });

  test('the same field edited on both phones: the later edit wins', () async {
    final store = MemoryStore();
    final a = await phone('phone-a');
    await household(a);
    await LogSync(a).sync(store);
    final b = await phone('phone-b');
    await LogSync(b).replaceFrom(store);

    await (b.update(b.accounts)..where((x) => x.id.equals('bank')))
        .write(const AccountsCompanion(name: Value('Bank (B)')));
    await later();
    await (a.update(a.accounts)..where((x) => x.id.equals('bank')))
        .write(const AccountsCompanion(name: Value('Bank (A, later)')));
    // B syncs first; A's later edit still wins everywhere.
    await LogSync(b).sync(store);
    await LogSync(a).sync(store);
    await LogSync(b).sync(store);
    for (final db in [a, b]) {
      expect((await account(db, 'bank')).name, 'Bank (A, later)');
    }
    // Both edits are in the log (Change history will show them).
    final edits = await a.customSelect(
        "SELECT COUNT(*) AS n FROM sync_ops WHERE tbl = 'accounts' "
        "AND row_id = 'bank' AND kind = 'update'").getSingle();
    expect(edits.read<int>('n'), 2);
  });

  test('a delete newer than an edit wins; an edit seen after it is ignored',
      () async {
    final store = MemoryStore();
    final a = await phone('phone-a');
    await household(a);
    await a.into(a.transactionTemplates).insert(
        TransactionTemplatesCompanion.insert(
            id: 'tpl', householdId: 'h', title: 'Coffee', type: 'expense',
            amount: 3, currency: 'USD'));
    await LogSync(a).sync(store);
    final b = await phone('phone-b');
    await LogSync(b).replaceFrom(store);

    await (b.update(b.transactionTemplates)..where((t) => t.id.equals('tpl')))
        .write(const TransactionTemplatesCompanion(amount: Value(4)));
    await later();
    await (a.delete(a.transactionTemplates)..where((t) => t.id.equals('tpl')))
        .go();
    await LogSync(a).sync(store);
    await LogSync(b).sync(store);
    await LogSync(a).sync(store);
    for (final db in [a, b]) {
      expect(await db.select(db.transactionTemplates).get(), isEmpty);
    }
  });

  test('money recorded offline on three phones adds up the same everywhere',
      () async {
    final store = MemoryStore();
    final a = await phone('phone-a');
    await household(a);
    await LogSync(a).sync(store);
    final phones = [a];
    for (final id in ['phone-b', 'phone-c']) {
      final p = await phone(id);
      await LogSync(p).replaceFrom(store);
      phones.add(p);
    }

    final rnd = Random(4);
    final expected = {'bank': 1000.0, 'cash': 1000.0, 'lbp': 1000.0};
    for (var round = 0; round < 3; round++) {
      for (final p in phones) {
        final engine = AllocationEngine(p);
        for (var i = 0; i < 15; i++) {
          if (rnd.nextBool()) {
            final amount = (rnd.nextInt(5000) + 1) / 100;
            final acct = ['bank', 'cash'][rnd.nextInt(2)];
            await engine.recordTransaction(
              householdId: 'h', accountId: acct, type: 'expense',
              lines: [TxLine(amount: amount, currency: 'USD',
                  categoryId: 'food', accountId: acct)],
              baseCurrency: 'USD');
            expected[acct] = expected[acct]! - amount;
          } else {
            final amount = (rnd.nextInt(100) + 1).toDouble();
            await engine.recordTransfer(
              householdId: 'h', fromAccountId: 'bank', toAccountId: 'lbp',
              amount: amount, currency: 'USD', exchangeRateToBase: 89500,
              createdBy: 't', deviceId: 'local');
            expected['bank'] = expected['bank']! - amount;
            expected['lbp'] = expected['lbp']! + amount * 89500;
          }
        }
      }
      // Phones sync in a different order each round.
      for (final p in [...phones]..shuffle(rnd)) {
        await LogSync(p).sync(store);
      }
    }
    for (final p in phones) {
      await LogSync(p).sync(store);
    }
    final first = await dump(phones.first);
    for (final p in phones) {
      expect(await dump(p), first);
      final balances = await BalanceCalculator(p).allAccountBalances('h');
      for (final e in expected.entries) {
        expect(balances[e.key], closeTo(e.value, 0.005), reason: e.key);
      }
    }
    // Nothing new: a sync applies nothing.
    expect(await LogSync(a).sync(store), 0);
  });

  test('only files with new entries are written; files are encrypted with '
      'the sync password', () async {
    await SyncEncryption.setPassword('correct horse');
    final store = MemoryStore();
    final a = await phone('phone-a');
    await household(a);
    final sync = LogSync(a, chunkSize: 3);
    await sync.sync(store);
    final first = store.writes;
    expect(first, greaterThan(1));
    expect(store.files.values.every((f) => f.startsWith('ENC:1:')), isTrue);
    await sync.sync(store);
    expect(store.writes, first, reason: 'nothing new, nothing written');
    await (a.update(a.accounts)..where((x) => x.id.equals('bank')))
        .write(const AccountsCompanion(name: Value('Main')));
    await sync.sync(store);
    // The rename logs two entries (the name, then the stamp): the last
    // file, and a new one when they straddle the 3-entry boundary.
    expect(store.writes - first, inInclusiveRange(1, 2),
        reason: 'only the files with new entries');
    expect(store.files.length, (await loadOps(a)).length ~/ 3 +
        ((await loadOps(a)).length % 3 == 0 ? 0 : 1));

    final b = await phone('phone-b');
    await LogSync(b).replaceFrom(store);
    expect((await account(b, 'bank')).name, 'Main');
    await SyncEncryption.clearPassword();
  });
}
