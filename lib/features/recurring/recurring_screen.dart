import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:drift/drift.dart' show Value;

import '../../core/database/app_database.dart';
import '../../core/providers/accounts_provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/engine_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/utils/format_number.dart';
import '../../shared/widgets/calculator_amount_field.dart';
import '../../shared/widgets/empty_state.dart';

class RecurringScreen extends ConsumerStatefulWidget {
  const RecurringScreen({super.key});

  @override
  ConsumerState<RecurringScreen> createState() => _RecurringScreenState();
}

class _RecurringScreenState extends ConsumerState<RecurringScreen> {
  List<RecurringTransaction> _items = [];
  bool _loading = true;
  String? _typeFilter; // null = all, 'income', 'expense'

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final householdId = ref.read(currentHouseholdIdProvider);
      if (householdId == null) return;
      final engine = ref.read(recurringEngineProvider);
      final items = await engine.getAll(householdId, excludeSubscriptions: true);
      if (mounted) setState(() { _items = items; _loading = false; });
    } catch (e) {
      debugPrint('[Recurring] Error loading: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  List<RecurringTransaction> get _filtered {
    if (_typeFilter == null) return _items;
    return _items.where((r) => r.type == _typeFilter).toList();
  }

  String _frequencyLabel(String freq, int interval) {
    if (interval == 1) {
      return switch (freq) {
        'daily' => 'Daily',
        'weekly' => 'Weekly',
        'monthly' => 'Monthly',
        'yearly' => 'Yearly',
        _ => freq,
      };
    }
    return switch (freq) {
      'daily' => 'Every $interval days',
      'weekly' => 'Every $interval weeks',
      'monthly' => 'Every $interval months',
      'yearly' => 'Every $interval years',
      _ => 'Every $interval $freq',
    };
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final activeCount = _items.where((r) => r.enabled).length;
    final pausedCount = _items.length - activeCount;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add recurring transaction',
        onPressed: () => _showAddSheet(),
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
                          'Recurring',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.tp(context),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Bill calendar',
                        icon: Icon(Icons.calendar_month_rounded,
                            color: AppColors.ts(context)),
                        onPressed: () =>
                            context.push('/bill-calendar'),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Summary banner ──
              if (_items.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.sfv(context),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          _SummaryChip(
                            icon: Icons.repeat_rounded,
                            label: '${_items.length}',
                            subtitle: 'Total',
                            color: AppColors.accent,
                          ),
                          const SizedBox(width: 16),
                          _SummaryChip(
                            icon: Icons.play_arrow_rounded,
                            label: '$activeCount',
                            subtitle: 'Active',
                            color: AppColors.healthy,
                          ),
                          if (pausedCount > 0) ...[
                            const SizedBox(width: 16),
                            _SummaryChip(
                              icon: Icons.pause_rounded,
                              label: '$pausedCount',
                              subtitle: 'Paused',
                              color: AppColors.caution,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

              // ── Type filter chips ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                  child: Row(
                    children: [
                      _TypeChip(
                        label: 'All',
                        selected: _typeFilter == null,
                        onTap: () =>
                            setState(() => _typeFilter = null),
                      ),
                      const SizedBox(width: 8),
                      _TypeChip(
                        label: 'Expense',
                        selected: _typeFilter == 'expense',
                        color: AppColors.overspent,
                        onTap: () =>
                            setState(() => _typeFilter = 'expense'),
                      ),
                      const SizedBox(width: 8),
                      _TypeChip(
                        label: 'Income',
                        selected: _typeFilter == 'income',
                        color: AppColors.healthy,
                        onTap: () =>
                            setState(() => _typeFilter = 'income'),
                      ),
                    ],
                  ),
                ),
              ),

              // ── List ──
              if (_loading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_items.isEmpty)
                const SliverFillRemaining(
                  child: EmptyState(
                    icon: Icons.repeat_rounded,
                    title: 'No recurring transactions',
                    subtitle: 'Tap + to create one',
                  ),
                )
              else if (filtered.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'No ${_typeFilter ?? ''} recurring transactions',
                      style: TextStyle(color: AppColors.ts(context)),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _RecurringTile(
                        item: filtered[i],
                        frequencyLabel: _frequencyLabel(
                            filtered[i].frequency, filtered[i].interval),
                        onToggle: (enabled) async {
                          final engine = ref.read(recurringEngineProvider);
                          await engine.toggleEnabled(filtered[i].id, enabled);
                          _load();
                        },
                        onDelete: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (dialogCtx) => AlertDialog(
                              title:
                                  const Text('Delete recurring transaction?'),
                              content: const Text(
                                  'This will be permanently removed.'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogCtx, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogCtx, true),
                                  style: TextButton.styleFrom(
                                      foregroundColor: AppColors.overspent),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                          if (confirmed != true) return;
                          final engine = ref.read(recurringEngineProvider);
                          await engine.delete(filtered[i].id);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Recurring transaction deleted'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            _load();
                          }
                        },
                        onEdit: () => _showEditSheet(filtered[i]),
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

  Future<void> _showAddSheet() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddRecurringSheet(),
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
      builder: (_) => EditRecurringSheet(item: item),
    );
    if (result == true) _load();
  }
}

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

