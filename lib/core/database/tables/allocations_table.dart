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
  // Purpose: 'spending' | 'saving' | 'flexible' | 'sinking' (a fund saved
  // monthly for scheduled payments; permanent, no target of its own)
  TextColumn get type => text().withDefault(const Constant('spending'))();
  // Behaviour: 'periodic' (resets) | 'permanent' (accumulates)
  TextColumn get periodicity => text().withDefault(const Constant('periodic'))();
  // Whether a periodic allocation carries its balance forward instead of resolving
  BoolColumn get rollover => boolean().withDefault(const Constant(false))();
  // Optional savings target amount
  RealColumn get targetAmount => real().nullable()();
  TextColumn get targetCurrency => text().nullable()();
  /// Optional second target in another currency (v26, roadmap #3: e.g.
  /// Groceries $100 + LBP 2,000,000). Funded, spent and shown on its own —
  /// never added to the first.
  RealColumn get secondTargetAmount => real().nullable()();
  TextColumn get secondTargetCurrency => text().nullable()();
  /// Family (v28, roadmap #5): whose envelope it is (a member's device id;
  /// a kid's envelopes are theirs), and whether it's private — then the
  /// other members' phones hide it, and its transactions show as "Private".
  /// The data still syncs to them.
  TextColumn get ownerDeviceId => text().nullable()();
  BoolColumn get isPrivate => boolean().withDefault(const Constant(false))();
  /// Emoji icon for this envelope (e.g. '⛽', '🛒'). Null = use linked category icon.
  TextColumn get icon => text().nullable()();
  /// Whether this periodic envelope resets automatically at period start.
  /// If false, user must manually handle it in Period Transition.
  BoolColumn get autoReset => boolean().withDefault(const Constant(true))();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  /// Manual position on the Budget tab (drag to reorder). Null = after the
  /// ordered ones, by name.
  IntColumn get sortOrder => integer().nullable()();
  /// Sinking fund that fell behind: 'spread' (raise the monthly amount),
  /// 'topup' (catch up now), null = ask each time.
  TextColumn get behindMode => text().nullable()();
  TextColumn get deviceId => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastModified => dateTime().withDefault(currentDateAndTime)();

  /// Soft-delete flag — set true instead of removing the row so deletions
  /// propagate across synced devices. List/aggregate queries filter this.
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
