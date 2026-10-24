import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/database/app_database.dart';
import '../../core/engine/sinking_fund.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/date_format_provider.dart';
import '../../core/providers/engine_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../core/providers/sinking_fund_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_icons.dart';
import '../../shared/theme/design_tokens.dart';
import '../../shared/utils/calendar_days.dart';
import '../../shared/utils/format_number.dart';
import '../../shared/utils/haptics.dart';
import '../../shared/widgets/category_icon.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/tappable.dart';
import 'option_card.dart';

/// Currencies with the base first, then by code.
List<String> _ordered(Iterable<String> currencies, String base) =>
    currencies.toList()
      ..sort((a, b) => a == base
          ? -1
          : b == base
              ? 1
              : a.compareTo(b));

/// "$500 + LBP 15,000,000": one amount per currency, the base first.
String fundAmounts(Map<String, double> amounts, String base) => [
      for (final c in _ordered(amounts.keys, base))
        formatAmount(amounts[c]!, currency: c)
    ].join(' + ');

/// What a fund still takes this period (by its catch-up setting) and how it
/// is going, for the Budget tab row and the fund screen.
String fundStatusLine(S tr, SinkingFund f, String base) {
  final next = f.plan.next;
  if (next == null) return tr.sinkNoPayments;
  if (f.mustChoose) {
    return tr.sinkBehindChoose(fundAmounts(f.plan.behind, base));
  }
  final left = f.thisPeriod;
  if (left.isEmpty) {
    return f.plan.isBehind
        ? '${tr.sinkFundedThisMonth} · ${tr.sinkCatchingUp}'
        : tr.sinkFundedThisMonth;
  }
  final amount = tr.sinkThisMonth(fundAmounts(left, base));
  return f.plan.isBehind ? '$amount · ${tr.sinkCatchingUp}' : '$amount · ${tr.sinkOnTrack}';
}

/// One sinking fund on the Budget tab: icon, name and next due date, a thin
/// bar per currency of what is saved toward the next payment, and what this
/// month takes.
class SinkingFundRow extends StatelessWidget {
  final SinkingFund fund;
  final String baseCurrency;
  final String? icon;
  final Color color;
  final VoidCallback? onTap;

