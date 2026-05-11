import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/database/app_database.dart';
import '../../core/engine/allocation_engine.dart';
import '../../core/providers/accounts_provider.dart';
import '../../core/providers/allocations_provider.dart';
import '../../core/providers/autofill_provider.dart';
import '../../core/services/autofill_service.dart';
import '../../core/providers/categories_provider.dart';
import '../../core/providers/engine_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../core/providers/transactions_provider.dart';
import '../../core/providers/tx_colors_provider.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/design_tokens.dart';
import '../../core/providers/date_format_provider.dart';
import '../../shared/utils/format_number.dart';
import '../../shared/utils/haptics.dart';
import '../../shared/widgets/calculator_amount_field.dart';
import '../../shared/widgets/category_icon.dart';

/// Assisted transaction entry: 3 popup steps.
/// 1) Enter Title  2) Select Category  3) Enter Amount + Account + Save
class AssistedTransactionScreen extends ConsumerStatefulWidget {
  final String? initialType;
  const AssistedTransactionScreen({super.key, this.initialType});

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
  String? currency;   // captured from account at entry time
  String? accountId;  // captured from account at entry time
  double exchangeRateToBase = 1.0;
}

class _AssistedTransactionScreenState
    extends ConsumerState<AssistedTransactionScreen> {
  late String _type;
  String _title = '';
  String? _accountId;
  String? _destinationAccountId;
  double _transferExchangeRate = 1.0;
  double? _originalTransferRate; // stored before inversion to avoid precision loss
  bool _rateInverted = false; // true = showing "1 DEST = X SOURCE"
  double _expenseExchangeRate = 1.0; // rate for non-transfer cross-currency
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
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

  /// True when the account currency differs from the household base currency
  /// (for non-transfer transactions).
  bool get _isExpenseCrossCurrency =>
      _type != 'transfer' && _selectedCurrency != _baseCurrency;

  /// Fetch exchange rate when account currency differs from base.
  Future<void> _fetchExpenseRate(String accountCurrency) async {
    if (accountCurrency == _baseCurrency) {
      setState(() => _expenseExchangeRate = 1.0);
      return;
    }
    try {
      final fxService = ref.read(fxServiceProvider);
      final rawRate =
          await fxService.getRateWithCache(_baseCurrency, accountCurrency);
      final rate = roundRate(rawRate);
      if (mounted) {
        setState(() {
          // Store as "1 accountCurrency = X baseCurrency"
          // i.e. exchangeRateToBase = 1/rate
          _expenseExchangeRate = 1.0 / rate;
        });
      }
    } catch (e) {
      debugPrint('[AssistedTx] Failed to fetch FX rate: $e');
    }
  }

  _LineItem get _activeLine => _lineItems[_activeLineIndex];

  @override
  void initState() {
    super.initState();
    _type = widget.initialType ?? 'expense';
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
        var filteredSuggestions = <String>[];
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
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    hintText: localType == 'transfer'
                        ? 'Note (e.g. rent, savings)'
                        : 'Title',
                    suffixIcon: Icon(
                        localType == 'transfer'
                            ? Icons.notes_rounded
                            : Icons.title_rounded,
                        color: AppColors.th(context)),
                  ),
                  onChanged: (val) {
                    final q = val.toLowerCase();
                    setSheetState(() {
                      filteredSuggestions = q.isEmpty
                          ? []
                          : suggestions
                              .where((s) => s.toLowerCase().contains(q))
                              .take(5)
                              .toList();
                    });
                  },
                  onSubmitted: (_) {
                    _title = ctrl.text.trim();
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
                ),
                // Inline suggestions (visible, tappable)
                if (filteredSuggestions.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: filteredSuggestions.map((s) {
                      return GestureDetector(
                        onTap: () {
                          _title = s;
                          movedForward = true;
                          Navigator.pop(ctx);
                          // Try autofill from title — may pre-fill category & account
                          _applyAutofillFromTitle(s);
                          if (localType == 'transfer') {
                            _showAmountScreen();
                          } else if (_activeLine.category == null) {
                            _showCategoryPopup();
                          } else {
                            // Category was filled by title autofill — skip to amount
                            _showAmountScreen();
                          }
                        },
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.42,
                          ),
                          child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.sfv(context),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: AppColors.bd(context)),
                          ),
                          child: Text(s,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.tp(context))),
                        ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
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
        var searchQuery = '';
        final searchFocus = FocusNode();
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final allForType = categories
                .where((c) => c.transactionType == localType)
                .toList();

            // Build parent/sub structure first, then filter
            final allParents =
                allForType.where((c) => c.parentId == null).toList();
            final allSubsByParent = <String, List<Category>>{};
            for (final c in allForType) {
              if (c.parentId != null) {
                allSubsByParent
                    .putIfAbsent(c.parentId!, () => [])
                    .add(c);
              }
            }

            // Apply search: keep a parent if it matches OR any of its subs match
            List<Category> parents;
            Map<String, List<Category>> subsByParent;
            if (searchQuery.isEmpty) {
              parents = allParents;
              subsByParent = allSubsByParent;
            } else {
              final q = searchQuery.toLowerCase();
              parents = [];
              subsByParent = {};
              for (final p in allParents) {
                final matchingSubs = (allSubsByParent[p.id] ?? [])
                    .where((s) => s.name.toLowerCase().contains(q))
                    .toList();
                if (p.name.toLowerCase().contains(q) ||
                    matchingSubs.isNotEmpty) {
                  parents.add(p);
                  if (matchingSubs.isNotEmpty) {
                    subsByParent[p.id] = matchingSubs;
                  } else if (allSubsByParent.containsKey(p.id)) {
                    subsByParent[p.id] = allSubsByParent[p.id]!;
                  }
                }
              }
            }

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.85,
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
                        const SizedBox(height: 10),
                        TextField(
                          focusNode: searchFocus,
                          onChanged: (v) =>
                              setSheetState(() => searchQuery = v),
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => searchFocus.unfocus(),
                          style: TextStyle(
                              fontSize: 14,
                              color: AppColors.tp(context)),
                          decoration: InputDecoration(
                            hintText: 'Search categories...',
                            hintStyle: TextStyle(
                                color: AppColors.th(context)),
                            prefixIcon: Icon(Icons.search_rounded,
                                size: 18,
                                color: AppColors.th(context)),
                            suffixIcon: searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.clear_rounded,
                                        size: 16,
                                        color: AppColors.th(context)),
                                    onPressed: () {
                                      setSheetState(
                                          () => searchQuery = '');
                                      searchFocus.unfocus();
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: AppColors.sfv(context),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding:
                                const EdgeInsets.symmetric(
                                    vertical: 10),
                            isDense: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
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
                        final color = AppColors.fromHex(parent.colorHex);
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
                              _applyAutofill(parent.id);
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
                                            AppColors.fromHex(sub.colorHex),
                                            () {
                                              hapticLight();
                                              _activeLine.category = sub;
                                              _activeLine.type = localType;
                                              _type = localType;
                                              _applyAutofill(sub.id);
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
            Expanded(
              child: Text(
                cat.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.tp(context),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Screen 3: Amount + Calculator + Save ───────────────────

  // ── Account selector (tap to pick from bottom sheet) ──────────

  Widget _buildAccountSelector({
    required String label,
    required String? selectedId,
    required List<Account> accounts,
    required Color color,
    required void Function(Account) onSelected,
  }) {
    final selected =
        selectedId != null
            ? accounts.where((a) => a.id == selectedId).firstOrNull
            : null;

    return GestureDetector(
      onTap: () => _showAccountPicker(
        label: label,
        accounts: accounts,
        selectedId: selectedId,
        color: color,
        onSelected: onSelected,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected != null
                ? color.withValues(alpha: 0.08)
                : AppColors.sfv(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected != null
                  ? color.withValues(alpha: 0.4)
                  : AppColors.bd(context),
            ),
          ),
          child: Row(
            children: [
              Icon(
                label.contains('To')
                    ? Icons.arrow_forward_rounded
                    : Icons.account_balance_wallet_outlined,
                size: 18,
                color: selected != null ? color : AppColors.ts(context),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.ts(context),
                      ),
                    ),
                    if (selected != null)
                      Text(
                        '${selected.name} · ${selected.currency}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.tp(context),
                        ),
                      )
                    else
                      Text(
                        'Tap to select',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.th(context),
                        ),
                      ),
                  ],
                ),
              ),
              Icon(Icons.unfold_more_rounded,
                  size: 18, color: AppColors.ts(context)),
            ],
          ),
        ),
      ),
    );
  }

  void _showAccountPicker({
    required String label,
    required List<Account> accounts,
    required String? selectedId,
    required Color color,
    required void Function(Account) onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.sf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.th(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(label,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.tp(context))),
              const SizedBox(height: 12),
              ...() {
                // Pre-fetch balances once for all accounts
                final allBalances = ref.read(accountsWithBalanceProvider).value ?? [];
                final balanceMap = {for (final ab in allBalances) ab.account.id: ab.balance};
                return accounts.map((a) {
                final isSelected = a.id == selectedId;
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color.withValues(alpha: 0.1)
                        : AppColors.sfv(context),
                    borderRadius: BorderRadius.circular(CardTokens.radius),
                    border: isSelected
                        ? Border.all(color: color.withValues(alpha: 0.4))
                        : null,
                  ),
                  child: ListTile(
                    onTap: () {
                      Navigator.pop(ctx);
                      onSelected(a);
                    },
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14),
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.account_balance_wallet_rounded,
                          size: 18, color: color),
                    ),
                    title: Text(a.name,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.tp(context))),
                    subtitle: () {
                      final bal = balanceMap[a.id];
                      if (bal != null) {
                        return Text(
                          '${a.currency} · ${formatAmount(bal, currency: a.currency)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: bal >= 0
                                ? AppColors.ts(context)
                                : AppColors.overspent,
                          ),
                        );
                      }
                      return Text(a.currency,
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.ts(context)));
                    }(),
                    trailing: isSelected
                        ? Icon(Icons.check_circle_rounded,
                            size: 20, color: color)
                        : null,
                  ),
                );
              });
              }(),
              const SizedBox(height: 4),
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.push('/accounts/new');
                },
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Account'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _applyAutofill(String categoryId) {
    final settings = ref.read(autofillProvider);
    final entries = ref.read(transactionEntriesProvider).value ?? [];
    final fill = lookupAutofill(
      categoryId: categoryId,
      entries: entries,
      settings: settings,
    );
    if (!fill.hasData) {
      // Fallback to category's default account
      final categories = ref.read(categoriesProvider).value ?? [];
      final cat = categories.where((c) => c.id == categoryId).firstOrNull;
      if (cat?.defaultAccountId != null && _accountId == null) {
        _accountId = cat!.defaultAccountId;
      }
      return;
    }
    final canOverride = settings.overrideExisting;
    if (fill.accountId != null && (_accountId == null || canOverride)) {
      _accountId = fill.accountId;
    }
    if (fill.title != null && (_title.isEmpty || canOverride)) {
      _title = fill.title!;
    }
  }

  void _applyAutofillFromTitle(String title) {
    final settings = ref.read(autofillProvider);
    final entries = ref.read(transactionEntriesProvider).value ?? [];
    final fill = lookupAutofillByTitle(
      title: title,
      entries: entries,
      settings: settings,
    );
    if (!fill.hasData) return;
    final canOverride = settings.overrideExisting;
    if (fill.accountId != null && (_accountId == null || canOverride)) {
      _accountId = fill.accountId;
    }
    if (fill.categoryId != null &&
        (_activeLine.category == null || canOverride)) {
      final categories = ref.read(categoriesProvider).value ?? [];
      final cat =
          categories.where((c) => c.id == fill.categoryId).firstOrNull;
      if (cat != null) {
        _activeLine.category = cat;
        _type = cat.transactionType;
      }
    }
  }

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

  /// Capture the current account/currency/rate on the active line item.
  void _captureLineContext() {
    final line = _activeLine;
    line.accountId = _accountId;
    line.currency = _selectedCurrency;
    line.exchangeRateToBase = _isExpenseCrossCurrency
        ? _expenseExchangeRate
        : 1.0;
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
    // Capture currency/account on the current line before moving on
    _captureLineContext();
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

  /// Format the calc display with commas if it's a pure number.
  String _fmtCalcForDisplay(String raw) {
    if (raw == '0' || raw.isEmpty) return raw;
    // If it contains operators, don't format (user is mid-expression)
    if (raw.contains('+') || raw.contains('-') ||
        raw.contains('×') || raw.contains('÷')) {
      return raw;
    }
    final n = double.tryParse(raw);
    if (n != null && n > 0) return formatForDisplay(n);
    return raw;
  }

  String _formatDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(date.year, date.month, date.day);
    if (selected == today) return 'Today';
    return formatDate(date);
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
    } catch (e) {
      debugPrint('Expression eval failed for "$expr": $e');
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

    final validItems = _lineItems.where((item) => item.amount > 0).toList();
    if (validItems.isEmpty) return;

    // Check for mixed types and show summary before saving
    if (_type != 'transfer') {
      final byType = <String, List<_LineItem>>{};
      for (final item in validItems) {
        byType.putIfAbsent(item.type, () => []).add(item);
      }

      if (byType.length > 1 && mounted) {
        final summaryLines = byType.entries.map((e) {
          final typeLabel = e.key == 'income' ? 'Income' : 'Expense';
          // Group amounts by currency within this type
          final byCur = <String, double>{};
          for (final item in e.value) {
            final cur = item.currency ?? _selectedCurrency;
            byCur[cur] = (byCur[cur] ?? 0) + item.amount;
          }
          final amountLabel = byCur.entries
              .map((c) => formatAmount(c.value, currency: c.key))
              .join(' + ');
          return '$typeLabel: $amountLabel (${e.value.length} ${e.value.length == 1 ? 'item' : 'items'})';
        }).join('\n');

        final proceed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Mixed transaction'),
            content: Text(
              'This will create ${byType.length} linked transactions:\n\n'
              '$summaryLines\n\n'
              'They will appear as separate transactions but linked together.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Save'),
              ),
            ],
          ),
        );
        if (proceed != true) return;
      }
    }

    // Capture context on the active line before saving
    _captureLineContext();

    setState(() => _saving = true);
    hapticMedium();

    try {
      final householdId = ref.read(currentHouseholdIdProvider);
      if (householdId == null) return;

      final engine = ref.read(allocationEngineProvider);

      // Use a fixed timestamp so linked transactions share the exact same
      // createdAt — this is how we find related transactions later.
      final saveDate = DateTime(
        _selectedDate.year, _selectedDate.month, _selectedDate.day,
        _selectedTime.hour, _selectedTime.minute,
      );

      if (_type == 'transfer') {
        await engine.recordTransfer(
          householdId: householdId,
          fromAccountId: _accountId!,
          toAccountId: _destinationAccountId!,
          amount: totalAmount,
          currency: _selectedCurrency,
          exchangeRateToBase: _isTransferCrossCurrency
              ? (_rateInverted
                  ? 1.0 / _transferExchangeRate
                  : _transferExchangeRate)
              : 1.0,
          createdBy: 'user',
          deviceId: 'local',
          note: _title,
          date: saveDate,
        );

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
                    currency: item.currency ?? _selectedCurrency,
                    categoryId: item.category?.id,
                    accountId: item.accountId ?? _accountId,
                    exchangeRateToBase: item.exchangeRateToBase,
                  ))
              .toList();

          await engine.recordTransaction(
            householdId: householdId,
            accountId: _accountId!,
            type: entry.key,
            lines: lines,
            baseCurrency: _baseCurrency,
            note: _title,
            date: saveDate,
          );
        }
      }

      if (mounted) {
        // Build envelope feedback message
        String snackText = 'Transaction saved';
        if (_type != 'transfer') {
          final categories = ref.read(categoriesProvider).value ?? [];
          final allocations = ref.read(allocationsProvider).value ?? [];
          final firstCat = validItems
              .where((item) => item.category != null)
              .map((item) => item.category!)
              .firstOrNull;
          if (firstCat != null) {
            final catData = categories
                .where((c) => c.id == firstCat.id)
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

        // Pop first, then show snackbar on the parent screen
        final messenger = ScaffoldMessenger.maybeOf(context);
        context.pop();
        messenger?.clearSnackBars();
        messenger?.showSnackBar(SnackBar(
          content: Text(snackText),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          dismissDirection: DismissDirection.horizontal,
        ));
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
        : AppColors.fromHex(_activeLine.category!.colorHex);
    final totalAmount =
        _lineItems.fold(0.0, (sum, l) => sum + l.amount);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          context.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Enter Amount'),
        ),
        body: Column(
          children: [
            // Scrollable content above the keypad
            Expanded(
              child: SingleChildScrollView(
                child: Column(
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
                          '$_selectedCurrency ${_fmtCalcForDisplay(_activeLine.calcDisplay)}',
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
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _selectedTime,
                        );
                        if (picked != null) {
                          setState(() => _selectedTime = picked);
                        }
                      },
                      child: Row(
                        children: [
                          Icon(Icons.access_time_rounded,
                              size: 16, color: AppColors.ts(context)),
                          const SizedBox(width: 6),
                          Text(
                            _selectedTime.format(context),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.tp(context),
                            ),
                          ),
                        ],
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
            // Account selector (labeled "From Account" for transfers)
            _buildAccountSelector(
              label: isTransfer ? 'From Account' : 'Account',
              selectedId: _accountId,
              accounts: accounts,
              color: AppColors.accent,
              onSelected: (a) {
                setState(() => _accountId = a.id);
                _fetchExpenseRate(a.currency);
              },
            ),
            // Destination account (transfers only)
            if (isTransfer)
              _buildAccountSelector(
                label: 'To Account',
                selectedId: _destinationAccountId,
                accounts: accounts
                    .where((a) => a.id != _accountId)
                    .toList(),
                color: typeColor,
                onSelected: (a) =>
                    setState(() => _destinationAccountId = a.id),
              ),
            // Exchange rate field (cross-currency transfers)
            if (_isTransferCrossCurrency) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _transferExchangeRate <= 1.0
                        ? AppColors.overspent.withValues(alpha: 0.08)
                        : AppColors.healthy.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(CardTokens.radius),
                    border: Border.all(
                        color: _transferExchangeRate <= 1.0
                            ? AppColors.overspent.withValues(alpha: 0.4)
                            : AppColors.healthy.withValues(alpha: 0.3),
                        width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.currency_exchange_rounded,
                              size: 18,
                              color: _transferExchangeRate <= 1.0
                                  ? AppColors.overspent
                                  : AppColors.healthy),
                          const SizedBox(width: 8),
                          Text(
                            'Exchange Rate Required',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _transferExchangeRate <= 1.0
                                    ? AppColors.overspent
                                    : AppColors.healthy),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _rateInverted
                                  ? 'How many $_selectedCurrency per 1 $_destinationCurrency?'
                                  : 'How many $_destinationCurrency per 1 $_selectedCurrency?',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.ts(context)),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                if (_transferExchangeRate > 0 &&
                                    _transferExchangeRate != 1.0) {
                                  if (!_rateInverted) {
                                    // Store original before inverting
                                    _originalTransferRate =
                                        _transferExchangeRate;
                                    _transferExchangeRate =
                                        1.0 / _transferExchangeRate;
                                  } else {
                                    // Restore original
                                    _transferExchangeRate =
                                        _originalTransferRate ??
                                            (1.0 / _transferExchangeRate);
                                    _originalTransferRate = null;
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
                                  size: 18, color: AppColors.accent),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.sf(context),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.bd(context)),
                        ),
                        child: Row(
                          children: [
                            Text(
                                _rateInverted
                                    ? '1 $_destinationCurrency = '
                                    : '1 $_selectedCurrency = ',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.ts(context))),
                            Expanded(
                              child: CalculatorAmountField(
                                value: _transferExchangeRate <= 1.0
                                    ? 0
                                    : _transferExchangeRate,
                                fontSize: 18,
                                hintText: 'Tap to enter rate',
                                onChanged: (v) {
                                  if (v > 0) {
                                    setState(
                                        () => _transferExchangeRate = v);
                                  }
                                },
                              ),
                            ),
                            Text(
                                _rateInverted
                                    ? ' $_selectedCurrency'
                                    : ' $_destinationCurrency',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.ts(context))),
                          ],
                        ),
                      ),
                      if (_transferExchangeRate > 0 && _transferExchangeRate != 1.0 && totalAmount > 0) ...[
                        const SizedBox(height: 10),
                        () {
                          // Compute recipient amount: always source * (dest per source)
                          final destPerSource = _rateInverted
                              ? 1.0 / _transferExchangeRate
                              : _transferExchangeRate;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.healthy.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle_rounded,
                                    size: 16, color: AppColors.healthy),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Recipient gets = ${formatAmount(totalAmount * destPerSource, currency: _destinationCurrency)}',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.healthy),
                                ),
                              ),
                            ],
                          ),
                        );
                        }(),
                      ],
                    ],
                  ),
                ),
              ),
            ],
                  ],
                ),
              ),
            ),
            // Exchange rate info (non-transfer cross-currency)
            if (_isExpenseCrossCurrency && !isTransfer)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.currency_exchange_rounded,
                          size: 16, color: AppColors.accent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _expenseExchangeRate > 0 && _expenseExchangeRate != 1.0
                              ? '1 $_selectedCurrency ≈ ${formatAmount(1.0 / _expenseExchangeRate, currency: '')} $_baseCurrency'
                              : 'Fetching rate for $_selectedCurrency...',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // Calculator keypad — fixed at bottom
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
                                ? 'Add another item (${_lineItems.length} items · ${_itemsTotalLabel()})'
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

  /// Build a label showing totals per currency for the "Add another" button.
  String _itemsTotalLabel() {
    final byCurrency = <String, double>{};
    for (final item in _lineItems) {
      final cur = item.currency ?? _selectedCurrency;
      byCurrency[cur] = (byCurrency[cur] ?? 0) + item.amount;
    }
    return byCurrency.entries
        .map((e) => formatAmount(e.value, currency: e.key))
        .join(' + ');
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
                    '${item.category?.name ?? 'Item ${i + 1}'}: ${formatAmount(item.amount, currency: item.currency ?? _selectedCurrency)}',
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

}
