import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import '../../shared/utils/haptics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/database/app_database.dart';
import '../../core/providers/allocations_provider.dart';
import '../../core/providers/categories_provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../core/providers/transactions_provider.dart';
import '../../core/providers/member_names_provider.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/design_tokens.dart';
import '../../shared/utils/format_number.dart';
import '../../shared/utils/receipt_helper.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/tappable.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_retry.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/utils/note_text.dart';
import '../../l10n/generated/app_localizations.dart';
import 'widgets/delete_with_undo.dart';
import 'widgets/tx_form_args.dart';
import 'widgets/tx_receipt.dart';
import 'widgets/tx_tile.dart';
import '../../shared/theme/app_icons.dart';

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
            appBar: AppBar(),
            body: EmptyState(
              icon: AppIcons.receipt,
              title: S.of(context).txDetailNotFound,
            ),
          );
        }

        return _DetailBody(entry: entry, categoryMap: categoryMap);
      },
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
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
    final baseCurrency =
        ref.watch(householdProvider).value?.baseCurrency ?? 'USD';

    final tr = S.of(context);
    final envelope = receiptEnvelope(entry, categoryMap,
        ref.watch(allocationsProvider).value ?? const []);
    final overBy = envelope != null && envelope.balance < -0.005
        ? -envelope.balance
        : null;
    // Shared budgets: who saved it (the last edit's device, after an edit).
    final savedBy = tx.id.startsWith('rec:')
        ? null
        : memberNameFor(
            ref.watch(memberNamesProvider).value ?? const {}, tx.deviceId);

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(AppIcons.pencilSimple),
            tooltip: tr.commonEdit,
            onPressed: () => _editTransaction(context, ref),
          ),
          PopupMenuButton<String>(
            icon: Icon(AppIcons.dotsThreeVertical, color: AppColors.ts(context)),
            onSelected: (action) {
              switch (action) {
                case 'save_template':
                  _saveAsTemplate(context, ref);
                case 'delete':
                  _confirmDelete(context, ref);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'save_template',
                child: Row(
                  children: [
                    Icon(AppIcons.lightning, size: 20, color: AppColors.ts(context)),
                    const SizedBox(width: 12),
                    Text(tr.txDetailSaveAsTemplate),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(AppIcons.trash, size: 20, color: AppColors.overspent),
                    const SizedBox(width: 12),
                    Text(tr.commonDelete,
                        style: TextStyle(color: AppColors.overspent)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          // The transaction as a paper receipt.
          TxReceipt(
            entry: entry,
            categoryMap: categoryMap,
            baseCurrency: baseCurrency,
          ),
          if (savedBy != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(AppIcons.user, size: 15, color: AppColors.ts(context)),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(tr.memberSavedBy(savedBy),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 13, color: AppColors.ts(context))),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          _ReceiptSection(
            receiptPath: tx.receiptPath,
            transactionId: tx.id,
          ),
          const SizedBox(height: 16),
          Row(children: [
            if (overBy != null) ...[
              Expanded(
                child: FilledButton(
                  onPressed: () => context.push(
                      '/allocations/${envelope.allocationId}',
                      extra: {'cover': true}),
                  child: Text(
                      tr.txCoverAmount(
                          formatAmount(overBy, currency: envelope!.currency)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  final args = txFormArgs(
                      entry, ref.read(categoriesProvider).value ?? const [],
                      edit: false);
                  context.pop();
                  context.push('/add-transaction', extra: args);
                },
                child: Text(tr.txContextDuplicate),
              ),
            ),
          ]),
          const SizedBox(height: 4),
          Center(
            child: TextButton(
              onPressed: () => _confirmDelete(context, ref),
              style: TextButton.styleFrom(
                  foregroundColor: AppColors.overspent,
                  minimumSize: const Size(0, 44)),
              child: Text(tr.commonDelete),
            ),
          ),

          // -- Related transactions (linked mixed-type entries) --
          _RelatedTransactions(tx: tx, categoryMap: categoryMap),
        ],
      ),
    );
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
            // The Activity row, so a linked transaction looks the same
            // everywhere.
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: AppColors.card(context),
              child: Column(children: [
                for (var i = 0; i < related.length; i++) ...[
                  if (i > 0)
                    Divider(height: 1, color: AppColors.bd(context)),
                  Consumer(builder: (context, ref, _) {
                    final e = ref
                        .watch(transactionByIdProvider(related[i].id))
                        .value;
                    if (e == null) return const SizedBox.shrink();
                    return TxTile(
                        entry: e,
                        categoryMap: categoryMap,
                        showBalance: false,
                        showDate: true);
                  }),
                ],
              ]),
            ),
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
    final tr = S.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final newFilenames = await pickAndSaveReceipts(context);
    if (newFilenames.isEmpty || !mounted) return;

    final updated = [..._filenames, ...newFilenames];
    try {
      await _writeReceipts(encodeReceiptPaths(updated));
    } catch (e) {
      debugPrint('[TxDetail] Adding receipts failed: $e');
      messenger.showSnackBar(SnackBar(
        content: Text(tr.commonSomethingWentWrong),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    if (!mounted) return;
    ref.invalidate(transactionEntriesProvider);
    messenger.showSnackBar(SnackBar(
      content: Text(newFilenames.length == 1
          ? tr.txFormReceiptAttached
          : tr.txFormNReceipts(newFilenames.length)),
      behavior: SnackBarBehavior.floating,
    ));

    _filenames = updated;
    _resolveFiles();
  }

  Future<void> _writeReceipts(String? encoded) {
    final db = ref.read(databaseProvider);
    return (db.update(db.transactions)
          ..where((t) => t.id.equals(widget.transactionId)))
        .write(TransactionsCompanion(
            receiptPath: Value(encoded),
            // Bump so the receipt change syncs.
            lastModified: Value(DateTime.now())));
  }

  Future<void> _removeReceipt(int index) async {
    final tr = S.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showConfirmDialog(
      context,
      title: tr.txDetailRemoveReceiptTitle,
      message: tr.txDetailRemoveReceiptBody,
      confirmLabel: tr.commonRemove,
    );
    if (!ok || !mounted) return;

    final updated = [..._filenames]..removeAt(index);
    try {
      await _writeReceipts(
          updated.isEmpty ? null : encodeReceiptPaths(updated));
    } catch (e) {
      debugPrint('[TxDetail] Removing receipt failed: $e');
      messenger.showSnackBar(SnackBar(
        content: Text(tr.commonSomethingWentWrong),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    if (!mounted) return;
    ref.invalidate(transactionEntriesProvider);
    messenger.showSnackBar(SnackBar(
      content: Text(tr.txDetailReceiptRemoved),
      behavior: SnackBarBehavior.floating,
    ));

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
              borderRadius: BorderRadius.circular(RadiusTokens.md),
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
      decoration: AppColors.card(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Icon(AppIcons.receipt,
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
                Tappable(
                  onTap: _addReceipts,
                  borderRadius: BorderRadius.circular(RadiusTokens.sm),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 2),
                    child: Text(
                      S.of(context).txDetailAttach,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accentText(context),
                      ),
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
                        Tappable(
                          onTap: () => _viewReceipt(path),
                          borderRadius:
                              BorderRadius.circular(RadiusTokens.md),
                          child: ClipRRect(
                            borderRadius:
                                BorderRadius.circular(RadiusTokens.md),
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
                          // On the photo itself: a dark scrim badge reads on
                          // any image, so it isn't theme-colored.
                          child: GestureDetector(
                            onTap: () => _removeReceipt(index),
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(AppIcons.x,
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
