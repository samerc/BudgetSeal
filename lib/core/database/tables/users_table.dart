import 'package:drift/drift.dart';

import 'households_table.dart';

class Users extends Table {
  TextColumn get id => text()();
  TextColumn get householdId =>
      text().references(Households, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  // 'admin' or 'member'
  TextColumn get role => text().withDefault(const Constant('member'))();
  TextColumn get permissionsJson => text().withDefault(const Constant('{}'))();
  TextColumn get deviceId => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastModified => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
