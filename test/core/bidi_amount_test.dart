import 'package:budgetseal/shared/utils/format_number.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

void main() {
  tearDown(() => Intl.defaultLocale = null);

  test('signed amounts keep their sign in front in Arabic', () {
    Intl.defaultLocale = 'ar';
    expect(formatAmount(-450, currency: 'USD'), startsWith('‎'));
    expect(formatSignedAmount(200, currency: 'USD', type: 'income'),
        startsWith('‎'));
    // Unsigned amounts are left alone.
    expect(formatAmount(450, currency: 'USD'), isNot(startsWith('‎')));
    // The mark doesn't break parsing a displayed amount back.
    expect(parseLooseAmount(formatAmount(-450, currency: 'USD')), -450);
  });

  test('no mark in left-to-right languages', () {
    Intl.defaultLocale = 'en';
    expect(formatAmount(-450, currency: 'USD'), '-\$450.00');
  });
}
