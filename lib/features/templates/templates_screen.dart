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
import '../../shared/theme/design_tokens.dart';
import '../../shared/utils/format_number.dart';
import '../../shared/utils/haptics.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets/calculator_amount_field.dart';
import '../../shared/widgets/category_icon.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/utils/dispose_later.dart';
import '../../shared/theme/app_icons.dart';
import '../../shared/widgets/skeleton_loader.dart';
import '../../shared/widgets/app_chip.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/error_retry.dart';
import '../../shared/widgets/large_title_header.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/sheet_title.dart';
import '../../shared/widgets/tappable.dart';

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
  bool _loadFailed = false;
  String _search = '';
  String? _typeFilter; // null = all, 'expense', 'income'
  _SortMode _sort = _SortMode.mostUsed;
  _GroupMode _group = _GroupMode.none;

  String _localizedType(String type) {
    final tr = S.of(context);
    return switch (type) {
      'expense' => tr.typeExpense,
      'income' => tr.typeIncome,
      'transfer' => tr.typeTransfer,
      _ => type[0].toUpperCase() + type.substring(1),
    };
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final db = ref.read(databaseProvider);
      final householdId = ref.read(currentHouseholdIdProvider);
      if (householdId == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      final items = await (db.select(db.transactionTemplates)
            ..where((t) => t.householdId.equals(householdId))
            ..where((t) => t.deleted.equals(false)))
          .get();
      if (mounted) {
        setState(() {
          _templates = items;
          _loading = false;
          _loadFailed = false;
        });
      }
    } catch (e) {
      debugPrint('[Templates] Error loading: $e');
      if (mounted) {
        setState(() {
          _loading = false;
          _loadFailed = true;
        });
      }
    }
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
    try {
      hapticLight();
      final db = ref.read(databaseProvider);
      await (db.update(db.transactionTemplates)
            ..where((r) => r.id.equals(t.id)))
          .write(TransactionTemplatesCompanion(
        useCount: Value(t.useCount + 1),
        lastUsedAt: Value(DateTime.now()),
        lastModified: Value(DateTime.now()),
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
    } catch (e) {
      debugPrint('[Templates] Error using template: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).tmplApplyError),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _delete(String id) async {
    final tr = S.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: tr.tmplDeleteTitle,
      message: tr.tmplDeleteMsg,
      confirmLabel: tr.commonDelete,
    );
    if (!confirmed || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final db = ref.read(databaseProvider);
      await (db.update(db.transactionTemplates)
            ..where((t) => t.id.equals(id)))
          .write(TransactionTemplatesCompanion(
              deleted: const Value(true),
              lastModified: Value(DateTime.now())));
      _load();
      messenger.showSnackBar(SnackBar(
        content: Text(tr.tmplDeleted),
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      debugPrint('[Templates] Error deleting: $e');
      messenger.showSnackBar(SnackBar(
        content: Text(tr.tmplDeleteError),
        behavior: SnackBarBehavior.floating,
      ));
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

    final Widget listSliver;
    if (_loading) {
      listSliver = const SliverToBoxAdapter(child: SkeletonList());
    } else if (_loadFailed) {
      listSliver = SliverFillRemaining(
        hasScrollBody: false,
        child: ErrorRetry(
          message: S.of(context).commonCouldntLoadData,
          onRetry: () {
            setState(() => _loading = true);
            _load();
          },
        ),
      );
    } else if (_templates.isEmpty) {
      listSliver = SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyState(
          icon: AppIcons.lightning,
          title: S.of(context).tmplNoTitle,
          subtitle: S.of(context).tmplNoSubtitle,
        ),
      );
    } else if (filtered.isEmpty) {
      listSliver = SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyState(
          icon: AppIcons.magnifyingGlassMinus,
          title: _search.isNotEmpty
              ? S.of(context).tmplNoMatch(_search)
              : S.of(context).tmplNoTitle,
        ),
      );
    } else {
      listSliver = SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
        sliver: SliverList(
          delegate: SliverChildListDelegate(_group == _GroupMode.none
              ? _buildFlatList(filtered, catMap, acctMap, txColors)
              : _buildGroupedList(filtered, catMap, acctMap, txColors)),
        ),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            LargeTitleHeader(
              title: S.of(context).tmplTitle,
              back: true,
              actions: [
                // Sort button
                PopupMenuButton<_SortMode>(
                  icon: Icon(AppIcons.sortAscending,
                      color: AppColors.ts(context)),
                  tooltip: S.of(context).tmplSortTooltip,
                  onSelected: (v) => setState(() => _sort = v),
                  itemBuilder: (_) => [
                    _sortItem(_SortMode.mostUsed, S.of(context).tmplSortMostUsed),
                    _sortItem(_SortMode.alphabetical, S.of(context).tmplSortAz),
                    _sortItem(_SortMode.newest, S.of(context).tmplSortNewest),
                    _sortItem(_SortMode.amount, S.of(context).tmplSortHighest),
                  ],
                ),
                // Group button
                PopupMenuButton<_GroupMode>(
                  icon: Icon(AppIcons.circlesThree,
                      color: AppColors.ts(context)),
                  tooltip: S.of(context).tmplGroupTooltip,
                  onSelected: (v) => setState(() => _group = v),
                  itemBuilder: (_) => [
                    _groupItem(_GroupMode.none, S.of(context).tmplGroupNone),
                    _groupItem(_GroupMode.type, S.of(context).tmplGroupType),
                    _groupItem(_GroupMode.category, S.of(context).tmplGroupCategory),
                  ],
                ),
              ],
            ),
            // ── Search + type filter ─────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  textInputAction: TextInputAction.search,
                  style: TextStyle(fontSize: 14, color: AppColors.tp(context)),
                  decoration: InputDecoration(
                    hintText: S.of(context).tmplSearchHint,
                    hintStyle: TextStyle(color: AppColors.th(context)),
                    prefixIcon: Icon(AppIcons.magnifyingGlass,
                        size: 20, color: AppColors.th(context)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    isDense: true,
                  ),
                ),
              ),
            ),
            // Type chips
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                child: Row(
                  children: [
                    _typeChip(S.of(context).typeAll, null, txColors),
                    const SizedBox(width: 8),
                    _typeChip(S.of(context).typeExpense, 'expense', txColors),
                    const SizedBox(width: 8),
                    _typeChip(S.of(context).typeIncome, 'income', txColors),
                  ],
                ),
              ),
            ),
            // ── Summary ──────────────────────────────────────────
            if (!_loading && !_loadFailed && filtered.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                  child: Text(
                    filtered.length == 1
                        ? S.of(context).tmplCountOne(filtered.length)
                        : S.of(context).tmplCountOther(filtered.length),
                    style: TextStyle(
                        fontSize: TypographyTokens.captionSize,
                        color: AppColors.ts(context)),
                  ),
                ),
              ),
            // ── List ─────────────────────────────────────────────
            listSliver,
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: S.of(context).tmplAddTooltip,
        onPressed: () => _showAddSheet(accounts, categories),
        child: const Icon(AppIcons.plus),
      ),
    );
  }

  List<Widget> _buildFlatList(
    List<TransactionTemplate> list,
    Map<String, Category> catMap,
    Map<String, Account> acctMap,
    TxColors txColors,
  ) =>
      [for (final t in list) _buildTile(t, catMap, acctMap, txColors)];

  List<Widget> _buildGroupedList(
    List<TransactionTemplate> list,
    Map<String, Category> catMap,
    Map<String, Account> acctMap,
    TxColors txColors,
  ) {
    final groups = <String, List<TransactionTemplate>>{};
    for (final t in list) {
      final key = _group == _GroupMode.type
          ? _localizedType(t.type)
          : (t.categoryId != null
              ? catMap[t.categoryId]?.name ?? S.of(context).commonUncategorized
              : S.of(context).commonUncategorized);
      groups.putIfAbsent(key, () => []).add(t);
    }

    return [
      for (final entry in groups.entries) ...[
        SectionHeader(
          entry.key,
          padding: const EdgeInsetsDirectional.fromSTEB(4, 12, 4, 6),
          trailing: Text('${entry.value.length}',
              style: TextStyle(
                  fontSize: TypographyTokens.captionSize,
                  color: AppColors.th(context))),
        ),
        for (final t in entry.value) _buildTile(t, catMap, acctMap, txColors),
      ],
    ];
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
        ? AppColors.fromHex(cat.colorHex)
        : color;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: DecoratedBox(
        decoration: AppColors.card(context),
        child: Tappable(
          onTap: () => _useTemplate(t),
          onLongPress: () => _showTemplateActions(t),
          borderRadius: CardTokens.borderRadius,
          scaleFactor: 0.97,
          haptic: true,
          child: Padding(
          padding: CardTokens.padding,
          child: Row(
            children: [
              // Category icon
              CategoryIcon(
                categoryName: cat?.name ?? t.title,
                emoji: cat?.icon,
                color: catColor,
                size: CategoryIconTokens.listSize,
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
                            color: AppColors.pastel(context, color,
                                light: 0.85, dark: 0.78),
                            borderRadius:
                                BorderRadius.circular(RadiusTokens.sm),
                          ),
                          child: Text(
                            _localizedType(t.type),
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: color),
                          ),
                        ),
                        if (cat != null || acct != null) ...[
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              [
                                if (cat != null) cat.name,
                                if (acct != null) acct.name,
                              ].join(' · '),
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.ts(context)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
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
                      t.useCount == 1
                          ? S.of(context).tmplUseCountOne(t.useCount)
                          : S.of(context).tmplUseCountOther(t.useCount),
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
            SheetTitle(t.title),
            ListTile(
              leading: Icon(AppIcons.play,
                  color: AppColors.accent),
              title: Text(S.of(ctx).tmplUse),
              onTap: () {
                Navigator.pop(ctx);
                _useTemplate(t);
              },
            ),
            ListTile(
              leading: Icon(AppIcons.pencilSimple, color: AppColors.ts(ctx)),
              title: Text(S.of(ctx).commonEdit),
              onTap: () {
                Navigator.pop(ctx);
                _showAddSheet(
                  ref.read(accountsProvider).value ?? const [],
                  ref.read(categoriesProvider).value ?? const [],
                  existing: t,
                );
              },
            ),
            ListTile(
              leading: Icon(AppIcons.trash,
                  color: AppColors.overspent),
              title: Text(S.of(ctx).commonDelete),
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
    return AppChip(
      label: label,
      selected: _typeFilter == type,
      color: type == null ? null : txColors.forType(type),
      onTap: () {
        hapticLight();
        setState(() => _typeFilter = type);
      },
    );
  }

  PopupMenuItem<_SortMode> _sortItem(_SortMode mode, String label) {
    return PopupMenuItem(
      value: mode,
      child: Row(
        children: [
          if (_sort == mode)
            Icon(AppIcons.check, size: 16, color: AppColors.accent)
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
            Icon(AppIcons.check, size: 16, color: AppColors.accent)
          else
            const SizedBox(width: 16),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  // ── Add template sheet ───────────────────────────────────────

  /// Create a template, or edit [existing].
  Future<void> _showAddSheet(
      List<Account> accounts, List<Category> categories,
      {TransactionTemplate? existing}) async {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    double calcAmount = existing?.amount ?? 0;
    final formKey = GlobalKey<FormState>();
    String type = existing?.type ?? 'expense';
    // Only ids still in the dropdowns (an account may have been archived).
    String? accountId = accounts.any((a) => a.id == existing?.accountId)
        ? existing!.accountId
        : null;
    String? categoryId = categories.any((c) => c.id == existing?.categoryId)
        ? existing!.categoryId
        : null;
    String currency = existing?.currency ??
        ref.read(householdProvider).value?.baseCurrency ?? 'USD';

    final tr = S.of(context);
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: EdgeInsets.fromLTRB(
              20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + MediaQuery.of(ctx).viewPadding.bottom + 20),
          decoration: BoxDecoration(
            color: AppColors.popup(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(RadiusTokens.sheet)),
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SheetTitle(
                    existing != null ? tr.tmplEditTitle : tr.tmplNewTitle,
                    subtitle: tr.tmplNewDesc,
                    padding: const EdgeInsetsDirectional.only(
                        top: 4, bottom: 16),
                  ),
                  TextFormField(
                    controller: titleCtrl,
                    autofocus: existing == null,
                    // Tapping an option below drops focus, so a rebuild
                    // doesn't bring the keyboard back.
                    onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(labelText: tr.commonTitle),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? tr.tmplTitleRequired
                        : null,
                  ),
                  const SizedBox(height: 14),
                  CalculatorAmountField(
                    value: calcAmount,
                    label: tr.commonAmount,
                    fontSize: 20,
                    onChanged: (v) =>
                        setSheetState(() => calcAmount = v),
                  ),
                  const SizedBox(height: 14),
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment(
                          value: 'expense', label: Text(tr.typeExpense)),
                      ButtonSegment(
                          value: 'income', label: Text(tr.typeIncome)),
                    ],
                    selected: {type},
                    onSelectionChanged: (s) =>
                        setSheetState(() => type = s.first),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    icon: AppIcons.dropdown,
                    initialValue: accountId,
                    decoration:
                        InputDecoration(labelText: tr.commonAccount),
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
                    icon: AppIcons.dropdown,
                    initialValue: categoryId,
                    decoration: InputDecoration(
                        labelText: tr.tmplCategoryOptional),
                    items: [
                      DropdownMenuItem(
                          value: null, child: Text(tr.catNone)),
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
                          SnackBar(
                            content: Text(tr.tmplEnterAmount),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }
                      final householdId =
                          ref.read(currentHouseholdIdProvider);
                      if (householdId == null) return;

                      final db = ref.read(databaseProvider);
                      try {
                      if (existing != null) {
                        await (db.update(db.transactionTemplates)
                              ..where((t) => t.id.equals(existing.id)))
                            .write(TransactionTemplatesCompanion(
                          title: Value(title),
                          type: Value(type),
                          amount: Value(calcAmount),
                          currency: Value(currency),
                          accountId: Value(accountId),
                          categoryId: Value(categoryId),
                          lastModified: Value(DateTime.now()),
                        ));
                      } else {
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
                      }
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(
                            content: Text(existing != null
                                ? tr.tmplSaved
                                : tr.tmplCreated),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        Navigator.pop(ctx, true);
                      }
                      } catch (e) {
                        debugPrint('[Templates] Save failed: $e');
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                            content: Text(tr.commonSomethingWentWrong),
                            behavior: SnackBarBehavior.floating,
                          ));
                        }
                      }
                    },
                    child: Text(tr.tmplSaveButton),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    disposeAfterRouteAnimation(titleCtrl);
    if (result == true) _load();
  }
}
