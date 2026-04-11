import 'package:drift/drift.dart';

import 'accounts_table.dart';
import 'allocations_table.dart';
import 'transactions_table.dart';

/// Append-only ledger. Records are NEVER updated after insertion.
/// All allocation balances are computed dynamically by summing entries here.
class AllocationLedger extends Table {
  TextColumn get id => text()();
  TextColumn get allocationId =>
      text().references(Allocations, #id, onDelete: KeyAction.cascade)();
  // The originating transaction (null for manual adjustments / period ops)
  TextColumn get sourceTransactionId =>
      text().nullable().references(Transactions, #id, onDelete: KeyAction.setNull)();
  // Accounts involved (explicit for transfers and cross-account ops)
  @ReferenceName('sourceLedgerEntries')
  TextColumn get sourceAccountId =>
      text().nullable().references(Accounts, #id, onDelete: KeyAction.setNull)();
  @ReferenceName('destLedgerEntries')
  TextColumn get destAccountId =>
      text().nullable().references(Accounts, #id, onDelete: KeyAction.setNull)();
  // 'funding' | 'consumption' | 'adjustment' | 'period_reset' | 'carry_forward'
  TextColumn get entryType => text()();
  // Positive = credit to allocation; Negative = debit from allocation
  RealColumn get amount => real()();
  TextColumn get currency => text()();
  RealColumn get exchangeRateToBase => real().withDefault(const Constant(1.0))();
  TextColumn get note => text().withDefault(const Constant(''))();
  // Immutable after insert
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get deviceId => text()();

  @override
  Set<Column> get primaryKey => {id};
}
