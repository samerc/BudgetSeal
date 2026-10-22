import 'dart:math' as math;

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import 'package:intl/intl.dart';

import '../../core/providers/date_format_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import 'move_money_sheet.dart';

import '../../core/database/app_database.dart';
import '../../core/database/daos/allocations_dao.dart';
import '../../core/database/daos/ledger_dao.dart';
import '../../core/providers/allocations_provider.dart';
import '../../core/providers/activity_filter_provider.dart';
import '../../core/providers/categories_provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/engine_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../core/providers/transactions_provider.dart';
import '../../shared/widgets/skeleton_loader.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/sheet_title.dart';
import '../../shared/widgets/tappable.dart';
import '../categories/emoji_groups.dart';
import 'option_card.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/widgets/budget_progress.dart';
import '../../shared/theme/design_tokens.dart';
import '../../shared/widgets/currency_picker_field.dart';
import '../../shared/utils/format_number.dart';
import '../../shared/widgets/calculator_amount_field.dart';
import '../../shared/widgets/category_icon.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/theme/app_icons.dart';
import '../../core/providers/seal_provider.dart';
import '../../shared/widgets/seal_mark.dart';

class AllocationDetailScreen extends ConsumerStatefulWidget {
  final String allocationId;

  /// Open the cover / move-money sheet once loaded ("Cover" on a Saved
  /// message).
  final bool openCover;
  const AllocationDetailScreen(
      {super.key, required this.allocationId, this.openCover = false});

  @override
  ConsumerState<AllocationDetailScreen> createState() =>
      _AllocationDetailScreenState();
}

