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

// ---------------------------------------------------------------------------
// Colour helpers (mirrored from add_transaction_screen)
// ---------------------------------------------------------------------------

const _categoryColors = [
  Color(0xFFE57373),
  Color(0xFFFF8A65),
  Color(0xFFFFD54F),
  Color(0xFF81C784),
  Color(0xFF4DB6AC),
  Color(0xFF64B5F6),
  Color(0xFFBA68C8),
  Color(0xFF90A4AE),
];

Color _hexToColor(String hex) {
  final h = hex.replaceAll('#', '');
  return Color(int.parse('FF$h', radix: 16));
}

String _colorToHex(Color color) =>
    '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final categories = categoriesAsync.value ?? [];

    return Scaffold(
      
      appBar: AppBar(
        title: const Text('Categories'),
        
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: categoriesAsync.when(
        data: (cats) => cats.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.label_outline_rounded,
                        size: 52, color: AppColors.textHint),
                    const SizedBox(height: 16),
                    const Text(
                      'No categories yet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tap + to create one',
                      style: TextStyle(fontSize: 14, color: AppColors.textHint),
                    ),
                  ],
                ),
              )
            : _CategoriesList(
                categories: cats,
                onEdit: (cat) => _showForm(context, ref,
                    categories: cats, existing: cat),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_categories',
        onPressed: () =>
            _showForm(context, ref, categories: categories),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showForm(
    BuildContext context,
    WidgetRef ref, {
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
}

// ---------------------------------------------------------------------------
// List
// ---------------------------------------------------------------------------

class _CategoriesList extends ConsumerWidget {
  final List<Category> categories;
  final void Function(Category) onEdit;

  const _CategoriesList({required this.categories, required this.onEdit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsProvider).value ?? [];
    final accountMap = {for (final a in accounts) a.id: a};
    // Organise into groups and sub-categories.
    final groups =
        categories.where((c) => c.parentId == null).toList();
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

    return ListView(
      padding: const EdgeInsets.only(bottom: 80),
      children: [
        if (expenseGroups.isNotEmpty) ...[
          _SectionHeader(label: 'Expense', color: AppColors.overspent),
          ...expenseGroups.map((g) => _GroupTile(
                group: g,
                subCategories: subsByParent[g.id] ?? [],
                accountMap: accountMap,
                onEdit: onEdit,
              )),
        ],
        if (incomeGroups.isNotEmpty) ...[
          _SectionHeader(label: 'Income', color: AppColors.healthy),
          ...incomeGroups.map((g) => _GroupTile(
                group: g,
                subCategories: subsByParent[g.id] ?? [],
                accountMap: accountMap,
                onEdit: onEdit,
              )),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final Color color;

  const _SectionHeader({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _GroupTile extends StatelessWidget {
  final Category group;
  final List<Category> subCategories;
  final Map<String, Account> accountMap;
  final void Function(Category) onEdit;

  const _GroupTile({
    required this.group,
    required this.subCategories,
    required this.accountMap,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final color = _hexToColor(group.colorHex);
    final hasEmoji = group.icon.length <= 4 && group.icon != 'category';
    final dot = CategoryIcon(
      categoryName: group.name,
      emoji: hasEmoji ? group.icon : null,
      color: color,
      size: 36,
    );

    final defaultAcct = group.defaultAccountId != null
        ? accountMap[group.defaultAccountId]
        : null;

    if (subCategories.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.sf(context),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          leading: dot,
          title: Text(group.name,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          subtitle: defaultAcct != null
              ? Text('${defaultAcct.name} (${defaultAcct.currency})',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textHint))
              : null,
          trailing: IconButton(
            icon: const Icon(Icons.edit_outlined,
                size: 18, color: AppColors.textHint),
            onPressed: () => onEdit(group),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        leading: dot,
        title: Text(group.name,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined,
                  size: 18, color: AppColors.textHint),
              onPressed: () => onEdit(group),
            ),
            const Icon(Icons.expand_more_rounded,
                color: AppColors.textSecondary),
          ],
        ),
        shape: const Border(),
        collapsedShape: const Border(),
        children: subCategories.map((sub) {
          final subColor = _hexToColor(sub.colorHex);
          final subHasEmoji =
              sub.icon.length <= 4 && sub.icon != 'category';
          final subAcct = sub.defaultAccountId != null
              ? accountMap[sub.defaultAccountId]
              : null;
          return ListTile(
            contentPadding: const EdgeInsets.fromLTRB(56, 0, 4, 0),
            leading: CategoryIcon(
              categoryName: sub.name,
              emoji: subHasEmoji ? sub.icon : null,
              color: subColor,
              size: 28,
            ),
            title: Text(sub.name,
                style: const TextStyle(fontSize: 13)),
            subtitle: subAcct != null
                ? Text('${subAcct.name} (${subAcct.currency})',
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textHint))
                : null,
            trailing: IconButton(
              icon: const Icon(Icons.edit_outlined,
                  size: 16, color: AppColors.textHint),
              onPressed: () => onEdit(sub),
            ),
          );
        }).toList(),
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

  static const _emojis = [
    '🛒', '🍕', '🏠', '🚗', '⛽', '💊', '🎬', '✈️', '👕', '💇',
    '📱', '💡', '🎓', '🏋️', '🎁', '🐾', '👶', '🔧', '📦', '💰',
    '💳', '🏦', '📊', '🎯', '☕', '🍺', '🛍️', '🧹', '🎵', '📚',
  ];

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
      _color = _hexToColor(cat.colorHex);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Only show groups (parentId == null) as potential parents.
    final groups = widget.categories
        .where((c) => c.parentId == null && c.id != widget.existing?.id)
        .toList();

    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
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
                color: AppColors.sfv(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _isNew ? 'New Category' : 'Edit Category',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 20),

          // Emoji icon
          Text('Icon', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _emojis.map((e) {
              final isSelected = e == _emoji;
              return GestureDetector(
                onTap: () => setState(() => _emoji = e),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.accent.withValues(alpha: 0.15)
                        : null,
                    borderRadius: BorderRadius.circular(8),
                    border: isSelected
                        ? Border.all(color: AppColors.accent, width: 2)
                        : null,
                  ),
                  child: Center(
                    child: Text(e, style: const TextStyle(fontSize: 20)),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Name
          TextField(
            controller: _nameCtrl,
            autofocus: true,
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
                borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
              ),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 20),

          // Type toggle
          Text('Type', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'expense', label: Text('Expense')),
              ButtonSegment(value: 'income', label: Text('Income')),
            ],
            selected: {_type},
            onSelectionChanged: (s) => setState(() => _type = s.first),
          ),
          const SizedBox(height: 20),

          // Parent group (optional)
          DropdownButtonFormField<String?>(
            initialValue: _parentId,
            decoration: InputDecoration(
              labelText: 'Parent group (optional)',
              filled: true,
              fillColor: AppColors.sfv(context),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            items: [
              const DropdownMenuItem(
                  value: null, child: Text('None — this is a group')),
              ...groups.map((g) =>
                  DropdownMenuItem(value: g.id, child: Text(g.name))),
            ],
            onChanged: (v) => setState(() => _parentId = v),
          ),
          const SizedBox(height: 20),

          // Default account
          Builder(builder: (context) {
            final accounts =
                ref.watch(accountsProvider).value ?? [];
            return DropdownButtonFormField<String?>(
              initialValue: _defaultAccountId,
              decoration: InputDecoration(
                labelText: 'Default account (optional)',
                filled: true,
                fillColor: AppColors.sfv(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              items: [
                const DropdownMenuItem(
                    value: null, child: Text('None')),
                ...accounts.map((a) => DropdownMenuItem(
                    value: a.id,
                    child: Text('${a.name} (${a.currency})'))),
              ],
              onChanged: (v) => setState(() => _defaultAccountId = v),
            );
          }),
          const SizedBox(height: 20),

          // Colour picker
          Text('Color', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _categoryColors.map((c) {
              final isSelected = c.toARGB32() == _color.toARGB32();
              return GestureDetector(
                onTap: () => setState(() => _color = c),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(
                            color: Colors.black87, width: 2.5)
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check,
                          size: 16, color: Colors.white)
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),

          // Archive / Delete (edit only)
          if (!_isNew) ...[
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: _loading ? null : _toggleArchive,
                    icon: Icon(
                      widget.existing!.archived
                          ? Icons.unarchive_outlined
                          : Icons.archive_outlined,
                      size: 18,
                    ),
                    label: Text(
                      widget.existing!.archived ? 'Unarchive' : 'Archive',
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton.icon(
                    onPressed: _loading ? null : _confirmDelete,
                    icon: const Icon(Icons.delete_forever_rounded, size: 18),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.overspent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // Save
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
    );
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

      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleArchive() async {
    final cat = widget.existing!;
    final db = ref.read(databaseProvider);
    await (db.update(db.categories)..where((c) => c.id.equals(cat.id)))
        .write(CategoriesCompanion(
      archived: Value(!cat.archived),
      lastModified: Value(DateTime.now()),
    ));
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _confirmDelete() async {
    final cat = widget.existing!;
    final db = ref.read(databaseProvider);

    // Count transactions referencing this category.
    final txRows = await (db.select(db.transactions)
          ..where((t) => t.categoryId.equals(cat.id)))
        .get();

    final lineRows = await (db.select(db.transactionLines)
          ..where((t) => t.categoryId.equals(cat.id)))
        .get();

    final totalTx = txRows.length + lineRows.length;

    // Check if linked to an envelope.
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
      warnings.add('$totalTx transaction${totalTx == 1 ? '' : 's'} use this category');
    }
    if (envelopeName != null) {
      warnings.add('linked to envelope "$envelopeName"');
    }

    if (warnings.isNotEmpty) {
      final warningText = warnings.join(' and is ');
      final action = await showDialog<String>(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          title: const Text('Delete Category'),
          content: Text(
            'This category has $warningText.\n\n'
            'Deleting it will uncategorize those transactions '
            'and unlink it from the envelope.\n\n'
            'Consider archiving instead to preserve history.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, 'cancel'),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, 'archive'),
              style: TextButton.styleFrom(
                  foregroundColor: AppColors.accent),
              child: const Text('Archive Instead'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, 'delete'),
              style: TextButton.styleFrom(
                  foregroundColor: AppColors.overspent),
              child: const Text('Delete Permanently'),
            ),
          ],
        ),
      );

      if (!mounted) return;

      if (action == 'archive') {
        await (db.update(db.categories)..where((c) => c.id.equals(cat.id)))
            .write(CategoriesCompanion(
          archived: const Value(true),
          lastModified: Value(DateTime.now()),
        ));
        if (mounted) Navigator.of(context).pop();
      } else if (action == 'delete') {
        // Category FK is onDelete: SetNull, so transactions will be uncategorized.
        await (db.delete(db.categories)..where((c) => c.id.equals(cat.id)))
            .go();
        ref.invalidate(categoriesProvider);
        ref.invalidate(allocationsProvider);
        if (mounted) Navigator.of(context).pop();
      }
    } else {
      // No references -- simple confirmation.
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          title: const Text('Delete Category Permanently'),
          content: const Text(
            'This category has no transactions and is not linked to any envelope. '
            'Are you sure you want to permanently delete it? '
            'This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, true),
              style: TextButton.styleFrom(
                  foregroundColor: AppColors.overspent),
              child: const Text('Delete Permanently'),
            ),
          ],
        ),
      );

      if (confirmed == true && mounted) {
        await (db.delete(db.categories)..where((c) => c.id.equals(cat.id)))
            .go();
        ref.invalidate(categoriesProvider);
        if (mounted) Navigator.of(context).pop();
      }
    }
  }
}
