import 'package:drift/drift.dart';

import 'accounts_table.dart';
import 'categories_table.dart';
import 'households_table.dart';

/// Template for a recurring transaction.
/// The engine checks on app start and generates actual transactions
/// for any that are due.
class RecurringTransactions extends Table {
  TextColumn get id => text()();
  TextColumn get householdId =>
      text().references(Households, #id, onDelete: KeyAction.cascade)();
  TextColumn get type => text()(); // 'income' | 'expense' | 'transfer'
  TextColumn get title => text().withDefault(const Constant(''))();
  RealColumn get amount => real()();
  TextColumn get currency => text()();
  @ReferenceName('recurringSourceAccount')
  TextColumn get accountId =>
      text().references(Accounts, #id, onDelete: KeyAction.restrict)();
  @ReferenceName('recurringDestAccount')
  TextColumn get destinationAccountId => text()
      .nullable()
      .references(Accounts, #id, onDelete: KeyAction.restrict)();
  TextColumn get categoryId => text()
      .nullable()
      .references(Categories, #id, onDelete: KeyAction.setNull)();
  TextColumn get note => text().withDefault(const Constant(''))();

  /// Frequency: 'daily' | 'weekly' | 'monthly' | 'yearly'
  TextColumn get frequency => text()();
  /// The interval multiplier (e.g. every 2 weeks → frequency='weekly', interval=2)
  IntColumn get interval => integer().withDefault(const Constant(1))();
  /// Next date this recurring transaction is due.
  DateTimeColumn get nextDueDate => dateTime()();
  /// Last date a transaction was generated from this template.
  DateTimeColumn get lastGeneratedDate => dateTime().nullable()();
  /// End date: stop generating after this date. Null = forever.
  DateTimeColumn get endDate => dateTime().nullable()();
  /// Whether auto-generation is active.
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();

  /// Whether this recurring transaction is a subscription (Netflix, Spotify, etc.)
  BoolColumn get isSubscription => boolean().withDefault(const Constant(false))();

  /// JSON-encoded price history for subscriptions.
  /// Format: [{"amount": 15.0, "from": "2025-01-01"}, {"amount": 18.0, "from": "2026-06-01"}]
  /// When generating transactions, the engine uses the price active on the due date.
  TextColumn get priceHistory => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
