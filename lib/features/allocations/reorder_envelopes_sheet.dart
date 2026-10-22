import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/daos/allocations_dao.dart';
import '../../core/providers/allocations_provider.dart';
import '../../core/providers/database_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/design_tokens.dart';
import '../../shared/theme/app_icons.dart';
import '../../shared/widgets/category_icon.dart';
import '../../shared/widgets/sheet_title.dart';

/// Budget tab ⋮ → Reorder envelopes: drag to set the order the Budget tab
/// (and funding screen) list envelopes in.
Future<void> showReorderEnvelopesSheet(
    BuildContext context, WidgetRef ref) async {
  final tr = S.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final allocations = ref.read(allocationsProvider).value ?? const [];
  if (allocations.isEmpty) return;
  final items = [
    for (final a in allocations)
      (id: a.data.allocation.id, name: a.data.allocation.name,
          icon: a.data.allocation.icon),
  ];

  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheet) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
              minWidth: double.infinity,
              maxHeight: MediaQuery.of(ctx).size.height * 0.8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SheetTitle(
                tr.allocReorderTitle,
                subtitle: tr.allocReorderHint,
                trailing: FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  // The theme's minimum size is full-width; in a Row
                  // that would be infinite.
                  style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 18)),
                  child: Text(tr.commonSave),
                ),
              ),
              Flexible(
                child: ReorderableListView.builder(
                  shrinkWrap: true,
                  buildDefaultDragHandles: false,
                  itemCount: items.length,
                  onReorderItem: (from, to) => setSheet(() {
                    final item = items.removeAt(from);
                    items.insert(to, item);
                  }),
                  itemBuilder: (_, i) {
                    final it = items[i];
                    return ListTile(
                      key: ValueKey(it.id),
                      leading: CategoryIcon(
                        categoryName: it.name,
                        emoji: it.icon,
                        color: AppColors.accent,
                        size: CategoryIconTokens.compactSize,
                        circular: true,
                      ),
                      title: Text(it.name),
                      trailing: ReorderableDragStartListener(
                        index: i,
                        child: Icon(AppIcons.dotsSixVertical,
                            color: AppColors.th(ctx)),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  if (saved != true) return;
  try {
    await AllocationsDao(ref.read(databaseProvider))
        .saveOrder([for (final it in items) it.id]);
    ref.invalidate(allocationsProvider);
    messenger.showSnackBar(SnackBar(
      content: Text(tr.allocOrderSaved),
      behavior: SnackBarBehavior.floating,
    ));
  } catch (e) {
    debugPrint('[ReorderEnvelopes] Save failed: $e');
    messenger.showSnackBar(SnackBar(
      content: Text(tr.commonSomethingWentWrong),
      behavior: SnackBarBehavior.floating,
    ));
  }
}
