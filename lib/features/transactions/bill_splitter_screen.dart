import 'dart:math' as math;

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../../core/database/app_database.dart';
import '../../core/fx/fx_service.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/date_format_provider.dart';
import '../../core/providers/engine_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../core/providers/objectives_provider.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/design_tokens.dart';
import '../../shared/utils/format_number.dart';
import '../../shared/utils/ocr_service.dart';
import '../../shared/widgets/calculator_amount_field.dart';
import '../../shared/widgets/currency_picker_field.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/section_header.dart';
import 'widgets/currency_sheet.dart' show kCurrencySymbols;
import '../../l10n/generated/app_localizations.dart';
import '../../shared/utils/dispose_later.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Bill Splitter — 3-step guided flow
//   Step 0: Add items (scan or manual)
//   Step 1: Split (assign people)
//   Step 2: Review & save
// ─────────────────────────────────────────────────────────────────────────────

class BillSplitterScreen extends ConsumerStatefulWidget {
  const BillSplitterScreen({super.key});

  @override
  ConsumerState<BillSplitterScreen> createState() => _BillSplitterScreenState();
}

class _BillSplitterScreenState extends ConsumerState<BillSplitterScreen> {
  int _step = 0; // 0=items, 1=split, 2=review

  // ── People ──
  // First person is always the user; named in the user's language below.
  final _people = <String>['Me'];
  bool _meNamed = false;
  final _personCtrl = TextEditingController();

  // ── Items ──
  final _items = <_BillItem>[];
  bool _splitEvenly = false;

  // ── Tip ──
  double _tipPercent = 0;
  double _tipAmount = 0;
  bool _tipIsAmount = false;
  bool _tipExpanded = false;

  // ── Currency ──
  late String _billCurrency;
  double _exchangeRate = 1.0;
  bool _rateInverted = true; // default: show base currency first (1 USD = X LBP)
  final _rateCtrl = TextEditingController();
  bool _currencyExpanded = false;

  // ── OCR ──
  bool _scanning = false;
  OcrResult? _ocrResult;

  /// Receipt lines already added as items.
  final _addedLines = <int>{};
  bool _showAllLines = true;

  // ── Tax & service: split in proportion to each person's items ──
  double _taxPercent = 0;
  double _taxAmount = 0;
  bool _taxIsAmount = true;
  bool _taxExpanded = false;

  // ── Who paid ──
  _PaidMode _paidMode = _PaidMode.me;
  String? _payer; // set when someone else paid

  String get _baseCurrency =>
      ref.read(householdProvider).value?.baseCurrency ?? 'USD';

  @override
  void initState() {
    super.initState();
    _billCurrency = ref.read(householdProvider).value?.baseCurrency ?? 'USD';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Name the user once, before anything is assigned to them.
    if (!_meNamed) {
      _meNamed = true;
      _people[0] = S.of(context).billMe;
    }
  }

  @override
  void dispose() {
    _personCtrl.dispose();
    _rateCtrl.dispose();
    super.dispose();
  }

  // ─── Navigation ───────────────────────────────────────────────────────────

  void _goToStep(int step) => setState(() {
    _step = step;
    _currencyExpanded = false; // reset expansion when changing steps
  });

  bool get _canProceedFromItems => _items.isNotEmpty;

  bool get _canProceedFromSplit {
    // Alone, every item is the user's; otherwise each needs someone.
    if (_splitEvenly || _people.length == 1) return true;
    return _items.every((i) => i.assignedTo.isNotEmpty);
  }

  // ─── People ───────────────────────────────────────────────────────────────

  void _addPerson() {
    final name = _personCtrl.text.trim();
    if (name.isEmpty || _people.contains(name)) return;
    setState(() => _people.add(name));
    _personCtrl.clear();
  }

