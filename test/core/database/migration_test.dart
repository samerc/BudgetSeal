import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketplan/core/database/app_database.dart';

void main() {
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

    test('schema version is 9', () {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      expect(db.schemaVersion, 9);
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
