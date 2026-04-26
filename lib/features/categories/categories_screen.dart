import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/database/app_database.dart';
import '../../core/providers/accounts_provider.dart';
import '../../core/providers/allocations_provider.dart';
import '../../core/providers/categories_provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/widgets/category_icon.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_retry.dart';
import '../../shared/widgets/skeleton_loader.dart';

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

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final categories = categoriesAsync.value ?? [];

    final expenseCount =
        categories.where((c) => c.transactionType == 'expense').length;
    final incomeCount =
        categories.where((c) => c.transactionType == 'income').length;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_categories',
        tooltip: 'Add category',
        onPressed: () => _showForm(categories: categories),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(categoriesProvider);
            await Future.delayed(const Duration(milliseconds: 300));
          },
          child: CustomScrollView(
            slivers: [
              // ── Header ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Categories',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.tp(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Summary ──
              if (categories.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.sfv(context),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          _SummaryChip(
                            icon: Icons.label_rounded,
                            label: '${categories.length}',
                            subtitle: 'Total',
                            color: AppColors.accent,
                          ),
                          const SizedBox(width: 20),
                          _SummaryChip(
                            icon: Icons.arrow_upward_rounded,
                            label: '$expenseCount',
                            subtitle: 'Expense',
                            color: AppColors.overspent,
                          ),
                          const SizedBox(width: 20),
                          _SummaryChip(
                            icon: Icons.arrow_downward_rounded,
                            label: '$incomeCount',
                            subtitle: 'Income',
                            color: AppColors.healthy,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // ── Search ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: TextField(
                    onChanged: (v) => setState(() => _search = v),
                    textInputAction: TextInputAction.search,
                    style: TextStyle(fontSize: 14, color: AppColors.tp(context)),
                    decoration: InputDecoration(
                      hintText: 'Search categories...',
                      hintStyle: TextStyle(color: AppColors.th(context)),
                      prefixIcon: Icon(Icons.search_rounded,
                          size: 20, color: AppColors.th(context)),
                      filled: true,
                      fillColor: AppColors.sfv(context),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
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
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
                  child: Row(
                    children: [
                      _TypeChip(
                        label: 'All',
                        selected: _typeFilter == null,
                        onTap: () => setState(() => _typeFilter = null),
                      ),
                      const SizedBox(width: 8),
                      _TypeChip(
                        label: 'Expense',
                        selected: _typeFilter == 'expense',
                        color: AppColors.overspent,
                        onTap: () =>
                            setState(() => _typeFilter = 'expense'),
                      ),
                      const SizedBox(width: 8),
                      _TypeChip(
                        label: 'Income',
                        selected: _typeFilter == 'income',
                        color: AppColors.healthy,
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
                    return const SliverFillRemaining(
                      child: EmptyState(
                        icon: Icons.label_outline_rounded,
                        title: 'No categories yet',
                        subtitle: 'Tap + to create one',
                      ),
                    );
                  }

                  final filtered = _applyFilters(cats);
                  if (filtered.isEmpty) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Text(
                          'No matching categories',
                          style: TextStyle(color: AppColors.ts(context)),
                        ),
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
                    message: "Couldn't load categories",
                    details: '$e',
                    onRetry: () => ref.invalidate(categoriesProvider),
                  ),
                ),
              ),

              const SliverPadding(padding: EdgeInsets.only(bottom: 88)),
            ],
          ),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CategoryForm(
        categories: categories,
        existing: existing,
      ),
    );
  }

  Future<void> _toggleArchive(Category cat) async {
    final db = ref.read(databaseProvider);
    final wasArchived = cat.archived;
    await (db.update(db.categories)..where((c) => c.id.equals(cat.id)))
        .write(CategoriesCompanion(
      archived: Value(!cat.archived),
      lastModified: Value(DateTime.now()),
    ));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(wasArchived ? 'Category restored' : 'Category archived'),
          behavior: SnackBarBehavior.floating,
        ),
      );
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

    if (!mounted) return;

    final warnings = <String>[];
    if (totalTx > 0) {
      warnings.add(
          '$totalTx transaction${totalTx == 1 ? '' : 's'} use this category');
    }
    if (envelopeName != null) {
      warnings.add('linked to envelope "$envelopeName"');
    }

    String? action;
    if (warnings.isNotEmpty) {
      final warningText = warnings.join(' and is ');
      action = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete Category'),
          content: Text(
            'This category has $warningText.\n\n'
            'Deleting will uncategorize those transactions and unlink it from the envelope.\n\n'
            'Consider archiving instead.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'cancel'),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'archive'),
              style: TextButton.styleFrom(foregroundColor: AppColors.accent),
              child: const Text('Archive Instead'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'delete'),
              style:
                  TextButton.styleFrom(foregroundColor: AppColors.overspent),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
    } else {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete Category'),
          content: const Text(
              'This category has no transactions. Delete permanently?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style:
                  TextButton.styleFrom(foregroundColor: AppColors.overspent),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      if (confirmed == true) action = 'delete';
    }

    if (!mounted || action == null || action == 'cancel') return;

    if (action == 'archive') {
      await (db.update(db.categories)..where((c) => c.id.equals(cat.id)))
          .write(CategoriesCompanion(
        archived: const Value(true),
        lastModified: Value(DateTime.now()),
      ));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Category archived'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else if (action == 'delete') {
      await (db.delete(db.categories)..where((c) => c.id.equals(cat.id)))
          .go();
      ref.invalidate(categoriesProvider);
      ref.invalidate(allocationsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Category deleted'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Summary chip
// ---------------------------------------------------------------------------

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.tp(context))),
            Text(subtitle,
                style:
                    TextStyle(fontSize: 11, color: AppColors.ts(context))),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Type chip
// ---------------------------------------------------------------------------

class _TypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;
  const _TypeChip({
    required this.label,
    required this.selected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.accent;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? chipColor.withValues(alpha: 0.15)
              : AppColors.sfv(context),
          borderRadius: BorderRadius.circular(20),
          border: selected
              ? Border.all(color: chipColor.withValues(alpha: 0.4))
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? chipColor : AppColors.ts(context),
          ),
        ),
      ),
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

    // Separate groups and subcategories
    final groups = categories.where((c) => c.parentId == null).toList();
    final subsByParent = <String, List<Category>>{};
    for (final cat in categories) {
      if (cat.parentId != null) {
        subsByParent.putIfAbsent(cat.parentId!, () => []).add(cat);
      }
    }

    final expenseGroups =
        groups.where((g) => g.transactionType == 'expense').toList();
    final incomeGroups =
        groups.where((g) => g.transactionType == 'income').toList();

    final tiles = <Widget>[];

    if (expenseGroups.isNotEmpty) {
      tiles.add(_sectionLabel(context, 'EXPENSE', AppColors.overspent));
      for (final g in expenseGroups) {
        tiles.add(_buildGroupTile(
            context, g, subsByParent[g.id] ?? [], accountMap, allocMap));
      }
    }
    if (incomeGroups.isNotEmpty) {
      tiles.add(_sectionLabel(context, 'INCOME', AppColors.healthy));
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

  Widget _sectionLabel(BuildContext context, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 6),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupTile(
    BuildContext context,
    Category group,
    List<Category> subs,
    Map<String, Account> accountMap,
    Map<String, String> allocMap,
  ) {
    final color = AppColors.fromHex(group.colorHex);
    final hasEmoji = group.icon.length <= 4 && group.icon != 'category';
    final defaultAcct = group.defaultAccountId != null
        ? accountMap[group.defaultAccountId]
        : null;
    final envelopeName = group.allocationId != null
        ? allocMap[group.allocationId]
        : null;

    // Build info chips
    final chips = <Widget>[];
    if (envelopeName != null) {
      chips.add(_infoBadge(
          context, Icons.account_balance_wallet_outlined, envelopeName));
    }
    if (defaultAcct != null) {
      chips.add(_infoBadge(context, Icons.credit_card_rounded,
          '${defaultAcct.name} (${defaultAcct.currency})'));
    }
    if (subs.isNotEmpty) {
      chips.add(_infoBadge(context, Icons.subdirectory_arrow_right_rounded,
          '${subs.length} sub'));
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.bd(context)),
      ),
      child: Column(
        children: [
          // Main category tile — tap to edit
          InkWell(
            onTap: () => onEdit(group),
            onLongPress: () => _showActions(context, group),
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14), bottom: Radius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              child: Row(
                children: [
                  CategoryIcon(
                    categoryName: group.name,
                    emoji: hasEmoji ? group.icon : null,
                    color: color,
                    size: 40,
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
                        if (chips.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Wrap(spacing: 6, runSpacing: 4, children: chips),
                        ],
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      size: 20, color: AppColors.th(context)),
                ],
              ),
            ),
          ),
          // Subcategories (inline, no expansion needed)
          if (subs.isNotEmpty) ...[
            Divider(height: 1, color: AppColors.bd(context)),
            ...subs.map((sub) {
              final subColor = AppColors.fromHex(sub.colorHex);
              final subEmoji =
                  sub.icon.length <= 4 && sub.icon != 'category';
              return InkWell(
                onTap: () => onEdit(sub),
                onLongPress: () => _showActions(context, sub),
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(52, 8, 12, 8),
                  child: Row(
                    children: [
                      CategoryIcon(
                        categoryName: sub.name,
                        emoji: subEmoji ? sub.icon : null,
                        color: subColor,
                        size: 28,
                      ),
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
                      Icon(Icons.chevron_right_rounded,
                          size: 16, color: AppColors.th(context)),
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

  Widget _infoBadge(BuildContext context, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.sfv(context),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: AppColors.ts(context)),
          const SizedBox(width: 3),
          Text(label,
              style:
                  TextStyle(fontSize: 10, color: AppColors.ts(context))),
        ],
      ),
    );
  }

  void _showActions(BuildContext context, Category cat) {
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
              Text(cat.name,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.tp(context))),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.edit_rounded),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(ctx);
                  onEdit(cat);
                },
              ),
              ListTile(
                leading: Icon(cat.archived
                    ? Icons.unarchive_rounded
                    : Icons.archive_rounded),
                title: Text(cat.archived ? 'Unarchive' : 'Archive'),
                onTap: () {
                  Navigator.pop(ctx);
                  onArchive(cat);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_rounded,
                    color: AppColors.overspent),
                title: Text('Delete',
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

  static const _emojiGroups = <String, List<String>>{
    'Food & Drink': [
      '🛒', '🍕', '🍔', '🍗', '🥗', '🍣', '🍜', '🌮', '🥐', '🍰',
      '☕', '🍺', '🥤', '🍷', '🧁', '🍩', '🥡', '🧃',
    ],
    'Transport': [
      '🚗', '⛽', '🚕', '🚌', '🚇', '🚲', '✈️', '🛳️', '🚁', '🅿️',
      '🛞', '🏍️',
    ],
    'Home & Bills': [
      '🏠', '💡', '💧', '🔌', '📡', '🛏️', '🪑', '🧹', '🧺', '🔧',
      '🏗️', '🔑',
    ],
    'Shopping': [
      '🛍️', '👕', '👗', '👟', '👜', '💄', '🕶️', '💎', '🧴', '🛒',
    ],
    'Health & Fitness': [
      '💊', '🏥', '🩺', '🏋️', '🧘', '🏊', '🚴', '🦷', '🩹', '💉',
    ],
    'Entertainment': [
      '🎬', '🎮', '🎵', '🎤', '🎭', '🎨', '📺', '🎧', '🎪', '🎲',
      '🍿', '📷',
    ],
    'Education & Work': [
      '🎓', '📚', '💻', '📱', '🖨️', '📊', '💼', '🏢', '📝', '✏️',
      '🔬', '📐',
    ],
    'Money': [
      '💰', '💳', '🏦', '📈', '💵', '🪙', '💲', '🧾', '📑', '🏧',
    ],
    'Family & Pets': [
      '👶', '🧒', '👨‍👩‍👧', '🐾', '🐕', '🐈', '🧸', '🍼', '🎁', '❤️',
    ],
    'Travel & Leisure': [
      '✈️', '🏖️', '🏔️', '🗺️', '🧳', '⛺', '🏨', '🎢', '🎣', '⛷️',
    ],
    'Other': [
      '📦', '🎯', '🔖', '⭐', '🌱', '♻️', '🤝', '🙏', '🚀', '🏷️',
      '📌', '🗂️',
    ],
  };

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
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.th(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _isNew ? 'New Category' : 'Edit Category',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.tp(context),
              ),
            ),
            const SizedBox(height: 20),

            // Icon + Name on the same row for compact feel
            Row(
              children: [
                // Current emoji preview (tap to expand picker)
                GestureDetector(
                  onTap: () => _showEmojiPicker(),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: _color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: _color.withValues(alpha: 0.3)),
                    ),
                    child: Center(
                      child: Text(_emoji,
                          style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _nameCtrl,
                    autofocus: _isNew,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      filled: true,
                      fillColor: AppColors.sfv(context),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppColors.accent, width: 1.5),
                      ),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Type toggle
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'expense', label: Text('Expense')),
                ButtonSegment(value: 'income', label: Text('Income')),
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
                return GestureDetector(
                  onTap: () => setState(() => _color = c),
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
                        ? const Icon(Icons.check,
                            size: 14, color: Colors.white)
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
                    initialValue: _parentId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Parent',
                      labelStyle: const TextStyle(fontSize: 13),
                      filled: true,
                      fillColor: AppColors.sfv(context),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('None', style: TextStyle(fontSize: 13))),
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
                      initialValue: _defaultAccountId,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Account',
                        labelStyle: const TextStyle(fontSize: 13),
                        filled: true,
                        fillColor: AppColors.sfv(context),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        isDense: true,
                      ),
                      items: [
                        const DropdownMenuItem(
                            value: null, child: Text('None', style: TextStyle(fontSize: 13))),
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
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      _isNew ? 'Create' : 'Save',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEmojiPicker() async {
    final customCtrl = TextEditingController();
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.sf(context),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.85,
        minChildSize: 0.4,
        builder: (_, scrollCtrl) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.th(context),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text('Choose Icon',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.tp(context))),
              const SizedBox(height: 12),
              // Custom emoji input — opens system emoji keyboard
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: customCtrl,
                      style: const TextStyle(fontSize: 24),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: 'Type or paste any emoji',
                        hintStyle: TextStyle(
                            fontSize: 14, color: AppColors.th(context)),
                        filled: true,
                        fillColor: AppColors.sfv(context),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      final text = customCtrl.text.trim();
                      if (text.isNotEmpty) {
                        Navigator.pop(ctx, text.characters.first);
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Use'),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Row(
                  children: [
                    Expanded(child: Divider(color: AppColors.bd(context))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('or pick below',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.th(context))),
                    ),
                    Expanded(child: Divider(color: AppColors.bd(context))),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  children: _emojiGroups.entries.map((group) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 12, bottom: 8),
                          child: Text(
                            group.key,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ts(context),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: group.value.map((e) {
                            final isSelected = e == _emoji;
                            return GestureDetector(
                              onTap: () {
                                Navigator.pop(ctx, e);
                              },
                              child: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.accent
                                          .withValues(alpha: 0.15)
                                      : AppColors.sfv(context),
                                  borderRadius: BorderRadius.circular(12),
                                  border: isSelected
                                      ? Border.all(
                                          color: AppColors.accent, width: 2)
                                      : null,
                                ),
                                child: Center(
                                  child: Text(e,
                                      style: const TextStyle(fontSize: 20)),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() => _emoji = result);
    }
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null) return;

    setState(() => _loading = true);
    try {
      final db = ref.read(databaseProvider);
      final id = _isNew ? const Uuid().v4() : widget.existing!.id;
      final colorHex = _colorToHex(_color);

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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isNew ? 'Category created' : 'Category updated'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
