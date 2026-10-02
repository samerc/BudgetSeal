import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' show Value;

import '../../core/database/app_database.dart';
import '../../core/engine/allocation_engine.dart';
import '../../core/providers/accounts_provider.dart';
import '../../core/providers/date_format_provider.dart';
import '../../core/providers/allocations_provider.dart';
import '../../core/providers/autofill_provider.dart';
import '../../core/services/autofill_service.dart';
import '../../core/providers/categories_provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/engine_provider.dart';
import '../../core/providers/tx_colors_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../core/providers/transactions_provider.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/design_tokens.dart';
import '../../shared/utils/format_number.dart';
import '../../shared/utils/haptics.dart';
import '../../shared/utils/receipt_helper.dart';
import '../../shared/widgets/amount_field.dart';
import '../../shared/widgets/calculator_amount_field.dart';
import '../../shared/widgets/category_icon.dart';
import '../../shared/utils/save_errors.dart';
import 'widgets/category_sheet.dart';
import 'widgets/currency_sheet.dart';
import 'widgets/transaction_form_widgets.dart';
import '../../l10n/generated/app_localizations.dart';

enum _TxType { income, expense, transfer }

class AddTransactionScreen extends ConsumerStatefulWidget {
  /// If set, we're editing this transaction (delete old + save new).
  final String? editTransactionId;
  final String? editType;
  final String? editNote;
  final DateTime? editDate;
  final List<Map<String, dynamic>>? editLines;
  final String? editFromAccountId;
  final String? editDestAccountId;

  const AddTransactionScreen({
    super.key,
    this.editTransactionId,
    this.editType,
    this.editNote,
    this.editDate,
    this.editLines,
    this.editFromAccountId,
    this.editDestAccountId,
  });

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  _TxType _type = _TxType.expense;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String? _fromAccountId;
  String? _destAccountId;
  bool _rateInverted = false;
  double? _originalRate;
  final _noteCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  bool _loading = false;
  final List<LineState> _lines = [];
  String? _validationError;
  List<String> _receiptFilenames = [];
  List<String> _resolvedReceiptPaths = [];
  Timer? _titleDebounce;
  bool _autoFilled = false; // tracks if category was auto-filled

  String get _baseCurrency =>
      ref.read(householdProvider).value?.baseCurrency ?? 'USD';

  @override
  void initState() {
    super.initState();
    final hasPreFill = widget.editTransactionId != null ||
        widget.editLines != null ||
        widget.editType != null ||
        widget.editNote != null;
    if (hasPreFill) {
      _initFromEdit();
    } else {
      _addLine();
    }
  }

  void _initFromEdit() {
    // Pre-fill type
    if (widget.editType == 'income') {
      _type = _TxType.income;
    } else if (widget.editType == 'transfer') {
      _type = _TxType.transfer;
    }

    // Pre-fill date/time
    if (widget.editDate != null) {
      _selectedDate = widget.editDate!;
      _selectedTime = TimeOfDay.fromDateTime(widget.editDate!);
    }

    // Pre-fill transfer accounts
    if (widget.editFromAccountId != null) {
      _fromAccountId = widget.editFromAccountId;
    }
    if (widget.editDestAccountId != null) {
      _destAccountId = widget.editDestAccountId;
    }

    // Pre-fill note/title
    final note = widget.editNote ?? '';
    if (note.contains(' — ')) {
      final parts = note.split(' — ');
      _titleCtrl.text = parts.first;
      _noteCtrl.text = parts.skip(1).join(' — ');
    } else {
      _titleCtrl.text = note;
    }

    // Pre-fill lines
    if (widget.editLines != null && widget.editLines!.isNotEmpty) {
      for (final lineData in widget.editLines!) {
        final line = LineState(
            currency: lineData['currency'] as String? ?? _baseCurrency);
        line.amountCtrl.text =
            (lineData['amount'] as double?)?.toString() ?? '';
        line.accountId = lineData['accountId'] as String?;
        line.categoryId = lineData['categoryId'] as String?;
        line.categoryName = lineData['categoryName'] as String?;
        line.noteCtrl.text = lineData['note'] as String? ?? '';
        // Restore exchange rate for foreign currency lines
        final rate = lineData['exchangeRateToBase'] as double?;
        if (rate != null && rate != 1.0) {
          line.exchangeRateToBase = rate;
          line.rateCtrl.text = formatRateForInput(roundRate(rate));
        }
        _lines.add(line);
      }
    }

    if (_lines.isEmpty) _addLine();
  }

  @override
  void dispose() {
    _titleDebounce?.cancel();
    _noteCtrl.dispose();
    _titleCtrl.dispose();
    for (final l in _lines) {
      l.dispose();
    }
    super.dispose();
  }

  void _autofillFromTitle(String title) {
    final afSettings = ref.read(autofillProvider);
    final entries = ref.read(transactionEntriesProvider).value ?? [];
    final fill = lookupAutofillByTitle(
      title: title,
      entries: entries,
      settings: afSettings,
    );
    if (!fill.hasData) {
      setState(() => _autoFilled = false);
      return;
    }
    setState(() {
      final line = _lines.isNotEmpty ? _lines[0] : null;
      if (line == null) return;
      final canOverride = afSettings.overrideExisting;
      bool didFill = false;
      if (fill.accountId != null &&
          (line.accountId == null || canOverride)) {
        _onLineAccountChanged(0, fill.accountId!);
        didFill = true;
      }
      if (fill.categoryId != null &&
          (line.categoryId == null || canOverride)) {
        line.categoryId = fill.categoryId;
        didFill = true;
        // Also set transaction type from category
        final categories = ref.read(categoriesProvider).value ?? [];
        final cat = categories.where((c) => c.id == fill.categoryId).firstOrNull;
        if (cat != null) {
          line.categoryName = cat.name;
          line.categoryColor = AppColors.fromHex(cat.colorHex);
          final txType = cat.transactionType == 'income'
              ? _TxType.income
              : _TxType.expense;
          if (_type != txType) _type = txType;
        }
      }
      if (fill.amount != null && fill.amount! > 0 &&
          (line.amount <= 0 || canOverride)) {
        line.amountCtrl.text = fill.amount!.toString();
        didFill = true;
      }
      _autoFilled = didFill;
    });
  }

