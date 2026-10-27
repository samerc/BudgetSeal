import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import '../../shared/utils/format_number.dart' show isRealRate;
import '../database/app_database.dart';
import '../engine/base_currency_change.dart';
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

  /// Write a new snapshot once the log has grown by this many entries.
  final int snapshotEvery;

  LogSync(this.db, {this.chunkSize = 1000, this.snapshotEvery = 10000});

  static final _name = RegExp(r'^log-(.+)-(\d{5})\.json$');
  static String fileName(String device, int chunk) =>
      'log-$device-${chunk.toString().padLeft(5, '0')}.json';

  /// A phone's snapshot: the whole log it holds, compacted ([compactOps]).
  /// Named `log-…` so stores list it with the logs; the log-file pattern
  /// doesn't match it.
  static final _snapName = RegExp(r'^log-snapshot-(.+)\.json$');
  static String snapshotName(String device) => 'log-snapshot-$device.json';

  /// One round: apply the other phones' new entries, then write this
  /// phone's (and a snapshot when the log has grown enough). Returns how
  /// many entries were applied.
  Future<int> sync(LogStore store) async {
    final applied = await pull(store);
    await push(store);
    await _snapshotIfDue(store);
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
  /// a household, or connecting to another budget's folder): the most
  /// complete snapshot, then only the log files past it.
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
    final files = await store.list();
    ({Map<String, int> covers, List<SyncOp> ops})? best;
    for (final name in files.keys) {
      if (_snapName.firstMatch(name) == null) continue;
      final raw = await store.read(name);
      if (raw == null) continue;
      try {
        final snap = _decodeSnapshot(await SyncEncryption.decrypt(raw));
        int sum(Map<String, int> m) => m.values.fold(0, (a, b) => a + b);
        if (best == null || sum(snap.covers) > sum(best.covers)) best = snap;
      } on FormatException catch (e) {
        debugPrint('[LogSync] Skipping snapshot $name: $e');
      }
    }
    var applied = 0;
    if (best != null) {
      applied = await apply(best.ops);
      // Full files it covers needn't be read (a full file never changes).
      await db.batch((b) {
        for (final MapEntry(key: name, value: version) in files.entries) {
          final m = _name.firstMatch(name);
          if (m == null) continue;
          final held = best!.covers[m.group(1)!] ?? 0;
          if ((int.parse(m.group(2)!) + 1) * chunkSize <= held) {
            b.customStatement(
                'INSERT OR REPLACE INTO sync_files (name, version) VALUES (?, ?)',
                [name, version]);
          }
        }
      });
    }
    return applied + await pull(store);
  }

  /// Writes this phone's snapshot when the log has grown by
  /// [snapshotEvery] entries since the last one.
  Future<void> _snapshotIfDue(LogStore store) async {
    final total = (await db
            .customSelect('SELECT COUNT(*) AS n FROM sync_ops')
            .getSingle())
        .read<int>('n');
    final last = int.tryParse(await _meta('snapshot_entries') ?? '') ?? 0;
    if (total - last < snapshotEvery) return;
    await writeSnapshot(store);
  }

  /// Writes this phone's snapshot: every entry it holds, compacted, and
  /// how many of each phone's entries that is (they're a prefix of that
  /// phone's files, so a joining phone knows which files it still needs).
  Future<void> writeSnapshot(LogStore store) async {
    final me = await _me();
    final ops = await loadOps(db);
    final covers = <String, int>{};
    for (final op in ops) {
      covers[op.device] = (covers[op.device] ?? 0) + 1;
    }
    await store.write(
        snapshotName(me),
        await SyncEncryption.encrypt(jsonEncode({
          'format': 'budgetseal-snapshot',
          'version': 1,
          'device': me,
          'covers': covers,
          // An entry's device is the end of its stamp.
          'entries': [for (final o in compactOps(ops)) _entry(o)],
        })));
    await _setMeta('snapshot_entries', '${ops.length}');
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
      if (touched.containsKey('households') ||
          touched.containsKey('transactions')) {
        await convertToCurrentBase(db);
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

  static Map<String, Object?> _entry(SyncOp o) => {
        'hlc': o.hlc,
        'seq': o.seq,
        'table': o.table,
        'row': o.rowId,
        'kind': o.kind,
        if (o.data != null) 'data': o.data,
        if (o.old != null) 'old': o.old,
      };

  static SyncOp _op(Map<String, dynamic> e, String device) => SyncOp(
        hlc: e['hlc'] as String,
        device: device,
        seq: e['seq'] as int,
        table: e['table'] as String,
        rowId: e['row'] as String,
        kind: e['kind'] as String,
        data: (e['data'] as Map<String, dynamic>?)?.cast<String, Object?>(),
        old: (e['old'] as Map<String, dynamic>?)?.cast<String, Object?>(),
      );

  static String _encode(String device, int chunk, List<SyncOp> ops) =>
      jsonEncode({
        'format': 'budgetseal-log',
        'version': 1,
        'device': device,
        'chunk': chunk,
        'entries': [for (final o in ops) _entry(o)],
      });

  static List<SyncOp> _decode(String json) {
    final m = jsonDecode(json) as Map<String, dynamic>;
    if (m['format'] != 'budgetseal-log') {
      throw const FormatException('Not a BudgetSeal log');
    }
    final device = m['device'] as String;
    return [
      for (final e in (m['entries'] as List).cast<Map<String, dynamic>>())
        _op(e, device),
    ];
  }

  static ({Map<String, int> covers, List<SyncOp> ops}) _decodeSnapshot(
      String json) {
    final m = jsonDecode(json) as Map<String, dynamic>;
    if (m['format'] != 'budgetseal-snapshot') {
      throw const FormatException('Not a BudgetSeal snapshot');
    }
    return (
      covers: (m['covers'] as Map<String, dynamic>).cast<String, int>(),
      ops: [
        for (final e in (m['entries'] as List).cast<Map<String, dynamic>>())
          _op(e, (e['hlc'] as String).substring(23)),
      ],
    );
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
/// here is logged (it runs again whenever the rows are merged again).
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
    final base = tx.read<String>('currency');
    await db.customStatement(
        'UPDATE transactions SET amount = ?, category_id = ?, account_id = '
        'COALESCE(?, account_id) WHERE id = ?',
        [
          _baseTotal([for (final l in lines) (l.currency, l.amount, l.rate)],
              base),
          lines.length == 1 ? lines.first.category : null,
          lines.first.account,
          id,
        ]);
  }
}

/// As AllocationEngine.recordTransaction totals lines, in their order:
/// lines in another currency without a rate are left out.
double _baseTotal(List<(String, double, double)> lines, String base) =>
    lines.fold(0.0, (sum, l) {
      final (currency, amount, rate) = l;
      if (currency == base) return sum + amount;
      if (!isRealRate(currency, base, rate)) return sum;
      return sum + amount * rate;
    });

/// After a merge: a posted income/expense whose total is still in an
/// earlier base currency — another phone recorded it before hearing of a
/// base change — is converted as `changeBaseCurrency()` would have, with
/// the rates in `households.baseHistory`. Logged like any change (the log
/// must hold the converted rates, or merging the rows again would bring
/// the old ones back); every phone that does it writes the same values.
/// Returns how many were converted.
Future<int> convertToCurrentBase(AppDatabase db) async {
  final rows = await db.customSelect(
    'SELECT t.id, t.currency, h.base_currency AS base, '
    'h.base_history AS history FROM transactions t '
    'JOIN households h ON h.id = t.household_id '
    "WHERE t.type <> 'transfer' AND t.status IS NULL "
    'AND t.currency <> h.base_currency ORDER BY t.id',
  ).get();
  var converted = 0;
  for (final r in rows) {
    final id = r.read<String>('id');
    final base = r.read<String>('base');
    final steps = basePath(baseChanges(r.read<String?>('history')),
        r.read<String>('currency'), base);
    if (steps == null) continue; // no known way from there to here
    double convert(String currency, double rate) {
      for (final c in steps) {
        rate = convertedRateToBase(currency, rate, c.from, c.to, c.rate);
      }
      return rate;
    }

    final lines = await db.customSelect(
        'SELECT id, amount, currency, exchange_rate_to_base AS rate '
        'FROM transaction_lines WHERE transaction_id = ? ORDER BY id',
        variables: [Variable.withString(id)]).get();
    final total = <(String, double, double)>[];
    for (final l in lines) {
      final rate = convert(l.read<String>('currency'), l.read<double>('rate'));
      total.add((l.read<String>('currency'), l.read<double>('amount'), rate));
      await db.customStatement(
          'UPDATE transaction_lines SET exchange_rate_to_base = ? WHERE id = ?',
          [rate, l.read<String>('id')]);
    }
    for (final e in await db.customSelect(
        'SELECT id, currency, exchange_rate_to_base AS rate '
        'FROM allocation_ledger WHERE source_transaction_id = ?',
        variables: [Variable.withString(id)]).get()) {
      await db.customStatement(
          'UPDATE allocation_ledger SET exchange_rate_to_base = ? WHERE id = ?',
          [
            convert(e.read<String>('currency'), e.read<double>('rate')),
            e.read<String>('id'),
          ]);
    }
    await db.customStatement(
        'UPDATE transactions SET amount = ?, currency = ? WHERE id = ?',
        [_baseTotal(total, base), base, id]);
    converted++;
  }
  return converted;
}

/// [ops] reduced to the entries that still decide something, each cut
/// down to what it decides: per row, the newest insert/delete, and for
/// each column the newest entry that set it (with only the columns it
/// wins; `old` dropped). [mergeRow] gives the same rows from them, now and
/// with any entries still to come — a field only ever takes its newest
/// value, a row its newest insert/delete.
List<SyncOp> compactOps(List<SyncOp> ops) {
  final byRow = <(String, String), List<SyncOp>>{};
  for (final op in ops) {
    (byRow[(op.table, op.rowId)] ??= []).add(op);
  }
  final out = <SyncOp>[];
  for (final rowOps in byRow.values) {
    rowOps.sort(_stampOrder);
    SyncOp? life;
    final winner = <String, SyncOp>{};
    for (final op in rowOps) {
      if (op.kind != 'update') life = op;
      if (op.kind == 'delete') continue;
      for (final k in (op.data ?? const <String, Object?>{}).keys) {
        winner[k] = op;
      }
    }
    for (final op in rowOps) {
      final wins = {
        for (final e in winner.entries)
          if (identical(e.value, op)) e.key: op.data![e.key],
      };
      if (!identical(op, life) && wins.isEmpty) continue;
      out.add(SyncOp(
        hlc: op.hlc,
        device: op.device,
        seq: op.seq,
        table: op.table,
        rowId: op.rowId,
        kind: op.kind,
        data: op.kind == 'delete' ? null : wins,
      ));
    }
  }
  return out;
}

int _stampOrder(SyncOp a, SyncOp b) {
  final c = a.hlc.compareTo(b.hlc);
  if (c != 0) return c;
  final d = a.device.compareTo(b.device);
  return d != 0 ? d : a.seq.compareTo(b.seq);
}

/// The row [ops] (all entries for one row) add up to, or null when it
/// doesn't exist: each column from the newest entry that set it; gone when
/// the newest insert/delete is a delete. Order-independent.
Map<String, Object?>? mergeRow(List<SyncOp> ops) {
  final sorted = [...ops]..sort(_stampOrder);
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
