import 'package:flutter_test/flutter_test.dart';
import 'package:budgetseal/core/database/app_database.dart';
import 'package:budgetseal/features/settings/change_log_screen.dart';

Transaction _tx(String id, DateTime at, {bool deleted = false, String type = 'expense'}) =>
    Transaction(
      id: id,
      householdId: 'hh',
      type: type,
      accountId: 'a',
      amount: 10,
      currency: 'USD',
      exchangeRateToBase: 1,
      note: '',
      createdBy: 'user',
      deviceId: 'local',
      createdAt: at,
      lastModified: at,
      deleted: deleted,
    );

void main() {
  final t0 = DateTime(2026, 10, 24, 12);

  test('an edit (new row + old deleted moments later) reads as one edit', () {
    final log = buildChangeLog([
      _tx('new', t0),
      _tx('old', t0.add(const Duration(seconds: 1)), deleted: true),
      _tx('other', t0.subtract(const Duration(hours: 2))),
    ]);
    expect(log.map((e) => (e.tx.id, e.kind)).toList(), [
      ('new', ChangeKind.edited),
      ('other', ChangeKind.added),
    ]);
  });

  test('a delete on its own stays a delete; types must match to pair', () {
    final log = buildChangeLog([
      _tx('inc', t0, type: 'income'),
      _tx('gone', t0.add(const Duration(seconds: 2)), deleted: true),
      _tx('late', t0.add(const Duration(minutes: 5)), deleted: true),
    ]);
    expect(log.map((e) => (e.tx.id, e.kind)).toList(), [
      ('late', ChangeKind.deleted),
      ('gone', ChangeKind.deleted),
      ('inc', ChangeKind.added),
    ]);
  });
}
