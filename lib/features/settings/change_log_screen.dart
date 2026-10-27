import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/database/app_database.dart';
import '../../core/engine/change_log.dart';
import '../../core/providers/accounts_provider.dart';
import '../../core/providers/categories_provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/date_format_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../core/providers/member_names_provider.dart';
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

/// Settings › Change history: what was added, edited or deleted, when, by
/// whom, and what an edit changed (from the operation log, every phone's).
class ChangeLogScreen extends ConsumerStatefulWidget {
  const ChangeLogScreen({super.key});

  @override
  ConsumerState<ChangeLogScreen> createState() => _ChangeLogScreenState();
}

class _ChangeLogScreenState extends ConsumerState<ChangeLogScreen> {
  static const _limit = 300;
  List<ChangeEvent> _events = const [];
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
      final events = await loadChangeLog(db, householdId, limit: _limit);
      if (mounted) {
        setState(() {
          _events = events;
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
  const _DayGroup({required this.day, required this.events});

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
    final accounts = {
      for (final a in ref.watch(accountsProvider).value ?? const <Account>[])
        a.id: a.name
    };
    final names = ref.watch(memberNamesProvider).value ?? const {};
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
              _EventRow(
                  event: e, cats: cats, accounts: accounts, names: names),
          ],
        ),
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  final ChangeEvent event;
  final Map<String, Category> cats;
  final Map<String, String> accounts;
  final Map<String, String> names;
  const _EventRow(
      {required this.event,
      required this.cats,
      required this.accounts,
      required this.names});

  /// "Category: Food → Home", one per thing an edit changed.
  String _change(S tr, FieldChange c) {
    String names(Object? ids, String Function(String) name, String sep) =>
        (ids as List?)
            ?.map((id) =>
                id == null ? tr.commonUncategorized : name(id as String))
            .join(sep) ??
        '—';
    String show(Object? v) => switch (c.field) {
          'amount' => (v as Map<String, double>?)
                  ?.entries
                  .map((e) => formatAmount(e.value, currency: e.key))
                  .join(' + ') ??
              '—',
          'category' => names(v, (id) => cats[id]?.name ?? '—', ', '),
          // A transfer's: from, to.
          'account' => names(v, (id) => accounts[id] ?? '—',
              event.tx.type == 'transfer' ? ' › ' : ', '),
          'date' => v == null ? '—' : formatDate(v as DateTime),
          'type' => switch (v) {
              'income' => tr.typeIncome,
              'transfer' => tr.typeTransfer,
              _ => tr.typeExpense,
            },
          _ => (v as String?)?.isNotEmpty == true
              ? '“${visibleNote(v!)}”'
              : '—',
        };
    final field = switch (c.field) {
      'amount' => tr.commonAmount,
      'category' => tr.commonCategory,
      'account' => tr.commonAccount,
      'date' => tr.txDetailDate,
      'type' => tr.changeLogFieldType,
      _ => tr.txDetailNote,
    };
    return tr.changeLogChange(field, show(c.from), show(c.to));
  }

  @override
  Widget build(BuildContext context) {
    final tr = S.of(context);
    final tx = event.tx;
    final (icon, color, verb) = switch (event.kind) {
      ChangeKind.added => (AppIcons.plusCircle, AppColors.healthy, tr.changeLogAdded),
      ChangeKind.edited => (AppIcons.pencilSimple, AppColors.accent, tr.changeLogEdited),
      ChangeKind.deleted => (AppIcons.trash, AppColors.overspent, tr.changeLogDeleted),
      ChangeKind.restored => (AppIcons.clockCounterClockwise, AppColors.healthy, tr.changeLogRestored),
    };
    final note = visibleNote(tx.note).split(' — ').first.trim();
    final catId = tx.categoryId;
    final title = note.isNotEmpty
        ? note
        : cats[catId]?.name ??
            switch (tx.type) {
              'income' => tr.typeIncome,
              'transfer' => tr.typeTransfer,
              _ => tr.typeExpense,
            };
    // Amounts in the lines' own currencies (never summed across them, never
    // the base total); a transfer keeps its sent amount.
    final amountText = event.amounts.entries
        .map((e) =>
            formatSignedAmount(e.value, currency: e.key, type: tx.type))
        .join(' + ');
    final time = TimeOfDay.fromDateTime(event.at.toLocal()).format(context);
    final source = switch (event.source) {
      'bill' => tr.changeLogFromBill,
      'web' => tr.changeLogFromWeb,
      _ => null,
    };
    final txDay = tx.createdAt.toLocal();
    final atDay = event.at.toLocal();
    final otherDay = calendarDaysBetween(atDay, txDay) != 0;
    // Shared budgets: whose device made the change.
    final by = event.by == null ? null : memberNameFor(names, event.by!);
    final replacedBy = event.replacedBy == null
        ? null
        : memberNameFor(names, event.replacedBy!);
    final sub = [
      '$verb $time',
      if (by != null) tr.changeLogBy(by),
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
                  for (final c in event.changes)
                    Text(_change(tr, c),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12.5, color: AppColors.ts(context))),
                  if (event.replacedBy != null)
                    Text(
                        replacedBy == null
                            ? tr.changeLogReplaced
                            : tr.changeLogReplacedBy(replacedBy),
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ts(context))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
