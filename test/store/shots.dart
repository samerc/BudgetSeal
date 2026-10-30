import 'package:budgetseal/features/allocations/allocation_detail_screen.dart';
import 'package:budgetseal/features/forecast/forecast_screen.dart';
import 'package:budgetseal/features/main/main_screen.dart';
import 'package:budgetseal/features/recurring/upcoming_bills_screen.dart';
import 'package:budgetseal/features/reports/time/report_view.dart';
import 'package:budgetseal/features/transactions/bill_splitter_screen.dart';
import 'package:budgetseal/features/transactions/calendar_screen.dart';
import 'package:budgetseal/features/transactions/quick_add_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// One store screenshot: where the app opens, and what to do there first.
class Shot {
  const Shot(this.name, this.location, {this.dark = false, this.act});
  final String name;
  final String location;
  final bool dark;
  final Future<void> Function(WidgetTester tester)? act;
}

Future<void> Function(WidgetTester) _tab(String label) =>
    (tester) async => tester.tap(find.text(label).last);

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump(const Duration(milliseconds: 150));
  }
}

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.tap(f, warnIfMissed: false);
  await _settle(tester);
}

/// Picks a suggestion: the form fills itself from a past purchase.
Future<void> _addFilled(WidgetTester tester) async {
  await _tap(tester, find.textContaining("Trader Joe").first);
}

/// A dinner for three with a tip.
Future<void> _splitDinner(WidgetTester tester) async {
  await _tap(tester, find.text(r'$0.00').first);
  for (final k in ['8', '6']) {
    await _tap(tester, find.text(k).last);
  }
  await _tap(tester, find.text('Done').last);
  for (final name in ['Sam', 'Maya']) {
    await _tap(tester, find.text('Add').last);
    await tester.enterText(find.byType(EditableText).last, name);
    await _tap(tester, find.text('Add').last);
  }
  await _tap(tester, find.text('15%').first);
}

final shots = <Shot>[
  const Shot('01_home', '/'),
  Shot('02_budget', '/', act: _tab('Budget')),
  Shot('03_activity', '/', act: _tab('Activity')),
  const Shot('04_envelope', '/allocations/japan'),
  Shot('05_reports', '/', act: _tab('Reports')),
  const Shot('06_forecast', '/forecast'),
  const Shot('07_bills', '/upcoming-bills'),
  const Shot('08_calendar', '/calendar'),
  const Shot('09_add', '/add-transaction', act: _addFilled),
  const Shot('10_splitter', '/bill-splitter', act: _splitDinner),
  const Shot('11_home_dark', '/', dark: true),
];

typedef ShotRoute = ({String path, Widget Function(GoRouterState) builder});

final List<ShotRoute> shotRoutes = [
  (path: '/', builder: (_) => const MainScreen()),
  (
    path: '/allocations/:id',
    builder: (s) =>
        AllocationDetailScreen(allocationId: s.pathParameters['id']!),
  ),
  (path: '/forecast', builder: (_) => const ForecastScreen()),
  (path: '/upcoming-bills', builder: (_) => const UpcomingBillsScreen()),
  (path: '/calendar', builder: (_) => const CalendarScreen()),
  (path: '/add-transaction', builder: (_) => QuickAddScreen.fromExtra(null)),
  (path: '/bill-splitter', builder: (_) => const BillSplitterScreen()),
  (
    path: '/reports/view/:id',
    builder: (s) => ReportView(id: s.pathParameters['id']!),
  ),
];