  const SinkingFundRow({
    super.key,
    required this.fund,
    required this.baseCurrency,
    required this.color,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tr = S.of(context);
    final next = fund.plan.next;
    final saved =
        next == null ? const <String, double>{} : savedToward(next, fund.balances);
    final behind = fund.mustChoose;
    final status = fundStatusLine(tr, fund, baseCurrency);
    final currencies = next == null
        ? const <String>[]
        : (next.amounts.keys.toList()
          ..sort((a, b) => a == baseCurrency ? -1 : b == baseCurrency ? 1 : a.compareTo(b)));

    return Semantics(
      label: [fund.allocation.name, if (next != null) tr.sinkNext(formatDate(next.date)), status]
          .join(', '),
      button: onTap != null,
      excludeSemantics: true,
      child: Tappable(
        onTap: onTap,
        borderRadius: BorderRadius.circular(RadiusTokens.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.pastel(context, color, light: 0.55, dark: 0.45),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: icon != null && icon!.isNotEmpty && icon != 'category'
                    ? EmojiGlyph(icon!, size: 20)
                    : Icon(AppIcons.calendarCheck,
                        size: 19,
                        color: AppColors.pastel(context, color,
                            light: 0.5, dark: 0.5, inverse: true)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(fund.allocation.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  if (next != null)
                    Text(tr.sinkNext(formatDate(next.date)),
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ts(context))),
                  for (final c in currencies) ...[
                    const SizedBox(height: 6),
                    _CurrencyBar(
                      label: currencies.length > 1 ? c : null,
                      saved: saved[c] ?? 0,
                      total: next!.amounts[c]!,
                      currency: c,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(status,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: behind
                              ? AppColors.caution
                              : AppColors.ts(context))),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _CurrencyBar extends StatelessWidget {
  final String? label;
  final double saved;
  final double total;
  final String currency;
  final double height;
  final bool showText;

  const _CurrencyBar({
    this.label,
    required this.saved,
    required this.total,
    required this.currency,
    this.height = 5,
    this.showText = true,
  });

  @override
  Widget build(BuildContext context) {
    final f = total <= 0 ? 0.0 : (saved / total).clamp(0.0, 1.0);
    final small = TextStyle(fontSize: 11, color: AppColors.ts(context));
    return Row(children: [
      if (label != null) ...[
        SizedBox(
          width: 34,
          child: Text(label!,
              style: small.copyWith(fontWeight: FontWeight.w800)),
        ),
      ],
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: SizedBox(
            height: height,
            child: Stack(children: [
              Container(color: AppColors.sfv(context)),
              FractionallySizedBox(
                widthFactor: f,
                alignment: AlignmentDirectional.centerStart,
                child: Container(color: AppColors.healthy),
              ),
            ]),
          ),
        ),
      ),
      if (showText) ...[
      const SizedBox(width: 8),
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 170),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerEnd,
          child: Text(
              S.of(context).sinkOf(formatAmount(saved, currency: currency),
                  formatAmount(total, currency: currency)),
              maxLines: 1,
              style: small),
        ),
      ),
      ],
    ]);
  }
}

/// Puts this period's remaining share into the fund, one funding row per
/// currency.
Future<void> fundSinkingThisPeriod(BuildContext context, WidgetRef ref,
    String fundId, Map<String, double> amounts) async {
  final tr = S.of(context);
  final messenger = ScaffoldMessenger.maybeOf(context);
  try {
    final engine = ref.read(allocationEngineProvider);
    await ref.read(databaseProvider).transaction(() async {
      for (final e in amounts.entries) {
        await engine.fundAllocation(
          allocationId: fundId,
          amount: e.value,
          currency: e.key,
          deviceId: 'local',
          note: tr.fundNote,
        );
      }
    });
    hapticMedium();
    messenger?.showSnackBar(SnackBar(
      content: Text(tr.fundSuccess),
      behavior: SnackBarBehavior.floating,
    ));
  } catch (e) {
    debugPrint('[SinkingFund] fund failed: $e');
    messenger?.showSnackBar(SnackBar(
      content: Text(tr.fundFailed),
      behavior: SnackBarBehavior.floating,
    ));
  }
}

Future<void> _setMode(WidgetRef ref, String fundId, BehindMode mode) async {
  final db = ref.read(databaseProvider);
  await (db.update(db.allocations)..where((a) => a.id.equals(fundId))).write(
      AllocationsCompanion(
          behindMode: Value(mode.stored), lastModified: Value(DateTime.now())));
}

/// The fund screen's top half for a sinking fund: what is saved toward the
/// next payment, this month's share and how to catch up, the monthly plan,
/// the payments (planned, bills, paid), and the fund's settings.
class SinkingFundPanel extends ConsumerWidget {
  final String fundId;
  final Color color;
  final List<Category> linkedCategories;
  final VoidCallback onLinkCategory;

  const SinkingFundPanel({
    super.key,
    required this.fundId,
    required this.color,
    required this.linkedCategories,
    required this.onLinkCategory,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = S.of(context);
    final base = ref.watch(householdProvider).value?.baseCurrency ?? 'USD';
    final fund = ref.watch(sinkingFundsProvider).value?[fundId];
    if (fund == null) return const SizedBox(height: 120);
    final plan = fund.plan;
    final next = plan.next;
    final left = fund.thisPeriod;
    final hero = AppColors.pastel(context, color, light: 0.8, dark: 0.75);
    final heroBold = const TextStyle(
        fontFamily: TypographyTokens.displayFamily,
        fontWeight: FontWeight.w800);

    final sections = <Widget>[];

    // ── Hero: next payment, saved toward it, this month ──
    sections.add(Container(
      decoration: BoxDecoration(
          color: hero, borderRadius: BorderRadius.circular(CardTokens.radius)),
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (next == null)
          Text(tr.sinkNoPaymentsHelp,
              style: TextStyle(fontSize: 14, color: AppColors.tp(context)))
        else ...[
          Text(
              next.title.isEmpty || next.title == fund.allocation.name
                  ? tr.sinkSavingForDate(formatDate(next.date))
                  : tr.sinkSavingFor(formatDate(next.date), next.title),
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ts(context))),
          const SizedBox(height: 10),
          for (final c in next.amounts.keys) ...[
            Row(crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic, children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                      formatAmount(savedToward(next, fund.balances)[c] ?? 0,
                          currency: c),
                      style: heroBold.copyWith(fontSize: 26)),
                ),
              ),
              const SizedBox(width: 8),
              Text(tr.sinkOfTotal(formatAmount(next.amounts[c]!, currency: c)),
                  style: TextStyle(fontSize: 13, color: AppColors.ts(context))),
            ]),
            const SizedBox(height: 6),
            _CurrencyBar(
                saved: savedToward(next, fund.balances)[c] ?? 0,
                total: next.amounts[c]!,
                currency: c,
                height: 8,
                showText: false),
            const SizedBox(height: 12),
          ],
          Text(tr.sinkThisMonthLabel,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ts(context))),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
                left.isEmpty ? tr.sinkFundedThisMonth : fundAmounts(left, base),
                style: heroBold.copyWith(fontSize: 18)),
          ),
          Text(
              plan.isBehind
                  ? tr.sinkBehindBy(fundAmounts(plan.behind, base))
                  : tr.sinkOnTrackCap,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: plan.isBehind ? AppColors.caution : AppColors.healthy)),
          if (left.isNotEmpty) ...[
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () {
                hapticLight();
                if (fund.mustChoose) {
                  showCatchUpSheet(context, ref, fund);
                } else {
                  fundSinkingThisPeriod(context, ref, fundId, left);
                }
              },
              child: Text(fund.mustChoose
                  ? tr.sinkCatchUpTitle
                  : tr.sinkFundThisMonth),
            ),
          ],
        ],
      ]),
    ));

    // ── No category: payments can't come from the fund ──
    if (linkedCategories.isEmpty) {
      sections.add(Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.pastel(context, AppColors.caution,
              light: 0.85, dark: 0.75),
          borderRadius: BorderRadius.circular(RadiusTokens.md),
        ),
        child: Row(children: [
          Expanded(
              child: Text(tr.sinkNeedsCategory,
                  style: const TextStyle(fontSize: 13))),
          TextButton(onPressed: onLinkCategory, child: Text(tr.allocLinkCategory)),
        ]),
      ));
    }

    // ── Monthly plan ──
    final steps = plan.steps(fund.mode == BehindMode.topUp
        ? BehindMode.topUp
        : BehindMode.spread);
    if (steps.isNotEmpty) {
      String range(FundPlanStep s) {
        final a = formatMonth(s.from, short: true);
        final b = formatMonth(s.to, short: true);
        return s.from == s.to ? a : '$a – $b';
      }

      sections.add(_card(context, [
        SectionHeader(tr.sinkMonthlyPlan),
        const SizedBox(height: 8),
        for (final s in steps)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(
                width: 96,
                child: Text(range(s),
                    style: TextStyle(fontSize: 13, color: AppColors.ts(context))),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final c in _ordered(s.amounts.keys, base))
                      Text(formatAmount(s.amounts[c]!, currency: c),
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ]),
          ),
        const SizedBox(height: 6),
        Text(tr.sinkPlanNote,
            style: TextStyle(fontSize: 12, color: AppColors.ts(context))),
      ]));
    }

    // ── Payments ──
    final category = linkedCategories.firstOrNull?.id;
    final paidOld = fund.paid.reversed.toList();
    sections.add(_card(context, [
      SectionHeader(tr.sinkPayments),
      const SizedBox(height: 4),
      if (plan.upcoming.isEmpty && paidOld.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(tr.sinkNoPayments,
              style: TextStyle(fontSize: 13, color: AppColors.ts(context))),
        ),
      for (final p in paidOld) _PaymentRow(payment: p, base: base),
      for (final p in plan.upcoming)
        _PaymentRow(
          payment: p,
          base: base,
          onTap: p.planId != null
              ? () => context.push('/fund-payment', extra: {'planId': p.planId})
              : p.recurringId != null
                  ? () => context.push('/recurring')
                  : null,
        ),
      const SizedBox(height: 8),
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        OutlinedButton.icon(
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: category == null
                ? onLinkCategory
                : () => context
                    .push('/fund-payment', extra: {'categoryId': category}),
            icon: const Icon(AppIcons.plus, size: 16),
            label: Text(tr.sinkAddPayment),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: category == null
                ? onLinkCategory
                : () => context.push('/allocations/$fundId/copy-year'),
            icon: const Icon(AppIcons.copy, size: 16),
            label: Text(tr.sinkCopyLastYear,
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
      ]),
    ]));

    // ── When behind ──
    sections.add(_card(context, [
      Row(children: [
        Expanded(
          child: Text(tr.sinkWhenBehind,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ),
        PopupMenuButton<BehindMode>(
          initialValue: fund.mode,
          onSelected: (m) async {
            try {
              await _setMode(ref, fundId, m);
            } catch (e) {
              debugPrint('[SinkingFund] mode failed: $e');
            }
          },
          itemBuilder: (_) => [
            for (final m in BehindMode.values)
              PopupMenuItem(value: m, child: Text(_modeLabel(tr, m))),
          ],
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(_modeLabel(tr, fund.mode),
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accentText(context))),
              const SizedBox(width: 4),
              Icon(AppIcons.caretDown,
                  size: 14, color: AppColors.accentText(context)),
            ]),
          ),
        ),
      ]),
      Text(tr.sinkWhenBehindHelp,
          style: TextStyle(fontSize: 12, color: AppColors.ts(context))),
    ]));

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (var i = 0; i < sections.length; i++) ...[
        if (i > 0) const SizedBox(height: 12),
        sections[i],
      ],
    ]);
  }

  static Widget _card(BuildContext context, List<Widget> children) => Container(
        decoration: AppColors.card(context),
        padding: CardTokens.padding,
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
      );
}

