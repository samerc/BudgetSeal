import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/database/app_database.dart';
import '../../core/providers/categories_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../core/providers/transactions_provider.dart';
import '../../core/providers/date_format_provider.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/design_tokens.dart';
import '../../shared/utils/format_number.dart';

/// Generates and shares an HTML monthly report that can be printed as PDF.
class ExportReportScreen extends ConsumerStatefulWidget {
  const ExportReportScreen({super.key});

  @override
  ConsumerState<ExportReportScreen> createState() =>
      _ExportReportScreenState();
}

class _ExportReportScreenState extends ConsumerState<ExportReportScreen> {
  int _selectedMonthsBack = 0;
  bool _exporting = false;

  DateTime get _month {
    final now = DateTime.now();
    return DateTime(now.year, now.month - _selectedMonthsBack, 1);
  }

  DateTime get _monthEnd =>
      DateTime(_month.year, _month.month + 1, 0, 23, 59, 59);

  @override
  Widget build(BuildContext context) {
    final monthLabel = DateFormat('MMMM yyyy').format(_month);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Report'),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
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
                border: Border.all(color: AppColors.bd(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.picture_as_pdf_rounded,
                        size: 24, color: AppColors.accent),
                    const SizedBox(width: 12),
                    Text('Monthly Report',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.tp(context))),
                  ]),
                  const SizedBox(height: 12),
                  Text(
                    'Generate a printable HTML report for a selected month. '
                    'Open it in a browser and use Print > Save as PDF.',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.ts(context)),
                  ),
                  const SizedBox(height: 20),
                  // Month selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded),
                        onPressed: () =>
                            setState(() => _selectedMonthsBack++),
                      ),
                      Text(monthLabel,
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.tp(context))),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded),
                        onPressed: _selectedMonthsBack > 0
                            ? () =>
                                setState(() => _selectedMonthsBack--)
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _exporting ? null : _export,
                    icon: _exporting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.share_rounded, size: 18),
                    label: Text(
                        _exporting ? 'Generating...' : 'Generate & Share'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(CardTokens.radius)),
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

  Future<void> _export() async {
    setState(() => _exporting = true);
    try {
      final entries =
          ref.read(transactionEntriesProvider).value ?? [];
      final categories =
          ref.read(categoriesProvider).value ?? [];
      final categoryMap = {for (final c in categories) c.id: c};
      final household = ref.read(householdProvider).value;
      final baseCurrency = household?.baseCurrency ?? 'USD';
      final householdName = household?.name ?? 'PocketPlan';

      final filtered = entries
          .where((e) =>
              e.tx.createdAt.isAfter(_month) &&
              e.tx.createdAt.isBefore(_monthEnd))
          .toList();

      double totalIncome = 0;
      double totalExpense = 0;
      final catSpend = <String, double>{};

      for (final e in filtered) {
        double baseAmt = 0;
        if (e.lines.isNotEmpty) {
          for (final l in e.lines) {
            baseAmt += l.amount * l.exchangeRateToBase;
          }
        } else {
          baseAmt = e.tx.amount * e.tx.exchangeRateToBase;
        }
        if (e.tx.type == 'income') totalIncome += baseAmt;
        if (e.tx.type == 'expense') {
          totalExpense += baseAmt;
          final catId = e.tx.categoryId;
          final name = catId != null
              ? (categoryMap[catId]?.name ?? 'Uncategorized')
              : 'Uncategorized';
          catSpend[name] = (catSpend[name] ?? 0) + baseAmt;
        }
      }

      final sortedCats = catSpend.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final monthLabel = DateFormat('MMMM yyyy').format(_month);
      final net = totalIncome - totalExpense;

      final html = _buildHtml(
        householdName: householdName,
        monthLabel: monthLabel,
        baseCurrency: baseCurrency,
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        net: net,
        categoryBreakdown: sortedCats,
        transactions: filtered,
        categoryMap: categoryMap,
      );

      final tempDir = await getTemporaryDirectory();
      final fileName =
          'pocketplan_report_${DateFormat('yyyy_MM').format(_month)}.html';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(html);

      if (mounted) {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            text: 'PocketPlan Report - $monthLabel',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
      // Clean up temp file after sharing
      try {
        final tempDir = await getTemporaryDirectory();
        final fileName =
            'pocketplan_report_${DateFormat('yyyy_MM').format(_month)}.html';
        final file = File('${tempDir.path}/$fileName');
        if (file.existsSync()) await file.delete();
      } catch (_) {}
    }
  }

  String _buildHtml({
    required String householdName,
    required String monthLabel,
    required String baseCurrency,
    required double totalIncome,
    required double totalExpense,
    required double net,
    required List<MapEntry<String, double>> categoryBreakdown,
    required List<TransactionEntry> transactions,
    required Map<String, dynamic> categoryMap,
  }) {
    final txRows = transactions.map((e) {
      final tx = e.tx;
      final cat = tx.categoryId != null ? categoryMap[tx.categoryId] : null;
      final catName = cat != null ? (cat as Category).name : '';
      final color = tx.type == 'income' ? '#10B981' : tx.type == 'expense' ? '#EF4444' : '#6366F1';
      return '''
        <tr>
          <td>${formatDate(tx.createdAt.toLocal())}</td>
          <td>${tx.note.isNotEmpty ? _escHtml(tx.note) : catName}</td>
          <td>$catName</td>
          <td>${_capitalize(tx.type)}</td>
          <td style="color:$color;font-weight:600;text-align:right">${formatSignedAmount(tx.amount, currency: baseCurrency, type: tx.type)}</td>
        </tr>''';
    }).join('\n');

    final catRows = categoryBreakdown.map((e) {
      final pct = totalExpense > 0
          ? (e.value / totalExpense * 100).toStringAsFixed(1)
          : '0';
      return '''
        <tr>
          <td>${_escHtml(e.key)}</td>
          <td style="text-align:right">${formatAmount(e.value, currency: baseCurrency)}</td>
          <td style="text-align:right">$pct%</td>
        </tr>''';
    }).join('\n');

    return '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>$householdName - $monthLabel Report</title>
<style>
  body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; color: #1a1a2e; }
  h1 { font-size: 24px; margin-bottom: 4px; }
  h2 { font-size: 18px; margin-top: 32px; border-bottom: 2px solid #e2e8f0; padding-bottom: 8px; }
  .subtitle { color: #64748b; font-size: 14px; }
  .summary { display: flex; gap: 24px; margin: 20px 0; }
  .summary-card { flex: 1; padding: 16px; border-radius: 12px; background: #f8fafc; border: 1px solid #e2e8f0; }
  .summary-card .label { font-size: 12px; color: #64748b; text-transform: uppercase; }
  .summary-card .value { font-size: 22px; font-weight: 700; margin-top: 4px; }
  .income { color: #10B981; }
  .expense { color: #EF4444; }
  .net { color: ${net >= 0 ? '#10B981' : '#EF4444'}; }
  table { width: 100%; border-collapse: collapse; font-size: 13px; }
  th { text-align: left; padding: 8px 12px; background: #f1f5f9; font-weight: 600; font-size: 11px; text-transform: uppercase; color: #64748b; }
  td { padding: 8px 12px; border-bottom: 1px solid #e2e8f0; }
  .footer { margin-top: 40px; text-align: center; font-size: 11px; color: #94a3b8; }
</style>
</head>
<body>
<h1>$householdName</h1>
<p class="subtitle">Monthly Report &mdash; $monthLabel</p>

<div class="summary">
  <div class="summary-card">
    <div class="label">Income</div>
    <div class="value income">${formatSignedAmount(totalIncome, currency: baseCurrency, type: 'income')}</div>
  </div>
  <div class="summary-card">
    <div class="label">Expenses</div>
    <div class="value expense">${formatSignedAmount(totalExpense, currency: baseCurrency, type: 'expense')}</div>
  </div>
  <div class="summary-card">
    <div class="label">Net</div>
    <div class="value net">${formatSignedAmount(net.abs(), currency: baseCurrency, type: net >= 0 ? 'income' : 'expense')}</div>
  </div>
</div>

<h2>Spending by Category</h2>
<table>
  <thead><tr><th>Category</th><th style="text-align:right">Amount</th><th style="text-align:right">%</th></tr></thead>
  <tbody>$catRows</tbody>
</table>

<h2>Transactions (${transactions.length})</h2>
<table>
  <thead><tr><th>Date</th><th>Description</th><th>Category</th><th>Type</th><th style="text-align:right">Amount</th></tr></thead>
  <tbody>$txRows</tbody>
</table>

<div class="footer">Generated by PocketPlan &mdash; ${formatDate(DateTime.now())}</div>
</body>
</html>''';
  }

  String _escHtml(String s) =>
      s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
