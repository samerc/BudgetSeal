import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/providers/accounts_provider.dart';
import '../../core/providers/categories_provider.dart';
import '../../core/providers/date_format_provider.dart';
import '../../core/providers/transactions_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_icons.dart';
import '../../shared/widgets/icon_header_card.dart';
import '../transactions/widgets/export_entries.dart';

enum _Period { all, thisMonth, lastMonth, thisYear, custom }

/// Export transactions as CSV (one row per line, in the line's own
/// currency — the same file as Activity's selection export), filtered by
/// period, account and category.
class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  bool _exporting = false;
  _Period _period = _Period.all;
  DateTimeRange? _custom;
  String? _accountId;
  String? _categoryId;

  /// The chosen period as [from, to) — null ends are open.
  (DateTime?, DateTime?) _bounds() {
    final now = DateTime.now();
    return switch (_period) {
      _Period.all => (null, null),
      _Period.thisMonth => (DateTime(now.year, now.month), null),
      _Period.lastMonth =>
        (DateTime(now.year, now.month - 1), DateTime(now.year, now.month)),
      _Period.thisYear => (DateTime(now.year), null),
      _Period.custom => _custom == null
          ? (null, null)
          : (
              _custom!.start,
              DateTime(_custom!.end.year, _custom!.end.month,
                  _custom!.end.day + 1)
            ),
    };
  }

  List<TransactionEntry> _filter(
      List<TransactionEntry> all, Map<String, Category> cats) {
    final (from, to) = _bounds();
    bool inCategory(String? id) =>
        id != null && (id == _categoryId || cats[id]?.parentId == _categoryId);
    return all.where((e) {
      final d = e.tx.createdAt.toLocal();
      if (from != null && d.isBefore(from)) return false;
      if (to != null && !d.isBefore(to)) return false;
      if (_accountId != null &&
          e.tx.accountId != _accountId &&
          e.tx.destinationAccountId != _accountId &&
          !e.lines.any((l) => l.accountId == _accountId)) {
        return false;
      }
      if (_categoryId != null &&
          !inCategory(e.tx.categoryId) &&
          !e.lines.any((l) => inCategory(l.categoryId))) {
        return false;
      }
      return true;
    }).toList();
  }

  Future<void> _pickCustom() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: _custom ??
          DateTimeRange(start: DateTime(now.year, now.month), end: now),
    );
    if (picked != null && mounted) {
      setState(() {
        _custom = picked;
        _period = _Period.custom;
      });
    }
  }

  Future<void> _export(List<TransactionEntry> entries,
      Map<String, Category> cats) async {
    final tr = S.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _exporting = true);
    try {
      await shareEntriesCsv(entries, cats);
    } catch (e) {
      debugPrint('[Export] Failed: $e');
      messenger.showSnackBar(SnackBar(
        content: Text(tr.exportFailed),
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = S.of(context);
    final all = ref.watch(transactionEntriesProvider).value;
    final accounts = ref.watch(accountsProvider).value ?? const <Account>[];
    final catList = ref.watch(categoriesProvider).value ?? const <Category>[];
    final cats = {for (final c in catList) c.id: c};
    final topCats = catList
        .where((c) => c.parentId == null && !c.archived)
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final entries = all == null ? null : _filter(all, cats);

    String periodLabel(_Period p) => switch (p) {
          _Period.all => tr.exportAllTime,
          _Period.thisMonth => tr.dashboardThisMonth,
          _Period.lastMonth => tr.exportLastMonth,
          _Period.thisYear => tr.rptSpanYear,
          _Period.custom => _custom == null
              ? tr.exportCustomRange
              : tr.exportRangeLabel(
                  formatDate(_custom!.start), formatDate(_custom!.end)),
        };

    return Scaffold(
      appBar: AppBar(title: Text(tr.exportDataTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          IconHeaderCard(
            icon: AppIcons.fileArrowDown,
            title: tr.exportTransTitle,
            description: tr.exportTransDesc,
            children: [
              DropdownButtonFormField<_Period>(
                icon: AppIcons.dropdown,
                isExpanded: true,
                initialValue: _period,
                decoration: InputDecoration(labelText: tr.exportPeriod),
                items: [
                  for (final p in _Period.values)
                    DropdownMenuItem(
                        value: p,
                        child: Text(periodLabel(p),
                            overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (p) {
                  if (p == _Period.custom) {
                    _pickCustom();
                  } else if (p != null) {
                    setState(() => _period = p);
                  }
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                icon: AppIcons.dropdown,
                isExpanded: true,
                initialValue: _accountId,
                decoration: InputDecoration(labelText: tr.commonAccount),
                items: [
                  DropdownMenuItem(value: null, child: Text(tr.txAllAccounts)),
                  for (final a in accounts)
                    DropdownMenuItem(
                        value: a.id,
                        child: Text('${a.name} · ${a.currency}',
                            overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (v) => setState(() => _accountId = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                icon: AppIcons.dropdown,
                isExpanded: true,
                initialValue: _categoryId,
                decoration: InputDecoration(labelText: tr.commonCategory),
                items: [
                  DropdownMenuItem(
                      value: null, child: Text(tr.txAllCategories)),
                  for (final c in topCats)
                    DropdownMenuItem(
                        value: c.id,
                        child: Text(c.name, overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (v) => setState(() => _categoryId = v),
              ),
              const SizedBox(height: 12),
              Text(
                entries == null
                    ? ''
                    : entries.isEmpty
                        ? tr.exportNone
                        : tr.exportCount(entries.length),
                style: TextStyle(color: AppColors.ts(context)),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _exporting || entries == null || entries.isEmpty
                    ? null
                    : () => _export(entries, cats),
                icon: _exporting
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            color: AppColors.onAccent, strokeWidth: 2))
                    : const Icon(AppIcons.shareNetwork, size: 18),
                label: Text(_exporting
                    ? tr.backupExporting
                    : tr.backupExportShare),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
