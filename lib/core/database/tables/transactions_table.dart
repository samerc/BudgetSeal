import 'package:drift/drift.dart';

import 'accounts_table.dart';
import 'categories_table.dart';
import 'households_table.dart';

class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get householdId =>
      text().references(Households, #id, onDelete: KeyAction.cascade)();
  // 'income' | 'expense' | 'transfer'
  TextColumn get type => text()();
  @ReferenceName('sourceTransactions')
  TextColumn get accountId =>
      text().references(Accounts, #id, onDelete: KeyAction.restrict)();
  // Null unless type == 'transfer'
  @ReferenceName('destinationTransactions')
  TextColumn get destinationAccountId =>
      text().nullable().references(Accounts, #id, onDelete: KeyAction.restrict)();
  // Null for transfers; 1:1 with an allocation
  TextColumn get categoryId =>
      text().nullable().references(Categories, #id, onDelete: KeyAction.setNull)();
  RealColumn get amount => real()();
  TextColumn get currency => text()();
  // Rate from this transaction's currency to household base currency at time of entry
  RealColumn get exchangeRateToBase => real().withDefault(const Constant(1.0))();
  TextColumn get note => text().withDefault(const Constant(''))();
  /// File path to a receipt photo, if attached.
  TextColumn get receiptPath => text().nullable()();
  TextColumn get createdBy => text()();
  TextColumn get deviceId => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastModified => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
