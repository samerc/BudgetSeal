import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'format_number.dart';

/// A line item extracted from a receipt via OCR.
class ExtractedItem {
  String name;
  double amount;
  int quantity;

  /// The price was a bare whole number ("Water 3"), not one with a
  /// separator or 4+ digits — it may as well be a street number or a code.
  final bool weakPrice;

  ExtractedItem({
    required this.name,
    required this.amount,
    this.quantity = 1,
    this.weakPrice = false,
  });

  /// Per-unit price when quantity > 1.
  double get unitPrice => quantity > 1 ? amount / quantity : amount;
}

/// What a receipt line is. Only [item] and [discount] lines can be added to
/// the bill; [tax] and [total] feed the tax field and the total check.
enum OcrLineKind { item, discount, tax, total, other }

/// A recognized receipt row (one or more OCR lines at the same height) with
/// its bounding box on the image.
class OcrLine {
  final String text;
  final ui.Rect boundingBox;
  final double? parsedAmount;
  final String? parsedName;
  final int parsedQuantity;
  final OcrLineKind kind;

  OcrLine({
    required this.text,
    required this.boundingBox,
    this.parsedAmount,
    this.parsedName,
    this.parsedQuantity = 1,
    this.kind = OcrLineKind.item,
  });

  /// Whether this line can be added as a bill item (a discount is negative).
  bool get hasPrice =>
      (kind == OcrLineKind.item || kind == OcrLineKind.discount) &&
      parsedAmount != null &&
      parsedAmount != 0;
}

/// Result of scanning a receipt.
class OcrResult {
  final List<OcrLine> lines;
  final int imageWidth;
  final int imageHeight;
  final String rawText;

  /// Largest "Total" line on the receipt (the grand total), if any.
  final double? receiptTotal;

  /// Sum of tax / VAT / service lines, if any.
  final double? taxTotal;

  const OcrResult({
    required this.lines,
    required this.imageWidth,
    required this.imageHeight,
    required this.rawText,
    this.receiptTotal,
    this.taxTotal,
  });
}

/// One line as the text recognizer returned it: its text, its axis-aligned
/// box, the slope of its baseline (radians, + = falling to the right) and its
/// real height (the box of a tilted line is taller than the text).
class OcrRawLine {
  final String text;
  final ui.Rect rect;
  final double angle;
  final double height;

  OcrRawLine({
    required this.text,
    required this.rect,
    this.angle = 0,
    double? height,
  }) : height = height ?? rect.height;
}

