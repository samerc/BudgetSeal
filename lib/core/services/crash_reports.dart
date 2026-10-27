import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/utils/app_info.dart';

/// One saved error.
class CrashReport {
  final DateTime time; // last time it happened
  final String source; // 'flutter' | 'async' | 'platform'
  final String error;
  final String stack;
  final String app;
  final String os;
  final int count;

  const CrashReport({
    required this.time,
    required this.source,
    required this.error,
    required this.stack,
    required this.app,
    required this.os,
    this.count = 1,
  });

  /// The error's first line (the list row).
  String get headline => error.split('\n').first;

  CrashReport again(DateTime at) => CrashReport(
      time: at, source: source, error: error, stack: stack, app: app,
      os: os, count: count + 1);

  Map<String, dynamic> toJson() => {
        'time': time.toUtc().toIso8601String(),
        'source': source,
        'error': error,
        'stack': stack,
        'app': app,
        'os': os,
        'count': count,
      };

  factory CrashReport.fromJson(Map<String, dynamic> m) => CrashReport(
        time: DateTime.parse(m['time'] as String).toLocal(),
        source: m['source'] as String? ?? '',
        error: m['error'] as String? ?? '',
        stack: m['stack'] as String? ?? '',
        app: m['app'] as String? ?? '',
        os: m['os'] as String? ?? '',
        count: m['count'] as int? ?? 1,
      );

  /// As shared: plain text a developer can read.
  String toText() => [
        '${time.toUtc().toIso8601String()} · $source'
            '${count > 1 ? ' · ×$count' : ''}',
        'BudgetSeal $app · $os',
        error,
        if (stack.isNotEmpty) stack,
      ].join('\n');
}

/// Opt-in crash reports, kept on this phone only (BudgetSeal has no
/// servers). Off by default. When on, uncaught errors (main.dart's three
/// handlers) are saved to `crash_reports.json` in the app's support
/// folder: the error, a trimmed stack, the app and system version — the
/// newest [maxReports], a repeat of the newest counted instead of saved
/// again. Settings → Crash reports lists them and shares them through the
/// system share sheet; nothing leaves the phone any other way. Turning
/// them off deletes them.
class CrashReports {
  static const prefKey = 'crash_reports_enabled';
  static const maxReports = 50;
  static const _maxStackLines = 30;
  static const _maxErrorChars = 1000;

  static bool _enabled = false;
  static File? _file;
  // Writes one at a time (errors can come in bursts).
  static Future<void> _queue = Future.value();

  /// Bumped on every change, for the screen and the Settings row.
  static final changes = ValueNotifier<int>(0);

  static bool get enabled => _enabled;

  /// Start-up: reads the setting; [dir] holds the file.
  static void init(SharedPreferences prefs, Directory dir) {
    _enabled = prefs.getBool(prefKey) ?? false;
    _file = File(p.join(dir.path, 'crash_reports.json'));
  }

  static Future<void> setEnabled(SharedPreferences prefs, bool on) async {
    _enabled = on;
    await prefs.setBool(prefKey, on);
    if (!on) await clear();
    changes.value++;
  }

  /// Saves an uncaught error when reports are on. Never throws.
  static void record(Object error, StackTrace? stack,
      {required String source}) {
    if (!_enabled || _file == null) return;
    final at = DateTime.now();
    _queue = _queue.then((_) => _save(error, stack, source, at)).catchError(
        (Object e) => debugPrint('[CrashReports] Saving failed: $e'));
  }

  static Future<void> _save(
      Object error, StackTrace? stack, String source, DateTime at) async {
    var text = error.toString();
    if (text.length > _maxErrorChars) {
      text = '${text.substring(0, _maxErrorChars)}…';
    }
    final frames = (stack?.toString() ?? '')
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .take(_maxStackLines)
        .join('\n');
    final reports = await load();
    final newest = reports.isEmpty ? null : reports.first;
    if (newest != null &&
        newest.error == text &&
        newest.stack.split('\n').first == frames.split('\n').first) {
      reports[0] = newest.again(at);
    } else {
      reports.insert(
          0,
          CrashReport(
            time: at,
            source: source,
            error: text,
            stack: frames,
            app: appBuildNumber.isEmpty
                ? appVersion
                : '$appVersion ($appBuildNumber)',
            os: '${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
          ));
    }
    await _write(reports.take(maxReports).toList());
  }

  /// Newest first.
  static Future<List<CrashReport>> load() async {
    final f = _file;
    if (f == null || !await f.exists()) return [];
    try {
      final list = jsonDecode(await f.readAsString()) as List;
      return [
        for (final m in list) CrashReport.fromJson(m as Map<String, dynamic>)
      ];
    } catch (e) {
      debugPrint('[CrashReports] Unreadable file: $e');
      return [];
    }
  }

  static Future<void> _write(List<CrashReport> reports) async {
    await _file!.parent.create(recursive: true);
    await _file!.writeAsString(
        jsonEncode([for (final r in reports) r.toJson()]),
        flush: true);
    changes.value++;
  }

  static Future<void> clear() async {
    await _queue;
    final f = _file;
    if (f != null && await f.exists()) await f.delete();
    changes.value++;
  }

  /// Every report as one text, for the share sheet.
  static String shareText(List<CrashReport> reports) =>
      reports.map((r) => r.toText()).join('\n\n────────\n\n');

  /// Waits for pending writes (tests).
  @visibleForTesting
  static Future<void> flush() => _queue;
}
