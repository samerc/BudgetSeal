import 'package:drift/drift.dart';

import 'households_table.dart';

/// A kid asking for money (roadmap #5): [amount] in [currency] into their
/// envelope [allocationId]. A grown-up approves (funds the envelope from
/// Ready to assign) or declines.
class MoneyRequests extends Table {
  TextColumn get id => text()();
  TextColumn get householdId =>
      text().references(Households, #id, onDelete: KeyAction.cascade)();
  /// The asker's device.
  TextColumn get fromDeviceId => text()();
  TextColumn get allocationId => text()();
  RealColumn get amount => real()();
  TextColumn get currency => text()();
  TextColumn get note => text().withDefault(const Constant(''))();
  /// 'open' | 'approved' | 'declined'
  TextColumn get status => text().withDefault(const Constant('open'))();
  /// The grown-up's device that decided.
  TextColumn get decidedBy => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastModified =>
      dateTime().withDefault(currentDateAndTime)();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// A grown-up confirmed the review of a budget period (roadmap #5); the
/// period is sealed for the family once every grown-up has. Id:
/// `<periodStart yyyy-MM-dd>:<device>`.
class MonthReviews extends Table {
  TextColumn get id => text()();
  TextColumn get householdId =>
      text().references(Households, #id, onDelete: KeyAction.cascade)();
  /// Start of the reviewed period, yyyy-MM-dd.
  TextColumn get period => text()();
  TextColumn get deviceId => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastModified =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
