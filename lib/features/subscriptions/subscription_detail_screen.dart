import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers/database_provider.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/design_tokens.dart';
import '../../shared/utils/format_number.dart';
import '../../shared/widgets/category_icon.dart';
import '../recurring/recurring_screen.dart' show EditRecurringSheet;

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
          'SELECT * FROM transactions WHERE household_id = ? AND (note LIKE ? OR note = ?) AND type = ? ORDER BY created_at DESC LIMIT 20',
          variables: [
            drift.Variable.withString(householdId),
            drift.Variable.withString('%$title%'),
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
        });
      }
    } catch (e, st) {
      debugPrint('[SubscriptionDetail] Error loading: $e\n$st');
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

  String _frequencySuffix(String frequency, int interval) {
    if (interval == 1) {
      return switch (frequency) {
        'daily' => '/day',
        'weekly' => '/week',
        'monthly' => '/month',
        'yearly' => '/year',
        _ => '/$frequency',
      };
    }
    return switch (frequency) {
      'daily' => '/$interval days',
      'weekly' => '/$interval weeks',
      'monthly' => '/$interval months',
      'yearly' => '/$interval years',
      _ => '/$interval $frequency',
    };
  }

  double _monthlyEquivalent(double amount, String frequency, int interval) {
    return switch (frequency) {
      'daily' => amount * (30.0 / interval),
      'weekly' => amount * (52.0 / (12.0 * interval)),
      'monthly' => amount / interval,
      'yearly' => amount / (12.0 * interval),
      _ => amount,
    };
  }

  /// Calculate upcoming billing dates from nextDueDate
  List<DateTime> _upcomingDates(
      DateTime nextDue, String frequency, int interval, int count) {
    final dates = <DateTime>[];
    var current = nextDue;
    for (var i = 0; i < count; i++) {
      dates.add(current);
      current = _advanceDate(current, frequency, interval);
    }
    return dates;
  }

  DateTime _advanceDate(DateTime d, String frequency, int interval) {
    return switch (frequency) {
      'daily' => d.add(Duration(days: interval)),
      'weekly' => d.add(Duration(days: 7 * interval)),
      'monthly' => DateTime(d.year, d.month + interval, d.day),
      'yearly' => DateTime(d.year + interval, d.month, d.day),
      _ => d.add(Duration(days: 30 * interval)),
    };
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
    final enabled = _sub!['enabled'] == 1 || _sub!['enabled'] == true;
    final endDate = _parseDate(_sub!['end_date']);
    if (!enabled || (endDate != null && endDate.isBefore(DateTime.now()))) {
      return 'cancelled';
    }
    if (endDate != null && endDate.difference(DateTime.now()).inDays <= 30) {
      return 'ending_soon';
    }
    return 'active';
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
      'SELECT COUNT(*) as cnt FROM transactions WHERE household_id = ? AND (note LIKE ? OR note = ?) AND created_at > ?',
      variables: [
        drift.Variable.withString(householdId),
        drift.Variable.withString('%$title%'),
        drift.Variable.withString(title),
        drift.Variable.withDateTime(picked),
      ],
    ).get();
    final futureCount = (futureRows.firstOrNull?.data['cnt'] as int?) ?? 0;

    if (!mounted) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel subscription'),
        content: Text(
          futureCount > 0
              ? 'This will cancel future billing and remove $futureCount transaction${futureCount == 1 ? '' : 's'} after ${DateFormat.yMMMd().format(picked)}.'
              : 'This will set the cancellation date to ${DateFormat.yMMMd().format(picked)}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Back'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    // Set end_date on the recurring transaction
    await db.customStatement(
      'UPDATE recurring_transactions SET end_date = ? WHERE id = ?',
      [picked.millisecondsSinceEpoch ~/ 1000, widget.subscriptionId],
    );

    // Delete transactions generated AFTER the cancellation date
    if (futureCount > 0) {
      await db.customStatement(
        'DELETE FROM transactions WHERE household_id = ? AND (note LIKE ? OR note = ?) AND created_at > ?',
        [householdId, '%$title%', title, picked.millisecondsSinceEpoch ~/ 1000],
      );
    }

    _load();
  }

  Future<void> _togglePause() async {
    if (_sub == null) return;
    final currentlyEnabled =
        _sub!['enabled'] == 1 || _sub!['enabled'] == true;
    final db = ref.read(databaseProvider);
    await db.customStatement(
      'UPDATE recurring_transactions SET enabled = ? WHERE id = ?',
      [currentlyEnabled ? 0 : 1, widget.subscriptionId],
    );
    _load();
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
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 48, color: AppColors.overspent),
                const SizedBox(height: 12),
                const Text('Could not load subscription'),
                const SizedBox(height: 8),
                Text(_error!,
                    style: TextStyle(fontSize: 12, color: AppColors.th(context)),
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: () {
                    setState(() {
                      _loading = true;
                      _error = null;
                    });
                    _load();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_sub == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Subscription not found')),
      );
    }

    final sub = _sub!;
    final title = sub['title']?.toString() ?? 'Untitled';
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

    final monthlyAmount = _monthlyEquivalent(amount, frequency, interval);
    final annualCost = monthlyAmount * 12;

    // Calculate total paid (rough: monthly * months since created)
    double totalPaid = 0;
    if (createdAt != null) {
      final monthsSince = DateTime.now().difference(createdAt).inDays / 30.0;
      totalPaid = monthlyAmount * monthsSince;
    }

    final catColor = _categoryColor != null
        ? Color(int.parse(_categoryColor!.replaceFirst('#', '0xFF')))
        : AppColors.accent;

    final statusDotColor = switch (status) {
      'active' => AppColors.healthy,
      'ending_soon' => AppColors.caution,
      'cancelled' => AppColors.overspent,
      _ => AppColors.healthy,
    };

    final statusLabel = switch (status) {
      'active' => 'Active',
      'ending_soon' => 'Ending soon',
      'cancelled' => 'Cancelled',
      _ => '',
    };

    // Upcoming dates
    final upcoming = nextDue != null && status != 'cancelled'
        ? _upcomingDates(nextDue, frequency, interval, 3)
        : <DateTime>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => _editSubscription(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // ── Amount + frequency header ──
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.sf(context),
              borderRadius: BorderRadius.circular(CardTokens.radius),
              border: Border.all(color: AppColors.bd(context)),
            ),
            child: Column(
              children: [
                CategoryIcon(
                  categoryName: _categoryName ?? title,
                  emoji: _categoryIcon,
                  color: catColor,
                  size: 56,
                ),
                const SizedBox(height: 12),
                Text(
                  '${formatAmount(amount, currency: currency)}${_frequencySuffix(frequency, interval)}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.tp(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Annual cost: ${formatAmount(annualCost, currency: currency)}',
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.sf(context),
              borderRadius: BorderRadius.circular(CardTokens.radius),
              border: Border.all(color: AppColors.bd(context)),
            ),
            child: Column(
              children: [
                _DetailRow(
                  label: 'Status',
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
                    label: 'Active since',
                    value: DateFormat.yMMMd().format(createdAt),
                  ),
                if (nextDue != null)
                  _DetailRow(
                    label: 'Next billing',
                    value: DateFormat.yMMMd().format(nextDue),
                  ),
                if (endDate != null)
                  _DetailRow(
                    label: 'Ends on',
                    value: DateFormat.yMMMd().format(endDate),
                  ),
                _DetailRow(
                  label: 'Total paid (est.)',
                  value: formatAmount(totalPaid, currency: currency),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Price History ──
          if (priceHistory.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
              child: Text(
                'PRICE HISTORY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: AppColors.ts(context),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.sf(context),
                borderRadius: BorderRadius.circular(CardTokens.radius),
                border: Border.all(color: AppColors.bd(context)),
              ),
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
                            '${formatAmount((priceHistory[i]['amount'] as num).toDouble(), currency: currency)}${_frequencySuffix(frequency, interval)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.tp(context),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${priceHistory[i]['from'] ?? ''}${i < priceHistory.length - 1 ? ' - ${priceHistory[i + 1]['from'] ?? ''}' : ' - present'}',
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
                  icon: const Icon(Icons.event_rounded, size: 18),
                  label: Text(endDate != null
                      ? 'Change Cancel Date'
                      : 'Set Cancellation Date'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.overspent,
                    side: const BorderSide(color: AppColors.overspent),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _togglePause,
                  icon: Icon(
                    enabled
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    size: 18,
                  ),
                  label: Text(enabled ? 'Pause' : 'Resume'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: const BorderSide(color: AppColors.accent),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Past Transactions ──
          if (_pastTransactions.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
              child: Text(
                'PAST TRANSACTIONS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: AppColors.ts(context),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: AppColors.sf(context),
                borderRadius: BorderRadius.circular(CardTokens.radius),
                border: Border.all(color: AppColors.bd(context)),
              ),
              child: Column(
                children: [
                  for (final tx in _pastTransactions)
                    _PastTransactionTile(tx: tx, parseDate: _parseDate),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // ── Upcoming ──
          if (upcoming.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
              child: Text(
                'UPCOMING',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: AppColors.ts(context),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: AppColors.sf(context),
                borderRadius: BorderRadius.circular(CardTokens.radius),
                border: Border.all(color: AppColors.bd(context)),
              ),
              child: Column(
                children: [
                  for (final date in upcoming)
                    ListTile(
                      dense: true,
                      leading: Icon(Icons.schedule_rounded,
                          size: 18, color: AppColors.th(context)),
                      title: Text(
                        DateFormat.yMMMd().format(date),
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.tp(context),
                        ),
                      ),
                      trailing: Text(
                        '-${formatAmount(amount, currency: currency)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.ts(context),
                        ),
                      ),
                      subtitle: Text(
                        'scheduled',
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
    );
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
  final DateTime? Function(dynamic) parseDate;

  const _PastTransactionTile({required this.tx, required this.parseDate});

  @override
  Widget build(BuildContext context) {
    final date = parseDate(tx['created_at']);
    final amount = (tx['amount'] as num?)?.toDouble() ?? 0;
    final currency = tx['currency'] as String?;

    return ListTile(
      dense: true,
      leading: Icon(Icons.check_circle_rounded,
          size: 18, color: AppColors.healthy),
      title: Text(
        date != null ? DateFormat.yMMMd().format(date) : '—',
        style: TextStyle(fontSize: 14, color: AppColors.tp(context)),
      ),
      trailing: Text(
        '-${formatAmount(amount, currency: currency)}',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.tp(context),
        ),
      ),
    );
  }
}
