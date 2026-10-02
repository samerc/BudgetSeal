import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/daos/allocations_dao.dart';
import '../../core/providers/allocations_provider.dart';
import '../../core/providers/database_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/theme/app_colors.dart';

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
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(20, 20, 12, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(tr.allocReorderTitle,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w800)),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(tr.commonSave),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(tr.allocReorderHint,
                    style:
                        TextStyle(fontSize: 13, color: AppColors.ts(ctx))),
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
                      leading: CircleAvatar(
                        backgroundColor: AppColors.sfv(ctx),
                        child: Text(
                          (it.icon?.isNotEmpty ?? false)
                              ? it.icon!
                              : it.name.characters.first.toUpperCase(),
                          style: TextStyle(color: AppColors.tp(ctx)),
                        ),
                      ),
                      title: Text(it.name),
                      trailing: ReorderableDragStartListener(
                        index: i,
                        child: Icon(Icons.drag_handle_rounded,
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
  } catch (e) {
    debugPrint('[ReorderEnvelopes] Save failed: $e');
    messenger.showSnackBar(SnackBar(
      content: Text(tr.commonSomethingWentWrong),
      behavior: SnackBarBehavior.floating,
    ));
  }
}
