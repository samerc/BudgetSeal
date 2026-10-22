import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:budgetseal/shared/utils/ocr_service.dart';

/// A receipt laid out in its own (straight) frame, then photographed tilted
/// by [tilt] radians: each line gets the box and angle the recognizer
/// would report.
class _Receipt {
  final double tilt;
  final lines = <OcrRawLine>[];
  _Receipt([this.tilt = 0]);

  /// A line whose left edge is [x], vertical centre [y], [w] wide.
  void add(String text, double x, double y, [double? w]) {
    final width = w ?? text.length * 14.0;
    const h = 28.0;
    final cx = x + width / 2;
    // Rotate the centre into the photo.
    final c = math.cos(tilt), s = math.sin(tilt);
    final px = cx * c - y * s, py = cx * s + y * c;
    final bw = width * c.abs() + h * s.abs();
    final bh = width * s.abs() + h * c.abs();
    lines.add(OcrRawLine(
      text: text,
      rect: ui.Rect.fromCenter(center: ui.Offset(px, py), width: bw, height: bh),
      angle: tilt,
      height: h,
    ));
  }

  /// "name ……… price": name at the left margin, price right-aligned.
  void row(String name, String price, double y) {
    add(name, 40, y);
    add(price, 760 - price.length * 14.0, y);
  }

  OcrResult parse({String? currency}) => OcrService.parseLines(lines,
      imageWidth: 800, imageHeight: 1400, currency: currency);
}

