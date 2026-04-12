import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/database/app_database.dart';
import '../../core/providers/accounts_provider.dart';
import '../../core/providers/categories_provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/engine_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../core/providers/transactions_provider.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/utils/format_number.dart';
import '../../shared/utils/receipt_helper.dart';
import '../../shared/widgets/category_icon.dart';

class TransactionDetailScreen extends ConsumerWidget {
  final String transactionId;

  const TransactionDetailScreen({super.key, required this.transactionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(transactionEntriesProvider);
    final categories = ref.watch(categoriesProvider).value ?? [];
    final categoryMap = {for (final c in categories) c.id: c};

    return entriesAsync.when(
      data: (entries) {
        final entry = entries
            .where((e) => e.tx.id == transactionId)
            .firstOrNull;

        if (entry == null) {
          return Scaffold(
            appBar: AppBar(
              surfaceTintColor: Colors.transparent,
              elevation: 0,
            ),
            body: Center(
              child: Text('Transaction not found',
                  style: TextStyle(
                      color: AppColors.ts(context), fontSize: 16)),
            ),
          );
        }

        return _DetailBody(entry: entry, categoryMap: categoryMap);
      },
      loading: () => Scaffold(
        appBar: AppBar(
            surfaceTintColor: Colors.transparent, elevation: 0),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) =>
          Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  final TransactionEntry entry;
  final Map<String, Category> categoryMap;

  const _DetailBody({required this.entry, required this.categoryMap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tx = entry.tx;
    final isIncome = tx.type == 'income';
    final isExpense = tx.type == 'expense';
    final accounts = ref.watch(accountsProvider).value ?? [];
    final accountMap = {for (final a in accounts) a.id: a};
    final baseCurrency =
        ref.watch(householdProvider).value?.baseCurrency ?? 'USD';

    final Color typeColor = isIncome
        ? AppColors.healthy
        : isExpense
            ? AppColors.overspent
            : AppColors.accent;

    final IconData icon = isIncome
        ? Icons.arrow_downward_rounded
        : isExpense
            ? Icons.arrow_upward_rounded
            : Icons.swap_horiz_rounded;

    final typeLabel = switch (tx.type) {
      'income' => 'Income',
      'expense' => 'Expense',
      'transfer' => 'Transfer',
      _ => tx.type,
    };

    // Resolve primary category for hero display
    final primaryCat = tx.categoryId != null ? categoryMap[tx.categoryId] : null;
    final catColor = primaryCat != null
        ? _hexToColor(primaryCat.colorHex)
        : typeColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Details'),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () => _editTransaction(context, ref),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: AppColors.overspent),
            tooltip: 'Delete',
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // -- Hero amount card --
          Container(
            padding:
                const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.sf(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.bd(context)),
            ),
            child: Column(
              children: [
                // Category icon or type icon
                if (primaryCat != null)
                  Hero(
                    tag: 'tx_${tx.id}',
                    child: CategoryIcon(
                      categoryName: primaryCat.name,
                      emoji: primaryCat.icon.length <= 4 &&
                              primaryCat.icon != 'category'
                          ? primaryCat.icon
                          : null,
                      color: catColor,
                      size: 56,
                      circular: true,
                    ),
                  )
                else
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: typeColor, size: 28),
                  ),
                const SizedBox(height: 12),
                // Category name
                if (primaryCat != null) ...[
                  Text(primaryCat.name,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.tp(context))),
                  const SizedBox(height: 4),
                ],
                // Amount
                Text(
                  formatSignedAmount(tx.amount, currency: tx.currency, type: tx.type),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: typeColor,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(typeLabel,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: typeColor,
                          letterSpacing: 0.5)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // -- Details card --
          _card(
            context,
            children: [
              _detailRow(context, 'Date',
                  DateFormat('EEEE, MMMM d, yyyy').format(tx.createdAt.toLocal()),
                  icon: Icons.calendar_today_rounded),
              _divider(context),
              _detailRow(context, 'Time',
                  DateFormat('h:mm a').format(tx.createdAt.toLocal()),
                  icon: Icons.access_time_rounded),
              _divider(context),
              _detailRow(context, 'Account',
                  entry.accountName.isNotEmpty ? entry.accountName : 'Unknown',
                  icon: Icons.account_balance_wallet_outlined),
              _divider(context),
              _detailRow(context, 'Balance after',
                  formatAmount(entry.accountBalanceAfter, currency: tx.currency),
                  icon: Icons.account_balance_outlined),
              if (tx.note.isNotEmpty) ...[
                _divider(context),
                _detailRow(context, 'Note', tx.note,
                    icon: Icons.notes_rounded),
              ],
              if (tx.categoryId != null &&
                  categoryMap.containsKey(tx.categoryId)) ...[
                _divider(context),
                _detailRow(context, 'Category',
                    categoryMap[tx.categoryId]!.name,
                    icon: Icons.label_outline_rounded),
              ],
            ],
          ),

          // -- Receipt --
          const SizedBox(height: 16),
          _ReceiptSection(
            receiptPath: tx.receiptPath,
            transactionId: tx.id,
          ),

          // -- Split lines --
          if (entry.lines.length > 1) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text('SPLIT ITEMS (${entry.lines.length})',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: AppColors.ts(context))),
            ),
            _card(context, children: [
              for (var i = 0; i < entry.lines.length; i++) ...[
                if (i > 0) _divider(context),
                _lineRow(context, entry.lines[i], categoryMap, accountMap,
                    baseCurrency),
              ],
            ]),
          ],

          // -- Single line detail --
          if (entry.lines.length == 1 &&
              (entry.lines.first.note.isNotEmpty ||
                  entry.lines.first.categoryId != null)) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text('LINE DETAIL',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: AppColors.ts(context))),
            ),
            _buildSingleLineCard(context, entry.lines.first, categoryMap),
          ],
        ],
      ),
    );
  }

  Widget _buildSingleLineCard(
      BuildContext context, TransactionLine line, Map<String, Category> catMap) {
    return _card(context, children: [
      if (line.categoryId != null && catMap.containsKey(line.categoryId))
        _detailRow(context, 'Category', catMap[line.categoryId]!.name,
            icon: Icons.label_outline_rounded),
      if (line.categoryId != null &&
          catMap.containsKey(line.categoryId) &&
          line.note.isNotEmpty)
        _divider(context),
      if (line.note.isNotEmpty)
        _detailRow(context, 'Note', line.note, icon: Icons.notes_rounded),
    ]);
  }

  Widget _card(BuildContext context, {required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.bd(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(children: children),
      ),
    );
  }

  Widget _detailRow(BuildContext context, String label, String value,
      {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(icon, size: 18, color: AppColors.th(context)),
            ),
            const SizedBox(width: 12),
          ],
          SizedBox(
            width: 90,
            child: Text(label,
                style: TextStyle(
                    fontSize: 13,
                    color: AppColors.ts(context),
                    fontWeight: FontWeight.w500)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    fontSize: 13,
                    color: AppColors.tp(context),
                    fontWeight: FontWeight.w600),
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
                maxLines: 2),
          ),
        ],
      ),
    );
  }

  Widget _lineRow(BuildContext context, TransactionLine line,
      Map<String, Category> catMap, Map<String, Account> accountMap,
      String baseCurrency) {
    final catName = line.categoryId != null
        ? catMap[line.categoryId]?.name ?? 'Unknown'
        : 'Uncategorized';
    final lineAccount =
        line.accountId != null ? accountMap[line.accountId] : null;
    final showConversion =
        line.currency != baseCurrency && line.exchangeRateToBase != 1.0;
    final baseAmount = line.amount * line.exchangeRateToBase;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        Icon(Icons.label_outline_rounded,
            size: 16, color: AppColors.th(context)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(catName,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.tp(context))),
                if (lineAccount != null)
                  Text(lineAccount.name,
                      style: TextStyle(
                          fontSize: 11, color: AppColors.ts(context))),
                if (line.note.isNotEmpty)
                  Text(line.note,
                      style: TextStyle(
                          fontSize: 11, color: AppColors.ts(context)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
              ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(formatAmount(line.amount, currency: line.currency),
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.tp(context))),
          if (showConversion)
            Text('= ${formatAmount(baseAmount, currency: baseCurrency)}',
                style: TextStyle(
                    fontSize: 11, color: AppColors.ts(context))),
        ]),
      ]),
    );
  }

  Widget _divider(BuildContext context) {
    return Divider(
        height: 1, indent: 16, endIndent: 16, color: AppColors.bd(context));
  }

  void _editTransaction(BuildContext context, WidgetRef ref) {
    final tx = entry.tx;
    final categories = ref.read(categoriesProvider).value ?? [];
    final catMap = {for (final c in categories) c.id: c};
    final editLines = entry.lines.map((l) {
      final cat = l.categoryId != null ? catMap[l.categoryId] : null;
      return <String, dynamic>{
        'amount': l.amount,
        'currency': l.currency,
        'accountId': l.accountId ?? tx.accountId,
        'categoryId': l.categoryId,
        'categoryName': cat?.name,
        'note': l.note,
      };
    }).toList();

    if (editLines.isEmpty) {
      final cat = tx.categoryId != null ? catMap[tx.categoryId] : null;
      editLines.add({
        'amount': tx.amount,
        'currency': tx.currency,
        'accountId': tx.accountId,
        'categoryId': tx.categoryId,
        'categoryName': cat?.name,
        'note': '',
      });
    }

    context.pop();
    context.push('/add-transaction', extra: {
      'editTransactionId': tx.id,
      'editType': tx.type,
      'editNote': tx.note,
      'editDate': tx.createdAt,
      'editLines': editLines,
    });
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text(
          'Are you sure you want to delete this transaction?\n\n'
          'This will reverse any envelope deductions and restore '
          'the balance. Ledger entries will be removed.\n\n'
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: TextButton.styleFrom(
                foregroundColor: AppColors.overspent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final engine = ref.read(allocationEngineProvider);
      await engine.deleteTransaction(entry.tx.id);
      if (context.mounted) context.pop();
    }
  }

  static Color _hexToColor(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }
}

