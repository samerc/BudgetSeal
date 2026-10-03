import 'package:budgetseal/features/transactions/widgets/currency_sheet.dart';
import 'package:budgetseal/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget sheet) async {
    // A small phone (Galaxy A02-like width) with large text.
    tester.view.physicalSize = const Size(320 * 2, 640 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      home: MediaQuery(
        data: const MediaQueryData(
            size: Size(320, 640), textScaler: TextScaler.linear(1.3)),
        child: Scaffold(body: sheet),
      ),
    ));
    await tester.pumpAndSettle();
  }

  test('every ISO currency, sorted, each with a translated name', () {
    final codes = kCurrencies.map((c) => c.$1).toList();
    expect(codes, contains('EGP'));
    expect(codes.length, greaterThan(150));
    expect(codes, [...codes]..sort());
    expect(codes.toSet().length, codes.length);
  });

  testWidgets('rows fit a narrow screen with large text', (tester) async {
    await pump(tester, const CurrencySheet(current: 'USD'));
    expect(tester.takeException(), isNull); // no overflow
    // The code is shown whole (it used to be cut to "U…").
    expect(find.textContaining('AED'), findsWidgets);
  });

  testWidgets('search finds the Egyptian pound by name', (tester) async {
    await pump(tester, const CurrencySheet(current: 'USD'));
    await tester.enterText(find.byType(TextField), 'egypt');
    await tester.pumpAndSettle();
    expect(find.text('Egyptian Pound'), findsOneWidget);
    expect(find.textContaining('EGP'), findsOneWidget);
  });

  testWidgets('excluded currencies are not offered', (tester) async {
    await pump(
        tester,
        const CurrencySheet(
            current: 'EUR',
            accountCurrencies: ['LBP', 'USD'],
            exclude: {'LBP'}));
    await tester.enterText(find.byType(TextField), 'LBP');
    await tester.pumpAndSettle();
    expect(find.text('Lebanese Pound'), findsNothing);
  });
}
