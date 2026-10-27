import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/database/app_database.dart';
import '../../core/fx/fx_service.dart';
import '../../core/providers/accounts_provider.dart';
import '../../core/providers/categories_provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/date_format_provider.dart';
import '../../core/providers/engine_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../core/providers/transactions_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_icons.dart';
import '../../shared/utils/format_number.dart';
import '../../shared/widgets/bottom_action_bar.dart';
import '../../shared/widgets/calculator_amount_field.dart';
import '../../shared/widgets/tappable.dart';
import '../../shared/utils/save_errors.dart';
import 'widgets/category_sheet.dart';
import 'widgets/tx_ui.dart';

/// Pay in one currency, get change in another (roadmap #3): what was
/// handed over, the change and its account, the rate (the shop's own one
/// can be typed), an optional price that works the change out. Saved by
/// `AllocationEngine.recordPaymentWithChange` — the spending counts in
/// what was handed over.
class PayWithChangeScreen extends ConsumerStatefulWidget {
  final String? initialTitle;
  final String? initialCategoryId;
  final DateTime? initialDate;

  const PayWithChangeScreen(
      {super.key, this.initialTitle, this.initialCategoryId, this.initialDate});

  @override
  ConsumerState<PayWithChangeScreen> createState() =>
      _PayWithChangeScreenState();
}

class _PayWithChangeScreenState extends ConsumerState<PayWithChangeScreen> {
  late final _titleCtrl = TextEditingController(text: widget.initialTitle);
  String? _categoryId;
  String? _payId;
  String? _changeId;
  double _paid = 0;
  double _change = 0;
  bool _changeTyped = false; // else worked out from the price
  double? _price;
  bool _priceInPaid = false; // the price's currency: paid's, else change's
  double? _rate; // 1 paid currency = rate change currency
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.initialCategoryId;
    WidgetsBinding.instance.addPostFrameCallback((_) => _defaults());
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  List<Account> get _accounts =>
      (ref.read(accountsProvider).value ?? const <Account>[])
          .where((a) => !a.archived)
          .toList();
  Account? _acct(String? id) =>
      _accounts.where((a) => a.id == id).firstOrNull;
  String get _base =>
      ref.read(householdProvider).value?.baseCurrency ?? 'USD';

  /// Cash in the base currency pays; change goes to cash in another one.
  Future<void> _defaults() async {
    // The list may still be loading on a cold open.
    final accts = (await ref.read(accountsProvider.future))
        .where((a) => !a.archived)
        .toList();
    if (!mounted) return;
    int rank(Account a) => a.type == 'cash' ? 0 : 1;
    final byCash = [...accts]..sort((a, b) => rank(a).compareTo(rank(b)));
    final pay = byCash.where((a) => a.currency == _base).firstOrNull ??
        byCash.firstOrNull;
    final change =
        byCash.where((a) => pay != null && a.currency != pay.currency).firstOrNull;
    setState(() {
      _payId = pay?.id;
      _changeId = change?.id;
    });
    await _loadRate();
  }

  Future<void> _loadRate() async {
    final pay = _acct(_payId), into = _acct(_changeId);
    if (pay == null || into == null) return;
    final db = ref.read(databaseProvider);
    double? rate = await latestCachedRate(db, pay.currency, into.currency);
    if (rate == null) {
      try {
        rate = await ref
            .read(fxServiceProvider)
            .getRateWithCache(pay.currency, into.currency);
      } catch (e) {
        debugPrint('[PayWithChange] No rate: $e');
      }
    }
    if (!mounted) return;
    setState(() {
      _rate = rate;
      _workOutChange();
    });
  }

  int _decimals(String? currency) =>
      currency == null ? 2 : currencyDecimals(currency);

  double _round(double v, String? currency) {
    final scale = math.pow(10, _decimals(currency)).toDouble();
    return (v * scale).round() / scale;
  }

  /// The change from the price, until the user types their own.
  void _workOutChange() {
    final rate = _rate, price = _price;
    final into = _acct(_changeId);
    if (_changeTyped || rate == null || price == null || into == null) return;
    final change = _priceInPaid ? (_paid - price) * rate : _paid * rate - price;
    _change = math.max(0, _round(change, into.currency));
  }

