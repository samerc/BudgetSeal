import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../core/database/app_database.dart';
import '../../core/database/daos/accounts_dao.dart';
import '../../core/engine/balance_calculator.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/engine_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/utils/format_number.dart';
import '../../shared/widgets/calculator_amount_field.dart';
import '../../shared/widgets/category_icon.dart';
import '../../shared/widgets/currency_picker_field.dart';
import '../../core/providers/transactions_provider.dart';
import '../../core/providers/categories_provider.dart';

class AccountDetailScreen extends ConsumerStatefulWidget {
  final String accountId;
  const AccountDetailScreen({super.key, required this.accountId});

  @override
  ConsumerState<AccountDetailScreen> createState() =>
      _AccountDetailScreenState();
}

class _AccountDetailScreenState extends ConsumerState<AccountDetailScreen> {
  final _nameController = TextEditingController();
  final _currencyController = TextEditingController();
  double _initialBalance = 0;
  String _type = 'cash';
  bool _loading = false;
  double? _currentBalance;

  bool get _isNew => widget.accountId == 'new';

  static const _accountTypes = [
    ('cash', 'Cash', Icons.wallet),
    ('bank', 'Bank', Icons.account_balance),
    ('credit', 'Credit card', Icons.credit_card),
    ('wallet', 'Digital wallet', Icons.account_balance_wallet),
  ];

