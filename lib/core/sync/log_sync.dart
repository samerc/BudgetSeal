import 'dart:convert';

import 'package:drift/drift.dart';

import '../../shared/utils/format_number.dart' show isRealRate;
import '../database/app_database.dart';
import 'cloud_provider.dart';
import 'op_log.dart';
import 'sync_encryption.dart';

/// Where the phones of a household keep their logs: a folder of files,
/// read and written whole (Google Drive, or a folder on the phone).
abstract class LogStore {
  /// The log files there, name → a version that changes whenever the file
  /// does (Drive's checksum, a local file's size and time).
  Future<Map<String, String>> list();
  Future<String?> read(String name);
  Future<void> write(String name, String content);
}

/// A [CloudProvider]'s folder as a [LogStore].
class ProviderLogStore implements LogStore {
  final CloudProvider provider;
  ProviderLogStore(this.provider);

  @override
  Future<Map<String, String>> list() => provider.listLogFiles();

  @override
  Future<String?> read(String name) => provider.readLogFile(name);

  @override
  Future<void> write(String name, String content) =>
      provider.writeLogFile(name, content);
}

/// Log sync (roadmap #1, step 2): each phone writes its own changes as
/// `log-<device>-<nnnnn>.json` files of [chunkSize] entries, and applies
/// the other phones' entries.
///
/// Merging is per field: of all entries for a row, each column takes the
/// value of the newest entry that set it; the row exists when its newest
/// insert/delete is an insert. That doesn't depend on the order entries
/// arrive in, so every phone ends with the same rows. Entries from other
/// phones are kept in `sync_ops` too (they decide later merges, and
/// Change history will read them).
class LogSync {
  final AppDatabase db;
  final int chunkSize;

  LogSync(this.db, {this.chunkSize = 1000});

  static final _name = RegExp(r'^log-(.+)-(\d{5})\.json$');
  static String fileName(String device, int chunk) =>
      'log-$device-${chunk.toString().padLeft(5, '0')}.json';

  /// One round: apply the other phones' new entries, then write this
  /// phone's. Returns how many entries were applied.
  Future<int> sync(LogStore store) async {
    final applied = await pull(store);
    await push(store);
    return applied;
  }

  /// Reads the other phones' changed files and applies what's new.
  Future<int> pull(LogStore store) async {
    final me = await _me();
    final files = await store.list();
    final seen = await _seenVersions();
    final incoming = <SyncOp>[];
    final versions = <String, String>{};
    for (final MapEntry(key: name, value: version) in files.entries) {
      final m = _name.firstMatch(name);
      if (m == null || m.group(1) == me || seen[name] == version) continue;
      final raw = await store.read(name);
      if (raw == null) continue;
      incoming.addAll(_decode(await SyncEncryption.decrypt(raw)));
      versions[name] = version;
    }
    final applied = await apply(incoming);
    await db.batch((b) {
      for (final e in versions.entries) {
        b.customStatement(
            'INSERT OR REPLACE INTO sync_files (name, version) VALUES (?, ?)',
            [e.key, e.value]);
      }
    });
    return applied;
  }

  /// Writes this phone's entries: only the files with entries not yet
  /// written (normally the last one).
  Future<void> push(LogStore store) async {
    final me = await _me();
    final rows = await db.customSelect(
        'SELECT * FROM sync_ops WHERE device = ? ORDER BY seq',
        variables: [Variable.withString(me)]).get();
    final mine = [for (final r in rows) SyncOp.fromRow(r)];
    if (mine.isEmpty) return;
    final written = await _meta('pushed_seq_$me');
    final lastSeq = mine.last.seq;
    if (written != null && int.parse(written) >= lastSeq) return;
    final writtenSeq = written == null ? null : int.parse(written);
    for (var chunk = 0; chunk * chunkSize < mine.length; chunk++) {
      final part = mine.sublist(chunk * chunkSize,
          (chunk + 1) * chunkSize > mine.length
              ? mine.length
              : (chunk + 1) * chunkSize);
      if (writtenSeq != null && part.last.seq <= writtenSeq) continue;
      await store.write(fileName(me, chunk),
          await SyncEncryption.encrypt(_encode(me, chunk, part)));
    }
    await _setMeta('pushed_seq_$me', '$lastSeq');
  }

