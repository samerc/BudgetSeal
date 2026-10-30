// Unhappy-path tests for data in/out: CSV import, backup/restore, household
// join through the relay, and the Web Companion REST API. Each test acts like
// a user who doesn't know what they're doing and asserts what SHOULD happen:
// no crash, no data lost, no raw exception text, a clear mapped message.
//
// A failing test here is a candidate bug (see the comment above each one).

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:budgetseal/core/database/app_database.dart';
import 'package:budgetseal/core/engine/allocation_engine.dart';
import 'package:budgetseal/core/engine/balance_calculator.dart';
import 'package:budgetseal/core/providers/database_provider.dart';
import 'package:budgetseal/core/providers/household_provider.dart';
import 'package:budgetseal/core/providers/sync_provider.dart';
import 'package:budgetseal/core/services/auto_backup_service.dart';
import 'package:budgetseal/core/services/household_members.dart';
import 'package:budgetseal/core/sync/file_picker_provider.dart';
import 'package:budgetseal/core/sync/household_key.dart';
import 'package:budgetseal/core/sync/log_sync.dart';
import 'package:budgetseal/core/sync/relay_provider.dart';
import 'package:budgetseal/core/sync/sync_encryption.dart';
import 'package:budgetseal/core/sync/sync_engine.dart';
import 'package:budgetseal/features/settings/import_screen.dart'
    show decodeImportBytes, parseImportDate;
import 'package:budgetseal/features/web_companion/api/accounts_handler.dart';
import 'package:budgetseal/features/web_companion/api/envelopes_handler.dart';
import 'package:budgetseal/features/web_companion/api/import_handler.dart';
import 'package:budgetseal/features/web_companion/api/transactions_handler.dart';
import 'package:budgetseal/l10n/generated/app_localizations_en.dart';
import 'package:budgetseal/shared/utils/format_number.dart';
import 'package:csv/csv.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shelf/shelf.dart';
import 'package:sqlite3/sqlite3.dart' as sql;

import '../core/sync/household_relay_test.dart' show FakeRelay;

final en = SEn();

// ── Helpers ──────────────────────────────────────────────────────────────────

/// Hands the handlers a live Ref, like the server does.
final _refProvider = Provider<Ref>((ref) => ref);

Future<Map<String, dynamic>> call(Handler h, String method,
    {Object? body, String? rawBody, String? id}) async {
  final res = await h(Request(
    method,
    Uri.parse('http://localhost/api/x'),
    body: rawBody ?? (body == null ? null : jsonEncode(body)),
    context: {
      if (id != null) 'shelf_router/params': {'id': id},
    },
  ));
  final text = await res.readAsString();
  final json = text.isEmpty ? <String, dynamic>{} : jsonDecode(text);
  return {'status': res.statusCode, ...(json as Map<String, dynamic>)};
}

Future<AppDatabase> openPhone(String device) async {
  DeviceIdentity.debugSet(device);
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  await db.customSelect('SELECT 1').get();
  addTearDown(db.close);
  return db;
}

/// A household [hid] with a USD bank account, a Food category and one
/// expense ([note]) — the budget this phone would lose.
Future<void> seedBudget(AppDatabase db, String hid, String note) async {
  await db.into(db.households).insert(HouseholdsCompanion.insert(
      id: hid, name: 'Home $hid', createdByDeviceId: 'x'));
  await db.into(db.accounts).insert(AccountsCompanion.insert(
      id: '$hid-bank',
      householdId: hid,
      name: 'Bank',
      type: 'bank',
      currency: 'USD',
      initialBalance: const Value(1000),
      deviceId: 'x'));
  await db.into(db.categories).insert(CategoriesCompanion.insert(
      id: '$hid-food', householdId: hid, name: 'Food'));
  await AllocationEngine(db).recordTransaction(
      householdId: hid,
      accountId: '$hid-bank',
      type: 'expense',
      note: note,
      lines: [TxLine(amount: 12.5, currency: 'USD', categoryId: '$hid-food')],
      baseCurrency: 'USD');
}

Future<List<String>> notes(AppDatabase db) async =>
    [for (final t in await db.select(db.transactions).get()) t.note];

/// A relay client that forwards to [relay] unless [fail] answers first
/// (a thrown error = the network dropped; a response = the relay said so).
http.Client flakyClient(FakeRelay relay,
        FutureOr<http.Response?> Function(http.Request r) fail) =>
    MockClient((req) async {
      final f = await fail(req);
      if (f != null) return f;
      final copy = http.Request(req.method, req.url)
        ..headers.addAll(req.headers)
        ..bodyBytes = req.bodyBytes;
      return http.Response.fromStream(await relay.client.send(copy));
    });

/// A [SyncNotifier] on [db] whose relay talks to [client] (the notifier
/// builds its own RelayProvider; http.runWithClient hands it ours).
SyncNotifier syncNotifierFor(AppDatabase db, http.Client client) {
  late ProviderContainer c;
  http.runWithClient(() {
    c = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
    c.read(syncProvider);
  }, () => client);
  addTearDown(c.dispose);
  return c.read(syncProvider.notifier);
}

SyncState stateOf(SyncNotifier n) => n.state;

