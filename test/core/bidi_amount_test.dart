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

  test('hide amounts: the number goes, the symbol and sign stay', () {
    Intl.defaultLocale = 'en';
    setHideAmounts(true);
    addTearDown(() => setHideAmounts(false));
    expect(formatAmount(1234.5, currency: 'USD'), r'$•••');
    expect(formatAmount(-1200000, currency: 'LBP'), 'LBP -•••');
    expect(formatSignedAmount(200, currency: 'USD', type: 'income'),
        r'+$•••');
    // Rates and percentages aren't money.
    expect(formatNumber(89500, decimals: 0), '89,500');
    setHideAmounts(false);
    expect(formatAmount(1234.5, currency: 'USD'), r'$1,234.50');
  });
}
