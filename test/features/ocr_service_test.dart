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

    test('a real Why Cook delivery receipt (ML Kit output, Oct 2026)', () {
      // A delivery slip: the header has phone numbers ("01600000",
      // "mc 03000000"), a check number and an order number — none are
      // items. (Name, address and numbers replaced; layout kept.) Prices carry a "T" suffix; the total is in LBP and USD.
      OcrRawLine l(String text, double l, double t, double r, double b,
              double angle, double h) =>
          OcrRawLine(
              text: text,
              rect: ui.Rect.fromLTRB(l, t, r, b),
              angle: angle,
              height: h);
      final lines = [
      l('Name: JOHN', 171, 189, 314, 219, 0.0779, 19.1),
      l('Fam.: SMITH', 180, 222, 312, 255, 0.0691, 24.1),
      l('>', 180, 357, 186, 374, 0.0000, 17.1),
      l('Why Cook sarl', 330, 16, 495, 52, 0.0984, 20.2),
      l('Baabda, Highway', 334, 45, 493, 84, 0.1149, 21.2),
      l('Tel: 01000000- *03000000', 170, 254, 437, 295, 0.0641, 24.1),
      l('1st left', 211, 359, 302, 383, 0.0785, 17.1),
      l('Tel: 03111111-81222222', 179, 287, 422, 326, 0.0622, 24.1),
      l('FIr : ar', 171, 390, 235, 412, 0.0644, 18.1),
      l('Str : main street after the bakery', 170, 323, 554, 366, 0.0523, 23.1),
      l('01600000', 369, 112, 461, 139, 0.0997, 18.1),
      l('Baabda', 379, 82, 450, 107, 0.1316, 16.3),
      l('DELIVERY-J', 339, 168, 490, 201, 0.0804, 21.1),
      l('me 03000000', 172, 632, 304, 656, -0.0227, 21.0),
      l('Near: the church then north about 200 m second building', 179, 426, 658, 458, 0.0230, 21.0),
      l('Zone : TOWN -AREA', 170, 459, 380, 485, 0.0239, 21.0),
      l('City : TOWN -AREA', 171, 493, 370, 520, 0.0152, 24.0),
      l('Address Label : HOME', 170, 529, 396, 551, 0.0089, 20.0),
      l('Rem : ring the bell twice', 172, 562, 408, 587, 0.0128, 22.0),
      l('OLD QUARTER', 171, 598, 321, 618, 0.0067, 19.0),
      l('24-10-2026 13:26', 333, 664, 508, 686, -0.0171, 19.0),
      l('1 Zone 1:', 246, 906, 332, 930, -0.0233, 22.0),
      l('Firstrder Tine: 24-0ct-26 13:22:45', 250, 696, 600, 725, -0.0143, 24.0),
      l('Prowsed Tinte: 14:13:32', 302, 730, 541, 757, -0.0251, 21.0),
      l('CHECK, 1600000', 341, 765, 513, 791, -0.0233, 22.0),
      l('Order Nb 20035', 330, 796, 515, 824, -0.0324, 22.0),
      l('1 TAWOUK L', 237, 940, 375, 963, -0.0217, 20.0),
      l('1 WITH CORN', 246, 974, 386, 1002, -0.0214, 25.0),
      l('1 WITH TOMATO', 246, 1009, 420, 1038, -0.0230, 25.0),
      l('1 CHICKEN AVOCADO SALI', 246, 1041, 528, 1075, -0.0354, 24.0),
      l('1 WITH CUTLERY', 246, 1080, 427, 1110, -0.0331, 24.0),
      l('1 TAWOUK BREADED LARC', 238, 1115, 530, 1146, -0.0274, 23.0),
      l('1 ICE TEA PEACH', 246, 1154, 431, 1184, -0.0270, 25.0),
      l('TOTAL LL: 2,240,000', 296, 1222, 567, 1262, -0.0295, 32.0),
      l('TOTAL \$: 25.17', 331, 1263, 535, 1296, -0.0343, 26.0),
      l('Thank you.', 379, 1383, 488, 1406, 0.0000, 23.0),
      l('Dollar Rate: 89000', 342, 1410, 530, 1446, -0.0694, 23.0),
      l('120000T', 595, 896, 668, 920, -0.0547, 20.0),
      l('630000T', 590, 934, 673, 954, 0.0000, 20.0),
      l('Call Center Reference: 8000000', 271, 1334, 594, 1375, -0.0496, 25.0),
      l('40000T', 602, 968, 670, 989, 0.0000, 21.0),
      l('0T', 652, 1004, 672, 1022, 0.0000, 18.0),
      l('870000T', 593, 1036, 674, 1063, -0.0749, 21.0),
      l('0T', 654, 1074, 675, 1093, 0.0000, 19.0),
      l('450000T', 594, 1107, 678, 1134, -0.0841, 20.0),
      l('130000T', 598, 1143, 680, 1170, -0.0739, 21.0),
      ];
      final res = OcrService.parseLines(lines,
          imageWidth: 1084, imageHeight: 1441, currency: 'LBP');
      expect(_items(res), [
        ('Zone 1', 120000.0, 1),
        ('TAWOUK L', 630000.0, 1),
        ('WITH CORN', 40000.0, 1),
        ('CHICKEN AVOCADO SALI', 870000.0, 1),
        ('TAWOUK BREADED LARC', 450000.0, 1),
        ('ICE TEA PEACH', 130000.0, 1),
      ]);
      expect(res.receiptTotal, 2240000);
      // "TOTAL LL:" names the lira.
      expect(
          OcrService.receiptCurrency(res,
              billCurrency: 'USD', userCurrencies: {'USD', 'LBP'}),
          (code: 'LBP', printed: true));
      // The delivery address and contact lines aren't items either.
      expect(
          res.lines
              .where((l) => l.kind == OcrLineKind.item && !l.hasPrice)
              .map((l) => l.text),
          isEmpty);
    });

    test('a real Beit Bhamdoun restaurant receipt (ML Kit output, Oct 2026)',
        () {
      // Wines listed by vintage ("1 2014  2700000" — all digits, still an
      // item), two references on one line ("CHECK # 105165 TABLE #1"), a
      // phone number, ungrouped LBP prices and the USD equivalent total.
      // (Phone and waiter's name replaced; layout kept.)
      OcrRawLine l(String text, double left, double top, double right,
              double bottom, double angle, double h) =>
          OcrRawLine(
              text: text,
              rect: ui.Rect.fromLTRB(left, top, right, bottom),
              angle: angle,
              height: h);
      final res = OcrService.parseLines([
        l('Beit Bhamdoun', 211, 88, 507, 127, -0.0270, 31.0),
        l('1 2014', 138, 447, 215, 480, -0.0389, 30.0),
        l('Bhamdoun El Dayaa', 236, 143, 482, 176, -0.0203, 28.0),
        l('1 2016', 143, 494, 219, 525, 0.0000, 31.0),
        l('03000000', 295, 186, 419, 213, -0.0242, 24.0),
        l('25-10-2026 16:13', 243, 274, 472, 305, -0.0218, 26.0),
        l('CHECK # 105165 TABLE #1', 175, 366, 544, 399, 0.0000, 33.0),
        l('TABLE', 315, 232, 399, 257, -0.0119, 24.0),
        l('DUPLICATA #2', 263, 320, 466, 353, 0.0000, 33.0),
        l('1 DUCK MAGRET', 144, 535, 356, 565, -0.0141, 27.0),
        l('1 PASTA RED', 147, 579, 312, 606, 0.0000, 27.0),
        l('3 ARGENTINIAN FILET', 139, 621, 423, 642, 0.0000, 21.0),
        l('1 FRIES', 154, 655, 243, 681, -0.0225, 24.0),
        l('2 PASTA MUSHROOM', 146, 693, 416, 714, 0.0000, 21.0),
        l('1 AUSTRALIAN WAGYU', 158, 731, 435, 756, 0.0000, 25.0),
        l('5 LARGE STILL WATER', 145, 773, 433, 793, 0.0000, 20.0),
        l('4 ESPRESSO COFFEE', 144, 811, 422, 832, 0.0000, 21.0),
        l('6 CREME BRULE', 144, 851, 357, 872, 0.0000, 21.0),
        l('1 ALL GREEN SALAD', 154, 890, 407, 915, 0.0000, 25.0),
        l('1 AUBERGINE KEBBE', 156, 930, 414, 955, 0.0000, 25.0),
        l('2 SAMOSAS', 143, 972, 296, 994, 0.0000, 22.0),
        l('1 DUCK SHAWARMA', 155, 1009, 405, 1038, 0.0120, 26.0),
        l('1 BEETROOT SALAD', 154, 1051, 404, 1077, 0.0000, 26.0),
        l('You Have been served by', 217, 1292, 503, 1316, 0.0000, 24.0),
        l('SAM', 322, 1325, 401, 1348, -0.0506, 19.0),
        l('2700000', 559, 453, 668, 476, 0.0000, 23.0),
        l('Thank you.', 306, 1369, 419, 1395, -0.0535, 20.0),
        l('2250000', 558, 498, 665, 519, 0.0000, 21.0),
        l('2700000', 556, 540, 662, 562, 0.0000, 22.0),
        l('1440000', 556, 579, 657, 603, 0.0200, 22.0),
        l('8100000', 551, 616, 649, 641, -0.0306, 22.0),
        l('540000', 563, 657, 648, 675, 0.0000, 18.0),
        l('3600000', 547, 693, 645, 713, 0.0000, 20.0),
        l('7020000', 547, 733, 645, 753, 0.0000, 20.0),
        l('1800000', 550, 773, 645, 792, 0.0000, 19.0),
        l('1080000', 550, 809, 644, 832, -0.0213, 21.0),
        l('4050000', 549, 852, 646, 872, 0.0000, 20.0),
        l('1080000', 551, 887, 645, 914, -0.0319, 24.0),
        l('1080000', 552, 932, 648, 952, 0.0000, 20.0),
        l('2160000', 550, 969, 647, 992, -0.0206, 21.0),
        l('TOTAL LL: 42660000', 165, 1119, 560, 1150, 0.0000, 31.0),
        l('TOTAL \$: 474.00', 206, 1162, 520, 1197, 0.0000, 35.0),
        l('1980000', 553, 1012, 650, 1033, 0.0000, 21.0),
        l('1080000', 554, 1050, 649, 1074, -0.0210, 22.0),
      ], imageWidth: 798, imageHeight: 1446, currency: 'LBP');
      expect(_items(res), [
        ('2014', 2700000.0, 1),
        ('2016', 2250000.0, 1),
        ('DUCK MAGRET', 2700000.0, 1),
        ('PASTA RED', 1440000.0, 1),
        ('ARGENTINIAN FILET', 8100000.0, 3),
        ('FRIES', 540000.0, 1),
        ('PASTA MUSHROOM', 3600000.0, 2),
        ('AUSTRALIAN WAGYU', 7020000.0, 1),
        ('LARGE STILL WATER', 1800000.0, 5),
        ('ESPRESSO COFFEE', 1080000.0, 4),
        ('CREME BRULE', 4050000.0, 6),
        ('ALL GREEN SALAD', 1080000.0, 1),
        ('AUBERGINE KEBBE', 1080000.0, 1),
        ('SAMOSAS', 2160000.0, 2),
        ('DUCK SHAWARMA', 1980000.0, 1),
        ('BEETROOT SALAD', 1080000.0, 1),
      ]);
      expect(res.receiptTotal, 42660000);
      // The items add up to the receipt.
      expect(_items(res).fold<double>(0, (s, i) => s + i.$2), 42660000);
      expect(
          OcrService.receiptCurrency(res,
              billCurrency: 'USD', userCurrencies: {'USD', 'LBP'}),
          (code: 'LBP', printed: true));
    });

    test('a real Roadster Diner receipt (ML Kit output, Oct 2026)', () {
      // Ungrouped LBP prices with ".00", the total on the row under
      // "TOTAL DUE" (read "6300O00.0O0"), a free "W/Regular 0.00", the USD
      // equivalent and a VAT table after the total, a keyboard in the photo.
      OcrRawLine l(String text, double left, double top, double right,
              double bottom, double angle, double h) =>
          OcrRawLine(
              text: text,
              rect: ui.Rect.fromLTRB(left, top, right, bottom),
              angle: angle,
              height: h);
      final res = OcrService.parseLines([
        l("Caps A", 3, 19, 66, 41, 0.0818, 17.1),
        l("LOck", 4, 31, 44, 48, 0.0000, 17.0),
        l("Shift", 5, 117, 31, 130, 0.0000, 13.0),
        l("trl", 1, 204, 18, 218, 0.0000, 14.0),
        l("A", 136, 9, 153, 27, 0.0000, 18.0),
        l("S#", 230, 6, 268, 24, 0.0000, 18.0),
        l("Alt", 275, 197, 299, 212, 0.0000, 15.0),
        l("D]", 323, 4, 364, 22, 0.0000, 18.0),
        l("CHECK # 1143185", 368, 529, 501, 546, -0.0301, 13.0),
        l("TABLE1", 369, 545, 444, 561, -0.0400, 13.0),
        l("GY", 510, 1, 556, 19, 0.0000, 18.0),
        l("ROADSTER", 459, 417, 652, 462, 0.0000, 45.0),
        l("PRESH CARUAL vOus", 473, 486, 620, 496, 0.0000, 10.0),
        l("DlNEIR", 504, 461, 585, 480, -0.0247, 17.0),
        l("ITEMS ORDERED", 404, 635, 520, 658, -0.0345, 19.0),
        l("2 MIGHTY GARL", 404, 681, 521, 703, -0.0342, 18.0),
        l("RATE", 350, 1295, 389, 1314, 0.0000, 19.0),
        l("11.00%", 352, 1318, 407, 1342, -0.0363, 22.0),
        l("Rd DINING : MOHAMMAD T", 438, 586, 639, 612, -0.0398, 18.0),
        l("1 CHZ AT HEART", 414, 702, 530, 727, -0.0345, 21.0),
        l("1 W/Skin On Fries", 416, 724, 560, 749, -0.0347, 20.0),
        l("1 SKIN ON FRIES", 416, 747, 541, 772, -0.0400, 20.0),
        l("BY", 556, 85, 601, 106, 0.0000, 21.0),
        l("1 SMALL BUF WINGS", 414, 770, 560, 794, -0.0342, 19.0),
        l("1 REF DIET PEPSI", 416, 814, 551, 840, -0.0444, 20.0),
        l("2 REFILL MIRINDA", 408, 840, 552, 861, -0.0278, 17.0),
        l("*************", 365, 934, 487, 952, -0.0328, 14.0),
        l("1 ICED TEA PEACH LIPTON", 416, 791, 617, 818, -0.0298, 21.0),
        l("1 **W/Th isld 45", 418, 861, 553, 886, -0.0370, 20.0),
        l("1 W/Regular", 411, 889, 508, 909, 0.0000, 20.0),
        l("SUBTOTAL", 402, 978, 540, 998, -0.0145, 18.0),
        l("TOTAL DUE", 383, 1067, 546, 1088, -0.0184, 18.0),
        l("DATE 10/05/26", 593, 522, 707, 540, -0.0351, 14.0),
        l("100BPM", 651, 541, 712, 551, 0.0000, 10.0),
        l("TIME", 595, 543, 628, 552, 0.0000, 9.0),
        l("N1 M", 652, 83, 764, 104, 0.0000, 21.0),
        l("USD", 512, 1139, 568, 1158, 0.0000, 19.0),
        l("2250000.00", 636, 675, 727, 695, -0.0220, 18.0),
        l("1260000.00", 638, 696, 726, 719, -0.0568, 18.0),
        l("AMOUNT", 672, 629, 725, 648, -0.0377, 17.0),
        l("# OF GUESTS", 532, 1236, 638, 1258, -0.0189, 20.0),
        l("360000.00", 646, 720, 726, 741, -0.0500, 17.0),
        l("585000.00", 647, 742, 729, 764, -0.0487, 18.0),
        l("Roadster Diner SAL", 462, 1536, 642, 1561, 0.0112, 23.0),
        l("ABC Ashrafieh", 470, 1563, 622, 1589, 0.0199, 23.0),
        l("495000.00", 648, 767, 729, 786, -0.0247, 17.0),
        l("***********************", 521, 930, 734, 948, -0.0141, 15.0),
        l("270000.00", 648, 790, 730, 809, -0.0244, 17.0),
        l("315000.00", 649, 815, 733, 833, 0.0000, 18.0),
        l("630000.00", 649, 836, 731, 855, -0.0122, 18.0),
        l("6300O00. 00", 560, 995, 739, 1017, -0.0168, 19.0),
        l("135000.00", 651, 856, 732, 881, -0.0624, 20.0),
        l("0.00", 698, 884, 735, 901, 0.0000, 17.0),
        l("6300O00.0O0", 551, 1085, 738, 1107, -0.0267, 17.0),
        l("70.00", 649, 1133, 741, 1155, -0.0435, 18.0),
        l("4", 740, 1236, 749, 1253, 0.0000, 17.0),
        l("NET", 503, 1292, 530, 1311, 0.0000, 19.0),
        l("VAT", 612, 1289, 640, 1309, 0.0000, 20.0),
        l("5675675.6 624324.32 6300000,00", 440, 1307, 748, 1339, -0.0325, 22.0),
        l("GROSS", 702, 1286, 750, 1306, 0.0000, 20.0),
        l("At", 859, 188, 884, 207, 0.0000, 19.0),
        l("Ctrl", 957, 193, 991, 208, 0.0000, 15.0),
        l("?S", 1042, 85, 1086, 103, 0.0000, 18.0),
        l("Shift", 1144, 104, 1184, 118, 0.0000, 14.0),
      ], imageWidth: 1203, imageHeight: 1600, currency: 'LBP');
      expect(_items(res), [
        ('MIGHTY GARL', 2250000.0, 2),
        ('CHZ AT HEART', 1260000.0, 1),
        ('W/Skin On Fries', 360000.0, 1),
        ('SKIN ON FRIES', 585000.0, 1),
        ('SMALL BUF WINGS', 495000.0, 1),
        ('ICED TEA PEACH LIPTON', 270000.0, 1),
        ('REF DIET PEPSI', 315000.0, 1),
        ('REFILL MIRINDA', 630000.0, 2),
        ('W/Th isld 45', 135000.0, 1),
      ]);
      expect(res.receiptTotal, 6300000);
      expect(res.taxTotal, isNull);
      expect(
          res.lines
              .where((l) => l.kind == OcrLineKind.item && !l.hasPrice)
              .map((l) => l.text),
          isEmpty);
      // "USD 70.00" is the equivalent; the prices say LBP.
      expect(
          OcrService.receiptCurrency(res,
              billCurrency: 'USD', userCurrencies: {'USD', 'LBP'}),
          (code: 'LBP', printed: false));
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

    test('a real delivery slip: address header, bare prices, two totals '
        '(ML Kit output, Oct 30 2026)', () {
      // Above the "Qty Description Total" row: the customer's name, company,
      // phones, street, floor ("Flr: 4") and the shop's phone beside the end
      // of its address ("…iye  76696698") — none of it items, and the
      // "Delivery" title isn't a charge. Every price is bare ("150000"), so
      // there's no "real" price to fence the header with. "Combo300g" was
      // read "Comb0300g". (Phones replaced; layout kept.)
      OcrRawLine l(String text, double left, double top, double right,
              double bottom, double angle, double h) =>
          OcrRawLine(
              text: text,
              rect: ui.Rect.fromLTRB(left, top, right, bottom),
              angle: angle,
              height: h);
      final res = OcrService.parseLines([
        l('Name: l', 29, 212, 285, 314, 0.1935, 55.1),
        l('Fam.:0', 29, 315, 255, 400, 0.1368, 55.6),
        l('Comp: uil gal4', 23, 414, 531, 558, 0.1616, 64.0),
        l('Tel:01000001-01000002', 17, 512, 804, 705, 0.1735, 58.1),
        l('Str: il', 24, 722, 394, 837, 0.1489, 61.8),
        l('Delivery', 590, 198, 970, 353, 0.1985, 83.7),
        l('Tel:01000003-70000004', 19, 613, 802, 804, 0.1716, 57.9),
        l('Flr: 4', 50, 824, 201, 908, 0.1409, 64.8),
        l('Apt: lA', 24, 920, 579, 1071, 0.1550, 66.9),
        l('ye', 838, -1, 914, 48, 0.1889, 36.9),
        l('76000000', 634, 27, 931, 133, 0.2061, 47.1),
        l('30-10-2026 12:39', 516, 1416, 1038, 1533, 0.1275, 51.5),
        l('CHECK# 106647', 527, 1514, 1027, 1629, 0.1271, 52.5),
        l('Order Nb. 20008', 435, 1583, 1120, 1736, 0.1120, 77.5),
        l('Qty Description', 162, 1863, 635, 1973, 0.0963, 65.4),
        l('1 Delivery Charge 1', 257, 2067, 809, 2184, 0.0897, 68.4),
        l('2 HALF&HALF', 230, 2170, 678, 2257, 0.0811, 51.2),
        l('2 half hotdog', 227, 2264, 618, 2359, 0.0932, 59.3),
        l('2 Half escalope', 224, 2362, 697, 2466, 0.0897, 62.3),
        l('1 Comb0300g fries', 255, 2467, 793, 2568, 0.0674, 65.2),
        l('TOTAL LL: 2,265,000', 273, 2665, 1251, 2825, 0.0689, 93.3),
        l('TOTAL \$: 25.17', 406, 2793, 1130, 2920, 0.0612, 83.2),
        l('Cash LL:2265000', 474, 3014, 1117, 3108, 0.0390, 69.1),
        l('We appreciate your visit!', 420, 3232, 1111, 3313, 0.0305, 60.0),
        l('Thank yQu', 632, 3325, 920, 3404, 0.0706, 59.2),
        l('Powered by OmegaPOs com', 364, 3525, 1175, 3595, 0.0111, 61.0),
        l('Total', 1330, 1988, 1461, 2049, 0.0713, 52.2),
        l('150000', 1264, 2169, 1460, 2234, 0.0836, 49.3),
        l('180000', 1265, 2264, 1462, 2329, 0.0780, 50.2),
        l('810000', 1261, 2358, 1463, 2423, 0.0810, 49.3),
        l('720000', 1259, 2452, 1464, 2518, 0.0848, 49.3),
        l('405000', 1263, 2550, 1462, 2612, 0.0459, 53.1),
      ], imageWidth: 1703, imageHeight: 3748, currency: 'LBP');
      expect(_items(res), [
        ('HALF&HALF', 180000.0, 2),
        ('half hotdog', 810000.0, 2),
        ('Half escalope', 720000.0, 2),
        ('Comb0300g fries', 405000.0, 1),
      ]);
      // The delivery charge is shared like a service charge; with it the
      // items match the receipt.
      expect(res.taxTotal, 150000);
      expect(res.receiptTotal, 2265000);
      expect(
          _items(res).fold<double>(0, (s, i) => s + i.$2) + res.taxTotal!,
          2265000);
      // No header line waits for a price.
      expect(
          res.lines.where((x) => x.kind == OcrLineKind.item && !x.hasPrice),
          isEmpty);
      // The rate the shop used: 25.17 / 2,265,000.
      expect(OcrService.printedRate(res, bill: 'LBP', other: 'USD'),
          closeTo(25.17 / 2265000, 1e-12));
      expect(OcrService.printedRate(res, bill: 'LBP', other: 'EUR'), isNull);
    });
  });

  group('OcrService receipt currency', () {
    OcrResult receipt(List<(String, double)> items,
        {double? total, String header = ''}) {
      var y = 100.0;
      OcrLine line(String text, [double? amount]) => OcrLine(
          text: text,
          boundingBox: ui.Rect.fromLTWH(40, y += 40, 700, 28),
          parsedAmount: amount,
          parsedName: text,
          kind: amount == null ? OcrLineKind.other : OcrLineKind.item);
      return OcrResult(
        lines: [
          if (header.isNotEmpty) line(header),
          for (final (name, a) in items) line(name, a),
        ],
        imageWidth: 800,
        imageHeight: 1400,
        rawText: header,
        receiptTotal: total,
      );
    }

    final lbpMeal = [('ChickenMac Meal', 700000.0), ('Hamburger', 450000.0)];

    test('whole thousands → the large-unit currency the user has', () {
      expect(
          OcrService.receiptCurrency(receipt(lbpMeal, total: 1150000),
              billCurrency: 'USD', userCurrencies: {'USD', 'LBP'}),
          (code: 'LBP', printed: false));
      // Nothing to suggest without such a currency, or when it's already set.
      expect(
          OcrService.receiptCurrency(receipt(lbpMeal),
              billCurrency: 'USD', userCurrencies: {'USD', 'EUR'}),
          isNull);
      expect(
          OcrService.receiptCurrency(receipt(lbpMeal),
              billCurrency: 'LBP', userCurrencies: {'USD', 'LBP'}),
          isNull);
    });

    test('several large-unit currencies: the shop\'s country decides', () {
      final mine = {'USD', 'LBP', 'SYP'};
      expect(
          OcrService.receiptCurrency(receipt(lbpMeal),
              billCurrency: 'USD', userCurrencies: mine),
          isNull);
      expect(
          OcrService.receiptCurrency(
              receipt(lbpMeal, header: "McDonald's Lebanon"),
              billCurrency: 'USD',
              userCurrencies: mine),
          (code: 'LBP', printed: false));
    });

    test('a currency printed on the receipt wins', () {
      expect(
          OcrService.receiptCurrency(
              receipt([('Pizza', 24.5), ('Salad', 12.0)],
                  header: 'Total EUR 36.50'),
              billCurrency: 'USD',
              userCurrencies: {'USD', 'EUR'}),
          (code: 'EUR', printed: true));
      expect(
          OcrService.receiptCurrency(receipt(lbpMeal, header: 'المجموع ل.ل'),
              billCurrency: 'USD', userCurrencies: {'USD', 'LBP'}),
          (code: 'LBP', printed: true));
    });

    test('cents on a bill set in a large-unit currency', () {
      expect(
          OcrService.receiptCurrency(receipt([('Latte', 4.5), ('Bagel', 3.25)]),
              billCurrency: 'LBP', userCurrencies: {'USD', 'LBP'}),
          (code: 'USD', printed: false));
      // Ordinary prices in the bill's own currency: nothing to say.
      expect(
          OcrService.receiptCurrency(receipt([('Latte', 4.5), ('Bagel', 3.25)]),
              billCurrency: 'USD', userCurrencies: {'USD', 'LBP'}),
          isNull);
    });
  });
}
