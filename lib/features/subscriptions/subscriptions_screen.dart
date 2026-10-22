import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/database_provider.dart';
import '../../core/providers/engine_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../core/providers/tx_colors_provider.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/design_tokens.dart';
import '../../shared/utils/format_number.dart';
import '../../shared/widgets/app_chip.dart';
import '../../shared/widgets/category_icon.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_retry.dart';
import '../../shared/widgets/large_title_header.dart';
import '../../shared/widgets/tappable.dart';
import '../recurring/recurring_format.dart';
import '../recurring/recurring_screen.dart'
    show AddRecurringSheet, RecurringStatusDot;
import '../../l10n/generated/app_localizations.dart';
import '../../shared/theme/app_icons.dart';
import '../../shared/widgets/skeleton_loader.dart';

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
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final householdId = ref.read(currentHouseholdIdProvider);
      if (householdId == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      final db = ref.read(databaseProvider);

      final rows = await db.customSelect(
        'SELECT * FROM recurring_transactions WHERE household_id = ? AND is_subscription = 1 AND deleted = 0 ORDER BY title ASC',
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
          _error = null;
        });
      }
    } catch (e) {
      debugPrint('[Subscriptions] Error loading: $e');
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e;
        });
      }
    }
  }

  /// Pause or resume a subscription through the recurring engine (moves
  /// last_modified so sync picks it up).
  Future<void> _toggleEnabled(Map<String, dynamic> sub) async {
    final tr = S.of(context);
    final messenger = ScaffoldMessenger.of(context);
    void snack(String m) => messenger.showSnackBar(
        SnackBar(content: Text(m), behavior: SnackBarBehavior.floating));
    try {
      final subId = sub['id']?.toString() ?? '';
      if (subId.isEmpty) return;
      final enabled = !_isEnabled(sub);
      await ref.read(recurringEngineProvider).toggleEnabled(subId, enabled);
      snack(enabled ? tr.subResumedSnack : tr.subPausedSnack);
    } catch (e) {
      debugPrint('[Subscriptions] Error toggling: $e');
      snack(tr.subCouldNotUpdate);
    }
    _load();
  }

  static bool _isEnabled(Map<String, dynamic> sub) =>
      sub['enabled'] == 1 || sub['enabled'] == true;

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value * 1000);
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  String _status(Map<String, dynamic> sub) => subscriptionStatus(
      enabled: _isEnabled(sub), endDate: _parseDate(sub['end_date']));

  String? _statusFilter; // null = all, 'active', 'paused', 'cancelled'
  bool _showOtherCurrencies = false;

  List<Map<String, dynamic>> get _filtered {
    if (_statusFilter == null) return _subs;
    // "Active" includes the ones ending soon (still billing).
    return _subs.where((s) {
      final st = _status(s);
      return _statusFilter == 'active'
          ? (st == 'active' || st == 'ending_soon')
          : st == _statusFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final tr = S.of(context);
    final filtered = _filtered;
    final statuses = _subs.map(_status).toList();
    final activeCount =
        statuses.where((s) => s == 'active' || s == 'ending_soon').length;
    final pausedCount = statuses.where((s) => s == 'paused').length;
    final cancelledCount = statuses.where((s) => s == 'cancelled').length;

    // Group monthly totals by currency to avoid mixing; only what still bills.
    final baseCurrency = ref.watch(householdProvider).value?.baseCurrency ?? 'USD';
    final monthlyByCurrency = <String, double>{};
    for (final s in _subs) {
      final st = _status(s);
      if (st == 'cancelled' || st == 'paused') continue;
      final amount = (s['amount'] as num?)?.toDouble() ?? 0;
      final currency = s['currency'] as String? ?? baseCurrency;
      final freq = s['frequency'] as String? ?? 'monthly';
      final interval = (s['interval'] as int?) ?? 1;
      monthlyByCurrency[currency] = (monthlyByCurrency[currency] ?? 0) +
          recurringMonthlyEquivalent(amount, freq, interval);
    }
    final monthlyTotal = monthlyByCurrency[baseCurrency] ?? 0.0;
    final annualTotal = monthlyTotal * 12;
    final hasOtherCurrencies = monthlyByCurrency.keys
        .any((c) => c != baseCurrency && (monthlyByCurrency[c] ?? 0) > 0);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        tooltip: tr.subAddTooltip,
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
        child: const Icon(AppIcons.plus),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            LargeTitleHeader(title: tr.subTitle, back: true),

            // ── Cost banner ──
            if (_subs.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.pastel(context, AppColors.accent,
                          light: 0.8, dark: 0.75),
                      borderRadius: BorderRadius.circular(RadiusTokens.hero),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            '${formatAmount(monthlyTotal, currency: baseCurrency)}${tr.subFreqMonth}',
                            style: TextStyle(
                              color: AppColors.tp(context),
                              fontSize: TypographyTokens.screenTitleSize,
                              fontFamily: TypographyTokens.displayFamily,
                              fontWeight: TypographyTokens.screenTitleWeight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Tappable(
                          onTap: hasOtherCurrencies
                              ? () => setState(() =>
                                  _showOtherCurrencies = !_showOtherCurrencies)
                              : null,
                          borderRadius: BorderRadius.circular(RadiusTokens.sm),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${formatAmount(annualTotal, currency: baseCurrency)}${tr.subFreqYear}',
                                style: TextStyle(
                                  color: AppColors.ts(context),
                                  fontSize: 13,
                                ),
                              ),
                              if (hasOtherCurrencies) ...[
                                const SizedBox(width: 4),
                                AnimatedRotation(
                                  turns: _showOtherCurrencies ? 0.5 : 0,
                                  duration: const Duration(milliseconds: 200),
                                  child: Icon(AppIcons.caretDown,
                                      size: 16, color: AppColors.ts(context)),
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
                                      '${formatAmount(e.value, currency: e.key)}${tr.subFreqMonth}',
                                      style: TextStyle(
                                        color: AppColors.ts(context),
                                        fontSize: TypographyTokens.captionSize,
                                      ),
                                    ),
                                  )),
                      ],
                    ),
                  ),
                ),
              ),

            // ── Count summary ──
            if (_subs.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: SummaryStrip(chips: [
                    SummaryChip(
                      icon: AppIcons.playCircle,
                      label: '${_subs.length}',
                      subtitle: tr.subTotal,
                      color: AppColors.accent,
                    ),
                    SummaryChip(
                      icon: AppIcons.play,
                      label: '$activeCount',
                      subtitle: tr.subActive,
                      color: AppColors.healthy,
                    ),
                    if (pausedCount > 0)
                      SummaryChip(
                        icon: AppIcons.pause,
                        label: '$pausedCount',
                        subtitle: tr.recurringStatusPaused,
                        color: AppColors.ts(context),
                      ),
                    if (cancelledCount > 0)
                      SummaryChip(
                        icon: AppIcons.xCircle,
                        label: '$cancelledCount',
                        subtitle: tr.subCancelled,
                        color: AppColors.overspent,
                      ),
                  ]),
                ),
              ),

            // ── Status filter chips ──
            if (_subs.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      AppChip(
                        label: tr.typeAll,
                        selected: _statusFilter == null,
                        onTap: () => setState(() => _statusFilter = null),
                      ),
                      AppChip(
                        label: tr.subActive,
                        selected: _statusFilter == 'active',
                        color: AppColors.healthy,
                        onTap: () => setState(() => _statusFilter = 'active'),
                      ),
                      if (pausedCount > 0)
                        AppChip(
                          label: tr.recurringStatusPaused,
                          selected: _statusFilter == 'paused',
                          onTap: () =>
                              setState(() => _statusFilter = 'paused'),
                        ),
                      if (cancelledCount > 0)
                        AppChip(
                          label: tr.subCancelled,
                          selected: _statusFilter == 'cancelled',
                          color: AppColors.overspent,
                          onTap: () =>
                              setState(() => _statusFilter = 'cancelled'),
                        ),
                    ],
                  ),
                ),
              ),

            // ── List ──
            if (_loading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: SkeletonList(),
                ),
              )
            else if (_error != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: ErrorRetry(
                  message: tr.subLoadFailed,
                  details: '$_error',
                  onRetry: () {
                    setState(() => _loading = true);
                    _load();
                  },
                ),
              )
            else if (_subs.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: AppIcons.playCircle,
                  title: tr.subNoTitle,
                  subtitle: tr.subNoSubtitle,
                ),
              )
            else if (filtered.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: AppIcons.playCircle,
                  title: tr.subNoMatch,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _SubscriptionTile(
                      sub: filtered[i],
                      categoryName: _categoryNames[filtered[i]['category_id']],
                      categoryIcon: _categoryIcons[filtered[i]['category_id']],
                      categoryColor:
                          _categoryColors[filtered[i]['category_id']],
                      status: _status(filtered[i]),
                      nextDue: _parseDate(filtered[i]['next_due_date']),
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
    );
  }
}

