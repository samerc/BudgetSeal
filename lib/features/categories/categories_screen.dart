import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/database/app_database.dart';
import '../../core/providers/accounts_provider.dart';
import '../../core/providers/allocations_provider.dart';
import '../../core/providers/categories_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import 'category_envelope_sheet.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/design_tokens.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_retry.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/skeleton_loader.dart';
import '../../shared/theme/app_icons.dart';
import '../../shared/widgets/category_icon.dart';
import '../../shared/widgets/app_chip.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/large_title_header.dart';
import '../../shared/widgets/sheet_title.dart';
import '../../shared/widgets/tappable.dart';
import '../../core/providers/tx_colors_provider.dart';
import 'emoji_groups.dart';

// ---------------------------------------------------------------------------
// Colour helpers
// ---------------------------------------------------------------------------

String _colorToHex(Color color) =>
    '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

const _categoryColors = [
  Color(0xFF6366F1), Color(0xFF10B981), Color(0xFFF59E0B),
  Color(0xFFEF4444), Color(0xFF8B5CF6), Color(0xFF06B6D4),
  Color(0xFFEC4899), Color(0xFFF97316), Color(0xFF14B8A6),
  Color(0xFF64748B), Color(0xFF84CC16), Color(0xFF78716C),
  Color(0xFFD946EF), Color(0xFF0EA5E9), Color(0xFFE11D48),
  Color(0xFF22C55E), Color(0xFFEAB308), Color(0xFF3B82F6),
  Color(0xFF9333EA), Color(0xFF90A4AE),
];

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  String _search = '';
  String? _typeFilter; // null = all
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final categories = categoriesAsync.value ?? [];

    final expenseCount =
        categories.where((c) => c.transactionType == 'expense').length;
    final incomeCount =
        categories.where((c) => c.transactionType == 'income').length;
    final txColors = ref.watch(txColorsProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_categories',
        tooltip: S.of(context).catAddTooltip,
        onPressed: () => _showForm(categories: categories),
        child: const Icon(AppIcons.plus),
      ),
      body: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(categoriesProvider);
            await Future.delayed(const Duration(milliseconds: 300));
          },
          child: CustomScrollView(
            slivers: [
              LargeTitleHeader(title: S.of(context).catTitle, back: true),

              // ── Summary ──
              if (categories.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Row(
                      children: [
                        _SummaryPill(
                          label: S.of(context).catTotal(categories.length),
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: 8),
                        _SummaryPill(
                          label: S.of(context).catExpenseCount(expenseCount),
                          color: txColors.expense,
                        ),
                        const SizedBox(width: 8),
                        _SummaryPill(
                          label: S.of(context).catIncomeCount(incomeCount),
                          color: txColors.income,
                        ),
                      ],
                    ),
                  ),
                ),

              // ── Search ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _search = v),
                    textInputAction: TextInputAction.search,
                    style: TextStyle(fontSize: 14, color: AppColors.tp(context)),
                    decoration: InputDecoration(
                      hintText: S.of(context).catSearchHint,
                      hintStyle: TextStyle(color: AppColors.th(context)),
                      prefixIcon: Icon(AppIcons.magnifyingGlass,
                          size: 20, color: AppColors.th(context)),
                      suffixIcon: _search.isNotEmpty
                          ? IconButton(
                              icon: Icon(AppIcons.x,
                                  size: 18, color: AppColors.th(context)),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _search = '');
                              },
                            )
                          : null,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 12),
                      isDense: true,
                    ),
                  ),
                ),
              ),

              // ── Type filter chips ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                  child: Row(
                    children: [
                      AppChip(
                        label: S.of(context).catAll,
                        selected: _typeFilter == null,
                        onTap: () => setState(() => _typeFilter = null),
                      ),
                      const SizedBox(width: 8),
                      AppChip(
                        label: S.of(context).typeExpense,
                        selected: _typeFilter == 'expense',
                        color: txColors.expense,
                        onTap: () =>
                            setState(() => _typeFilter = 'expense'),
                      ),
                      const SizedBox(width: 8),
                      AppChip(
                        label: S.of(context).typeIncome,
                        selected: _typeFilter == 'income',
                        color: txColors.income,
                        onTap: () =>
                            setState(() => _typeFilter = 'income'),
                      ),
                    ],
                  ),
                ),
              ),

              // ── List ──
              categoriesAsync.when(
                data: (cats) {
                  if (cats.isEmpty) {
                    return SliverFillRemaining(
                      child: EmptyState(
                        icon: AppIcons.tag,
                        title: S.of(context).catNoYet,
                        subtitle: S.of(context).catTapPlus,
                      ),
                    );
                  }

                  final filtered = _applyFilters(cats);
                  if (filtered.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyState(
                        icon: AppIcons.magnifyingGlassMinus,
                        title: S.of(context).catNoMatch,
                      ),
                    );
                  }

                  return _CategoriesSliver(
                    categories: filtered,
                    allCategories: cats,
                    onEdit: (cat) =>
                        _showForm(categories: cats, existing: cat),
                    onArchive: _toggleArchive,
                    onDelete: _confirmDelete,
                  );
                },
                loading: () =>
                    const SliverToBoxAdapter(child: SkeletonList()),
                error: (e, _) => SliverFillRemaining(
                  child: ErrorRetry(
                    message: S.of(context).catCouldntLoad,
                    details: '$e',
                    onRetry: () => ref.invalidate(categoriesProvider),
                  ),
                ),
              ),

              const SliverPadding(padding: EdgeInsets.only(bottom: 88)),
            ],
          ),
      ),
    );
  }

  List<Category> _applyFilters(List<Category> cats) {
    var list = cats.toList();
    if (_typeFilter != null) {
      list = list.where((c) => c.transactionType == _typeFilter).toList();
    }
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((c) => c.name.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  void _showForm({
    required List<Category> categories,
    Category? existing,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CategoryForm(
        categories: categories,
        existing: existing,
      ),
    );
  }

  Future<void> _toggleArchive(Category cat) async {
    final db = ref.read(databaseProvider);
    final wasArchived = cat.archived;
    final messenger = ScaffoldMessenger.of(context);
    final tr = S.of(context);
    try {
      await (db.update(db.categories)..where((c) => c.id.equals(cat.id)))
          .write(CategoriesCompanion(
        archived: Value(!cat.archived),
        lastModified: Value(DateTime.now()),
      ));
      messenger.showSnackBar(SnackBar(
        content: Text(wasArchived ? tr.catRestored : tr.catArchived),
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      debugPrint('[Categories] Archive failed: $e');
      messenger.showSnackBar(SnackBar(
        content: Text(tr.commonSomethingWentWrong),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _confirmDelete(Category cat) async {
    final db = ref.read(databaseProvider);

    // Count references
    final txRows = await (db.select(db.transactions)
          ..where((t) => t.categoryId.equals(cat.id))
          ..where((t) => t.deleted.equals(false)))
        .get();
    final lineRows = await (db.select(db.transactionLines)
          ..where((t) => t.categoryId.equals(cat.id)))
        .get();
    final totalTx = txRows.length + lineRows.length;

    String? envelopeName;
    if (cat.allocationId != null) {
      final alloc = await (db.select(db.allocations)
            ..where((a) => a.id.equals(cat.allocationId!)))
          .getSingleOrNull();
      envelopeName = alloc?.name;
    }

    final subCount = (await (db.select(db.categories)
              ..where((c) => c.parentId.equals(cat.id) & c.deleted.equals(false)))
            .get())
        .length;

    if (!mounted) return;
    final subsNote =
        subCount > 0 ? '\n\n${S.of(context).catDeleteSubsKept(subCount)}' : '';

    final warnings = <String>[];
    if (totalTx > 0) {
      warnings.add(S.of(context).catDeleteTxCount(totalTx));
    }
    if (envelopeName != null) {
      warnings.add(S.of(context).catDeleteLinkedEnvelope(envelopeName));
    }

    String? action;
    final tr = S.of(context);
    if (warnings.isNotEmpty) {
      final warningText = warnings.join(', ');
      action = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(tr.catDeleteTitle),
          content: Text(tr.catDeleteWarning(warningText) + subsNote),
          actions: [
            OutlinedButton(
              style: DialogButtons.outlined,
              onPressed: () => Navigator.pop(ctx, 'cancel'),
              child: Text(tr.commonCancel),
            ),
            OutlinedButton(
              style: DialogButtons.outlined,
              onPressed: () => Navigator.pop(ctx, 'archive'),
              child: Text(tr.allocArchiveInstead),
            ),
            FilledButton(
              style: DialogButtons.destructive,
              onPressed: () => Navigator.pop(ctx, 'delete'),
              child: Text(tr.commonDelete),
            ),
          ],
        ),
      );
    } else {
      final confirmed = await showConfirmDialog(
        context,
        title: tr.catDeleteTitle,
        message: tr.catDeleteNoTx + subsNote,
        confirmLabel: tr.commonDelete,
      );
      if (confirmed) action = 'delete';
    }

    if (!mounted || action == null || action == 'cancel') return;
    final messenger = ScaffoldMessenger.of(context);
    void show(String text) => messenger.showSnackBar(SnackBar(
          content: Text(text),
          behavior: SnackBarBehavior.floating,
        ));

    try {
      if (action == 'archive') {
        await (db.update(db.categories)..where((c) => c.id.equals(cat.id)))
            .write(CategoriesCompanion(
          archived: const Value(true),
          lastModified: Value(DateTime.now()),
        ));
        show(tr.catArchived);
      } else if (action == 'delete') {
        await db.transaction(() async {
          await (db.update(db.categories)..where((c) => c.id.equals(cat.id)))
              .write(CategoriesCompanion(
                  deleted: const Value(true),
                  lastModified: Value(DateTime.now())));
          // Its subcategories stay, as top-level categories — otherwise they
          // hang off a deleted group and no list shows them again.
          await (db.update(db.categories)
                ..where((c) =>
                    c.parentId.equals(cat.id) & c.deleted.equals(false)))
              .write(CategoriesCompanion(
                  parentId: const Value(null),
                  lastModified: Value(DateTime.now())));
        });
        ref.invalidate(categoriesProvider);
        ref.invalidate(allocationsProvider);
        show(tr.catDeleted);
      }
    } catch (e) {
      debugPrint('[Categories] Delete failed: $e');
      show(tr.commonSomethingWentWrong);
    }
  }
}

// ---------------------------------------------------------------------------
// Summary pill
// ---------------------------------------------------------------------------

class _SummaryPill extends StatelessWidget {
  final String label;
  final Color color;
  const _SummaryPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.pastel(context, color,
            light: 0.85, dark: 0.78),
        borderRadius: BorderRadius.circular(RadiusTokens.pill),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

// ---------------------------------------------------------------------------
// Categories Sliver (grouped by type, with parent/child hierarchy)
// ---------------------------------------------------------------------------

class _CategoriesSliver extends ConsumerWidget {
  final List<Category> categories;
  final List<Category> allCategories;
  final void Function(Category) onEdit;
  final Future<void> Function(Category) onArchive;
  final Future<void> Function(Category) onDelete;

  const _CategoriesSliver({
    required this.categories,
    required this.allCategories,
    required this.onEdit,
    required this.onArchive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsProvider).value ?? [];
    final accountMap = {for (final a in accounts) a.id: a};
    final allocations = ref.watch(allocationsProvider).value ?? [];
    final allocMap = {
      for (final a in allocations) a.data.allocation.id: a.data.allocation.name
    };

    // Separate groups and subcategories. A category whose parent isn't
    // listed (deleted or archived, or a grandchild from old data) shows as
    // a group, so it can still be edited.
    final ids = {for (final c in categories) c.id};
    final topIds = {
      for (final c in categories)
        if (c.parentId == null || !ids.contains(c.parentId)) c.id
    };
    bool isSub(Category c) =>
        c.parentId != null && topIds.contains(c.parentId);
    final groups = categories.where((c) => !isSub(c)).toList();
    final subsByParent = <String, List<Category>>{};
    for (final cat in categories) {
      if (isSub(cat)) {
        subsByParent.putIfAbsent(cat.parentId!, () => []).add(cat);
      }
    }

    final expenseGroups =
        groups.where((g) => g.transactionType == 'expense').toList();
    final incomeGroups =
        groups.where((g) => g.transactionType == 'income').toList();

    final tiles = <Widget>[];

    if (expenseGroups.isNotEmpty) {
      tiles.add(_sectionLabel(S.of(context).catSectionExpense));
      for (final g in expenseGroups) {
        tiles.add(_buildGroupTile(
            context, g, subsByParent[g.id] ?? [], accountMap, allocMap));
      }
    }
    if (incomeGroups.isNotEmpty) {
      tiles.add(_sectionLabel(S.of(context).catSectionIncome));
      for (final g in incomeGroups) {
        tiles.add(_buildGroupTile(
            context, g, subsByParent[g.id] ?? [], accountMap, allocMap));
      }
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildListDelegate(tiles),
      ),
    );
  }

  Widget _sectionLabel(String label) => SectionHeader(label,
      padding: const EdgeInsetsDirectional.fromSTEB(4, 16, 4, 6));

  Widget _buildGroupTile(
    BuildContext context,
    Category group,
    List<Category> subs,
    Map<String, Account> accountMap,
    Map<String, String> allocMap,
  ) {
    final color = AppColors.fromHex(group.colorHex);
    final hasEmoji = group.icon.length <= 4 && group.icon != 'category';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: AppColors.card(context),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Main category tile
          Tappable(
            onTap: () => onEdit(group),
            onLongPress: () => _showActions(context, group),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(12, 12, 14, 12),
              child: Row(
                children: [
                  CategoryIcon(
                    categoryName: group.name,
                    emoji: hasEmoji ? group.icon : null,
                    color: color,
                    size: CategoryIconTokens.listSize,
                    circular: true,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: group.archived
                                ? AppColors.th(context)
                                : AppColors.tp(context),
                            decoration: group.archived
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subs.isNotEmpty)
                          Text(
                            S.of(context).catSubcategories(subs.length),
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.ts(context)),
                          ),
                        // Envelope badge: where this category's spending goes.
                        if (allocMap[group.allocationId] != null)
                          Row(
                            children: [
                              Icon(AppIcons.envelopeSimple,
                                  size: 12, color: AppColors.accent),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  allocMap[group.allocationId]!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.accent),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  Icon(AppIcons.caretRight,
                      size: 18, color: AppColors.th(context)),
                ],
              ),
            ),
          ),
          // Subcategories
          if (subs.isNotEmpty) ...[
            Divider(
                height: 1,
                indent: 12,
                endIndent: 12,
                color: AppColors.bd(context)),
            ...subs.map((sub) {
              final subEmoji =
                  sub.icon.length <= 4 && sub.icon != 'category';
              return Tappable(
                onTap: () => onEdit(sub),
                onLongPress: () => _showActions(context, sub),
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 14, 8),
                  child: Row(
                    children: [
                      subEmoji
                          ? EmojiGlyph(sub.icon, size: 20)
                          : Text('·',
                              style: TextStyle(fontSize: 20, color: color)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          sub.name,
                          style: TextStyle(
                            fontSize: 13,
                            color: sub.archived
                                ? AppColors.th(context)
                                : AppColors.tp(context),
                            decoration: sub.archived
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  void _showActions(BuildContext context, Category cat) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SheetTitle(cat.name),
              ListTile(
                leading: const Icon(AppIcons.pencilSimple),
                title: Text(S.of(ctx).catEdit),
                onTap: () {
                  Navigator.pop(ctx);
                  onEdit(cat);
                },
              ),
              if (cat.transactionType == 'expense')
                ListTile(
                  leading: const Icon(AppIcons.envelopeSimple),
                  title: Text(S.of(ctx).catLinkEnvelope),
                  onTap: () {
                    Navigator.pop(ctx);
                    showCategoryEnvelopeSheet(context, cat);
                  },
                ),
              ListTile(
                leading: Icon(cat.archived
                    ? AppIcons.boxArrowUp
                    : AppIcons.archive),
                title: Text(cat.archived ? S.of(ctx).catUnarchive : S.of(ctx).catArchive),
                onTap: () {
                  Navigator.pop(ctx);
                  onArchive(cat);
                },
              ),
              ListTile(
                leading: Icon(AppIcons.trash,
                    color: AppColors.overspent),
                title: Text(S.of(ctx).commonDelete,
                    style: TextStyle(color: AppColors.overspent)),
                onTap: () {
                  Navigator.pop(ctx);
                  onDelete(cat);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Create / Edit form (bottom sheet)
// ---------------------------------------------------------------------------

class _CategoryForm extends ConsumerStatefulWidget {
  final List<Category> categories;
  final Category? existing;

  const _CategoryForm({required this.categories, this.existing});

  @override
  ConsumerState<_CategoryForm> createState() => _CategoryFormState();
}

class _CategoryFormState extends ConsumerState<_CategoryForm> {
  final _nameCtrl = TextEditingController();
  String _type = 'expense';
  String? _parentId;
  String? _defaultAccountId;
  String _emoji = '📦';
  Color _color = _categoryColors[0];
  bool _loading = false;
  bool _showEmojiGrid = false;

  bool get _isNew => widget.existing == null;

  @override
  void initState() {
    super.initState();
    if (!_isNew) {
      final cat = widget.existing!;
      _nameCtrl.text = cat.name;
      _type = cat.transactionType;
      _parentId = cat.parentId;
      _defaultAccountId = cat.defaultAccountId;
      _emoji = cat.icon.length <= 4 ? cat.icon : '📦';
      _color = AppColors.fromHex(cat.colorHex);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groups = widget.categories
        .where((c) => c.parentId == null && c.id != widget.existing?.id)
        .toList();

    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).viewPadding.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetTitle(
              _isNew ? S.of(context).catNewTitle : S.of(context).catEditTitle,
              padding: const EdgeInsetsDirectional.only(top: 4, bottom: 16),
            ),

            // Icon + Name on the same row
            Row(
              children: [
                // Current emoji preview (tap to expand/collapse inline picker)
                Tappable(
                  onTap: () => setState(() {
                    _showEmojiGrid = !_showEmojiGrid;
                    // Dismiss keyboard when opening picker
                    if (_showEmojiGrid) FocusScope.of(context).unfocus();
                  }),
                  borderRadius: BorderRadius.circular(
                      CategoryIconTokens.listSize / 2),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _showEmojiGrid
                            ? AppColors.accent
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: CategoryIcon(
                      categoryName: _nameCtrl.text,
                      emoji: _emoji,
                      color: _color,
                      size: CategoryIconTokens.listSize,
                      circular: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _nameCtrl,
                    autofocus: _isNew && !_showEmojiGrid,
                    // Tapping an option below drops focus, so a rebuild
                    // doesn't bring the keyboard back.
                    onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
                    textInputAction: TextInputAction.done,
                    maxLength: InputLimits.nameMaxLength,
                    decoration: InputDecoration(
                      labelText: S.of(context).catName,
                    ),
                    textCapitalization: TextCapitalization.words,
                    onTap: () {
                      if (_showEmojiGrid) setState(() => _showEmojiGrid = false);
                    },
                  ),
                ),
              ],
            ),

            // ── Inline emoji picker (expands below icon+name row) ──
            if (_showEmojiGrid) ...[
              const SizedBox(height: 12),
              InlineEmojiGrid(
                selected: _emoji,
                onPick: (e) => setState(() {
                  _emoji = e;
                  _showEmojiGrid = false;
                }),
              ),
            ],
            const SizedBox(height: 16),

            // Type toggle
            SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'expense', label: Text(S.of(context).typeExpense)),
                ButtonSegment(value: 'income', label: Text(S.of(context).typeIncome)),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 16),

            // Color picker (scrollable row)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categoryColors.map((c) {
                final isSelected =
                    c.toARGB32() == _color.toARGB32();
                return Tappable(
                  onTap: () => setState(() => _color = c),
                  borderRadius: BorderRadius.circular(RadiusTokens.pill),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(
                              color: AppColors.tp(context), width: 2.5)
                          : null,
                    ),
                    child: isSelected
                        ? Icon(AppIcons.check,
                            size: 14, color: AppColors.inkOn(c))
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Parent group + default account (collapsed into a row)
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    icon: AppIcons.dropdown,
                    initialValue: _parentId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: S.of(context).catParent,
                      labelStyle: const TextStyle(fontSize: 13),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      isDense: true,
                    ),
                    items: [
                      DropdownMenuItem(
                          value: null, child: Text(S.of(context).catNone, style: const TextStyle(fontSize: 13))),
                      ...groups.map((g) => DropdownMenuItem(
                          value: g.id,
                          child: Text(g.name, style: const TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis))),
                    ],
                    onChanged: (v) => setState(() => _parentId = v),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Builder(builder: (context) {
                    final accounts =
                        ref.watch(accountsProvider).value ?? [];
                    return DropdownButtonFormField<String?>(
                      icon: AppIcons.dropdown,
                      initialValue: _defaultAccountId,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: S.of(context).commonAccount,
                        labelStyle: const TextStyle(fontSize: 13),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        isDense: true,
                      ),
                      items: [
                        DropdownMenuItem(
                            value: null, child: Text(S.of(context).catNone, style: const TextStyle(fontSize: 13))),
                        ...accounts.map((a) => DropdownMenuItem(
                            value: a.id,
                            child: Text('${a.name} (${a.currency})',
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis))),
                      ],
                      onChanged: (v) =>
                          setState(() => _defaultAccountId = v),
                    );
                  }),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Save button
            FilledButton(
              onPressed: _loading ? null : _save,
              child: _loading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: AppColors.onAccent, strokeWidth: 2),
                    )
                  : Text(
                      _isNew ? S.of(context).catCreate : S.of(context).commonSave,
                    ),
            ),
          ],
        ),
      ),
    );
  }


  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).catEnterName),
            behavior: SnackBarBehavior.floating),
      );
      return;
    }
    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null) return;

    setState(() => _loading = true);
    try {
      final db = ref.read(databaseProvider);
      final id = _isNew ? const Uuid().v4() : widget.existing!.id;
      final colorHex = _colorToHex(_color);

      await db.transaction(() async {
        await db.into(db.categories).insertOnConflictUpdate(
              CategoriesCompanion(
                id: Value(id),
                householdId: Value(householdId),
                name: Value(name),
                transactionType: Value(_type),
                parentId: Value(_parentId),
                defaultAccountId: Value(_defaultAccountId),
                icon: Value(_emoji),
                colorHex: Value(colorHex),
                lastModified: Value(DateTime.now()),
              ),
            );
        // Only two levels: a group that becomes a subcategory takes its own
        // subcategories along under the new parent, rather than leaving
        // them as grandchildren the list can't show.
        if (!_isNew && _parentId != null) {
          await (db.update(db.categories)
                ..where((c) => c.parentId.equals(id) & c.deleted.equals(false)))
              .write(CategoriesCompanion(
                  parentId: Value(_parentId),
                  lastModified: Value(DateTime.now())));
        }
      });

      ref.invalidate(categoriesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isNew ? S.of(context).catCreated : S.of(context).catUpdated),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('[Categories] Save failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(S.of(context).commonSomethingWentWrong),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