  void _onTitleChanged(String value) {
    _titleDebounce?.cancel();
    if (value.length >= 3) {
      _titleDebounce = Timer(const Duration(milliseconds: 500), () {
        _autofillFromTitle(value);
      });
    } else if (_autoFilled) {
      // Title cleared or too short — reset auto-filled category
      setState(() {
        if (_lines.isNotEmpty) {
          _lines[0].categoryId = null;
          _lines[0].categoryName = null;
          _lines[0].categoryColor = AppColors.textSecondary;
        }
        _autoFilled = false;
      });
      return;
    }
    setState(() {}); // rebuild suggestions
  }

  Color _typeColor(BuildContext context) {
    final txColors = ref.watch(txColorsProvider);
    return switch (_type) {
      _TxType.income => txColors.income,
      _TxType.expense => txColors.expense,
      _TxType.transfer => txColors.transfer,
    };
  }

  double get _totalBaseAmount =>
      _lines.fold(0.0, (sum, l) => sum + l.baseAmount);

  bool get _hasMultipleLines =>
      _type != _TxType.transfer && _lines.length > 1;

  bool get _hasMultiCurrency =>
      _lines.any((l) => l.currency != _baseCurrency);

  // ---------------------------------------------------------------------------
  // Line management
  // ---------------------------------------------------------------------------

  void _addLine() {
    setState(() => _lines.add(LineState(currency: _baseCurrency)));
  }

  void _removeLine(int index) {
    if (_lines.length <= 1) return;
    setState(() {
      _lines[index].dispose();
      _lines.removeAt(index);
    });
  }

  Future<void> _onLineAccountChanged(int lineIndex, String? accountId) async {
    if (accountId == null) return;
    final accounts = ref.read(accountsProvider).value ?? [];
    final acc = accounts.where((a) => a.id == accountId).firstOrNull;
    if (acc == null) return;
    if (!mounted || lineIndex >= _lines.length) return;

    setState(() {
      _lines[lineIndex].accountId = accountId;
      _lines[lineIndex].accountName = acc.name;
      _lines[lineIndex].currency = acc.currency;
      _validationError = null;
    });

    if (acc.currency != _baseCurrency) {
      final existingRate = _lines[lineIndex].exchangeRateToBase;
      if (existingRate == 1.0 || existingRate == 0.0) {
        await _fetchRate(lineIndex, acc.currency);
      }
    } else if (mounted && lineIndex < _lines.length) {
      setState(() {
        _lines[lineIndex].exchangeRateToBase = 1.0;
        _lines[lineIndex].rateCtrl.text = '';
      });
    }

    if (!mounted || lineIndex >= _lines.length) return;

    // Auto-fill category from last transaction with this account
    final afSettings = ref.read(autofillProvider);
    if (afSettings.category && _lines[lineIndex].categoryId == null) {
      final entries = ref.read(transactionEntriesProvider).value ?? [];
      for (final e in entries) {
        if (e.tx.type == 'transfer') continue;
        final matchesAccount = e.tx.accountId == accountId ||
            e.lines.any((l) => l.accountId == accountId);
        if (matchesAccount && e.tx.categoryId != null) {
          final categories = ref.read(categoriesProvider).value ?? [];
          final cat = categories.where((c) => c.id == e.tx.categoryId).firstOrNull;
          if (cat != null && mounted && lineIndex < _lines.length) {
            setState(() {
              _lines[lineIndex].categoryId = cat.id;
              _lines[lineIndex].categoryName = cat.name;
            });
          }
          break;
        }
      }
    }
  }

  Future<void> _fetchRate(int lineIndex, String lineCurrency) async {
    try {
      final fxService = ref.read(fxServiceProvider);
      final rawRate =
          await fxService.getRateWithCache(_baseCurrency, lineCurrency);
      final rate = roundRate(rawRate);
      if (mounted && lineIndex < _lines.length) {
        setState(() {
          _lines[lineIndex].rateCtrl.text = formatRateForInput(rate);
          // Guard against a 0 rate from the FX provider — 1.0/0 = Infinity
          // would poison all downstream balance/report math.
          _lines[lineIndex].exchangeRateToBase = rate > 0 ? 1.0 / rate : 1.0;
        });
      }
    } catch (e) {
      debugPrint('Failed to fetch FX rate: $e');
    }
  }

