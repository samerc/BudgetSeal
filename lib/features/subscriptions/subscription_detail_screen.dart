import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/database/app_database.dart';
import '../../core/engine/recurring_engine.dart' show advanceRecurringDate;
import '../../core/providers/database_provider.dart';
import '../../core/providers/date_format_provider.dart';
import '../../core/providers/engine_provider.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/design_tokens.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/utils/format_number.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/category_icon.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_retry.dart';
import '../recurring/recurring_format.dart';
import '../recurring/recurring_screen.dart' show EditRecurringSheet;
import '../../l10n/generated/app_localizations.dart';
import '../../shared/theme/app_icons.dart';

class SubscriptionDetailScreen extends ConsumerStatefulWidget {
  final String subscriptionId;
  const SubscriptionDetailScreen({super.key, required this.subscriptionId});

  @override
  ConsumerState<SubscriptionDetailScreen> createState() =>
      _SubscriptionDetailScreenState();
}

class _SubscriptionDetailScreenState
    extends ConsumerState<SubscriptionDetailScreen> {
  Map<String, dynamic>? _sub;
  String? _categoryName;
  String? _categoryIcon;
  String? _categoryColor;
  List<Map<String, dynamic>> _pastTransactions = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final db = ref.read(databaseProvider);

      // Load subscription
      final rows = await db.customSelect(
        'SELECT * FROM recurring_transactions WHERE id = ?',
        variables: [drift.Variable.withString(widget.subscriptionId)],
      ).get();

      if (rows.isEmpty) {
        debugPrint(
            '[SubscriptionDetail] No recurring_transaction found for id=${widget.subscriptionId}');
        if (mounted) setState(() => _loading = false);
        return;
      }

      final sub = rows.first.data;

      // Load category
      String? catName;
      String? catIcon;
      String? catColor;
      final catId = sub['category_id']?.toString();
      if (catId != null) {
        final catRows = await db.customSelect(
          'SELECT name, icon, color_hex FROM categories WHERE id = ?',
          variables: [drift.Variable.withString(catId)],
        ).get();
        if (catRows.isNotEmpty) {
          catName = catRows.first.data['name']?.toString();
          catIcon = catRows.first.data['icon']?.toString();
          catColor = catRows.first.data['color_hex']?.toString();
        }
      }

      // Load past transactions matching this subscription by title and type
      final title = sub['title']?.toString() ?? '';
      final subType = sub['type']?.toString() ?? 'expense';
      final householdId = sub['household_id']?.toString() ?? '';

      List<Map<String, dynamic>> pastData = [];
      if (householdId.isNotEmpty && title.isNotEmpty) {
        final pastRows = await db.customSelect(
          // Each payment's first line: its amount in the account's
          // currency (the transaction's own amount is in the base currency).
          'SELECT t.id, t.type, t.created_at, '
          '(SELECT l.amount FROM transaction_lines l WHERE l.transaction_id = t.id LIMIT 1) AS line_amount, '
          '(SELECT l.currency FROM transaction_lines l WHERE l.transaction_id = t.id LIMIT 1) AS line_currency '
          'FROM transactions t WHERE t.household_id = ? AND t.deleted = 0 AND t.status IS NULL AND (t.note LIKE ? ESCAPE \'\\\' OR t.note = ?) AND t.type = ? ORDER BY t.created_at DESC LIMIT 20',
          variables: [
            drift.Variable.withString(householdId),
            drift.Variable.withString('%${title.replaceAll('\\', '\\\\').replaceAll('%', '\\%').replaceAll('_', '\\_')}%'),
            drift.Variable.withString(title),
            drift.Variable.withString(subType),
          ],
        ).get();
        pastData = pastRows.map((r) => r.data).toList();
      }

      debugPrint(
          '[SubscriptionDetail] Loaded sub id=${widget.subscriptionId}, title="$title", pastTx=${pastData.length}');

      if (mounted) {
        setState(() {
          _sub = sub;
          _categoryName = catName;
          _categoryIcon = catIcon;
          _categoryColor = catColor;
          _pastTransactions = pastData;
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      debugPrint('[SubscriptionDetail] Error loading: $e');
      if (mounted) {
        setState(() {
          _loading = false;
          _error = '$e';
        });
      }
    }
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value * 1000);
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  /// Calculate upcoming billing dates from nextDueDate
  List<DateTime> _upcomingDates(
      DateTime nextDue, String frequency, int interval, int count,
      {int? anchorDay}) {
    final dates = <DateTime>[];
    var current = nextDue;
    for (var i = 0; i < count; i++) {
      dates.add(current);
      current = advanceRecurringDate(current, frequency, interval,
          anchorDay: anchorDay);
    }
    return dates;
  }

  /// Parse price history JSON
  List<Map<String, dynamic>> _parsePriceHistory(String? json) {
    if (json == null || json.isEmpty) return [];
    try {
      final list = jsonDecode(json) as List;
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  /// Determine subscription status
  String _status() {
    if (_sub == null) return 'active';
    return subscriptionStatus(
        enabled: _sub!['enabled'] == 1 || _sub!['enabled'] == true,
        endDate: _parseDate(_sub!['end_date']));
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _setCancellationDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked == null || _sub == null) return;

    final db = ref.read(databaseProvider);
    final title = _sub!['title']?.toString() ?? '';
    final householdId = _sub!['household_id']?.toString() ?? '';
    if (householdId.isEmpty) return;

    // Count transactions AFTER the picked cancellation date
    final futureRows = await db.customSelect(
      'SELECT COUNT(*) as cnt FROM transactions WHERE household_id = ? AND deleted = 0 AND status IS NULL AND (note LIKE ? ESCAPE \'\\\' OR note = ?) AND created_at > ?',
      variables: [
        drift.Variable.withString(householdId),
        drift.Variable.withString('%${title.replaceAll('\\', '\\\\').replaceAll('%', '\\%').replaceAll('_', '\\_')}%'),
        drift.Variable.withString(title),
        drift.Variable.withDateTime(picked),
      ],
    ).get();
    final futureCount = (futureRows.firstOrNull?.data['cnt'] as int?) ?? 0;

    if (!mounted) return;

    // Show confirmation dialog
    final tr = S.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: tr.subCancelConfirmTitle,
      message: futureCount > 0
          ? tr.subCancelBodyWithTx(futureCount, formatDate(picked))
          : tr.subCancelBodyNoTx(formatDate(picked)),
      confirmLabel: tr.commonConfirm,
      // "Cancel" would read as "cancel the subscription" here.
      cancelLabel: tr.commonBack,
      destructive: futureCount > 0,
    );
    if (!confirmed || !mounted) return;

    try {
    // Set end_date on the recurring transaction (moves last_modified so the
    // change syncs).
    await (db.update(db.recurringTransactions)
          ..where((r) => r.id.equals(widget.subscriptionId)))
        .write(RecurringTransactionsCompanion(
      endDate: drift.Value(picked),
      lastModified: drift.Value(DateTime.now()),
    ));

    // Delete transactions generated AFTER the cancellation date (with ledger cleanup)
    if (futureCount > 0) {
      final engine = ref.read(allocationEngineProvider);
      final futureTxRows = await db.customSelect(
        'SELECT id FROM transactions WHERE household_id = ? AND deleted = 0 AND status IS NULL AND (note LIKE ? ESCAPE \'\\\' OR note = ?) AND created_at > ?',
        variables: [
          drift.Variable.withString(householdId),
          drift.Variable.withString('%${title.replaceAll('\\', '\\\\').replaceAll('%', '\\%').replaceAll('_', '\\_')}%'),
          drift.Variable.withString(title),
          drift.Variable.withDateTime(picked),
        ],
      ).get();
      for (final row in futureTxRows) {
        final txId = row.data['id'] as String?;
        if (txId != null) await engine.deleteTransaction(txId);
      }
    }
    if (mounted) _snack(tr.subCancelDateSet);
    } catch (e) {
      debugPrint('[SubscriptionDetail] Set cancellation failed: $e');
      if (mounted) _snack(tr.subCouldNotUpdate);
    }

    _load();
  }

  /// Pause or resume through the recurring engine (moves last_modified).
  Future<void> _togglePause() async {
    if (_sub == null) return;
    final tr = S.of(context);
    final enabled = !(_sub!['enabled'] == 1 || _sub!['enabled'] == true);
    try {
      await ref
          .read(recurringEngineProvider)
          .toggleEnabled(widget.subscriptionId, enabled);
      if (mounted) _snack(enabled ? tr.subResumedSnack : tr.subPausedSnack);
    } catch (e) {
      debugPrint('[SubscriptionDetail] Toggle failed: $e');
      if (mounted) _snack(tr.subCouldNotUpdate);
    }
    _load();
  }

  /// Soft-deletes the subscription the same way Recurring deletes an item
  /// (RecurringEngine.delete); the transactions it already posted stay.
  Future<void> _delete() async {
    final tr = S.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: tr.subDeleteTitle,
      message: tr.subDeleteBody,
      confirmLabel: tr.commonDelete,
    );
    if (!confirmed || !mounted) return;
    try {
      await ref.read(recurringEngineProvider).delete(widget.subscriptionId);
      if (!mounted) return;
      _snack(tr.subDeleted);
      context.pop();
    } catch (e) {
      debugPrint('[SubscriptionDetail] Delete failed: $e');
      if (mounted) _snack(tr.subDeleteFailed);
    }
  }

  Future<void> _editSubscription() async {
    final db = ref.read(databaseProvider);
    // Load the typed RecurringTransaction object for the edit sheet
    final item = await (db.select(db.recurringTransactions)
          ..where((r) => r.id.equals(widget.subscriptionId)))
        .getSingleOrNull();
    if (item == null || !mounted) return;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditRecurringSheet(item: item),
    );
    if (result == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(),
        body: ErrorRetry(
          message: S.of(context).subDetailError,
          details: _error,
          onRetry: () {
            setState(() {
              _loading = true;
              _error = null;
            });
            _load();
          },
        ),
      );
    }

    if (_sub == null) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState(
          icon: AppIcons.playCircle,
          title: S.of(context).subDetailNotFound,
        ),
      );
    }

    final sub = _sub!;
    final title = sub['title']?.toString() ?? S.of(context).subUntitled;
    final amount = (sub['amount'] as num?)?.toDouble() ?? 0;
    final currency = sub['currency']?.toString();
    final frequency = sub['frequency']?.toString() ?? 'monthly';
    final interval = (sub['interval'] is int)
        ? sub['interval'] as int
        : int.tryParse(sub['interval']?.toString() ?? '') ?? 1;
    final nextDue = _parseDate(sub['next_due_date']);
    final createdAt = _parseDate(sub['created_at']);
    final endDate = _parseDate(sub['end_date']);
    final priceHistoryJson = sub['price_history'] as String?;
    final priceHistory = _parsePriceHistory(priceHistoryJson);
    final status = _status();
    final enabled = sub['enabled'] == 1 || sub['enabled'] == true;

    final monthlyAmount =
        recurringMonthlyEquivalent(amount, frequency, interval);
    final subType = sub['type']?.toString() ?? 'expense';
    final suffix = recurringPriceSuffix(S.of(context), frequency, interval);
    final annualCost = monthlyAmount * 12;

    // Calculate total paid (rough: monthly * months since created)
    double totalPaid = 0;
    if (createdAt != null) {
      final monthsSince = DateTime.now().difference(createdAt).inDays / 30.0;
      totalPaid = monthlyAmount * monthsSince;
    }

    final catColor = _categoryColor != null
        ? AppColors.fromHex(_categoryColor!)
        : AppColors.accent;

    final statusDotColor = subscriptionStatusColor(context, status);

    final tr = S.of(context);
    final statusLabel = subscriptionStatusLabel(tr, status);

    // Upcoming dates
    final upcoming = nextDue != null && status != 'cancelled' && status != 'paused'
        ? _upcomingDates(nextDue, frequency, interval, 3,
            anchorDay: sub['anchor_day'] as int?)
        : <DateTime>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: tr.commonEdit,
            icon: const Icon(AppIcons.pencilSimple),
            onPressed: () => _editSubscription(),
          ),
          IconButton(
            tooltip: tr.commonDelete,
            icon: const Icon(AppIcons.trash),
            onPressed: _delete,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // ── Amount + frequency header ──
          AppCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                CategoryIcon(
                  categoryName: _categoryName ?? title,
                  emoji: _categoryIcon,
                  color: catColor,
                  size: CategoryIconTokens.heroSize,
                  circular: true,
                ),
                const SizedBox(height: 12),
                // Large amounts shrink to one line instead of wrapping.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.center,
                  child: Text(
                    '${formatAmount(amount, currency: currency)}$suffix',
                    style: TextStyle(
                      fontSize: TypographyTokens.amountLargeSize,
                      fontFamily: TypographyTokens.displayFamily,
                      fontWeight: FontWeight.w800,
                      color: AppColors.tp(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tr.subDetailAnnualCost(formatAmount(annualCost, currency: currency)),
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.ts(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Status details ──
          AppCard(
            child: Column(
              children: [
                _DetailRow(
                  label: tr.subDetailStatus,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(statusLabel,
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.tp(context))),
                      const SizedBox(width: 6),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: statusDotColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
                if (createdAt != null)
                  _DetailRow(
                    label: tr.subDetailActiveSince,
                    value: formatDate(createdAt),
                  ),
                if (nextDue != null)
                  _DetailRow(
                    label: tr.subDetailNextBilling,
                    value: formatDate(nextDue),
                  ),
                if (endDate != null)
                  _DetailRow(
                    label: tr.subDetailEndsOn,
                    value: formatDate(endDate),
                  ),
                _DetailRow(
                  label: tr.subDetailTotalPaid,
                  value: formatAmount(totalPaid, currency: currency),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Price History ──
          if (priceHistory.isNotEmpty) ...[
            SectionHeader(tr.subDetailPriceHistory,
                padding: const EdgeInsets.fromLTRB(4, 8, 4, 8)),
            AppCard(
              child: Column(
                children: [
                  for (var i = 0; i < priceHistory.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: i == priceHistory.length - 1
                                  ? AppColors.accent
                                  : AppColors.th(context),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${formatAmount((priceHistory[i]['amount'] as num).toDouble(), currency: currency)}$suffix',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.tp(context),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${_historyDate(priceHistory[i]['from'])} – ${i < priceHistory.length - 1 ? _historyDate(priceHistory[i + 1]['from']) : tr.subDetailPresent}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.ts(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── Action buttons ──
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _setCancellationDate,
                  icon: const Icon(AppIcons.calendarDots, size: 18),
                  label: Text(endDate != null
                      ? tr.subDetailChangeCancel
                      : tr.subDetailSetCancel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _togglePause,
                  icon: Icon(
                    enabled
                        ? AppIcons.pause
                        : AppIcons.play,
                    size: 18,
                  ),
                  label: Text(enabled ? tr.subPause : tr.subResume),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Past Transactions ──
          if (_pastTransactions.isNotEmpty) ...[
            SectionHeader(tr.subDetailPastTx,
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 8)),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final tx in _pastTransactions)
                    _PastTransactionTile(
                        tx: tx, type: subType, parseDate: _parseDate),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // ── Upcoming ──
          if (upcoming.isNotEmpty) ...[
            SectionHeader(tr.subDetailUpcoming,
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 8)),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final date in upcoming)
                    ListTile(
                      dense: true,
                      leading: Icon(AppIcons.clock,
                          size: 18, color: AppColors.th(context)),
                      title: Text(
                        formatDate(date),
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.tp(context),
                        ),
                      ),
                      trailing: Text(
                        formatSignedAmount(amount,
                            currency: currency ?? '', type: subType),
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.ts(context),
                        ),
                      ),
                      subtitle: Text(
                        tr.subDetailScheduled,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.th(context),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
      ),
    );
  }

  /// Price-history dates are stored as ISO strings (yyyy-MM-dd).
  String _historyDate(dynamic raw) {
    final d = raw is String ? DateTime.tryParse(raw) : null;
    return d != null ? formatDate(d) : (raw?.toString() ?? '');
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? child;

  const _DetailRow({required this.label, this.value, this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(fontSize: 14, color: AppColors.ts(context))),
          child ??
              Text(value ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.tp(context),
                  )),
        ],
      ),
    );
  }
}

class _PastTransactionTile extends StatelessWidget {
  final Map<String, dynamic> tx;
  final String type;
  final DateTime? Function(dynamic) parseDate;

  const _PastTransactionTile(
      {required this.tx, required this.type, required this.parseDate});

  @override
  Widget build(BuildContext context) {
    final date = parseDate(tx['created_at']);
    // The line's amount in the account's currency, not the base-currency total.
    final amount = (tx['line_amount'] as num?)?.toDouble() ?? 0;
    final currency = tx['line_currency'] as String? ?? '';

    return ListTile(
      dense: true,
      leading: Icon(AppIcons.checkCircleFill,
          size: 18, color: AppColors.healthy),
      title: Text(
        date != null ? formatDate(date) : '—',
        style: TextStyle(fontSize: 14, color: AppColors.tp(context)),
      ),
      trailing: Text(
        formatSignedAmount(amount, currency: currency, type: type),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.tp(context),
        ),
      ),
    );
  }
}
