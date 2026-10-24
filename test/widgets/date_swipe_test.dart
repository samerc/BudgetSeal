import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgetseal/shared/widgets/date_swipe.dart';

void main() {
  Future<DateTime?> fling(WidgetTester tester, Offset by,
      {TextDirection dir = TextDirection.ltr, DateTime? last}) async {
    DateTime? got;
    await tester.pumpWidget(Directionality(
      textDirection: dir,
      child: Center(
        child: DateSwipe(
          date: DateTime(2026, 10, 24),
          lastDate: last,
          onChanged: (d) => got = d,
          child: const SizedBox(width: 200, height: 40),
        ),
      ),
    ));
    await tester.fling(find.byType(SizedBox), by, 1000);
    await tester.pumpAndSettle();
    return got;
  }

  testWidgets('swiping right goes to the day before, left to the next',
      (tester) async {
    expect(await fling(tester, const Offset(150, 0)), DateTime(2026, 10, 23));
    expect(await fling(tester, const Offset(-150, 0)), DateTime(2026, 10, 25));
  });

  testWidgets('directions swap in RTL', (tester) async {
    expect(await fling(tester, const Offset(150, 0), dir: TextDirection.rtl),
        DateTime(2026, 10, 25));
  });

  testWidgets('never past the last date', (tester) async {
    expect(
        await fling(tester, const Offset(-150, 0),
            last: DateTime(2026, 10, 24, 18)),
        isNull);
  });
}
