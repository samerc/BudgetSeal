import 'package:drift/drift.dart';

class FxRates extends Table {
  TextColumn get id => text()();
  TextColumn get fromCurrency => text()();
  TextColumn get toCurrency => text()();
  RealColumn get rate => real()();
  DateTimeColumn get fetchedAt => dateTime().withDefault(currentDateAndTime)();
  // 'api' | 'manual'
  TextColumn get source => text().withDefault(const Constant('api'))();

  @override
  Set<Column> get primaryKey => {id};
}