String _modeLabel(S tr, BehindMode m) => switch (m) {
      BehindMode.ask => tr.sinkModeAsk,
      BehindMode.spread => tr.sinkModeSpread,
      BehindMode.topUp => tr.sinkModeTopUp,
    };

class _PaymentRow extends StatelessWidget {
  final FundPayment payment;
  final String base;
  final VoidCallback? onTap;

  const _PaymentRow({required this.payment, required this.base, this.onTap});

  @override
  Widget build(BuildContext context) {
    final tr = S.of(context);
    final days = calendarDaysBetween(DateTime.now(), payment.date);
    final String when;
    Color whenColor = AppColors.ts(context);
    if (payment.paid) {
      when = tr.sinkPaid;
      whenColor = AppColors.healthy;
    } else if (days < 0) {
      when = tr.dashOverdue;
      whenColor = AppColors.billOverdue;
    } else {
      when = tr.sinkInDays(days);
    }
    return Opacity(
      opacity: payment.paid ? 0.6 : 1,
      child: Tappable(
        onTap: onTap,
        borderRadius: BorderRadius.circular(RadiusTokens.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(children: [
            Container(
              width: 44,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                  color: AppColors.sfv(context),
                  borderRadius: BorderRadius.circular(RadiusTokens.sm)),
              child: Column(children: [
                Text(formatMonth(payment.date, short: true).toUpperCase(),
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ts(context))),
                Text('${payment.date.day}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800)),
                // Another year: say which (schedules run across years).
                if (payment.date.year != DateTime.now().year)
                  Text('${payment.date.year}',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ts(context))),
              ]),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                    child: Text(
                        payment.title.isEmpty
                            ? formatDate(payment.date)
                            : payment.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 8),
                  Text(when,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: whenColor)),
                ]),
                const SizedBox(height: 2),
                Text(fundAmounts(payment.amounts, base),
                    style: TextStyle(fontSize: 13, color: AppColors.tp(context))),
                if (payment.recurringId != null)
                  Text(tr.sinkRecurringBill,
                      style: TextStyle(fontSize: 11, color: AppColors.ts(context))),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Behind: spread the shortfall over the months left, or top up now.
Future<void> showCatchUpSheet(
    BuildContext context, WidgetRef ref, SinkingFund fund) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _CatchUpSheet(fund: fund),
  );
}

class _CatchUpSheet extends ConsumerStatefulWidget {
  final SinkingFund fund;
  const _CatchUpSheet({required this.fund});

