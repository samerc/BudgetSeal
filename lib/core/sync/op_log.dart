import 'dart:convert';

import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../services/household_members.dart' show DeviceIdentity;

/// The operation log: every change to a shared table, in order, so phones
/// can exchange changes instead of whole rows (roadmap #1; design in
/// docs/dev/data.md "Operation log").
///
/// SQLite triggers on [opLogTables] write one entry per change into
/// `sync_ops` — every screen and engine is covered without calling
/// anything. An insert logs the whole row; an update only the fields that
/// changed, with their old values; a delete the deleted row. Each entry has
/// a hybrid logical clock stamp ([SyncOp.hlc]: wall-clock milliseconds,
/// never going backwards, a counter, the device) that sorts the same on
/// every phone, and the device's own sequence number.
///
/// Rows that existed before the log get one starting entry each (stamp
/// "0…", older than any real change), so replaying the log into an empty
/// database rebuilds this one — see [replayOps].
const opLogTables = [
  'households',
  'users',
  'accounts',
  'categories',
  'allocations',
  'transactions',
  'transaction_lines',
  'allocation_ledger',
  'recurring_transactions',
  'transaction_templates',
  'fx_rates',
  'objectives',
];

class SyncOp {
  final String hlc;
  final String device;
  final int seq;
  final String table;
  final String rowId;

  /// 'insert' | 'update' | 'delete'
  final String kind;

  /// Insert: the row. Update: the changed fields' new values. Delete: null.
  final Map<String, Object?>? data;

  /// Update: the changed fields' old values. Delete: the row.
  final Map<String, Object?>? old;

  const SyncOp({
    required this.hlc,
    required this.device,
    required this.seq,
    required this.table,
    required this.rowId,
    required this.kind,
    this.data,
    this.old,
  });

  static Map<String, Object?>? _map(Object? json) => json == null
      ? null
      : (jsonDecode(json as String) as Map<String, dynamic>)
          .cast<String, Object?>();

  factory SyncOp.fromRow(QueryRow r) => SyncOp(
        hlc: r.read<String>('hlc'),
        device: r.read<String>('device'),
        seq: r.read<int>('seq'),
        table: r.read<String>('tbl'),
        rowId: r.read<String>('row_id'),
        kind: r.read<String>('kind'),
        data: _map(r.data['data']),
        old: _map(r.data['old']),
      );
}

/// Starting stamp for rows that predate the log.
const baselineHlc = '0000000000000-00000000';

// SQLite: now, in milliseconds since 1970.
const _nowMs = "CAST((julianday('now') - 2440587.5) * 86400000 AS INTEGER)";

/// Creates the log's tables and triggers (every open; idempotent), points
/// the clock at this device, and logs the existing rows once.
Future<void> ensureOpLog(AppDatabase db) async {
  await db.customStatement('''
    CREATE TABLE IF NOT EXISTS sync_clock (
      id INTEGER PRIMARY KEY CHECK (id = 1),
      device TEXT NOT NULL,
      ms INTEGER NOT NULL,
      counter INTEGER NOT NULL,
      seq INTEGER NOT NULL,
      applying INTEGER NOT NULL DEFAULT 0)''');
  await db.customStatement('''
    CREATE TABLE IF NOT EXISTS sync_ops (
      n INTEGER PRIMARY KEY AUTOINCREMENT,
      hlc TEXT NOT NULL,
      device TEXT NOT NULL,
      seq INTEGER NOT NULL,
      tbl TEXT NOT NULL,
      row_id TEXT NOT NULL,
      kind TEXT NOT NULL,
      data TEXT,
      old TEXT)''');
  await db.customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_sync_ops_id ON sync_ops (device, seq)');
  await db.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_sync_ops_row ON sync_ops (tbl, row_id)');
  await db.customStatement(
      'INSERT OR IGNORE INTO sync_clock (id, device, ms, counter, seq) '
      'VALUES (1, ?, 0, 0, 0)',
      [DeviceIdentity.id]);
  await db.customStatement(
      'UPDATE sync_clock SET device = ?, applying = 0 WHERE id = 1',
      [DeviceIdentity.id]);

  final fresh = (await db
          .customSelect('SELECT COUNT(*) AS n FROM sync_ops')
          .getSingle())
      .read<int>('n') ==
      0;
  for (final table in _tables(db)) {
    await _createTriggers(db, table);
  }
  if (fresh) await _logExistingRows(db);
}

List<TableInfo<Table, dynamic>> _tables(AppDatabase db) => [
      for (final name in opLogTables)
        db.allTables.firstWhere((t) => t.actualTableName == name),
    ];

List<String> _columns(TableInfo<Table, dynamic> t) =>
    [for (final c in t.$columns) c.$name];

String _jsonOf(String alias, List<String> cols) =>
    "json_object(${cols.map((c) => "'$c', $alias.$c").join(', ')})";

