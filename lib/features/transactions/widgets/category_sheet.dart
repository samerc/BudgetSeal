import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/category_icon.dart';

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

class _CategorySheetState extends State<CategorySheet>
    with WidgetsBindingObserver {
  bool _creating = false;
  final _newCatCtrl = TextEditingController();
  final _sheetCtrl = DraggableScrollableController();
  String _search = '';
  String _typeFilter = 'expense'; // 'expense' or 'income'
  bool _keyboardVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sheetCtrl.dispose();
    _newCatCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    final bottomInset =
        WidgetsBinding.instance.platformDispatcher.views.first.viewInsets.bottom;
    final nowVisible = bottomInset > 100;
    if (nowVisible && !_keyboardVisible) {
      _keyboardVisible = true;
      // Expand sheet to max so results are visible above the keyboard
      if (_sheetCtrl.isAttached) {
        _sheetCtrl.animateTo(0.92,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut);
      }
    } else if (!nowVisible && _keyboardVisible) {
      _keyboardVisible = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter by type
    var filtered = widget.categories
        .where((c) => c.transactionType == _typeFilter)
        .toList();

    // Build parent/sub structure
    final allParents = filtered.where((c) => c.parentId == null).toList();
    final allSubsByParent = <String, List<Category>>{};
    for (final c in filtered) {
      if (c.parentId != null) {
        allSubsByParent.putIfAbsent(c.parentId!, () => []).add(c);
      }
    }

    // Apply search
    List<Category> parents;
    Map<String, List<Category>> subsByParent;
    if (_search.isEmpty) {
      parents = allParents;
      subsByParent = allSubsByParent;
    } else {
      final q = _search.toLowerCase();
      parents = [];
      subsByParent = {};
      for (final p in allParents) {
        final matchingSubs = (allSubsByParent[p.id] ?? [])
            .where((s) => s.name.toLowerCase().contains(q))
            .toList();
        if (p.name.toLowerCase().contains(q) || matchingSubs.isNotEmpty) {
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
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        controller: _sheetCtrl,
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        snap: true,
        snapSizes: const [0.7, 0.92],
        builder: (_, scrollCtrl) => Column(
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
                          color: AppColors.th(context),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Title + New button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(S.of(context).catSheetTitle,
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.tp(context))),
                        if (!_creating)
                          TextButton.icon(
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: Text(S.of(context).catSheetNew),
                            onPressed: () =>
                                setState(() => _creating = true),
                          ),
                      ],
                    ),
                    // New category input
                    if (_creating) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _newCatCtrl,
                              autofocus: true,
                              decoration: InputDecoration(
                                hintText: S.of(context).catSheetCategoryName,
                                isDense: true,
                                filled: true,
                                fillColor: AppColors.sfv(context),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              textCapitalization: TextCapitalization.words,
                              onSubmitted: _submitNew,
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: () => _submitNew(_newCatCtrl.text),
                            style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10)),
                            child: Text(S.of(context).catSheetAdd),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () =>
                                setState(() => _creating = false),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 10),
                    // Type toggle
                    Row(
                      children: [
                        _typeChip(S.of(context).catSheetExpense, 'expense', AppColors.overspent),
                        const SizedBox(width: 8),
                        _typeChip(S.of(context).catSheetIncome, 'income', AppColors.healthy),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Search field
                    TextField(
                      onChanged: (v) => setState(() => _search = v),
                      textInputAction: TextInputAction.search,
                      style: TextStyle(
                          fontSize: 14, color: AppColors.tp(context)),
                      decoration: InputDecoration(
                        hintText: S.of(context).catSheetSearchHint,
                        hintStyle:
                            TextStyle(color: AppColors.th(context)),
                        prefixIcon: Icon(Icons.search_rounded,
                            size: 18, color: AppColors.th(context)),
                        filled: true,
                        fillColor: AppColors.sfv(context),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              Expanded(
                child: parents.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            _search.isNotEmpty
                                ? S.of(context).catSheetNoMatch
                                : S.of(context).catSheetNoCategories,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: AppColors.ts(context)),
                          ),
                        ),
                      )
                    : ListView(
                        controller: scrollCtrl,
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding:
                            const EdgeInsets.fromLTRB(20, 4, 20, 24),
                        children:
                            _buildCategoryList(parents, subsByParent),
                      ),
              ),
            ],
          ),
      ),
    );
  }

  Widget _typeChip(String label, String value, Color color) {
    final selected = _typeFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _typeFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.15)
              : AppColors.sfv(context),
          borderRadius: BorderRadius.circular(20),
          border: selected
              ? Border.all(color: color.withValues(alpha: 0.4))
              : null,
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? color : AppColors.ts(context),
            )),
      ),
    );
  }

  List<Widget> _buildCategoryList(
    List<Category> parents,
    Map<String, List<Category>> subsByParent,
  ) {
    final widgets = <Widget>[];

    for (final group in parents) {
      final subs = subsByParent[group.id] ?? [];
      final groupColor = AppColors.fromHex(group.colorHex);
      final hasEmoji =
          group.icon.length <= 4 && group.icon != 'category';

      // Parent tile
      widgets.add(
        GestureDetector(
          onTap: subs.isEmpty
              ? () => widget.onSelected(
                  group.id, group.name, groupColor, group.transactionType)
              : null,
          child: Container(
            margin: const EdgeInsets.only(top: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: group.id == widget.selectedId
                  ? groupColor.withValues(alpha: 0.12)
                  : null,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                CategoryIcon(
                  categoryName: group.name,
                  emoji: hasEmoji ? group.icon : null,
                  color: groupColor,
                  size: 32,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(group.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.tp(context),
                          )),
                      if (subs.isNotEmpty)
                        Text(S.of(context).catSheetSubcategories(subs.length),
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.ts(context))),
                    ],
                  ),
                ),
                if (group.id == widget.selectedId)
                  Icon(Icons.check_circle_rounded,
                      size: 18, color: groupColor),
              ],
            ),
          ),
        ),
      );

      // Subcategories
      for (final sub in subs) {
        final subColor = AppColors.fromHex(sub.colorHex);
        final subEmoji =
            sub.icon.length <= 4 && sub.icon != 'category';
        widgets.add(
          GestureDetector(
            onTap: () => widget.onSelected(
                sub.id, sub.name, subColor, sub.transactionType),
            child: Container(
              margin: const EdgeInsetsDirectional.only(start: 28),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: sub.id == widget.selectedId
                    ? subColor.withValues(alpha: 0.12)
                    : null,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  CategoryIcon(
                    categoryName: sub.name,
                    emoji: subEmoji ? sub.icon : null,
                    color: subColor,
                    size: 26,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(sub.name,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.tp(context),
                        )),
                  ),
                  if (sub.id == widget.selectedId)
                    Icon(Icons.check_circle_rounded,
                        size: 16, color: subColor),
                ],
              ),
            ),
          ),
        );
      }
    }

    return widgets;
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
