import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../shared/utils/format_number.dart' show isRealRate;
import '../database/app_database.dart';
import 'allocation_engine.dart';

/// Looks up a `from → to` exchange rate; null when none is known.
typedef RateLookup = Future<double?> Function(String from, String to);

/// Planned payments: transactions with `status = 'planned'`, one line, in
/// the (source) account's currency at rate 1.0, no ledger rows. Shared by
/// the phone screens (`features/planned/`) and the Web Companion.
class PlannedEngine {
  final AppDatabase _db;
  final AllocationEngine _engine;
  final _uuid = const Uuid();

  PlannedEngine(this._db) : _engine = AllocationEngine(_db);

  /// Id of the transaction a plan becomes when posted. Fixed, so two devices
  /// posting the same plan before they sync write one transaction, not two.
  static String postedId(String planId) => 'planned:$planId';

  /// Creates a plan, or replaces [replaceId] (soft-deleted, its lines
  /// removed) — all in one db transaction. Returns the new plan's id.
  Future<String> save({
    String? replaceId,
    required String householdId,
    required String type,
    required String accountId,
    String? destinationAccountId,
    required double amount,
    required String currency,
    String? categoryId,
    String note = '',
    required DateTime date,
    required String createdBy,
    required String deviceId,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    final isTransfer = type == 'transfer';
    await _db.transaction(() async {
      if (replaceId != null) {
        await (_db.delete(_db.transactionLines)
              ..where((l) => l.transactionId.equals(replaceId)))
            .go();
        await (_db.update(_db.transactions)
              ..where((t) => t.id.equals(replaceId)))
            .write(TransactionsCompanion(
                deleted: const Value(true), lastModified: Value(now)));
      }
      await _db.into(_db.transactions).insert(TransactionsCompanion.insert(
            id: id,
            householdId: householdId,
            type: type,
            accountId: accountId,
            destinationAccountId:
                Value(isTransfer ? destinationAccountId : null),
            amount: amount,
            currency: currency,
            exchangeRateToBase: const Value(1.0),
            categoryId: Value(isTransfer ? null : categoryId),
            createdBy: createdBy,
            deviceId: deviceId,
            note: Value(note),
            createdAt: Value(date),
            status: const Value('planned'),
            lastModified: Value(now),
          ));
      await _db.into(_db.transactionLines).insert(
            TransactionLinesCompanion.insert(
              id: _uuid.v4(),
              transactionId: id,
              amount: amount,
              currency: currency,
              categoryId: Value(isTransfer ? null : categoryId),
              accountId: Value(accountId),
              exchangeRateToBase: const Value(1.0),
            ),
          );
    });
    return id;
  }

  /// Records plan [planId] as a real transaction, then deletes the plan, in
  /// one db transaction (a crash can't leave both, or neither). Returns the
  /// posted transaction's id ([postedId]); a plan that is already posted
  /// (double tap, Post all after Post, the other device) returns that id
  /// without posting again.
  ///
  /// The date is the planned date, or [now] when that is still ahead (paid
  /// early: a future-dated transaction would move balances today but stay
  /// hidden in the Activity tab until its month).
  ///
  /// Rates: the plan was saved at 1.0, so a foreign line takes [rate]
  /// (falling back to 1.0, shown as "No rate"); a transfer between two
  /// currencies without a rate throws [CurrencyConversionException].
  Future<String> post(
    String planId, {
    required String baseCurrency,
    required RateLookup rate,
    required String createdBy,
    required String deviceId,
    DateTime? now,
  }) async {
    final postedTxId = postedId(planId);
    final plan = await _livePlan(planId);
    if (plan == null) {
      if (await _exists(postedTxId)) return postedTxId;
      throw StateError('Planned payment $planId not found');
    }
    final today = now ?? DateTime.now();
    final date = plan.createdAt.isAfter(today) ? today : plan.createdAt;

    // Rates first: a network lookup must not run inside the db transaction.
    double? transferRate;
    var lines = <TxLine>[];
    if (plan.type == 'transfer') {
      final dest = await (_db.select(_db.accounts)
            ..where((a) => a.id.equals(plan.destinationAccountId ?? '')))
          .getSingleOrNull();
      final destCurrency = dest?.currency ?? plan.currency;
      transferRate = plan.currency == destCurrency
          ? 1.0
          : await rate(plan.currency, destCurrency);
      if (transferRate == null) {
        throw CurrencyConversionException(plan.currency, destCurrency);
      }
    } else {
      Future<double> lineRate(String currency, double stored) async {
        if (currency == baseCurrency) return 1.0;
        if (isRealRate(currency, baseCurrency, stored)) return stored;
        return await rate(currency, baseCurrency) ?? 1.0;
      }

      final stored = await (_db.select(_db.transactionLines)
            ..where((l) => l.transactionId.equals(planId)))
          .get();
      lines = [
        for (final l in stored)
          TxLine(
            amount: l.amount,
            currency: l.currency,
            categoryId: l.categoryId,
            accountId: l.accountId,
            exchangeRateToBase: await lineRate(l.currency, l.exchangeRateToBase),
            note: l.note,
          ),
      ];
      // Legacy plans without a line: build it from the header.
      if (lines.isEmpty) {
        lines.add(TxLine(
          amount: plan.amount,
          currency: plan.currency,
          categoryId: plan.categoryId,
          exchangeRateToBase:
              await lineRate(plan.currency, plan.exchangeRateToBase),
        ));
      }
    }

    await _db.transaction(() async {
      // Posted meanwhile (a second tap waited for the first one)?
      if (await _livePlan(planId) == null) return;
      if (plan.type == 'transfer') {
        await _engine.recordTransfer(
          householdId: plan.householdId,
          fromAccountId: plan.accountId,
          toAccountId: plan.destinationAccountId ?? plan.accountId,
          amount: plan.amount,
          currency: plan.currency,
          exchangeRateToBase: transferRate!,
          createdBy: createdBy,
          deviceId: deviceId,
          note: plan.note,
          date: date,
          id: postedTxId,
        );
      } else {
        await _engine.recordTransaction(
          householdId: plan.householdId,
          accountId: plan.accountId,
          type: plan.type,
          lines: lines,
          baseCurrency: baseCurrency,
          note: plan.note,
          deviceId: deviceId,
          date: date,
          id: postedTxId,
        );
      }
      await _engine.deleteTransaction(planId);
    });
    return postedTxId;
  }

  Future<Transaction?> _livePlan(String id) => (_db.select(_db.transactions)
        ..where((t) =>
            t.id.equals(id) &
            t.status.equals('planned') &
            t.deleted.equals(false)))
      .getSingleOrNull();

  Future<bool> _exists(String id) async =>
      await (_db.select(_db.transactions)..where((t) => t.id.equals(id)))
          .getSingleOrNull() !=
      null;
}
