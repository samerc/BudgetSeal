import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/database/app_database.dart' show User;
import '../../core/providers/family_provider.dart';
import '../../core/services/household_members.dart';
import '../../core/services/family_service.dart';
import '../../core/database/daos/ledger_dao.dart';
import '../../core/engine/budget_history.dart';
import '../../core/engine/period_engine.dart' show budgetPeriodFor;
import '../../core/providers/database_provider.dart';
import '../../core/providers/date_format_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../core/providers/period_reset_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_icons.dart';
import '../../shared/theme/design_tokens.dart';
import '../../shared/utils/format_number.dart';
import '../../shared/widgets/error_retry.dart';
import '../../shared/widgets/seal_mark.dart';
import '../transactions/widgets/tx_ui.dart' show capitalizedFirst;

/// The last budget period closed: a dated seal (when it stayed within what
/// was funded), one line on how it went, funded / spent / kept, which
/// envelopes held and which went over, what happened to the leftovers, and
/// a way into the new period. The recap can be shared as an image.
class MonthCloseScreen extends ConsumerStatefulWidget {
  const MonthCloseScreen({super.key});

  @override
  ConsumerState<MonthCloseScreen> createState() => _MonthCloseScreenState();
}

class _Recap {
  final DateTime lastMid;
  final DateTime currentMid;
  final String currency;
  final double funded;
  final double spent;
  final int held;

  /// Envelopes that went over: name and closing balance (negative).
  final List<(String, double)> over;
  final double returned;

  /// Funded counts what the envelopes had to spend in the period: what
  /// they closed with plus what they spent (money funded earlier included).
  const _Recap({
    required this.lastMid,
    required this.currentMid,
    required this.currency,
    required this.funded,
    required this.spent,
    required this.held,
    required this.over,
    required this.returned,
  });

  double get kept => funded - spent;
  bool get sealed => kept > -0.005;
}

class _MonthCloseScreenState extends ConsumerState<MonthCloseScreen> {
  // Family (roadmap #5): who has reviewed the closed period.
  DateTime? _periodStart;
  Set<String> _reviewed = const {};

  _Recap? _recap;
  bool _loading = true;
  bool _failed = false;
  final _shot = GlobalKey();

  @override
  void initState() {
    super.initState();
    _load();
  }

