import 'package:flutter_test/flutter_test.dart';
import 'package:budgetseal/features/settings/import_screen.dart';
import 'package:budgetseal/shared/utils/format_number.dart';

void main() {
  group('parseImportDate', () {
    test('ISO dates, with or without a time', () {
      expect(parseImportDate('2026-03-04', dayFirst: false),
          DateTime(2026, 3, 4));
      expect(parseImportDate('2026-03-04 13:45:00', dayFirst: true),
          DateTime(2026, 3, 4));
    });

    test('slash dates follow the detected order', () {
      expect(parseImportDate('03/04/2026', dayFirst: false),
          DateTime(2026, 3, 4));
      expect(parseImportDate('03/04/2026', dayFirst: true),
          DateTime(2026, 4, 3));
      expect(parseImportDate('4.3.26', dayFirst: true), DateTime(2026, 3, 4));
    });

    test('rejects impossible dates instead of rolling them over', () {
      expect(parseImportDate('2026-02-30', dayFirst: false), isNull);
      expect(parseImportDate('13/25/2026', dayFirst: false), isNull);
      expect(parseImportDate('25/12/2026', dayFirst: false), isNull);
      expect(parseImportDate('yesterday', dayFirst: false), isNull);
      expect(parseImportDate('', dayFirst: false), isNull);
    });
  });

  group('parseLooseAmount', () {
    test('both separator conventions', () {
      expect(parseLooseAmount('1,234.56'), 1234.56);
      expect(parseLooseAmount('1.234,56'), 1234.56);
      expect(parseLooseAmount('12,50'), 12.5);
      expect(parseLooseAmount('1,234'), 1234);
      expect(parseLooseAmount('1.234.567'), 1234567);
      expect(parseLooseAmount('12.5'), 12.5);
    });

    test('signs and symbols', () {
      expect(parseLooseAmount(r'-$5.00'), -5);
      expect(parseLooseAmount('(5.00)'), -5);
      expect(parseLooseAmount('€ 4,50'), 4.5);
      expect(parseLooseAmount('abc'), isNull);
    });
  });
}
