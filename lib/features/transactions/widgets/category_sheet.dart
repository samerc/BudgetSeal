import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../../../shared/theme/app_colors.dart';

Color hexToColor(String hex) {
  final h = hex.replaceAll('#', '');
  return Color(int.parse('FF$h', radix: 16));
}

const categoryPresetColors = [
  Color(0xFFE57373),
  Color(0xFFFF8A65),
  Color(0xFFFFD54F),
  Color(0xFF81C784),
  Color(0xFF4DB6AC),
  Color(0xFF64B5F6),
  Color(0xFFBA68C8),
  Color(0xFF90A4AE),
];

class CategorySheet extends StatefulWidget {
  final List<Category> categories;
  final String? selectedId;
  final String? householdId;
  final void Function(String id, String name, Color color, String txType)
      onSelected;
  final void Function(String name) onCreated;
  /// Map of allocationId → envelope display string (e.g. "Groceries — USD 500")
  final Map<String, String> envelopeInfo;

  const CategorySheet({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.householdId,
    required this.onSelected,
    required this.onCreated,
    this.envelopeInfo = const {},
  });

  @override
  State<CategorySheet> createState() => _CategorySheetState();
}

class _CategorySheetState extends State<CategorySheet> {
  bool _creating = false;
  final _newCatCtrl = TextEditingController();

  @override
  void dispose() {
    _newCatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groups =
        widget.categories.where((c) => c.parentId == null).toList();
    final subsByParent = <String, List<Category>>{};
    for (final cat in widget.categories) {
      if (cat.parentId != null) {
        subsByParent.putIfAbsent(cat.parentId!, () => []).add(cat);
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, scrollCtrl) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Column(
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
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Category',
                            style: Theme.of(context).textTheme.titleMedium),
                        if (!_creating)
                          TextButton.icon(
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: const Text('New'),
                            onPressed: () =>
                                setState(() => _creating = true),
                          ),
                      ],
                    ),
                    if (_creating) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _newCatCtrl,
                              autofocus: true,
                              decoration: const InputDecoration(
                                  hintText: 'Category name',
                                  isDense: true),
                              textCapitalization:
                                  TextCapitalization.words,
                              onSubmitted: _submitNew,
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: () =>
                                _submitNew(_newCatCtrl.text),
                            style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10)),
                            child: const Text('Add'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded,
                                size: 18),
                            onPressed: () =>
                                setState(() => _creating = false),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                  ],
                ),
              ),
              Expanded(
                child: widget.categories.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'No categories yet.\nCreate one above or manage in Settings → Categories.',
                            textAlign: TextAlign.center,
                            style:
                                TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      )
                    : ListView(
                        controller: scrollCtrl,
                        padding:
                            const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        children:
                            _buildGroupedChips(groups, subsByParent),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildGroupedChips(
    List<Category> groups,
    Map<String, List<Category>> subsByParent,
  ) {
    final widgets = <Widget>[];

    for (final txType in ['expense', 'income']) {
      final sectionGroups =
          groups.where((g) => g.transactionType == txType).toList();
      if (sectionGroups.isEmpty) continue;

      widgets.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 12, 0, 6),
          child: Text(
            txType == 'expense' ? 'EXPENSE' : 'INCOME',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: txType == 'expense'
                  ? AppColors.overspent
                  : AppColors.healthy,
            ),
          ),
        ),
      );

      for (final group in sectionGroups) {
        final subs = subsByParent[group.id] ?? [];
        final groupColor = hexToColor(group.colorHex);

        // Always show group name as a header.
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 4),
            child: Text(
              group.name,
              style: TextStyle(
                fontSize: 12,
                color: groupColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );

        if (subs.isEmpty) {
          // Standalone category (no subs) — still selectable as itself.
          widgets.add(_buildChipsRow([group]));
        } else {
          // Has subcategories — only subs are selectable.
          widgets.add(_buildChipsRow(subs));
        }
      }
    }

    return widgets;
  }

  Widget _buildChipsRow(List<Category> cats) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: cats.map((cat) {
          final color = hexToColor(cat.colorHex);
          final isSelected = cat.id == widget.selectedId;
          final envInfo = cat.allocationId != null
              ? widget.envelopeInfo[cat.allocationId]
              : null;
          return FilterChip(
            selected: isSelected,
            showCheckmark: false,
            avatar: CircleAvatar(radius: 8, backgroundColor: color),
            label: envInfo != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(cat.name),
                      Text(envInfo,
                          style: TextStyle(
                              fontSize: 9,
                              color: color.withValues(alpha: 0.7))),
                    ],
                  )
                : Text(cat.name),
            backgroundColor: color.withValues(alpha: 0.08),
            selectedColor: color.withValues(alpha: 0.22),
            side: BorderSide(
              color: isSelected ? color : color.withValues(alpha: 0.3),
              width: isSelected ? 1.5 : 1,
            ),
            labelStyle: TextStyle(
              color: color,
              fontWeight:
                  isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
            onSelected: (_) => widget.onSelected(
                cat.id, cat.name, color, cat.transactionType),
          );
        }).toList(),
      ),
    );
  }

  void _submitNew(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    widget.onCreated(trimmed);
    setState(() {
      _creating = false;
      _newCatCtrl.clear();
    });
  }
}
