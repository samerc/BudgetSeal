/// The app with years of data: about 11,000 transactions over three years
/// in three currencies, written through the engines (see [BigBudget]).
///
/// Checks that every balance still matches the seed's own model, that the
/// lists, reports, sync file and Web Companion agree with each other, and
/// times what the screens load. The timings print at the end; the limits
/// are loose (a slow CI machine must pass) and only catch something that
/// has become unusable.
///
/// `BIG_BUDGET_MONTHS=60` makes a bigger history; `BIG_BUDGET_DB=path`
/// also writes the database to a file (to try on a phone).
@Tags(['scale'])
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:budgetseal/core/database/app_database.dart';
import 'package:budgetseal/core/engine/age_of_money.dart';
import 'package:budgetseal/core/engine/allocation_engine.dart';
import 'package:budgetseal/core/engine/balance_calculator.dart';
import 'package:budgetseal/core/engine/base_currency_change.dart';
import 'package:budgetseal/core/engine/budget_history.dart';
import 'package:budgetseal/core/engine/change_log.dart';
import 'package:budgetseal/core/engine/spending_average.dart';
import 'package:budgetseal/core/providers/autofill_provider.dart';
import 'package:budgetseal/core/providers/database_provider.dart';
import 'package:budgetseal/core/providers/household_provider.dart';
import 'package:budgetseal/core/providers/report_stats_provider.dart';
import 'package:budgetseal/core/providers/transactions_provider.dart';
import 'package:budgetseal/core/services/autofill_service.dart';
import 'package:budgetseal/core/services/household_members.dart';
import 'package:budgetseal/core/sync/log_sync.dart';
import 'package:budgetseal/core/sync/op_log.dart';
import 'package:budgetseal/core/sync/sync_engine.dart';
import 'package:budgetseal/features/accounts/account_detail_screen.dart';
import 'package:budgetseal/features/accounts/accounts_screen.dart';
import 'package:budgetseal/features/allocations/allocation_detail_screen.dart';
import 'package:budgetseal/features/allocations/allocations_screen.dart';
import 'package:budgetseal/features/allocations/funding_screen.dart';
import 'package:budgetseal/features/dashboard/dashboard_screen.dart';
import 'package:budgetseal/features/reports/time/budget_report.dart';
import 'package:budgetseal/features/reports/time/list_reports.dart';
import 'package:budgetseal/features/reports/time/money_report.dart';
import 'package:budgetseal/features/reports/time/places_report.dart';
import 'package:budgetseal/features/reports/time/reports_home.dart';
import 'package:budgetseal/features/reports/time/spending_report.dart';
import 'package:budgetseal/features/reports/time/year_report.dart';
import 'package:budgetseal/features/settings/change_log_screen.dart';
import 'package:budgetseal/features/transactions/transactions_screen.dart';
import 'package:budgetseal/features/web_companion/api/_running.dart';
import 'package:budgetseal/features/web_companion/api/change_log_handler.dart';
import 'package:budgetseal/features/web_companion/api/dashboard_handler.dart';
import 'package:budgetseal/features/web_companion/api/envelopes_handler.dart';
import 'package:budgetseal/features/web_companion/api/reports_handler.dart';
import 'package:budgetseal/features/web_companion/api/transactions_handler.dart';
import 'package:budgetseal/l10n/generated/app_localizations.dart';
import 'package:budgetseal/shared/utils/search_match.dart';
import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shelf/shelf.dart';

import 'big_budget.dart';
import '../core/sync/log_sync_test.dart' show MemoryStore;


final _refProvider = Provider<Ref>((ref) => ref);

/// The first value of [p], read the way a screen does (listening: Riverpod
/// pauses a provider nobody listens to).
Future<T> _valueOf<T>(
    ProviderContainer c, ProviderListenable<AsyncValue<T>> p) async {
  final done = Completer<T>();
  final sub = c.listen<AsyncValue<T>>(p, (_, next) {
    if (done.isCompleted) return;
    if (next.hasValue) {
      done.complete(next.value as T);
    } else if (next.hasError) {
      done.completeError(next.error!, next.stackTrace);
    }
  }, fireImmediately: true);
  try {
    return await done.future;
  } finally {
    sub.close();
  }
}

