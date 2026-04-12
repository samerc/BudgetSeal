import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/database/app_database.dart';
import '../../core/engine/allocation_engine.dart';
import '../../core/providers/accounts_provider.dart';
import '../../core/providers/categories_provider.dart';
import '../../core/providers/engine_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../core/providers/transactions_provider.dart';
import '../../core/providers/tx_colors_provider.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/utils/format_number.dart';
import '../../shared/utils/haptics.dart';
import '../../shared/widgets/category_icon.dart';

/// Assisted transaction entry: 3 popup steps.
/// 1) Enter Title  2) Select Category  3) Enter Amount + Account + Save
class AssistedTransactionScreen extends ConsumerStatefulWidget {
  const AssistedTransactionScreen({super.key});

  @override
  ConsumerState<AssistedTransactionScreen> createState() =>
      _AssistedTransactionScreenState();
}

/// Represents one line item being built in the AF.
class _LineItem {
  Category? category;
  String type = 'expense';
  double amount = 0;
  String calcDisplay = '0';
  String calcExpression = '';
}

class _AssistedTransactionScreenState
    extends ConsumerState<AssistedTransactionScreen> {
  String _type = 'expense';
  String _title = '';
  String? _accountId;
  String? _destinationAccountId;
  double _transferExchangeRate = 1.0;
  DateTime _selectedDate = DateTime.now();
  bool _saving = false;

  // Multi-line support
  final List<_LineItem> _lineItems = [];
  int _activeLineIndex = 0;

  String get _baseCurrency =>
      ref.read(householdProvider).value?.baseCurrency ?? 'USD';

  String get _selectedCurrency {
    final accounts = ref.read(accountsProvider).value ?? [];
    if (_accountId != null) {
      final acc = accounts.where((a) => a.id == _accountId).firstOrNull;
      if (acc != null) return acc.currency;
    }
    return _baseCurrency;
  }

  String get _destinationCurrency {
    final accounts = ref.read(accountsProvider).value ?? [];
    if (_destinationAccountId != null) {
      final acc = accounts.where((a) => a.id == _destinationAccountId).firstOrNull;
      if (acc != null) return acc.currency;
    }
    return _baseCurrency;
  }

  bool get _isTransferCrossCurrency =>
      _type == 'transfer' && _selectedCurrency != _destinationCurrency;

  _LineItem get _activeLine => _lineItems[_activeLineIndex];

  @override
  void initState() {
    super.initState();
    _lineItems.add(_LineItem());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final accounts = ref.read(accountsProvider).value ?? [];
      if (accounts.isNotEmpty) {
        _accountId = accounts.first.id;
      }
      _showTitlePopup();
    });
  }

  // ── Back button handling with cancel confirmation ────────────
  Future<bool> _onWillPop() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Discard transaction?'),
        content: const Text(
            'You have an unsaved transaction. Are you sure you want to go back?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style:
                TextButton.styleFrom(foregroundColor: AppColors.overspent),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // ── Popup 1: Enter Title ──────────────────────────────────

  void _showTitlePopup() {
    final ctrl = TextEditingController();
    final entries =
        ref.read(transactionEntriesProvider).value ?? [];
    final previousTitles = <String>{};
    for (final e in entries) {
      final note = e.tx.note;
      if (note.isNotEmpty) {
        final t = note.contains(' — ') ? note.split(' — ').first : note;
        if (t.isNotEmpty) previousTitles.add(t);
      }
    }
    final suggestions = previousTitles.toList()..sort();
    var movedForward = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        // Use local state for type so tapping expense/income/transfer works
        var localType = _type;
        return StatefulBuilder(
          builder: (ctx, setSheetState) => Container(
            padding: EdgeInsets.fromLTRB(
                20, 24, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
            decoration: BoxDecoration(
              color: AppColors.sf(context),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Type toggle at top
                _buildTypeToggleSheet(localType, (newType) {
                  setSheetState(() => localType = newType);
                  setState(() => _type = newType);
                }),
                const SizedBox(height: 20),
                Text('Enter Title',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.tp(context))),
                const SizedBox(height: 16),
                Autocomplete<String>(
                  optionsBuilder: (val) {
                    if (val.text.isEmpty) return const [];
                    final q = val.text.toLowerCase();
                    return suggestions
                        .where((s) => s.toLowerCase().contains(q))
                        .take(5);
                  },
                  onSelected: (s) => ctrl.text = s,
                  fieldViewBuilder: (_, controller, focusNode, __) {
                    controller.text = ctrl.text;
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      autofocus: true,
                      textCapitalization: TextCapitalization.sentences,
                      style: const TextStyle(fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'Title',
                        suffixIcon: Icon(Icons.title_rounded,
                            color: AppColors.th(context)),
                      ),
                      onSubmitted: (_) {
                        _title = controller.text.trim();
                        movedForward = _title.isNotEmpty;
                        Navigator.pop(ctx);
                        if (_title.isNotEmpty) {
                          if (localType == 'transfer') {
                            _showAmountScreen();
                          } else {
                            _showCategoryPopup();
                          }
                        }
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    _title = ctrl.text.trim();
                    movedForward = true;
                    Navigator.pop(ctx);
                    if (localType == 'transfer') {
                      _showAmountScreen();
                    } else {
                      _showCategoryPopup();
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                      localType == 'transfer'
                          ? 'Enter Amount'
                          : 'Select Category',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      // Only pop the screen if the user didn't proceed to category selection.
      if (!movedForward && mounted) {
        context.pop();
      }
    });
  }

  // ── Popup 2: Select Category (grouped by parent) ──────────

  void _showCategoryPopup() {
    final categories = ref.read(categoriesProvider).value ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        var localType = _type;
        String? expandedParentId;
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final filtered = categories
                .where((c) => c.transactionType == localType)
                .toList();
            final parents =
                filtered.where((c) => c.parentId == null).toList();
            final subsByParent = <String, List<Category>>{};
            for (final c in filtered) {
              if (c.parentId != null) {
                subsByParent
                    .putIfAbsent(c.parentId!, () => [])
                    .add(c);
              }
            }

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.75,
              ),
              decoration: BoxDecoration(
                color: AppColors.sf(context),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Type toggle
                        Row(
                          children: [
                            _buildSmallTypeChip(
                              'Expense',
                              localType == 'expense',
                              ref.watch(txColorsProvider).expense,
                              () {
                                setSheetState(() {
                                  localType = 'expense';
                                  expandedParentId = null;
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            _buildSmallTypeChip(
                              'Income',
                              localType == 'income',
                              ref.watch(txColorsProvider).income,
                              () {
                                setSheetState(() {
                                  localType = 'income';
                                  expandedParentId = null;
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            _buildSmallTypeChip(
                              'Transfer',
                              localType == 'transfer',
                              ref.watch(txColorsProvider).transfer,
                              () {
                                setSheetState(() {
                                  localType = 'transfer';
                                  expandedParentId = null;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text('Select Category',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.tp(context))),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      itemCount: parents.length + 1, // +1 for "New"
                      itemBuilder: (_, i) {
                        if (i == parents.length) {
                          // Add new category button
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(ctx);
                                context.push('/categories');
                              },
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text('New Category'),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(12)),
                              ),
                            ),
                          );
                        }

                        final parent = parents[i];
                        final subs = subsByParent[parent.id] ?? [];
                        final color = _hexToColor(parent.colorHex);
                        final isExpanded = expandedParentId == parent.id;

                        if (subs.isEmpty) {
                          // Standalone category — directly selectable
                          return _buildCategoryTile(
                            parent,
                            color,
                            () {
                              hapticLight();
                              _activeLine.category = parent;
                              _activeLine.type = localType;
                              _type = localType;
                              if (parent.defaultAccountId != null) {
                                _accountId = parent.defaultAccountId;
                              }
                              Navigator.pop(ctx);
                              _showAmountScreen();
                            },
                          );
                        }

                        // Parent with subcategories — expandable
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Parent header (tap to expand)
                            GestureDetector(
                              onTap: () => setSheetState(() {
                                expandedParentId =
                                    isExpanded ? null : parent.id;
                              }),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                margin:
                                    const EdgeInsets.only(top: 4, bottom: 2),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    CategoryIcon(
                                      categoryName: parent.name,
                                      emoji: parent.icon.length <= 4 &&
                                              parent.icon != 'category'
                                          ? parent.icon
                                          : null,
                                      color: color,
                                      size: 36,
                                      circular: true,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        parent.name,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.tp(context),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${subs.length}',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.ts(context)),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      isExpanded
                                          ? Icons.expand_less_rounded
                                          : Icons.expand_more_rounded,
                                      size: 20,
                                      color: AppColors.ts(context),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Subcategories (shown when expanded)
                            if (isExpanded)
                              Padding(
                                padding:
                                    const EdgeInsets.only(left: 20, bottom: 4),
                                child: Column(
                                  children: subs
                                      .map((sub) => _buildCategoryTile(
                                            sub,
                                            _hexToColor(sub.colorHex),
                                            () {
                                              hapticLight();
                                              _activeLine.category = sub;
                                              _activeLine.type = localType;
                                              _type = localType;
                                              if (sub.defaultAccountId !=
                                                  null) {
                                                _accountId =
                                                    sub.defaultAccountId;
                                              }
                                              Navigator.pop(ctx);
                                              _showAmountScreen();
                                            },
                                          ))
                                      .toList(),
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
          },
        );
      },
    ).then((_) {
      // If the category popup closed without a selection (e.g. user navigated
      // to /categories), remove the incomplete line item.
      if (!mounted) return;
      if (_activeLine.category == null) {
        setState(() {
          if (_lineItems.length > 1) {
            _lineItems.removeAt(_activeLineIndex);
            _activeLineIndex =
                _activeLineIndex.clamp(0, _lineItems.length - 1);
          }
        });
      }
    });
  }

  Widget _buildCategoryTile(
      Category cat, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        margin: const EdgeInsets.only(top: 2, bottom: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            CategoryIcon(
              categoryName: cat.name,
              emoji: cat.icon.length <= 4 && cat.icon != 'category'
                  ? cat.icon
                  : null,
              color: color,
              size: 40,
              circular: true,
            ),
            const SizedBox(width: 12),
            Text(
              cat.name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.tp(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Screen 3: Amount + Calculator + Save ───────────────────

  void _showAmountScreen() {
    setState(() {
      _activeLine.calcDisplay = '0';
      _activeLine.calcExpression = '';
      _activeLine.amount = 0;
    });
  }

  void _calcDigit(String d) {
    HapticFeedback.lightImpact();
    setState(() {
      final line = _activeLine;
      if (line.calcDisplay == '0' && d != '.') {
        line.calcDisplay = d;
        line.calcExpression = d;
      } else {
        line.calcDisplay += d;
        line.calcExpression += d;
      }
      line.amount = _evalExpr(line.calcExpression);
    });
  }

  void _calcOp(String op) {
    HapticFeedback.mediumImpact();
    setState(() {
      final line = _activeLine;
      line.amount = _evalExpr(line.calcExpression);
      line.calcDisplay = _fmtCalc(line.amount);
      line.calcExpression = '${line.calcDisplay}$op';
    });
  }

  void _calcBackspace() {
    HapticFeedback.lightImpact();
    setState(() {
      final line = _activeLine;
      if (line.calcDisplay.length > 1) {
        line.calcDisplay =
            line.calcDisplay.substring(0, line.calcDisplay.length - 1);
        if (line.calcExpression.isNotEmpty) {
          line.calcExpression = line.calcExpression.substring(
              0, line.calcExpression.length - 1);
        }
      } else {
        line.calcDisplay = '0';
        line.calcExpression = '';
      }
      line.amount = _evalExpr(line.calcExpression);
    });
  }

  void _addAnotherItem() {
    // Save current line and open category picker for next item
    if (_activeLine.amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter an amount for this item first'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    hapticMedium();
    setState(() {
      _lineItems.add(_LineItem());
      _activeLineIndex = _lineItems.length - 1;
    });
    _showCategoryPopup();
  }

  String _fmtCalc(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }

  String _formatDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(date.year, date.month, date.day);
    if (selected == today) return 'Today';
    return DateFormat('MMM d, y').format(date);
  }

  double _evalExpr(String expr) {
    if (expr.isEmpty) return 0;
    try {
      var e = expr.replaceAll('×', '*').replaceAll('÷', '/');
      while (e.isNotEmpty && '+-*/'.contains(e[e.length - 1])) {
        e = e.substring(0, e.length - 1);
      }
      if (e.isEmpty) return 0;
      final parts = e.split(RegExp(r'(?=[+\-*/])|(?<=[+\-*/])'));
      double result = 0;
      String op = '+';
      for (final p in parts) {
        if ('+-*/'.contains(p)) {
          op = p;
        } else {
          final n = double.tryParse(p) ?? 0;
          result = switch (op) {
            '+' => result + n,
            '-' => result - n,
            '*' => result * n,
            '/' => n != 0 ? result / n : result,
            _ => result + n,
          };
        }
      }
      return result;
    } catch (_) {
      return 0;
    }
  }

  /// Check if a transaction with the same amount, category, and date exists.
  Future<bool> _checkForDuplicate() async {
    final existingEntries =
        ref.read(transactionEntriesProvider).value ?? [];
    final selectedDay = DateTime(
        _selectedDate.year, _selectedDate.month, _selectedDate.day);

    for (final lineItem in _lineItems) {
      if (lineItem.amount <= 0 || lineItem.category == null) continue;
      for (final existing in existingEntries) {
        final txDate = existing.tx.createdAt.toLocal();
        final txDay = DateTime(txDate.year, txDate.month, txDate.day);
        if (txDay != selectedDay) continue;

        // Check amount match (on header or lines)
        bool amountMatch = false;
        if ((existing.tx.amount - lineItem.amount).abs() < 0.01) {
          amountMatch = true;
        }
        for (final line in existing.lines) {
          if ((line.amount - lineItem.amount).abs() < 0.01) {
            amountMatch = true;
            break;
          }
        }
        if (!amountMatch) continue;

        // Check category match
        bool categoryMatch = false;
        if (existing.tx.categoryId == lineItem.category!.id) {
          categoryMatch = true;
        }
        for (final line in existing.lines) {
          if (line.categoryId == lineItem.category!.id) {
            categoryMatch = true;
            break;
          }
        }
        if (categoryMatch) return true;
      }
    }
    return false;
  }

  Future<void> _save() async {
    final totalAmount =
        _lineItems.fold(0.0, (sum, l) => sum + l.amount);
    if (totalAmount <= 0) {
      hapticHeavy();
      return;
    }
    if (_accountId == null) {
      hapticHeavy();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select an account'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    if (_type == 'transfer' && _destinationAccountId == null) {
      hapticHeavy();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a destination account'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    // Duplicate detection
    final hasDuplicate = await _checkForDuplicate();
    if (hasDuplicate && mounted) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          title: Text('Possible Duplicate',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.tp(context))),
          content: Text(
            'A similar transaction with the same amount, category, and date already exists. Save anyway?',
            style: TextStyle(color: AppColors.ts(context)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, true),
              style: TextButton.styleFrom(
                  foregroundColor: AppColors.accent),
              child: const Text('Save Anyway'),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }

    setState(() => _saving = true);
    hapticMedium();

    try {
      final householdId = ref.read(currentHouseholdIdProvider);
      if (householdId == null) return;

      final engine = ref.read(allocationEngineProvider);
      final validItems = _lineItems.where((item) => item.amount > 0).toList();
      if (validItems.isEmpty) return;

      String? lastTxId;

      if (_type == 'transfer') {
        final txId = await engine.recordTransfer(
          householdId: householdId,
          fromAccountId: _accountId!,
          toAccountId: _destinationAccountId!,
          amount: totalAmount,
          currency: _selectedCurrency,
          exchangeRateToBase: _isTransferCrossCurrency
              ? _transferExchangeRate
              : 1.0,
          createdBy: 'user',
          deviceId: 'local',
          note: _title,
          date: _selectedDate,
        );
        lastTxId = txId;
      } else {
        // Group by type — each type becomes its own transaction
        final byType = <String, List<_LineItem>>{};
        for (final item in validItems) {
          byType.putIfAbsent(item.type, () => []).add(item);
        }

        for (final entry in byType.entries) {
          final lines = entry.value
              .map((item) => TxLine(
                    amount: item.amount,
                    currency: _selectedCurrency,
                    categoryId: item.category?.id,
                    accountId: _accountId,
                  ))
              .toList();

          final txId = await engine.recordTransaction(
            householdId: householdId,
            accountId: _accountId!,
            type: entry.key,
            lines: lines,
            baseCurrency: _baseCurrency,
            note: _title,
            date: _selectedDate,
          );
          lastTxId = txId;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Transaction saved'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              if (lastTxId != null) {
                ref.read(allocationEngineProvider).deleteTransaction(lastTxId);
              }
            },
          ),
        ));
        context.pop();
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final txColors = ref.watch(txColorsProvider);
    final typeColor = txColors.forType(_type);
    final accounts = ref.watch(accountsProvider).value ?? [];

    // If no category selected yet (and not a transfer), show empty waiting screen
    final isTransfer = _type == 'transfer';
    if (_activeLine.category == null && !isTransfer) {
      return PopScope(
        canPop: true,
        child: Scaffold(
          appBar: AppBar(title: const Text('New Transaction')),
          body: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    // Amount screen with calculator
    final color = isTransfer
        ? typeColor
        : _hexToColor(_activeLine.category!.colorHex);
    final totalAmount =
        _lineItems.fold(0.0, (sum, l) => sum + l.amount);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) context.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Enter Amount'),
        ),
        body: Column(
          children: [
            // Category / Transfer banner
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              color: typeColor.withValues(alpha: 0.08),
              child: Row(
                children: [
                  if (isTransfer)
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: typeColor.withValues(alpha: 0.15),
                      child: Icon(Icons.swap_horiz_rounded,
                          color: typeColor, size: 24),
                    )
                  else
                    CategoryIcon(
                      categoryName: _activeLine.category!.name,
                      emoji: _activeLine.category!.icon.length <= 4 &&
                              _activeLine.category!.icon != 'category'
                          ? _activeLine.category!.icon
                          : null,
                      color: color,
                      size: 44,
                      circular: true,
                    ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$_selectedCurrency ${_activeLine.calcDisplay}',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            color: typeColor,
                          ),
                        ),
                        Text(
                          isTransfer
                              ? 'Transfer'
                              : _activeLine.category!.name,
                          style: TextStyle(
                            fontSize: 13,
                            color: typeColor.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Date picker
            GestureDetector(
              onTap: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: now.subtract(const Duration(days: 365)),
                  lastDate: now,
                );
                if (picked != null) {
                  setState(() => _selectedDate = picked);
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        size: 18, color: AppColors.ts(context)),
                    const SizedBox(width: 10),
                    Text(
                      _formatDateLabel(_selectedDate),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.tp(context),
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.chevron_right_rounded,
                        size: 20, color: AppColors.ts(context)),
                  ],
                ),
              ),
            ),
            // Line items summary (if multiple)
            if (_lineItems.length > 1) _buildLineItemsSummary(typeColor),
            // Account chips (labeled "From Account" for transfers)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  isTransfer ? 'From Account' : 'Account',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ts(context),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
              child: SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ...accounts.map((a) {
                      final isSelected = a.id == _accountId;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text('${a.name} (${a.currency})',
                              style: const TextStyle(fontSize: 12)),
                          selected: isSelected,
                          onSelected: (_) =>
                              setState(() => _accountId = a.id),
                          selectedColor:
                              AppColors.accent.withValues(alpha: 0.2),
                          showCheckmark: false,
                        ),
                      );
                    }),
                    GestureDetector(
                      onTap: () => context.push('/accounts/new'),
                      child: Chip(
                        label: const Icon(Icons.add, size: 14),
                        backgroundColor: AppColors.sfv(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Destination account chips (transfers only)
            if (isTransfer) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'To Account',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ts(context),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
                child: SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      ...accounts
                          .where((a) => a.id != _accountId)
                          .map((a) {
                        final isSelected =
                            a.id == _destinationAccountId;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text('${a.name} (${a.currency})',
                                style: const TextStyle(fontSize: 12)),
                            selected: isSelected,
                            onSelected: (_) => setState(
                                () => _destinationAccountId = a.id),
                            selectedColor:
                                typeColor.withValues(alpha: 0.2),
                            showCheckmark: false,
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
            // Exchange rate field (cross-currency transfers)
            if (_isTransferCrossCurrency) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.caution.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.caution.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.currency_exchange_rounded,
                          size: 18, color: AppColors.caution),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '1 $_selectedCurrency = ? $_destinationCurrency',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.tp(context)),
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              height: 32,
                              child: TextField(
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.tp(context)),
                                decoration: InputDecoration(
                                  hintText: 'Exchange rate',
                                  hintStyle: TextStyle(
                                      color: AppColors.th(context),
                                      fontSize: 13),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onChanged: (v) {
                                  final rate = double.tryParse(v);
                                  if (rate != null && rate > 0) {
                                    setState(
                                        () => _transferExchangeRate = rate);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_transferExchangeRate > 0 && totalAmount > 0)
                        Text(
                          '≈ ${formatAmount(totalAmount * _transferExchangeRate, currency: _destinationCurrency)}',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ts(context)),
                        ),
                    ],
                  ),
                ),
              ),
            ],
            // Calculator keypad — no Expanded, fixed height
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              decoration: BoxDecoration(
                color: AppColors.sfv(context),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _calcRow(['7', '8', '9', '÷']),
                  const SizedBox(height: 6),
                  _calcRow(['4', '5', '6', '×']),
                  const SizedBox(height: 6),
                  _calcRow(['1', '2', '3', '-']),
                  const SizedBox(height: 6),
                  _calcRow(['.', '0', '⌫', '+']),
                ],
              ),
            ),
            // Add another item + Save buttons
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Column(
                  children: [
                    // Add another item (hidden for transfers)
                    if (!isTransfer) ...[
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _addAnotherItem,
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: Text(
                            _lineItems.length > 1
                                ? 'Add another item (${_lineItems.length} items · ${_fmtCalc(totalAmount)})'
                                : 'Add another item',
                            style: const TextStyle(fontSize: 14),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            side: BorderSide(
                                color: AppColors.bd(context)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    // Save button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _saving ? null : _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: typeColor,
                          disabledBackgroundColor:
                              typeColor.withValues(alpha: 0.7),
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _saving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : Text(
                                isTransfer
                                    ? 'Save Transfer'
                                    : _lineItems.length > 1
                                        ? 'Save ${_lineItems.length} Items'
                                        : 'Add Transaction',
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineItemsSummary(Color typeColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: SizedBox(
        height: 32,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _lineItems.length,
          itemBuilder: (_, i) {
            final item = _lineItems[i];
            final isActive = i == _activeLineIndex;
            return GestureDetector(
              onTap: () => setState(() => _activeLineIndex = i),
              child: Container(
                margin: const EdgeInsets.only(right: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive
                      ? typeColor.withValues(alpha: 0.15)
                      : AppColors.sfv(context),
                  borderRadius: BorderRadius.circular(8),
                  border: isActive
                      ? Border.all(color: typeColor, width: 1.5)
                      : null,
                ),
                child: Center(
                  child: Text(
                    '${item.category?.name ?? 'Item ${i + 1}'}: ${_fmtCalc(item.amount)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive
                          ? typeColor
                          : AppColors.ts(context),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _calcRow(List<String> keys) {
    return Row(
      children: keys.map((key) {
        final isOp = '+-×÷'.contains(key);
        final isBack = key == '⌫';
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Material(
              color: isOp
                  ? AppColors.accent.withValues(alpha: 0.1)
                  : AppColors.sf(context),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  if (isBack) {
                    _calcBackspace();
                  } else if (isOp) {
                    _calcOp(key);
                  } else {
                    _calcDigit(key);
                  }
                },
                onLongPress: isBack
                    ? () => setState(() {
                          _activeLine.calcDisplay = '0';
                          _activeLine.calcExpression = '';
                          _activeLine.amount = 0;
                        })
                    : null,
                child: Container(
                  height: 54,
                  alignment: Alignment.center,
                  child: isBack
                      ? Icon(Icons.backspace_outlined,
                          size: 20, color: AppColors.ts(context))
                      : Text(
                          key,
                          style: TextStyle(
                            fontSize: isOp ? 24 : 22,
                            fontWeight:
                                isOp ? FontWeight.w700 : FontWeight.w500,
                            color: isOp
                                ? AppColors.accent
                                : AppColors.tp(context),
                          ),
                        ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Type toggle used inside bottom sheets (with callback for local state).
  Widget _buildTypeToggleSheet(
      String currentType, ValueChanged<String> onChanged) {
    final txColors = ref.watch(txColorsProvider);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.sfv(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildToggleItemSheet('Expense', 'expense',
              Icons.arrow_upward_rounded, txColors.expense, currentType,
              onChanged),
          _buildToggleItemSheet('Income', 'income',
              Icons.arrow_downward_rounded, txColors.income, currentType,
              onChanged),
          _buildToggleItemSheet('Transfer', 'transfer',
              Icons.swap_horiz_rounded, txColors.transfer, currentType,
              onChanged),
        ],
      ),
    );
  }

  Widget _buildToggleItemSheet(String label, String value, IconData icon,
      Color color, String currentType, ValueChanged<String> onChanged) {
    final isSelected = currentType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16, color: isSelected ? Colors.white : color),
              const SizedBox(width: 4),
              Text(label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : AppColors.ts(context),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmallTypeChip(
      String label, bool isSelected, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color : AppColors.sfv(context),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color:
                      isSelected ? Colors.white : AppColors.ts(context),
                )),
          ),
        ),
      ),
    );
  }

  Color _hexToColor(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }
}
