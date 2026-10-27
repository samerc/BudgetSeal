import 'package:drift/drift.dart';

import 'households_table.dart';

/// Rules for captured payments (roadmap #2): when a shared message, a bank
/// alert or a receipt's shop contains [match], fill in the category, the
/// account and/or the title. Made by the user (Settings › Rules) or learned
/// when a captured payment is saved with a category ([learned]).
class CaptureRules extends Table {
  TextColumn get id => text()();
  TextColumn get householdId =>
      text().references(Households, #id, onDelete: KeyAction.cascade)();
  /// Matched case-insensitively anywhere in the text.
  TextColumn get match => text()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get accountId => text().nullable()();
  /// The title to use instead of the shop as written ("SPINNEYS ACHRAF…"
  /// → "Spinneys").
  TextColumn get title => text().nullable()();
  BoolColumn get learned => boolean().withDefault(const Constant(false))();
  IntColumn get uses => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastModified =>
      dateTime().withDefault(currentDateAndTime)();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