class _AllocationDetailScreenState
    extends ConsumerState<AllocationDetailScreen> {
  final _nameController = TextEditingController();
  double _targetAmount = 0;
  final _targetCurrencyController = TextEditingController();
  String _type = 'spending';
  String _periodicity = 'periodic';
  bool _rollover = false;
  bool _autoReset = true;
  String? _icon; // emoji icon for this envelope
  bool _loading = false;
  bool _showSettings = false;
  bool _showEmojiGrid = false;
  bool _fundPulse = false;
  List<Category> _linkedCategories = [];
  /// For the creation flow: distinguishes saving-with-goal from saving-open.

  bool get _isNew => widget.allocationId == 'new';

  @override
  void initState() {
    super.initState();
    final baseCurrency =
        ref.read(householdProvider).value?.baseCurrency ?? 'USD';
    _targetCurrencyController.text = baseCurrency;
    if (!_isNew) {
      _loadAllocation().then((_) async {
        if (!widget.openCover || !mounted) return;
        await ref.read(allocationsProvider.future);
        if (mounted) _moveMoney();
      });
    }
  }

  Future<void> _loadAllocation() async {
    try {
    final db = ref.read(databaseProvider);
    final dao = AllocationsDao(db);
    final alloc = await dao.getById(widget.allocationId);
    if (alloc != null && mounted) {
      final linked = await dao.linkedCategories(widget.allocationId);
      if (!mounted) return;
      setState(() {
        _nameController.text = alloc.name;
        _type = alloc.type;
        _periodicity = alloc.periodicity;
        _rollover = alloc.rollover;
        _autoReset = alloc.autoReset;
        _icon = alloc.icon;
        if (alloc.targetAmount != null) {
          _targetAmount = alloc.targetAmount!;
        }
        _targetCurrencyController.text = alloc.targetCurrency ??
            ref.read(householdProvider).value?.baseCurrency ??
            'USD';
        _linkedCategories = linked;
      });
    }
    } catch (e) {
      debugPrint('[AllocationDetail] Error loading: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetCurrencyController.dispose();
    super.dispose();
  }

  static final _sectionRadius = BorderRadius.circular(CardTokens.radius);
  static const _inputRadius =
      BorderRadius.all(Radius.circular(RadiusTokens.md));

  InputDecoration _inputDecoration(String label, {Widget? prefixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: AppColors.ts(context), fontSize: 14),
      floatingLabelStyle: TextStyle(
          color: AppColors.accent, fontWeight: FontWeight.w600),
      prefixIcon: prefixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _sectionContainer({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: _sectionRadius,
        boxShadow: AppColors.cardShadow(context),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _sectionHeader(String label) => SectionHeader(label,
      padding: const EdgeInsets.only(bottom: 12));

  Widget _buildSegmentedSelector<T>({
    required List<(T, String, IconData)> options,
    required T selected,
    required ValueChanged<T> onChanged,
  }) {
    return SegmentedButton<T>(
      segments: [
        for (final o in options)
          ButtonSegment(
              value: o.$1, label: Text(o.$2), icon: Icon(o.$3, size: 18)),
      ],
      selected: {selected},
      showSelectedIcon: false,
      onSelectionChanged: (v) => onChanged(v.first),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = S.of(context);
    final envelopeName = _nameController.text.isNotEmpty
        ? _nameController.text
        : l.allocFallbackName;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(_isNew ? l.allocNewEnvelope : envelopeName,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          if (!_isNew)
            PopupMenuButton<String>(
              icon: const Icon(AppIcons.dotsThreeVertical),
              onSelected: (v) {
                if (v == 'settings') {
                  setState(() => _showSettings = !_showSettings);
                } else if (v == 'move') {
                  _moveMoney();
                } else if (v == 'withdraw') {
                  _showWithdrawSheet();
                } else if (v == 'revalue') {
                  _showRevalueSheet();
                } else if (v == 'archive') {
                  _confirmArchive();
                } else if (v == 'delete') {
                  _confirmDelete();
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'settings',
                  child: Row(children: [
                    Icon(AppIcons.gear,
                        size: 20, color: AppColors.ts(context)),
                    const SizedBox(width: 12),
                    Text(l.allocEditSettings),
                  ]),
                ),
                PopupMenuItem(
                  value: 'move',
                  child: Row(children: [
                    Icon(AppIcons.arrowsLeftRight,
                        size: 20, color: AppColors.accent),
                    const SizedBox(width: 12),
                    Text(_targetBalance() < 0
                        ? l.allocCoverTitle
                        : l.allocMoveMenu),
                  ]),
                ),
                PopupMenuItem(
                    value: 'withdraw',
                    child: Row(children: [
                      Icon(AppIcons.signOut,
                          size: 20, color: AppColors.accent),
                      const SizedBox(width: 12),
                      Text(l.allocWithdrawMenu),
                    ]),
                  ),
                PopupMenuItem(
                  value: 'revalue',
                  child: Row(children: [
                    Icon(AppIcons.currencyCircleDollar,
                        size: 20, color: AppColors.accent),
                    const SizedBox(width: 12),
                    Text(l.allocRevalueMenu),
                  ]),
                ),
                PopupMenuItem(
                  value: 'archive',
                  child: Row(children: [
                    Icon(AppIcons.archive,
                        size: 20, color: AppColors.caution),
                    const SizedBox(width: 12),
                    Text(l.allocArchiveMenu,
                        style: TextStyle(color: AppColors.caution)),
                  ]),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [
                    Icon(AppIcons.trash,
                        size: 20, color: AppColors.overspent),
                    const SizedBox(width: 12),
                    Text(l.commonDelete,
                        style: TextStyle(color: AppColors.overspent)),
                  ]),
                ),
              ],
            ),
        ],
      ),
      bottomNavigationBar: (_isNew || _showSettings)
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: FilledButton(
                  onPressed: _loading ? null : _save,
                  child: _loading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: AppColors.onAccent, strokeWidth: 2))
                      : Text(_isNew ? l.allocCreateButtonDetail : l.allocSaveChanges),
                ),
              ),
            )
          : null,
      body: Stack(
        children: [
          SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // For existing envelopes: balance hero + fund + recent
            if (!_isNew) ...[
              _buildBalanceHero(),
              const SizedBox(height: 12),
            ],
            // Settings (always shown for new, toggled for existing)
            if (_isNew || _showSettings) ...[
            // Icon + Name
            _sectionContainer(children: [
              _sectionHeader(l.allocNameIconSection),
              Row(
                children: [
                  Tappable(
                    onTap: () => setState(() {
                      _showEmojiGrid = !_showEmojiGrid;
                      if (_showEmojiGrid) FocusScope.of(context).unfocus();
                    }),
                    borderRadius: BorderRadius.circular(
                        CategoryIconTokens.listSize / 2),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _showEmojiGrid
                              ? AppColors.accent
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: _icon != null
                          ? CategoryIcon(
                              categoryName: _nameController.text,
                              emoji: _icon,
                              color: AppColors.accent,
                              size: CategoryIconTokens.listSize,
                              circular: true,
                            )
                          : Container(
                              width: CategoryIconTokens.listSize,
                              height: CategoryIconTokens.listSize,
                              decoration: BoxDecoration(
                                color: AppColors.pastel(
                                    context, AppColors.accent,
                                    light: 0.85, dark: 0.78),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(AppIcons.smiley,
                                  size: 22, color: AppColors.accent),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      // Hide the maxLength counter so it doesn't add height
                      // below the field and push the icon out of alignment.
                      decoration: _inputDecoration(l.allocNameHint)
                          .copyWith(counterText: ''),
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.done,
                      autofocus: _isNew && !_showEmojiGrid,
                      // Tapping an option below drops focus, so a rebuild
                      // doesn't bring the keyboard back.
                      onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
                      maxLength: InputLimits.nameMaxLength,
                      style: TextStyle(
                          color: AppColors.tp(context), fontSize: 15),
                      onTap: () {
                        if (_showEmojiGrid) setState(() => _showEmojiGrid = false);
                      },
                    ),
                  ),
                ],
              ),
              // Inline emoji grid
              if (_showEmojiGrid) ...[
                const SizedBox(height: 12),
                if (_icon != null)
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton(
                      onPressed: () => setState(() {
                        _icon = null;
                        _showEmojiGrid = false;
                      }),
                      child: Text(l.allocRemoveIcon),
                    ),
                  ),
                InlineEmojiGrid(
                  selected: _icon,
                  onPick: (e) => setState(() {
                    _icon = e;
                    _showEmojiGrid = false;
                  }),
                ),
              ],
            ]),
            const SizedBox(height: 16),

            // Envelope Type Selection
            if (_isNew) ...[
              _sectionContainer(children: [
                _sectionHeader(l.allocTypeSection),
                OptionCard(
                  icon: AppIcons.shoppingBag,
                  title: l.allocSpendingTitle,
                  subtitle: l.allocSpendingDesc,
                  selected: _type == 'spending',
                  onTap: () => setState(() {
                    _type = 'spending';
                    _periodicity = 'periodic';
                  }),
                ),
                const SizedBox(height: 8),
                OptionCard(
                  icon: AppIcons.slidersHorizontal,
                  title: l.allocFlexibleTitle,
                  subtitle: l.allocFlexibleDesc,
                  selected: _type == 'flexible' || _type == 'saving',
                  onTap: () => setState(() {
                    _type = 'flexible';
                    _periodicity = 'permanent';
                  }),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.sfv(context),
                    borderRadius: BorderRadius.circular(RadiusTokens.md),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(AppIcons.info,
                          size: 16, color: AppColors.ts(context)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l.allocInfoBanner,
                          style: TextStyle(
                              fontSize: 11, color: AppColors.ts(context), height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 16),
            ] else ...[
              // For existing envelopes: show type selector (remap 'saving' → 'flexible')
              _sectionContainer(children: [
                _sectionHeader(l.allocPurposeSection),
                _buildSegmentedSelector<String>(
                  options: [
                    ('spending', l.allocSpendingTitle, AppIcons.shoppingBag),
                    ('flexible', l.allocFlexibleTitle, AppIcons.slidersHorizontal),
                  ],
                  selected: _type == 'saving' ? 'flexible' : _type,
                  onChanged: (v) => setState(() {
                    _type = v;
                  }),
                ),
              ]),
              const SizedBox(height: 16),
            ],

            // Cycle (all envelope types)
            ...[
              _sectionContainer(children: [
                _sectionHeader(l.allocCycleSection),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    l.allocCycleHelp,
                    style: TextStyle(
                        fontSize: 11, color: AppColors.ts(context), height: 1.5),
                  ),
                ),
                _buildSegmentedSelector<String>(
                  options: [
                    ('periodic', l.allocPeriodic, AppIcons.calendarDots),
                    ('permanent', l.allocPermanent, AppIcons.infinity),
                  ],
                  selected: _periodicity,
                  onChanged: (v) => setState(() => _periodicity = v),
                ),
                if (_periodicity == 'periodic') ...[
                  const SizedBox(height: 14),
                  Container(
                    decoration: BoxDecoration(
                        color: AppColors.sfv(context),
                        borderRadius: _inputRadius),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    child: Row(children: [
                      Icon(AppIcons.arrowCounterClockwise,
                          size: 20, color: AppColors.ts(context)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l.allocRolloverBalance,
                                  style: TextStyle(
                                      color: AppColors.tp(context),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500)),
                              Text(l.allocRolloverDesc,
                                  style: TextStyle(
                                      color: AppColors.ts(context),
                                      fontSize: 12)),
                            ]),
                      ),
                      Switch.adaptive(
                        value: _rollover,
                        onChanged: (v) => setState(() => _rollover = v),
                        activeTrackColor: AppColors.accent,
                      ),
                    ]),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(children: [
                      Icon(AppIcons.arrowsClockwise,
                          size: 20, color: AppColors.ts(context)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l.allocAutoReset,
                                  style: TextStyle(
                                      color: AppColors.tp(context),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500)),
                              Text(l.allocAutoResetDesc,
                                  style: TextStyle(
                                      color: AppColors.ts(context),
                                      fontSize: 12)),
                            ]),
                      ),
                      Switch.adaptive(
                        value: _autoReset,
                        onChanged: (v) => setState(() => _autoReset = v),
                        activeTrackColor: AppColors.accent,
                      ),
                    ]),
                  ),
                ],
              ]),
              const SizedBox(height: 16),
            ],

            // Budget / Target Amount
            _sectionContainer(children: [
              _sectionHeader(
                _type == 'spending' ? l.allocMonthlyBudget : l.allocTargetOptional),
              Text(
                _type == 'spending'
                    ? l.allocMonthlyBudgetDesc
                    : l.allocTargetDesc,
                style: TextStyle(
                    fontSize: 12, color: AppColors.ts(context)),
              ),
                const SizedBox(height: 12),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                    flex: 3,
                    child: CalculatorAmountField(
                      value: _targetAmount,
                      label: _type == 'spending' ? l.allocBudgetAmount : l.allocTargetAmount,
                      fontSize: 20,
                      onChanged: (v) => setState(() => _targetAmount = v),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: CurrencyPickerField(
                      label: l.commonCurrency,
                      value: _targetCurrencyController.text,
                      onChanged: (v) {
                        setState(() => _targetCurrencyController.text = v);
                      },
                    ),
                  ),
                ]),
              ]),
              const SizedBox(height: 16),

            // Linked Categories
            _sectionContainer(children: [
                _sectionHeader(l.allocLinkedCategoriesSection),
                Text(
                  l.allocLinkedCategoriesDesc,
                  style: TextStyle(
                      fontSize: 12, color: AppColors.ts(context)),
                ),
                const SizedBox(height: 12),
                if (_linkedCategories.isEmpty && !_isNew)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.pastel(context, AppColors.caution,
                          light: 0.85, dark: 0.75),
                      borderRadius: BorderRadius.circular(RadiusTokens.md),
                    ),
                    child: Row(children: [
                      const Icon(AppIcons.info,
                          size: 16, color: AppColors.caution),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l.allocNoCategoriesLinked,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.caution),
                        ),
                      ),
                    ]),
                  ),
                ..._linkedCategories.map((cat) => Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.sfv(context),
                        borderRadius: BorderRadius.circular(RadiusTokens.md),
                      ),
                      child: Row(children: [
                        CircleAvatar(
                          radius: 6,
                          backgroundColor: AppColors.fromHex(cat.colorHex),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(cat.name,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w500)),
                        ),
                        Tappable(
                          onTap: () => _unlinkCategory(cat.id),
                          borderRadius:
                              BorderRadius.circular(RadiusTokens.md),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(AppIcons.x,
                                size: 16, color: AppColors.th(context)),
                          ),
                        ),
                      ]),
                    )),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _showLinkCategorySheet,
                  icon: const Icon(AppIcons.plus, size: 16),
                  label: Text(l.allocLinkCategory),
                ),
              ]),
            ], // end if (_isNew || _showSettings)

            if (!_isNew) ...[
              const SizedBox(height: 16),
              _buildRecentTransactions(),
              const SizedBox(height: 16),
              _buildSpendingHistory(),
            ],
            const SizedBox(height: 80),
          ],
        ),
      ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Balance hero card
  // ---------------------------------------------------------------------------

  Widget _buildBalanceHero() {
    final targetCurrency = _targetCurrencyController.text.isNotEmpty
        ? _targetCurrencyController.text
        : ref.watch(householdProvider).value?.baseCurrency ?? 'USD';
    final allocAsync = ref.watch(allocationsProvider);
    final alloc = allocAsync.value
        ?.where((a) => a.data.allocation.id == widget.allocationId)
        .firstOrNull;
    final balances = alloc?.balanceByCurrency ?? {};
    final mainBalance = balances[targetCurrency] ?? 0;
    final otherBalances = Map.of(balances)..remove(targetCurrency);
    final hasTarget = _targetAmount > 0;

    // Fully funded → the wax seal (stamped on if it happens here).
    final sealed = ref
            .watch(sealedEnvelopesProvider)
            .value
            ?.contains(widget.allocationId) ??
        false;

    // Cashew budgetPage header: pastel of the envelope's color, dark text,
    // thick progress bar with a pace marker for spending envelopes.
    final envColor = _linkedCategories.isNotEmpty
        ? AppColors.fromHex(_linkedCategories.first.colorHex)
        : AppColors.accent;
    final heroColor = AppColors.pastel(context, envColor, light: 0.8, dark: 0.75);
    final onHero = AppColors.tp(context);
    final isSpending = _type == 'spending';
    final period = BudgetProgress.currentPeriod(
        ref.watch(householdProvider).value?.periodStartDay ?? 1);
    final elapsed = isSpending
        ? BudgetProgress.fractionOfPeriod(period.start, period.end)
        : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
      decoration: BoxDecoration(
        color: heroColor,
        borderRadius: BorderRadius.circular(RadiusTokens.hero),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  S.of(context).allocAvailable,
                  style: TextStyle(
                    color: AppColors.ts(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (sealed)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: Text(S.of(context).sealFullyFunded,
                      style: TextStyle(
                          color: AppColors.ts(context),
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                ),
              SealStamp(sealed: sealed, size: 30),
            ],
          ),
          const SizedBox(height: 2),
          // Balance (pulses after funding)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: AnimatedScale(
              scale: _fundPulse ? 1.08 : 1.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  formatAmount(mainBalance, currency: targetCurrency),
                  style: TextStyle(
                    color: mainBalance < 0 ? AppColors.overspent : onHero,
                    fontSize: 34,
                    fontFamily: TypographyTokens.displayFamily,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
          ),
          // Other currency balances
          for (final entry in otherBalances.entries)
            if (entry.value.abs() > 0.001)
              Text(
                entry.value >= 0
                    ? '+ ${formatAmount(entry.value, currency: entry.key)}'
                    : formatAmount(entry.value, currency: entry.key),
                style: TextStyle(
                  color: entry.value < 0
                      ? AppColors.caution
                      : AppColors.ts(context),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
          // Progress bar + target
          if (hasTarget) ...[
            const SizedBox(height: 16),
            BudgetProgress(
              progress: mainBalance / _targetAmount,
              color: envColor,
              height: 22,
              showPercent: true,
              trackColor: AppColors.pastel(context, envColor,
                  light: 0.62, dark: 0.6),
              overspent: mainBalance < 0,
              // Bar shows what's left: marker = share that should remain.
              todayFraction: elapsed == null ? null : 1 - elapsed,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    S.of(context).objOfTarget(
                        formatAmount(_targetAmount, currency: targetCurrency)),
                    style: TextStyle(
                      color: AppColors.ts(context),
                      fontSize: 13,
                    ),
                  ),
                ),
                Flexible(
                  child: Text(
                    // Spending: what was spent this period (ledger, not
                    // target − balance, which counts unfunded money).
                    // Flexible: how far from the target.
                    isSpending
                        ? S.of(context).allocAmountSpent(formatAmount(
                            ref.watch(periodSpendingProvider).value?[
                                    widget.allocationId]?[targetCurrency] ??
                                0,
                            currency: targetCurrency))
                        : S.of(context).allocAmountToGo(formatAmount(
                            (_targetAmount - mainBalance)
                                .clamp(0, double.infinity),
                            currency: targetCurrency)),
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      color: AppColors.ts(context),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          // Fund button — tonal on the pastel card
          FilledButton.icon(
            onPressed: () => _showFundSheet(targetCurrency),
            icon: const Icon(AppIcons.plus, size: 20),
            label: Text(S.of(context).allocFund),
          ),
        ],
      ),
    );
  }

  Future<void> _showFundSheet(String defaultCurrency) async {
    double amount = 0;
    var selectedCurrency = defaultCurrency;

    // Get available currencies from unallocated balances
    final unallocated = ref.read(unallocatedProvider).value ?? {};
    final availableCurrencies = unallocated.keys.toList();
    if (!availableCurrencies.contains(defaultCurrency)) {
      availableCurrencies.insert(0, defaultCurrency);
    }

    // Quick amounts: what's missing to reach the target, or all of Ready
    // to assign (in the chosen currency).
    final me = (ref.read(allocationsProvider).value ?? const [])
        .where((a) => a.data.allocation.id == widget.allocationId)
        .firstOrNull;
    double gapFor(String cur) {
      final target = me?.data.allocation.targetAmount;
      final targetCur = me?.data.allocation.targetCurrency ?? defaultCurrency;
      if (target == null || cur != targetCur) return 0;
      return (target - (me?.balanceByCurrency[cur] ?? 0))
          .clamp(0.0, double.infinity);
    }

    final tr = S.of(context);
    final textPrimaryColor = AppColors.tp(context);
    final textSecondaryColor = AppColors.ts(context);
    final surfaceVariantColor = AppColors.sfv(context);
    final borderColor = AppColors.bd(context);
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + MediaQuery.of(ctx).viewPadding.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SheetTitle(
                tr.allocFundEnvelope(_nameController.text),
                subtitle: tr.allocFromUnallocated,
                padding: const EdgeInsetsDirectional.only(bottom: 16),
              ),
              // Currency selector
              if (availableCurrencies.length > 1)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: availableCurrencies.map((c) {
                      final isSelected = c == selectedCurrency;
                      final bal = unallocated[c] ?? 0;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Tappable(
                          onTap: () =>
                              setSheetState(() => selectedCurrency = c),
                          borderRadius:
                              BorderRadius.circular(RadiusTokens.md),
                          color: isSelected
                              ? AppColors.accentLight
                              : surfaceVariantColor,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 8),
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(RadiusTokens.md),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.accent
                                    : borderColor,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(c,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected
                                          ? AppColors.accent
                                          : textPrimaryColor,
                                    )),
                                Text(
                                  formatAmount(bal, currency: c),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: textSecondaryColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: surfaceVariantColor,
                      borderRadius: BorderRadius.circular(RadiusTokens.md),
                    ),
                    child: Text(
                      selectedCurrency,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textSecondaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: surfaceVariantColor,
                        borderRadius: BorderRadius.circular(RadiusTokens.md),
                      ),
                      child: CalculatorAmountField(
                        value: amount,
                        onChanged: (v) => setSheetState(() => amount = v),
                        hintText: tr.commonAmount,
                        fontSize: 16,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textPrimaryColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [
                  if (gapFor(selectedCurrency) > 0)
                    ActionChip(
                      label: Text(tr.allocFundToTarget(formatAmount(
                          gapFor(selectedCurrency),
                          currency: selectedCurrency))),
                      onPressed: () => setSheetState(() => amount =
                          double.parse(gapFor(selectedCurrency)
                              .toStringAsFixed(2))),
                    ),
                  if ((unallocated[selectedCurrency] ?? 0) > 0)
                    ActionChip(
                      label: Text(tr.allocFundAllAvailable(formatAmount(
                          unallocated[selectedCurrency]!,
                          currency: selectedCurrency))),
                      onPressed: () => setSheetState(() => amount =
                          double.parse(unallocated[selectedCurrency]!
                              .toStringAsFixed(2))),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(
                      ctx, {'amount': amount, 'currency': selectedCurrency}),
                  child: Text(tr.allocFund),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (result == null || !mounted) return;
    final fundAmount = (result['amount'] as double?) ?? 0;
    final fundCurrency = result['currency'] as String? ?? defaultCurrency;
    if (fundAmount <= 0) return;

    // Check if funding exceeds unallocated balance
    final unallocBal = ref.read(unallocatedProvider).value ?? {};
    final available = unallocBal[fundCurrency] ?? 0.0;
    if (fundAmount > available + 0.01 && mounted) {
      final deficit = fundAmount - available;
      final tr = S.of(context);
      final proceed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(tr.allocOverFundingTitle),
          content: Text(
            tr.allocOverFundingMsg(
              formatAmount(deficit, currency: fundCurrency),
              formatAmount(available, currency: fundCurrency),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(tr.commonCancel),
            ),
            FilledButton(
              style: DialogButtons.filled,
              onPressed: () => Navigator.pop(context, true),
              child: Text(tr.allocFundAnyway),
            ),
          ],
        ),
      );
      if (proceed != true || !mounted) return;
    }

    try {
      final engine = ref.read(allocationEngineProvider);
      await engine.fundAllocation(
        allocationId: widget.allocationId,
        amount: fundAmount,
        currency: fundCurrency,
        deviceId: 'local',
        note: S.of(context).allocFundedNote,
      );
      if (!mounted) return;
      ref.invalidate(allocationsProvider);
      ref.invalidate(unallocatedProvider);
      if (mounted) {
        // Trigger balance pulse animation
        setState(() => _fundPulse = true);
        Future.delayed(const Duration(milliseconds: 350), () {
          if (mounted) setState(() => _fundPulse = false);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                S.of(context).allocFundedSuccess(formatAmount(fundAmount, currency: fundCurrency), _nameController.text)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).allocFundError),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Recent transactions (last 5)
  // ---------------------------------------------------------------------------

  Widget _buildRecentTransactions() {
    final db = ref.watch(databaseProvider);
    final ledgerDao = LedgerDao(db);

    return _sectionContainer(children: [
      Row(children: [
        Expanded(
          child: _sectionHeader(S.of(context).allocRecentActivity),
        ),
        Builder(builder: (_) {
          // Its linked category (top level first) — the Activity tab filter
          // also matches subcategories.
          final linked = (ref.watch(categoriesProvider).value ?? const [])
              .where((c) => c.allocationId == widget.allocationId)
              .toList()
            ..sort((a, b) => (a.parentId == null ? 0 : 1)
                .compareTo(b.parentId == null ? 0 : 1));
          if (linked.isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextButton(
              onPressed: () {
                ref.read(activityFilterRequestProvider.notifier).request((
                  accountId: null,
                  categoryId: linked.first.id,
                  categoryName: linked.first.name,
                ));
                context.go('/');
              },
              child: Text(S.of(context).commonSeeAll),
            ),
          );
        }),
      ]),
      StreamBuilder<List<({AllocationLedgerData entry, DateTime date})>>(
        stream: ledgerDao.watchByAllocation(widget.allocationId),
        builder: (context, snapshot) {
          final ledgerEntries = snapshot.data;
          if (ledgerEntries == null) {
            return const SkeletonList(count: 3);
          }

          final recent = ledgerEntries.take(8).toList();

          if (recent.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(S.of(context).allocNoActivity,
                    style:
                        TextStyle(fontSize: 13, color: AppColors.th(context))),
              ),
            );
          }

          return Column(
            children: recent.map((row) {
              final entry = row.entry;
              final isPositive = entry.amount > 0;
              final color =
                  isPositive ? AppColors.healthy : AppColors.overspent;

              final sl = S.of(context);
              final label = switch (entry.entryType) {
                'funding' => sl.allocEntryFunded,
                'consumption' => sl.allocEntrySpent,
                'adjustment' => sl.allocEntryAdjustment,
                'period_reset' => sl.allocEntryPeriodReset,
                'carry_forward' => sl.allocEntryCarryForward,
                'withdrawal' => sl.allocEntryWithdrawn,
                'revaluation' => sl.allocEntryRevaluation,
                'transfer' => sl.allocEntryMoved,
                _ => sl.allocEntryAdjustment,
              };

              final icon = switch (entry.entryType) {
                'funding' => AppIcons.plusCircle,
                'consumption' => AppIcons.minusCircle,
                'adjustment' => AppIcons.slidersHorizontal,
                'period_reset' => AppIcons.arrowClockwise,
                'carry_forward' => AppIcons.arrowBendUpRight,
                'withdrawal' => AppIcons.tray,
                'revaluation' => AppIcons.currencyCircleDollar,
                'transfer' => AppIcons.arrowsLeftRight,
                _ => AppIcons.circle,
              };

              // A spending row opens its transaction.
              final txId = entry.sourceTransactionId;
              return Tappable(
                borderRadius: BorderRadius.circular(RadiusTokens.md),
                onTap: txId == null
                    ? null
                    : () => context.push('/transactions/$txId'),
                child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.pastel(context, color,
                            light: 0.82, dark: 0.7),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 18, color: color),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.note.isNotEmpty ? entry.note : label,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            // Only repeat the type when a note took the title.
                            entry.note.isNotEmpty
                                ? '${formatDate(row.date.toLocal())} · $label'
                                : formatDate(row.date.toLocal()),
                            style: TextStyle(
                                fontSize: TypographyTokens.txSubtitleSize,
                                color: AppColors.ts(context)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${isPositive ? '+' : ''}${formatAmount(entry.amount, currency: entry.currency)}',
                      style: TextStyle(
                          fontSize: TypographyTokens.amountRegularSize,
                          fontWeight: TypographyTokens.amountRegularWeight,
                          color: color),
                    ),
                  ],
                ),
              ));
            }).toList(),
          );
        },
      ),
    ]);
  }

  // ---------------------------------------------------------------------------
  // Spending history: last 3 months bar chart
  // ---------------------------------------------------------------------------

  Widget _buildSpendingHistory() {
    final entriesAsync = ref.watch(transactionEntriesProvider);
    final linkedCatIds = _linkedCategories.map((c) => c.id).toSet();

    if (linkedCatIds.isEmpty) return const SizedBox.shrink();

    return entriesAsync.when(
      data: (entries) {
        final now = DateTime.now();
        // Build last 3 months
        final months = List.generate(3, (i) {
          final d = DateTime(now.year, now.month - (2 - i), 1);
          return d;
        });

        final totals = <DateTime, double>{};
        for (final m in months) {
          totals[m] = 0;
        }

        final targetCurrency = _targetCurrencyController.text;
        for (final e in entries) {
          if (e.tx.type != 'expense') continue;
          final txDate = e.tx.createdAt.toLocal();

          // Sum matching line amounts in the envelope's target currency
          if (e.lines.isNotEmpty) {
            for (final l in e.lines) {
              if (linkedCatIds.contains(l.categoryId) &&
                  l.currency == targetCurrency) {
                for (final m in months) {
                  if (txDate.year == m.year && txDate.month == m.month) {
                    totals[m] = (totals[m] ?? 0) + l.amount;
                    break;
                  }
                }
              }
            }
          } else if (linkedCatIds.contains(e.tx.categoryId) &&
              e.tx.currency == targetCurrency) {
            for (final m in months) {
              if (txDate.year == m.year && txDate.month == m.month) {
                totals[m] = (totals[m] ?? 0) + e.tx.amount;
                break;
              }
            }
          }
        }

        final maxVal = totals.values.fold<double>(0, (a, b) => math.max(a, b));
        if (maxVal == 0) return const SizedBox.shrink();

        return _sectionContainer(children: [
          _sectionHeader(S.of(context).allocSpendingHistory),
          const SizedBox(height: 4),
          // Sized by its content: a fixed height overflowed at larger text
          // sizes.
          Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: months.map((m) {
                final val = totals[m] ?? 0;
                final fraction = maxVal > 0 ? (val / maxVal) : 0.0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          formatAmount(val, currency: _targetCurrencyController.text),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ts(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOut,
                          height: (60 * fraction).clamp(4.0, 60.0),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius:
                                BorderRadius.circular(RadiusTokens.sm),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          DateFormat('MMM').format(m),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ts(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ]);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  // ---------------------------------------------------------------------------
  // Withdraw from savings envelope
  // ---------------------------------------------------------------------------

  /// This envelope's balance in its target currency (0 without one).
  double _targetBalance() {
    final currency = _targetCurrencyController.text;
    if (currency.isEmpty) return 0;
    final all = ref.read(allocationsProvider).value ?? const [];
    final me = all
        .where((a) => a.data.allocation.id == widget.allocationId)
        .firstOrNull;
    return me?.balanceByCurrency[currency] ?? 0;
  }

  /// Move money out of this envelope — or, when it's overspent, cover it.
  Future<void> _moveMoney() async {
    final currency = _targetCurrencyController.text.isNotEmpty
        ? _targetCurrencyController.text
        : null;
    final bal = _targetBalance();
    // The sheet invalidates the allocation providers this screen watches.
    bal < 0
        ? await showMoveMoneySheet(context, ref,
            toId: widget.allocationId,
            currency: currency,
            amount: -bal,
            cover: true)
        : await showMoveMoneySheet(context, ref,
            fromId: widget.allocationId, currency: currency);
  }

  Future<void> _showWithdrawSheet() async {
    double withdrawAmount = 0;
    final currency = _targetCurrencyController.text;

    final tr = S.of(context);
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + MediaQuery.of(ctx).viewPadding.bottom + 20),
          decoration: BoxDecoration(
            color: AppColors.popup(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(RadiusTokens.sheet)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SheetTitle(
                tr.allocWithdrawTitle,
                subtitle: tr.allocWithdrawDesc,
                padding: const EdgeInsetsDirectional.only(bottom: 16),
              ),
              CalculatorAmountField(
                value: withdrawAmount,
                label: tr.allocWithdrawAmountLabel,
                currency: currency,
                fontSize: 22,
                onChanged: (v) => setSheetState(() => withdrawAmount = v),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(tr.commonCancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: withdrawAmount > 0
                          ? () => Navigator.pop(ctx, true)
                          : null,
                      child: Text(tr.allocWithdrawButton),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true && withdrawAmount > 0 && mounted) {
      try {
        final engine = ref.read(allocationEngineProvider);
        await engine.withdrawFromAllocation(
          allocationId: widget.allocationId,
          amount: withdrawAmount,
          currency: currency,
        );
        if (!mounted) return;
        ref.invalidate(allocationsProvider);
        ref.invalidate(unallocatedProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                S.of(context).allocWithdrawSuccess(formatAmount(withdrawAmount, currency: currency))),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        debugPrint('[AllocationDetail] Withdraw failed: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              // StateError = the envelope holds less than asked.
              content: Text(e is StateError
                  ? S.of(context).allocWithdrawTooMuch
                  : S.of(context).commonErrorDesc),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Category linking
  // ---------------------------------------------------------------------------

  Future<void> _showLinkCategorySheet() async {
    final allCategories = ref.read(categoriesProvider).value ?? [];
    final linkedIds = _linkedCategories.map((c) => c.id).toSet();
    final available = allCategories
        .where((c) =>
            c.allocationId == null && !linkedIds.contains(c.id))
        .toList();

    if (available.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).allocAllCategoriesLinked),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final tr = S.of(context);
    final linkHintColor = AppColors.th(context);
    final linkTextPrimary = AppColors.tp(context);
    final linkTextSecondary = AppColors.ts(context);
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        var search = '';
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final filtered = search.isEmpty
                ? available
                : available
                    .where((c) =>
                        c.name.toLowerCase().contains(search.toLowerCase()))
                    .toList();

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.7,
              ),
              decoration: BoxDecoration(
                color: AppColors.popup(context),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(RadiusTokens.sheet)),
              ),
              child: Column(
                children: [
                  SheetTitle(tr.allocLinkCategoryTitle),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Column(
                      children: [
                        TextField(
                          onChanged: (v) =>
                              setSheetState(() => search = v),
                          textInputAction: TextInputAction.search,
                          style: TextStyle(
                              fontSize: 14,
                              color: linkTextPrimary),
                          decoration: InputDecoration(
                            hintText: tr.allocSearchCategories,
                            hintStyle: TextStyle(
                                color: linkHintColor),
                            prefixIcon: Icon(AppIcons.magnifyingGlass,
                                size: 18,
                                color: linkHintColor),
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 10),
                            isDense: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Text(tr.allocNoMatchingCategories,
                                style: TextStyle(
                                    color: linkTextSecondary)))
                        : ListView.builder(
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            padding:
                                const EdgeInsets.fromLTRB(16, 0, 16, 20),
                            itemCount: filtered.length,
                            itemBuilder: (_, i) {
                              final cat = filtered[i];
                              final color =
                                  AppColors.fromHex(cat.colorHex);
                              final hasEmoji = cat.icon.length <= 4 &&
                                  cat.icon != 'category';
                              return Tappable(
                                onTap: () =>
                                    Navigator.pop(ctx, cat.id),
                                borderRadius:
                                    BorderRadius.circular(RadiusTokens.md),
                                child: Container(
                                  margin:
                                      const EdgeInsets.only(bottom: 4),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  child: Row(
                                    children: [
                                      CategoryIcon(
                                        categoryName: cat.name,
                                        emoji: hasEmoji
                                            ? cat.icon
                                            : null,
                                        color: color,
                                        size: CategoryIconTokens.compactSize,
                                        circular: true,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(cat.name,
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight:
                                                        FontWeight.w500,
                                                    color:
                                                        linkTextPrimary)),
                                            Text(
                                              cat.transactionType == 'income'
                                                  ? S.of(context).typeIncome
                                                  : S.of(context).typeExpense,
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: linkTextSecondary),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (selected != null && mounted) {
      if (_isNew) {
        // The envelope doesn't exist yet — stage the link in memory and
        // persist it in _save() once the real id is generated. (Writing now
        // would link the category to the literal 'new' id and orphan it.)
        final cat = (ref.read(categoriesProvider).value ?? [])
            .where((c) => c.id == selected)
            .firstOrNull;
        if (cat != null) {
          setState(() => _linkedCategories = [..._linkedCategories, cat]);
        }
        return;
      }
      final db = ref.read(databaseProvider);
      await AllocationsDao(db)
          .linkCategory(selected, widget.allocationId);
      ref.invalidate(categoriesProvider);
      await _loadAllocation();
    }
  }

  Future<void> _unlinkCategory(String categoryId) async {
    if (_isNew) {
      setState(() => _linkedCategories =
          _linkedCategories.where((c) => c.id != categoryId).toList());
      return;
    }
    final db = ref.read(databaseProvider);
    await AllocationsDao(db).unlinkCategory(categoryId);
    ref.invalidate(categoriesProvider);
    await _loadAllocation();
  }

  // ---------------------------------------------------------------------------
  // Revalue foreign balances
  // ---------------------------------------------------------------------------

  Future<void> _showRevalueSheet() async {
    final db = ref.read(databaseProvider);
    final targetCurrency = _targetCurrencyController.text;

    // Get all ledger entries for this allocation
    final entries = await (db.select(db.allocationLedger)
          ..where((t) => t.allocationId.equals(widget.allocationId)))
        .get();

    // Group foreign-currency entries: currency -> list of entries
    final Map<String, List<AllocationLedgerData>> foreignEntries = {};
    for (final e in entries) {
      if (e.currency != targetCurrency) {
        foreignEntries.putIfAbsent(e.currency, () => []).add(e);
      }
    }

    if (foreignEntries.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).allocNoForeignBalances),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    // Build data for the sheet: for each foreign currency, compute
    // the net foreign amount and weighted-average original rate.
    final List<_ForeignBalance> foreignBalances = [];
    for (final entry in foreignEntries.entries) {
      final currency = entry.key;
      final ledgerList = entry.value;

      double totalForeignAmount = 0;
      double totalTargetValue = 0;

      for (final e in ledgerList) {
        totalForeignAmount += e.amount;
        totalTargetValue += e.amount * e.exchangeRateToBase;
      }

      if (totalForeignAmount.abs() < 0.0001) continue;

      final weightedAvgRate = totalForeignAmount != 0
          ? totalTargetValue / totalForeignAmount
          : 1.0;

      foreignBalances.add(_ForeignBalance(
        currency: currency,
        amount: totalForeignAmount,
        originalRate: weightedAvgRate,
        originalValue: totalTargetValue,
      ));
    }

    if (foreignBalances.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).allocNoForeignBalances),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    final fxService = ref.read(fxServiceProvider);

    final applied = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _RevalueSheet(
        foreignBalances: foreignBalances,
        targetCurrency: targetCurrency,
        allocationId: widget.allocationId,
        fxService: fxService,
        db: db,
      ),
    );

    if (applied == true && mounted) {
      ref.invalidate(allocationsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).allocRevalApplied),
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {}); // refresh
    }
  }

  // ---------------------------------------------------------------------------
  // Archive
  // ---------------------------------------------------------------------------

  Future<void> _confirmArchive() async {
    final tr = S.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: tr.allocArchiveTitle,
      message: tr.allocArchiveMsg,
      confirmLabel: tr.commonArchive,
      destructive: false,
    );
    if (!confirmed || !mounted) return;
    await _archive();
  }

  /// Archive this envelope, tell the user, and leave the screen.
  Future<void> _archive() async {
    final tr = S.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final db = ref.read(databaseProvider);
      await AllocationsDao(db).archive(widget.allocationId);
      ref.invalidate(allocationsProvider);
      messenger.showSnackBar(SnackBar(
        content: Text(tr.allocArchived),
        behavior: SnackBarBehavior.floating,
      ));
      if (mounted) context.pop();
    } catch (e) {
      debugPrint('[AllocationDetail] Archive failed: $e');
      messenger.showSnackBar(SnackBar(
        content: Text(tr.commonSomethingWentWrong),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  // ---------------------------------------------------------------------------
  // Delete with safeguards
  // ---------------------------------------------------------------------------

  Future<void> _confirmDelete() async {
    final db = ref.read(databaseProvider);
    final dao = AllocationsDao(db);

    // Count linked categories.
    final linked = await dao.linkedCategories(widget.allocationId);
    final linkedCount = linked.length;

    if (!mounted) return;

    final warnings = <String>[];
    if (linkedCount > 0) {
      final names = linked.take(3).map((c) => c.name).join(', ');
      final suffix = linkedCount > 3
          ? ' ${S.of(context).allocDeleteAndMore(linkedCount - 3)}'
          : '';
      warnings.add(
          S.of(context).allocDeleteLinkedWarning(linkedCount, '$names$suffix'));
    }

    final tr = S.of(context);
    String? action;
    if (warnings.isNotEmpty) {
      action = await showDialog<String>(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          title: Text(tr.allocDeleteTitle),
          content: Text(
            '${warnings.join('. ')}.\n\n'
            '${tr.allocDeleteConsequences}',
          ),
          actions: [
            OutlinedButton(
              style: DialogButtons.outlined,
              onPressed: () => Navigator.pop(dialogCtx, 'cancel'),
              child: Text(tr.commonCancel),
            ),
            OutlinedButton(
              style: DialogButtons.outlined,
              onPressed: () => Navigator.pop(dialogCtx, 'archive'),
              child: Text(tr.allocArchiveInstead),
            ),
            FilledButton(
              style: DialogButtons.destructive,
              onPressed: () => Navigator.pop(dialogCtx, 'delete'),
              child: Text(tr.commonDelete),
            ),
          ],
        ),
      );
    } else {
      // No linked categories -- simple confirmation.
      final confirmed = await showConfirmDialog(
        context,
        title: tr.allocDeleteNoLinksTitle,
        message: tr.allocDeleteNoLinksMsg,
        confirmLabel: tr.commonDelete,
      );
      if (confirmed) action = 'delete';
    }

    if (!mounted) return;
    if (action == 'archive') {
      await _archive();
      return;
    }
    if (action != 'delete') return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      for (final cat in linked) {
        await dao.unlinkCategory(cat.id);
      }
      await (db.update(db.allocations)
            ..where((a) => a.id.equals(widget.allocationId)))
          .write(AllocationsCompanion(
              deleted: const Value(true),
              lastModified: Value(DateTime.now())));
      ref.invalidate(allocationsProvider);
      ref.invalidate(categoriesProvider);
      messenger.showSnackBar(SnackBar(
        content: Text(tr.allocDeleted),
        behavior: SnackBarBehavior.floating,
      ));
      if (mounted) context.pop();
    } catch (e) {
      debugPrint('[AllocationDetail] Delete failed: $e');
      messenger.showSnackBar(SnackBar(
        content: Text(tr.allocDeleteError),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  // ---------------------------------------------------------------------------
  // Save
  // ---------------------------------------------------------------------------

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null) return;

    setState(() => _loading = true);
    try {
      final db = ref.read(databaseProvider);
      final dao = AllocationsDao(db);
      final allocId = _isNew ? const Uuid().v4() : widget.allocationId;

      // For existing envelopes, preserve the linked category.
      // For new envelopes, use allocId as placeholder categoryId
      // (required by schema). User should link real categories after creation.
      String categoryId;
      if (_isNew) {
        categoryId = allocId; // placeholder, will be replaced when user links categories
      } else {
        final existing = await dao.getById(allocId);
        categoryId = existing?.categoryId ?? allocId;
      }

      final targetAmount =
          _targetAmount > 0 ? _targetAmount : null;
      final targetCurrency = _targetCurrencyController.text.trim();
      final effectivePeriodicity = _periodicity;

      await dao.upsert(AllocationsCompanion.insert(
        id: allocId,
        householdId: householdId,
        name: name,
        categoryId: categoryId,
        type: Value(_type),
        periodicity: Value(effectivePeriodicity),
        rollover: Value(_rollover),
        autoReset: Value(_autoReset),
        icon: Value(_icon),
        targetAmount: Value(targetAmount),
        targetCurrency: Value(targetCurrency.isEmpty ? null : targetCurrency),
        deviceId: 'local',
      ));
      // Persist the categories the user linked during creation, now that the
      // real allocation id exists.
      if (_isNew) {
        for (final cat in _linkedCategories) {
          await dao.linkCategory(cat.id, allocId);
        }
      }
      ref.invalidate(categoriesProvider);
      ref.invalidate(allocationsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isNew ? S.of(context).allocEnvelopeCreated : S.of(context).allocEnvelopeUpdated),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } catch (e) {
      debugPrint('[AllocationDetail] Save failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(S.of(context).commonSomethingWentWrong),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

// =============================================================================
// Revalue Foreign Balances
// =============================================================================

class _ForeignBalance {
  final String currency;
  final double amount;
  final double originalRate;
  final double originalValue;

  const _ForeignBalance({
    required this.currency,
    required this.amount,
    required this.originalRate,
    required this.originalValue,
  });
}

class _RevalueSheet extends StatefulWidget {
  final List<_ForeignBalance> foreignBalances;
  final String targetCurrency;
  final String allocationId;
  final dynamic fxService; // FxService
  final AppDatabase db;

  const _RevalueSheet({
    required this.foreignBalances,
    required this.targetCurrency,
    required this.allocationId,
    required this.fxService,
    required this.db,
  });

  @override
  State<_RevalueSheet> createState() => _RevalueSheetState();
}

class _RevalueSheetState extends State<_RevalueSheet> {
  // Map from currency -> new rate entered by user
  final Map<String, double> _newRates = {};
  bool _applying = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill new rates with original rates
    for (final fb in widget.foreignBalances) {
      _newRates[fb.currency] = fb.originalRate;
    }
  }

  double _newValue(_ForeignBalance fb) {
    final rate = _newRates[fb.currency] ?? fb.originalRate;
    return fb.amount * rate;
  }

  double _gain(_ForeignBalance fb) {
    return _newValue(fb) - fb.originalValue;
  }

  double _totalGain() {
    double total = 0;
    for (final fb in widget.foreignBalances) {
      total += _gain(fb);
    }
    return total;
  }

  bool _hasChanges() {
    for (final fb in widget.foreignBalances) {
      final gain = _gain(fb);
      if (gain.abs() > 0.01) return true;
    }
    return false;
  }

  Future<void> _fetchRate(String foreignCurrency) async {
    try {
      final rate = await widget.fxService
          .getRateWithCache(foreignCurrency, widget.targetCurrency);
      if (mounted) {
        setState(() {
          _newRates[foreignCurrency] = rate;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).allocFetchRateError(foreignCurrency)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _apply() async {
    if (_applying) return;
    setState(() => _applying = true);

    try {
      final ledgerDao = LedgerDao(widget.db);
      final revaluationNote = S.of(context).allocRevaluationNote;
      final uuid = const Uuid();

      for (final fb in widget.foreignBalances) {
        final gain = _gain(fb);
        if (gain.abs() < 0.01) continue;

        await ledgerDao.appendEntry(AllocationLedgerCompanion.insert(
          id: uuid.v4(),
          allocationId: widget.allocationId,
          entryType: 'revaluation',
          amount: gain,
          currency: widget.targetCurrency,
          exchangeRateToBase: Value(1.0),
          // Rates are plain numbers, not money (no currency symbol).
          note: Value(revaluationNote(
            formatAmount(fb.amount, currency: fb.currency),
            _rateText(_newRates[fb.currency] ?? fb.originalRate),
            _rateText(fb.originalRate),
          )),
          deviceId: 'local',
        ));
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).allocRevalError),
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => _applying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _totalGain();
    final hasChanges = _hasChanges();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      decoration: BoxDecoration(
        color: AppColors.popup(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(RadiusTokens.sheet)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetTitle(S.of(context).allocRevalueForeignTitle),
          // Content
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              children: [
                for (final fb in widget.foreignBalances) ...[
                  _buildCurrencyCard(fb),
                  const SizedBox(height: 12),
                ],
                // Total summary
                if (widget.foreignBalances.length > 1) ...[
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        S.of(context).allocTotalAdjustment,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.tp(context),
                        ),
                      ),
                      Text(
                        '${total >= 0 ? '+' : ''}${formatAmount(total, currency: widget.targetCurrency)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: total >= 0
                              ? AppColors.healthy
                              : AppColors.overspent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
          // Apply button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: (hasChanges && !_applying) ? _apply : null,
                  child: _applying
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: AppColors.onAccent, strokeWidth: 2))
                      : Text(S.of(context).allocApplyRevaluation),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyCard(_ForeignBalance fb) {
    final newRate = _newRates[fb.currency] ?? fb.originalRate;
    final newValue = _newValue(fb);
    final gain = _gain(fb);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.sfv(context),
        borderRadius: BorderRadius.circular(CardTokens.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Currency header
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.pastel(context, AppColors.accent,
                      light: 0.85, dark: 0.78),
                  borderRadius: BorderRadius.circular(RadiusTokens.sm),
                ),
                child: Text(
                  fb.currency,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  S.of(context).allocBalanceInEnvelope,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.ts(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Foreign amount
          Text(
            formatAmount(fb.amount, currency: fb.currency),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.tp(context),
            ),
          ),
          const SizedBox(height: 14),
          // Original rate & value
          _infoRow(
            S.of(context).allocOriginalRate,
            _rateText(fb.originalRate),
          ),
          const SizedBox(height: 4),
          _infoRow(
            S.of(context).allocOriginalValue,
            formatAmount(fb.originalValue, currency: widget.targetCurrency),
          ),
          const SizedBox(height: 14),
          // New rate input
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: CalculatorAmountField(
                  value: newRate,
                  label: S.of(context).allocNewRate,
                  fontSize: 18,
                  onChanged: (v) {
                    setState(() {
                      _newRates[fb.currency] = v;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 42,
                child: OutlinedButton.icon(
                  onPressed: () => _fetchRate(fb.currency),
                  icon: const Icon(AppIcons.arrowsClockwise, size: 16),
                  label: Text(S.of(context).allocFetch),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 42),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // New value
          _infoRow(
            S.of(context).allocNewValue,
            formatAmount(newValue, currency: widget.targetCurrency),
            bold: true,
          ),
          const SizedBox(height: 6),
          // Gain/loss
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: gain >= 0
                  ? AppColors.pastel(context, AppColors.healthy,
                      light: 0.88, dark: 0.78)
                  : AppColors.pastel(context, AppColors.overspent,
                      light: 0.88, dark: 0.78),
              borderRadius: BorderRadius.circular(RadiusTokens.md),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  gain >= 0 ? S.of(context).allocGain : S.of(context).allocLoss,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color:
                        gain >= 0 ? AppColors.healthy : AppColors.overspent,
                  ),
                ),
                Text(
                  '${gain >= 0 ? '+' : ''}${formatAmount(gain, currency: widget.targetCurrency)}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color:
                        gain >= 0 ? AppColors.healthy : AppColors.overspent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.ts(context),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: AppColors.tp(context),
          ),
        ),
      ],
    );
  }
}

/// An exchange rate for display: 4 decimals for small rates, 2 for large.
String _rateText(double rate) =>
    formatNumber(rate, decimals: rate >= 100 ? 2 : 4);
