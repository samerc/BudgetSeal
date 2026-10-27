import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../database/daos/transactions_dao.dart';
import '../sync/op_log.dart';

enum ChangeKind { added, edited, deleted, restored }

/// One thing an edit changed.
class FieldChange {
  /// 'type' | 'amount' | 'category' | 'account' | 'date' | 'note'
  final String field;

  /// amount: `Map<String, double>` per currency · category, account:
  /// `List<String?>` of ids (a transfer's account: from, to) · date:
  /// [DateTime] · note, type: [String].
  final Object? from;
  final Object? to;
  const FieldChange(this.field, this.from, this.to);
}

/// One entry of the change history.
class ChangeEvent {
  final ChangeKind kind;
  final Transaction tx; // the row as it is now
  final DateTime at;

  /// The device that made the change (member names), or null when no one
  /// should be named (a bill posted by itself).
  final String? by;

  /// 'bill' (posted by a recurring bill), 'web' (Web Companion) or null.
  final String? source;

  /// Per currency, as of this change (never summed across currencies; a
  /// transfer has its sent amount).
  final Map<String, double> amounts;

  /// Edits: what changed.
  final List<FieldChange> changes;

  /// Edits: another device's later edit, made without seeing this one,
  /// changed the same thing — that one is what stuck (sync keeps the later
  /// edit; both stay in the history).
  final String? replacedBy;

  const ChangeEvent(
    this.kind,
    this.tx,
    this.at, {
    this.by,
    this.source,
    this.amounts = const {},
    this.changes = const [],
    this.replacedBy,
  });
}

/// The change history of rows from before the operation log, from the
/// rows alone: a row's `lastModified` is when it was saved, or when it was
/// deleted. Back then an edit saved a new row and deleted the old one
/// within moments, so a deleted row and a live row of the same type within
/// [pairWindow] read as one "edited". Newest first.
List<ChangeEvent> buildChangeLog(List<Transaction> rows,
    {Duration pairWindow = const Duration(seconds: 10)}) {
  final live = rows.where((t) => !t.deleted).toList();
  final deleted = rows.where((t) => t.deleted).toList();
  final edited = <String>{};
  final pairedDeleted = <String>{};
  for (final d in deleted) {
    Transaction? best;
    var bestGap = pairWindow;
    for (final a in live) {
      if (edited.contains(a.id) || a.type != d.type) continue;
      final gap = a.lastModified.difference(d.lastModified).abs();
      if (gap <= bestGap) {
        best = a;
        bestGap = gap;
      }
    }
    if (best != null) {
      edited.add(best.id);
      pairedDeleted.add(d.id);
    }
  }
  final out = <ChangeEvent>[
    for (final a in live)
      ChangeEvent(edited.contains(a.id) ? ChangeKind.edited : ChangeKind.added,
          a, a.lastModified),
    for (final d in deleted)
      if (!pairedDeleted.contains(d.id))
        ChangeEvent(ChangeKind.deleted, d, d.lastModified),
  ]..sort((a, b) => b.at.compareTo(a.at));
  return out;
}