  /// What counts as spent (as the engine works it out), or null.
  double? get _spent {
    final pay = _acct(_payId), rate = _rate;
    if (pay == null || rate == null || rate <= 0 || _paid <= 0) return null;
    return _round(_paid - _change / rate, pay.currency);
  }

  Future<void> _amount(String title, double start, String? currency,
      void Function(double) set) async {
    final v = await showCalculatorSheet(context, start, title: title);
    if (v == null || !mounted) return;
    setState(() {
      set(_round(v, currency));
      _workOutChange();
    });
  }

  Future<void> _pickAccount({required bool change}) async {
    final pay = _acct(_payId);
    final picked = await showAccountPickerSheet(context,
        accounts: change
            ? _accounts.where((a) => a.currency != pay?.currency).toList()
            : _accounts,
        selectedId: change ? _changeId : _payId);
    if (picked == null || !mounted) return;
    setState(() {
      if (change) {
        _changeId = picked;
      } else {
        _payId = picked;
        final into = _acct(_changeId);
        if (into != null && into.currency == _acct(picked)?.currency) {
          _changeId = _accounts
              .where((a) => a.currency != _acct(picked)?.currency)
              .firstOrNull
              ?.id;
        }
      }
    });
    await _loadRate();
  }

  Future<void> _editRate() async {
    final tr = S.of(context);
    final pay = _acct(_payId), into = _acct(_changeId);
    if (pay == null || into == null) return;
    final start = _rate ?? 0;
    // Shown the way round that reads as a number above 1.
    final inverted = start > 0 && start < 1;
    final typed = await showCalculatorSheet(
        context, inverted ? 1 / start : start,
        title: inverted
            ? tr.fxRateSheet(into.currency, pay.currency)
            : tr.fxRateSheet(pay.currency, into.currency));
    if (typed == null || typed <= 0 || !mounted) return;
    setState(() {
      _rate = inverted ? 1 / typed : typed;
      _workOutChange();
    });
  }

