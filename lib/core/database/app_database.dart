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
          if (from < 2) {
            await m.createTable(transactionLines);
          }
          if (from < 3) {
            await m.addColumn(categories, categories.parentId);
            await m.addColumn(categories, categories.transactionType);
          }
          if (from < 4) {
            await m.addColumn(
                transactionLines, transactionLines.accountId);
            await m.addColumn(
                transactionLines, transactionLines.exchangeRateToBase);
          }
          if (from < 5) {
            await m.addColumn(
                categories, categories.defaultAccountId);
          }
          if (from < 6) {
            await m.addColumn(categories, categories.allocationId);
            await customStatement('''
              UPDATE categories SET allocation_id = (
                SELECT id FROM allocations
                WHERE allocations.category_id = categories.id
                LIMIT 1
              )
            ''');
          }
          if (from < 7) {
            await m.createTable(recurringTransactions);
            await m.addColumn(transactions, transactions.receiptPath);
          }
          if (from < 8) {
            await m.createTable(transactionTemplates);
          }
          if (from < 9) {
            await m.addColumn(
                recurringTransactions, recurringTransactions.endDate);
          }
          if (from < 10) {
            await m.addColumn(
                recurringTransactions, recurringTransactions.isSubscription);
            await m.addColumn(
                recurringTransactions, recurringTransactions.priceHistory);
          }
          if (from < 11) {
            await m.addColumn(allocations, allocations.icon);
          }
          if (from < 12) {
            await m.addColumn(transactions, transactions.deleted);
          }
          if (from < 13) {
            await m.addColumn(allocations, allocations.autoReset);
          }
          if (from < 14) {
            await m.addColumn(accounts, accounts.decimalPlaces);
            await m.addColumn(transactions, transactions.status);
            await m.createTable(objectives);
          }
          if (from < 15) {
            await m.addColumn(accounts, accounts.isTravel);
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
            await _addColumnIfMissing(m, accounts, 'deleted', accounts.deleted);
            await _addColumnIfMissing(
                m, categories, 'deleted', categories.deleted);
            await _addColumnIfMissing(
                m, allocations, 'deleted', allocations.deleted);
            await _addColumnIfMissing(
                m, objectives, 'deleted', objectives.deleted);
            await _addColumnIfMissing(m, recurringTransactions, 'last_modified',
                recurringTransactions.lastModified);
            await _addColumnIfMissing(m, recurringTransactions, 'deleted',
                recurringTransactions.deleted);
            await _addColumnIfMissing(m, transactionTemplates, 'last_modified',
                transactionTemplates.lastModified);
            await _addColumnIfMissing(m, transactionTemplates, 'deleted',
                transactionTemplates.deleted);
          }
        },
      );

  /// Adds [column] to [table] only if the underlying SQLite table does not
  /// already have a column named [columnName]. Prevents "duplicate column
  /// name" crashes when a migration is retried or the column pre-exists.
  Future<void> _addColumnIfMissing(
    Migrator m,
    TableInfo table,
    String columnName,
    GeneratedColumn column,
  ) async {
    final info =
        await customSelect('PRAGMA table_info(${table.actualTableName})').get();
    final exists = info.any((row) => row.data['name'] == columnName);
    if (!exists) {
      await m.addColumn(table, column);
    }
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'budgetseal.db'));
    return NativeDatabase.createInBackground(file);
  });
}