// ─── Receipt Section ────────────────────────────────────────────────────────

class _ReceiptSection extends ConsumerStatefulWidget {
  final String? receiptPath;
  final String transactionId;

  const _ReceiptSection({
    required this.receiptPath,
    required this.transactionId,
  });

  @override
  ConsumerState<_ReceiptSection> createState() => _ReceiptSectionState();
}

class _ReceiptSectionState extends ConsumerState<_ReceiptSection> {
  List<String> _filenames = [];
  List<String> _resolvedPaths = [];

  @override
  void initState() {
    super.initState();
    _filenames = parseReceiptPaths(widget.receiptPath);
    _resolveFiles();
  }

  @override
  void didUpdateWidget(covariant _ReceiptSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.receiptPath != widget.receiptPath) {
      _filenames = parseReceiptPaths(widget.receiptPath);
      _resolveFiles();
    }
  }

  Future<void> _resolveFiles() async {
    final paths = await resolveReceiptPaths(_filenames);
    if (mounted) {
      setState(() {
        _resolvedPaths = paths;
      });
    }
  }

  Future<void> _addReceipts() async {
    final newFilenames = await pickAndSaveReceipts(context);
    if (newFilenames.isEmpty) return;

    final updated = [..._filenames, ...newFilenames];
    final encoded = encodeReceiptPaths(updated);

    final db = ref.read(databaseProvider);
    await (db.update(db.transactions)
          ..where((t) => t.id.equals(widget.transactionId)))
        .write(TransactionsCompanion(receiptPath: Value(encoded)));
    ref.invalidate(transactionEntriesProvider);

    _filenames = updated;
    _resolveFiles();
  }

  Future<void> _removeReceipt(int index) async {
    final updated = [..._filenames]..removeAt(index);
    final encoded = updated.isEmpty ? null : encodeReceiptPaths(updated);

    final db = ref.read(databaseProvider);
    await (db.update(db.transactions)
          ..where((t) => t.id.equals(widget.transactionId)))
        .write(TransactionsCompanion(receiptPath: Value(encoded)));
    ref.invalidate(transactionEntriesProvider);

    _filenames = updated;
    _resolveFiles();
  }

  void _viewReceipt(String path) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(ctx),
          child: InteractiveViewer(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(File(path)),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasReceipts = _resolvedPaths.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.bd(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Icon(Icons.receipt_long_rounded,
                      size: 16, color: AppColors.ts(context)),
                  const SizedBox(width: 8),
                  Text(
                    hasReceipts
                        ? 'Receipts (${_resolvedPaths.length})'
                        : 'Receipt',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ts(context)),
                  ),
                ]),
                GestureDetector(
                  onTap: _addReceipts,
                  child: Text(
                    'Attach',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (hasReceipts) ...[
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _resolvedPaths.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final path = _resolvedPaths[index];
                    return Stack(
                      children: [
                        GestureDetector(
                          onTap: () => _viewReceipt(path),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              File(path),
                              width: 100,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _removeReceipt(index),
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close_rounded,
                                  size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
              child: Text('No receipt attached',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.th(context))),
            ),
        ],
      ),
    );
  }
}
