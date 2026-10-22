import 'package:budgetseal/shared/utils/calendar_days.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('counts calendar days, not 24-hour blocks', () {
    // Spans the Oct 25 2026 daylight-saving change in Lebanon (a 25-hour
    // day); inDays on local dates gave 1 here.
    expect(calendarDaysBetween(DateTime(2026, 10, 23, 0, 30),
        DateTime(2026, 10, 25)), 2);
    expect(calendarDaysBetween(DateTime(2026, 3, 28), DateTime(2026, 3, 30)), 2);
    expect(calendarDaysBetween(DateTime(2026, 1, 31, 23, 59),
        DateTime(2026, 2, 1, 0, 1)), 1);
    expect(calendarDaysBetween(DateTime(2026, 5, 10), DateTime(2026, 5, 7)), -3);
    expect(calendarDaysBetween(DateTime(2026, 5, 10, 8), DateTime(2026, 5, 10, 22)), 0);
  });
}
