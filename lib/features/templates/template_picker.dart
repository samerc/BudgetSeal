import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/database/app_database.dart';
import '../../core/providers/categories_provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../core/providers/tx_colors_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_icons.dart';
import '../../shared/theme/design_tokens.dart';
import '../../shared/utils/format_number.dart';
import '../../shared/widgets/category_icon.dart';
import '../../shared/widgets/sheet_title.dart';

/// Counts a use of [t] and returns the add-transaction route `extra` that
/// fills the form from it (shared by the Templates screen and the picker).
Future<Map<String, dynamic>> useTemplate(
    WidgetRef ref, TransactionTemplate t) async {
  final db = ref.read(databaseProvider);
  await (db.update(db.transactionTemplates)..where((r) => r.id.equals(t.id)))
      .write(TransactionTemplatesCompanion(
    useCount: Value(t.useCount + 1),
    lastUsedAt: Value(DateTime.now()),
    lastModified: Value(DateTime.now()),
  ));
  final cats = ref.read(categoriesProvider).value ?? [];
  final cat = t.categoryId != null
      ? cats.where((c) => c.id == t.categoryId).firstOrNull
      : null;
  return {
    'editType': t.type,
    'editNote': t.title,
    'editLines': [
      {
        'amount': t.amount,
        'currency': t.currency,
        'accountId': t.accountId,
        'categoryId': t.categoryId,
        'categoryName': cat?.name,
        'note': '',
      }
    ],
  };
}

/// The add form's ⚡ button: pick a template in a sheet, then the form is
/// replaced by one filled from it (any entry mode), keeping the form's
/// [date]. "Manage templates" opens the Templates screen.
Future<void> pickTemplateIntoForm(BuildContext context, WidgetRef ref,
    {DateTime? date}) async {
  final tr = S.of(context);
  final householdId = ref.read(currentHouseholdIdProvider);
  if (householdId == null) return;
  final db = ref.read(databaseProvider);
  List<TransactionTemplate> items;
  try {
    items = await (db.select(db.transactionTemplates)
          ..where((t) =>
              t.householdId.equals(householdId) & t.deleted.equals(false))
          ..orderBy([
            (t) => OrderingTerm.desc(t.useCount),
            (t) => OrderingTerm.asc(t.title),
          ]))
        .get();
  } catch (e) {
    debugPrint('[Templates] Picker load failed: $e');
    items = const [];
  }
  if (!context.mounted) return;
  final picked = await showModalBottomSheet<Object>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _TemplatePickerSheet(items: items, tr: tr),
  );
  if (!context.mounted || picked == null) return;
  if (picked == _manage) {
    context.push('/templates');
    return;
  }
  try {
    final extra = await useTemplate(ref, picked as TransactionTemplate);
    if (date != null) extra['editDate'] = date;
    if (context.mounted) context.pushReplacement('/add-transaction', extra: extra);
  } catch (e) {
    debugPrint('[Templates] Error using template: $e');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(tr.tmplApplyError),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }
}

const _manage = Object();

class _TemplatePickerSheet extends ConsumerWidget {
  final List<TransactionTemplate> items;
  final S tr;
  const _TemplatePickerSheet({required this.items, required this.tr});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cats = {
      for (final c in ref.watch(categoriesProvider).value ?? const <Category>[])
        c.id: c
    };
    final colors = ref.watch(txColorsProvider);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.7;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetTitle(tr.txFormUseTemplate),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Text(tr.tmplPickerEmpty,
                    style: TextStyle(color: AppColors.ts(context))),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final t = items[i];
                    final cat = cats[t.categoryId];
                    return ListTile(
                      leading: CategoryIcon(
                        categoryName: cat?.name ?? t.title,
                        emoji: cat?.icon,
                        color: cat != null
                            ? AppColors.fromHex(cat.colorHex)
                            : colors.forType(t.type),
                        size: CategoryIconTokens.compactSize,
                        circular: true,
                      ),
                      title: Text(t.title,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: cat != null
                          ? Text(cat.name,
                              maxLines: 1, overflow: TextOverflow.ellipsis)
                          : null,
                      trailing: Text(
                        formatSignedAmount(t.amount,
                            currency: t.currency, type: t.type),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: t.type == 'expense'
                              ? AppColors.tp(context)
                              : colors.forType(t.type),
                        ),
                      ),
                      onTap: () => Navigator.pop(context, t),
                    );
                  },
                ),
              ),
            ListTile(
              leading: const Icon(AppIcons.gear),
              title: Text(tr.tmplPickerManage),
              onTap: () => Navigator.pop(context, _manage),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