/// Advances the clock and logs one entry (the trigger body).
String _logStatement(String table, String kind, String data, String old) => '''
  UPDATE sync_clock SET
    counter = CASE WHEN $_nowMs > ms THEN 0 ELSE counter + 1 END,
    ms = MAX(ms, $_nowMs),
    seq = seq + 1
  WHERE id = 1;
  INSERT INTO sync_ops (hlc, device, seq, tbl, row_id, kind, data, old)
  SELECT printf('%013d-%08d-%s', ms, counter, device), device, seq,
         '$table', ${kind == 'delete' ? 'OLD' : 'NEW'}.id, '$kind', $data, $old
    FROM sync_clock WHERE id = 1;''';

Future<void> _createTriggers(
    AppDatabase db, TableInfo<Table, dynamic> table) async {
  final t = table.actualTableName;
  final cols = _columns(table);
  const live = '(SELECT applying FROM sync_clock WHERE id = 1) = 0';
  // Changed fields only, as {column: value}.
  String changed(String alias) => '(SELECT json_group_object(k, v) FROM ('
      '${cols.map((c) => "SELECT '$c' AS k, $alias.$c AS v WHERE NEW.$c IS NOT OLD.$c").join(' UNION ALL ')}))';
  final anyChange = cols.map((c) => 'NEW.$c IS NOT OLD.$c').join(' OR ');

  // Recreated on every open: the columns follow the current schema.
  for (final kind in ['insert', 'update', 'delete']) {
    await db.customStatement('DROP TRIGGER IF EXISTS oplog_${kind}_$t');
  }
  await db.customStatement('''
    CREATE TRIGGER oplog_insert_$t AFTER INSERT ON $t WHEN $live
    BEGIN ${_logStatement(t, 'insert', _jsonOf('NEW', cols), 'NULL')} END''');
  await db.customStatement('''
    CREATE TRIGGER oplog_update_$t AFTER UPDATE ON $t
    WHEN $live AND ($anyChange)
    BEGIN ${_logStatement(t, 'update', changed('NEW'), changed('OLD'))} END''');
  await db.customStatement('''
    CREATE TRIGGER oplog_delete_$t AFTER DELETE ON $t WHEN $live
    BEGIN ${_logStatement(t, 'delete', 'NULL', _jsonOf('OLD', cols))} END''');
}

/// One starting entry per existing row, in table order.
Future<void> _logExistingRows(AppDatabase db) async {
  final device = DeviceIdentity.id;
  var seq = 0;
  // A negative sequence keeps them apart from the device's own changes.
  for (final table in _tables(db)) {
    final t = table.actualTableName;
    final rows = await db
        .customSelect('SELECT id, ${_jsonOf(t, _columns(table))} AS j FROM $t')
        .get();
    await db.batch((b) {
      for (final r in rows) {
        b.customStatement(
          'INSERT INTO sync_ops (hlc, device, seq, tbl, row_id, kind, data) '
          "VALUES (?, ?, ?, ?, ?, 'insert', ?)",
          ['$baselineHlc-$device', device, --seq, t, r.read<String>('id'),
           r.read<String>('j')],
        );
      }
    });
  }
}

/// The whole log, oldest first.
Future<List<SyncOp>> loadOps(AppDatabase db) async => [
      for (final r in await db
          .customSelect('SELECT * FROM sync_ops ORDER BY hlc, device, seq')
          .get())
        SyncOp.fromRow(r),
    ];

/// Applies [ops] in stamp order without logging them again: an insert puts
/// the row (replacing one with the same id), an update sets the changed
/// fields, a delete removes the row.
Future<void> replayOps(AppDatabase db, Iterable<SyncOp> ops) async {
  final sorted = ops.toList()
    ..sort((a, b) {
      final c = a.hlc.compareTo(b.hlc);
      if (c != 0) return c;
      final d = a.device.compareTo(b.device);
      return d != 0 ? d : a.seq.compareTo(b.seq);
    });
  final known = {
    for (final t in _tables(db)) t.actualTableName: _columns(t).toSet(),
  };
  await db.transaction(() async {
    await db.customStatement('UPDATE sync_clock SET applying = 1 WHERE id = 1');
    try {
      for (final op in sorted) {
        final cols = known[op.table];
        if (cols == null) continue;
        switch (op.kind) {
          case 'insert':
            final row = {
              for (final e in op.data!.entries)
                if (cols.contains(e.key)) e.key: e.value,
            };
            await db.customStatement(
                'INSERT OR REPLACE INTO ${op.table} (${row.keys.join(', ')}) '
                'VALUES (${row.keys.map((_) => '?').join(', ')})',
                row.values.toList());
          case 'update':
            final set = {
              for (final e in op.data!.entries)
                if (cols.contains(e.key) && e.key != 'id') e.key: e.value,
            };
            if (set.isEmpty) continue;
            await db.customStatement(
                'UPDATE ${op.table} SET ${set.keys.map((k) => '$k = ?').join(', ')} '
                'WHERE id = ?',
                [...set.values, op.rowId]);
          case 'delete':
            await db.customStatement(
                'DELETE FROM ${op.table} WHERE id = ?', [op.rowId]);
        }
      }
    } finally {
      await db.customStatement(
          'UPDATE sync_clock SET applying = 0 WHERE id = 1');
    }
  });
}
