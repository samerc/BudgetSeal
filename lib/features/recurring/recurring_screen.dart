import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import 'package:drift/drift.dart' show Value;

import '../../core/database/app_database.dart';
import '../../core/providers/tx_colors_provider.dart';
import '../../core/providers/accounts_provider.dart';
import '../../core/providers/categories_provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/engine_provider.dart';
import '../../core/providers/date_format_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/design_tokens.dart';
import '../../shared/utils/format_number.dart';
import '../../shared/widgets/app_chip.dart';
import '../../shared/widgets/calculator_amount_field.dart';
import '../../shared/widgets/category_icon.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/error_retry.dart';
import '../../shared/widgets/large_title_header.dart';
import '../../shared/widgets/sheet_title.dart';
import '../../shared/widgets/tappable.dart';
import '../transactions/widgets/category_sheet.dart';
import '../../core/providers/premium_provider.dart';
import '../../shared/widgets/empty_state.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/theme/app_icons.dart';
import '../../shared/widgets/skeleton_loader.dart';
import 'recurring_format.dart';

class RecurringScreen extends ConsumerStatefulWidget {
  const RecurringScreen({super.key});

  @override
  ConsumerState<RecurringScreen> createState() => _RecurringScreenState();
}

class _RecurringScreenState extends ConsumerState<RecurringScreen> {
  List<RecurringTransaction> _items = [];
  bool _loading = true;
  Object? _error;
  String? _typeFilter; // null = all, 'income', 'expense'

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
      final engine = ref.read(recurringEngineProvider);
      final items = await engine.getAll(householdId, excludeSubscriptions: true);
      if (mounted) {
        setState(() {
          _items = items;
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      debugPrint('[Recurring] Error loading: $e');
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e;
        });
      }
    }
  }

  List<RecurringTransaction> get _filtered {
    if (_typeFilter == null) return _items;
    return _items.where((r) => r.type == _typeFilter).toList();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _toggle(RecurringTransaction item, bool enabled) async {
    final tr = S.of(context);
    try {
      await ref.read(recurringEngineProvider).toggleEnabled(item.id, enabled);
      if (!mounted) return;
      _snack(enabled ? tr.recurringResumedSnack : tr.recurringPausedSnack);
    } catch (e) {
      debugPrint('[Recurring] Toggle failed: $e');
      if (mounted) _snack(tr.recurringUpdateFailed);
    }
    _load();
  }

  Future<void> _delete(RecurringTransaction item) async {
    final tr = S.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: tr.recurringDeleteTitle,
      message: tr.recurringDeleteBody,
      confirmLabel: tr.commonDelete,
    );
    if (!confirmed || !mounted) return;
    try {
      await ref.read(recurringEngineProvider).delete(item.id);
      if (mounted) _snack(tr.recurringDeleted);
    } catch (e) {
      debugPrint('[Recurring] Delete failed: $e');
      if (mounted) _snack(tr.recurringDeleteFailed);
    }
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final tr = S.of(context);
    final filtered = _filtered;
    final activeCount = _items.where((r) => r.enabled).length;
    final pausedCount = _items.length - activeCount;
    final txColors = ref.watch(txColorsProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        tooltip: tr.recurringAddTooltip,
        onPressed: () {
          if (!checkFreeLimit(context, ref, _items.length, FreeLimits.maxRecurring, 'recurring')) return;
          _showAddSheet();
        },
        child: const Icon(AppIcons.plus),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            LargeTitleHeader(
              title: tr.recurringTitle,
              back: true,
              actions: [
                IconButton(
                  tooltip: tr.calendarTitle,
                  icon: Icon(AppIcons.calendar, color: AppColors.ts(context)),
                  onPressed: () => context.push('/calendar'),
                ),
              ],
            ),

            // ── Summary strip ──
            if (_items.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: SummaryStrip(chips: [
                    SummaryChip(
                      icon: AppIcons.repeat,
                      label: '${_items.length}',
                      subtitle: tr.recurringSummaryTotal,
                      color: AppColors.accent,
                    ),
                    SummaryChip(
                      icon: AppIcons.play,
                      label: '$activeCount',
                      subtitle: tr.recurringSummaryActive,
                      color: AppColors.healthy,
                    ),
                    if (pausedCount > 0)
                      SummaryChip(
                        icon: AppIcons.pause,
                        label: '$pausedCount',
                        subtitle: tr.recurringSummaryPaused,
                        color: AppColors.ts(context),
                      ),
                  ]),
                ),
              ),

            // ── Type filter chips ──
            if (_items.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      AppChip(
                        label: tr.typeAll,
                        selected: _typeFilter == null,
                        onTap: () => setState(() => _typeFilter = null),
                      ),
                      AppChip(
                        label: tr.typeExpense,
                        selected: _typeFilter == 'expense',
                        color: txColors.expense,
                        onTap: () => setState(() => _typeFilter = 'expense'),
                      ),
                      AppChip(
                        label: tr.typeIncome,
                        selected: _typeFilter == 'income',
                        color: txColors.income,
                        onTap: () => setState(() => _typeFilter = 'income'),
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
                  message: tr.recurringLoadFailed,
                  details: '$_error',
                  onRetry: () {
                    setState(() => _loading = true);
                    _load();
                  },
                ),
              )
            else if (_items.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: AppIcons.repeat,
                  title: tr.recurringEmptyTitle,
                  subtitle: tr.recurringEmptySubtitle,
                ),
              )
            else if (filtered.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: AppIcons.repeat,
                  title: _typeFilter == 'income'
                      ? tr.recurringNoIncome
                      : tr.recurringNoExpenses,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _RecurringTile(
                      item: filtered[i],
                      onToggle: (enabled) => _toggle(filtered[i], enabled),
                      onDelete: () => _delete(filtered[i]),
                      onEdit: () => _showEditSheet(filtered[i]),
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

  Future<void> _showAddSheet() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddRecurringSheet(),
    );
    if (result == true) _load();
  }

  Future<void> _showEditSheet(RecurringTransaction item) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditRecurringSheet(
        item: item,
        onDelete: () => _delete(item),
      ),
    );
    if (result == true) _load();
  }
}

