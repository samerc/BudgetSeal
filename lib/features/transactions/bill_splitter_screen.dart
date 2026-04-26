import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/providers/household_provider.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/utils/format_number.dart';
import '../../shared/utils/ocr_service.dart';
import 'dart:ui' as ui;

import '../../shared/widgets/currency_picker_field.dart';

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
  bool _scanning = false;

  // Bill currency (may differ from base)
  late String _billCurrency;
  double _exchangeRate = 1.0; // billCurrency → baseCurrency

  // OCR state
  String? _receiptPath;
  OcrResult? _ocrResult;
  final _selectedLineIndices = <int, String>{}; // lineIndex → personName
  String? _activePersonForSelection; // pre-selected person for tap assignment

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
    super.dispose();
  }

  // ─── Receipt Scan ──────────────────────────────────────────────────────────

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
      imageQuality: 85,
    );
    if (image == null) return;

    setState(() {
      _scanning = true;
      _receiptPath = image.path;
    });

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

  // ─── Line Selection ────────────────────────────────────────────────────────

  void _onLineTapped(int lineIndex) {
    final line = _ocrResult!.lines[lineIndex];

    // Already selected? Deselect
    if (_selectedLineIndices.containsKey(lineIndex)) {
      setState(() {
        _selectedLineIndices.remove(lineIndex);
        _items.removeWhere((item) => item.ocrLineIndex == lineIndex);
      });
      return;
    }

    // If a person is pre-selected, assign directly
    if (_activePersonForSelection != null) {
      _assignLineToPersons(lineIndex, line, _activePersonForSelection!);
      return;
    }

    // No person pre-selected: show popup to pick person
    _showPersonPickerForLine(lineIndex, line);
  }

  void _assignLineToPersons(int lineIndex, OcrLine line, String person) {
    setState(() {
      _selectedLineIndices[lineIndex] = person;
      _items.add(_BillItem(
        name: line.parsedName ?? line.text,
        amount: line.parsedAmount ?? 0,
        assignedTo: {person},
        ocrLineIndex: lineIndex,
      ));
    });
  }

  void _showPersonPickerForLine(int lineIndex, OcrLine line) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.sf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Assign to:',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.tp(ctx))),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _people.map((p) {
                  final color = _personColor(p);
                  return ActionChip(
                    label: Text(p),
                    backgroundColor: color.withValues(alpha: 0.15),
                    side: BorderSide(color: color.withValues(alpha: 0.3)),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _assignLineToPersons(lineIndex, line, p);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ─── People ────────────────────────────────────────────────────────────────

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
      if (_activePersonForSelection == removed) {
        _activePersonForSelection = null;
      }
      // Remove items assigned to this person
      _selectedLineIndices.removeWhere((_, p) => p == removed);
      _items.removeWhere((item) => item.assignedTo.contains(removed));
    });
  }

  // ─── Manual Item ───────────────────────────────────────────────────────────

  void _addManualItem() {
    setState(() => _items.add(_BillItem(
        name: '', amount: 0, assignedTo: {}, ocrLineIndex: null)));
  }

  void _removeItem(int index) {
    final item = _items[index];
    setState(() {
      if (item.ocrLineIndex != null) {
        _selectedLineIndices.remove(item.ocrLineIndex);
      }
      _items.removeAt(index);
    });
  }

  // ─── Calculations ──────────────────────────────────────────────────────────

  Map<String, double> _calculateSplits() {
    final splits = <String, double>{};
    for (final p in _people) {
      splits[p] = 0;
    }

    for (final item in _items) {
      if (item.assignedTo.isEmpty || item.amount <= 0) continue;
      final share = item.amount / item.assignedTo.length;
      for (final person in item.assignedTo) {
        splits[person] = (splits[person] ?? 0) + share;
      }
    }

    if (_tipPercent > 0) {
      final tipMultiplier = 1 + _tipPercent / 100;
      for (final key in splits.keys) {
        splits[key] = splits[key]! * tipMultiplier;
      }
    }

    return splits;
  }

  double _toBase(double amount) {
    if (_billCurrency == _baseCurrency) return amount;
    if ((_exchangeRate - 1.0).abs() < 0.001) return amount; // rate not set
    return amount * _exchangeRate;
  }

  // ─── Create Transaction ────────────────────────────────────────────────────

  void _createTransaction() {
    final splits = _calculateSplits();
    final myName = _people.first;
    final myShare = splits[myName] ?? 0;
    final total = splits.values.fold(0.0, (s, v) => s + v);
    final otherPeople = _people.where((p) => p != myName).toList();
    final note = otherPeople.isEmpty
        ? 'Bill: ${formatAmount(total, currency: _billCurrency)}'
        : 'Split with ${otherPeople.join(", ")} — '
            'Total: ${formatAmount(total, currency: _billCurrency)}';

    context.push('/add-transaction', extra: {
      'editType': 'expense',
      'editNote': note,
      'editLines': [
        {
          'amount': myShare,
          'currency': _billCurrency,
          'exchangeRateToBase': _billCurrency == _baseCurrency ? 1.0 : _exchangeRate,
        },
      ],
    });
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  Color _personColor(String person) {
    const colors = [
      Color(0xFF6366F1), Color(0xFF10B981), Color(0xFFF59E0B),
      Color(0xFFEF4444), Color(0xFF8B5CF6), Color(0xFF06B6D4),
      Color(0xFFEC4899), Color(0xFFFF7043),
    ];
    return colors[_people.indexOf(person) % colors.length];
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final splits = _calculateSplits();
    final grandTotal = splits.values.fold(0.0, (s, v) => s + v);
    final isCrossCurrency = _billCurrency != _baseCurrency;

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
                // ── Receipt Image with OCR overlay ──
                if (_receiptPath != null && _ocrResult != null)
                  _buildReceiptOverlay(),
                if (_receiptPath != null) const SizedBox(height: 16),

                // ── People ──
                _sectionHeader(context, 'PEOPLE'),
                const SizedBox(height: 8),
                _card(
                  context,
                  child: Column(
                    children: [
                      // Active person selector (for tap-to-assign mode)
                      if (_ocrResult != null) ...[
                        Text('Tap a person, then tap items on the receipt:',
                            style: TextStyle(
                                fontSize: 11, color: AppColors.ts(context))),
                        const SizedBox(height: 8),
                      ],
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          for (var i = 0; i < _people.length; i++)
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _activePersonForSelection =
                                      _activePersonForSelection == _people[i]
                                          ? null
                                          : _people[i];
                                });
                              },
                              onLongPress: _people.length > 1
                                  ? () => _removePerson(i)
                                  : null,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _activePersonForSelection == _people[i]
                                      ? _personColor(_people[i])
                                          .withValues(alpha: 0.2)
                                      : AppColors.sfv(context),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _activePersonForSelection == _people[i]
                                        ? _personColor(_people[i])
                                        : AppColors.bd(context),
                                    width: _activePersonForSelection == _people[i]
                                        ? 2
                                        : 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: _personColor(_people[i]),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(_people[i],
                                        style: TextStyle(
                                            fontSize: 13,
                                            fontWeight:
                                                _activePersonForSelection ==
                                                        _people[i]
                                                    ? FontWeight.w700
                                                    : FontWeight.w500,
                                            color: AppColors.tp(context))),
                                  ],
                                ),
                              ),
                            ),
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
                                backgroundColor: AppColors.accent),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Bill Currency ──
                _sectionHeader(context, 'BILL CURRENCY'),
                const SizedBox(height: 8),
                _card(
                  context,
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
                      if (isCrossCurrency) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text('1 $_billCurrency = ',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.ts(context))),
                            Expanded(
                              child: TextFormField(
                                initialValue: _exchangeRate != 1.0
                                    ? _exchangeRate.toString()
                                    : '',
                                decoration: InputDecoration(
                                  hintText: 'Rate to $_baseCurrency',
                                  isDense: true,
                                  filled: true,
                                  fillColor: AppColors.sfv(context),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                keyboardType: const TextInputType
                                    .numberWithOptions(decimal: true),
                                onChanged: (v) {
                                  _exchangeRate = double.tryParse(v) ?? 1.0;
                                },
                              ),
                            ),
                            Text(' $_baseCurrency',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.ts(context))),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Selected Items ──
                _sectionHeader(context, 'ITEMS (${_items.length})'),
                const SizedBox(height: 8),
                for (var i = 0; i < _items.length; i++)
                  _buildItemCard(context, i),
                TextButton.icon(
                  onPressed: _addManualItem,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add item manually'),
                ),
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
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _personColor(entry.key),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(entry.key,
                                    style: const TextStyle(fontSize: 14)),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    formatAmount(entry.value,
                                        currency: _billCurrency),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.tp(context),
                                    ),
                                  ),
                                  if (isCrossCurrency &&
                                      (_exchangeRate - 1.0).abs() >= 0.001)
                                    Text(
                                      '≈ ${formatAmount(_toBase(entry.value), currency: _baseCurrency)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.ts(context),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      const Divider(),
                      Row(
                        children: [
                          const Expanded(
                            child: Text('Total',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700)),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                formatAmount(grandTotal,
                                    currency: _billCurrency),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.tp(context),
                                ),
                              ),
                              if (isCrossCurrency &&
                                  (_exchangeRate - 1.0).abs() >= 0.001)
                                Text(
                                  '≈ ${formatAmount(_toBase(grandTotal), currency: _baseCurrency)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.ts(context),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                FilledButton.icon(
                  onPressed: grandTotal > 0 ? _createTransaction : null,
                  icon: const Icon(Icons.receipt_long_rounded),
                  label: Text(
                      'Create Transaction (${formatAmount(splits[_people.first] ?? 0, currency: _billCurrency)})'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
    );
  }

  // ─── Receipt Image with Tappable OCR Overlay ───────────────────────────────

  Widget _buildReceiptOverlay() {
    final result = _ocrResult!;
    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.document_scanner_rounded,
                  size: 16, color: AppColors.ts(context)),
              const SizedBox(width: 8),
              Text('Tap items to assign them',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.tp(context))),
              const Spacer(),
              TextButton(
                onPressed: _scanReceipt,
                child: const Text('Re-scan', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    // Receipt image
                    Image.file(
                      File(_receiptPath!),
                      width: constraints.maxWidth,
                      fit: BoxFit.fitWidth,
                    ),
                    // OCR line overlays
                    Positioned.fill(
                      child: LayoutBuilder(
                        builder: (_, imageConstraints) {
                          // We need the actual rendered image size to scale bounding boxes
                          return FutureBuilder<Size>(
                            future: _getImageSize(),
                            builder: (_, snapshot) {
                              if (!snapshot.hasData) return const SizedBox();
                              final imageSize = snapshot.data!;
                              final scaleX =
                                  imageConstraints.maxWidth / imageSize.width;
                              final scaleY =
                                  (imageConstraints.maxHeight > 0
                                      ? imageConstraints.maxHeight
                                      : imageConstraints.maxWidth *
                                          imageSize.height /
                                          imageSize.width) /
                                  imageSize.height;

                              return Stack(
                                children: [
                                  for (var i = 0; i < result.lines.length; i++)
                                    _buildLineOverlay(
                                        i, result.lines[i], scaleX, scaleY),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<Size>? _imageSizeCache;

  Future<Size> _getImageSize() {
    _imageSizeCache ??= () async {
      final file = File(_receiptPath!);
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      return Size(
          frame.image.width.toDouble(), frame.image.height.toDouble());
    }();
    return _imageSizeCache!;
  }

  Widget _buildLineOverlay(
      int index, OcrLine line, double scaleX, double scaleY) {
    final isSelected = _selectedLineIndices.containsKey(index);
    final assignedPerson =
        isSelected ? _selectedLineIndices[index] : null;
    final color = assignedPerson != null
        ? _personColor(assignedPerson)
        : AppColors.accent;

    final rect = Rect.fromLTRB(
      line.boundingBox.left * scaleX,
      line.boundingBox.top * scaleY,
      line.boundingBox.right * scaleX,
      line.boundingBox.bottom * scaleY,
    );

    return Positioned(
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: GestureDetector(
        onTap: () => _onLineTapped(index),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.3)
                : Colors.transparent,
            border: isSelected
                ? Border.all(color: color, width: 2)
                : line.hasPrice
                    ? Border.all(
                        color: Colors.white.withValues(alpha: 0.4), width: 1)
                    : null,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }

  // ─── Item Card ─────────────────────────────────────────────────────────────

  Widget _buildItemCard(BuildContext context, int index) {
    final item = _items[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.bd(context)),
      ),
      child: Row(
        children: [
          // Person color dot
          if (item.assignedTo.isNotEmpty)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: _personColor(item.assignedTo.first),
                shape: BoxShape.circle,
              ),
            ),
          // Name
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
          // Amount — flexible width to fit large amounts
          Flexible(
            flex: 0,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 70, maxWidth: 140),
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
                    initialValue:
                        item.amount > 0 ? item.amount.toStringAsFixed(2) : '',
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
          ),
          // Delete
          IconButton(
            icon: Icon(Icons.close, size: 16, color: AppColors.th(context)),
            onPressed: () => _removeItem(index),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          ),
        ],
      ),
    );
  }

  // ─── Shared Widgets ────────────────────────────────────────────────────────

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
}

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
