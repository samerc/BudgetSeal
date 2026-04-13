import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/database/app_database.dart';
import '../../core/providers/accounts_provider.dart';
import '../../core/providers/categories_provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../core/providers/tx_colors_provider.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/utils/format_number.dart';
import '../../shared/utils/haptics.dart';
import '../../shared/widgets/calculator_amount_field.dart';
import '../../shared/widgets/category_icon.dart';
import '../../shared/widgets/empty_state.dart';

enum _SortMode { mostUsed, alphabetical, newest, amount }
enum _GroupMode { none, type, category }

class TemplatesScreen extends ConsumerStatefulWidget {
  const TemplatesScreen({super.key});

  @override
  ConsumerState<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends ConsumerState<TemplatesScreen> {
  List<TransactionTemplate> _templates = [];
  bool _loading = true;
  String _search = '';
  String? _typeFilter; // null = all, 'expense', 'income'
  _SortMode _sort = _SortMode.mostUsed;
  _GroupMode _group = _GroupMode.none;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = ref.read(databaseProvider);
    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null) return;
    final items = await (db.select(db.transactionTemplates)
          ..where((t) => t.householdId.equals(householdId)))
        .get();
    if (mounted) setState(() { _templates = items; _loading = false; });
  }

  List<TransactionTemplate> get _filtered {
    var list = _templates.toList();

    // Type filter
    if (_typeFilter != null) {
      list = list.where((t) => t.type == _typeFilter).toList();
    }

    // Search
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      final categories = ref.read(categoriesProvider).value ?? [];
      final catMap = {for (final c in categories) c.id: c};
      list = list.where((t) {
        if (t.title.toLowerCase().contains(q)) return true;
        if (t.categoryId != null) {
          final cat = catMap[t.categoryId];
          if (cat != null && cat.name.toLowerCase().contains(q)) return true;
        }
        return false;
      }).toList();
    }

    // Sort
    switch (_sort) {
      case _SortMode.mostUsed:
        list.sort((a, b) => b.useCount.compareTo(a.useCount));
      case _SortMode.alphabetical:
        list.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      case _SortMode.newest:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case _SortMode.amount:
        list.sort((a, b) => b.amount.compareTo(a.amount));
    }

    return list;
  }

  Future<void> _useTemplate(TransactionTemplate t) async {
    hapticLight();
    final db = ref.read(databaseProvider);
    await (db.update(db.transactionTemplates)
          ..where((r) => r.id.equals(t.id)))
        .write(TransactionTemplatesCompanion(
      useCount: Value(t.useCount + 1),
      lastUsedAt: Value(DateTime.now()),
    ));

    final cats = ref.read(categoriesProvider).value ?? [];
    final cat = t.categoryId != null
        ? cats.where((c) => c.id == t.categoryId).firstOrNull
        : null;

    if (mounted) {
      context.push('/add-transaction', extra: {
        'editType': t.type,
        'editNote': t.title,
        'editLines': [
          {
            'amount': t.amount,
            'currency': t.currency,
            'accountId': t.accountId,
            'categoryId': t.categoryId,
            'categoryName': cat?.name,
            'note': '',
          }
        ],
      });
    }
  }

  Future<void> _delete(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete template?'),
        content: const Text('This template will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.overspent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final db = ref.read(databaseProvider);
      await (db.delete(db.transactionTemplates)
            ..where((t) => t.id.equals(id)))
          .go();
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider).value ?? [];
    final acctMap = {for (final a in accounts) a.id: a};
    final categories = ref.watch(categoriesProvider).value ?? [];
    final catMap = {for (final c in categories) c.id: c};
    final txColors = ref.watch(txColorsProvider);
    final filtered = _filtered;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text('Templates',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.tp(context))),
                  ),
                  // Sort button
                  PopupMenuButton<_SortMode>(
                    icon: Icon(Icons.sort_rounded,
                        color: AppColors.ts(context)),
                    tooltip: 'Sort',
                    onSelected: (v) => setState(() => _sort = v),
                    itemBuilder: (_) => [
                      _sortItem(_SortMode.mostUsed, 'Most used'),
                      _sortItem(_SortMode.alphabetical, 'A–Z'),
                      _sortItem(_SortMode.newest, 'Newest first'),
                      _sortItem(_SortMode.amount, 'Highest amount'),
                    ],
                  ),
                  // Group button
                  PopupMenuButton<_GroupMode>(
                    icon: Icon(Icons.workspaces_outlined,
                        color: AppColors.ts(context)),
                    tooltip: 'Group',
                    onSelected: (v) => setState(() => _group = v),
                    itemBuilder: (_) => [
                      _groupItem(_GroupMode.none, 'No grouping'),
                      _groupItem(_GroupMode.type, 'By type'),
                      _groupItem(_GroupMode.category, 'By category'),
                    ],
                  ),
                ],
              ),
            ),
            // ── Search + type filter ─────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                style: TextStyle(fontSize: 14, color: AppColors.tp(context)),
                decoration: InputDecoration(
                  hintText: 'Search templates...',
                  hintStyle: TextStyle(color: AppColors.th(context)),
                  prefixIcon: Icon(Icons.search_rounded,
                      size: 20, color: AppColors.th(context)),
                  filled: true,
                  fillColor: AppColors.sfv(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  isDense: true,
                ),
              ),
            ),
            // Type chips
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Row(
                children: [
                  _typeChip('All', null, txColors),
                  const SizedBox(width: 8),
                  _typeChip('Expense', 'expense', txColors),
                  const SizedBox(width: 8),
                  _typeChip('Income', 'income', txColors),
                ],
              ),
            ),
            // ── Summary ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Text(
                '${filtered.length} template${filtered.length == 1 ? '' : 's'}',
                style: TextStyle(
                    fontSize: 12, color: AppColors.ts(context)),
              ),
            ),
            // ── List ─────────────────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                      ? const EmptyState(
                          icon: Icons.bolt_rounded,
                          title: 'No templates found',
                          subtitle:
                              'Save frequent transactions for quick re-use',
                        )
                      : _group == _GroupMode.none
                          ? _buildFlatList(
                              filtered, catMap, acctMap, txColors)
                          : _buildGroupedList(
                              filtered, catMap, acctMap, txColors),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add template',
        onPressed: () => _showAddSheet(accounts, categories),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFlatList(
    List<TransactionTemplate> list,
    Map<String, Category> catMap,
    Map<String, Account> acctMap,
    TxColors txColors,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
      itemCount: list.length,
      itemBuilder: (_, i) =>
          _buildTile(list[i], catMap, acctMap, txColors),
    );
  }

  Widget _buildGroupedList(
    List<TransactionTemplate> list,
    Map<String, Category> catMap,
    Map<String, Account> acctMap,
    TxColors txColors,
  ) {
    final groups = <String, List<TransactionTemplate>>{};
    for (final t in list) {
      final key = _group == _GroupMode.type
          ? t.type[0].toUpperCase() + t.type.substring(1)
          : (t.categoryId != null
              ? catMap[t.categoryId]?.name ?? 'Uncategorized'
              : 'Uncategorized');
      groups.putIfAbsent(key, () => []).add(t);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
      children: groups.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
              child: Row(
                children: [
                  Text(entry.key,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ts(context))),
                  const SizedBox(width: 6),
                  Text('${entry.value.length}',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.th(context))),
                ],
              ),
            ),
            ...entry.value
                .map((t) => _buildTile(t, catMap, acctMap, txColors)),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildTile(
    TransactionTemplate t,
    Map<String, Category> catMap,
    Map<String, Account> acctMap,
    TxColors txColors,
  ) {
    final cat = t.categoryId != null ? catMap[t.categoryId] : null;
    final acct = t.accountId != null ? acctMap[t.accountId] : null;
    final color = txColors.forType(t.type);
    final catColor = cat != null
        ? _hexToColor(cat.colorHex)
        : color;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GestureDetector(
        onTap: () => _useTemplate(t),
        onLongPress: () => _showTemplateActions(t),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.sf(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.bd(context)),
          ),
          child: Row(
            children: [
              // Category icon
              CategoryIcon(
                categoryName: cat?.name ?? t.title,
                emoji: cat?.icon,
                color: catColor,
                size: 42,
                circular: true,
              ),
              const SizedBox(width: 14),
              // Title + details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.title,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.tp(context)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            t.type[0].toUpperCase() + t.type.substring(1),
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: color),
                          ),
                        ),
                        if (cat != null) ...[
                          const SizedBox(width: 6),
                          Text(cat.name,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.ts(context))),
                        ],
                        if (acct != null) ...[
                          Text(' · ',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.th(context))),
                          Text(acct.name,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.ts(context))),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Amount + use count
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        formatAmount(t.amount, currency: t.currency),
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: color),
                      ),
                    ),
                    Text(
                      '${t.useCount} use${t.useCount == 1 ? '' : 's'}',
                      style: TextStyle(
                          fontSize: 10, color: AppColors.th(context)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTemplateActions(TransactionTemplate t) {
    hapticMedium();
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.play_arrow_rounded,
                  color: AppColors.accent),
              title: const Text('Use template'),
              onTap: () {
                Navigator.pop(ctx);
                _useTemplate(t);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline,
                  color: AppColors.overspent),
              title: const Text('Delete'),
              onTap: () {
                Navigator.pop(ctx);
                _delete(t.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeChip(String label, String? type, TxColors txColors) {
    final isSelected = _typeFilter == type;
    final color = type == null
        ? AppColors.accent
        : txColors.forType(type);
    return GestureDetector(
      onTap: () {
        hapticLight();
        setState(() => _typeFilter = type);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : color)),
      ),
    );
  }

  PopupMenuItem<_SortMode> _sortItem(_SortMode mode, String label) {
    return PopupMenuItem(
      value: mode,
      child: Row(
        children: [
          if (_sort == mode)
            Icon(Icons.check_rounded, size: 16, color: AppColors.accent)
          else
            const SizedBox(width: 16),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  PopupMenuItem<_GroupMode> _groupItem(_GroupMode mode, String label) {
    return PopupMenuItem(
      value: mode,
      child: Row(
        children: [
          if (_group == mode)
            Icon(Icons.check_rounded, size: 16, color: AppColors.accent)
          else
            const SizedBox(width: 16),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  Color _hexToColor(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  // ── Add template sheet ───────────────────────────────────────

  Future<void> _showAddSheet(
      List<Account> accounts, List<Category> categories) async {
    final titleCtrl = TextEditingController();
    double calcAmount = 0;
    final formKey = GlobalKey<FormState>();
    String type = 'expense';
    String? accountId;
    String? categoryId;
    String currency =
        ref.read(householdProvider).value?.baseCurrency ?? 'USD';

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: EdgeInsets.fromLTRB(
              20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          decoration: BoxDecoration(
            color: AppColors.sf(context),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.sfv(context),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('New Template',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.tp(context))),
                  const SizedBox(height: 4),
                  Text(
                    'Save a transaction you do often for quick re-use.',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.ts(context)),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: titleCtrl,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(labelText: 'Title'),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Title is required'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  CalculatorAmountField(
                    value: calcAmount,
                    label: 'Amount',
                    fontSize: 20,
                    onChanged: (v) =>
                        setSheetState(() => calcAmount = v),
                  ),
                  const SizedBox(height: 14),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                          value: 'expense', label: Text('Expense')),
                      ButtonSegment(
                          value: 'income', label: Text('Income')),
                    ],
                    selected: {type},
                    onSelectionChanged: (s) =>
                        setSheetState(() => type = s.first),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: accountId,
                    decoration:
                        const InputDecoration(labelText: 'Account'),
                    items: accounts
                        .map((a) => DropdownMenuItem(
                            value: a.id,
                            child:
                                Text('${a.name} (${a.currency})')))
                        .toList(),
                    onChanged: (v) => setSheetState(() {
                      accountId = v;
                      if (v != null) {
                        currency = accounts
                            .firstWhere((a) => a.id == v)
                            .currency;
                      }
                    }),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: categoryId,
                    decoration: const InputDecoration(
                        labelText: 'Category (optional)'),
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('None')),
                      ...categories.map((c) => DropdownMenuItem(
                          value: c.id, child: Text(c.name))),
                    ],
                    onChanged: (v) =>
                        setSheetState(() => categoryId = v),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final title = titleCtrl.text.trim();
                      if (calcAmount <= 0) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text('Enter an amount'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }
                      final householdId =
                          ref.read(currentHouseholdIdProvider);
                      if (householdId == null) return;

                      final db = ref.read(databaseProvider);
                      await db.into(db.transactionTemplates).insert(
                            TransactionTemplatesCompanion.insert(
                              id: const Uuid().v4(),
                              householdId: householdId,
                              title: title,
                              type: type,
                              amount: calcAmount,
                              currency: currency,
                              accountId: Value(accountId),
                              categoryId: Value(categoryId),
                            ),
                          );
                      if (ctx.mounted) Navigator.pop(ctx, true);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Save Template',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (result == true) _load();
  }
}