  @override
  void initState() {
    super.initState();
    if (_isNew) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final household = ref.read(householdProvider).value;
        if (household != null && mounted) {
          setState(() => _currencyController.text = household.baseCurrency);
        }
      });
    } else {
      _loadAccount();
    }
  }

  Future<void> _loadAccount() async {
    final db = ref.read(databaseProvider);
    final acc = await AccountsDao(db).getById(widget.accountId);
    if (acc != null && mounted) {
      final calculator = BalanceCalculator(db);
      final balance = await calculator.accountBalance(acc.id);
      setState(() {
        _nameController.text = acc.name;
        _currencyController.text = acc.currency;
        _initialBalance = acc.initialBalance;
        _type = acc.type;
        _currentBalance = balance;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _currencyController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: AppColors.sfv(context),
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      hintStyle: const TextStyle(color: AppColors.textHint),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
      ),
    );
  }

  bool _showSettings = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isNew
              ? 'New Account'
              : _nameController.text.isNotEmpty
                  ? _nameController.text
                  : 'Account',
        ),
        actions: [
          if (!_isNew)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (v) {
                if (v == 'adjust') {
                  _showAdjustBalanceSheet();
                } else if (v == 'archive') {
                  _confirmArchive();
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'adjust',
                  child: Row(
                    children: [
                      Icon(Icons.tune_rounded, size: 18),
                      SizedBox(width: 10),
                      Text('Adjust Balance'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'archive',
                  child: Row(
                    children: [
                      Icon(Icons.archive_outlined,
                          size: 18, color: AppColors.overspent),
                      const SizedBox(width: 10),
                      Text('Archive Account',
                          style: TextStyle(color: AppColors.overspent)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Current balance display card (existing accounts only)
            if (!_isNew && _currentBalance != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFF2A3F6A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'Current Balance',
                      style: TextStyle(
                          color: Colors.white60,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      formatAmount(_currentBalance!,
                          currency: _currencyController.text),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _currentBalance! >= 0
                                ? Icons.trending_up_rounded
                                : Icons.trending_down_rounded,
                            size: 14,
                            color: _currentBalance! >= 0
                                ? AppColors.healthy
                                : AppColors.overspent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _currencyController.text,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            // Settings section
            if (!_isNew) ...[
              // Collapsible settings toggle
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
                        child: Text('Account Settings',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
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
            ],
            if (_isNew || _showSettings) ...[
              const SizedBox(height: 8),
            ],
            if (_isNew || _showSettings)
              Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.sf(context),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: _inputDecoration('Account name'),
                    textCapitalization: TextCapitalization.words,
                    autofocus: _isNew,
                    style: TextStyle(color: AppColors.tp(context)),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Account type',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _accountTypes.map((entry) {
                      final (value, label, icon) = entry;
                      final selected = _type == value;
                      return GestureDetector(
                        onTap: () => setState(() => _type = value),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.accent.withValues(alpha: 0.1)
                                : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected
                                  ? AppColors.accent
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                icon,
                                size: 20,
                                color: selected
                                    ? AppColors.accent
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                label,
                                style: TextStyle(
                                  color: selected
                                      ? AppColors.accent
                                      : AppColors.textSecondary,
                                  fontWeight: selected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  CurrencyPickerField(
                    label: 'Currency',
                    value: _currencyController.text.isEmpty
                        ? 'USD'
                        : _currencyController.text,
                    onChanged: (v) =>
                        setState(() => _currencyController.text = v),
                  ),
                  if (_isNew) ...[
                    const SizedBox(height: 16),
                    CalculatorAmountField(
                      value: _initialBalance,
                      label: 'Opening balance',
                      fontSize: 20,
                      onChanged: (v) => setState(() => _initialBalance = v),
                    ),
                  ],
                ],
              ),
            ),
            if (_isNew || _showSettings) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: _loading ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  disabledBackgroundColor:
                      AppColors.accent.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        _isNew ? 'Create account' : 'Save',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            ],
            // Account transactions (existing accounts only)
            if (!_isNew) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  const Icon(Icons.receipt_long_rounded,
                      size: 18, color: AppColors.accent),
                  const SizedBox(width: 8),
                  const Text(
                    'RECENT TRANSACTIONS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildAccountTransactions(),
            ],
          ],
        ),
      ),
    );
  }

  Color _hexToColor(String hex) {
    final clean = hex.replaceAll('#', '');
    return Color(int.parse('FF$clean', radix: 16));
  }

  Widget _buildAccountTransactions() {
    final entriesAsync = ref.watch(transactionEntriesProvider);
    final categories = ref.watch(categoriesProvider).value ?? [];
    final catMap = {for (final c in categories) c.id: c};

    return entriesAsync.when(
      data: (entries) {
        // Filter to transactions involving this account.
        final filtered = entries.where((e) {
          if (e.tx.accountId == widget.accountId) return true;
          if (e.tx.destinationAccountId == widget.accountId) return true;
          for (final l in e.lines) {
            if (l.accountId == widget.accountId) return true;
          }
          return false;
        }).take(10).toList();

        if (filtered.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.sf(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('No transactions yet',
                  style: TextStyle(color: AppColors.textHint)),
            ),
          );
        }

        return Column(
          children: filtered.map((e) {
            final tx = e.tx;
            final isIncome = tx.type == 'income';
            final isTransfer = tx.type == 'transfer';
            final sign = isIncome || (isTransfer && tx.destinationAccountId == widget.accountId) ? '+' : '-';
            final color = sign == '+'
                ? AppColors.healthy
                : AppColors.overspent;
            final cat = tx.categoryId != null ? catMap[tx.categoryId] : null;
            final catName = cat?.name ?? '';
            final label = tx.note.isNotEmpty
                ? tx.note
                : catName.isNotEmpty
                    ? catName
                    : tx.type;
            final catColor = cat != null
                ? _hexToColor(cat.colorHex)
                : AppColors.textSecondary;

            // Determine display amount from lines
            final lines = e.lines;
            final acctLine = lines.where(
                (l) => l.accountId == widget.accountId).firstOrNull;
            final displayAmt = acctLine?.amount ?? tx.amount;
            final displayCur = acctLine?.currency ?? tx.currency;
            final showBase = displayCur != tx.currency;

            return Container(
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: AppColors.sf(context),
                borderRadius: BorderRadius.circular(10),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => context.push('/transactions/${tx.id}'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      CategoryIcon(
                        categoryName: cat?.name ?? tx.type,
                        color: catColor,
                        size: 40,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(label,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat('MMM d, yyyy')
                                  .format(tx.createdAt.toLocal()),
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textHint),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            formatSignedAmount(displayAmt, currency: displayCur, type: sign == '+' ? 'income' : 'expense'),
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: color),
                          ),
                          if (showBase)
                            Text(
                              '\u2248 ${formatAmount(tx.amount, currency: tx.currency)}',
                              style: const TextStyle(
                                  fontSize: 9,
                                  color: AppColors.textHint),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  // ---------------------------------------------------------------------------
  // Adjust balance
  // ---------------------------------------------------------------------------

  Future<void> _showAdjustBalanceSheet() async {
    final adjustCtrl = TextEditingController();
    final currency = _currencyController.text.trim().toUpperCase();

    final result = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          decoration: BoxDecoration(
            color: AppColors.sf(context),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Adjust Balance',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.tp(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the actual balance of this account. An adjustment transaction will be created for the difference.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              if (_currentBalance != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Current balance: ${formatAmount(_currentBalance!, currency: currency)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: adjustCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true, signed: true),
                autofocus: true,
                decoration: _inputDecoration('Actual balance',
                    hint: 'Enter the real balance'),
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.tp(context)),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  final val = double.tryParse(adjustCtrl.text);
                  if (val != null) {
                    Navigator.pop(ctx, val);
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Apply Adjustment',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        );
      },
    );

    if (result != null && _currentBalance != null && mounted) {
      final diff = result - _currentBalance!;
      if (diff.abs() < 0.001) return; // No change.

      setState(() => _loading = true);
      try {
        final householdId = ref.read(currentHouseholdIdProvider);
        if (householdId == null) return;
        final engine = ref.read(allocationEngineProvider);
        final currency = _currencyController.text.trim().toUpperCase();

        if (diff > 0) {
          // Positive adjustment → record as income.
          await engine.recordIncome(
            householdId: householdId,
            accountId: widget.accountId,
            amount: diff,
            currency: currency,
            exchangeRateToBase: 1.0,
            createdBy: 'user',
            deviceId: 'local',
            note: 'Balance adjustment',
          );
        } else {
          // Negative adjustment → record as expense (no allocation).
          final txId = const Uuid().v4();
          final db = ref.read(databaseProvider);
          await db.into(db.transactions).insert(
                TransactionsCompanion.insert(
                  id: txId,
                  householdId: householdId,
                  type: 'expense',
                  accountId: widget.accountId,
                  amount: diff.abs(),
                  currency: currency,
                  createdBy: 'user',
                  deviceId: 'local',
                  note: const Value('Balance adjustment'),
                ),
              );
        }

        await _loadAccount(); // Refresh current balance.
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Balance adjusted by ${formatSignedAmount(diff, currency: currency, type: diff > 0 ? 'income' : 'expense')}'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Archive
  // ---------------------------------------------------------------------------

  Future<void> _confirmArchive() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Archive Account'),
        content: const Text(
          'This account will be hidden from all lists and dropdowns. '
          'Your transactions will be preserved.\n\n'
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
      await (db.update(db.accounts)
            ..where((a) => a.id.equals(widget.accountId)))
          .write(const AccountsCompanion(archived: Value(true)));
      if (mounted) context.pop();
    }
  }

  // ---------------------------------------------------------------------------
  // Save
  // ---------------------------------------------------------------------------

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final currency = _currencyController.text.trim().toUpperCase();
    if (currency.isEmpty) return;
    final balance = _initialBalance;
    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null) return;

    setState(() => _loading = true);
    try {
      final db = ref.read(databaseProvider);
      final id = _isNew ? const Uuid().v4() : widget.accountId;
      await AccountsDao(db).upsert(AccountsCompanion.insert(
        id: id,
        householdId: householdId,
        name: name,
        type: _type,
        currency: currency,
        initialBalance: Value(balance),
        deviceId: 'local',
      ));
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
