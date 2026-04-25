import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/providers/household_provider.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/utils/format_number.dart';
import '../../shared/utils/ocr_service.dart';
import '../../shared/widgets/calculator_amount_field.dart';

class BillSplitterScreen extends ConsumerStatefulWidget {
  const BillSplitterScreen({super.key});

  @override
  ConsumerState<BillSplitterScreen> createState() => _BillSplitterScreenState();
}

class _BillSplitterScreenState extends ConsumerState<BillSplitterScreen> {
  final _people = <String>['Me'];
  final _personCtrl = TextEditingController();
  final _items = <_BillItem>[];
  double _tipPercent = 0;
  String? _receiptPath;
  bool _scanning = false;
  bool _manualMode = true;

  // Manual mode fields
  double _totalAmount = 0;
  bool _evenSplit = true;

  String get _baseCurrency =>
      ref.read(householdProvider).value?.baseCurrency ?? 'USD';

  @override
  void dispose() {
    _personCtrl.dispose();
    super.dispose();
  }

  // ─── OCR Scan ──────────────────────────────────────────────────────────────

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
      source: source,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 80,
    );
    if (image == null) return;

    setState(() {
      _scanning = true;
      _receiptPath = image.path;
      _manualMode = false;
    });

    final items = await OcrService.extractLineItems(image.path);

    if (mounted) {
      setState(() {
        _scanning = false;
        _items.clear();
        for (final item in items) {
          _items.add(_BillItem(
            name: item.name,
            amount: item.amount,
            assignedTo: {},
          ));
        }
      });

      if (items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No items detected. Try adding manually.'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  // ─── People Management ─────────────────────────────────────────────────────

  void _addPerson() {
    final name = _personCtrl.text.trim();
    if (name.isEmpty || _people.contains(name)) return;
    setState(() => _people.add(name));
    _personCtrl.clear();
  }

  void _removePerson(int index) {
    if (_people.length <= 1) return;
    final removed = _people[index];
    setState(() {
      _people.removeAt(index);
      for (final item in _items) {
        item.assignedTo.remove(removed);
      }
    });
  }

  // ─── Item Management ───────────────────────────────────────────────────────

  void _addItem() {
    setState(() => _items.add(_BillItem(name: '', amount: 0, assignedTo: {})));
  }

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
  }

  void _toggleAssignment(int itemIdx, String person) {
    setState(() {
      final item = _items[itemIdx];
      if (item.assignedTo.contains(person)) {
        item.assignedTo.remove(person);
      } else {
        item.assignedTo.add(person);
      }
    });
  }

  // ─── Calculations ──────────────────────────────────────────────────────────

  Map<String, double> _calculateSplits() {
    final splits = <String, double>{};
    for (final p in _people) {
      splits[p] = 0;
    }

    if (_manualMode && _evenSplit && _people.isNotEmpty) {
      final perPerson = _totalAmount / _people.length;
      for (final p in _people) {
        splits[p] = perPerson;
      }
    } else {
      // Item-based: each item split among assigned people
      for (final item in _items) {
        if (item.assignedTo.isEmpty || item.amount <= 0) continue;
        final share = item.amount / item.assignedTo.length;
        for (final person in item.assignedTo) {
          splits[person] = (splits[person] ?? 0) + share;
        }
      }
    }

    // Apply tip
    if (_tipPercent > 0) {
      final tipMultiplier = 1 + _tipPercent / 100;
      for (final key in splits.keys) {
        splits[key] = splits[key]! * tipMultiplier;
      }
    }

    return splits;
  }

  // ─── Create Transaction ────────────────────────────────────────────────────

  void _createTransaction() {
    final splits = _calculateSplits();
    final total = splits.values.fold(0.0, (s, v) => s + v);
    final splitDetails = splits.entries
        .map((e) =>
            '${e.key}: ${formatAmount(e.value, currency: _baseCurrency)}')
        .join(', ');
    final note = 'Bill split ($splitDetails)';

    context.push('/add-transaction', extra: {
      'editType': 'expense',
      'editNote': note,
      'editLines': [
        {
          'amount': total,
          'currency': _baseCurrency,
        },
      ],
    });
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final splits = _calculateSplits();
    final grandTotal = splits.values.fold(0.0, (s, v) => s + v);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bill Splitter'),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt_rounded),
            tooltip: 'Scan receipt',
            onPressed: _scanReceipt,
          ),
        ],
      ),
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
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Receipt preview
                if (_receiptPath != null)
                  Container(
                    height: 120,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: FileImage(File(_receiptPath!)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                // Mode toggle
                _card(
                  context,
                  child: Row(
                    children: [
                      Expanded(
                        child: _modeChip('Manual', _manualMode, () {
                          setState(() => _manualMode = true);
                        }),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _modeChip('Items', !_manualMode, () {
                          setState(() => _manualMode = false);
                        }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── People ──
                _sectionHeader(context, 'PEOPLE'),
                const SizedBox(height: 8),
                _card(
                  context,
                  child: Column(
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          for (var i = 0; i < _people.length; i++)
                            Chip(
                              label: Text(_people[i],
                                  style: const TextStyle(fontSize: 13)),
                              deleteIcon: _people.length > 1
                                  ? const Icon(Icons.close, size: 16)
                                  : null,
                              onDeleted: _people.length > 1
                                  ? () => _removePerson(i)
                                  : null,
                              backgroundColor: AppColors.sfv(context),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
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
                                  borderSide: BorderSide.none,
                                ),
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
                              backgroundColor: AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Manual Mode ──
                if (_manualMode) ...[
                  _sectionHeader(context, 'AMOUNT'),
                  const SizedBox(height: 8),
                  _card(
                    context,
                    child: Column(
                      children: [
                        CalculatorAmountField(
                          value: _totalAmount,
                          currency: _baseCurrency,
                          label: 'Total bill',
                          onChanged: (v) =>
                              setState(() => _totalAmount = v),
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Even split',
                              style: TextStyle(fontSize: 14)),
                          value: _evenSplit,
                          onChanged: (v) =>
                              setState(() => _evenSplit = v),
                        ),
                      ],
                    ),
                  ),
                ],

                // ── Items Mode ──
                if (!_manualMode) ...[
                  _sectionHeader(context, 'ITEMS'),
                  const SizedBox(height: 8),
                  for (var i = 0; i < _items.length; i++)
                    _buildItemCard(context, i),
                  TextButton.icon(
                    onPressed: _addItem,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add item'),
                  ),
                ],
                const SizedBox(height: 16),

                // ── Tip ──
                _sectionHeader(context, 'TIP'),
                const SizedBox(height: 8),
                _card(
                  context,
                  child: Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _tipPercent,
                          min: 0,
                          max: 30,
                          divisions: 6,
                          label: '${_tipPercent.round()}%',
                          onChanged: (v) =>
                              setState(() => _tipPercent = v),
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
                  ),
                ),
                const SizedBox(height: 16),

                // ── Summary ──
                _sectionHeader(context, 'SPLIT SUMMARY'),
                const SizedBox(height: 8),
                _card(
                  context,
                  child: Column(
                    children: [
                      for (final entry in splits.entries)
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(entry.key,
                                  style: const TextStyle(fontSize: 14)),
                              Text(
                                formatAmount(entry.value,
                                    currency: _baseCurrency),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.tp(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const Divider(),
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700)),
                          Text(
                            formatAmount(grandTotal,
                                currency: _baseCurrency),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.tp(context),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Create Transaction ──
                FilledButton.icon(
                  onPressed: grandTotal > 0 ? _createTransaction : null,
                  icon: const Icon(Icons.receipt_long_rounded),
                  label: const Text('Create Transaction'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
    );
  }

  Widget _buildItemCard(BuildContext context, int index) {
    final item = _items[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.bd(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: item.name,
                  decoration: InputDecoration(
                    hintText: 'Item name',
                    isDense: true,
                    filled: true,
                    fillColor: AppColors.sfv(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (v) => item.name = v,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 90,
                child: TextFormField(
                  initialValue: item.amount > 0
                      ? item.amount.toStringAsFixed(2)
                      : '',
                  decoration: InputDecoration(
                    hintText: '0.00',
                    isDense: true,
                    filled: true,
                    fillColor: AppColors.sfv(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    prefixText: '\$ ',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (v) {
                    item.amount = double.tryParse(v) ?? 0;
                    setState(() {});
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => _removeItem(index),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                    minWidth: 28, minHeight: 28),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Person assignment chips
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: _people
                .map((p) => GestureDetector(
                      onTap: () => _toggleAssignment(index, p),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: item.assignedTo.contains(p)
                              ? AppColors.accent.withValues(alpha: 0.15)
                              : AppColors.sfv(context),
                          borderRadius: BorderRadius.circular(20),
                          border: item.assignedTo.contains(p)
                              ? Border.all(
                                  color: AppColors.accent
                                      .withValues(alpha: 0.4))
                              : null,
                        ),
                        child: Text(p,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: item.assignedTo.contains(p)
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: item.assignedTo.contains(p)
                                  ? AppColors.accent
                                  : AppColors.ts(context),
                            )),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.bd(context)),
      ),
      child: child,
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Text(title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.ts(context),
          letterSpacing: 0.5,
        ));
  }

  Widget _modeChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withValues(alpha: 0.12)
              : AppColors.sfv(context),
          borderRadius: BorderRadius.circular(10),
          border: selected
              ? Border.all(color: AppColors.accent.withValues(alpha: 0.4))
              : null,
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? AppColors.accent : AppColors.ts(context),
              )),
        ),
      ),
    );
  }

}

class _BillItem {
  String name;
  double amount;
  final Set<String> assignedTo;

  _BillItem({
    required this.name,
    required this.amount,
    required this.assignedTo,
  });
}
