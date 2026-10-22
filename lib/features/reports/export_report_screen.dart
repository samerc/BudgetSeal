import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/database/app_database.dart';
import '../../core/providers/categories_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../core/providers/transactions_provider.dart';
import '../../core/providers/date_format_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/design_tokens.dart';
import '../../shared/utils/format_number.dart';
import '../../shared/utils/note_text.dart';
import '../../shared/theme/app_icons.dart';
import '../../shared/widgets/app_card.dart';
import 'widgets/month_nav.dart';

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

  /// Exclusive: the first moment of the next month.
  DateTime get _monthEnd => DateTime(_month.year, _month.month + 1, 1);

  @override
  Widget build(BuildContext context) {
    final monthLabel = DateFormat('MMMM yyyy').format(_month);

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).exportReportTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Spacing.lg),
        child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                Icon(AppIcons.filePdf,
                    size: 22, color: AppColors.accentText(context)),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: Text(S.of(context).exportMonthlyTitle,
                      style: TextStyle(
                          fontSize: TypographyTokens.cardTitleSize,
                          fontWeight: TypographyTokens.cardTitleWeight,
                          color: AppColors.tp(context))),
                ),
              ]),
              const SizedBox(height: Spacing.md),
              Text(
                S.of(context).exportMonthlyDesc,
                style: TextStyle(
                    fontSize: TypographyTokens.amountSmallSize,
                    color: AppColors.ts(context)),
              ),
              const SizedBox(height: Spacing.lg),
              // The same month navigator as Reports.
              MonthNav(
                label: monthLabel,
                onPrev: () => setState(() => _selectedMonthsBack++),
                onNext: _selectedMonthsBack > 0
                    ? () => setState(() => _selectedMonthsBack--)
                    : null,
              ),
              const SizedBox(height: Spacing.lg),
              FilledButton.icon(
                onPressed: _exporting ? null : _export,
                icon: _exporting
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            color: AppColors.onAccent, strokeWidth: 2))
                    : const Icon(AppIcons.shareNetwork, size: 18),
                label: Text(_exporting
                    ? S.of(context).exportGenerating
                    : S.of(context).exportGenerateShare),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _export() async {
    final s = S.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final messenger = ScaffoldMessenger.of(context);
    final uncategorized = s.commonUncategorized;
    final fileName =
        'budgetseal_report_${DateFormat('yyyy_MM').format(_month)}.html';
    File? file;
    setState(() => _exporting = true);
    try {
      final entries =
          ref.read(transactionEntriesProvider).value ?? [];
      final categories =
          ref.read(categoriesProvider).value ?? [];
      final categoryMap = {for (final c in categories) c.id: c};
      final household = ref.read(householdProvider).value;
      final baseCurrency = household?.baseCurrency ?? 'USD';
      final householdName = household?.name ?? 'BudgetSeal';

      // [start, end): a transaction at 00:00 on the 1st belongs here.
      final filtered = entries
          .where((e) =>
              !e.tx.createdAt.isBefore(_month) &&
              e.tx.createdAt.isBefore(_monthEnd))
          .toList();

      double totalIncome = 0;
      double totalExpense = 0;
      final catSpend = <String, double>{};

      for (final e in filtered) {
        // Lines without a real rate to the base currency are left out, as
        // everywhere else in Reports.
        double baseAmt = 0;
        if (e.lines.isNotEmpty) {
          for (final l in e.lines) {
            if (!isRealRate(l.currency, baseCurrency, l.exchangeRateToBase)) {
              continue;
            }
            baseAmt += l.amount * l.exchangeRateToBase;
          }
        } else if (isRealRate(
            e.tx.currency, baseCurrency, e.tx.exchangeRateToBase)) {
          baseAmt = e.tx.amount * e.tx.exchangeRateToBase;
        }
        if (e.tx.type == 'income') totalIncome += baseAmt;
        if (e.tx.type == 'expense') {
          totalExpense += baseAmt;
          final catId = e.tx.categoryId;
          final name = catId != null
              ? (categoryMap[catId]?.name ?? uncategorized)
              : uncategorized;
          catSpend[name] = (catSpend[name] ?? 0) + baseAmt;
        }
      }

      final sortedCats = catSpend.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final monthLabel = DateFormat('MMMM yyyy').format(_month);
      final net = totalIncome - totalExpense;

      final html = _buildHtml(
        s: s,
        rtl: rtl,
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
      file = File('${tempDir.path}/$fileName');
      await file.writeAsString(html);

      if (mounted) {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            text: s.exportShareText(monthLabel),
          ),
        );
      }
    } catch (e) {
      debugPrint('[ExportReport] Failed: $e');
      messenger.showSnackBar(SnackBar(
        content: Text(s.exportReportFailed),
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _exporting = false);
      // Clean up temp file after sharing
      try {
        if (file != null && file.existsSync()) await file.delete();
      } catch (_) {}
    }
  }

  String _buildHtml({
    required S s,
    required bool rtl,
    required String householdName,
    required String monthLabel,
    required String baseCurrency,
    required double totalIncome,
    required double totalExpense,
    required double net,
    required List<MapEntry<String, double>> categoryBreakdown,
    required List<TransactionEntry> transactions,
    required Map<String, Category> categoryMap,
  }) {
    String typeLabel(String type) => switch (type) {
          'income' => s.typeIncome,
          'transfer' => s.typeTransfer,
          _ => s.typeExpense,
        };
    final start = rtl ? 'right' : 'left';
    final end = rtl ? 'left' : 'right';

    final txRows = transactions.map((e) {
      final tx = e.tx;
      final cat = tx.categoryId != null ? categoryMap[tx.categoryId] : null;
      final catName = _escHtml(cat?.name ?? '');
      final color = tx.type == 'income' ? '#059669' : tx.type == 'expense' ? '#DC2626' : '#6577E0';
      return '''
        <tr>
          <td>${formatDate(tx.createdAt.toLocal())}</td>
          <td>${tx.note.isNotEmpty ? _escHtml(visibleNote(tx.note)) : catName}</td>
          <td>$catName</td>
          <td>${typeLabel(tx.type)}</td>
          <td style="color:$color;font-weight:600;text-align:$end">${formatSignedAmount(tx.amount, currency: baseCurrency, type: tx.type)}</td>
        </tr>''';
    }).join('\n');

    final catRows = categoryBreakdown.map((e) {
      final pct = totalExpense > 0
          ? formatNumber(e.value / totalExpense * 100, decimals: 1)
          : '0';
      return '''
        <tr>
          <td>${_escHtml(e.key)}</td>
          <td style="text-align:$end">${formatAmount(e.value, currency: baseCurrency)}</td>
          <td style="text-align:$end">$pct%</td>
        </tr>''';
    }).join('\n');

    final name = _escHtml(householdName);
    final subtitle = _escHtml(s.exportHtmlSubtitle(monthLabel));

    return '''
<!DOCTYPE html>
<html dir="${rtl ? 'rtl' : 'ltr'}">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>$name – $subtitle</title>
<style>
  body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; color: #1a1a2e; }
  h1 { font-size: 24px; margin-bottom: 4px; }
  h2 { font-size: 18px; margin-top: 32px; border-bottom: 2px solid #e2e8f0; padding-bottom: 8px; }
  .subtitle { color: #64748b; font-size: 14px; }
  .summary { display: flex; gap: 24px; margin: 20px 0; }
  .summary-card { flex: 1; padding: 16px; border-radius: 12px; background: #f8fafc; border: 1px solid #e2e8f0; }
  .summary-card .label { font-size: 12px; color: #64748b; }
  .summary-card .value { font-size: 22px; font-weight: 700; margin-top: 4px; }
  .income { color: #059669; }
  .expense { color: #DC2626; }
  .net { color: ${net >= 0 ? '#059669' : '#DC2626'}; }
  table { width: 100%; border-collapse: collapse; font-size: 13px; }
  th { text-align: $start; padding: 8px 12px; background: #f1f5f9; font-weight: 600; font-size: 11px; color: #64748b; }
  td { padding: 8px 12px; border-bottom: 1px solid #e2e8f0; }
  .footer { margin-top: 40px; text-align: center; font-size: 11px; color: #94a3b8; }
</style>
</head>
<body>
<h1>$name</h1>
<p class="subtitle">$subtitle</p>

<div class="summary">
  <div class="summary-card">
    <div class="label">${s.typeIncome}</div>
    <div class="value income">${formatSignedAmount(totalIncome, currency: baseCurrency, type: 'income')}</div>
  </div>
  <div class="summary-card">
    <div class="label">${s.dashboardLabelExpenses}</div>
    <div class="value expense">${formatSignedAmount(totalExpense, currency: baseCurrency, type: 'expense')}</div>
  </div>
  <div class="summary-card">
    <div class="label">${s.dashboardLabelNet}</div>
    <div class="value net">${formatSignedAmount(net.abs(), currency: baseCurrency, type: net >= 0 ? 'income' : 'expense')}</div>
  </div>
</div>

<h2>${s.exportSpendingByCat}</h2>
<table>
  <thead><tr><th>${s.commonCategory}</th><th style="text-align:$end">${s.commonAmount}</th><th style="text-align:$end">%</th></tr></thead>
  <tbody>$catRows</tbody>
</table>

<h2>${s.exportHtmlTransactions(transactions.length)}</h2>
<table>
  <thead><tr><th>${s.txDetailDate}</th><th>${s.importColDescription}</th><th>${s.commonCategory}</th><th>${s.acctTypeSection}</th><th style="text-align:$end">${s.commonAmount}</th></tr></thead>
  <tbody>$txRows</tbody>
</table>

<div class="footer">${s.exportHtmlFooter(formatDate(DateTime.now()))}</div>
</body>
</html>''';
  }

  String _escHtml(String s) =>
      s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');
}
