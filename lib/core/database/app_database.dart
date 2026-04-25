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
  int get schemaVersion => 12;

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
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'pocketplan.db'));
    return NativeDatabase.createInBackground(file);
  });
}