  /// Fetch transfer exchange rate when both accounts are selected.
  Future<void> _fetchTransferRate() async {
    if (_fromAccountId == null || _destAccountId == null) return;
    final accounts = ref.read(accountsProvider).value ?? [];
    final fromAcc = accounts.where((a) => a.id == _fromAccountId).firstOrNull;
    final toAcc = accounts.where((a) => a.id == _destAccountId).firstOrNull;
    if (fromAcc == null || toAcc == null) return;
    if (fromAcc.currency == toAcc.currency) {
      setState(() {
        _lines.first.exchangeRateToBase = 1.0;
        _lines.first.rateCtrl.text = '';
      });
      return;
    }
    try {
      final fxService = ref.read(fxServiceProvider);
      final rawRate = await fxService.getRateWithCache(
          fromAcc.currency, toAcc.currency);
      final rate = roundRate(rawRate);
      if (mounted && _lines.isNotEmpty) {
        setState(() {
          _lines.first.rateCtrl.text = formatRateForInput(rate);
          _lines.first.exchangeRateToBase = rate;
        });
      }
    } catch (e) {
      debugPrint('Failed to fetch transfer FX rate: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Pickers
  // ---------------------------------------------------------------------------

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && mounted) {
      setState(() => _selectedTime = picked);
    }
  }

  /// Combine date + time into a single DateTime.
  DateTime get _effectiveDateTime => DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

  String get _dateLabel {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sel =
        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final diff = today.difference(sel).inDays;
    if (diff == 0) return S.of(context).commonToday;
    if (diff == 1) return S.of(context).commonYesterday;
    return formatDate(_selectedDate);
  }

  String get _timeLabel {
    final hour = _selectedTime.hourOfPeriod == 0 ? 12 : _selectedTime.hourOfPeriod;
    final minute = _selectedTime.minute.toString().padLeft(2, '0');
    final period = _selectedTime.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _pickCategory(int lineIndex) async {
    final categories = ref.read(categoriesProvider).value ?? [];
    final householdId = ref.read(currentHouseholdIdProvider);
    // Build envelope balance info for the category picker.
    final allocations =
        ref.read(allocationsProvider).value ?? [];
    final envelopeInfo = <String, String>{};
    for (final a in allocations) {
      final bal = a.balanceByCurrency.entries.firstOrNull;
      if (bal != null) {
        envelopeInfo[a.data.allocation.id] =
            '${a.data.allocation.name} — ${formatAmount(bal.value, currency: bal.key)}';
      }
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CategorySheet(
        categories: categories,
        selectedId: _lines[lineIndex].categoryId,
        householdId: householdId,
        envelopeInfo: envelopeInfo,
        onSelected: (id, name, color, txType) {
          if (!mounted || lineIndex >= _lines.length) return;
          setState(() {
            _lines[lineIndex].categoryId = id;
            _lines[lineIndex].categoryName = name;
            _lines[lineIndex].categoryColor = color;
            if (_type != _TxType.transfer) {
              _type = txType == 'income' ? _TxType.income : _TxType.expense;
            }
          });
          Navigator.of(ctx).pop();

          // Auto-fill from last transaction with this category
          if (!mounted || lineIndex >= _lines.length) return;
          final afSettings = ref.read(autofillProvider);
          final entries = ref.read(transactionEntriesProvider).value ?? [];
          final fill = lookupAutofill(
            categoryId: id,
            entries: entries,
            settings: afSettings,
          );
          if (fill.hasData) {
            if (!mounted || lineIndex >= _lines.length) return;
            setState(() {
              final line = _lines[lineIndex];
              final canOverride = afSettings.overrideExisting;
              if (fill.accountId != null &&
                  (line.accountId == null || canOverride)) {
                _onLineAccountChanged(lineIndex, fill.accountId!);
              }
              if (fill.title != null &&
                  (_titleCtrl.text.isEmpty || canOverride)) {
                _titleCtrl.text = fill.title!;
              }
              if (fill.amount != null && fill.amount! > 0 &&
                  (line.amount <= 0 || canOverride)) {
                line.amountCtrl.text = fill.amount!.toString();
              }
            });
          } else {
            // Fallback: auto-fill account from category's default
            if (_lines[lineIndex].accountId == null && categories.isNotEmpty) {
              final cat = categories
                  .where((c) => c.id == id)
                  .firstOrNull;
              if (cat?.defaultAccountId != null) {
                _onLineAccountChanged(lineIndex, cat!.defaultAccountId);
              }
            }
          }
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
          final txType = _type == _TxType.income ? 'income' : 'expense';
          try {
            await db.into(db.categories).insert(CategoriesCompanion.insert(
                  id: newId,
                  householdId: householdId,
                  name: name,
                  colorHex: Value(colorHex),
                  transactionType: Value(txType),
                ));
          } catch (e) {
            debugPrint('[AddTransaction] Creating category failed: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(S.of(context).commonSomethingWentWrong),
                behavior: SnackBarBehavior.floating,
              ));
            }
            return;
          }
          if (!mounted) return;
          ref.invalidate(categoriesProvider);
          if (lineIndex < _lines.length) {
            setState(() {
              _lines[lineIndex].categoryId = newId;
              _lines[lineIndex].categoryName = name;
              _lines[lineIndex].categoryColor = color;
            });
          }
          // Close the sheet via its own context — the screen's navigator
          // would pop the form itself if the sheet were already gone.
          if (ctx.mounted) Navigator.of(ctx).pop();
        },
      ),
    );
  }

