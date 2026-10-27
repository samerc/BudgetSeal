import 'package:drift/drift.dart';

import 'accounts_table.dart';
import 'categories_table.dart';
import 'households_table.dart';

class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get householdId =>
      text().references(Households, #id, onDelete: KeyAction.cascade)();
  // 'income' | 'expense' | 'transfer'
  TextColumn get type => text()();
  @ReferenceName('sourceTransactions')
  TextColumn get accountId =>
      text().references(Accounts, #id, onDelete: KeyAction.restrict)();
  // Null unless type == 'transfer'
  @ReferenceName('destinationTransactions')
  TextColumn get destinationAccountId =>
      text().nullable().references(Accounts, #id, onDelete: KeyAction.restrict)();
  // Null for transfers; 1:1 with an allocation
  TextColumn get categoryId =>
      text().nullable().references(Categories, #id, onDelete: KeyAction.setNull)();
  /// Income/expense: the total in the household's base currency (each
  /// line holds its own amount in its account's currency). Transfer: the
  /// amount sent, in the source account's currency.
  RealColumn get amount => real()();
  TextColumn get currency => text()();
  /// Income/expense: 1.0 (each line has its own rate). Transfer: the
  /// source→destination rate — only still written so phones on 0.11 and
  /// earlier read transfers right; use [destinationAmount].
  RealColumn get exchangeRateToBase => real().withDefault(const Constant(1.0))();
  /// Transfer: the amount the destination account received, in its
  /// currency. Null on other types (and on transfers written before v23 or
  /// by an older phone until `normalizeTransactions()` fills it).
  RealColumn get destinationAmount => real().nullable()();
  TextColumn get note => text().withDefault(const Constant(''))();
  /// File path to a receipt photo, if attached.
  TextColumn get receiptPath => text().nullable()();
  TextColumn get createdBy => text()();
  TextColumn get deviceId => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastModified => dateTime().withDefault(currentDateAndTime)();
  /// Transaction status: null = posted (normal), 'upcoming' = pending bill,
  /// 'skipped' = user skipped this occurrence.
  TextColumn get status => text().nullable()();
  /// Soft-delete flag. Deleted transactions are excluded from all balance
  /// calculations and queries but retained for sync conflict resolution.
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
  /// Set by an edit that rewrote the lines (v24): that edit's lines and
  /// envelope debits have ids starting `<id>:<revision>:`. When two phones
  /// rewrite the same transaction, sync keeps the newer revision's lines
  /// and debits whole (`settleTransactions()` in log_sync.dart).
  TextColumn get revision => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
