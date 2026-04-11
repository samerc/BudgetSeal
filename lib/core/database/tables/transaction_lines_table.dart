import 'package:drift/drift.dart';

import 'accounts_table.dart';
import 'categories_table.dart';
import 'transactions_table.dart';

/// Each row represents one line of a (possibly split) transaction.
/// A simple transaction has exactly one line.
/// A split transaction has multiple lines, each with its own amount,
/// currency, optional category, and source account.
class TransactionLines extends Table {
  TextColumn get id => text()();
  TextColumn get transactionId =>
      text().references(Transactions, #id, onDelete: KeyAction.cascade)();
  TextColumn get categoryId => text()
      .nullable()
      .references(Categories, #id, onDelete: KeyAction.setNull)();
  /// The account this line draws money from (multi-account support).
  TextColumn get accountId => text()
      .nullable()
      .references(Accounts, #id, onDelete: KeyAction.restrict)();
  RealColumn get amount => real()();
  TextColumn get currency => text()();
  /// Rate from this line's currency to household base currency at time of entry.
  RealColumn get exchangeRateToBase =>
      real().withDefault(const Constant(1.0))();
  TextColumn get note => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};
}
