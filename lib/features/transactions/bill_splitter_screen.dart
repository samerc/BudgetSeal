import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../core/database/app_database.dart';
import '../../core/engine/allocation_engine.dart';
import '../../core/fx/fx_service.dart';
import '../../core/providers/accounts_provider.dart';
import '../../core/providers/categories_provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/date_format_provider.dart';
import '../../core/providers/engine_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../core/providers/objectives_provider.dart';
import '../../core/providers/transactions_provider.dart';
import '../../core/services/last_used_service.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_icons.dart';
import '../../shared/theme/design_tokens.dart';
import '../../shared/utils/dispose_later.dart';
import '../../shared/utils/format_number.dart';
import '../../shared/utils/ocr_service.dart';
import '../../shared/utils/save_errors.dart';
import '../../shared/widgets/calculator_amount_field.dart';
import 'widgets/category_sheet.dart';
import 'widgets/currency_sheet.dart';
import 'widgets/tx_ui.dart';
import '../../shared/widgets/app_chip.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/sheet_title.dart';
import '../../shared/widgets/tappable.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Bill splitter — one screen, quick split first.
//   Bill card: total (calculator), currency, tip chips, optional tax/service.
//   Who's in: Evenly (shares, tap one to set it by hand) | By item (pick a
//   person, tap the items they had; items start as "everyone").
//   Bottom bar: Paid by, From account + category, Save — records the
//   expense and the loans directly, then shows who owes what.
// Layout rule (see CLAUDE.md): the body is ONE flat ListView.
// ─────────────────────────────────────────────────────────────────────────────

class BillSplitterScreen extends ConsumerStatefulWidget {
  const BillSplitterScreen({super.key});

  @override
  ConsumerState<BillSplitterScreen> createState() => _BillSplitterScreenState();
}

enum _SplitMode { evenly, byItem }

/// Who paid the bill: the user, another person (who the user now owes), or
/// everyone their own part.
enum _PaidMode { me, other, each }

class _BillItem {
  String name;
  double amount;

  /// Quantity read from the receipt ("3 x Lemonade"); offers "Split into 3".
  int qty;

  /// Who had it. Empty = everyone.
  final Set<String> people;
  final int? ocrLineIndex;

  _BillItem({
    required this.name,
    required this.amount,
    this.qty = 1,
    Set<String>? people,
    this.ocrLineIndex,
  }) : people = people ?? {};
}

const _personColors = [
  Color(0xFF4F7BD9),
  Color(0xFFE07A3F),
  Color(0xFF2F9E6E),
  Color(0xFF8E5CC9),
  Color(0xFFD9488A),
  Color(0xFF1E9DB0),
  Color(0xFFB8892B),
  Color(0xFF6B7FA8),
];

class _BillSplitterScreenState extends ConsumerState<BillSplitterScreen> {
  // ── People ── first is always the user (named in their language).
  final _people = <String>['Me'];
  bool _meNamed = false;

  // ── Split ──
  _SplitMode _mode = _SplitMode.evenly;
  double _subtotalEntered = 0; // Evenly: the bill before tip/tax
  final _fixed = <String, double>{}; // Evenly: shares set by hand
  final _items = <_BillItem>[];
  String? _painting; // By item: the person whose items are being tapped

  // ── Tip ── percentage (proportional) or a fixed amount (split evenly)
  double _tipPercent = 0;
  double _tipAmount = 0;
  bool _tipIsAmount = false;

  // ── Tax or service ── optional, in proportion to what each person had
  bool _taxOn = false;
  double _taxPercent = 0;
  double _taxAmount = 0;
  bool _taxIsAmount = true;

  // ── Currency ──
  late String _billCurrency;
  double _exchangeRate = 1.0;
  bool _rateInverted = true; // 1 <base> = X <bill>
  final _rateCtrl = TextEditingController();

  // ── OCR ──
  bool _scanning = false;
  OcrResult? _ocr;

  /// "Split in" (the base currency): the bill is in another currency (an LBP receipt)
  /// but people pay in the base one — shares, what's owed, the summary and
  /// the loans are in the base currency. Remembered between bills.
  bool _splitInBase = false;
  static const _prefSplitInBase = 'bill_split_in_base';

  /// The totals page (review before saving): each person's amount, who
  /// owes whom, account/category, Share and Save. Edit split goes back.
  bool _reviewing = false;

  /// The currency the scanned receipt seems to be in (offered under the
  /// total until the user switches or picks a currency).
  String? _currencyHint;
  final _addedLines = <int>{};
  bool _showUnpriced = false;

  // ── Paying ──
  _PaidMode _paidMode = _PaidMode.me;
  String? _payer;
  String? _accountId;
  String? _categoryId;
  bool _saving = false;

  /// The "Tap what Sam had" banner: scrolled to the top when a person is
  /// picked, so the items show above the bottom bar.
  final _bannerKey = GlobalKey();

  String get _baseCurrency =>
      ref.read(householdProvider).value?.baseCurrency ?? 'USD';

  @override
  void initState() {
    super.initState();
    _billCurrency = ref.read(householdProvider).value?.baseCurrency ?? 'USD';
    SharedPreferences.getInstance().then((prefs) {
      final on = prefs.getBool(_prefSplitInBase) ?? false;
      if (mounted && on) setState(() => _splitInBase = true);
    }).catchError((Object e) => debugPrint('[BillSplitter] prefs: $e'));
    // The usual account, once accounts have loaded.
    ref.listenManual(accountsProvider, (_, next) async {
      final accounts =
          (next.value ?? const <Account>[]).where((a) => !a.archived).toList();
      if (_accountId != null || accounts.isEmpty) return;
      final id = await LastUsedService.defaultAccount(accounts);
      if (mounted && _accountId == null) setState(() => _accountId = id);
    }, fireImmediately: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_meNamed) {
      _meNamed = true;
      _people[0] = S.of(context).billMe;
    }
  }

  @override
  void dispose() {
    _rateCtrl.dispose();
    super.dispose();
  }

  String get _me => _people.first;
  List<String> get _others => _people.skip(1).toList();
  String _fmt(double v) => formatAmount(v, currency: _billCurrency);

  bool get _isEmpty =>
      _subtotalEntered == 0 && _items.isEmpty && _people.length == 1;

  // ─── Money ─────────────────────────────────────────────────────────────────

  double get _itemsTotal => _items.fold(0.0, (s, i) => s + i.amount);
  double get _subtotal =>
      _mode == _SplitMode.evenly ? _subtotalEntered : _itemsTotal;
  double get _taxTotal =>
      !_taxOn ? 0 : (_taxIsAmount ? _taxAmount : _subtotal * _taxPercent / 100);
  double get _tipTotal =>
      _tipIsAmount ? _tipAmount : _subtotal * _tipPercent / 100;
  double get _grand => _subtotal + _taxTotal + _tipTotal;

  double get _factor =>
      math.pow(10, currencyDecimals(_billCurrency)).toDouble();

  /// Who had [item]: its people, or everyone.
  Set<String> _owners(_BillItem item) {
    final own = item.people.where(_people.contains).toSet();
    return own.isEmpty ? _people.toSet() : own;
  }

  /// Each person's share of the whole bill (tip and tax included), rounded
  /// to the currency so the shares add up to the rounded total exactly.
  Map<String, double> _shares() {
    final raw = <String, double>{};
    final exact = <String>{};
    if (_mode == _SplitMode.evenly) {
      final fixed = {
        for (final p in _people)
          if (_fixed.containsKey(p)) p: _fixed[p]!,
      };
      final free = _people.where((p) => !fixed.containsKey(p)).toList();
      final rest = _grand - fixed.values.fold(0.0, (s, v) => s + v);
      raw.addAll(fixed);
      exact.addAll(fixed.keys);
      for (final p in free) {
        raw[p] = rest / free.length;
      }
    } else {
      final sub = {for (final p in _people) p: 0.0};
      for (final item in _items) {
        final owners = _owners(item);
        for (final p in owners) {
          sub[p] = sub[p]! + item.amount / owners.length;
        }
      }
      final subtotal = _itemsTotal;
      for (final p in _people) {
        final s = sub[p]!;
        final tax = subtotal != 0 ? s / subtotal * _taxTotal : 0.0;
        final tip =
            _tipIsAmount ? _tipAmount / _people.length : s * _tipPercent / 100;
        raw[p] = s + tax + tip;
      }
    }
    return _rounded(raw, exact);
  }

  /// Each person's part of the tip in [shares] (bill currency), rounded so
  /// the parts add up to the tip: in proportion to each share (Evenly), the
  /// tip percentage of what they had (By item), or evenly (custom tip).
  Map<String, double> _tipParts(Map<String, double> shares) {
    final tip = _tipTotal;
    if (tip == 0 || _grand == 0) return {for (final p in _people) p: 0.0};
    final raw = <String, double>{};
    if (_mode == _SplitMode.evenly) {
      for (final p in _people) {
        raw[p] = tip * (shares[p] ?? 0) / _grand;
      }
    } else if (_tipIsAmount) {
      for (final p in _people) {
        raw[p] = tip / _people.length;
      }
    } else {
      for (final p in _people) {
        var sub = 0.0;
        for (final item in _items) {
          final owners = _owners(item);
          if (owners.contains(p)) sub += item.amount / owners.length;
        }
        raw[p] = sub * _tipPercent / 100;
      }
    }
    return _rounded(raw, const {});
  }

