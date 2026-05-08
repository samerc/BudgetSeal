import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/database/app_database.dart';
import '../../core/engine/allocation_engine.dart';
import '../../core/providers/accounts_provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/engine_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../core/providers/objectives_provider.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/design_tokens.dart';
import '../../shared/utils/format_number.dart';
import '../../shared/widgets/calculator_amount_field.dart';
import '../../shared/widgets/currency_picker_field.dart';

class ObjectiveDetailScreen extends ConsumerStatefulWidget {
  final String objectiveId; // 'new' for creating
  const ObjectiveDetailScreen({super.key, required this.objectiveId});

  @override
  ConsumerState<ObjectiveDetailScreen> createState() =>
      _ObjectiveDetailScreenState();
}

class _ObjectiveDetailScreenState
    extends ConsumerState<ObjectiveDetailScreen> {
  final _nameCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  String _type = 'goal'; // 'goal' or 'loan'
  String? _direction; // 'lent' or 'borrowed' (loans only)
  String _currency = 'USD';
  double _targetAmount = 0;
  double _currentAmount = 0;
  DateTime? _endDate;
  String? _icon;
  String _colorHex = '#2563EB';
  bool _loading = false;

  bool get _isNew => widget.objectiveId == 'new';

  static const _colors = [
    '#2563EB', '#6366F1', '#8B5CF6', '#EC4899', '#EF4444',
    '#F97316', '#EAB308', '#22C55E', '#14B8A6', '#06B6D4',
  ];

  @override
  void initState() {
    super.initState();
    if (_isNew) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final household = ref.read(householdProvider).value;
        if (household != null && mounted) {
          setState(() => _currency = household.baseCurrency);
        }
      });
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final obj = await ref.read(objectiveByIdProvider(widget.objectiveId).future);
      if (obj != null && mounted) {
        setState(() {
          _nameCtrl.text = obj.name;
          _type = obj.type;
          _direction = obj.direction;
          _currency = obj.targetCurrency;
          _targetAmount = obj.targetAmount;
          _currentAmount = obj.currentAmount;
          _endDate = obj.endDate;
          _icon = obj.icon;
          _colorHex = obj.colorHex;
          if (obj.contactName != null) _contactCtrl.text = obj.contactName!;
        });
      }
    } catch (e) {
      debugPrint('[ObjectiveDetail] Error loading: $e');
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _contactCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name is required'),
            behavior: SnackBarBehavior.floating),
      );
      return;
    }

    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null) return;

    setState(() => _loading = true);
    try {
      final db = ref.read(databaseProvider);
      final id = _isNew ? const Uuid().v4() : widget.objectiveId;
      await db.into(db.objectives).insertOnConflictUpdate(
        ObjectivesCompanion.insert(
          id: id,
          householdId: householdId,
          name: name,
          type: _type,
          targetCurrency: _currency,
          deviceId: 'local',
          icon: Value(_icon),
          targetAmount: Value(_targetAmount),
          currentAmount: Value(_currentAmount),
          endDate: Value(_endDate),
          contactName: Value(_type == 'loan' ? _contactCtrl.text.trim() : null),
          direction: Value(_type == 'loan' ? (_direction ?? 'lent') : null),
          colorHex: Value(_colorHex),
          lastModified: Value(DateTime.now()),
        ),
      );
      ref.invalidate(objectivesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isNew ? 'Objective created' : 'Objective updated'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'),
              behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateAmount() async {
    final accounts = ref.read(accountsProvider).value ?? [];
    final activeAccounts = accounts.where((a) => !a.archived && !a.isTravel).toList();
    if (activeAccounts.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No accounts available'),
              behavior: SnackBarBehavior.floating),
        );
      }
      return;
    }

    final isLoan = _type == 'loan';
    final isLent = _direction == 'lent';
    // For goals: expense (money leaves account into savings)
    // For loans I borrowed: expense (I'm paying them back)
    // For loans I lent: income (they're paying me back)
    final txType = isLoan && isLent ? 'income' : 'expense';
    final sheetTitle = isLoan ? 'Record Payment' : 'Add Funds';
    final buttonLabel = isLoan
        ? (isLent ? 'Record Payment Received' : 'Record Payment Sent')
        : 'Save from Account';

    // Capture theme colors for the sheet
    final tpColor = AppColors.tp(context);
    final tsColor = AppColors.ts(context);
    final bdColor = AppColors.bd(context);

    final result = await showModalBottomSheet<({double amount, String accountId})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.sf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        double amount = 0;
        String? selectedAccountId = activeAccounts.first.id;
        return StatefulBuilder(
          builder: (ctx, setModalState) => Padding(
            padding: EdgeInsets.fromLTRB(
                24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(sheetTitle,
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                      color: tpColor)),
              const SizedBox(height: 4),
              Text('Current: ${formatAmount(_currentAmount, currency: _currency)}',
                  style: TextStyle(fontSize: 13, color: tsColor)),
              const SizedBox(height: 20),

              // Account picker
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: bdColor),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedAccountId,
                    isExpanded: true,
                    items: activeAccounts.map((a) => DropdownMenuItem(
                      value: a.id,
                      child: Text('${a.name} (${a.currency})',
                          style: const TextStyle(fontSize: 14)),
                    )).toList(),
                    onChanged: (v) => setModalState(() => selectedAccountId = v),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Amount
              CalculatorAmountField(
                value: 0,
                hintText: '0.00',
                currency: _currency,
                fontSize: 28,
                onChanged: (v) => setModalState(() => amount = v),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: amount > 0 && selectedAccountId != null
                      ? () => Navigator.pop(ctx, (amount: amount, accountId: selectedAccountId!))
                      : null,
                  child: Text(buttonLabel),
                ),
              ),
            ]),
          ),
        );
      },
    );

    if (result == null || !mounted) return;

    try {
      final engine = ref.read(allocationEngineProvider);
      final householdId = ref.read(currentHouseholdIdProvider);
      if (householdId == null) return;

      final account = activeAccounts.where((a) => a.id == result.accountId).firstOrNull;
      if (account == null) return;

      final noteName = isLoan && _contactCtrl.text.isNotEmpty
          ? '${_nameCtrl.text.trim()} — ${_contactCtrl.text.trim()}'
          : _nameCtrl.text.trim();

      // Create a real transaction
      await engine.recordTransaction(
        householdId: householdId,
        accountId: result.accountId,
        type: txType,
        lines: [
          TxLine(
            amount: result.amount,
            currency: _currency,
            exchangeRateToBase: account.currency == _currency ? 1.0 : 1.0,
          ),
        ],
        baseCurrency: ref.read(householdProvider).value?.baseCurrency ?? 'USD',
        note: isLoan
            ? (isLent ? 'Payment received — $noteName' : 'Payment — $noteName')
            : 'Goal savings — $noteName',
        deviceId: 'local',
        date: DateTime.now(),
      );

      // Update objective's currentAmount
      final newAmount = _currentAmount + result.amount;
      final db = ref.read(databaseProvider);
      await (db.update(db.objectives)
            ..where((o) => o.id.equals(widget.objectiveId)))
          .write(ObjectivesCompanion(
        currentAmount: Value(newAmount),
        lastModified: Value(DateTime.now()),
      ));

      if (mounted) setState(() => _currentAmount = newAmount);
      ref.invalidate(objectivesProvider);
      ref.invalidate(accountsWithBalanceProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${txType == 'income' ? 'Received' : 'Paid'} ${formatAmount(result.amount, currency: _currency)} from ${account.name}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'),
              behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _endDate ?? now.add(const Duration(days: 90));
    // Allow selecting past dates when editing an objective with an existing past deadline
    final first = _endDate != null && _endDate!.isBefore(now) ? _endDate! : now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) setState(() => _endDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final color = AppColors.fromHex(_colorHex);
    final progress = _targetAmount > 0
        ? (_currentAmount / _targetAmount).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'New Objective' : _nameCtrl.text.isEmpty ? 'Edit' : _nameCtrl.text),
        actions: [
          if (!_isNew) ...[
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Delete',
              onPressed: _confirmDelete,
            ),
          ],
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: _loading ? null : _save,
              icon: _loading
                  ? const SizedBox(height: 14, width: 14,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.check_rounded, size: 18),
              label: const Text('Save'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                minimumSize: Size.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress hero (edit only)
            if (!_isNew && _targetAmount > 0) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(CardTokens.radius),
                  border: Border.all(color: color.withValues(alpha: 0.2)),
                ),
                child: Column(children: [
                  Text(
                    formatAmount(_currentAmount, currency: _currency),
                    style: TextStyle(
                      fontSize: 28, fontWeight: FontWeight.w800,
                      color: AppColors.tp(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'of ${formatAmount(_targetAmount, currency: _currency)}',
                    style: TextStyle(fontSize: 14, color: AppColors.ts(context)),
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: color.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('${(progress * 100).toStringAsFixed(1)}%',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _updateAmount,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text(_type == 'loan' ? 'Record Payment' : 'Add Funds'),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 16),
            ],

            // Type toggle
            Row(children: [
              _TypeChip(
                label: 'Goal', icon: Icons.flag_rounded,
                selected: _type == 'goal',
                onTap: () => setState(() => _type = 'goal'),
              ),
              const SizedBox(width: 8),
              _TypeChip(
                label: 'Loan', icon: Icons.handshake_rounded,
                selected: _type == 'loan',
                onTap: () => setState(() { _type = 'loan'; _direction ??= 'lent'; }),
              ),
            ]),
            const SizedBox(height: 16),

            // Name
            _FormCard(child: TextField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: _type == 'loan' ? 'Loan name' : 'Goal name',
                hintText: _type == 'loan' ? 'e.g. Car loan' : 'e.g. Emergency fund',
                border: InputBorder.none,
                prefixIcon: Icon(Icons.edit_rounded, size: 18, color: AppColors.ts(context)),
              ),
            )),
            const SizedBox(height: 10),

            // Loan-specific fields
            if (_type == 'loan') ...[
              _FormCard(child: Column(children: [
                TextField(
                  controller: _contactCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Person',
                    hintText: 'e.g. Ali, Bank, etc.',
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.person_rounded, size: 18, color: AppColors.ts(context)),
                  ),
                ),
                Divider(height: 1, color: AppColors.bd(context)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(children: [
                    Text('Direction', style: TextStyle(fontSize: 14, color: AppColors.ts(context))),
                    const Spacer(),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'lent', label: Text('I lent')),
                        ButtonSegment(value: 'borrowed', label: Text('I borrowed')),
                      ],
                      selected: {_direction ?? 'lent'},
                      onSelectionChanged: (s) => setState(() => _direction = s.first),
                      style: SegmentedButton.styleFrom(
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ]),
                ),
              ])),
              const SizedBox(height: 10),
            ],

            // Target amount
            _FormCard(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: CalculatorAmountField(
                value: _targetAmount,
                hintText: '0.00',
                label: 'Target amount',
                currency: _currency,
                fontSize: 24,
                onChanged: (v) => setState(() => _targetAmount = v),
              ),
            )),
            const SizedBox(height: 10),
            // Currency
            _FormCard(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: CurrencyPickerField(
                label: 'Currency',
                value: _currency,
                onChanged: (v) => setState(() => _currency = v),
              ),
            )),
            const SizedBox(height: 10),

            // Deadline
            _FormCard(child: InkWell(
              onTap: _pickDate,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(children: [
                  Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.ts(context)),
                  const SizedBox(width: 10),
                  Text(
                    _endDate != null
                        ? 'Deadline: ${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                        : 'Set a deadline (optional)',
                    style: TextStyle(fontSize: 14, color: _endDate != null
                        ? AppColors.tp(context) : AppColors.th(context)),
                  ),
                  const Spacer(),
                  if (_endDate != null)
                    GestureDetector(
                      onTap: () => setState(() => _endDate = null),
                      child: Icon(Icons.close_rounded, size: 16, color: AppColors.th(context)),
                    ),
                ]),
              ),
            )),
            const SizedBox(height: 16),

            // Color picker
            Text('COLOR', style: TextStyle(
              fontSize: TypographyTokens.sectionHeaderSize,
              fontWeight: TypographyTokens.sectionHeaderWeight,
              letterSpacing: TypographyTokens.sectionHeaderLetterSpacing,
              color: AppColors.th(context),
            )),
            const SizedBox(height: 8),
            Wrap(spacing: 10, runSpacing: 10,
              children: _colors.map((hex) {
                final c = AppColors.fromHex(hex);
                final selected = _colorHex == hex;
                return GestureDetector(
                  onTap: () => setState(() => _colorHex = hex),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: c, shape: BoxShape.circle,
                      border: selected ? Border.all(color: AppColors.tp(context), width: 3) : null,
                    ),
                    child: selected ? const Icon(Icons.check_rounded, color: Colors.white, size: 16) : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Objective'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.overspent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      final db = ref.read(databaseProvider);
      await (db.delete(db.objectives)
            ..where((o) => o.id.equals(widget.objectiveId)))
          .go();
      ref.invalidate(objectivesProvider);
      if (mounted) context.pop();
    }
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.accent.withValues(alpha: 0.12)
                : AppColors.sf(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.bd(context),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18,
                  color: selected ? AppColors.accent : AppColors.ts(context)),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected ? AppColors.accent : AppColors.ts(context),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  final Widget child;
  const _FormCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.circular(CardTokens.radius),
        border: Border.all(color: AppColors.bd(context)),
      ),
      child: child,
    );
  }
}
