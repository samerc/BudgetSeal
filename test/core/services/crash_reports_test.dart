import 'dart:io';

import 'package:budgetseal/core/services/crash_reports.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Directory dir;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    dir = Directory.systemTemp.createTempSync('bs_crash');
    CrashReports.init(prefs, dir);
  });

  tearDown(() async {
    await CrashReports.flush();
    dir.deleteSync(recursive: true);
  });

  StackTrace at(String frame) => StackTrace.fromString('#0 $frame\n#1 main');

  test('off by default: nothing is saved', () async {
    CrashReports.record(StateError('boom'), at('a'), source: 'async');
    await CrashReports.flush();
    expect(CrashReports.enabled, isFalse);
    expect(await CrashReports.load(), isEmpty);
    expect(File('${dir.path}/crash_reports.json').existsSync(), isFalse);
  });

  test('on: newest first, a repeat is counted, not saved again', () async {
    await CrashReports.setEnabled(prefs, true);
    CrashReports.record(StateError('first'), at('a'), source: 'flutter');
    CrashReports.record(StateError('second'), at('b'), source: 'async');
    CrashReports.record(StateError('second'), at('b'), source: 'async');
    await CrashReports.flush();
    final reports = await CrashReports.load();
    expect(reports.map((r) => r.headline),
        ['Bad state: second', 'Bad state: first']);
    expect(reports.first.count, 2);
    expect(reports.first.stack, startsWith('#0 b'));
    // Survives a restart.
    CrashReports.init(prefs, dir);
    expect(CrashReports.enabled, isTrue);
    expect(await CrashReports.load(), hasLength(2));
  });

  test('keeps the newest ${CrashReports.maxReports}', () async {
    await CrashReports.setEnabled(prefs, true);
    for (var i = 0; i < CrashReports.maxReports + 5; i++) {
      CrashReports.record(StateError('e$i'), at('f$i'), source: 'async');
    }
    await CrashReports.flush();
    final reports = await CrashReports.load();
    expect(reports, hasLength(CrashReports.maxReports));
    expect(reports.first.headline, 'Bad state: e${CrashReports.maxReports + 4}');
  });

  test('the shared text carries the error and the versions', () async {
    await CrashReports.setEnabled(prefs, true);
    CrashReports.record(StateError('boom'), at('x'), source: 'platform');
    await CrashReports.flush();
    final text = CrashReports.shareText(await CrashReports.load());
    expect(text, contains('Bad state: boom'));
    expect(text, contains('BudgetSeal '));
    expect(text, contains(Platform.operatingSystem));
    expect(text, contains('platform'));
  });

  test('turning them off deletes them', () async {
    await CrashReports.setEnabled(prefs, true);
    CrashReports.record(StateError('boom'), at('x'), source: 'async');
    await CrashReports.flush();
    await CrashReports.setEnabled(prefs, false);
    expect(await CrashReports.load(), isEmpty);
    expect(prefs.getBool(CrashReports.prefKey), isFalse);
  });

  test('an unreadable file reads as empty and is replaced', () async {
    File('${dir.path}/crash_reports.json').writeAsStringSync('not json');
    await CrashReports.setEnabled(prefs, true);
    expect(await CrashReports.load(), isEmpty);
    CrashReports.record(StateError('boom'), at('x'), source: 'async');
    await CrashReports.flush();
    expect(await CrashReports.load(), hasLength(1));
  });
}