  /// Largest remainder rounding; [exact] (shares set by hand) are kept.
  Map<String, double> _rounded(Map<String, double> raw, Set<String> exact,
      {double? factor}) {
    final f = factor ?? _factor;
    final target = (raw.values.fold(0.0, (s, v) => s + v) * f).round();
    final units = {
      for (final e in raw.entries)
        e.key: exact.contains(e.key)
            ? (e.value * f).round()
            : (e.value * f).floor(),
    };
    var remainder = target - units.values.fold(0, (s, v) => s + v);
    final byFraction = raw.keys.where((k) => !exact.contains(k)).toList()
      ..sort((a, b) =>
          ((raw[b]! * f) - units[b]!).compareTo((raw[a]! * f) - units[a]!));
    for (final p in byFraction) {
      if (remainder <= 0) break;
      units[p] = units[p]! + 1;
      remainder--;
    }
    return {for (final p in _people) p: (units[p] ?? 0) / f};
  }

  double _toBase(double amount) {
    if (_billCurrency == _baseCurrency) return amount;
    if ((_exchangeRate - 1.0).abs() < 0.001) return amount;
    return amount * _exchangeRate;
  }

  /// Shares are paid in the base currency (see [_splitInBase]); needs a
  /// real rate.
  bool get _canSplitInBase =>
      _billCurrency != _baseCurrency && (_exchangeRate - 1.0).abs() >= 0.001;
  bool get _inBase => _splitInBase && _canSplitInBase;
  String get _payCurrency => _inBase ? _baseCurrency : _billCurrency;
  String _fmtPay(double v) => formatAmount(v, currency: _payCurrency);

  /// [shares] in the currency people pay in: converted at the bill's rate
  /// and rounded to it so they still add up to the converted total.
  Map<String, double> _payShares(Map<String, double> shares) {
    if (!_inBase) return shares;
    return _rounded({for (final e in shares.entries) e.key: _toBase(e.value)},
        const {},
        factor: math.pow(10, currencyDecimals(_baseCurrency)).toDouble());
  }

