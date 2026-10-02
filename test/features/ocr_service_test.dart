import 'package:flutter_test/flutter_test.dart';
import 'package:budgetseal/shared/utils/ocr_service.dart';

void main() {
  group('OcrService line kinds', () {
    OcrLineKind k(String s) => OcrService.classifyForTest(s);

    test('items', () {
      expect(k('Burger deluxe  12.50'), OcrLineKind.item);
      expect(k('2 x Coffee  7.00'), OcrLineKind.item);
      expect(k('Taxi fare 15.00'), OcrLineKind.item); // "tax" is a whole word
    });

    test('totals and subtotals', () {
      expect(k('TOTAL  52.70'), OcrLineKind.total);
      expect(k('Grand Total 52.70'), OcrLineKind.total);
      expect(k('Total TTC 48,00'), OcrLineKind.total);
      expect(k('Subtotal 45.00'), OcrLineKind.other);
      expect(k('Sous-total 40,00'), OcrLineKind.other);
      expect(k('المجموع 120.000'), OcrLineKind.total);
    });

    test('tax and service', () {
      expect(k('VAT 11%  4.95'), OcrLineKind.tax);
      expect(k('TVA 10% 4,00'), OcrLineKind.tax);
      expect(k('Service charge 5.00'), OcrLineKind.tax);
      expect(k('ضريبة القيمة المضافة 11,000'), OcrLineKind.tax);
    });

    test('payment, change and tip lines are not items', () {
      expect(k('CASH  60.00'), OcrLineKind.other);
      expect(k('Change 7.30'), OcrLineKind.other);
      expect(k('Visa ****1234 52.70'), OcrLineKind.other);
      expect(k('Tip 5.00'), OcrLineKind.other);
    });

    test('discounts', () {
      expect(k('Discount 10%  -4.50'), OcrLineKind.discount);
      expect(k('Remise fidélité 2,00'), OcrLineKind.discount);
      expect(k('خصم 5.000'), OcrLineKind.discount);
    });
  });

  group('OcrService item parsing', () {
    test('Arabic item names are kept', () {
      final item = OcrService.parseLineForTest('شاورما دجاج  350,000');
      expect(item, isNotNull);
      expect(item!.name, 'شاورما دجاج');
      expect(item.amount, 350000);
    });

    test('decimal comma and quantity', () {
      final item = OcrService.parseLineForTest('2 x Croissant  4,50');
      expect(item!.quantity, 2);
      expect(item.amount, 4.5);
      expect(item.name, 'Croissant');
    });
  });
}
