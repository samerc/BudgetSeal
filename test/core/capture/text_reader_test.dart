import 'package:budgetseal/core/capture/text_reader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a card purchase SMS: amount, shop, card, date; the balance after is '
      'not the amount', () {
    final d = readCapturedText(
        'Your Visa card ending 1234 was used for USD 45.20 at SPINNEYS '
        'ACHRAFIEH on 27/10/2026. Available balance USD 1,204.80');
    expect(d.amount, 45.2);
    expect(d.currency, 'USD');
    expect(d.type, 'expense');
    expect(d.merchant, 'SPINNEYS ACHRAFIEH');
    expect(d.card, '1234');
    expect(d.date, DateTime(2026, 10, 27));
  });

  test('Lebanese pounds with thousands separators', () {
    final d = readCapturedText(
        'Purchase of LBP 1,350,000 at Charcutier Aoun with card ***5678');
    expect((d.amount, d.currency), (1350000.0, 'LBP'));
    expect(d.merchant, 'Charcutier Aoun');
    expect(d.card, '5678');
  });

  test('money in: credited, salary', () {
    final d = readCapturedText(
        r'Your account was credited with $2,500.00 salary from ACME Ltd.');
    expect((d.amount, d.currency, d.type), (2500.0, 'USD', 'income'));
    expect(d.merchant, 'ACME Ltd');
  });

  test('French: comma decimals, the euro after the amount, "chez"', () {
    final d = readCapturedText(
        'Paiement de 23,90 € chez CARREFOUR le 12/10/2026 avec la carte 4321');
    expect((d.amount, d.currency), (23.9, 'EUR'));
    expect(d.merchant, 'CARREFOUR');
    expect(d.card, '4321');
    expect(d.date, DateTime(2026, 10, 12));
  });

  test('a space as the thousands separator', () {
    final d = readCapturedText('Achat 1 234,56 EUR chez Fnac.');
    expect((d.amount, d.currency), (1234.56, 'EUR'));
  });

  test('Arabic: Arabic-Indic digits, a local currency sign, "لدى"', () {
    final d = readCapturedText('تم شراء بمبلغ ١٢٥٫٥٠ د.إ لدى كارفور بطاقة 9876');
    expect((d.amount, d.currency), (125.5, 'AED'));
    expect(d.merchant, 'كارفور');
    expect(d.card, '9876');
    expect(d.type, 'expense');
  });

  test('Arabic: a deposit is income; "your account" is not a shop', () {
    final d = readCapturedText('تم إيداع 500 USD في حسابك');
    expect((d.amount, d.currency, d.type), (500.0, 'USD', 'income'));
    expect(d.merchant, isNull);
  });

  test('no currency beside the amount: the fallback', () {
    final d = readCapturedText('Spent 12.50 at Starbucks', fallbackCurrency: 'USD');
    expect((d.amount, d.currency), (12.5, 'USD'));
    expect(d.merchant, 'Starbucks');
  });

  test('nothing to read', () {
    expect(readCapturedText('See you tomorrow!').isEmpty, isTrue);
  });
}
