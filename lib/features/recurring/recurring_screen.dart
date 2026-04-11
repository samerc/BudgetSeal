import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null) return;
    final engine = ref.read(recurringEngineProvider);
    final items = await engine.getAll(householdId);
    if (mounted) setState(() { _items = items; _loading = false; });
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
    return Scaffold(
      appBar: AppBar(title: const Text('Recurring')),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add recurring transaction',
        onPressed: () => _showAddSheet(),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const EmptyState(
                  icon: Icons.repeat_rounded,
                  title: 'No recurring transactions',
                  subtitle: 'Tap + to create one',
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: _items.length,
                  itemBuilder: (_, i) => _RecurringTile(
                    item: _items[i],
                    frequencyLabel: _frequencyLabel(
                        _items[i].frequency, _items[i].interval),
                    onToggle: (enabled) async {
                      final engine = ref.read(recurringEngineProvider);
                      await engine.toggleEnabled(_items[i].id, enabled);
                      _load();
                    },
                    onDelete: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (dialogCtx) => AlertDialog(
                          title: const Text('Delete recurring transaction?'),
                          content: const Text(
                              'This recurring transaction will be permanently removed.'),
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
                      await engine.delete(_items[i].id);
                      _load();
                    },
                    onEdit: () => _showEditSheet(_items[i]),
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
      builder: (_) => _EditRecurringSheet(item: item),
    );
    if (result == true) _load();
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
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: ListTile(
        onTap: onEdit,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.repeat_rounded, color: color, size: 18),
        ),
        title: Text(
          item.title.isNotEmpty ? item.title : item.note,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              formatSignedAmount(item.amount, currency: item.currency, type: item.type),
              style: TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 13, color: color),
            ),
            Text(
              '$frequencyLabel · Next: ${DateFormat('MMM d').format(item.nextDueDate)}',
              style: const TextStyle(fontSize: 11, color: AppColors.textHint),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch.adaptive(
              value: item.enabled,
              onChanged: onToggle,
              activeTrackColor: AppColors.accent,
            ),
            IconButton(
              tooltip: 'Delete recurring transaction',
              icon: Icon(Icons.delete_outline,
                  size: 18, color: AppColors.overspent),
              onPressed: onDelete,
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
            const SizedBox(height: 20),
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
      );
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ---------------------------------------------------------------------------
// Edit Recurring Sheet
// ---------------------------------------------------------------------------

class _EditRecurringSheet extends ConsumerStatefulWidget {
  final RecurringTransaction item;
  const _EditRecurringSheet({required this.item});

  @override
  ConsumerState<_EditRecurringSheet> createState() =>
      _EditRecurringSheetState();
}

class _EditRecurringSheetState extends ConsumerState<_EditRecurringSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late double _calcAmount;
  late String _frequency;
  late DateTime _startDate;
  late String? _accountId;
  late String _currency;
  late DateTime? _endDate;
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
            const SizedBox(height: 20),
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
      ));
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
