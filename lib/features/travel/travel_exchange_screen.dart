import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/database/app_database.dart';
import '../../core/database/daos/accounts_dao.dart';
import '../../core/engine/balance_calculator.dart';
import '../../core/providers/accounts_provider.dart';
import '../../core/providers/allocations_provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/engine_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/design_tokens.dart';
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

  /// Exchange rate: how many destination units per 1 source unit.
  /// e.g. $100 → €90 means rate = 0.9 (destination gets source * 0.9)
  double get _effectiveRate =>
      _sourceAmount > 0 && _receivedAmount > 0
          ? _receivedAmount / _sourceAmount
          : 1.0;

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Travel Exchange'),
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
                color: AppColors.accent.withValues(alpha: 0.08),
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
                      'Exchange money for your trip. A temporary travel wallet will be created automatically.',
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
            _SectionLabel(label: 'FROM'),
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
                    Text('Select account',
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
            _SectionLabel(label: 'AMOUNT TO EXCHANGE'),
            const SizedBox(height: 6),
            _FormCard(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: CalculatorAmountField(
                  value: _sourceAmount,
                  hintText: '0.00',
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
                  color: AppColors.accent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_downward_rounded,
                    color: AppColors.accent, size: 20),
              ),
            ),
            const SizedBox(height: 20),

            // ── Target Currency ──
            _SectionLabel(label: 'TRAVEL CURRENCY'),
            const SizedBox(height: 6),
            _FormCard(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: CurrencyPickerField(
                  label: 'Currency you receive',
                  value: _targetCurrency,
                  onChanged: (v) => setState(() => _targetCurrency = v),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Amount received ──
            _SectionLabel(label: 'AMOUNT RECEIVED'),
            const SizedBox(height: 6),
            _FormCard(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: CalculatorAmountField(
                  value: _receivedAmount,
                  hintText: '0.00',
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

            const SizedBox(height: 28),

            // ── Exchange Button ──
            FilledButton.icon(
              onPressed: _canExchange ? (_loading ? null : _doExchange) : null,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.flight_takeoff_rounded, size: 18),
              label: const Text('Exchange & Create Travel Wallet',
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
    setState(() => _loading = true);
    try {
      final db = ref.read(databaseProvider);
      final engine = ref.read(allocationEngineProvider);
      final householdId = ref.read(currentHouseholdIdProvider);
      if (householdId == null) return;

      final fromAcc = (ref.read(accountsProvider).value ?? [])
          .where((a) => a.id == _fromAccountId)
          .firstOrNull;
      if (fromAcc == null) return;

      // Check for existing archived travel account in this currency
      final existingTravel = await (db.select(db.accounts)
            ..where((a) =>
                a.householdId.equals(householdId))
            ..where((a) => a.isTravel.equals(true))
            ..where((a) => a.currency.equals(_targetCurrency))
            ..where((a) => a.archived.equals(true)))
          .getSingleOrNull();

      String travelAccountId;

      if (existingTravel != null) {
        // Ask user whether to reactivate or create new
        final reactivate = await _askReactivate(existingTravel);
        if (!mounted) return;
        if (reactivate == null) {
          setState(() => _loading = false);
          return; // cancelled
        }
        if (reactivate) {
          // Unarchive existing
          travelAccountId = existingTravel.id;
          await (db.update(db.accounts)
                ..where((a) => a.id.equals(travelAccountId)))
              .write(AccountsCompanion(
            archived: const Value(false),
            lastModified: Value(DateTime.now()),
          ));
        } else {
          // Create new
          travelAccountId = await _createTravelAccount(
              db, householdId, fromAcc.currency);
        }
      } else {
        // No existing — create new
        travelAccountId =
            await _createTravelAccount(db, householdId, fromAcc.currency);
      }

      // Record the transfer
      await engine.recordTransfer(
        householdId: householdId,
        fromAccountId: _fromAccountId!,
        toAccountId: travelAccountId,
        amount: _sourceAmount,
        currency: fromAcc.currency,
        exchangeRateToBase: _effectiveRate,
        createdBy: 'local',
        deviceId: 'local',
        note: 'Travel exchange → $_targetCurrency',
        date: DateTime.now(),
      );

      // Refresh providers
      ref.invalidate(accountsProvider);
      ref.invalidate(accountsWithBalanceProvider);
      ref.invalidate(unallocatedProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Exchanged ${formatAmount(_sourceAmount, currency: fromAcc.currency)} → ${formatAmount(_receivedAmount, currency: _targetCurrency)}. When you\'re back, open the travel wallet and use "Convert Back & Close" to return leftover money.'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 6),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Exchange failed: $e'),
              behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<String> _createTravelAccount(
      AppDatabase db, String householdId, String sourceCurrency) async {
    final id = const Uuid().v4();
    await AccountsDao(db).upsert(AccountsCompanion.insert(
      id: id,
      householdId: householdId,
      name: 'Travel - $_targetCurrency',
      type: 'wallet',
      currency: _targetCurrency,
      deviceId: 'local',
      isTravel: const Value(true),
      decimalPlaces: Value(currencyDecimals(_targetCurrency)),
    ));
    return id;
  }

  Future<bool?> _askReactivate(Account existing) async {
    final calculator = BalanceCalculator(ref.read(databaseProvider));
    final balance = await calculator.accountBalance(existing.id);
    if (!mounted) return null;
    // Capture theme colors before dialog to avoid using outer context in builder
    final tsColor = AppColors.ts(context);
    final sfvColor = AppColors.sfv(context);
    final bdColor = AppColors.bd(context);

    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Existing Travel Wallet'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You have a previous ${existing.currency} travel wallet:',
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
                          'Balance: ${formatAmount(balance, currency: existing.currency)}',
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
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Create New'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reactivate'),
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
    return Text(label,
        style: TextStyle(
          fontSize: TypographyTokens.sectionHeaderSize,
          fontWeight: TypographyTokens.sectionHeaderWeight,
          letterSpacing: TypographyTokens.sectionHeaderLetterSpacing,
          color: AppColors.th(context),
        ));
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
