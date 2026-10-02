import 'dart:async';

import 'package:drift/drift.dart' show TableUpdate;
import 'package:shelf/shelf.dart';

import '../../../core/database/app_database.dart';
import '_validation.dart';

/// Counts database writes — the phone's and the browsers' — so browsers can
/// long-poll `GET /api/changes` and redraw instead of refreshing on focus.
/// Writes within 250 ms are one change; the last 100 changes keep the tables
/// they touched.
class ChangeFeed {
  ChangeFeed(AppDatabase db) {
    _sub = db.tableUpdates().listen((updates) {
      _pending.addAll(updates.map((u) => u.table));
      _debounce ??= Timer(const Duration(milliseconds: 250), _flush);
    });
  }

  late final StreamSubscription<Set<TableUpdate>> _sub;
  final _pending = <String>{};
  final _log = <int, Set<String>>{};
  Timer? _debounce;
  Completer<void>? _waiter;
  int _version = 0;

  int get version => _version;

  void _flush() {
    _debounce = null;
    _version++;
    _log[_version] = {..._pending};
    _pending.clear();
    _log.remove(_version - 100);
    _waiter?.complete();
    _waiter = null;
  }

  /// Tables changed after [since]; null when that's too far back to know.
  Set<String>? tablesSince(int since) {
    if (since >= _version) return {};
    if (!_log.containsKey(since + 1)) return null;
    return {for (var v = since + 1; v <= _version; v++) ...?_log[v]};
  }

  /// Completes on the next change, or after [timeout].
  Future<void> next(Duration timeout) {
    final w = _waiter ??= Completer<void>();
    return w.future.timeout(timeout, onTimeout: () {});
  }

  void dispose() {
    _sub.cancel();
    _debounce?.cancel();
    _waiter?.complete();
    _waiter = null;
  }
}

// ── GET /api/changes?since=N ──────────────────────────────────────────────────
// Answers at once when something changed after version N (or N is unknown,
// e.g. the server restarted), else holds the request up to [wait]. The reply
// is { version, tables } — tables null means "assume everything".

Handler changesHandler(ChangeFeed feed,
    {Duration wait = const Duration(seconds: 25)}) {
  return (Request request) async {
    final since = int.tryParse(request.url.queryParameters['since'] ?? '');
    if (since == null || since < 0 || since > feed.version) {
      return ok({'version': feed.version, 'tables': null});
    }
    if (since == feed.version) await feed.next(wait);
    return ok({
      'version': feed.version,
      'tables': feed.tablesSince(since)?.toList(),
    });
  };
}
