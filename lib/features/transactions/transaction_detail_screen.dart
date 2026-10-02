import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../shared/utils/haptics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/database/app_database.dart';
import '../../core/providers/accounts_provider.dart';
import '../../core/providers/categories_provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/date_format_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../core/providers/transactions_provider.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/design_tokens.dart';
import '../../shared/utils/format_number.dart';
import '../../shared/utils/receipt_helper.dart';
import '../../shared/widgets/category_icon.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_retry.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/utils/note_text.dart';
import '../../l10n/generated/app_localizations.dart';
import 'widgets/delete_with_undo.dart';
import 'widgets/tx_form_args.dart';

class TransactionDetailScreen extends ConsumerWidget {
  final String transactionId;

  const TransactionDetailScreen({super.key, required this.transactionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Just this transaction — no full-history replay.
    final entryAsync = ref.watch(transactionByIdProvider(transactionId));
    final categories = ref.watch(categoriesProvider).value ?? [];
    final categoryMap = {for (final c in categories) c.id: c};

    return entryAsync.when(
      data: (entry) {
        if (entry == null) {
          return Scaffold(
            appBar: AppBar(
              surfaceTintColor: Colors.transparent,
              elevation: 0,
            ),
            body: EmptyState(
              icon: Icons.receipt_long_rounded,
              title: S.of(context).txDetailNotFound,
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
      error: (e, _) => Scaffold(
        appBar: AppBar(
            surfaceTintColor: Colors.transparent, elevation: 0),
        body: ErrorRetry(
          message: S.of(context).txCouldNotLoad,
          details: '$e',
          onRetry: () =>
              ref.invalidate(transactionByIdProvider(transactionId)),
        ),
      ),
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
      'income' => S.of(context).typeIncome,
      'expense' => S.of(context).typeExpense,
      'transfer' => S.of(context).typeTransfer,
      _ => tx.type,
    };

    // Resolve primary category for hero display
    final primaryCat = tx.categoryId != null ? categoryMap[tx.categoryId] : null;
    final catColor = primaryCat != null
        ? AppColors.fromHex(primaryCat.colorHex)
        : typeColor;

    // Same pastel band as the add/edit form, so view and edit look alike.
    final bandColor =
        AppColors.pastel(context, catColor, light: 0.75, dark: 0.7);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: bandColor,
        title: Text(S.of(context).txDetailTitle),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            tooltip: S.of(context).commonEdit,
            onPressed: () => _editTransaction(context, ref),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: AppColors.ts(context)),
            onSelected: (action) {
              switch (action) {
                case 'duplicate':
                  final args = txFormArgs(
                      entry, ref.read(categoriesProvider).value ?? const [],
                      edit: false);
                  context.pop();
                  context.push('/add-transaction', extra: args);
                case 'save_template':
                  _saveAsTemplate(context, ref);
                case 'delete':
                  _confirmDelete(context, ref);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'duplicate',
                child: Row(
                  children: [
                    Icon(Icons.copy_rounded, size: 20, color: AppColors.ts(context)),
                    const SizedBox(width: 12),
                    Text(S.of(context).txContextDuplicate),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'save_template',
                child: Row(
                  children: [
                    Icon(Icons.bolt_rounded, size: 20, color: AppColors.ts(context)),
                    const SizedBox(width: 12),
                    Text(S.of(context).txDetailSaveAsTemplate),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.overspent),
                    const SizedBox(width: 12),
                    Text(S.of(context).commonDelete,
                        style: TextStyle(color: AppColors.overspent)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          // -- Hero band (Cashew style) --
          Container(
            color: bandColor,
            padding: const EdgeInsetsDirectional.fromSTEB(18, 14, 20, 20),
            child: Row(
              children: [
                // Icon with the category name under it (same as the form).
                SizedBox(
                  width: 96,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                              size: 64,
                              circular: true,
                            ),
                          )
                        else
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppColors.pastel(context, typeColor,
                                  light: 0.35, dark: 0.3),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon,
                                color: AppColors.pastel(context, typeColor,
                                    light: 0.5, dark: 0.4, inverse: true),
                                size: 30),
                          ),
                      const SizedBox(height: 6),
                      Text(
                        primaryCat?.name ?? typeLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.tp(context).withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                Builder(builder: (_) {
                        final String amountText;
                        if (entry.lines.length == 1) {
                          amountText = formatSignedAmount(entry.lines.first.amount,
                              currency: entry.lines.first.currency, type: tx.type);
                        } else {
                          // Multi-line: compute base total from lines, skipping bogus rates
                          double baseTotal = 0;
                          for (final l in entry.lines) {
                            if (l.currency == baseCurrency) {
                              baseTotal += l.amount;
                            } else if ((l.exchangeRateToBase - 1.0).abs() >= 0.001) {
                              baseTotal += l.amount * l.exchangeRateToBase;
                            }
                            // else: skip lines with unset rate
                          }
                          amountText = formatSignedAmount(baseTotal,
                              currency: baseCurrency, type: tx.type);
                        }
                        return GestureDetector(
                          onLongPress: () {
                            Clipboard.setData(ClipboardData(text: amountText));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(S.of(context).txDetailCopied(amountText)),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          child: SizedBox(
                            height: 46,
                            width: double.infinity,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: AlignmentDirectional.centerEnd,
                              child: Text(
                                amountText,
                                style: TextStyle(
                                  fontSize: 36,
                                  fontFamily: TypographyTokens.displayFamily,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                  color: AppColors.tp(context),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                      if (entry.lines.length == 1 &&
                          entry.lines.first.currency != baseCurrency)
                        Text(
                          '= ${formatAmount(tx.amount, currency: baseCurrency)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.tp(context).withValues(alpha: 0.6),
                          ),
                        ),
                      const SizedBox(height: 2),
                      Text(
                        typeLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.tp(context).withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
          const SizedBox(height: 16),

          // -- Details card --
          _card(
            context,
            children: [
              _detailRow(context, S.of(context).txDetailDate,
                  formatDate(tx.createdAt.toLocal()),
                  icon: Icons.calendar_today_rounded),
              _divider(context),
              _detailRow(context, S.of(context).txDetailTime,
                  // Follows the device's 12/24-hour setting.
                  TimeOfDay.fromDateTime(tx.createdAt.toLocal())
                      .format(context),
                  icon: Icons.access_time_rounded),
              _divider(context),
              Builder(builder: (_) {
                final involvedNames = entry.involvedAccountNames;
                if (involvedNames.length > 1) {
                  // Multi-account: show all account names
                  return _detailRow(context, S.of(context).txDetailAccounts,
                      involvedNames.join(', '),
                      icon: Icons.account_balance_wallet_rounded);
                }
                // The line's account (per-line accounts), as shown in the name.
                final accountId = entry.lines.isNotEmpty
                    ? (entry.lines.first.accountId ?? tx.accountId)
                    : tx.accountId;
                return GestureDetector(
                  onTap: () => context.push('/accounts/$accountId'),
                  child: _detailRow(context, S.of(context).commonAccount,
                      '${entry.accountName.isNotEmpty ? entry.accountName : S.of(context).txDetailUnknownAccount} ›',
                      icon: Icons.account_balance_wallet_rounded),
                );
              }),
              if (tx.note.isNotEmpty) ...[
                _divider(context),
                _detailRow(context, S.of(context).txDetailNote, visibleNote(tx.note),
                    icon: Icons.notes_rounded),
              ],
              if (tx.categoryId != null &&
                  categoryMap.containsKey(tx.categoryId)) ...[
                _divider(context),
                _detailRow(context, S.of(context).commonCategory,
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
            SectionHeader(S.of(context).txDetailSplitItems(entry.lines.length),
                padding:
                    const EdgeInsetsDirectional.only(start: 4, bottom: 8)),
            _card(context, children: [
              for (var i = 0; i < entry.lines.length; i++) ...[
                if (i > 0) _divider(context),
                _lineRow(context, entry.lines[i], categoryMap, accountMap,
                    baseCurrency),
              ],
            ]),
          ],

          // -- Single line detail --
          // Only when the line adds something the band doesn't already show.
          if (entry.lines.length == 1 &&
              ((entry.lines.first.note.isNotEmpty &&
                      entry.lines.first.note.trim() != tx.note.trim()) ||
                  (entry.lines.first.categoryId != null &&
                      entry.lines.first.categoryId != tx.categoryId))) ...[
            const SizedBox(height: 16),
            SectionHeader(S.of(context).txDetailLineDetail,
                padding:
                    const EdgeInsetsDirectional.only(start: 4, bottom: 8)),
            _buildSingleLineCard(context, entry.lines.first, categoryMap),
          ],

          // -- Related transactions (linked mixed-type entries) --
          _RelatedTransactions(tx: tx, categoryMap: categoryMap),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleLineCard(
      BuildContext context, TransactionLine line, Map<String, Category> catMap) {
    return _card(context, children: [
      if (line.categoryId != null && catMap.containsKey(line.categoryId))
        _detailRow(context, S.of(context).commonCategory, catMap[line.categoryId]!.name,
            icon: Icons.label_outline_rounded),
      if (line.categoryId != null &&
          catMap.containsKey(line.categoryId) &&
          line.note.isNotEmpty)
        _divider(context),
      if (line.note.isNotEmpty)
        _detailRow(context, S.of(context).txDetailNote, line.note, icon: Icons.notes_rounded),
    ]);
  }

  Widget _card(BuildContext context, {required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.circular(CardTokens.radius),
        boxShadow: AppColors.cardShadow(context),
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
        ? catMap[line.categoryId]?.name ?? S.of(context).txDetailUnknownAccount
        : S.of(context).txDetailUncategorized;
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
    final args = txFormArgs(
        entry, ref.read(categoriesProvider).value ?? const [],
        edit: true);
    context.pop();
    context.push('/add-transaction', extra: args);
  }

  Future<void> _saveAsTemplate(BuildContext context, WidgetRef ref) async {
    final tx = entry.tx;
    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null) return;

    // Use the first line's data for currency/amount/category
    final line = entry.lines.isNotEmpty ? entry.lines.first : null;
    final amount = line?.amount ?? tx.amount;
    final currency = line?.currency ?? tx.currency;
    final categoryId = line?.categoryId ?? tx.categoryId;
    final title = tx.note.isNotEmpty ? visibleNote(tx.note) : (categoryMap[categoryId]?.name ?? '');

    try {
      final db = ref.read(databaseProvider);
      await db.into(db.transactionTemplates).insert(
            TransactionTemplatesCompanion.insert(
              id: const Uuid().v4(),
              householdId: householdId,
              title: title,
              type: tx.type,
              amount: amount,
              currency: currency,
              accountId: Value(tx.accountId),
              categoryId: Value(categoryId),
            ),
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).txDetailTemplateSaved),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('[TxDetail] Error saving template: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).txDetailTemplateError),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Deletes right away and pops; the list shows the Undo SnackBar.
  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    hapticHeavy();
    // Capture the messenger before popping so the SnackBar shows on the
    // screen underneath.
    final undo = deleteTransactionsWithUndo(context, [entry.tx.id]);
    context.pop();
    await undo;
  }

}

// ─── Receipt Section ────────────────────────────────────────────────────────

/// Shows linked transactions that were created together (same note + timestamp,
/// different type). This happens when the assisted flow splits mixed
/// expense+income items into separate transactions.
class _RelatedTransactions extends ConsumerStatefulWidget {
  final Transaction tx;
  final Map<String, Category> categoryMap;

  const _RelatedTransactions({required this.tx, required this.categoryMap});

  @override
  ConsumerState<_RelatedTransactions> createState() =>
      _RelatedTransactionsState();
}

class _RelatedTransactionsState extends ConsumerState<_RelatedTransactions> {
  late final Future<List<Transaction>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadRelated();
  }

  Future<List<Transaction>> _loadRelated() async {
    final tx = widget.tx;
    final db = ref.read(databaseProvider);
    // Find transactions with same note + same createdAt + same household
    // but different ID. For empty notes, also require matching type to
    // avoid false positives (many transactions could have empty notes).
    final candidates = await (db.select(db.transactions)
          ..where((t) => t.householdId.equals(tx.householdId))
          ..where((t) => t.deleted.equals(false))
          ..where((t) => t.note.equals(tx.note))
          ..where((t) => t.createdAt.equals(tx.createdAt))
          ..where((t) => t.id.isNotIn([tx.id])))
        .get();
    // For empty notes, only show related if the types differ
    // (income+expense pair from the same assisted flow session)
    if (tx.note.isEmpty) {
      return candidates.where((c) => c.type != tx.type).toList();
    }
    return candidates;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tx.note.isEmpty) return const SizedBox.shrink();

    final categoryMap = widget.categoryMap;

    return FutureBuilder<List<Transaction>>(
      future: _future,
      builder: (context, snapshot) {
        final related = snapshot.data;
        if (related == null || related.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            SectionHeader(
                related.length == 1
                    ? S.of(context).txDetailRelatedSingle
                    : S.of(context).txDetailRelatedPlural,
                padding:
                    const EdgeInsetsDirectional.only(start: 4, bottom: 8)),
            ...related.map((r) {
              final isIncome = r.type == 'income';
              final color = isIncome ? AppColors.healthy : AppColors.overspent;
              final typeLabel =
                  r.type[0].toUpperCase() + r.type.substring(1);
              final cat =
                  r.categoryId != null ? categoryMap[r.categoryId] : null;

              return GestureDetector(
                onTap: () => context.push('/transactions/${r.id}'),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.sf(context),
                    borderRadius: BorderRadius.circular(CardTokens.radius),
                    boxShadow: AppColors.cardShadow(context),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.pastel(context, color,
                              light: 0.85, dark: 0.78),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isIncome
                              ? Icons.arrow_downward_rounded
                              : Icons.arrow_upward_rounded,
                          color: color,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cat?.name ?? typeLabel,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.tp(context),
                              ),
                            ),
                            Text(
                              typeLabel,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.ts(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        formatSignedAmount(r.amount,
                            currency: r.currency, type: r.type),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right_rounded,
                          size: 18, color: AppColors.th(context)),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

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
    if (newFilenames.isEmpty || !mounted) return;

    final updated = [..._filenames, ...newFilenames];
    final encoded = encodeReceiptPaths(updated);

    final db = ref.read(databaseProvider);
    await (db.update(db.transactions)
          ..where((t) => t.id.equals(widget.transactionId)))
        .write(TransactionsCompanion(
            receiptPath: Value(encoded),
            // Bump so the receipt change syncs.
            lastModified: Value(DateTime.now())));
    if (!mounted) return;
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
        .write(TransactionsCompanion(
            receiptPath: Value(encoded),
            // Bump so the receipt change syncs.
            lastModified: Value(DateTime.now())));
    if (!mounted) return;
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
        borderRadius: BorderRadius.circular(CardTokens.radius),
        boxShadow: AppColors.cardShadow(context),
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
                        ? S.of(context).txDetailReceipts(_resolvedPaths.length)
                        : S.of(context).txDetailReceipt,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ts(context)),
                  ),
                ]),
                GestureDetector(
                  onTap: _addReceipts,
                  child: Text(
                    S.of(context).txDetailAttach,
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
                              cacheWidth: 200,
                              cacheHeight: 240,
                            ),
                          ),
                        ),
                        PositionedDirectional(
                          top: 4,
                          end: 4,
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
              child: Text(S.of(context).txDetailNoReceipt,
                  style: TextStyle(
                      fontSize: 12, color: AppColors.th(context))),
            ),
        ],
      ),
    );
  }
}
