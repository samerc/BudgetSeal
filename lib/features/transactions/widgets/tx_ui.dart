import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/accounts_provider.dart';
import '../../../core/providers/date_format_provider.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_icons.dart';
import '../../../shared/theme/design_tokens.dart';
import '../../../shared/utils/format_number.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/sheet_title.dart';

/// Hero amount on the add form band, the detail band, the assisted amount
/// step and the bill splitter total — one size so view and edit match.
const double kHeroAmountSize = 40;

/// First letter upper-cased: month and weekday names come lower-case from
/// intl in French ("janvier", "lundi").
String capitalizedFirst(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// The one account picker of the transaction screens: a theme sheet of
/// ListTile rows (wallet icon, name, balance in the account's currency).
///
/// [allLabel] adds a first "All accounts" row that returns ''; [addLabel]
/// adds a last "Add account" row that returns [kAddAccountPick]. Returns the
/// picked account id, or null when dismissed.
Future<String?> showAccountPickerSheet(
  BuildContext context, {
  required List<Account> accounts,
  String? title,
  String? selectedId,
  String? allLabel,
  String? addLabel,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _AccountPickerSheet(
      accounts: accounts,
      title: title,
      selectedId: selectedId,
      allLabel: allLabel,
      addLabel: addLabel,
    ),
  );
}

/// What [showAccountPickerSheet] returns for its "Add account" row.
const String kAddAccountPick = '+new';

class _AccountPickerSheet extends ConsumerWidget {
  const _AccountPickerSheet({
    required this.accounts,
    this.title,
    this.selectedId,
    this.allLabel,
    this.addLabel,
  });

  final List<Account> accounts;
  final String? title;
  final String? selectedId;
  final String? allLabel;
  final String? addLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balances = {
      for (final ab in ref.watch(accountsWithBalanceProvider).value ?? [])
        ab.account.id: ab.balance
    };
    Widget? check(bool on) => on
        ? Icon(AppIcons.check, size: 20, color: AppColors.accentText(context))
        : null;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.75),
        child: ListView(
          shrinkWrap: true,
          children: [
            if (title != null) SheetTitle(title!),
            if (allLabel != null)
              ListTile(
                leading: const Icon(AppIcons.infinity),
                title: Text(allLabel!),
                trailing: check(selectedId == null || selectedId!.isEmpty),
                onTap: () => Navigator.pop(context, ''),
              ),
            for (final a in accounts)
              ListTile(
                leading:
                    Icon(a.isTravel ? AppIcons.airplane : AppIcons.wallet),
                title: Text(a.name,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: balances[a.id] == null
                    ? Text(a.currency)
                    : Text(
                        formatAmount(balances[a.id]!, currency: a.currency),
                        style: balances[a.id]! < 0
                            ? const TextStyle(color: AppColors.overspent)
                            : null),
                trailing: check(a.id == selectedId),
                onTap: () => Navigator.pop(context, a.id),
              ),
            if (addLabel != null)
              ListTile(
                leading: Icon(AppIcons.plus,
                    color: AppColors.accentText(context)),
                title: Text(addLabel!,
                    style: TextStyle(color: AppColors.accentText(context))),
                onTap: () => Navigator.pop(context, kAddAccountPick),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// "Discard transaction?" when leaving a form with unsaved changes — the
/// classic form and the assisted flow ask the same way.
Future<bool> confirmDiscardTransaction(BuildContext context) {
  final tr = S.of(context);
  return showConfirmDialog(
    context,
    title: tr.txAfDiscardTitle,
    message: tr.txAfDiscardContent,
    cancelLabel: tr.txAfKeepEditing,
    confirmLabel: tr.txAfDiscard,
  );
}

/// "Possible duplicate": shows the transaction that looks the same so the
/// user can compare before saving. Both add forms use it.
Future<bool> confirmDuplicateTransaction(
    BuildContext context, Transaction match) {
  final tr = S.of(context);
  final note = match.note.isNotEmpty ? match.note : tr.txFormNoTitle;
  final amount = formatAmount(match.amount, currency: match.currency);
  final date = formatDate(match.createdAt);
  return showConfirmDialog(
    context,
    title: tr.txFormDuplicateTitle,
    confirmLabel: tr.commonSaveAnyway,
    destructive: false,
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tr.txFormDuplicateSimilarExists),
        const SizedBox(height: Spacing.md),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(Spacing.md),
          decoration: BoxDecoration(
            color: AppColors.sfv(context),
            borderRadius: BorderRadius.circular(RadiusTokens.md),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(note, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: Spacing.xs),
              Text('$amount  •  $date',
                  style: TextStyle(
                      fontSize: TypographyTokens.amountSmallSize,
                      color: AppColors.ts(context))),
            ],
          ),
        ),
        const SizedBox(height: Spacing.md),
        Text(tr.txFormDuplicateSaveAnyway),
      ],
    ),
  );
}