void main() {
  const hh = BigBudget.hh;
  final months =
      int.tryParse(Platform.environment['BIG_BUDGET_MONTHS'] ?? '') ?? 36;
  final dbFile = Platform.environment['BIG_BUDGET_DB'];

  late AppDatabase db;
  late BigBudget seed;
  late ProviderContainer container;
  late Ref ref;
  late List<TransactionEntry> entries;
  final timings = <(String, int, String)>[];

  /// Times [f]; fails if it takes longer than [limitMs].
  Future<T> timed<T>(String name, Future<T> Function() f,
      {int limitMs = 5000, String Function(T)? note}) async {
    final sw = Stopwatch()..start();
    final r = await f();
    sw.stop();
    timings.add((name, sw.elapsedMilliseconds, note?.call(r) ?? ''));
    expect(sw.elapsedMilliseconds, lessThan(limitMs), reason: '$name is slow');
    return r;
  }

  setUpAll(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    if (dbFile != null) {
      final f = File(dbFile);
      if (f.existsSync()) f.deleteSync();
    }
    db = AppDatabase.forTesting(dbFile != null
        ? NativeDatabase(File(dbFile))
        : NativeDatabase.memory());
    seed = BigBudget(db);
    await timed('seed (all writes)', () => seed.build(months: months),
        limitMs: 600000,
        note: (_) => '${seed.liveTransactions} live transactions');
    container =
        ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
    container.read(currentHouseholdIdProvider.notifier).set(hh);
    ref = container.read(_refProvider);
    // Keep the history stream alive like the app does.
    container.listen(transactionEntriesProvider, (_, __) {});
  });

  tearDownAll(() async {
    final out = StringBuffer('\n── Big budget ($months months) ──\n');
    seed.counts.forEach((k, v) => out.writeln('  $k: $v'));
    out.writeln('  writes, ms per 1,000 (first → last): '
        '${seed.writeMsPer1000.join(' ')}');
    out.writeln('── Timings ──');
    for (final (name, ms, note) in timings) {
      out.writeln('  ${name.padRight(44)} ${'$ms ms'.padLeft(8)}  $note');
    }
    // ignore: avoid_print
    print(out);
    container.dispose();
    // A widget test's stream timer can keep close() waiting; the data is
    // already written.
    await db.close().timeout(const Duration(seconds: 5), onTimeout: () {});
  });

  test('the balances match the model after years of history', () async {
    final calc = BalanceCalculator(db);
    final got = await timed('account balances', () => calc.allAccountBalances(hh));
    for (final id in BigBudget.accounts.keys) {
      expect(got[id], closeTo(seed.acct[id]!, 0.01), reason: 'account $id');
    }
    final envs = await timed('envelope balances',
        () => calc.allAllocationBalancesByCurrency(hh));
    for (final id in seed.envelopeName.keys) {
      final curs = {...?envs[id]?.keys, ...?seed.env[id]?.keys};
      for (final c in curs) {
        expect(envs[id]?[c] ?? 0, closeTo(seed.envBal(id, c), 0.01),
            reason: 'envelope $id $c');
      }
    }
    final ready = await timed('ready to assign', () => calc.unallocatedByCurrency(hh));
    expect(ready.keys, containsAll(['USD', 'EUR', 'LBP']));
    expect(await calc.checkInvariant(hh), isTrue);
  });

  test('Activity history: every row, running balances end at the balance',
      () async {
    entries = await timed('Activity: whole history',
        () => _valueOf(container, transactionEntriesProvider),
        note: (e) => '${e.length} rows');
    expect(entries.length, seed.liveTransactions);
    // Newest first, and the newest row of each account (with nothing newer
    // touching that account) shows the account's balance.
    final balances = await BalanceCalculator(db).allAccountBalances(hh);
    final touched = <String>{};
    final checked = <String>{};
    for (final e in entries) {
      final own = e.lines.length == 1 && e.lines.first.accountId != null
          ? e.lines.first.accountId!
          : e.tx.accountId;
      if (!touched.contains(own) && checked.add(own)) {
        expect(e.accountBalanceAfter, closeTo(balances[own]!, 0.01),
            reason: 'running balance of $own');
      }
      final dest = e.tx.destinationAccountId;
      if (dest != null && !touched.contains(dest) && checked.add(dest)) {
        expect(e.destinationAccountBalanceAfter, closeTo(balances[dest]!, 0.01),
            reason: 'running balance of $dest (received)');
      }
      touched
        ..add(e.tx.accountId)
        ..addAll(e.lines.map((l) => l.accountId).whereType<String>());
      if (e.tx.destinationAccountId != null) {
        touched.add(e.tx.destinationAccountId!);
      }
    }
    expect(checked, containsAll(BigBudget.accounts.keys));
  });

  test('a month on its own agrees with the whole history', () async {
    final now = DateTime.now();
    for (final (label, y, m) in [
      ('this month', now.year, now.month),
      if (months > 24) ('two years ago', now.year - 2, now.month),
    ]) {
      final month = await timed('Activity: one month ($label)',
          () => _valueOf(
              container, monthlyTransactionsProvider((year: y, month: m))),
          note: (e) => '${e.length} rows');
      expect(month, isNotEmpty);
      final byId = {for (final e in entries) e.tx.id: e};
      for (final e in month) {
        final full = byId[e.tx.id]!;
        expect(e.accountBalanceAfter,
            closeTo(full.accountBalanceAfter, 0.01),
            reason: '$label: ${e.tx.id}');
      }
    }
  });

  test('search, autofill and change log', () async {
    final cats = {
      for (final c in await db.select(db.categories).get()) c.id: c,
    };
    // The Activity search, as the screen runs it on every keystroke.
    int search(String q) {
      final query = SearchQuery.parse(q);
      var n = 0;
      for (final e in entries) {
        final text = StringBuffer()
          ..write(e.tx.note)
          ..write(' ')
          ..write(e.accountName)
          ..write(' ')
          ..write(e.tx.amount.toStringAsFixed(2));
        final cat = cats[e.tx.categoryId];
        if (cat != null) text.write(' ${cat.name}');
        for (final l in e.lines) {
          text.write(' ${l.note} ${l.amount.toStringAsFixed(2)}');
          final lc = cats[l.categoryId];
          if (lc != null) text.write(' ${lc.name}');
        }
        if (query.matches(foldForSearch(text.toString()), e.tx.amount)) n++;
      }
      return n;
    }

    final carrefour = await timed('search "carrefour"',
        () async => search('carrefour'), limitMs: 2000,
        note: (n) => '$n matches');
    expect(carrefour, greaterThan(months * 3));
    await timed('search "cafe >20"', () async => search('cafe >20'),
        limitMs: 2000, note: (n) => '$n matches');

    await timed('autofill lookup "Spinn"', () async {
      return lookupAutofillByTitle(
          entries: entries, title: 'Spinneys', settings: const AutofillSettings());
    }, limitMs: 500);

    final log = await timed('change log (300 newest)',
        () => loadChangeLog(db, hh), note: (r) => '${r.length} events');
    expect(log, isNotEmpty);
  });

  test('budget and report figures', () async {
    final now = DateTime.now();
    final stats = await timed('Reports: monthly stats',
        () => _valueOf(container, reportStatsProvider),
        note: (s) => '${s.monthly.length} months');
    expect(stats.monthly.length, greaterThanOrEqualTo(months));

    final start = DateTime(now.year, now.month, 1);
    final period = await timed('envelope stats, this month',
        () => envelopePeriodStats(db.ledgerDao,
            householdId: hh,
            start: start,
            end: DateTime(now.year, now.month + 1, 1),
            currency: 'USD'));
    expect(period, isNotEmpty);
    await timed('usual spending (3 months)',
        () => recentAverageSpending(db.ledgerDao, hh, 1));
    final age = await timed('age of money', () => calculateAgeOfMoney(db, hh),
        note: (d) => '$d days');
    if (months >= 6) expect(age, isNotNull);
  });

  group('Web Companion at scale', () {
    Future<Map<String, dynamic>> call(Handler h, {String query = ''}) async {
      final res = await h(Request('GET', Uri.parse('http://localhost/api/x$query')));
      final body = jsonDecode(await res.readAsString());
      expect(res.statusCode, 200, reason: '$body');
      return body is Map<String, dynamic> ? body : {'items': body};
    }

    test('lists, search and reports answer quickly', () async {
      final page = await timed('web: transactions page 1',
          () => call(listTransactionsHandler(ref)));
      expect(page.toString(), isNot(contains('"error"')));
      await timed('web: transactions page 100',
          () => call(listTransactionsHandler(ref), query: '?page=100'));
      await timed('web: search "spinneys"',
          () => call(listTransactionsHandler(ref), query: '?search=spinneys'));
      await timed('web: dashboard', () => call(dashboardHandler(ref)));
      await timed('web: envelopes', () => call(listEnvelopesHandler(ref)));
      await timed('web: cash flow report', () => call(cashflowReportHandler(ref)));
      await timed('web: by category', () => call(byCategoryReportHandler(ref)));
      await timed('web: change log', () => call(changeLogHandler(ref)));
    });
  });

  test('log sync: first upload, a phone joining with and without the '
      'snapshot', () async {
    final store = MemoryStore();
    await timed('log sync: first upload', () => LogSync(db).sync(store),
        note: (_) {
          String mb(Iterable<String> f) =>
              (f.fold(0, (n, x) => n + x.length) / 1024 / 1024)
                  .toStringAsFixed(1);
          final snap = store.files.entries.where((e) => e.key.contains('snapshot'));
          return '${store.files.length - 1} log files ${mb(store.files.entries.where((e) => !e.key.contains('snapshot')).map((e) => e.value))} MB'
              ' + snapshot ${mb(snap.map((e) => e.value))} MB';
        },
        limitMs: 60000);
    expect(store.files.keys.where((n) => n.contains('snapshot')), hasLength(1));
    final a = await BalanceCalculator(db).allAccountBalances(hh);
    for (final withSnapshot in [true, false]) {
      final files = Map.of(store.files);
      final versions = Map.of(store.versions);
      if (!withSnapshot) {
        files.removeWhere((n, _) => n.contains('snapshot'));
        versions.removeWhere((n, _) => n.contains('snapshot'));
      }
      final from = MemoryStore()
        ..files.addAll(files)
        ..versions.addAll(versions);
      DeviceIdentity.debugSet('scale-joiner');
      final joiner = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(joiner.close);
      await timed(
          'log sync: join ${withSnapshot ? 'from the snapshot' : 'from every log file'}',
          () => LogSync(joiner).replaceFrom(from),
          note: (_) => '${from.reads.length} files read',
          limitMs: 120000);
      DeviceIdentity.debugSet('local');
      final b = await BalanceCalculator(joiner).allAccountBalances(hh);
      for (final id in BigBudget.accounts.keys) {
        expect(b[id], closeTo(a[id]!, 0.01), reason: 'joined $id');
      }
    }
  });

  test('sync file: export, restore to a new phone', () async {
    final sync = SyncEngine(db);
    final json = await timed('sync: export', () => sync.exportToJson(),
        note: (s) => '${(s.length / 1024 / 1024).toStringAsFixed(1)} MB');
    final copy = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(copy.close);
    await timed('sync: restore into an empty app',
        () => SyncEngine(copy).restoreFromJson(json), limitMs: 60000);
    final a = await BalanceCalculator(db).allAccountBalances(hh);
    final b = await BalanceCalculator(copy).allAccountBalances(hh);
    for (final id in BigBudget.accounts.keys) {
      expect(b[id], closeTo(a[id]!, 0.01), reason: 'restored $id');
    }
    expect(await BalanceCalculator(copy).allAllocationBalancesByCurrency(hh),
        await BalanceCalculator(db).allAllocationBalancesByCurrency(hh));

    // Changing the base currency rewrites every line: on the copy, so the
    // other tests keep USD.
    final before = await BalanceCalculator(copy).allAccountBalances(hh);
    await timed('base currency change (USD → EUR)',
        () => changeBaseCurrency(copy, hh, 'USD', 'EUR', 1 / 1.08),
        limitMs: 60000);
    final after = await BalanceCalculator(copy).allAccountBalances(hh);
    for (final id in BigBudget.accounts.keys) {
      expect(after[id], closeTo(before[id]!, 0.01), reason: 'base change $id');
    }
  });

  test('more transactions than one SQLite query can bind (32,766)', () async {
    final big = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(big.close);
    await big.into(big.households).insert(HouseholdsCompanion.insert(
        id: 'h', name: 'Huge', createdByDeviceId: 't'));
    for (final id in ['a', 'b']) {
      await big.into(big.accounts).insert(AccountsCompanion.insert(
          id: id, householdId: 'h', name: id, type: 'bank', currency: 'USD',
          deviceId: 't'));
    }
    const n = 40000;
    final start = DateTime(2020);
    await big.batch((b) {
      for (var i = 0; i < n; i++) {
        final transfer = i % 10 == 0;
        b.insert(big.transactions, TransactionsCompanion.insert(
            id: 't$i', householdId: 'h',
            type: transfer ? 'transfer' : 'expense',
            accountId: 'a',
            destinationAccountId: Value(transfer ? 'b' : null),
            amount: transfer ? 2 : 1, currency: 'USD',
            createdBy: 't', deviceId: 't',
            createdAt: Value(start.add(Duration(minutes: i)))));
        if (!transfer) {
          b.insert(big.transactionLines, TransactionLinesCompanion.insert(
              id: 'l$i', transactionId: 't$i', amount: 1, currency: 'USD',
              accountId: const Value('a')));
        }
      }
    });
    const transfers = n ~/ 10;
    const expenses = n - transfers;
    final balances = await timed('40,000 transactions: account balances',
        () => BalanceCalculator(big).allAccountBalances('h'));
    expect(balances['a'], -(expenses + 2.0 * transfers));
    expect(balances['b'], 2.0 * transfers);

    final c = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(big)]);
    addTearDown(c.dispose);
    c.read(currentHouseholdIdProvider.notifier).set('h');
    final all = await timed('40,000 transactions: Activity history',
        () => _valueOf(c, transactionEntriesProvider), limitMs: 20000);
    expect(all, hasLength(n));
    expect(all.first.accountBalanceAfter, balances['a']);

    final account = await (big.select(big.accounts)
          ..where((a) => a.id.equals('a')))
        .getSingle();
    final running = await timed('40,000 transactions: web account history',
        () => accountRunning(big, account), limitMs: 20000);
    expect(running, hasLength(n));
  });

  test('the operation log rebuilds the whole budget', () async {
    final ops = await timed('op log: read', () => loadOps(db),
        note: (o) => '${o.length} entries');
    final size = (await db
            .customSelect('SELECT SUM(LENGTH(data)) + SUM(IFNULL(LENGTH(old), 0)) '
                'AS b FROM sync_ops')
            .getSingle())
        .read<int>('b');
    timings.add(('op log: size', 0, '${(size / 1024 / 1024).toStringAsFixed(1)} MB of JSON'));
    final copy = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(copy.close);
    await timed('op log: replay into an empty app', () => replayOps(copy, ops),
        limitMs: 60000);
    for (final t in opLogTables) {
      final q = 'SELECT * FROM $t ORDER BY id';
      expect([for (final r in await copy.customSelect(q).get()) r.data],
          [for (final r in await db.customSelect(q).get()) r.data],
          reason: t);
    }
  });

  test('saving one more expense refreshes the history', () async {
    final updated = Completer<int>();
    final sub = container.listen(transactionEntriesProvider, (_, next) {
      final n = next.value?.length;
      if (n == entries.length + 1 && !updated.isCompleted) updated.complete(n);
    });
    await timed('save one expense → Activity updated', () async {
      await AllocationEngine(db).recordTransaction(
        householdId: hh,
        accountId: 'card',
        type: 'expense',
        lines: const [TxLine(amount: 4.5, currency: 'USD', categoryId: 'coffee')],
        baseCurrency: BigBudget.base,
        note: 'Costa',
      );
      return updated.future;
    });
    sub.close();
    entries = await _valueOf(container, transactionEntriesProvider);
  });

  // ── The screens, built with all of it ───────────────────────────
  final screens = <String, Widget Function()>{
    'Home': () => const DashboardScreen(),
    'Activity': () => const TransactionsScreen(),
    'Budget': () => const AllocationsScreen(),
    'Fund envelopes': () => const FundingScreen(),
    'Accounts': () => const AccountsScreen(),
    'Account detail (card)': () => const AccountDetailScreen(accountId: 'card'),
    'Envelope detail (food)': () =>
        const AllocationDetailScreen(allocationId: 'env-food_drink'),
    'Change log': () => const ChangeLogScreen(),
    'Reports home': () => const Scaffold(body: ReportsHome()),
    'Report: budget': () => const BudgetReport(),
    'Report: spending': () => const SpendingReport(),
    'Report: money': () => const MoneyReport(),
    'Report: places': () => const PlacesReport(),
    'Report: biggest': () => const BiggestReport(),
    'Report: accounts': () => const AccountsReport(),
    'Report: year': () => const YearReport(),
  };
  for (final MapEntry(key: name, value: build) in screens.entries) {
    testWidgets('screen: $name builds with the whole history', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      // Keep every error's details (which widget), not only the first.
      final errors = <FlutterErrorDetails>[];
      final onError = FlutterError.onError;
      FlutterError.onError = (d) {
        errors.add(d);
        onError?.call(d);
      };
      final sw = Stopwatch()..start();
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: build(),
        ),
      ));
      // Let the streams and futures settle (real time: the database).
      var waited = 0;
      while (waited < 40) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 50)));
        await tester.pump(const Duration(milliseconds: 50));
        waited++;
        if (find.byType(CircularProgressIndicator).evaluate().isEmpty &&
            waited >= 4) {
          break;
        }
      }
      sw.stop();
      timings.add(('screen: $name', sw.elapsedMilliseconds,
          'settled after ${waited * 50} ms of waiting'));
      FlutterError.onError = onError;
      for (final d in errors) {
        // ignore: avoid_print
        print('── $name ──\n'
            '${d.toString().split('\n').take(16).join('\n')}');
      }
      expect(tester.takeException(), isNull);
      expect(find.byType(CircularProgressIndicator), findsNothing,
          reason: '$name still loading');
      // Unmount; closing the database streams schedules timers of its own.
      await tester.pumpWidget(const SizedBox.shrink());
      for (var i = 0; i < 3; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 50)));
        await tester.pump(const Duration(milliseconds: 10));
      }
    });
  }
}
