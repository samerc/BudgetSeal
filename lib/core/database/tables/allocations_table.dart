import 'package:drift/drift.dart';

import 'households_table.dart';

class Allocations extends Table {
  TextColumn get id => text()();
  TextColumn get householdId =>
      text().references(Households, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  // Legacy 1:1 link. New model: categories reference allocations via
  // categories.allocationId (many categories → one envelope).
  TextColumn get categoryId => text()();
  // Purpose: 'spending' | 'saving' | 'flexible'
  TextColumn get type => text().withDefault(const Constant('spending'))();
  // Behaviour: 'periodic' (resets) | 'permanent' (accumulates)
  TextColumn get periodicity => text().withDefault(const Constant('periodic'))();
  // Whether a periodic allocation carries its balance forward instead of resolving
  BoolColumn get rollover => boolean().withDefault(const Constant(false))();
  // Optional savings target amount
  RealColumn get targetAmount => real().nullable()();
  TextColumn get targetCurrency => text().nullable()();
  /// Emoji icon for this envelope (e.g. '⛽', '🛒'). Null = use linked category icon.
  TextColumn get icon => text().nullable()();
  /// Whether this periodic envelope resets automatically at period start.
  /// If false, user must manually handle it in Period Transition.
  BoolColumn get autoReset => boolean().withDefault(const Constant(true))();
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
