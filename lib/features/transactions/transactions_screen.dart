import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../core/database/app_database.dart';
import 'package:drift/drift.dart' hide Column;
import '../../core/providers/allocations_provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/accounts_provider.dart';
import '../../core/providers/activity_filter_provider.dart';
import '../../core/providers/engine_provider.dart';
import '../../core/providers/categories_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../core/providers/transactions_provider.dart';
import '../../core/providers/tx_colors_provider.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/widgets/faded_edges.dart';
import '../../core/providers/tx_list_settings_provider.dart';
import '../../shared/theme/design_tokens.dart';
import '../../core/providers/date_format_provider.dart';
import '../../shared/utils/format_number.dart';
import '../../shared/utils/haptics.dart';
import 'widgets/category_sheet.dart';
import 'widgets/delete_with_undo.dart';
import 'widgets/feature_colors.dart';
import 'widgets/export_entries.dart';
import 'widgets/tx_form_args.dart';
import 'widgets/tx_tile.dart';
import 'widgets/tx_ui.dart';
import '../../core/providers/premium_provider.dart';
import '../../shared/widgets/app_chip.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/sheet_title.dart';
import '../../shared/widgets/tappable.dart';
import '../../shared/widgets/error_retry.dart';
import '../../shared/widgets/hint_banner.dart' show showHintIfNeeded;
import '../../shared/widgets/skeleton_loader.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets/calculator_amount_field.dart' show showCalculatorSheet;
import '../../shared/theme/app_icons.dart';
import '../../shared/widgets/seal_mark.dart';
import '../../shared/utils/calendar_days.dart';

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() =>
      _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen>
    with AutomaticKeepAliveClientMixin {
  String _searchQuery = '';
  String? _typeFilter;
  bool _showSearch = false;
  bool _showFilters = false;
  String? _accountFilter;
  // Set by "See all" from an account/envelope: list every month.
  bool _allMonthsRequested = false;
  final _searchCtrl = TextEditingController();
  String? _highlightedTxId;
  Timer? _searchDebounce;

  bool get _isFutureMonth {
    final now = DateTime.now();
    return _selectedYear > now.year ||
        (_selectedYear == now.year && _selectedMonth > now.month);
  }

  // Selection mode
  bool _selectionMode = false;
  final Set<String> _selectedIds = {};
  // Rows swiped away, hidden until the soft-delete reaches the provider
  // (or brought back by Undo).
  final Set<String> _swipedIds = {};
  // Rows currently listed (after filters) — for "Select all".
  List<TransactionEntry> _lastFiltered = const [];
  // Month navigation
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  late final ScrollController _monthScrollCtrl;
  Timer? _initialScrollTimer;

  // Advanced filters
  DateTime? _dateFrom;
  DateTime? _dateTo;
  double? _amountMin;
  double? _amountMax;

  // Quick category filter (#5)
  String? _categoryFilter;
  String? _categoryFilterName;

  // Scroll-to-today (#10)
  // The list scrolls with the tab's PrimaryScrollController so re-tapping
  // Activity in the nav bar scrolls it back to the top.
  final _ownListScrollCtrl = ScrollController();
  ScrollController? _attachedListCtrl;
  ScrollController get _listScrollCtrl =>
      _attachedListCtrl ?? _ownListScrollCtrl;
  bool _showScrollToTop = false;

  /// Title and month strip slide away while scrolling down the list and
  /// come back on the way up (more rows on small phones).
  bool _headerHidden = false;

  // Quick-add bar
  final _quickAddCtrl = TextEditingController();

  // Planned payments for the visible month
  List<Transaction> _plannedTxs = [];
  Map<String, List<TransactionLine>> _plannedLinesByTx = {};
  Map<String, Account> _plannedAccountMap = {};
  Map<String, Category> _plannedCategoryMap = {};

  @override
  void initState() {
    super.initState();
    _monthScrollCtrl = ScrollController();
    _restoreFilters();
    _loadPlanned();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // A "See all" made before this tab was first built.
      if (mounted) _applyFilterRequest(ref.read(activityFilterRequestProvider));
      // Start at the year, then glide to the selected month.
      if (_monthScrollCtrl.hasClients) {
        _monthScrollCtrl.jumpTo(0);
        _initialScrollTimer = Timer(const Duration(milliseconds: 400), () {
          _scrollMonthIntoView(const Duration(milliseconds: 600));
        });
      }
      if (!mounted) return;
      showHintIfNeeded(
        context,
        hintId: 'transactions_intro',
        icon: AppIcons.receipt,
        title: S.of(context).txIntroTitle,
        body: S.of(context).txIntroBody,
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final c = PrimaryScrollController.maybeOf(context) ?? _ownListScrollCtrl;
    if (!identical(c, _attachedListCtrl)) {
      _attachedListCtrl?.removeListener(_onListScroll);
      _attachedListCtrl = c..addListener(_onListScroll);
    }
  }

  void _onListScroll() {
    if (!_listScrollCtrl.hasClients) return;
    final pos = _listScrollCtrl.position;
    final show = pos.pixels > 500;
    var hidden = _headerHidden;
    if (pos.pixels < 80) {
      hidden = false;
    } else if (pos.userScrollDirection == ScrollDirection.reverse) {
      hidden = true;
    } else if (pos.userScrollDirection == ScrollDirection.forward) {
      hidden = false;
    }
    if (show != _showScrollToTop || hidden != _headerHidden) {
      setState(() {
        _showScrollToTop = show;
        _headerHidden = hidden;
      });
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _initialScrollTimer?.cancel();
    _searchCtrl.dispose();
    _monthScrollCtrl.dispose();
    _quickAddCtrl.dispose();
    _attachedListCtrl?.removeListener(_onListScroll);
    _ownListScrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _deleteSelected() async {
    final count = _selectedIds.length;
    final tr = S.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: tr.txDeleteSelectedTitle,
      message: tr.txDeleteSelectedContent(count),
      confirmLabel: tr.commonDelete,
    );
    if (!confirmed || !mounted) return;

    final ids = _selectedIds.toList();
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
    await deleteTransactionsWithUndo(context, ids);
  }

  // ── Bulk actions on the selection ──────────────────────────
  Future<void> _onBulkAction(String action) async {
    switch (action) {
      case 'all':
        setState(() => _selectedIds.addAll(_lastFiltered.map((e) => e.tx.id)));
      case 'export':
        final cats = ref.read(categoriesProvider).value ?? const <Category>[];
        final tr = S.of(context);
        final messenger = ScaffoldMessenger.of(context);
        try {
          await shareEntriesCsv(
              _lastFiltered
                  .where((e) => _selectedIds.contains(e.tx.id))
                  .toList(),
              {for (final c in cats) c.id: c});
        } catch (e) {
          debugPrint('[Transactions] Export failed: $e');
          messenger.showSnackBar(SnackBar(
            content: Text(tr.txExportFailed),
            behavior: SnackBarBehavior.floating,
          ));
        }
      case 'category':
        final selected = _lastFiltered
            .where((e) => _selectedIds.contains(e.tx.id))
            .toList();
        final incomeOnly =
            selected.isNotEmpty && selected.every((e) => e.tx.type == 'income');
        String? picked;
        String? pickedType;
        await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (ctx) => CategorySheet(
            categories: ref.read(categoriesProvider).value ?? const [],
            selectedId: null,
            householdId: ref.read(currentHouseholdIdProvider),
            initialType: incomeOnly ? 'income' : 'expense',
            recentIds: recentCategoryIds(
                ref.read(transactionEntriesProvider).value ?? const []),
            onSelected: (id, name, color, txType) {
              picked = id;
              pickedType = txType;
              Navigator.of(ctx).pop();
            },
            onCreated: (_) {},
          ),
        );
        if (picked == null) return;
        // Only transactions of the category's type (no transfers).
        await _bulkRewrite(
            (e) => e.tx.type == pickedType, categoryId: picked);
      case 'account':
        final accounts = ref.read(accountsProvider).value ?? const <Account>[];
        final picked = await showAccountPickerSheet(context,
            accounts: accounts, title: S.of(context).txBulkAccount);
        if (picked == null) return;
        await _bulkRewrite((e) => e.tx.type != 'transfer', accountId: picked);
      case 'date':
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime.now().add(const Duration(days: 1)),
        );
        if (picked == null) return;
        await _bulkRewrite((_) => true, date: picked);
    }
  }

  /// Re-save each selected transaction that [applies] through the engine.
  Future<void> _bulkRewrite(bool Function(TransactionEntry) applies,
      {String? categoryId, String? accountId, DateTime? date}) async {
    final tr = S.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final engine = ref.read(allocationEngineProvider);
    final targets = _lastFiltered
        .where((e) => _selectedIds.contains(e.tx.id))
        .toList();
    var done = 0, skipped = 0;
    for (final e in targets) {
      if (!applies(e)) {
        skipped++;
        continue;
      }
      try {
        await engine.rewriteTransaction(e.tx.id,
            categoryId: categoryId, accountId: accountId, date: date);
        done++;
      } catch (err) {
        debugPrint('[Transactions] Bulk edit failed for ${e.tx.id}: $err');
        skipped++;
      }
    }
    if (!mounted) return;
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
    ref.invalidate(transactionEntriesProvider);
    ref.invalidate(monthlyTransactionsProvider);
    messenger.showSnackBar(SnackBar(
      content: Text(skipped == 0
          ? tr.txBulkUpdated(done)
          : '${tr.txBulkUpdated(done)} · ${tr.txBulkSkipped(skipped)}'),
      behavior: SnackBarBehavior.floating,
    ));
  }

  /// Duplicate the single selected transaction into a new add form.
  void _duplicateSelected() {
    final id = _selectedIds.first;
    final entries = _visibleEntries();
    final e = entries.where((x) => x.tx.id == id).firstOrNull;
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
    if (e == null) return;
    context.push('/add-transaction',
        extra: txFormArgs(
            e, ref.read(categoriesProvider).value ?? const <Category>[],
            edit: false));
  }

  /// New transactions start in the month being viewed: today in the
  /// current month, the last day of a past month.
  Map<String, dynamic> _newTxDate() {
    final now = DateTime.now();
    if (_selectedYear == now.year && _selectedMonth == now.month) return {};
    final last = DateTime(_selectedYear, _selectedMonth + 1, 0);
    return {
      'editDate': DateTime(last.year, last.month, last.day, now.hour, now.minute)
    };
  }

  /// Opens the edit form straight away (selection bar Edit, swipe right).
  void _openEditForm(String id) {
    final entries = _visibleEntries();
    final e = entries.where((x) => x.tx.id == id).firstOrNull;
    if (e == null) {
      context.push('/transactions/$id');
      return;
    }
    context.push('/add-transaction',
        extra: txFormArgs(
            e, ref.read(categoriesProvider).value ?? const <Category>[],
            edit: true));
  }

  /// Search text or a date range: list every month, not just the open one.
  bool get _allMonths =>
      _allMonthsRequested ||
      _searchQuery.isNotEmpty ||
      _dateFrom != null ||
      _dateTo != null;

  void _applyFilterRequest(ActivityFilter? f) {
    if (f == null) return;
    setState(() {
      _typeFilter = null; // every type for this account/envelope
      _accountFilter = f.accountId;
      _categoryFilter = f.categoryId;
      _categoryFilterName = f.categoryName;
      _allMonthsRequested = true;
      _showFilters = false;
    });
    ref.read(activityFilterRequestProvider.notifier).clear();
  }

  List<TransactionEntry> _visibleEntries() => (_allMonths
              ? ref.read(transactionEntriesProvider)
              : ref.read(monthlyTransactionsProvider(
                  (year: _selectedYear, month: _selectedMonth))))
          .value ??
      const <TransactionEntry>[];

  void _setMonth(int year, int month) {
    _initialScrollTimer?.cancel();
    setState(() {
      _selectedYear = year;
      _selectedMonth = month;
      // Selected rows belong to the old month — don't act on hidden rows.
      _selectionMode = false;
      _selectedIds.clear();
    });
    _loadPlanned();
    // Swipes, arrows, taps and the year picker all re-center the strip
    // (after the frame, when a new year has its months laid out).
    WidgetsBinding.instance
        .addPostFrameCallback((_) { if (mounted) _scrollMonthIntoView(); });
  }

  Future<void> _loadPlanned() async {
    try {
      final db = ref.read(databaseProvider);
      final householdId = ref.read(currentHouseholdIdProvider);
      if (householdId == null) return;

      final now = DateTime.now();
      final isCurrentMonth = _selectedYear == now.year && _selectedMonth == now.month;

      // When viewing the current month, show ALL planned payments (including future months).
      // When viewing a specific past/future month, show only that month's planned items.
      final query = db.select(db.transactions)
            ..where((t) =>
                t.householdId.equals(householdId) &
                t.status.equals('planned') &
                t.deleted.equals(false))
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]);

      if (!isCurrentMonth) {
        final monthStart = DateTime(_selectedYear, _selectedMonth, 1);
        final monthEnd = DateTime(_selectedYear, _selectedMonth + 1, 1);
        query.where((t) =>
            t.createdAt.isBiggerOrEqualValue(monthStart) &
            t.createdAt.isSmallerThanValue(monthEnd));
      }

      final txs = await query.get();

      if (txs.isEmpty) {
        if (mounted) setState(() { _plannedTxs = []; _plannedLinesByTx = {}; });
        return;
      }

      final txIds = txs.map((t) => t.id).toList();
      final lines = await (db.select(db.transactionLines)
            ..where((l) => l.transactionId.isIn(txIds)))
          .get();
      final linesByTx = <String, List<TransactionLine>>{};
      for (final l in lines) {
        linesByTx.putIfAbsent(l.transactionId, () => []).add(l);
      }

      final accounts = await (db.select(db.accounts)
            ..where((a) => a.householdId.equals(householdId)))
          .get();
      final accountMap = {for (final a in accounts) a.id: a};

      final categories = await (db.select(db.categories)
            ..where((c) => c.householdId.equals(householdId)))
          .get();
      final catMap = {for (final c in categories) c.id: c};

      if (mounted) {
        setState(() {
          _plannedTxs = txs;
          _plannedLinesByTx = linesByTx;
          _plannedAccountMap = accountMap;
          _plannedCategoryMap = catMap;
        });
      }
    } catch (e) {
      debugPrint('[TransactionsScreen] Error loading planned: $e');
    }
  }

  Future<void> _restoreFilters() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _typeFilter = prefs.getString('tx_filter_type');
    });
  }

  Future<void> _saveFilters() async {
    final prefs = await SharedPreferences.getInstance();
    if (_typeFilter != null) {
      await prefs.setString('tx_filter_type', _typeFilter!);
    } else {
      await prefs.remove('tx_filter_type');
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    ref.listen(activityFilterRequestProvider,
        (_, next) => _applyFilterRequest(next));
    // Searching or a date range looks across every month.
    final entriesAsync = _allMonths
        ? ref.watch(transactionEntriesProvider)
        : ref.watch(monthlyTransactionsProvider(
            (year: _selectedYear, month: _selectedMonth)));
    final categories = ref.watch(categoriesProvider).value ?? [];
    final categoryMap = {for (final c in categories) c.id: c};

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Selection action bar ──
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubicEmphasized,
              child: !_selectionMode
                  ? const SizedBox(width: double.infinity)
                  : Container(
                      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                      padding: const EdgeInsetsDirectional.fromSTEB(4, 6, 8, 6),
                      decoration: BoxDecoration(
                        color: AppColors.sfv(context),
                        borderRadius: BorderRadius.circular(RadiusTokens.input),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(AppIcons.x),
                            onPressed: () => setState(() {
                              _selectionMode = false;
                              _selectedIds.clear();
                            }),
                          ),
                          Expanded(
                            child: Text(
                                S.of(context).txNSelected(_selectedIds.length),
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w700)),
                          ),
                          if (_selectedIds.length == 1) ...[
                            IconButton(
                              icon: const Icon(AppIcons.pencilSimple),
                              tooltip: S.of(context).txContextEdit,
                              onPressed: () {
                                final id = _selectedIds.first;
                                setState(() {
                                  _selectionMode = false;
                                  _selectedIds.clear();
                                });
                                _openEditForm(id);
                              },
                            ),
                            IconButton(
                              icon: const Icon(AppIcons.copy),
                              tooltip: S.of(context).txContextDuplicate,
                              onPressed: _duplicateSelected,
                            ),
                          ],
                          IconButton(
                            icon: const Icon(AppIcons.trash),
                            tooltip: S.of(context).txDeleteSelectedTooltip,
                            color: AppColors.overspent,
                            onPressed:
                                _selectedIds.isEmpty ? null : _deleteSelected,
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(AppIcons.dotsThreeVertical),
                            onSelected: _onBulkAction,
                            itemBuilder: (_) {
                              final tr = S.of(context);
                              return [
                                PopupMenuItem(
                                    value: 'all', child: Text(tr.txSelectAll)),
                                PopupMenuItem(
                                    value: 'category',
                                    child: Text(tr.txBulkCategory)),
                                PopupMenuItem(
                                    value: 'account',
                                    child: Text(tr.txBulkAccount)),
                                PopupMenuItem(
                                    value: 'date', child: Text(tr.txBulkDate)),
                                PopupMenuItem(
                                    value: 'export',
                                    child: Text(tr.txExportSelected)),
                              ];
                            },
                          ),
                        ],
                      ),
                    ),
            ),
            // ── Header area (the selection bar takes its place) ──
            // Keep the slot (placeholder) so the month strip below keeps its
            // element — and its scroll position — when selection toggles.
            // Both slide up out of the way while scrolling down (kept in
            // the tree so the month strip keeps its position).
            ClipRect(
              child: AnimatedAlign(
                alignment: Alignment.bottomCenter,
                heightFactor:
                    _headerHidden && !_selectionMode && !_showSearch ? 0 : 1,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _selectionMode
                        ? const SizedBox.shrink()
                        : _buildHeader(context),
                    // ── Month tabs ───────────────────────────────
                    _buildMonthTabs(context),
                  ],
                ),
              ),
            ),
            // ── Filter chips (collapsible) ───────────────────────
            if (_showFilters) _buildFilterChips(),
            if (!_showFilters) _buildActiveFilters(),
            if (_allMonths && !_allMonthsRequested)
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(20, 6, 20, 0),
                child: Text(S.of(context).txSearchingAllMonths,
                    style: TextStyle(
                        fontSize: 12, color: AppColors.ts(context))),
              ),
            // ── Content ──────────────────────────────────────────
            Expanded(
              child: GestureDetector(
                dragStartBehavior: DragStartBehavior.start,
                onHorizontalDragEnd: (details) {
                  final dx = details.primaryVelocity ?? 0;
                  final isRtl = Directionality.of(context) == TextDirection.rtl;
                  final goPrev = isRtl ? dx < 0 : dx > 0;
                  final goNext = isRtl ? dx > 0 : dx < 0;
                  if (goPrev) {
                    // Swipe toward start → previous month
                    if (_selectedMonth == 1) {
                      _setMonth(_selectedYear - 1, 12);
                    } else {
                      _setMonth(_selectedYear, _selectedMonth - 1);
                    }
                    hapticLight();
                  } else if (goNext) {
                    // Swipe toward end → next month (capped at current)
                    final now = DateTime.now();
                    if (_selectedYear < now.year || _selectedMonth < now.month) {
                      if (_selectedMonth == 12) {
                        _setMonth(_selectedYear + 1, 1);
                      } else {
                        _setMonth(_selectedYear, _selectedMonth + 1);
                      }
                      hapticLight();
                    }
                  }
                },
                child: RefreshIndicator(
                  onRefresh: () async {
                    final key = (year: _selectedYear, month: _selectedMonth);
                    ref.invalidate(monthlyTransactionsProvider(key));
                    _loadPlanned();
                    await ref.read(monthlyTransactionsProvider(key).future);
                  },
                  child: entriesAsync.when(
                    data: (entries) =>
                        _buildContent(entries, categoryMap, context),
                    loading: () => _pullable(const SkeletonList(),
                        center: false),
                    error: (e, _) => _pullable(ErrorRetry(
                      message: S.of(context).commonCouldntLoadData,
                      details: '$e',
                      onRetry: () => ref.invalidate(
                          monthlyTransactionsProvider(
                              (year: _selectedYear, month: _selectedMonth))),
                    )),
                  ),
                ),
              ),
            ),
            // ── Quick-add bar ──────────────────────────────────
            _buildQuickAddBar(context),
          ],
        ),
      ),
      floatingActionButton: _isFutureMonth ? null : Padding(
        padding: const EdgeInsets.only(bottom: 88),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_showScrollToTop) ...[
              FloatingActionButton.small(
                heroTag: 'fab_scroll_top',
                tooltip: S.of(context).txScrollTopTooltip,
                backgroundColor: AppColors.sf(context),
                foregroundColor: AppColors.tp(context),
                elevation: 2,
                onPressed: () {
                  _listScrollCtrl.animateTo(0,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOut);
                },
                child: const Icon(AppIcons.arrowUp, size: 20),
              ),
              const SizedBox(height: 8),
            ],
            FloatingActionButton.small(
              heroTag: 'fab_split',
              tooltip: S.of(context).txSplitBillTooltip,
              backgroundColor: AppColors.pastel(context, kSplitColor,
                  light: 0.75, dark: 0.55),
              foregroundColor: AppColors.tp(context),
              elevation: 2,
              onPressed: () {
                if (!checkPremiumAccess(context, ref, PremiumFeature.billSplitter)) return;
                context.push('/bill-splitter');
              },
              child: const Icon(AppIcons.arrowsSplit, size: 18),
            ),
            const SizedBox(height: 8),
            // Cashew FAB: 60px rounded square in the accent color.
            SizedBox(
              width: 60,
              height: 60,
              child: Material(
                color: AppColors.accent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(RadiusTokens.fab)),
                elevation: 3,
                shadowColor: Theme.of(context).colorScheme.shadow,
                child: InkWell(
                  customBorder: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(RadiusTokens.fab)),
                  onTap: () async {
                    hapticLight();
                    final txId = await context.push<String?>('/add-transaction',
                        extra: {'editType': 'expense', ..._newTxDate()});
                    _flashTx(txId);
                  },
                  onLongPress: () {
                    hapticMedium();
                    _showTypePicker(context);
                  },
                  child: Center(
                    child: Icon(AppIcons.plus,
                        size: 28, color: AppColors.onAccent),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// A non-list body (skeleton, empty, error) made scrollable so
  /// pull-to-refresh still works; [center] keeps it vertically centered.
  Widget _pullable(Widget child, {bool center = true}) {
    return LayoutBuilder(
      builder: (context, c) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: c.maxHeight),
          child: center ? Center(child: child) : child,
        ),
      ),
    );
  }

  void _flashTx(String? txId) {
    if (txId != null && mounted) {
      setState(() => _highlightedTxId = txId);
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) setState(() => _highlightedTxId = null);
      });
    }
  }

  void _showTypePicker(BuildContext context) {
    hapticMedium();
    final txColors = ref.read(txColorsProvider);
    // Capture context-dependent values BEFORE the sheet opens
    final tr = S.of(context);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SheetTitle(tr.txNewTransactionSheet),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  _TypeOption(
                    icon: AppIcons.minus,
                    label: tr.typeExpense,
                    color: txColors.expense,
                    onTap: () async {
                      Navigator.pop(ctx);
                      final txId = await context.push<String?>('/add-transaction',
                          extra: {'editType': 'expense', ..._newTxDate()});
                      _flashTx(txId);
                    },
                  ),
                  const SizedBox(width: 12),
                  _TypeOption(
                    icon: AppIcons.plus,
                    label: tr.typeIncome,
                    color: txColors.income,
                    onTap: () async {
                      Navigator.pop(ctx);
                      final txId = await context.push<String?>('/add-transaction',
                          extra: {'editType': 'income', ..._newTxDate()});
                      _flashTx(txId);
                    },
                  ),
                  const SizedBox(width: 12),
                  _TypeOption(
                    icon: AppIcons.arrowsLeftRight,
                    label: tr.typeTransfer,
                    color: txColors.transfer,
                    onTap: () async {
                      Navigator.pop(ctx);
                      final txId = await context.push<String?>('/add-transaction',
                          extra: {'editType': 'transfer', ..._newTxDate()});
                      _flashTx(txId);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header with title, filter icon, search icon ──────────────
  Widget _buildHeader(BuildContext context) {
    if (_showSearch) {
      return Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 8, 0),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                // Opening search means typing — bring the keyboard up.
                autofocus: true,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  hintText: S.of(context).txSearchHint,
                  hintStyle: TextStyle(color: AppColors.th(context)),
                  border: InputBorder.none,
        filled: false,
                  isDense: true,
                ),
                onChanged: (v) {
                  _searchDebounce?.cancel();
                  _searchDebounce = Timer(
                    const Duration(milliseconds: 400),
                    () { if (mounted) setState(() => _searchQuery = v); },
                  );
                },
              ),
            ),
            IconButton(
              tooltip: S.of(context).txCloseSearch,
              icon: const Icon(AppIcons.x, size: 22),
              onPressed: () {
                setState(() {
                  _showSearch = false;
                  _searchQuery = '';
                  _searchCtrl.clear();
                });
              },
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 8, 0),
      child: Row(
        children: [
          // Expanded gives the title a width, so it shrinks instead of
          // pushing the actions off screen at large text sizes. Same name
          // as the tab.
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                S.of(context).tabActivity,
                style: TextStyle(
                  fontSize: TypographyTokens.screenTitleSize,
                  fontFamily: TypographyTokens.displayFamily,
                  fontWeight: TypographyTokens.screenTitleWeight,
                  color: AppColors.tp(context),
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: S.of(context).txFilterTooltip,
            icon: Icon(
              AppIcons.funnelSimple,
              size: 22,
              color: _showFilters || _hasAnyFilter
                  ? AppColors.accent
                  : AppColors.ts(context),
            ),
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
          IconButton(
            tooltip: S.of(context).txSearchTooltip,
            icon: Icon(AppIcons.magnifyingGlass,
                size: 22, color: AppColors.ts(context)),
            onPressed: () => setState(() => _showSearch = true),
          ),
          IconButton(
            tooltip: S.of(context).txListSettingsTooltip,
            icon: Icon(AppIcons.slidersHorizontal,
                size: 21, color: AppColors.ts(context)),
            onPressed: () => context.push('/tx-list-settings'),
          ),
        ],
      ),
    );
  }

  // ── Quick-add bar (replaces FAB) ─────────────────────────────
  Widget _buildQuickAddBar(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(12, 6, 8, 6),
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        border: Border(top: BorderSide(color: AppColors.bd(context))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _quickAddCtrl,
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.tp(context),
                ),
                // The theme's filled input; only made compact for the bar.
                decoration: InputDecoration(
                  hintText: S.of(context).txQuickAddHint,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _submitQuickAdd(context),
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 38,
              height: 38,
              child: IconButton.filled(
                tooltip: S.of(context).txSendTooltip,
                padding: EdgeInsets.zero,
                icon: const Icon(AppIcons.arrowUp, size: 20),
                onPressed: () => _submitQuickAdd(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitQuickAdd(BuildContext context) async {
    final text = _quickAddCtrl.text.trim();
    if (text.isEmpty) return;

    // Parse: last number token is the amount, rest is the note/title
    // "Coffee 4,50" and "Rent 1,200.00" both work.
    final numPattern = RegExp(r'(\d[\d.,]*)\s*$');
    final match = numPattern.firstMatch(text);

    String note = text;
    double? amount;
    if (match != null) {
      amount = parseLooseAmount(match.group(1)!);
      note = text.substring(0, match.start).trim();
    }

    _quickAddCtrl.clear();

    final txId = await context.push<String?>('/add-transaction', extra: {
      'editType': 'expense',
      'editNote': note,
      if (amount != null)
        'editLines': [
          {'amount': amount, 'note': note},
        ],
    });
    _flashTx(txId);
  }

  void _showYearPicker(BuildContext context) async {
    final tr = S.of(context);
    // Back to the year of the oldest transaction (at least 5 years shown).
    final now = DateTime.now().year;
    var firstYear = now - 5;
    try {
      final db = ref.read(databaseProvider);
      final householdId = ref.read(currentHouseholdIdProvider);
      if (householdId != null) {
        final oldest = await (db.select(db.transactions)
              ..where((t) =>
                  t.householdId.equals(householdId) & t.deleted.equals(false))
              ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
              ..limit(1))
            .getSingleOrNull();
        final y = oldest?.createdAt.toLocal().year;
        if (y != null && y < firstYear) firstYear = y;
      }
    } catch (e) {
      debugPrint('[Transactions] Oldest year lookup failed: $e');
    }
    if (!context.mounted) return;
    final picked = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(tr.txSelectYear),
        children: List.generate(now - firstYear + 1, (i) {
          final y = firstYear + i;
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, y),
            child: Text('$y',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: y == _selectedYear
                        ? FontWeight.w700
                        : FontWeight.w400,
                    color: y == _selectedYear
                        ? AppColors.accent
                        : null)),
          );
        }),
      ),
    );
    if (picked != null) {
      _setMonth(picked, _selectedMonth);
    }
  }

  // ── Month tabs (year inline as first item) ─────────────────────
  static const double _kYearSlot = 76;
  static const double _kMonthSlot = 100;

  /// Space before the year / after the last month, so January and the
  /// current month (always the last item) can sit in the middle too.
  static double _monthStripStartPad(double width) =>
      math.max(0, width / 2 - _kYearSlot - _kMonthSlot / 2);
  static double _monthStripEndPad(double width) =>
      math.max(0, width / 2 - _kMonthSlot / 2);

  /// Center the selected month in the month strip (fixed slot widths make
  /// this exact).
  void _scrollMonthIntoView(
      [Duration duration = const Duration(milliseconds: 350)]) {
    if (!_monthScrollCtrl.hasClients) return;
    final pos = _monthScrollCtrl.position;
    final center = _monthStripStartPad(pos.viewportDimension) +
        _kYearSlot +
        (_selectedMonth - 1) * _kMonthSlot +
        _kMonthSlot / 2;
    final target = (center - pos.viewportDimension / 2)
        .clamp(0.0, pos.maxScrollExtent);
    _monthScrollCtrl.animateTo(target,
        duration: duration, curve: Curves.easeOutCubic);
  }

  Widget _buildMonthTabs(BuildContext context) {
    final now = DateTime.now();
    final monthCount = _selectedYear == now.year ? now.month : 12;

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: SizedBox(
            height: 50,
            child: Row(
              children: [
                // Left arrow
                Tappable(
                  borderRadius: BorderRadius.circular(RadiusTokens.md),
                  onTap: () {
                    hapticLight();
                    if (_selectedMonth == 1) {
                      _setMonth(_selectedYear - 1, 12);
                    } else {
                      _setMonth(_selectedYear, _selectedMonth - 1);
                    }
                    _scrollMonthIntoView();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(AppIcons.caretLeft,
                        size: 22, color: AppColors.ts(context)),
                  ),
                ),
                // Year + Month list (year is the first item)
                Expanded(
                  // Wide enough that a month cut at the edge fades out
                  // instead of showing a stray letter.
                  child: FadedEdges(
                  startFade: 48,
                  endFade: 32,
                  child: LayoutBuilder(builder: (context, box) => ListView.builder(
                    controller: _monthScrollCtrl,
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsetsDirectional.only(
                      start: _monthStripStartPad(box.maxWidth),
                      end: _monthStripEndPad(box.maxWidth),
                    ),
                    itemCount: monthCount + 1, // +1 for year item
                    itemBuilder: (_, i) {
                      // First item: year selector
                      if (i == 0) {
                        return Tappable(
                          borderRadius:
                              BorderRadius.circular(RadiusTokens.md),
                          onTap: () => _showYearPicker(context),
                          child: Container(
                            width: _kYearSlot,
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('$_selectedYear',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.accent)),
                                Icon(AppIcons.caretDown,
                                    size: 14, color: AppColors.accent),
                              ],
                            ),
                          ),
                        );
                      }
                      final month = i; // i=1 → month 1 (Jan)
                      final isSelected = month == _selectedMonth;
                      final isCurrent =
                          _selectedYear == now.year && month == now.month;
                      final label =
                          formatMonth(DateTime(2000, month));
                      // Cashew monthSelector: fixed 100px slot, track line,
                      // animated pill under the selected month.
                      return SizedBox(
                        width: _kMonthSlot,
                        child: InkWell(
                          borderRadius:
                              BorderRadius.circular(RadiusTokens.md),
                          onTap: () {
                            hapticSelection();
                            _setMonth(_selectedYear, month);
                            _scrollMonthIntoView();
                          },
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                child: Container(
                                    height: 2, color: AppColors.bd(context)),
                              ),
                              Positioned(
                                bottom: 0,
                                child: AnimatedScale(
                                  scale: isSelected ? 1 : 0.4,
                                  duration: const Duration(milliseconds: 500),
                                  curve: isSelected
                                      ? Curves.decelerate
                                      : Curves.easeOutQuart,
                                  child: AnimatedOpacity(
                                    opacity: isSelected ? 1 : 0,
                                    duration: const Duration(milliseconds: 300),
                                    child: Container(
                                      width: _kMonthSlot - 20,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: AppColors.tp(context),
                                        borderRadius:
                                            const BorderRadius.vertical(
                                                top: Radius.circular(40)),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 6),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: AnimatedDefaultTextStyle(
                                    duration: const Duration(milliseconds: 200),
                                    style: TextStyle(
                                      fontFamily: DefaultTextStyle.of(context)
                                          .style
                                          .fontFamily,
                                      fontSize: 14.5,
                                      fontWeight: isSelected || isCurrent
                                          ? FontWeight.w800
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? AppColors.tp(context)
                                          : AppColors.ts(context),
                                    ),
                                    child: Text(label),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  )),
                )),
                // Right arrow (hidden if at current month)
                if (!_isFutureMonth && !(_selectedYear == DateTime.now().year && _selectedMonth == DateTime.now().month))
                Tappable(
                  borderRadius: BorderRadius.circular(RadiusTokens.md),
                  onTap: () {
                    final now = DateTime.now();
                    hapticLight();
                    if (_selectedMonth == 12) {
                      if (_selectedYear < now.year) {
                        _setMonth(_selectedYear + 1, 1);
                      }
                    } else {
                      if (_selectedYear < now.year || _selectedMonth < now.month) {
                        _setMonth(_selectedYear, _selectedMonth + 1);
                      }
                    }
                    _scrollMonthIntoView();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(AppIcons.caretRight,
                        size: 22, color: AppColors.ts(context)),
                  ),
                ),
              ],
            ),
      ),
    );
  }

  // ── Filter chips (shown when filter icon tapped) ─────────────
  Widget _buildFilterChips() {
    final hasAdvancedFilters =
        _dateFrom != null || _dateTo != null || _amountMin != null || _amountMax != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Type filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 2),
          child: Row(
            children: [
              AppChip(
                label: S.of(context).typeAll,
                selected: _typeFilter == null,
                onTap: () { setState(() => _typeFilter = null); _saveFilters(); },
              ),
              const SizedBox(width: 8),
              AppChip(
                label: S.of(context).typeIncome,
                selected: _typeFilter == 'income',
                color: ref.watch(txColorsProvider).income,
                onTap: () { setState(() => _typeFilter = 'income'); _saveFilters(); },
              ),
              const SizedBox(width: 8),
              AppChip(
                label: S.of(context).typeExpense,
                selected: _typeFilter == 'expense',
                color: ref.watch(txColorsProvider).expense,
                onTap: () { setState(() => _typeFilter = 'expense'); _saveFilters(); },
              ),
              const SizedBox(width: 8),
              AppChip(
                label: S.of(context).typeTransfer,
                selected: _typeFilter == 'transfer',
                color: ref.watch(txColorsProvider).transfer,
                onTap: () { setState(() => _typeFilter = 'transfer'); _saveFilters(); },
              ),
            ],
          ),
        ),
        // Date range filter
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: Row(
            children: [
              Icon(AppIcons.calendarBlank,
                  size: 16, color: AppColors.ts(context)),
              const SizedBox(width: 8),
              Expanded(
                child: Tappable(
                  onTap: () => _pickDate(isFrom: true),
                  borderRadius: BorderRadius.circular(RadiusTokens.input),
                  child: InputDecorator(
                    isEmpty: _dateFrom == null,
                    decoration: InputDecoration(
                      hintText: S.of(context).txFromDate,
                      isDense: true,
                    ),
                    child: Text(
                      _dateFrom != null ? formatDate(_dateFrom!) : '',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.tp(context)),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text('–',
                    style: TextStyle(
                        color: AppColors.ts(context), fontSize: 16)),
              ),
              Expanded(
                child: Tappable(
                  onTap: () => _pickDate(isFrom: false),
                  borderRadius: BorderRadius.circular(RadiusTokens.input),
                  child: InputDecorator(
                    isEmpty: _dateTo == null,
                    decoration: InputDecoration(
                      hintText: S.of(context).txToDate,
                      isDense: true,
                    ),
                    child: Text(
                      _dateTo != null ? formatDate(_dateTo!) : '',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.tp(context)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Amount range filter — the calculator, never the keyboard; 0 clears.
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Row(
            children: [
              Expanded(
                child: _FilterPickerBox(
                  icon: AppIcons.arrowLineDown,
                  label: _amountMin != null
                      ? formatNumber(_amountMin!)
                      : S.of(context).txMinAmount,
                  active: _amountMin != null,
                  onTap: () async {
                    final v = await showCalculatorSheet(context, _amountMin ?? 0);
                    if (v != null && mounted) {
                      setState(() => _amountMin = v == 0 ? null : v);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _FilterPickerBox(
                  icon: AppIcons.arrowLineUp,
                  label: _amountMax != null
                      ? formatNumber(_amountMax!)
                      : S.of(context).txMaxAmount,
                  active: _amountMax != null,
                  onTap: () async {
                    final v = await showCalculatorSheet(context, _amountMax ?? 0);
                    if (v != null && mounted) {
                      setState(() => _amountMax = v == 0 ? null : v);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        // Account + category
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Row(
            children: [
              Expanded(
                child: _FilterPickerBox(
                  icon: AppIcons.wallet,
                  label: _accountFilter != null
                      ? (ref
                              .watch(accountsProvider)
                              .value
                              ?.where((a) => a.id == _accountFilter)
                              .firstOrNull
                              ?.name ??
                          S.of(context).txAllAccounts)
                      : S.of(context).txAllAccounts,
                  active: _accountFilter != null,
                  onTap: _pickAccountFilter,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _FilterPickerBox(
                  icon: AppIcons.squaresFour,
                  label: _categoryFilterName ?? S.of(context).txAllCategories,
                  active: _categoryFilter != null,
                  onTap: _pickCategoryFilter,
                ),
              ),
            ],
          ),
        ),
        // Clear all filters button
        if (hasAdvancedFilters || _hasAnyFilter)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Tappable(
                onTap: _clearAllFilters,
                borderRadius: BorderRadius.circular(RadiusTokens.sm),
                child: Text(
                  S.of(context).txClearAllFilters,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accentText(context),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  bool get _hasAnyFilter =>
      _typeFilter != null ||
      _accountFilter != null ||
      _categoryFilter != null ||
      _dateFrom != null ||
      _dateTo != null ||
      _amountMin != null ||
      _amountMax != null;

  void _clearAllFilters() {
    setState(() {
      _allMonthsRequested = false;
      _typeFilter = null;
      _accountFilter = null;
      _categoryFilter = null;
      _categoryFilterName = null;
      _dateFrom = null;
      _dateTo = null;
      _amountMin = null;
      _amountMax = null;
    });
    _saveFilters();
  }

  Future<void> _pickAccountFilter() async {
    final tr = S.of(context);
    final accounts = ref.read(accountsProvider).value ?? const <Account>[];
    final picked = await showAccountPickerSheet(context,
        accounts: accounts,
        title: tr.commonAccount,
        selectedId: _accountFilter,
        allLabel: tr.txAllAccounts);
    if (picked == null || !mounted) return;
    setState(() => _accountFilter = picked.isEmpty ? null : picked);
  }

  Future<void> _pickCategoryFilter() async {
    final categories = ref.read(categoriesProvider).value ?? const <Category>[];
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CategorySheet(
        categories: categories,
        selectedId: _categoryFilter,
        householdId: ref.read(currentHouseholdIdProvider),
        initialType: _typeFilter == 'income' ? 'income' : 'expense',
        recentIds: recentCategoryIds(
            ref.read(transactionEntriesProvider).value ?? const []),
        onSelected: (id, name, color, txType) {
          Navigator.of(ctx).pop();
          if (!mounted) return;
          setState(() {
            _categoryFilter = id;
            _categoryFilterName = name;
          });
        },
        onCreated: (_) {},
      ),
    );
  }

  /// Active filters as removable chips (when the filter panel is closed).
  Widget _buildActiveFilters() {
    final tr = S.of(context);
    final chips = <(String, VoidCallback)>[
      if (_typeFilter != null)
        (
          switch (_typeFilter) {
            'income' => tr.typeIncome,
            'expense' => tr.typeExpense,
            _ => tr.typeTransfer,
          },
          () {
            setState(() => _typeFilter = null);
            _saveFilters();
          }
        ),
      if (_accountFilter != null)
        (
          ref
                  .watch(accountsProvider)
                  .value
                  ?.where((a) => a.id == _accountFilter)
                  .firstOrNull
                  ?.name ??
              tr.commonAccount,
          () => setState(() => _accountFilter = null)
        ),
      if (_categoryFilter != null)
        (
          _categoryFilterName ?? tr.commonCategory,
          () => setState(() {
                _categoryFilter = null;
                _categoryFilterName = null;
              })
        ),
      if (_dateFrom != null || _dateTo != null)
        (
          '${_dateFrom != null ? formatDate(_dateFrom!) : '…'} – ${_dateTo != null ? formatDate(_dateTo!) : '…'}',
          () => setState(() {
                _dateFrom = null;
                _dateTo = null;
              })
        ),
      if (_amountMin != null || _amountMax != null)
        (
          '${_amountMin != null ? formatNumber(_amountMin!) : '…'} – ${_amountMax != null ? formatNumber(_amountMax!) : '…'}',
          () => setState(() {
                _amountMin = null;
                _amountMax = null;
              })
        ),
    ];
    if (_allMonthsRequested) {
      chips.insert(0, (
        tr.txAllMonths,
        () => setState(() => _allMonthsRequested = false)
      ));
    }
    if (chips.isEmpty) return const SizedBox.shrink();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        children: [
          for (final (label, onRemove) in chips)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 6),
              // Tap removes the filter (the × says so); the funnel opens
              // the panel.
              child: AppChip(
                label: label,
                selected: true,
                icon: AppIcons.x,
                onTap: onRemove,
              ),
            ),
          if (chips.length > 1)
            TextButton(
              onPressed: _clearAllFilters,
              child: Text(tr.txClearAll),
            ),
        ],
      ),
    );
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = isFrom
        ? (_dateFrom ?? DateTime.now())
        : (_dateTo ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _dateFrom = picked;
        } else {
          _dateTo = picked;
        }
      });
    }
  }

  // ── Main content builder ─────────────────────────────────────
  Widget _buildContent(List<TransactionEntry> entries,
      Map<String, Category> categoryMap, BuildContext context) {
    if (_swipedIds.isNotEmpty) {
      entries = entries.where((e) => !_swipedIds.contains(e.tx.id)).toList();
    }
    // Month filtering is already done at the SQL level via
    // monthlyTransactionsProvider. Apply all filters in a single pass.
    final hasDateFilter = _dateFrom != null || _dateTo != null;
    final hasTypeFilter = _typeFilter != null;
    final hasCategoryFilter = _categoryFilter != null;
    final hasAmountFilter = _amountMin != null || _amountMax != null;
    final hasSearch = _searchQuery.isNotEmpty;
    final q = hasSearch ? _searchQuery.toLowerCase() : '';
    final hasAccountFilter = _accountFilter != null;
    final hasAnyFilter = hasDateFilter || hasTypeFilter || hasCategoryFilter ||
        hasAmountFilter || hasSearch || hasAccountFilter;

    final filtered = hasAnyFilter
        ? entries.where((e) {
            // Date range
            if (hasDateFilter) {
              final d = e.tx.createdAt.toLocal();
              final dayOnly = DateTime(d.year, d.month, d.day);
              if (_dateFrom != null && dayOnly.isBefore(_dateFrom!)) return false;
              if (_dateTo != null && dayOnly.isAfter(_dateTo!)) return false;
            }
            // Type
            if (hasTypeFilter && e.tx.type != _typeFilter) return false;
            // Account (either side of a transfer, or any line's account)
            if (hasAccountFilter &&
                e.tx.accountId != _accountFilter &&
                e.tx.destinationAccountId != _accountFilter &&
                !e.lines.any((l) => l.accountId == _accountFilter)) {
              return false;
            }
            // Category
            if (hasCategoryFilter) {
              // The category or one of its subcategories.
              bool inFilter(String? id) =>
                  id != null &&
                  (id == _categoryFilter ||
                      categoryMap[id]?.parentId == _categoryFilter);
              if (!inFilter(e.tx.categoryId) &&
                  !e.lines.any((l) => inFilter(l.categoryId))) {
                return false;
              }
            }
            // Amount range
            if (hasAmountFilter) {
              final amt = e.tx.amount;
              if (_amountMin != null && amt < _amountMin!) return false;
              if (_amountMax != null && amt > _amountMax!) return false;
            }
            // Search
            if (hasSearch) {
              if (e.tx.note.toLowerCase().contains(q)) return true;
              if (e.accountName.toLowerCase().contains(q)) return true;
              if (e.tx.amount.toStringAsFixed(2).contains(q)) return true;
              final cat = e.tx.categoryId != null ? categoryMap[e.tx.categoryId] : null;
              if (cat != null && cat.name.toLowerCase().contains(q)) return true;
              for (final line in e.lines) {
                if (line.note.toLowerCase().contains(q)) return true;
                final lineCat = line.categoryId != null ? categoryMap[line.categoryId] : null;
                if (lineCat != null && lineCat.name.toLowerCase().contains(q)) return true;
              }
              return false;
            }
            return true;
          }).toList()
        : entries.toList();

    if (filtered.isEmpty) {
      final hasFilters = _searchQuery.isNotEmpty || _hasAnyFilter;
      final monthLabel = formatMonth(
          DateTime(_selectedYear, _selectedMonth), short: true, year: true);
      return _pullable(Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_categoryFilter != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppChip(
                label: S.of(context).txFilteredCategory(
                    _categoryFilterName ?? S.of(context).commonCategory),
                selected: true,
                icon: AppIcons.x,
                onTap: () => setState(() {
                  _categoryFilter = null;
                  _categoryFilterName = null;
                }),
              ),
            ),
          EmptyState(
            art: !hasFilters,
            icon: hasFilters
                ? AppIcons.magnifyingGlassMinus
                : AppIcons.receipt,
            title: _categoryFilter != null
                ? S.of(context).txNoCategoryInMonth(_categoryFilterName ?? S.of(context).commonCategory, monthLabel)
                : hasFilters
                    ? S.of(context).txNoMatching
                    : S.of(context).txNoYet,
            subtitle: hasFilters ? null : S.of(context).txTapPlus,
            // No match: one tap back to everything. Nothing yet: the
            // subtitle points at the + button (no second button under it).
            actionLabel: hasFilters ? S.of(context).txClearAllFilters : null,
            onAction: hasFilters
                ? () {
                    _clearAllFilters();
                    if (_searchQuery.isNotEmpty) {
                      setState(() {
                        _searchQuery = '';
                        _searchCtrl.clear();
                      });
                    }
                  }
                : null,
          ),
        ],
      ));
    }

    // Compute month summary — skip lines where currency differs from base
    // but rate is 1.0 (exchange rate not set), as those would inflate totals.
    _lastFiltered = filtered;
    final baseCurrencyForSummary =
        ref.read(householdProvider).value?.baseCurrency ?? 'USD';
    double monthExpense = 0, monthIncome = 0;
    for (final e in filtered) {
      double baseAmt = 0;
      if (e.lines.isNotEmpty) {
        for (final l in e.lines) {
          // Skip lines with bogus rate (foreign currency with rate=1.0)
          if (l.currency != baseCurrencyForSummary &&
              (l.exchangeRateToBase - 1.0).abs() < 0.001) {
            continue;
          }
          baseAmt += l.amount * l.exchangeRateToBase;
        }
      } else {
        if (e.tx.currency == baseCurrencyForSummary ||
            (e.tx.exchangeRateToBase - 1.0).abs() >= 0.001) {
          baseAmt = e.tx.amount * e.tx.exchangeRateToBase;
        }
      }
      if (e.tx.type == 'expense') monthExpense += baseAmt;
      if (e.tx.type == 'income') monthIncome += baseAmt;
    }

    final baseCurrency =
        ref.read(householdProvider).value?.baseCurrency ?? 'USD';
    final groups = _buildGroups(filtered);
    final net = monthIncome - monthExpense;
    final showDayTotal =
        ref.watch(txListSettingsProvider).dateBannerTotal == 'dayTotal';

    // The month card's "budgeted": spending envelopes' targets in the base
    // currency (flexible targets are savings totals, not a month's budget).
    final allocations = ref.watch(allocationsProvider).value ?? [];
    double totalBudget = 0;
    for (final a in allocations) {
      final target = a.data.allocation.targetAmount ?? 0;
      if (target <= 0 || a.data.allocation.type != 'spending') continue;
      final targetCcy = a.data.allocation.targetCurrency ?? baseCurrency;
      // Only include envelopes in base currency to avoid mixing
      if (targetCcy == baseCurrency) {
        totalBudget += target;
      }
    }

    return Column(
      children: [
        // ── Category quick filter chip (#5) ───────────────────
        if (_categoryFilter != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: AppChip(
                label: S.of(context).txFilteredCategory(
                    _categoryFilterName ?? S.of(context).commonCategory),
                selected: true,
                icon: AppIcons.x,
                onTap: () => setState(() {
                  _categoryFilter = null;
                  _categoryFilterName = null;
                }),
              ),
            ),
          ),
        // ── Transaction list (sticky date headers) ──────────────
        Expanded(
          child: CustomScrollView(
            controller: _listScrollCtrl,
            slivers: [
              // The month's budget on top; with filters, the filtered
              // expense/income/net instead.
              if (!hasAnyFilter && !_allMonths)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: _MonthBudgetCard(
                      year: _selectedYear,
                      month: _selectedMonth,
                      spent: monthExpense,
                      income: monthIncome,
                      budgeted: totalBudget,
                      currency: baseCurrency,
                    ),
                  ),
                ),
              if (hasAnyFilter)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                  child: _MonthlySummaryBar(
                    entries: filtered,
                    baseCurrency: baseCurrency,
                  ),
                ),
              ),
              // Planned payments section (dimmed, above real transactions)
              if (_plannedTxs.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                    child: _PlannedSection(
                      transactions: _plannedTxs,
                      linesByTx: _plannedLinesByTx,
                      accountMap: _plannedAccountMap,
                      categoryMap: _plannedCategoryMap,
                      onRefresh: _loadPlanned,
                    ),
                  ),
                ),
              // One card per day: date header, then the rows with hairlines.
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, gi) {
                      final group = groups[gi];
                      return Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: _DayCard(
                          header: _DateHeaderTile(
                            date: group.date,
                            dayTotal: group.dayTotal,
                            baseCurrency: group.baseCurrency,
                            showTotal: showDayTotal,
                          ),
                          rows: [
                            for (var i = 0; i < group.entries.length; i++)
                              _buildTxRow(context, group.entries[i],
                                  group.entries, i, categoryMap),
                          ],
                        ),
                      );
                    },
                    childCount: groups.length,
                  ),
                ),
              ),
              // Footer
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  child: _CashFlowFooter(
                    total: net,
                    count: filtered.length,
                    baseCurrency: baseCurrency,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _toggleSelected(String id) {
    hapticSelection();
    setState(() {
      if (!_selectionMode) {
        _selectionMode = true;
        _selectedIds.add(id);
      } else if (!_selectedIds.remove(id)) {
        _selectedIds.add(id);
      } else if (_selectedIds.isEmpty) {
        _selectionMode = false;
      }
    });
  }

  /// One transaction row: selection highlight (Cashew merges adjacent
  /// selected rows into one block), animated check, swipe actions.
  Widget _buildTxRow(BuildContext context, TransactionEntry e,
      List<TransactionEntry> siblings, int i, Map<String, Category> categoryMap) {
    final isSelected = _selectedIds.contains(e.tx.id);
    // Rows fill their day card edge to edge (the card clips the corners),
    // so adjacent selected rows read as one block.
    const radius = BorderRadius.zero;

    final row = AnimatedContainer(
      // Flash for a just-added transaction (fades over 1.5s).
      duration: const Duration(milliseconds: 1500),
      decoration: BoxDecoration(
        color: _highlightedTxId == e.tx.id
            ? AppColors.accentLight
            : Colors.transparent,
        borderRadius: radius,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubicEmphasized,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.pastel(context, AppColors.accent,
                  light: 0.78, dark: 0.7)
              : Colors.transparent,
          borderRadius: radius,
        ),
        child: Row(
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubicEmphasized,
              child: _selectionMode
                  ? Padding(
                      padding: const EdgeInsetsDirectional.only(start: 8),
                      child: _SelectCheck(selected: isSelected),
                    )
                  : const SizedBox.shrink(),
            ),
            Expanded(
              child: TxTile(
                entry: e,
                categoryMap: categoryMap,
                balanceAccountId: _accountFilter,
                onCategoryTap: _selectionMode
                    ? null
                    : (catId, catName) {
                        hapticLight();
                        setState(() {
                          _categoryFilter = catId;
                          _categoryFilterName = catName;
                        });
                      },
                onTap: _selectionMode ? () => _toggleSelected(e.tx.id) : null,
                onLongPress: () => _toggleSelected(e.tx.id),
              ),
            ),
          ],
        ),
      ),
    );

    if (_selectionMode) return row;

    const swipeRadius = BorderRadius.zero;
    return Dismissible(
      key: ValueKey(e.tx.id),
      direction: DismissDirection.horizontal,
      // Swipe right → edit
      background: Container(
        alignment: AlignmentDirectional.centerStart,
        padding: const EdgeInsetsDirectional.only(start: 20),
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: swipeRadius,
        ),
        child: Icon(AppIcons.pencilSimple, color: AppColors.onAccent),
      ),
      // Swipe left → delete
      secondaryBackground: Container(
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsetsDirectional.only(end: 20),
        decoration: BoxDecoration(
          color: AppColors.overspent,
          borderRadius: swipeRadius,
        ),
        child: Icon(AppIcons.trash,
            color: AppColors.inkOn(AppColors.overspent)),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          _openEditForm(e.tx.id);
          return false; // don't dismiss
        }
        return true; // Undo on the SnackBar replaces a confirm dialog
      },
      onDismissed: (_) {
        // Hide the row now — the Dismissible must leave the tree this frame,
        // before the soft-delete reaches the provider.
        setState(() => _swipedIds.add(e.tx.id));
        deleteTransactionsWithUndo(context, [e.tx.id],
            onUndo: () {
          if (mounted) setState(() => _swipedIds.remove(e.tx.id));
        });
      },
      child: row,
    );
  }

  List<({DateTime date, double dayTotal, String baseCurrency, List<TransactionEntry> entries})>
      _buildGroups(List<TransactionEntry> entries) {
    final baseCurrency =
        ref.read(householdProvider).value?.baseCurrency ?? 'USD';

    final dayGroups = <String, List<TransactionEntry>>{};
    final dayDates = <String, DateTime>{};
    for (final entry in entries) {
      final local = entry.tx.createdAt.toLocal();
      final dateKey = DateFormat('yyyy-MM-dd').format(local);
      dayGroups.putIfAbsent(dateKey, () => []).add(entry);
      dayDates.putIfAbsent(dateKey, () => local);
    }

    final result = <({DateTime date, double dayTotal, String baseCurrency, List<TransactionEntry> entries})>[];
    for (final dateKey in dayGroups.keys) {
      final dayEntries = dayGroups[dateKey]!;
      double dayTotal = 0;
      for (final e in dayEntries) {
        double baseAmt = 0;
        if (e.lines.isNotEmpty) {
          for (final l in e.lines) {
            if (!isRealRate(l.currency, baseCurrency, l.exchangeRateToBase)) continue;
            baseAmt += l.amount * l.exchangeRateToBase;
          }
        } else {
          if (isRealRate(e.tx.currency, baseCurrency, e.tx.exchangeRateToBase)) {
            baseAmt = e.tx.amount * e.tx.exchangeRateToBase;
          }
        }
        if (e.tx.type == 'income') {
          dayTotal += baseAmt;
        } else if (e.tx.type == 'expense') {
          dayTotal -= baseAmt;
        }
      }
      result.add((
        date: dayDates[dateKey]!,
        dayTotal: dayTotal,
        baseCurrency: baseCurrency,
        entries: dayEntries,
      ));
    }
    return result;
  }
}

