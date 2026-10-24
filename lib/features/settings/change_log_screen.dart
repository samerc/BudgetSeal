import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/database/app_database.dart';
import '../../core/engine/change_log.dart';
import '../../core/providers/categories_provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/date_format_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_icons.dart';
import '../../shared/theme/design_tokens.dart';
import '../../shared/utils/calendar_days.dart';
import '../../shared/utils/format_number.dart';
import '../../shared/utils/note_text.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_retry.dart';
import '../../shared/widgets/large_title_header.dart';
import '../../shared/widgets/skeleton_loader.dart';
import '../../shared/widgets/tappable.dart';

/// Settings › Change history: what was added, edited or deleted, and when.
class ChangeLogScreen extends ConsumerStatefulWidget {
  const ChangeLogScreen({super.key});

  @override
  ConsumerState<ChangeLogScreen> createState() => _ChangeLogScreenState();
}

class _ChangeLogScreenState extends ConsumerState<ChangeLogScreen> {
  static const _limit = 300;
  List<ChangeEvent> _events = const [];
  Map<String, List<TransactionLine>> _lines = const {};
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final db = ref.read(databaseProvider);
      final householdId = ref.read(currentHouseholdIdProvider);
      if (householdId == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      final log = await loadChangeLog(db, householdId, limit: _limit);
      if (mounted) {
        setState(() {
          _events = log.events;
          _lines = log.lines;
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      debugPrint('[ChangeLog] Load failed: $e');
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = S.of(context);
    // Day groups by when the change happened.
    final groups = <({DateTime day, List<ChangeEvent> events})>[];
    for (final e in _events) {
      final l = e.at.toLocal();
      final day = DateTime(l.year, l.month, l.day);
      if (groups.isEmpty || groups.last.day != day) {
        groups.add((day: day, events: []));
      }
      groups.last.events.add(e);
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            LargeTitleHeader(title: tr.changeLogTitle, back: true),
            if (_loading)
              const SliverToBoxAdapter(child: SkeletonList())
            else if (_error != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: ErrorRetry(
                  message: tr.changeLogLoadFailed,
                  details: '$_error',
                  onRetry: () {
                    setState(() => _loading = true);
                    _load();
                  },
                ),
              )
            else if (_events.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: AppIcons.clockCounterClockwise,
                  title: tr.changeLogEmpty,
                ),
              )
            else ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                  child: Text(tr.changeLogIntro(_limit),
                      style: TextStyle(
                          fontSize: 13, color: AppColors.ts(context))),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                sliver: SliverList.builder(
                  itemCount: groups.length,
                  itemBuilder: (_, i) => _DayGroup(
                    day: groups[i].day,
                    events: groups[i].events,
                    lines: _lines,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DayGroup extends ConsumerWidget {
  final DateTime day;
  final List<ChangeEvent> events;
  final Map<String, List<TransactionLine>> lines;
  const _DayGroup(
      {required this.day, required this.events, required this.lines});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = S.of(context);
    final days = calendarDaysBetween(DateTime.now(), day);
    final label = days == 0
        ? tr.commonToday
        : days == -1
            ? tr.commonYesterday
            : formatDate(day);
    final cats = {
      for (final c in ref.watch(categoriesProvider).value ?? const <Category>[])
        c.id: c
    };
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        decoration: AppColors.card(context),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 16, 2),
              child: Text(label,
                  style: TextStyle(
                    fontFamily: TypographyTokens.displayFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.tp(context),
                  )),
            ),
            for (final e in events)
              _EventRow(event: e, lines: lines[e.tx.id] ?? const [], cats: cats),
          ],
        ),
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  final ChangeEvent event;
  final List<TransactionLine> lines;
  final Map<String, Category> cats;
  const _EventRow(
      {required this.event, required this.lines, required this.cats});

  @override
  Widget build(BuildContext context) {
    final tr = S.of(context);
    final tx = event.tx;
    final (icon, color, verb) = switch (event.kind) {
      ChangeKind.added => (AppIcons.plusCircle, AppColors.healthy, tr.changeLogAdded),
      ChangeKind.edited => (AppIcons.pencilSimple, AppColors.accent, tr.changeLogEdited),
      ChangeKind.deleted => (AppIcons.trash, AppColors.overspent, tr.changeLogDeleted),
    };
    final note = visibleNote(tx.note).split(' — ').first.trim();
    final catId = tx.categoryId ?? lines.firstOrNull?.categoryId;
    final title = note.isNotEmpty
        ? note
        : cats[catId]?.name ??
            switch (tx.type) {
              'income' => tr.typeIncome,
              'transfer' => tr.typeTransfer,
              _ => tr.typeExpense,
            };
    // Amounts in the lines' own currencies (never summed across them, never
    // the base total); a transfer has no lines and keeps its sent amount.
    final perCurrency = <String, double>{};
    if (tx.type == 'transfer' || lines.isEmpty) {
      perCurrency[tx.currency] = tx.amount;
    } else {
      for (final l in lines) {
        perCurrency[l.currency] = (perCurrency[l.currency] ?? 0) + l.amount;
      }
    }
    final amountText = perCurrency.entries
        .map((e) =>
            formatSignedAmount(e.value, currency: e.key, type: tx.type))
        .join(' + ');
    final time = TimeOfDay.fromDateTime(event.at.toLocal()).format(context);
    final source = tx.id.startsWith('rec:')
        ? tr.changeLogFromBill
        : tx.deviceId == 'web'
            ? tr.changeLogFromWeb
            : null;
    final txDay = tx.createdAt.toLocal();
    final atDay = event.at.toLocal();
    final otherDay = calendarDaysBetween(atDay, txDay) != 0;
    final sub = [
      '$verb $time',
      if (otherDay) tr.changeLogForDate(formatDate(txDay)),
      if (source != null) source,
    ].join(' · ');

    return Tappable(
      onTap: event.kind == ChangeKind.deleted
          ? null
          : () => context.push('/transactions/${tx.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.pastel(context, color, light: 0.85, dark: 0.75),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and amount share the top line; the amount is
                  // capped and scales down so long LBP figures fit.
                  Row(
                    children: [
                      Expanded(
                        child: Text(title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.tp(context),
                              decoration: event.kind == ChangeKind.deleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            )),
                      ),
                      const SizedBox(width: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 170),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerEnd,
                          child: Text(
                            amountText,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: event.kind == ChangeKind.deleted
                                  ? AppColors.th(context)
                                  : AppColors.tp(context),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(sub,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12.5, color: AppColors.ts(context))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