/// Status line under a recurring/subscription row's amount: colored dot +
/// label (Active / Paused / Ending soon / Cancelled).
class RecurringStatusDot extends StatelessWidget {
  final Color color;
  final String label;
  const RecurringStatusDot({super.key, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: TypographyTokens.overlineSize,
            color: AppColors.ts(context),
          ),
        ),
      ],
    );
  }
}

class _RecurringTile extends ConsumerWidget {
  final RecurringTransaction item;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _RecurringTile({
    required this.item,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = S.of(context);
    final color = ref.watch(txColorsProvider).forType(item.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: AppColors.card(context, radius: CardTokens.radius),
      child: Material(
        // Transparent Material so the ripple paints above the card fill.
        type: MaterialType.transparency,
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: CardTokens.borderRadius),
          onTap: onEdit,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          leading: Container(
            width: CategoryIconTokens.listSize,
            height: CategoryIconTokens.listSize,
            decoration: BoxDecoration(
              color: AppColors.pastel(context, color, light: 0.85, dark: 0.78),
              shape: BoxShape.circle,
            ),
            child: Icon(AppIcons.repeat, color: color, size: 20),
          ),
          title: Text(
            item.title.isNotEmpty ? item.title : item.note,
            style: TextStyle(
              fontWeight: TypographyTokens.txTitleWeight,
              fontSize: TypographyTokens.txTitleSize,
              color: item.enabled
                  ? AppColors.tp(context)
                  : AppColors.th(context),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            recurringNextLine(
                tr, item.nextDueDate, item.frequency, item.interval),
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
                    formatSignedAmount(item.amount,
                        currency: item.currency, type: item.type),
                    style: TextStyle(
                      fontWeight: TypographyTokens.amountRegularWeight,
                      fontSize: TypographyTokens.amountRegularSize,
                      color: item.enabled ? color : AppColors.th(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  RecurringStatusDot(
                    color: item.enabled
                        ? AppColors.healthy
                        : AppColors.th(context),
                    label: item.enabled
                        ? tr.recurringStatusActive
                        : tr.recurringStatusPaused,
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
                  tooltip: item.enabled ? tr.recurringPauseTooltip : tr.recurringResumeTooltip,
                  icon: Icon(
                    item.enabled
                        ? AppIcons.pauseCircle
                        : AppIcons.playCircle,
                    color: item.enabled
                        ? AppColors.th(context)
                        : AppColors.healthy,
                  ),
                  onPressed: () => onToggle(!item.enabled),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AddRecurringSheet extends ConsumerStatefulWidget {
  /// When true, the "This is a subscription" toggle is hidden and
  /// isSubscription is forced to true. Used from the Subscriptions screen.
  final bool forceSubscription;

  const AddRecurringSheet({super.key, this.forceSubscription = false});

  @override
  ConsumerState<AddRecurringSheet> createState() => _AddRecurringSheetState();
}

class _AddRecurringSheetState extends ConsumerState<AddRecurringSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  double _calcAmount = 0;
  String _type = 'expense';
  String _frequency = 'monthly';
  DateTime _startDate = DateTime.now();
  String? _accountId;
  String _currency = 'USD';
  DateTime? _endDate;
  String? _categoryId;
  late bool _isSubscription = widget.forceSubscription;
  bool _saving = false;
  bool _submitted = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom +
        MediaQuery.of(context).viewPadding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      decoration: BoxDecoration(
        color: AppColors.popup(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(RadiusTokens.sheet)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetTitle(
                widget.forceSubscription ? S.of(context).recurringNewSubTitle : S.of(context).recurringNewTitle,
                padding: const EdgeInsetsDirectional.only(bottom: 12)),
            TextFormField(
              controller: _titleCtrl,
              autofocus: true,
              // Tapping an option below drops focus, so a rebuild
              // doesn't bring the keyboard back.
              onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
              decoration: InputDecoration(labelText: S.of(context).recurringFormTitleHint),
              textCapitalization: TextCapitalization.words,
              maxLength: InputLimits.nameMaxLength,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? S.of(context).recurringFormTitleRequired : null,
            ),
            const SizedBox(height: 12),
            CalculatorAmountField(
              value: _calcAmount,
              label: S.of(context).commonAmount,
              fontSize: 20,
              onChanged: (v) => setState(() => _calcAmount = v),
            ),
            const SizedBox(height: 12),
            // Account picker
            Builder(builder: (context) {
              final accounts =
                  ref.watch(accountsProvider).value ?? [];
              return DropdownButtonFormField<String>(
                icon: AppIcons.dropdown,
                initialValue: _accountId,
                decoration:
                    InputDecoration(labelText: S.of(context).commonAccount),
                items: accounts
                    .map((a) => DropdownMenuItem(
                          value: a.id,
                          child: Text('${a.name} (${a.currency})'),
                        ))
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    _accountId = v;
                    if (v != null) {
                      final acc =
                          accounts.where((a) => a.id == v).firstOrNull;
                      if (acc != null) _currency = acc.currency;
                    }
                  });
                },
                validator: (v) =>
                    (_submitted && _accountId == null) ? S.of(context).recurringFormAccountRequired : null,
              );
            }),
            const SizedBox(height: 12),
            // Category picker
            _RecurringCategoryField(
              categoryId: _categoryId,
              type: _type,
              onSelected: (id, txType) => setState(() {
                _categoryId = id;
                _type = txType;
              }),
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'expense', label: Text(S.of(context).typeExpense)),
                ButtonSegment(value: 'income', label: Text(S.of(context).typeIncome)),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() {
                _type = s.first;
                // Drop the selected category if it no longer matches the type.
                final cats = ref.read(categoriesProvider).value ?? [];
                final cat = cats.where((c) => c.id == _categoryId).firstOrNull;
                if (cat != null && cat.transactionType != _type) {
                  _categoryId = null;
                }
              }),
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'weekly', label: Text(S.of(context).freqWeekly)),
                ButtonSegment(value: 'monthly', label: Text(S.of(context).freqMonthly)),
                ButtonSegment(value: 'yearly', label: Text(S.of(context).freqYearly)),
              ],
              selected: {_frequency},
              onSelectionChanged: (s) =>
                  setState(() => _frequency = s.first),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2030),
                );
                if (picked != null) setState(() => _startDate = picked);
              },
              icon: const Icon(AppIcons.calendarBlank, size: 16),
              label: Text(
                  S.of(context).recurringFormStarts(formatDate(_startDate))),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate:
                      _endDate ?? _startDate.add(const Duration(days: 365)),
                  firstDate: _startDate,
                  lastDate: DateTime(2035),
                );
                if (picked != null) {
                  setState(() => _endDate = picked);
                }
              },
              icon: const Icon(AppIcons.calendarX, size: 16),
              label: Text(_endDate != null
                  ? S.of(context).recurringFormEnds(formatDate(_endDate!))
                  : S.of(context).recurringFormEndsNever),
            ),
            if (_endDate != null) ...[
              const SizedBox(height: 4),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: () => setState(() => _endDate = null),
                  child: Text(S.of(context).recurringFormClearEndDate),
                ),
              ),
            ],
            if (!widget.forceSubscription) ...[
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(S.of(context).recurringFormIsSubscription,
                    style: const TextStyle(fontSize: 14)),
                subtitle: Text(S.of(context).recurringFormSubscriptionHint,
                    style: TextStyle(fontSize: 12, color: AppColors.th(context))),
                value: _isSubscription,
                onChanged: (v) => setState(() => _isSubscription = v),
                activeTrackColor: AppColors.accent,
              ),
            ],
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: AppColors.onAccent, strokeWidth: 2))
                  : Text(S.of(context).recurringFormCreate),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) return;

    final title = _titleCtrl.text.trim();
    if (_calcAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).recurringFormEnterAmount),
            behavior: SnackBarBehavior.floating),
      );
      return;
    }

    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null) return;
    if (_accountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).recurringFormSelectAccount),
            behavior: SnackBarBehavior.floating),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final engine = ref.read(recurringEngineProvider);
      await engine.create(
        householdId: householdId,
        type: _type,
        title: title,
        amount: _calcAmount,
        currency: _currency,
        accountId: _accountId!,
        categoryId: _categoryId,
        frequency: _frequency,
        startDate: _startDate,
        endDate: _endDate,
        isSubscription: _isSubscription,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).recurringCreated),
            behavior: SnackBarBehavior.floating,
          ),
        );
        // If this is a subscription created from the Recurring screen, jump to
        // the Subscriptions screen so the user sees what they just added.
        // (When opened from the Subscriptions screen, forceSubscription is true
        // and we're already there — just pop back to it.)
        final goToSubs = _isSubscription && !widget.forceSubscription;
        final router = GoRouter.of(context);
        Navigator.pop(context, true);
        if (goToSubs) router.push('/subscriptions');
      }
    } catch (e) {
      debugPrint('[Recurring] Create failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(S.of(context).recurringSaveFailed),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ---------------------------------------------------------------------------
// Edit Recurring Sheet
// ---------------------------------------------------------------------------

class EditRecurringSheet extends ConsumerStatefulWidget {
  final RecurringTransaction item;

  /// Shown as a Delete button under Save; the sheet closes first, then the
  /// caller confirms and deletes.
  final VoidCallback? onDelete;
  const EditRecurringSheet({super.key, required this.item, this.onDelete});

  @override
  ConsumerState<EditRecurringSheet> createState() =>
      _EditRecurringSheetState();
}

class _EditRecurringSheetState extends ConsumerState<EditRecurringSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late double _calcAmount;
  late String _frequency;
  late DateTime _startDate;
  late String? _accountId;
  late String _currency;
  late DateTime? _endDate;
  late String? _categoryId;
  late bool _isSubscription;
  bool _saving = false;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _titleCtrl = TextEditingController(text: item.title);
    _calcAmount = item.amount;
    _frequency = item.frequency;
    _startDate = item.nextDueDate;
    _accountId = item.accountId;
    _currency = item.currency;
    _endDate = item.endDate;
    _categoryId = item.categoryId;
    _isSubscription = item.isSubscription;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom +
        MediaQuery.of(context).viewPadding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      decoration: BoxDecoration(
        color: AppColors.popup(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(RadiusTokens.sheet)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetTitle(S.of(context).recurringEditTitle,
                padding: const EdgeInsetsDirectional.only(bottom: 12)),
            TextFormField(
              controller: _titleCtrl,
              autofocus: false,
              decoration:
                  InputDecoration(labelText: S.of(context).recurringFormTitleHint),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? S.of(context).recurringFormTitleRequired : null,
            ),
            const SizedBox(height: 12),
            CalculatorAmountField(
              value: _calcAmount,
              label: S.of(context).commonAmount,
              fontSize: 20,
              onChanged: (v) => setState(() => _calcAmount = v),
            ),
            const SizedBox(height: 12),
            // Account picker
            Builder(builder: (context) {
              final accounts = ref.watch(accountsProvider).value ?? [];
              return DropdownButtonFormField<String>(
                icon: AppIcons.dropdown,
                initialValue: _accountId,
                decoration: InputDecoration(labelText: S.of(context).commonAccount),
                items: accounts
                    .map((a) => DropdownMenuItem(
                          value: a.id,
                          child: Text('${a.name} (${a.currency})'),
                        ))
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    _accountId = v;
                    if (v != null) {
                      final acc = accounts.where((a) => a.id == v).firstOrNull;
                      if (acc != null) _currency = acc.currency;
                    }
                  });
                },
                validator: (v) =>
                    (_submitted && _accountId == null) ? S.of(context).recurringFormAccountRequired : null,
              );
            }),
            const SizedBox(height: 12),
            // Category picker
            _RecurringCategoryField(
              categoryId: _categoryId,
              type: widget.item.type,
              onSelected: (id, _) => setState(() => _categoryId = id),
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'weekly', label: Text(S.of(context).freqWeekly)),
                ButtonSegment(value: 'monthly', label: Text(S.of(context).freqMonthly)),
                ButtonSegment(value: 'yearly', label: Text(S.of(context).freqYearly)),
              ],
              selected: {_frequency},
              onSelectionChanged: (s) => setState(() => _frequency = s.first),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (picked != null) setState(() => _startDate = picked);
              },
              icon: const Icon(AppIcons.calendarBlank, size: 16),
              label: Text(
                  S.of(context).recurringFormNextDue(formatDate(_startDate))),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate:
                      _endDate ?? _startDate.add(const Duration(days: 365)),
                  firstDate: _startDate,
                  lastDate: DateTime(2035),
                );
                if (picked != null) {
                  setState(() => _endDate = picked);
                }
              },
              icon: const Icon(AppIcons.calendarX, size: 16),
              label: Text(_endDate != null
                  ? S.of(context).recurringFormEnds(formatDate(_endDate!))
                  : S.of(context).recurringFormEndsNever),
            ),
            if (_endDate != null) ...[
              const SizedBox(height: 4),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: () => setState(() => _endDate = null),
                  child: Text(S.of(context).recurringFormClearEndDate),
                ),
              ),
            ],
            const SizedBox(height: 12),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(S.of(context).recurringFormIsSubscription,
                  style: const TextStyle(fontSize: 14)),
              subtitle: Text(S.of(context).recurringFormSubscriptionHint,
                  style: TextStyle(fontSize: 12, color: AppColors.th(context))),
              value: _isSubscription,
              onChanged: (v) => setState(() => _isSubscription = v),
              activeTrackColor: AppColors.accent,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(S.of(context).commonCancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: AppColors.onAccent, strokeWidth: 2))
                        : Text(S.of(context).commonSave),
                  ),
                ),
              ],
            ),
            if (widget.onDelete != null) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _saving
                    ? null
                    : () {
                        Navigator.pop(context, false);
                        widget.onDelete!();
                      },
                icon: const Icon(AppIcons.trash, size: 18),
                label: Text(S.of(context).commonDelete),
                style: TextButton.styleFrom(
                    foregroundColor: AppColors.overspent),
              ),
            ],
          ],
        ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _submitted = true);
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).recurringFormEnterTitle),
            behavior: SnackBarBehavior.floating),
      );
      return;
    }
    if (_calcAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).recurringFormEnterAmount),
            behavior: SnackBarBehavior.floating),
      );
      return;
    }
    if (_accountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).recurringFormSelectAccount),
            behavior: SnackBarBehavior.floating),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final db = ref.read(databaseProvider);
      await (db.update(db.recurringTransactions)
            ..where((r) => r.id.equals(widget.item.id)))
          .write(RecurringTransactionsCompanion(
        title: Value(title),
        amount: Value(_calcAmount),
        currency: Value(_currency),
        accountId: Value(_accountId!),
        categoryId: Value(_categoryId),
        frequency: Value(_frequency),
        nextDueDate: Value(_startDate),
        anchorDay: Value(_startDate.day),
        endDate: Value(_endDate),
        isSubscription: Value(_isSubscription),
        lastModified: Value(DateTime.now()),
      ));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).recurringUpdated),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('[Recurring] Update failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(S.of(context).recurringSaveFailed),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

/// Category picker field that opens the same rich [CategorySheet] used on the
/// transaction screen (search, expense/income toggle, parent/subcategory
/// hierarchy with icons) instead of a flat dropdown list.
class _RecurringCategoryField extends ConsumerWidget {
  final String? categoryId;

  /// Current transaction type ('expense' | 'income') — used when creating a
  /// new category from the sheet.
  final String type;

  /// Called with the chosen category id (null = None) and its transaction type.
  final void Function(String? id, String txType) onSelected;

  const _RecurringCategoryField({
    required this.categoryId,
    required this.type,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allCats = ref.watch(categoriesProvider).value ?? [];
    final selected = allCats.where((c) => c.id == categoryId).firstOrNull;

    return Tappable(
      borderRadius: BorderRadius.circular(RadiusTokens.input),
      onTap: () => _open(context, ref, allCats),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: S.of(context).recurringFormCategory,
        ),
        child: Row(
          children: [
            if (selected != null) ...[
              CategoryIcon(
                categoryName: selected.name,
                emoji: selected.icon,
                color: AppColors.fromHex(selected.colorHex),
                size: 28,
                circular: true,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  selected.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.tp(context),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ] else
              Expanded(
                child: Text(
                  S.of(context).catNone,
                  style: TextStyle(color: AppColors.th(context)),
                ),
              ),
            Icon(AppIcons.caretDown, color: AppColors.ts(context)),
          ],
        ),
      ),
    );
  }

  Future<void> _open(
      BuildContext context, WidgetRef ref, List<Category> allCats) async {
    final householdId = ref.read(currentHouseholdIdProvider);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CategorySheet(
        categories: allCats,
        selectedId: categoryId,
        householdId: householdId,
        onSelected: (id, name, color, txType) {
          onSelected(id, txType);
          Navigator.of(ctx).pop();
        },
        onCreated: (name) async {
          if (householdId == null) return;
          final db = ref.read(databaseProvider);
          final cats = ref.read(categoriesProvider).value ?? [];
          final color =
              categoryPresetColors[cats.length % categoryPresetColors.length];
          final colorHex =
              '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
          final newId = const Uuid().v4();
          await db.into(db.categories).insert(CategoriesCompanion.insert(
                id: newId,
                householdId: householdId,
                name: name,
                colorHex: Value(colorHex),
                transactionType: Value(type),
              ));
          ref.invalidate(categoriesProvider);
          onSelected(newId, type);
          if (ctx.mounted && Navigator.of(ctx).canPop()) {
            Navigator.of(ctx).pop();
          }
        },
      ),
    );
  }
}
