import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'daos/accounts_dao.dart';
import 'daos/allocations_dao.dart';
import 'daos/ledger_dao.dart';
import 'daos/transactions_dao.dart';
import 'tables/accounts_table.dart';
import 'tables/allocation_ledger_table.dart';
import 'tables/allocations_table.dart';
import 'tables/categories_table.dart';
import 'tables/fx_rates_table.dart';
import 'tables/households_table.dart';
import 'tables/objectives_table.dart';
import 'tables/recurring_transactions_table.dart';
import 'tables/transaction_lines_table.dart';
import 'tables/transaction_templates_table.dart';
import 'tables/transactions_table.dart';
import 'tables/users_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Households,
    Users,
    Accounts,
    Transactions,
    TransactionLines,
    Categories,
    Allocations,
    AllocationLedger,
    FxRates,
    RecurringTransactions,
    TransactionTemplates,
    Objectives,
  ],
  daos: [
    AccountsDao,
    TransactionsDao,
    AllocationsDao,
    LedgerDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 18;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // NOTE: every addColumn/createTable below goes through the
          // *IfMissing helpers. SQLite raises "duplicate column name" /
          // "table already exists" if a migration re-runs a step whose result
          // already exists — which happens whenever the on-disk schema is ahead
          // of the recorded user_version (a partially-applied upgrade, or a
          // build whose table classes gained columns before schemaVersion was
          // bumped). Guarding each step makes the whole migration idempotent.
          if (from < 2) {
            await _createTableIfMissing(m, transactionLines);
          }
          if (from < 3) {
            await _addColumnIfMissing(m, categories, categories.parentId);
            await _addColumnIfMissing(m, categories, categories.transactionType);
          }
          if (from < 4) {
            await _addColumnIfMissing(
                m, transactionLines, transactionLines.accountId);
            await _addColumnIfMissing(
                m, transactionLines, transactionLines.exchangeRateToBase);
          }
          if (from < 5) {
            await _addColumnIfMissing(
                m, categories, categories.defaultAccountId);
          }
          if (from < 6) {
            await _addColumnIfMissing(m, categories, categories.allocationId);
            await customStatement('''
              UPDATE categories SET allocation_id = (
                SELECT id FROM allocations
                WHERE allocations.category_id = categories.id
                LIMIT 1
              )
              WHERE allocation_id IS NULL
            ''');
          }
          if (from < 7) {
            await _createTableIfMissing(m, recurringTransactions);
            await _addColumnIfMissing(
                m, transactions, transactions.receiptPath);
          }
          if (from < 8) {
            await _createTableIfMissing(m, transactionTemplates);
          }
          if (from < 9) {
            await _addColumnIfMissing(
                m, recurringTransactions, recurringTransactions.endDate);
          }
          if (from < 10) {
            await _addColumnIfMissing(
                m, recurringTransactions, recurringTransactions.isSubscription);
            await _addColumnIfMissing(
                m, recurringTransactions, recurringTransactions.priceHistory);
          }
          if (from < 11) {
            await _addColumnIfMissing(m, allocations, allocations.icon);
          }
          if (from < 12) {
            await _addColumnIfMissing(m, transactions, transactions.deleted);
          }
          if (from < 13) {
            await _addColumnIfMissing(m, allocations, allocations.autoReset);
          }
          if (from < 14) {
            await _addColumnIfMissing(m, accounts, accounts.decimalPlaces);
            await _addColumnIfMissing(m, transactions, transactions.status);
            await _createTableIfMissing(m, objectives);
          }
          if (from < 15) {
            await _addColumnIfMissing(m, accounts, accounts.isTravel);
          }
          if (from < 16) {
            // Performance indexes for hot query paths
            await m.createIndex(Index('idx_transactions_household_date',
                'CREATE INDEX IF NOT EXISTS idx_transactions_household_date '
                'ON transactions (household_id, created_at)'));
            await m.createIndex(Index('idx_transactions_household_deleted',
                'CREATE INDEX IF NOT EXISTS idx_transactions_household_deleted '
                'ON transactions (household_id, deleted)'));
            await m.createIndex(Index('idx_transaction_lines_tx',
                'CREATE INDEX IF NOT EXISTS idx_transaction_lines_tx '
                'ON transaction_lines (transaction_id)'));
            await m.createIndex(Index('idx_ledger_allocation',
                'CREATE INDEX IF NOT EXISTS idx_ledger_allocation '
                'ON allocation_ledger (allocation_id)'));
            await m.createIndex(Index('idx_allocations_household',
                'CREATE INDEX IF NOT EXISTS idx_allocations_household '
                'ON allocations (household_id)'));
            await m.createIndex(Index('idx_categories_household',
                'CREATE INDEX IF NOT EXISTS idx_categories_household '
                'ON categories (household_id)'));
          }
          if (from < 17) {
            await m.createIndex(Index('idx_ledger_source_tx',
                'CREATE INDEX IF NOT EXISTS idx_ledger_source_tx '
                'ON allocation_ledger (source_transaction_id)'));
            await m.createIndex(Index('idx_categories_allocation',
                'CREATE INDEX IF NOT EXISTS idx_categories_allocation '
                'ON categories (allocation_id)'));
          }
          if (from < 18) {
            // Soft-delete flags so deletions propagate across synced devices,
            // plus lastModified on recurring/templates so their edits sync.
            // Idempotent: some databases already have these columns (e.g. a
            // partially-applied v18 upgrade, or a fresh install created from
            // table classes that already declared them). Re-running ALTER TABLE
            // ADD COLUMN on an existing column throws "duplicate column name"
            // and wedges every launch, so add each only if it's missing.
            await _addColumnIfMissing(m, accounts, accounts.deleted);
            await _addColumnIfMissing(m, categories, categories.deleted);
            await _addColumnIfMissing(m, allocations, allocations.deleted);
            await _addColumnIfMissing(m, objectives, objectives.deleted);
            // lastModified defaults to currentDateAndTime, a NON-CONSTANT
            // expression. SQLite rejects `ALTER TABLE ADD COLUMN` with a
            // non-constant default, so add it with a constant default and
            // backfill from created_at instead of using m.addColumn.
            await _addTimestampColumnIfMissing(
                'recurring_transactions', 'last_modified');
            await _addColumnIfMissing(
                m, recurringTransactions, recurringTransactions.deleted);
            await _addTimestampColumnIfMissing(
                'transaction_templates', 'last_modified');
            await _addColumnIfMissing(
                m, transactionTemplates, transactionTemplates.deleted);
          }
        },
      );

  /// Adds [column] to [table] only if the SQLite table does not already have
  /// it. Prevents "duplicate column name" when a migration re-runs or the
  /// column already exists (schema ahead of the recorded user_version).
  Future<void> _addColumnIfMissing(
    Migrator m,
    TableInfo table,
    GeneratedColumn column,
  ) async {
    final info =
        await customSelect('PRAGMA table_info(${table.actualTableName})').get();
    final exists = info.any((row) => row.data['name'] == column.name);
    if (!exists) {
      await m.addColumn(table, column);
    }
  }

  /// Creates [table] only if it does not already exist. Prevents "table already
  /// exists" when a migration re-runs against a schema that is ahead of the
  /// recorded user_version.
  Future<void> _createTableIfMissing(Migrator m, TableInfo table) async {
    final rows = await customSelect(
      "SELECT 1 FROM sqlite_master WHERE type='table' AND name='"
      "${table.actualTableName}'",
    ).get();
    if (rows.isEmpty) {
      await m.createTable(table);
    }
  }

  /// Adds a NOT NULL DateTime (INTEGER seconds) column if missing, working
  /// around SQLite's ban on non-constant defaults in ALTER TABLE ADD COLUMN:
  /// the column is added with a constant `0` default and then backfilled from
  /// `created_at` so existing rows carry a sensible sync timestamp. Idempotent.
  Future<void> _addTimestampColumnIfMissing(
    String tableName,
    String columnName,
  ) async {
    final info =
        await customSelect('PRAGMA table_info($tableName)').get();
    if (info.any((row) => row.data['name'] == columnName)) return;
    await customStatement(
        'ALTER TABLE $tableName ADD COLUMN $columnName INTEGER NOT NULL DEFAULT 0');
    await customStatement(
        'UPDATE $tableName SET $columnName = created_at WHERE $columnName = 0');
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'budgetseal.db'));
    return NativeDatabase.createInBackground(file);
  });
}
