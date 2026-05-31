import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' show Value;

import '../../core/database/app_database.dart';
import '../../core/providers/accounts_provider.dart';
import '../../core/providers/categories_provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/design_tokens.dart';
import '../../shared/utils/haptics.dart';
import '../../shared/widgets/amount_field.dart';
import '../transactions/widgets/category_sheet.dart';
import '../transactions/widgets/transaction_form_widgets.dart';

enum _PlanType { expense, income, transfer }

class PlanPaymentScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? editTx;

  const PlanPaymentScreen({super.key, this.editTx});

  @override
  ConsumerState<PlanPaymentScreen> createState() => _PlanPaymentScreenState();
}

class _PlanPaymentScreenState extends ConsumerState<PlanPaymentScreen> {
  _PlanType _type = _PlanType.expense;
  final _amountCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String? _accountId;
  String? _destAccountId;
  String? _categoryId;
  String? _categoryName;
  Color _categoryColor = AppColors.textSecondary;
  String? _validationError;
  bool _loading = false;

  // Target month
  late int _targetYear;
  late int _targetMonth;
  DateTime? _exactDate;

  // Currency (derived from selected account)
  String _currency = 'USD';

  bool get _isEditing => widget.editTx != null;

  String get _baseCurrency =>
      ref.read(householdProvider).value?.baseCurrency ?? 'USD';

  @override
  void initState() {
    super.initState();
    // Default target: next month
    final now = DateTime.now();
    _targetYear = now.month == 12 ? now.year + 1 : now.year;
    _targetMonth = now.month == 12 ? 1 : now.month + 1;
    _currency = _baseCurrency;

    if (_isEditing) {
      _initFromEdit();
    }
  }