  Future<void> _toggleSplitInBase(bool on) async {
    setState(() => _splitInBase = on);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefSplitInBase, on);
    } catch (e) {
      debugPrint('[BillSplitter] prefs: $e');
    }
  }

  double get _tolerance => 1.5 / _factor;

  _PaidMode get _effectiveMode => _others.isEmpty ? _PaidMode.each : _paidMode;

  String get _effectivePayer => _payer != null && _people.contains(_payer)
      ? _payer!
      : (_others.isNotEmpty ? _others.first : _me);

  // ─── Currency ──────────────────────────────────────────────────────────────

  Future<void> _pickCurrency() async {
    final accts = ref.read(accountsProvider).value ?? const <Account>[];
    final c = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CurrencySheet(
        current: _billCurrency,
        accountCurrencies: accts.map((a) => a.currency).toSet().toList(),
      ),
    );
    if (c == null || c == _billCurrency || !mounted) return;
    await _setBillCurrency(c);
  }

  /// Switches the bill currency and fills the rate from the app's rates
  /// (live, else cached). The user can still type their own.
  Future<void> _setBillCurrency(String c) async {
    setState(() {
      _billCurrency = c;
      _currencyHint = null;
      _exchangeRate = 1.0;
      _rateCtrl.clear();
      _fixed.clear();
    });
    if (c == _baseCurrency) return;
    final rate = await rateToBaseOrOne(ref.read(fxServiceProvider),
        ref.read(databaseProvider), c, _baseCurrency);
    if (!mounted || _billCurrency != c || rate == 1.0) return;
    // The rate shown is rounded (89,881 → 90,000); the maths use that same
    // rate so the amounts match what people see.
    final shown = roundRate(_rateInverted ? 1.0 / rate : rate);
    setState(() {
      _exchangeRate = _rateInverted ? 1.0 / shown : shown;
      _rateCtrl.text = formatRateForInput(shown);
    });
  }

  void _onRateTyped(String v) {
    final r = parseLooseAmount(v) ?? 0;
    if (r > 0) _exchangeRate = _rateInverted ? 1.0 / r : r;
    setState(() {});
  }

  void _swapRateDirection() => setState(() {
        _rateInverted = !_rateInverted;
        if (_exchangeRate > 0 && _exchangeRate != 1.0) {
          _rateCtrl.text = formatRateForInput(
              roundRate(_rateInverted ? 1.0 / _exchangeRate : _exchangeRate));
        }
      });

  // ─── Total, tip, tax ───────────────────────────────────────────────────────

  Future<void> _editTotal() async {
    if (_mode == _SplitMode.byItem) return; // the items make the total
    final v = await showCalculatorSheet(context, _subtotalEntered);
    if (v == null || !mounted) return;
    setState(() {
      _subtotalEntered = v;
      _fixed.clear();
    });
  }

  Future<void> _setTip(String choice) async {
    if (choice == 'custom') {
      final v =
          await showCalculatorSheet(context, _tipIsAmount ? _tipAmount : 0);
      if (v == null || !mounted) return;
      setState(() {
        _tipIsAmount = true;
        _tipAmount = v;
        _fixed.clear();
      });
      return;
    }
    setState(() {
      _tipIsAmount = false;
      _tipAmount = 0;
      _tipPercent = double.parse(choice);
      _fixed.clear();
    });
  }

  Future<void> _editTax() async {
    final tr = S.of(context);
    final percent = await showModalBottomSheet<bool>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(AppIcons.percent),
            title: Text(tr.billTaxPercent),
            onTap: () => Navigator.pop(ctx, true),
          ),
          ListTile(
            leading: const Icon(AppIcons.money),
            title: Text(tr.billTaxFixed),
            onTap: () => Navigator.pop(ctx, false),
          ),
        ]),
      ),
    );
    if (percent == null || !mounted) return;
    final v =
        await showCalculatorSheet(context, percent ? _taxPercent : _taxAmount);
    if (v == null || !mounted) return;
    setState(() {
      _taxOn = v > 0;
      _taxIsAmount = !percent;
      if (percent) {
        _taxPercent = v;
      } else {
        _taxAmount = v;
      }
      _fixed.clear();
    });
  }

  // ─── People ────────────────────────────────────────────────────────────────

  List<String> get _recentPeople {
    final loans = ref.watch(objectivesProvider).value ?? const <Objective>[];
    final sorted = loans
        .where(
            (o) => o.type == 'loan' && (o.contactName ?? '').trim().isNotEmpty)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final out = <String>[];
    for (final o in sorted) {
      final n = o.contactName!.trim();
      if (!out.contains(n) && !_people.contains(n)) out.add(n);
      if (out.length == 3) break;
    }
    return out;
  }

  void _addPersonNamed(String name) {
    final n = name.trim();
    if (n.isEmpty || _people.contains(n)) return;
    setState(() {
      _people.add(n);
      _fixed.clear();
    });
  }

  Future<void> _addPerson() async {
    final tr = S.of(context);
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr.billAddPerson),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(hintText: tr.billPersonName),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(tr.commonCancel)),
          FilledButton(
              style: DialogButtons.filled,
              onPressed: () => Navigator.pop(ctx, ctrl.text),
              child: Text(tr.commonAdd)),
        ],
      ),
    );
    disposeAfterRouteAnimation(ctrl);
    if (name != null) _addPersonNamed(name);
  }

  void _removePerson(String name) {
    if (name == _me) return;
    final tr = S.of(context);
    // Items that were only theirs would silently become everyone's: say so.
    final solo = _items
        .where((i) => i.people.length == 1 && i.people.contains(name))
        .toList();
    final index = _people.indexOf(name);
    final fixedBackup = Map<String, double>.from(_fixed);
    setState(() {
      _people.remove(name);
      _fixed.clear();
      for (final i in _items) {
        i.people.remove(name);
      }
      if (_painting == name) _painting = null;
      if (_payer == name) _payer = null;
    });
    if (solo.isEmpty) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(tr.billItemsSharedNow(name)),
        behavior: SnackBarBehavior.floating,
        persist: false,
        action: SnackBarAction(
          label: tr.txUndoAction,
          onPressed: () {
            if (!mounted || _people.contains(name)) return;
            setState(() {
              _people.insert(math.min(index, _people.length), name);
              for (final i in solo) {
                i.people
                  ..clear()
                  ..add(name);
              }
              _fixed
                ..clear()
                ..addAll(fixedBackup);
            });
          },
        ),
      ));
  }

  Future<void> _personActions(String name) async {
    final tr = S.of(context);
    final canSet = _mode == _SplitMode.evenly &&
        _people.length > 1 &&
        // The last free person takes whatever is left.
        _people.where((p) => !_fixed.containsKey(p) && p != name).isNotEmpty;
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (canSet)
            ListTile(
              leading: const Icon(AppIcons.pencilSimple),
              title: Text(tr.billSetShare),
              onTap: () => Navigator.pop(ctx, 'set'),
            ),
          if (_fixed.containsKey(name))
            ListTile(
              leading: const Icon(AppIcons.arrowCounterClockwise),
              title: Text(tr.billResetShare),
              onTap: () => Navigator.pop(ctx, 'reset'),
            ),
          if (name != _me)
            ListTile(
              leading: Icon(AppIcons.trash, color: AppColors.overspent),
              title: Text(tr.commonRemove,
                  style: TextStyle(color: AppColors.overspent)),
              onTap: () => Navigator.pop(ctx, 'remove'),
            ),
        ]),
      ),
    );
    if (!mounted) return;
    switch (action) {
      case 'set':
        await _setShare(name);
      case 'reset':
        setState(() => _fixed.remove(name));
      case 'remove':
        _removePerson(name);
    }
  }

  /// Evenly: set one person's share by hand; the others split the rest.
  Future<void> _setShare(String name) async {
    if (_mode != _SplitMode.evenly || _people.length < 2) return;
    final others = _people.where((p) => p != name);
    if (others.every(_fixed.containsKey)) return; // someone must take the rest
    // Typed in the currency people pay in, kept in the bill's.
    final current = _payShares(_shares())[name] ?? 0;
    final typed = await showCalculatorSheet(context, current);
    if (typed == null || !mounted) return;
    final v = _inBase ? typed / _exchangeRate : typed;
    final fixedOthers = _fixed.entries
        .where((e) => e.key != name)
        .fold(0.0, (s, e) => s + e.value);
    if (v + fixedOthers > _grand + _tolerance) {
      HapticFeedback.heavyImpact();
      return;
    }
    setState(() => _fixed[name] = v);
  }

  // ─── Items ─────────────────────────────────────────────────────────────────

  void _setMode(_SplitMode m) {
    if (m == _mode) return;
    setState(() {
      if (m == _SplitMode.evenly && _items.isNotEmpty) {
        _subtotalEntered = _itemsTotal;
      }
      _mode = m;
      _painting = null;
      _fixed.clear();
    });
  }

  void _toggleItem(_BillItem item) {
    final p = _painting;
    if (p == null) return;
    final owners = _owners(item);
    setState(() {
      if (owners.contains(p)) {
        if (owners.length == 1) {
          HapticFeedback.heavyImpact(); // someone has to have had it
          return;
        }
        item.people
          ..clear()
          ..addAll(owners..remove(p));
      } else {
        item.people
          ..clear()
          ..addAll(owners..add(p));
      }
      // Everyone again = the default.
      if (item.people.length == _people.length) item.people.clear();
    });
  }

  /// Add (item null) or edit an item: name, amount, split a quantity, delete.
  Future<void> _editItem([_BillItem? item]) async {
    final tr = S.of(context);
    final nameCtrl = TextEditingController(text: item?.name ?? '');
    var amount = item?.amount ?? 0;
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(item == null ? tr.billAddItem : tr.commonEdit),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: nameCtrl,
                autofocus: item == null,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(hintText: tr.billItemName),
              ),
              const SizedBox(height: 12),
              Material(
                color: AppColors.sfv(ctx),
                borderRadius: BorderRadius.circular(RadiusTokens.md),
                child: Tappable(
                  borderRadius: BorderRadius.circular(RadiusTokens.md),
                  onTap: () async {
                    final v = await showCalculatorSheet(ctx, amount);
                    if (v != null) setLocal(() => amount = v);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    child: Row(children: [
                      Text(tr.commonAmount,
                          style: TextStyle(color: AppColors.ts(ctx))),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerEnd,
                          child: Text(_fmt(amount),
                              style: const TextStyle(
                                  fontFamily: TypographyTokens.displayFamily,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18)),
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
              if (item != null && item.qty > 1 && item.amount > 0)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    onPressed: () => Navigator.pop(ctx, 'split'),
                    icon: const Icon(AppIcons.arrowsSplit, size: 18),
                    label: Text(tr.billSplitInto(item.qty)),
                  ),
                ),
            ],
          ),
          actions: [
            if (item != null)
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'delete'),
                style:
                    TextButton.styleFrom(foregroundColor: AppColors.overspent),
                child: Text(tr.commonDelete),
              ),
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(tr.commonCancel)),
            FilledButton(
                style: DialogButtons.filled,
                onPressed: () => Navigator.pop(ctx, 'save'),
                child: Text(tr.commonSave)),
          ],
        ),
      ),
    );
    final name = nameCtrl.text.trim();
    disposeAfterRouteAnimation(nameCtrl);
    if (!mounted || result == null) return;
    setState(() {
      switch (result) {
        case 'delete':
          _items.remove(item);
          if (item?.ocrLineIndex != null) {
            _addedLines.remove(item!.ocrLineIndex);
          }
        case 'split':
          final i = _items.indexOf(item!);
          final unit = item.amount / item.qty;
          final base = item.name.replaceAll(RegExp(r'\s*×\d+$'), '');
          _items
            ..removeAt(i)
            ..insertAll(i, [
              for (var n = 0; n < item.qty; n++)
                _BillItem(
                  name: '$base (${n + 1}/${item.qty})',
                  amount: unit,
                  people: Set.of(item.people),
                  ocrLineIndex: item.ocrLineIndex,
                ),
            ]);
        case 'save':
          if (amount == 0) return;
          final label = name.isEmpty ? tr.billItemN(_items.length + 1) : name;
          if (item == null) {
            _items.add(_BillItem(name: label, amount: amount));
          } else {
            item
              ..name = label
              ..amount = amount;
          }
      }
    });
  }

  // ─── OCR ───────────────────────────────────────────────────────────────────

  Future<void> _scanReceipt() async {
    final path = await _receiptImage();
    if (path == null || !mounted) return;
    setState(() => _scanning = true);
    final result = await OcrService.scanReceipt(path, currency: _billCurrency);
    if (!mounted) return;
    setState(() {
      _scanning = false;
      _ocr = result;
      _addedLines.clear();
      _items.clear();
      _painting = null;
      _fixed.clear();
      for (var i = 0; i < result.lines.length; i++) {
        final l = result.lines[i];
        if (!l.hasPrice) continue;
        final name = l.parsedName ?? l.text.trim();
        _items.add(_BillItem(
          name: l.parsedQuantity > 1 ? '$name ×${l.parsedQuantity}' : name,
          amount: l.parsedAmount!,
          qty: l.parsedQuantity,
          ocrLineIndex: i,
        ));
        _addedLines.add(i);
      }
      if (_items.isNotEmpty) _mode = _SplitMode.byItem;
      // A receipt that lists tax/service separately: when items + tax
      // match its total, fill the tax (a tax-inclusive one is left alone).
      final tax = result.taxTotal, total = result.receiptTotal;
      if (tax != null &&
          total != null &&
          (_itemsTotal + tax - total).abs() <= _tolerance) {
        _taxOn = true;
        _taxIsAmount = true;
        _taxAmount = tax;
      }
    });
    if (result.lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(S.of(context).billNoText),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    _checkReceiptCurrency(result);
  }

  /// A receipt in another currency than the bill's: one it names ("LBP",
  /// "ل.ل") switches the bill at once (with Undo); one guessed from the
  /// amounts is offered under the total.
  void _checkReceiptCurrency(OcrResult result) {
    final accounts = ref.read(accountsProvider).value ?? const <Account>[];
    final guess = OcrService.receiptCurrency(
      result,
      billCurrency: _billCurrency,
      userCurrencies: {_baseCurrency, ...accounts.map((a) => a.currency)},
    );
    if (guess == null) {
      setState(() => _currencyHint = null);
      return;
    }
    if (!guess.printed) {
      setState(() => _currencyHint = guess.code);
      return;
    }
    final before = _billCurrency;
    _setBillCurrency(guess.code);
    final tr = S.of(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(tr.billCurrencySwitched(guess.code)),
      behavior: SnackBarBehavior.floating,
      persist: false,
      action: SnackBarAction(
        label: tr.txUndoAction,
        onPressed: () {
          if (mounted) _setBillCurrency(before);
        },
      ),
    ));
  }

  /// The receipt photo to read. On Android, Google's document scanner
  /// (finds the edges, crops, flattens, cleans up; offers the gallery too) —
  /// a much better image for the text reader. Elsewhere, or when the scanner
  /// can't start (no Play services), the camera / gallery picker.
  Future<String?> _receiptImage() async {
    if (Platform.isAndroid) {
      final scanner = DocumentScanner(
        options: DocumentScannerOptions(
          mode: ScannerMode.full,
          isGalleryImport: true,
        ),
      );
      try {
        final scan = await scanner.scanDocument();
        final images = scan.images ?? const [];
        if (images.isNotEmpty) return images.first;
        return null;
      } on PlatformException catch (e) {
        if ((e.message ?? '').contains('cancel')) return null;
        debugPrint('[BillSplitter] Document scanner unavailable: $e');
      } catch (e) {
        debugPrint('[BillSplitter] Document scanner unavailable: $e');
      } finally {
        scanner.close();
      }
      if (!mounted) return null;
    }
    return _pickImage();
  }

  Future<String?> _pickImage() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(AppIcons.camera),
              title: Text(S.of(ctx).billTakePhoto),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(AppIcons.images),
              title: Text(S.of(ctx).billFromGallery),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return null;
    XFile? image;
    try {
      image = await picker.pickImage(
          source: source, maxWidth: 2400, maxHeight: 2400, imageQuality: 95);
    } catch (e) {
      debugPrint('[BillSplitter] pickImage failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(S.of(context).commonSomethingWentWrong),
          behavior: SnackBarBehavior.floating,
        ));
      }
      return null;
    }
    // The user may have left during camera/gallery.
    if (image == null || !mounted) return null;
    return image.path;
  }

  /// A receipt line read without a price: ask for it, then add it.
  Future<void> _addUnpriced(int index) async {
    final line = _ocr!.lines[index];
    final v = await showCalculatorSheet(context, 0);
    if (v == null || v == 0 || !mounted) return;
    setState(() {
      _items.add(_BillItem(
          name: line.parsedName ?? line.text.trim(),
          amount: v,
          ocrLineIndex: index));
      _addedLines.add(index);
    });
  }

  // ─── Account & category ────────────────────────────────────────────────────

  Future<void> _pickAccount() async {
    final accounts = (ref.read(accountsProvider).value ?? const <Account>[])
        .where((a) => !a.archived)
        .toList();
    final id = await showAccountPickerSheet(context,
        accounts: accounts,
        title: S.of(context).commonAccount,
        selectedId: _accountId);
    if (id != null && mounted) setState(() => _accountId = id);
  }

  Future<void> _pickCategory() async {
    final categories = ref.read(categoriesProvider).value ?? const <Category>[];
    final householdId = ref.read(currentHouseholdIdProvider);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CategorySheet(
        categories: categories,
        selectedId: _categoryId,
        householdId: householdId,
        initialType: 'expense',
        recentIds: recentCategoryIds(
            ref.read(transactionEntriesProvider).value ?? const []),
        onSelected: (id, name, color, txType) {
          if (mounted) setState(() => _categoryId = id);
          Navigator.of(ctx).pop();
        },
        onCreated: (name) async {
          if (householdId == null) return;
          final db = ref.read(databaseProvider);
          final cats = ref.read(categoriesProvider).value ?? [];
          final color =
              categoryPresetColors[cats.length % categoryPresetColors.length];
          final colorHex =
              '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
          final newId = const Uuid().v4();
          try {
            await db.into(db.categories).insert(CategoriesCompanion.insert(
                  id: newId,
                  householdId: householdId,
                  name: name,
                  colorHex: Value(colorHex),
                  transactionType: const Value('expense'),
                ));
          } catch (e) {
            debugPrint('[BillSplitter] Creating category failed: $e');
            return;
          }
          if (!mounted) return;
          ref.invalidate(categoriesProvider);
          setState(() => _categoryId = newId);
          if (ctx.mounted) Navigator.of(ctx).pop();
        },
      ),
    );
  }

  // ─── Save ──────────────────────────────────────────────────────────────────

  bool get _canSave {
    if (_saving || _grand <= 0) return false;
    final mine = _shares()[_me] ?? 0;
    return _effectiveMode == _PaidMode.me || mine > 0;
  }

  Future<void> _save() async {
    final tr = S.of(context);
    final mode = _effectiveMode;
    final records = mode != _PaidMode.other;
    if (records && _accountId == null) {
      await _pickAccount();
      if (_accountId == null || !mounted) return;
    }
    final isCross = _billCurrency != _baseCurrency;
    if (records && isCross && (_exchangeRate - 1.0).abs() < 0.001) {
      final proceed = await showConfirmDialog(
        context,
        title: tr.billRateNotSetTitle,
        message: tr.billRateNotSetContent(_billCurrency),
        cancelLabel: tr.commonGoBack,
        confirmLabel: tr.commonSaveAnyway,
        destructive: false,
      );
      if (!proceed || !mounted) return;
    }

    final shares = _shares();
    final mine = shares[_me] ?? 0;
    final total = shares.values.fold(0.0, (s, v) => s + v);
    final others = _others;
    final owed = {
      for (final p in others)
        if ((shares[p] ?? 0) > 0) p: shares[p]!,
    };
    final account = (ref.read(accountsProvider).value ?? const <Account>[])
        .where((a) => a.id == _accountId)
        .firstOrNull;

    setState(() => _saving = true);
    String? txId;
    var loanIds = const <String>[];
    try {
      if (records) {
        final householdId = ref.read(currentHouseholdIdProvider);
        if (householdId == null) throw StateError('no household');
        final rate = isCross ? _exchangeRate : 1.0;
        final note = others.isEmpty
            ? tr.billNoteTotal(_fmt(total))
            : tr.billNoteSplitWith(others.join(', '), _fmt(total));
        final lines = <TxLine>[
          if (mine > 0)
            TxLine(
              amount: mine,
              currency: _billCurrency,
              categoryId: _categoryId,
              accountId: _accountId,
              exchangeRateToBase: rate,
            ),
          if (mode == _PaidMode.me)
            for (final e in owed.entries)
              TxLine(
                amount: e.value,
                currency: _billCurrency,
                accountId: _accountId,
                exchangeRateToBase: rate,
                note: tr.billLinePart(e.key),
              ),
        ];
        txId = await ref.read(allocationEngineProvider).recordTransaction(
              householdId: householdId,
              accountId: _accountId!,
              type: 'expense',
              lines: lines,
              baseCurrency: _baseCurrency,
              note: '${tr.billNoteTitle} — $note',
            );
        LastUsedService.rememberAccount(_accountId!);
      }
      // Loans in the currency people pay back in.
      final pay = _payShares(shares);
      if (mode == _PaidMode.me) {
        loanIds = await _createLoans(
            'lent', {for (final p in owed.keys) p: pay[p] ?? 0});
      } else if (mode == _PaidMode.other) {
        loanIds = await _createLoans(
            'borrowed', {_effectivePayer: pay[_me] ?? 0});
        if (loanIds.isEmpty) throw StateError('loan not saved');
      }
    } catch (e) {
      debugPrint('[BillSplitter] Save failed: $e');
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(txSaveErrorText(tr, e)),
          behavior: SnackBarBehavior.floating,
        ));
      }
      return;
    }
    if (!mounted) return;
    setState(() => _saving = false);

    final pay = _payShares(shares);
    final outcome = await _showSaved(
      mode: mode,
      shares: pay,
      owed: {for (final p in owed.keys) p: pay[p] ?? 0},
      total: pay.values.fold(0.0, (s, v) => s + v),
      accountName: account?.name ?? '',
    );
    if (!mounted) return;
    if (outcome == 'undo') {
      await _undo(txId: txId, loanIds: loanIds);
      return; // the bill stays on screen to fix
    }
    context.pop();
  }

  /// The saved bill: who owes what, a way to send each share, Undo.
  Future<String?> _showSaved({
    required _PaidMode mode,
    required Map<String, double> shares,
    required Map<String, double> owed,
    required double total,
    required String accountName,
  }) {
    final tr = S.of(context);
    final mine = shares[_me] ?? 0;
    final payer = _effectivePayer;
    final subtitle = switch (mode) {
      // What left the account is in the bill's currency; what people owe
      // (below) is in the currency they pay in.
      _PaidMode.me => tr.billSavedFrom(
          _fmt(_grand), accountName, _fmt(_shares()[_me] ?? 0)),
      _PaidMode.each =>
        tr.billSavedEach(_fmt(_shares()[_me] ?? 0), accountName),
      _PaidMode.other => tr.billNothingLeaves(payer),
    };
    final rows = mode == _PaidMode.me
        ? owed
        : mode == _PaidMode.other
            ? {payer: mine}
            : const <String, double>{};
    final shareText = _shareText(shares, mode);
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.pastel(ctx, AppColors.healthy,
                        light: 0.82, dark: 0.7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(AppIcons.check,
                      size: 24, color: AppColors.healthy),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr.billNoteTitle,
                          style: const TextStyle(
                              fontWeight: TypographyTokens.sheetTitleWeight,
                              fontSize: TypographyTokens.sheetTitleSize)),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: TextStyle(
                              fontSize: 13, color: AppColors.ts(ctx))),
                    ],
                  ),
                ),
              ]),
              if (rows.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  decoration: AppColors.card(ctx),
                  padding: const EdgeInsets.only(top: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          mode == _PaidMode.me
                              ? tr.billOwesYouTitle
                              : tr.billYouOweTitle,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ts(ctx)),
                        ),
                      ),
                      for (final e in rows.entries)
                        Padding(
                          padding:
                              const EdgeInsetsDirectional.fromSTEB(16, 4, 4, 4),
                          child: Row(children: [
                            _Avatar(
                                label: _initials(e.key),
                                color: _colorOf(e.key),
                                size: 36),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(e.key,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700)),
                            ),
                            Text(
                              _fmtPay(e.value),
                              style: TextStyle(
                                fontFamily: TypographyTokens.displayFamily,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                fontFeatures: const [
                                  FontFeature.tabularFigures()
                                ],
                                color: mode == _PaidMode.me
                                    ? AppColors.healthy
                                    : AppColors.caution,
                              ),
                            ),
                            if (mode == _PaidMode.me)
                              IconButton(
                                tooltip: tr.billSendShare(e.key),
                                icon: Icon(AppIcons.shareFat,
                                    size: 20, color: AppColors.accent),
                                onPressed: () => SharePlus.instance.share(
                                    ShareParams(
                                        text: tr.billPersonShareText(
                                            _fmtPay(e.value)))),
                              )
                            else
                              const SizedBox(width: 12),
                          ]),
                        ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                        child: Text(tr.billTrackedHint,
                            style: TextStyle(
                                fontSize: 12, color: AppColors.ts(ctx))),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(children: [
                if (_others.isNotEmpty) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => SharePlus.instance
                          .share(ShareParams(text: shareText)),
                      icon: const Icon(AppIcons.shareNetwork, size: 18),
                      label: Text(tr.billShareShort),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(ctx, 'done'),
                    child: Text(tr.commonDone),
                  ),
                ),
              ]),
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'undo'),
                child: Text(tr.txUndoAction),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Undo a saved bill: the payment (if any) and the loans it created.
  Future<void> _undo({String? txId, List<String> loanIds = const []}) async {
    try {
      if (txId != null) {
        await ref.read(allocationEngineProvider).deleteTransaction(txId);
        ref.invalidate(transactionEntriesProvider);
        ref.invalidate(monthlyTransactionsProvider);
      }
      if (loanIds.isNotEmpty) {
        final db = ref.read(databaseProvider);
        await (db.update(db.objectives)..where((o) => o.id.isIn(loanIds)))
            .write(ObjectivesCompanion(
                deleted: const Value(true),
                lastModified: Value(DateTime.now())));
        ref.invalidate(objectivesProvider);
      }
    } catch (e) {
      debugPrint('[BillSplitter] Undo failed: $e');
    }
  }

  /// One loan per person in Goals & Loans, in the currency people pay in
  /// (the bill's, or the base one with "Split in"). Repayments
  /// are recorded from the loan (Record payment), like any other loan.
  Future<List<String>> _createLoans(
      String direction, Map<String, double> amounts) async {
    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null) return const [];
    final db = ref.read(databaseProvider);
    final name = S.of(context).billLoanName(formatDate(DateTime.now()));
    final ids = <String>[];
    for (final e in amounts.entries) {
      if (e.value <= 0) continue;
      final id = const Uuid().v4();
      await db.into(db.objectives).insert(ObjectivesCompanion.insert(
            id: id,
            householdId: householdId,
            name: name,
            type: 'loan',
            targetCurrency: _payCurrency,
            deviceId: 'local',
            targetAmount: Value(e.value),
            currentAmount: const Value(0),
            contactName: Value(e.key),
            direction: Value(direction),
            lastModified: Value(DateTime.now()),
          ));
      ids.add(id);
    }
    ref.invalidate(objectivesProvider);
    return ids;
  }

  /// Plain-text summary for a group chat.
  String _shareText(Map<String, double> shares, _PaidMode mode) {
    final tr = S.of(context);
    final total = shares.values.fold(0.0, (s, v) => s + v);
    final b = StringBuffer(tr.billShareHeader(_fmtPay(total)));
    for (final p in _people) {
      b.write('\n$p: ${_fmtPay(shares[p] ?? 0)}');
    }
    if (mode == _PaidMode.other) {
      b.write('\n${tr.billSharePaidBy(_effectivePayer)}');
    }
    return b.toString();
  }

  Future<bool> _confirmDiscard() {
    final tr = S.of(context);
    return showConfirmDialog(
      context,
      title: tr.billDiscardTitle,
      message: tr.billDiscardBody,
      cancelLabel: tr.txAfKeepEditing,
      confirmLabel: tr.txAfDiscard,
    );
  }

  Future<void> _pickPayer() async {
    final tr = S.of(context);
    final mode = _effectiveMode;
    final payer = _effectivePayer;
    // One line per choice: the bottom bar already says what it means
    // ("They owe you…", "You owe Sam…").
    Widget? check(bool on) =>
        on ? Icon(AppIcons.check, color: AppColors.accent) : null;
    final choice = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: ListView(shrinkWrap: true, children: [
          SheetTitle(tr.billPaidBy),
          ListTile(
            leading: _Avatar(label: _initials(_me), color: _colorOf(_me)),
            title: Text(tr.billYou),
            trailing: check(mode == _PaidMode.me),
            onTap: () => Navigator.pop(ctx, 'me'),
          ),
          for (final p in _others)
            ListTile(
              leading: _Avatar(label: _initials(p), color: _colorOf(p)),
              title: Text(p),
              trailing: check(mode == _PaidMode.other && payer == p),
              onTap: () => Navigator.pop(ctx, 'p:$p'),
            ),
          ListTile(
            leading:
                const SizedBox(width: 36, child: Icon(AppIcons.usersThree)),
            title: Text(tr.billEachOwn),
            subtitle: Text(tr.billPaidEachDesc),
            trailing: check(mode == _PaidMode.each),
            onTap: () => Navigator.pop(ctx, 'each'),
          ),
        ]),
      ),
    );
    if (choice == null || !mounted) return;
    setState(() {
      if (choice == 'me') {
        _paidMode = _PaidMode.me;
      } else if (choice == 'each') {
        _paidMode = _PaidMode.each;
      } else {
        _paidMode = _PaidMode.other;
        _payer = choice.substring(2);
      }
    });
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  Color _colorOf(String person) {
    if (person == _me) return AppColors.accent;
    final i = _people.indexOf(person);
    return _personColors[
        (i < 1 ? person.hashCode.abs() : i - 1) % _personColors.length];
  }

  String _initials(String person) {
    if (person == _me) return _me;
    final t = person.trim();
    return t.isEmpty ? '?' : t.characters.first.toUpperCase();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD — the body is one flat ListView (see the file header).
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final tr = S.of(context);
    if (_scanning) {
      return Scaffold(
        appBar: AppBar(title: Text(tr.billScreenTitle)),
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(tr.billScanning),
          ]),
        ),
      );
    }
    final shares = _shares();
    if (_reviewing) return _totalsPage(tr, shares);
    return PopScope(
      canPop: _isEmpty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_painting != null) {
          setState(() => _painting = null);
          return;
        }
        if (!await _confirmDiscard() || !mounted) return;
        this.context.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(tr.billScreenTitle),
          actions: [
            IconButton(
              tooltip: tr.billScanButton,
              onPressed: _scanReceipt,
              icon: const Icon(AppIcons.camera),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            _billCard(tr),
            const SizedBox(height: Spacing.sectionGap),
            SectionHeader(
              tr.billWhosIn,
              trailing: _ModeSwitch(
                evenly: _mode == _SplitMode.evenly,
                evenlyLabel: tr.billEvenly,
                byItemLabel: tr.billByItem,
                onChanged: (evenly) =>
                    _setMode(evenly ? _SplitMode.evenly : _SplitMode.byItem),
              ),
            ),
            const SizedBox(height: Spacing.headerToCard),
            if (_mode == _SplitMode.evenly) ...[
              _peopleCard(tr, _payShares(shares)),
              if (_people.length > 1) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 4),
                  child: Text(tr.billByHandHint,
                      style: TextStyle(
                          fontSize: 12, color: AppColors.ts(context))),
                ),
              ],
            ] else ...[
              if (_painting != null)
                _paintingBanner(tr)
              else if (_people.length > 1 && _items.isNotEmpty)
                Padding(
                  padding:
                      const EdgeInsetsDirectional.only(start: 4, bottom: 8),
                  child: Text(tr.billPickPersonHint,
                      style: TextStyle(
                          fontSize: 12, color: AppColors.ts(context))),
                ),
              if (_items.isNotEmpty) ...[
                _itemsCard(tr),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    onPressed: _editItem,
                    icon: const Icon(AppIcons.plus, size: 18),
                    label: Text(tr.billAddItem),
                  ),
                ),
              ] else
                // No items yet: read them off the receipt, or type them.
                Row(children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _scanReceipt,
                      icon: const Icon(AppIcons.camera, size: 18),
                      label: Text(tr.billScanButton),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _editItem,
                      icon: const Icon(AppIcons.plus, size: 18),
                      label: Text(tr.billAddItem),
                    ),
                  ),
                ]),
              ..._receiptCheck(tr),
              ..._unpricedLines(tr),
            ],
          ],
        ),
        bottomNavigationBar: _editBar(tr, _payShares(shares)),
      ),
    );
  }

  // ─── Bill card ─────────────────────────────────────────────────────────────

  Widget _billCard(S tr) {
    final byItem = _mode == _SplitMode.byItem;
    final parts = <String>[
      if (_tipTotal != 0) tr.billPlusTip(_fmt(_tipTotal)),
      if (_taxTotal != 0) tr.billPlusTax(_fmt(_taxTotal)),
    ];
    final breakdown =
        parts.isEmpty ? null : '${_fmt(_subtotal)} ${parts.join(' ')}';
    final isCross = _billCurrency != _baseCurrency;
    final tipChoice = _tipIsAmount
        ? 'custom'
        : _tipPercent == 0
            ? '0'
            : _tipPercent.toStringAsFixed(0);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: AppColors.card(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(tr.billTotalLabel,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ts(context))),
            ),
            _Pill(
              onTap: _pickCurrency,
              label: _billCurrency,
              trailing: AppIcons.caretDown,
              height: 32,
            ),
          ]),
          Tappable(
            onTap: byItem ? null : _editTotal,
            borderRadius: BorderRadius.circular(RadiusTokens.sm),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  _fmt(_grand),
                  style: TextStyle(
                    fontFamily: TypographyTokens.displayFamily,
                    fontWeight: FontWeight.w800,
                    fontSize: kHeroAmountSize,
                    letterSpacing: -1,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: _grand == 0
                        ? AppColors.th(context)
                        : AppColors.tp(context),
                  ),
                ),
              ),
            ),
          ),
          if (breakdown != null)
            Text(breakdown,
                style: TextStyle(fontSize: 13, color: AppColors.ts(context))),
          if (_currencyHint != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Tappable(
                onTap: () => _setBillCurrency(_currencyHint!),
                borderRadius: BorderRadius.circular(RadiusTokens.sm),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(children: [
                    Icon(AppIcons.arrowsLeftRight,
                        size: 16, color: AppColors.accentText(context)),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(tr.billCurrencyHint(_currencyHint!),
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accentText(context))),
                    ),
                  ]),
                ),
              ),
            ),
          if (isCross) ...[
            const SizedBox(height: 8),
            Row(children: [
              Text('1 ${_rateInverted ? _baseCurrency : _billCurrency} = ',
                  style: TextStyle(fontSize: 13, color: AppColors.ts(context))),
              SizedBox(
                width: 110,
                child: TextField(
                  controller: _rateCtrl,
                  decoration:
                      InputDecoration(hintText: tr.billRateHint, isDense: true),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: _onRateTyped,
                ),
              ),
              Text(' ${_rateInverted ? _billCurrency : _baseCurrency}',
                  style: TextStyle(fontSize: 13, color: AppColors.ts(context))),
              IconButton(
                onPressed: _swapRateDirection,
                icon: Icon(AppIcons.arrowsDownUp,
                    size: 18, color: AppColors.accent),
              ),
              const Spacer(),
              if ((_exchangeRate - 1.0).abs() >= 0.001 && _grand > 0)
                Flexible(
                  child: Text(
                    '≈ ${formatAmount(_toBase(_grand), currency: _baseCurrency)}',
                    overflow: TextOverflow.ellipsis,
                    style:
                        TextStyle(fontSize: 13, color: AppColors.ts(context)),
                  ),
                ),
            ]),
            // Everyone pays in the base currency (an LBP bill paid in USD).
            if (_canSplitInBase)
              Row(children: [
                Expanded(
                  child: Text(tr.billSplitInBase(_baseCurrency),
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.tp(context))),
                ),
                Switch(value: _splitInBase, onChanged: _toggleSplitInBase),
              ]),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 34,
                child: Text(tr.billTip,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ts(context))),
              ),
              for (final (value, label) in [
                ('0', tr.commonNone),
                ('10', '10%'),
                ('15', '15%'),
                (
                  'custom',
                  _tipIsAmount && _tipAmount > 0
                      ? _fmt(_tipAmount)
                      : tr.billTipCustom
                ),
              ])
                AppChip(
                  label: label,
                  selected: tipChoice == value,
                  onTap: () => _setTip(value),
                ),
            ],
          ),
          const SizedBox(height: 4),
          if (!_taxOn)
            TextButton.icon(
              onPressed: _editTax,
              style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: const Size(0, 36)),
              icon: const Icon(AppIcons.plus, size: 16),
              label: Text(tr.billAddTax),
            )
          else
            Row(children: [
              Expanded(
                child: Tappable(
                  onTap: _editTax,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      _taxIsAmount
                          ? '${tr.billAddTax} · ${_fmt(_taxAmount)}'
                          : '${tr.billAddTax} · ${formatNumber(_taxPercent)}% · ${_fmt(_taxTotal)}',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.tp(context)),
                    ),
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => setState(() {
                  _taxOn = false;
                  _fixed.clear();
                }),
                icon: Icon(AppIcons.x, size: 18, color: AppColors.th(context)),
              ),
            ]),
        ],
      ),
    );
  }

  // ─── Evenly: people and their shares ───────────────────────────────────────

  Widget _peopleCard(S tr, Map<String, double> shares) {
    final recent = _recentPeople;
    return Container(
      decoration: AppColors.card(context),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        for (final p in _people) ...[
          Tappable(
            onTap: () => _personActions(p),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 8, 8),
              child: Row(children: [
                _Avatar(label: _initials(p), color: _colorOf(p)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(p == _me ? tr.billYou : p,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                ),
                Tappable(
                  borderRadius: BorderRadius.circular(RadiusTokens.sm),
                  onTap: _people.length > 1 ? () => _setShare(p) : null,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Text(
                      _fmtPay(shares[p] ?? 0),
                      style: TextStyle(
                        fontFamily: TypographyTokens.displayFamily,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: _fixed.containsKey(p)
                            ? AppColors.accentText(context)
                            : AppColors.tp(context),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ),
          Divider(height: 1, indent: 64, color: AppColors.bd(context)),
        ],
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _Pill(
                onTap: _addPerson,
                icon: AppIcons.plus,
                label: tr.commonAdd,
                accent: true,
              ),
              if (recent.isNotEmpty)
                Text(tr.billRecent,
                    style:
                        TextStyle(fontSize: 12, color: AppColors.ts(context))),
              for (final r in recent)
                _Pill(onTap: () => _addPersonNamed(r), label: r),
            ],
          ),
        ),
      ]),
    );
  }

  // ─── By item ───────────────────────────────────────────────────────────────

  void _pickPainter(String p) {
    setState(() => _painting = _painting == p ? null : p);
    if (_painting == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _bannerKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut);
      }
    });
  }

  Widget _paintingBanner(S tr) {
    final p = _painting!;
    final c = _colorOf(p);
    return Container(
      key: _bannerKey,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsetsDirectional.fromSTEB(12, 6, 6, 6),
      decoration: BoxDecoration(
        color: AppColors.pastel(context, c, light: 0.82, dark: 0.72),
        borderRadius: BorderRadius.circular(RadiusTokens.md),
      ),
      child: Row(children: [
        _Avatar(label: _initials(p), color: c, size: 32),
        const SizedBox(width: 10),
        Expanded(
          child: Text(tr.billTapWhatHad(p == _me ? tr.billYou : p),
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ),
        TextButton(
          onPressed: () => setState(() => _painting = null),
          child: Text(tr.commonDone),
        ),
      ]),
    );
  }

  Widget _itemsCard(S tr) {
    final painting = _painting;
    return Container(
      decoration: AppColors.card(context),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        for (var i = 0; i < _items.length; i++) ...[
          if (i > 0)
            Divider(
                height: 1,
                indent: painting != null ? 52 : 16,
                color: AppColors.bd(context)),
          _itemRow(tr, _items[i], painting),
        ],
      ]),
    );
  }

  Widget _itemRow(S tr, _BillItem item, String? painting) {
    final owners = _owners(item);
    final everyone = owners.length == _people.length;
    final has = painting != null && owners.contains(painting);
    final each = owners.isEmpty ? 0.0 : item.amount / owners.length;
    final String sub;
    if (_people.length == 1) {
      sub = '';
    } else if (everyone) {
      sub = tr.billEveryoneEach(_fmt(each));
    } else if (owners.length == 1) {
      final o = owners.first;
      sub = tr.billOnly(o == _me ? tr.billYou : o);
    } else {
      sub = tr.billSharedEach(owners.length, _fmt(each));
    }
    final paintColor = painting == null ? null : _colorOf(painting);
    return Material(
      color: has
          ? AppColors.pastel(context, paintColor!, light: 0.92, dark: 0.82)
          : Colors.transparent,
      child: Tappable(
        onTap:
            painting != null ? () => _toggleItem(item) : () => _editItem(item),
        onLongPress: () => _editItem(item),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(children: [
            if (painting != null) ...[
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: has ? paintColor : null,
                  border: has
                      ? null
                      : Border.all(color: AppColors.th(context), width: 2),
                ),
                child: has
                    ? Icon(AppIcons.check,
                        size: 14, color: AppColors.inkOn(paintColor!))
                    : null,
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  if (sub.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Row(children: [
                      if (!everyone && owners.length > 1)
                        for (final o in owners.take(4))
                          Padding(
                            padding: const EdgeInsetsDirectional.only(end: 3),
                            child: _Avatar(
                                label: _initials(o),
                                color: _colorOf(o),
                                size: 20),
                          ),
                      if (!everyone && owners.length > 1)
                        const SizedBox(width: 3),
                      Flexible(
                        child: Text(sub,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 12, color: AppColors.ts(context))),
                      ),
                    ]),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _fmt(item.amount),
              style: TextStyle(
                fontFamily: TypographyTokens.displayFamily,
                fontWeight: FontWeight.w700,
                fontSize: 16,
                fontFeatures: const [FontFeature.tabularFigures()],
                color:
                    item.amount < 0 ? AppColors.healthy : AppColors.tp(context),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  /// Items vs the receipt's total (or the total typed before itemizing), so
  /// a missed or misread line shows.
  List<Widget> _receiptCheck(S tr) {
    final receipt =
        _ocr?.receiptTotal ?? (_subtotalEntered > 0 ? _subtotalEntered : null);
    if (receipt == null || _items.isEmpty) return const [];
    final items = _itemsTotal;
    final tax = _ocr?.taxTotal ?? 0;
    final matches = (items - receipt).abs() <= _tolerance ||
        (tax > 0 && (items + tax - receipt).abs() <= _tolerance);
    final color = matches ? AppColors.healthy : AppColors.caution;
    return [
      Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.pastel(context, color, light: 0.88, dark: 0.78),
          borderRadius: BorderRadius.circular(RadiusTokens.md),
        ),
        child: Row(children: [
          Icon(matches ? AppIcons.checkCircleFill : AppIcons.warningCircleFill,
              size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              matches
                  ? tr.billReceiptMatch(_fmt(receipt))
                  : tr.billReceiptDiff(_fmt(items), _fmt(receipt)),
              style: TextStyle(fontSize: 12.5, color: AppColors.tp(context)),
            ),
          ),
        ]),
      ),
    ];
  }

  /// Receipt lines read as an item but without a price: tap to add one.
  List<Widget> _unpricedLines(S tr) {
    final ocr = _ocr;
    if (ocr == null) return const [];
    final idx = [
      for (var i = 0; i < ocr.lines.length; i++)
        if (ocr.lines[i].kind == OcrLineKind.item &&
            !ocr.lines[i].hasPrice &&
            !_addedLines.contains(i))
          i,
    ];
    if (idx.isEmpty) return const [];
    return [
      const SizedBox(height: 8),
      Tappable(
        onTap: () => setState(() => _showUnpriced = !_showUnpriced),
        borderRadius: BorderRadius.circular(RadiusTokens.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(children: [
            Icon(_showUnpriced ? AppIcons.caretUp : AppIcons.caretDown,
                size: 16, color: AppColors.ts(context)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(tr.billUnpricedLines(idx.length),
                  style:
                      TextStyle(fontSize: 12.5, color: AppColors.ts(context))),
            ),
          ]),
        ),
      ),
      if (_showUnpriced)
        for (final i in idx)
          Tappable(
            onTap: () => _addUnpriced(i),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(26, 8, 4, 8),
              child: Row(children: [
                Expanded(
                  child: Text(ocr.lines[i].text,
                      style: TextStyle(
                          fontSize: 13, color: AppColors.tp(context))),
                ),
                Icon(AppIcons.plus, size: 16, color: AppColors.accent),
              ]),
            ),
          ),
    ];
  }

  // ─── Bottom bar ────────────────────────────────────────────────────────────

  /// The editing view's bar: the people chips (By item) and See totals.
  Widget _editBar(S tr, Map<String, double> shares) {
    return Material(
      color: AppColors.sf(context),
      elevation: 8,
      shadowColor: Theme.of(context).colorScheme.shadow,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(RadiusTokens.sheet))),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_mode == _SplitMode.byItem) ...[
                // Sized by its content (a fixed height overflowed at large
                // text sizes); scrolls sideways with many people.
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final p in _people)
                        _PersonChip(
                          label: _initials(p),
                          color: _colorOf(p),
                          amount: _fmtPay(shares[p] ?? 0),
                          selected: _painting == p,
                          semantics: p == _me ? tr.billYou : p,
                          onTap: () => _pickPainter(p),
                          onLongPress: () => _personActions(p),
                        ),
                      _PersonChip(
                        label: '+',
                        color: AppColors.ts(context),
                        amount: tr.commonAdd,
                        selected: false,
                        semantics: tr.billAddPerson,
                        onTap: _addPerson,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
              ],
              FilledButton(
                onPressed: _grand > 0
                    ? () => setState(() {
                          _painting = null;
                          _reviewing = true;
                        })
                    : null,
                child: Text(tr.billSeeTotals),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Totals page ───────────────────────────────────────────────────────────

  /// Review before saving — a flat ListView like the editing view.
  Widget _totalsPage(S tr, Map<String, double> billShares) {
    final shares = _payShares(billShares);
    // With and without the tip, in the currency people pay in.
    final tips = _payShares(_tipParts(billShares));
    final mode = _effectiveMode;
    final mine = shares[_me] ?? 0;
    final owedTotal = _others.fold(0.0, (s, p) => s + (shares[p] ?? 0));
    final payer = _effectivePayer;
    final accounts = ref.watch(accountsProvider).value ?? const <Account>[];
    final account = accounts.where((a) => a.id == _accountId).firstOrNull;
    final categories =
        ref.watch(categoriesProvider).value ?? const <Category>[];
    final category = categories.where((c) => c.id == _categoryId).firstOrNull;
    final cross = (_exchangeRate - 1.0).abs() >= 0.001 &&
        _billCurrency != _baseCurrency;

    final String? consequence = switch (mode) {
      _PaidMode.me when _others.length == 1 =>
        tr.billOwesYouOne(_others.first, _fmtPay(owedTotal)),
      _PaidMode.me => tr.billTheyOweYou(_fmtPay(owedTotal)),
      _PaidMode.other => tr.billYouOwe(payer, _fmtPay(mine)),
      _PaidMode.each => _others.isEmpty ? null : tr.billNobodyOwes,
    };
    final consequenceColor = switch (mode) {
      _PaidMode.me => AppColors.healthy,
      _PaidMode.other => AppColors.caution,
      _PaidMode.each => AppColors.ts(context),
    };
    final saveLabel = switch (mode) {
      // Money leaving the account: the bill's currency.
      // (the account is shown just above).
      _PaidMode.me => tr.billSaveAmount(_fmt(_grand)),
      _PaidMode.other => tr.billSaveOwe(payer, _fmtPay(mine)),
      _PaidMode.each => tr.billSaveShare(_fmt(billShares[_me] ?? 0)),
    };
    final labelStyle = TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.ts(context));
    final rate = roundRate(
        _rateInverted ? 1.0 / _exchangeRate : _exchangeRate);
    final rateNum =
        formatNumber(rate, decimals: rate >= 100 ? 0 : (rate >= 1 ? 2 : 6));
    final rateText = _rateInverted
        ? '1 $_baseCurrency = $rateNum $_billCurrency'
        : '1 $_billCurrency = $rateNum $_baseCurrency';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _reviewing = false);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(tr.billTotalsTitle),
          leading: IconButton(
            tooltip: tr.billEditSplit,
            icon: const Icon(AppIcons.arrowLeft),
            onPressed: () => setState(() => _reviewing = false),
          ),
        ),
        body: ListView(
          key: const PageStorageKey('bill-totals'),
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            // The bill, and the rate it was split at.
            Container(
              decoration: AppColors.card(context),
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr.billTotalLabel,
                      style: TextStyle(
                          fontSize: 14, color: AppColors.ts(context))),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(_fmt(_grand),
                        style: TextStyle(
                          fontFamily: TypographyTokens.displayFamily,
                          fontWeight: FontWeight.w800,
                          fontSize: 30,
                          color: AppColors.tp(context),
                        )),
                  ),
                  if (cross)
                    Text(
                        '≈ ${formatAmount(_toBase(_grand), currency: _baseCurrency)} · $rateText',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.ts(context))),
                  if (_tipTotal != 0 || _taxTotal != 0) ...[
                    const SizedBox(height: 8),
                    _BreakdownRow(tr.billBeforeTipLabel, _fmt(_subtotal)),
                    if (_taxTotal != 0)
                      _BreakdownRow(tr.billTaxLabel, _fmt(_taxTotal)),
                    if (_tipTotal != 0)
                      _BreakdownRow(tr.billTip, _fmt(_tipTotal)),
                  ],
                  if (_canSplitInBase)
                    Row(children: [
                      Expanded(
                        child: Text(tr.billSplitInBase(_baseCurrency),
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.tp(context))),
                      ),
                      Switch(
                          value: _splitInBase,
                          onChanged: _toggleSplitInBase),
                    ]),
                ],
              ),
            ),
            const SizedBox(height: Spacing.sectionGap),
            SectionHeader(tr.billTotalsEach),
            const SizedBox(height: Spacing.headerToCard),
            // Each person's amount, in the currency they pay in (and the
            // bill's under it when that differs).
            Container(
              decoration: AppColors.card(context),
              clipBehavior: Clip.antiAlias,
              child: Column(children: [
                for (final (i, p) in _people.indexed) ...[
                  if (i > 0)
                    Divider(height: 1, indent: 64, color: AppColors.bd(context)),
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 12),
                    // Name and amount on top; the tip split, then the bill-
                    // currency amount, each on a full-width line under them.
                    child: Row(children: [
                      _Avatar(label: _initials(p), color: _colorOf(p)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(children: [
                              Expanded(
                                child: Text(p == _me ? tr.billYou : p,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700)),
                              ),
                              const SizedBox(width: 8),
                              Text(_fmtPay(shares[p] ?? 0),
                                  style: TextStyle(
                                    fontFamily: TypographyTokens.displayFamily,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 20,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures()
                                    ],
                                    color: AppColors.tp(context),
                                  )),
                            ]),
                            // Without and with the tip.
                            if (_tipTotal != 0)
                              Text(
                                  tr.billBeforeTipLine(
                                      _fmtPay((shares[p] ?? 0) -
                                          (tips[p] ?? 0)),
                                      _fmtPay(tips[p] ?? 0)),
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.ts(context))),
                            if (_inBase)
                              Text(_fmt(billShares[p] ?? 0),
                                  textAlign: TextAlign.end,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.ts(context))),
                          ],
                        ),
                      ),
                    ]),
                  ),
                ],
              ]),
            ),
            const SizedBox(height: Spacing.sectionGap),
            // Who paid, and what that means; where it's recorded.
            Container(
              decoration: AppColors.card(context),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_others.isNotEmpty) ...[
                    Row(children: [
                      SizedBox(
                          width: 60,
                          child: Text(tr.billPaidBy, style: labelStyle)),
                      _Pill(
                        onTap: _pickPayer,
                        leading: mode == _PaidMode.each
                            ? null
                            : _Avatar(
                                label: _initials(
                                    mode == _PaidMode.me ? _me : payer),
                                color: _colorOf(
                                    mode == _PaidMode.me ? _me : payer),
                                size: 26),
                        label: switch (mode) {
                          _PaidMode.me => _me,
                          _PaidMode.other => payer,
                          _PaidMode.each => tr.billEachOwn,
                        },
                        trailing: AppIcons.caretDown,
                      ),
                    ]),
                    if (consequence != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(consequence,
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: consequenceColor)),
                      ),
                  ],
                  if (mode == _PaidMode.other)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(tr.billNothingLeaves(payer),
                          style: TextStyle(
                              fontSize: 12, color: AppColors.ts(context))),
                    )
                  else ...[
                    if (_others.isNotEmpty) const SizedBox(height: 12),
                    Text(tr.billFrom, style: labelStyle),
                    const SizedBox(height: 6),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      _Pill(
                        onTap: _pickAccount,
                        icon: AppIcons.wallet,
                        label: account?.name ?? tr.commonAccount,
                      ),
                      _Pill(
                          onTap: _pickCategory,
                          leading: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: category == null
                                  ? AppColors.th(context)
                                  : AppColors.fromHex(category.colorHex),
                            ),
                          ),
                          label: category?.name ?? tr.commonCategory,
                        ),
                    ]),
                  ],
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: Material(
          color: AppColors.sf(context),
          elevation: 8,
          shadowColor: Theme.of(context).colorScheme.shadow,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                  top: Radius.circular(RadiusTokens.sheet))),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton(
                    onPressed: _canSave ? _save : null,
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(saveLabel, maxLines: 1)),
                  ),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => setState(() => _reviewing = false),
                        icon: const Icon(AppIcons.pencilSimple, size: 18),
                        label: Text(tr.billEditSplit),
                      ),
                    ),
                    if (_others.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => SharePlus.instance.share(
                              ShareParams(
                                  text: _shareText(shares, mode))),
                          icon: const Icon(AppIcons.shareNetwork, size: 18),
                          label: Text(tr.billShareShort),
                        ),
                      ),
                    ],
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Small widgets ───────────────────────────────────────────────────────────

