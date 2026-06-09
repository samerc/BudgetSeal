import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/database/app_database.dart';
import '../../core/engine/allocation_engine.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/date_format_provider.dart';
import '../../core/providers/engine_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/design_tokens.dart';
import '../../shared/utils/format_number.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/tappable.dart';

/// A planned payment item with its resolved account, category, and lines.
class _PlannedItem {
  final Transaction tx;
  final List<TransactionLine> lines;
  final String accountName;
  final String? categoryName;
  final String lineCurrency;
  final double lineAmount;

  _PlannedItem({
    required this.tx,
    required this.lines,
    required this.accountName,
    this.categoryName,
    required this.lineCurrency,
    required this.lineAmount,
  });
}

/// A month group of planned payments.
class _MonthGroup {
  final String key; // 'yyyy-MM'
  final String label; // 'June 2026'
  final List<_PlannedItem> items;
  final double total; // base currency only
  final bool hasOtherCurrencies;

  _MonthGroup({
    required this.key,
    required this.label,
    required this.items,
    required this.total,
    required this.hasOtherCurrencies,
  });
}

class PlannedPaymentsScreen extends ConsumerStatefulWidget {
  const PlannedPaymentsScreen({super.key});

  @override
  ConsumerState<PlannedPaymentsScreen> createState() =>
      _PlannedPaymentsScreenState();
}

