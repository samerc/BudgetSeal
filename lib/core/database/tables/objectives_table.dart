import 'package:drift/drift.dart';

import 'households_table.dart';

/// Objectives: standalone savings goals and loan tracking.
/// Goals accumulate toward a target. Loans track money owed/lent.
class Objectives extends Table {
  TextColumn get id => text()();
  TextColumn get householdId =>
      text().references(Households, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  /// 'goal' or 'loan'
  TextColumn get type => text()();
  /// Optional emoji icon
  TextColumn get icon => text().nullable()();
  /// Target amount to reach (goal) or total owed (loan)
  RealColumn get targetAmount => real().withDefault(const Constant(0.0))();
  TextColumn get targetCurrency => text()();
  /// Current saved/paid amount — updated via ledger entries
  RealColumn get currentAmount => real().withDefault(const Constant(0.0))();
  /// Optional deadline
  DateTimeColumn get endDate => dateTime().nullable()();
  /// For loans: name of the person (who owes you or you owe)
  TextColumn get contactName => text().nullable()();
  /// For loans: 'lent' (they owe you) or 'borrowed' (you owe them)
  TextColumn get direction => text().nullable()();
  /// Color hex for display
  TextColumn get colorHex => text().withDefault(const Constant('#2563EB'))();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  TextColumn get deviceId => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastModified => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