  @override
  ConsumerState<_CatchUpSheet> createState() => _CatchUpSheetState();
}

class _CatchUpSheetState extends ConsumerState<_CatchUpSheet> {
  BehindMode _mode = BehindMode.spread;
  bool _always = false;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final tr = S.of(context);
    final base = ref.watch(householdProvider).value?.baseCurrency ?? 'USD';
    final plan = widget.fund.plan;
    final spreadNow = plan.remaining(BehindMode.spread);
    final topUpNow = plan.remaining(BehindMode.topUp);
    final now = _mode == BehindMode.topUp ? topUpNow : spreadNow;
    final steady = plan.steps(BehindMode.topUp).length > 1
        ? plan.steps(BehindMode.topUp)[1].amounts
        : const <String, double>{};

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(tr.sinkCatchUpTitle,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
              tr.sinkBehindExplain(widget.fund.allocation.name,
                  fundAmounts(plan.behind, base)),
              style: TextStyle(fontSize: 13, color: AppColors.ts(context))),
          const SizedBox(height: 14),
          OptionCard(
            icon: AppIcons.chartLineUp,
            title: tr.sinkModeSpread,
            subtitle:
                '${tr.sinkThisMonth(spreadNow.isEmpty ? '0' : fundAmounts(spreadNow, base))}\n${tr.sinkSpreadSub}',
            selected: _mode == BehindMode.spread,
            onTap: () => setState(() => _mode = BehindMode.spread),
          ),
          const SizedBox(height: 8),
          OptionCard(
            icon: AppIcons.lightning,
            title: tr.sinkModeTopUp,
            subtitle:
                '${tr.sinkTopUpNow(topUpNow.isEmpty ? '0' : fundAmounts(topUpNow, base), steady.isEmpty ? '—' : fundAmounts(steady, base))}\n${tr.sinkTopUpSub}',
            selected: _mode == BehindMode.topUp,
            onTap: () => setState(() => _mode = BehindMode.topUp),
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            value: _always,
            onChanged: (v) => setState(() => _always = v ?? false),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(tr.sinkAlways, style: const TextStyle(fontSize: 14)),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _busy || now.isEmpty
                ? null
                : () async {
                    setState(() => _busy = true);
                    final nav = Navigator.of(context);
                    try {
                      if (_always) {
                        await _setMode(ref, widget.fund.allocation.id, _mode);
                      }
                    } catch (e) {
                      debugPrint('[SinkingFund] mode failed: $e');
                    }
                    if (!context.mounted) return;
                    await fundSinkingThisPeriod(
                        context, ref, widget.fund.allocation.id, now);
                    nav.pop();
                  },
            child: Text(tr.sinkFundAmount(fundAmounts(now, base))),
          ),
        ]),
      ),
    );
  }
}