/// The newest [limit] changes to posted transactions, newest first, read
/// from the operation log (`sync_ops`, every phone's changes): one entry
/// per save — the transaction's entry plus the line and envelope entries
/// written with it — with what an edit changed and whether a later edit
/// from another phone replaced it. Changes from before the log come from
/// the rows ([buildChangeLog]).
Future<List<ChangeEvent>> loadChangeLog(AppDatabase db, String householdId,
    {int limit = 300}) async {
  // Transaction entries with real stamps, newest first — not the
  // last_modified bumps, nor purges.
  final heads = [
    for (final r in await db.customSelect(
      "SELECT * FROM sync_ops WHERE tbl = 'transactions' AND kind <> 'delete' "
      "AND hlc >= '0000000000001' AND NOT (kind = 'update' AND "
      "(SELECT COUNT(*) FROM json_each(data)) = 1 AND "
      r"json_extract(data, '$.last_modified') IS NOT NULL) "
      'ORDER BY hlc DESC LIMIT ?',
      variables: [Variable.withInt(limit)],
    ).get())
      SyncOp.fromRow(r),
  ];

  // Each device's entries around them: a save writes the transaction's
  // entry first, then its lines and debits.
  final byDevice = <String, List<SyncOp>>{};
  for (final h in heads) {
    (byDevice[h.device] ??= []).add(h);
  }
  final events = <_Draft>[];
  for (final MapEntry(key: device, value: list) in byDevice.entries) {
    list.sort((a, b) => a.seq.compareTo(b.seq));
    final ops = {
      for (final r in await db.customSelect(
        'SELECT * FROM sync_ops WHERE device = ? AND seq BETWEEN ? AND ?',
        variables: [
          Variable.withString(device),
          Variable.withInt(list.first.seq),
          Variable.withInt(list.last.seq + 400),
        ],
      ).get())
        r.read<int>('seq'): SyncOp.fromRow(r),
    };
    _Draft? current;
    for (final h in list) {
      // Receipts saved right after are part of the save.
      if (current != null && current.txId == h.rowId && h.seq <= current.end) {
        continue;
      }
      final run = <SyncOp>[h];
      var seq = h.seq + 1;
      while (ops[seq] != null && _partOf(ops[seq]!, h)) {
        run.add(ops[seq++]!);
      }
      current = _Draft(h, run, seq - 1);
      events.add(current);
    }
  }

  // The transactions as they are now, with their lines.
  final txIds = {for (final e in events) e.txId};
  final rows = <String, Transaction>{};
  for (final chunk in chunked(txIds)) {
    for (final t in await (db.select(db.transactions)
          ..where((t) => t.id.isIn(chunk)))
        .get()) {
      rows[t.id] = t;
    }
  }
  // Every transaction entry for them, to see which edits were replaced.
  final history = <String, List<SyncOp>>{};
  for (final chunk in chunked(txIds)) {
    for (final r in await db.customSelect(
      "SELECT * FROM sync_ops WHERE tbl = 'transactions' AND row_id IN "
      "(${chunk.map((_) => '?').join(', ')}) AND hlc >= '0000000000001'",
      variables: [for (final id in chunk) Variable.withString(id)],
    ).get()) {
      final op = SyncOp.fromRow(r);
      (history[op.rowId] ??= []).add(op);
    }
  }

  // Changes from before the log.
  final firstStamp = (await db
          .customSelect(
              "SELECT MIN(hlc) AS h FROM sync_ops WHERE hlc >= '0000000000001'")
          .getSingle())
      .read<String?>('h');
  final legacyRows = await (db.select(db.transactions)
        ..where((t) =>
            t.householdId.equals(householdId) &
            (t.status.isNull() | t.deleted.equals(true)))
        ..where((t) => firstStamp == null
            ? const Constant(true)
            : t.lastModified.isSmallerThanValue(_stampTime(firstStamp)))
        ..orderBy([(t) => OrderingTerm.desc(t.lastModified)])
        ..limit(limit))
      .get();

  final lines = await TransactionsDao(db).linesByTransaction(
      {...txIds, for (final t in legacyRows) t.id});

  final out = <ChangeEvent>[];
  for (final d in events) {
    final tx = rows[d.txId];
    // Purged, another budget's, or a planned payment (not history yet).
    if (tx == null || tx.householdId != householdId) continue;
    if (tx.status != null && !tx.deleted) continue;
    final e = d.build(tx, lines[tx.id] ?? const [], history[tx.id] ?? const []);
    if (e != null) out.add(e);
  }
  for (final e in buildChangeLog(legacyRows)) {
    final tx = e.tx;
    final bill = tx.id.startsWith('rec:');
    out.add(ChangeEvent(
      e.kind,
      tx,
      e.at,
      // A delete is the old row's: it names who saved it, not who deleted
      // it — left out.
      by: e.kind == ChangeKind.deleted || bill ? null : tx.deviceId,
      source: bill ? 'bill' : (tx.deviceId == 'web' ? 'web' : null),
      amounts: _amounts(tx, lines[tx.id] ?? const []),
    ));
  }
  out.sort((a, b) => b.at.compareTo(a.at));
  return out.length > limit ? out.sublist(0, limit) : out;
}

