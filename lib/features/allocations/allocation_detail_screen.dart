import 'dart:math' as math;

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import 'package:intl/intl.dart';

import '../../core/database/app_database.dart';
import '../../core/database/daos/allocations_dao.dart';
import '../../core/providers/categories_provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../core/providers/transactions_provider.dart';
import '../../shared/theme/app_colors.dart';
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
  bool _loading = false;
  bool _showSettings = false;
  List<Category> _linkedCategories = [];

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
    super.dispose();
  }

  static const _sectionRadius = BorderRadius.all(Radius.circular(16));
  static const _inputRadius = BorderRadius.all(Radius.circular(12));

  InputDecoration _inputDecoration(String label, {Widget? prefixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
      floatingLabelStyle: const TextStyle(
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
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5)),
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
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.6)),
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
      appBar: AppBar(
        title: Text(_isNew ? 'New Envelope' : envelopeName),
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
                        borderRadius: BorderRadius.circular(14)),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // For existing envelopes: show transactions first, settings collapsible
            if (!_isNew) ...[
              // Envelope transactions
              _sectionContainer(children: [
                _sectionHeader('TRANSACTIONS THIS PERIOD',
                    icon: Icons.receipt_long_rounded),
                _buildEnvelopeTransactions(),
              ]),
              const SizedBox(height: 16),
              // Settings toggle
              GestureDetector(
                onTap: () => setState(() => _showSettings = !_showSettings),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.sf(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.bd(context)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.settings_outlined,
                          size: 18, color: AppColors.textSecondary),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text('Envelope Settings',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                      ),
                      Icon(
                        _showSettings
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        color: AppColors.textHint,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            // Settings (always shown for new, toggled for existing)
            if (_isNew || _showSettings) ...[
            // Name
            _sectionContainer(children: [
              _sectionHeader('NAME', icon: Icons.label_outline_rounded),
              TextField(
                controller: _nameController,
                decoration:
                    _inputDecoration('Envelope name (e.g. Groceries)'),
                textCapitalization: TextCapitalization.words,
                autofocus: _isNew,
                style: TextStyle(
                    color: AppColors.tp(context), fontSize: 15),
              ),
            ]),
            const SizedBox(height: 16),

            // Purpose
            _sectionContainer(children: [
              _sectionHeader('PURPOSE', icon: Icons.category_outlined),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  '• Spending: for regular expenses (groceries, dining)\n'
                  '• Saving: for goals you\'re saving toward (vacation, emergency fund)\n'
                  '• Flexible: for variable expenses that don\'t fit a fixed budget',
                  style: TextStyle(
                      fontSize: 11, color: AppColors.ts(context), height: 1.5),
                ),
              ),
              _buildSegmentedSelector<String>(
                options: const [
                  ('spending', 'Spending', Icons.shopping_bag_outlined),
                  ('saving', 'Saving', Icons.savings_outlined),
                  ('flexible', 'Flexible', Icons.swap_horiz_rounded),
                ],
                selected: _type,
                onChanged: (v) => setState(() => _type = v),
              ),
            ]),
            const SizedBox(height: 16),

            // Cycle
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
                    const Icon(Icons.replay_rounded,
                        size: 20, color: AppColors.textSecondary),
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
                                    color: AppColors.textSecondary,
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
              ],
            ]),
            const SizedBox(height: 16),

            // Budget
            _sectionContainer(children: [
              _sectionHeader('MONTHLY BUDGET',
                  icon: Icons.track_changes_rounded),
              const Text(
                  'How much do you want to spend in this envelope each month?',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  flex: 3,
                  child: CalculatorAmountField(
                    value: _targetAmount,
                    label: 'Budget amount',
                    fontSize: 20,
                    onChanged: (v) => setState(() => _targetAmount = v),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 88,
                  child: TextField(
                    controller: _targetCurrencyController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: _inputDecoration('Currency'),
                    style: TextStyle(
                        color: AppColors.tp(context),
                        fontSize: 15,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ]),
            ]),
            const SizedBox(height: 16),

            // Linked Categories
            _sectionContainer(children: [
              _sectionHeader('LINKED CATEGORIES',
                  icon: Icons.label_outline_rounded),
              const Text(
                'Expenses with these categories will debit this envelope.',
                style: TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
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
                        backgroundColor: _hexToColor(cat.colorHex),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(cat.name,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w500)),
                      ),
                      GestureDetector(
                        onTap: () => _unlinkCategory(cat.id),
                        child: const Icon(Icons.close_rounded,
                            size: 16, color: AppColors.textHint),
                      ),
                    ]),
                  )),
              if (!_isNew) ...[
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
              ] else
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    'A category will be auto-created when you save. You can link more after.',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textHint,
                        fontStyle: FontStyle.italic),
                  ),
                ),
            ]),
            ], // end if (_isNew || _showSettings)

            // --- Progress ring + recent transactions + spending history ---
            if (!_isNew) ...[
              const SizedBox(height: 24),
              _buildProgressRing(),
              const SizedBox(height: 16),
              _buildRecentTransactions(),
              const SizedBox(height: 16),
              _buildSpendingHistory(),
            ],
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Progress ring: spent vs target
  // ---------------------------------------------------------------------------

  Widget _buildProgressRing() {
    if (_targetAmount <= 0) return const SizedBox.shrink();
    final target = _targetAmount;

    final entriesAsync = ref.watch(transactionEntriesProvider);
    final linkedCatIds = _linkedCategories.map((c) => c.id).toSet();

    return entriesAsync.when(
      data: (entries) {
        double spent = 0;
        for (final e in entries) {
          bool match = linkedCatIds.contains(e.tx.categoryId);
          if (!match) {
            for (final l in e.lines) {
              if (linkedCatIds.contains(l.categoryId)) {
                match = true;
                break;
              }
            }
          }
          if (match && e.tx.type == 'expense') {
            spent += e.tx.amount;
          }
        }

        final progress = (spent / target).clamp(0.0, 1.5);
        final pct = (progress * 100).round();
        final color = progress > 1.0
            ? AppColors.overspent
            : progress > 0.8
                ? AppColors.caution
                : AppColors.healthy;

        return _sectionContainer(children: [
          _sectionHeader('BUDGET PROGRESS', icon: Icons.donut_large_rounded),
          const SizedBox(height: 4),
          Center(
            child: SizedBox(
              width: 140,
              height: 140,
              child: CustomPaint(
                painter: _ProgressRingPainter(
                  progress: progress.clamp(0.0, 1.0),
                  color: color,
                  bgColor: AppColors.bd(context),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$pct%',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                      Text(
                        'of ${formatAmount(target, currency: _targetCurrencyController.text)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _miniStat('Spent', formatAmount(spent, currency: _targetCurrencyController.text), color),
              _miniStat('Remaining', formatAmount((target - spent).clamp(0, double.infinity), currency: _targetCurrencyController.text), AppColors.healthy),
            ],
          ),
        ]);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Recent transactions (last 5)
  // ---------------------------------------------------------------------------

  Widget _buildRecentTransactions() {
    final entriesAsync = ref.watch(transactionEntriesProvider);
    final linkedCatIds = _linkedCategories.map((c) => c.id).toSet();
    final categories = ref.watch(categoriesProvider).value ?? [];
    final catMap = {for (final c in categories) c.id: c};

    if (linkedCatIds.isEmpty) return const SizedBox.shrink();

    return _sectionContainer(children: [
      _sectionHeader('RECENT TRANSACTIONS', icon: Icons.receipt_outlined),
      entriesAsync.when(
        data: (entries) {
          final filtered = entries.where((e) {
            if (linkedCatIds.contains(e.tx.categoryId)) return true;
            for (final l in e.lines) {
              if (linkedCatIds.contains(l.categoryId)) return true;
            }
            return false;
          }).take(5).toList();

          if (filtered.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text('No transactions yet',
                    style: TextStyle(fontSize: 13, color: AppColors.textHint)),
              ),
            );
          }

          return Column(
            children: filtered.map((e) {
              final tx = e.tx;
              final isIncome = tx.type == 'income';
              final color = isIncome ? AppColors.healthy : AppColors.overspent;
              final cat = tx.categoryId != null ? catMap[tx.categoryId] : null;
              final label = tx.note.isNotEmpty
                  ? tx.note
                  : cat?.name ?? tx.type;
              final catColor = cat != null
                  ? _hexToColor(cat.colorHex)
                  : AppColors.textSecondary;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    CategoryIcon(
                      categoryName: cat?.name ?? '',
                      color: catColor,
                      size: 36,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(label,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          Text(
                            DateFormat('MMM d, yyyy').format(tx.createdAt.toLocal()),
                            style: const TextStyle(
                                fontSize: 10, color: AppColors.textHint),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      formatSignedAmount(tx.amount, currency: tx.currency, type: tx.type),
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const SizedBox.shrink(),
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

        for (final e in entries) {
          bool match = linkedCatIds.contains(e.tx.categoryId);
          if (!match) {
            for (final l in e.lines) {
              if (linkedCatIds.contains(l.categoryId)) {
                match = true;
                break;
              }
            }
          }
          if (!match || e.tx.type != 'expense') continue;

          final txDate = e.tx.createdAt.toLocal();
          for (final m in months) {
            if (txDate.year == m.year && txDate.month == m.month) {
              totals[m] = (totals[m] ?? 0) + e.tx.amount;
              break;
            }
          }
        }

        final maxVal = totals.values.fold<double>(0, (a, b) => math.max(a, b));
        if (maxVal == 0) return const SizedBox.shrink();

        return _sectionContainer(children: [
          _sectionHeader('SPENDING HISTORY', icon: Icons.bar_chart_rounded),
          const SizedBox(height: 4),
          SizedBox(
            height: 100,
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
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
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

  Widget _buildEnvelopeTransactions() {
    final entriesAsync = ref.watch(transactionEntriesProvider);
    final linkedCatIds = _linkedCategories.map((c) => c.id).toSet();

    return entriesAsync.when(
      data: (entries) {
        // Filter: transactions whose category is linked to this envelope.
        final filtered = entries.where((e) {
          if (linkedCatIds.contains(e.tx.categoryId)) return true;
          for (final l in e.lines) {
            if (linkedCatIds.contains(l.categoryId)) return true;
          }
          return false;
        }).take(20).toList();

        if (filtered.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Text('No transactions in this envelope yet',
                  style: TextStyle(
                      fontSize: 13, color: AppColors.textHint)),
            ),
          );
        }

        return Column(
          children: filtered.map((e) {
            final tx = e.tx;
            final color = tx.type == 'income'
                ? AppColors.healthy
                : AppColors.overspent;
            final label = tx.note.isNotEmpty ? tx.note : tx.type;

            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        Text(
                          DateFormat('MMM d').format(
                              tx.createdAt.toLocal()),
                          style: const TextStyle(
                              fontSize: 10, color: AppColors.textHint),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    formatSignedAmount(tx.amount, currency: tx.currency, type: tx.type),
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
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  // ---------------------------------------------------------------------------
  // Category linking
  // ---------------------------------------------------------------------------

  Future<void> _showLinkCategorySheet() async {
    final allCategories = ref.read(categoriesProvider).value ?? [];
    // Filter: show only unlinked categories (no allocationId or linked to this).
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
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.6,
        ),
        decoration: BoxDecoration(
          color: AppColors.sf(context),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Text('Link a Category',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700)),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                children: available
                    .map((cat) => ListTile(
                          leading: CircleAvatar(
                            radius: 10,
                            backgroundColor: _hexToColor(cat.colorHex),
                          ),
                          title: Text(cat.name),
                          onTap: () => Navigator.pop(ctx, cat.id),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
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

  Color _hexToColor(String hex) {
    final clean = hex.replaceAll('#', '');
    return Color(int.parse('FF$clean', radix: 16));
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

      String categoryId;
      if (_isNew) {
        // Auto-create a matching category and link it to this envelope.
        categoryId = const Uuid().v4();
        await db.into(db.categories).insert(CategoriesCompanion.insert(
              id: categoryId,
              householdId: householdId,
              name: name,
              transactionType: const Value('expense'),
              allocationId: Value(allocId),
            ));
      } else {
        final existing = await dao.getById(allocId);
        categoryId = existing?.categoryId ?? const Uuid().v4();
      }

      final targetAmount =
          _targetAmount > 0 ? _targetAmount : null;
      final targetCurrency = _targetCurrencyController.text.trim();

      await dao.upsert(AllocationsCompanion.insert(
        id: allocId,
        householdId: householdId,
        name: name,
        categoryId: categoryId,
        type: Value(_type),
        periodicity: Value(_periodicity),
        rollover: Value(_rollover),
        targetAmount: Value(targetAmount),
        targetCurrency: Value(targetCurrency.isEmpty ? null : targetCurrency),
        deviceId: 'local',
      ));
      if (mounted) context.pop();
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
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.accent : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon,
              size: 22,
              color:
                  isSelected ? AppColors.accent : AppColors.textSecondary),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color:
                    isSelected ? AppColors.accent : AppColors.textSecondary,
              )),
        ]),
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final Color color;
  final Color bgColor;

  _ProgressRingPainter({
    required this.progress,
    required this.color,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) / 2) - 10;
    const startAngle = -math.pi / 2;
    const fullSweep = 2 * math.pi;

    // Background ring
    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      fullSweep,
      false,
      bgPaint,
    );

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      fullSweep * progress.clamp(0.0, 1.0),
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter old) =>
      old.progress != progress || old.color != color;
}