  /// Household ids in the store's logs (connecting: is it this budget?).
  Future<Set<String>> householdIdsIn(LogStore store) async {
    final ids = <String>{};
    for (final name in (await store.list()).keys) {
      if (_name.firstMatch(name) == null) continue;
      final raw = await store.read(name);
      if (raw == null) continue;
      for (final op in _decode(await SyncEncryption.decrypt(raw))) {
        if (op.table == 'households' && op.kind == 'insert') ids.add(op.rowId);
      }
    }
    return ids;
  }

  /// Replaces this phone's data with what the store's logs hold (joining
  /// a household, or connecting to another budget's folder).
  Future<int> replaceFrom(LogStore store) async {
    await db.transaction(() async {
      await db.customStatement('UPDATE sync_clock SET applying = 1 WHERE id = 1');
      for (final t in opLogTables.reversed) {
        await db.customStatement('DELETE FROM $t');
      }
      await db.customStatement('DELETE FROM sync_ops');
      await db.customStatement('DELETE FROM sync_files');
      await db.customStatement("DELETE FROM sync_meta");
      await db.customStatement('UPDATE sync_clock SET applying = 0 WHERE id = 1');
    });
    return pull(store);
  }

  /// Stores [ops] that are new here and merges the rows they touch.
  /// Returns how many were new.
  Future<int> apply(List<SyncOp> ops) async {
    if (ops.isEmpty) return 0;
    var added = 0;
    final touched = <String, Set<String>>{};
    var newestMs = 0;
    await db.transaction(() async {
      final have = <String>{
        for (final r in await db
            .customSelect('SELECT device, seq FROM sync_ops')
            .get())
          '${r.read<String>('device')}:${r.read<int>('seq')}',
      };
      await db.batch((b) {
        for (final op in ops) {
          if (!have.add('${op.device}:${op.seq}')) continue;
          added++;
          (touched[op.table] ??= {}).add(op.rowId);
          final ms = int.tryParse(op.hlc.split('-').first) ?? 0;
          if (ms > newestMs) newestMs = ms;
          b.customStatement(
            'INSERT INTO sync_ops (hlc, device, seq, tbl, row_id, kind, data, old) '
            'VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
            [
              op.hlc, op.device, op.seq, op.table, op.rowId, op.kind,
              op.data == null ? null : jsonEncode(op.data),
              op.old == null ? null : jsonEncode(op.old),
            ],
          );
        }
      });
      if (added == 0) return;
      // Our next stamps sort after everything we've seen.
      await db.customStatement(
          'UPDATE sync_clock SET ms = MAX(ms, ?) WHERE id = 1', [newestMs]);
      await db.customStatement('UPDATE sync_clock SET applying = 1 WHERE id = 1');
      try {
        for (final MapEntry(key: table, value: ids) in touched.entries) {
          await _merge(table, ids);
        }
        await settleTransactions(db, await _transactionsOf(ops, touched));
      } finally {
        await db.customStatement(
            'UPDATE sync_clock SET applying = 0 WHERE id = 1');
      }
    });
    return added;
  }

  /// Rebuilds [ids] of [table] from all their entries.
  Future<void> _merge(String table, Set<String> ids) async {
    final columns = {
      for (final t in db.allTables)
        if (t.actualTableName == table)
          for (final c in t.$columns) c.$name,
    };
    final idList = ids.toList();
    for (var i = 0; i < idList.length; i += 500) {
      final chunk = idList.sublist(i, i + 500 > idList.length ? idList.length : i + 500);
      final rows = await db.customSelect(
        'SELECT * FROM sync_ops WHERE tbl = ? AND row_id IN '
        '(${chunk.map((_) => '?').join(', ')})',
        variables: [
          Variable.withString(table),
          for (final id in chunk) Variable.withString(id),
        ],
      ).get();
      final byRow = <String, List<SyncOp>>{};
      for (final r in rows) {
        final op = SyncOp.fromRow(r);
        (byRow[op.rowId] ??= []).add(op);
      }
      for (final MapEntry(key: id, value: ops) in byRow.entries) {
        final row = mergeRow(ops);
        if (row == null) {
          await db.customStatement('DELETE FROM $table WHERE id = ?', [id]);
          continue;
        }
        final values = {
          for (final e in row.entries)
            if (columns.contains(e.key)) e.key: e.value,
        };
        // An update without the insert it belongs to (not here yet).
        if (!values.containsKey('id')) continue;
        await db.customStatement(
            'INSERT OR REPLACE INTO $table (${values.keys.join(', ')}) '
            'VALUES (${values.keys.map((_) => '?').join(', ')})',
            values.values.toList());
      }
    }
  }

