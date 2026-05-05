import 'dart:io';

import 'package:csv/csv.dart';
import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/providers/database_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../shared/theme/app_colors.dart';

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  bool _exporting = false;

  Future<void> _exportTransactions() async {
    setState(() => _exporting = true);
    try {
      final db = ref.read(databaseProvider);
      final householdId = ref.read(currentHouseholdIdProvider);
      if (householdId == null) return;

      // Fetch all transactions with lines.
      final txs = await (db.select(db.transactions)
            ..where((t) => t.householdId.equals(householdId))
            ..where((t) => t.deleted.equals(false))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

      final allLines = await db.select(db.transactionLines).get();
      final linesByTx = <String, List<dynamic>>{};
      for (final l in allLines) {
        linesByTx.putIfAbsent(l.transactionId, () => []).add(l);
      }

      // Fetch accounts and categories for names.
      final accounts = await db.select(db.accounts).get();
      final accountMap = {for (final a in accounts) a.id: a.name};
      final categories = await db.select(db.categories).get();
      final catMap = {for (final c in categories) c.id: c.name};

      // Build CSV rows.
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
          'Destination Account'
        ],
      ];

      for (final tx in txs) {
        final date = DateFormat('yyyy-MM-dd').format(tx.createdAt.toLocal());
        final time = DateFormat('HH:mm').format(tx.createdAt.toLocal());
        final account = accountMap[tx.accountId] ?? '';
        final destAccount = tx.destinationAccountId != null
            ? accountMap[tx.destinationAccountId] ?? ''
            : '';
        final category =
            tx.categoryId != null ? catMap[tx.categoryId] ?? '' : '';

        rows.add([
          date,
          time,
          tx.type,
          tx.note,
          tx.amount.toString(),
          tx.currency,
          account,
          category,
          destAccount,
        ]);
      }

      final csv = const CsvEncoder().convert(rows);
      final dir = await getTemporaryDirectory();
      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final file = File('${dir.path}/pocketplan_export_$dateStr.csv');
      await file.writeAsString(csv);

      if (mounted) {
        await SharePlus.instance.share(
          ShareParams(files: [XFile(file.path)], text: 'Pocket Plan export'),
        );
      }

      // Clean up temp file
      try {
        if (await file.exists()) await file.delete();
      } catch (_) {}
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(title: const Text('Export Data')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.sf(context),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.file_download_outlined,
                          size: 24, color: AppColors.accent),
                      SizedBox(width: 12),
                      Text('Export Transactions',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Export all your transactions as a CSV file. '
                    'You can open it in Excel, Google Sheets, or any spreadsheet app.',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.ts(context)),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _exporting ? null : _exportTransactions,
                    icon: _exporting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.share_rounded, size: 18),
                    label: Text(
                        _exporting ? 'Exporting...' : 'Export & Share'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
