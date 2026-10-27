import 'package:budgetseal/features/accounts/cash_count_screen.dart';
import 'package:budgetseal/l10n/generated/app_localizations.dart';
import 'package:budgetseal/shared/theme/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('counting notes totals them, shows the difference and returns '
      'the count', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    double? counted;
    final router = GoRouter(routes: [
      GoRoute(
        path: '/',
        builder: (context, _) => Scaffold(
          body: TextButton(
            onPressed: () async =>
                counted = await context.push<double>('/count'),
            child: const Text('open'),
          ),
        ),
      ),
      GoRoute(
        path: '/count',
        builder: (_, __) =>
            const CashCountScreen(currency: 'USD', balance: 50),
      ),
    ]);
    await tester.pumpWidget(MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: const TextScaler.linear(1.15)),
        child: child!,
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Two $20 notes and one $5 (the rows are largest first: 100, 50, 20,
    // 10, 5 …).
    final plus = find.byIcon(AppIcons.plus);
    await tester.tap(plus.at(2));
    await tester.tap(plus.at(2));
    await tester.tap(plus.at(4));
    await tester.pump();
    expect(find.textContaining(r'$45.00'), findsOneWidget);
    expect(find.textContaining(r'$5.00'), findsWidgets); // 5 short of 50

    await tester.tap(find.text('Use this count'));
    await tester.pumpAndSettle();
    expect(counted, 45);
  });
}
