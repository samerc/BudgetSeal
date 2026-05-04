import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/providers/household_provider.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/utils/format_number.dart';
import '../../shared/utils/ocr_service.dart';
import '../../shared/widgets/currency_picker_field.dart';
import 'widgets/currency_sheet.dart' show kCurrencySymbols;

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
  static const _stepLabels = ['Items', 'Split', 'Review'];

  // ── People ──
  final _people = <String>['Me'];
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
  bool _rateInverted = false;
  final _rateCtrl = TextEditingController();
  bool _currencyExpanded = false;

  // ── OCR ──
  bool _scanning = false;
  OcrResult? _ocrResult;
  final _selectedLineIndices = <int, String>{};
  String? _activePersonForSelection;
  bool _showAllLines = true;

  String get _baseCurrency =>
      ref.read(householdProvider).value?.baseCurrency ?? 'USD';

  @override
  void initState() {
    super.initState();
    _billCurrency = ref.read(householdProvider).value?.baseCurrency ?? 'USD';
  }

  @override
  void dispose() {
    _personCtrl.dispose();
    _rateCtrl.dispose();
    super.dispose();
  }

  // ─── Navigation ───────────────────────────────────────────────────────────

  void _goToStep(int step) => setState(() => _step = step);

  bool get _canProceedFromItems => _items.isNotEmpty;

  bool get _canProceedFromSplit {
    if (_splitEvenly) return true;
    return _items.every((i) => i.assignedTo.isNotEmpty);
  }

  // ─── People ───────────────────────────────────────────────────────────────

  void _addPerson() {
    final name = _personCtrl.text.trim();
    if (name.isEmpty || _people.contains(name)) return;
    setState(() => _people.add(name));
    _personCtrl.clear();
  }

  void _removePerson(String name) {
    if (_people.length <= 1) return;
    setState(() {
      _people.remove(name);
      if (_activePersonForSelection == name) _activePersonForSelection = null;
      _selectedLineIndices.removeWhere((_, p) => p == name);
      final toRemove = <int>[];
      for (var i = 0; i < _items.length; i++) {
        _items[i].assignedTo.remove(name);
        if (_items[i].assignedTo.isEmpty) {
          if (_items[i].ocrLineIndex != null) {
            _selectedLineIndices.remove(_items[i].ocrLineIndex);
          }
          toRemove.add(i);
        }
      }
      for (var i = toRemove.length - 1; i >= 0; i--) {
        _items.removeAt(toRemove[i]);
      }
    });
  }

  // ─── Items ────────────────────────────────────────────────────────────────

  void _addManualItem() {
    setState(() => _items.add(
        _BillItem(name: '', amount: 0, assignedTo: {}, ocrLineIndex: null)));
  }

  void _removeItem(int index) {
    final item = _items[index];
    setState(() {
      _items.removeAt(index);
      if (item.ocrLineIndex != null) {
        final stillReferenced =
            _items.any((i) => i.ocrLineIndex == item.ocrLineIndex);
        if (!stillReferenced) _selectedLineIndices.remove(item.ocrLineIndex);
      }
    });
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
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final image = await picker.pickImage(
        source: source, maxWidth: 2400, maxHeight: 2400, imageQuality: 95);
    if (image == null) return;

    setState(() => _scanning = true);

    final result = await OcrService.scanReceipt(image.path);

    if (mounted) {
      setState(() {
        _scanning = false;
        _ocrResult = result;
        _selectedLineIndices.clear();
        _items.clear();
      });
      if (result.lines.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No text detected. Try a clearer photo.'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  void _onLineTapped(int lineIndex) {
    final line = _ocrResult!.lines[lineIndex];
    if (_selectedLineIndices.containsKey(lineIndex)) {
      setState(() {
        _selectedLineIndices.remove(lineIndex);
        _items.removeWhere((item) => item.ocrLineIndex == lineIndex);
      });
      return;
    }
    if (!line.hasPrice) {
      _promptAmountForLine(lineIndex, line);
      return;
    }
    if (_activePersonForSelection != null) {
      _assignLine(lineIndex, line, _activePersonForSelection!);
    } else {
      _assignLine(lineIndex, line, _people.first);
    }
  }

  void _promptAmountForLine(int lineIndex, OcrLine line) {
    final amountCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter amount'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('OCR: "${line.text}"',
                style: TextStyle(
                    fontSize: 12,
                    color: AppColors.ts(ctx),
                    fontStyle: FontStyle.italic)),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: '0.00',
                labelText: 'Amount',
                filled: true,
                fillColor: AppColors.sfv(ctx),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
              ),
              onSubmitted: (_) {
                final amount =
                    double.tryParse(amountCtrl.text.replaceAll(',', '.'));
                if (amount != null && amount > 0) {
                  Navigator.pop(ctx);
                  final fixedLine = OcrLine(
                    text: line.text,
                    boundingBox: line.boundingBox,
                    parsedAmount: amount,
                    parsedName: line.parsedName ?? line.text.trim(),
                  );
                  _ocrResult!.lines[lineIndex] = fixedLine;
                  _assignLine(lineIndex, fixedLine,
                      _activePersonForSelection ?? _people.first);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final amount =
                  double.tryParse(amountCtrl.text.replaceAll(',', '.'));
              if (amount != null && amount > 0) {
                Navigator.pop(ctx);
                final fixedLine = OcrLine(
                  text: line.text,
                  boundingBox: line.boundingBox,
                  parsedAmount: amount,
                  parsedName: line.parsedName ?? line.text.trim(),
                );
                _ocrResult!.lines[lineIndex] = fixedLine;
                _assignLine(lineIndex, fixedLine,
                    _activePersonForSelection ?? _people.first);
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _assignLine(int lineIndex, OcrLine line, String person) async {
    final qty = line.parsedQuantity;
    final amount = line.parsedAmount ?? 0;
    final name = line.parsedName ?? line.text;

    if (qty > 1 && _people.length > 1) {
      final split = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('$qty × $name'),
          content: Text(
              'Split into $qty items (${formatAmount(amount / qty, currency: _billCurrency)} each)?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Keep as one')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Split')),
          ],
        ),
      );
      if (split == true && mounted) {
        final unitPrice = amount / qty;
        setState(() {
          _selectedLineIndices[lineIndex] = person;
          for (var i = 0; i < qty; i++) {
            _items.add(_BillItem(
              name: '$name (${i + 1}/$qty)',
              amount: unitPrice,
              assignedTo: {person},
              ocrLineIndex: lineIndex,
            ));
          }
        });
        return;
      }
      if (!mounted) return;
    }

    setState(() {
      _selectedLineIndices[lineIndex] = person;
      _items.add(_BillItem(
        name: qty > 1 ? '$name ×$qty' : name,
        amount: amount,
        assignedTo: {person},
        ocrLineIndex: lineIndex,
      ));
    });
  }

  // ─── Calculations ─────────────────────────────────────────────────────────

  Map<String, double> _calculateSplits() {
    final splits = <String, double>{for (final p in _people) p: 0};
    final subtotal = _items.fold(0.0, (s, i) => s + i.amount);

    if (_splitEvenly && subtotal > 0) {
      final perPerson = subtotal / _people.length;
      for (final p in _people) {
        splits[p] = perPerson;
      }
    } else {
      for (final item in _items) {
        if (item.assignedTo.isEmpty || item.amount <= 0) continue;
        final share = item.amount / item.assignedTo.length;
        for (final person in item.assignedTo) {
          splits[person] = (splits[person] ?? 0) + share;
        }
      }
    }

    // Apply tip
    if (_tipIsAmount && _tipAmount > 0) {
      final tipPerPerson = _tipAmount / _people.length;
      for (final key in splits.keys) {
        splits[key] = splits[key]! + tipPerPerson;
      }
    } else if (!_tipIsAmount && _tipPercent > 0) {
      final m = 1 + _tipPercent / 100;
      for (final key in splits.keys) {
        splits[key] = splits[key]! * m;
      }
    }
    return splits;
  }

  double _toBase(double amount) {
    if (_billCurrency == _baseCurrency) return amount;
    if ((_exchangeRate - 1.0).abs() < 0.001) return amount;
    return amount * _exchangeRate;
  }

  // ─── Create Transaction ───────────────────────────────────────────────────

  void _createTransaction() async {
    final isCross = _billCurrency != _baseCurrency;
    final rateNotSet = isCross && (_exchangeRate - 1.0).abs() < 0.001;

    if (rateNotSet) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Exchange rate not set'),
          content: Text(
              'Bill is in $_billCurrency but no rate was entered.\n'
              'The transaction will be saved without conversion.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Go back')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Continue anyway')),
          ],
        ),
      );
      if (proceed != true || !mounted) return;
    }

    final splits = _calculateSplits();
    final myShare = splits[_people.first] ?? 0;
    final total = splits.values.fold(0.0, (s, v) => s + v);
    final others = _people.where((p) => p != _people.first).toList();
    final note = others.isEmpty
        ? 'Bill: ${formatAmount(total, currency: _billCurrency)}'
        : 'Split with ${others.join(", ")} — '
            'Total: ${formatAmount(total, currency: _billCurrency)}';

    if (!mounted) return;
    context.push('/add-transaction', extra: {
      'editType': 'expense',
      'editNote': 'Bill Split — $note',
      'editLines': [
        {
          'amount': myShare,
          'currency': _billCurrency,
          'exchangeRateToBase':
              _billCurrency == _baseCurrency ? 1.0 : _exchangeRate,
        },
      ],
    });
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
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final splits = _calculateSplits();
    final grandTotal = splits.values.fold(0.0, (s, v) => s + v);
    final myShare = splits[_people.first] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bill Splitter'),
        actions: [
          if (_step == 0)
            IconButton(
              icon: const Icon(Icons.camera_alt_rounded),
              tooltip: 'Scan receipt',
              onPressed: _scanReceipt,
            ),
        ],
      ),
      bottomNavigationBar: _scanning ? null : _buildBottomBar(grandTotal, myShare),
      body: _scanning
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Scanning receipt...'),
                ],
              ),
            )
          : Column(
              children: [
                _buildStepIndicator(),
                Expanded(
                  child: _step == 0
                      ? _buildItemsStep()
                      : _step == 1
                          ? _buildSplitStep()
                          : _buildReviewStep(splits, grandTotal),
                ),
              ],
            ),
    );
  }

  // ─── Step Indicator ───────────────────────────────────────────────────────

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 8, 32, 12),
      child: Row(
        children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0)
              Expanded(
                child: Container(
                  height: 2,
                  color: i <= _step ? AppColors.accent : AppColors.bd(context),
                ),
              ),
            GestureDetector(
              onTap: () {
                if (i < _step) _goToStep(i);
                if (i == 1 && _canProceedFromItems) _goToStep(1);
                if (i == 2 && _canProceedFromSplit) _goToStep(2);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: i < _step
                          ? AppColors.accent
                          : i == _step
                              ? AppColors.accent.withValues(alpha: 0.15)
                              : AppColors.sfv(context),
                      shape: BoxShape.circle,
                      border: i == _step
                          ? Border.all(color: AppColors.accent, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: i < _step
                          ? const Icon(Icons.check_rounded,
                              size: 14, color: Colors.white)
                          : Text('${i + 1}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: i == _step
                                    ? AppColors.accent
                                    : AppColors.ts(context),
                              )),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(_stepLabels[i],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            i == _step ? FontWeight.w700 : FontWeight.w500,
                        color: i == _step
                            ? AppColors.accent
                            : AppColors.ts(context),
                      )),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Step 0: Items ────────────────────────────────────────────────────────

  Widget _buildItemsStep() {
    if (_items.isEmpty && _ocrResult == null) {
      // Empty state — show entry points
      return Center(
          child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.receipt_long_rounded,
                  size: 56, color: AppColors.ts(context)),
              const SizedBox(height: 16),
              Text('Add items to split',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.tp(context))),
              const SizedBox(height: 8),
              Text('Scan a receipt or add items manually',
                  style: TextStyle(
                      fontSize: 14, color: AppColors.ts(context))),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _scanReceipt,
                  icon: const Icon(Icons.camera_alt_rounded, size: 20),
                  label: const Text('Scan Receipt'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _addManualItem,
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: const Text('Add Manually'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Has items or OCR result
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        // OCR detected lines
        if (_ocrResult != null) ...[
          _buildDetectedLinesList(),
          const SizedBox(height: 12),
        ],

        // Items list
        if (_items.isNotEmpty) ...[
          for (var i = 0; i < _items.length; i++)
            Dismissible(
              key: ValueKey('item-$i-${_items[i].name}'),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16),
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: AppColors.overspent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.delete_rounded,
                    color: AppColors.overspent),
              ),
              onDismissed: (_) => _removeItem(i),
              child: _buildItemTile(i),
            ),
        ],

        // Add more
        TextButton.icon(
          onPressed: _addManualItem,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Add item'),
        ),
      ],
    );
  }

  Widget _buildItemTile(int index) {
    final item = _items[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.bd(context)),
      ),
      child: Row(
        children: [
          if (item.assignedTo.isNotEmpty)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: _personColor(item.assignedTo.first),
                shape: BoxShape.circle,
              ),
            ),
          Expanded(
            child: item.ocrLineIndex != null
                ? Text(item.name,
                    style: const TextStyle(fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis)
                : TextFormField(
                    initialValue: item.name,
                    decoration: const InputDecoration(
                      hintText: 'Item name',
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: const TextStyle(fontSize: 13),
                    onChanged: (v) => item.name = v,
                  ),
          ),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 60, maxWidth: 140),
            child: item.ocrLineIndex != null
                ? Text(
                    formatAmount(item.amount, currency: _billCurrency),
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.tp(context)),
                    textAlign: TextAlign.end,
                  )
                : IntrinsicWidth(
                    child: TextFormField(
                      initialValue: item.amount > 0
                          ? (item.amount % 1 == 0
                              ? item.amount.toInt().toString()
                              : item.amount.toStringAsFixed(2))
                          : '',
                      decoration: const InputDecoration(
                        hintText: '0.00',
                        isDense: true,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: const TextStyle(fontSize: 13),
                      textAlign: TextAlign.end,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      onChanged: (v) {
                        item.amount = double.tryParse(v) ?? 0;
                        setState(() {});
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ─── Step 1: Split ────────────────────────────────────────────────────────

  Widget _buildSplitStep() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        // People management
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('WHO\'S SPLITTING?',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: AppColors.ts(context))),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  for (final p in _people)
                    _personChip(p),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _personCtrl,
                      decoration: InputDecoration(
                        hintText: 'Add person',
                        isDense: true,
                        filled: true,
                        fillColor: AppColors.sfv(context),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none),
                      ),
                      textCapitalization: TextCapitalization.words,
                      onSubmitted: (_) => _addPerson(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _addPerson,
                    icon: const Icon(Icons.add, size: 18),
                    style: IconButton.styleFrom(
                        backgroundColor: AppColors.accent),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Split evenly toggle
        _card(
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Split evenly',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: Text(
                'Each person pays ${formatAmount(_items.fold(0.0, (s, i) => s + i.amount) / (_people.isNotEmpty ? _people.length : 1), currency: _billCurrency)}',
                style: TextStyle(fontSize: 12, color: AppColors.ts(context))),
            value: _splitEvenly,
            onChanged: (v) => setState(() => _splitEvenly = v),
          ),
        ),
        const SizedBox(height: 12),

        // Per-item assignment (only when not splitting evenly)
        if (!_splitEvenly && _people.length > 1) ...[
          Text('ASSIGN ITEMS',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: AppColors.ts(context))),
          const SizedBox(height: 8),
          for (var i = 0; i < _items.length; i++) _buildAssignableItem(i),
        ],
      ],
    );
  }

  Widget _personChip(String name) {
    final color = _personColor(name);
    final isActive = _activePersonForSelection == name;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activePersonForSelection = isActive ? null : name;
        });
        HapticFeedback.selectionClick();
      },
      onLongPress: _people.length > 1 ? () => _removePerson(name) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.2) : AppColors.sfv(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? color : AppColors.bd(context),
            width: isActive ? 2 : 1,
          ),
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
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: AppColors.tp(context))),
            if (_people.length > 1 && name != _people.first) ...[
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
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.bd(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(item.name.isEmpty ? 'Item ${index + 1}' : item.name,
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
            children: _people.map((p) {
              final assigned = item.assignedTo.contains(p);
              final color = _personColor(p);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (assigned) {
                      item.assignedTo.remove(p);
                    } else {
                      item.assignedTo.add(p);
                    }
                  });
                  HapticFeedback.selectionClick();
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: assigned
                        ? color.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: assigned
                          ? color
                          : AppColors.bd(context),
                    ),
                  ),
                  child: Text(p,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            assigned ? FontWeight.w600 : FontWeight.w400,
                        color: assigned ? color : AppColors.ts(context),
                      )),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── Step 2: Review ───────────────────────────────────────────────────────

  Widget _buildReviewStep(Map<String, double> splits, double grandTotal) {
    final isCross = _billCurrency != _baseCurrency;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        // Per-person summary
        _card(
          child: Column(
            children: [
              for (final entry in splits.entries)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Container(
                        width: 10, height: 10,
                        decoration: BoxDecoration(
                          color: _personColor(entry.key),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(entry.key,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: entry.key == _people.first
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: AppColors.tp(context))),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            formatAmount(entry.value, currency: _billCurrency),
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.tp(context)),
                          ),
                          if (isCross && (_exchangeRate - 1.0).abs() >= 0.001)
                            Text(
                              '≈ ${formatAmount(_toBase(entry.value), currency: _baseCurrency)}',
                              style: TextStyle(
                                  fontSize: 11, color: AppColors.ts(context)),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              Divider(color: AppColors.bd(context)),
              Row(
                children: [
                  Expanded(
                      child: Text('Total',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.tp(context)))),
                  Text(formatAmount(grandTotal, currency: _billCurrency),
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.tp(context))),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Tip (collapsible)
        _collapsibleCard(
          title: 'Tip',
          trailing: _tipPercent > 0 || _tipAmount > 0
              ? _tipIsAmount
                  ? formatAmount(_tipAmount, currency: _billCurrency)
                  : '${_tipPercent.round()}%'
              : 'None',
          expanded: _tipExpanded,
          onTap: () => setState(() => _tipExpanded = !_tipExpanded),
          child: Column(
            children: [
              // Toggle
              Row(
                children: [
                  _segmentButton('Percentage', !_tipIsAmount,
                      () => setState(() => _tipIsAmount = false)),
                  const SizedBox(width: 8),
                  _segmentButton('Amount', _tipIsAmount,
                      () => setState(() => _tipIsAmount = true)),
                ],
              ),
              const SizedBox(height: 12),
              if (!_tipIsAmount)
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: _tipPercent,
                        min: 0, max: 30, divisions: 6,
                        label: '${_tipPercent.round()}%',
                        onChanged: (v) => setState(() => _tipPercent = v),
                      ),
                    ),
                    SizedBox(
                      width: 50,
                      child: Text('${_tipPercent.round()}%',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.tp(context))),
                    ),
                  ],
                )
              else
                TextField(
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: '0.00',
                    labelText: 'Tip amount',
                    prefixText:
                        '${kCurrencySymbols[_billCurrency] ?? _billCurrency} ',
                    isDense: true,
                    filled: true,
                    fillColor: AppColors.sfv(context),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none),
                  ),
                  onChanged: (v) =>
                      setState(() => _tipAmount = double.tryParse(v) ?? 0),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Currency (collapsible, hidden if same as base)
        _collapsibleCard(
          title: 'Currency',
          trailing: _billCurrency,
          expanded: _currencyExpanded,
          onTap: () => setState(() => _currencyExpanded = !_currencyExpanded),
          child: Column(
            children: [
              CurrencyPickerField(
                value: _billCurrency,
                label: 'Bill currency',
                onChanged: (c) => setState(() {
                  _billCurrency = c;
                  if (c == _baseCurrency) _exchangeRate = 1.0;
                }),
              ),
              if (isCross) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                        '1 ${_rateInverted ? _baseCurrency : _billCurrency} = ',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.ts(context))),
                    Expanded(
                      child: TextField(
                        controller: _rateCtrl,
                        decoration: InputDecoration(
                          hintText: 'Rate',
                          isDense: true,
                          filled: true,
                          fillColor: AppColors.sfv(context),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        onChanged: (v) {
                          final r = double.tryParse(v) ?? 0;
                          if (r > 0) {
                            _exchangeRate = _rateInverted ? 1.0 / r : r;
                          }
                          setState(() {});
                        },
                      ),
                    ),
                    Text(
                        ' ${_rateInverted ? _billCurrency : _baseCurrency}',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.ts(context))),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _rateInverted = !_rateInverted;
                          if (_exchangeRate > 0 && _exchangeRate != 1.0) {
                            final display = _rateInverted
                                ? 1.0 / _exchangeRate
                                : _exchangeRate;
                            _rateCtrl.text = display
                                .toStringAsFixed(display >= 1 ? 2 : 6);
                          }
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
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ─── Bottom Bar ───────────────────────────────────────────────────────────

  Widget _buildBottomBar(double grandTotal, double myShare) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        border: Border(top: BorderSide(color: AppColors.bd(context))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Total display
            if (_items.isNotEmpty)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _step == 2
                          ? 'Your share'
                          : 'Total: ${_items.length} items',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.ts(context)),
                    ),
                    Text(
                      _step == 2
                          ? formatAmount(myShare, currency: _billCurrency)
                          : formatAmount(
                              _items.fold(0.0, (s, i) => s + i.amount),
                              currency: _billCurrency),
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.tp(context)),
                    ),
                  ],
                ),
              )
            else
              const Spacer(),

            // Action button
            if (_step == 0)
              FilledButton(
                onPressed: _canProceedFromItems ? () => _goToStep(1) : null,
                child: const Text('Next'),
              )
            else if (_step == 1)
              Row(
                children: [
                  TextButton(
                    onPressed: () => _goToStep(0),
                    child: const Text('Back'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed:
                        _canProceedFromSplit ? () => _goToStep(2) : null,
                    child: const Text('Next'),
                  ),
                ],
              )
            else
              Row(
                children: [
                  TextButton(
                    onPressed: () => _goToStep(1),
                    child: const Text('Back'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed:
                        grandTotal > 0 && myShare > 0
                            ? _createTransaction
                            : null,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Save'),
                  ),
                ],
              ),
          ],
        ),
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
        border: Border.all(color: AppColors.bd(context)),
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
        border: Border.all(color: AppColors.bd(context)),
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
                ? AppColors.accent.withValues(alpha: 0.12)
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
              Text('$detected lines ($withPrice with prices)',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.ts(context))),
              const Spacer(),
              TextButton(
                onPressed: _scanReceipt,
                style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 30)),
                child:
                    const Text('Re-scan', style: TextStyle(fontSize: 12)),
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
              border: Border.all(color: AppColors.bd(context)),
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
                        color: _selectedLineIndices.containsKey(i)
                            ? _personColor(_selectedLineIndices[i]!)
                                .withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          if (_selectedLineIndices.containsKey(i))
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Icon(Icons.check_circle_rounded,
                                  size: 14,
                                  color: _personColor(
                                      _selectedLineIndices[i]!)),
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
                                  color: AppColors.accent),
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
