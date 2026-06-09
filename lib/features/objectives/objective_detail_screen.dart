import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/database/app_database.dart';
import '../../core/engine/allocation_engine.dart';
import '../../core/providers/accounts_provider.dart';
import '../../core/providers/categories_provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/engine_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../core/providers/date_format_provider.dart';
import '../../core/providers/objectives_provider.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/design_tokens.dart';
import '../../shared/utils/format_number.dart';
import '../../shared/widgets/calculator_amount_field.dart';
import '../../shared/widgets/currency_picker_field.dart';
import '../../l10n/generated/app_localizations.dart';

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
  String? _categoryId; // optional category for payments
  String? _categoryName;
  bool _loading = false;
  bool _showSettings = false; // toggle for edit form (existing objectives)

  // Payment history
  List<Transaction> _payments = [];

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
      // Load payment history
      await _loadPayments();
    } catch (e) {
      debugPrint('[ObjectiveDetail] Error loading: $e');
    }
  }

  Future<void> _loadPayments() async {
    if (_isNew) return;
    final db = ref.read(databaseProvider);
    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null) return;

    // Primary: search by objective ID tag (new format)
    // Fallback: search by name (legacy transactions before ID tagging)
    final idTag = '[obj:${widget.objectiveId}]';
    final name = _nameCtrl.text.trim();

    var txs = await (db.select(db.transactions)
          ..where((t) =>
              t.householdId.equals(householdId) &
              t.deleted.equals(false) &
              t.note.like('%$idTag%'))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();

    // Fallback: match by name for pre-existing payments
    if (txs.isEmpty && name.isNotEmpty) {
      // Escape SQL LIKE wildcards in user input
      final escapedName = name
          .replaceAll('\\', '\\\\')
          .replaceAll('%', '\\%')
          .replaceAll('_', '\\_');
      txs = await (db.select(db.transactions)
            ..where((t) =>
                t.householdId.equals(householdId) &
                t.deleted.equals(false) &
                t.note.like('%$escapedName%'))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();
    }

    if (mounted) setState(() => _payments = txs);
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
        SnackBar(content: Text(S.of(context).objNameRequired),
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
            content: Text(_isNew ? S.of(context).objCreated : S.of(context).objUpdated),
            behavior: SnackBarBehavior.floating,
          ),
        );
        if (_isNew) {
          context.pop();
        } else {
          setState(() => _showSettings = false);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).commonSomethingWentWrong),
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
          SnackBar(content: Text(S.of(context).objNoAccounts),
              behavior: SnackBarBehavior.floating),
        );
      }
      return;
    }

    // Load categories for picker
    final categories = ref.read(categoriesProvider).value ?? [];

    final isLoan = _type == 'loan';
    final isLent = _direction == 'lent';
    final txType = isLoan && isLent ? 'income' : 'expense';
    final tr = S.of(context);
    final sheetTitle = isLoan ? tr.objRecordPayment : tr.objAddFunds;
    final buttonLabel = isLoan
        ? (isLent ? tr.objRecordReceived : tr.objRecordSent)
        : tr.objSaveFromAccount;

    final tpColor = AppColors.tp(context);
    final tsColor = AppColors.ts(context);
    final bdColor = AppColors.bd(context);
    final sfColor = AppColors.sf(context);
    final sfvColor = AppColors.sfv(context);

    final result = await showModalBottomSheet<({double amount, String accountId, String? categoryId})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: sfColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        double amount = 0;
        String? selectedAccountId = activeAccounts.first.id;
        String? selectedCategoryId = _categoryId;
        String? selectedCategoryName = _categoryName;

        return StatefulBuilder(
          builder: (ctx, setModalState) => Padding(
            padding: EdgeInsets.fromLTRB(
                24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(sheetTitle,
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                      color: tpColor)),
              const SizedBox(height: 4),
              Text(tr.objCurrent(formatAmount(_currentAmount, currency: _currency)),
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
              const SizedBox(height: 12),

              // Category picker (optional)
              GestureDetector(
                onTap: () async {
                  final expenseCategories = categories
                      .where((c) => c.transactionType == txType)
                      .toList();
                  if (expenseCategories.isEmpty) return;

                  await showModalBottomSheet(
                    context: ctx,
                    isScrollControlled: true,
                    backgroundColor: sfColor,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (catCtx) => Container(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(catCtx).size.height * 0.6,
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(tr.commonCategory, style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w700,
                              color: tpColor)),
                          const SizedBox(height: 12),
                          // None option
                          ListTile(
                            dense: true,
                            title: Text(tr.commonNone, style: TextStyle(color: tsColor)),
                            leading: Icon(Icons.block_rounded, size: 18, color: tsColor),
                            onTap: () {
                              setModalState(() {
                                selectedCategoryId = null;
                                selectedCategoryName = null;
                              });
                              Navigator.pop(catCtx);
                            },
                          ),
                          const Divider(height: 1),
                          Expanded(
                            child: ListView.builder(
                              itemCount: expenseCategories.length,
                              itemBuilder: (_, i) {
                                final cat = expenseCategories[i];
                                final isParent = cat.parentId == null;
                                return ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.only(
                                    left: isParent ? 16 : 40, right: 16),
                                  title: Text(cat.name,
                                      style: TextStyle(
                                        fontWeight: isParent ? FontWeight.w600 : FontWeight.w400,
                                        fontSize: 14,
                                      )),
                                  trailing: selectedCategoryId == cat.id
                                      ? Icon(Icons.check_rounded, size: 18, color: AppColors.accent)
                                      : null,
                                  onTap: () {
                                    setModalState(() {
                                      selectedCategoryId = cat.id;
                                      selectedCategoryName = cat.name;
                                    });
                                    Navigator.pop(catCtx);
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: sfvColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: bdColor),
                  ),
                  child: Row(children: [
                    Icon(Icons.label_rounded, size: 16, color: tsColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        selectedCategoryName ?? tr.objCategoryOptional,
                        style: TextStyle(
                          fontSize: 14,
                          color: selectedCategoryName != null ? tpColor : tsColor,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, size: 18, color: tsColor),
                  ]),
                ),
              ),
              const SizedBox(height: 16),

              // Amount
              CalculatorAmountField(
                value: amount,
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
                      ? () => Navigator.pop(ctx,
                          (amount: amount, accountId: selectedAccountId!, categoryId: selectedCategoryId))
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

      final noteName = _type == 'loan' && _contactCtrl.text.isNotEmpty
          ? '${_nameCtrl.text.trim()} — ${_contactCtrl.text.trim()}'
          : _nameCtrl.text.trim();

      await engine.recordTransaction(
        householdId: householdId,
        accountId: result.accountId,
        type: txType,
        lines: [
          TxLine(
            amount: result.amount,
            currency: _currency,
            exchangeRateToBase: _currency == (ref.read(householdProvider).value?.baseCurrency ?? 'USD')
                ? 1.0
                : (await ref.read(fxServiceProvider).getRateWithCache(_currency, ref.read(householdProvider).value?.baseCurrency ?? 'USD').catchError((_) => 1.0)),
            categoryId: result.categoryId,
          ),
        ],
        baseCurrency: ref.read(householdProvider).value?.baseCurrency ?? 'USD',
        note: isLoan
            ? (isLent ? 'Payment received — $noteName [obj:${widget.objectiveId}]' : 'Payment — $noteName [obj:${widget.objectiveId}]')
            : 'Goal savings — $noteName [obj:${widget.objectiveId}]',
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

      // Remember category choice for next time
      if (result.categoryId != null) {
        _categoryId = result.categoryId;
        final cat = categories.where((c) => c.id == result.categoryId).firstOrNull;
        _categoryName = cat?.name;
      }

      if (mounted) setState(() => _currentAmount = newAmount);
      ref.invalidate(objectivesProvider);
      ref.invalidate(accountsWithBalanceProvider);
      await _loadPayments();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(txType == 'income'
                ? S.of(context).objReceivedFrom(formatAmount(result.amount, currency: _currency), account.name)
                : S.of(context).objPaidFrom(formatAmount(result.amount, currency: _currency), account.name)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).objPaymentFailed),
              behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _endDate ?? now.add(const Duration(days: 90));
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
    final isLoan = _type == 'loan';

    // New: show creation form
    if (_isNew) return _buildForm(context, color);

    // Existing: show summary with optional settings
    return Scaffold(
      appBar: AppBar(
        title: Text(_nameCtrl.text.isEmpty ? 'Objective' : _nameCtrl.text),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: AppColors.tp(context)),
            onSelected: (v) {
              if (v == 'edit') setState(() => _showSettings = !_showSettings);
              if (v == 'delete') _confirmDelete();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(children: [
                  Icon(_showSettings ? Icons.visibility_off_rounded : Icons.settings_rounded,
                      size: 18, color: AppColors.ts(context)),
                  const SizedBox(width: 10),
                  Text(_showSettings ? S.of(context).objHideSettings : S.of(context).objEditSettings),
                ]),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(children: [
                  Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.overspent),
                  const SizedBox(width: 10),
                  Text(S.of(context).commonDelete, style: TextStyle(color: AppColors.overspent)),
                ]),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async { await _load(); },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            // ── Progress hero ──
            if (_targetAmount > 0)
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
                    S.of(context).objOfTarget(formatAmount(_targetAmount, currency: _currency)),
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
                      label: Text(isLoan ? S.of(context).objRecordPayment : S.of(context).objAddFunds),
                    ),
                  ),
                ]),
              ),

            // ── Summary info ──
            const SizedBox(height: 16),
            _SummaryCard(
              children: [
                if (isLoan && _contactCtrl.text.isNotEmpty)
                  _SummaryRow(
                    label: _direction == 'lent'
                        ? S.of(context).objLentTo('').trim()
                        : S.of(context).objBorrowedFrom('').trim(),
                    value: _contactCtrl.text,
                  ),
                _SummaryRow(label: S.of(context).commonCurrency, value: _currency),
                if (_endDate != null)
                  _SummaryRow(
                    label: S.of(context).objSummaryDeadline,
                    value: formatDate(_endDate!),
                  ),
                _SummaryRow(
                  label: S.of(context).objSummaryRemaining,
                  value: formatAmount(
                    (_targetAmount - _currentAmount).clamp(0, double.infinity),
                    currency: _currency,
                  ),
                ),
              ],
            ),

            // ── Payment History ──
            const SizedBox(height: 20),
            Text(
              S.of(context).objPaymentsSection,
              style: TextStyle(
                fontSize: TypographyTokens.sectionHeaderSize,
                fontWeight: TypographyTokens.sectionHeaderWeight,
                letterSpacing: TypographyTokens.sectionHeaderLetterSpacing,
                color: AppColors.th(context),
              ),
            ),
            const SizedBox(height: 8),
            if (_payments.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(S.of(context).objNoPayments,
                      style: TextStyle(fontSize: 13, color: AppColors.ts(context))),
                ),
              )
            else
              ...List.generate(_payments.length, (i) {
                final tx = _payments[i];
                final isIncome = tx.type == 'income';
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.sf(context),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.bd(context)),
                  ),
                  child: Row(children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: (isIncome ? AppColors.healthy : AppColors.overspent)
                            .withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isIncome ? Icons.call_received_rounded : Icons.call_made_rounded,
                        size: 15,
                        color: isIncome ? AppColors.healthy : AppColors.overspent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            formatDate(tx.createdAt),
                            style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600,
                              color: AppColors.tp(context),
                            ),
                          ),
                          if (tx.note.isNotEmpty)
                            Text(tx.note.replaceAll(RegExp(r'\s*\[obj:[^\]]+\]'), ''),
                                style: TextStyle(fontSize: 11, color: AppColors.ts(context)),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    Text(
                      formatAmount(tx.amount, currency: tx.currency),
                      style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700,
                        color: isIncome ? AppColors.healthy : AppColors.overspent,
                      ),
                    ),
                  ]),
                );
              }),

            // ── Settings (hidden, toggled via 3-dot) ──
            if (_showSettings) ...[
              const SizedBox(height: 20),
              Text(
                S.of(context).objSettingsSection,
                style: TextStyle(
                  fontSize: TypographyTokens.sectionHeaderSize,
                  fontWeight: TypographyTokens.sectionHeaderWeight,
                  letterSpacing: TypographyTokens.sectionHeaderLetterSpacing,
                  color: AppColors.th(context),
                ),
              ),
              const SizedBox(height: 8),
              _buildSettingsForm(context, color),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _loading ? null : _save,
                  child: _loading
                      ? const SizedBox(height: 16, width: 16,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(S.of(context).allocSaveChanges),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Full creation form (for new objectives).
  Widget _buildForm(BuildContext context, Color color) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).objNewTitle),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 12),
            child: FilledButton.icon(
              onPressed: _loading ? null : _save,
              icon: _loading
                  ? const SizedBox(height: 14, width: 14,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.check_rounded, size: 18),
              label: Text(S.of(context).commonSave),
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
            // Type toggle
            _buildTypeToggle(),
            const SizedBox(height: 16),
            _buildSettingsForm(context, color),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeToggle() {
    return Row(children: [
      _TypeChip(
        label: S.of(context).objGoalChip, icon: Icons.flag_rounded,
        selected: _type == 'goal',
        onTap: () => setState(() => _type = 'goal'),
      ),
      const SizedBox(width: 8),
      _TypeChip(
        label: S.of(context).objLoanChip, icon: Icons.handshake_rounded,
        selected: _type == 'loan',
        onTap: () => setState(() { _type = 'loan'; _direction ??= 'lent'; }),
      ),
    ]);
  }

  Widget _buildSettingsForm(BuildContext context, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Name
        _FormCard(child: TextField(
          controller: _nameCtrl,
          textCapitalization: TextCapitalization.sentences,
          maxLength: InputLimits.nameMaxLength,
          decoration: InputDecoration(
            labelText: _type == 'loan' ? S.of(context).objLoanName : S.of(context).objGoalName,
            hintText: _type == 'loan' ? S.of(context).objLoanNameHint : S.of(context).objGoalNameHint,
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
              maxLength: InputLimits.nameMaxLength,
              decoration: InputDecoration(
                labelText: S.of(context).objPerson,
                hintText: S.of(context).objPersonHint,
                border: InputBorder.none,
                prefixIcon: Icon(Icons.person_rounded, size: 18, color: AppColors.ts(context)),
              ),
            ),
            Divider(height: 1, color: AppColors.bd(context)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(S.of(context).objDirection, style: TextStyle(fontSize: 14, color: AppColors.ts(context))),
                    const Spacer(),
                    SegmentedButton<String>(
                      segments: [
                        ButtonSegment(value: 'lent', label: Text(S.of(context).objILent)),
                        ButtonSegment(value: 'borrowed', label: Text(S.of(context).objIBorrowed)),
                      ],
                      selected: {_direction ?? 'lent'},
                      onSelectionChanged: (s) => setState(() => _direction = s.first),
                      style: SegmentedButton.styleFrom(
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Text(
                    (_direction ?? 'lent') == 'lent'
                        ? S.of(context).objLoanDirLentHint
                        : S.of(context).objLoanDirBorrowedHint,
                    style: TextStyle(fontSize: 11, color: AppColors.th(context)),
                  ),
                ],
              ),
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
            label: S.of(context).objTargetAmountLabel,
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
            label: S.of(context).commonCurrency,
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
                    ? S.of(context).objDeadlinePrefix(formatDate(_endDate!))
                    : S.of(context).objSetDeadline,
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
        Text(S.of(context).objColorSection, style: TextStyle(
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

        // Type toggle (for existing, allow switching)
        if (!_isNew) ...[
          const SizedBox(height: 16),
          Text(S.of(context).objTypeSection, style: TextStyle(
            fontSize: TypographyTokens.sectionHeaderSize,
            fontWeight: TypographyTokens.sectionHeaderWeight,
            letterSpacing: TypographyTokens.sectionHeaderLetterSpacing,
            color: AppColors.th(context),
          )),
          const SizedBox(height: 8),
          _buildTypeToggle(),
        ],
      ],
    );
  }

  Future<void> _confirmDelete() async {
    final tr = S.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr.objDeleteTitle),
        content: Text(tr.objCannotUndo),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr.commonCancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.overspent),
            child: Text(tr.commonDelete),
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

// ─────────────────────────────────────────────
// Summary Card
// ─────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final List<Widget> children;
  const _SummaryCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.circular(CardTokens.radius),
        border: Border.all(color: AppColors.bd(context)),
      ),
      child: Column(children: children),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: AppColors.ts(context))),
          Text(value, style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: AppColors.tp(context))),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Reusable widgets
// ─────────────────────────────────────────────
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