  void _initFromEdit() {
    final data = widget.editTx!;
    final tx = data['transaction'] as Transaction?;
    final lines = data['lines'] as List<TransactionLine>?;
    if (tx == null) return;

    // Type
    if (tx.type == 'income') {
      _type = _PlanType.income;
    } else if (tx.type == 'transfer') {
      _type = _PlanType.transfer;
    }

    // Amount
    _amountCtrl.text = tx.amount > 0 ? tx.amount.toString() : '';

    // Account
    _accountId = tx.accountId;
    _destAccountId = tx.destinationAccountId;
    _currency = tx.currency;

    // Category from first line
    if (lines != null && lines.isNotEmpty) {
      _categoryId = lines.first.categoryId;
    }

    // Note/title
    final note = tx.note;
    if (note.contains(' — ')) {
      final parts = note.split(' — ');
      _titleCtrl.text = parts.first;
      _noteCtrl.text = parts.skip(1).join(' — ');
    } else {
      _titleCtrl.text = note;
    }

    // Target date
    _targetYear = tx.createdAt.year;
    _targetMonth = tx.createdAt.month;
    // If the day is not the 1st, treat it as an exact date
    if (tx.createdAt.day != 1) {
      _exactDate = tx.createdAt;
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  // ─── Pickers ────────────────────────────────────────────────────────────────

  Future<void> _pickCategory() async {
    final categories = ref.read(categoriesProvider).value ?? [];
    final householdId = ref.read(currentHouseholdIdProvider);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CategorySheet(
        categories: categories,
        selectedId: _categoryId,
        householdId: householdId,
        onSelected: (id, name, color, txType) {
          setState(() {
            _categoryId = id;
            _categoryName = name;
            _categoryColor = color;
            if (_type != _PlanType.transfer) {
              _type = txType == 'income' ? _PlanType.income : _PlanType.expense;
            }
          });
          Navigator.of(ctx).pop();
        },
        onCreated: (_) {},
      ),
    );
  }

  Future<void> _pickExactDate() async {
    final firstDay = DateTime(_targetYear, _targetMonth, 1);
    final lastDay = DateTime(_targetYear, _targetMonth + 1, 0);
    final picked = await showDatePicker(
      context: context,
      initialDate: _exactDate ?? firstDay,
      firstDate: firstDay,
      lastDate: lastDay,
    );
    if (picked != null && mounted) {
      setState(() => _exactDate = picked);
    }
  }

  // ─── Validation + Save ──────────────────────────────────────────────────────

  String? _validate() {
    final tr = S.of(context);
    if (_type == _PlanType.transfer) {
      if (_accountId == null) return tr.txFormSelectSource;
      if (_destAccountId == null) return tr.txFormSelectDest;
      if (_accountId == _destAccountId) return tr.txFormSourceDestDiffer;
    } else {
      if (_accountId == null) return tr.plannedSelectAccount;
    }
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '')) ?? 0;
    if (amount <= 0) return tr.txFormEnterAmount;
    return null;
  }

  Future<void> _save() async {
    final error = _validate();
    if (error != null) {
      setState(() => _validationError = error);
      hapticHeavy();
      return;
    }

    hapticMedium();
    setState(() {
      _validationError = null;
      _loading = true;
    });

    try {
      final db = ref.read(databaseProvider);
      final householdId = ref.read(currentHouseholdIdProvider);
      if (householdId == null) return;

      final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '')) ?? 0;
      final title = _titleCtrl.text.trim();
      final note = _noteCtrl.text.trim();
      final effectiveNote = title.isNotEmpty && note.isNotEmpty
          ? '$title — $note'
          : title.isNotEmpty
              ? title
              : note;

      final targetDate =
          _exactDate ?? DateTime(_targetYear, _targetMonth, 1);

      final typeStr = switch (_type) {
        _PlanType.income => 'income',
        _PlanType.expense => 'expense',
        _PlanType.transfer => 'transfer',
      };

      // If editing, soft-delete old transaction (lines can be hard-deleted
      // since they aren't synced independently)
      if (_isEditing) {
        final oldTx = widget.editTx!['transaction'] as Transaction?;
        if (oldTx != null) {
          await (db.delete(db.transactionLines)
                ..where((l) => l.transactionId.equals(oldTx.id)))
              .go();
          await (db.update(db.transactions)
                ..where((t) => t.id.equals(oldTx.id)))
              .write(TransactionsCompanion(
            deleted: const Value(true),
            lastModified: Value(DateTime.now()),
          ));
        }
      }

      final txId = const Uuid().v4();
      final now = DateTime.now();

      await db.into(db.transactions).insert(TransactionsCompanion.insert(
            id: txId,
            householdId: householdId,
            type: typeStr,
            accountId: _accountId!,
            destinationAccountId: Value(_type == _PlanType.transfer ? _destAccountId : null),
            amount: amount,
            currency: _currency,
            exchangeRateToBase: const Value(1.0),
            categoryId: Value(_categoryId),
            createdBy: 'user',
            deviceId: 'local',
            note: Value(effectiveNote),
            createdAt: Value(targetDate),
            status: const Value('planned'),
            lastModified: Value(now),
          ));

      // Insert transaction line
      await db.into(db.transactionLines).insert(TransactionLinesCompanion.insert(
            id: const Uuid().v4(),
            transactionId: txId,
            amount: amount,
            currency: _currency,
            categoryId: Value(_categoryId),
            accountId: Value(_accountId),
            exchangeRateToBase: const Value(1.0),
          ));

      if (!mounted) return;

      final tr = S.of(context);
      final nav = GoRouter.of(context);
      final messenger = ScaffoldMessenger.maybeOf(context);
      nav.pop(true);
      messenger?.clearSnackBars();
      messenger?.showSnackBar(SnackBar(
        content: Text(_isEditing ? tr.plannedUpdated : tr.plannedCreated),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        dismissDirection: DismissDirection.horizontal,
      ));
      return;
    } catch (e) {
      debugPrint('[PlanPayment] Save error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(S.of(context).plannedSaveFailed),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  Color _typeColor() {
    return switch (_type) {
      _PlanType.income => AppColors.healthy,
      _PlanType.expense => AppColors.overspent,
      _PlanType.transfer => AppColors.accent,
    };
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider).value ?? [];
    final nonArchived = accounts.where((a) => !a.archived).toList();

    // Resolve category name if not yet set (for edit mode)
    if (_categoryId != null && _categoryName == null) {
      final categories = ref.read(categoriesProvider).value ?? [];
      final cat = categories.where((c) => c.id == _categoryId).firstOrNull;
      if (cat != null) {
        _categoryName = cat.name;
        _categoryColor = AppColors.fromHex(cat.colorHex);
      }
    }

    // Resolve account currency
    if (_accountId != null) {
      final acc = nonArchived.where((a) => a.id == _accountId).firstOrNull;
      if (acc != null) _currency = acc.currency;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? S.of(context).plannedEditTitle : S.of(context).plannedPlanButton),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: _loading ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: _typeColor(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                minimumSize: Size.zero,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              icon: _loading
                  ? const SizedBox(
                      height: 14,
                      width: 14,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.check_rounded, size: 18),
              label: Text(S.of(context).plannedPlanButton,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Type Selector ──
            _buildTypeSelector(),
            const SizedBox(height: 12),

            // ── Amount ──
            _TxFieldCard(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text(_currency,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ts(context),
                            letterSpacing: 0.5)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AmountField(
                        controller: _amountCtrl,
                        onChanged: () => setState(() {}),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // ── Account ──
            _TxFieldCard(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: DropdownButtonFormField<String>(
                  value: _accountId,
                  decoration: InputDecoration(
                    labelText:
                        _type == _PlanType.transfer ? S.of(context).txFormFromAccount : S.of(context).plannedAccount,
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.account_balance_rounded,
                        size: 18, color: AppColors.ts(context)),
                  ),
                  items: nonArchived
                      .map((a) => DropdownMenuItem(
                            value: a.id,
                            child: Text(
                              '${a.name} (${a.currency})',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val == null) return;
                    final acc =
                        nonArchived.where((a) => a.id == val).firstOrNull;
                    setState(() {
                      _accountId = val;
                      if (acc != null) _currency = acc.currency;
                      _validationError = null;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),

            // ── Destination Account (transfers only) ──
            if (_type == _PlanType.transfer) ...[
              _TxFieldCard(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: DropdownButtonFormField<String>(
                    value: _destAccountId,
                    decoration: InputDecoration(
                      labelText: S.of(context).txFormToAccount,
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.account_balance_rounded,
                          size: 18, color: AppColors.ts(context)),
                    ),
                    items: nonArchived
                        .where((a) => a.id != _accountId)
                        .map((a) => DropdownMenuItem(
                              value: a.id,
                              child: Text(
                                '${a.name} (${a.currency})',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        _destAccountId = val;
                        _validationError = null;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],

            // ── Category (not for transfers) ──
            if (_type != _PlanType.transfer) ...[
              _TxFieldCard(
                child: InkWell(
                  onTap: _pickCategory,
                  borderRadius: BorderRadius.circular(CardTokens.radius),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Icon(Icons.label_outline_rounded,
                            size: 18, color: AppColors.ts(context)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _categoryId != null
                              ? Row(
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                          color: _categoryColor,
                                          shape: BoxShape.circle),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(_categoryName ?? S.of(context).plannedCategory,
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.tp(context))),
                                  ],
                                )
                              : Text(S.of(context).plannedCategory,
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.th(context))),
                        ),
                        Icon(Icons.expand_more_rounded,
                            size: 18, color: AppColors.ts(context)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],

            // ── Title ──
            _TxFieldCard(
              child: TextField(
                controller: _titleCtrl,
                textCapitalization: TextCapitalization.sentences,
                maxLength: InputLimits.nameMaxLength,
                decoration: InputDecoration(
                  hintText: S.of(context).plannedTitleHint,
                  hintStyle: TextStyle(color: AppColors.th(context)),
                  prefixIcon: Icon(Icons.short_text_rounded,
                      size: 18, color: AppColors.ts(context)),
                  border: InputBorder.none,
                  counterText: '',
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // ── Note ──
            _TxFieldCard(
              child: TextField(
                controller: _noteCtrl,
                textCapitalization: TextCapitalization.sentences,
                maxLength: InputLimits.noteMaxLength,
                decoration: InputDecoration(
                  hintText: S.of(context).plannedNoteHint,
                  hintStyle: TextStyle(color: AppColors.th(context)),
                  prefixIcon: Icon(Icons.notes_rounded,
                      size: 18, color: AppColors.ts(context)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
                maxLines: 3,
                minLines: 1,
              ),
            ),
            const SizedBox(height: 16),

            // ── Target Month ──
            _buildTargetMonthSection(),
            const SizedBox(height: 12),

            // ── Exact Date (optional) ──
            _TxFieldCard(
              child: InkWell(
                onTap: _pickExactDate,
                borderRadius: BorderRadius.circular(CardTokens.radius),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Icon(Icons.today_rounded,
                          size: 18, color: AppColors.ts(context)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _exactDate != null
                              ? S.of(context).plannedExactDateValue('${_exactDate!.day} ${_monthName(_exactDate!.month)}')
                              : S.of(context).plannedExactDate,
                          style: TextStyle(
                            fontSize: 14,
                            color: _exactDate != null
                                ? AppColors.tp(context)
                                : AppColors.th(context),
                          ),
                        ),
                      ),
                      if (_exactDate != null)
                        GestureDetector(
                          onTap: () => setState(() => _exactDate = null),
                          child: Icon(Icons.close_rounded,
                              size: 18, color: AppColors.ts(context)),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Validation Error ──
            if (_validationError != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.overspentLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.overspent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_rounded,
                        size: 16, color: AppColors.overspent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _validationError!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.overspent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ─── Type Selector ────────────────────────────────────────────────────────

  Widget _buildTypeSelector() {
    final tr = S.of(context);
    return Row(
      children: [
        TypeChip(
          label: tr.typeExpense,
          icon: Icons.arrow_upward_rounded,
          selected: _type == _PlanType.expense,
          color: AppColors.overspent,
          onTap: () => setState(() => _type = _PlanType.expense),
        ),
        const SizedBox(width: 8),
        TypeChip(
          label: tr.typeIncome,
          icon: Icons.arrow_downward_rounded,
          selected: _type == _PlanType.income,
          color: AppColors.healthy,
          onTap: () => setState(() => _type = _PlanType.income),
        ),
        const SizedBox(width: 8),
        TypeChip(
          label: tr.typeTransfer,
          icon: Icons.swap_horiz_rounded,
          selected: _type == _PlanType.transfer,
          color: AppColors.accent,
          onTap: () => setState(() => _type = _PlanType.transfer),
        ),
      ],
    );
  }

  // ─── Target Month ─────────────────────────────────────────────────────────

  Widget _buildTargetMonthSection() {
    final months = List.generate(
      12,
      (i) => DateFormat('MMM').format(DateTime(2000, i + 1)),
    );

    return _TxFieldCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Year selector
            Row(
              children: [
                Icon(Icons.calendar_month_rounded,
                    size: 18, color: AppColors.ts(context)),
                const SizedBox(width: 12),
                Text(S.of(context).plannedTargetMonth,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.tp(context))),
                const Spacer(),
                IconButton(
                  onPressed: () =>
                      setState(() => _targetYear = _targetYear - 1),
                  icon: Icon(Icons.chevron_left_rounded,
                      size: 20, color: AppColors.ts(context)),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                Text('$_targetYear',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.tp(context))),
                IconButton(
                  onPressed: () =>
                      setState(() => _targetYear = _targetYear + 1),
                  icon: Icon(Icons.chevron_right_rounded,
                      size: 20, color: AppColors.ts(context)),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Month chips
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: List.generate(12, (i) {
                final month = i + 1;
                final selected = _targetMonth == month;
                final color = _typeColor();
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _targetMonth = month;
                      // Reset exact date when month changes
                      _exactDate = null;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? color
                          : color.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(RadiusTokens.pill),
                      border: Border.all(
                        color: selected
                            ? color
                            : color.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      months[i],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : color,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  String _monthName(int month) {
    return DateFormat('MMMM').format(DateTime(2000, month));
  }
}

// ─── Shared Card Wrapper (matches add_transaction_screen) ─────────────────

class _TxFieldCard extends StatelessWidget {
  final Widget child;
  const _TxFieldCard({required this.child});

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