DateTime _stampTime(String hlc) =>
    DateTime.fromMillisecondsSinceEpoch(int.parse(hlc.split('-').first));

/// Whether [op], right after [head] on the same device, is part of the
/// same save: a line or envelope entry of the transaction, the
/// `last_modified` bump, or receipts attached within two seconds. Any
/// other change to the transaction is a save of its own.
bool _partOf(SyncOp op, SyncOp head) {
  final txId = head.rowId;
  switch (op.table) {
    case 'transaction_lines':
      return _field(op, 'transaction_id') == txId;
    case 'allocation_ledger':
      return _field(op, 'source_transaction_id') == txId;
    case 'transactions':
      if (op.rowId != txId || op.kind != 'update') return false;
      final keys = {...?op.data?.keys}..remove('last_modified');
      if (keys.isEmpty) return true;
      return keys.length == 1 &&
          keys.single == 'receipt_path' &&
          _stampTime(op.hlc).difference(_stampTime(head.hlc)).inSeconds < 2;
    default:
      return false;
  }
}

Object? _field(SyncOp op, String column) =>
    op.data?[column] ?? op.old?[column];

Map<String, double> _amounts(Transaction tx, List<TransactionLine> lines) {
  if (tx.type == 'transfer' || lines.isEmpty) return {tx.currency: tx.amount};
  return _sum([for (final l in lines) (l.currency, l.amount)]);
}

Map<String, double> _sum(Iterable<(String, double)> parts) {
  final out = <String, double>{};
  for (final (currency, amount) in parts) {
    out[currency] = (out[currency] ?? 0) + amount;
  }
  return out;
}

bool _sameMap(Map<String, double> a, Map<String, double> b) =>
    a.length == b.length &&
    a.entries.every((e) => b[e.key] != null && (b[e.key]! - e.value).abs() < 1e-9);

/// One save, before it's matched to the transaction as it is now.
class _Draft {
  final SyncOp head;
  final List<SyncOp> run; // head first
  final int end; // last seq of the save
  _Draft(this.head, this.run, this.end);

  String get txId => head.rowId;