/// "Tip ........ LBP 485,000" under the bill on the totals page.
class _BreakdownRow extends StatelessWidget {
  final String label;
  final String amount;
  const _BreakdownRow(this.label, this.amount);

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontSize: 13, color: AppColors.ts(context));
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8, top: 2),
      child: Row(children: [
        Expanded(child: Text(label, style: style)),
        Text(amount, style: style),
      ]),
    );
  }
}

/// A person's initials on their pastel.
class _Avatar extends StatelessWidget {
  final String label;
  final Color color;
  final double size;
  const _Avatar({required this.label, required this.color, this.size = 36});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.pastel(context, color, light: 0.78, dark: 0.68),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.clip,
        style: TextStyle(
          fontSize: size * (label.length > 2 ? 0.3 : 0.38),
          fontWeight: FontWeight.w800,
          color: dark
              ? AppColors.lightenPastel(color, 0.35)
              : AppColors.darkenPastel(color, 0.35),
        ),
      ),
    );
  }
}

/// Tonal pill button: chips for currency, account, category, Add, recent
/// people.
class _Pill extends StatelessWidget {
  final VoidCallback onTap;
  final String label;
  final IconData? icon;
  final IconData? trailing;
  final Widget? leading;
  final double height;
  final bool accent;
  const _Pill({
    required this.onTap,
    required this.label,
    this.icon,
    this.trailing,
    this.leading,
    this.height = 36,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = accent ? AppColors.accentText(context) : AppColors.tp(context);
    return Material(
      color: AppColors.sfv(context),
      shape: const StadiumBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Container(
          height: height,
          padding: EdgeInsetsDirectional.fromSTEB(
              leading != null ? 5 : 12, 0, trailing != null ? 10 : 12, 0),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (leading != null) ...[leading!, const SizedBox(width: 6)],
            if (icon != null) ...[
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: fg)),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 4),
              Icon(trailing, size: 12, color: fg),
            ],
          ]),
        ),
      ),
    );
  }
}