class _TypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;
  const _TypeChip({
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

class _RecurringTile extends StatelessWidget {
  final RecurringTransaction item;
  final String frequencyLabel;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _RecurringTile({
    required this.item,
    required this.frequencyLabel,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = item.type == 'income';
    final color = isIncome ? AppColors.healthy : AppColors.overspent;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.bd(context)),
      ),
      child: ListTile(
        onTap: onEdit,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.repeat_rounded, color: color, size: 20),
        ),
        title: Text(
          item.title.isNotEmpty ? item.title : item.note,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: item.enabled
                ? AppColors.tp(context)
                : AppColors.th(context),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          'Next: ${DateFormat('MMM d').format(item.nextDueDate)} · $frequencyLabel',
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
                  formatSignedAmount(item.amount,
                      currency: item.currency, type: item.type),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: item.enabled ? color : AppColors.th(context),
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
                        color: item.enabled
                            ? AppColors.healthy
                            : AppColors.th(context),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item.enabled ? 'Active' : 'Paused',
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
                tooltip: item.enabled ? 'Pause' : 'Resume',
                icon: Icon(
                  item.enabled
                      ? Icons.pause_circle_outline_rounded
                      : Icons.play_circle_outline_rounded,
                  color: item.enabled
                      ? AppColors.ts(context)
                      : AppColors.healthy,
                ),
                onPressed: () => onToggle(!item.enabled),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddRecurringSheet extends ConsumerStatefulWidget {
  const _AddRecurringSheet();

  @override
  ConsumerState<_AddRecurringSheet> createState() => _AddRecurringSheetState();
}

class _AddRecurringSheetState extends ConsumerState<_AddRecurringSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  double _calcAmount = 0;
  String _type = 'expense';
  String _frequency = 'monthly';
  DateTime _startDate = DateTime.now();
  String? _accountId;
  String _currency = 'USD';
  DateTime? _endDate;
  bool _isSubscription = false;
  bool _saving = false;
  bool _submitted = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('New Recurring Transaction',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleCtrl,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Title (e.g. Rent, Salary)'),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Title is required' : null,
            ),
            const SizedBox(height: 12),
            CalculatorAmountField(
              value: _calcAmount,
              label: 'Amount',
              fontSize: 20,
              onChanged: (v) => setState(() => _calcAmount = v),
            ),
            const SizedBox(height: 12),
            // Account picker
            Builder(builder: (context) {
              final accounts =
                  ref.watch(accountsProvider).value ?? [];
              return DropdownButtonFormField<String>(
                initialValue: _accountId,
                decoration:
                    const InputDecoration(labelText: 'Account'),
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
                          accounts.firstWhere((a) => a.id == v);
                      _currency = acc.currency;
                    }
                  });
                },
                validator: (v) =>
                    (_submitted && _accountId == null) ? 'Account is required' : null,
              );
            }),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'expense', label: Text('Expense')),
                ButtonSegment(value: 'income', label: Text('Income')),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'weekly', label: Text('Weekly')),
                ButtonSegment(value: 'monthly', label: Text('Monthly')),
                ButtonSegment(value: 'yearly', label: Text('Yearly')),
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
              icon: const Icon(Icons.calendar_today_rounded, size: 16),
              label: Text(
                  'Starts: ${DateFormat('MMMM d, yyyy').format(_startDate)}'),
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
              icon: const Icon(Icons.event_busy_rounded, size: 16),
              label: Text(_endDate != null
                  ? 'Ends: ${DateFormat('MMMM d, yyyy').format(_endDate!)}'
                  : 'Ends: Never (tap to set)'),
            ),
            if (_endDate != null) ...[
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => setState(() => _endDate = null),
                  child: const Text('Clear end date',
                      style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
            const SizedBox(height: 12),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('This is a subscription',
                  style: TextStyle(fontSize: 14)),
              subtitle: const Text('e.g. Netflix, Spotify',
                  style: TextStyle(fontSize: 12, color: AppColors.textHint)),
              value: _isSubscription,
              onChanged: (v) => setState(() => _isSubscription = v),
              activeTrackColor: AppColors.accent,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Create',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
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
    if (_calcAmount <= 0) return;

    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null || _accountId == null) return;

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
        frequency: _frequency,
        startDate: _startDate,
        endDate: _endDate,
        isSubscription: _isSubscription,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recurring transaction created'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
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
  const EditRecurringSheet({super.key, required this.item});

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
  late bool _isSubscription;
  bool _saving = false;
  final bool _submitted = false;

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
    _isSubscription = item.isSubscription;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Edit Recurring Transaction',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleCtrl,
              autofocus: false,
              decoration:
                  const InputDecoration(labelText: 'Title (e.g. Rent, Salary)'),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Title is required' : null,
            ),
            const SizedBox(height: 12),
            CalculatorAmountField(
              value: _calcAmount,
              label: 'Amount',
              fontSize: 20,
              onChanged: (v) => setState(() => _calcAmount = v),
            ),
            const SizedBox(height: 12),
            // Account picker
            Builder(builder: (context) {
              final accounts = ref.watch(accountsProvider).value ?? [];
              return DropdownButtonFormField<String>(
                initialValue: _accountId,
                decoration: const InputDecoration(labelText: 'Account'),
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
                      final acc = accounts.firstWhere((a) => a.id == v);
                      _currency = acc.currency;
                    }
                  });
                },
                validator: (v) =>
                    (_submitted && _accountId == null) ? 'Account is required' : null,
              );
            }),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'weekly', label: Text('Weekly')),
                ButtonSegment(value: 'monthly', label: Text('Monthly')),
                ButtonSegment(value: 'yearly', label: Text('Yearly')),
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
              icon: const Icon(Icons.calendar_today_rounded, size: 16),
              label: Text(
                  'Next due: ${DateFormat('MMMM d, yyyy').format(_startDate)}'),
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
              icon: const Icon(Icons.event_busy_rounded, size: 16),
              label: Text(_endDate != null
                  ? 'Ends: ${DateFormat('MMMM d, yyyy').format(_endDate!)}'
                  : 'Ends: Never (tap to set)'),
            ),
            if (_endDate != null) ...[
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => setState(() => _endDate = null),
                  child: const Text('Clear end date',
                      style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
            const SizedBox(height: 12),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('This is a subscription',
                  style: TextStyle(fontSize: 14)),
              subtitle: const Text('e.g. Netflix, Spotify',
                  style: TextStyle(fontSize: 12, color: AppColors.textHint)),
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
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Cancel',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('Save',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty || _calcAmount <= 0) return;
    if (_accountId == null) return;

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
        frequency: Value(_frequency),
        nextDueDate: Value(_startDate),
        endDate: Value(_endDate),
        isSubscription: Value(_isSubscription),
      ));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recurring transaction updated'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
