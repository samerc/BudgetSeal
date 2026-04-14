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
import '../../core/providers/allocations_provider.dart';
import '../../core/providers/categories_provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/engine_provider.dart';
import '../../core/providers/tx_colors_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../core/providers/transactions_provider.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/utils/format_number.dart';
import '../../shared/utils/haptics.dart';
import '../../shared/utils/receipt_helper.dart';
import '../../shared/widgets/amount_field.dart';
import 'widgets/category_sheet.dart';
import 'widgets/currency_sheet.dart';
import 'widgets/transaction_form_widgets.dart';

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
  final _noteCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  bool _loading = false;
  final List<LineState> _lines = [];
  String? _validationError;
  List<String> _receiptFilenames = [];
  List<String> _resolvedReceiptPaths = [];

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
        _lines.add(line);
      }
    }

    if (_lines.isEmpty) _addLine();
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    _titleCtrl.dispose();
    for (final l in _lines) {
      l.dispose();
    }
    super.dispose();
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
    return DateFormat('MMMM d, yyyy').format(_selectedDate);
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
          // Auto-fill account from category's default if line has no account.
          if (_lines[lineIndex].accountId == null) {
            final cat = categories.firstWhere((c) => c.id == id,
                orElse: () => categories.first);
            if (cat.defaultAccountId != null) {
              _onLineAccountChanged(lineIndex, cat.defaultAccountId);
            }
          }
        },
        onCreated: (cat) async {
          if (householdId == null) return;
          final db = ref.read(databaseProvider);
          final cats = ref.read(categoriesProvider).value ?? [];
          final color =
              categoryPresetColors[cats.length % categoryPresetColors.length];
          final colorHex =
              '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
          await db.into(db.categories).insert(CategoriesCompanion.insert(
                id: const Uuid().v4(),
                householdId: householdId,
                name: cat,
                colorHex: Value(colorHex),
              ));
        },
      ),
    );
  }

  Future<void> _pickCurrency(int lineIndex) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CurrencySheet(current: _lines[lineIndex].currency),
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

  Future<void> _save() async {
    final error = _validate();
    if (error != null) {
      setState(() => _validationError = error);
      hapticHeavy();
      return;
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
        final db = ref.read(databaseProvider);
        await (db.update(db.transactions)
              ..where((t) => t.id.equals(txId)))
            .write(TransactionsCompanion(
                receiptPath: Value(encodeReceiptPaths(_receiptFilenames))));
      }

      if (mounted) {
        // Build envelope feedback message
        String snackText = 'Transaction saved';
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

        final messenger = ScaffoldMessenger.of(context);
        context.pop();
        messenger.clearSnackBars();
        messenger.showSnackBar(SnackBar(
          content: Text(snackText),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          dismissDirection: DismissDirection.horizontal,
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
            // Quick templates button
            if (widget.editTransactionId == null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/templates'),
                  icon: const Icon(Icons.bolt_rounded, size: 16),
                  label: const Text('Use Template'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: BorderSide(
                        color: AppColors.accent.withValues(alpha: 0.3)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            _buildTypeSelector(),
            const SizedBox(height: 12),
            // Title field with autocomplete
            TxCard(
              child: _buildTitleField(),
            ),
            const SizedBox(height: 12),
            _buildDateRow(),
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
            if (_type == _TxType.transfer) ...[
              _buildTransferSection(accounts),
              const SizedBox(height: 12),
            ],
            if (_type != _TxType.transfer) ...[
              _buildLinesSection(accounts),
              const SizedBox(height: 12),
            ],
            _buildNoteField(),
            const SizedBox(height: 12),
            // Receipt photo
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

  Widget _buildDateRow() {
    return TxCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Date
            Expanded(
              child: InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Text(_dateLabel,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              width: 1,
              height: 24,
              color: AppColors.textHint.withValues(alpha: 0.3),
            ),
            // Time
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: InkWell(
                onTap: _pickTime,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time_rounded,
                          size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Text(_timeLabel,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Transfer section (with FX rate)
  // ---------------------------------------------------------------------------

  Widget _buildTransferSection(List<Account> accounts) {
    final fromAcc = _fromAccountId != null
        ? accounts.firstWhere((a) => a.id == _fromAccountId,
            orElse: () => accounts.first)
        : null;
    final toAcc = _destAccountId != null
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
                        Text('1 ${fromAcc.currency} =',
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary)),
                        const SizedBox(width: 6),
                        SizedBox(
                          width: 80,
                          child: TextField(
                            controller: _lines.first.rateCtrl,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.accent),
                            decoration: const InputDecoration(
                              hintText: '0.00',
                              hintStyle: TextStyle(
                                  fontSize: 13, color: AppColors.textHint),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: (val) {
                              final r =
                                  double.tryParse(val.replaceAll(',', ''));
                              if (r != null && r > 0) {
                                _lines.first.exchangeRateToBase = r;
                              }
                              setState(() {});
                            },
                          ),
                        ),
                        Text(toAcc.currency,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary)),
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
                                color: AppColors.textSecondary),
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
              Icon(icon, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 12),
              Text(hint,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 15)),
            ],
          ),
          icon: const Icon(Icons.chevron_right_rounded,
              size: 18, color: AppColors.textHint),
          items: accounts
              .map((a) => DropdownMenuItem(
                    value: a.id,
                    child: Row(children: [
                      Icon(_accountIcon(a.type),
                          size: 18, color: AppColors.textSecondary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(a.name,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 6),
                      Text(a.currency,
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary)),
                    ]),
                  ))
              .toList(),
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
        OutlinedButton.icon(
          icon: const Icon(Icons.add_rounded, size: 16),
          label: const Text('Add item'),
          style: OutlinedButton.styleFrom(
            foregroundColor: _typeColor(context),
            side: BorderSide(color: _typeColor(context).withValues(alpha: 0.4)),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
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
    // Get unique previous transaction titles for autocomplete.
    final entries =
        ref.read(transactionEntriesProvider).value ?? [];
    final previousTitles = <String>{};
    for (final e in entries) {
      final note = e.tx.note;
      if (note.isNotEmpty) {
        // Extract title part (before " — " if present)
        final title = note.contains(' — ') ? note.split(' — ').first : note;
        if (title.isNotEmpty) previousTitles.add(title);
      }
    }
    final suggestions = previousTitles.toList()..sort();

    return Autocomplete<String>(
      optionsBuilder: (textEditingValue) {
        if (textEditingValue.text.isEmpty) return const Iterable.empty();
        final query = textEditingValue.text.toLowerCase();
        return suggestions
            .where((s) => s.toLowerCase().contains(query))
            .take(5);
      },
      onSelected: (selection) {
        _titleCtrl.text = selection;
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        // Sync with our _titleCtrl
        controller.text = _titleCtrl.text;
        controller.addListener(() {
          if (_titleCtrl.text != controller.text) {
            _titleCtrl.text = controller.text;
          }
        });
        return TextField(
          controller: controller,
          focusNode: focusNode,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Title (e.g. Coffee, Groceries)',
            hintStyle: TextStyle(color: AppColors.textHint),
            prefixIcon: Icon(Icons.edit_rounded,
                size: 18, color: AppColors.textSecondary),
            border: InputBorder.none,
            contentPadding:
                EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200, maxWidth: 300),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (_, i) {
                  final option = options.elementAt(i);
                  return ListTile(
                    dense: true,
                    title: Text(option, style: const TextStyle(fontSize: 14)),
                    leading: const Icon(Icons.history_rounded,
                        size: 16, color: AppColors.textHint),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoteField() {
    return TxCard(
      child: TextField(
        controller: _noteCtrl,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          hintText: 'Add a note…',
          hintStyle: TextStyle(color: AppColors.textHint),
          prefixIcon: Icon(Icons.notes_rounded,
              size: 18, color: AppColors.textSecondary),
          border: InputBorder.none,
          contentPadding:
              EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        maxLines: 3,
        minLines: 1,
      ),
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
                icon: const Icon(Icons.add_rounded,
                    size: 18, color: AppColors.textHint),
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
                icon: const Icon(Icons.close_rounded,
                    size: 18, color: AppColors.textHint),
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

    return OutlinedButton.icon(
      onPressed: () async {
        final filenames = await pickAndSaveReceipts(context);
        if (filenames.isNotEmpty && mounted) {
          _receiptFilenames = filenames;
          _resolveReceiptPaths();
        }
      },
      icon: const Icon(Icons.receipt_long_rounded, size: 16),
      label: const Text('Attach Receipt'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textSecondary,
        side: BorderSide(color: AppColors.bd(context)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
