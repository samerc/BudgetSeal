import 'package:drift/drift.dart';

import '../../shared/utils/format_number.dart' show parseLooseAmount;
import '../../shared/utils/ocr_service.dart';
import '../database/app_database.dart';

/// One row read from a screenshot of the bank's transaction list.
class StatementRow {
  final String name;
  final double amount; // positive
  final bool income;
  const StatementRow(this.name, this.amount, {this.income = false});
}

/// A recorded movement on the account: what it did to the account
/// (positive), in or out.
class BookedItem {
  final String id;
  final String title;
  final double amount;
  final bool income;
  final DateTime date;
  const BookedItem(this.id, this.title, this.amount,
      {this.income = false, required this.date});
}

class StatementMatch {
  final List<(StatementRow, BookedItem)> matched;
  final List<StatementRow> missing;
  const StatementMatch(this.matched, this.missing);
}

/// An amount at the end of a bank list line, with its sign and maybe a
/// currency: "-18.00", "+ $2,500.00", "82,40 EUR", "−1 350 000 LBP".
final _rowAmount = RegExp(
    r'([+\-−–])?\s*(?:[A-Z]{3}|[$€£])?\s*'
    r'(\d{1,3}(?:[ ,.]\d{3})*(?:[.,]\d{1,2})?)\s*(?:[A-Z]{3}|[$€£])?\s*$');

/// Lines that aren't payments.
final _notPayment = RegExp(
    r'\b(balance|available|total|solde|disponible)\b|رصيد|المتاح|المجموع',
    caseSensitive: false);

/// The rows of a bank list screenshot, read from each line's text (the
/// receipt reader's classes are made for receipts — "WATER DELIVERY -18.00"
/// isn't an item there): a name, then an amount at the end. A "-" is money
/// out, a "+" money in; no sign reads as money out (most bank apps show
/// spending unsigned or in red). Balances and totals are left out.
List<StatementRow> statementRows(OcrResult ocr) {
  final rows = <StatementRow>[];
  for (final l in ocr.lines) {
    final text = l.text.trim();
    final m = _rowAmount.firstMatch(text);
    if (m == null || _notPayment.hasMatch(text)) continue;
    final name = text.substring(0, m.start).trim();
    if (!RegExp(r'[^\W\d_]', unicode: true).hasMatch(name)) continue;
    final amount =
        parseLooseAmount(m.group(2)!.replaceAll(' ', ''));
    if (amount == null || amount == 0) continue;
    rows.add(StatementRow(name, amount.abs(), income: m.group(1) == '+'));
  }
  return rows;
}

Set<String> _words(String s) => {
      for (final w in s.toLowerCase().split(RegExp(r'[^\p{L}\p{N}]+', unicode: true)))
        if (w.length >= 3) w,
    };

/// Each row matched to a recorded movement with the same amount and
/// direction (one each): the one whose title shares the most words, then
/// the most recent. Rows left over are missing from BudgetSeal.
StatementMatch matchStatement(List<StatementRow> rows, List<BookedItem> booked) {
  final free = [...booked]..sort((a, b) => b.date.compareTo(a.date));
  final matched = <(StatementRow, BookedItem)>[];
  final missing = <StatementRow>[];
  for (final row in rows) {
    final words = _words(row.name);
    BookedItem? best;
    var bestScore = -1;
    for (final b in free) {
      if (b.income != row.income || (b.amount - row.amount).abs() >= 0.005) {
        continue;
      }
      final score = _words(b.title).intersection(words).length;
      if (score > bestScore) {
        best = b;
        bestScore = score;
      }
    }
    if (best == null) {
      missing.add(row);
    } else {
      free.remove(best);
      matched.add((row, best));
    }
  }
  return StatementMatch(matched, missing);
}

/// What was recorded on [accountId] since [since]: each posted income or
/// expense's lines on it, and transfers out (sent) and in (received).
Future<List<BookedItem>> bookedOnAccount(
    AppDatabase db, String accountId, DateTime since) async {
  final rows = await db.customSelect(
    'SELECT t.id, t.note, t.type, t.created_at AS at, '
    'SUM(l.amount) AS amount, 0 AS incoming '
    'FROM transactions t JOIN transaction_lines l ON l.transaction_id = t.id '
    "WHERE t.deleted = 0 AND t.status IS NULL AND t.type <> 'transfer' "
    'AND l.account_id = ? AND t.created_at >= ? GROUP BY t.id '
    'UNION ALL '
    'SELECT t.id, t.note, t.type, t.created_at, t.amount, 0 '
    'FROM transactions t '
    "WHERE t.deleted = 0 AND t.status IS NULL AND t.type = 'transfer' "
    'AND t.account_id = ? AND t.created_at >= ? '
    'UNION ALL '
    'SELECT t.id, t.note, t.type, t.created_at, '
    'COALESCE(t.destination_amount, t.amount * t.exchange_rate_to_base), 1 '
    'FROM transactions t '
    "WHERE t.deleted = 0 AND t.status IS NULL AND t.type = 'transfer' "
    'AND t.destination_account_id = ? AND t.created_at >= ?',
    variables: [
      for (var i = 0; i < 3; i++) ...[
        Variable.withString(accountId),
        Variable<DateTime>(since),
      ],
    ],
  ).get();
  return [
    for (final r in rows)
      BookedItem(
        r.read<String>('id'),
        r.read<String>('note'),
        r.read<double>('amount').abs(),
        income: r.read<String>('type') == 'income' ||
            (r.read<String>('type') == 'transfer' &&
                r.read<int>('incoming') == 1),
        date: DateTime.fromMillisecondsSinceEpoch(r.read<int>('at') * 1000),
      ),
  ];
}