  void _removePerson(String name) async {
    // The first person is the user — their share is what gets saved.
    if (_people.length <= 1 || name == _people.first) return;

    // Count items solely assigned to this person
    final soloItems = _items.where((item) =>
        item.assignedTo.contains(name) && item.assignedTo.length == 1).length;
    final others = _people.where((p) => p != name).toList();

    if (soloItems > 0 && others.isNotEmpty && mounted) {
      final tr = S.of(context);
      final result = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(tr.billRemovePersonTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tr.billRemovePersonContent(name, soloItems)),
              if (others.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(tr.billReassignTo, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                ...others.map((other) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(ctx, other),
                      child: Text(other),
                    ),
                  ),
                )),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(tr.commonCancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, '_delete'),
              child: Text(tr.billDeleteItems),
            ),
          ],
        ),
      );
      if (result == null || !mounted) return;

      // Snapshot state so a "Delete items" removal can be undone (the only
      // branch that discards data — reassign keeps the items).
      final peopleBackup = List<String>.from(_people);
      final itemsBackup = _items
          .map((it) => _BillItem(
                name: it.name,
                amount: it.amount,
                assignedTo: Set<String>.from(it.assignedTo),
                ocrLineIndex: it.ocrLineIndex,
              ))
          .toList();
      final selectionBackup = Set<int>.from(_addedLines);
      final payerBackup = _payer;

      setState(() {
        if (result != '_delete') {
          // Reassign solo items to the chosen person
          for (final item in _items) {
            if (item.assignedTo.contains(name) && item.assignedTo.length == 1) {
              item.assignedTo.add(result);
            }
          }
        }
        _people.remove(name);
        if (_payer == name) _payer = null;
        final toRemove = <int>[];
        for (var i = 0; i < _items.length; i++) {
          // Only items that were this person's alone go; items nobody has
          // been given yet stay.
          final had = _items[i].assignedTo.remove(name);
          if (had && _items[i].assignedTo.isEmpty) {
            if (_items[i].ocrLineIndex != null) {
              _addedLines.remove(_items[i].ocrLineIndex);
            }
            toRemove.add(i);
          }
        }
        for (var i = toRemove.length - 1; i >= 0; i--) {
          _items.removeAt(toRemove[i]);
        }
      });

      // Offer undo only when items were actually discarded.
      if (result == '_delete' && mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr.billPersonRemoved),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: tr.txUndoAction,
              onPressed: () => setState(() {
                _people
                  ..clear()
                  ..addAll(peopleBackup);
                _items
                  ..clear()
                  ..addAll(itemsBackup);
                _addedLines
                  ..clear()
                  ..addAll(selectionBackup);
                _payer = payerBackup;
              }),
            ),
          ),
        );
      }
    } else {
      // No solo items — just remove
      setState(() {
        _people.remove(name);
        if (_payer == name) _payer = null;
        for (final item in _items) {
          item.assignedTo.remove(name);
        }
      });
    }
  }

  // ─── Items ────────────────────────────────────────────────────────────────

  void _addManualItem() {
    setState(() => _items.add(
        _BillItem(name: '', amount: 0, assignedTo: {}, ocrLineIndex: null)));
  }

  // ─── OCR ──────────────────────────────────────────────────────────────────

  Future<void> _scanReceipt() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: Text(S.of(ctx).billTakePhoto),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: Text(S.of(ctx).billFromGallery),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

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
      return;
    }
    if (image == null) return;
    if (!mounted) return; // user may have left during camera/gallery

    setState(() => _scanning = true);

    final result = await OcrService.scanReceipt(image.path);

    if (mounted) {
      setState(() {
        _scanning = false;
        _ocrResult = result;
        _addedLines.clear();
        _items.clear();
      });
      if (result.lines.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(S.of(context).billNoText),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  void _onLineTapped(int lineIndex) {
    final line = _ocrResult!.lines[lineIndex];
    if (_addedLines.contains(lineIndex)) {
      setState(() {
        _addedLines.remove(lineIndex);
        _items.removeWhere((item) => item.ocrLineIndex == lineIndex);
      });
      return;
    }
    // Tax and total lines feed the tax field and the total check instead.
    if (line.kind == OcrLineKind.tax || line.kind == OcrLineKind.total) return;
    if (!line.hasPrice) {
      _promptAmountForLine(lineIndex, line);
      return;
    }
    _addLine(lineIndex, line);
  }

  Future<void> _promptAmountForLine(int lineIndex, OcrLine line) async {
    final amount = await showCalculatorSheet(context, 0);
    if (amount == null || amount <= 0 || !mounted) return;
    final fixedLine = OcrLine(
      text: line.text,
      boundingBox: line.boundingBox,
      parsedAmount: amount,
      parsedName: line.parsedName ?? line.text.trim(),
    );
    _ocrResult!.lines[lineIndex] = fixedLine;
    _addLine(lineIndex, fixedLine);
  }

  /// Adds a receipt line as an item. Items start unassigned: who had what is
  /// chosen in the next step.
  Future<void> _addLine(int lineIndex, OcrLine line) async {
    final qty = line.parsedQuantity;
    final amount = line.parsedAmount ?? 0;
    final name = line.parsedName ?? line.text;

    if (qty > 1) {
      final tr = S.of(context);
      final split = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(tr.billSplitQtyTitle(qty, name)),
          content: Text(tr.billSplitQtyContent(
              qty, formatAmount(amount / qty, currency: _billCurrency))),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(tr.billKeepAsOne)),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(tr.billSplit)),
          ],
        ),
      );
      if (!mounted || split == null) return;
      if (split) {
        final unitPrice = amount / qty;
        setState(() {
          _addedLines.add(lineIndex);
          for (var i = 0; i < qty; i++) {
            _items.add(_BillItem(
              name: '$name (${i + 1}/$qty)',
              amount: unitPrice,
              assignedTo: {},
              ocrLineIndex: lineIndex,
            ));
          }
        });
        return;
      }
    }

    setState(() {
      _addedLines.add(lineIndex);
      _items.add(_BillItem(
        name: qty > 1 ? '$name ×$qty' : name,
        amount: amount,
        assignedTo: {},
        ocrLineIndex: lineIndex,
      ));
    });
  }

  // ─── Calculations ─────────────────────────────────────────────────────────

  double get _itemsTotal => _items.fold(0.0, (s, i) => s + i.amount);

  double _taxTotalFor(double subtotal) =>
      _taxIsAmount ? _taxAmount : subtotal * _taxPercent / 100;

  /// Per-person breakdown: items, their share of tax & service (in proportion
  /// to their items) and of the tip, kept separate for the review screen.
  Map<String, ({double subtotal, double tax, double tip})>
      _calculateBreakdown() {
    final sub = <String, double>{for (final p in _people) p: 0};
    final subtotal = _itemsTotal;

    if (_splitEvenly && subtotal != 0 && _people.isNotEmpty) {
      final perPerson = subtotal / _people.length;
      for (final p in _people) {
        sub[p] = perPerson;
      }
    } else {
      for (final item in _items) {
        // Discounts are negative items and reduce the people they're given to.
        final owners =
            _people.length == 1 ? {_people.first} : item.assignedTo;
        if (owners.isEmpty || item.amount == 0) continue;
        final share = item.amount / owners.length;
        for (final person in owners) {
          sub[person] = (sub[person] ?? 0) + share;
        }
      }
    }

    final taxTotal = _taxTotalFor(subtotal);
    final tax = <String, double>{
      for (final p in _people)
        p: subtotal != 0 ? (sub[p] ?? 0) / subtotal * taxTotal : 0,
    };

    final tip = <String, double>{for (final p in _people) p: 0};
    if (_tipIsAmount && _tipAmount > 0 && _people.isNotEmpty) {
      // Fixed tip split evenly.
      final tipPerPerson = _tipAmount / _people.length;
      for (final p in _people) {
        tip[p] = tipPerPerson;
      }
    } else if (!_tipIsAmount && _tipPercent > 0) {
      // Percentage tip is proportional to each person's item subtotal.
      for (final p in _people) {
        tip[p] = (sub[p] ?? 0) * _tipPercent / 100;
      }
    }

    return {
      for (final p in _people)
        p: (subtotal: sub[p] ?? 0, tax: tax[p] ?? 0, tip: tip[p] ?? 0),
    };
  }

  /// Per-person totals (items + tax + tip), rounded to the currency's
  /// decimals so the shares add up to the rounded bill total exactly.
  Map<String, double> _calculateSplits() {
    final raw = {
      for (final e in _calculateBreakdown().entries)
        e.key: e.value.subtotal + e.value.tax + e.value.tip,
    };
    final factor = math.pow(10, currencyDecimals(_billCurrency)).toDouble();
    final target = (raw.values.fold(0.0, (s, v) => s + v) * factor).round();
    final units = {for (final e in raw.entries) e.key: (e.value * factor).floor()};
    var remainder = target - units.values.fold(0, (s, v) => s + v);
    // Hand the leftover cents to whoever lost the most to rounding down.
    final byFraction = raw.keys.toList()
      ..sort((a, b) => ((raw[b]! * factor) - units[b]!)
          .compareTo((raw[a]! * factor) - units[a]!));
    for (final p in byFraction) {
      if (remainder <= 0) break;
      units[p] = units[p]! + 1;
      remainder--;
    }
    return {for (final p in _people) p: (units[p] ?? 0) / factor};
  }

  double _toBase(double amount) {
    if (_billCurrency == _baseCurrency) return amount;
    if ((_exchangeRate - 1.0).abs() < 0.001) return amount;
    return amount * _exchangeRate;
  }

  // ─── Create Transaction ───────────────────────────────────────────────────

  // ─── Exchange rate ────────────────────────────────────────────────────────

  /// Switches the bill currency and fills the rate from the app's rates
  /// (live, else cached). The user can still type their own.
  Future<void> _setBillCurrency(String c) async {
    setState(() {
      _billCurrency = c;
      _exchangeRate = 1.0;
      _rateCtrl.clear();
    });
    if (c == _baseCurrency) return;
    final rate = await rateToBaseOrOne(ref.read(fxServiceProvider),
        ref.read(databaseProvider), c, _baseCurrency);
    if (!mounted || _billCurrency != c || rate == 1.0) return;
    setState(() {
      _exchangeRate = rate;
      _rateCtrl.text =
          formatRateForInput(roundRate(_rateInverted ? 1.0 / rate : rate));
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
          _rateCtrl.text = formatRateForInput(roundRate(
              _rateInverted ? 1.0 / _exchangeRate : _exchangeRate));
        }
      });

  /// A receipt that lists tax/service separately: when items + tax match the
  /// receipt total, fill the tax field (a tax-inclusive receipt is left alone).
  void _prefillTaxFromReceipt() {
    final ocr = _ocrResult;
    if (ocr == null || ocr.taxTotal == null || ocr.receiptTotal == null) return;
    if (_taxAmount > 0 || _taxPercent > 0) return;
    if ((_itemsTotal + ocr.taxTotal! - ocr.receiptTotal!).abs() > _tolerance) {
      return;
    }
    _taxIsAmount = true;
    _taxAmount = ocr.taxTotal!;
    _taxExpanded = true;
  }

  double get _tolerance =>
      1.5 / math.pow(10, currencyDecimals(_billCurrency)).toDouble();

  // ─── Save ─────────────────────────────────────────────────────────────────

  List<String> get _others => _people.skip(1).toList();

  /// Who paid when "someone else paid" is chosen (first other by default).
  String get _effectivePayer =>
      _payer ?? (_others.isNotEmpty ? _others.first : _people.first);

  _PaidMode get _mode => _others.isEmpty ? _PaidMode.each : _paidMode;

  bool get _canSave {
    final splits = _calculateSplits();
    final total = splits.values.fold(0.0, (s, v) => s + v);
    final mine = splits[_people.first] ?? 0;
    if (total <= 0) return false;
    return _mode == _PaidMode.me ? true : mine > 0;
  }

  Future<void> _save() async {
    final tr = S.of(context);
    final mode = _mode;
    final isCross = _billCurrency != _baseCurrency;
    final rateNotSet = isCross && (_exchangeRate - 1.0).abs() < 0.001;

    // Loans are kept in the bill's currency; only a recorded expense needs
    // a rate to the base currency.
    if (rateNotSet && mode != _PaidMode.other) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(tr.billRateNotSetTitle),
          content: Text(tr.billRateNotSetContent(_billCurrency)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(tr.billGoBackBtn)),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(tr.billContinueAnyway)),
          ],
        ),
      );
      if (proceed != true || !mounted) return;
    }

    final splits = _calculateSplits();
    final myShare = splits[_people.first] ?? 0;
    final total = splits.values.fold(0.0, (s, v) => s + v);
    final others = _others;
    final totalText = formatAmount(total, currency: _billCurrency);
    final note = others.isEmpty
        ? tr.billNoteTotal(totalText)
        : tr.billNoteSplitWith(others.join(', '), totalText);
    final rate = isCross ? _exchangeRate : 1.0;
    final messenger = ScaffoldMessenger.of(context);

    if (mode == _PaidMode.other) {
      // Nothing leaves the account now: track what the user owes the payer.
      final payer = _effectivePayer;
      final n = await _createLoans('borrowed', {payer: myShare});
      if (!mounted || n == 0) return;
      context.pop();
      messenger.showSnackBar(SnackBar(
        content: Text(tr.billOweCreated(
            payer, formatAmount(myShare, currency: _billCurrency))),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    // "I paid": the whole bill leaves the account — the user's share plus one
    // line per person. "Each paid": only the user's share.
    final lines = <Map<String, dynamic>>[
      if (myShare > 0)
        {
          'amount': myShare,
          'currency': _billCurrency,
          'exchangeRateToBase': rate,
        },
      if (mode == _PaidMode.me)
        for (final p in others)
          if ((splits[p] ?? 0) > 0)
            {
              'amount': splits[p],
              'currency': _billCurrency,
              'exchangeRateToBase': rate,
              'note': tr.billLinePart(p),
            },
    ];
    if (lines.isEmpty) return;

    final txId = await context.push<String?>('/add-transaction', extra: {
      'editType': 'expense',
      'editNote': '${tr.billNoteTitle} — $note',
      'editLines': lines,
    });
    // Not saved (form closed): stay on the bill so nothing is lost.
    if (txId == null || !mounted) return;

    var loans = 0;
    if (mode == _PaidMode.me) {
      loans = await _createLoans('lent', {
        for (final p in others)
          if ((splits[p] ?? 0) > 0) p: splits[p]!,
      });
    }
    if (!mounted) return;
    context.pop();
    if (loans > 0) {
      messenger.showSnackBar(SnackBar(
        content: Text(tr.billLoansCreated(loans)),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  /// One loan per person in Goals & Loans, in the bill's currency. Repayments
  /// are recorded from the loan (Record payment), like any other loan.
  Future<int> _createLoans(String direction, Map<String, double> amounts) async {
    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null) return 0;
    final db = ref.read(databaseProvider);
    final name = S.of(context).billLoanName(formatDate(DateTime.now()));
    var n = 0;
    try {
      for (final e in amounts.entries) {
        if (e.value <= 0) continue;
        await db.into(db.objectives).insert(ObjectivesCompanion.insert(
              id: const Uuid().v4(),
              householdId: householdId,
              name: name,
              type: 'loan',
              targetCurrency: _billCurrency,
              deviceId: 'local',
              targetAmount: Value(e.value),
              currentAmount: const Value(0),
              contactName: Value(e.key),
              direction: Value(direction),
              lastModified: Value(DateTime.now()),
            ));
        n++;
      }
      ref.invalidate(objectivesProvider);
    } catch (e) {
      debugPrint('[BillSplitter] creating loans failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(S.of(context).commonSomethingWentWrong),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
    return n;
  }

  /// Plain-text summary for a group chat.
  Future<void> _shareSplit() async {
    final tr = S.of(context);
    final splits = _calculateSplits();
    final total = splits.values.fold(0.0, (s, v) => s + v);
    final b = StringBuffer(
        tr.billShareHeader(formatAmount(total, currency: _billCurrency)));
    for (final p in _people) {
      b.write('\n$p: ${formatAmount(splits[p] ?? 0, currency: _billCurrency)}');
    }
    if (_mode == _PaidMode.other) {
      b.write('\n${tr.billSharePaidBy(_effectivePayer)}');
    }
    await SharePlus.instance.share(ShareParams(text: b.toString()));
  }

  Future<bool> _confirmDiscard() async {
    final tr = S.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr.billDiscardTitle),
        content: Text(tr.billDiscardBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(tr.commonCancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(tr.txAfDiscard)),
        ],
      ),
    );
    return ok == true;
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Color _personColor(String person) {
    const colors = [
      Color(0xFF6366F1), Color(0xFF10B981), Color(0xFFF59E0B),
      Color(0xFFEF4444), Color(0xFF8B5CF6), Color(0xFF06B6D4),
      Color(0xFFEC4899), Color(0xFFFF7043),
    ];
    final idx = _people.indexOf(person);
    return colors[idx >= 0 ? idx % colors.length : 0];
  }


  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD — single ListView, no Column/Expanded
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    if (_scanning) {
      return Scaffold(
        appBar: AppBar(title: Text(S.of(context).billTitle)),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(S.of(context).billScanning),
            ],
          ),
        ),
      );
    }

    final splits = _calculateSplits();
    final grandTotal = splits.values.fold(0.0, (s, v) => s + v);

    return PopScope(
      // Back goes to the previous step, and asks before throwing a bill away.
      canPop: _step == 0 && _items.isEmpty && _ocrResult == null,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_step > 0) {
          _goToStep(_step - 1);
          return;
        }
        if (!await _confirmDiscard() || !mounted) return;
        this.context.pop();
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).billTitle),
        actions: [
          if (_step == 0)
            IconButton(
              icon: const Icon(Icons.camera_alt_rounded),
              tooltip: S.of(context).billScanTooltip,
              onPressed: _scanReceipt,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_step == 0) ...[
            // Step instruction
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                S.of(context).billStep1Desc,
                style: TextStyle(fontSize: 13, color: AppColors.ts(context)),
              ),
            ),
            // Currency indicator — tap to change
            GestureDetector(
              onTap: () => setState(() => _currencyExpanded = !_currencyExpanded),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.sfv(context),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.payments_rounded, size: 16, color: AppColors.ts(context)),
                    const SizedBox(width: 6),
                    Text(S.of(context).billBillIn(_billCurrency),
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                            color: AppColors.tp(context))),
                    const SizedBox(width: 4),
                    Icon(Icons.edit_rounded, size: 12, color: AppColors.th(context)),
                  ],
                ),
              ),
            ),
            if (_currencyExpanded) ...[
              CurrencyPickerField(value: _billCurrency, label: S.of(context).billBillCurrency,
                onChanged: (c) {
                  setState(() => _currencyExpanded = false);
                  _setBillCurrency(c);
                }),
              const SizedBox(height: 12),
            ],
            // Show exchange rate inline when cross-currency
            if (_billCurrency != _baseCurrency) ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.pastel(context, AppColors.caution,
                      light: 0.88, dark: 0.8),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.caution.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(S.of(context).billExchangeRateTitle,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                            color: AppColors.caution)),
                    const SizedBox(height: 8),
                    Row(children: [
                      Text('1 ${_rateInverted ? _baseCurrency : _billCurrency} = ',
                          style: TextStyle(fontSize: 13, color: AppColors.ts(context))),
                      Expanded(child: TextField(controller: _rateCtrl,
                        decoration: InputDecoration(hintText: S.of(context).billRateHint, isDense: true,
                          filled: true, fillColor: AppColors.sfv(context),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none)),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: _onRateTyped)),
                      Text(' ${_rateInverted ? _billCurrency : _baseCurrency}',
                          style: TextStyle(fontSize: 13, color: AppColors.ts(context))),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _swapRateDirection,
                        child: Icon(Icons.swap_vert_rounded,
                            size: 20, color: AppColors.accent),
                      ),
                    ]),
                  ],
                ),
              ),
            ],
            if (_items.isEmpty && _ocrResult == null) ...[
              const SizedBox(height: 40),
              EmptyState(
                icon: Icons.receipt_long_rounded,
                title: S.of(context).billEmptyTitle,
                subtitle: S.of(context).billEmptySubtitle,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _scanReceipt,
                icon: const Icon(Icons.camera_alt_rounded, size: 20),
                label: Text(S.of(context).billScanButton),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _addManualItem,
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: Text(S.of(context).billAddManually),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ] else ...[
              if (_ocrResult != null) ...[
                _buildDetectedLinesList(),
                const SizedBox(height: 12),
              ],
              for (var i = 0; i < _items.length; i++) _buildItemTile(i),
              if (_ocrResult?.receiptTotal != null && _items.isNotEmpty)
                _buildReceiptCheck(),
              TextButton.icon(
                onPressed: _addManualItem,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(S.of(context).billAddItem),
              ),
            ],
          ],
          if (_step == 1) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                S.of(context).billStep2Desc,
                style: TextStyle(fontSize: 13, color: AppColors.ts(context)),
              ),
            ),
            _buildPeopleSection(),
            const SizedBox(height: 12),
            _buildSplitEvenlyToggle(),
            const SizedBox(height: 12),
            if (!_splitEvenly && _people.length > 1) ...[
              SectionHeader(S.of(context).billAssignItems),
              const SizedBox(height: 8),
              for (var i = 0; i < _items.length; i++) _buildAssignableItem(i),
            ],
          ],
          if (_step == 2) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                S.of(context).billStep3Desc,
                style: TextStyle(fontSize: 13, color: AppColors.ts(context)),
              ),
            ),
            _buildSummaryCard(),
            const SizedBox(height: 10),
            if (_others.isNotEmpty) ...[
              _buildWhoPaidSection(),
              const SizedBox(height: 10),
            ],
            _buildTaxSection(),
            const SizedBox(height: 8),
            _buildTipSection(),
            const SizedBox(height: 8),
            _buildCurrencySection(),
            if (_others.isNotEmpty) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: grandTotal > 0 ? _shareSplit : null,
                icon: const Icon(Icons.share_rounded, size: 18),
                label: Text(S.of(context).billShare),
              ),
            ],
          ],
          // Nav buttons at bottom
          const SizedBox(height: 24),
          Row(
            children: [
              if (_step > 0) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _goToStep(_step - 1),
                    child: Text(S.of(context).commonBack),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: _step == 2
                    ? FilledButton.icon(
                        onPressed: _canSave ? _save : null,
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: Text(S.of(context).commonSave),
                      )
                    : FilledButton(
                        onPressed: _step == 0
                            ? (_canProceedFromItems
                                ? () {
                                    _prefillTaxFromReceipt();
                                    _goToStep(1);
                                  }
                                : null)
                            : (_canProceedFromSplit ? () => _goToStep(2) : null),
                        child: Text(S.of(context).commonNext),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    ),
    );
  }

  Widget _buildItemTile(int index) {
    final item = _items[index];
    // Every item (including scanned ones) is editable. ObjectKey keeps each
    // field's text bound to its item when the list changes (e.g. after a split).
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsetsDirectional.fromSTEB(12, 4, 4, 4),
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.circular(10),
        boxShadow: AppColors.cardShadow(context),
      ),
      child: Row(
        children: [
          if (item.assignedTo.isNotEmpty)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsetsDirectional.only(end: 10),
              decoration: BoxDecoration(
                color: _personColor(item.assignedTo.first),
                shape: BoxShape.circle,
              ),
            ),
          Expanded(
            child: TextFormField(
              key: ValueKey('name_${identityHashCode(item)}'),
              initialValue: item.name,
              decoration: InputDecoration(
                hintText: S.of(context).billItemName,
                isDense: true,
                border: InputBorder.none,
        filled: false,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(fontSize: 13),
              onChanged: (v) => item.name = v,
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () async {
              final v = await showCalculatorSheet(context, item.amount.abs());
              if (v == null || !mounted) return;
              // A discount stays negative when its amount is edited.
              setState(() => item.amount = item.amount < 0 ? -v : v);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: Text(
                item.amount == 0
                    ? formatAmount(0, currency: _billCurrency)
                    : formatAmount(item.amount, currency: _billCurrency),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: item.amount == 0
                      ? AppColors.th(context)
                      : item.amount < 0
                          ? AppColors.healthy
                          : AppColors.tp(context),
                ),
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            icon: Icon(Icons.call_split_rounded,
                size: 18, color: AppColors.ts(context)),
            tooltip: S.of(context).billSplitIntoUnits,
            onPressed: () => _splitItemIntoUnits(index),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            icon: Icon(Icons.close_rounded,
                size: 18, color: AppColors.ts(context)),
            tooltip: S.of(context).commonDelete,
            onPressed: () => _removeItem(index),
          ),
        ],
      ),
    );
  }

  /// Splits one item into [n] equal unit-items so a shared multi-quantity item
  /// (e.g. "5× fries" for 3 people) can be assigned per-person in the next step.
  Future<void> _splitItemIntoUnits(int index) async {
    if (index < 0 || index >= _items.length) return;
    final item = _items[index];
    final tr = S.of(context);
    final ctrl = TextEditingController(text: '2');
    final n = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr.billSplitIntoUnits),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: tr.billSplitUnitsPrompt),
          onSubmitted: (_) => Navigator.pop(ctx, int.tryParse(ctrl.text)),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(tr.commonCancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, int.tryParse(ctrl.text)),
              child: Text(tr.billSplit)),
        ],
      ),
    );
    disposeAfterRouteAnimation(ctrl);
    if (n == null || n < 2 || n > 50 || !mounted) return;
    if (index >= _items.length) return;
    setState(() {
      final unit = item.amount / n;
      // Drop any trailing "×5" / "(1/5)" qualifier before re-numbering.
      final base = item.name
          .replaceAll(RegExp(r'\s*[×x]\s*\d+\s*$'), '')
          .replaceAll(RegExp(r'\s*\(\d+/\d+\)\s*$'), '')
          .trim();
      final display = base.isEmpty ? tr.billItemN(index + 1) : base;
      final units = [
        for (var i = 0; i < n; i++)
          _BillItem(
            name: '$display (${i + 1}/$n)',
            amount: unit,
            assignedTo: Set<String>.from(item.assignedTo),
            ocrLineIndex: null,
          ),
      ];
      _items.replaceRange(index, index + 1, units);
    });
  }

  void _removeItem(int index) {
    if (index < 0 || index >= _items.length) return;
    final removed = _items[index];
    final at = index;
    final line = removed.ocrLineIndex;
    setState(() {
      _items.removeAt(index);
      if (line != null && !_items.any((i) => i.ocrLineIndex == line)) {
        _addedLines.remove(line);
      }
    });
    final tr = S.of(context);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(tr.billItemRemoved),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 4),
      action: SnackBarAction(
        label: tr.txUndoAction,
        onPressed: () => setState(() {
          _items.insert(at <= _items.length ? at : _items.length, removed);
          if (line != null) _addedLines.add(line);
        }),
      ),
    ));
  }

  // ─── Split helpers (used inline in ListView) ──────────────────────────────

  Widget _buildPeopleSection() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(S.of(context).billWhosSplitting),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 6, children: [
            for (final p in _people) _personChip(p),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: TextField(
              controller: _personCtrl,
              decoration: InputDecoration(hintText: S.of(context).billAddPerson, isDense: true,
                filled: true, fillColor: AppColors.sfv(context),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none)),
              textCapitalization: TextCapitalization.words,
              onSubmitted: (_) => _addPerson(),
            )),
            const SizedBox(width: 8),
            IconButton.filled(onPressed: _addPerson,
              icon: const Icon(Icons.add_rounded, size: 18),
              style: IconButton.styleFrom(backgroundColor: AppColors.accent)),
          ]),
        ],
      ),
    );
  }

  Widget _buildSplitEvenlyToggle() {
    return _card(
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(S.of(context).billSplitEvenly,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Text(
          S.of(context).billEachPays(formatAmount(_items.fold(0.0, (s, i) => s + i.amount) / (_people.isNotEmpty ? _people.length : 1), currency: _billCurrency)),
          style: TextStyle(fontSize: 12, color: AppColors.ts(context))),
        value: _splitEvenly,
        onChanged: (v) => setState(() => _splitEvenly = v),
      ),
    );
  }

  // ─── Review helpers ───────────────────────────────────────────────────────

  Widget _buildSummaryCard() {
    final isCross = _billCurrency != _baseCurrency;
    final hasRate = isCross && (_exchangeRate - 1.0).abs() >= 0.001;
    final breakdown = _calculateBreakdown();
    final splits = _calculateSplits(); // rounded so they add up exactly
    final grandTotal = splits.values.fold(0.0, (s, v) => s + v);
    final totalTip = breakdown.values.fold(0.0, (s, b) => s + b.tip);
    final totalTax = breakdown.values.fold(0.0, (s, b) => s + b.tax);
    final tr = S.of(context);
    final small = TextStyle(fontSize: 11, color: AppColors.ts(context));
    final rowLabel = TextStyle(fontSize: 13, color: AppColors.ts(context));
    return _card(
      child: Column(children: [
        for (final entry in breakdown.entries)
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(children: [
                Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                        color: _personColor(entry.key),
                        shape: BoxShape.circle)),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(entry.key,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: entry.key == _people.first
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: AppColors.tp(context)))),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(
                      formatAmount(splits[entry.key] ?? 0,
                          currency: _billCurrency),
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.tp(context))),
                  // Show the tax and tip portions so no one has to guess them.
                  if (entry.value.tax.abs() >= 0.005)
                    Text(
                        '${tr.billTax} ${formatAmount(entry.value.tax, currency: _billCurrency)}',
                        style: small),
                  if (entry.value.tip > 0)
                    Text(
                        '${tr.billTipLabel} ${formatAmount(entry.value.tip, currency: _billCurrency)}',
                        style: small),
                  if (hasRate)
                    Text(
                        '≈ ${formatAmount(_toBase(splits[entry.key] ?? 0), currency: _baseCurrency)}',
                        style: small),
                ]),
              ])),
        Divider(color: AppColors.bd(context)),
        if (totalTax.abs() >= 0.005)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(children: [
              Expanded(child: Text(tr.billTax, style: rowLabel)),
              Text(formatAmount(totalTax, currency: _billCurrency),
                  style: rowLabel),
            ]),
          ),
        if (totalTip > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(children: [
              Expanded(child: Text(tr.billTipLabel, style: rowLabel)),
              Text(formatAmount(totalTip, currency: _billCurrency),
                  style: rowLabel),
            ]),
          ),
        Row(children: [
          Expanded(
              child: Text(tr.billTotal,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.tp(context)))),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(formatAmount(grandTotal, currency: _billCurrency),
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.tp(context))),
            if (hasRate)
              Text(
                  '≈ ${formatAmount(_toBase(grandTotal), currency: _baseCurrency)}',
                  style: small),
          ]),
        ]),
      ]),
    );
  }

  /// Items vs the receipt's TOTAL line, so a missed or misread line shows.
  Widget _buildReceiptCheck() {
    final tr = S.of(context);
    final receipt = _ocrResult!.receiptTotal!;
    final items = _itemsTotal;
    final tax = _ocrResult!.taxTotal ?? 0;
    // Tax-inclusive receipts match on items alone; others on items + tax.
    final matches = (items - receipt).abs() <= _tolerance ||
        (tax > 0 && (items + tax - receipt).abs() <= _tolerance);
    final color = matches ? AppColors.healthy : AppColors.caution;
    final receiptText = formatAmount(receipt, currency: _billCurrency);
    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.pastel(context, color, light: 0.88, dark: 0.78),
        borderRadius: BorderRadius.circular(RadiusTokens.md),
      ),
      child: Row(children: [
        Icon(matches ? Icons.check_circle_rounded : Icons.info_rounded,
            size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            matches
                ? tr.billReceiptMatch(receiptText)
                : tr.billReceiptDiff(
                    formatAmount(items, currency: _billCurrency), receiptText),
            style: TextStyle(fontSize: 12.5, color: AppColors.tp(context)),
          ),
        ),
      ]),
    );
  }

  Widget _buildWhoPaidSection() {
    final tr = S.of(context);
    final payer = _effectivePayer;

    Widget option(_PaidMode m, String title, String desc) {
      final selected = _paidMode == m;
      return InkWell(
        borderRadius: BorderRadius.circular(RadiusTokens.md),
        onTap: () => setState(() => _paidMode = m),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 20,
              color: selected ? AppColors.accent : AppColors.th(context),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.tp(context))),
                  const SizedBox(height: 2),
                  Text(desc,
                      style: TextStyle(
                          fontSize: 12, color: AppColors.ts(context))),
                ],
              ),
            ),
          ]),
        ),
      );
    }

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(tr.billWhoPaid),
          const SizedBox(height: 4),
          option(_PaidMode.me, tr.billPaidMe, tr.billPaidMeDesc),
          option(_PaidMode.other, tr.billPaidOther,
              tr.billPaidOtherDesc(payer)),
          // Pick the payer when more than one other person is splitting.
          if (_paidMode == _PaidMode.other && _others.length > 1)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 30, bottom: 6),
              child: Wrap(spacing: 6, runSpacing: 4, children: [
                for (final p in _others)
                  _assignChip(
                    label: p,
                    selected: p == payer,
                    color: _personColor(p),
                    onTap: () => setState(() => _payer = p),
                  ),
              ]),
            ),
          option(_PaidMode.each, tr.billPaidEach, tr.billPaidEachDesc),
        ],
      ),
    );
  }

  Widget _buildTaxSection() {
    final tr = S.of(context);
    final active = _taxIsAmount ? _taxAmount > 0 : _taxPercent > 0;
    return _collapsibleCard(
      title: tr.billTax,
      trailing: active
          ? (_taxIsAmount
              ? formatAmount(_taxAmount, currency: _billCurrency)
              : '${_taxPercent.round()}%')
          : tr.commonNone,
      expanded: _taxExpanded,
      onTap: () => setState(() => _taxExpanded = !_taxExpanded),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(tr.billTaxHint,
            style: TextStyle(fontSize: 12, color: AppColors.ts(context))),
        const SizedBox(height: 10),
        Row(children: [
          _segmentButton(tr.billPercentage, !_taxIsAmount,
              () => setState(() => _taxIsAmount = false)),
          const SizedBox(width: 8),
          _segmentButton(tr.commonAmount, _taxIsAmount,
              () => setState(() => _taxIsAmount = true)),
        ]),
        const SizedBox(height: 12),
        if (!_taxIsAmount)
          Row(children: [
            Expanded(
                child: Slider(
                    value: _taxPercent,
                    min: 0,
                    max: 30,
                    divisions: 30,
                    label: '${_taxPercent.round()}%',
                    onChanged: (v) => setState(() => _taxPercent = v))),
            SizedBox(
                width: 50,
                child: Text('${_taxPercent.round()}%',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.tp(context)))),
          ])
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.sfv(context),
              borderRadius: BorderRadius.circular(10),
            ),
            child: CalculatorAmountField(
              value: _taxAmount,
              label: tr.billTaxAmount,
              currency: kCurrencySymbols[_billCurrency] ?? _billCurrency,
              fontSize: 18,
              onChanged: (v) => setState(() => _taxAmount = v),
            ),
          ),
      ]),
    );
  }

  Widget _buildTipSection() {
    return _collapsibleCard(
      title: S.of(context).billTip,
      trailing: _tipPercent > 0 || _tipAmount > 0
          ? _tipIsAmount
              ? formatAmount(_tipAmount, currency: _billCurrency)
              : '${_tipPercent.round()}%'
          : S.of(context).commonNone,
      expanded: _tipExpanded,
      onTap: () => setState(() => _tipExpanded = !_tipExpanded),
      child: Column(children: [
        Row(children: [
          _segmentButton(S.of(context).billPercentage, !_tipIsAmount,
              () => setState(() => _tipIsAmount = false)),
          const SizedBox(width: 8),
          _segmentButton(S.of(context).commonAmount, _tipIsAmount,
              () => setState(() => _tipIsAmount = true)),
        ]),
        const SizedBox(height: 12),
        if (!_tipIsAmount)
          Row(children: [
            Expanded(child: Slider(value: _tipPercent, min: 0, max: 30,
                divisions: 6, label: '${_tipPercent.round()}%',
                onChanged: (v) => setState(() => _tipPercent = v))),
            SizedBox(width: 50, child: Text('${_tipPercent.round()}%',
                textAlign: TextAlign.center, style: TextStyle(
                    fontWeight: FontWeight.w600, color: AppColors.tp(context)))),
          ])
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.sfv(context),
              borderRadius: BorderRadius.circular(10),
            ),
            child: CalculatorAmountField(
              value: _tipAmount,
              label: S.of(context).billTipAmount,
              currency: kCurrencySymbols[_billCurrency] ?? _billCurrency,
              fontSize: 18,
              onChanged: (v) => setState(() => _tipAmount = v),
            ),
          ),
      ]),
    );
  }

  Widget _buildCurrencySection() {
    final isCross = _billCurrency != _baseCurrency;
    return _collapsibleCard(
      title: S.of(context).commonCurrency,
      trailing: _billCurrency,
      expanded: _currencyExpanded,
      onTap: () => setState(() => _currencyExpanded = !_currencyExpanded),
      child: Column(children: [
        CurrencyPickerField(value: _billCurrency, label: S.of(context).billBillCurrency,
          onChanged: _setBillCurrency),
        if (isCross) ...[
          const SizedBox(height: 12),
          Row(children: [
            Text('1 ${_rateInverted ? _baseCurrency : _billCurrency} = ',
                style: TextStyle(fontSize: 13, color: AppColors.ts(context))),
            Expanded(child: TextField(controller: _rateCtrl,
              decoration: InputDecoration(hintText: S.of(context).billRateHint, isDense: true,
                filled: true, fillColor: AppColors.sfv(context),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none)),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: _onRateTyped)),
            Text(' ${_rateInverted ? _billCurrency : _baseCurrency}',
                style: TextStyle(fontSize: 13, color: AppColors.ts(context))),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _swapRateDirection,
              child: Container(padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.pastel(context, AppColors.accent,
                      light: 0.85, dark: 0.78),
                  borderRadius: BorderRadius.circular(6)),
                child: Icon(Icons.swap_vert_rounded, size: 16,
                    color: AppColors.accent)),
            ),
          ]),
        ],
      ]),
    );
  }

  Widget _personChip(String name) {
    final color = _personColor(name);
    final removable = _people.length > 1 && name != _people.first;
    return GestureDetector(
      onLongPress: removable ? () => _removePerson(name) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.sfv(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.bd(context)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(name,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.tp(context))),
            if (removable) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => _removePerson(name),
                child: Icon(Icons.close_rounded,
                    size: 14, color: AppColors.th(context)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAssignableItem(int index) {
    final item = _items[index];
    final tr = S.of(context);
    final sharedBy = item.assignedTo.length;
    final perPerson = sharedBy > 0 ? item.amount / sharedBy : 0.0;
    final allSelected =
        _people.isNotEmpty && item.assignedTo.length == _people.length;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.circular(10),
        boxShadow: AppColors.cardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(item.name.isEmpty ? tr.billItemN(index + 1) : item.name,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              Text(formatAmount(item.amount, currency: _billCurrency),
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.tp(context))),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              // "Everyone" shortcut — for items shared by the whole table.
              if (_people.length > 1)
                _assignChip(
                  label: tr.billEveryone,
                  selected: allSelected,
                  color: AppColors.accent,
                  onTap: () {
                    setState(() {
                      if (allSelected) {
                        item.assignedTo.clear();
                      } else {
                        item.assignedTo
                          ..clear()
                          ..addAll(_people);
                      }
                    });
                    HapticFeedback.selectionClick();
                  },
                ),
              for (final p in _people)
                _assignChip(
                  label: p,
                  selected: item.assignedTo.contains(p),
                  color: _personColor(p),
                  onTap: () {
                    setState(() {
                      if (item.assignedTo.contains(p)) {
                        item.assignedTo.remove(p);
                      } else {
                        item.assignedTo.add(p);
                      }
                    });
                    HapticFeedback.selectionClick();
                  },
                ),
            ],
          ),
          // When an item is shared, show how the cost divides so it's obvious.
          if (sharedBy >= 2) ...[
            const SizedBox(height: 6),
            Text(
              tr.billSharedEach(
                  sharedBy, formatAmount(perPerson, currency: _billCurrency)),
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.accent),
            ),
          ],
        ],
      ),
    );
  }

  /// A pill toggle used for assigning an item to a person (or everyone).
  Widget _assignChip({
    required String label,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.pastel(context, color, light: 0.85, dark: 0.75)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(CardTokens.radius),
          border: Border.all(color: selected ? color : AppColors.bd(context)),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? color : AppColors.ts(context),
            )),
      ),
    );
  }

  // ─── Shared Widgets ───────────────────────────────────────────────────────

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppColors.cardShadow(context),
      ),
      child: child,
    );
  }

  Widget _collapsibleCard({
    required String title,
    required String trailing,
    required bool expanded,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppColors.cardShadow(context),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text(trailing,
                      style: TextStyle(
                          fontSize: 13, color: AppColors.ts(context))),
                  const SizedBox(width: 4),
                  Icon(
                    expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 20,
                    color: AppColors.ts(context),
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: child,
            ),
        ],
      ),
    );
  }

  Widget _segmentButton(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.accentLight
                : AppColors.sfv(context),
            borderRadius: BorderRadius.circular(8),
            border: selected
                ? Border.all(color: AppColors.accent.withValues(alpha: 0.4))
                : null,
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected ? AppColors.accent : AppColors.ts(context))),
          ),
        ),
      ),
    );
  }

  // ─── OCR Lines List ───────────────────────────────────────────────────────

  Widget _buildDetectedLinesList() {
    final result = _ocrResult!;
    final detected = result.lines.length;
    final withPrice = result.lines.where((l) => l.hasPrice).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _showAllLines = !_showAllLines),
          child: Row(
            children: [
              Icon(
                _showAllLines
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
                size: 18,
                color: AppColors.ts(context),
              ),
              const SizedBox(width: 4),
              Text(S.of(context).billNLines(detected, withPrice),
                  style: TextStyle(
                      fontSize: 12, color: AppColors.ts(context))),
              const Spacer(),
              TextButton(
                onPressed: _scanReceipt,
                style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 30)),
                child:
                    Text(S.of(context).billReScan, style: const TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
        if (_showAllLines) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.sf(context),
              borderRadius: BorderRadius.circular(10),
              boxShadow: AppColors.cardShadow(context),
            ),
            child: Column(
              children: [
                for (var i = 0; i < result.lines.length; i++)
                  GestureDetector(
                    onTap: () => _onLineTapped(i),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 5, horizontal: 8),
                      margin: const EdgeInsets.only(bottom: 2),
                      decoration: BoxDecoration(
                        color: _addedLines.contains(i)
                            ? AppColors.accentLight
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          if (_addedLines.contains(i))
                            Padding(
                              padding: const EdgeInsetsDirectional.only(end: 6),
                              child: Icon(Icons.check_circle_rounded,
                                  size: 14, color: AppColors.accent),
                            ),
                          Expanded(
                            child: Text(result.lines[i].text,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.tp(context))),
                          ),
                          if (result.lines[i].hasPrice)
                            Text(
                              formatAmount(result.lines[i].parsedAmount!,
                                  currency: _billCurrency),
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: result.lines[i].parsedAmount! < 0
                                      ? AppColors.healthy
                                      : AppColors.accent),
                            )
                          else if (result.lines[i].parsedAmount != null &&
                              (result.lines[i].kind == OcrLineKind.tax ||
                                  result.lines[i].kind == OcrLineKind.total))
                            // Not an item: shown so the user sees it was read.
                            Text(
                              '${result.lines[i].kind == OcrLineKind.tax ? S.of(context).billTax : S.of(context).billTotal}'
                              ' · ${formatAmount(result.lines[i].parsedAmount!, currency: _billCurrency)}',
                              style: TextStyle(
                                  fontSize: 11, color: AppColors.ts(context)),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Data Model ─────────────────────────────────────────────────────────────

/// Who paid the bill: the user, another person (who the user now owes), or
/// everyone their own part.
enum _PaidMode { me, other, each }

class _BillItem {
  String name;
  double amount;
  final Set<String> assignedTo;
  final int? ocrLineIndex;

  _BillItem({
    required this.name,
    required this.amount,
    required this.assignedTo,
    required this.ocrLineIndex,
  });
}
