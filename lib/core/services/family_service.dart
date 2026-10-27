import 'package:drift/drift.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../engine/allocation_engine.dart';
import 'household_members.dart';

/// Money requests and the monthly review (roadmap #5).
class FamilyService {
  final AppDatabase db;
  FamilyService(this.db);

  /// A kid asks for [amount] in [currency] into their envelope.
  Future<String> ask({
    required String householdId,
    required String allocationId,
    required double amount,
    required String currency,
    String note = '',
  }) async {
    final id = const Uuid().v4();
    await db.into(db.moneyRequests).insert(MoneyRequestsCompanion.insert(
          id: id,
          householdId: householdId,
          fromDeviceId: DeviceIdentity.id,
          allocationId: allocationId,
          amount: amount,
          currency: currency,
          note: Value(note),
        ));
    return id;
  }

  /// A grown-up approves: the envelope is funded from Ready to assign
  /// (ledger id `req:<id>`, so two grown-ups approving the same request
  /// on their phones before syncing fund it once). False when it was
  /// already decided.
  Future<bool> approve(String requestId, {String note = ''}) =>
      db.transaction(() async {
        final r = await _open(requestId);
        if (r == null) return false;
        await AllocationEngine(db).fundAllocation(
          id: 'req:$requestId',
          allocationId: r.allocationId,
          amount: r.amount,
          currency: r.currency,
          deviceId: 'local',
          note: note.isEmpty ? r.note : note,
        );
        await _decide(requestId, 'approved');
        return true;
      });

  Future<bool> decline(String requestId) => db.transaction(() async {
        if (await _open(requestId) == null) return false;
        await _decide(requestId, 'declined');
        return true;
      });

  Future<MoneyRequest?> _open(String id) => (db.select(db.moneyRequests)
        ..where((r) =>
            r.id.equals(id) & r.status.equals('open') & r.deleted.equals(false)))
      .getSingleOrNull();

  Future<void> _decide(String id, String status) =>
      (db.update(db.moneyRequests)..where((r) => r.id.equals(id))).write(
          MoneyRequestsCompanion(
              status: Value(status),
              decidedBy: Value(DeviceIdentity.id),
              lastModified: Value(DateTime.now())));

  static String periodKey(DateTime start) =>
      DateFormat('yyyy-MM-dd').format(start);

  /// This grown-up has reviewed the period starting [periodStart].
  Future<void> confirmReview(String householdId, DateTime periodStart) async {
    final period = periodKey(periodStart);
    await db.into(db.monthReviews).insert(
          MonthReviewsCompanion.insert(
            id: '$period:${DeviceIdentity.id}',
            householdId: householdId,
            period: period,
            deviceId: DeviceIdentity.id,
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  /// Who has reviewed the period starting [periodStart] (devices).
  Future<Set<String>> reviewedBy(String householdId, DateTime periodStart) async {
    final rows = await (db.select(db.monthReviews)
          ..where((r) =>
              r.householdId.equals(householdId) &
              r.period.equals(periodKey(periodStart))))
        .get();
    return {for (final r in rows) r.deviceId};
  }
}
