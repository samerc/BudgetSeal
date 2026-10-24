import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/utils/note_text.dart';
import '../database/app_database.dart';
import '../engine/envelope_for_category.dart';
import '../engine/period_engine.dart' show budgetPeriodFor;
import '../engine/sinking_fund.dart';
import 'allocations_provider.dart';
import 'categories_provider.dart';
import 'database_provider.dart';
import 'household_provider.dart';

/// A sinking fund (envelope type `sinking`) with its schedule and plan.
class SinkingFund {
  final Allocation allocation;
  final Map<String, double> balances;
  final FundPlan plan;

  /// Paid from the fund in the past year, newest first.
  final List<FundPayment> paid;

  /// Paid ones of the past year and every planned one (for "Copy from last
  /// year").
  final List<FundPayment> history;

  const SinkingFund({
    required this.allocation,
    required this.balances,
    required this.plan,
    required this.paid,
    required this.history,
  });

  BehindMode get mode => BehindMode.parse(allocation.behindMode);

  /// Still to put in this period, as the fund's catch-up setting says
  /// (asking = spread until the user picks).
  Map<String, double> get thisPeriod => plan.remaining(mode);

  /// Behind, set to ask, and this period not funded yet: the user picks
  /// spread or top up.
  bool get mustChoose =>
      plan.isBehind &&
      mode == BehindMode.ask &&
      plan.remaining(BehindMode.spread).isNotEmpty;
}

/// Re-runs when recurring bills change (planned payments are transactions,
/// which [allocationsProvider] already follows).
final _recurringChangesProvider = StreamProvider<int>((ref) {
  final db = ref.watch(databaseProvider);
  var n = 0;
  return db
      .tableUpdates(TableUpdateQuery.onAllTables([db.recurringTransactions]))
      .map((_) => ++n);
});

/// Every live sinking fund by envelope id.
final sinkingFundsProvider =
    FutureProvider<Map<String, SinkingFund>>((ref) async {
  final allocations = await ref.watch(allocationsProvider.future);
  final categories = await ref.watch(categoriesProvider.future);
  ref.watch(_recurringChangesProvider);
  final household = ref.watch(householdProvider).value;
  if (household == null) return const {};
  final funds = [
    for (final a in allocations)
      if (a.data.allocation.type == 'sinking') a,
  ];
  if (funds.isEmpty) return const {};
  return loadSinkingFunds(
    ref.read(databaseProvider),
    householdId: household.id,
    funds: {for (final a in funds) a.data.allocation: a.balanceByCurrency},
    liveAllocations: [for (final a in allocations) a.data.allocation],
    categories: categories,
    startDay: household.periodStartDay,
  );
});

