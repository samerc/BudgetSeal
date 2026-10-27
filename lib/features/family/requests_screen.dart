import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/database/app_database.dart';
import '../../core/providers/allocations_provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/family_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../core/providers/member_names_provider.dart';
import '../../core/providers/transactions_provider.dart';
import '../../core/services/family_service.dart';
import '../../core/services/household_members.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_icons.dart';
import '../../shared/utils/format_number.dart';
import '../../shared/widgets/calculator_amount_field.dart';
import '../../shared/widgets/envelope_row.dart';
import '../../shared/widgets/tappable.dart';
import '../transactions/widgets/tx_tile.dart';

/// The household's money requests, newest first (roadmap #5).
final moneyRequestsProvider = StreamProvider<List<MoneyRequest>>((ref) {
  final householdId = ref.watch(currentHouseholdIdProvider);
  if (householdId == null) return Stream.value(const []);
  final db = ref.watch(databaseProvider);
  return (db.select(db.moneyRequests)
        ..where((r) =>
            r.householdId.equals(householdId) & r.deleted.equals(false))
        ..orderBy([(r) => OrderingTerm.desc(r.createdAt)]))
      .watch();
});

/// Money requests (roadmap #5; user's decision: kids ask, grown-ups
/// approve). A grown-up sees the open ones with Approve (funds the kid's
/// envelope from Ready to assign) / Decline, then the earlier ones; a kid
/// asks for money into one of their envelopes and sees theirs.
class RequestsScreen extends ConsumerStatefulWidget {
  const RequestsScreen({super.key});

  @override
  ConsumerState<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends ConsumerState<RequestsScreen> {
  final _noteCtrl = TextEditingController();
  String? _envelopeId;
  double _amount = 0;
  bool _busy = false;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  void _snack(String text) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating));

  Future<void> _decide(MoneyRequest r, bool approve) async {
    final tr = S.of(context);
    setState(() => _busy = true);
    try {
      final service = FamilyService(ref.read(databaseProvider));
      final done =
          approve ? await service.approve(r.id) : await service.decline(r.id);
      if (done) _snack(approve ? tr.reqApproved : tr.reqDeclined);
      ref.invalidate(allocationsProvider);
      ref.invalidate(unallocatedProvider);
    } catch (e) {
      debugPrint('[Requests] Deciding failed: $e');
      _snack(tr.commonSomethingWentWrong);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _ask(List<AllocationWithBalance> mine, String base) async {
    final tr = S.of(context);
    final householdId = ref.read(currentHouseholdIdProvider);
    final env = mine.where((a) => a.data.allocation.id == _envelopeId).firstOrNull ??
        mine.firstOrNull;
    if (householdId == null || env == null || _amount <= 0) return;
    setState(() => _busy = true);
    try {
      await FamilyService(ref.read(databaseProvider)).ask(
        householdId: householdId,
        allocationId: env.data.allocation.id,
        amount: _amount,
        currency: env.data.allocation.targetCurrency ?? base,
        note: _noteCtrl.text.trim(),
      );
      _noteCtrl.clear();
      setState(() => _amount = 0);
      _snack(tr.reqSent);
    } catch (e) {
      debugPrint('[Requests] Asking failed: $e');
      _snack(tr.commonSomethingWentWrong);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = S.of(context);
    final kid = ref.watch(amKidProvider);
    final base = ref.watch(householdProvider).value?.baseCurrency ?? 'USD';
    final names = ref.watch(memberNamesProvider).value ?? const {};
    final envelopes = {
      for (final a in ref.watch(allocationsProvider).value ?? const [])
        a.data.allocation.id: a.data.allocation.name
    };
    final all = ref.watch(moneyRequestsProvider).value ?? const [];
    final requests =
        kid ? [for (final r in all) if (r.fromDeviceId == DeviceIdentity.id) r] : all;
    final open = [for (final r in requests) if (r.status == 'open') r];
    final past = [for (final r in requests) if (r.status != 'open') r];
    final mine = ref.watch(visibleAllocationsProvider).value ?? const [];

    Widget card(MoneyRequest r) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
          decoration: AppColors.card(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                tr.reqAsked(names[r.fromDeviceId] ?? '?',
                    formatAmount(r.amount, currency: r.currency)),
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700),
              ),
              Text(
                [
                  tr.reqInto(envelopes[r.allocationId] ?? '?'),
                  if (r.note.isNotEmpty) '“${r.note}”',
                ].join(' · '),
                style: TextStyle(fontSize: 13.5, color: AppColors.ts(context)),
              ),
              if (r.status == 'open' && !kid)
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 4),
                  child: Row(children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _busy ? null : () => _decide(r, false),
                        style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 44)),
                        child: Text(tr.reqDecline),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: _busy ? null : () => _decide(r, true),
                        style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 44)),
                        child: Text(tr.reqApprove),
                      ),
                    ),
                  ]),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 4),
                  child: Text(
                    switch (r.status) {
                      'approved' => tr.reqApproved,
                      'declined' => tr.reqDeclined,
                      _ => tr.reqWaiting,
                    },
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: switch (r.status) {
                        'approved' => AppColors.healthy,
                        'declined' => AppColors.overspent,
                        _ => AppColors.ts(context),
                      },
                    ),
                  ),
                ),
            ],
          ),
        );

    Widget header(String t) => Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(4, 16, 4, 8),
          child: Text(t,
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        );

    return Scaffold(
      appBar: AppBar(title: Text(tr.reqTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          if (kid) ...[
            header(tr.reqAsk),
            if (mine.isEmpty)
              Text(tr.reqNoEnvelope,
                  style: TextStyle(color: AppColors.ts(context)))
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: AppColors.card(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CalculatorAmountField(
                      value: _amount,
                      fontSize: 22,
                      onChanged: (v) => setState(() => _amount = v),
                    ),
                    const SizedBox(height: 12),
                    Text(tr.reqFor,
                        style: TextStyle(
                            fontSize: 12.5, color: AppColors.ts(context))),
                    Wrap(spacing: 8, children: [
                      for (final a in mine)
                        ChoiceChip(
                          label: Text(a.data.allocation.name),
                          selected: (_envelopeId ?? mine.first.data.allocation.id) ==
                              a.data.allocation.id,
                          onSelected: (_) => setState(
                              () => _envelopeId = a.data.allocation.id),
                        ),
                    ]),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _noteCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(hintText: tr.reqNoteHint),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _busy || _amount <= 0
                          ? null
                          : () => _ask(mine, base),
                      child: Text(tr.reqSend),
                    ),
                  ],
                ),
              ),
          ],
          if (!kid) header(tr.reqOpen),
          if (!kid && open.isEmpty)
            Text(tr.reqNone, style: TextStyle(color: AppColors.ts(context))),
          for (final r in kid ? requests : open) card(r),
          if (!kid && past.isNotEmpty) ...[
            header(tr.reqPast),
            for (final r in past.take(20)) card(r),
          ],
        ],
      ),
    );
  }
}

