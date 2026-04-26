import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// A line item extracted from a receipt via OCR.
class ExtractedItem {
  String name;
  double amount;

  ExtractedItem({required this.name, required this.amount});
}

/// A recognized text line with its bounding box on the image.
class OcrLine {
  final String text;
  final ui.Rect boundingBox;
  final double? parsedAmount;
  final String? parsedName;

  OcrLine({
    required this.text,
    required this.boundingBox,
    this.parsedAmount,
    this.parsedName,
  });

  /// Whether this line looks like a billable item (has a price).
  bool get hasPrice => parsedAmount != null && parsedAmount! > 0;
}

/// Result of scanning a receipt.
class OcrResult {
  final List<OcrLine> lines;
  final int imageWidth;
  final int imageHeight;
  final String rawText;

  const OcrResult({
    required this.lines,
    required this.imageWidth,
    required this.imageHeight,
    required this.rawText,
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

      // Get image dimensions from metadata
      final inputImg = InputImage.fromFilePath(imagePath);
      final imageData = inputImg.metadata;
      int imgW = 1000, imgH = 1400; // fallback
      if (imageData?.size != null) {
        imgW = imageData!.size.width.toInt();
        imgH = imageData.size.height.toInt();
      }

      final lines = <OcrLine>[];
      for (final block in recognized.blocks) {
        for (final line in block.lines) {
          final bbox = line.boundingBox;
          final parsed = _parseLine(line.text);
          lines.add(OcrLine(
            text: line.text,
            boundingBox: ui.Rect.fromLTRB(
              bbox.left.toDouble(),
              bbox.top.toDouble(),
              bbox.right.toDouble(),
              bbox.bottom.toDouble(),
            ),
            parsedAmount: parsed?.amount,
            parsedName: parsed?.name,
          ));
        }
      }

      debugPrint('[OcrService] Scanned ${lines.length} lines, '
          '${lines.where((l) => l.hasPrice).length} with prices');

      return OcrResult(
        lines: lines,
        imageWidth: imgW,
        imageHeight: imgH,
        rawText: recognized.text,
      );
    } catch (e) {
      debugPrint('[OcrService] Error: $e');
      return const OcrResult(lines: [], imageWidth: 1000, imageHeight: 1400, rawText: '');
    } finally {
      textRecognizer.close();
    }
  }

  /// Try to parse a line into (name, amount).
  static ExtractedItem? _parseLine(String line) {
    final trimmed = line.trim();
    if (trimmed.length < 2) return null;

    final lower = trimmed.toLowerCase();
    if (_isNonItemLine(lower)) return null;

    // Strategy 1: Price at end (most common)
    final endPrice = RegExp(
      r'(.+?)\s+[\$€£¥]?\s*(\d{1,6}[.,]\d{1,2})\s*$',
    );
    var match = endPrice.firstMatch(trimmed);
    if (match != null) return _buildItem(match.group(1)!, match.group(2)!);

    // Strategy 2: Whole number price at end
    final wholePrice = RegExp(r'(.+?)\s+[\$€£¥]?\s*(\d{1,6})\s*$');
    match = wholePrice.firstMatch(trimmed);
    if (match != null) {
      final name = match.group(1)!;
      if (name.length > 2 && !RegExp(r'^\d+$').hasMatch(name.trim())) {
        return _buildItem(name, match.group(2)!);
      }
    }

    // Strategy 3: Price at start
    final startPrice = RegExp(r'^[\$€£¥]?\s*(\d{1,6}[.,]\d{1,2})\s+(.+)');
    match = startPrice.firstMatch(trimmed);
    if (match != null) return _buildItem(match.group(2)!, match.group(1)!);

    // Strategy 4: "qty x item price"
    final qtyPattern = RegExp(
      r'^\d+\s*[xX×]\s*(.+?)\s+[\$€£¥]?\s*(\d{1,6}[.,]\d{1,2})\s*$',
    );
    match = qtyPattern.firstMatch(trimmed);
    if (match != null) return _buildItem(match.group(1)!, match.group(2)!);

    return null;
  }

  static ExtractedItem? _buildItem(String rawName, String rawPrice) {
    final priceStr = rawPrice.replaceAll(',', '.');
    final amount = double.tryParse(priceStr);
    if (amount == null || amount <= 0) return null;

    var name = rawName.trim();
    name = name.replaceAll(RegExp(r'^[\d]+[.\s]+'), '');
    name = name.replaceAll(RegExp(r'[.\-_:]+$'), '').trim();
    name = name.replaceAll(RegExp(r'\s{2,}'), ' ');

    if (name.isEmpty || name.length < 2) return null;
    if (name.length > 80) name = name.substring(0, 80);

    return ExtractedItem(name: name, amount: amount);
  }

  static bool _isNonItemLine(String lower) {
    const skip = [
      'total', 'subtotal', 'sub total', 'grand total',
      'tax ', 'vat ', 'tip ', 'gratuity', 'change ',
      'cash ', 'credit card', 'debit card', 'visa ', 'mastercard',
      'thank you', 'receipt', 'invoice',
      'table ', 'server ', 'cashier',
      'tel ', 'phone', 'fax ', 'www.', 'http',
      'balance', 'payment', 'amount due',
    ];
    for (final s in skip) {
      if (lower.startsWith(s)) return true;
    }
    if (RegExp(r'^\d[\d/\-.:, ]+$').hasMatch(lower)) return true;
    return false;
  }
}