/// Evenly | By item.
class _ModeSwitch extends StatelessWidget {
  final bool evenly;
  final String evenlyLabel;
  final String byItemLabel;
  final ValueChanged<bool> onChanged;
  const _ModeSwitch({
    required this.evenly,
    required this.evenlyLabel,
    required this.byItemLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    Widget seg(String label, bool on, bool value) => Semantics(
          selected: on,
          button: true,
          child: Tappable(
            borderRadius: BorderRadius.circular(RadiusTokens.pill),
            onTap: () => onChanged(value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                // In dark mode sf is darker than the track: lift it.
                color: !on
                    ? Colors.transparent
                    : Theme.of(context).brightness == Brightness.dark
                        ? AppColors.lightenPastel(AppColors.sfv(context), 0.12)
                        : AppColors.sf(context),
                borderRadius: BorderRadius.circular(RadiusTokens.pill),
                boxShadow: on ? AppColors.cardShadow(context) : null,
              ),
              child: Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: on ? FontWeight.w700 : FontWeight.w600,
                      color:
                          on ? AppColors.tp(context) : AppColors.ts(context))),
            ),
          ),
        );
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.sfv(context),
        borderRadius: BorderRadius.circular(RadiusTokens.pill),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        seg(evenlyLabel, evenly, true),
        seg(byItemLabel, !evenly, false),
      ]),
    );
  }
}

/// A person in the By-item strip: avatar + their share; picked = ringed.
class _PersonChip extends StatelessWidget {
  final String label;
  final Color color;
  final String amount;
  final bool selected;
  final String semantics;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  const _PersonChip({
    required this.label,
    required this.color,
    required this.amount,
    required this.selected,
    required this.semantics,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semantics,
      selected: selected,
      button: true,
      child: Tappable(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(RadiusTokens.md),
        // As wide as the share needs (LBP amounts are long), at least 72.
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 72, maxWidth: 150),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: selected ? color : Colors.transparent, width: 2),
                ),
                child: _Avatar(label: label, color: color, size: 36),
              ),
              const SizedBox(height: 2),
              Text(amount,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: TypographyTokens.displayFamily,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                    fontSize: 12.5,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: selected ? color : AppColors.tp(context),
                  )),
            ]),
          ),
        ),
      ),
    );
  }
}
