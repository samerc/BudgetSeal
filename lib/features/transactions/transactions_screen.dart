import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sliver_tools/sliver_tools.dart';

import '../../core/database/app_database.dart';
import '../../core/providers/allocations_provider.dart';
import '../../core/providers/accounts_provider.dart';
import '../../core/providers/categories_provider.dart';
import '../../core/providers/engine_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../core/providers/transactions_provider.dart';
import '../../core/providers/tx_colors_provider.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/utils/format_number.dart';
import '../../shared/utils/haptics.dart';
import '../../shared/utils/receipt_helper.dart';
import '../../shared/widgets/category_icon.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_retry.dart';
import '../../shared/widgets/hint_banner.dart';
import '../../shared/widgets/skeleton_loader.dart';

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() =>
      _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  String _searchQuery = '';
  String? _typeFilter;
  bool _showSearch = false;
  bool _showFilters = false;
  final _searchCtrl = TextEditingController();
  // Month navigation
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  late final ScrollController _monthScrollCtrl;

  // Advanced filters
  DateTime? _dateFrom;
  DateTime? _dateTo;
  double? _amountMin;
  double? _amountMax;
  final _amountMinCtrl = TextEditingController();
  final _amountMaxCtrl = TextEditingController();

  // Quick category filter (#5)
  String? _categoryFilter;
  String? _categoryFilterName;

  // Scroll-to-today (#10)
  final _listScrollCtrl = ScrollController();
  bool _showScrollToTop = false;

  // Quick-add bar
  final _quickAddCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _monthScrollCtrl = ScrollController();
    _listScrollCtrl.addListener(_onListScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final offset = (_selectedMonth - 1) * 80.0;
      if (_monthScrollCtrl.hasClients) {
        _monthScrollCtrl.animateTo(offset - 120,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut);
      }
    });
  }

  void _onListScroll() {
    final show = _listScrollCtrl.hasClients && _listScrollCtrl.offset > 500;
    if (show != _showScrollToTop) {
      setState(() => _showScrollToTop = show);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _monthScrollCtrl.dispose();
    _amountMinCtrl.dispose();
    _amountMaxCtrl.dispose();
    _quickAddCtrl.dispose();
    _listScrollCtrl.removeListener(_onListScroll);
    _listScrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(monthlyTransactionsProvider(
        (year: _selectedYear, month: _selectedMonth)));
    final categories = ref.watch(categoriesProvider).value ?? [];
    final categoryMap = {for (final c in categories) c.id: c};

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header area ──────────────────────────────────────
            _buildHeader(context),
            // ── First-visit hint ────────────────────────────────
            const HintBanner(
              hintId: 'transactions_intro',
              icon: Icons.receipt_long_rounded,
              title: 'Your transactions',
              body:
                  'Your transactions appear here grouped by date. Swipe left to delete, right to edit. Long-press for more options.',
            ),
            // ── Month tabs ───────────────────────────────────────
            _buildMonthTabs(context),
            // ── Filter chips (collapsible) ───────────────────────
            if (_showFilters) _buildFilterChips(),
            // ── Content ──────────────────────────────────────────
            Expanded(
              child: GestureDetector(
                dragStartBehavior: DragStartBehavior.start,
                onHorizontalDragEnd: (details) {
                  final dx = details.primaryVelocity ?? 0;
                  if (dx > 0) {
                    // Swipe right → previous month
                    setState(() {
                      if (_selectedMonth == 1) {
                        _selectedMonth = 12;
                        _selectedYear--;
                      } else {
                        _selectedMonth--;
                      }
                    });
                    hapticLight();
                  } else if (dx < 0) {
                    // Swipe left → next month
                    setState(() {
                      if (_selectedMonth == 12) {
                        _selectedMonth = 1;
                        _selectedYear++;
                      } else {
                        _selectedMonth++;
                      }
                    });
                    hapticLight();
                  }
                },
                child: RefreshIndicator(
                  onRefresh: () async {
                    final key = (year: _selectedYear, month: _selectedMonth);
                    ref.invalidate(monthlyTransactionsProvider(key));
                    await ref.read(monthlyTransactionsProvider(key).future);
                  },
                  child: entriesAsync.when(
                    data: (entries) =>
                        _buildContent(entries, categoryMap, context),
                    loading: () => const SkeletonList(),
                    error: (e, _) => ErrorRetry(
                      message: "Couldn't load your data",
                      details: '$e',
                      onRetry: () => ref.invalidate(
                          monthlyTransactionsProvider(
                              (year: _selectedYear, month: _selectedMonth))),
                    ),
                  ),
                ),
              ),
            ),
            // ── Quick-add bar ──────────────────────────────────
            _buildQuickAddBar(context),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_showScrollToTop) ...[
              FloatingActionButton.small(
                heroTag: 'fab_scroll_top',
                tooltip: 'Scroll to top',
                backgroundColor: AppColors.sf(context),
                foregroundColor: AppColors.tp(context),
                elevation: 2,
                onPressed: () {
                  _listScrollCtrl.animateTo(0,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOut);
                },
                child: const Icon(Icons.arrow_upward_rounded, size: 20),
              ),
              const SizedBox(height: 8),
            ],
            FloatingActionButton(
              heroTag: 'fab_add_tx',
              tooltip: 'Add transaction',
              onPressed: () => context.push('/add-transaction'),
              child: const Icon(Icons.add),
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
        padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: const TextStyle(fontSize: 16),
                decoration: const InputDecoration(
                  hintText: 'Search transactions...',
                  hintStyle: TextStyle(color: AppColors.textHint),
                  border: InputBorder.none,
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ),
            IconButton(
              tooltip: 'Close search',
              icon: const Icon(Icons.close_rounded, size: 22),
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
      padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
      child: Row(
        children: [
          Text(
            'Transactions',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.tp(context),
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Filter transactions',
            icon: Icon(
              Icons.filter_list_rounded,
              size: 22,
              color: _showFilters || _typeFilter != null || _dateFrom != null || _dateTo != null || _amountMin != null || _amountMax != null || _categoryFilter != null
                  ? AppColors.accent
                  : AppColors.ts(context),
            ),
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
          IconButton(
            tooltip: 'Search transactions',
            icon: Icon(Icons.search_rounded,
                size: 22, color: AppColors.ts(context)),
            onPressed: () => setState(() => _showSearch = true),
          ),
        ],
      ),
    );
  }

  // ── Quick-add bar (replaces FAB) ─────────────────────────────
  Widget _buildQuickAddBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
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
                decoration: InputDecoration(
                  hintText: 'Quick: Coffee 4.50',
                  hintStyle: TextStyle(
                    color: AppColors.th(context),
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: AppColors.sfv(context),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
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
                tooltip: 'Send',
                padding: EdgeInsets.zero,
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.arrow_upward_rounded, size: 20),
                onPressed: () => _submitQuickAdd(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitQuickAdd(BuildContext context) {
    final text = _quickAddCtrl.text.trim();
    if (text.isEmpty) return;

    // Parse: last number token is the amount, rest is the note/title
    final numPattern = RegExp(r'(\d+(?:\.\d+)?)\s*$');
    final match = numPattern.firstMatch(text);

    String note = text;
    double? amount;
    if (match != null) {
      amount = double.tryParse(match.group(1)!);
      note = text.substring(0, match.start).trim();
    }

    _quickAddCtrl.clear();

    context.push('/add-transaction', extra: {
      'editType': 'expense',
      'editNote': note,
      if (amount != null)
        'editLines': [
          {'amount': amount, 'note': note},
        ],
    });
  }

  // ── Month tabs (with year tap) ───────────────────────────────
  Widget _buildMonthTabs(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          // Year selector
          GestureDetector(
            onTap: () async {
              final picked = await showDialog<int>(
                context: context,
                builder: (ctx) => SimpleDialog(
                  title: const Text('Select Year'),
                  children: List.generate(10, (i) {
                    final y = DateTime.now().year - 5 + i;
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
                setState(() => _selectedYear = picked);
              }
            },
            child: Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('$_selectedYear',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ts(context))),
                  Icon(Icons.expand_more_rounded,
                      size: 16, color: AppColors.ts(context)),
                ],
              ),
            ),
          ),
          // Month row with arrow buttons
          SizedBox(
            height: 38,
            child: Row(
              children: [
                // Left arrow
                GestureDetector(
                  onTap: () {
                    hapticLight();
                    setState(() {
                      if (_selectedMonth == 1) {
                        _selectedMonth = 12;
                        _selectedYear--;
                      } else {
                        _selectedMonth--;
                      }
                    });
                    final offset = (_selectedMonth - 1) * 80.0;
                    if (_monthScrollCtrl.hasClients) {
                      _monthScrollCtrl.animateTo(offset - 120,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(Icons.chevron_left_rounded,
                        size: 22, color: AppColors.ts(context)),
                  ),
                ),
                // Month list
                Expanded(
                  child: ListView.builder(
                    controller: _monthScrollCtrl,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    itemCount: 12,
                    itemBuilder: (_, i) {
                      final month = i + 1;
                      final isSelected = month == _selectedMonth;
                      final label =
                          DateFormat('MMMM').format(DateTime(2000, month));
                      return GestureDetector(
                        onTap: () {
                          hapticLight();
                          setState(() => _selectedMonth = month);
                        },
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 14),
                          margin:
                              const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            border: isSelected
                                ? Border(
                                    bottom: BorderSide(
                                        color: AppColors.tp(context),
                                        width: 2.5))
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: isSelected
                                  ? AppColors.tp(context)
                                  : AppColors.ts(context),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Right arrow
                GestureDetector(
                  onTap: () {
                    hapticLight();
                    setState(() {
                      if (_selectedMonth == 12) {
                        _selectedMonth = 1;
                        _selectedYear++;
                      } else {
                        _selectedMonth++;
                      }
                    });
                    final offset = (_selectedMonth - 1) * 80.0;
                    if (_monthScrollCtrl.hasClients) {
                      _monthScrollCtrl.animateTo(offset - 120,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(Icons.chevron_right_rounded,
                        size: 22, color: AppColors.ts(context)),
                  ),
                ),
              ],
            ),
          ),
        ],
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
              _FilterChip(
                label: 'All',
                selected: _typeFilter == null,
                onTap: () => setState(() => _typeFilter = null),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Income',
                selected: _typeFilter == 'income',
                color: AppColors.healthy,
                onTap: () => setState(() => _typeFilter = 'income'),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Expense',
                selected: _typeFilter == 'expense',
                color: AppColors.overspent,
                onTap: () => setState(() => _typeFilter = 'expense'),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Transfer',
                selected: _typeFilter == 'transfer',
                color: AppColors.accent,
                onTap: () => setState(() => _typeFilter = 'transfer'),
              ),
            ],
          ),
        ),
        // Date range filter
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: Row(
            children: [
              Icon(Icons.calendar_today_rounded,
                  size: 16, color: AppColors.ts(context)),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => _pickDate(isFrom: true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.sfv(context),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.bd(context)),
                    ),
                    child: Text(
                      _dateFrom != null
                          ? DateFormat('MMM d, y').format(_dateFrom!)
                          : 'From date',
                      style: TextStyle(
                        fontSize: 13,
                        color: _dateFrom != null
                            ? AppColors.tp(context)
                            : AppColors.th(context),
                      ),
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
                child: GestureDetector(
                  onTap: () => _pickDate(isFrom: false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.sfv(context),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.bd(context)),
                    ),
                    child: Text(
                      _dateTo != null
                          ? DateFormat('MMM d, y').format(_dateTo!)
                          : 'To date',
                      style: TextStyle(
                        fontSize: 13,
                        color: _dateTo != null
                            ? AppColors.tp(context)
                            : AppColors.th(context),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Amount range filter
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Row(
            children: [
              Icon(Icons.attach_money_rounded,
                  size: 16, color: AppColors.ts(context)),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _amountMinCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(
                      fontSize: 13, color: AppColors.tp(context)),
                  decoration: InputDecoration(
                    hintText: 'Min',
                    hintStyle: TextStyle(color: AppColors.th(context)),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    filled: true,
                    fillColor: AppColors.sfv(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.bd(context)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.bd(context)),
                    ),
                  ),
                  onChanged: (v) => setState(() {
                    _amountMin = double.tryParse(v);
                  }),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text('–',
                    style: TextStyle(
                        color: AppColors.ts(context), fontSize: 16)),
              ),
              Expanded(
                child: TextField(
                  controller: _amountMaxCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(
                      fontSize: 13, color: AppColors.tp(context)),
                  decoration: InputDecoration(
                    hintText: 'Max',
                    hintStyle: TextStyle(color: AppColors.th(context)),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    filled: true,
                    fillColor: AppColors.sfv(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.bd(context)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.bd(context)),
                    ),
                  ),
                  onChanged: (v) => setState(() {
                    _amountMax = double.tryParse(v);
                  }),
                ),
              ),
            ],
          ),
        ),
        // Clear all filters button
        if (hasAdvancedFilters)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: GestureDetector(
              onTap: () => setState(() {
                _dateFrom = null;
                _dateTo = null;
                _amountMin = null;
                _amountMax = null;
                _amountMinCtrl.clear();
                _amountMaxCtrl.clear();
              }),
              child: Text(
                'Clear advanced filters',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent,
                ),
              ),
            ),
          ),
      ],
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
    // Month filtering is already done at the SQL level via
    // monthlyTransactionsProvider. Apply optional date-range narrowing.
    final hasDateFilter = _dateFrom != null || _dateTo != null;
    var filtered = hasDateFilter
        ? entries.where((e) {
            final d = e.tx.createdAt.toLocal();
            final dayOnly = DateTime(d.year, d.month, d.day);
            if (_dateFrom != null && dayOnly.isBefore(_dateFrom!)) return false;
            if (_dateTo != null && dayOnly.isAfter(_dateTo!)) return false;
            return true;
          }).toList()
        : entries.toList();

    if (_typeFilter != null) {
      filtered = filtered.where((e) => e.tx.type == _typeFilter).toList();
    }

    // Category quick filter (#5)
    if (_categoryFilter != null) {
      filtered = filtered.where((e) {
        if (e.tx.categoryId == _categoryFilter) return true;
        for (final l in e.lines) {
          if (l.categoryId == _categoryFilter) return true;
        }
        return false;
      }).toList();
    }

    // Amount range filter
    if (_amountMin != null || _amountMax != null) {
      filtered = filtered.where((e) {
        final amt = e.tx.amount;
        if (_amountMin != null && amt < _amountMin!) return false;
        if (_amountMax != null && amt > _amountMax!) return false;
        return true;
      }).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((e) {
        if (e.tx.note.toLowerCase().contains(q)) return true;
        if (e.accountName.toLowerCase().contains(q)) return true;
        if (e.tx.amount.toStringAsFixed(2).contains(q)) return true;
        final cat =
            e.tx.categoryId != null ? categoryMap[e.tx.categoryId] : null;
        if (cat != null && cat.name.toLowerCase().contains(q)) return true;
        for (final line in e.lines) {
          if (line.note.toLowerCase().contains(q)) return true;
          final lineCat = line.categoryId != null
              ? categoryMap[line.categoryId]
              : null;
          if (lineCat != null && lineCat.name.toLowerCase().contains(q)) {
            return true;
          }
        }
        return false;
      }).toList();
    }

    if (filtered.isEmpty) {
      final hasFilters = _searchQuery.isNotEmpty || _typeFilter != null || hasDateFilter || _amountMin != null || _amountMax != null || _categoryFilter != null;
      final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final monthLabel = '${monthNames[_selectedMonth - 1]} $_selectedYear';
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_categoryFilter != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => setState(() {
                  _categoryFilter = null;
                  _categoryFilterName = null;
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Filtered: ${_categoryFilterName ?? 'Category'}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.close_rounded,
                          size: 14, color: AppColors.accent),
                    ],
                  ),
                ),
              ),
            ),
          EmptyState(
            icon: hasFilters
                ? Icons.search_off_rounded
                : Icons.receipt_long_rounded,
            title: _categoryFilter != null
                ? 'No ${_categoryFilterName ?? 'category'} transactions in $monthLabel'
                : hasFilters
                    ? 'No matching transactions'
                    : 'No transactions yet',
            subtitle: hasFilters ? null : 'Tap + to record one',
          ),
        ],
      );
    }

    // Compute month summary
    double monthExpense = 0, monthIncome = 0;
    for (final e in filtered) {
      double baseAmt = 0;
      if (e.lines.isNotEmpty) {
        for (final l in e.lines) {
          baseAmt += l.amount * l.exchangeRateToBase;
        }
      } else {
        baseAmt = e.tx.amount * e.tx.exchangeRateToBase;
      }
      if (e.tx.type == 'expense') monthExpense += baseAmt;
      if (e.tx.type == 'income') monthIncome += baseAmt;
    }

    final baseCurrency =
        ref.read(householdProvider).value?.baseCurrency ?? 'USD';
    final groups = _buildGroups(filtered);
    final txColors = ref.watch(txColorsProvider);
    final net = monthIncome - monthExpense;

    // Budget context bar (#2) — sum of allocation targets
    final allocations = ref.watch(allocationsProvider).value ?? [];
    double totalBudget = 0;
    for (final a in allocations) {
      totalBudget += a.data.allocation.targetAmount ?? 0;
    }

    return Column(
      children: [
        // ── Summary strip ──────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: Row(
            children: [
              _SummaryDot(
                color: txColors.income,
                label: formatSignedAmount(monthIncome, currency: baseCurrency, type: 'income'),
              ),
              const SizedBox(width: 12),
              _SummaryDot(
                color: txColors.expense,
                label: formatSignedAmount(monthExpense, currency: baseCurrency, type: 'expense'),
              ),
              const SizedBox(width: 12),
              Text(
                '= ${formatAmount(net, currency: baseCurrency)}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: net >= 0 ? AppColors.healthy : AppColors.overspent,
                ),
              ),
            ],
          ),
        ),
        // ── Budget progress bar (#2) ──────────────────────────
        if (totalBudget > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 2, 20, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Spent ${formatAmount(monthExpense, currency: baseCurrency)} of ${formatAmount(totalBudget, currency: baseCurrency)} budget',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.ts(context),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${(monthExpense / totalBudget * 100).clamp(0, 999).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: monthExpense > totalBudget
                            ? AppColors.overspent
                            : AppColors.ts(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: (monthExpense / totalBudget).clamp(0.0, 1.0),
                    minHeight: 4,
                    backgroundColor: AppColors.sfv(context),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      monthExpense > totalBudget
                          ? AppColors.overspent
                          : monthExpense > totalBudget * 0.8
                              ? AppColors.caution
                              : AppColors.healthy,
                    ),
                  ),
                ),
              ],
            ),
          ),
        // ── Category quick filter chip (#5) ───────────────────
        if (_categoryFilter != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() {
                    _categoryFilter = null;
                    _categoryFilterName = null;
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Filtered: ${_categoryFilterName ?? 'Category'}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accent,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.close_rounded,
                            size: 14, color: AppColors.accent),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        // ── Transaction list (sticky date headers) ──────────────
        Expanded(
          child: CustomScrollView(
            controller: _listScrollCtrl,
            slivers: [
              // Top padding
              const SliverPadding(padding: EdgeInsets.only(top: 4)),
              // Date-grouped slivers with sticky headers
              for (final group in groups)
                MultiSliver(
                  pushPinnedChildren: true,
                  children: [
                    SliverPinnedHeader(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _DateHeaderTile(
                          date: group.date,
                          dayTotal: group.dayTotal,
                          baseCurrency: group.baseCurrency,
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) {
                            // Build visual items: transfers get 2 rows (from + to)
                            final visualItems = <({TransactionEntry entry, String? transferSide})>[];
                            for (final e in group.entries) {
                              if (e.tx.type == 'transfer') {
                                visualItems.add((entry: e, transferSide: 'from'));
                                visualItems.add((entry: e, transferSide: 'to'));
                              } else {
                                visualItems.add((entry: e, transferSide: null));
                              }
                            }
                            if (i >= visualItems.length) return const SizedBox.shrink();
                            final item = visualItems[i];
                            final e = item.entry;
                            // Use a unique key for transfer halves
                            final tileKey = item.transferSide != null
                                ? '${e.tx.id}_${item.transferSide}'
                                : e.tx.id;
                            return Dismissible(
                              key: ValueKey(tileKey),
                              direction: DismissDirection.horizontal,
                              // Left background (swipe right → edit) (#6)
                              background: Container(
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.only(left: 20),
                                margin: const EdgeInsets.only(bottom: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(Icons.edit_rounded,
                                    color: Colors.white),
                              ),
                              // Right background (swipe left → delete)
                              secondaryBackground: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                margin: const EdgeInsets.only(bottom: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.overspent,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(Icons.delete_rounded,
                                    color: Colors.white),
                              ),
                              confirmDismiss: (direction) async {
                                if (direction == DismissDirection.startToEnd) {
                                  // Swipe right → edit (#6)
                                  context.push('/transactions/${e.tx.id}');
                                  return false; // don't dismiss
                                }
                                // Swipe left → delete
                                return await showDialog<bool>(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: const Text('Delete?'),
                                        content: const Text(
                                            'This transaction will be permanently deleted.'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            style: TextButton.styleFrom(
                                                foregroundColor: AppColors.overspent),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    ) ??
                                    false;
                              },
                              onDismissed: (_) {
                                ref
                                    .read(allocationEngineProvider)
                                    .deleteTransaction(e.tx.id);
                              },
                              child: _TxTile(
                                entry: e,
                                categoryMap: categoryMap,
                                transferSide: item.transferSide,
                                onCategoryTap: (catId, catName) {
                                  hapticLight();
                                  setState(() {
                                    _categoryFilter = catId;
                                    _categoryFilterName = catName;
                                  });
                                },
                              ),
                            );
                          },
                          childCount: group.entries.fold<int>(0, (sum, e) =>
                              sum + (e.tx.type == 'transfer' ? 2 : 1)),
                        ),
                      ),
                    ),
                  ],
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
            baseAmt += l.amount * l.exchangeRateToBase;
          }
        } else {
          baseAmt = e.tx.amount * e.tx.exchangeRateToBase;
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
// Filter chip
// ---------------------------------------------------------------------------

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return GestureDetector(
      onTap: () {
        hapticLight();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? c : c.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? c : c.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : c,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Date header tile — natural case, like "Today, April 11"
// ---------------------------------------------------------------------------

class _DateHeaderTile extends StatelessWidget {
  final DateTime date;
  final double dayTotal;
  final String baseCurrency;
  const _DateHeaderTile({
    required this.date,
    this.dayTotal = 0,
    this.baseCurrency = 'USD',
  });

  @override
  Widget build(BuildContext context) {
    final isToday = _isToday(date);
    // Solid background so it visually separates when scrolling (#1)
    return Container(
      color: AppColors.bg(context),
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Today indicator (#4)
              if (isToday) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'TODAY',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                _label(date),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isToday ? AppColors.tp(context) : AppColors.ts(context),
                ),
              ),
            ],
          ),
          if (dayTotal != 0)
            Text(
              formatSignedAmount(dayTotal, currency: baseCurrency, type: dayTotal < 0 ? 'expense' : 'income'),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: dayTotal < 0 ? AppColors.overspent : AppColors.healthy,
              ),
            ),
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  String _label(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    final diff = today.difference(d).inDays;
    if (diff == 0) return DateFormat('MMMM d').format(date);
    if (diff == 1) return 'Yesterday, ${DateFormat('MMMM d').format(date)}';
    if (diff < 7) return '${DateFormat('EEEE').format(date)}, ${DateFormat('MMMM d').format(date)}';
    return DateFormat('MMMM d').format(date);
  }
}

// ---------------------------------------------------------------------------
// Transaction tile — flat, circular icon, clean layout
// ---------------------------------------------------------------------------

class _TxTile extends ConsumerWidget {
  final TransactionEntry entry;
  final Map<String, Category> categoryMap;
  final void Function(String catId, String catName)? onCategoryTap;
  /// null for normal transactions, 'from' or 'to' for transfer visual split.
  final String? transferSide;

  const _TxTile({
    required this.entry,
    required this.categoryMap,
    this.onCategoryTap,
    this.transferSide,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tx = entry.tx;
    final txColors = ref.watch(txColorsProvider);
    final isTransferSplit = transferSide != null;
    final isFrom = transferSide == 'from';
    final typeColor = isTransferSplit
        ? (isFrom ? txColors.expense : txColors.income)
        : txColors.forType(tx.type);

    // Resolve category
    final cat = _resolveCategory();
    final catName = cat?.name;
    final catColor =
        cat != null ? _parseColor(cat.colorHex) : AppColors.accent;

    // For transfers, override display name and note
    final String displayName;
    final String? note;
    if (isTransferSplit) {
      final accounts = ref.read(accountsProvider).value ?? [];
      final acctMap = {for (final a in accounts) a.id: a};
      final fromAcct = acctMap[tx.accountId];
      final toAcct = tx.destinationAccountId != null
          ? acctMap[tx.destinationAccountId]
          : null;
      if (isFrom) {
        displayName = 'Transfer to ${toAcct?.name ?? 'account'}';
        note = fromAcct?.name;
      } else {
        displayName = 'Transfer from ${fromAcct?.name ?? 'account'}';
        note = toAcct?.name;
      }
    } else {
      displayName = _buildDisplayName(catName);
      note = _buildNote(catName);
    }
    final notePreview = _buildNotePreview(catName, displayName);

    return Semantics(
      label: '$displayName, ${formatSignedAmount(tx.amount, currency: tx.currency, type: tx.type)}',
      button: true,
      child: GestureDetector(
        onTap: () => context.push('/transactions/${tx.id}'),
        onLongPress: () {
          hapticMedium();
          _showContextMenu(context, ref);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              // ── Circular category icon (tap to filter #5) ─────
            if (isTransferSplit)
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isFrom
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  color: typeColor,
                  size: 22,
                ),
              )
            else
              GestureDetector(
                onTap: () {
                  final catId = cat?.id;
                  if (catId != null && onCategoryTap != null) {
                    onCategoryTap!(catId, catName ?? 'Unknown');
                  }
                },
                child: Hero(
                  tag: 'tx_${tx.id}',
                  child: CategoryIcon(
                    categoryName: catName ?? '',
                    emoji: cat?.icon,
                    color: catColor,
                    size: 46,
                    circular: true,
                  ),
                ),
              ),
            const SizedBox(width: 14),
            // ── Name + note ─────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.tp(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (note != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      note,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.ts(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  // Note preview (#7)
                  if (notePreview != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      notePreview,
                      style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: AppColors.th(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            // ── Receipt indicator ────────────────────────────────
            if (tx.receiptPath != null && tx.receiptPath!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: () {
                  final receiptCount = parseReceiptPaths(tx.receiptPath).length;
                  if (receiptCount > 1) {
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(Icons.receipt_long_rounded,
                            size: 14, color: AppColors.th(context)),
                        Positioned(
                          top: -6,
                          right: -8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$receiptCount',
                              style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                  return Icon(Icons.receipt_long_rounded,
                      size: 14, color: AppColors.th(context));
                }(),
              ),
            // ── Amount (right-aligned #3) ───────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _buildAmountColumn(context, typeColor),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Category? _resolveCategory() {
    final tx = entry.tx;
    final lines = entry.lines;
    if (lines.isNotEmpty && lines.first.categoryId != null) {
      return categoryMap[lines.first.categoryId];
    }
    if (tx.categoryId != null) {
      return categoryMap[tx.categoryId];
    }
    return null;
  }

  String _buildDisplayName(String? catName) {
    final tx = entry.tx;
    final lines = entry.lines;

    if (catName != null) return catName;

    // Multi-line: show first category names
    if (lines.length > 1) {
      final names = lines
          .take(2)
          .map((l) =>
              l.categoryId != null ? categoryMap[l.categoryId]?.name : null)
          .whereType<String>()
          .toList();
      if (names.isEmpty) return '${lines.length} items';
      final extra = lines.length - names.length;
      return extra > 0
          ? '${names.join(', ')} +$extra more'
          : names.join(', ');
    }

    if (tx.note.isNotEmpty) return tx.note;
    return _typeLabel(tx.type);
  }

  String? _buildNote(String? catName) {
    final tx = entry.tx;
    final lines = entry.lines;

    // If we have a category name, show note as subtitle (if any)
    if (catName != null && tx.note.isNotEmpty) {
      return tx.note;
    }

    // Show account name as subtitle if we have a display name already
    final involvedAccounts = entry.involvedAccountNames;
    if (involvedAccounts.length > 1) {
      return involvedAccounts.join(' · ');
    }

    // Show single line note if different from display name
    if (lines.isNotEmpty && lines.first.note.isNotEmpty && catName != null) {
      return lines.first.note;
    }

    return null;
  }

  /// Note preview (#7): show tx note as a third line if it isn't already
  /// used as the display name or the subtitle from _buildNote.
  String? _buildNotePreview(String? catName, String displayName) {
    final tx = entry.tx;
    final lines = entry.lines;
    if (tx.note.isEmpty && (lines.isEmpty || lines.first.note.isEmpty)) {
      return null;
    }
    // If note is already the display name, skip
    if (tx.note == displayName) return null;
    // If _buildNote already returns the tx.note as subtitle, skip
    if (catName != null && tx.note.isNotEmpty) return null;
    // Show line-level note if it exists and differs from display
    if (lines.isNotEmpty && lines.first.note.isNotEmpty) {
      final lineNote = lines.first.note;
      if (lineNote != displayName) return lineNote;
    }
    // Show tx note as preview if it exists and not shown elsewhere
    if (tx.note.isNotEmpty) return tx.note;
    return null;
  }

  List<Widget> _buildAmountColumn(BuildContext context, Color typeColor) {
    final tx = entry.tx;
    final lines = entry.lines;
    final isTransferSplit = transferSide != null;
    final isFrom = transferSide == 'from';

    String displayCurrency = tx.currency;
    double displayAmount = tx.amount;

    if (lines.isNotEmpty) {
      displayCurrency = lines.first.currency;
      displayAmount = lines.first.amount;
    }

    final baseCurrency = tx.currency;
    final showConversion =
        displayCurrency != baseCurrency && lines.isNotEmpty;
    final baseAmount = tx.amount;

    // For transfer splits, show as expense (from) or income (to)
    final effectiveType = isTransferSplit
        ? (isFrom ? 'expense' : 'income')
        : tx.type;

    // Show running balance only when a single account is involved
    final isSingleAccount = entry.involvedAccountNames.length <= 1;

    return [
      // Amount right-aligned (#3)
      Text(
        formatSignedAmount(displayAmount, currency: displayCurrency, type: effectiveType),
        textAlign: TextAlign.end,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 15,
          color: typeColor,
        ),
      ),
      // Multi-currency badge (#8) — show pill instead of full conversion text
      if (showConversion)
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  displayCurrency,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                formatAmount(baseAmount, currency: baseCurrency),
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.th(context),
                ),
              ),
            ],
          ),
        ),
      if (isSingleAccount)
        Text(
          '${entry.accountName}: ${formatAmount(entry.accountBalanceAfter, currency: entry.accountCurrency)}',
          textAlign: TextAlign.end,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.th(context),
          ),
        ),
      if (!isSingleAccount)
        Text(
          '${entry.involvedAccountNames.length} accounts',
          textAlign: TextAlign.end,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.th(context),
          ),
        ),
    ];
  }

  Color _parseColor(String hex) {
    try {
      return Color(
          int.parse(hex.replaceFirst('#', ''), radix: 16) | 0xFF000000);
    } catch (_) {
      return AppColors.accent;
    }
  }

  String _typeLabel(String type) => switch (type) {
        'income' => 'Income',
        'expense' => 'Expense',
        'transfer' => 'Transfer',
        _ => type,
      };

  void _showContextMenu(BuildContext context, WidgetRef ref) {
    final tx = entry.tx;
    final cat = _resolveCategory();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.sf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.edit_rounded, color: AppColors.tp(context)),
              title: Text('Edit',
                  style: TextStyle(color: AppColors.tp(context))),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/transactions/${tx.id}');
              },
            ),
            ListTile(
              leading: Icon(Icons.copy_rounded, color: AppColors.tp(context)),
              title: Text('Duplicate',
                  style: TextStyle(color: AppColors.tp(context))),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/add-transaction', extra: {
                  'editType': tx.type,
                  'editNote': tx.note,
                  'editLines': [
                    {
                      'amount': tx.amount,
                      'currency': tx.currency,
                      'accountId': tx.accountId,
                      'categoryId': tx.categoryId,
                      'categoryName': cat?.name,
                      'note': tx.note,
                    },
                  ],
                });
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_rounded, color: AppColors.overspent),
              title: Text('Delete',
                  style: TextStyle(color: AppColors.overspent)),
              onTap: () async {
                Navigator.pop(ctx);
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (dCtx) => AlertDialog(
                    title: const Text('Delete transaction?'),
                    content: const Text(
                        'This action cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dCtx, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(dCtx, true),
                        child: Text('Delete',
                            style: TextStyle(color: AppColors.overspent)),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  ref.read(allocationEngineProvider).deleteTransaction(tx.id);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Summary dot — colored bullet + amount
// ---------------------------------------------------------------------------

class _SummaryDot extends StatelessWidget {
  final Color color;
  final String label;

  const _SummaryDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Cash flow footer
// ---------------------------------------------------------------------------

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
          'Total cash flow: ${formatAmount(total, currency: baseCurrency)} · $count transaction${count == 1 ? '' : 's'}',
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
