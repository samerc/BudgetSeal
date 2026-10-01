import 'package:flutter_test/flutter_test.dart';
import 'package:budgetseal/features/settings/import_screen.dart';

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
}
