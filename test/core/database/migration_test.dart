import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:budgetseal/core/database/app_database.dart';
import 'package:budgetseal/core/engine/balance_calculator.dart';

/// An old database had none of today's triggers, and SQLite won't drop a
/// column a trigger names: remove them before rewinding a schema.
Future<void> dropTriggers(AppDatabase db) async {
  final names = await db
      .customSelect("SELECT name FROM sqlite_master WHERE type = 'trigger'")
      .get();
  for (final r in names) {
    await db.customStatement('DROP TRIGGER IF EXISTS ${r.read<String>('name')}');
  }
}

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
      await dropTriggers(db);
      await db.customStatement('PRAGMA user_version = 17');
      await db.close();

      // 2. Reopening runs the 17->18 migration against a DB that already has
      //    the columns. It must NOT throw and must finish at v18.
      db = AppDatabase.forTesting(NativeDatabase(file));
      await db.select(db.accounts).get(); // forces open + migration
      final row = await db.customSelect('PRAGMA user_version').getSingle();
      expect(row.data['user_version'], 27);
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
      await dropTriggers(db);
      // A real v17 database has no sync triggers (they're created on open,
      // after migrating), and they'd block dropping last_modified below.
      for (final t in AppDatabase.syncedTables) {
        await db.customStatement('DROP TRIGGER IF EXISTS bump_last_modified_$t');
      }
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
        'ALTER TABLE recurring_transactions DROP COLUMN anchor_day',
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
      expect(row.data['user_version'], 27);
      await db.close();
    } finally {
      dir.deleteSync(recursive: true);
    }
  });

  test('v19 migration adds recurring anchor_day to a v18 database', () async {
    final dir = Directory.systemTemp.createTempSync('bs_mig_test4');
    final file = File(p.join(dir.path, 'v18.db'));
    try {
      var db = AppDatabase.forTesting(NativeDatabase(file));
      await dropTriggers(db);
      await db.customStatement(
          'ALTER TABLE recurring_transactions DROP COLUMN anchor_day');
      await db.customStatement('PRAGMA user_version = 18');
      await db.close();

      db = AppDatabase.forTesting(NativeDatabase(file));
      await db.select(db.recurringTransactions).get(); // forces migration
      final cols = await db
          .customSelect('PRAGMA table_info(recurring_transactions)')
          .get();
      expect(cols.any((c) => c.data['name'] == 'anchor_day'), isTrue);
      final row = await db.customSelect('PRAGMA user_version').getSingle();
      expect(row.data['user_version'], 27);
      await db.close();
    } finally {
      dir.deleteSync(recursive: true);
    }
  });

  test('v20 migration adds allocations sort_order to a v19 database',
      () async {
    final dir = Directory.systemTemp.createTempSync('bs_mig_test5');
    final file = File(p.join(dir.path, 'v19.db'));
    try {
      var db = AppDatabase.forTesting(NativeDatabase(file));
      await dropTriggers(db);
      await db.customStatement('ALTER TABLE allocations DROP COLUMN sort_order');
      await db.customStatement('PRAGMA user_version = 19');
      await db.close();

      db = AppDatabase.forTesting(NativeDatabase(file));
      await db.select(db.allocations).get(); // forces migration
      final cols =
          await db.customSelect('PRAGMA table_info(allocations)').get();
      expect(cols.any((c) => c.data['name'] == 'sort_order'), isTrue);
      final row = await db.customSelect('PRAGMA user_version').getSingle();
      expect(row.data['user_version'], 27);
      await db.close();
    } finally {
      dir.deleteSync(recursive: true);
    }
  });

  test('v21 migration adds allocations behind_mode to a v20 database',
      () async {
    final dir = Directory.systemTemp.createTempSync('bs_mig_test6');
    final file = File(p.join(dir.path, 'v20.db'));
    try {
      var db = AppDatabase.forTesting(NativeDatabase(file));
      await dropTriggers(db);
      await db.customStatement('ALTER TABLE allocations DROP COLUMN behind_mode');
      await db.customStatement('PRAGMA user_version = 20');
      await db.close();

      db = AppDatabase.forTesting(NativeDatabase(file));
      await db.select(db.allocations).get(); // forces migration
      final cols =
          await db.customSelect('PRAGMA table_info(allocations)').get();
      expect(cols.any((c) => c.data['name'] == 'behind_mode'), isTrue);
      final row = await db.customSelect('PRAGMA user_version').getSingle();
      expect(row.data['user_version'], 27);
      await db.close();
    } finally {
      dir.deleteSync(recursive: true);
    }
  });

  test('v22 migration adds bill ask_first and remind_days to a v21 database',
      () async {
    final dir = Directory.systemTemp.createTempSync('bs_mig_test7');
    final file = File(p.join(dir.path, 'v21.db'));
    try {
      var db = AppDatabase.forTesting(NativeDatabase(file));
      await dropTriggers(db);
      await db.customStatement(
          'ALTER TABLE recurring_transactions DROP COLUMN ask_first');
      await db.customStatement(
          'ALTER TABLE recurring_transactions DROP COLUMN remind_days');
      await db.customStatement('PRAGMA user_version = 21');
      await db.close();

      db = AppDatabase.forTesting(NativeDatabase(file));
      await db.select(db.recurringTransactions).get(); // forces migration
      final cols = await db
          .customSelect('PRAGMA table_info(recurring_transactions)')
          .get();
      expect(cols.any((c) => c.data['name'] == 'ask_first'), isTrue);
      expect(cols.any((c) => c.data['name'] == 'remind_days'), isTrue);
      final row = await db.customSelect('PRAGMA user_version').getSingle();
      expect(row.data['user_version'], 27);
      await db.close();
    } finally {
      dir.deleteSync(recursive: true);
    }
  });

  // v27: capture_rules.
  test('v27 migration creates the rules table', () async {
    final dir = Directory.systemTemp.createTempSync('bs_mig_test12');
    final file = File(p.join(dir.path, 'v26.db'));
    try {
      var db = AppDatabase.forTesting(NativeDatabase(file));
      await dropTriggers(db);
      await db.customStatement('DROP TABLE capture_rules');
      await db.customStatement('PRAGMA user_version = 26');
      await db.close();

      db = AppDatabase.forTesting(NativeDatabase(file));
      expect(await db.select(db.captureRules).get(), isEmpty);
      await db.close();
    } finally {
      dir.deleteSync(recursive: true);
    }
  });

  // v26: allocations' second target.
  test('v26 migration adds the second target columns', () async {
    final dir = Directory.systemTemp.createTempSync('bs_mig_test11');
    final file = File(p.join(dir.path, 'v25.db'));
    try {
      var db = AppDatabase.forTesting(NativeDatabase(file));
      await dropTriggers(db);
      for (final c in ['second_target_amount', 'second_target_currency']) {
        await db.customStatement('ALTER TABLE allocations DROP COLUMN $c');
      }
      await db.customStatement('PRAGMA user_version = 25');
      await db.close();

      db = AppDatabase.forTesting(NativeDatabase(file));
      expect(await db.select(db.allocations).get(), isEmpty);
      final cols = await db.customSelect('PRAGMA table_info(allocations)').get();
      expect(cols.map((c) => c.data['name']),
          containsAll(['second_target_amount', 'second_target_currency']));
      await db.close();
    } finally {
      dir.deleteSync(recursive: true);
    }
  });

  // v25: households.base_history (base change on a shared budget).
  test('v25 migration adds the base history column', () async {
    final dir = Directory.systemTemp.createTempSync('bs_mig_test10');
    final file = File(p.join(dir.path, 'v24.db'));
    try {
      var db = AppDatabase.forTesting(NativeDatabase(file));
      await dropTriggers(db);
      await db.customStatement('ALTER TABLE households DROP COLUMN base_history');
      await db.customStatement('PRAGMA user_version = 24');
      await db.close();

      db = AppDatabase.forTesting(NativeDatabase(file));
      expect(await db.select(db.households).get(), isEmpty);
      final cols = await db.customSelect('PRAGMA table_info(households)').get();
      expect(cols.map((c) => c.data['name']), contains('base_history'));
      await db.close();
    } finally {
      dir.deleteSync(recursive: true);
    }
  });

  // v24: transactions.revision (in-place edits, op-log sync step 3).
  test('v24 migration adds the revision column', () async {
    final dir = Directory.systemTemp.createTempSync('bs_mig_test9');
    final file = File(p.join(dir.path, 'v23.db'));
    try {
      var db = AppDatabase.forTesting(NativeDatabase(file));
      await dropTriggers(db);
      await db.customStatement('ALTER TABLE transactions DROP COLUMN revision');
      await db.customStatement('PRAGMA user_version = 23');
      await db.close();

      db = AppDatabase.forTesting(NativeDatabase(file));
      expect(await db.select(db.transactions).get(), isEmpty);
      final cols = await db.customSelect('PRAGMA table_info(transactions)').get();
      expect(cols.map((c) => c.data['name']), contains('revision'));
      final row = await db.customSelect('PRAGMA user_version').getSingle();
      expect(row.data['user_version'], 27);
      await db.close();
    } finally {
      dir.deleteSync(recursive: true);
    }
  });

  // v23: transfers store what arrived; an income/expense always has a line.
  // A v22 database (or a phone on 0.11) has transfers with only the
  // source→destination rate and header-only incomes in the account's
  // currency. Opening converts them; no balance moves.
  test('v23 migration converts old transfers and header-only rows', () async {
    final dir = Directory.systemTemp.createTempSync('bs_mig_test8');
    final file = File(p.join(dir.path, 'v22.db'));
    try {
      var db = AppDatabase.forTesting(NativeDatabase(file));
      await dropTriggers(db);
      await db.customStatement(
          'ALTER TABLE transactions DROP COLUMN destination_amount');
      for (final s in const [
        "INSERT INTO households (id, name, base_currency, created_by_device_id) "
            "VALUES ('h', 'Home', 'USD', 'd')",
        "INSERT INTO accounts (id, household_id, name, type, currency, device_id) "
            "VALUES ('usd', 'h', 'Bank', 'bank', 'USD', 'd')",
        "INSERT INTO accounts (id, household_id, name, type, currency, device_id) "
            "VALUES ('lbp', 'h', 'Cash', 'cash', 'LBP', 'd')",
        // 100 USD sent, 8,950,000 LBP received (rate stored on the header).
        "INSERT INTO transactions (id, household_id, type, account_id, "
            "destination_account_id, amount, currency, exchange_rate_to_base, "
            "created_by, device_id) VALUES ('t1', 'h', 'transfer', 'usd', "
            "'lbp', 100, 'USD', 89500, 'u', 'd')",
        // A balance adjustment from 0.11: 450,000 LBP, header only.
        "INSERT INTO transactions (id, household_id, type, account_id, amount, "
            "currency, exchange_rate_to_base, created_by, device_id) VALUES "
            "('t2', 'h', 'income', 'lbp', 450000, 'LBP', 0.0000111731843575, "
            "'u', 'd')",
      ]) {
        await db.customStatement(s);
      }
      await db.customStatement('PRAGMA user_version = 22');
      await db.close();

      db = AppDatabase.forTesting(NativeDatabase(file));
      final t1 = await (db.select(db.transactions)
            ..where((t) => t.id.equals('t1')))
          .getSingle();
      expect(t1.destinationAmount, 8950000);
      final t2 = await (db.select(db.transactions)
            ..where((t) => t.id.equals('t2')))
          .getSingle();
      expect(t2.currency, 'USD');
      expect(t2.amount, closeTo(5.03, 0.01));
      final lines = await (db.select(db.transactionLines)
            ..where((l) => l.transactionId.equals('t2')))
          .get();
      expect(lines.single.id, 't2:acct');
      expect(lines.single.amount, 450000);
      expect(lines.single.currency, 'LBP');
      expect(lines.single.accountId, 'lbp');
      final balances = await BalanceCalculator(db).allAccountBalances('h');
      expect(balances['usd'], -100);
      expect(balances['lbp'], 8950000 + 450000);
      final row = await db.customSelect('PRAGMA user_version').getSingle();
      expect(row.data['user_version'], 27);
      await db.close();

      // Opening again changes nothing.
      db = AppDatabase.forTesting(NativeDatabase(file));
      expect(
          (await db.select(db.transactionLines).get()).length, lines.length);
      expect((await BalanceCalculator(db).allAccountBalances('h'))['lbp'],
          8950000 + 450000);
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
      await dropTriggers(db);
      await db.customStatement('PRAGMA user_version = 1');
      await db.close();

      db = AppDatabase.forTesting(NativeDatabase(file));
      await db.select(db.transactionLines).get(); // forces the full 1->18 run
      final row = await db.customSelect('PRAGMA user_version').getSingle();
      expect(row.data['user_version'], 27);
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

    test('schema version is 27', () {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      expect(db.schemaVersion, 27);
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
