import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/daos/ledger_dao.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/utils/format_number.dart';

/// What the "Saved" message says about the envelope a new expense spent
/// from: its balance (in the spent currency) right after the save.
class EnvelopeFeedback {
  final String allocationId;
  final String name;
  final String currency;
  final double balance;
  const EnvelopeFeedback(
      this.allocationId, this.name, this.currency, this.balance);

  bool get overspent => balance < -0.005;

  String message(S s) => overspent
      ? s.txSavedEnvelopeOver(
          name, formatAmount(-balance, currency: currency))
      : s.txSavedEnvelopeLeft(
          name, formatAmount(balance, currency: currency));
}

/// The envelope transaction [txId] debited (the engine's consumption row,
/// so subcategories resolve to their parent's envelope), or null.
Future<EnvelopeFeedback?> envelopeAfterSave(
    AppDatabase db, String txId) async {
  final row = await (db.select(db.allocationLedger)
        ..where((l) =>
            l.sourceTransactionId.equals(txId) &
            l.entryType.equals('consumption'))
        ..limit(1))
      .getSingleOrNull();
  if (row == null) return null;
  final alloc = await (db.select(db.allocations)
        ..where((a) => a.id.equals(row.allocationId)))
      .getSingleOrNull();
  if (alloc == null) return null;
  final balances = await LedgerDao(db).getBalanceByCurrency(alloc.id);
  return EnvelopeFeedback(
      alloc.id, alloc.name, row.currency, balances[row.currency] ?? 0);
}