class _SubscriptionTile extends ConsumerWidget {
  final Map<String, dynamic> sub;
  final String? categoryName;
  final String? categoryIcon;
  final String? categoryColor;
  final String status;
  final DateTime? nextDue;
  final VoidCallback onTap;
  final VoidCallback onToggleEnabled;

  const _SubscriptionTile({
    required this.sub,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
    required this.status,
    required this.nextDue,
    required this.onTap,
    required this.onToggleEnabled,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = S.of(context);
    final title = sub['title'] as String? ?? tr.subUntitled;
    final amount = (sub['amount'] as num?)?.toDouble() ?? 0;
    final currency = sub['currency'] as String? ?? '';
    final type = sub['type'] as String? ?? 'expense';
    final frequency = sub['frequency'] as String? ?? 'monthly';
    final interval = (sub['interval'] as int?) ?? 1;
    final isCancelled = status == 'cancelled';
    final isEnabled = sub['enabled'] == 1 || sub['enabled'] == true;
    final billing = status != 'cancelled' && status != 'paused';

    final catColor = categoryColor != null
        ? AppColors.fromHex(categoryColor!)
        : AppColors.accent;
    final amountColor = billing
        ? ref.watch(txColorsProvider).forType(type)
        : AppColors.th(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: AppColors.card(context, radius: CardTokens.radius),
      child: Material(
        // Transparent Material so the ripple paints above the card fill.
        type: MaterialType.transparency,
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: CardTokens.borderRadius),
          onTap: onTap,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          leading: CategoryIcon(
            categoryName: categoryName ?? title,
            emoji: categoryIcon,
            color: catColor,
            size: CategoryIconTokens.listSize,
            circular: true,
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: TypographyTokens.txTitleWeight,
              fontSize: TypographyTokens.txTitleSize,
              color: billing ? AppColors.tp(context) : AppColors.th(context),
              decoration: isCancelled ? TextDecoration.lineThrough : null,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            recurringNextLine(tr, isCancelled ? null : nextDue, frequency,
                interval),
            style: TextStyle(
              fontSize: TypographyTokens.txSubtitleSize,
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
                    formatSignedAmount(amount, currency: currency, type: type),
                    style: TextStyle(
                      fontWeight: TypographyTokens.amountRegularWeight,
                      fontSize: TypographyTokens.amountRegularSize,
                      color: amountColor,
                      decoration:
                          isCancelled ? TextDecoration.lineThrough : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  RecurringStatusDot(
                    color: subscriptionStatusColor(context, status),
                    label: subscriptionStatusLabel(tr, status),
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
                  tooltip:
                      isEnabled ? tr.subPauseTooltip : tr.subResumeTooltip,
                  icon: Icon(
                    isEnabled ? AppIcons.pauseCircle : AppIcons.playCircle,
                    color:
                        isEnabled ? AppColors.th(context) : AppColors.healthy,
                  ),
                  onPressed: onToggleEnabled,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
