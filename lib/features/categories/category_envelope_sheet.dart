import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' show Value;

import '../../core/database/app_database.dart';
import '../../core/database/daos/allocations_dao.dart';
import '../../core/providers/allocations_provider.dart';
import '../../core/providers/categories_provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_icons.dart';
import '../../shared/theme/design_tokens.dart';
import '../../shared/widgets/category_icon.dart';
import '../../shared/widgets/sheet_title.dart';

/// Category → envelope link from the category side: pick an envelope,
/// unlink, or create a new spending envelope named after the category
/// (then opened so a target can be set).
Future<void> showCategoryEnvelopeSheet(
    BuildContext context, Category cat) async {
  final container = ProviderScope.containerOf(context);
  final tr = S.of(context);
  final router = GoRouter.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final allocations = container.read(allocationsProvider).value ?? const [];

  // '' = unlink, '+' = create, else an allocation id.
  final picked = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: ConstrainedBox(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.7),
        child: ListView(
          shrinkWrap: true,
          children: [
            SheetTitle(tr.catLinkEnvelopeTitle(cat.name)),
            if (cat.allocationId == null)
              ListTile(
                leading: const Icon(AppIcons.plusCircle),
                title: Text(tr.catCreateEnvelope(cat.name)),
                onTap: () => Navigator.pop(ctx, '+'),
              ),
            for (final a in allocations)
              ListTile(
                leading: CategoryIcon(
                  categoryName: a.data.allocation.name,
                  emoji: a.data.allocation.icon,
                  color: AppColors.accent,
                  size: CategoryIconTokens.compactSize,
                  circular: true,
                ),
                title: Text(a.data.allocation.name),
                selected: a.data.allocation.id == cat.allocationId,
                trailing: a.data.allocation.id == cat.allocationId
                    ? const Icon(AppIcons.check)
                    : null,
                onTap: () => Navigator.pop(ctx, a.data.allocation.id),
              ),
            if (cat.allocationId != null)
              ListTile(
                leading: const Icon(AppIcons.linkBreak),
                title: Text(tr.catUnlinkEnvelope),
                onTap: () => Navigator.pop(ctx, ''),
              ),
          ],
        ),
      ),
    ),
  );
  if (picked == null) return;

  final db = container.read(databaseProvider);
  final dao = AllocationsDao(db);
  void show(String text) => messenger.showSnackBar(SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
      ));
  try {
    if (picked.isEmpty) {
      await dao.unlinkCategory(cat.id);
      show(tr.catEnvelopeUnlinked);
    } else if (picked == '+') {
      final household = container.read(householdProvider).value;
      if (household == null) return;
      final id = const Uuid().v4();
      final hasEmoji = cat.icon.length <= 4 && cat.icon != 'category';
      await dao.upsert(AllocationsCompanion.insert(
        id: id,
        householdId: household.id,
        name: cat.name,
        categoryId: id, // legacy column; the link is categories.allocationId
        icon: Value(hasEmoji ? cat.icon : null),
        targetCurrency: Value(household.baseCurrency),
        deviceId: 'local',
      ));
      await dao.linkCategory(cat.id, id);
      container.invalidate(allocationsProvider);
      container.invalidate(categoriesProvider);
      show(tr.allocEnvelopeCreated);
      router.push('/allocations/$id');
      return;
    } else {
      await dao.linkCategory(cat.id, picked);
      final name = allocations
              .where((a) => a.data.allocation.id == picked)
              .firstOrNull
              ?.data
              .allocation
              .name ??
          '';
      show(tr.catEnvelopeLinked(name));
    }
    container.invalidate(allocationsProvider);
    container.invalidate(categoriesProvider);
  } catch (e) {
    debugPrint('[CategoryEnvelope] Failed: $e');
    show(tr.commonSomethingWentWrong);
  }
}