  /// The transactions whose header, lines or envelope debits [ops] touched.
  Future<Set<String>> _transactionsOf(
      List<SyncOp> ops, Map<String, Set<String>> touched) async {
    final out = {...?touched['transactions']};
    for (final (table, column) in [
      ('transaction_lines', 'transaction_id'),
      ('allocation_ledger', 'source_transaction_id'),
    ]) {
      final ids = touched[table];
      if (ids == null) continue;
      // An insert or delete carries the whole row; an update may not.
      final lookUp = <String>{};
      for (final op in ops) {
        if (op.table != table || !ids.contains(op.rowId)) continue;
        final tx = (op.data ?? const {})[column] ?? (op.old ?? const {})[column];
        if (tx is String) {
          out.add(tx);
        } else if (op.kind == 'update') {
          lookUp.add(op.rowId);
        }
      }
      final list = lookUp.toList();
      for (var i = 0; i < list.length; i += 500) {
        final chunk = list.sublist(i, i + 500 > list.length ? list.length : i + 500);
        final rows = await db.customSelect(
          'SELECT $column AS tx FROM $table WHERE id IN '
          '(${chunk.map((_) => '?').join(', ')})',
          variables: [for (final id in chunk) Variable.withString(id)],
        ).get();
        for (final r in rows) {
          final tx = r.read<String?>('tx');
          if (tx != null) out.add(tx);
        }
      }
    }
    return out;
  }

  // ── Files ──────────────────────────────────────────────────────

  static String _encode(String device, int chunk, List<SyncOp> ops) =>
      jsonEncode({
        'format': 'budgetseal-log',
        'version': 1,
        'device': device,
        'chunk': chunk,
        'entries': [
          for (final o in ops)
            {
              'hlc': o.hlc,
              'seq': o.seq,
              'table': o.table,
              'row': o.rowId,
              'kind': o.kind,
              if (o.data != null) 'data': o.data,
              if (o.old != null) 'old': o.old,
            },
        ],
      });

  static List<SyncOp> _decode(String json) {
    final m = jsonDecode(json) as Map<String, dynamic>;
    if (m['format'] != 'budgetseal-log') {
      throw const FormatException('Not a BudgetSeal log');
    }
    final device = m['device'] as String;
    return [
      for (final e in (m['entries'] as List).cast<Map<String, dynamic>>())
        SyncOp(
          hlc: e['hlc'] as String,
          device: device,
          seq: e['seq'] as int,
          table: e['table'] as String,
          rowId: e['row'] as String,
          kind: e['kind'] as String,
          data: (e['data'] as Map<String, dynamic>?)?.cast<String, Object?>(),
          old: (e['old'] as Map<String, dynamic>?)?.cast<String, Object?>(),
        ),
    ];
  }

  // ── Bookkeeping ────────────────────────────────────────────────

  /// This phone, as its log stamps it.
  Future<String> _me() async => (await db
          .customSelect('SELECT device FROM sync_clock WHERE id = 1')
          .getSingle())
      .read<String>('device');

  Future<Map<String, String>> _seenVersions() async => {
        for (final r
            in await db.customSelect('SELECT name, version FROM sync_files').get())
          r.read<String>('name'): r.read<String>('version'),
      };

  Future<String?> _meta(String key) async => (await db
          .customSelect('SELECT value FROM sync_meta WHERE key = ?',
              variables: [Variable.withString(key)])
          .getSingleOrNull())
      ?.read<String>('value');