/// Offline receipt OCR using Google ML Kit (Latin script).
class OcrService {
  /// Scan a receipt and return its rows, classified and parsed. [currency]
  /// (the bill's) settles "12.500": 12.5 in a 3-decimal currency, else 12,500.
  static Future<OcrResult> scanReceipt(String imagePath,
      {String? currency}) async {
    final textRecognizer = TextRecognizer();
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognized = await textRecognizer.processImage(inputImage);

      // Actual image dimensions (for the column checks).
      int imgW = 1000, imgH = 1400; // fallback
      try {
        final bytes = await File(imagePath).readAsBytes();
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        imgW = frame.image.width;
        imgH = frame.image.height;
        frame.image.dispose();
      } catch (_) {
        // Keep fallback dimensions
      }

      final raw = <OcrRawLine>[];
      for (final block in recognized.blocks) {
        for (final line in block.lines) {
          final b = line.boundingBox;
          var angle = 0.0;
          double? height;
          // Corner points run clockwise from the top-left.
          final cp = line.cornerPoints;
          if (cp.length == 4) {
            angle = math.atan2((cp[1].y - cp[0].y).toDouble(),
                (cp[1].x - cp[0].x).toDouble());
            height = math.sqrt(math.pow(cp[3].x - cp[0].x, 2) +
                math.pow(cp[3].y - cp[0].y, 2));
          }
          raw.add(OcrRawLine(
            text: line.text,
            rect: ui.Rect.fromLTRB(b.left.toDouble(), b.top.toDouble(),
                b.right.toDouble(), b.bottom.toDouble()),
            angle: angle,
            height: height,
          ));
        }
      }

      final result = parseLines(raw,
          imageWidth: imgW,
          imageHeight: imgH,
          rawText: recognized.text,
          currency: currency);
      debugPrint('[OcrService] ${raw.length} lines → ${result.lines.length} '
          'rows, ${result.lines.where((l) => l.hasPrice).length} with prices, '
          'total ${result.receiptTotal}, tax ${result.taxTotal}');
      for (final l in result.lines) {
        debugPrint('  ${l.kind.name.padRight(8)} "${l.text}"');
      }
      return result;
    } catch (e) {
      debugPrint('[OcrService] Error: $e');
      return const OcrResult(
          lines: [], imageWidth: 1000, imageHeight: 1400, rawText: '');
    } finally {
      textRecognizer.close();
    }
  }

  /// Turns recognized lines into receipt rows: straightens a tilted photo,
  /// joins lines at the same height into one row (name … price), parses
  /// each row, then cleans up with the receipt's layout — quantity lines
  /// ("2 x 4.50") go to the item above, wrapped names join their item,
  /// nothing after the grand total is an item, and bare whole numbers off
  /// the price column (addresses, table numbers) aren't prices.
  static OcrResult parseLines(
    List<OcrRawLine> raw, {
    required int imageWidth,
    required int imageHeight,
    String rawText = '',
    String? currency,
  }) {
    if (raw.isEmpty) {
      return OcrResult(
          lines: const [],
          imageWidth: imageWidth,
          imageHeight: imageHeight,
          rawText: rawText);
    }
    final decimals = currency == null ? null : currencyDecimals(currency);

    // 1. Skew: the median slope of the longer lines (short ones are noisy).
    final slopes = [
      for (final l in raw)
        if (l.rect.width > 3 * l.height) l.angle,
    ]..sort();
    final skew = slopes.isEmpty ? 0.0 : slopes[slopes.length ~/ 2];
    final cosA = math.cos(skew), sinA = math.sin(skew);

    // 2. Each line's centre in the straightened frame.
    final placed = [
      for (final l in raw)
        _Placed(
          l,
          x: l.rect.center.dx * cosA + l.rect.center.dy * sinA,
          y: -l.rect.center.dx * sinA + l.rect.center.dy * cosA,
          // The box of a tilted line is W·cos + H·sin wide.
          w: math.max(
              (l.rect.width - l.height * sinA.abs()) /
                  math.max(cosA.abs(), 0.5),
              1),
        ),
    ]..sort((a, b) => a.y.compareTo(b.y));
    final heights = [for (final p in placed) p.line.height]..sort();
    final lineH = math.max(heights[heights.length ~/ 2], 1.0);

    // 3. Rows: lines whose centres sit within half a line height of the
    // row's centre and that don't overlap side by side.
    final rows = <_Row>[];
    for (final p in placed) {
      _Row? home;
      for (var i = rows.length - 1; i >= 0 && i >= rows.length - 3; i--) {
        final r = rows[i];
        if ((p.y - r.y).abs() < lineH * 0.55 && !r.overlaps(p)) {
          home = r;
          break;
        }
      }
      if (home != null) {
        home.add(p);
      } else {
        rows.add(_Row(p));
      }
    }
    rows.sort((a, b) => a.y.compareTo(b.y));

    // 4. Parse each row.
    final parsed = <_Parsed>[];
    for (final r in rows) {
      final text = _tidyNumbers(_fixDigits(r.text));
      final kind = _classify(text.toLowerCase());
      switch (kind) {
        case OcrLineKind.total:
        case OcrLineKind.tax:
          parsed.add(_Parsed(r, text, kind,
              amount: _lastPrice(text, decimals)));
        case OcrLineKind.other:
          parsed.add(_Parsed(r, text, kind));
        case OcrLineKind.item:
        case OcrLineKind.discount:
          final item = _parseLine(text, decimals);
          // "-2.00" anywhere on the line also marks a discount.
          final isDiscount = kind == OcrLineKind.discount ||
              RegExp(r'(^|\s)-\s*[$€£¥]?\s*\d').hasMatch(text);
          parsed.add(_Parsed(
            r,
            text,
            isDiscount ? OcrLineKind.discount : OcrLineKind.item,
            amount: item?.amount,
            name: item?.name,
            quantity: isDiscount ? 1 : (item?.quantity ?? 1),
            weak: item?.weakPrice ?? false,
          ));
      }
    }

    // 4b. "TOTAL DUE" with its amount on the row below.
    for (var i = 0; i + 1 < parsed.length; i++) {
      final p = parsed[i], next = parsed[i + 1];
      if ((p.kind != OcrLineKind.total && p.kind != OcrLineKind.tax) ||
          p.amount != null ||
          next.row.y - p.row.y > lineH * 2.2) {
        continue;
      }
      final lone = _lonePrice.firstMatch(next.text.trim());
      if (lone == null) continue;
      p.amount = _parsePrice(lone.group(1)!, decimals);
      p.row.absorb(next.row);
      parsed.removeAt(i + 1);
    }

    // 5. Nothing after the grand total is an item (payment, change, thanks).
    var grandIdx = -1;
    for (var i = 0; i < parsed.length; i++) {
      final p = parsed[i];
      if (p.kind != OcrLineKind.total || p.amount == null) continue;
      if (grandIdx < 0 || p.amount! >= parsed[grandIdx].amount!) grandIdx = i;
    }
    if (grandIdx >= 0) {
      for (var i = grandIdx + 1; i < parsed.length; i++) {
        if (parsed[i].kind == OcrLineKind.item) parsed[i].toOther();
      }
    }

    // 6. Bare whole numbers are prices only in the price column, and not in
    // the header above the first real price.
    final strong = [
      for (final p in parsed)
        if (p.kind == OcrLineKind.item && p.amount != null && !p.weak) p,
    ];
    final firstStrong = strong.isEmpty ? -1 : parsed.indexOf(strong.first);
    final rights = [for (final p in strong) p.row.right]..sort();
    final column = rights.length >= 3 ? rights[rights.length ~/ 2] : null;
    for (var i = 0; i < parsed.length; i++) {
      final p = parsed[i];
      if (p.kind != OcrLineKind.item || p.amount == null || !p.weak) continue;
      final offColumn =
          column != null && (p.row.right - column).abs() > imageWidth * 0.06;
      if (i < firstStrong || offColumn) p.toOther();
    }

    // 7. Quantity lines ("2 x 4.50", "2 @ 4,500  9,000") belong to the
    // item above; a priceless text line right under an item is the rest of
    // its name; priceless lines indented under an item are its parts (a
    // meal's "1 Regular Fries", "NO Ice") — not items of their own.
    final out = <_Parsed>[];
    _Parsed? priced; // the last item with a price
    for (final p in parsed) {
      final prev = out.isEmpty ? null : out.last;
      if (p.amount == null &&
          (p.kind == OcrLineKind.item || p.kind == OcrLineKind.discount) &&
          priced != null &&
          p.row.left > priced.row.left + lineH * 0.6 &&
          (prev != priced || _leadingQty.hasMatch(p.text.trim()))) {
        p.toOther();
        out.add(p);
        continue;
      }
      final nearPrev =
          prev != null && (p.row.y - prev.row.y) < lineH * 2.5;
      final namedPrev = nearPrev &&
          prev.kind == OcrLineKind.item &&
          prev.text.replaceAll(_nonLetter, '').length >= 2;
      final qty = _qtyLine.firstMatch(p.text.trim());
      if (qty != null && namedPrev) {
        prev.name ??= _cleanName(prev.text);
        final q = int.parse(qty.group(1)!);
        final unit = _parsePrice(qty.group(2)!, decimals);
        final lineTotal =
            qty.group(3) == null ? null : _parsePrice(qty.group(3)!, decimals);
        if (q >= 1 && q <= 99) prev.quantity = q;
        if (prev.amount == null || prev.weak) {
          prev.amount = lineTotal ?? (unit == null ? null : unit * q);
          prev.weak = false;
        }
        continue;
      }
      // A price alone on the row under a priceless name (the price column
      // printed a little lower).
      final lone = _lonePrice.firstMatch(p.text.trim());
      if (lone != null && namedPrev && prev.amount == null) {
        prev.amount = _parsePrice(lone.group(1)!, decimals);
        prev.name ??= _cleanName(prev.text);
        prev.row.absorb(p.row);
        continue;
      }
      // "1 W/Regular  0.00": a free extra, nothing to split.
      if (p.kind == OcrLineKind.item &&
          p.amount == null &&
          _zeroPrice.hasMatch(p.text.trim())) {
        p.toOther();
        out.add(p);
        continue;
      }
      // A row that starts with a count is an item of its own.
      final isText = p.kind == OcrLineKind.item &&
          p.amount == null &&
          !_leadingQty.hasMatch(p.text.trim()) &&
          p.text.replaceAll(_nonLetter, '').length >= 2;
      if (isText &&
          nearPrev &&
          prev.kind == OcrLineKind.item &&
          prev.amount != null &&
          prev.name != null &&
          p.row.left >= prev.row.left - imageWidth * 0.04) {
        prev.name = '${prev.name} ${p.text.trim()}';
        if (prev.name!.length > 80) prev.name = prev.name!.substring(0, 80);
        prev.row.absorb(p.row);
        continue;
      }
      out.add(p);
      if (p.kind == OcrLineKind.item && p.amount != null) priced = p;
    }

    // Above the first priced item is the header (shop name, address, VAT
    // number): no items waiting for a price, no tax.
    final firstPriced = out.indexWhere(
        (p) => p.kind == OcrLineKind.item && p.amount != null);
    for (var i = 0; i < (firstPriced < 0 ? 0 : firstPriced); i++) {
      final k = out[i].kind;
      if (k == OcrLineKind.item || k == OcrLineKind.tax) out[i].toOther();
    }

    _matchTotal(out);

    double? receiptTotal;
    double taxTotal = 0;
    final lines = <OcrLine>[];
    for (final p in out) {
      if (p.kind == OcrLineKind.total &&
          p.amount != null &&
          p.amount! > 0 &&
          (receiptTotal == null || p.amount! > receiptTotal)) {
        receiptTotal = p.amount;
      }
      if (p.kind == OcrLineKind.tax && p.amount != null && p.amount! > 0) {
        taxTotal += p.amount!;
      }
      final isDiscount = p.kind == OcrLineKind.discount;
      lines.add(OcrLine(
        text: p.text,
        boundingBox: p.row.box,
        parsedAmount: p.amount == null
            ? null
            : (isDiscount ? -p.amount!.abs() : p.amount),
        parsedName: p.name,
        parsedQuantity: p.quantity,
        kind: p.kind,
      ));
    }
    return OcrResult(
      lines: lines,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      rawText: rawText,
      receiptTotal: receiptTotal,
      taxTotal: taxTotal > 0 ? taxTotal : null,
    );
  }

  /// The recognizer sometimes drops a digit of a thousands group: "650,000"
  /// reads "650,00" (= 650). When the items don't add up to the printed
  /// total and multiplying exactly one suspicious price by 10, 100 or 1000
  /// makes them match, that is the fix. Suspicious = a 2-decimal price on a
  /// receipt whose other prices are whole thousands. Only an exact match
  /// changes anything, so a good scan is never touched.
  static void _matchTotal(List<_Parsed> rows) {
    _Parsed? grand;
    double tax = 0;
    for (final p in rows) {
      if (p.kind == OcrLineKind.total &&
          p.amount != null &&
          (grand == null || p.amount! > grand.amount!)) {
        grand = p;
      }
      if (p.kind == OcrLineKind.tax && p.amount != null) tax += p.amount!;
    }
    if (grand == null) return;
    final priced = [
      for (final p in rows)
        if ((p.kind == OcrLineKind.item || p.kind == OcrLineKind.discount) &&
            p.amount != null)
          p,
    ];
    double signed(_Parsed p) =>
        p.kind == OcrLineKind.discount ? -p.amount!.abs() : p.amount!;
    final sum = priced.fold(0.0, (t, p) => t + signed(p));
    final target = grand.amount! - tax;
    final tolerance = math.max(target.abs() * 1e-6, 0.005);
    if ((sum - target).abs() <= tolerance) return;
    bool whole(double v) => v >= 1000 && v == v.roundToDouble();
    final wholeCount = priced.where((p) => whole(p.amount!)).length;
    if (wholeCount < 2) return;
    final fixes = <(_Parsed, double)>[];
    for (final p in priced) {
      if (p.kind != OcrLineKind.item || whole(p.amount!)) continue;
      for (final m in const [10.0, 100.0, 1000.0]) {
        final fixed = p.amount! * m;
        if ((sum - p.amount! + fixed - target).abs() <= tolerance) {
          fixes.add((p, fixed));
        }
      }
    }
    if (fixes.length == 1) fixes.first.$1.amount = fixes.first.$2;
  }

  /// "2 x 4.50", "2 @ 4,500  9,000", "3X 1.20 3.60" — a row with no words.
  static final _qtyLine = RegExp(
    r'^(\d{1,2})\s*[xX×@*]\s*[$€£¥]?\s*(\d[\d,. ]*?\d|\d)(?:\s+[$€£¥]?\s*(\d[\d,. ]*\d))?\s*[A-Za-z]{0,3}$',
  );

  static final _nonLetter = RegExp(r'[^\p{L}]', unicode: true);

  /// A row that ends in a zero price ("0.00", "0", "0T").
  static final _zeroPrice =
      RegExp(r'(^|\s)[$€£¥]?0+(?:[.,]0+)?[A-Za-z]{0,3}$');

  /// "1 Regular Fries": a row that starts with a count and a word.
  static final _leadingQty = RegExp(r'^\d{1,2}\s+\p{L}', unicode: true);

  /// A row that is only a price: "4.50", "$12.00", "450,000 LBP".
  static final _lonePrice = RegExp(
      r'^(?!0\d)[$€£¥]?\s*(\d{1,3}(?:[,. ]\d{3})*(?:[.,]\d{1,3})?|\d{4,}(?:[.,]\d{1,3})?)\s*[A-Za-z]{0,3}$');

  /// A priceless row's text as an item name.
  static String? _cleanName(String text) =>
      _finishItem(text, 1)?.name ?? text.trim();

  /// Letters the recognizer mistakes for digits, fixed only inside numbers:
  /// "1,5OO" → "1,500", "l2.50" → "12.50". A token qualifies when it has a
  /// digit and nothing but digits, separators and O/o/I/l/| (so "Oil", "0.5L"
  /// and "COOL" stay as they are).
  static String _fixDigits(String text) => text.replaceAllMapped(
        RegExp(r'(?<=^|\s|[$€£¥])[0-9OoIl|][0-9OoIl|,.]*(?=$|\s)'),
        (m) {
          final t = m.group(0)!;
          if (!t.contains(RegExp(r'\d'))) return t;
          // A lone letter next to one digit ("I2" could be a code) needs a
          // separator or 3+ characters to count.
          if (t.length < 3 && !t.contains(RegExp(r'[,.]'))) return t;
          // I/l only before a digit or separator: "1.5l" is litres.
          return t
              .replaceAll(RegExp('[Oo]'), '0')
              .replaceAll(RegExp(r'[Il|](?=[\d,.])'), '1');
        },
      );

  /// "1,250, 000" → "1,250,000": the recognizer puts a space after a
  /// thousands separator now and then.
  static String _tidyNumbers(String text) =>
      text.replaceAllMapped(RegExp(r'(\d[,.]) +(?=\d{2,3}(?!\d))'),
          (m) => m.group(1)!);

  /// A date or a time on the line: a header or footer, never an item.
  static final _dateOrTime = RegExp(
      r'\b\d{1,2}[/.\-]\d{1,2}[/.\-] ?\d{2,4}\b|\b\d{1,2}:\d{2}\b');

  /// Strip trailing tax/note suffixes from a price string.
  /// e.g. "450,000T" → "450,000", "12.50TTC" → "12.50", "100*" → "100"
  static String _stripPriceSuffix(String s) {
    return s.replaceAll(RegExp(r'[A-Za-z*+]+$'), '').trim();
  }

  static final _letter = RegExp(r'\p{L}', unicode: true);

  // Optional currency symbol before ($/€/£/¥) or letters after (T, TTC, LBP…).
  // Not glued to a number or a code ("MDS-8865", "122732-601", "#3360009").
  static final _priceRe = RegExp(
    r'(?<![\d#/]|[A-Za-z\d]-)[$€£¥]?\s*([,.]?\d{1,3}(?:[,. ]\d{3})*(?:[.,]\d{1,3})?|\d{4,}(?:[.,]\d{1,3})?)\s*[A-Za-z*+]{0,4}(?=\s|$)',
  );

  /// Try to parse a line into (name, amount) using multiple strategies.
  static ExtractedItem? _parseLine(String line, [int? decimals]) {
    var trimmed = line.trim();
    if (trimmed.length < 2) return null;
    if (_isNoise(trimmed.toLowerCase())) return null;

    // Find ALL price-like numbers in the line.
    // Match both decimal prices (12.50, 4,50), thousands-separated (317,100, 1.234.567),
    // prices starting with a separator (,450,000), and plain large numbers (765000, 90000).
    final priceMatches = _priceRe.allMatches(trimmed).toList();

    // Filter: reject partial matches where a digit follows (e.g., "317,10" from "317,100")
    final validMatches = priceMatches.where((m) {
      // Must contain at least one separator or be 4+ digits to look like a price
      final text = _stripPriceSuffix(m.group(1)!);
      final cleaned = text.replaceAll(RegExp(r'^[,.]'), ''); // strip leading sep
      // "01600000", "03000000": a leading zero is a phone number or a code,
      // never a price ("0.50" has a separator).
      if (RegExp(r'^0\d+$').hasMatch(cleaned)) return false;
      return cleaned.contains(RegExp(r'[.,]')) || cleaned.replaceAll(RegExp(r'[,. ]'), '').length >= 4;
    }).toList();

    if (validMatches.isNotEmpty) {
      // Use the LAST price in the line (rightmost = most likely the item price)
      final lastMatch = validMatches.last;
      final priceStr = lastMatch.group(1)!;
      final namepart = trimmed.substring(0, lastMatch.start).trim();
      // A bare run of digits ("20035", no separator, currency or suffix)
      // may be an order or check number: weak, so it only counts in the
      // price column below the header (step 6).
      final bare = RegExp(r'^\s*\d+\s*$').hasMatch(lastMatch.group(0)!);
      final item = _buildItem(namepart, priceStr, decimals, bare);
      if (item != null) return item;
    }

    // Strategy 2: Whole number price at end (e.g., "Water 3")
    final wholePrice = RegExp(r'(.+?)\s+[$€£¥]?\s*(\d{1,6})\s*$');
    var match = wholePrice.firstMatch(trimmed);
    if (match != null) {
      final name = match.group(1)!;
      if (name.length > 2 && !RegExp(r'^\d+$').hasMatch(name.trim())) {
        return _buildItem(name, match.group(2)!, decimals, true);
      }
    }

    // Strategy 3: Price at start (e.g., "$4.50 Coffee")
    final startPrice = RegExp(r'^[$€£¥]?\s*(\d{1,6}[.,]\d{1,2})\s+(.+)');
    match = startPrice.firstMatch(trimmed);
    if (match != null) {
      return _buildItem(match.group(2)!, match.group(1)!, decimals);
    }

    return null;
  }

  static ExtractedItem? _buildItem(String rawName, String rawPrice,
      [int? decimals, bool weak = false]) {
    final amount = _parsePrice(rawPrice, decimals);
    if (amount == null || amount <= 0) return null;
    return _finishItem(rawName, amount, weak);
  }

  /// The rightmost price on [line] (used for total and tax lines).
  static double? _lastPrice(String line, [int? decimals]) {
    final matches = _priceRe.allMatches(line.trim()).where((m) {
      final cleaned =
          _stripPriceSuffix(m.group(1)!).replaceAll(RegExp(r'^[,.]'), '');
      return cleaned.contains(RegExp(r'[.,]')) ||
          cleaned.replaceAll(RegExp(r'[,. ]'), '').length >= 2;
    }).toList();
    if (matches.isEmpty) return null;
    return _parsePrice(matches.last.group(1)!, decimals);
  }

  /// Normalises "1,234.56" / "1.234,56" / "4,50" / "450,000T" to a number.
  /// [decimals] is the bill currency's: in a 3-decimal currency (KWD, BHD…)
  /// one separator before exactly 3 digits is the decimal point.
  static double? _parsePrice(String rawPrice, [int? decimals]) {
    // Clean price: strip trailing suffixes (T, TTC, HT, VAT, etc.), remove spaces
    var priceStr = _stripPriceSuffix(rawPrice).replaceAll(' ', '');
    // Strip leading separator: ",450,000" → "450,000"
    if (priceStr.startsWith(',') || priceStr.startsWith('.')) {
      priceStr = priceStr.substring(1);
    }
    // "6300000.000": a thousands separator never follows 5+ ungrouped
    // digits, so this one is the decimal point.
    final ungrouped = RegExp(r'^(\d{5,})[.,](\d{1,3})$').firstMatch(priceStr);
    if (ungrouped != null) {
      return double.tryParse('${ungrouped[1]}.${ungrouped[2]}');
    }
    final threeDecimal = RegExp(r'^\d+[.,]\d{3}$');
    if (decimals == 3 && threeDecimal.hasMatch(priceStr)) {
      return double.tryParse(priceStr.replaceAll(',', '.'));
    }
    // Handle various number formats:
    // "1,234.56" (US thousands) → 1234.56
    // "1.234,56" (EU thousands) → 1234.56
    // "4,50" (EU decimal, no thousands) → 4.50
    // "1,500" (US thousands, no decimal) → 1500
    if (priceStr.contains(',') && priceStr.contains('.')) {
      // Both separators present — last one is the decimal
      if (priceStr.lastIndexOf(',') > priceStr.lastIndexOf('.')) {
        // EU: "1.234,56" → dots are thousands, comma is decimal
        priceStr = priceStr.replaceAll('.', '').replaceAll(',', '.');
      } else {
        // US: "1,234.56" → commas are thousands, dot is decimal
        priceStr = priceStr.replaceAll(',', '');
      }
    } else if (priceStr.contains(',')) {
      // Only comma — check if it's a decimal or thousands separator
      final commaPos = priceStr.indexOf(',');
      final afterComma = priceStr.substring(commaPos + 1);
      if (afterComma.length == 3 && RegExp(r'^\d{3}$').hasMatch(afterComma)) {
        // "317,100" or "1,500" → exactly 3 digits = thousands separator
        priceStr = priceStr.replaceAll(',', '');
      } else if (afterComma.length <= 2 && !afterComma.contains(',')) {
        // "4,50" or "4,5" → EU decimal
        priceStr = priceStr.replaceAll(',', '.');
      } else {
        // Multiple commas or other patterns → treat as thousands
        priceStr = priceStr.replaceAll(',', '');
      }
    } else if (priceStr.contains('.')) {
      // Only dot — "145.000" with exactly 3 trailing digits = thousands, not decimal
      final dotPos = priceStr.lastIndexOf('.');
      final afterDot = priceStr.substring(dotPos + 1);
      if (afterDot.length == 3 && RegExp(r'^\d{3}$').hasMatch(afterDot)) {
        if (priceStr.indexOf('.') != priceStr.lastIndexOf('.')) {
          // Multiple dots: "1.234.567"
          priceStr = priceStr.replaceAll('.', '');
        } else if (decimals != null ||
            (double.tryParse(priceStr.replaceAll('.', '')) ?? 0) > 999) {
          // A 0/2-decimal currency never prints 3 decimals: "12.500" is
          // 12,500. Without a currency, only large numbers are read so.
          priceStr = priceStr.replaceAll('.', '');
        }
      }
      // Otherwise it's a normal decimal: "12.50" → keep as-is
    }
    return double.tryParse(priceStr);
  }

  static ExtractedItem? _finishItem(String rawName, double amount,
      [bool weak = false]) {
    var name = rawName.trim();
    int quantity = 1;

    // Inline unit price: "Coffee 2 @ 4.50" (the line's price is the total).
    final inlineQty =
        RegExp(r'^(.+?)\s+(\d{1,2})\s*[xX×@]\s*[$€£¥]?\s*[\d.,]+$')
            .firstMatch(name);
    if (inlineQty != null && inlineQty.group(1)!.contains(_letter)) {
      quantity = int.parse(inlineQty.group(2)!);
      name = inlineQty.group(1)!;
    }

    // Extract leading quantity: "2 x Mango", "3x Coffee", "2  AVOCADO"
    final leadingQty = RegExp(r'^(\d{1,2})\s*[xX×]?\s+(.+)').firstMatch(name);
    if (leadingQty != null && quantity == 1) {
      final q = int.tryParse(leadingQty.group(1)!);
      final rest = leadingQty.group(2)!;
      // Only treat as quantity if the rest looks like a name (has letters)
      if (q != null && q >= 1 && q <= 99 && rest.contains(_letter)) {
        quantity = q;
        name = rest;
      }
    }

    // Strip a leading product/barcode code: "2745P", "37470", "SKU123".
    // Only a token with a digit — "Pizza margherita" keeps its first word.
    name = name.replaceAll(
        RegExp(r'^(?=[A-Z]*\d)[\dA-Z]{3,13}\s+', caseSensitive: false), '');

    // Extract trailing quantity: "AVOCADO EXTRA  2" or "Mango  3"
    // Only treat as quantity if value is 2-20 (1 is noise, >20 is likely a code)
    final trailingQty = RegExp(r'^(.+?)\s{2,}(\d{1,2})$').firstMatch(name);
    if (trailingQty != null && quantity == 1) {
      final q = int.tryParse(trailingQty.group(2)!);
      if (q != null && q >= 2 && q <= 20) {
        quantity = q;
        name = trailingQty.group(1)!;
      }
    }

    // Strip trailing punctuation
    name = name.replaceAll(RegExp(r'[.\-_:;,*#]+$'), '').trim();
    // Strip leading special chars
    name = name.replaceAll(RegExp(r'^[#*\-]+'), '').trim();
    // Collapse whitespace
    name = name.replaceAll(RegExp(r'\s{2,}'), ' ');

    if (name.isEmpty || name.length < 2) return null;
    // Skip if name is all digits (not an item name)
    if (RegExp(r'^\d+$').hasMatch(name)) return null;
    if (name.length > 80) name = name.substring(0, 80);

    return ExtractedItem(
        name: name, amount: amount, quantity: quantity, weakPrice: weak);
  }

  // Receipt keywords: English, French, Arabic, plus common Spanish/German.
  static const _subtotalWords = [
    'subtotal', 'sub total', 'sub-total', 'sous-total', 'sous total',
    'total ht', 'المجموع الفرعي', 'zwischensumme',
  ];
  static const _totalWords = [
    'total', 'grand total', 'amount due', 'balance due', 'net à payer',
    'à payer', 'montant total', 'المجموع', 'الإجمالي', 'المبلغ المستحق',
    'importe', 'summe', 'gesamt',
  ];
  static const _taxWords = [
    'tax', 'vat', 'tva', 'gst', 'hst', 'iva', 'mwst', 'service', 'svc',
    'ضريبة', 'القيمة المضافة', 'خدمة',
    // Charges shared like tax.
    'delivery', 'livraison', 'توصيل',
  ];
  static const _discountWords = [
    'discount', 'remise', 'réduction', 'promo', 'coupon', 'descuento',
    'rabatt', 'خصم', 'تخفيض',
  ];
  static const _otherWords = [
    // Tip is entered separately; payment, change and contact lines aren't items.
    'tip', 'gratuity', 'pourboire', 'cash', 'change', 'rendu', 'monnaie',
    'rounding', 'arrondi', 'tendered',
    'espèces', 'carte', 'card', 'visa', 'mastercard', 'payment', 'paiement',
    'paid', 'thank', 'merci', 'receipt', 'invoice', 'facture', 'reçu',
    'www', 'http', 'tel', 'tél', 'fax', 'نقدا', 'نقداً', 'الباقي', 'الدفع',
    'بطاقة', 'شكرا', 'شكراً', 'فاتورة', 'إيصال',
  ];

  static final _latinWord = RegExp(r'^[a-zà-ÿ .\-]+$');

  /// "Total (incl VAT)", "Total TTC": the tax is inside the amount.
  static final _taxIncluded =
      RegExp(r'(^|[^a-z])(incl|includ\w*|inclus\w*|ttc)([^a-z]|$)');

  /// "VAT no: 1227", "TAX INVOICE", "Tax ID": header lines, not tax.
  static final _taxId = RegExp(
      r'(^|[^a-z])(vat|tax|tva|gst|trn)\s*(no|n°|nr|number|#|id|reg\w*|invoice|facture)([^a-z]|$)');

  /// "Order Nb 20035", "CHECK # 1600000", "Ref: 8000000", "Table 12":
  /// a reference number, not an item with a price.
  static final _reference = RegExp(
      r'^(order|check|chk|cheque|ticket|table|ref|reference|bill|commande|trans\w*|txn|cashier|caissier|server)[\s.:#,n°obr]*\d+$');

  static bool _has(String lower, List<String> words) {
    for (final w in words) {
      if (_latinWord.hasMatch(w)) {
        // Latin keywords must be whole words ("tax" not in "taxi").
        final re = RegExp('(^|[^a-zà-ÿ])${RegExp.escape(w)}(\$|[^a-zà-ÿ])');
        if (re.hasMatch(lower)) return true;
      } else if (lower.contains(w)) {
        return true;
      }
    }
    return false;
  }

  /// Sorts a receipt line into item / discount / tax / total / other.
  static OcrLineKind _classify(String lower) {
    if (_isNoise(lower)) return OcrLineKind.other;
    if (_dateOrTime.hasMatch(lower)) return OcrLineKind.other;
    if (_has(lower, _subtotalWords)) return OcrLineKind.other;
    if (_taxId.hasMatch(lower)) return OcrLineKind.other;
    if (_reference.hasMatch(lower.trim())) return OcrLineKind.other;
    if (_taxIncluded.hasMatch(lower)) {
      return _has(lower, _totalWords) ? OcrLineKind.total : OcrLineKind.other;
    }
    if (_has(lower, _discountWords)) return OcrLineKind.discount;
    if (_has(lower, _taxWords)) return OcrLineKind.tax;
    if (_has(lower, _totalWords)) return OcrLineKind.total;
    if (_has(lower, _otherWords)) return OcrLineKind.other;
    return OcrLineKind.item;
  }

  /// Lines that are only numbers, dates or codes, or have almost no letters
  /// (in any script, so Arabic item names count).
  static bool _isNoise(String lower) {
    if (RegExp(r'^[\d/\-.:, ]+$').hasMatch(lower)) return true;
    if (lower.replaceAll(_nonLetter, '').length < 2) {
      return true;
    }
    return false;
  }

  /// Currencies whose prices are normally whole thousands ("700,000").
  static const largeUnitCurrencies = {
    'LBP', 'SYP', 'IRR', 'IQD', 'IDR', 'VND', 'KRW', 'COP', 'UZS', 'LAK',
    'GNF', 'MGA', 'PYG', 'UGX', 'TZS', 'KHR', 'MMK', 'CLP', 'JPY',
  };

  /// Symbols that name one currency.
  static const _currencySymbols = {
    'ل.ل': 'LBP', 'l.l': 'LBP', 'l.l.': 'LBP', '€': 'EUR', '£': 'GBP',
    'د.إ': 'AED', 'us\$': 'USD',
  };

  /// Words on a receipt that place it in a country.
  static const _countryHints = {
    'LBP': ['lebanon', 'liban', 'لبنان', 'beirut', 'beyrouth', 'بيروت',
      '.lb', '+961'],
  };

  /// The receipt's currency when it isn't [billCurrency]. [printed] = the
  /// receipt names it ("LBP", "ل.ل", "€"); otherwise it is a guess from
  /// the amounts (whole thousands → the large-unit currency among
  /// [userCurrencies]; cents → the one other currency) and the shop's
  /// country. Only [userCurrencies] are suggested; null = no clear answer.
  static ({String code, bool printed})? receiptCurrency(
    OcrResult r, {
    required String billCurrency,
    required Iterable<String> userCurrencies,
  }) {
    final mine = {for (final c in userCurrencies) c.toUpperCase()};
    final text = '${r.rawText}\n${r.lines.map((l) => l.text).join('\n')}';
    final lower = text.toLowerCase();

    // 1. Named on the receipt.
    final printed = <String>{};
    _currencySymbols.forEach((sym, code) {
      if (mine.contains(code) && lower.contains(sym)) printed.add(code);
    });
    // "TOTAL LL: 2,240,000": Lebanese receipts write the lira as LL (a
    // whole word, so "all" or "mall" don't count).
    if (mine.contains('LBP') &&
        RegExp(r'(^|[^a-z])ll([^a-z]|$)').hasMatch(lower)) {
      printed.add('LBP');
    }
    for (final c in mine) {
      if (RegExp('(^|[^A-Za-z])$c([^A-Za-z]|\$)').hasMatch(text)) {
        printed.add(c);
      }
    }

    // 2. The amounts. A printed currency that doesn't fit them is an
    // equivalent ("TOTAL 6,300,000 · USD 70.00"), not the receipt's.
    final amounts = [
      for (final l in r.lines)
        if (l.hasPrice) l.parsedAmount!.abs(),
      if (r.receiptTotal != null) r.receiptTotal!,
    ];
    final large = amounts.length >= 2 &&
        amounts.every((a) => a >= 1000 && a % 100 == 0);
    final cents = amounts.any((a) => a != a.roundToDouble());
    printed.removeWhere((c) =>
        (large && !largeUnitCurrencies.contains(c)) ||
        (cents && largeUnitCurrencies.contains(c)));
    if (printed.length == 1) {
      final c = printed.first;
      return c == billCurrency ? null : (code: c, printed: true);
    }
    if (amounts.length < 2) return null;
    final billLarge = largeUnitCurrencies.contains(billCurrency);
    Iterable<String> pool = printed.isNotEmpty ? printed : mine;
    if (large && !billLarge) {
      pool = pool.where(largeUnitCurrencies.contains);
    } else if (cents && billLarge) {
      pool = pool.where((c) => !largeUnitCurrencies.contains(c));
    } else {
      return null;
    }
    final candidates = pool.where((c) => c != billCurrency).toList();
    if (candidates.length > 1) {
      // Several fit: the shop's country decides.
      candidates.retainWhere((c) =>
          (_countryHints[c] ?? const []).any((w) => lower.contains(w)));
    }
    return candidates.length == 1
        ? (code: candidates.first, printed: false)
        : null;
  }

  /// Exposed for tests.
  @visibleForTesting
  static OcrLineKind classifyForTest(String line) =>
      _classify(_tidyNumbers(_fixDigits(line)).toLowerCase());

  /// Exposed for tests.
  @visibleForTesting
  static ExtractedItem? parseLineForTest(String line, {String? currency}) =>
      _parseLine(_tidyNumbers(_fixDigits(line)),
          currency == null ? null : currencyDecimals(currency));
}