// ---------------------------------------------------------------------------
// Planned payments section (dimmed, above real transactions)
// ---------------------------------------------------------------------------

class _PlannedSection extends StatelessWidget {
  final List<Transaction> transactions;
  final Map<String, List<TransactionLine>> linesByTx;
  final Map<String, Account> accountMap;
  final Map<String, Category> categoryMap;
  final VoidCallback? onRefresh;

  const _PlannedSection({
    required this.transactions,
    required this.linesByTx,
    required this.accountMap,
    required this.categoryMap,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.pastel(context, kPlannedColor,
                      light: 0.85, dark: 0.75),
                  borderRadius: BorderRadius.circular(RadiusTokens.sm),
                ),
                child: Text(
                  S.of(context).plannedBadge,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: kPlannedColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Divider(
                  color: AppColors.bd(context),
                  height: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final tx in transactions)
            _PlannedTile(
              tx: tx,
              lines: linesByTx[tx.id] ?? [],
              accountMap: accountMap,
              categoryMap: categoryMap,
              onRefresh: onRefresh,
            ),
        ],
      ),
    );
  }
}

class _PlannedTile extends StatelessWidget {
  final Transaction tx;
  final List<TransactionLine> lines;
  final Map<String, Account> accountMap;
  final Map<String, Category> categoryMap;
  final VoidCallback? onRefresh;

