import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/capture/bank_alerts.dart';
import '../../core/capture/share_intake.dart';
import '../../core/database/app_database.dart';
import '../../core/engine/allocation_engine.dart';
import '../../core/engine/envelope_for_category.dart';
import '../../core/engine/period_engine.dart' show budgetPeriodFor;
import '../../core/providers/accounts_provider.dart';
import '../../core/providers/allocations_provider.dart';
import '../../core/providers/autofill_provider.dart';
import '../../core/providers/categories_provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/date_format_provider.dart';
import '../../core/providers/engine_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../core/providers/transactions_provider.dart';
import '../../core/providers/tx_colors_provider.dart';
import '../../core/services/autofill_service.dart';
import '../../core/services/last_used_service.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets/date_swipe.dart';
import '../templates/template_picker.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_icons.dart';
import '../../shared/theme/design_tokens.dart';
import '../../shared/utils/calendar_days.dart';
import '../../shared/utils/dispose_later.dart';
import '../../shared/utils/format_number.dart';
import '../../shared/utils/note_text.dart';
import '../../shared/utils/receipt_helper.dart';
import '../../shared/utils/save_errors.dart';
import '../../shared/widgets/calculator_amount_field.dart';
import '../../shared/widgets/category_icon.dart';
import '../../shared/widgets/sheet_title.dart';
import '../../shared/widgets/tappable.dart';
import '../allocations/move_money_sheet.dart';
import 'widgets/category_sheet.dart';
import 'widgets/save_feedback.dart';
import 'widgets/tx_ui.dart';

/// The one-screen add (Entry mode "One screen"): amount first with the
/// keypad open, a title field with one-tap recent suggestions, category /
/// account / date pills, and a card showing what the spending does to its
/// envelope before saving (Cover chips when it would overspend). Extras
/// (note, split, receipt, photo) sit in an always-visible row.
///
/// Split keeps the total and carves items out of it: the first item holds
/// what's left. It also edits ([editTransactionId]) and takes prefilled
/// lines, as long as they share one account and currency ([canTake]).
class QuickAddScreen extends ConsumerStatefulWidget {
  final String? initialType;
  final DateTime? initialDate;

  /// The note as stored: "title — note".
  final String? initialTitle;
  final String? editTransactionId;
  final List<Map<String, dynamic>>? editLines;
  final String? editFromAccountId;
  final String? editDestAccountId;

  /// Receipt filenames already attached (a shared photo).
  final List<String>? initialReceipts;

  /// A captured payment (shared, or a bank alert): see `captureSaved`.
  final Map<String, dynamic>? capture;
  const QuickAddScreen({
    super.key,
    this.initialType,
    this.initialDate,
    this.initialTitle,
    this.editTransactionId,
    this.editLines,
    this.editFromAccountId,
    this.editDestAccountId,
    this.initialReceipts,
    this.capture,
  });

  /// Built from the `/add-transaction` route extra.
  factory QuickAddScreen.fromExtra(Map<String, dynamic>? extra) =>
      QuickAddScreen(
        initialType: extra?['editType'] as String?,
        initialDate: extra?['editDate'] as DateTime?,
        initialTitle: extra?['editNote'] as String?,
        editTransactionId: extra?['editTransactionId'] as String?,
        editLines: extra?['editLines'] as List<Map<String, dynamic>>?,
        editFromAccountId: extra?['editFromAccountId'] as String?,
        editDestAccountId: extra?['editDestAccountId'] as String?,
        initialReceipts: extra?['editReceipts'] as List<String>?,
        capture: extra?['capture'] as Map<String, dynamic>?,
      );

  /// One account and one currency per transaction here; lines spread over
  /// several need the classic form.
  static bool canTake(Map<String, dynamic>? extra) {
    final lines = extra?['editLines'] as List<Map<String, dynamic>>?;
    if (lines == null || extra?['editType'] == 'transfer') return true;
    final accounts = lines.map((l) => l['accountId']).whereType<String>();
    final currencies = lines.map((l) => l['currency']).whereType<String>();
    return accounts.toSet().length <= 1 && currencies.toSet().length <= 1;
  }

  @override
  ConsumerState<QuickAddScreen> createState() => _QuickAddScreenState();
}

/// One split item. The first item's [expr] is unused: it holds the rest.
class _Item {
  String? categoryId;
  String expr;
  final String note;
  _Item({this.categoryId, this.expr = '', this.note = ''});
}

/// A recent transaction offered as a one-tap fill.
class _Suggestion {
  final String title;
  final String? categoryId;
  final String? accountId;
  final double? amount;
  final String? currency;
  const _Suggestion(this.title, this.categoryId, this.accountId, this.amount,
      this.currency);
}

class _QuickAddScreenState extends ConsumerState<QuickAddScreen> {
  late String _type;

  /// The keypad expression ("26×2"); operators + - × ÷.
  String _expr = '';

  /// The amount came from a suggestion or autofill: the first digit typed
  /// replaces it instead of appending.
  bool _prefilled = false;

  final _titleCtrl = TextEditingController();
  final _titleFocus = FocusNode();
  final _scroll = ScrollController();
  String? _categoryId;
  String? _accountId;

  /// [_accountId] is the last-used default, so autofill may replace it.
  bool _accountIsDefault = false;
  String? _destId;
  late DateTime _date;
  TimeOfDay _time = TimeOfDay.now();
  String _note = '';
  late List<String> _receipts = [...?widget.initialReceipts];

  /// Expense/income in a foreign account: account-currency units per 1 base.
  /// Transfer across currencies: destination units per 1 source unit.
  /// Null while unknown.
  double? _rate;
  bool _saving = false;

  /// Split items; empty when not split, else at least two.
  List<_Item> _items = [];

  /// What the keypad types into: 0 = the total, else that item.
  int _target = 0;

  bool _receiptsTouched = false;
  late final String _initialSignature;

  /// Editing: what the saved version already did, taken out of the
  /// "before" figures so it isn't counted twice. Envelope → currency →
  /// ledger sum; Ready to assign by currency; account → balance change.
  Map<String, Map<String, double>> _oldEnvelope = {};
  Map<String, double> _oldUnallocated = {};
  Map<String, double> _oldAccount = {};

  bool get _editing => widget.editTransactionId != null;
  bool get _split => _items.isNotEmpty;

  static const _ops = '+-×÷';

  // ── Derived ─────────────────────────────────────────────────────

  String get _baseCurrency =>
      ref.read(householdProvider).value?.baseCurrency ?? 'USD';

  Account? _account(String? id) {
    if (id == null) return null;
    final accounts = ref.read(accountsProvider).value ?? const <Account>[];
    return accounts.where((a) => a.id == id).firstOrNull;
  }

  String get _currency => _account(_accountId)?.currency ?? _baseCurrency;
  String get _destCurrency => _account(_destId)?.currency ?? _currency;

  bool get _needsRate => _type == 'transfer'
      ? _destId != null && _destCurrency != _currency
      : _currency != _baseCurrency;

  double get _amount => _value(_expr);

  /// [expr]'s value rounded to the account currency's minor units ("10÷3"
  /// is 3.33, not 3.333…); 0 while it can't be worked out ("50÷0").
  double _value(String expr) {
    final v = _eval(expr, currencyDecimals(_currency));
    return v.isFinite ? v : 0;
  }

  /// The total divides by zero: no amount, and the display keeps the sum.
  bool get _divByZero => !_eval(_expr, 2).isFinite;

  /// Item [i]'s amount; the first takes what the others leave of the total.
  double _itemAmount(int i) {
    if (i > 0) return _value(_items[i].expr);
    var rest = _amount;
    for (var j = 1; j < _items.length; j++) {
      rest -= _value(_items[j].expr);
    }
    return roundToDecimals(rest, currencyDecimals(_currency));
  }

  static bool _isMid(String e) {
    if (e.length < 2) return false;
    final body = e.substring(1);
    return body.contains(RegExp(r'[+\-×÷]')) && !_ops.contains(e[e.length - 1]);
  }

  bool get _midCalculation => _isMid(_expr);

  /// The expression the keypad edits.
  String get _active => _target > 0 ? _items[_target].expr : _expr;
  set _active(String v) {
    if (_target > 0) {
      _items[_target].expr = v;
    } else {
      _expr = v;
    }
  }

