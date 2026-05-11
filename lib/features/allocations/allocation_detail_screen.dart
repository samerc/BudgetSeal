import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import 'package:intl/intl.dart';

import '../../core/providers/date_format_provider.dart';

import '../../core/database/app_database.dart';
import '../../core/database/daos/allocations_dao.dart';
import '../../core/database/daos/ledger_dao.dart';
import '../../core/providers/allocations_provider.dart';
import '../../core/providers/categories_provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/engine_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../core/providers/transactions_provider.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/design_tokens.dart';
import '../../shared/widgets/currency_picker_field.dart';
import '../../shared/utils/format_number.dart';
import '../../shared/widgets/calculator_amount_field.dart';
import '../../shared/widgets/category_icon.dart';

class AllocationDetailScreen extends ConsumerStatefulWidget {
  final String allocationId;
  const AllocationDetailScreen({super.key, required this.allocationId});

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
  final _confettiCtrl = ConfettiController(duration: const Duration(seconds: 2));
  bool _confettiPlayed = false;
  List<Category> _linkedCategories = [];
  /// For the creation flow: distinguishes saving-with-goal from saving-open.

  bool get _isNew => widget.allocationId == 'new';

  @override
  void initState() {
    super.initState();
    final baseCurrency =
        ref.read(householdProvider).value?.baseCurrency ?? 'USD';
    _targetCurrencyController.text = baseCurrency;
    if (!_isNew) _loadAllocation();
  }