  Future<void> _pickCurrency(int lineIndex) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final accts = ref.read(accountsProvider).value ?? [];
        return CurrencySheet(
          current: _lines[lineIndex].currency,
          accountCurrencies: accts.map((a) => a.currency).toSet().toList(),
        );
      },
    );
    if (result != null && mounted && lineIndex < _lines.length) {
      setState(() => _lines[lineIndex].currency = result);
      if (result != _baseCurrency) {
        await _fetchRate(lineIndex, result);
      } else if (mounted && lineIndex < _lines.length) {
        setState(() {
          _lines[lineIndex].exchangeRateToBase = 1.0;
          _lines[lineIndex].rateCtrl.text = '';
        });
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Validation + Save
  // ---------------------------------------------------------------------------

  String? _validate() {
    if (_type == _TxType.transfer) {
      if (_fromAccountId == null) return S.of(context).txFormSelectSource;
      if (_destAccountId == null) return S.of(context).txFormSelectDest;
      if (_fromAccountId == _destAccountId) {
        return S.of(context).txFormSourceDestDiffer;
      }
      if (_lines.isEmpty || _lines.first.amount <= 0) {
        return S.of(context).txFormEnterAmount;
      }
    } else {
      for (var i = 0; i < _lines.length; i++) {
        final l = _lines[i];
        if (l.accountId == null) {
          return _lines.length > 1
              ? S.of(context).txFormSelectAccountItem(i + 1)
              : S.of(context).txFormSelectAccount;
        }
        if (l.amount <= 0) {
          return _lines.length > 1
              ? S.of(context).txFormEnterAmountItem(i + 1)
              : S.of(context).txFormEnterAmountTx;
        }
      }
    }
    return null;
  }

  /// Check if a transaction with the same amount, category, and date exists.
  TransactionEntry? _checkForDuplicate() {
    final existingEntries =
        ref.read(transactionEntriesProvider).value ?? [];
    final selectedDay = DateTime(
        _selectedDate.year, _selectedDate.month, _selectedDate.day);

    for (final line in _lines) {
      if (line.amount <= 0 || line.categoryId == null) continue;
      for (final existing in existingEntries) {
        final txDate = existing.tx.createdAt.toLocal();
        final txDay = DateTime(txDate.year, txDate.month, txDate.day);
        if (txDay != selectedDay) continue;

        // Check amount match
        bool amountMatch = (existing.tx.amount - line.amount).abs() < 0.01;
        if (!amountMatch) {
          for (final el in existing.lines) {
            if ((el.amount - line.amount).abs() < 0.01) {
              amountMatch = true;
              break;
            }
          }
        }
        if (!amountMatch) continue;

        // Check category match
        if (existing.tx.categoryId == line.categoryId) return existing;
        for (final el in existing.lines) {
          if (el.categoryId == line.categoryId) return existing;
        }
      }
    }
    return null;
  }

  Future<void> _save() async {
    final error = _validate();
    if (error != null) {
      setState(() => _validationError = error);
      hapticHeavy();
      return;
    }

    // Warn if any line has a foreign currency with no exchange rate set
    final tr = S.of(context);
    final missingRateLines = <int>[];
    for (var i = 0; i < _lines.length; i++) {
      final l = _lines[i];
      if (l.currency != _baseCurrency &&
          (l.exchangeRateToBase - 1.0).abs() < 0.001) {
        missingRateLines.add(i);
      }
    }
    if (missingRateLines.isNotEmpty) {
      final items = missingRateLines
          .map((i) => _lines.length > 1
              ? 'Item ${i + 1} (${_lines[i].currency})'
              : _lines[i].currency)
          .join(', ');
      final proceed = await showDialog<bool>(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          title: Text(tr.txFormRateNotSetTitle),
          content: Text(tr.txFormRateNotSetBody(items, _baseCurrency)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: Text(tr.commonGoBack),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogCtx, true),
              child: Text(tr.commonSaveAnyway),
            ),
          ],
        ),
      );
      if (proceed != true || !mounted) return;
    }

    // Duplicate detection (skip when editing existing transaction)
    if (widget.editTransactionId == null && _type != _TxType.transfer) {
      final duplicateMatch = _checkForDuplicate();
      if (duplicateMatch != null && mounted) {
        final matchTx = duplicateMatch.tx;
        final matchNote = matchTx.note.isNotEmpty ? matchTx.note : tr.txFormNoTitle;
        final matchAmount = formatAmount(matchTx.amount, currency: matchTx.currency);
        final matchDate = formatDate(matchTx.createdAt);
        final proceed = await showDialog<bool>(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            title: Text(tr.txFormDuplicateTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr.txFormDuplicateSimilarExists),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(dialogCtx).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(matchNote,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('$matchAmount  •  $matchDate',
                          style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(dialogCtx).colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(tr.txFormDuplicateSaveAnyway),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx, false),
                child: Text(tr.commonCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogCtx, true),
                child: Text(tr.commonSaveAnyway),
              ),
            ],
          ),
        );
        if (proceed != true || !mounted) return;
      }
    }

    hapticMedium();
    setState(() => _validationError = null);

    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null) return;

    setState(() => _loading = true);
    try {
      final engine = ref.read(allocationEngineProvider);

      final title = _titleCtrl.text.trim();
      final note = _noteCtrl.text.trim();
      final effectiveNote =
          title.isNotEmpty && note.isNotEmpty
              ? '$title — $note'
              : title.isNotEmpty
                  ? title
                  : note;

      // Create the new transaction FIRST (if this fails, old data is intact)
      late final String txId;
      if (_type == _TxType.transfer) {
        txId = await engine.recordTransfer(
          householdId: householdId,
          fromAccountId: _fromAccountId!,
          toAccountId: _destAccountId!,
          amount: _lines.first.amount,
          currency: _lines.first.currency,
          exchangeRateToBase: _lines.first.exchangeRateToBase,
          createdBy: 'user',
          deviceId: 'local',
          note: effectiveNote,
          date: _effectiveDateTime,
        );
      } else {
        final txLines = _lines
            .map((l) => TxLine(
                  amount: l.amount,
                  currency: l.currency,
                  categoryId: l.categoryId,
                  accountId: l.accountId,
                  exchangeRateToBase: l.exchangeRateToBase,
                  // A single line is shown compact (its own note is hidden):
                  // the header note is the note, so don't keep a stale one.
                  note: _lines.length == 1 ? '' : l.noteCtrl.text.trim(),
                ))
            .toList();
        final primaryAccountId = txLines.first.accountId ?? '';
        txId = await engine.recordTransaction(
          householdId: householdId,
          accountId: primaryAccountId,
          type: _type == _TxType.income ? 'income' : 'expense',
          lines: txLines,
          baseCurrency: _baseCurrency,
          note: effectiveNote,
          date: _effectiveDateTime,
        );
      }

      // Only delete the old transaction AFTER successful creation
      if (widget.editTransactionId != null) {
        await engine.deleteTransaction(widget.editTransactionId!);
      }

      // Save receipt filenames if attached.
      if (_receiptFilenames.isNotEmpty) {
        try {
          final db = ref.read(databaseProvider);
          await (db.update(db.transactions)
                ..where((t) => t.id.equals(txId)))
              .write(TransactionsCompanion(
                  receiptPath: Value(encodeReceiptPaths(_receiptFilenames))));
        } catch (e) {
          debugPrint('[AddTransaction] Failed to save receipt paths: $e');
        }
      }

      if (!mounted) return;

      // Build envelope feedback message
      String snackText = S.of(context).txFormSaved;
      try {
        if (_type != _TxType.transfer) {
          final categories = ref.read(categoriesProvider).value ?? [];
          final allocations = ref.read(allocationsProvider).value ?? [];
          final firstCatId = _lines
              .where((l) => l.categoryId != null)
              .map((l) => l.categoryId!)
              .firstOrNull;
          if (firstCatId != null) {
            final catData = categories
                .where((c) => c.id == firstCatId)
                .firstOrNull;
            if (catData?.allocationId != null) {
              final alloc = allocations
                  .where((a) =>
                      a.data.allocation.id == catData!.allocationId)
                  .firstOrNull;
              if (alloc != null) {
                snackText =
                    S.of(context).txFormSavedEnvelope(alloc.data.allocation.name);
              }
            }
          }
        }
      } catch (_) {
        // Provider might be unavailable if widget tree is torn down
      }

      if (!mounted) return;
      // Capture navigator and messenger before any async/pop calls
      final nav = GoRouter.of(context);
      final messenger = ScaffoldMessenger.maybeOf(context);
      // Pop first — this unmounts the widget
      nav.pop(txId);
      // Show snackbar via previously-captured messenger
      messenger?.clearSnackBars();
      messenger?.showSnackBar(SnackBar(
        content: Text(snackText),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        dismissDirection: DismissDirection.horizontal,
      ));
      return; // skip finally setState since we're already popped
    } catch (e) {
      debugPrint('[AddTransaction] Save failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(txSaveErrorText(S.of(context), e)),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider).value ?? [];
    ref.watch(categoriesProvider);

    final bandColor = _bandColor(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: bandColor,
        title: Text(_screenTitle(context)),
        actions: [
          if (widget.editTransactionId == null)
            IconButton(
              tooltip: S.of(context).txFormUseTemplate,
              onPressed: () => context.push('/templates'),
              icon: const Icon(Icons.bolt_rounded),
            ),
          const SizedBox(width: 4),
        ],
      ),
      bottomNavigationBar: _buildSaveBar(context),
      body: SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cashew header band: type tabs + category icon + big amount.
            _buildHeaderBand(context, bandColor),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title, date/time and note grouped in one card (Cashew).
            _TxFieldCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTitleField(),
                  _fieldDivider(context),
                  _buildDateRowInline(),
                  _fieldDivider(context),
                  TextField(
                    controller: _noteCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    maxLength: InputLimits.noteMaxLength,
                    decoration: InputDecoration(
                      counterText: '', // limit still enforced, counter hidden
                      hintText: S.of(context).txFormNoteHint,
                      hintStyle: TextStyle(color: AppColors.ts(context).withValues(alpha: 0.75)),
                      prefixIcon: Icon(Icons.notes_rounded,
                          size: 18, color: AppColors.ts(context)),
                      border: InputBorder.none,
                      filled: false,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                    maxLines: 3,
                    minLines: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Validation error
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

            // Lines or transfer
            if (_type == _TxType.transfer) ...[
              _buildTransferSection(accounts),
              const SizedBox(height: 12),
            ],
            if (_type != _TxType.transfer) ...[
              _buildLinesSection(accounts),
              const SizedBox(height: 12),
            ],

            // Receipt (when attached) + action chips
            _buildReceiptButton(),
            const SizedBox(height: 24),
          ],
        ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Type selector
  // ---------------------------------------------------------------------------

  // ---------------------------------------------------------------------------
  // Header band (Cashew addTransactionPage)
  // ---------------------------------------------------------------------------

  Category? get _firstLineCategory {
    if (_lines.isEmpty || _lines.first.categoryId == null) return null;
    return (ref.read(categoriesProvider).value ?? [])
        .where((c) => c.id == _lines.first.categoryId)
        .firstOrNull;
  }

  /// Band color: pastel of the category color (single line), else of the
  /// transaction type color.
  Color _bandColor(BuildContext context) {
    final cat = _type == _TxType.transfer || _hasMultipleLines
        ? null
        : _firstLineCategory;
    final base = cat != null ? AppColors.fromHex(cat.colorHex) : _typeColor(context);
    // Lighter than the category icon's own pastel (0.55) so the icon reads.
    return AppColors.pastel(context, base, light: 0.75, dark: 0.7);
  }

  Future<void> _editHeaderAmount() async {
    if (_lines.isEmpty) _addLine();
    final line = _lines.first;
    final v = await showCalculatorSheet(context, line.amount);
    if (v == null || !mounted) return;
    setState(() {
      setAmountText(line.amountCtrl, v);
      _validationError = null;
    });
  }

  Widget _buildHeaderBand(BuildContext context, Color bandColor) {
    final isTransfer = _type == _TxType.transfer;
    final multi = _hasMultipleLines;
    final cat = isTransfer || multi ? null : _firstLineCategory;
    final line = _lines.isNotEmpty ? _lines.first : null;
    final amount = multi ? _totalBaseAmount : (line?.amount ?? 0);
    final amountCcy = multi ? _baseCurrency : (line?.currency ?? _baseCurrency);
    final typeColor = _typeColor(context);

    final String subtitle;
    if (isTransfer) {
      subtitle = S.of(context).typeTransfer;
    } else if (multi) {
      subtitle = S.of(context).txNItems(_lines.length);
    } else if (cat != null) {
      subtitle = cat.name;
    } else {
      subtitle = S.of(context).txAfSelectCategoryButton;
    }

    final Widget icon;
    if (cat != null) {
      icon = CategoryIcon(
        key: ValueKey(cat.id),
        categoryName: cat.name,
        emoji: cat.icon,
        color: AppColors.fromHex(cat.colorHex),
        size: 64,
        circular: true,
      );
    } else {
      icon = Container(
        key: ValueKey('type_$_type'),
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.pastel(context, typeColor, light: 0.35, dark: 0.3),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isTransfer
              ? Icons.swap_horiz_rounded
              : multi
                  ? Icons.list_alt_rounded
                  : Icons.category_rounded,
          size: 30,
          color: Colors.white,
        ),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      color: bandColor,
      child: Column(
        children: [
          _buildTypeTabs(context),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(18, 16, 20, 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon with the category name under it; both open the
                // category sheet (edit badge hints at that).
                GestureDetector(
                  onTap: isTransfer || multi ? null : () => _pickCategory(0),
                  child: SizedBox(
                    width: 96,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder: (child, anim) =>
                                  ScaleTransition(scale: anim, child: child),
                              child: icon,
                            ),
                            if (!isTransfer && !multi)
                              PositionedDirectional(
                                end: -2,
                                bottom: -2,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: AppColors.sf(context),
                                    shape: BoxShape.circle,
                                    border:
                                        Border.all(color: bandColor, width: 2),
                                  ),
                                  child: Icon(Icons.edit_rounded,
                                      size: 12, color: AppColors.ts(context)),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          // "Select category" needs two lines at this width.
                          maxLines: cat == null ? 2 : 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color:
                                AppColors.tp(context).withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: multi ? null : _editHeaderAmount,
                        child: SizedBox(
                          height: 50,
                          width: double.infinity,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: AlignmentDirectional.centerEnd,
                            child: Text(
                              formatAmount(amount > 0 ? amount : 0,
                                  currency: amountCcy),
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                                color: amount > 0
                                    ? AppColors.tp(context)
                                    : AppColors.tp(context)
                                        .withValues(alpha: 0.35),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (_autoFilled && cat != null)
                        Text(
                          S.of(context).txFormAutoDetected,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.tp(context).withValues(alpha: 0.55),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Expense / Income / Transfer as a pill selector inset in the band, with
  /// a sliding indicator so the current type is unmistakable.
  Widget _buildTypeTabs(BuildContext context) {
    final types = [_TxType.expense, _TxType.income, _TxType.transfer];
    final labels = [
      S.of(context).typeExpense,
      S.of(context).typeIncome,
      S.of(context).typeTransfer,
    ];
    final index = types.indexOf(_type);
    final dark = AppColors.isDark;
    final track = dark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);
    final pill = dark
        ? Colors.white.withValues(alpha: 0.18)
        : Colors.white.withValues(alpha: 0.92);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Container(
        height: 46,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: track,
          borderRadius: BorderRadius.circular(RadiusTokens.pill),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                alignment: AlignmentDirectional(index - 1.0, 0),
                child: FractionallySizedBox(
                  widthFactor: 1 / 3,
                  heightFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: pill,
                      borderRadius: BorderRadius.circular(RadiusTokens.pill),
                      boxShadow: dark
                          ? null
                          : const [
                              BoxShadow(
                                  color: Color(0x14000000),
                                  blurRadius: 6,
                                  offset: Offset(0, 1)),
                            ],
                    ),
                  ),
                ),
              ),
            ),
            Row(
              children: [
                for (var i = 0; i < types.length; i++)
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (_type == types[i]) return;
                        hapticSelection();
                        setState(() {
                          _type = types[i];
                          if (_lines.isEmpty) _addLine();
                        });
                      },
                      child: Center(
                        child: Text(
                          labels[i],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight:
                                i == index ? FontWeight.w800 : FontWeight.w600,
                            color: AppColors.tp(context)
                                .withValues(alpha: i == index ? 1 : 0.55),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Bottom action: "Enter amount" until an amount exists, then Save/Add.
  Widget _buildSaveBar(BuildContext context) {
    final needsAmount = !_hasMultipleLines &&
        (_lines.isEmpty || _lines.first.amount <= 0);
    final isEdit = widget.editTransactionId != null;
    final label = needsAmount
        ? S.of(context).txAfEnterAmountButton
        : isEdit
            ? S.of(context).commonSave
            : S.of(context).txAfAddTransaction;
    return DecoratedBox(
      decoration: BoxDecoration(
        // Fade content into the bar instead of a hard edge.
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.bg(context).withValues(alpha: 0),
            AppColors.bg(context),
          ],
          stops: const [0, 0.25],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: FilledButton(
            onPressed: _loading
                ? null
                : needsAmount
                    ? _editHeaderAmount
                    : _save,
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5))
                : AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Text(label, key: ValueKey(label)),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateRowInline() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        size: 16, color: AppColors.ts(context)),
                    const SizedBox(width: 8),
                    Text(_dateLabel,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.tp(context))),
                  ],
                ),
              ),
            ),
          ),
          Container(
              width: 1, height: 24, color: AppColors.bd(context)),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 12),
            child: InkWell(
              onTap: _pickTime,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.access_time_rounded,
                        size: 16, color: AppColors.ts(context)),
                    const SizedBox(width: 8),
                    Text(_timeLabel,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.tp(context))),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Transfer section (with FX rate)
  // ---------------------------------------------------------------------------

  Widget _buildTransferSection(List<Account> accounts) {
    final fromAcc = _fromAccountId != null && accounts.isNotEmpty
        ? accounts.firstWhere((a) => a.id == _fromAccountId,
            orElse: () => accounts.first)
        : null;
    final toAcc = _destAccountId != null && accounts.isNotEmpty
        ? accounts.firstWhere((a) => a.id == _destAccountId,
            orElse: () => accounts.first)
        : null;
    final crossCurrency =
        fromAcc != null && toAcc != null && fromAcc.currency != toAcc.currency;
    final rate = _lines.isNotEmpty ? _lines.first.exchangeRateToBase : 1.0;
    final destAmount =
        _lines.isNotEmpty ? _lines.first.amount * rate : 0.0;

    // Same card surface as the field card above.
    return _TxFieldCard(
      child: Column(
        children: [
          // From account
          _buildAccountDropdown(
            value: _fromAccountId,
            hint: S.of(context).txFormFromAccount,
            icon: Icons.arrow_upward_rounded,
            accounts: accounts,
            onChanged: (v) {
              setState(() {
                _fromAccountId = v;
                if (v != null && _lines.isNotEmpty) {
                  final acc = accounts.firstWhere((a) => a.id == v);
                  _lines.first.currency = acc.currency;
                  _lines.first.accountId = v;
                  _validationError = null;
                }
              });
              _fetchTransferRate();
            },
          ),
          const TxDivider(),
          // To account
          _buildAccountDropdown(
            value: _destAccountId,
            hint: S.of(context).txFormToAccount,
            icon: Icons.arrow_downward_rounded,
            accounts: accounts.where((a) => a.id != _fromAccountId).toList(),
            onChanged: (v) {
              setState(() {
                _destAccountId = v;
                _validationError = null;
              });
              _fetchTransferRate();
            },
          ),
          // The amount lives in the header band (tap it for the calculator).
          if (_lines.isNotEmpty) ...[
            // Cross-currency rate for transfers
            if (crossCurrency) ...[
              const TxDivider(),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.currency_exchange_rounded,
                            size: 14, color: AppColors.accent),
                        const SizedBox(width: 8),
                        Text(
                            '1 ${_rateInverted ? toAcc.currency : fromAcc.currency} =',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.ts(context))),
                        const SizedBox(width: 6),
                        SizedBox(
                          width: 90,
                          child: TextField(
                            controller: _lines.first.rateCtrl,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.accent),
                            decoration: InputDecoration(
                              hintText: '0.00',
                              hintStyle: TextStyle(
                                  fontSize: 13, color: AppColors.th(context)),
                              border: InputBorder.none,
        filled: false,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: (val) {
                              final r =
                                  double.tryParse(val.replaceAll(',', ''));
                              if (r != null && r > 0) {
                                if (_rateInverted) {
                                  _lines.first.exchangeRateToBase = 1.0 / r;
                                } else {
                                  _lines.first.exchangeRateToBase = r;
                                }
                                _originalRate = null; // user typed manually
                              }
                              setState(() {});
                            },
                          ),
                        ),
                        Text(
                            _rateInverted ? fromAcc.currency : toAcc.currency,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ts(context))),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              if (!_rateInverted) {
                                // Save original before inverting
                                _originalRate = _lines.first.exchangeRateToBase;
                                final inverted = _originalRate != null && _originalRate! > 0
                                    ? 1.0 / _originalRate!
                                    : 0.0;
                                _lines.first.rateCtrl.text =
                                    formatRateForInput(roundRate(inverted));
                              } else {
                                // Restore original rate
                                if (_originalRate != null) {
                                  _lines.first.rateCtrl.text =
                                      formatRateForInput(roundRate(_originalRate!));
                                }
                              }
                              _rateInverted = !_rateInverted;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(Icons.swap_vert_rounded,
                                size: 16, color: AppColors.accent),
                          ),
                        ),
                      ],
                    ),
                    if (_lines.first.amount > 0) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            S.of(context).txFormDestReceives,
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.ts(context)),
                          ),
                          Text(
                            formatAmount(destAmount,
                                currency: toAcc.currency),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildAccountDropdown({
    required String? value,
    required String hint,
    required IconData icon,
    required List<Account> accounts,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Row(
            children: [
              Icon(icon, size: 18, color: AppColors.ts(context)),
              const SizedBox(width: 12),
              Text(hint,
                  style: TextStyle(
                      color: AppColors.ts(context), fontSize: 15)),
            ],
          ),
          icon: Icon(Icons.chevron_right_rounded,
              size: 18, color: AppColors.th(context)),
          items: () {
              final balances = ref.watch(accountsWithBalanceProvider).value ?? [];
              final balanceMap = {for (final ab in balances) ab.account.id: ab.balance};
              return accounts
                  .map((a) {
                    final balance = balanceMap[a.id];
                    return DropdownMenuItem(
                        value: a.id,
                        child: Row(children: [
                          Icon(_accountIcon(a.type),
                              size: 18, color: AppColors.ts(context)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(a.name,
                                style: const TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            balance != null
                                ? formatAmount(balance, currency: a.currency)
                                : a.currency,
                            style: TextStyle(
                                fontSize: 12,
                                color: balance != null && balance < 0
                                    ? AppColors.overspent
                                    : AppColors.ts(context)),
                          ),
                        ]),
                      );
                  })
                  .toList();
          }(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Lines section
  // ---------------------------------------------------------------------------

  Widget _buildLinesSection(List<Account> accounts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ..._lines.asMap().entries.map((entry) {
          final i = entry.key;
          final line = entry.value;
          return Padding(
            // Keyed by line so removing one doesn't hand its state to the next.
            key: ObjectKey(line),
            padding: const EdgeInsets.only(bottom: 10),
            child: LineCard(
              line: line,
              compact: _lines.length == 1,
              canRemove: _lines.length > 1,
              typeColor: _typeColor(context),
              baseCurrency: _baseCurrency,
              accounts: accounts,
              onRemove: () => _removeLine(i),
              onPickCategory: () => _pickCategory(i),
              onPickCurrency: () => _pickCurrency(i),
              onAccountChanged: (v) => _onLineAccountChanged(i, v),
              onChanged: () => setState(() {}),
            ),
          );
        }),
        if (_hasMultipleLines || _hasMultiCurrency) ...[
          const SizedBox(height: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _typeColor(context).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _typeColor(context).withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _hasMultiCurrency
                      ? '${S.of(context).txFormTotal} ($_baseCurrency)'
                      : S.of(context).txFormTotal,
                  style: TextStyle(
                      color: _typeColor(context),
                      fontWeight: FontWeight.w600,
                      fontSize: 14),
                ),
                Text(
                  formatAmount(_totalBaseAmount),
                  style: TextStyle(
                    color: _typeColor(context),
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTitleField() {
    // Get unique previous transaction titles for inline pills.
    final entries =
        ref.read(transactionEntriesProvider).value ?? [];
    final previousTitles = <String>{};
    for (final e in entries) {
      final note = e.tx.note;
      if (note.isNotEmpty) {
        final title = note.contains(' — ') ? note.split(' — ').first : note;
        if (title.isNotEmpty) previousTitles.add(title);
      }
    }
    final allSuggestions = previousTitles.toList()..sort();

    // Filter suggestions based on current input
    final query = _titleCtrl.text.toLowerCase();
    final filtered = query.isEmpty
        ? <String>[]
        : allSuggestions
            .where((s) =>
                s.toLowerCase().contains(query) && s.toLowerCase() != query)
            .take(5)
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _titleCtrl,
          textCapitalization: TextCapitalization.sentences,
          onChanged: _onTitleChanged,
          maxLength: InputLimits.nameMaxLength,
          decoration: InputDecoration(
            counterText: '', // limit still enforced, counter hidden
            hintText: S.of(context).txFormTitleHint,
            hintStyle: TextStyle(color: AppColors.ts(context).withValues(alpha: 0.75)),
            prefixIcon: Icon(Icons.edit_rounded,
                size: 18, color: AppColors.ts(context)),
            border: InputBorder.none,
        filled: false,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        if (filtered.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: filtered.map((s) {
                return GestureDetector(
                  onTap: () {
                    _titleCtrl.text = s;
                    _titleCtrl.selection = TextSelection.fromPosition(
                        TextPosition(offset: s.length));
                    FocusScope.of(context).unfocus();
                    // Auto-fill from last transaction with this title
                    _autofillFromTitle(s);
                  },
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.sizeOf(context).width * 0.42,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.sfv(context),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.bd(context)),
                      ),
                      child: Text(s,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 13,
                              color: AppColors.tp(context))),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }


  Future<void> _resolveReceiptPaths() async {
    final paths = await resolveReceiptPaths(_receiptFilenames);
    if (mounted) {
      setState(() => _resolvedReceiptPaths = paths);
    }
  }

  /// Attached receipt (if any) and a single row of action chips: add item,
  /// scan receipt, pick from gallery.
  Widget _buildReceiptButton() {
    Future<void> addReceipts({required bool camera}) async {
      final filenames = await pickAndSaveReceipts(context, fromCamera: camera);
      if (filenames.isNotEmpty && mounted) {
        _receiptFilenames = [..._receiptFilenames, ...filenames];
        _resolveReceiptPaths();
      }
    }

    final receiptCard = _receiptFilenames.isEmpty
        ? null
        : TxCard(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              if (_resolvedReceiptPaths.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(_resolvedReceiptPaths.first),
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    cacheWidth: 96,
                    cacheHeight: 96,
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _receiptFilenames.length == 1
                      ? S.of(context).txFormReceiptAttached
                      : S.of(context).txFormNReceipts(_receiptFilenames.length),
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.healthy),
                ),
              ),
              IconButton(
                icon: Icon(Icons.add_rounded,
                    size: 18, color: AppColors.th(context)),
                tooltip: S.of(context).txFormAddMore,
                onPressed: () async {
                  await addReceipts(camera: false);
                },
              ),
              IconButton(
                icon: Icon(Icons.close_rounded,
                    size: 18, color: AppColors.th(context)),
                onPressed: () => setState(() {
                  _receiptFilenames = [];
                  _resolvedReceiptPaths = [];
                }),
              ),
            ],
          ),
        ),
      );

    final chips = <Widget>[
      if (_type != _TxType.transfer)
        _ActionChip(
          icon: Icons.add_rounded,
          label: S.of(context).txFormAddItem,
          onTap: _addLine,
        ),
      if (receiptCard == null) ...[
        _ActionChip(
          icon: Icons.camera_alt_rounded,
          label: S.of(context).txFormScanReceipt,
          onTap: () => addReceipts(camera: true),
        ),
        _ActionChip(
          icon: Icons.image_rounded,
          label: S.of(context).txFormGallery,
          onTap: () => addReceipts(camera: false),
        ),
      ],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (receiptCard != null) ...[receiptCard, const SizedBox(height: 12)],
        // One row of equal chips; labels shrink rather than wrap.
        if (chips.isNotEmpty)
          Row(
            children: [
              for (var i = 0; i < chips.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(child: chips[i]),
              ],
            ],
          ),
      ],
    );
  }

  Widget _fieldDivider(BuildContext context) => Divider(
      height: 1, indent: 16, endIndent: 16, color: AppColors.bd(context));

  String _screenTitle(BuildContext context) {
    final l = S.of(context);
    final edit = widget.editTransactionId != null;
    return switch (_type) {
      _TxType.expense => edit ? l.txFormEditExpense : l.txFormNewExpense,
      _TxType.income => edit ? l.txFormEditIncome : l.txFormNewIncome,
      _TxType.transfer => edit ? l.txFormEditTransfer : l.txFormNewTransfer,
    };
  }

  IconData _accountIcon(String type) => switch (type) {
        'bank' => Icons.account_balance_rounded,
        'credit' => Icons.credit_card_rounded,
        'wallet' => Icons.account_balance_wallet_rounded,
        _ => Icons.money_rounded,
      };
}

/// Consistent styled field card for the transaction form.
class _TxFieldCard extends StatelessWidget {
  final Widget child;
  const _TxFieldCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _inputCardDecoration(context),
      child: child,
    );
  }
}

/// Small action tile under the form (add item / scan / gallery).
class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionChip(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _inputCardDecoration(context),
      child: Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(RadiusTokens.input),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: AppColors.accentText(context)),
              const SizedBox(height: 4),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.tp(context))),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

/// Form cards (fields, items, transfer, action tiles): the regular card
/// surface with its soft shadow so inputs stand out from the page.
BoxDecoration _inputCardDecoration(BuildContext context) => BoxDecoration(
      color: AppColors.sf(context),
      borderRadius: BorderRadius.circular(RadiusTokens.input),
      boxShadow: AppColors.cardShadow(context),
      border: Border.all(color: AppColors.cardBorder(context)),
    );