  /// Form state when it opened: leaving with changes asks first.
  String _signature() => [
        _type,
        _expr,
        _titleCtrl.text.trim(),
        _note,
        _categoryId,
        _saveDate.toIso8601String(),
        if (_editing) ...[_accountId, _destId],
        for (final i in _items) '${i.categoryId}/${i.expr}',
      ].join('|');

  bool get _dirty => _receiptsTouched || _signature() != _initialSignature;

  // ── Lifecycle ───────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _type = widget.initialType == 'income' || widget.initialType == 'transfer'
        ? widget.initialType!
        : 'expense';
    _date = widget.initialDate ?? DateTime.now();
    if (widget.initialDate != null) {
      _time = TimeOfDay.fromDateTime(widget.initialDate!);
    }
    final note = widget.initialTitle ?? '';
    final dash = note.indexOf(' — ');
    if (dash >= 0) {
      _titleCtrl.text = note.substring(0, dash);
      _note = note.substring(dash + 3);
    } else {
      _titleCtrl.text = note;
    }
    _initFromLines();
    _initialSignature = _signature();
    _titleFocus.addListener(() {
      if (!_titleFocus.hasFocus) _autofillFromTitle();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyAccountDefaults();
      if (_editing) {
        _loadEditState();
      } else if (_titleCtrl.text.isNotEmpty && _categoryId == null) {
        _autofillFromTitle();
      }
    });
  }

  /// Prefilled lines (edit, duplicate, template): one line fills the
  /// amount and category, several become split items.
  void _initFromLines() {
    if (_type == 'transfer') {
      _accountId = widget.editFromAccountId;
      _destId = widget.editDestAccountId;
    }
    final lines = widget.editLines ?? const <Map<String, dynamic>>[];
    if (lines.isEmpty) return;
    if (_type != 'transfer') {
      _accountId = lines
          .map((l) => l['accountId'])
          .whereType<String>()
          .firstOrNull;
    }
    final decimals = currencyDecimals(
        _account(_accountId)?.currency ?? lines.first['currency'] as String? ??
            _baseCurrency);
    final amounts = [for (final l in lines) (l['amount'] as num?)?.toDouble() ?? 0];
    final total = amounts.fold<double>(0, (a, b) => a + b);
    if (total > 0) _expr = _exprFor(total, decimals);
    _prefilled = lines.length == 1 && total > 0;
    if (lines.length == 1) {
      _categoryId = lines.first['categoryId'] as String?;
    } else {
      _items = [
        for (var i = 0; i < lines.length; i++)
          _Item(
            categoryId: lines[i]['categoryId'] as String?,
            expr: i == 0 ? '' : _exprFor(amounts[i], decimals),
            note: lines[i]['note'] as String? ?? '',
          ),
      ];
      _categoryId = _items.first.categoryId;
    }
    // Stored rate: base per account unit (transfer: destination per source).
    final r = (lines.first['exchangeRateToBase'] as num?)?.toDouble();
    if (r != null && r > 0 && (r - 1).abs() > 1e-9) {
      _rate = _type == 'transfer' ? r : 1 / r;
    }
  }

  /// An edit saves under a new id: carry the receipts over, and note what
  /// the saved version did to balances.
  Future<void> _loadEditState() async {
    try {
      final db = ref.read(databaseProvider);
      final id = widget.editTransactionId!;
      final tx = await db.transactionsDao.getById(id);
      final ledger = await (db.select(db.allocationLedger)
            ..where((l) => l.sourceTransactionId.equals(id)))
          .get();
      if (tx == null || !mounted) return;

      final envelope = <String, Map<String, double>>{};
      final unallocated = <String, double>{};
      final account = <String, double>{};
      void add(Map<String, double> m, String k, double v) =>
          m[k] = (m[k] ?? 0) + v;
      final accounts = ref.read(accountsProvider).value ?? const <Account>[];
      String curOf(String? accountId, String fallback) =>
          accounts.where((a) => a.id == accountId).firstOrNull?.currency ??
          fallback;

      final lines = widget.editLines ?? const <Map<String, dynamic>>[];
      if (tx.type == 'transfer') {
        final amount = (lines.firstOrNull?['amount'] as num?)?.toDouble() ??
            tx.amount;
        final r = tx.exchangeRateToBase > 0 ? tx.exchangeRateToBase : 1.0;
        final from = curOf(tx.accountId, tx.currency);
        final to = curOf(tx.destinationAccountId, from);
        final credit = from == to ? amount : amount * r;
        add(account, tx.accountId, -amount);
        add(unallocated, from, -amount);
        if (tx.destinationAccountId != null) {
          add(account, tx.destinationAccountId!, credit);
          add(unallocated, to, credit);
        }
      } else {
        final sign = tx.type == 'income' ? 1.0 : -1.0;
        for (final l in lines) {
          final amount = (l['amount'] as num?)?.toDouble() ?? 0;
          final acc = l['accountId'] as String? ?? tx.accountId;
          final cur = l['currency'] as String? ?? curOf(acc, tx.currency);
          add(account, acc, sign * amount);
          add(unallocated, cur, sign * amount);
        }
      }
      // Unallocated = accounts − envelopes.
      for (final e in ledger) {
        add(envelope.putIfAbsent(e.allocationId, () => {}), e.currency,
            e.amount);
        add(unallocated, e.currency, -e.amount);
      }

      final paths = parseReceiptPaths(tx.receiptPath);
      setState(() {
        _oldEnvelope = envelope;
        _oldUnallocated = unallocated;
        _oldAccount = account;
        if (paths.isNotEmpty) _receipts = [...paths, ..._receipts];
      });
    } catch (e) {
      debugPrint('[QuickAdd] Loading the edited transaction failed: $e');
    }
  }

  /// An envelope's balance without the transaction being edited.
  double _envBalance(AllocationWithBalance a, String cur) =>
      (a.balanceByCurrency[cur] ?? 0) -
      (_oldEnvelope[a.data.allocation.id]?[cur] ?? 0);

  @override
  void dispose() {
    _titleCtrl.dispose();
    _titleFocus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _applyAccountDefaults() async {
    try {
      final accounts = await ref.read(accountsProvider.future);
      if (!mounted || accounts.isEmpty) return;
      if (_type == 'transfer') {
        final pair = await LastUsedService.transferPair(accounts);
        if (!mounted) return;
        setState(() {
          _accountId ??= pair.from ?? accounts.first.id;
          final to = pair.to ??
              accounts.where((a) => a.id != _accountId).firstOrNull?.id;
          if (to != _accountId) _destId ??= to;
          _accountIsDefault = true;
        });
      } else if (_accountId == null) {
        final id = await LastUsedService.defaultAccount(accounts);
        if (!mounted || _accountId != null) return;
        setState(() {
          _accountId = id;
          _accountIsDefault = true;
        });
      }
      // A prefilled line brings its own rate.
      if (_rate == null) _refreshRate();
    } catch (e) {
      debugPrint('[QuickAdd] Account defaults failed: $e');
    }
  }

  /// Fetch the rate the current accounts need (cached live rates).
  Future<void> _refreshRate() async {
    if (!_needsRate) {
      if (_rate != null) setState(() => _rate = null);
      return;
    }
    final (from, to) = _type == 'transfer'
        ? (_currency, _destCurrency)
        : (_baseCurrency, _currency);
    try {
      final raw = await ref.read(fxServiceProvider).getRateWithCache(from, to);
      final rate = roundRate(raw);
      if (mounted && rate > 0) setState(() => _rate = rate);
    } catch (e) {
      debugPrint('[QuickAdd] Rate fetch failed: $e');
      if (mounted) setState(() => _rate = null);
    }
  }

  // ── Keypad ──────────────────────────────────────────────────────

  String get _currentOperand {
    final e = _active;
    final i = e.lastIndexOf(RegExp(r'[+\-×÷]'));
    return i < 0 ? e : e.substring(i + 1);
  }

  void _digit(String d) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_prefilled && _target == 0) {
        _expr = '';
        _prefilled = false;
      }
      final operand = _currentOperand;
      if (d == '.') {
        if (operand.contains('.')) return;
        if (currencyDecimals(_currency) == 0) return;
        _active += operand.isEmpty ? '0.' : '.';
        return;
      }
      if (operand.replaceAll('.', '').length >= 12) return;
      final dot = operand.indexOf('.');
      if (dot >= 0 && operand.length - dot - 1 >= currencyDecimals(_currency)) {
        return;
      }
      final e = _active;
      if (operand == '0') {
        _active = e.substring(0, e.length - 1) + d;
      } else {
        _active = e + d;
      }
    });
  }

  void _op(String op) {
    HapticFeedback.mediumImpact();
    setState(() {
      _prefilled = false;
      final e = _active;
      if (e.isEmpty) return;
      if (_ops.contains(e[e.length - 1])) {
        _active = e.substring(0, e.length - 1) + op;
      } else {
        _active = e + op;
      }
    });
  }

  void _backspace() {
    HapticFeedback.lightImpact();
    setState(() {
      _prefilled = false;
      final e = _active;
      if (e.isNotEmpty) _active = e.substring(0, e.length - 1);
    });
  }

  void _clear() {
    HapticFeedback.heavyImpact();
    setState(() {
      _prefilled = false;
      _active = '';
    });
  }

  /// Left-to-right, like the calculator sheet ("2+3×4" = 20), rounded to
  /// [decimals]. Dividing by zero gives NaN (no amount).
  static double _eval(String expr, int decimals) {
    var e = expr.replaceAll('×', '*').replaceAll('÷', '/');
    while (e.isNotEmpty && '+-*/'.contains(e[e.length - 1])) {
      e = e.substring(0, e.length - 1);
    }
    if (e.isEmpty) return 0;
    final parts = e.split(RegExp(r'(?=[+\-*/])|(?<=[+\-*/])'));
    double result = 0;
    var op = '+';
    for (final p in parts) {
      if ('+-*/'.contains(p)) {
        op = p;
        continue;
      }
      final n = double.tryParse(p) ?? 0;
      if (op == '/' && n == 0) return double.nan;
      result = switch (op) {
        '-' => result - n,
        '*' => result * n,
        '/' => result / n,
        _ => result + n,
      };
    }
    return roundToDecimals(result, decimals);
  }

  /// [v] as keypad input: no grouping, no trailing zeros.
  static String _exprFor(double v, int decimals) {
    var s = v.toStringAsFixed(decimals);
    if (s.contains('.')) {
      s = s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
    }
    return s;
  }

  void _setAmount(double v) {
    _expr = _exprFor(v, currencyDecimals(_currency));
    _prefilled = true;
  }

  // ── Fills ───────────────────────────────────────────────────────

  List<_Suggestion> _suggestions() {
    if (_type == 'transfer') return const [];
    final entries =
        ref.watch(transactionEntriesProvider).value ?? const <TransactionEntry>[];
    final query = _titleCtrl.text.trim().toLowerCase();
    final seen = <String>{};
    final out = <_Suggestion>[];
    // Entries are oldest first: walk from the newest.
    for (var i = entries.length - 1; i >= 0 && out.length < 8; i--) {
      final e = entries[i];
      if (e.tx.type != _type) continue;
      final full = visibleNote(e.tx.note).trim();
      final title = full.split(' — ').first.trim();
      if (title.isEmpty) continue;
      final key = title.toLowerCase();
      if (!seen.add(key)) continue;
      if (query.isNotEmpty && (key == query || !key.contains(query))) continue;
      final line = e.lines.length == 1 ? e.lines.first : null;
      out.add(_Suggestion(
        title,
        line?.categoryId ?? e.tx.categoryId,
        line?.accountId ?? e.tx.accountId,
        line?.amount,
        line?.currency,
      ));
    }
    return out;
  }

  void _applySuggestion(_Suggestion s) {
    HapticFeedback.selectionClick();
    // An amount the user typed stays, with its account (and currency).
    final typed = _amount > 0 && !_prefilled;
    final account = typed ? null : _account(s.accountId);
    setState(() {
      _titleCtrl.text = s.title;
      _titleCtrl.selection =
          TextSelection.collapsed(offset: _titleCtrl.text.length);
      if (s.categoryId != null && !_split) _categoryId = s.categoryId;
      if (account != null) {
        _accountId = account.id;
        _accountIsDefault = false;
      }
      if (!typed && s.amount != null && s.amount! > 0 &&
          s.currency == _currency && !_split) {
        _setAmount(s.amount!);
      }
    });
    _titleFocus.unfocus();
    _refreshRate();
  }

  void _autofillFromTitle() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty || _type == 'transfer' || _split) return;
    final settings = ref.read(autofillProvider);
    final fill = lookupAutofillByTitle(
      title: title,
      entries: ref.read(transactionEntriesProvider).value ?? const [],
      settings: settings,
    );
    if (!fill.hasData || !mounted) return;
    final canOverride = settings.overrideExisting;
    setState(() {
      if (fill.categoryId != null && (_categoryId == null || canOverride)) {
        _categoryId = fill.categoryId;
      }
      if (fill.accountId != null &&
          (_accountId == null || _accountIsDefault || canOverride)) {
        _accountId = fill.accountId;
        _accountIsDefault = false;
      }
      if (fill.amount != null && fill.amount! > 0 &&
          (_expr.isEmpty || canOverride)) {
        _setAmount(fill.amount!);
      }
    });
    _refreshRate();
  }

  void _autofillFromCategory(String categoryId) {
    final settings = ref.read(autofillProvider);
    final fill = lookupAutofill(
      categoryId: categoryId,
      entries: ref.read(transactionEntriesProvider).value ?? const [],
      settings: settings,
    );
    final canOverride = settings.overrideExisting;
    if (!fill.hasData) {
      final cats = ref.read(categoriesProvider).value ?? const <Category>[];
      final cat = cats.where((c) => c.id == categoryId).firstOrNull;
      if (cat?.defaultAccountId != null && (_accountId == null || _accountIsDefault)) {
        _accountId = cat!.defaultAccountId;
      }
      return;
    }
    if (fill.accountId != null &&
        (_accountId == null || _accountIsDefault || canOverride)) {
      _accountId = fill.accountId;
      _accountIsDefault = false;
    }
    if (fill.title != null &&
        (_titleCtrl.text.trim().isEmpty || canOverride)) {
      _titleCtrl.text = fill.title!;
    }
    if (fill.amount != null && fill.amount! > 0 &&
        (_expr.isEmpty || canOverride)) {
      _setAmount(fill.amount!);
    }
  }

  // ── Pickers ─────────────────────────────────────────────────────

  void _setType(String type) {
    if (type == _type) return;
    HapticFeedback.selectionClick();
    final cats = ref.read(categoriesProvider).value ?? const <Category>[];
    setState(() {
      _type = type;
      final cat = cats.where((c) => c.id == _categoryId).firstOrNull;
      if (type == 'transfer' || (cat != null && cat.transactionType != type)) {
        _categoryId = null;
      }
      if (type == 'transfer') {
        _items = [];
        _target = 0;
      }
    });
    if (type == 'transfer') _applyAccountDefaults();
    _refreshRate();
  }

  /// The category of the transaction, or of split item [item].
  Future<void> _pickCategory({int? item}) async {
    final categories = ref.read(categoriesProvider).value ?? const <Category>[];
    final householdId = ref.read(currentHouseholdIdProvider);
    final allocations = ref.read(allocationsProvider).value ?? const [];
    final envelopeInfo = <String, String>{
      for (final a in allocations)
        if (a.balanceByCurrency.entries.firstOrNull case final b?)
          a.data.allocation.id:
              '${a.data.allocation.name} — ${formatAmount(b.value, currency: b.key)}',
    };
    _titleFocus.unfocus();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CategorySheet(
        categories: categories,
        selectedId: item != null ? _items[item].categoryId : _categoryId,
        householdId: householdId,
        envelopeInfo: envelopeInfo,
        initialType: _type == 'income' ? 'income' : 'expense',
        recentIds: recentCategoryIds(
            ref.read(transactionEntriesProvider).value ?? const []),
        onSelected: (id, name, color, txType) {
          Navigator.of(ctx).pop();
          if (!mounted) return;
          setState(() {
            if (item != null) {
              _items[item].categoryId = id;
              if (item == 0) _categoryId = id;
              return;
            }
            _categoryId = id;
            if (txType == 'income' || txType == 'expense') _type = txType;
            _autofillFromCategory(id);
          });
          _refreshRate();
        },
        onCreated: (_) {},
      ),
    );
  }

  Future<void> _pickAccount({bool destination = false}) async {
    final tr = S.of(context);
    final accounts = ref.read(accountsProvider).value ?? const <Account>[];
    _titleFocus.unfocus();
    final picked = await showAccountPickerSheet(context,
        accounts: destination
            ? accounts.where((a) => a.id != _accountId).toList()
            : accounts,
        title: destination || _type == 'income'
            ? tr.txFormToAccount
            : tr.txFormFromAccount,
        selectedId: destination ? _destId : _accountId,
        addLabel: tr.txAfAddAccount);
    if (picked == null || !mounted) return;
    if (picked == kAddAccountPick) {
      context.push('/accounts/new');
      return;
    }
    setState(() {
      if (destination) {
        _destId = picked;
      } else {
        _accountId = picked;
        _accountIsDefault = false;
        if (_destId == picked) _destId = null;
      }
    });
    _refreshRate();
  }

  void _swapTransfer() {
    if (_destId == null) return;
    HapticFeedback.selectionClick();
    setState(() {
      final from = _accountId;
      _accountId = _destId;
      _destId = from;
    });
    _refreshRate();
  }

  Future<void> _pickWhen() async {
    final tr = S.of(context);
    _titleFocus.unfocus();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SheetTitle(tr.quickWhen),
            ListTile(
              leading: const Icon(AppIcons.calendarBlank),
              title: Text(tr.commonToday),
              trailing: calendarDaysBetween(today, _date) == 0
                  ? Icon(AppIcons.check, color: AppColors.accentText(ctx))
                  : null,
              onTap: () => Navigator.pop(ctx, 'today'),
            ),
            ListTile(
              leading: const Icon(AppIcons.calendarBlank),
              title: Text(tr.commonYesterday),
              trailing: calendarDaysBetween(today, _date) == -1
                  ? Icon(AppIcons.check, color: AppColors.accentText(ctx))
                  : null,
              onTap: () => Navigator.pop(ctx, 'yesterday'),
            ),
            ListTile(
              leading: const Icon(AppIcons.calendarDots),
              title: Text(tr.quickPickDate),
              onTap: () => Navigator.pop(ctx, 'pick'),
            ),
            ListTile(
              leading: const Icon(AppIcons.clock),
              title: Text(tr.quickTime),
              trailing: Text(_time.format(ctx),
                  style: TextStyle(color: AppColors.ts(ctx))),
              onTap: () => Navigator.pop(ctx, 'time'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!mounted || choice == null) return;
    switch (choice) {
      case 'today':
        setState(() => _date = today);
      case 'yesterday':
        setState(() => _date = today.subtract(const Duration(days: 1)));
      case 'pick':
        final d = await showDatePicker(
          context: context,
          initialDate: _date.isAfter(now) ? now : _date,
          firstDate: DateTime(2000),
          lastDate: now,
        );
        if (d != null && mounted) setState(() => _date = d);
      case 'time':
        final t = await showTimePicker(context: context, initialTime: _time);
        if (t != null && mounted) setState(() => _time = t);
    }
  }

  Future<void> _editNote() async {
    final tr = S.of(context);
    final ctrl = TextEditingController(text: _note);
    final result = await showDialog<String>(
      context: context,
      builder: (dCtx) => AlertDialog(
        scrollable: true,
        title: Text(tr.quickNoteTitle),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLines: 4,
          minLines: 2,
          maxLength: InputLimits.noteMaxLength,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(hintText: tr.txFormNoteHint),
        ),
        actions: [
          OutlinedButton(
            style: DialogButtons.outlined,
            onPressed: () => Navigator.pop(dCtx),
            child: Text(tr.commonCancel),
          ),
          FilledButton(
            style: DialogButtons.filled,
            onPressed: () => Navigator.pop(dCtx, ctrl.text),
            child: Text(tr.commonSave),
          ),
        ],
      ),
    );
    disposeAfterRouteAnimation(ctrl);
    if (result != null && mounted) setState(() => _note = result.trim());
  }

  Future<void> _addReceipt({required bool camera}) async {
    _titleFocus.unfocus();
    final files = await pickAndSaveReceipts(context, fromCamera: camera);
    if (files.isEmpty || !mounted) return;
    setState(() {
      _receipts = [..._receipts, ...files];
      _receiptsTouched = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(S.of(context).txFormReceiptAttached),
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _editRate() async {
    // Shown and edited as "1 X = big number" (89,500, not 0.0000112).
    final r = _rate;
    final inverted = r != null && r < 1;
    final shown = r == null ? 0.0 : (inverted ? 1 / r : r);
    final v = await showCalculatorSheet(context, shown);
    if (v == null || v <= 0 || !mounted) return;
    setState(() => _rate = inverted ? 1 / v : v);
  }

  /// Split: the typed total stays; the first item keeps the category and
  /// what's left, a new item is carved out of it. Tapping again adds one.
  void _openSplit() {
    if (!_split && _amount <= 0) {
      HapticFeedback.heavyImpact();
      _snack(S.of(context).quickSplitNeedsTotal);
      return;
    }
    HapticFeedback.selectionClick();
    _titleFocus.unfocus();
    setState(() {
      if (!_split) _items = [_Item(categoryId: _categoryId)];
      _items.add(_Item());
      _target = _items.length - 1;
      _prefilled = false;
    });
    // Bring the new item into view above the keypad.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(_scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    });
  }

  /// Its amount goes back to the first item; one item left ends the split.
  void _removeItem(int i) {
    HapticFeedback.selectionClick();
    setState(() {
      _items.removeAt(i);
      if (_items.length < 2) {
        _categoryId = _items.firstOrNull?.categoryId;
        _items = [];
        _target = 0;
      } else if (_target >= i) {
        _target = _target == i ? 0 : _target - 1;
      }
    });
  }

  // ── Cover ───────────────────────────────────────────────────────

  Future<void> _cover({
    required String toId,
    required String? fromId,
    required String fromName,
    required double amount,
    required String currency,
  }) async {
    final tr = S.of(context);
    final messenger = ScaffoldMessenger.of(context);
    HapticFeedback.mediumImpact();
    try {
      await ref.read(allocationEngineProvider).moveMoney(
            fromAllocationId: fromId,
            toAllocationId: toId,
            amount: amount,
            currency: currency,
          );
      messenger.showSnackBar(SnackBar(
        content: Text(tr.quickCovered(
            formatAmount(amount, currency: currency), fromName)),
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      debugPrint('[QuickAdd] Cover failed: $e');
      messenger.showSnackBar(SnackBar(
        content: Text(tr.commonSomethingWentWrong),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  // ── Save ────────────────────────────────────────────────────────

  DateTime get _saveDate =>
      DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);

  void _snack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(text),
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<Transaction?> _findDuplicate(double amount) async {
    if (_categoryId == null) return null;
    final entries = ref.read(transactionEntriesProvider).value ?? const [];
    for (final e in entries) {
      if (calendarDaysBetween(e.tx.createdAt.toLocal(), _date) != 0) continue;
      final sameAmount = (e.tx.amount - amount).abs() < 0.01 ||
          e.lines.any((l) => (l.amount - amount).abs() < 0.01);
      final sameCategory = e.tx.categoryId == _categoryId ||
          e.lines.any((l) => l.categoryId == _categoryId);
      if (sameAmount && sameCategory) return e.tx;
    }
    return null;
  }

  Future<void> _save({bool addAnother = false}) async {
    if (_saving) return;
    final tr = S.of(context);
    final amount = _amount;
    if (amount <= 0) {
      HapticFeedback.heavyImpact();
      return;
    }
    if (_split && _itemAmount(0) < -0.005) {
      HapticFeedback.heavyImpact();
      _snack(tr.quickItemsOverTotal(
          formatAmount(-_itemAmount(0), currency: _currency)));
      return;
    }
    if (amount > InputLimits.maxAmount) {
      HapticFeedback.heavyImpact();
      _snack(tr.txAmountTooLarge(
          formatAmount(InputLimits.maxAmount, currency: _currency)));
      return;
    }
    if (_accountId == null) {
      _snack(tr.txAfPleaseSelectAccount);
      return;
    }
    if (_type == 'transfer' && (_destId == null || _destId == _accountId)) {
      _snack(tr.txAfPleaseSelectDest);
      return;
    }
    if (_needsRate && (_rate == null || _rate! <= 0)) {
      _snack(tr.quickSetRate);
      _editRate();
      return;
    }
    if (_type != 'transfer' && !_split && !_editing) {
      final dup = await _findDuplicate(amount);
      if (dup != null && mounted) {
        if (!await confirmDuplicateTransaction(context, dup)) return;
      }
    }
    if (!mounted) return;

    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null) return;
    setState(() => _saving = true);
    HapticFeedback.mediumImpact();

    final title = _titleCtrl.text.trim();
    final note = title.isNotEmpty && _note.isNotEmpty
        ? '$title — $_note'
        : (title.isNotEmpty ? title : _note);
    final engine = ref.read(allocationEngineProvider);
    final db = ref.read(databaseProvider);
    try {
      final String txId;
      if (_type == 'transfer') {
        txId = await engine.recordTransfer(
          householdId: householdId,
          fromAccountId: _accountId!,
          toAccountId: _destId!,
          amount: amount,
          currency: _currency,
          exchangeRateToBase: _needsRate ? _rate! : 1.0,
          createdBy: 'user',
          deviceId: 'local',
          note: note,
          date: _saveDate,
          rateGot: true,
          editing: widget.editTransactionId,
        );
        LastUsedService.rememberTransfer(_accountId!, _destId!);
      } else {
        txId = await engine.recordTransaction(
          householdId: householdId,
          accountId: _accountId!,
          type: _type,
          lines: [
            for (final (i, item) in (_split ? _items : [_Item()]).indexed)
              if (!_split || _itemAmount(i) > 0.005)
                TxLine(
                  amount: _split ? _itemAmount(i) : amount,
                  currency: _currency,
                  categoryId: _split ? item.categoryId : _categoryId,
                  accountId: _accountId,
                  exchangeRateToBase: _needsRate ? 1 / _rate! : 1.0,
                  note: item.note,
                ),
          ],
          baseCurrency: _baseCurrency,
          note: note,
          date: _saveDate,
          editing: widget.editTransactionId,
        );
        LastUsedService.rememberAccount(_accountId!);
      }
      // A captured payment: learn its shop, clear its alert.
      if (widget.capture != null && _type != 'transfer') {
        try {
          await captureSaved(db,
              householdId: householdId,
              capture: widget.capture!,
              amount: amount,
              categoryId: _split ? _items.first.categoryId : _categoryId,
              accountId: _accountId);
          ref.invalidate(alertInboxProvider);
        } catch (e) {
          debugPrint('[QuickAdd] Capture follow-up failed: $e');
        }
      }
      if (_receipts.isNotEmpty) {
        try {
          await (db.update(db.transactions)..where((t) => t.id.equals(txId)))
              .write(TransactionsCompanion(
                  receiptPath: Value(encodeReceiptPaths(_receipts))));
        } catch (e) {
          debugPrint('[QuickAdd] Saving receipts failed: $e');
        }
      }

      EnvelopeFeedback? envelope;
      if (_type == 'expense') {
        try {
          envelope = await envelopeAfterSave(db, txId);
        } catch (e) {
          debugPrint('[QuickAdd] Envelope feedback failed: $e');
        }
      }
      if (!mounted) return;
      final text = envelope?.message(tr) ?? tr.txFormSaved;
      final coverId = envelope?.overspent == true ? envelope!.allocationId : null;
      final messenger = ScaffoldMessenger.of(context);
      final nav = GoRouter.of(context);
      final snack = SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        persist: false,
        action: coverId != null
            ? SnackBarAction(
                label: tr.allocCoverButton,
                onPressed: () =>
                    nav.push('/allocations/$coverId', extra: {'cover': true}),
              )
            : null,
      );
      messenger.clearSnackBars();
      if (addAnother) {
        setState(() {
          _expr = '';
          _prefilled = false;
          _titleCtrl.clear();
          _note = '';
          _receipts = [];
          _receiptsTouched = false;
          _categoryId = null;
          _items = [];
          _target = 0;
          _saving = false;
        });
        messenger.showSnackBar(snack);
      } else {
        context.pop(txId);
        messenger.showSnackBar(snack);
      }
    } catch (e) {
      debugPrint('[QuickAdd] Save failed: $e');
      if (mounted) {
        setState(() => _saving = false);
        _snack(txSaveErrorText(tr, e));
      }
    }
  }

  // ── Build ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final tr = S.of(context);
    // Rebuild when these change (balances move while the screen is open).
    ref.watch(accountsProvider);
    ref.watch(categoriesProvider);
    final suggestions = _suggestions();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (!_dirty || await confirmDiscardTransaction(context)) {
          if (context.mounted) context.pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bg(context),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _header(tr),
              Expanded(
                child: ListView(
                  controller: _scroll,
                  padding: const EdgeInsets.only(bottom: 12),
                  children: [
                    _amountBlock(tr),
                    if (_type == 'transfer') ...[
                      _transferCard(tr),
                      _titleField(tr, compact: true),
                      _pillsRow(tr),
                      _infoCard(tr.quickTransferHint, AppIcons.info),
                    ] else ...[
                      _titleField(tr),
                      if (suggestions.isNotEmpty) _suggestionRow(suggestions),
                      _pillsRow(tr),
                      if (_split) _itemsCard(tr),
                      if (_type != 'expense')
                        _incomeCard(tr)
                      else if (!_split)
                        _envelopeCard(tr),
                    ],
                  ],
                ),
              ),
              // Pinned above the keypad so the extras never scroll away.
              if (_type != 'transfer') _extrasRow(tr),
              _keypad(tr),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(S tr) {
    final colors = ref.watch(txColorsProvider);
    Widget seg(String type, String label) {
      final selected = _type == type;
      return Tappable(
        onTap: () => _setType(type),
        borderRadius: BorderRadius.circular(RadiusTokens.pill),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? AppColors.sf(context) : Colors.transparent,
            borderRadius: BorderRadius.circular(RadiusTokens.pill),
            boxShadow: selected ? AppColors.cardShadow(context) : null,
          ),
          child: Text(label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: selected
                    ? (type == 'expense'
                        ? AppColors.tp(context)
                        : colors.forType(type))
                    : AppColors.ts(context),
              )),
        ),
      );
    }

    return SizedBox(
      height: 52,
      child: Row(
        children: [
          IconButton(
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            icon: const Icon(AppIcons.x),
            onPressed: () => Navigator.maybePop(context),
          ),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.sfv(context),
                  borderRadius: BorderRadius.circular(RadiusTokens.pill),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  seg('expense', tr.typeExpense),
                  seg('income', tr.typeIncome),
                  seg('transfer', tr.typeTransfer),
                ]),
              ),
            ),
          ),
          if (_editing)
            const SizedBox(width: 48)
          else
            IconButton(
              tooltip: tr.txFormUseTemplate,
              icon: const Icon(AppIcons.lightning),
              onPressed: () => pickTemplateIntoForm(context, ref,
                  date: DateTime(_date.year, _date.month, _date.day,
                      _time.hour, _time.minute)),
            ),
        ],
      ),
    );
  }

  Widget _amountBlock(S tr) {
    final colors = ref.watch(txColorsProvider);
    final hasValue = _expr.isNotEmpty;
    final mid = _midCalculation;
    final big = mid && !_divByZero
        ? formatForDisplay(_amount)
        : (hasValue ? formatCalcExpression(_expr) : '0');
    final color = !hasValue
        ? AppColors.th(context)
        : (_type == 'income' ? colors.income : AppColors.tp(context));
    final account = _account(_accountId);
    String rateText() {
      final r = _rate!;
      final (from, to) = _type == 'transfer'
          ? (_currency, _destCurrency)
          : (_baseCurrency, _currency);
      return r >= 1
          ? tr.quickRateLine(from, formatForDisplay(r), to)
          : tr.quickRateLine(to, formatForDisplay(1 / r), from);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
      child: Column(
        children: [
          SizedBox(
            height: 18,
            child: mid
                ? Text(formatCalcExpression(_expr),
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ts(context)))
                : null,
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${_type == 'income' && hasValue ? '+' : ''}$big',
              textDirection: TextDirection.ltr,
              style: TextStyle(
                fontFamily: TypographyTokens.displayFamily,
                fontSize: 48,
                height: 1.1,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              if (_type != 'transfer')
                _smallChip(
                  account == null
                      ? _currency
                      : '$_currency · ${account.name}',
                  onTap: () => _pickAccount(),
                  icon: account?.isTravel == true
                      ? AppIcons.airplane
                      : AppIcons.wallet,
                ),
              if (_needsRate)
                _smallChip(
                  _rate == null ? tr.quickSetRate : rateText(),
                  onTap: _editRate,
                  warn: _rate == null,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _smallChip(String text,
      {VoidCallback? onTap, bool warn = false, IconData? icon}) {
    final color = warn ? AppColors.caution : AppColors.ts(context);
    return Tappable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(RadiusTokens.md),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: warn
              ? AppColors.pastel(context, AppColors.caution)
              : AppColors.sfv(context),
          borderRadius: BorderRadius.circular(RadiusTokens.md),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700, color: color)),
          ),
          if (icon != null) ...[
            const SizedBox(width: 2),
            Icon(AppIcons.caretDown, size: 12, color: color),
          ],
        ]),
      ),
    );
  }

  Widget _titleField(S tr, {bool compact = false}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, compact ? 10 : 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _titleCtrl,
            focusNode: _titleFocus,
            maxLength: InputLimits.nameMaxLength,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _titleFocus.unfocus(),
            onTapOutside: (_) => _titleFocus.unfocus(),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              hintText: tr.quickWhatFor,
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              counterText: '',
              prefixIcon: const Icon(AppIcons.pencilSimple, size: 18),
            ),
          ),
          if (_note.isNotEmpty)
            Tappable(
              onTap: _editNote,
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(14, 8, 14, 0),
                child: Row(children: [
                  Icon(AppIcons.textAlignLeft, size: 14, color: AppColors.ts(context)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(_note,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 13, color: AppColors.ts(context))),
                  ),
                ]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _suggestionRow(List<_Suggestion> suggestions) {
    final cats = {
      for (final c in ref.watch(categoriesProvider).value ?? const <Category>[])
        c.id: c,
    };
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final s = suggestions[i];
          final cat = cats[s.categoryId];
          final label = s.amount != null && s.currency != null
              ? '${s.title} · ${formatAmount(s.amount!, currency: s.currency!)}'
              : s.title;
          return Tappable(
            onTap: () => _applySuggestion(s),
            borderRadius: BorderRadius.circular(RadiusTokens.pill),
            child: Container(
              padding: const EdgeInsetsDirectional.fromSTEB(6, 0, 12, 0),
              decoration: BoxDecoration(
                color: AppColors.sf(context),
                borderRadius: BorderRadius.circular(RadiusTokens.pill),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (cat != null)
                  CategoryIcon(
                    categoryName: cat.name,
                    emoji: cat.icon,
                    color: AppColors.fromHex(cat.colorHex),
                    size: 24,
                    circular: true,
                  )
                else
                  const SizedBox(width: 6),
                const SizedBox(width: 6),
                Text(label,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _pill({
    required Widget leading,
    required String label,
    required VoidCallback onTap,
    Color? fill,
    bool dashed = false,
    bool expand = false,
  }) {
    final child = Tappable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(RadiusTokens.pill),
      child: Container(
        height: 38,
        padding: const EdgeInsetsDirectional.fromSTEB(8, 0, 12, 0),
        decoration: BoxDecoration(
          color: dashed ? Colors.transparent : (fill ?? AppColors.sfv(context)),
          borderRadius: BorderRadius.circular(RadiusTokens.pill),
          border: dashed
              ? Border.all(color: AppColors.th(context), width: 1.5)
              : null,
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          leading,
          const SizedBox(width: 6),
          Flexible(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: dashed ? AppColors.ts(context) : AppColors.tp(context))),
          ),
        ]),
      ),
    );
    return expand ? Expanded(child: child) : child;
  }

  Widget _pillsRow(S tr) {
    final now = DateTime.now();
    final days = calendarDaysBetween(now, _date);
    final dateLabel = days == 0
        ? tr.commonToday
        : days == -1
            ? tr.commonYesterday
            : formatDate(_date);
    final datePill = DateSwipe(
      date: _date,
      lastDate: now,
      onChanged: (d) => setState(() => _date = d),
      child: _pill(
        leading: Icon(AppIcons.calendarBlank, size: 16, color: AppColors.tp(context)),
        label: dateLabel,
        onTap: _pickWhen,
      ),
    );
    if (_type == 'transfer') {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: Row(children: [datePill]),
      );
    }
    // The account is in the chip under the amount: the category gets the
    // room. Split items carry their own categories.
    if (_split) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: Row(children: [datePill]),
      );
    }
    final cats = ref.watch(categoriesProvider).value ?? const <Category>[];
    final cat = cats.where((c) => c.id == _categoryId).firstOrNull;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(children: [
        cat == null
            ? _pill(
                leading: Icon(AppIcons.plusCircle,
                    size: 18, color: AppColors.ts(context)),
                label: tr.commonCategory,
                onTap: _pickCategory,
                dashed: true,
                expand: true,
              )
            : _pill(
                leading: CategoryIcon(
                  categoryName: cat.name,
                  emoji: cat.icon,
                  color: AppColors.fromHex(cat.colorHex),
                  size: 28,
                  circular: true,
                ),
                label: cat.name,
                onTap: _pickCategory,
                fill: AppColors.pastel(context, AppColors.fromHex(cat.colorHex)),
                expand: true,
              ),
        const SizedBox(width: 8),
        datePill,
      ]),
    );
  }

  /// Split items: category, its envelope after this spending, amount. The
  /// selected row takes the keypad; the first holds the rest of the total.
  Widget _itemsCard(S tr) {
    final cats = {
      for (final c in ref.watch(categoriesProvider).value ?? const <Category>[])
        c.id: c,
    };
    final allocations =
        ref.watch(allocationsProvider).value ?? const <AllocationWithBalance>[];
    final cur = _currency;
    final colors = ref.watch(txColorsProvider);
    final bad = AppColors.overspent;
    // On a dark card plain red is unreadable: lift it.
    final badText = AppColors.isDark ? AppColors.lightenPastel(bad, 0.45) : bad;

    // Items in one envelope spend from the same balance.
    final envOf = <int, AllocationWithBalance>{};
    final spent = <String, double>{};
    if (_type == 'expense') {
      for (var i = 0; i < _items.length; i++) {
        final catId = _items[i].categoryId;
        if (catId == null) continue;
        final envId = envelopeForCategory(catId,
            categoriesById: cats,
            liveAllocations: allocations.map((a) => a.data.allocation));
        final env =
            allocations.where((a) => a.data.allocation.id == envId).firstOrNull;
        if (env == null) continue;
        envOf[i] = env;
        final amt = _itemAmount(i);
        spent[envId!] = (spent[envId] ?? 0) + (amt > 0 ? amt : 0);
      }
    }
    final rest = _itemAmount(0);
    final overTotal = rest < -0.005;

    Widget row(int i) {
      final item = _items[i];
      final cat = cats[item.categoryId];
      final selected = _target == i;
      final env = envOf[i];
      String? sub;
      var subBad = false;
      if (env != null) {
        final before = _envBalance(env, cur);
        final after = before - (spent[env.data.allocation.id] ?? 0);
        subBad = after < -0.005;
        final left = subBad
            ? tr.quickOverBy(formatAmount(-after, currency: cur))
            : tr.quickLeft(formatAmount(after, currency: cur));
        // Short enough for one line: the envelope's name only when it
        // isn't the category's.
        final envName = env.data.allocation.name;
        sub = envName == cat?.name
            ? capitalizedFirst(left)
            : '$envName · $left';
      } else if (item.note.isNotEmpty) {
        sub = item.note;
      } else if (i == 0) {
        sub = tr.quickSplitRest;
      }
      final e = item.expr;
      final typing =
          i > 0 && e.isNotEmpty && (_isMid(e) || _ops.contains(e[e.length - 1]));
      final amountText = typing
          ? formatCalcExpression(e)
          : formatAmount(_itemAmount(i), currency: cur);
      return Tappable(
        onTap: () {
          HapticFeedback.selectionClick();
          _titleFocus.unfocus();
          setState(() {
            _target = i;
            _prefilled = false;
          });
        },
        borderRadius: BorderRadius.circular(RadiusTokens.md),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsetsDirectional.fromSTEB(8, 6, 0, 6),
          decoration: BoxDecoration(
            color: selected ? AppColors.accentLight : Colors.transparent,
            borderRadius: BorderRadius.circular(RadiusTokens.md),
            border: Border.all(
                color: selected ? AppColors.accent : Colors.transparent,
                width: 1.5),
          ),
          child: Row(children: [
            Tappable(
              onTap: () => _pickCategory(item: i),
              borderRadius: BorderRadius.circular(RadiusTokens.pill),
              child: cat == null
                  ? Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.th(context), width: 1.5),
                      ),
                      child: Icon(AppIcons.plus,
                          size: 16, color: AppColors.ts(context)),
                    )
                  : CategoryIcon(
                      categoryName: cat.name,
                      emoji: cat.icon,
                      color: AppColors.fromHex(cat.colorHex),
                      size: 32,
                      circular: true,
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Tappable(
                    onTap: () => _pickCategory(item: i),
                    child: Text(cat?.name ?? tr.commonCategory,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: cat == null
                                ? AppColors.ts(context)
                                : AppColors.tp(context))),
                  ),
                  if (sub != null)
                    Text(sub,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: subBad ? badText : AppColors.ts(context))),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(amountText,
                textDirection: TextDirection.ltr,
                style: TextStyle(
                  fontFamily: TypographyTokens.displayFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: i == 0 && overTotal
                      ? badText
                      : _type == 'income'
                          ? colors.income
                          : AppColors.tp(context),
                )),
            if (i > 0)
              IconButton(
                tooltip: tr.txAfRemoveItem,
                visualDensity: VisualDensity.compact,
                iconSize: 16,
                icon: Icon(AppIcons.x, color: AppColors.ts(context)),
                onPressed: () => _removeItem(i),
              )
            else
              const SizedBox(width: 40),
          ]),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.all(6),
      decoration: AppColors.card(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < _items.length; i++) row(i),
          if (overTotal)
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(8, 6, 8, 2),
              child: Text(
                  tr.quickItemsOverTotal(formatAmount(-rest, currency: cur)),
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: badText)),
            ),
          Tappable(
            onTap: _openSplit,
            borderRadius: BorderRadius.circular(RadiusTokens.md),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Row(children: [
                Icon(AppIcons.plusCircle,
                    size: 18, color: AppColors.accentText(context)),
                const SizedBox(width: 8),
                Text(tr.txFormAddItem,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accentText(context))),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(String text, IconData icon) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.sfv(context),
        borderRadius: BorderRadius.circular(CardTokens.radius),
      ),
      child: Row(children: [
        Icon(icon, size: 18, color: AppColors.ts(context)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ts(context))),
        ),
      ]),
    );
  }

  Widget _envelopeCard(S tr) {
    if (_categoryId == null) {
      return _infoCard(tr.quickPickCategoryHint, AppIcons.envelopeSimple);
    }
    final cats = {
      for (final c in ref.watch(categoriesProvider).value ?? const <Category>[])
        c.id: c,
    };
    final allocations =
        ref.watch(allocationsProvider).value ?? const <AllocationWithBalance>[];
    final envId = envelopeForCategory(_categoryId!,
        categoriesById: cats,
        liveAllocations: allocations.map((a) => a.data.allocation));
    final env =
        allocations.where((a) => a.data.allocation.id == envId).firstOrNull;
    if (env == null) return _infoCard(tr.quickNotBudgeted, AppIcons.info);

    final cur = _currency;
    final before = _envBalance(env, cur);
    final amount = _amount;
    final after = before - amount;
    final over = after < -0.005;
    final name = env.data.allocation.name;

    // Daily pace until the budget period ends (only for today's spending).
    String? pace;
    final startDay = ref.watch(
        householdProvider.select((h) => h.value?.periodStartDay ?? 1));
    final period = budgetPeriodFor(startDay);
    final daysLeft = calendarDaysBetween(DateTime.now(), period.end);
    if (!over && after > 0 && daysLeft > 0 &&
        calendarDaysBetween(DateTime.now(), _date) == 0) {
      pace = tr.quickPerDay(daysLeft,
          formatAmount(after / daysLeft, currency: cur));
    }

    final bad = AppColors.overspent;
    // On the dark red card plain red is unreadable: lift it.
    final textColor = !over
        ? AppColors.tp(context)
        : (AppColors.isDark ? AppColors.lightenPastel(bad, 0.45) : bad);
    final spentShare = before > 0 ? (amount / before).clamp(0.0, 1.0) : 0.0;
    final leftShare = before > 0 ? (after / before).clamp(0.0, 1.0) : 0.0;

    // Cover suggestions: the fullest envelope that can take it alone, and
    // Ready to assign when it has enough.
    final shortfall = over ? -after : 0.0;
    final List<Widget> coverChips = [];
    if (over) {
      final donors = allocations
          .where((a) =>
              a.data.allocation.id != env.data.allocation.id &&
              _envBalance(a, cur) >= shortfall - 0.005)
          .toList()
        ..sort((a, b) => _envBalance(b, cur).compareTo(_envBalance(a, cur)));
      final donor = donors.firstOrNull;
      if (donor != null) {
        coverChips.add(_coverChip(
          '${donor.data.allocation.name} · ${formatAmount(_envBalance(donor, cur), currency: cur)}',
          () => _cover(
            toId: env.data.allocation.id,
            fromId: donor.data.allocation.id,
            fromName: donor.data.allocation.name,
            amount: shortfall,
            currency: cur,
          ),
        ));
      }
      final unallocated =
          ref.watch(unallocatedProvider).value ?? const <String, double>{};
      if ((unallocated[cur] ?? 0) - (_oldUnallocated[cur] ?? 0) >=
          shortfall - 0.005) {
        coverChips.add(_coverChip(
          tr.allocReadyToAssign,
          () => _cover(
            toId: env.data.allocation.id,
            fromId: null,
            fromName: tr.allocReadyToAssign,
            amount: shortfall,
            currency: cur,
          ),
        ));
      }
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: over
          ? BoxDecoration(
              color: AppColors.pastel(context, bad),
              borderRadius: BorderRadius.circular(CardTokens.radius),
            )
          : AppColors.card(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr.quickEnvelopeName(name),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ts(context))),
          const SizedBox(height: 2),
          Text.rich(
            TextSpan(children: [
              if (amount > 0)
                TextSpan(
                  text: '${formatAmount(before, currency: cur)} → ',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.ts(context)),
                ),
              TextSpan(
                text: over
                    ? tr.quickOverBy(formatAmount(-after, currency: cur))
                    : tr.quickLeft(formatAmount(after, currency: cur)),
                style: TextStyle(fontWeight: FontWeight.w800, color: textColor),
              ),
            ]),
            style: const TextStyle(fontSize: 15),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: over
                  ? ColoredBox(color: bad, child: const SizedBox.expand())
                  : Row(children: [
                      Expanded(
                        flex: (leftShare * 1000).round(),
                        child: ColoredBox(color: AppColors.accentBright),
                      ),
                      Expanded(
                        flex: (spentShare * 1000).round(),
                        child: ColoredBox(
                            color: AppColors.pastel(
                                context, AppColors.accentBright)),
                      ),
                      Expanded(
                        flex: ((1 - leftShare - spentShare).clamp(0.0, 1.0) *
                                1000)
                            .round(),
                        child: ColoredBox(color: AppColors.sfv(context)),
                      ),
                    ]),
            ),
          ),
          if (pace != null) ...[
            const SizedBox(height: 8),
            Text(pace,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ts(context))),
          ],
          if (over) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(tr.quickCoverFrom,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.tp(context))),
                ...coverChips,
                Tappable(
                  onTap: () => showMoveMoneySheet(context, ref,
                      toId: env.data.allocation.id,
                      currency: cur,
                      amount: shortfall,
                      cover: true),
                  borderRadius: BorderRadius.circular(RadiusTokens.pill),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                    child: Text(tr.quickCoverOther,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accentText(context))),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _coverChip(String label, VoidCallback onTap) {
    return Tappable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(RadiusTokens.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.sf(context),
          borderRadius: BorderRadius.circular(RadiusTokens.pill),
        ),
        child: Text(label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _incomeCard(S tr) {
    final cur = _currency;
    final unallocated =
        ref.watch(unallocatedProvider).value ?? const <String, double>{};
    final before = (unallocated[cur] ?? 0) - (_oldUnallocated[cur] ?? 0);
    final after = before + _amount;
    final ink = AppColors.inkOn(AppColors.accentBright);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accentBright,
        borderRadius: BorderRadius.circular(RadiusTokens.hero),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr.allocReadyToAssign,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: ink)),
          const SizedBox(height: 4),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 8,
            children: [
              if (_amount > 0)
                Text('${formatAmount(before, currency: cur)} →',
                    style: TextStyle(
                        fontFamily: TypographyTokens.displayFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: ink.withValues(alpha: 0.75))),
              Text(formatAmount(after, currency: cur),
                  style: TextStyle(
                      fontFamily: TypographyTokens.displayFamily,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: ink)),
            ],
          ),
          const SizedBox(height: 4),
          Text(tr.quickIncomeHint,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: ink)),
        ],
      ),
    );
  }

  Widget _transferCard(S tr) {
    final balances = {
      for (final a in ref.watch(accountsWithBalanceProvider).value ?? const [])
        a.account.id: a.balance,
    };
    final amount = _amount;
    final credit = _needsRate && _rate != null ? amount * _rate! : amount;

    Widget row(String label, String? id, double delta, bool destination) {
      final acc = _account(id);
      final raw = id == null ? null : balances[id];
      final bal = raw == null ? null : raw - (_oldAccount[id] ?? 0);
      return Tappable(
        onTap: () => _pickAccount(destination: destination),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(children: [
            Container(
              width: CategoryIconTokens.compactSize,
              height: CategoryIconTokens.compactSize,
              decoration: BoxDecoration(
                color: AppColors.pastel(context, AppColors.accent),
                shape: BoxShape.circle,
              ),
              child: Icon(
                  acc?.isTravel == true ? AppIcons.airplane : AppIcons.wallet,
                  size: 18,
                  color: AppColors.accentText(context)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 12, color: AppColors.ts(context))),
                  Text(acc?.name ?? tr.txAfPleaseSelectDest,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            if (acc != null && bal != null)
              Text.rich(
                TextSpan(children: [
                  if (amount > 0)
                    TextSpan(
                        text:
                            '${formatAmount(bal, currency: acc.currency)} → '),
                  TextSpan(
                    text: formatAmount(bal + delta, currency: acc.currency),
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.tp(context)),
                  ),
                ]),
                style: TextStyle(fontSize: 13, color: AppColors.ts(context)),
              ),
          ]),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: AppColors.card(context),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(children: [
            row(tr.quickFrom, _accountId, -amount, false),
            Divider(height: 1, color: AppColors.bd(context)),
            row(tr.quickTo, _destId, credit, true),
          ]),
          Material(
            color: AppColors.sfv(context),
            shape: const CircleBorder(),
            child: IconButton(
              tooltip: tr.txFormSwapAccounts,
              iconSize: 18,
              visualDensity: VisualDensity.compact,
              icon: const Icon(AppIcons.arrowsDownUp),
              onPressed: _swapTransfer,
            ),
          ),
        ],
      ),
    );
  }

  /// Small phones (Galaxy A02: ~750 dp tall) need the room for the
  /// category and date, so the pinned parts get a little shorter.
  bool get _shortScreen => MediaQuery.sizeOf(context).height < 800;

  Widget _extrasRow(S tr) {
    Widget btn(String label, IconData icon, VoidCallback onTap,
        {bool on = false, int badge = 0}) {
      return Expanded(
        child: Tappable(
          onTap: onTap,
          borderRadius: BorderRadius.circular(RadiusTokens.md),
          child: Container(
            height: _shortScreen ? 44 : 50,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: on ? AppColors.accentLight : AppColors.sf(context),
              borderRadius: BorderRadius.circular(RadiusTokens.md),
              border: on
                  ? Border.all(color: AppColors.accent, width: 1.5)
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(icon, size: 18, color: AppColors.accentText(context)),
                  if (badge > 0) ...[
                    const SizedBox(width: 4),
                    Container(
                      constraints: const BoxConstraints(minWidth: 16),
                      height: 16,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text('$badge',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.onAccent)),
                    ),
                  ],
                ]),
                const SizedBox(height: 2),
                // Shrinks to fit rather than cut ("Receipt" with five
                // buttons on a 360 dp phone, longer words in French).
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(label,
                        maxLines: 1,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(children: [
        btn(tr.quickNote, AppIcons.textAlignLeft, _editNote, on: _note.isNotEmpty),
        const SizedBox(width: 8),
        btn(tr.quickSplit, AppIcons.arrowsSplit, _openSplit, on: _split),
        const SizedBox(width: 8),
        btn(tr.quickReceipt, AppIcons.camera, () => _addReceipt(camera: true),
            badge: _receipts.length),
        const SizedBox(width: 8),
        btn(tr.quickPhoto, AppIcons.image, () => _addReceipt(camera: false)),
        // A new expense, with accounts in more than one currency: it can be
        // a payment with change in another currency instead.
        if (_type == 'expense' &&
            !_editing &&
            !_split &&
            (ref.read(accountsProvider).value ?? const <Account>[])
                    .map((a) => a.currency)
                    .toSet()
                    .length >
                1) ...[
          const SizedBox(width: 8),
          btn(tr.payChangeButton, AppIcons.coins,
              () => context.pushReplacement('/pay-with-change', extra: {
                    'title': _titleCtrl.text.trim(),
                    'categoryId': _categoryId,
                    'date': _saveDate,
                  })),
        ],
      ]),
    );
  }

  Widget _keypad(S tr) {
    Widget key(String label, VoidCallback onTap,
        {bool op = false, Widget? child, VoidCallback? onLongPress}) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Tappable(
            onTap: onTap,
            onLongPress: onLongPress,
            haptic: false,
            scaleFactor: 0.95,
            borderRadius: BorderRadius.circular(RadiusTokens.md + 2),
            child: Container(
              height: _shortScreen ? 40 : 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: op ? AppColors.accentLight : AppColors.sf(context),
                borderRadius: BorderRadius.circular(RadiusTokens.md + 2),
              ),
              child: child ??
                  Text(label,
                      style: TextStyle(
                        fontSize: op ? 22 : 24,
                        fontWeight: op ? FontWeight.w700 : FontWeight.w600,
                        color: op
                            ? AppColors.accentText(context)
                            : AppColors.tp(context),
                      )),
            ),
          ),
        ),
      );
    }

    Widget digit(String d) => key(d, () => _digit(d));
    Widget op(String o, [String? shown]) =>
        key(shown ?? o, () => _op(o), op: true);

    final amount = _amount;
    final canSave = amount > 0 && !_saving;
    final label = amount <= 0
        ? tr.txFormEnterAmount
        : (_type == 'transfer'
            ? tr.quickMoveAmount(formatAmount(amount, currency: _currency))
            : tr.quickSaveAmount(formatAmount(amount, currency: _currency)));

    return Container(
      decoration: BoxDecoration(
        color: AppColors.sfv(context),
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(RadiusTokens.sheet + 2)),
      ),
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Directionality(
              // Number pads read left to right in every language.
              textDirection: TextDirection.ltr,
              child: Column(children: [
                Row(children: [digit('7'), digit('8'), digit('9'), op('÷')]),
                Row(children: [digit('4'), digit('5'), digit('6'), op('×')]),
                Row(children: [digit('1'), digit('2'), digit('3'), op('-', '−')]),
                Row(children: [
                  key(decimalSeparatorChar, () => _digit('.')),
                  digit('0'),
                  key('', _backspace,
                      onLongPress: _clear,
                      child: Icon(AppIcons.backspace,
                          size: 22, color: AppColors.tp(context))),
                  op('+'),
                ]),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(3, 4, 3, 8),
              child: Row(children: [
                if (_type != 'transfer' && amount > 0 && !_editing) ...[
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 50),
                          padding: const EdgeInsets.symmetric(horizontal: 8)),
                      onPressed: canSave ? () => _save(addAnother: true) : null,
                      child: Text(tr.txFormSaveAndNew,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 50),
                        padding: const EdgeInsets.symmetric(horizontal: 12)),
                    onPressed: canSave ? _save : null,
                    child: _saving
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.onAccent))
                        // Shrink rather than cut long amounts (LBP 42,000,000).
                        : FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(label, maxLines: 1)),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
