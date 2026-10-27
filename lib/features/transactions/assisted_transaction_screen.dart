import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/database/app_database.dart';
import '../../core/engine/allocation_engine.dart';
import '../../core/providers/accounts_provider.dart';
import '../../core/providers/autofill_provider.dart';
import '../../core/services/autofill_service.dart';
import '../../core/providers/database_provider.dart';
import '../../core/services/last_used_service.dart';
import 'widgets/category_sheet.dart' show recentCategoryIds;
import 'widgets/save_feedback.dart';
import 'widgets/transaction_form_widgets.dart' show DateQuickChip;
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
import '../../l10n/generated/app_localizations.dart';
import '../../shared/utils/dispose_later.dart';
import '../../shared/utils/save_errors.dart';
import '../../shared/theme/app_icons.dart';
import '../../shared/widgets/app_chip.dart';
import '../../shared/widgets/bottom_action_bar.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/sheet_title.dart';
import '../../shared/widgets/tappable.dart';
import 'widgets/tx_ui.dart';

/// Assisted transaction entry: 3 popup steps.
/// 1) Enter Title  2) Select Category  3) Enter Amount + Account + Save
class AssistedTransactionScreen extends ConsumerStatefulWidget {
  final String? initialType;
  /// Starting date (the month being viewed on the Activity tab).
  final DateTime? initialDate;
  /// Title typed in the Activity tab's quick-add bar.
  final String? initialTitle;
  const AssistedTransactionScreen(
      {super.key, this.initialType, this.initialDate, this.initialTitle});

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
  bool startNewOperand = false;
  String? currency;   // captured from account at entry time
  String? accountId;  // captured from account at entry time
  double exchangeRateToBase = 1.0;
}

