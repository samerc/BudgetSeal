import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/database/app_database.dart';
import '../../core/engine/balance_calculator.dart';
import '../../core/providers/accounts_provider.dart';
import '../../core/providers/allocations_provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../core/services/travel_account_service.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/design_tokens.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/utils/format_number.dart';
import '../../shared/widgets/calculator_amount_field.dart';
import '../../shared/widgets/currency_picker_field.dart';

class TravelExchangeScreen extends ConsumerStatefulWidget {
  const TravelExchangeScreen({super.key});

  @override
  ConsumerState<TravelExchangeScreen> createState() =>
      _TravelExchangeScreenState();
}

class _TravelExchangeScreenState
    extends ConsumerState<TravelExchangeScreen> {
  String? _fromAccountId;
  double _sourceAmount = 0;
  String _targetCurrency = 'EUR';
  double _receivedAmount = 0;
  bool _loading = false;

  String get _baseCurrency =>
      ref.read(householdProvider).value?.baseCurrency ?? 'USD';

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider).value ?? [];
    final activeAccounts =
        accounts.where((a) => !a.archived && !a.isTravel).toList();

    final fromAcc = _fromAccountId != null
        ? activeAccounts
            .where((a) => a.id == _fromAccountId)
            .firstOrNull
        : null;
    // Mid-trip: more cash goes into the wallet already open for it.
    final openWallet = (accounts
            .where((a) =>
                a.isTravel && !a.archived && a.currency == _targetCurrency)
            .toList()
          ..sort((a, b) => b.lastModified.compareTo(a.lastModified)))
        .firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).travelTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.pastel(context, AppColors.accent,
                    light: 0.88, dark: 0.8),
                borderRadius: BorderRadius.circular(CardTokens.radius),
                border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  Icon(Icons.flight_takeoff_rounded,
                      color: AppColors.accent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      S.of(context).travelInfo,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.ts(context),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── From Account ──
            _SectionLabel(label: S.of(context).travelFrom),
            const SizedBox(height: 6),
            _FormCard(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _fromAccountId,
                  isExpanded: true,
                  hint: Row(children: [
                    Icon(Icons.account_balance_rounded,
                        size: 16, color: AppColors.th(context)),
                    const SizedBox(width: 10),
                    Text(S.of(context).travelSelectAccount,
                        style: TextStyle(color: AppColors.th(context))),
                  ]),
                  icon: Icon(Icons.expand_more_rounded,
                      color: AppColors.th(context)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  items: activeAccounts.map((a) {
                    return DropdownMenuItem(
                      value: a.id,
                      child: Row(children: [
                        Icon(_accountIcon(a.type),
                            size: 16, color: AppColors.ts(context)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(a.name,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w500)),
                        ),
                        Text(a.currency,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.th(context))),
                      ]),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _fromAccountId = v),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Amount to exchange ──
            _SectionLabel(label: S.of(context).travelAmountToExchange),
            const SizedBox(height: 6),
            _FormCard(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: CalculatorAmountField(
                  value: _sourceAmount,
                  hintText: formatNumber(0,
                      decimals: currencyDecimals(fromAcc?.currency ?? _baseCurrency)),
                  currency: fromAcc?.currency ?? _baseCurrency,
                  fontSize: 24,
                  onChanged: (v) => setState(() => _sourceAmount = v),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Divider arrow
            Center(
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.pastel(context, AppColors.accent,
                      light: 0.85, dark: 0.78),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_downward_rounded,
                    color: AppColors.accent, size: 20),
              ),
            ),
            const SizedBox(height: 20),

            // ── Target Currency ──
            _SectionLabel(label: S.of(context).travelCurrencySection),
            const SizedBox(height: 6),
            _FormCard(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: CurrencyPickerField(
                  label: S.of(context).travelCurrencyReceive,
                  value: _targetCurrency,
                  onChanged: (v) => setState(() => _targetCurrency = v),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Amount received ──
            _SectionLabel(label: S.of(context).travelAmountReceived),
            const SizedBox(height: 6),
            _FormCard(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: CalculatorAmountField(
                  value: _receivedAmount,
                  hintText: formatNumber(0, decimals: currencyDecimals(_targetCurrency)),
                  currency: _targetCurrency,
                  fontSize: 24,
                  onChanged: (v) => setState(() => _receivedAmount = v),
                ),
              ),
            ),

            // Exchange rate display
            if (_sourceAmount > 0 && _receivedAmount > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.sfv(context),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.bd(context)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.currency_exchange_rounded,
                        size: 14, color: AppColors.ts(context)),
                    const SizedBox(width: 8),
                    Text(
                      '1 ${fromAcc?.currency ?? _baseCurrency} = ${formatNumber(_receivedAmount / _sourceAmount, decimals: 4)} $_targetCurrency',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ts(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (openWallet != null) ...[
              const SizedBox(height: 12),
              Row(children: [
                Icon(Icons.flight_rounded, size: 14, color: AppColors.accent),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    S.of(context).travelAddsToWallet(openWallet.name),
                    style: TextStyle(fontSize: 13, color: AppColors.ts(context)),
                  ),
                ),
              ]),
            ],

            const SizedBox(height: 28),

            // ── Exchange Button ──
            FilledButton.icon(
              onPressed: _canExchange ? (_loading ? null : _doExchange) : null,
              icon: _loading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: AppColors.onAccent, strokeWidth: 2))
                  : const Icon(Icons.flight_takeoff_rounded, size: 18),
              label: Text(
                  openWallet != null
                      ? S.of(context).travelExchangeTopUp
                      : S.of(context).travelExchangeButton,
                  style:
                      TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(CardTokens.radius)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _canExchange {
    if (_fromAccountId == null || _sourceAmount <= 0 ||
        _receivedAmount <= 0 || _targetCurrency.isEmpty) {
      return false;
    }
    // Prevent same-currency exchange
    final fromAcc = (ref.read(accountsProvider).value ?? [])
        .where((a) => a.id == _fromAccountId).firstOrNull;
    return fromAcc == null || fromAcc.currency != _targetCurrency;
  }

  Future<void> _doExchange() async {
    // Translated before any await (context may change meanwhile).
    final tr = S.of(context);
    final exchangeNote = tr.travelExchangeNote(_targetCurrency);
    setState(() => _loading = true);
    try {
      final db = ref.read(databaseProvider);
      final householdId = ref.read(currentHouseholdIdProvider);
      if (householdId == null) return;

      final fromAcc = (ref.read(accountsProvider).value ?? [])
          .where((a) => a.id == _fromAccountId)
          .firstOrNull;
      if (fromAcc == null) return;

      // More than the account holds: say so, but allow it (like funding an
      // envelope past Ready to assign).
      final available = await BalanceCalculator(db).accountBalance(fromAcc.id);
      if (_sourceAmount - available >=
          TravelAccountService.zeroThreshold(fromAcc.currency)) {
        if (!mounted) return;
        final go = await _confirmOverBalance(fromAcc, available);
        if (go != true) return;
      }

      // Into the wallet already open for this currency; else offer the last
      // archived one; else a new wallet.
      String? walletId =
          (await TravelAccountService.activeWallet(db, householdId, _targetCurrency))
              ?.id;
      if (walletId == null) {
        final archived = await TravelAccountService.archivedWallet(
            db, householdId, _targetCurrency);
        if (archived != null) {
          final reactivate = await _askReactivate(archived);
          if (!mounted || reactivate == null) return; // cancelled
          if (reactivate) walletId = archived.id;
        }
      }

      await TravelAccountService.exchange(
        db,
        householdId: householdId,
        fromAccountId: fromAcc.id,
        fromCurrency: fromAcc.currency,
        amount: _sourceAmount,
        toCurrency: _targetCurrency,
        received: _receivedAmount,
        walletId: walletId,
        newWalletName: tr.travelWalletName(_targetCurrency),
        note: exchangeNote,
      );

      // Refresh providers
      ref.invalidate(accountsProvider);
      ref.invalidate(accountsWithBalanceProvider);
      ref.invalidate(unallocatedProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                tr.travelExchangeSuccess(
                    formatAmount(_sourceAmount, currency: fromAcc.currency),
                    formatAmount(_receivedAmount, currency: _targetCurrency))),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 6),
          ),
        );
        context.pop();
      }
    } catch (e) {
      debugPrint('[Travel] Exchange failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(tr.travelExchangeFailed),
              behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<bool?> _confirmOverBalance(Account from, double available) {
    final tr = S.of(context);
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr.travelOverBalanceTitle),
        content: Text(tr.travelOverBalanceMsg(
          from.name,
          formatAmount(available, currency: from.currency),
          formatAmount(available - _sourceAmount, currency: from.currency),
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr.travelExchangeAnyway),
          ),
        ],
      ),
    );
  }

  Future<bool?> _askReactivate(Account existing) async {
    final calculator = BalanceCalculator(ref.read(databaseProvider));
    final balance = await calculator.accountBalance(existing.id);
    if (!mounted) return null;
    // Capture theme colors before dialog to avoid using outer context in builder
    final tsColor = AppColors.ts(context);
    final sfvColor = AppColors.sfv(context);
    final bdColor = AppColors.bd(context);

    final tr = S.of(context);
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr.travelExistingWallet),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr.travelPreviousWallet(existing.currency),
              style: TextStyle(color: tsColor),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: sfvColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: bdColor),
              ),
              child: Row(
                children: [
                  Icon(Icons.flight_rounded,
                      size: 20, color: AppColors.accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(existing.name,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(
                          S.of(context).travelBalanceLabel(formatAmount(balance, currency: existing.currency)),
                          style: TextStyle(
                              fontSize: 12, color: tsColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(S.of(context).commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(S.of(context).travelCreateNew),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(S.of(context).travelReactivate),
          ),
        ],
      ),
    );
  }

  IconData _accountIcon(String type) => switch (type) {
        'bank' => Icons.account_balance_rounded,
        'credit' => Icons.credit_card_rounded,
        'wallet' => Icons.account_balance_wallet_rounded,
        _ => Icons.money_rounded,
      };
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return SectionHeader(label);
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
        boxShadow: AppColors.cardShadow(context),
      ),
      child: child,
    );
  }
}
