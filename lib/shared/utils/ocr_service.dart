import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// A line item extracted from a receipt via OCR.
class ExtractedItem {
  String name;
  double amount;
  int quantity;

  ExtractedItem({required this.name, required this.amount, this.quantity = 1});

  /// Per-unit price when quantity > 1.
  double get unitPrice => quantity > 1 ? amount / quantity : amount;
}

/// What a receipt line is. Only [item] and [discount] lines can be added to
/// the bill; [tax] and [total] feed the tax field and the total check.
enum OcrLineKind { item, discount, tax, total, other }

/// A recognized text line with its bounding box on the image.
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

/// Offline receipt OCR using Google ML Kit.
class OcrService {
  /// Scan a receipt and return all recognized lines with bounding boxes.
  static Future<OcrResult> scanReceipt(String imagePath) async {
    final textRecognizer = TextRecognizer();
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognized = await textRecognizer.processImage(inputImage);

      // Get actual image dimensions by decoding the file
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

      // Collect all raw lines from all blocks
      final rawLines = <_RawLine>[];
      for (final block in recognized.blocks) {
        for (final line in block.lines) {
          final bbox = line.boundingBox;
          rawLines.add(_RawLine(
            text: line.text,
            rect: ui.Rect.fromLTRB(
              bbox.left.toDouble(),
              bbox.top.toDouble(),
              bbox.right.toDouble(),
              bbox.bottom.toDouble(),
            ),
          ));
        }
      }

      // Merge lines at the same vertical position (same receipt row).
      // ML Kit often splits "Item name    $4.50" into separate blocks.
      rawLines.sort((a, b) => a.rect.top.compareTo(b.rect.top));
      final merged = <_RawLine>[];
      for (final raw in rawLines) {
        if (merged.isNotEmpty) {
          final last = merged.last;
          final verticalOverlap =
              raw.rect.top < last.rect.bottom - (last.rect.height * 0.3);
          if (verticalOverlap) {
            // Same visual row — merge text and expand bounding box
            final combinedRect = ui.Rect.fromLTRB(
              last.rect.left < raw.rect.left ? last.rect.left : raw.rect.left,
              last.rect.top < raw.rect.top ? last.rect.top : raw.rect.top,
              last.rect.right > raw.rect.right ? last.rect.right : raw.rect.right,
              last.rect.bottom > raw.rect.bottom ? last.rect.bottom : raw.rect.bottom,
            );
            // Order text left-to-right
            final leftFirst = last.rect.left < raw.rect.left;
            merged[merged.length - 1] = _RawLine(
              text: leftFirst
                  ? '${last.text}  ${raw.text}'
                  : '${raw.text}  ${last.text}',
              rect: combinedRect,
            );
            continue;
          }
        }
        merged.add(raw);
      }

      // Parse merged lines
      final lines = <OcrLine>[];
      double? receiptTotal;
      double taxTotal = 0;
      for (final raw in merged) {
        final kind = _classify(raw.text.toLowerCase());
        switch (kind) {
          case OcrLineKind.total:
          case OcrLineKind.tax:
            final amount = _lastPrice(raw.text);
            if (amount != null && amount > 0) {
              if (kind == OcrLineKind.total) {
                if (receiptTotal == null || amount > receiptTotal) {
                  receiptTotal = amount;
                }
              } else {
                taxTotal += amount;
              }
            }
            lines.add(OcrLine(
                text: raw.text,
                boundingBox: raw.rect,
                parsedAmount: amount,
                kind: kind));
          case OcrLineKind.other:
            lines.add(
                OcrLine(text: raw.text, boundingBox: raw.rect, kind: kind));
          case OcrLineKind.item:
          case OcrLineKind.discount:
            final parsed = _parseLine(raw.text);
            // "-2.00" anywhere on the line also marks a discount.
            final isDiscount = kind == OcrLineKind.discount ||
                RegExp(r'(^|\s)-\s*[$€£¥]?\s*\d').hasMatch(raw.text);
            final amount = parsed?.amount;
            lines.add(OcrLine(
              text: raw.text,
              boundingBox: raw.rect,
              parsedAmount:
                  amount == null ? null : (isDiscount ? -amount : amount),
              parsedName: parsed?.name,
              parsedQuantity: isDiscount ? 1 : (parsed?.quantity ?? 1),
              kind: isDiscount ? OcrLineKind.discount : OcrLineKind.item,
            ));
        }
      }

      debugPrint('[OcrService] Raw: ${rawLines.length} lines, '
          'merged: ${merged.length}, '
          '${lines.where((l) => l.hasPrice).length} with prices, '
          'total $receiptTotal, tax $taxTotal');
      for (final l in lines) {
        debugPrint('  ${l.kind.name.padRight(8)} "${l.text}"');
      }

      return OcrResult(
        lines: lines,
        imageWidth: imgW,
        imageHeight: imgH,
        rawText: recognized.text,
        receiptTotal: receiptTotal,
        taxTotal: taxTotal > 0 ? taxTotal : null,
      );
    } catch (e) {
      debugPrint('[OcrService] Error: $e');
      return const OcrResult(lines: [], imageWidth: 1000, imageHeight: 1400, rawText: '');
    } finally {
      textRecognizer.close();
    }
  }

  /// Strip trailing tax/note suffixes from a price string.
  /// e.g. "450,000T" → "450,000", "12.50TTC" → "12.50", "100*" → "100"
  static String _stripPriceSuffix(String s) {
    return s.replaceAll(RegExp(r'[A-Za-z*+]+$'), '').trim();
  }

  static final _letter = RegExp(r'\p{L}', unicode: true);

  // Optional currency symbol before ($/€/£/¥) or letters after (T, TTC, LBP…).
  static final _priceRe = RegExp(
    r'[$€£¥]?\s*([,.]?\d{1,3}(?:[,. ]\d{3})*(?:[.,]\d{1,2})?|\d{4,}(?:[.,]\d{1,2})?)\s*[A-Za-z*+]{0,4}(?=\s|$)',
  );

  /// Try to parse a line into (name, amount) using multiple strategies.
  static ExtractedItem? _parseLine(String line) {
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
      return cleaned.contains(RegExp(r'[.,]')) || cleaned.replaceAll(RegExp(r'[,. ]'), '').length >= 4;
    }).toList();

    if (validMatches.isNotEmpty) {
      // Use the LAST price in the line (rightmost = most likely the item price)
      final lastMatch = validMatches.last;
      final priceStr = lastMatch.group(1)!;
      final namepart = trimmed.substring(0, lastMatch.start).trim();
      final item = _buildItem(namepart, priceStr);
      if (item != null) return item;
    }

    // Strategy 2: Whole number price at end (e.g., "Water 3")
    final wholePrice = RegExp(r'(.+?)\s+[$€£¥]?\s*(\d{1,6})\s*$');
    var match = wholePrice.firstMatch(trimmed);
    if (match != null) {
      final name = match.group(1)!;
      if (name.length > 2 && !RegExp(r'^\d+$').hasMatch(name.trim())) {
        return _buildItem(name, match.group(2)!);
      }
    }

    // Strategy 3: Price at start (e.g., "$4.50 Coffee")
    final startPrice = RegExp(r'^[$€£¥]?\s*(\d{1,6}[.,]\d{1,2})\s+(.+)');
    match = startPrice.firstMatch(trimmed);
    if (match != null) return _buildItem(match.group(2)!, match.group(1)!);

    // Strategy 4: "qty x item price"
    final qtyPattern = RegExp(
      r'^\d+\s*[xX×]\s*(.+?)\s+[$€£¥]?\s*(\d{1,6}[.,]\d{1,2})\s*$',
    );
    match = qtyPattern.firstMatch(trimmed);
    if (match != null) return _buildItem(match.group(1)!, match.group(2)!);

    return null;
  }

  static ExtractedItem? _buildItem(String rawName, String rawPrice) {
    final amount = _parsePrice(rawPrice);
    if (amount == null || amount <= 0) return null;
    return _finishItem(rawName, amount);
  }

  /// The rightmost price on [line] (used for total and tax lines).
  static double? _lastPrice(String line) {
    final matches = _priceRe.allMatches(line.trim()).where((m) {
      final cleaned =
          _stripPriceSuffix(m.group(1)!).replaceAll(RegExp(r'^[,.]'), '');
      return cleaned.contains(RegExp(r'[.,]')) ||
          cleaned.replaceAll(RegExp(r'[,. ]'), '').length >= 2;
    }).toList();
    if (matches.isEmpty) return null;
    return _parsePrice(matches.last.group(1)!);
  }

  /// Normalises "1,234.56" / "1.234,56" / "4,50" / "450,000T" to a number.
  static double? _parsePrice(String rawPrice) {
    // Clean price: strip trailing suffixes (T, TTC, HT, VAT, etc.), remove spaces
    var priceStr = _stripPriceSuffix(rawPrice).replaceAll(' ', '');
    // Strip leading separator: ",450,000" → "450,000"
    if (priceStr.startsWith(',') || priceStr.startsWith('.')) {
      priceStr = priceStr.substring(1);
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
        // Could be thousands (145.000 = 145000) or decimal (145.000 = 145.0)
        // If multiple dots, definitely thousands: "1.234.567"
        if (priceStr.indexOf('.') != priceStr.lastIndexOf('.')) {
          priceStr = priceStr.replaceAll('.', '');
        }
        // Single dot + 3 digits: ambiguous, but for large numbers treat as thousands
        else {
          final asWhole = double.tryParse(priceStr.replaceAll('.', ''));
          if (asWhole != null && asWhole > 999) {
            priceStr = priceStr.replaceAll('.', '');
          }
        }
      }
      // Otherwise it's a normal decimal: "12.50" → keep as-is
    }
    return double.tryParse(priceStr);
  }

  static ExtractedItem? _finishItem(String rawName, double amount) {
    var name = rawName.trim();
    int quantity = 1;

    // Extract leading quantity: "2 x Mango", "3x Coffee", "2  AVOCADO"
    final leadingQty = RegExp(r'^(\d{1,2})\s*[xX×]?\s+(.+)').firstMatch(name);
    if (leadingQty != null) {
      final q = int.tryParse(leadingQty.group(1)!);
      final rest = leadingQty.group(2)!;
      // Only treat as quantity if the rest looks like a name (has letters)
      if (q != null && q >= 1 && q <= 99 && rest.contains(_letter)) {
        quantity = q;
        name = rest;
      }
    }

    // Strip leading product/barcode codes: "2745P", "37470", "SKU123"
    name = name.replaceAll(
        RegExp(r'^[A-Z]?[\dA-Z]{3,10}\s+', caseSensitive: false), '');

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

    return ExtractedItem(name: name, amount: amount, quantity: quantity);
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
  ];
  static const _discountWords = [
    'discount', 'remise', 'réduction', 'promo', 'coupon', 'descuento',
    'rabatt', 'خصم', 'تخفيض',
  ];
  static const _otherWords = [
    // Tip is entered separately; payment, change and contact lines aren't items.
    'tip', 'gratuity', 'pourboire', 'cash', 'change', 'rendu', 'monnaie',
    'espèces', 'carte', 'card', 'visa', 'mastercard', 'payment', 'paiement',
    'paid', 'thank', 'merci', 'receipt', 'invoice', 'facture', 'reçu',
    'www', 'http', 'tel', 'tél', 'fax', 'نقدا', 'نقداً', 'الباقي', 'الدفع',
    'بطاقة', 'شكرا', 'شكراً', 'فاتورة', 'إيصال',
  ];

  static final _latinWord = RegExp(r'^[a-zà-ÿ .\-]+$');

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
    if (_has(lower, _subtotalWords)) return OcrLineKind.other;
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
    if (lower.replaceAll(RegExp(r'[^\p{L}]', unicode: true), '').length < 2) {
      return true;
    }
    return false;
  }

  /// Exposed for tests.
  @visibleForTesting
  static OcrLineKind classifyForTest(String line) =>
      _classify(line.toLowerCase());

  /// Exposed for tests.
  @visibleForTesting
  static ExtractedItem? parseLineForTest(String line) => _parseLine(line);
}

/// Internal helper for pre-merge OCR lines.
class _RawLine {
  final String text;
  final ui.Rect rect;
  const _RawLine({required this.text, required this.rect});
}