  DateTime _mid(({DateTime start, DateTime end}) p) =>
      p.start.add(Duration(days: p.end.difference(p.start).inDays ~/ 2));

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final household = await ref.read(householdProvider.future);
      if (household == null) throw StateError('no household');
      final current = budgetPeriodFor(household.periodStartDay);
      final last = budgetPeriodFor(household.periodStartDay,
          current.start.subtract(const Duration(days: 1)));
      final db = ref.read(databaseProvider);
      _periodStart = last.start;
      _reviewed = await FamilyService(db).reviewedBy(household.id, last.start);
      final dao = LedgerDao(db);
      final base = household.baseCurrency;
      final stats = await envelopePeriodStats(dao,
          householdId: household.id,
          start: last.start,
          end: last.end,
          currency: base);
      final names = {
        for (final a in await (db.select(db.allocations)
              ..where((a) => a.householdId.equals(household.id)))
            .get())
          a.id: a.name,
      };
      final over = <(String, double)>[];
      var held = 0;
      double funded = 0, spent = 0;
      stats.forEach((id, s) {
        funded += s.endBalance + s.spent;
        spent += s.spent;
        switch (s.outcome) {
          case EnvelopeOutcome.over:
            over.add((names[id] ?? '?', s.endBalance));
          case EnvelopeOutcome.held:
            held++;
          case EnvelopeOutcome.idle:
            break;
        }
      });
      over.sort((a, b) => a.$2.compareTo(b.$2));
      final returned =
          (await dao.resetReturnedSince(household.id, current.start))[base] ??
              0;
      if (!mounted) return;
      setState(() {
        _recap = _Recap(
          lastMid: _mid(last),
          currentMid: _mid(current),
          currency: base,
          funded: funded,
          spent: spent,
          held: held,
          over: over,
          returned: returned,
        );
        _loading = false;
      });
    } catch (e) {
      debugPrint('[MonthClose] Load failed: $e');
      if (mounted) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
    }
  }

  Future<void> _share() async {
    final tr = S.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final boundary =
          _shot.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) throw StateError('no image');
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/budgetseal_recap.png');
      await file.writeAsBytes(bytes.buffer.asUint8List());
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
    } catch (e) {
      debugPrint('[MonthClose] Share failed: $e');
      messenger.showSnackBar(SnackBar(
        content: Text(tr.commonSomethingWentWrong),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = S.of(context);
    final r = _recap;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          icon: const Icon(AppIcons.x),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _failed || r == null
              ? ErrorRetry(message: tr.commonSomethingWentWrong, onRetry: _load)
              : _body(context, tr, r),
    );
  }

  Future<void> _confirmReview() async {
    final household = ref.read(householdProvider).value;
    if (household == null || _periodStart == null) return;
    try {
      final service = FamilyService(ref.read(databaseProvider));
      await service.confirmReview(household.id, _periodStart!);
      final reviewed = await service.reviewedBy(household.id, _periodStart!);
      if (mounted) setState(() => _reviewed = reviewed);
    } catch (e) {
      debugPrint('[MonthClose] Review failed: $e');
    }
  }

  Widget _body(BuildContext context, S tr, _Recap r) {
    final month = formatMonth(r.lastMid);
    // A family budget: sealed once every grown-up has reviewed it (user's
    // decision), as well as kept within budget.
    final grownUps = [
      for (final u in ref.watch(membersProvider).value ?? const <User>[])
        if (u.role != kidRole) u,
    ];
    final family = grownUps.length > 1;
    final waiting = [
      for (final u in grownUps)
        if (!_reviewed.contains(u.deviceId)) u,
    ];
    final sealed = r.sealed && (!family || waiting.isEmpty);
    String money(double v) => formatAmount(v, currency: r.currency);
    final pending = ref.watch(pendingResetProvider).value ?? const <String>[];
    final story = [
      r.sealed
          ? tr.closeStoryKept(money(r.kept))
          : tr.closeStoryOverTotal(money(-r.kept)),
      switch (r.over.length) {
        0 => tr.closeStoryAllHeld,
        1 => tr.closeStoryOneOver(r.over.first.$1),
        _ => tr.closeStoryNOver(r.over.length),
      },
    ].join(' ');

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        // The part that becomes the shared image.
        RepaintBoundary(
          key: _shot,
          child: ColoredBox(
            color: AppColors.bg(context),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: sealed
                        // Stamped on once: drops in large, settles.
                        ? TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration: const Duration(milliseconds: 520),
                            curve: Curves.easeOutBack,
                            builder: (_, t, child) => Opacity(
                              opacity: t.clamp(0.0, 1.0),
                              child: Transform.scale(
                                  scale: 1.6 - 0.6 * t, child: child),
                            ),
                            child: DatedSeal(
                              top: formatMonth(r.lastMid, short: true)
                                  .toUpperCase(),
                              bottom: '${r.lastMid.year}',
                            ),
                          )
                        : Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              color: AppColors.pastel(context, AppColors.accent),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(AppIcons.calendarBlank,
                                size: 40, color: AppColors.accentText(context)),
                          ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    sealed ? tr.periodSealedTitle(month) : tr.closeDone(month),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontFamily: TypographyTokens.displayFamily,
                        fontSize: 28,
                        height: 1.1,
                        fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(story,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 15,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ts(context))),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: AppColors.card(context),
                    child: Row(children: [
                      _stat(context, tr.closeFunded, money(r.funded)),
                      _stat(context, tr.closeSpent, money(r.spent)),
                      _stat(
                        context,
                        r.sealed ? tr.closeKept : tr.closeOver,
                        money(r.kept.abs()),
                        color: r.sealed ? AppColors.healthy : AppColors.overspent,
                      ),
                    ]),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: AppColors.card(context),
                    child: Column(children: [
                      if (r.held > 0)
                        _row(
                          context,
                          const SealMark(size: 26),
                          tr.closeHeld(r.held),
                          null,
                        ),
                      for (final (name, balance) in r.over)
                        _row(
                          context,
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: AppColors.pastel(
                                  context, AppColors.overspent),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(AppIcons.warning,
                                size: 14, color: AppColors.overspent),
                          ),
                          name,
                          capitalizedFirst(tr.quickOverBy(money(-balance))),
                          bad: true,
                        ),
                    ]),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(tr.closeLeftover,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(
          r.returned > 0.005
              ? tr.closeReturned(money(r.returned))
              : tr.closeStayed,
          style: TextStyle(
              fontSize: 14, height: 1.4, color: AppColors.ts(context)),
        ),
        if (pending.isNotEmpty) ...[
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => context.push('/period-transition'),
            child: Text(tr.closeReview(pending.length)),
          ),
        ],
        if (family) ...[
          const SizedBox(height: 18),
          Text(
            waiting.isEmpty
                ? tr.reviewFamilySealed
                : tr.reviewFamilyWaiting(
                    waiting.map((u) => u.name).join(', ')),
            style: TextStyle(
                fontSize: 14, height: 1.4, color: AppColors.ts(context)),
          ),
          if (!_reviewed.contains(DeviceIdentity.id)) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _confirmReview,
              icon: const Icon(AppIcons.checkCircle, size: 20),
              label: Text(tr.reviewFamilyDone),
            ),
          ],
        ],
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () {
            context.pop();
            context.push('/funding');
          },
          child: Text(tr.closePlan(formatMonth(r.currentMid))),
        ),
        const SizedBox(height: 4),
        TextButton.icon(
          onPressed: _share,
          style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
          icon: const Icon(AppIcons.shareNetwork, size: 18),
          label: Text(tr.closeShare),
        ),
      ],
    );
  }

  Widget _stat(BuildContext context, String label, String value,
      {Color? color}) {
    return Expanded(
      child: Column(children: [
        Text(label,
            style: TextStyle(fontSize: 12, color: AppColors.ts(context))),
        const SizedBox(height: 2),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value,
                style: TextStyle(
                    fontFamily: TypographyTokens.displayFamily,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: color)),
          ),
        ),
      ]),
    );
  }

  Widget _row(BuildContext context, Widget leading, String text, String? trailing,
      {bool bad = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        leading,
        const SizedBox(width: 12),
        Expanded(
          child: Text(text,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        ),
        if (trailing != null)
          Text(trailing,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: bad ? AppColors.overspent : null)),
      ]),
    );
  }
}