/// "Save for it monthly" on a yearly bill: a sinking fund named after the
/// bill, with a category of its own (under the bill's, same look) that the
/// bill now posts to, so its payments come out of the fund. Returns the
/// fund's id.
Future<String?> createFundForBill(WidgetRef ref, String recurringId) async {
  final db = ref.read(databaseProvider);
  final householdId = ref.read(currentHouseholdIdProvider);
  if (householdId == null) return null;
  final bill = await (db.select(db.recurringTransactions)
        ..where((r) => r.id.equals(recurringId)))
      .getSingleOrNull();
  if (bill == null) return null;
  final cat = bill.categoryId == null
      ? null
      : await (db.select(db.categories)
            ..where((c) => c.id.equals(bill.categoryId!)))
          .getSingleOrNull();
  final name = bill.title.isNotEmpty ? bill.title : (cat?.name ?? bill.note);
  final fundId = const Uuid().v4();
  final catId = const Uuid().v4();
  final now = DateTime.now();
  await db.transaction(() async {
    await db.into(db.allocations).insert(AllocationsCompanion.insert(
          id: fundId,
          householdId: householdId,
          name: name,
          categoryId: catId,
          type: const Value('sinking'),
          periodicity: const Value('permanent'),
          targetCurrency: Value(bill.currency),
          deviceId: 'local',
        ));
    await db.into(db.categories).insert(CategoriesCompanion.insert(
          id: catId,
          householdId: householdId,
          name: name,
          parentId: Value(cat?.parentId ?? cat?.id),
          icon: Value(cat?.icon ?? 'category'),
          colorHex: Value(cat?.colorHex ?? '#607D8B'),
          transactionType: const Value('expense'),
          allocationId: Value(fundId),
        ));
    await (db.update(db.recurringTransactions)
          ..where((r) => r.id.equals(recurringId)))
        .write(RecurringTransactionsCompanion(
            categoryId: Value(catId), lastModified: Value(now)));
  });
  return fundId;
}