class _AssistedTransactionScreenState
    extends ConsumerState<AssistedTransactionScreen> {
  late String _type;
  String _title = '';
  String? _accountId;
  /// [_accountId] came from the last-used default — autofill may replace it.
  bool _accountIsDefault = false;
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
          // i.e. exchangeRateToBase = 1/rate. Guard against a 0 rate
          // (1.0/0 = Infinity would poison balance/report math).
          _expenseExchangeRate = rate > 0 ? 1.0 / rate : 1.0;
        });
      }
    } catch (e) {
      debugPrint('[AssistedTx] Failed to fetch FX rate: $e');
    }
  }

  /// Every account change goes through here so a foreign account always
  /// fetches its rate — otherwise the line saves at 1.0 and reports drop it.
  void _setAccount(String? id) {
    _accountId = id;
    final currency = _selectedCurrency;
    if (currency == _baseCurrency) {
      _expenseExchangeRate = 1.0;
    } else {
      _fetchExpenseRate(currency); // async: sets state after the fetch
    }
  }

  _LineItem get _activeLine => _lineItems[_activeLineIndex];

  /// Start on the last used account (or transfer pair), like the classic form.
  Future<void> _applyAccountDefaults() async {
    try {
      final accounts = await ref.read(accountsProvider.future);
      if (!mounted || accounts.isEmpty) return;
      if (_type == 'transfer') {
        final pair = await LastUsedService.transferPair(accounts);
        if (!mounted) return;
        setState(() {
          _accountIsDefault = true;
          _setAccount(pair.from ?? accounts.first.id);
          if (pair.to != null && pair.to != _accountId) {
            _destinationAccountId = pair.to;
          }
        });
      } else if (_accountId == null) {
        final id = await LastUsedService.defaultAccount(accounts);
        if (mounted && _accountId == null) {
          setState(() {
            _setAccount(id);
            _accountIsDefault = true;
          });
        }
      }
    } catch (e) {
      debugPrint('[AssistedTx] Account defaults failed: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _type = widget.initialType ?? 'expense';
    if (widget.initialDate != null) _selectedDate = widget.initialDate!;
    _lineItems.add(_LineItem());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyAccountDefaults();
      _showTitlePopup();
    });
  }

  // ── Back button handling with cancel confirmation ────────────
  Future<bool> _onWillPop() => confirmDiscardTransaction(context);

  // ── Popup 1: Enter Title ──────────────────────────────────

  void _showTitlePopup() {
    final ctrl = TextEditingController(
        text: _title.isNotEmpty ? _title : (widget.initialTitle ?? ''));
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
    void proceed(BuildContext ctx, String localType) {
      _title = ctrl.text.trim();
      movedForward = true;
      Navigator.pop(ctx);
      // A typed title fills category/account like picking a suggestion.
      if (_title.isNotEmpty) _applyAutofillFromTitle(_title);
      if (localType == 'transfer') {
        _showAmountScreen();
      } else if (_activeLine.category == null) {
        _showCategoryPopup();
      } else {
        _showAmountScreen();
      }
    }
    // Capture S + theme colors before opening sheet to avoid _dependents.isEmpty crash.
    // Using the outer widget's context inside a StatefulBuilder registers InheritedWidget
    // dependencies that break when the sheet is dismissed.
    final tr = S.of(context);
    final textPrimary = AppColors.tp(context);
    final textHint = AppColors.th(context);
    final surfaceVariant = AppColors.sfv(context);
    final screenWidth = MediaQuery.sizeOf(context).width;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        // Use local state for type so tapping expense/income/transfer works
        var localType = _type;
        var filteredSuggestions = <String>[];
        return StatefulBuilder(
          builder: (ctx, setSheetState) => Container(
            padding: EdgeInsets.fromLTRB(
                20, 24, 20, MediaQuery.of(ctx).viewInsets.bottom + MediaQuery.of(ctx).viewPadding.bottom + 20),
            decoration: BoxDecoration(
              color: AppColors.popup(context),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(RadiusTokens.sheet)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Type toggle at top
                _buildTypeToggleSheet(localType, (newType) {
                  setSheetState(() => localType = newType);
                  setState(() => _type = newType);
                }, tr: tr, bgColor: surfaceVariant),
                const SizedBox(height: 20),
                SheetTitle(tr.txAfEnterTitle,
                    padding: EdgeInsets.zero,
                    trailing: const _StepIndicator(current: 1)),
                const SizedBox(height: 16),
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    hintText: localType == 'transfer'
                        ? tr.txAfTransferNoteHint
                        : tr.commonTitle,
                    suffixIcon: Icon(
                        localType == 'transfer'
                            ? AppIcons.textAlignLeft
                            : AppIcons.textT,
                        color: textHint),
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
                  // Enter = the button below (the title is optional), never
                  // a silent exit from the flow.
                  onSubmitted: (_) => proceed(ctx, localType),
                ),
                // Inline suggestions (visible, tappable)
                if (filteredSuggestions.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: filteredSuggestions.map((s) {
                      return Tappable(
                        borderRadius: BorderRadius.circular(RadiusTokens.pill),
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
                            maxWidth: screenWidth * 0.42,
                          ),
                          child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: surfaceVariant,
                            borderRadius: BorderRadius.circular(RadiusTokens.pill),
                          ),
                          child: Text(s,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 14,
                                  color: textPrimary)),
                        ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => proceed(ctx, localType),
                  child: Text(
                      localType == 'transfer'
                          ? tr.txAfEnterAmountButton
                          : tr.txAfSelectCategoryButton),
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      disposeAfterRouteAnimation(ctrl);
      // Only pop the screen if the user didn't proceed to category selection.
      if (!movedForward && mounted) {
        context.pop();
      }
    });
  }

  // ── Popup 2: Select Category (grouped by parent) ──────────

  void _showCategoryPopup() {
    final categories = ref.read(categoriesProvider).value ?? [];
    // Capture S before opening sheet to avoid _dependents.isEmpty crash
    final tr = S.of(context);

    final catTextPrimary = AppColors.tp(context);
    final catHint = AppColors.th(context);
    final catSurfaceVariant = AppColors.sfv(context);
    final searchFocus = FocusNode();
    final searchCtrl = TextEditingController();
    // These live in the method scope (not inside the builder) so they survive
    // the modal re-running its builder on keyboard inset changes — otherwise
    // the search query/type reset whenever the keyboard is dismissed.
    var localType = _type;
    String? expandedParentId;
    var searchQuery = '';
    final recentIds = recentCategoryIds(
        ref.read(transactionEntriesProvider).value ?? const []);
    final catById = {for (final c in categories) c.id: c};
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
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
                color: AppColors.popup(context),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(RadiusTokens.sheet)),
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
                              tr.typeExpense,
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
                              tr.typeIncome,
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
                              tr.typeTransfer,
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
                        SheetTitle(tr.txAfSelectCategoryTitle,
                            padding: EdgeInsets.zero,
                            trailing: const _StepIndicator(current: 2)),
                        const SizedBox(height: 10),
                        TextField(
                          controller: searchCtrl,
                          focusNode: searchFocus,
                          onChanged: (v) =>
                              setSheetState(() => searchQuery = v),
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => searchFocus.unfocus(),
                          style: TextStyle(
                              fontSize: 14,
                              color: catTextPrimary),
                          decoration: InputDecoration(
                            hintText: tr.txAfSearchCategories,
                            hintStyle: TextStyle(
                                color: catHint),
                            prefixIcon: Icon(AppIcons.magnifyingGlass,
                                size: 18,
                                color: catHint),
                            suffixIcon: searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(AppIcons.x,
                                        size: 16,
                                        color: catHint),
                                    onPressed: () {
                                      searchCtrl.clear();
                                      setSheetState(
                                          () => searchQuery = '');
                                      searchFocus.unfocus();
                                    },
                                  )
                                : null,
                            contentPadding:
                                const EdgeInsets.symmetric(
                                    vertical: 10),
                            isDense: true,
                          ),
                        ),
                        // Recent categories of this type, one tap away.
                        if (searchQuery.isEmpty)
                          Builder(builder: (_) {
                            final recent = [
                              for (final id in recentIds)
                                if (catById[id]?.transactionType == localType)
                                  catById[id]!,
                            ].take(4).toList();
                            if (recent.isEmpty) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final c in recent)
                                    ActionChip(
                                      avatar: CategoryIcon(
                                        categoryName: c.name,
                                        emoji: c.icon.length <= 4 &&
                                                c.icon != 'category'
                                            ? c.icon
                                            : null,
                                        color: AppColors.fromHex(c.colorHex),
                                        size: 22,
                                        circular: true,
                                      ),
                                      label: Text(c.name),
                                      shape: const StadiumBorder(),
                                      side: BorderSide.none,
                                      backgroundColor: catSurfaceVariant,
                                      onPressed: () {
                                        hapticLight();
                                        _activeLine.category = c;
                                        _activeLine.type = localType;
                                        _type = localType;
                                        _applyAutofill(c.id);
                                        Navigator.pop(ctx);
                                        _showAmountScreen();
                                      },
                                    ),
                                ],
                              ),
                            );
                          }),
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
                              onPressed: () async {
                                // Snapshot existing category IDs before navigating
                                final before = (ref.read(categoriesProvider).value ?? [])
                                    .map((c) => c.id).toSet();
                                Navigator.pop(ctx);
                                await Future.delayed(const Duration(milliseconds: 200));
                                if (!mounted) return;
                                await context.push('/categories');
                                if (!mounted) return;
                                // Invalidate + find newly created category
                                ref.invalidate(categoriesProvider);
                                await Future.delayed(const Duration(milliseconds: 300));
                                final after = ref.read(categoriesProvider).value ?? [];
                                final newCats = after.where((c) => !before.contains(c.id)).toList();
                                if (newCats.length == 1) {
                                  // Auto-select the single new category and proceed to amount
                                  setState(() {
                                    _activeLine.category = newCats.first;
                                    if (newCats.first.transactionType != _type) {
                                      _type = newCats.first.transactionType;
                                    }
                                  });
                                  // The build method will show the amount step since category is set
                                } else {
                                  // Multiple new or none — re-open picker
                                  _showCategoryPopup();
                                }
                              },
                              icon: const Icon(AppIcons.plus, size: 18),
                              label: Text(tr.txAfNewCategory),
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
                            Tappable(
                              borderRadius:
                                  BorderRadius.circular(RadiusTokens.md),
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
                                  color: AppColors.pastel(context, color,
                                      light: 0.88, dark: 0.8),
                                  borderRadius:
                                      BorderRadius.circular(RadiusTokens.md),
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
                                          ? AppIcons.caretUp
                                          : AppIcons.caretDown,
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
                                    const EdgeInsetsDirectional.only(start: 20, bottom: 4),
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
      // The sheet still rebuilds its search field while animating out.
      disposeAfterRouteAnimation(searchFocus);
      disposeAfterRouteAnimation(searchCtrl);
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
    return Tappable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(RadiusTokens.md),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        margin: const EdgeInsets.only(top: 2, bottom: 2),
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
    bool isDestination = false,
  }) {
    final selected =
        selectedId != null
            ? accounts.where((a) => a.id == selectedId).firstOrNull
            : null;

    return Tappable(
      borderRadius: BorderRadius.circular(RadiusTokens.md),
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
                ? AppColors.pastel(context, color, light: 0.88, dark: 0.78)
                : AppColors.sfv(context),
            borderRadius: BorderRadius.circular(RadiusTokens.md),
          ),
          child: Row(
            children: [
              Icon(
                isDestination
                    ? AppIcons.arrowRight
                    : AppIcons.wallet,
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
                        S.of(context).txAfTapToSelect,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.th(context),
                        ),
                      ),
                  ],
                ),
              ),
              Icon(AppIcons.caretUpDown,
                  size: 18, color: AppColors.ts(context)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAccountPicker({
    required String label,
    required List<Account> accounts,
    required String? selectedId,
    required Color color,
    required void Function(Account) onSelected,
  }) async {
    final tr = S.of(context);
    final picked = await showAccountPickerSheet(context,
        accounts: accounts,
        title: label,
        selectedId: selectedId,
        addLabel: tr.txAfAddAccount);
    if (picked == null || !mounted) return;
    if (picked == kAddAccountPick) {
      context.push('/accounts/new');
      return;
    }
    final account = accounts.where((a) => a.id == picked).firstOrNull;
    if (account != null) onSelected(account);
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
      if (cat?.defaultAccountId != null &&
          (_accountId == null || _accountIsDefault)) {
        _setAccount(cat!.defaultAccountId);
      }
      return;
    }
    final canOverride = settings.overrideExisting;
    if (fill.accountId != null && (_accountId == null || canOverride || _accountIsDefault)) {
      _setAccount(fill.accountId);
    }
    if (fill.title != null && (_title.isEmpty || canOverride)) {
      _title = fill.title!;
    }
    _applyAutofillAmount(fill.amount, canOverride);
  }

  /// Settings › Auto-fill › Amount: pre-enter the last amount.
  void _applyAutofillAmount(double? amount, bool canOverride) {
    if (amount == null || amount <= 0) return;
    final line = _activeLine;
    if (line.amount > 0 && !canOverride) return;
    line.amount = amount;
    line.calcDisplay = _fmtCalc(amount);
    line.calcExpression = line.calcDisplay;
    line.startNewOperand = false;
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
    if (fill.accountId != null && (_accountId == null || canOverride || _accountIsDefault)) {
      _setAccount(fill.accountId);
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
    _applyAutofillAmount(fill.amount, canOverride);
  }

  Future<void> _editTitle() async {
    final tr = S.of(context);
    final ctrl = TextEditingController(text: _title);
    final result = await showDialog<String>(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: Text(tr.commonTitle),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          maxLength: InputLimits.nameMaxLength,
          onSubmitted: (v) => Navigator.pop(dCtx, v),
        ),
        actions: [
          TextButton(
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
    if (result != null && mounted) setState(() => _title = result.trim());
  }

  void _showAmountScreen() {
    setState(() {
      // Keep an auto-filled amount; otherwise start from zero.
      if (_activeLine.amount > 0) return;
      _activeLine.calcDisplay = '0';
      _activeLine.calcExpression = '';
      _activeLine.amount = 0;
    });
  }

  void _calcDigit(String d) {
    // Block a second decimal point in the same operand — "1.2." can't be
    // parsed and would silently evaluate to 0, showing the user a wrong total.
    if (d == '.' &&
        !_activeLine.startNewOperand &&
        _activeLine.calcDisplay.contains('.')) {
      return;
    }
    HapticFeedback.lightImpact();
    setState(() {
      final line = _activeLine;
      if (line.startNewOperand) {
        // After operator: reset display, keep expression building
        line.calcDisplay = (d == '.') ? '0.' : d;
        line.calcExpression += d;
        line.startNewOperand = false;
      } else if (line.calcDisplay == '0' && d != '.') {
        line.calcDisplay = d;
        if (line.calcExpression.isEmpty || line.calcExpression == '0') {
          line.calcExpression = d;
        } else {
          line.calcExpression += d;
        }
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
      line.startNewOperand = true;
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
        SnackBar(
          content: Text(S.of(context).txAfEnterAmountFirst),
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

  /// The active line's sum ("12 + 5") is being typed: an operator and the
  /// second number, not just "12 +".
  bool get _midCalculation {
    final e = _activeLine.calcExpression;
    return e.isNotEmpty &&
        !_activeLine.startNewOperand &&
        e.substring(1).contains(RegExp(r'[+\-×÷]')) &&
        !'+-×÷'.contains(e[e.length - 1]);
  }

  /// The header amount: the whole sum while one is typed, else the number.
  String _amountText() {
    final e = _activeLine.calcExpression;
    if (e.isNotEmpty && e.substring(1).contains(RegExp(r'[+\-×÷]'))) {
      return formatCalcExpression(e);
    }
    return _fmtCalcForDisplay(_activeLine.calcDisplay);
  }

  String _fmtCalcResult(double v) =>
      v < 0 ? '-${formatForDisplay(-v)}' : formatForDisplay(v);

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
    if (selected == today) return S.of(context).commonToday;
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
  Future<Transaction?> _checkForDuplicate() async {
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
        if (categoryMatch) return existing.tx;
      }
    }
    return null;
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
          SnackBar(
            content: Text(S.of(context).txAfPleaseSelectAccount),
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
          SnackBar(
            content: Text(S.of(context).txAfPleaseSelectDest),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    // Duplicate detection
    final duplicate = await _checkForDuplicate();
    if (duplicate != null && mounted) {
      final proceed = await confirmDuplicateTransaction(context, duplicate);
      if (!proceed) return;
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
          final typeLabel = e.key == 'income' ? S.of(context).typeIncome : S.of(context).typeExpense;
          // Group amounts by currency within this type
          final byCur = <String, double>{};
          for (final item in e.value) {
            final cur = item.currency ?? _selectedCurrency;
            byCur[cur] = (byCur[cur] ?? 0) + item.amount;
          }
          final amountLabel = byCur.entries
              .map((c) => formatAmount(c.value, currency: c.key))
              .join(' + ');
          return '$typeLabel: $amountLabel (${S.of(context).txAfItemsCount(e.value.length)})';
        }).join('\n');

        final tr = S.of(context);
        final proceed = await showConfirmDialog(
          context,
          title: tr.txAfMixedTitle,
          message: tr.txAfMixedContent(byType.length, summaryLines),
          confirmLabel: tr.commonSave,
          destructive: false,
        );
        if (!proceed) return;
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

      String? expenseTxId;
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
          rateGot: true,
        );
        LastUsedService.rememberTransfer(_accountId!, _destinationAccountId!);
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

          final id = await engine.recordTransaction(
            householdId: householdId,
            accountId: _accountId!,
            type: entry.key,
            lines: lines,
            baseCurrency: _baseCurrency,
            note: _title,
            date: saveDate,
          );
          if (entry.key == 'expense') expenseTxId = id;
        }
        LastUsedService.rememberAccount(_accountId!);
      }

      if (mounted) {
        // Build envelope feedback message
        String snackText = S.of(context).txFormSaved;
        EnvelopeFeedback? envelope;
        if (expenseTxId != null) {
          try {
            envelope = await envelopeAfterSave(
                ref.read(databaseProvider), expenseTxId);
          } catch (e) {
            debugPrint('[AssistedTx] Envelope feedback failed: $e');
          }
        }
        if (!mounted) return;
        if (envelope != null) snackText = envelope.message(S.of(context));
        final nav = GoRouter.of(context);
        final coverId =
            envelope?.overspent == true ? envelope!.allocationId : null;
        final coverLabel = S.of(context).allocCoverButton;

        // Pop first, then show snackbar on the parent screen
        final messenger = ScaffoldMessenger.maybeOf(context);
        context.pop();
        messenger?.clearSnackBars();
        messenger?.showSnackBar(SnackBar(
          content: Text(snackText),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          dismissDirection: DismissDirection.horizontal,
          persist: false,
          action: coverId != null
              ? SnackBarAction(
                  label: coverLabel,
                  onPressed: () => nav
                      .push('/allocations/$coverId', extra: {'cover': true}),
                )
              : null,
        ));
      }
    } catch (e) {
      debugPrint('[AssistedTx] Save failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(txSaveErrorText(S.of(context), e)),
          behavior: SnackBarBehavior.floating,
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
          appBar: AppBar(title: Text(S.of(context).txFormNewTitle)),
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
          title: Text(S.of(context).txAfEnterAmountTitle),
          actions: [
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 12),
              child: _StepIndicator(current: 3),
            ),
          ],
        ),
        body: Column(
          children: [
            // Scrollable content above the keypad
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
            // Category / Transfer banner
            Tappable(
              onTap: isTransfer ? null : () {
                // Re-open category selection as bottom sheet (don't pop)
                if (mounted) _showCategoryPopup();
              },
              child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              color: AppColors.pastel(context, typeColor,
                  light: 0.88, dark: 0.78),
              child: Row(
                children: [
                  if (isTransfer)
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.pastel(context, typeColor,
                          light: 0.8, dark: 0.7),
                      child: Icon(AppIcons.arrowsLeftRight,
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
                        // Large amounts shrink to one line instead of wrapping.
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerEnd,
                          child: Text(
                            '$_selectedCurrency ${_amountText()}',
                            style: TextStyle(
                              fontSize: kHeroAmountSize,
                              fontFamily: TypographyTokens.displayFamily,
                              fontWeight: FontWeight.w800,
                              color: typeColor,
                            ),
                          ),
                        ),
                        // Mid-sum ("12 + 5") the running result takes the
                        // category's line, so the header keeps its height.
                        Text(
                          _midCalculation
                              ? '= ${_fmtCalcResult(_activeLine.amount)}'
                              : isTransfer
                                  ? S.of(context).typeTransfer
                                  : _activeLine.category!.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: _midCalculation
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: AppColors.pastel(context, typeColor,
                                light: 0.25, dark: 0.25),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
            // Title — editable without going back through the flow.
            Tappable(
              onTap: _editTitle,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Icon(AppIcons.textT,
                        size: 18, color: AppColors.ts(context)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _title.isNotEmpty
                            ? _title
                            : S.of(context).txAfAddTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _title.isNotEmpty
                              ? AppColors.tp(context)
                              : AppColors.th(context),
                        ),
                      ),
                    ),
                    Icon(AppIcons.pencilSimple,
                        size: 16, color: AppColors.th(context)),
                  ],
                ),
              ),
            ),
            // Date picker
            Tappable(
              onTap: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  // Same range as the classic form.
                  firstDate: DateTime(2000),
                  lastDate: now.add(const Duration(days: 1)),
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
                    Icon(AppIcons.calendarBlank,
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
                    DateQuickChip(
                      selected: _selectedDate,
                      onPick: (d) => setState(() => _selectedDate = d),
                    ),
                    const SizedBox(width: 4),
                    Tappable(
                      borderRadius: BorderRadius.circular(RadiusTokens.sm),
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
                          Icon(AppIcons.clock,
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
                    Icon(AppIcons.caretRight,
                        size: 20, color: AppColors.ts(context)),
                  ],
                ),
              ),
            ),
            // Line items summary (if multiple)
            if (_lineItems.length > 1) _buildLineItemsSummary(typeColor),
            // Account selector (labeled "From Account" for transfers)
            _buildAccountSelector(
              label: isTransfer ? S.of(context).txAfFromAccount : S.of(context).commonAccount,
              selectedId: _accountId,
              accounts: accounts,
              color: AppColors.accent,
              onSelected: (a) {
                setState(() {
                  _setAccount(a.id);
                  _accountIsDefault = false; // picked by hand: keep it
                });
              },
            ),
            // Destination account (transfers only)
            if (isTransfer)
              _buildAccountSelector(
                label: S.of(context).txAfToAccount,
                selectedId: _destinationAccountId,
                isDestination: true,
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
                        ? AppColors.pastel(context, AppColors.overspent,
                            light: 0.88, dark: 0.78)
                        : AppColors.pastel(context, AppColors.healthy,
                            light: 0.9, dark: 0.8),
                    borderRadius: BorderRadius.circular(CardTokens.radius),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(AppIcons.currencyCircleDollar,
                              size: 18,
                              color: _transferExchangeRate <= 1.0
                                  ? AppColors.overspent
                                  : AppColors.healthy),
                          const SizedBox(width: 8),
                          Text(
                            S.of(context).txAfExchangeRateRequired,
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
                                  ? S.of(context).txAfHowManyPer(_selectedCurrency, _destinationCurrency)
                                  : S.of(context).txAfHowManyPer(_destinationCurrency, _selectedCurrency),
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.ts(context)),
                            ),
                          ),
                          Tappable(
                            borderRadius:
                                BorderRadius.circular(RadiusTokens.sm),
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
                                color: AppColors.pastel(context, AppColors.accent,
                                    light: 0.85, dark: 0.78),
                                borderRadius:
                                    BorderRadius.circular(RadiusTokens.sm),
                              ),
                              child: Icon(AppIcons.arrowsDownUp,
                                  size: 18, color: AppColors.accent),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration:
                            AppColors.card(context, radius: RadiusTokens.md),
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
                                hintText: S.of(context).txAfTapToEnterRate,
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
                              color: AppColors.pastel(context, AppColors.healthy,
                                  light: 0.88, dark: 0.8),
                              borderRadius:
                                  BorderRadius.circular(RadiusTokens.sm),
                            ),
                            child: Row(
                              children: [
                                Icon(AppIcons.checkCircleFill,
                                    size: 16, color: AppColors.healthy),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    S.of(context).txAfRecipientGets(formatAmount(totalAmount * destPerSource, currency: _destinationCurrency)),
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
                    color: AppColors.pastel(context, AppColors.accent,
                        light: 0.88, dark: 0.8),
                    borderRadius: BorderRadius.circular(RadiusTokens.md),
                  ),
                  child: Row(
                    children: [
                      Icon(AppIcons.currencyCircleDollar,
                          size: 16, color: AppColors.accent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _expenseExchangeRate > 0
                              ? '1 $_baseCurrency ≈ ${formatNumber(1.0 / _expenseExchangeRate)} $_selectedCurrency'
                              : S.of(context).txAfFetchingRate(_selectedCurrency),
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
                    const BorderRadius.vertical(
                        top: Radius.circular(RadiusTokens.hero)),
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
            BottomActionBar(
              // Add another item (hidden for transfers)
              above: isTransfer
                  ? null
                  : SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _addAnotherItem,
                        icon: const Icon(AppIcons.plus, size: 18),
                        label: Text(
                          _lineItems.length > 1
                              ? S.of(context).txAfAnotherWithCount(
                                  _lineItems.length, _itemsTotalLabel())
                              : S.of(context).txAfAddAnother,
                        ),
                      ),
                    ),
              children: [
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: AppColors.onAccent, strokeWidth: 2))
                      : Text(isTransfer
                          ? S.of(context).txAfSaveTransfer
                          : _lineItems.length > 1
                              ? S.of(context).txAfSaveNItems(_lineItems.length)
                              : S.of(context).txAfAddTransaction),
                ),
              ],
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
            return Padding(
              padding: const EdgeInsetsDirectional.only(end: 6),
              child: Tappable(
              borderRadius: BorderRadius.circular(RadiusTokens.pill),
              onTap: () => setState(() => _activeLineIndex = i),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.pastel(context, typeColor,
                          light: 0.8, dark: 0.7)
                      : AppColors.sfv(context),
                  borderRadius: BorderRadius.circular(RadiusTokens.pill),
                  border: isActive
                      ? Border.all(color: typeColor, width: 1.5)
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${item.category?.name ?? S.of(context).txAfItemN(i + 1)}: ${formatAmount(item.amount, currency: item.currency ?? _selectedCurrency)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.w400,
                        color: isActive
                            ? typeColor
                            : AppColors.ts(context),
                      ),
                    ),
                    // The active item can be removed (another stays).
                    if (isActive)
                      Semantics(
                        button: true,
                        label: S.of(context).txAfRemoveItem,
                        child: Tappable(
                          borderRadius:
                              BorderRadius.circular(RadiusTokens.pill),
                          onTap: () => setState(() {
                            _lineItems.removeAt(i);
                            _activeLineIndex = _activeLineIndex
                                .clamp(0, _lineItems.length - 1);
                          }),
                          child: Padding(
                            padding: const EdgeInsetsDirectional.only(start: 6),
                            child: Icon(AppIcons.x,
                                size: 14, color: typeColor),
                          ),
                        ),
                      ),
                  ],
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
                  ? AppColors.accentLight
                  : AppColors.sf(context),
              borderRadius: BorderRadius.circular(RadiusTokens.md),
              child: InkWell(
                borderRadius: BorderRadius.circular(RadiusTokens.md),
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
                      ? Icon(AppIcons.backspace,
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
      String currentType, ValueChanged<String> onChanged,
      {S? tr, Color? bgColor}) {
    final txColors = ref.watch(txColorsProvider);
    final l = tr ?? S.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: bgColor ?? AppColors.sfv(context),
        borderRadius: BorderRadius.circular(RadiusTokens.pill),
      ),
      child: Row(
        children: [
          _buildToggleItemSheet(l.typeExpense, 'expense',
              AppIcons.arrowUp, txColors.expense, currentType,
              onChanged),
          _buildToggleItemSheet(l.typeIncome, 'income',
              AppIcons.arrowDown, txColors.income, currentType,
              onChanged),
          _buildToggleItemSheet(l.typeTransfer, 'transfer',
              AppIcons.arrowsLeftRight, txColors.transfer, currentType,
              onChanged),
        ],
      ),
    );
  }

  Widget _buildToggleItemSheet(String label, String value, IconData icon,
      Color color, String currentType, ValueChanged<String> onChanged) {
    final isSelected = currentType == value;
    return Expanded(
      child: Tappable(
        borderRadius: BorderRadius.circular(RadiusTokens.pill),
        onTap: () => onChanged(value),
        // Same look as the classic form's type pill: a raised surface pill
        // on a neutral track, the type's color only on the icon.
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.sf(context) : Colors.transparent,
            borderRadius: BorderRadius.circular(RadiusTokens.pill),
            boxShadow: isSelected ? AppColors.cardShadow(context) : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected
                          ? AppColors.tp(context)
                          : AppColors.ts(context),
                    )),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmallTypeChip(
      String label, bool isSelected, Color color, VoidCallback onTap) {
    return AppChip(
        label: label, selected: isSelected, color: color, onTap: onTap);
  }

}

class _StepIndicator extends StatelessWidget {
  final int current;
  static const _total = 3;
  const _StepIndicator({required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 1; i <= _total; i++) ...[
          if (i > 1) const SizedBox(width: 4),
          Container(
            width: i == current ? 18 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i <= current
                  ? AppColors.accent
                  : AppColors.pastel(context, AppColors.accent,
                      light: 0.75, dark: 0.6),
              borderRadius: BorderRadius.circular(RadiusTokens.sm),
            ),
          ),
        ],
      ],
    );
  }
}