class _PlannedPaymentsScreenState
    extends ConsumerState<PlannedPaymentsScreen> {
  List<_MonthGroup> _groups = [];
  bool _loading = true;
  String _baseCurrency = 'USD';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final db = ref.read(databaseProvider);
      final householdId = ref.read(currentHouseholdIdProvider);
      if (householdId == null) return;

      // Fetch household base currency
      final household = await (db.select(db.households)
            ..where((h) => h.id.equals(householdId)))
          .getSingleOrNull();
      final baseCurrency = household?.baseCurrency ?? 'USD';

      // Fetch planned transactions
      final items = await (db.select(db.transactions)
            ..where((t) => t.householdId.equals(householdId))
            ..where((t) => t.status.equals('planned'))
            ..where((t) => t.deleted.equals(false))
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .get();

      if (items.isEmpty) {
        if (mounted) {
          setState(() {
            _groups = [];
            _baseCurrency = baseCurrency;
            _loading = false;
          });
        }
        return;
      }

      // Batch-fetch lines, accounts, and categories in parallel
      final txIds = items.map((t) => t.id).toList();
      final accountIds = items.map((t) => t.accountId).toSet().toList();
      final categoryIds = items
          .where((t) => t.categoryId != null)
          .map((t) => t.categoryId!)
          .toSet()
          .toList();

      final results = await Future.wait([
        // Lines
        (db.select(db.transactionLines)
              ..where((l) => l.transactionId.isIn(txIds)))
            .get(),
        // Accounts
        (db.select(db.accounts)..where((a) => a.id.isIn(accountIds))).get(),
        // Categories
        if (categoryIds.isNotEmpty)
          (db.select(db.categories)
                ..where((c) => c.id.isIn(categoryIds)))
              .get()
        else
          Future.value(<Category>[]),
      ]);

      final allLines = results[0] as List<TransactionLine>;
      final accounts = results[1] as List<Account>;
      final categories = results[2] as List<Category>;

      final accountMap = {for (final a in accounts) a.id: a.name};
      final categoryMap = {for (final c in categories) c.id: c.name};
      final linesMap = <String, List<TransactionLine>>{};
      for (final line in allLines) {
        linesMap.putIfAbsent(line.transactionId, () => []).add(line);
      }

      // Build planned items
      final planned = <_PlannedItem>[];
      for (final tx in items) {
        final txLines = linesMap[tx.id] ?? [];
        final firstLine = txLines.isNotEmpty ? txLines.first : null;
        planned.add(_PlannedItem(
          tx: tx,
          lines: txLines,
          accountName: accountMap[tx.accountId] ?? 'Unknown',
          categoryName:
              tx.categoryId != null ? categoryMap[tx.categoryId] : null,
          lineCurrency: firstLine?.currency ?? tx.currency,
          lineAmount: firstLine?.amount ?? tx.amount,
        ));
      }

      // Group by month
      final groupMap = <String, List<_PlannedItem>>{};
      for (final item in planned) {
        final date = item.tx.createdAt;
        final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
        groupMap.putIfAbsent(key, () => []).add(item);
      }

      final groups = <_MonthGroup>[];
      final sortedKeys = groupMap.keys.toList()..sort();
      for (final key in sortedKeys) {
        final items = groupMap[key]!;
        final parts = key.split('-');
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final label = DateFormat('MMMM yyyy').format(DateTime(year, month));
        final total = items
            .where((item) => item.lineCurrency == baseCurrency)
            .fold(0.0, (sum, item) => sum + item.lineAmount);
        final hasOtherCurrencies =
            items.any((item) => item.lineCurrency != baseCurrency);
        groups.add(_MonthGroup(
          key: key,
          label: label,
          items: items,
          total: total,
          hasOtherCurrencies: hasOtherCurrencies,
        ));
      }

      if (mounted) {
        setState(() {
          _groups = groups;
          _baseCurrency = baseCurrency;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('[PlannedPayments] Error loading: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  int get _totalCount =>
      _groups.fold(0, (sum, g) => sum + g.items.length);

  double get _totalAmount =>
      _groups.fold(0.0, (sum, g) => sum + g.total);

  bool get _hasOtherCurrencies =>
      _groups.any((g) => g.hasOtherCurrencies);

  /// Posts a planned item silently (no SnackBar, no _load).
  /// Returns true on success, false on failure.
  Future<bool> _postItemSilent(_PlannedItem item) async {
    try {
      final engine = ref.read(allocationEngineProvider);
      final householdId = ref.read(currentHouseholdIdProvider);
      if (householdId == null) return false;

      final tx = item.tx;

      // 1. Create the posted transaction FIRST (if this fails, planned tx is still intact)
      if (tx.type == 'transfer') {
        await engine.recordTransfer(
          householdId: householdId,
          fromAccountId: tx.accountId,
          toAccountId: tx.destinationAccountId ?? tx.accountId,
          amount: tx.amount,
          currency: tx.currency,
          exchangeRateToBase: tx.exchangeRateToBase,
          createdBy: 'user',
          deviceId: tx.deviceId,
          note: tx.note,
          date: tx.createdAt,
        );
      } else {
        // income or expense — use recordTransaction with lines
        final lines = item.lines
            .map((l) => TxLine(
                  amount: l.amount,
                  currency: l.currency,
                  categoryId: l.categoryId,
                  accountId: l.accountId,
                  exchangeRateToBase: l.exchangeRateToBase,
                  note: l.note,
                ))
            .toList();

        // If no lines exist (legacy), create one from the header
        if (lines.isEmpty) {
          lines.add(TxLine(
            amount: tx.amount,
            currency: tx.currency,
            categoryId: tx.categoryId,
            exchangeRateToBase: tx.exchangeRateToBase,
          ));
        }

        await engine.recordTransaction(
          householdId: householdId,
          accountId: tx.accountId,
          type: tx.type,
          lines: lines,
          baseCurrency: _baseCurrency,
          destinationAccountId: tx.destinationAccountId,
          note: tx.note,
          deviceId: tx.deviceId,
          date: tx.createdAt,
        );
      }

      // 2. Only delete the planned transaction AFTER successful creation
      await engine.deleteTransaction(tx.id);

      return true;
    } catch (e) {
      debugPrint('[PlannedPayments] Error posting: $e');
      return false;
    }
  }

  Future<void> _postItem(_PlannedItem item) async {
    final success = await _postItemSilent(item);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).plannedPosted),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).plannedPostFailed),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _postAll(_MonthGroup group) async {
    final tr = S.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr.plannedPostAllTitle),
        content: Text(
          tr.plannedPostAllContent(group.items.length, group.label),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr.plannedPostAll),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    var posted = 0;
    var failed = 0;
    for (final item in group.items) {
      final success = await _postItemSilent(item);
      if (success) {
        posted++;
      } else {
        failed++;
      }
    }

    if (!mounted) return;
    final tr2 = S.of(context);
    final message = failed == 0
        ? tr2.plannedPostAllResult(posted)
        : tr2.plannedPostAllResultPartial(posted, failed);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
    _load();
  }

  Future<void> _deleteItem(_PlannedItem item) async {
    final tr = S.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr.plannedDeleteTitle),
        content: Text(tr.plannedDeleteContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.overspent),
            child: Text(tr.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      final engine = ref.read(allocationEngineProvider);
      await engine.deleteTransaction(item.tx.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).plannedDeleted),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _load();
    } catch (e) {
      debugPrint('[PlannedPayments] Error deleting: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).plannedDeleteFailed),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        tooltip: S.of(context).plannedAddTooltip,
        onPressed: () async {
          final result = await context.push('/plan-payment');
          if (result == true) _load();
        },
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async => _load(),
          child: CustomScrollView(
            slivers: [
              // ── Header ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          S.of(context).plannedTitle,
                          style: TextStyle(
                            fontSize: TypographyTokens.screenTitleSize,
                            fontWeight: FontWeight.w800,
                            color: AppColors.tp(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Summary banner ──
              if (!_loading && _groups.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.sfv(context),
                        borderRadius:
                            BorderRadius.circular(CardTokens.radius),
                      ),
                      child: Row(
                        children: [
                          _SummaryChip(
                            icon: Icons.schedule_send_rounded,
                            label: '$_totalCount',
                            subtitle: S.of(context).plannedChipLabel,
                            color: AppColors.accent,
                          ),
                          const SizedBox(width: 20),
                          _SummaryChip(
                            icon: Icons.payments_rounded,
                            label: formatAmount(_totalAmount,
                                currency: _baseCurrency),
                            subtitle: _hasOtherCurrencies
                                ? '${S.of(context).plannedTotalLabel} + other'
                                : S.of(context).plannedTotalLabel,
                            color: AppColors.caution,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // ── Loading / Empty / List ──
              if (_loading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_groups.isEmpty)
                SliverFillRemaining(
                  child: EmptyState(
                    icon: Icons.schedule_send_rounded,
                    title: S.of(context).plannedEmptyTitle,
                    subtitle: S.of(context).plannedEmptySubtitle,
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        // Build a flat list of month headers + items
                        int offset = 0;
                        for (final group in _groups) {
                          // Month header
                          if (index == offset) {
                            return _MonthHeader(
                              group: group,
                              baseCurrency: _baseCurrency,
                              onPostAll: () => _postAll(group),
                            );
                          }
                          offset++;

                          // Items within this month
                          final itemIndex = index - offset;
                          if (itemIndex < group.items.length) {
                            return _PlannedCard(
                              item: group.items[itemIndex],
                              baseCurrency: _baseCurrency,
                              onPost: () => _postItem(
                                  group.items[itemIndex]),
                              onDelete: () => _deleteItem(
                                  group.items[itemIndex]),
                              onTap: () async {
                                final item = group.items[itemIndex];
                                final result = await context.push(
                                  '/plan-payment',
                                  extra: {
                                    'transaction': item.tx,
                                    'lines': item.lines,
                                  },
                                );
                                if (result == true) _load();
                              },
                            );
                          }
                          offset += group.items.length;
                        }
                        return const SizedBox.shrink();
                      },
                      childCount: _groups.fold<int>(
                          0,
                          (sum, g) =>
                              sum + 1 + g.items.length), // headers + items
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Summary Chip ─────────────────────────────────────────────────────────────

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;

  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.tp(context),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: AppColors.ts(context)),
        ),
      ],
    );
  }
}

// ─── Month Header ─────────────────────────────────────────────────────────────

class _MonthHeader extends StatelessWidget {
  final _MonthGroup group;
  final String baseCurrency;
  final VoidCallback onPostAll;

  const _MonthHeader({
    required this.group,
    required this.baseCurrency,
    required this.onPostAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: SectionHeader(
              group.label,
              trailing: Text(
                formatAmount(group.total, currency: baseCurrency),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ts(context),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Tappable(
            onTap: onPostAll,
            borderRadius: BorderRadius.circular(RadiusTokens.pill),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(RadiusTokens.pill),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_rounded,
                      size: 14, color: AppColors.accent),
                  const SizedBox(width: 4),
                  Text(
                    S.of(context).plannedPostAll,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Planned Payment Card ─────────────────────────────────────────────────────

class _PlannedCard extends StatelessWidget {
  final _PlannedItem item;
  final String baseCurrency;
  final VoidCallback onPost;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _PlannedCard({
    required this.item,
    required this.baseCurrency,
    required this.onPost,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tx = item.tx;

    final typeIcon = switch (tx.type) {
      'income' => Icons.arrow_downward_rounded,
      'transfer' => Icons.swap_horiz_rounded,
      _ => Icons.arrow_upward_rounded,
    };

    final typeColor = switch (tx.type) {
      'income' => AppColors.healthy,
      'transfer' => AppColors.accent,
      _ => AppColors.overspent,
    };

    final title = tx.note.isNotEmpty ? tx.note : _typeLabel(context, tx.type);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: ValueKey(tx.id),
        background: Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsetsDirectional.only(start: 20),
          decoration: BoxDecoration(
            color: AppColors.healthy.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(CardTokens.radius),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle_rounded,
                  color: AppColors.healthy, size: 22),
              const SizedBox(width: 8),
              Text(
                S.of(context).plannedPost,
                style: TextStyle(
                  color: AppColors.healthy,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        secondaryBackground: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsetsDirectional.only(end: 20),
          decoration: BoxDecoration(
            color: AppColors.overspent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(CardTokens.radius),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                S.of(context).commonDelete,
                style: TextStyle(
                  color: AppColors.overspent,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.delete_rounded,
                  color: AppColors.overspent, size: 22),
            ],
          ),
        ),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            onPost();
            return false; // Don't actually dismiss; _load() rebuilds
          } else {
            onDelete();
            return false;
          }
        },
        child: Tappable(
          onTap: onTap,
          borderRadius: BorderRadius.circular(CardTokens.radius),
          child: Container(
            padding: CardTokens.padding,
            decoration: BoxDecoration(
              color: AppColors.sf(context),
              borderRadius: BorderRadius.circular(CardTokens.radius),
              border: Border.all(color: AppColors.bd(context)),
            ),
            child: Row(
              children: [
                // Type icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(typeIcon, size: 18, color: typeColor),
                ),
                const SizedBox(width: 12),

                // Title + meta
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: TypographyTokens.cardTitleSize,
                          fontWeight: TypographyTokens.cardTitleWeight,
                          color: AppColors.tp(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (item.categoryName != null) ...[
                            Icon(Icons.label_rounded,
                                size: 12, color: AppColors.th(context)),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                item.categoryName!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.ts(context),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Icon(Icons.account_balance_wallet_rounded,
                              size: 12, color: AppColors.th(context)),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              item.accountName,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.ts(context),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Amount + date
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatSignedAmount(
                        item.lineAmount,
                        currency: item.lineCurrency,
                        type: tx.type,
                      ),
                      style: TextStyle(
                        fontSize: TypographyTokens.amountRegularSize,
                        fontWeight: TypographyTokens.amountRegularWeight,
                        color: typeColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatDate(tx.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.th(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _typeLabel(BuildContext context, String type) {
    final tr = S.of(context);
    return switch (type) {
      'income' => tr.typeIncome,
      'transfer' => tr.typeTransfer,
      _ => tr.typeExpense,
    };
  }
}
