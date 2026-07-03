import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:budgetseal/core/database/app_database.dart';

void main() {
  // Regression: a database that already has the v18 soft-delete columns but is
  // still marked as v17 (a partially-applied upgrade, or a fresh install created
  // from table classes that already declared the columns) used to crash every
  // launch with "duplicate column name: deleted". The v18 migration must add
  // each column only if missing.
  test('v18 migration recovers a stuck DB that already has the columns',
      () async {
    final dir = Directory.systemTemp.createTempSync('bs_mig_test');
    final file = File(p.join(dir.path, 'stuck.db'));
    try {
      // 1. Create a full current-schema DB (all v18 columns present), then
      //    rewind its recorded version to 17 — the exact "stuck" state.
      var db = AppDatabase.forTesting(NativeDatabase(file));
      await db.customStatement('PRAGMA user_version = 17');
      await db.close();

      // 2. Reopening runs the 17->18 migration against a DB that already has
      //    the columns. It must NOT throw and must finish at v18.
      db = AppDatabase.forTesting(NativeDatabase(file));
      await db.select(db.accounts).get(); // forces open + migration
      final row = await db.customSelect('PRAGMA user_version').getSingle();
      expect(row.data['user_version'], 18);
      await db.close();
    } finally {
      dir.deleteSync(recursive: true);
    }
  });

  // Regression: a genuine v17 DB is MISSING the new columns. Adding
  // last_modified (whose default is the non-constant currentDateAndTime) used
  // to crash with "cannot add a column with non-constant default". The
  // migration must add it with a constant default and backfill from created_at.
  test('v18 migration adds missing columns without a non-constant default',
      () async {
    final dir = Directory.systemTemp.createTempSync('bs_mig_test2');
    final file = File(p.join(dir.path, 'v17.db'));
    try {
      var db = AppDatabase.forTesting(NativeDatabase(file));
      // Strip the v18 columns to mimic a real v17 database, then rewind version.
      for (final stmt in const [
        'ALTER TABLE accounts DROP COLUMN deleted',
        'ALTER TABLE categories DROP COLUMN deleted',
        'ALTER TABLE allocations DROP COLUMN deleted',
        'ALTER TABLE objectives DROP COLUMN deleted',
        'ALTER TABLE recurring_transactions DROP COLUMN last_modified',
        'ALTER TABLE recurring_transactions DROP COLUMN deleted',
        'ALTER TABLE transaction_templates DROP COLUMN last_modified',
        'ALTER TABLE transaction_templates DROP COLUMN deleted',
      ]) {
        await db.customStatement(stmt);
      }
      await db.customStatement('PRAGMA user_version = 17');
      await db.close();

      // Reopen → 17->18 migration adds every column, including last_modified.
      db = AppDatabase.forTesting(NativeDatabase(file));
      await db.select(db.recurringTransactions).get(); // forces migration
      await db.select(db.transactionTemplates).get();
      final row = await db.customSelect('PRAGMA user_version').getSingle();
      expect(row.data['user_version'], 18);
      await db.close();
    } finally {
      dir.deleteSync(recursive: true);
    }
  });

  // Regression: rewinding a full current-schema DB all the way to v1 forces
  // EVERY migration step (createTable + addColumn across all versions) to run
  // against objects that already exist. With the *IfMissing guards this must be
  // a no-op that lands on v18 rather than throwing "table already exists" or
  // "duplicate column name".
  test('full migration from v1 is idempotent on an up-to-date schema',
      () async {
    final dir = Directory.systemTemp.createTempSync('bs_mig_test3');
    final file = File(p.join(dir.path, 'v1.db'));
    try {
      var db = AppDatabase.forTesting(NativeDatabase(file));
      await db.customStatement('PRAGMA user_version = 1');
      await db.close();

      db = AppDatabase.forTesting(NativeDatabase(file));
      await db.select(db.transactionLines).get(); // forces the full 1->18 run
      final row = await db.customSelect('PRAGMA user_version').getSingle();
      expect(row.data['user_version'], 18);
      await db.close();
    } finally {
      dir.deleteSync(recursive: true);
    }
  });

  group('Database migration', () {
    late AppDatabase db;

    tearDown(() async {
      await db.close();
    });

    test('creates all tables from scratch at current schema version', () async {
      db = AppDatabase.forTesting(NativeDatabase.memory());

      // Verify all expected tables exist by running simple queries.
      // Each select will throw if the table doesn't exist.
      await db.select(db.households).get();
      await db.select(db.users).get();
      await db.select(db.accounts).get();
      await db.select(db.transactions).get();
      await db.select(db.transactionLines).get();
      await db.select(db.categories).get();
      await db.select(db.allocations).get();
      await db.select(db.allocationLedger).get();
      await db.select(db.fxRates).get();
      await db.select(db.recurringTransactions).get();
      await db.select(db.transactionTemplates).get();
    });

    test('schema version is 18', () {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      expect(db.schemaVersion, 18);
    });

    test('tables return empty results on fresh database', () async {
      db = AppDatabase.forTesting(NativeDatabase.memory());

      final households = await db.select(db.households).get();
      expect(households, isEmpty);

      final accounts = await db.select(db.accounts).get();
      expect(accounts, isEmpty);

      final categories = await db.select(db.categories).get();
      expect(categories, isEmpty);

      final txns = await db.select(db.transactions).get();
      expect(txns, isEmpty);

      final allocations = await db.select(db.allocations).get();
      expect(allocations, isEmpty);
    });

    test('categories table has expected columns from migrations', () async {
      db = AppDatabase.forTesting(NativeDatabase.memory());

      // These columns were added in migrations 3, 5, and 6.
      // Inserting a row that uses them proves they exist.
      await db.into(db.categories).insert(CategoriesCompanion.insert(
        id: 'test-cat-1',
        householdId: 'hh-1',
        name: 'Test Category',
        icon: const Value('📦'),
        colorHex: const Value('#FF0000'),
        // migration 3 columns
        parentId: const Value('parent-1'),
        transactionType: const Value('expense'),
        // migration 5 column
        defaultAccountId: const Value('acct-1'),
        // migration 6 column
        allocationId: const Value('alloc-1'),
      ));

      final cats = await db.select(db.categories).get();
      expect(cats, hasLength(1));
      expect(cats.first.parentId, 'parent-1');
      expect(cats.first.transactionType, 'expense');
      expect(cats.first.defaultAccountId, 'acct-1');
      expect(cats.first.allocationId, 'alloc-1');
    });

    test('recurring_transactions table has endDate column from migration 9',
        () async {
      db = AppDatabase.forTesting(NativeDatabase.memory());

      // Just verify the table is queryable (endDate column exists).
      final results = await db.select(db.recurringTransactions).get();
      expect(results, isEmpty);
    });
  });
}
