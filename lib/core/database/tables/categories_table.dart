import 'package:drift/drift.dart';

import 'accounts_table.dart';
import 'allocations_table.dart';
import 'households_table.dart';

class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get householdId =>
      text().references(Households, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  TextColumn get parentId => text().nullable()();
  TextColumn get transactionType =>
      text().withDefault(const Constant('expense'))();
  /// The envelope this category is linked to. Expenses with this category
  /// debit this envelope. Multiple categories can share one envelope.
  @ReferenceName('categoryAllocations')
  TextColumn get allocationId => text()
      .nullable()
      .references(Allocations, #id, onDelete: KeyAction.setNull)();
  /// Default account for this category.
  TextColumn get defaultAccountId => text()
      .nullable()
      .references(Accounts, #id, onDelete: KeyAction.setNull)();
  TextColumn get icon => text().withDefault(const Constant('category'))();
  TextColumn get colorHex => text().withDefault(const Constant('#607D8B'))();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastModified => dateTime().withDefault(currentDateAndTime)();

  /// Soft-delete flag — set true instead of removing the row so deletions
  /// propagate across synced devices. List/aggregate queries filter this.
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
