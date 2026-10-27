import 'package:budgetseal/core/database/app_database.dart';
import 'package:budgetseal/core/engine/base_currency_change.dart';
import 'package:budgetseal/core/sync/op_log.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../scale/big_budget.dart';

/// Every shared table, row by row.
Future<Map<String, List<Map<String, Object?>>>> dump(AppDatabase db) async => {
      for (final t in opLogTables)
        t: [
          for (final r
              in await db.customSelect('SELECT * FROM $t ORDER BY id').get())
            r.data,
        ],
    };

Future<int> opCount(AppDatabase db) async => (await db
        .customSelect('SELECT COUNT(*) AS n FROM sync_ops')
        .getSingle())
    .read<int>('n');

void main() {
  test('replaying the log into an empty database rebuilds it', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final seed = BigBudget(db);
    await seed.build(months: 3);
    // Writes the way screens make them (not through an engine).
    await (db.update(db.accounts)..where((a) => a.id.equals('cash')))
        .write(const AccountsCompanion(name: Value('Pocket money')));
    await (db.update(db.categories)..where((c) => c.id.equals('pets')))
        .write(const CategoriesCompanion(archived: Value(true)));
    // A purge (Health check): hard deletes.
    final gone = (await (db.select(db.transactions)
              ..where((t) => t.deleted.equals(true))
              ..limit(5))
            .get())
        .map((t) => t.id)
        .toList();
    await (db.delete(db.transactionLines)
          ..where((l) => l.transactionId.isIn(gone)))
        .go();
    await (db.delete(db.transactions)..where((t) => t.id.isIn(gone))).go();
    await changeBaseCurrency(db, BigBudget.hh, 'USD', 'EUR', 1 / 1.08);

    final ops = await loadOps(db);
    expect(ops.map((o) => o.kind).toSet(), {'insert', 'update', 'delete'});

    final copy = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(copy.close);
    await replayOps(copy, ops);
    final want = await dump(db);
    final got = await dump(copy);
    for (final t in opLogTables) {
      expect(got[t], want[t], reason: t);
    }
    // Replaying isn't logged as new changes.
    expect(await opCount(copy), 0);
  });

  test('rows from before the log get one starting entry each', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    // Data written with logging off, then the log emptied: an upgraded app.
    await db.customStatement('UPDATE sync_clock SET applying = 1');
    await BigBudget(db).build(months: 1);
    await db.customStatement('UPDATE sync_clock SET applying = 0');
    await db.customStatement('DELETE FROM sync_ops');
    await ensureOpLog(db);
    final baseline = await loadOps(db);
    expect(baseline, isNotEmpty);
    expect(baseline.every((o) => o.hlc.startsWith(baselineHlc)), isTrue);
    final rows = await dump(db);
    expect(baseline.length, rows.values.fold<int>(0, (n, l) => n + l.length));

    // A change after it sorts later and wins.
    await (db.update(db.accounts)..where((a) => a.id.equals('eur')))
        .write(const AccountsCompanion(name: Value('Euros')));
    final copy = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(copy.close);
    await replayOps(copy, await loadOps(db));
    expect(await dump(copy), await dump(db));
  });

  test('an edit logs only what changed, with the old value', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db.into(db.households).insert(HouseholdsCompanion.insert(
        id: 'h', name: 'Home', createdByDeviceId: 'd'));
    await db.into(db.accounts).insert(AccountsCompanion.insert(
        id: 'a', householdId: 'h', name: 'Bank', type: 'bank',
        currency: 'USD', deviceId: 'd'));
    await (db.update(db.accounts)..where((a) => a.id.equals('a'))).write(
        AccountsCompanion(
            name: const Value('Main bank'),
            lastModified: Value(DateTime(2026, 10, 27))));
    // Writing the same values again is not a change.
    await (db.update(db.accounts)..where((a) => a.id.equals('a'))).write(
        AccountsCompanion(
            name: const Value('Main bank'),
            lastModified: Value(DateTime(2026, 10, 27))));

    final ops = await loadOps(db);
    expect(ops.map((o) => '${o.table}:${o.kind}'),
        ['households:insert', 'accounts:insert', 'accounts:update']);
    final edit = ops.last;
    expect(edit.rowId, 'a');
    expect(edit.data!.keys.toSet(), {'name', 'last_modified'});
    expect(edit.data!['name'], 'Main bank');
    expect(edit.old!['name'], 'Bank');
    // Stamps only go forward.
    expect(ops[1].hlc.compareTo(ops[0].hlc), greaterThan(0));
    expect(ops[2].hlc.compareTo(ops[1].hlc), greaterThan(0));
    expect(ops.map((o) => o.seq), [1, 2, 3]);
  });
}
