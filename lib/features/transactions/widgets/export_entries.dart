import 'dart:io';

import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/transactions_provider.dart';
import '../../../shared/utils/note_text.dart';

/// Share [entries] (e.g. the Activity tab's selection) as a CSV — one row
/// per line, in the line's own currency and account. The temp file is
/// deleted afterwards.
Future<void> shareEntriesCsv(
    List<TransactionEntry> entries, Map<String, Category> categoryMap) async {
  final rows = <List<String>>[
    [
      'Date',
      'Time',
      'Type',
      'Title/Note',
      'Amount',
      'Currency',
      'Account',
      'Category',
      'Destination Account',
    ],
  ];
  for (final e in entries) {
    final tx = e.tx;
    final local = tx.createdAt.toLocal();
    final date = DateFormat('yyyy-MM-dd').format(local);
    final time = DateFormat('HH:mm').format(local);
    final note = visibleNote(tx.note);
    if (tx.type == 'transfer' || e.lines.isEmpty) {
      rows.add([
        date,
        time,
        tx.type,
        note,
        tx.amount.toString(),
        e.lines.isNotEmpty ? e.lines.first.currency : tx.currency,
        e.accountName,
        categoryMap[tx.categoryId]?.name ?? '',
        e.destinationAccountName ?? '',
      ]);
      continue;
    }
    for (final l in e.lines) {
      rows.add([
        date,
        time,
        tx.type,
        l.note.isNotEmpty ? '$note — ${l.note}' : note,
        l.amount.toString(),
        l.currency,
        e.lineAccountNames[l.accountId] ?? e.accountName,
        categoryMap[l.categoryId]?.name ?? '',
        '',
      ]);
    }
  }

  final dir = await getTemporaryDirectory();
  final stamp = DateFormat('yyyy-MM-dd_HHmm').format(DateTime.now());
  final file = File('${dir.path}/budgetseal_transactions_$stamp.csv');
  try {
    await file.writeAsString(const CsvEncoder().convert(rows));
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: 'BudgetSeal transactions'),
    );
  } finally {
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}
