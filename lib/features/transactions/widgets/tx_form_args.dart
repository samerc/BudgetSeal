import '../../../core/database/app_database.dart';
import '../../../core/providers/transactions_provider.dart';

/// Route `extra` for `/add-transaction` that pre-fills the form from an
/// existing transaction: every line (amount, currency, rate, account,
/// category, note) and, for transfers, both accounts.
///
/// [edit] re-saves the same transaction (keeps its id and date); otherwise
/// it's a duplicate dated now.
Map<String, dynamic> txFormArgs(
  TransactionEntry entry,
  List<Category> categories, {
  required bool edit,
}) {
  final tx = entry.tx;
  final catMap = {for (final c in categories) c.id: c};
  final lines = entry.lines.map((l) {
    return <String, dynamic>{
      'amount': l.amount,
      'currency': l.currency,
      'exchangeRateToBase': l.exchangeRateToBase,
      'accountId': l.accountId ?? tx.accountId,
      'categoryId': l.categoryId,
      'categoryName': catMap[l.categoryId]?.name,
      'note': l.note,
    };
  }).toList();
  if (lines.isEmpty) {
    lines.add({
      'amount': tx.amount,
      'currency': tx.currency,
      'exchangeRateToBase': tx.exchangeRateToBase,
      'accountId': tx.accountId,
      'categoryId': tx.categoryId,
      'categoryName': catMap[tx.categoryId]?.name,
      'note': '',
    });
  }
  return {
    if (edit) 'editTransactionId': tx.id,
    if (edit) 'editDate': tx.createdAt,
    'editType': tx.type,
    'editNote': tx.note,
    'editLines': lines,
    if (tx.type == 'transfer') ...{
      'editFromAccountId': tx.accountId,
      'editDestAccountId': tx.destinationAccountId,
    },
  };
}