/// Builds each fund's schedule from the database: planned expenses and
/// yearly/quarterly recurring bills whose category spends from the fund,
/// plus what was paid from it ([FundPayment.paid]), then plans it.
Future<Map<String, SinkingFund>> loadSinkingFunds(
  AppDatabase db, {
  required String householdId,
  required Map<Allocation, Map<String, double>> funds,
  required List<Allocation> liveAllocations,
  required List<Category> categories,
  required int startDay,
  DateTime? now,
}) async {
  now ??= DateTime.now();
  final period = budgetPeriodFor(startDay, now);
  final catsById = {for (final c in categories) c.id: c};
  final fundIds = {for (final a in funds.keys) a.id};
  String? fundOf(String? categoryId) {
    if (categoryId == null) return null;
    final id = envelopeForCategory(categoryId,
        categoriesById: catsById, liveAllocations: liveAllocations);
    return fundIds.contains(id) ? id : null;
  }

  String titleOf(String note, String? categoryId) {
    final t = visibleNote(note).trim();
    return t.isNotEmpty ? t : (catsById[categoryId]?.name ?? '');
  }

  final upcoming = <String, List<FundPayment>>{};

  // Planned expenses: one payment per plan, a part per currency.
  final plans = await (db.select(db.transactions)
        ..where((t) =>
            t.householdId.equals(householdId) &
            t.status.equals('planned') &
            t.deleted.equals(false) &
            t.type.equals('expense')))
      .get();
  if (plans.isNotEmpty) {
    final lines = await (db.select(db.transactionLines)
          ..where((l) => l.transactionId.isIn(plans.map((t) => t.id))))
        .get();
    final byTx = <String, List<TransactionLine>>{};
    for (final l in lines) {
      byTx.putIfAbsent(l.transactionId, () => []).add(l);
    }
    for (final t in plans) {
      final parts = byTx[t.id] ?? const <TransactionLine>[];
      final amounts = <String, double>{};
      final accounts = <String>[];
      String? fund;
      String? category;
      if (parts.isEmpty) {
        fund = fundOf(t.categoryId);
        category = t.categoryId;
        amounts[t.currency] = t.amount;
        accounts.add(t.accountId);
      }
      for (final l in parts) {
        final f = fundOf(l.categoryId);
        if (f == null) continue;
        fund ??= f;
        category ??= l.categoryId;
        if (f != fund) continue;
        amounts[l.currency] = (amounts[l.currency] ?? 0) + l.amount;
        final acc = l.accountId ?? t.accountId;
        if (!accounts.contains(acc)) accounts.add(acc);
      }
      if (fund == null || amounts.isEmpty) continue;
      upcoming.putIfAbsent(fund, () => []).add(FundPayment(
            title: titleOf(t.note, category),
            date: t.createdAt,
            amounts: amounts,
            accountIds: accounts,
            planId: t.id,
          ));
    }
  }

  // Yearly / quarterly bills, for the next 13 months.
  final until = DateTime(now.year + 1, now.month + 1, now.day);
  final bills = await (db.select(db.recurringTransactions)
        ..where((r) =>
            r.householdId.equals(householdId) &
            r.enabled.equals(true) &
            r.deleted.equals(false) &
            r.type.equals('expense')))
      .get();
  for (final r in bills) {
    if (!isFundBill(r.frequency, r.interval)) continue;
    final fund = fundOf(r.categoryId);
    if (fund == null) continue;
    for (final d in fundBillDates(
        frequency: r.frequency,
        interval: r.interval,
        next: r.nextDueDate,
        endDate: r.endDate,
        until: until,
        anchorDay: r.anchorDay)) {
      upcoming.putIfAbsent(fund, () => []).add(FundPayment(
            title: r.title.isNotEmpty ? r.title : titleOf(r.note, r.categoryId),
            date: d,
            amounts: {r.currency: r.amount},
            accountIds: [r.accountId],
            recurringId: r.id,
          ));
    }
  }

  // Each fund's ledger, dated as in the balance (spending at its
  // transaction's date).
  final rows = await db.customSelect(
    'SELECT l.allocation_id AS fund, l.entry_type AS kind, l.amount AS amount, '
    'l.currency AS currency, l.source_transaction_id AS tx, '
    'COALESCE(t.created_at, l.created_at) AS at, t.note AS note, '
    't.category_id AS category, t.account_id AS account '
    'FROM allocation_ledger l '
    'LEFT JOIN transactions t ON t.id = l.source_transaction_id '
    'WHERE l.allocation_id IN (${List.filled(fundIds.length, '?').join(',')}) '
    'AND (l.source_transaction_id IS NULL OR t.id IS NULL OR t.deleted = 0)',
    variables: [for (final id in fundIds) Variable.withString(id)],
    readsFrom: {db.allocationLedger, db.transactions},
  ).get();

  final result = <String, SinkingFund>{};
  for (final entry in funds.entries) {
    final fund = entry.key;
    final mine = [
      for (final r in rows)
        if (r.read<String>('fund') == fund.id)
          (
            kind: r.read<String>('kind'),
            amount: r.read<double>('amount'),
            currency: r.read<String>('currency'),
            tx: r.readNullable<String>('tx'),
            at: DateTime.fromMillisecondsSinceEpoch(r.read<int>('at') * 1000),
            note: r.readNullable<String>('note') ?? '',
            category: r.readNullable<String>('category'),
            account: r.readNullable<String>('account'),
          ),
    ];

    Map<String, double> balanceAt(DateTime t) {
      final out = <String, double>{};
      for (final r in mine) {
        if (r.at.isBefore(t)) {
          out[r.currency] = (out[r.currency] ?? 0) + r.amount;
        }
      }
      return out;
    }

    final funded = <String, double>{};
    for (final r in mine) {
      if ((r.kind == 'funding' || r.kind == 'transfer') &&
          r.amount > 0 &&
          !r.at.isBefore(period.start)) {
        funded[r.currency] = (funded[r.currency] ?? 0) + r.amount;
      }
    }

    // Payments made from the fund: its spending, one per transaction.
    final paidByTx = <String, FundPayment>{};
    for (final r in mine) {
      if (r.kind != 'consumption' || r.tx == null || r.amount >= 0) continue;
      final p = paidByTx[r.tx!];
      paidByTx[r.tx!] = FundPayment(
        title: p?.title ?? titleOf(r.note, r.category),
        date: r.at,
        amounts: {
          ...?p?.amounts,
          r.currency: (p?.amounts[r.currency] ?? 0) - r.amount,
        },
        accountIds: [
          ...?p?.accountIds,
          if (r.account != null && !(p?.accountIds.contains(r.account) ?? false))
            r.account!,
        ],
        txId: r.tx,
      );
    }
    final yearAgo = DateTime(now.year - 1, now.month, now.day);
    final paid = paidByTx.values.where((p) => !p.date.isBefore(yearAgo)).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    // The steady plan runs from the fund's first period, at most a year back.
    final first = budgetPeriodFor(startDay, fund.createdAt).start;
    final yearBack = budgetPeriodFor(
            startDay, DateTime(period.start.year - 1, period.start.month, 15))
        .start;
    final anchor = first.isAfter(yearBack) ? first : yearBack;
    final start = anchor.isAfter(period.start) ? period.start : anchor;

    final mineUpcoming = upcoming[fund.id] ?? const <FundPayment>[];
    final plan = planSinkingFund(
      payments: [
        ...paidByTx.values.where((p) => !p.date.isBefore(start)),
        ...mineUpcoming,
      ],
      balanceAtStart: balanceAt(period.start),
      funded: funded,
      anchor: start,
      balanceAtAnchor: balanceAt(start),
      startDay: startDay,
      now: now,
    );
    result[fund.id] = SinkingFund(
      allocation: fund,
      balances: entry.value,
      plan: plan,
      paid: paid,
      history: [
        ...paid,
        ...mineUpcoming.where((p) => p.planId != null),
      ],
    );
  }
  return result;
}

/// The fund's next payment, saved so far toward it per currency (at most
/// the payment's amount).
Map<String, double> savedToward(FundPayment next, Map<String, double> balances) =>
    {
      for (final e in next.amounts.entries)
        e.key: math.min(math.max(balances[e.key] ?? 0, 0), e.value),
    };
