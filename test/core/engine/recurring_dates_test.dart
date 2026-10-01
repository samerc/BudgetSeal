import 'package:flutter_test/flutter_test.dart';
import 'package:budgetseal/core/engine/recurring_engine.dart';

void main() {
  group('advanceRecurringDate', () {
    test('monthly clamps to short months and returns to the anchor day', () {
      final feb = advanceRecurringDate(DateTime(2026, 1, 31), 'monthly', 1,
          anchorDay: 31);
      expect(feb, DateTime(2026, 2, 28));
      final mar = advanceRecurringDate(feb, 'monthly', 1, anchorDay: 31);
      expect(mar, DateTime(2026, 3, 31));
      final apr = advanceRecurringDate(mar, 'monthly', 1, anchorDay: 31);
      expect(apr, DateTime(2026, 4, 30));
    });

    test('monthly interval crosses the year', () {
      expect(
          advanceRecurringDate(DateTime(2026, 11, 15), 'monthly', 3),
          DateTime(2027, 2, 15));
    });

    test('yearly Feb 29 clamps in common years', () {
      expect(
          advanceRecurringDate(DateTime(2028, 2, 29), 'yearly', 1,
              anchorDay: 29),
          DateTime(2029, 2, 28));
    });

    test('daily and weekly keep the wall-clock time across DST', () {
      final from = DateTime(2026, 3, 28, 9, 30);
      expect(advanceRecurringDate(from, 'daily', 2), DateTime(2026, 3, 30, 9, 30));
      expect(advanceRecurringDate(from, 'weekly', 1), DateTime(2026, 4, 4, 9, 30));
    });
  });
}
