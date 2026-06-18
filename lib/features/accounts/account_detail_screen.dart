import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:uuid/uuid.dart';

import '../../core/database/app_database.dart';
import '../../core/database/daos/accounts_dao.dart';
import '../../core/engine/allocation_engine.dart';
import '../../core/engine/balance_calculator.dart';
import '../../core/providers/date_format_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../core/providers/accounts_provider.dart';
import '../../core/providers/allocations_provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/engine_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/design_tokens.dart';
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
  int? _decimalPlaces; // null = auto-detect from currency
  bool _isTravel = false;
  bool _loading = false;
  double? _currentBalance;

  bool get _isNew => widget.accountId == 'new';

  List<(String, String, IconData)> _accountTypes(BuildContext context) {
    final l = S.of(context);
    return [
      ('cash', l.acctTypeCash, Icons.wallet),
      ('bank', l.acctTypeBank, Icons.account_balance),
      ('credit', l.acctTypeCredit, Icons.credit_card),
      ('wallet', l.acctTypeDigital, Icons.account_balance_wallet),
    ];
  }

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
    try {
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
          _decimalPlaces = acc.decimalPlaces;
          _isTravel = acc.isTravel;
          _currentBalance = balance;
        });
      }
    } catch (e) {
      debugPrint('[AccountDetail] Error loading: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _currencyController.dispose();
    super.dispose();
  }

  Widget _formSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.circular(CardTokens.radius),
        border: Border.all(color: AppColors.bd(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.ts(context)),
              const SizedBox(width: 6),
              Text(title,
                  style: TextStyle(
                    fontSize: TypographyTokens.sectionHeaderSize,
                    fontWeight: TypographyTokens.sectionHeaderWeight,
                    letterSpacing: TypographyTokens.sectionHeaderLetterSpacing,
                    color: AppColors.ts(context),
                  )),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: AppColors.sfv(context),
      labelStyle: TextStyle(color: AppColors.ts(context)),
      hintStyle: TextStyle(color: AppColors.th(context)),
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
        borderSide: BorderSide(color: AppColors.accent, width: 1.5),
      ),
    );
  }

  bool _showSettings = false;

  @override
  Widget build(BuildContext context) {
    final l = S.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isNew
              ? l.acctNewTitle
              : _nameController.text.isNotEmpty
                  ? _nameController.text
                  : l.commonAccount,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (!_isNew)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (v) {
                if (v == 'adjust') {
                  _showAdjustBalanceSheet();
                } else if (v == 'convert_back') {
                  _convertBack();
                } else if (v == 'archive') {
                  _confirmArchive();
                } else if (v == 'delete') {
                  _confirmDelete();
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'adjust',
                  child: Row(
                    children: [
                      const Icon(Icons.tune_rounded, size: 18),
                      const SizedBox(width: 10),
                      Text(l.acctAdjustBalance),
                    ],
                  ),
                ),
                if (_isTravel && _currentBalance != null && _currentBalance! > 0)
                  PopupMenuItem(
                    value: 'convert_back',
                    child: Row(
                      children: [
                        const Icon(Icons.currency_exchange_rounded, size: 18),
                        const SizedBox(width: 10),
                        Text(l.acctConvertBackClose),
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
                      Text(l.acctArchiveTitle,
                          style: TextStyle(color: AppColors.overspent)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_forever_rounded,
                          size: 18, color: AppColors.overspent),
                      const SizedBox(width: 10),
                      Text(l.allocDeletePermanently,
                          style: TextStyle(color: AppColors.overspent)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
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
                    Text(
                      l.acctCurrentBalance,
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

            // Travel wallet helper banner
            if (!_isNew && _isTravel && _currentBalance != null && _currentBalance! > 0) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(CardTokens.radius),
                  border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.flight_land_rounded,
                            size: 18, color: AppColors.accent),
                        const SizedBox(width: 8),
                        Text(l.acctBackFromTrip,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.tp(context))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l.acctConvertBackDesc(_currencyController.text),
                      style: TextStyle(
                          fontSize: 13,
                          color: AppColors.ts(context),
                          height: 1.4),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _convertBack,
                        icon: const Icon(Icons.currency_exchange_rounded, size: 16),
                        label: Text(l.acctConvertBackClose),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.accent,
                          side: BorderSide(color: AppColors.accent.withValues(alpha: 0.3)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
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
                      Icon(Icons.settings_outlined,
                          size: 18, color: AppColors.ts(context)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(l.acctSettings,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                      ),
                      Icon(
                        _showSettings
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        color: AppColors.th(context),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (_isNew || _showSettings) ...[
              const SizedBox(height: 8),
            ],
            if (_isNew || _showSettings) ...[
              // ── Name ──
              _formSection(
                context,
                icon: Icons.label_outline_rounded,
                title: l.acctNameSection,
                child: TextField(
                  controller: _nameController,
                  decoration: _inputDecoration(l.acctAccountName),
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  autofocus: _isNew,
                  maxLength: InputLimits.nameMaxLength,
                  style: TextStyle(color: AppColors.tp(context)),
                ),
              ),
              const SizedBox(height: 12),

              // ── Type ──
              _formSection(
                context,
                icon: Icons.category_outlined,
                title: l.acctTypeSection,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _accountTypes(context).map((entry) {
                    final (value, label, icon) = entry;
                    final selected = _type == value;
                    return GestureDetector(
                      onTap: () => setState(() => _type = value),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.accent.withValues(alpha: 0.12)
                              : AppColors.sfv(context),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? AppColors.accent
                                : AppColors.bd(context),
                            width: selected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon,
                                size: 18,
                                color: selected
                                    ? AppColors.accent
                                    : AppColors.ts(context)),
                            const SizedBox(width: 8),
                            Text(label,
                                style: TextStyle(
                                  color: selected
                                      ? AppColors.accent
                                      : AppColors.tp(context),
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  fontSize: 13,
                                )),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),

              // ── Currency ──
              _formSection(
                context,
                icon: Icons.attach_money_rounded,
                title: l.acctCurrencySection,
                child: CurrencyPickerField(
                  label: l.acctSelectCurrency,
                  value: _currencyController.text.isEmpty
                      ? 'USD'
                      : _currencyController.text,
                  onChanged: (v) =>
                      setState(() => _currencyController.text = v),
                ),
              ),

              // ── Decimal places ──
              const SizedBox(height: 12),
              _formSection(
                context,
                icon: Icons.pin_rounded,
                title: l.acctDecimalSection,
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int?>(
                    value: _decimalPlaces,
                    isExpanded: true,
                    isDense: true,
                    items: [
                      DropdownMenuItem<int?>(
                        value: null,
                        child: Text(l.acctDecimalAuto(currencyDecimals(_currencyController.text)),
                            style: TextStyle(fontSize: 14, color: AppColors.tp(context))),
                      ),
                      for (final d in [0, 1, 2, 3])
                        DropdownMenuItem<int?>(
                          value: d,
                          child: Text('$d', style: TextStyle(fontSize: 14, color: AppColors.tp(context))),
                        ),
                    ],
                    onChanged: (v) => setState(() => _decimalPlaces = v),
                  ),
                ),
              ),

              // ── Opening balance (new only) ──
              if (_isNew) ...[
                const SizedBox(height: 12),
                _formSection(
                  context,
                  icon: Icons.account_balance_rounded,
                  title: l.acctOpeningBalance,
                  child: CalculatorAmountField(
                    value: _initialBalance,
                    hintText: '0.00',
                    fontSize: 20,
                    onChanged: (v) => setState(() => _initialBalance = v),
                  ),
                ),
              ],
            ],
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
                    borderRadius: BorderRadius.circular(CardTokens.radius),
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
                        _isNew ? l.acctCreateAccount : l.commonSave,
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
                  Icon(Icons.receipt_long_rounded,
                      size: 18, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Text(
                    l.acctRecentTransactions,
                    style: TextStyle(
                      fontSize: TypographyTokens.sectionHeaderSize,
                      fontWeight: TypographyTokens.sectionHeaderWeight,
                      letterSpacing: TypographyTokens.sectionHeaderLetterSpacing,
                      color: AppColors.ts(context),
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
      ),
    );
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
            child: Center(
              child: Text(S.of(context).acctNoTransactions,
                  style: TextStyle(color: AppColors.th(context))),
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
                ? AppColors.fromHex(cat.colorHex)
                : AppColors.ts(context);

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
                              formatDate(tx.createdAt.toLocal()),
                              style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.th(context)),
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
                              style: TextStyle(
                                  fontSize: 9,
                                  color: AppColors.th(context)),
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
            color: AppColors.sf(ctx),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                S.of(ctx).acctAdjustBalance,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.tp(ctx),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                S.of(ctx).acctAdjustDesc,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.ts(ctx),
                ),
              ),
              if (_currentBalance != null) ...[
                const SizedBox(height: 12),
                Text(
                  S.of(ctx).acctCurrentBalanceLabel(formatAmount(_currentBalance!, currency: currency)),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              CalculatorAmountField(
                value: double.tryParse(adjustCtrl.text) ?? 0,
                hintText: S.of(ctx).acctEnterRealBalance,
                fontSize: 20,
                onChanged: (v) => adjustCtrl.text = v.toString(),
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
                      borderRadius: BorderRadius.circular(CardTokens.radius)),
                ),
                child: Text(S.of(ctx).acctApplyAdjustment,
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
            note: S.of(context).acctBalanceAdjustment,
          );
        } else {
          // Negative adjustment → record as expense via engine (preserves balance invariant).
          final baseCurrency = ref.read(householdProvider).value?.baseCurrency ?? currency;
          await engine.recordTransaction(
            householdId: householdId,
            accountId: widget.accountId,
            type: 'expense',
            baseCurrency: baseCurrency,
            lines: [
              TxLine(
                amount: diff.abs(),
                currency: currency,
              ),
            ],
            note: S.of(context).acctBalanceAdjustment,
          );
        }

        await _loadAccount(); // Refresh current balance.
        if (!mounted) return;
        ref.invalidate(accountsProvider);
        ref.invalidate(accountsWithBalanceProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  S.of(context).acctBalanceAdjustedBy(formatSignedAmount(diff, currency: currency, type: diff > 0 ? 'income' : 'expense'))),
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
  // Convert Back (travel wallets)
  // ---------------------------------------------------------------------------

  Future<void> _convertBack() async {
    final balance = _currentBalance ?? 0;
    if (balance <= 0) return;

    final accounts = ref.read(accountsProvider).value ?? [];
    final regularAccounts = accounts
        .where((a) => !a.archived && !a.isTravel && a.id != widget.accountId)
        .toList();

    if (regularAccounts.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).acctNoTransferTarget),
              behavior: SnackBarBehavior.floating),
        );
      }
      return;
    }

    String? destAccountId = regularAccounts.first.id;
    double receivedAmount = 0;

    final tr = S.of(context);
    final surfaceColor = AppColors.sf(context);
    final textPrimaryColor = AppColors.tp(context);
    final textSecondaryColor = AppColors.ts(context);
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(tr.acctConvertBack,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                    color: textPrimaryColor)),
            const SizedBox(height: 4),
            Text(
              tr.acctConvertBackMsg(formatAmount(balance, currency: _currencyController.text)),
              style: TextStyle(fontSize: 13, color: textSecondaryColor),
            ),
            const SizedBox(height: 20),
            // Destination account picker
            DropdownButtonFormField<String>(
              value: destAccountId,
              decoration: InputDecoration(
                labelText: tr.acctTransferTo,
              ),
              items: regularAccounts.map((a) => DropdownMenuItem(
                value: a.id,
                child: Text('${a.name} (${a.currency})'),
              )).toList(),
              onChanged: (v) => setModalState(() => destAccountId = v),
            ),
            const SizedBox(height: 16),
            // Amount received
            CalculatorAmountField(
              value: receivedAmount,
              label: tr.acctAmountReceived,
              currency: regularAccounts
                  .where((a) => a.id == destAccountId).firstOrNull?.currency,
              hintText: '0.00',
              fontSize: 22,
              onChanged: (v) => setModalState(() => receivedAmount = v),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: receivedAmount > 0
                    ? () => Navigator.pop(ctx, true)
                    : null,
                child: Text(tr.acctConvertArchive),
              ),
            ),
          ]),
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final engine = ref.read(allocationEngineProvider);
      final householdId = ref.read(currentHouseholdIdProvider);
      if (householdId == null) return;

      final destAcc = regularAccounts
          .where((a) => a.id == destAccountId).firstOrNull;
      if (destAcc == null) return;

      // Record the reverse transfer
      final rate = balance > 0 ? receivedAmount / balance : 1.0;
      await engine.recordTransfer(
        householdId: householdId,
        fromAccountId: widget.accountId,
        toAccountId: destAccountId!,
        amount: balance,
        currency: _currencyController.text,
        exchangeRateToBase: rate,
        createdBy: 'local',
        deviceId: 'local',
        note: 'Travel convert back → ${destAcc.currency}',
        date: DateTime.now(),
      );

      // Archive the travel account
      final db = ref.read(databaseProvider);
      await (db.update(db.accounts)
            ..where((a) => a.id.equals(widget.accountId)))
          .write(AccountsCompanion(
        archived: const Value(true),
        lastModified: Value(DateTime.now()),
      ));

      ref.invalidate(accountsProvider);
      ref.invalidate(accountsWithBalanceProvider);
      ref.invalidate(unallocatedProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                S.of(context).acctConvertedBack(formatAmount(receivedAmount, currency: destAcc.currency))),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).acctSomethingWrong),
              behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Archive
  // ---------------------------------------------------------------------------

  Future<void> _confirmArchive() async {
    final tr = S.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(tr.acctArchiveTitle),
        content: Text(
          tr.acctArchiveMsg,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style:
                TextButton.styleFrom(foregroundColor: AppColors.overspent),
            child: Text(tr.commonArchive),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final db = ref.read(databaseProvider);
      await (db.update(db.accounts)
            ..where((a) => a.id.equals(widget.accountId)))
          .write(const AccountsCompanion(archived: Value(true)));
      ref.invalidate(accountsWithBalanceProvider);
      if (mounted) context.pop();
    }
  }

  // ---------------------------------------------------------------------------
  // Delete with safeguards
  // ---------------------------------------------------------------------------

  Future<void> _confirmDelete() async {
    final db = ref.read(databaseProvider);

    // Count transactions referencing this account (parallel queries).
    final results = await Future.wait([
      (db.select(db.transactions)
            ..where((t) => t.accountId.equals(widget.accountId))
            ..where((t) => t.deleted.equals(false)))
          .get(),
      (db.select(db.transactions)
            ..where((t) => t.destinationAccountId.equals(widget.accountId))
            ..where((t) => t.deleted.equals(false)))
          .get(),
      (db.select(db.transactionLines)
            ..where((t) => t.accountId.equals(widget.accountId)))
          .get(),
    ]);

    final totalRefs =
        results[0].length + results[1].length + results[2].length;

    if (!mounted) return;

    if (totalRefs > 0) {
      // Has transactions -- cannot delete, offer archive instead.
      final tr = S.of(context);
      final action = await showDialog<String>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(tr.acctCannotDeleteTitle),
          content: Text(
            tr.acctCannotDeleteMsg(totalRefs),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'cancel'),
              child: Text(tr.commonCancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'archive'),
              style: TextButton.styleFrom(
                  foregroundColor: AppColors.accent),
              child: Text(tr.acctArchiveInstead),
            ),
          ],
        ),
      );

      if (action == 'archive' && mounted) {
        await (db.update(db.accounts)
              ..where((a) => a.id.equals(widget.accountId)))
            .write(const AccountsCompanion(archived: Value(true)));
        ref.invalidate(accountsProvider);
        ref.invalidate(accountsWithBalanceProvider);
        if (mounted) context.pop();
      }
    } else {
      // No transactions -- allow permanent deletion with confirmation.
      final tr = S.of(context);
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(tr.acctDeleteTitle),
          content: Text(
            tr.acctDeleteMsg,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(tr.commonCancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(
                  foregroundColor: AppColors.overspent),
              child: Text(tr.allocDeletePermanently),
            ),
          ],
        ),
      );

      if (confirmed == true && mounted) {
        await (db.delete(db.accounts)
              ..where((a) => a.id.equals(widget.accountId)))
            .go();
        ref.invalidate(accountsProvider);
        ref.invalidate(accountsWithBalanceProvider);
        if (mounted) context.pop();
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Save
  // ---------------------------------------------------------------------------

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).objNameRequired), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    final currency = _currencyController.text.trim().toUpperCase();
    if (currency.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).acctSelectCurrency), behavior: SnackBarBehavior.floating),
      );
      return;
    }
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
        decimalPlaces: Value(_decimalPlaces),
        deviceId: 'local',
      ));
      // Refresh account list and any balance-dependent screens
      ref.invalidate(accountsProvider);
      ref.invalidate(accountsWithBalanceProvider);
      ref.invalidate(unallocatedProvider);
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
