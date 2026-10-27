import 'package:drift/drift.dart';

/// Brings transactions written by older versions — on this phone before
/// v23, restored from an old backup, or synced from a phone still on 0.11
/// or earlier — to the current model (see the `Transactions` table):
///
/// - A posted transfer gets [destinationAmount]: `amount ×
///   exchangeRateToBase`, the source→destination rate older versions keep
///   there.
/// - A posted income/expense with no line gets one, `<id>:acct`, holding
///   the header's amount on the header account in its currency; the header
///   then holds the base-currency total like every other transaction
///   (0 without a rate, as `recordTransaction` does).
///
/// Idempotent, and deterministic — every device makes the same line id and
/// values — so two phones converting the same row agree after syncing. The
/// updates move `last_modified` (sync trigger), so the converted rows sync
/// out; phones on 0.11 read them the same as before (they use the line
/// once there is one, and ignore the new column).
///
/// Runs on every open, and after a sync merge or restore.
Future<void> normalizeTransactions(DatabaseConnectionUser db) async {
  await db.customStatement('''
    UPDATE transactions
       SET destination_amount = amount * exchange_rate_to_base
     WHERE type = 'transfer' AND status IS NULL
       AND destination_amount IS NULL''');

  await db.customStatement('''
    INSERT OR IGNORE INTO transaction_lines
      (id, transaction_id, category_id, account_id, amount, currency,
       exchange_rate_to_base, note)
    SELECT t.id || ':acct', t.id, t.category_id, t.account_id, t.amount,
           t.currency, t.exchange_rate_to_base, ''
      FROM transactions t
     WHERE t.type IN ('income', 'expense') AND t.status IS NULL
       AND NOT EXISTS (SELECT 1 FROM transaction_lines l
                        WHERE l.transaction_id = t.id)''');

  await db.customStatement('''
    UPDATE transactions
       SET amount = CASE
             WHEN currency = (SELECT base_currency FROM households h
                               WHERE h.id = transactions.household_id)
               THEN amount
             WHEN ABS(exchange_rate_to_base - 1.0) < 0.001 THEN 0
             ELSE amount * exchange_rate_to_base END,
           currency = (SELECT base_currency FROM households h
                        WHERE h.id = transactions.household_id),
           exchange_rate_to_base = 1.0
     WHERE EXISTS (SELECT 1 FROM transaction_lines l
                    WHERE l.id = transactions.id || ':acct')
       AND (exchange_rate_to_base <> 1.0
            OR currency <> (SELECT base_currency FROM households h
                             WHERE h.id = transactions.household_id))''');
}
