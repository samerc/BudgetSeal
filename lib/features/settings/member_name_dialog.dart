import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/database_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../core/providers/member_names_provider.dart';
import '../../core/services/household_members.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_icons.dart';
import '../../shared/theme/design_tokens.dart';

/// Asks this device's name once the budget is shared (see
/// [HouseholdMembers.shouldAsk]); does nothing otherwise.
Future<void> askMemberNameIfNeeded(BuildContext context, WidgetRef ref) async {
  final householdId = ref.read(currentHouseholdIdProvider);
  if (householdId == null) return;
  final db = ref.read(databaseProvider);
  try {
    if (!await HouseholdMembers.shouldAsk(db, householdId)) return;
  } catch (e) {
    debugPrint('[Members] Check failed: $e');
    return;
  }
  if (!context.mounted) return;
  await showMemberNameDialog(context, ref, firstTime: true);
}

/// The name dialog: first time ("Others use this budget too", with
/// "Just me") or from Settings (rename).
Future<void> showMemberNameDialog(BuildContext context, WidgetRef ref,
    {bool firstTime = false, String initial = ''}) async {
  final tr = S.of(context);
  final householdId = ref.read(currentHouseholdIdProvider);
  if (householdId == null) return;
  final db = ref.read(databaseProvider);
  final messenger = ScaffoldMessenger.of(context);
  final ctrl = TextEditingController(text: initial);
  final name = await showDialog<String>(
    context: context,
    barrierDismissible: !firstTime,
    builder: (ctx) => AlertDialog(
      scrollable: true,
      icon: firstTime
          ? Icon(AppIcons.users, size: 48, color: AppColors.accent)
          : null,
      title: Text(firstTime ? tr.memberAskTitle : tr.memberYourName,
          textAlign: firstTime ? TextAlign.center : null),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(tr.memberAskBody,
              style: TextStyle(fontSize: 14, color: AppColors.ts(ctx))),
          const SizedBox(height: 16),
          TextField(
            controller: ctrl,
            autofocus: true,
            maxLength: 30,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(labelText: tr.memberYourName),
            onSubmitted: (v) => Navigator.pop(ctx, v),
          ),
        ],
      ),
      actions: [
        OutlinedButton(
          style: DialogButtons.outlined,
          onPressed: () => Navigator.pop(ctx, firstTime ? '' : null),
          child: Text(firstTime ? tr.memberJustMe : tr.commonCancel),
        ),
        FilledButton(
          style: DialogButtons.filled,
          onPressed: () => Navigator.pop(ctx, ctrl.text),
          child: Text(tr.commonSave),
        ),
      ],
    ),
  );
  ctrl.dispose();
  if (name == null) return;
  try {
    if (name.trim().isEmpty) {
      if (firstTime) await HouseholdMembers.skip(db, householdId);
      return;
    }
    await HouseholdMembers.setMyName(db, householdId, name);
    ref.invalidate(memberNamesProvider);
    messenger.showSnackBar(SnackBar(
      content: Text(tr.memberSaved(name.trim())),
      behavior: SnackBarBehavior.floating,
    ));
  } catch (e) {
    debugPrint('[Members] Save failed: $e');
    messenger.showSnackBar(SnackBar(
      content: Text(tr.commonSomethingWentWrong),
      behavior: SnackBarBehavior.floating,
    ));
  }
}
