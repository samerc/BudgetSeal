import 'package:budgetseal/shared/utils/format_number.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

void main() {
  tearDown(() {
    Intl.defaultLocale = null;
    setCurrencySymbolOverrides({});
  });

  test('LBP, SYP, IRR and IQD have no decimals', () {
    for (final c in ['LBP', 'SYP', 'IRR', 'IQD']) {
      expect(currencyDecimals(c), 0, reason: c);
    }
    expect(currencyDecimals('KWD'), 3);
    expect(currencyDecimals('LBP', 2), 2); // an account's own setting wins
  });

  test('Arabic-script symbols show the code outside Arabic', () {
    Intl.defaultLocale = 'en';
    expect(formatAmount(1200000, currency: 'LBP'), 'LBP 1,200,000');
    expect(formatAmount(-5, currency: 'AED'), 'AED -5.00');
    expect(formatAmount(5, currency: 'USD'), '\$5.00');
    expect(defaultCurrencySymbols['LBP'], 'LBP');

    Intl.defaultLocale = 'fr';
    expect(defaultCurrencySymbols['SAR'], 'SAR');
  });

  test('Arabic keeps the native symbol', () {
    Intl.defaultLocale = 'ar';
    expect(defaultCurrencySymbols['LBP'], 'ل.ل');
    expect(formatAmount(1200000, currency: 'LBP'), contains('ل.ل'));
  });

  test("a user's own symbol wins in every language", () {
    Intl.defaultLocale = 'en';
    setCurrencySymbolOverrides({'LBP': 'ل.ل'});
    expect(formatAmount(1, currency: 'LBP'), contains('ل.ل'));
  });
}
