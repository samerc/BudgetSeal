import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
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
import 'widgets/category_sheet.dart';
import 'widgets/currency_sheet.dart';
import 'widgets/transaction_form_widgets.dart';

bool _isEmoji(String s) => s.isNotEmpty && s.runes.first > 255;

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
    final acc = accounts.firstWhere((a) => a.id == accountId);

    setState(() {
      _lines[lineIndex].accountId = accountId;
      _lines[lineIndex].accountName = acc.name;
      _lines[lineIndex].currency = acc.currency;
      _validationError = null;
    });

    if (acc.currency != _baseCurrency) {
      await _fetchRate(lineIndex, acc.currency);
    } else {
      setState(() {
        _lines[lineIndex].exchangeRateToBase = 1.0;
        _lines[lineIndex].rateCtrl.text = '';
      });
    }

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
          if (cat != null && mounted) {
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
          _lines[lineIndex].exchangeRateToBase = 1.0 / rate;
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
    final fromAcc = accounts.firstWhere((a) => a.id == _fromAccountId);
    final toAcc = accounts.firstWhere((a) => a.id == _destAccountId);
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
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
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
          final afSettings = ref.read(autofillProvider);
          final entries = ref.read(transactionEntriesProvider).value ?? [];
          final fill = lookupAutofill(
            categoryId: id,
            entries: entries,
            settings: afSettings,
          );
          if (fill.hasData) {
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
          await db.into(db.categories).insert(CategoriesCompanion.insert(
                id: newId,
                householdId: householdId,
                name: name,
                colorHex: Value(colorHex),
                transactionType: Value(txType),
              ));
          ref.invalidate(categoriesProvider);
          if (mounted) {
            // Auto-select the newly created category
            setState(() {
              _lines[lineIndex].categoryId = newId;
              _lines[lineIndex].categoryName = name;
              _lines[lineIndex].categoryColor = color;
            });
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          }
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
    if (result != null && mounted) {
      setState(() => _lines[lineIndex].currency = result);
      if (result != _baseCurrency) {
        await _fetchRate(lineIndex, result);
      } else {
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
      if (_fromAccountId == null) return 'Select a source account';
      if (_destAccountId == null) return 'Select a destination account';
      if (_fromAccountId == _destAccountId) {
        return 'Source and destination must differ';
      }
      if (_lines.isEmpty || _lines.first.amount <= 0) {
        return 'Enter an amount';
      }
    } else {
      for (var i = 0; i < _lines.length; i++) {
        final l = _lines[i];
        if (l.accountId == null) {
          return 'Select an account for ${_lines.length > 1 ? "item ${i + 1}" : "the transaction"}';
        }
        if (l.amount <= 0) {
          return 'Enter an amount for ${_lines.length > 1 ? "item ${i + 1}" : "the transaction"}';
        }
      }
    }
    return null;
  }

  /// Check if a transaction with the same amount, category, and date exists.
  bool _checkForDuplicate() {
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
        if (existing.tx.categoryId == line.categoryId) return true;
        for (final el in existing.lines) {
          if (el.categoryId == line.categoryId) return true;
        }
      }
    }
    return false;
  }

  Future<void> _save() async {
    final error = _validate();
    if (error != null) {
      setState(() => _validationError = error);
      hapticHeavy();
      return;
    }

    // Warn if any line has a foreign currency with no exchange rate set
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
        builder: (_) => AlertDialog(
          title: const Text('Exchange rate not set'),
          content: Text(
            '$items has no exchange rate to $_baseCurrency. '
            'The amount won\'t be included in your base currency totals.\n\n'
            'Save anyway, or go back to set the rate?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Go Back'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save Anyway'),
            ),
          ],
        ),
      );
      if (proceed != true || !mounted) return;
    }

    // Duplicate detection (skip when editing existing transaction)
    if (widget.editTransactionId == null && _type != _TxType.transfer) {
      final isDuplicate = _checkForDuplicate();
      if (isDuplicate && mounted) {
        final proceed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Possible Duplicate'),
            content: const Text(
              'A similar transaction with the same amount, category, '
              'and date already exists. Save anyway?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Save Anyway'),
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

      // If editing, delete the old transaction first.
      if (widget.editTransactionId != null) {
        await engine.deleteTransaction(widget.editTransactionId!);
      }

      final title = _titleCtrl.text.trim();
      final note = _noteCtrl.text.trim();
      final effectiveNote =
          title.isNotEmpty && note.isNotEmpty
              ? '$title — $note'
              : title.isNotEmpty
                  ? title
                  : note;

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
                  note: l.noteCtrl.text.trim(),
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
      String snackText = 'Transaction saved';
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
                    'Transaction saved \u00b7 ${alloc.data.allocation.name} envelope updated';
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error saving: $e'),
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

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editTransactionId != null
            ? 'Edit'
            : 'New Transaction'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: _loading ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: _typeColor(context),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                minimumSize: Size.zero,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              icon: _loading
                  ? const SizedBox(
                      height: 14,
                      width: 14,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.check_rounded, size: 18),
              label: const Text('Save',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Type selector + template
            Row(
              children: [
                Expanded(child: _buildTypeSelector()),
                if (widget.editTransactionId == null) ...[
                  const SizedBox(width: 10),
                  IconButton(
                    tooltip: 'Use Template',
                    onPressed: () => context.push('/templates'),
                    icon: Icon(Icons.bolt_rounded,
                        color: AppColors.accent, size: 22),
                    style: IconButton.styleFrom(
                      backgroundColor:
                          AppColors.accent.withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),

            // Category hero banner — only show when category is selected
            if (_type != _TxType.transfer &&
                _lines.isNotEmpty &&
                _lines.first.categoryId != null) ...[
              _buildCategoryHero(context),
              const SizedBox(height: 12),
            ],

            // Title
            _TxFieldCard(
              child: _buildTitleField(),
            ),
            const SizedBox(height: 8),

            // Date + Time
            _TxFieldCard(
              child: _buildDateRowInline(),
            ),
            const SizedBox(height: 8),

            // Note
            _TxFieldCard(
              child: TextField(
                controller: _noteCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Add a note…',
                  hintStyle: TextStyle(color: AppColors.th(context)),
                  prefixIcon: Icon(Icons.notes_rounded,
                      size: 18, color: AppColors.ts(context)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
                maxLines: 3,
                minLines: 1,
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

            // Receipt
            _buildReceiptButton(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Type selector
  // ---------------------------------------------------------------------------

  Widget _buildCategoryHero(BuildContext context) {
    final line = _lines.first;
    final cat = line.categoryId != null
        ? (ref.read(categoriesProvider).value ?? [])
            .where((c) => c.id == line.categoryId)
            .firstOrNull
        : null;

    final typeColor = _typeColor(context);
    final catColor = cat?.colorHex != null
        ? AppColors.fromHex(cat!.colorHex)
        : typeColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: catColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(CardTokens.radius),
        border: Border.all(color: catColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          // Category icon
          Container(
            width: CategoryIconTokens.listSize,
            height: CategoryIconTokens.listSize,
            decoration: BoxDecoration(
              color: catColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: cat != null && cat.icon.isNotEmpty && _isEmoji(cat.icon)
                  ? Text(cat.icon, style: const TextStyle(fontSize: 22))
                  : Icon(
                      _type == _TxType.income
                          ? Icons.arrow_downward_rounded
                          : Icons.arrow_upward_rounded,
                      size: 22,
                      color: catColor,
                    ),
            ),
          ),
          const SizedBox(width: 14),
          // Category name + amount
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatAmount(_totalBaseAmount, currency: _baseCurrency),
                  style: TextStyle(
                    fontSize: TypographyTokens.amountLargeSize,
                    fontWeight: TypographyTokens.amountLargeWeight,
                    color: AppColors.tp(context),
                  ),
                ),
                if (cat != null) ...[
                  Text(
                    cat.name,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.ts(context),
                    ),
                  ),
                  if (_autoFilled)
                    Text(
                      'Auto-detected',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.accent.withValues(alpha: 0.7),
                      ),
                    ),
                ] else
                  Text(
                    'No category',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.th(context),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Row(
      children: [
        TypeChip(
          label: 'Income',
          icon: Icons.arrow_downward_rounded,
          selected: _type == _TxType.income,
          color: AppColors.healthy,
          onTap: () => setState(() {
            _type = _TxType.income;
            if (_lines.isEmpty) _addLine();
          }),
        ),
        const SizedBox(width: 8),
        TypeChip(
          label: 'Expense',
          icon: Icons.arrow_upward_rounded,
          selected: _type == _TxType.expense,
          color: AppColors.overspent,
          onTap: () => setState(() {
            _type = _TxType.expense;
            if (_lines.isEmpty) _addLine();
          }),
        ),
        const SizedBox(width: 8),
        TypeChip(
          label: 'Transfer',
          icon: Icons.swap_horiz_rounded,
          selected: _type == _TxType.transfer,
          color: AppColors.accent,
          onTap: () => setState(() {
            _type = _TxType.transfer;
            if (_lines.isEmpty) _addLine();
          }),
        ),
      ],
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
            padding: const EdgeInsets.only(left: 12),
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

    return TxCard(
      child: Column(
        children: [
          // From account
          _buildAccountDropdown(
            value: _fromAccountId,
            hint: 'From account',
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
            hint: 'To account',
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
          if (_lines.isNotEmpty) ...[
            const TxDivider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: AmountField(
                      controller: _lines.first.amountCtrl,
                      onChanged: () => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  CurrencyBadge(
                      currency: _lines.first.currency),
                ],
              ),
            ),
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
                            'Destination receives:',
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
            padding: const EdgeInsets.only(bottom: 10),
            child: LineCard(
              line: line,
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
        TextButton.icon(
          icon: Icon(Icons.add_rounded, size: 16, color: AppColors.accent),
          label: Text('Add item',
              style: TextStyle(color: AppColors.accent)),
          onPressed: _addLine,
        ),
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
                      ? 'Total ($_baseCurrency)'
                      : 'Total',
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
            .where((s) => s.toLowerCase().contains(query))
            .take(5)
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _titleCtrl,
          textCapitalization: TextCapitalization.sentences,
          onChanged: _onTitleChanged,
          decoration: InputDecoration(
            hintText: 'Title (e.g. Coffee, Groceries)',
            hintStyle: TextStyle(color: AppColors.th(context)),
            prefixIcon: Icon(Icons.edit_rounded,
                size: 18, color: AppColors.ts(context)),
            border: InputBorder.none,
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
                      maxWidth: MediaQuery.of(context).size.width * 0.42,
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

  Widget _buildReceiptButton() {
    if (_receiptFilenames.isNotEmpty) {
      return TxCard(
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
                      ? 'Receipt attached'
                      : '${_receiptFilenames.length} receipts attached',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.healthy),
                ),
              ),
              IconButton(
                icon: Icon(Icons.add_rounded,
                    size: 18, color: AppColors.th(context)),
                tooltip: 'Add more',
                onPressed: () async {
                  final newFilenames = await pickAndSaveReceipts(context);
                  if (newFilenames.isNotEmpty && mounted) {
                    _receiptFilenames = [..._receiptFilenames, ...newFilenames];
                    _resolveReceiptPaths();
                  }
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
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton.icon(
          onPressed: () async {
            final filenames = await pickAndSaveReceipts(context, fromCamera: true);
            if (filenames.isNotEmpty && mounted) {
              _receiptFilenames = filenames;
              _resolveReceiptPaths();
            }
          },
          icon: Icon(Icons.camera_alt_rounded,
              size: 16, color: AppColors.ts(context)),
          label: Text('Scan Receipt',
              style: TextStyle(color: AppColors.ts(context), fontSize: 13)),
        ),
        Container(
            width: 1,
            height: 20,
            color: AppColors.bd(context)),
        TextButton.icon(
          onPressed: () async {
            final filenames = await pickAndSaveReceipts(context);
            if (filenames.isNotEmpty && mounted) {
              _receiptFilenames = filenames;
              _resolveReceiptPaths();
            }
          },
          icon: Icon(Icons.image_rounded,
              size: 16, color: AppColors.ts(context)),
          label: Text('Gallery',
              style: TextStyle(color: AppColors.ts(context), fontSize: 13)),
        ),
      ],
    );
  }

  IconData _accountIcon(String type) => switch (type) {
        'bank' => Icons.account_balance_rounded,
        'credit' => Icons.credit_card_rounded,
        'wallet' => Icons.account_balance_wallet_rounded,
        _ => Icons.money_rounded,
      };
}

/// Consistent styled field card for the transaction form.
/// Lighter background than TxCard, subtle border, same radius.
class _TxFieldCard extends StatelessWidget {
  final Widget child;
  const _TxFieldCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.sfv(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.bd(context).withValues(alpha: 0.5)),
      ),
      child: child,
    );
  }
}
