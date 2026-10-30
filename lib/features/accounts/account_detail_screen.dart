import 'dart:math' as math;

import 'package:image_picker/image_picker.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

import 'package:uuid/uuid.dart';

import '../../core/database/app_database.dart';
import '../../core/database/daos/accounts_dao.dart';
import '../../core/database/daos/transactions_dao.dart' show chunked;
import '../../core/engine/allocation_engine.dart';
import '../../core/engine/balance_calculator.dart';
import '../../core/providers/date_format_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../core/providers/accounts_provider.dart';
import '../../core/providers/allocations_provider.dart';
import '../../core/fx/fx_service.dart';
import '../../core/services/travel_account_service.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/activity_filter_provider.dart';
import '../../core/providers/engine_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/design_tokens.dart';
import '../../shared/utils/format_number.dart';
import '../../shared/widgets/calculator_amount_field.dart';
import '../../shared/widgets/currency_picker_field.dart';
import '../../core/providers/transactions_provider.dart';
import '../../core/providers/categories_provider.dart';
import '../../shared/utils/dispose_later.dart';
import '../../shared/theme/app_icons.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_chip.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_retry.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/sheet_title.dart';
import '../transactions/widgets/tx_tile.dart';
import 'account_type.dart';
import 'widgets/balance_hero.dart';

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
  bool _loadFailed = false;
  double? _currentBalance;
  DateTime? _lastReconciled;

  /// The currency can't change once the account has money or transactions:
  /// every amount in it is in this currency, so a new code would turn $70
  /// into 70 euros.
  bool _currencyLocked = false;

  String get _reconciledKey => 'reconciled_${widget.accountId}';

  Future<void> _markReconciled() async {
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_reconciledKey, now.toIso8601String());
    if (mounted) setState(() => _lastReconciled = now);
  }

  bool get _isNew => widget.accountId == 'new';

  List<(String, String, IconData)> _accountTypes(BuildContext context) {
    final l = S.of(context);
    return [
      for (final t in const ['cash', 'bank', 'credit', 'wallet'])
        (t, accountTypeLabel(l, t), accountTypeIcon(t)),
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
    if (_loadFailed) setState(() => _loadFailed = false);
    try {
      final db = ref.read(databaseProvider);
      final acc = await AccountsDao(db).getById(widget.accountId);
      if (acc != null && mounted) {
        final calculator = BalanceCalculator(db);
        final balance = await calculator.accountBalance(acc.id);
        final locked = acc.initialBalance != 0 ||
            balance != 0 ||
            await _hasTransactions(db, acc.id);
        if (!mounted) return;
        setState(() {
          _currencyLocked = locked;
          _nameController.text = acc.name;
          _currencyController.text = acc.currency;
          _initialBalance = acc.initialBalance;
          _type = acc.type;
          _decimalPlaces = acc.decimalPlaces;
          _isTravel = acc.isTravel;
          _currentBalance = balance;
        });
        final prefs = await SharedPreferences.getInstance();
        final rec = DateTime.tryParse(prefs.getString(_reconciledKey) ?? '');
        if (mounted && rec != null) setState(() => _lastReconciled = rec);
      }
    } catch (e) {
      debugPrint('[AccountDetail] Error loading: $e');
      if (mounted) setState(() => _loadFailed = true);
    }
  }

  /// Whether any transaction (posted or planned, as header, transfer
  /// destination or split line) uses [accountId].
  static Future<bool> _hasTransactions(AppDatabase db, String accountId) async {
    final row = await db.customSelect(
      'SELECT EXISTS(SELECT 1 FROM transactions WHERE deleted = 0 AND '
      '(account_id = ?1 OR destination_account_id = ?1)) OR '
      'EXISTS(SELECT 1 FROM transaction_lines l JOIN transactions t '
      'ON t.id = l.transaction_id WHERE t.deleted = 0 AND l.account_id = ?1) '
      'AS used',
      variables: [Variable.withString(accountId)],
    ).getSingle();
    return row.read<bool>('used');
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
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title, padding: EdgeInsets.zero),
          const SizedBox(height: Spacing.md),
          child,
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(color: AppColors.ts(context)),
      hintStyle: TextStyle(color: AppColors.th(context)),
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
              icon: const Icon(AppIcons.dotsThreeVertical),
              onSelected: (v) {
                if (v == 'adjust') {
                  _showAdjustBalanceSheet();
                } else if (v == 'count') {
                  _countCash();
                } else if (v == 'shot') {
                  _checkScreenshot();
                } else if (v == 'convert_back') {
                  _convertBack();
                } else if (v == 'archive') {
                  _confirmArchive();
                } else if (v == 'delete') {
                  _confirmDelete();
                }
              },
              itemBuilder: (_) => [
                if (_type == 'cash')
                  PopupMenuItem(
                    value: 'count',
                    child: Row(
                      children: [
                        const Icon(AppIcons.coins, size: 18),
                        const SizedBox(width: 10),
                        Text(l.cashCountTitle),
                      ],
                    ),
                  ),
                PopupMenuItem(
                  value: 'shot',
                  child: Row(
                    children: [
                      const Icon(AppIcons.image, size: 18),
                      const SizedBox(width: 10),
                      Text(l.shotCheck),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'adjust',
                  child: Row(
                    children: [
                      const Icon(AppIcons.slidersHorizontal, size: 18),
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
                        const Icon(AppIcons.currencyCircleDollar, size: 18),
                        const SizedBox(width: 10),
                        Text(l.acctConvertBackClose),
                      ],
                    ),
                  ),
                PopupMenuItem(
                  value: 'archive',
                  child: Row(
                    children: [
                      Icon(AppIcons.archive,
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
                      Icon(AppIcons.trash,
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
      body: _loadFailed
          ? ErrorRetry(
              message: S.of(context).commonCouldntLoadAccounts,
              onRetry: _loadAccount,
            )
          : GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Current balance display card (existing accounts only)
            if (!_isNew && _currentBalance != null) ...[
              BalanceHero(
                padding: const EdgeInsets.all(Spacing.xl),
                child: Column(
                  children: [
                    Text(
                      l.acctCurrentBalance,
                      style: balanceHeroLabelStyle(context),
                    ),
                    const SizedBox(height: 6),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        formatAmount(_currentBalance!,
                            currency: _currencyController.text),
                        style: balanceHeroAmountStyle(context,
                            value: _currentBalance, size: 36),
                      ),
                    ),
                    if (_lastReconciled != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          l.acctLastReconciled(formatDate(_lastReconciled!)),
                          style: TextStyle(
                              fontSize: TypographyTokens.captionSize,
                              color: AppColors.ts(context)),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.pastel(context, AppColors.accent,
                            light: 0.6, dark: 0.55),
                        borderRadius: BorderRadius.circular(RadiusTokens.pill),
                      ),
                      child: Text(
                        _currencyController.text,
                        style: TextStyle(
                          color: AppColors.tp(context),
                          fontSize: TypographyTokens.captionSize,
                          fontWeight: FontWeight.w700,
                        ),
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
                padding: CardTokens.padding,
                decoration: BoxDecoration(
                  color: AppColors.pastel(context, AppColors.accent,
                      light: 0.88, dark: 0.8),
                  borderRadius: BorderRadius.circular(CardTokens.radius),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(AppIcons.airplaneLanding,
                            size: 18, color: AppColors.accent),
                        const SizedBox(width: 8),
                        Text(l.acctBackFromTrip,
                            style: TextStyle(
                                fontSize: TypographyTokens.cardTitleSize,
                                fontWeight: TypographyTokens.cardTitleWeight,
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
                        icon: const Icon(AppIcons.currencyCircleDollar, size: 16),
                        label: Text(l.acctConvertBackClose),
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
              AppCard(
                onTap: () => setState(() => _showSettings = !_showSettings),
                child: Row(
                    children: [
                      Icon(AppIcons.gear,
                          size: 18, color: AppColors.ts(context)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(l.acctSettings,
                            style: TextStyle(
                                fontSize: TypographyTokens.cardTitleSize,
                                fontWeight: TypographyTokens.cardTitleWeight,
                                color: AppColors.tp(context))),
                      ),
                      Icon(
                        _showSettings
                            ? AppIcons.caretUp
                            : AppIcons.caretDown,
                        color: AppColors.th(context),
                      ),
                    ],
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
                icon: AppIcons.tag,
                title: l.acctNameSection,
                child: TextField(
                  controller: _nameController,
                  decoration: _inputDecoration(l.acctAccountName),
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  autofocus: _isNew,
                  // Tapping an option below drops focus, so a rebuild
                  // doesn't bring the keyboard back.
                  onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
                  maxLength: InputLimits.nameMaxLength,
                  style: TextStyle(color: AppColors.tp(context)),
                ),
              ),
              const SizedBox(height: 12),

              // ── Type ──
              _formSection(
                context,
                icon: AppIcons.squaresFour,
                title: l.acctTypeSection,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _accountTypes(context).map((entry) {
                    final (value, label, icon) = entry;
                    return AppChip(
                      label: label,
                      icon: icon,
                      selected: _type == value,
                      onTap: () => setState(() => _type = value),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),

              // ── Currency ──
              _formSection(
                context,
                icon: AppIcons.currencyDollar,
                title: l.acctCurrencySection,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    IgnorePointer(
                      ignoring: _currencyLocked,
                      child: Opacity(
                        opacity: _currencyLocked ? 0.6 : 1,
                        child: CurrencyPickerField(
                          label: l.acctSelectCurrency,
                          value: _currencyController.text.isEmpty
                              ? 'USD'
                              : _currencyController.text,
                          onChanged: (v) {
                            if (_currencyLocked) return;
                            setState(() => _currencyController.text = v);
                          },
                        ),
                      ),
                    ),
                    if (_currencyLocked) ...[
                      const SizedBox(height: 6),
                      Text(
                        l.acctCurrencyLocked,
                        style: TextStyle(
                            fontSize: 12, color: AppColors.ts(context)),
                      ),
                    ],
                  ],
                ),
              ),

              // ── Decimal places ──
              const SizedBox(height: 12),
              _formSection(
                context,
                icon: AppIcons.password,
                title: l.acctDecimalSection,
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int?>(
                    icon: AppIcons.dropdown,
                    value: _decimalPlaces,
                    isExpanded: true,
                    isDense: true,
                    items: [
                      DropdownMenuItem<int?>(
                        value: null,
                        child: Text(l.acctDecimalAuto(currencyDecimals(_currencyController.text)),
                            style: TextStyle(fontSize: TypographyTokens.bodySize, color: AppColors.tp(context))),
                      ),
                      for (final d in [0, 1, 2, 3])
                        DropdownMenuItem<int?>(
                          value: d,
                          child: Text('$d', style: TextStyle(fontSize: TypographyTokens.bodySize, color: AppColors.tp(context))),
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
                  icon: AppIcons.bank,
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
              child: FilledButton(
                onPressed: _loading ? null : _save,
                child: _loading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: AppColors.onAccent, strokeWidth: 2),
                      )
                    : Text(_isNew ? l.acctCreateAccount : l.commonSave),
              ),
            ),
            ],
            // Account transactions (existing accounts only)
            if (!_isNew) ...[
              const SizedBox(height: 24),
              SectionHeader(
                l.acctRecentTransactions,
                trailing: TextButton(
                  onPressed: () {
                    ref.read(activityFilterRequestProvider.notifier).request(
                        (accountId: widget.accountId,
                         categoryId: null,
                         categoryName: null));
                    context.go('/');
                  },
                  child: Text(l.commonSeeAll),
                ),
              ),
              const SizedBox(height: Spacing.headerToCard),
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
          return EmptyState(
            icon: AppIcons.receipt,
            title: S.of(context).acctNoTransactions,
          );
        }

        // The same rows as Activity and Home (category emoji, the user's
        // income/expense colors, the date under the amount).
        return Column(
          children: [
            for (final e in filtered)
              TxTile(
                entry: e,
                categoryMap: catMap,
                showBalance: false,
                showDate: true,
                balanceAccountId: widget.accountId,
              ),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(Spacing.xl),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => ErrorRetry(
        message: S.of(context).commonCouldntLoadData,
        details: '$e',
        onRetry: () => ref.invalidate(transactionEntriesProvider),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Adjust balance
  // ---------------------------------------------------------------------------

  /// Check the account against a screenshot of the bank's list (roadmap
  /// #2): pick it from the gallery; read and matched on the phone.
  Future<void> _checkScreenshot() async {
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked == null || !mounted) return;
      await context.push('/check-screenshot',
          extra: {'accountId': widget.accountId, 'path': picked.path});
      await _loadAccount();
    } catch (e) {
      debugPrint('[AccountDetail] Screenshot check failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(S.of(context).receiptPickFailed),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  /// Count cash by notes (roadmap #3): the count comes back as the real
  /// balance.
  Future<void> _countCash() async {
    final total = await context.push<double>('/count-cash', extra: {
      'currency': _currencyController.text.trim().toUpperCase(),
      'balance': _currentBalance,
    });
    if (total != null && mounted) await _applyRealBalance(total);
  }

  Future<void> _showAdjustBalanceSheet() async {
    final adjustCtrl = TextEditingController();
    final currency = _currencyController.text.trim().toUpperCase();

    double? entered;
    // Captured before the sheet: S.of inside a StatefulBuilder in a modal
    // sheet crashes (_dependents.isEmpty).
    final tr = S.of(context);
    final result = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheet) {
        final diff = entered != null && _currentBalance != null
            ? entered! - _currentBalance!
            : null;
        return Padding(
          padding: EdgeInsets.fromLTRB(
              20, 0, 20, MediaQuery.of(ctx).viewInsets.bottom + MediaQuery.of(ctx).viewPadding.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SheetTitle(
                tr.acctAdjustBalance,
                subtitle: tr.acctAdjustDesc,
                padding: const EdgeInsetsDirectional.only(top: 20),
              ),
              if (_currentBalance != null) ...[
                const SizedBox(height: 12),
                Text(
                  tr.acctCurrentBalanceLabel(formatAmount(_currentBalance!, currency: currency)),
                  style: TextStyle(
                    fontSize: TypographyTokens.bodySize,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accentText(ctx),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              CalculatorAmountField(
                value: double.tryParse(adjustCtrl.text) ?? 0,
                hintText: tr.acctEnterRealBalance,
                fontSize: 20,
                onChanged: (v) => setSheet(() {
                  adjustCtrl.text = v.toString();
                  entered = v;
                }),
              ),
              // Preview: what reconciling will do.
              if (diff != null) ...[
                const SizedBox(height: 10),
                Text(
                  diff.abs() < 0.005
                      ? tr.acctReconcileMatches
                      : tr.acctReconcileDiff(formatSignedAmount(diff,
                          currency: currency,
                          type: diff > 0 ? 'income' : 'expense')),
                  style: TextStyle(
                    fontSize: TypographyTokens.amountSmallSize,
                    fontWeight: FontWeight.w600,
                    color: diff.abs() < 0.005
                        ? AppColors.healthy
                        : AppColors.caution,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  final val = double.tryParse(adjustCtrl.text);
                  if (val != null) {
                    Navigator.pop(ctx, val);
                  }
                },
                child: Text(diff != null && diff.abs() < 0.005
                    ? tr.acctReconcileConfirm
                    : tr.acctApplyAdjustment),
              ),
            ],
          ),
        );
      }),
    );
    disposeAfterRouteAnimation(adjustCtrl);
    if (result != null) await _applyRealBalance(result);
  }

  /// Brings the balance to [result], what's really in the account: an
  /// adjustment for the difference (none when it matches), and the
  /// account is marked reconciled. Shared by Adjust balance and Count cash.
  Future<void> _applyRealBalance(double result) async {
    final tr = S.of(context);
    if (_currentBalance != null && mounted) {
      final diff = result - _currentBalance!;
      if (diff.abs() < 0.005) {
        // Already matches the bank: just record the reconciliation.
        await _markReconciled();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(S.of(context).acctReconciledMatch),
            behavior: SnackBarBehavior.floating,
          ));
        }
        return;
      }

      setState(() => _loading = true);
      try {
        final householdId = ref.read(currentHouseholdIdProvider);
        if (householdId == null) return;
        final engine = ref.read(allocationEngineProvider);
        final currency = _currencyController.text.trim().toUpperCase();
        final baseCurrency =
            ref.read(householdProvider).value?.baseCurrency ?? currency;
        final rate = await rateToBaseOrOne(ref.read(fxServiceProvider),
            ref.read(databaseProvider), currency, baseCurrency);
        if (!mounted) return;

        if (diff > 0) {
          // Positive adjustment → record as income.
          await engine.recordIncome(
            householdId: householdId,
            accountId: widget.accountId,
            amount: diff,
            currency: currency,
            exchangeRateToBase: rate,
            createdBy: 'user',
            deviceId: 'local',
            note: S.of(context).acctBalanceAdjustment,
          );
        } else {
          // Negative adjustment → record as expense via engine (preserves balance invariant).
          await engine.recordTransaction(
            householdId: householdId,
            accountId: widget.accountId,
            type: 'expense',
            baseCurrency: baseCurrency,
            lines: [
              TxLine(
                amount: diff.abs(),
                currency: currency,
                exchangeRateToBase: rate,
              ),
            ],
            note: S.of(context).acctBalanceAdjustment,
          );
        }

        await _markReconciled();
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
      } catch (e) {
        debugPrint('[AccountDetail] Adjust failed: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(tr.acctAdjustFailed),
            behavior: SnackBarBehavior.floating,
          ));
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

    final walletCurrency = _currencyController.text;
    String? destAccountId = regularAccounts.first.id;
    double sameCurrencyAmount(String? id) =>
        regularAccounts.where((a) => a.id == id).firstOrNull?.currency ==
                walletCurrency
            ? balance
            : 0;
    double receivedAmount = sameCurrencyAmount(destAccountId);

    // Envelopes holding the wallet's currency are emptied back to Ready to
    // assign when this is the last account in it (convertBack) — say so.
    var envelopeMoney = 0.0;
    final lastInCurrency = !accounts.any((a) =>
        !a.archived && a.id != widget.accountId && a.currency == walletCurrency);
    final hhId = ref.read(currentHouseholdIdProvider);
    if (lastInCurrency && hhId != null) {
      try {
        envelopeMoney = await TravelAccountService.envelopeMoneyIn(
            ref.read(databaseProvider), hhId, walletCurrency);
      } catch (e) {
        debugPrint('[AccountDetail] Envelope money check failed: $e');
      }
      if (!mounted) return;
    }

    final tr = S.of(context);
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 0, 20, MediaQuery.of(ctx).viewInsets.bottom + MediaQuery.of(ctx).viewPadding.bottom + 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            SheetTitle(
              tr.acctConvertBack,
              subtitle: [
                tr.acctConvertBackMsg(
                    formatAmount(balance, currency: _currencyController.text)),
                if (envelopeMoney.abs() >= TravelAccountService.zeroThreshold(walletCurrency))
                  tr.acctConvertBackEnvelopes(
                      formatAmount(envelopeMoney, currency: walletCurrency)),
              ].join('\n\n'),
              padding: const EdgeInsetsDirectional.only(top: 20),
            ),
            const SizedBox(height: 20),
            // Destination account picker
            DropdownButtonFormField<String>(
              icon: AppIcons.dropdown,
              initialValue: destAccountId,
              decoration: InputDecoration(
                labelText: tr.acctTransferTo,
              ),
              items: regularAccounts.map((a) => DropdownMenuItem(
                value: a.id,
                child: Text('${a.name} (${a.currency})'),
              )).toList(),
              onChanged: (v) => setModalState(() {
                destAccountId = v;
                receivedAmount = sameCurrencyAmount(v);
              }),
            ),
            const SizedBox(height: 16),
            // Amount received
            CalculatorAmountField(
              // A new key per destination so the prefilled amount shows.
              key: ValueKey(destAccountId),
              value: receivedAmount,
              label: tr.acctAmountReceived,
              currency: regularAccounts
                  .where((a) => a.id == destAccountId).firstOrNull?.currency,
              hintText: formatNumber(0,
                  decimals: currencyDecimals(regularAccounts
                          .where((a) => a.id == destAccountId)
                          .firstOrNull
                          ?.currency ??
                      walletCurrency)),
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
      final householdId = ref.read(currentHouseholdIdProvider);
      if (householdId == null) return;

      final destAcc = regularAccounts
          .where((a) => a.id == destAccountId).firstOrNull;
      if (destAcc == null) return;

      // Transfer the balance and archive, in one db transaction; refused if
      // the balance changed since the sheet opened.
      await TravelAccountService.convertBack(
        ref.read(databaseProvider),
        householdId: householdId,
        walletId: widget.accountId,
        expectedBalance: balance,
        toAccountId: destAccountId!,
        received: receivedAmount,
        note: tr.travelConvertBackNote(destAcc.currency),
        envelopeNote: tr.travelEnvelopeReturnedNote,
      );

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
    } on TravelBalanceChangedException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr.acctBalanceChanged),
              behavior: SnackBarBehavior.floating),
        );
        _loadAccount(); // show the new balance
      }
    } catch (e) {
      debugPrint('[AccountDetail] Convert back failed: $e');
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

  /// Archived accounts drop out of every balance, so archiving one that still
  /// holds money would silently pull that money out of Unallocated. Only
  /// allow it at zero; otherwise explain how to empty it first.
  Future<bool> _canArchive() {
    final tr = S.of(context);
    return _isAtZero(tr.acctArchiveTitle, tr.acctArchiveNonZero);
  }

  /// True when the account's balance is zero; otherwise explains (with
  /// [message] given the balance) and returns false.
  Future<bool> _isAtZero(
      String title, String Function(String amount) message) async {
    final db = ref.read(databaseProvider);
    final acc = await AccountsDao(db).getById(widget.accountId);
    final balance =
        await BalanceCalculator(db).accountBalance(widget.accountId);
    final currency = acc?.currency ?? _currencyController.text;
    final threshold = 0.5 / math.pow(10, currencyDecimals(currency));
    if (balance.abs() < threshold) return true;
    if (!mounted) return false;
    final tr = S.of(context);
    await showDialog<void>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: Text(title),
        content: Text(message(formatAmount(balance, currency: currency))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dctx),
            child: Text(tr.commonOk),
          ),
        ],
      ),
    );
    return false;
  }

  Future<void> _confirmArchive() async {
    if (!await _canArchive() || !mounted) return;
    final schedules = await _schedules();
    if (!mounted) return;
    final tr = S.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: tr.acctArchiveConfirmTitle,
      message: tr.acctArchiveMsg + _schedulesNote(tr, schedules),
      confirmLabel: tr.commonArchive,
      destructive: false,
    );
    if (confirmed && mounted) await _archive(schedules);
  }

  /// Switched-on bills and planned payments that use this account: an
  /// archived or deleted account can't pay them.
  Future<({List<String> bills, List<String> plans})> _schedules() async {
    final db = ref.read(databaseProvider);
    final id = widget.accountId;
    final bills = await (db.select(db.recurringTransactions)
          ..where((r) =>
              (r.accountId.equals(id) | r.destinationAccountId.equals(id)) &
              r.deleted.equals(false) &
              r.enabled.equals(true)))
        .get();
    final plans = await (db.select(db.transactions)
          ..where((t) => t.status.equals('planned') & t.deleted.equals(false)))
        .get();
    final lines =
        await db.transactionsDao.linesByTransaction(plans.map((t) => t.id));
    return (
      bills: [for (final b in bills) b.id],
      plans: [
        for (final t in plans)
          if (t.accountId == id ||
              t.destinationAccountId == id ||
              (lines[t.id] ?? const <TransactionLine>[])
                  .any((l) => l.accountId == id))
            t.id
      ],
    );
  }

  /// "Its 2 bills will be switched off." for a confirm dialog (empty when
  /// there are none). [plans] is false when the plans are already counted as
  /// transactions being deleted.
  String _schedulesNote(S tr, ({List<String> bills, List<String> plans}) s,
      {bool plans = true}) {
    final notes = [
      if (s.bills.isNotEmpty) tr.acctBillsOffNote(s.bills.length),
      if (plans && s.plans.isNotEmpty) tr.acctPlansDeletedNote(s.plans.length),
    ];
    return notes.isEmpty ? '' : '\n\n${notes.join(' ')}';
  }

  /// Switches off [billIds] (they stay in the Bills list, paused).
  Future<void> _switchOffBills(AppDatabase db, List<String> billIds) async {
    if (billIds.isEmpty) return;
    await (db.update(db.recurringTransactions)
          ..where((r) => r.id.isIn(billIds)))
        .write(RecurringTransactionsCompanion(
            enabled: const Value(false), lastModified: Value(DateTime.now())));
  }

  /// Archives the account (switching off its bills and deleting its planned
  /// payments first), says so, and leaves the screen.
  Future<void> _archive(
      ({List<String> bills, List<String> plans}) schedules) async {
    final tr = S.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final name = _nameController.text;
    try {
      final db = ref.read(databaseProvider);
      final engine = ref.read(allocationEngineProvider);
      await db.transaction(() async {
        for (final id in schedules.plans) {
          await engine.deleteTransaction(id);
        }
        await _switchOffBills(db, schedules.bills);
        await (db.update(db.accounts)
              ..where((a) => a.id.equals(widget.accountId)))
            .write(AccountsCompanion(
                archived: const Value(true),
                lastModified: Value(DateTime.now())));
      });
      ref.invalidate(accountsProvider);
      ref.invalidate(accountsWithBalanceProvider);
      messenger.showSnackBar(SnackBar(
        content: Text(tr.acctArchivedSnack(name)),
        behavior: SnackBarBehavior.floating,
      ));
      if (mounted) context.pop();
    } catch (e) {
      debugPrint('[AccountDetail] Archive failed: $e');
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
    final accId = widget.accountId;

    // Gather every non-deleted transaction that references this account:
    // as the header account, a transfer destination, or a split line.
    final headerTxs = await (db.select(db.transactions)
          ..where((t) => t.accountId.equals(accId))
          ..where((t) => t.deleted.equals(false)))
        .get();
    final destTxs = await (db.select(db.transactions)
          ..where((t) => t.destinationAccountId.equals(accId))
          ..where((t) => t.deleted.equals(false)))
        .get();
    final accLines = await (db.select(db.transactionLines)
          ..where((l) => l.accountId.equals(accId)))
        .get();

    final refTxIds = <String>{
      ...headerTxs.map((t) => t.id),
      ...destTxs.map((t) => t.id),
      ...accLines.map((l) => l.transactionId),
    };

    final schedules = await _schedules();
    if (!mounted) return;
    final tr = S.of(context);
    // Planned payments on this account are among refTxIds (deleted with it).
    final billsNote = _schedulesNote(tr, schedules, plans: false);

    // ── No transactions: simple permanent delete ──
    if (refTxIds.isEmpty) {
      // Like archive: an account that still holds money (an opening
      // balance) can't just vanish — that money would leave Ready to
      // assign, which may already be in envelopes.
      if (!await _isAtZero(tr.acctDeleteConfirmTitle, tr.acctDeleteNonZero) ||
          !mounted) {
        return;
      }
      final confirmed = await showConfirmDialog(
        context,
        title: tr.acctDeleteConfirmTitle,
        message: tr.acctDeleteMsg + billsNote,
        confirmLabel: tr.allocDeletePermanently,
      );
      if (confirmed && mounted) {
        await _deleteAccount(const {}, schedules.bills);
      }
      return;
    }

    // ── Has transactions: archive, or delete with transactions ──
    final action = await showDialog<String>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: Text(tr.acctDeleteConfirmTitle),
        content: Text(tr.acctHasTxnsMsg(refTxIds.length)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dctx, 'cancel'),
              child: Text(tr.commonCancel)),
          OutlinedButton(
            style: DialogButtons.outlined,
            onPressed: () => Navigator.pop(dctx, 'archive'),
            child: Text(tr.acctArchiveInstead),
          ),
          FilledButton(
            style: DialogButtons.destructive,
            onPressed: () => Navigator.pop(dctx, 'delete'),
            child: Text(tr.acctDeleteWithTxns),
          ),
        ],
      ),
    );

    if (!mounted || action == null || action == 'cancel') return;

    if (action == 'archive') {
      await _confirmArchive();
      return;
    }

    // action == 'delete' → detect transactions shared with OTHER accounts
    // (transfers or cross-account splits), since deleting those also changes
    // the other accounts' balances.
    final linesByTx = await db.transactionsDao.linesByTransaction(refTxIds);
    final txById = <String, Transaction>{
      for (final t in [...headerTxs, ...destTxs]) t.id: t,
    };
    final missingIds =
        refTxIds.where((id) => !txById.containsKey(id)).toList();
    if (missingIds.isNotEmpty) {
      for (final chunk in chunked(missingIds)) {
        for (final t in await (db.select(db.transactions)
              ..where((t) => t.id.isIn(chunk)))
            .get()) {
          txById[t.id] = t;
        }
      }
    }

    var sharedCount = 0;
    for (final t in txById.values) {
      final accts = <String>{};
      if (t.accountId.isNotEmpty) accts.add(t.accountId);
      if (t.destinationAccountId != null) accts.add(t.destinationAccountId!);
      for (final l in (linesByTx[t.id] ?? const <TransactionLine>[])) {
        if (l.accountId != null) accts.add(l.accountId!);
      }
      accts.remove(accId);
      if (accts.isNotEmpty) sharedCount++;
    }

    if (!mounted) return;
    final confirmed = await showConfirmDialog(
      context,
      title: tr.acctDeleteConfirmTitle,
      message: (sharedCount > 0
              ? tr.acctDeleteSharedMsg(sharedCount)
              : tr.acctDeleteCountConfirm(refTxIds.length)) +
          billsNote,
      confirmLabel: tr.allocDeletePermanently,
    );
    if (!confirmed || !mounted) return;
    await _deleteAccount(refTxIds, schedules.bills);
  }

  /// Soft-deletes [txIds] through the engine (ledger rows go too, so balances
  /// and sync stay correct), then the account; says so and leaves the screen.
  /// No Undo here: the account itself is gone, so `deleteTransactionsWithUndo`
  /// (which restores transactions into their account) doesn't fit.
  Future<void> _deleteAccount(Set<String> txIds, List<String> billIds) async {
    final tr = S.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final name = _nameController.text;
    try {
      final db = ref.read(databaseProvider);
      final engine = ref.read(allocationEngineProvider);
      await db.transaction(() async {
        for (final id in txIds) {
          await engine.deleteTransaction(id);
        }
        await _switchOffBills(db, billIds);
        await (db.update(db.accounts)
              ..where((a) => a.id.equals(widget.accountId)))
            .write(AccountsCompanion(
                deleted: const Value(true),
                lastModified: Value(DateTime.now())));
      });
      ref.invalidate(accountsProvider);
      ref.invalidate(accountsWithBalanceProvider);
      if (txIds.isNotEmpty) {
        ref.invalidate(allocationsProvider);
        ref.invalidate(unallocatedProvider);
        ref.invalidate(transactionEntriesProvider);
      }
      messenger.showSnackBar(SnackBar(
        content: Text(tr.acctDeletedSnack(name)),
        behavior: SnackBarBehavior.floating,
      ));
      if (mounted) context.pop();
    } catch (e) {
      debugPrint('[AccountDetail] Delete failed: $e');
      messenger.showSnackBar(SnackBar(
        content: Text(tr.commonSomethingWentWrong),
        behavior: SnackBarBehavior.floating,
      ));
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
    var currency = _currencyController.text.trim().toUpperCase();
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
      if (!_isNew) {
        // Never reinterpret existing amounts in another currency: once the
        // account has money or transactions, the stored currency stays.
        final stored = await AccountsDao(db).getById(id);
        if (stored != null &&
            stored.currency != currency &&
            (stored.initialBalance != 0 ||
                await BalanceCalculator(db).accountBalance(id) != 0 ||
                await _hasTransactions(db, id))) {
          currency = stored.currency;
        }
      }
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                _isNew ? S.of(context).acctCreated : S.of(context).acctUpdated),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } catch (e) {
      debugPrint('[AccountDetail] Save failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(S.of(context).acctSaveFailed),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
