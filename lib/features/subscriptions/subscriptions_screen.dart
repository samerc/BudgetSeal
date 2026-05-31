import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/database_provider.dart';
import '../../core/providers/date_format_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/design_tokens.dart';
import '../../shared/utils/format_number.dart';
import '../../shared/widgets/category_icon.dart';
import '../../shared/widgets/empty_state.dart';
import '../recurring/recurring_screen.dart' show AddRecurringSheet;
import '../../l10n/generated/app_localizations.dart';

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
    try {
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
    } catch (e) {
      debugPrint('[Subscriptions] Error loading: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Toggle enabled/disabled state for a subscription (Bug 2 fix)
  Future<void> _toggleEnabled(Map<String, dynamic> sub) async {
    try {
      final db = ref.read(databaseProvider);
      final subId = sub['id']?.toString() ?? '';
      if (subId.isEmpty) return;
      final currentlyEnabled = sub['enabled'] == 1 || sub['enabled'] == true;
      final enabled = !currentlyEnabled;
      await db.customStatement(
        'UPDATE recurring_transactions SET enabled = ? WHERE id = ?',
        [enabled ? 1 : 0, subId],
      );
      _load();
    } catch (e) {
      debugPrint('[Subscriptions] Error toggling: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).subCouldNotUpdate),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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
    final tr = S.of(context);
    if (interval == 1) {
      return switch (frequency) {
        'daily' => tr.subFreqDay,
        'weekly' => tr.subFreqWeek,
        'monthly' => tr.subFreqMonth,
        'yearly' => tr.subFreqYear,
        _ => '/$frequency',
      };
    }
    return switch (frequency) {
      'daily' => tr.subFreqDays(interval),
      'weekly' => tr.subFreqWeeks(interval),
      'monthly' => tr.subFreqMonths(interval),
      'yearly' => tr.subFreqYears(interval),
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

  String? _statusFilter; // null = all, 'active', 'cancelled'
  bool _showOtherCurrencies = false;

  List<Map<String, dynamic>> get _filtered {
    if (_statusFilter == null) return _subs;
    return _subs.where((s) => _status(s) == _statusFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final activeCount =
        _subs.where((s) => _status(s) == 'active').length;
    final cancelledCount =
        _subs.where((s) => _status(s) == 'cancelled').length;

    // Group monthly totals by currency to avoid mixing
    final baseCurrency = ref.watch(householdProvider).value?.baseCurrency ?? 'USD';
    final monthlyByCurrency = <String, double>{};
    for (final s in _subs) {
      if (_status(s) == 'cancelled') continue;
      final amount = (s['amount'] as num?)?.toDouble() ?? 0;
      final currency = s['currency'] as String? ?? baseCurrency;
      final freq = s['frequency'] as String? ?? 'monthly';
      final interval = (s['interval'] as int?) ?? 1;
      monthlyByCurrency[currency] =
          (monthlyByCurrency[currency] ?? 0) + _monthlyEquivalent(amount, freq, interval);
    }
    final monthlyTotal = monthlyByCurrency[baseCurrency] ?? 0.0;
    final annualTotal = monthlyTotal * 12;
    final hasOtherCurrencies = monthlyByCurrency.keys
        .any((c) => c != baseCurrency && (monthlyByCurrency[c] ?? 0) > 0);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        tooltip: S.of(context).subAddTooltip,
        onPressed: () async {
          final result = await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            isDismissible: true,
            enableDrag: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const AddRecurringSheet(forceSubscription: true),
          );
          if (result == true) _load();
        },
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _load,
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
                          S.of(context).subTitle,
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
              if (_subs.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.accent, AppColors.primaryLight],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(CardTokens.radius),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${formatAmount(monthlyTotal, currency: baseCurrency)}/month',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: TypographyTokens.screenTitleSize,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                GestureDetector(
                                  onTap: hasOtherCurrencies
                                      ? () => setState(() => _showOtherCurrencies = !_showOtherCurrencies)
                                      : null,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${formatAmount(annualTotal, currency: baseCurrency)}/year',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.7),
                                          fontSize: 13,
                                        ),
                                      ),
                                      if (hasOtherCurrencies) ...[
                                        const SizedBox(width: 4),
                                        AnimatedRotation(
                                          turns: _showOtherCurrencies ? 0.5 : 0,
                                          duration: const Duration(milliseconds: 200),
                                          child: Icon(Icons.expand_more_rounded,
                                              size: 16, color: Colors.white.withValues(alpha: 0.7)),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                if (_showOtherCurrencies)
                                  ...monthlyByCurrency.entries
                                      .where((e) => e.key != baseCurrency && e.value > 0)
                                      .map((e) => Padding(
                                            padding: const EdgeInsets.only(top: 2),
                                            child: Text(
                                              '${formatAmount(e.value, currency: e.key)}/month',
                                              style: TextStyle(
                                                color: Colors.white.withValues(alpha: 0.6),
                                                fontSize: 12,
                                              ),
                                            ),
                                          )),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$activeCount ${S.of(context).subActive.toLowerCase()}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // ── Count summary ──
              if (_subs.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.sfv(context),
                        borderRadius: BorderRadius.circular(CardTokens.radius),
                      ),
                      child: Row(
                        children: [
                          _CountChip(
                            icon: Icons.subscriptions_rounded,
                            label: '${_subs.length}',
                            subtitle: S.of(context).subTotal,
                            color: AppColors.accent,
                          ),
                          const SizedBox(width: 16),
                          _CountChip(
                            icon: Icons.play_arrow_rounded,
                            label: '$activeCount',
                            subtitle: S.of(context).subActive,
                            color: AppColors.healthy,
                          ),
                          if (cancelledCount > 0) ...[
                            const SizedBox(width: 16),
                            _CountChip(
                              icon: Icons.cancel_outlined,
                              label: '$cancelledCount',
                              subtitle: S.of(context).subCancelled,
                              color: AppColors.overspent,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

              // ── Status filter chips ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                  child: Row(
                    children: [
                      _StatusChip(
                        label: S.of(context).typeAll,
                        selected: _statusFilter == null,
                        onTap: () =>
                            setState(() => _statusFilter = null),
                      ),
                      const SizedBox(width: 8),
                      _StatusChip(
                        label: S.of(context).subActive,
                        selected: _statusFilter == 'active',
                        color: AppColors.healthy,
                        onTap: () =>
                            setState(() => _statusFilter = 'active'),
                      ),
                      if (cancelledCount > 0) ...[
                        const SizedBox(width: 8),
                        _StatusChip(
                          label: S.of(context).subCancelled,
                          selected: _statusFilter == 'cancelled',
                          color: AppColors.overspent,
                          onTap: () =>
                              setState(() => _statusFilter = 'cancelled'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // ── List ──
              if (_loading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_subs.isEmpty)
                SliverFillRemaining(
                  child: EmptyState(
                    icon: Icons.subscriptions_rounded,
                    title: S.of(context).subNoTitle,
                    subtitle: S.of(context).subNoSubtitle,
                  ),
                )
              else if (filtered.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Text(
                      S.of(context).subNoTitle,
                      style: TextStyle(color: AppColors.ts(context)),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _SubscriptionTile(
                        sub: filtered[i],
                        categoryName:
                            _categoryNames[filtered[i]['category_id']],
                        categoryIcon:
                            _categoryIcons[filtered[i]['category_id']],
                        categoryColor:
                            _categoryColors[filtered[i]['category_id']],
                        frequencySuffix: _frequencySuffix(
                          filtered[i]['frequency'] as String? ?? 'monthly',
                          (filtered[i]['interval'] as int?) ?? 1,
                        ),
                        status: _status(filtered[i]),
                        parseDate: _parseDate,
                        onTap: () async {
                          final id = filtered[i]['id'] as String;
                          await context.push('/subscriptions/$id');
                          _load();
                        },
                        onToggleEnabled: () => _toggleEnabled(filtered[i]),
                      ),
                      childCount: filtered.length,
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

class _CountChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  const _CountChip({
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
        Text(label,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.tp(context))),
        const SizedBox(width: 4),
        Text(subtitle,
            style: TextStyle(fontSize: 12, color: AppColors.ts(context))),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;
  const _StatusChip({
    required this.label,
    required this.selected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.accent;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? chipColor.withValues(alpha: 0.15)
              : AppColors.sfv(context),
          borderRadius: BorderRadius.circular(20),
          border: selected
              ? Border.all(color: chipColor.withValues(alpha: 0.4))
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? chipColor : AppColors.ts(context),
          ),
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
  final VoidCallback onToggleEnabled;

  const _SubscriptionTile({
    required this.sub,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
    required this.frequencySuffix,
    required this.status,
    required this.parseDate,
    required this.onTap,
    required this.onToggleEnabled,
  });

  @override
  Widget build(BuildContext context) {
    final tr = S.of(context);
    final title = sub['title'] as String? ?? tr.subUntitled;
    final amount = (sub['amount'] as num?)?.toDouble() ?? 0;
    final currency = sub['currency'] as String?;
    final nextDue = parseDate(sub['next_due_date']);
    final isCancelled = status == 'cancelled';
    final isEnabled = sub['enabled'] == 1 || sub['enabled'] == true;

    final catColor = categoryColor != null
        ? AppColors.fromHex(categoryColor!)
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
        borderRadius: BorderRadius.circular(CardTokens.radius),
        border: Border.all(color: AppColors.bd(context)),
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          nextDue != null
              ? 'Next: ${formatDate(nextDue)} $frequencySuffix'
              : frequencySuffix,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.ts(context),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatAmount(amount, currency: currency),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: isCancelled
                        ? AppColors.th(context)
                        : AppColors.tp(context),
                    decoration:
                        isCancelled ? TextDecoration.lineThrough : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
                        'active' => tr.subActive,
                        'ending_soon' => tr.subEndingSoon,
                        'cancelled' => tr.subCancelled,
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
            const SizedBox(width: 6),
            SizedBox(
              width: 32,
              height: 32,
              child: IconButton(
                padding: EdgeInsets.zero,
                iconSize: 20,
                tooltip: isEnabled ? '${tr.subPause} subscription' : '${tr.subResume} subscription',
                icon: Icon(
                  isEnabled
                      ? Icons.pause_circle_rounded
                      : Icons.play_circle_rounded,
                  color: isEnabled
                      ? AppColors.th(context)
                      : AppColors.healthy,
                ),
                onPressed: onToggleEnabled,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
