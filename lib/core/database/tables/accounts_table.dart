import 'package:drift/drift.dart';

import 'households_table.dart';

// Account types
enum AccountType { cash, bank, credit, wallet }

class Accounts extends Table {
  TextColumn get id => text()();
  TextColumn get householdId =>
      text().references(Households, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  // 'cash' | 'bank' | 'credit' | 'wallet'
  TextColumn get type => text()();
  TextColumn get currency => text()();
  // Stored as minor units (e.g. cents) multiplied by 1e6 for precision,
  // but we keep as Real for simplicity at this stage.
  RealColumn get initialBalance => real().withDefault(const Constant(0.0))();
  /// Number of decimal places for display (e.g. 2 for USD, 0 for JPY, 3 for KWD).
  /// Null means auto-detect (default 2).
  IntColumn get decimalPlaces => integer().nullable()();
  /// Travel wallet flag — temporary currency pocket for trips.
  /// Auto-archives when balance hits zero, shown with travel badge.
  BoolColumn get isTravel => boolean().withDefault(const Constant(false))();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  TextColumn get deviceId => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastModified => dateTime().withDefault(currentDateAndTime)();

  /// Soft-delete flag — set true instead of removing the row so deletions
  /// propagate across synced devices. List/aggregate queries filter this.
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