  Future<void> _loadAllocation() async {
    final db = ref.read(databaseProvider);
    final dao = AllocationsDao(db);
    final alloc = await dao.getById(widget.allocationId);
    if (alloc != null && mounted) {
      final linked = await dao.linkedCategories(widget.allocationId);
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
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetCurrencyController.dispose();
    _confettiCtrl.dispose();
    super.dispose();
  }

  static final _sectionRadius = BorderRadius.circular(CardTokens.radius);
  static const _inputRadius = BorderRadius.all(Radius.circular(12));

  InputDecoration _inputDecoration(String label, {Widget? prefixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: AppColors.ts(context), fontSize: 14),
      floatingLabelStyle: TextStyle(
          color: AppColors.accent, fontWeight: FontWeight.w600),
      filled: true,
      fillColor: AppColors.sfv(context),
      prefixIcon: prefixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
          borderRadius: _inputRadius, borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: _inputRadius, borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: _inputRadius,
          borderSide: BorderSide(color: AppColors.accent, width: 1.5)),
    );
  }

  Widget _sectionContainer({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: _sectionRadius,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _sectionHeader(String label, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: AppColors.accent),
          const SizedBox(width: 8),
        ],
        Text(label,
            style: TextStyle(
                fontSize: TypographyTokens.sectionHeaderSize,
                fontWeight: TypographyTokens.sectionHeaderWeight,
                color: AppColors.ts(context),
                letterSpacing: TypographyTokens.sectionHeaderLetterSpacing)),
      ]),
    );
  }

  Widget _buildSegmentedSelector<T>({
    required List<(T, String, IconData)> options,
    required T selected,
    required ValueChanged<T> onChanged,
  }) {
    return Row(children: [
      for (int i = 0; i < options.length; i++) ...[
        if (i > 0) const SizedBox(width: 8),
        Expanded(
          child: _SegmentChip(
            label: options[i].$2,
            icon: options[i].$3,
            isSelected: selected == options[i].$1,
            onTap: () => onChanged(options[i].$1),
          ),
        ),
      ],
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final envelopeName = _nameController.text.isNotEmpty
        ? _nameController.text
        : 'Envelope';

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(_isNew ? 'New Envelope' : envelopeName,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          if (!_isNew)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (v) {
                if (v == 'settings') {
                  setState(() => _showSettings = !_showSettings);
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
                    Icon(Icons.settings_outlined,
                        size: 18, color: AppColors.ts(context)),
                    const SizedBox(width: 10),
                    const Text('Edit Settings'),
                  ]),
                ),
                if (_type == 'saving' || _type == 'flexible')
                  PopupMenuItem(
                    value: 'withdraw',
                    child: Row(children: [
                      Icon(Icons.output_rounded,
                          size: 18, color: AppColors.accent),
                      const SizedBox(width: 10),
                      const Text('Withdraw'),
                    ]),
                  ),
                PopupMenuItem(
                  value: 'revalue',
                  child: Row(children: [
                    Icon(Icons.currency_exchange_rounded,
                        size: 18, color: AppColors.accent),
                    const SizedBox(width: 10),
                    const Text('Revalue Balances'),
                  ]),
                ),
                PopupMenuItem(
                  value: 'archive',
                  child: Row(children: [
                    Icon(Icons.archive_outlined,
                        size: 18, color: AppColors.caution),
                    const SizedBox(width: 10),
                    Text('Archive',
                        style: TextStyle(color: AppColors.caution)),
                  ]),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [
                    Icon(Icons.delete_forever_rounded,
                        size: 18, color: AppColors.overspent),
                    const SizedBox(width: 10),
                    Text('Delete',
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
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(CardTokens.radius)),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(_isNew ? 'Create Envelope' : 'Save Changes',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            )
          : null,
      body: Stack(
        children: [
          SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
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
              _sectionHeader('NAME & ICON', icon: Icons.label_outline_rounded),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() {
                      _showEmojiGrid = !_showEmojiGrid;
                      if (_showEmojiGrid) FocusScope.of(context).unfocus();
                    }),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _showEmojiGrid
                              ? AppColors.accent
                              : AppColors.accent.withValues(alpha: 0.3),
                          width: _showEmojiGrid ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: _icon != null
                            ? Text(_icon!, style: const TextStyle(fontSize: 24))
                            : Icon(Icons.add_reaction_outlined,
                                size: 22, color: AppColors.accent),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      decoration:
                          _inputDecoration('Envelope name (e.g. Groceries)'),
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.done,
                      autofocus: _isNew && !_showEmojiGrid,
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
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => setState(() {
                        _icon = null;
                        _showEmojiGrid = false;
                      }),
                      child: const Text('Remove icon',
                          style: TextStyle(fontSize: 12)),
                    ),
                  ),
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppColors.sfv(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.bd(context)),
                  ),
                  child: ListView(
                    padding: const EdgeInsets.all(10),
                    children: _emojiGroups.entries.map((group) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 6),
                            child: Text(group.key,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ts(context),
                                  letterSpacing: 0.5,
                                )),
                          ),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: group.value.map((e) {
                              final isSelected = e == _icon;
                              return GestureDetector(
                                onTap: () => setState(() {
                                  _icon = e;
                                  _showEmojiGrid = false;
                                }),
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.accent.withValues(alpha: 0.15)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    border: isSelected
                                        ? Border.all(
                                            color: AppColors.accent, width: 2)
                                        : null,
                                  ),
                                  child: Center(
                                    child: Text(e,
                                        style: const TextStyle(fontSize: 20)),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ]),
            const SizedBox(height: 16),

            // Envelope Type Selection
            if (_isNew) ...[
              _sectionContainer(children: [
                _sectionHeader('ENVELOPE TYPE', icon: Icons.category_outlined),
                _buildTypeOptionCard(
                  icon: Icons.shopping_bag_rounded,
                  title: 'Spending',
                  description: 'For recurring expenses like groceries or fuel. Set a monthly budget and spend from it.',
                  isSelected: _type == 'spending',
                  onTap: () => setState(() {
                    _type = 'spending';
                    _periodicity = 'periodic';
                  }),
                ),
                const SizedBox(height: 8),
                _buildTypeOptionCard(
                  icon: Icons.tune_rounded,
                  title: 'Flexible',
                  description: 'For anything else — set an optional target or leave it open. Accumulates over time.',
                  isSelected: _type == 'flexible' || _type == 'saving',
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
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded,
                          size: 16, color: AppColors.ts(context)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Envelopes plan how to use your money. To save toward a goal or track debts, use Goals & Loans instead.',
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
                _sectionHeader('PURPOSE', icon: Icons.category_outlined),
                _buildSegmentedSelector<String>(
                  options: const [
                    ('spending', 'Spending', Icons.shopping_bag_outlined),
                    ('flexible', 'Flexible', Icons.tune_rounded),
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
                _sectionHeader('CYCLE', icon: Icons.autorenew_rounded),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    '• Periodic: resets each month (e.g. groceries budget)\n'
                    '• Permanent: accumulates over time (e.g. emergency fund)',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.ts(context), height: 1.5),
                  ),
                ),
                _buildSegmentedSelector<String>(
                  options: const [
                    ('periodic', 'Periodic', Icons.event_repeat_rounded),
                    ('permanent', 'Permanent', Icons.all_inclusive_rounded),
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
                      Icon(Icons.replay_rounded,
                          size: 20, color: AppColors.ts(context)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Rollover balance',
                                  style: TextStyle(
                                      color: AppColors.tp(context),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500)),
                              Text('Carry remaining funds to the next period',
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
                      Icon(Icons.auto_mode_rounded,
                          size: 20, color: AppColors.ts(context)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Auto-reset',
                                  style: TextStyle(
                                      color: AppColors.tp(context),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500)),
                              Text('Reset automatically at period start',
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
                _type == 'spending' ? 'MONTHLY BUDGET' : 'TARGET (OPTIONAL)',
                icon: Icons.track_changes_rounded,
              ),
              Text(
                _type == 'spending'
                    ? 'How much do you want to spend in this envelope each month?'
                    : 'Set a target amount, or leave at zero for open-ended.',
                style: TextStyle(
                    fontSize: 12, color: AppColors.ts(context)),
              ),
                const SizedBox(height: 12),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                    flex: 3,
                    child: CalculatorAmountField(
                      value: _targetAmount,
                      label: _type == 'spending' ? 'Budget amount' : 'Target amount',
                      fontSize: 20,
                      onChanged: (v) => setState(() => _targetAmount = v),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: CurrencyPickerField(
                      label: 'Currency',
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
                _sectionHeader('LINKED CATEGORIES',
                    icon: Icons.label_outline_rounded),
                Text(
                  'Expenses with these categories will debit this envelope.',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.ts(context)),
                ),
                const SizedBox(height: 12),
                if (_linkedCategories.isEmpty && !_isNew)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cautionLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.caution.withValues(alpha: 0.3)),
                    ),
                    child: const Row(children: [
                      Icon(Icons.info_outline_rounded,
                          size: 16, color: AppColors.caution),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No categories linked. Tap + to link categories so expenses debit this envelope.',
                          style: TextStyle(
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
                        borderRadius: BorderRadius.circular(10),
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
                        GestureDetector(
                          onTap: () => _unlinkCategory(cat.id),
                          child: Icon(Icons.close_rounded,
                              size: 16, color: AppColors.th(context)),
                        ),
                      ]),
                    )),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _showLinkCategorySheet,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Link Category'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: BorderSide(
                        color: AppColors.accent.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
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
          // Confetti overlay for savings goal completion
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiCtrl,
              blastDirectionality: BlastDirectionality.explosive,
              gravity: 0.2,
              numberOfParticles: 20,
              maximumSize: const Size(12, 12),
              minimumSize: const Size(6, 6),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Icon picker
  // ---------------------------------------------------------------------------

  static const _emojiGroups = <String, List<String>>{
    'Money & Budget': [
      '💰', '💳', '🏦', '📈', '💵', '🪙', '💲', '🧾', '🏧', '📊',
    ],
    'Food & Drink': [
      '🛒', '🍕', '🍔', '☕', '🍺', '🥗', '🍣', '🌮', '🍩', '🥤',
    ],
    'Transport': [
      '🚗', '⛽', '🚕', '🚌', '🚇', '✈️', '🚲', '🅿️', '🏍️', '🛞',
    ],
    'Home': [
      '🏠', '💡', '💧', '🔌', '🛏️', '🧹', '🔧', '🔑', '🪑', '📡',
    ],
    'Shopping & Style': [
      '🛍️', '👕', '👗', '💄', '👟', '💎', '🕶️', '👜', '🧴', '💇',
    ],
    'Health & Fitness': [
      '💊', '🏥', '🏋️', '🧘', '🦷', '🩺', '🏊', '🚴', '🩹', '💉',
    ],
    'Fun & Travel': [
      '🎬', '🎮', '🎵', '✈️', '🏖️', '🏔️', '🎭', '📷', '🎧', '🍿',
    ],
    'Education & Work': [
      '🎓', '📚', '💻', '📱', '💼', '🏢', '📝', '✏️', '🔬', '📐',
    ],
    'Family & Pets': [
      '👶', '🐾', '🐕', '🧸', '🍼', '🎁', '❤️', '👨‍👩‍👧', '🎂', '🏡',
    ],
    'Other': [
      '📦', '🎯', '⭐', '🌱', '♻️', '🚀', '🏷️', '📌', '🗂️', '🔖',
    ],
  };


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
    final progress =
        hasTarget ? (mainBalance / _targetAmount).clamp(0.0, 1.0) : null;

    // Trigger confetti when savings goal is reached
    if ((_type == 'saving' || _type == 'flexible') && hasTarget && mainBalance >= _targetAmount &&
        !_confettiPlayed) {
      _confettiPlayed = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _confettiCtrl.play();
      });
    }

    final progressColor = progress != null
        ? (progress >= 1.0
            ? AppColors.healthy
            : progress > 0.8
                ? AppColors.caution
                : AppColors.accent)
        : AppColors.accent;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, const Color(0xFF2A3F6A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(CardTokens.radius),
      ),
      child: Column(
        children: [
          // Balance
          Text(
            formatAmount(mainBalance, currency: targetCurrency),
            style: const TextStyle(
              color: Colors.white,
              fontSize: TypographyTokens.screenTitleSize,
              fontWeight: TypographyTokens.screenTitleWeight,
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
                      ? const Color(0xFFFFB74D) // amber warning for debt
                      : Colors.white.withValues(alpha: 0.7),
                  fontSize: 13,
                ),
              ),
          const SizedBox(height: 4),
          Text(
            'Available',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
            ),
          ),
          // Progress bar + target
          if (hasTarget) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                color: progressColor,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(progress! * 100).round()}% of ${formatAmount(_targetAmount, currency: targetCurrency)}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
                Text(
                  '${formatAmount((_targetAmount - mainBalance).clamp(0, double.infinity), currency: targetCurrency)} left',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          // Fund button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _showFundSheet(targetCurrency),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Fund'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
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

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: AppColors.sf(context),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.th(context),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Fund ${_nameController.text}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.tp(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'From your unallocated balance',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.ts(context),
                ),
              ),
              const SizedBox(height: 16),
              // Currency selector
              if (availableCurrencies.length > 1)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: availableCurrencies.map((c) {
                      final isSelected = c == selectedCurrency;
                      final bal = unallocated[c] ?? 0;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setSheetState(() => selectedCurrency = c),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.accent.withValues(alpha: 0.12)
                                  : AppColors.sfv(context),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.accent
                                    : AppColors.bd(context),
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
                                          : AppColors.tp(context),
                                    )),
                                Text(
                                  formatAmount(bal, currency: c),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.ts(context),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
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
                      color: AppColors.sfv(context),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      selectedCurrency,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ts(context),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.sfv(context),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: CalculatorAmountField(
                        value: amount,
                        onChanged: (v) => setSheetState(() => amount = v),
                        hintText: 'Amount',
                        fontSize: 16,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.tp(context),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(
                      ctx, {'amount': amount, 'currency': selectedCurrency}),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Fund',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
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
      final proceed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Over-funding'),
          content: Text(
            'You\'re assigning ${formatAmount(deficit, currency: fundCurrency)} '
            'more than your available ${formatAmount(available, currency: fundCurrency)} '
            'unallocated balance.\n\n'
            'Your unallocated balance will go negative. Continue anyway?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Fund Anyway'),
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
        note: 'Funded from Unallocated',
      );
      ref.invalidate(allocationsProvider);
      ref.invalidate(unallocatedProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Funded ${formatAmount(fundAmount, currency: fundCurrency)} to ${_nameController.text}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not fund: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.overspent,
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
      _sectionHeader('RECENT ACTIVITY', icon: Icons.receipt_outlined),
      StreamBuilder<List<AllocationLedgerData>>(
        stream: ledgerDao.watchByAllocation(widget.allocationId),
        builder: (context, snapshot) {
          final ledgerEntries = snapshot.data;
          if (ledgerEntries == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final recent = ledgerEntries.take(8).toList();

          if (recent.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text('No activity yet',
                    style:
                        TextStyle(fontSize: 13, color: AppColors.th(context))),
              ),
            );
          }

          return Column(
            children: recent.map((entry) {
              final isPositive = entry.amount > 0;
              final color =
                  isPositive ? AppColors.healthy : AppColors.overspent;

              final label = switch (entry.entryType) {
                'funding' => 'Funded',
                'consumption' => 'Spent',
                'adjustment' => 'Adjustment',
                'period_reset' => 'Period Reset',
                'carry_forward' => 'Carried Forward',
                _ => entry.entryType,
              };

              final icon = switch (entry.entryType) {
                'funding' => Icons.add_circle_outline_rounded,
                'consumption' => Icons.remove_circle_outline_rounded,
                'adjustment' => Icons.tune_rounded,
                'period_reset' => Icons.refresh_rounded,
                'carry_forward' => Icons.forward_rounded,
                _ => Icons.circle_outlined,
              };

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
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
                                fontSize: 13,
                                fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${formatDate(entry.createdAt.toLocal())} · $label',
                            style: TextStyle(
                                fontSize: 10,
                                color: AppColors.th(context)),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${isPositive ? '+' : ''}${formatAmount(entry.amount, currency: entry.currency)}',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: color),
                    ),
                  ],
                ),
              );
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
          _sectionHeader('SPENDING HISTORY', icon: Icons.bar_chart_rounded),
          const SizedBox(height: 4),
          SizedBox(
            height: 105,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: months.map((m) {
                final val = totals[m] ?? 0;
                final fraction = maxVal > 0 ? (val / maxVal) : 0.0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
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
                            color: AppColors.accent.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(6),
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
          ),
        ]);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  // ---------------------------------------------------------------------------
  // Type option card for creation flow
  // ---------------------------------------------------------------------------

  Widget _buildTypeOptionCard({
    required IconData icon,
    required String title,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent.withValues(alpha: 0.08)
              : AppColors.sfv(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.bd(context),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.accent.withValues(alpha: 0.15)
                    : AppColors.bd(context).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  size: 22,
                  color: isSelected ? AppColors.accent : AppColors.ts(context)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? AppColors.accent
                            : AppColors.tp(context),
                      )),
                  const SizedBox(height: 4),
                  Text(description,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.ts(context),
                        height: 1.4,
                      )),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded,
                  size: 20, color: AppColors.accent),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Withdraw from savings envelope
  // ---------------------------------------------------------------------------

  Future<void> _showWithdrawSheet() async {
    double withdrawAmount = 0;
    final currency = _targetCurrencyController.text;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          decoration: BoxDecoration(
            color: AppColors.sf(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Withdraw from Savings',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(
                'Move money from this envelope back to Unallocated.',
                style: TextStyle(
                    fontSize: 13, color: AppColors.ts(context)),
              ),
              const SizedBox(height: 16),
              CalculatorAmountField(
                value: withdrawAmount,
                label: 'Amount to withdraw',
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
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: withdrawAmount > 0
                          ? () => Navigator.pop(ctx, true)
                          : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Withdraw',
                          style: TextStyle(fontWeight: FontWeight.w600)),
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
      final engine = ref.read(allocationEngineProvider);
      await engine.withdrawFromAllocation(
        allocationId: widget.allocationId,
        amount: withdrawAmount,
        currency: currency,
      );
      ref.invalidate(allocationsProvider);
      ref.invalidate(unallocatedProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Withdrew ${formatAmount(withdrawAmount, currency: currency)} to Unallocated'),
            behavior: SnackBarBehavior.floating,
          ),
        );
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
          const SnackBar(
            content: Text('All categories are already linked to envelopes'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

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
                color: AppColors.sf(context),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Column(
                      children: [
                        Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.th(context),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text('Link a Category',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.tp(context))),
                        const SizedBox(height: 10),
                        TextField(
                          onChanged: (v) =>
                              setSheetState(() => search = v),
                          textInputAction: TextInputAction.search,
                          style: TextStyle(
                              fontSize: 14,
                              color: AppColors.tp(context)),
                          decoration: InputDecoration(
                            hintText: 'Search categories...',
                            hintStyle: TextStyle(
                                color: AppColors.th(context)),
                            prefixIcon: Icon(Icons.search_rounded,
                                size: 18,
                                color: AppColors.th(context)),
                            filled: true,
                            fillColor: AppColors.sfv(context),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
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
                            child: Text('No matching categories',
                                style: TextStyle(
                                    color: AppColors.ts(context))))
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
                              return GestureDetector(
                                onTap: () =>
                                    Navigator.pop(ctx, cat.id),
                                child: Container(
                                  margin:
                                      const EdgeInsets.only(bottom: 4),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    borderRadius:
                                        BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      CategoryIcon(
                                        categoryName: cat.name,
                                        emoji: hasEmoji
                                            ? cat.icon
                                            : null,
                                        color: color,
                                        size: 32,
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
                                                        AppColors.tp(
                                                            context))),
                                            Text(
                                              cat.transactionType[0]
                                                      .toUpperCase() +
                                                  cat.transactionType
                                                      .substring(1),
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: AppColors.ts(
                                                      context)),
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
      final db = ref.read(databaseProvider);
      await AllocationsDao(db)
          .linkCategory(selected, widget.allocationId);
      await _loadAllocation();
    }
  }

  Future<void> _unlinkCategory(String categoryId) async {
    final db = ref.read(databaseProvider);
    await AllocationsDao(db).unlinkCategory(categoryId);
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
          const SnackBar(
            content: Text('No foreign-currency balances to revalue'),
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
          const SnackBar(
            content: Text('No foreign-currency balances to revalue'),
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
        const SnackBar(
          content: Text('Revaluation applied'),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Archive Envelope'),
        content: const Text(
          'This envelope will be hidden from all lists. '
          'Linked categories and transaction history will be preserved.\n\n'
          'You can unarchive it later from Settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style:
                TextButton.styleFrom(foregroundColor: AppColors.overspent),
            child: const Text('Archive'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final db = ref.read(databaseProvider);
      await AllocationsDao(db).archive(widget.allocationId);
      ref.invalidate(allocationsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Envelope archived'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
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
      final suffix = linkedCount > 3 ? ' and ${linkedCount - 3} more' : '';
      warnings.add(
          '$linkedCount categor${linkedCount == 1 ? 'y is' : 'ies are'} '
          'linked to this envelope ($names$suffix)');
    }

    if (warnings.isNotEmpty) {
      final action = await showDialog<String>(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          title: const Text('Delete Envelope'),
          content: Text(
            '${warnings.join('. ')}.\n\n'
            'Deleting will:\n'
            '  \u2022 Unlink all categories from this envelope\n'
            '  \u2022 Remove all ledger history for this envelope\n\n'
            'Consider archiving instead to preserve history.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, 'cancel'),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, 'archive'),
              style: TextButton.styleFrom(
                  foregroundColor: AppColors.accent),
              child: const Text('Archive Instead'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, 'delete'),
              style: TextButton.styleFrom(
                  foregroundColor: AppColors.overspent),
              child: const Text('Delete Permanently'),
            ),
          ],
        ),
      );

      if (!mounted) return;

      if (action == 'archive') {
        await dao.archive(widget.allocationId);
        ref.invalidate(allocationsProvider);
        if (mounted) context.pop();
      } else if (action == 'delete') {
        try {
          for (final cat in linked) {
            await dao.unlinkCategory(cat.id);
          }
          await (db.delete(db.allocationLedger)
                ..where(
                    (l) => l.allocationId.equals(widget.allocationId)))
              .go();
          await (db.delete(db.allocations)
                ..where((a) => a.id.equals(widget.allocationId)))
              .go();
          ref.invalidate(allocationsProvider);
          ref.invalidate(categoriesProvider);
          if (mounted) context.pop();
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Could not delete: $e'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.overspent,
            ));
          }
        }
      }
    } else {
      // No linked categories -- simple confirmation.
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          title: const Text('Delete Envelope Permanently'),
          content: const Text(
            'This envelope has no linked categories. '
            'All ledger history will be removed.\n\n'
            'Are you sure? This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, true),
              style: TextButton.styleFrom(
                  foregroundColor: AppColors.overspent),
              child: const Text('Delete Permanently'),
            ),
          ],
        ),
      );

      if (confirmed == true && mounted) {
        try {
          await (db.delete(db.allocationLedger)
                ..where(
                    (l) => l.allocationId.equals(widget.allocationId)))
              .go();
          await (db.delete(db.allocations)
                ..where((a) => a.id.equals(widget.allocationId)))
              .go();
          ref.invalidate(allocationsProvider);
          if (mounted) context.pop();
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Could not delete: $e'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.overspent,
            ));
          }
        }
      }
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isNew ? 'Envelope created' : 'Envelope updated'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _SegmentChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SegmentChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent.withValues(alpha: 0.12)
              : AppColors.sfv(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.bd(context),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon,
              size: 22,
              color:
                  isSelected ? AppColors.accent : AppColors.ts(context)),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color:
                    isSelected ? AppColors.accent : AppColors.ts(context),
              )),
        ]),
      ),
    );
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
            content: Text('Could not fetch rate for $foreignCurrency'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.overspent,
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
          note: Value(
            'Revaluation: ${fb.currency} ${formatAmount(fb.amount, currency: fb.currency)} '
            'at ${formatAmount(_newRates[fb.currency] ?? fb.originalRate)} '
            '(was ${formatAmount(fb.originalRate)})',
          ),
          deviceId: 'local',
        ));
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error applying revaluation: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.overspent,
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
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.bd(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(
              children: [
                Icon(Icons.currency_exchange_rounded,
                    size: 22, color: AppColors.accent),
                const SizedBox(width: 10),
                Text(
                  'Revalue Foreign Balances',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.tp(context),
                  ),
                ),
              ],
            ),
          ),
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
                        'Total adjustment',
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
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(CardTokens.radius)),
                  ),
                  child: _applying
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Apply Revaluation',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
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
        border: Border.all(color: AppColors.bd(context)),
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
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
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
                  'balance in this envelope',
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
            'Original rate',
            formatAmount(fb.originalRate),
          ),
          const SizedBox(height: 4),
          _infoRow(
            'Original value',
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
                  label: 'New rate',
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
                  icon: const Icon(Icons.sync_rounded, size: 16),
                  label: const Text('Fetch'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: BorderSide(
                        color: AppColors.accent.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // New value
          _infoRow(
            'New value',
            formatAmount(newValue, currency: widget.targetCurrency),
            bold: true,
          ),
          const SizedBox(height: 6),
          // Gain/loss
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: gain >= 0
                  ? AppColors.healthy.withValues(alpha: 0.08)
                  : AppColors.overspent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  gain >= 0 ? 'Gain' : 'Loss',
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