  ChangeEvent? build(
      Transaction tx, List<TransactionLine> nowLines, List<SyncOp> history) {
    // The transaction's fields: new values, and the values before the save.
    final data = <String, Object?>{};
    final old = <String, Object?>{};
    for (final op in run) {
      if (op.table != 'transactions') continue;
      data.addAll(op.data ?? const {});
      for (final e in (op.old ?? const <String, Object?>{}).entries) {
        old.putIfAbsent(e.key, () => e.value);
      }
    }
    // Lines the save removed and wrote.
    final before = [
      for (final op in run)
        if (op.table == 'transaction_lines' && op.kind == 'delete') op.old!,
    ];
    final after = [
      for (final op in run)
        if (op.table == 'transaction_lines' && op.kind == 'insert') op.data!,
    ];

    final sorted = [...history]..sort((a, b) => a.hlc.compareTo(b.hlc));
    // Which device id the row had after this save (an edit only logs it
    // when it changed).
    var device = tx.deviceId;
    for (final op in sorted) {
      if (op.hlc.compareTo(head.hlc) > 0) break;
      final d = op.data?['device_id'];
      if (d is String) device = d;
    }
    if (data['device_id'] case final String d) device = d;

    final ChangeKind kind;
    if (head.kind == 'insert') {
      // A planned payment isn't history until it's paid.
      if (data['status'] != null) return null;
      kind = ChangeKind.added;
    } else if (data.containsKey('deleted')) {
      kind = data['deleted'] == 1 ? ChangeKind.deleted : ChangeKind.restored;
    } else if (data.containsKey('status') && old['status'] != null) {
      kind = ChangeKind.added; // a planned payment paid
    } else {
      kind = ChangeKind.edited;
    }

    final transfer = (data['type'] ?? tx.type) == 'transfer';
    final Map<String, double> amounts;
    if (transfer) {
      amounts = {
        (data['currency'] ?? tx.currency) as String:
            ((data['amount'] ?? tx.amount) as num).toDouble(),
      };
    } else if (after.isNotEmpty) {
      amounts = _sum([
        for (final l in after)
          (l['currency'] as String, (l['amount'] as num).toDouble()),
      ]);
    } else {
      amounts = _amounts(tx, nowLines);
    }

    final changes = <FieldChange>[];
    String? replacedBy;
    if (kind == ChangeKind.edited) {
      if (data.containsKey('type')) {
        changes.add(FieldChange('type', old['type'], data['type']));
      }
      if (transfer && !data.containsKey('type')) {
        if (data.containsKey('amount') || data.containsKey('currency')) {
          changes.add(FieldChange('amount', {
            (old['currency'] ?? data['currency'] ?? tx.currency) as String:
                ((old['amount'] ?? data['amount'] ?? tx.amount) as num)
                    .toDouble(),
          }, amounts));
        }
        if (data.containsKey('account_id') ||
            data.containsKey('destination_account_id')) {
          List<String?> pair(Map<String, Object?> m) => [
                (m['account_id'] ?? tx.accountId) as String?,
                (m['destination_account_id'] ?? tx.destinationAccountId)
                    as String?,
              ];
          changes.add(FieldChange('account', pair(old), pair(data)));
        }
      } else if (before.isNotEmpty && after.isNotEmpty) {
        final from = _sum([
          for (final l in before)
            (l['currency'] as String, (l['amount'] as num).toDouble()),
        ]);
        if (!_sameMap(from, amounts)) {
          changes.add(FieldChange('amount', from, amounts));
        }
        for (final (field, column) in [
          ('category', 'category_id'),
          ('account', 'account_id'),
        ]) {
          List<String?> ids(List<Map<String, Object?>> ls) =>
              {for (final l in ls) l[column] as String?}.toList();
          final a = ids(before), b = ids(after);
          if (a.toSet().difference(b.toSet()).isNotEmpty ||
              b.toSet().difference(a.toSet()).isNotEmpty) {
            changes.add(FieldChange(field, a, b));
          }
        }
      }
      if (data.containsKey('created_at')) {
        DateTime at(Object? s) =>
            DateTime.fromMillisecondsSinceEpoch((s as num).toInt() * 1000);
        changes.add(FieldChange(
            'date', old['created_at'] == null ? null : at(old['created_at']),
            at(data['created_at'])));
      }
      if (data.containsKey('note')) {
        changes.add(FieldChange('note', old['note'], data['note']));
      }

      // What this save set that a later, unaware edit elsewhere changed:
      // that edit's "before" isn't this one's "after".
      const watched = {
        'type', 'note', 'created_at', 'revision', 'destination_account_id',
      };
      final mine = {
        for (final e in data.entries)
          if (watched.contains(e.key) ||
              (transfer && {'amount', 'currency', 'account_id'}.contains(e.key)))
            e.key: e.value,
      };
      for (final op in sorted) {
        if (op.kind != 'update' ||
            op.device == head.device ||
            op.hlc.compareTo(head.hlc) <= 0) {
          continue;
        }
        final hit = mine.keys.any((k) =>
            (op.data ?? const {}).containsKey(k) &&
            (op.old ?? const {})[k] != mine[k]);
        if (hit) {
          replacedBy = op.device;
          break;
        }
      }
    }

    final bill = tx.id.startsWith('rec:') && kind == ChangeKind.added;
    return ChangeEvent(
      kind,
      tx,
      _stampTime(head.hlc),
      by: bill ? null : head.device,
      source: bill ? 'bill' : (device == 'web' ? 'web' : null),
      amounts: amounts,
      changes: changes,
      replacedBy: replacedBy,
    );
  }
}
