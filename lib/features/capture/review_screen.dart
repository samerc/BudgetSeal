import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/capture/bank_alerts.dart';
import '../../core/capture/capture_rules.dart';
import '../../core/capture/share_intake.dart';
import '../../core/capture/text_reader.dart';
import '../../core/database/app_database.dart';
import '../../core/providers/categories_provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/date_format_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_icons.dart';
import '../../shared/utils/format_number.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/tappable.dart';

/// One alert as it will be filled in.
typedef _Row = ({AlertItem item, CaptureDraft draft, String? categoryId});

/// "To review" (roadmap #2): payments read from bank notifications, each
/// with what was read (and the category a rule gives it). Add opens the
/// form filled in — saving it removes the alert; Dismiss drops it (Undo).
class ReviewScreen extends ConsumerWidget {
  const ReviewScreen({super.key});

  Future<List<_Row>> _rows(WidgetRef ref, List<AlertItem> items) async {
    final db = ref.read(databaseProvider);
    final householdId = ref.read(currentHouseholdIdProvider) ?? '';
    final base = ref.read(householdProvider).value?.baseCurrency ?? 'USD';
    return [
      for (final item in items)
        await () async {
          final draft = readCapturedText(item.fullText,
              fallbackCurrency: base,
              amountIndex: await BankAlerts.amountIndex(item.app));
          final rule = await findCaptureRule(db, householdId,
              [draft.merchant ?? '', item.fullText].join(' '));
          return (item: item, draft: draft, categoryId: rule?.categoryId);
        }(),
    ];
  }

  Future<void> _add(BuildContext context, WidgetRef ref, AlertItem item) async {
    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null) return;
    try {
      final args = await alertFormArgs(item,
          db: ref.read(databaseProvider),
          householdId: householdId,
          baseCurrency:
              ref.read(householdProvider).value?.baseCurrency ?? 'USD');
      if (context.mounted) await context.push('/add-transaction', extra: args);
      ref.invalidate(alertInboxProvider);
    } catch (e) {
      debugPrint('[Review] Opening failed: $e');
    }
  }

  void _dismiss(BuildContext context, WidgetRef ref, AlertItem item) {
    final tr = S.of(context);
    final inbox = ref.read(alertInboxProvider.notifier);
    inbox.dismiss(item);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(tr.reviewDismissed),
        behavior: SnackBarBehavior.floating,
        persist: false,
        action: SnackBarAction(
            label: tr.txUndoAction, onPressed: () => inbox.undoDismiss(item)),
      ));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = S.of(context);
    final items = ref.watch(alertInboxProvider).value ?? const <AlertItem>[];
    final cats = {
      for (final c in ref.watch(categoriesProvider).value ?? const <Category>[])
        c.id: c.name
    };
    return Scaffold(
      appBar: AppBar(title: Text(tr.reviewTitle)),
      body: FutureBuilder<List<_Row>>(
        future: _rows(ref, items),
        builder: (context, snap) {
          final rows = snap.data ?? const <_Row>[];
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                child: Text(tr.reviewIntro,
                    style:
                        TextStyle(fontSize: 13.5, color: AppColors.ts(context))),
              ),
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child:
                      EmptyState(icon: AppIcons.tray, title: tr.reviewEmpty),
                ),
              for (final r in rows)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
                  decoration: AppColors.card(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '${r.item.appName} · ${formatDateSmart(r.item.at)}',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.th(context)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        r.draft.amount == null
                            ? tr.reviewNoAmount
                            : formatSignedAmount(r.draft.amount!,
                                currency: r.draft.currency ?? '', type: r.draft.type),
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        [
                          if (r.draft.merchant != null) r.draft.merchant!,
                          if (cats[r.categoryId] case final c?) c,
                        ].join(' · '),
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(r.item.text,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 12.5, color: AppColors.ts(context))),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => _dismiss(context, ref, r.item),
                            style: TextButton.styleFrom(
                                minimumSize: const Size(0, 40)),
                            child: Text(tr.reviewDismiss),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: () => _add(context, ref, r.item),
                            style: FilledButton.styleFrom(
                                minimumSize: const Size(0, 40)),
                            child: Text(tr.reviewAdd),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Home: "N payments to review" while bank alerts wait (Android).
class ReviewAlertsCard extends ConsumerWidget {
  const ReviewAlertsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!BankAlerts.supported) return const SizedBox.shrink();
    final n = ref.watch(alertInboxProvider).value?.length ?? 0;
    if (n == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Tappable(
        onTap: () => context.push('/review'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.accentLight,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(children: [
            Icon(AppIcons.tray, size: 20, color: AppColors.accent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(S.of(context).reviewCard(n),
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent)),
            ),
            Icon(AppIcons.caretRight, size: 18, color: AppColors.accent),
          ]),
        ),
      ),
    );
  }
}