  const _PlannedTile({
    required this.tx,
    required this.lines,
    required this.accountMap,
    required this.categoryMap,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    // Resolve category
    String? catName;
    Category? cat;
    if (lines.isNotEmpty && lines.first.categoryId != null) {
      cat = categoryMap[lines.first.categoryId];
    }
    cat ??= tx.categoryId != null ? categoryMap[tx.categoryId] : null;
    catName = cat?.name;

    // Display name
    final displayName = catName ?? (tx.note.isNotEmpty ? tx.note : tx.type);

    // Amount
    final displayCurrency = lines.isNotEmpty ? lines.first.currency : tx.currency;
    final displayAmount = lines.isNotEmpty ? lines.first.amount : tx.amount;

    // Date
    final date = tx.createdAt.toLocal();

    return Tappable(
      onTap: () async {
        await context.push('/plan-payment', extra: {
          'transaction': tx,
          'lines': lines,
        });
        onRefresh?.call();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            // Purple dot icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.pastel(context, kPlannedColor,
                    light: 0.85, dark: 0.75),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(
                  tx.type == 'income'
                      ? AppIcons.plus
                      : tx.type == 'transfer'
                          ? AppIcons.arrowsLeftRight
                          : AppIcons.minus,
                  size: 16,
                  color: kPlannedColor,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Name + note
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.tp(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (catName != null && tx.note.isNotEmpty)
                    Text(
                      tx.note,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.ts(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Amount + date
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatSignedAmount(displayAmount,
                      currency: displayCurrency, type: tx.type),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.tp(context),
                  ),
                ),
                Text(
                  formatDate(date),
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.th(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter chip
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Date header tile — natural case, like "Today, April 11"
// ---------------------------------------------------------------------------

/// Cashew selection check: outlined circle that fills with a check.
class _SelectCheck extends StatelessWidget {
  final bool selected;
  const _SelectCheck({required this.selected});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 275),
      switchInCurve: Curves.easeOutBack,
      transitionBuilder: (child, anim) => ScaleTransition(
        scale: Tween(begin: 0.85, end: 1.0).animate(anim),
        child: FadeTransition(opacity: anim, child: child),
      ),
      child: Container(
        key: ValueKey(selected),
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? AppColors.accent : Colors.transparent,
          border: Border.all(
            color: selected
                ? AppColors.accent
                : AppColors.pastel(context, AppColors.accent,
                    light: 0.35, dark: 0.3),
            width: 2,
          ),
        ),
        child: selected
            ? Icon(AppIcons.check, size: 16, color: AppColors.onAccent)
            : null,
      ),
    );
  }
}

/// One day of Activity: a card holding the date header and the rows,
/// separated by hairlines. Clips so swipe and selection fills keep the
/// card's corners.
class _DayCard extends StatelessWidget {
  final Widget header;
  final List<Widget> rows;
  const _DayCard({required this.header, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppColors.card(context),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Divider(height: 1, thickness: 1, color: AppColors.bd(context)),
            rows[i],
          ],
        ],
      ),
    );
  }
}

class _DateHeaderTile extends StatelessWidget {
  final DateTime date;
  final double dayTotal;
  final String baseCurrency;
  final bool showTotal;
  const _DateHeaderTile({
    required this.date,
    this.dayTotal = 0,
    this.baseCurrency = 'USD',
    this.showTotal = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 16, 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            _name(context),
            style: TextStyle(
              fontFamily: TypographyTokens.displayFamily,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.tp(context),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              formatDate(date),
              style: TextStyle(fontSize: 12.5, color: AppColors.ts(context)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (showTotal && dayTotal.abs() >= 0.005)
            Text(
              dayTotal > 0
                  ? bidiSafeAmount('+${formatAmount(dayTotal, currency: baseCurrency)}')
                  : formatAmount(dayTotal, currency: baseCurrency),
              style: TextStyle(
                fontFamily: TypographyTokens.displayFamily,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.ts(context),
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
        ],
      ),
    );
  }

  /// Today / Yesterday / the weekday.
  String _name(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    final diff = calendarDaysBetween(d, today);
    if (diff == 0) return S.of(context).commonToday;
    if (diff == 1) return S.of(context).commonYesterday;
    return capitalizedFirst(DateFormat.EEEE().format(date));
  }
}

/// Top of Activity: the month's budget — what's left of the spending
/// envelopes' targets, a gold bar, spent of budgeted and income. A past
/// month that stayed within budget closes as "September sealed".
class _MonthBudgetCard extends StatelessWidget {
  final int year;
  final int month;
  final double spent;
  final double income;
  final double budgeted;
  final String currency;

  const _MonthBudgetCard({
    required this.year,
    required this.month,
    required this.spent,
    required this.income,
    required this.budgeted,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final now = DateTime.now();
    final isPast = year < now.year || (year == now.year && month < now.month);
    final monthName =
        formatMonth(DateTime(year, month, 15));
    String f(double v) => formatAmount(v, currency: currency);
    final hasBudget = budgeted > 0;
    final left = budgeted - spent;
    final over = left < -0.005;
    final detail = hasBudget
        ? s.txMonthSpentOf(f(spent), f(budgeted), f(income))
        : s.txMonthSpent(f(spent), f(income));
    const tabular = [FontFeature.tabularFigures()];
    final titleStyle = TextStyle(
      fontFamily: TypographyTokens.displayFamily,
      fontWeight: FontWeight.w700,
      color: AppColors.tp(context),
    );
    final decoration = AppColors.card(context);
    final detailStyle = TextStyle(fontSize: 13, color: AppColors.ts(context));

    // A finished month within its budget: one calm line with the seal.
    if (isPast && hasBudget && !over) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: decoration,
        child: Row(
          children: [
            const SealMark(size: 34),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.periodSealedTitle(monthName),
                      style: titleStyle.copyWith(fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(detail, style: detailStyle.copyWith(fontSize: 12.5)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: decoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    hasBudget ? s.txMonthBudget(monthName) : monthName,
                    style: titleStyle.copyWith(fontSize: 20),
                    maxLines: 1,
                  ),
                ),
              ),
              if (hasBudget) ...[
                const SizedBox(width: 12),
                Text(
                  over ? s.txImpactOver(f(-left)) : s.txImpactLeft(f(left)),
                  style: titleStyle.copyWith(
                    fontSize: 16,
                    color: over
                        ? AppColors.overspent
                        : AppColors.accentText(context),
                    fontFeatures: tabular,
                  ),
                ),
              ],
            ],
          ),
          if (hasBudget) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (spent / budgeted).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: AppColors.sfv(context),
                valueColor: AlwaysStoppedAnimation<Color>(
                    over ? AppColors.overspent : AppColors.accentBright),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(detail, style: detailStyle),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Cash flow footer
// ---------------------------------------------------------------------------

class _MonthlySummaryBar extends StatelessWidget {
  final List<TransactionEntry> entries;
  final String baseCurrency;

  const _MonthlySummaryBar({required this.entries, required this.baseCurrency});

  @override
  Widget build(BuildContext context) {
    double income = 0, expense = 0;
    for (final e in entries) {
      double baseAmt = 0;
      if (e.lines.isNotEmpty) {
        for (final l in e.lines) {
          if (!isRealRate(l.currency, baseCurrency, l.exchangeRateToBase)) continue;
          baseAmt += l.amount * l.exchangeRateToBase;
        }
      } else {
        if (isRealRate(e.tx.currency, baseCurrency, e.tx.exchangeRateToBase)) {
          baseAmt = e.tx.amount * e.tx.exchangeRateToBase;
        }
      }
      if (e.tx.type == 'income') income += baseAmt;
      if (e.tx.type == 'expense') expense += baseAmt;
    }
    final net = income - expense;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.sfv(context),
        borderRadius: BorderRadius.circular(RadiusTokens.md),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text.rich(TextSpan(children: [
              TextSpan(
                text: '▼ ',
                style: TextStyle(fontSize: 10, color: AppColors.overspent),
              ),
              TextSpan(
                text: formatAmount(expense, currency: baseCurrency),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.overspent,
                ),
              ),
            ])),
          ),
          Expanded(
            child: Center(
              child: Text.rich(TextSpan(children: [
                TextSpan(
                  text: '▲ ',
                  style: TextStyle(fontSize: 10, color: AppColors.healthy),
                ),
                TextSpan(
                  text: formatAmount(income, currency: baseCurrency),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.healthy,
                  ),
                ),
              ])),
            ),
          ),
          Expanded(
            child: Text.rich(
              TextSpan(children: [
                TextSpan(
                  text: '= ',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.tp(context)),
                ),
                TextSpan(
                  text: formatAmount(net, currency: baseCurrency),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: net >= 0 ? AppColors.healthy : AppColors.overspent,
                  ),
                ),
              ]),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _CashFlowFooter extends StatelessWidget {
  final double total;
  final int count;
  final String baseCurrency;

  const _CashFlowFooter({required this.total, required this.count, required this.baseCurrency});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 12),
      child: Center(
        child: Text(
          S.of(context).txTotalCashFlow(formatAmount(total, currency: baseCurrency), count),
          style: TextStyle(
            fontSize: 13,
            color: AppColors.ts(context),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _TypeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _TypeOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(CardTokens.radius);
    return Expanded(
      child: Tappable(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: AppColors.pastel(context, color,
                light: 0.88, dark: 0.8),
            borderRadius: radius,
          ),
          child: Column(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.pastel(context, color,
                    light: 0.85, dark: 0.78),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 22, color: color),
            ),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color)),
          ]),
        ),
      ),
    );
  }
}

/// Account / category picker box in the filter panel.
class _FilterPickerBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _FilterPickerBox(
      {required this.icon,
      required this.label,
      required this.active,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppColors.accentLight : AppColors.sfv(context),
      borderRadius: BorderRadius.circular(RadiusTokens.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(RadiusTokens.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(icon,
                  size: 16,
                  color: active ? AppColors.accent : AppColors.ts(context)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                        color: active
                            ? AppColors.accent
                            : AppColors.tp(context))),
              ),
              Icon(AppIcons.caretDown,
                  size: 18, color: AppColors.th(context)),
            ],
          ),
        ),
      ),
    );
  }
}
