import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/database/app_database.dart';
import '../theme/app_colors.dart';

/// Full-screen category grid for the assisted transaction flow.
class CategoryGrid extends StatelessWidget {
  final List<Category> categories;
  final String selectedType; // 'expense' | 'income'
  final ValueChanged<String> onTypeChanged;
  final void Function(Category category) onSelected;
  final VoidCallback onCreateNew;

  const CategoryGrid({
    super.key,
    required this.categories,
    required this.selectedType,
    required this.onTypeChanged,
    required this.onSelected,
    required this.onCreateNew,
  });

  Color _hexToColor(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    // Filter by type and get subcategories (or standalone)
    final filtered = categories
        .where((c) => c.transactionType == selectedType)
        .toList();

    // Separate groups and subs
    final groups = filtered.where((c) => c.parentId == null).toList();
    final subsByParent = <String, List<Category>>{};
    for (final c in filtered) {
      if (c.parentId != null) {
        subsByParent.putIfAbsent(c.parentId!, () => []).add(c);
      }
    }

    // Build flat list of selectable categories
    final selectableCategories = <Category>[];
    for (final group in groups) {
      final subs = subsByParent[group.id] ?? [];
      if (subs.isEmpty) {
        selectableCategories.add(group);
      } else {
        selectableCategories.addAll(subs);
      }
    }

    return Column(
      children: [
        // Type toggle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              _TypeTab(
                label: 'Expense',
                isSelected: selectedType == 'expense',
                onTap: () => onTypeChanged('expense'),
              ),
              const SizedBox(width: 8),
              _TypeTab(
                label: 'Income',
                isSelected: selectedType == 'income',
                onTap: () => onTypeChanged('income'),
              ),
            ],
          ),
        ),
        // Category grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 0.85,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: selectableCategories.length + 1, // +1 for "add new"
            itemBuilder: (_, i) {
              if (i == selectableCategories.length) {
                return _AddNewTile(onTap: onCreateNew);
              }
              final cat = selectableCategories[i];
              final color = _hexToColor(cat.colorHex);
              final hasEmoji =
                  cat.icon.length <= 4 && cat.icon != 'category';

              return _CategoryTile(
                label: cat.name,
                emoji: hasEmoji ? cat.icon : null,
                color: color,
                onTap: () {
                  HapticFeedback.lightImpact();
                  onSelected(cat);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TypeTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.accent
                : AppColors.sfv(context),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.ts(context),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final String label;
  final String? emoji;
  final Color color;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.label,
    this.emoji,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: emoji != null
                  ? Text(emoji!, style: const TextStyle(fontSize: 26))
                  : Icon(Icons.label_rounded, color: color, size: 26),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.tp(context),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _AddNewTile extends StatelessWidget {
  final VoidCallback onTap;
  const _AddNewTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.sfv(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AppColors.bd(context), style: BorderStyle.solid),
            ),
            child: Icon(Icons.add_rounded,
                size: 24, color: AppColors.ts(context)),
          ),
          const SizedBox(height: 6),
          Text(
            'New',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.ts(context),
            ),
          ),
        ],
      ),
    );
  }
}