  Future<void> _setMeta(String key, String value) => db.customStatement(
      'INSERT OR REPLACE INTO sync_meta (key, value) VALUES (?, ?)',
      [key, value]);
}

/// After a merge: makes each of [ids] (transactions) whole again. An edit
/// rewrites a transaction's lines and envelope debits under a new
/// `revision` (AllocationEngine `editing:`); when two phones did that,
/// the field merge leaves the newer revision on the header but both
/// phones' lines. Only the current revision's lines and debits are kept,
/// and the header fields that follow from the lines (total, category,
/// account) are recomputed from them — the same on every phone, since
/// they all hold the same rows. Runs while the log is muted, so nothing
/// here is logged.
Future<void> settleTransactions(AppDatabase db, Iterable<String> ids) async {
  for (final id in ids) {
    final tx = await db
        .customSelect(
            'SELECT type, currency, status, revision FROM transactions '
            'WHERE id = ?',
            variables: [Variable.withString(id)])
        .getSingleOrNull();
    final revision = tx?.read<String?>('revision');
    if (tx == null || revision == null) continue;
    final prefix = '$id:$revision:';
    for (final (table, column) in [
      ('transaction_lines', 'transaction_id'),
      ('allocation_ledger', 'source_transaction_id'),
    ]) {
      await db.customStatement(
          'DELETE FROM $table WHERE $column = ? AND substr(id, 1, ?) <> ?',
          [id, prefix.length, prefix]);
    }
    // A plan's header is its first part, not a total — left as merged.
    if (tx.read<String>('type') == 'transfer' ||
        tx.read<String?>('status') != null) {
      continue;
    }
    final lines = (await db
            .customSelect(
                'SELECT id, amount, currency, exchange_rate_to_base AS rate, '
                'category_id, account_id FROM transaction_lines '
                'WHERE transaction_id = ?',
                variables: [Variable.withString(id)])
            .get())
        .map((r) => (
              n: int.tryParse(r.read<String>('id').substring(prefix.length +
                      'line'.length)) ??
                  0,
              amount: r.read<double>('amount'),
              currency: r.read<String>('currency'),
              rate: r.read<double>('rate'),
              category: r.read<String?>('category_id'),
              account: r.read<String?>('account_id'),
            ))
        .toList()
      ..sort((a, b) => a.n.compareTo(b.n));
    if (lines.isEmpty) continue;
    // As AllocationEngine.recordTransaction totals them, in line order.
    final base = tx.read<String>('currency');
    final total = lines.fold(0.0, (sum, l) {
      if (l.currency == base) return sum + l.amount;
      if (!isRealRate(l.currency, base, l.rate)) return sum;
      return sum + l.amount * l.rate;
    });
    await db.customStatement(
        'UPDATE transactions SET amount = ?, category_id = ?, account_id = '
        'COALESCE(?, account_id) WHERE id = ?',
        [
          total,
          lines.length == 1 ? lines.first.category : null,
          lines.first.account,
          id,
        ]);
  }
}

/// The row [ops] (all entries for one row) add up to, or null when it
/// doesn't exist: each column from the newest entry that set it; gone when
/// the newest insert/delete is a delete. Order-independent.
Map<String, Object?>? mergeRow(List<SyncOp> ops) {
  int cmp(SyncOp a, SyncOp b) {
    final c = a.hlc.compareTo(b.hlc);
    if (c != 0) return c;
    final d = a.device.compareTo(b.device);
    return d != 0 ? d : a.seq.compareTo(b.seq);
  }

  final sorted = [...ops]..sort(cmp);
  SyncOp? lastLife;
  for (final op in sorted) {
    if (op.kind != 'update') lastLife = op;
  }
  if (lastLife == null || lastLife.kind == 'delete') {
    // Only updates: the insert hasn't arrived — nothing to build yet.
    return lastLife == null ? const {} : null;
  }
  final row = <String, Object?>{};
  for (final op in sorted) {
    if (op.kind == 'delete') continue;
    row.addAll(op.data ?? const {});
  }
  return row;
}
