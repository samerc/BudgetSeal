import 'package:drift/drift.dart';

import 'accounts_table.dart';
import 'categories_table.dart';
import 'households_table.dart';

/// Saved transaction templates for quick re-use.
class TransactionTemplates extends Table {
  TextColumn get id => text()();
  TextColumn get householdId =>
      text().references(Households, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text()();
  TextColumn get type => text()(); // 'income' | 'expense'
  RealColumn get amount => real()();
  TextColumn get currency => text()();
  @ReferenceName('templateAccount')
  TextColumn get accountId => text()
      .nullable()
      .references(Accounts, #id, onDelete: KeyAction.setNull)();
  TextColumn get categoryId => text()
      .nullable()
      .references(Categories, #id, onDelete: KeyAction.setNull)();
  IntColumn get useCount =>
      integer().withDefault(const Constant(0))();
  DateTimeColumn get lastUsedAt => dateTime().nullable()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  /// Bumped on every edit so changes propagate across synced devices
  /// (merge keys on this).
  DateTimeColumn get lastModified => dateTime().withDefault(currentDateAndTime)();

  /// Soft-delete flag — set true instead of removing the row so deletions sync.
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
