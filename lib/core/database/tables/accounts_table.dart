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
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  TextColumn get deviceId => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastModified => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