  Future<void> _pickCategory() async {
    final householdId = ref.read(currentHouseholdIdProvider);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CategorySheet(
        categories: ref.read(categoriesProvider).value ?? const <Category>[],
        selectedId: _categoryId,
        householdId: householdId,
        recentIds: recentCategoryIds(
            ref.read(transactionEntriesProvider).value ?? const []),
        onSelected: (id, name, color, txType) {
          Navigator.of(ctx).pop();
          if (mounted) setState(() => _categoryId = id);
        },
        onCreated: (_) {},
      ),
    );
  }

  Future<void> _save() async {
    final tr = S.of(context);
    final householdId = ref.read(currentHouseholdIdProvider);
    final spent = _spent;
    if (householdId == null || spent == null || _changeId == null) return;
    final messenger = ScaffoldMessenger.of(context);
    if (spent <= 0) {
      messenger.showSnackBar(SnackBar(
          content: Text(tr.payChangeTooMuch),
          behavior: SnackBarBehavior.floating));
      return;
    }
    setState(() => _saving = true);
    try {
      final r = await ref.read(allocationEngineProvider).recordPaymentWithChange(
            householdId: householdId,
            payAccountId: _payId!,
            paid: _paid,
            changeAccountId: _changeId!,
            change: _change,
            rate: _rate!,
            baseCurrency: _base,
            categoryId: _categoryId,
            note: _titleCtrl.text.trim(),
            date: widget.initialDate,
          );
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        content: Text(tr.payChangeSpent(
            formatAmount(r.spent, currency: _acct(_payId)!.currency))),
        behavior: SnackBarBehavior.floating,
      ));
      context.pop(r.expenseId);
    } catch (e) {
      debugPrint('[PayWithChange] Save failed: $e');
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(
          content: Text(txSaveErrorText(tr, e)),
          behavior: SnackBarBehavior.floating));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = S.of(context);
    ref.watch(accountsProvider);
    final pay = _acct(_payId), into = _acct(_changeId);
    final category = (ref.watch(categoriesProvider).value ?? const <Category>[])
        .where((c) => c.id == _categoryId)
        .firstOrNull;
    final spent = _spent;
    final priceCurrency = _priceInPaid ? pay?.currency : into?.currency;

    Widget row(IconData icon, String label, String value,
            {VoidCallback? onTap, String? trailing, VoidCallback? onTrailing,
            String? hint}) =>
        Tappable(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(children: [
              Icon(icon, size: 20, color: AppColors.ts(context)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            fontSize: 12.5, color: AppColors.ts(context))),
                    Text(value,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    if (hint != null)
                      Text(hint,
                          style: TextStyle(
                              fontSize: 12, color: AppColors.th(context))),
                  ],
                ),
              ),
              if (trailing != null)
                Tappable(
                  onTap: onTrailing,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(trailing,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.accentText(context))),
                      Icon(AppIcons.caretRight,
                          size: 16, color: AppColors.th(context)),
                    ]),
                  ),
                ),
            ]),
          ),
        );

    Widget card(List<Widget> children) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: AppColors.card(context),
          clipBehavior: Clip.antiAlias,
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children),
        );

    final noOther = pay != null &&
        !_accounts.any((a) => a.currency != pay.currency);

    return Scaffold(
      appBar: AppBar(title: Text(tr.payChangeTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
            child: Text(noOther ? tr.payChangeNeedOther : tr.payChangeIntro,
                style: TextStyle(fontSize: 13.5, color: AppColors.ts(context))),
          ),
          card([
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextField(
                controller: _titleCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(hintText: tr.txFormTitleHint),
              ),
            ),
            row(AppIcons.tag, tr.commonCategory,
                category?.name ?? tr.commonUncategorized,
                onTap: _pickCategory),
          ]),
          card([
            row(AppIcons.tag, tr.payChangePrice,
                _price == null
                    ? '—'
                    : formatAmount(_price!, currency: priceCurrency),
                hint: tr.payChangePriceHint,
                onTap: () => _amount(tr.payChangePrice, _price ?? 0,
                    priceCurrency, (v) => _price = v > 0 ? v : null),
                trailing: pay != null && into != null ? priceCurrency : null,
                onTrailing: () => setState(() {
                      _priceInPaid = !_priceInPaid;
                      _workOutChange();
                    })),
            row(AppIcons.coins, tr.payChangePaid,
                formatAmount(_paid, currency: pay?.currency),
                onTap: () => _amount(tr.payChangePaid, _paid, pay?.currency,
                    (v) => _paid = v),
                trailing: pay?.name,
                onTrailing: () => _pickAccount(change: false)),
            row(AppIcons.wallet, tr.payChangeChange,
                formatAmount(_change, currency: into?.currency),
                onTap: () => _amount(tr.payChangeChange, _change,
                    into?.currency, (v) {
                  _change = v;
                  _changeTyped = true;
                }),
                trailing: into?.name,
                onTrailing: () => _pickAccount(change: true)),
            row(
                AppIcons.arrowsLeftRight,
                tr.payChangeRate,
                _rate == null || pay == null || into == null
                    ? '—'
                    : _rate! < 1
                        ? tr.quickRateLine(into.currency,
                            formatNumber(roundRate(1 / _rate!)), pay.currency)
                        : tr.quickRateLine(pay.currency,
                            formatNumber(roundRate(_rate!)), into.currency),
                hint: tr.payChangeRateHint,
                onTap: _editRate),
          ]),
          if (spent != null && pay != null && into != null)
            card([
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      spent > 0
                          ? tr.payChangeSpent(
                              formatAmount(spent, currency: pay.currency))
                          : tr.payChangeTooMuch,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: spent > 0 ? null : AppColors.overspent,
                      ),
                    ),
                    if (spent > 0 && _change > 0)
                      Text(
                          tr.payChangeInto(
                              formatAmount(_change, currency: into.currency),
                              into.name),
                          style: TextStyle(
                              fontSize: 13.5, color: AppColors.ts(context))),
                    if (widget.initialDate != null)
                      Text(formatDate(widget.initialDate!),
                          style: TextStyle(
                              fontSize: 13, color: AppColors.th(context))),
                  ],
                ),
              ),
            ]),
        ],
      ),
      bottomNavigationBar: BottomActionBar(children: [
        FilledButton(
          onPressed: _saving || spent == null || spent <= 0 || into == null
              ? null
              : _save,
          child: Text(tr.commonSave),
        ),
      ]),
    );
  }
}