/// A raw line placed in the straightened frame: centre ([x], [y]) and width.
class _Placed {
  final OcrRawLine line;
  final double x, y, w;
  _Placed(this.line, {required this.x, required this.y, required this.w});
  double get left => x - w / 2;
  double get right => x + w / 2;
}

/// One receipt row: lines at the same (straightened) height.
class _Row {
  final List<_Placed> parts;
  double y;
  ui.Rect box;

  _Row(_Placed p)
      : parts = [p],
        y = p.y,
        box = p.line.rect;

  void add(_Placed p) {
    parts.add(p);
    y = parts.fold(0.0, (s, q) => s + q.y) / parts.length;
    box = box.expandToInclude(p.line.rect);
  }

  /// A wrapped name line folded into this row.
  void absorb(_Row other) => box = box.expandToInclude(other.box);

  bool overlaps(_Placed p) =>
      parts.any((q) => p.left < q.right - 2 && q.left < p.right - 2);

  double get left => parts.map((p) => p.left).reduce(math.min);
  double get right => parts.map((p) => p.right).reduce(math.max);

  String get text {
    final sorted = [...parts]..sort((a, b) => a.x.compareTo(b.x));
    return sorted.map((p) => p.line.text).join('  ');
  }
}

/// A row being cleaned up (section 5–7 of [OcrService.parseLines]).
class _Parsed {
  final _Row row;
  final String text;
  OcrLineKind kind;
  double? amount;
  String? name;
  int quantity;
  bool weak;

  _Parsed(this.row, this.text, this.kind,
      {this.amount, this.name, this.quantity = 1, this.weak = false});

  void toOther() {
    kind = OcrLineKind.other;
    amount = null;
    name = null;
    quantity = 1;
  }
}
