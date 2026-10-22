import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/database/daos/allocations_dao.dart';
import '../../core/providers/allocations_provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/design_tokens.dart';
import '../../shared/theme/app_icons.dart';
import '../../shared/widgets/category_icon.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/sheet_title.dart';

/// Lists archived envelopes with an Unarchive action (Budget tab menu).
Future<void> showArchivedEnvelopesSheet(
    BuildContext context, WidgetRef ref) async {
  final tr = S.of(context);
  final db = ref.read(databaseProvider);
  final householdId = ref.read(currentHouseholdIdProvider);
  if (householdId == null) return;
  final dao = AllocationsDao(db);
  final archived = await dao.archivedFor(householdId);
  if (!context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);

  final restored = await showModalBottomSheet<Allocation>(
    context: context,
    isScrollControlled: true,
    builder: (sheetCtx) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
            minWidth: double.infinity,
            maxHeight: MediaQuery.of(sheetCtx).size.height * 0.7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SheetTitle(tr.allocArchivedTitle),
            if (archived.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: EmptyState(
                  icon: AppIcons.archive,
                  title: tr.allocNoArchived,
                ),
              )
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(bottom: 12),
                  children: [
                    for (final a in archived)
                      ListTile(
                        leading: CategoryIcon(
                          categoryName: a.name,
                          emoji: a.icon,
                          color: AppColors.accent,
                          size: CategoryIconTokens.compactSize,
                          circular: true,
                        ),
                        title: Text(a.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        trailing: TextButton(
                          onPressed: () => Navigator.pop(sheetCtx, a),
                          child: Text(tr.acctUnarchive),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ),
  );

  if (restored == null) return;
  try {
    await dao.unarchive(restored.id);
    ref.invalidate(allocationsProvider);
    messenger.showSnackBar(SnackBar(
      content: Text(tr.allocUnarchived(restored.name)),
      behavior: SnackBarBehavior.floating,
    ));
  } catch (e) {
    debugPrint('[ArchivedEnvelopes] Unarchive failed: $e');
    messenger.showSnackBar(SnackBar(
      content: Text(tr.commonSomethingWentWrong),
      behavior: SnackBarBehavior.floating,
    ));
  }
}