/// Home (grown-ups): "N money requests" while kids wait for an answer.
class RequestsCard extends ConsumerWidget {
  const RequestsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(amKidProvider)) return const SizedBox.shrink();
    final n = (ref.watch(moneyRequestsProvider).value ?? const [])
        .where((r) => r.status == 'open')
        .length;
    if (n == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Tappable(
        onTap: () => context.push('/requests'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.accentLight,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(children: [
            Icon(AppIcons.coins, size: 20, color: AppColors.accent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(S.of(context).reqCard(n),
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

/// A kid's phone (user's decision: only their own envelopes): what's left
/// in each, add spending, ask for money, their spending — no accounts,
/// other envelopes or settings.
class KidHomeScreen extends ConsumerWidget {
  const KidHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = S.of(context);
    final base = ref.watch(householdProvider).value?.baseCurrency ?? 'USD';
    final mine = ref.watch(visibleAllocationsProvider).value ?? const [];
    final spending = ref.watch(periodSpendingProvider).value ?? const {};
    final myIds = {for (final a in mine) a.data.allocation.id};
    final hidden = ref.watch(hiddenCategoryIdsProvider);
    final recent = [
      for (final e in ref.watch(recentTransactionsProvider).value ?? const [])
        if (!e.isPrivate &&
            e.lines.any((l) => l.categoryId != null && !hidden.contains(l.categoryId)))
          e,
    ];
    final name = ref.watch(memberNamesProvider).value?[DeviceIdentity.id];
    return Scaffold(
      appBar: AppBar(title: Text(name ?? tr.kidMyEnvelopes)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // Stacked: side by side they don't fit a small phone with large
          // text.
          FilledButton.icon(
            onPressed: () => context
                .push('/add-transaction', extra: {'editType': 'expense'}),
            icon: const Icon(AppIcons.plus, size: 20),
            label: Text(tr.kidAddSpending),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => context.push('/requests'),
            icon: const Icon(AppIcons.coins, size: 20),
            label: Text(tr.reqAsk),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(4, 20, 4, 8),
            child: Text(tr.kidMyEnvelopes,
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ),
          if (mine.isEmpty)
            Text(tr.reqNoEnvelope, style: TextStyle(color: AppColors.ts(context)))
          else
            Container(
              decoration: AppColors.card(context),
              clipBehavior: Clip.antiAlias,
              child: Column(children: [
                for (final a in mine)
                  EnvelopeRow(
                    name: a.data.allocation.name,
                    type: a.data.allocation.type,
                    balanceByCurrency: a.balanceByCurrency,
                    baseCurrency: base,
                    targetAmount: a.data.allocation.targetAmount,
                    targetCurrency: a.data.allocation.targetCurrency,
                    envelopeIcon: a.data.allocation.icon,
                    spent: spending[a.data.allocation.id]
                            ?[a.data.allocation.targetCurrency ?? base] ??
                        0,
                  ),
              ]),
            ),
          if (recent.isNotEmpty && myIds.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(4, 20, 4, 8),
              child: Text(tr.kidRecent,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700)),
            ),
            Container(
              decoration: AppColors.card(context),
              clipBehavior: Clip.antiAlias,
              child: Column(children: [
                for (final e in recent)
                  TxTile(entry: e, categoryMap: const {}, showBalance: false,
                      showDate: true),
              ]),
            ),
          ],
        ],
      ),
    );
  }
}