List<(String, double, int)> _items(OcrResult r) => [
      for (final l in r.lines)
        if (l.hasPrice) (l.parsedName!, l.parsedAmount!, l.parsedQuantity),
    ];

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
      expect(k('Other Total (incl VAT)  2,400,000'), OcrLineKind.total);
    });

    test('tax numbers and included VAT are not tax to add', () {
      expect(k('VAT no: 122732-601'), OcrLineKind.other);
      expect(k('TAX INVOICE'), OcrLineKind.other);
      expect(k('Prices include VAT  237,838'), OcrLineKind.other);
      expect(k('Delivery Charge  200,000'), OcrLineKind.tax);
      expect(k('Rounding Adjustment  0'), OcrLineKind.other);
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
    ExtractedItem? p(String s, {String? currency}) =>
        OcrService.parseLineForTest(s, currency: currency);

    test('Arabic item names are kept', () {
      final item = p('شاورما دجاج  350,000');
      expect(item, isNotNull);
      expect(item!.name, 'شاورما دجاج');
      expect(item.amount, 350000);
    });

    test('decimal comma and quantity', () {
      final item = p('2 x Croissant  4,50');
      expect(item!.quantity, 2);
      expect(item.amount, 4.5);
      expect(item.name, 'Croissant');
    });

    test('names keep their first word; only codes with a digit go', () {
      expect(p('Pizza margherita  24.00')!.name, 'Pizza margherita');
      expect(p('Chicken shawarma 350,000')!.name, 'Chicken shawarma');
      expect(p('2745P Mango juice 4.50')!.name, 'Mango juice');
      expect(p('SKU1234 Olive oil  9.99')!.name, 'Olive oil');
    });

    test('letters read as digits inside numbers', () {
      expect(p('Water 0.5L  1,5OO')!.amount, 1500);
      expect(p('Water 0.5L  1,5OO')!.name, 'Water 0.5L');
      expect(p('Hummus  l2.50')!.amount, 12.5);
      // "1.5l" is litres, not 1.51.
      expect(p('Pepsi 1.5l  2,000')!.name, 'Pepsi 1.5l');
      expect(p('Olive oil  9.99')!.name, 'Olive oil');
    });

    test('the bill currency settles 3-digit fractions', () {
      expect(p('Tabbouleh  12.500', currency: 'LBP')!.amount, 12500);
      expect(p('Tabbouleh  12.500', currency: 'USD')!.amount, 12500);
      expect(p('Machboos  2.750', currency: 'KWD')!.amount, 2.75);
      expect(p('Machboos  2,750', currency: 'BHD')!.amount, 2.75);
    });

    test('inline unit price', () {
      final item = p('Coffee 2 @ 4.50  9.00')!;
      expect(item.name, 'Coffee');
      expect(item.quantity, 2);
      expect(item.amount, 9);
    });
  });

  group('OcrService receipt layout', () {
    test('a tilted photo still pairs each name with its price', () {
      // 3°: across 700 px the price sits ~37 px lower than its name —
      // more than a line height.
      final r = _Receipt(3 * math.pi / 180)
        ..row('Mezze platter', '28.00', 300)
        ..row('Pizza margherita', '24.00', 340)
        ..row('Burger', '16.00', 380)
        ..row('TOTAL', '68.00', 440);
      final res = r.parse(currency: 'USD');
      expect(_items(res), [
        ('Mezze platter', 28.0, 1),
        ('Pizza margherita', 24.0, 1),
        ('Burger', 16.0, 1),
      ]);
      expect(res.receiptTotal, 68);
    });

    test('header numbers and lines after the total are not items', () {
      final r = _Receipt()
        ..add('Cafe Hamra', 300, 80)
        ..add('Hamra Street 45', 250, 120)
        ..add('Table 12', 330, 160)
        ..row('Fattoush', '9.00', 300)
        ..row('Hummus', '6.50', 340)
        ..row('Kebab plate', '18.00', 380)
        ..row('TOTAL', '33.50', 440)
        ..row('CASH', '50.00', 480)
        ..row('Points earned', '3.35', 520);
      final res = r.parse(currency: 'USD');
      expect(_items(res), [
        ('Fattoush', 9.0, 1),
        ('Hummus', 6.5, 1),
        ('Kebab plate', 18.0, 1),
      ]);
    });

    test('a wrapped name joins its item', () {
      final r = _Receipt()
        ..row('Chicken shawarma', '350,000', 300)
        ..add('extra garlic', 40, 334)
        ..row('Ayran', '80,000', 380);
      expect(_items(r.parse(currency: 'LBP')), [
        ('Chicken shawarma extra garlic', 350000.0, 1),
        ('Ayran', 80000.0, 1),
      ]);
    });

    test('a quantity line goes to the item above', () {
      final r = _Receipt()
        ..add('Mango juice', 40, 300)
        ..add('2 x 4.50', 80, 334)
        ..add('9.00', 690, 334)
        ..row('Croissant', '3.20', 380);
      expect(_items(r.parse(currency: 'USD')), [
        ('Mango juice', 9.0, 2),
        ('Croissant', 3.2, 1),
      ]);
    });

    test('a real LBP scan (ML Kit output, Oct 2026)', () {
      // Text exactly as the recognizer read a tilted cafe receipt: spaces
      // after separators, a dropped zero ("650,00"), a date header and a
      // quantity line two rows down at real spacing (text 22 px, rows 44).
      final lines = <OcrRawLine>[];
      var y = 100.0;
      void line(String text, [double x = 40]) {
        lines.add(OcrRawLine(
            text: text,
            rect: ui.Rect.fromLTWH(x, y, text.length * 13.0, 22)));
      }

      void row(String name, String price) {
        line(name);
        line(price, 760 - price.length * 13.0);
        y += 44;
      }

      line('CAFE HAMRA', 300); y += 44;
      line('Hamra Street 45, Beirut', 220); y += 44;
      line('Tel 01 345 678', 260); y += 44;
      line('Table 12  22/10/ 2026 13:05', 200); y += 64;
      row('Mezze platter', '1,250, 000');
      row('Pizza margherita', '980,000');
      row('Chicken shawarma', '650,00');
      line('extra garlic', 70); y += 44;
      line('Lemonade'); y += 44;
      row('3 X 150,000', '450,000');
      row('Tabbouleh', '400,000');
      row('Burger', '850,000');
      y += 20;
      row('TOTAL', '4,580, 000');
      row('CASH', '5,000, 000');
      row('CHANGE', '420,000');
      line('Thank you!', 300);

      final res = OcrService.parseLines(lines,
          imageWidth: 800, imageHeight: 1400, currency: 'USD');
      expect(_items(res), [
        ('Mezze platter', 1250000.0, 1),
        ('Pizza margherita', 980000.0, 1),
        ('Chicken shawarma extra garlic', 650000.0, 1),
        ('Lemonade', 450000.0, 3),
        ('Tabbouleh', 400000.0, 1),
        ('Burger', 850000.0, 1),
      ]);
      expect(res.receiptTotal, 4580000);
    });

    test("a real McDonald's Lebanon receipt (ML Kit output, Oct 2026)", () {
      // Meals print their parts indented under them ("1 Regular Fries",
      // "NO Ice"); the total says "(incl VAT)"; the VAT line after it is
      // already included; the header has a VAT number; delivery is a charge.
      OcrRawLine l(String text, double l, double t, double r, double b,
              double angle, double h) =>
          OcrRawLine(
              text: text,
              rect: ui.Rect.fromLTRB(l, t, r, b),
              angle: angle,
              height: h);
      final lines = [
      l('** MDS-8865 **', 365, 24, 693, 92, -0.0920, 38.1),
      l("McDonald's Lebanon", 417, 126, 629, 170, -0.0997, 23.1),
      l('Restaurant #3360009', 418, 151, 641, 199, -0.1171, 22.1),
      l('Hazmieh', 486, 186, 568, 217, -0.0997, 23.1),
      l('Crew id 666 - haidar ossaily', 363, 345, 699, 394, -0.0715, 25.0),
      l('TAX INVOICE', 464, 383, 592, 415, -0.0786, 22.0),
      l('MFY Side 1', 474, 411, 592, 441, -0.0683, 22.0),
      l('Www.mcdona lds,com. 1b', 406, 202, 639, 257, -0.1340, 24.2),
      l('Tel: 05 453998', 443, 237, 606, 282, -0.1366, 23.2),
      l('VAT no: 122732-601', 418, 264, 628, 311, -0.1101, 24.1),
      l('ORD #08-REG #99-04/10/2026 12:22:06', 319, 459, 742, 508, -0.0568, 25.0),
      l('QTY ITEM', 289, 508, 381, 537, -0.0768, 22.0),
      l('1 Reg ChickenMac Meal', 322, 523, 559, 566, -0.0677, 27.0),
      l('1 Regular Fries', 345, 557, 513, 594, -0.0598, 27.0),
      l('1 No Promo', 348, 591, 452, 621, -0.0384, 26.0),
      l('1 Reg Cola Zero', 344, 617, 514, 652, -0.0473, 27.0),
      l('1 Reg BigTasty Meal', 322, 647, 537, 683, -0.0420, 27.0),
      l('1 Regular Fries', 348, 679, 517, 712, -0.0416, 26.0),
      l('1 No Promo', 342, 713, 457, 736, -0.0261, 20.0),
      l('1 Regular Fanta', 354, 734, 520, 768, -0.0484, 26.0),
      l('NO Ice', 390, 769, 459, 792, -0.0290, 21.0),
      l('1 HM Hamburger', 326, 797, 480, 824, -0.0130, 25.0),
      l('1 Hamburger', 350, 830, 473, 854, 0.0000, 24.0),
      l('ADD Cheddar Chees', 388, 849, 595, 882, -0.0435, 24.0),
      l('ONLY Ketchup', 389, 882, 533, 914, -0.0419, 26.0),
      l('ONLY Mustard', 390, 912, 535, 941, -0.0345, 24.0),
      l('1 Orange Juice Box', 352, 941, 561, 976, -0.0432, 26.0),
      l('1 Toy For Girl', 356, 973, 508, 1005, -0.0329, 27.0),
      l('1 Smal1 Fries', 356, 1003, 499, 1033, -0.0210, 27.0),
      l('3 BigTasty Sauce', 319, 1034, 512, 1065, -0.0259, 26.0),
      l('Subtotal', 300, 1157, 393, 1180, 0.0000, 23.0),
      l('Rounding Adjustment', 297, 1092, 525, 1126, -0.0307, 27.0),
      l('Change', 292, 1304, 365, 1332, 0.0000, 28.0),
      l('Delivery Charge', 303, 1215, 482, 1239, 0.0000, 24.0),
      l('Other Total (incl VAT)', 297, 1242, 560, 1268, 0.0000, 26.0),
      l('Cash Tendered', 298, 1273, 456, 1298, 0.0000, 25.0),
      l('TOTAL INCLUDES VAT OF 118', 287, 1372, 604, 1397, 0.0000, 25.0),
      l('TOTAL', 715, 489, 776, 514, 0.0000, 25.0),
      l('700,000', 691, 517, 777, 546, -0.0470, 25.0),
      l('900,000', 692, 638, 777, 666, -0.0235, 26.0),
      l('450,000', 696, 783, 778, 812, -0.0244, 27.0),
      l('150,000', 703, 1024, 785, 1053, -0.0493, 25.0),
      l('2,200,000', 679, 1145, 786, 1177, -0.0187, 30.0),
      l('200,000', 705, 1208, 791, 1232, 0.0000, 24.0),
      l('2,400,000', 687, 1235, 796, 1264, -0.0275, 26.0),
      l('2,400,000', 681, 1265, 793, 1297, -0.0450, 27.0),
      l('0', 785, 1301, 797, 1324, 0.0000, 23.0),
      l('237,838', 710, 1366, 799, 1398, -0.0225, 30.0),
      l('Thank you for your visit', 378, 1405, 688, 1435, 0.0000, 30.0),
      l("Download McDona ld's App", 385, 1437, 690, 1474, 0.0000, 37.0),
      l('to benefit from daily offers', 345, 1476, 719, 1508, 0.0000, 32.0),
      ];
      final res = OcrService.parseLines(lines,
          imageWidth: 1203, imageHeight: 1600, currency: 'LBP');
      expect(_items(res), [
        ('Reg ChickenMac Meal', 700000.0, 1),
        ('Reg BigTasty Meal', 900000.0, 1),
        ('HM Hamburger', 450000.0, 1),
        ('BigTasty Sauce', 150000.0, 3),
      ]);
      expect(res.receiptTotal, 2400000);
      expect(res.taxTotal, 200000);
      // Meal parts, header and footer aren't items waiting for a price.
      expect(
          res.lines
              .where((l) => l.kind == OcrLineKind.item && !l.hasPrice)
              .map((l) => l.text),
          isEmpty);
    });

    test('the total only fixes a price when exactly one change matches', () {
      // Two suspicious prices could each explain the gap: leave both.
      final r = _Receipt()
        ..row('Fries', '300,00', 300)
        ..row('Salad', '300,00', 340)
        ..row('Steak', '1,200,000', 380)
        ..row('Wine', '900,000', 420)
        ..row('TOTAL', '2,400,300', 480);
      expect(_items(r.parse()).map((i) => i.$2), [300, 300, 1200000, 900000]);
    });

    test('a price printed just under its name', () {
      final r = _Receipt()
        ..add('Caesar salad', 40, 300)
        ..add('12.00', 690, 324)
        ..row('Lemonade', '4.00', 380);
      expect(_items(r.parse(currency: 'USD')), [
        ('Caesar salad', 12.0, 1),
        ('Lemonade', 4.0, 1),
      ]);
    });
  });
}
