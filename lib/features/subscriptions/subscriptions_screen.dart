import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/providers/database_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/utils/format_number.dart';
import '../../shared/widgets/category_icon.dart';
import '../../shared/widgets/empty_state.dart';

class SubscriptionsScreen extends ConsumerStatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  ConsumerState<SubscriptionsScreen> createState() =>
      _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends ConsumerState<SubscriptionsScreen> {
  List<Map<String, dynamic>> _subs = [];
  Map<String, String> _categoryNames = {};
  Map<String, String> _categoryIcons = {};
  Map<String, String> _categoryColors = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null) return;
    final db = ref.read(databaseProvider);

    final rows = await db.customSelect(
      'SELECT * FROM recurring_transactions WHERE household_id = ? AND is_subscription = 1 ORDER BY title ASC',
      variables: [drift.Variable.withString(householdId)],
    ).get();

    final subs = rows.map((r) => r.data).toList();

    // Load categories for icons
    final cats = await (db.select(db.categories)
          ..where((c) => c.householdId.equals(householdId)))
        .get();
    final catNames = <String, String>{};
    final catIcons = <String, String>{};
    final catColors = <String, String>{};
    for (final c in cats) {
      catNames[c.id] = c.name;
      catIcons[c.id] = c.icon;
      catColors[c.id] = c.colorHex;
    }

    if (mounted) {
      setState(() {
        _subs = subs;
        _categoryNames = catNames;
        _categoryIcons = catIcons;
        _categoryColors = catColors;
        _loading = false;
      });
    }
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

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value * 1000);
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  /// Determine subscription status: 'active', 'cancelled', or 'ending_soon'
  String _status(Map<String, dynamic> sub) {
    final enabled = sub['enabled'] == 1 || sub['enabled'] == true;
    final endDate = _parseDate(sub['end_date']);
    if (!enabled || (endDate != null && endDate.isBefore(DateTime.now()))) {
      return 'cancelled';
    }
    if (endDate != null &&
        endDate.difference(DateTime.now()).inDays <= 30) {
      return 'ending_soon';
    }
    return 'active';
  }

  @override
  Widget build(BuildContext context) {
    final monthlyTotal = _subs.fold<double>(0.0, (sum, s) {
      final status = _status(s);
      if (status == 'cancelled') return sum;
      final amount = (s['amount'] as num?)?.toDouble() ?? 0;
      final freq = s['frequency'] as String? ?? 'monthly';
      final interval = (s['interval'] as int?) ?? 1;
      return sum + _monthlyEquivalent(amount, freq, interval);
    });
    final annualTotal = monthlyTotal * 12;

    return Scaffold(
      appBar: AppBar(title: const Text('Subscriptions')),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add subscription',
        onPressed: () async {
          // Open recurring screen — user creates a recurring + marks as subscription
          context.push('/recurring');
        },
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _subs.isEmpty
              ? const EmptyState(
                  icon: Icons.subscriptions_rounded,
                  title: 'No subscriptions',
                  subtitle:
                      'Add a recurring transaction and mark it as a subscription',
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    children: [
                      // ── Annual total card ──
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.accent, AppColors.primaryLight],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'You spend',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${formatAmount(annualTotal)}/year',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'on subscriptions',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${formatAmount(monthlyTotal)}/month',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Subscription list ──
                      ..._subs.map((sub) => _SubscriptionTile(
                            sub: sub,
                            categoryName: _categoryNames[sub['category_id']],
                            categoryIcon: _categoryIcons[sub['category_id']],
                            categoryColor: _categoryColors[sub['category_id']],
                            frequencySuffix: _frequencySuffix(
                              sub['frequency'] as String? ?? 'monthly',
                              (sub['interval'] as int?) ?? 1,
                            ),
                            status: _status(sub),
                            parseDate: _parseDate,
                            onTap: () {
                              final id = sub['id'] as String;
                              context.push('/subscriptions/$id');
                            },
                          )),
                    ],
                  ),
                ),
    );
  }
}

class _SubscriptionTile extends StatelessWidget {
  final Map<String, dynamic> sub;
  final String? categoryName;
  final String? categoryIcon;
  final String? categoryColor;
  final String frequencySuffix;
  final String status;
  final DateTime? Function(dynamic) parseDate;
  final VoidCallback onTap;

  const _SubscriptionTile({
    required this.sub,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
    required this.frequencySuffix,
    required this.status,
    required this.parseDate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final title = sub['title'] as String? ?? 'Untitled';
    final amount = (sub['amount'] as num?)?.toDouble() ?? 0;
    final currency = sub['currency'] as String?;
    final nextDue = parseDate(sub['next_due_date']);
    final isCancelled = status == 'cancelled';

    final catColor = categoryColor != null
        ? Color(int.parse(categoryColor!.replaceFirst('#', '0xFF')))
        : AppColors.accent;

    final statusDotColor = switch (status) {
      'active' => AppColors.healthy,
      'ending_soon' => AppColors.caution,
      'cancelled' => AppColors.overspent,
      _ => AppColors.healthy,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: CategoryIcon(
          categoryName: categoryName ?? title,
          emoji: categoryIcon,
          color: catColor,
          size: 44,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: AppColors.tp(context),
            decoration: isCancelled ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: nextDue != null
            ? Text(
                'Next: ${DateFormat.yMMMd().format(nextDue)}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.ts(context),
                ),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${formatAmount(amount, currency: currency)}$frequencySuffix',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: isCancelled
                        ? AppColors.th(context)
                        : AppColors.tp(context),
                    decoration:
                        isCancelled ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusDotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      switch (status) {
                        'active' => 'Active',
                        'ending_soon' => 'Ending soon',
                        'cancelled' => 'Cancelled',
                        _ => '',
                      },
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.ts(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
