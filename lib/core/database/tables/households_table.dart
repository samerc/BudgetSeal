import 'package:drift/drift.dart';

class Households extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get baseCurrency => text().withDefault(const Constant('USD'))();
  IntColumn get periodStartDay => integer().withDefault(const Constant(1))();
  BoolColumn get autoPromptPeriod => boolean().withDefault(const Constant(true))();
  BoolColumn get allowSkipPeriod => boolean().withDefault(const Constant(true))();
  TextColumn get createdByDeviceId => text()();
  TextColumn get settingsJson => text().withDefault(const Constant('{}'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastModified => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