late Directory docsDir;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    docsDir = Directory.systemTemp.createTempSync('bs_unhappy_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (call) async => docsDir.path);
  });
  tearDownAll(() {
    try {
      docsDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    AutoBackupService.restorePending = false;
  });
  tearDown(() => DeviceIdentity.debugSet('local'));

  // ═══════════════════════════════════════════════════════════════════════
  // CSV import
  // ═══════════════════════════════════════════════════════════════════════

  group('CSV parsing', () {
    test('amounts in bank formats', () {
      expect(parseLooseAmount('1.234,56'), closeTo(1234.56, 1e-9));
      expect(parseLooseAmount('1,234.56'), closeTo(1234.56, 1e-9));
      expect(parseLooseAmount('(12.50)'), closeTo(-12.5, 1e-9));
      expect(parseLooseAmount('12.50-'), closeTo(-12.5, 1e-9));
      expect(parseLooseAmount('-'), isNull);
      expect(parseLooseAmount(''), isNull);
      expect(parseLooseAmount(r'$ 1 234,56'), closeTo(1234.56, 1e-9));
      expect(parseLooseAmount('1.234.567,89'), closeTo(1234567.89, 1e-6));
      expect(parseLooseAmount('n/a'), isNull);
    });

    // CANDIDATE: a cell that isn't an amount at all is read as one — a
    // date mapped to the Amount column becomes an expense of 20 million.
    test('a date in the amount column is not an amount', () {
      expect(parseLooseAmount('2026-01-15'), isNull);
    });

    test('dates in mixed formats: real ones parse, impossible ones skip', () {
      expect(parseImportDate('2026-01-15', dayFirst: false),
          DateTime(2026, 1, 15));
      expect(parseImportDate('15/01/2026', dayFirst: true),
          DateTime(2026, 1, 15));
      expect(parseImportDate('15.01.26', dayFirst: true),
          DateTime(2026, 1, 15));
      expect(parseImportDate('2026-01-15T10:30:00Z', dayFirst: false),
          DateTime(2026, 1, 15));
      expect(parseImportDate('2026-02-30', dayFirst: false), isNull);
      expect(parseImportDate('31/31/2026', dayFirst: true), isNull);
      expect(parseImportDate('Jan 15, 2026', dayFirst: false), isNull);
      expect(parseImportDate('', dayFirst: false), isNull);
    });

    test('semicolon and tab files are split into columns', () {
      final semi = const CsvDecoder()
          .convert('Date;Description;Amount\n2026-01-02;Bakery;-12,50\n');
      expect(semi.first.length, 3);
      expect(semi[1][2].toString(), '-12,50');
      final tab = const CsvDecoder()
          .convert('Date\tDescription\tAmount\n2026-01-02\tBakery\t-12.50\n');
      expect(tab.first.length, 3);
    });

    test('empty file, header only, JSON file: no crash', () {
      expect(const CsvDecoder().convert(''), isEmpty);
      expect(const CsvDecoder().convert('Date,Amount\n').length, 1);
      expect(() => const CsvDecoder().convert('{"a": [1, 2]}'), returnsNormally);
    });

    // CANDIDATE (mirrors import_screen.dart _pickFile): bank CSVs saved by
    // Excel on Windows are Windows-1252/Latin-1 ("Café", "Société"). The
    // screen reads with File.readAsString() (strict UTF-8) → the whole file
    // fails with "Import failed" instead of importing.
    test('a Latin-1 bank file (é in a description) can be read', () async {
      final f = File('${docsDir.path}/latin1.csv')
        ..writeAsBytesSync(latin1.encode(
            'Date,Description,Amount\n2026-01-02,Café Paris,-4.50\n'));
      // exactly what _pickFile does
      final content = decodeImportBytes(await f.readAsBytes());
      final rows = const CsvDecoder().convert(content);
      expect(rows.length, 2);
    });
  });

  group('CSV import through the Web Companion (same rules as the app)', () {
    late AppDatabase db;
    late ProviderContainer container;
    late Ref ref;
    const hh = 'hh1';

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      container = ProviderContainer(
          overrides: [databaseProvider.overrideWithValue(db)]);
      container.read(currentHouseholdIdProvider.notifier).set(hh);
      ref = container.read(_refProvider);
      await db.into(db.households).insert(HouseholdsCompanion.insert(
          id: hh, name: 'Home', createdByDeviceId: 't'));
      await db.into(db.accounts).insert(AccountsCompanion.insert(
          id: 'usd',
          householdId: hh,
          name: 'usd',
          type: 'bank',
          currency: 'USD',
          deviceId: 't'));
    });
    tearDown(() async {
      container.dispose();
      await db.close();
    });

    // CANDIDATE: two real, identical purchases on one statement (two
    // coffees, two bus fares) — the second is dropped as a "duplicate" of
    // the first, so the account ends up off by one purchase. The `seen` set
    // collects keys from the file itself, not only from what's already in
    // the app. Same code in import_screen.dart.
    test('two identical purchases on the same day both import', () async {
      final res = await call(importCsvHandler(ref), 'POST', body: {
        'accountId': 'usd',
        'rows': [
          {'date': '2026-01-02', 'description': 'Bus', 'amount': -1.5},
          {'date': '2026-01-02', 'description': 'Bus', 'amount': -1.5},
        ],
      });
      expect(res['status'], 200);
      expect(res['imported'], 2);
      expect((await BalanceCalculator(db).allAccountBalances(hh))['usd'], -3);
    });

    test('importing the same file twice adds nothing the second time',
        () async {
      final rows = [
        {'date': '2026-01-02', 'description': 'Bakery', 'amount': -4},
        {'date': '2026-01-03', 'description': 'Salary', 'amount': 1000},
      ];
      final first = await call(importCsvHandler(ref), 'POST',
          body: {'accountId': 'usd', 'rows': rows});
      expect(first['imported'], 2);
      final second = await call(importCsvHandler(ref), 'POST',
          body: {'accountId': 'usd', 'rows': rows});
      expect(second['imported'], 0);
      expect(second['duplicates'], 2);
    });

    // CANDIDATE: Feb 30 passes the YYYY-MM-DD check and DateTime.tryParse
    // rolls it over to Mar 2, so it's imported on the wrong day instead of
    // skipped.
    test('an impossible date (Feb 30) is skipped, not moved to March',
        () async {
      final res = await call(importCsvHandler(ref), 'POST', body: {
        'accountId': 'usd',
        'rows': [
          {'date': '2026-02-30', 'description': 'X', 'amount': -5},
        ],
      });
      expect(res['skipped'], 1);
      expect(res['imported'], 0);
    });

    test('rubbish rows are skipped, bad requests are 400s', () async {
      final res = await call(importCsvHandler(ref), 'POST', body: {
        'accountId': 'usd',
        'rows': [
          'not a row',
          {'date': '02/01/2026', 'amount': -5},
          {'date': '2026-01-02', 'amount': '1.234,56'},
          {'date': '2026-01-02', 'amount': 0},
          {'date': '2026-01-02', 'amount': 1e13},
          {'date': '2026-01-02'},
        ],
      });
      expect(res['status'], 200);
      expect(res['skipped'], 6);
      expect(res['imported'], 0);

      for (final body in <Object>[
        {'accountId': 'usd', 'rows': []},
        {'accountId': 'usd', 'rows': 'x'},
        {'rows': [{'date': '2026-01-02', 'amount': 1}]},
        {'accountId': 'nope', 'rows': [{'date': '2026-01-02', 'amount': 1}]},
        {
          'accountId': 'usd',
          'rows': List.generate(1001, (i) => {'date': '2026-01-02', 'amount': 1}),
        },
      ]) {
        expect((await call(importCsvHandler(ref), 'POST', body: body))['status'],
            400, reason: '$body');
      }
      expect((await call(importCsvHandler(ref), 'POST', rawBody: '[1,2'))['status'],
          400);
    });

    // CANDIDATE: the import reads every income/expense's lines with
    // `transactionId.isIn(<all ids>)` — past SQLite's 32,766 bound
    // variables (a long history) the whole import fails with a 500.
    test('import still works with a long history (>32,766 transactions)',
        () async {
      const n = 33000;
      await db.batch((b) {
        for (var i = 0; i < n; i++) {
          b.customStatement(
              "INSERT INTO transactions (id, household_id, account_id, type, "
              "amount, currency, note, created_at, device_id, created_by) "
              "VALUES (?, ?, 'usd', 'expense', 1, 'USD', 'old', ?, 't', 't')",
              ['t$i', hh, 1700000000 + i]);
        }
      });
      final res = await call(importCsvHandler(ref), 'POST', body: {
        'accountId': 'usd',
        'rows': [
          {'date': '2026-01-02', 'description': 'New', 'amount': -3},
        ],
      });
      expect(res['status'], 200);
      expect(res['imported'], 1);
    }, timeout: const Timeout(Duration(minutes: 3)));
  });

  // ═══════════════════════════════════════════════════════════════════════
  // Backup / restore
  // ═══════════════════════════════════════════════════════════════════════

  group('restore a sync/backup JSON', () {
    test('truncated JSON: refused with the "corrupt" message, data kept',
        () async {
      final db = await openPhone('p');
      await seedBudget(db, 'h', 'Groceries');
      final json = await SyncEngine(db).exportToJson();
      final cut = json.substring(0, json.length ~/ 2);
      Object? err;
      try {
        await SyncEngine(db).restoreFromJson(cut);
      } catch (e) {
        err = e;
      }
      expect(err, isA<FormatException>());
      expect(syncErrorText(err!), en.syncErrCorrupt);
      expect(await notes(db), ['Groceries']);
    });

    test('a JSON array or plain text: refused, data kept', () async {
      final db = await openPhone('p');
      await seedBudget(db, 'h', 'Groceries');
      for (final bad in ['[]', 'hello', '']) {
        await expectLater(SyncEngine(db).restoreFromJson(bad),
            throwsA(isA<FormatException>()), reason: bad);
      }
      expect(await notes(db), ['Groceries']);
    });

    // CANDIDATE: any JSON object is "a backup" — `{}` (or another app's
    // settings file) empties every table and succeeds. Nothing checks the
    // file has a household before deleting.
    test('a JSON object that is not a budget does not wipe the budget',
        () async {
      final db = await openPhone('p');
      await seedBudget(db, 'h', 'Groceries');
      try {
        await SyncEngine(db).restoreFromJson('{"theme":"dark","fontSize":14}');
      } catch (_) {}
      expect(await notes(db), ['Groceries']);
    });

    // CANDIDATE: a file from a newer app (format version 2) is restored
    // blindly by the old app — fields it doesn't know are dropped.
    test('a file from a newer format version is refused', () async {
      final db = await openPhone('p');
      await seedBudget(db, 'h', 'Groceries');
      final data = jsonDecode(await SyncEngine(db).exportToJson())
          as Map<String, dynamic>;
      data['version'] = 99;
      await expectLater(SyncEngine(db).restoreFromJson(jsonEncode(data)),
          throwsA(anything));
    });

    test('a row with a missing id rolls back, nothing half-restored',
        () async {
      final db = await openPhone('p');
      await seedBudget(db, 'h', 'Groceries');
      final data = jsonDecode(await SyncEngine(db).exportToJson())
          as Map<String, dynamic>;
      (data['transactions'] as List).add({'note': 'broken'});
      Object? err;
      try {
        await SyncEngine(db).restoreFromJson(jsonEncode(data));
      } catch (e) {
        err = e;
      }
      expect(err, isNotNull);
      expect(syncErrorText(err!), isNot(contains('Null')));
      expect(await notes(db), ['Groceries']);
    });

    test('encrypted file, wrong password / no password: mapped, data kept',
        () async {
      final db = await openPhone('p');
      await seedBudget(db, 'h', 'Groceries');
      await SyncEncryption.setPassword('right one');
      final enc = await SyncEngine(db).exportToJson();
      expect(enc, startsWith('ENC:'));

      await SyncEncryption.setPassword('wrong one');
      Object? err;
      try {
        await SyncEngine(db).restoreFromJson(enc);
      } catch (e) {
        err = e;
      }
      expect(err, isA<SyncPasswordException>());
      expect(syncErrorText(err!), en.syncErrWrongPassword);

      await SyncEncryption.clearPassword();
      err = null;
      try {
        await SyncEngine(db).restoreFromJson(enc);
      } catch (e) {
        err = e;
      }
      expect(syncErrorText(err!), en.syncErrNeedsPassword);
      expect(await notes(db), ['Groceries']);
    });

    test('restoring over existing data replaces it (no mix)', () async {
      final src = await openPhone('src');
      await seedBudget(src, 'other', 'From backup');
      final json = await SyncEngine(src).exportToJson();
      final db = await openPhone('p');
      await seedBudget(db, 'h', 'Groceries');
      await SyncEngine(db).restoreFromJson(json);
      expect(await notes(db), ['From backup']);
      expect((await db.select(db.households).get()).map((h) => h.id), ['other']);
    });
  });

  group('restore a .db backup file', () {
    Future<File> realBackup(String name) async {
      final f = File('${docsDir.path}/$name');
      if (f.existsSync()) f.deleteSync();
      final db = AppDatabase.forTesting(NativeDatabase(f));
      await seedBudget(db, 'h', 'Groceries');
      await db.close();
      return f;
    }

    void clearStaged() {
      final s = File('${docsDir.path}/budgetseal.db.restore');
      if (s.existsSync()) s.deleteSync();
    }

    test('onboarding check refuses a truncated / foreign / non-SQLite file',
        () async {
      final good = await realBackup('good.db');
      expect(await AutoBackupService.backupHouseholdId(good.path), 'h');

      final bytes = good.readAsBytesSync();
      final cut = File('${docsDir.path}/cut.db')
        ..writeAsBytesSync(bytes.sublist(0, 200));
      expect(await AutoBackupService.backupHouseholdId(cut.path), isNull);

      final json = File('${docsDir.path}/x.json')..writeAsStringSync('{}');
      expect(await AutoBackupService.backupHouseholdId(json.path), isNull);

      final foreign = File('${docsDir.path}/foreign.db');
      if (foreign.existsSync()) foreign.deleteSync();
      sql.sqlite3.open(foreign.path)
        ..execute('CREATE TABLE notes (id TEXT)')
        ..dispose();
      expect(await AutoBackupService.backupHouseholdId(foreign.path), isNull);
    });

    // CANDIDATE: Settings › Backup › Restore from file checks only the 16
    // "SQLite format 3" bytes (backup_screen.dart) and then
    // restoreFromBackup stages anything. A truncated backup (cut-off
    // download / share) is swapped in on the next launch, where the
    // database can't be opened → the app fails at start every time.
    test('a truncated backup is refused, not staged for the next launch',
        () async {
      clearStaged();
      final good = await realBackup('good2.db');
      final bytes = good.readAsBytesSync();
      final cut = File('${docsDir.path}/cut2.db')
        ..writeAsBytesSync(bytes.sublist(0, bytes.length ~/ 2));
      // The backup screen's own check passes:
      expect(String.fromCharCodes(bytes.take(15)), 'SQLite format 3');
      try {
        await AutoBackupService.restoreFromBackup(cut.path);
      } catch (_) {}
      expect(File('${docsDir.path}/budgetseal.db.restore').existsSync(), isFalse,
          reason: 'a broken file was staged to replace the database');
      clearStaged();
      AutoBackupService.restorePending = false;
    });

    test('...because that truncated file cannot be opened by the app',
        () async {
      final good = await realBackup('good3.db');
      final bytes = good.readAsBytesSync();
      final cut = File('${docsDir.path}/cut3.db')
        ..writeAsBytesSync(bytes.sublist(0, bytes.length ~/ 2));
      final db = AppDatabase.forTesting(NativeDatabase(cut));
      Object? err;
      try {
        await db.select(db.households).get();
      } catch (e) {
        err = e;
      }
      await db.close();
      // Documents the consequence; not itself a bug assertion.
      expect(err, isNotNull);
    });

    // CANDIDATE: another app's SQLite file passes the backup screen's check
    // and is staged; on restart the user's budget is replaced by it.
    test('a non-BudgetSeal SQLite file is refused by Restore from file',
        () async {
      clearStaged();
      final foreign = File('${docsDir.path}/foreign2.db');
      if (foreign.existsSync()) foreign.deleteSync();
      sql.sqlite3.open(foreign.path)
        ..execute('CREATE TABLE notes (id TEXT)')
        ..dispose();
      try {
        await AutoBackupService.restoreFromBackup(foreign.path);
      } catch (_) {}
      expect(File('${docsDir.path}/budgetseal.db.restore').existsSync(), isFalse);
      clearStaged();
      AutoBackupService.restorePending = false;
    });

    test('a backup from a newer app version opens without losing data',
        () async {
      final f = await realBackup('newer.db');
      sql.sqlite3.open(f.path)
        ..execute('PRAGMA user_version = 99')
        ..execute('ALTER TABLE transactions ADD COLUMN future_col TEXT')
        ..dispose();
      final db = AppDatabase.forTesting(NativeDatabase(f));
      Object? err;
      List<String> n = [];
      try {
        n = await notes(db);
      } catch (e) {
        err = e;
      }
      await db.close();
      expect(err, isNull);
      expect(n, ['Groceries']);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // Household join
  // ═══════════════════════════════════════════════════════════════════════

  group('household invite code', () {
    final k = HouseholdKey.generate();

    test('spaces and newlines around the code are fine', () {
      expect(HouseholdKey.fromCode('  ${k.code}\n')?.householdId,
          k.householdId);
    });

    // CANDIDATE: the invite is shared as "Join my BudgetSeal household!
    // Enter this code in the app:\n<code>" (syncShareInviteText). A user
    // who copies the whole WhatsApp message and pastes it gets "invalid
    // code"; fromCode only accepts the bare code.
    test('the whole shared message pasted in still joins', () {
      final msg = en.syncShareInviteText(k.code);
      expect(HouseholdKey.fromCode(msg)?.householdId, k.householdId);
    });

    // CANDIDATE: a code copied with the sentence's full stop, or broken
    // over two lines by the chat app, is refused.
    test('a trailing full stop or a line break inside is tolerated', () {
      expect(HouseholdKey.fromCode('${k.code}.')?.householdId, k.householdId);
      final mid = k.code.length ~/ 2;
      final wrapped =
          '${k.code.substring(0, mid)}\n${k.code.substring(mid)}';
      expect(HouseholdKey.fromCode(wrapped)?.householdId, k.householdId);
    });

    test('a truncated code, garbage, an old PP- code: refused, no crash', () {
      expect(HouseholdKey.fromCode(k.code.substring(0, 20)), isNull);
      expect(HouseholdKey.fromCode('BS1-'), isNull);
      expect(HouseholdKey.fromCode('BS1-!!!!'), isNull);
      expect(HouseholdKey.fromCode('BS1-${'A' * 43}.%%%'), isNull);
      expect(HouseholdKey.fromCode(''), isNull);
      expect(HouseholdKey.isOldInvite(' PP-ABC123 '), isTrue);
    });

    // CANDIDATE (cosmetic): the code field's hint still shows the old
    // Drive format "PP-...", so users type a PP code.
    test('the code field hint shows the current code format', () {
      expect(en.onboardInviteHint, startsWith('BS1-'));
    });
  });

  group('joining a household (SyncNotifier + relay)', () {
    /// Phone A starts a household with a budget and pushes it to [relay].
    Future<HouseholdKey> startA(FakeRelay relay, {bool upload = true}) async {
      final a = await openPhone('phone-a');
      await seedBudget(a, 'ha', 'Shared groceries');
      final pa = RelayProvider(client: relay.client);
      await pa.connect();
      if (upload) await LogSync(a).sync(ProviderLogStore(pa));
      final k = (await pa.key)!;
      // Phone A's key went to the (shared, mocked) secure storage; phone B
      // starts with its own empty storage.
      FlutterSecureStorage.setMockInitialValues({});
      return k;
    }

    test('a good join replaces the budget; leave and rejoin works', () async {
      final relay = FakeRelay();
      final key = await startA(relay);
      final b = await openPhone('phone-b');
      await seedBudget(b, 'hb', 'My own');
      final n = syncNotifierFor(b, relay.client);
      await n.joinHousehold(HouseholdKey.fromCode(key.code)!);
      expect(stateOf(n).status, SyncStatus.success);
      expect(await notes(b), ['Shared groceries']);

      await n.disconnectProvider();
      expect(await n.relay.isConnected, isFalse);
      await n.joinHousehold(HouseholdKey.fromCode(key.code)!);
      expect(stateOf(n).status, SyncStatus.success);
      expect(await notes(b), ['Shared groceries']);
    });

    test('relay errors at the join step: mapped, nothing changed', () async {
      for (final (status, body, msg) in [
        (404, '{}', en.relayErrNotFound),
        (401, '{}', en.relayErrKey),
        (429, '{}', en.relayErrBusy),
        (500, '<html>oops</html>', en.relayErrServer),
        (503, '', en.relayErrServer),
      ]) {
        final relay = FakeRelay();
        final key = await startA(relay);
        final b = await openPhone('phone-b');
        await seedBudget(b, 'hb', 'My own');
        final n = syncNotifierFor(
            b, flakyClient(relay, (_) => http.Response(body, status)));
        Object? err;
        try {
          await n.joinHousehold(key);
        } catch (e) {
          err = e;
        }
        expect(err, isA<RelayException>(), reason: '$status');
        expect(syncErrorText(err!), msg, reason: '$status');
        expect(await notes(b), ['My own'], reason: '$status');
        expect(await n.relay.isConnected, isFalse, reason: '$status');
      }
    });

    test('network down at the join step: network message, nothing changed',
        () async {
      final relay = FakeRelay();
      final key = await startA(relay);
      final b = await openPhone('phone-b');
      await seedBudget(b, 'hb', 'My own');
      final n = syncNotifierFor(b,
          flakyClient(relay, (_) => throw http.ClientException('no route')));
      Object? err;
      try {
        await n.joinHousehold(key);
      } catch (e) {
        err = e;
      }
      expect(syncErrorText(err!), en.syncErrNetwork);
      expect(await notes(b), ['My own']);
    });

    // CANDIDATE (data loss): the network drops after the join was accepted,
    // while the household's files download. LogSync.replaceFrom() empties
    // every table FIRST and downloads after, so the phone is left with an
    // empty budget (only the auto-backup has it).
    test('network drops while downloading: this phone keeps its budget',
        () async {
      final relay = FakeRelay();
      final key = await startA(relay);
      final b = await openPhone('phone-b');
      await seedBudget(b, 'hb', 'My own');
      final n = syncNotifierFor(
          b,
          flakyClient(relay, (r) {
            // Listing works; reading a log file fails.
            if (r.url.pathSegments.length == 5 && r.method == 'GET') {
              throw http.ClientException('connection reset');
            }
            return null;
          }));
      await n.joinHousehold(key);
      expect(stateOf(n).status, SyncStatus.error);
      expect(stateOf(n).lastError, en.syncErrNetwork);
      expect(await notes(b), ['My own'],
          reason: 'local budget was wiped before the download finished');
    });

    // CANDIDATE: same with a timeout instead of a dropped connection.
    test('a timeout while downloading: this phone keeps its budget', () async {
      final relay = FakeRelay();
      final key = await startA(relay);
      final b = await openPhone('phone-b');
      await seedBudget(b, 'hb', 'My own');
      final n = syncNotifierFor(
          b,
          flakyClient(relay, (r) {
            if (r.url.pathSegments.length == 5 && r.method == 'GET') {
              throw TimeoutException('slow');
            }
            return null;
          }));
      await n.joinHousehold(key);
      expect(stateOf(n).lastError, en.syncErrNetwork);
      expect(await notes(b), ['My own']);
    });

    // CANDIDATE: a corrupt file on the relay (garbage instead of a sealed
    // file) — same wipe-first problem.
    test('garbage file on the relay: this phone keeps its budget', () async {
      final relay = FakeRelay();
      final key = await startA(relay);
      final b = await openPhone('phone-b');
      await seedBudget(b, 'hb', 'My own');
      final n = syncNotifierFor(
          b,
          flakyClient(relay, (r) {
            if (r.url.pathSegments.length == 5 && r.method == 'GET') {
              return http.Response('{"not":"sealed"}', 200);
            }
            return null;
          }));
      await n.joinHousehold(key);
      expect(stateOf(n).status, SyncStatus.error);
      expect(stateOf(n).lastError, en.syncErrCorrupt);
      expect(await notes(b), ['My own']);
    });

    test('garbage JSON as the file list: mapped message, data kept',
        () async {
      final relay = FakeRelay();
      final key = await startA(relay);
      final b = await openPhone('phone-b');
      await seedBudget(b, 'hb', 'My own');
      var lists = 0;
      final n = syncNotifierFor(
          b,
          flakyClient(relay, (r) {
            if (r.url.pathSegments.length == 4 && ++lists > 1) {
              return http.Response('{"files": nul', 200);
            }
            return null;
          }));
      await n.joinHousehold(key);
      expect(stateOf(n).status, SyncStatus.error);
      expect(stateOf(n).lastError, isNot(contains('Exception')));
      expect(await notes(b), ['My own']);
    });

    // CANDIDATE (half-joined): when the join fails after the relay accepted
    // the key, the key is already in secure storage (RelayProvider.join
    // saves it before the download), Drive/folder sync was already left and
    // the sync password erased. The phone isn't shown as in the household
    // (pref not set) but holds its key.
    test('a failed join leaves no household key behind', () async {
      final relay = FakeRelay();
      final key = await startA(relay);
      final b = await openPhone('phone-b');
      await seedBudget(b, 'hb', 'My own');
      final n = syncNotifierFor(
          b,
          flakyClient(relay, (r) {
            if (r.url.pathSegments.length == 5) {
              throw http.ClientException('connection reset');
            }
            return null;
          }));
      await n.joinHousehold(key);
      expect(stateOf(n).status, SyncStatus.error);
      expect(await n.relay.isConnected, isFalse);
    });

    // CANDIDATE (confusing UX): the household exists but its creator's
    // first upload never happened. The joiner reads "No budget found in
    // this folder" — there is no folder in a household.
    test('joining an empty household says so in household words', () async {
      final relay = FakeRelay();
      final key = await startA(relay, upload: false);
      final b = await openPhone('phone-b');
      await seedBudget(b, 'hb', 'My own');
      final n = syncNotifierFor(b, relay.client);
      await n.joinHousehold(key);
      expect(stateOf(n).status, SyncStatus.error);
      expect(await notes(b), ['My own']);
      expect(stateOf(n).lastError, isNot(contains('folder')));
    });

    // CANDIDATE (data mix): a phone already in household 1 tries to join
    // household 2; the join step succeeds (key 2 saved) but the download
    // fails before anything is replaced. The phone keeps household 1's
    // budget, stays "in a household" — but now with household 2's key, so
    // the next sync pulls household 2's entries into household 1's budget
    // and pushes household 1's entries to household 2.
    test('a failed switch to another household keeps the old one', () async {
      final relay = FakeRelay();
      final key2 = await startA(relay);

      final b = await openPhone('phone-b');
      await seedBudget(b, 'hb', 'Household one');
      var armed = false;
      var lists = 0;
      final n = syncNotifierFor(
          b,
          flakyClient(relay, (r) {
            // Household 2: the join's own GET /files passes, the restore's
            // listing (the second) fails.
            if (armed &&
                r.url.pathSegments.length == 4 &&
                r.url.pathSegments[2] == key2.householdId &&
                ++lists == 2) {
              return http.Response('{}', 500);
            }
            return null;
          }));
      DeviceIdentity.debugSet('phone-b');
      await n.startHousehold();
      expect(stateOf(n).activeProvider, isA<RelayProvider>());
      final key1 = (await n.relay.key)!;

      armed = true;
      await n.joinHousehold(key2);
      expect(stateOf(n).status, SyncStatus.error);
      expect(await notes(b), ['Household one']);
      expect(stateOf(n).activeProvider, isA<RelayProvider>());
      expect((await n.relay.key)!.householdId, key1.householdId,
          reason: 'the phone is still in household one but holds the key '
              'of household two');
    });

    // CANDIDATE (consequence of the one above): the next sync after that
    // failed switch merges household two into household one's budget.
    test('after a failed switch, the next sync does not mix two budgets',
        () async {
      final relay = FakeRelay();
      final key2 = await startA(relay);
      final b = await openPhone('phone-b');
      await seedBudget(b, 'hb', 'Household one');
      var armed = false;
      var lists = 0;
      final n = syncNotifierFor(
          b,
          flakyClient(relay, (r) {
            if (armed &&
                r.url.pathSegments.length == 4 &&
                r.url.pathSegments[2] == key2.householdId &&
                ++lists == 2) {
              return http.Response('{}', 500);
            }
            return null;
          }));
      DeviceIdentity.debugSet('phone-b');
      await n.startHousehold();
      armed = true;
      await n.joinHousehold(key2);
      armed = false;
      await n.sync();
      final households =
          (await b.select(b.households).get()).map((h) => h.id).toSet();
      expect(households, {'hb'},
          reason: 'rows of household two were merged into household one');
    });

    // CANDIDATE: Start a household while the relay is unreachable. It
    // first leaves Google Drive / the folder and erases the sync password,
    // then fails to create the household — the phone ends with no sync at
    // all and no password.
    test('start a household offline: folder sync and password are kept',
        () async {
      final folder = Directory('${docsDir.path}/syncfolder')
        ..createSync(recursive: true);
      SharedPreferences.setMockInitialValues({'file_sync_folder': folder.path});
      final b = await openPhone('phone-b');
      await seedBudget(b, 'hb', 'My own');
      final n = syncNotifierFor(
          b, MockClient((_) async => throw http.ClientException('offline')));
      await n.useConnectedProvider(n.filePicker);
      await SyncEncryption.setPassword('pw');

      Object? err;
      try {
        await n.startHousehold();
      } catch (e) {
        err = e;
      }
      expect(syncErrorText(err!), en.syncErrNetwork);
      expect(stateOf(n).activeProvider, isA<FilePickerProvider>());
      expect(await SyncEncryption.hasPassword(), isTrue);
    });

    test('sync while the relay is busy / down: mapped messages', () async {
      final relay = FakeRelay();
      final key = await startA(relay);
      final b = await openPhone('phone-b');
      var answer = 200;
      final n = syncNotifierFor(
          b,
          flakyClient(relay,
              (_) => answer == 200 ? null : http.Response('{}', answer)));
      await n.joinHousehold(key);
      expect(stateOf(n).status, SyncStatus.success);
      for (final (code, msg) in [
        (429, en.relayErrBusy),
        (413, en.relayErrFull),
        (502, en.relayErrServer),
        (404, en.relayErrNotFound),
      ]) {
        answer = code;
        await n.sync();
        expect(stateOf(n).lastError, msg, reason: '$code');
      }
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // Web Companion REST API
  // ═══════════════════════════════════════════════════════════════════════

  group('Web Companion API', () {
    late AppDatabase db;
    late ProviderContainer container;
    late Ref ref;
    const hh = 'hh1';

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      container = ProviderContainer(
          overrides: [databaseProvider.overrideWithValue(db)]);
      container.read(currentHouseholdIdProvider.notifier).set(hh);
      ref = container.read(_refProvider);
      await db.into(db.households).insert(HouseholdsCompanion.insert(
          id: hh, name: 'Home', createdByDeviceId: 't'));
      for (final (id, cur) in [('usd', 'USD'), ('lbp', 'LBP')]) {
        await db.into(db.accounts).insert(AccountsCompanion.insert(
            id: id,
            householdId: hh,
            name: id,
            type: 'bank',
            currency: cur,
            deviceId: 't'));
      }
      await db.into(db.categories).insert(CategoriesCompanion.insert(
          id: 'food', householdId: hh, name: 'Food'));
      await db.into(db.allocations).insert(AllocationsCompanion.insert(
          id: 'env', householdId: hh, name: 'Groceries', categoryId: 'food', deviceId: 't'));
      await db.into(db.allocations).insert(AllocationsCompanion.insert(
          id: 'gone', categoryId: 'food', deviceId: 't',
          householdId: hh,
          name: 'Deleted one',
          deleted: const Value(true)));
    });
    tearDown(() async {
      container.dispose();
      await db.close();
    });

    test('malformed JSON bodies are 400s on every write', () async {
      final handlers = <(Handler, String?)>[
        (createTransactionHandler(ref), null),
        (updateTransactionHandler(ref), 'x'),
        (createAccountHandler(ref), null),
        (fundEnvelopeHandler(ref), 'env'),
        (moveEnvelopeMoneyHandler(ref), null),
        (importCsvHandler(ref), null),
      ];
      for (final (h, id) in handlers) {
        for (final raw in ['{"amount": 5', '[1,2,3]', 'null', '"text"', '']) {
          final res = await call(h, 'POST', rawBody: raw, id: id);
          expect(res['status'], 400, reason: '$raw');
          expect(res['error'], isA<String>());
        }
      }
    });

    test('missing fields, wrong types, negative/huge amounts are 400s',
        () async {
      final h = createTransactionHandler(ref);
      for (final body in <Map<String, dynamic>>[
        {'accountId': 'usd', 'amount': 5},
        {'type': 'expense', 'amount': 5},
        {'type': 'expense', 'accountId': 'usd'},
        {'type': 'expense', 'accountId': 'usd', 'amount': 'five'},
        {'type': 'expense', 'accountId': 'usd', 'amount': true},
        {'type': 'expense', 'accountId': 'usd', 'amount': -5},
        {'type': 'expense', 'accountId': 'usd', 'amount': 0},
        {'type': 'expense', 'accountId': 'usd', 'amount': 1e13},
        {'type': 'expense', 'accountId': 'usd', 'amount': '1e400'},
        {'type': 'expense', 'accountId': 'nope', 'amount': 5},
        {'type': 'expense', 'accountId': 'usd', 'amount': 5, 'categoryId': 'nope'},
        {'type': 7, 'accountId': 'usd', 'amount': 5},
        {'type': 'expense', 'accountId': 'usd', 'lines': [5]},
        {'type': 'expense', 'accountId': 'usd', 'lines': [{'amount': -1}]},
        {'type': 'transfer', 'accountId': 'usd', 'destinationAccountId': 'usd', 'amount': 5},
        {'type': 'transfer', 'accountId': 'usd', 'destinationAccountId': 'lbp', 'amount': 5},
        {'type': 'expense', 'accountId': 'usd', 'amount': 5, 'currency': 'ZZZ'},
      ]) {
        final res = await call(h, 'POST', body: body);
        expect(res['status'], 400, reason: '$body');
      }
      expect(await db.select(db.transactions).get(), isEmpty);

      for (final body in <Map<String, dynamic>>[
        {'amount': -5, 'currency': 'USD'},
        {'amount': 1e13, 'currency': 'USD'},
        {'amount': 5},
        {'amount': 5, 'currency': 'US D'},
      ]) {
        expect((await call(fundEnvelopeHandler(ref), 'POST', body: body, id: 'env'))['status'],
            400, reason: '$body');
      }
      expect((await call(createAccountHandler(ref), 'POST',
              body: {'name': 'X', 'currency': 'US1'}))['status'],
          400);
    });

    test('unknown ids are 404s', () async {
      expect((await call(updateTransactionHandler(ref), 'PUT',
              body: {'amount': 5}, id: 'nope'))['status'],
          404);
      expect((await call(deleteTransactionHandler(ref), 'DELETE', id: 'nope'))['status'],
          404);
      expect((await call(getTransactionHandler(ref), 'GET', id: 'nope'))['status'],
          404);
      expect((await call(fundEnvelopeHandler(ref), 'POST',
              body: {'amount': 5, 'currency': 'USD'}, id: 'nope'))['status'],
          404);
      expect((await call(moveEnvelopeMoneyHandler(ref), 'POST',
              body: {'toId': 'nope', 'amount': 5, 'currency': 'USD'}))['status'],
          404);
    });

    // CANDIDATE: an unreadable date is silently replaced by "now" — the
    // expense is saved today with a 201 instead of being refused.
    test('an invalid date is refused, not saved as today', () async {
      for (final d in ['31/12/2026', 'yesterday', '2026-13-01']) {
        final res = await call(createTransactionHandler(ref), 'POST', body: {
          'type': 'expense',
          'accountId': 'usd',
          'amount': 5,
          'date': d,
        });
        expect(res['status'], 400, reason: d);
      }
    });

    // CANDIDATE: Feb 30 is accepted and saved as March 2.
    test('Feb 30 is refused, not rolled over to March', () async {
      final res = await call(createTransactionHandler(ref), 'POST', body: {
        'type': 'expense',
        'accountId': 'usd',
        'amount': 5,
        'date': '2026-02-30',
      });
      expect(res['status'], 400);
    });

    // CANDIDATE (minor): the "patch the first line" edit path never checks
    // exchangeRateToBase; the engine refuses it (ArgumentError), so nothing
    // is saved, but the browser gets a 500 "Internal server error" instead
    // of a 400 saying what's wrong.
    test('editing with a negative or zero rate is refused', () async {
      final created = await call(createTransactionHandler(ref), 'POST', body: {
        'type': 'expense',
        'accountId': 'lbp',
        'amount': 89500,
        'currency': 'LBP',
        'exchangeRateToBase': 1 / 89500,
        'categoryId': 'food',
      });
      expect(created['status'], 201);
      final id = created['id'] as String;
      for (final rate in [-5, 0]) {
        final res = await call(updateTransactionHandler(ref), 'PUT',
            body: {'exchangeRateToBase': rate}, id: id);
        expect(res['status'], 400, reason: '$rate');
      }
      final tx = await db.transactionsDao.getById(id);
      expect(tx!.amount, greaterThan(0));
    });

    // CANDIDATE (money wrong): funding goes to an envelope that was
    // deleted — the money leaves Ready to assign into a hidden envelope.
    // Move checks deleted/archived; fund doesn't.
    test('funding a deleted envelope is refused', () async {
      final res = await call(fundEnvelopeHandler(ref), 'POST',
          body: {'amount': 50, 'currency': 'USD'}, id: 'gone');
      expect(res['status'], 404);
    });

    // CANDIDATE: funding in a currency the budget has no account in
    // (a typo, "UDS") is accepted — Ready to assign in "UDS" goes negative
    // and shows up as a new currency.
    test('funding in a currency with no account is refused', () async {
      final res = await call(fundEnvelopeHandler(ref), 'POST',
          body: {'amount': 50, 'currency': 'UDS'}, id: 'env');
      expect(res['status'], 400);
    });

    test('moving more than an envelope holds is a 400, not a 500', () async {
      final res = await call(moveEnvelopeMoneyHandler(ref), 'POST',
          body: {'fromId': 'env', 'amount': 50, 'currency': 'USD'});
      expect(res['status'], 400);
    });

    test('errors never carry exception text', () async {
      final res = await call(createTransactionHandler(ref), 'POST', body: {
        'type': 'expense',
        'accountId': 'usd',
        'amount': 5,
        'note': 'x' * 100000,
      });
      expect(res['status'], 201);
      final tx = await db.transactionsDao.getById(res['id'] as String);
      expect(tx!.note.length, lessThanOrEqualTo(500));
    });
  });
}
