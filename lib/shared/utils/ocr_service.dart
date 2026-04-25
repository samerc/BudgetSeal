import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// A line item extracted from a receipt via OCR.
class ExtractedItem {
  String name;
  double amount;

  ExtractedItem({required this.name, required this.amount});
}

/// Offline receipt OCR using Google ML Kit.
class OcrService {
  /// Extract line items (name + amount) from a receipt image.
  ///
  /// Uses on-device text recognition — no internet required.
  /// Returns a best-effort list of items; the user should review and edit.
  static Future<List<ExtractedItem>> extractLineItems(String imagePath) async {
    final textRecognizer = TextRecognizer();
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognized = await textRecognizer.processImage(inputImage);

      final items = <ExtractedItem>[];

      for (final block in recognized.blocks) {
        for (final line in block.lines) {
          final item = _parseLine(line.text);
          if (item != null) items.add(item);
        }
      }

      // If no structured items found, try line-by-line across blocks
      if (items.isEmpty) {
        for (final block in recognized.blocks) {
          final item = _parseLine(block.text);
          if (item != null) items.add(item);
        }
      }

      return items;
    } catch (e) {
      debugPrint('[OcrService] Error: $e');
      return [];
    } finally {
      textRecognizer.close();
    }
  }

  /// Try to parse a line into (name, amount).
  ///
  /// Matches patterns like:
  ///   "Coffee          $4.50"
  ///   "Burger 12.99"
  ///   "Tax   2.00"
  ///   "Subtotal $15.49"
  static ExtractedItem? _parseLine(String line) {
    // Skip common non-item lines
    final lower = line.toLowerCase().trim();
    if (lower.isEmpty) return null;
    if (lower.length < 3) return null;
    // Skip header/footer lines
    if (_isNonItemLine(lower)) return null;

    // Match: text followed by a price pattern
    // Supports: $12.50, 12.50, 12,50, $1,234.56
    final pricePattern = RegExp(
        r'[\$€£¥]?\s*(\d{1,3}(?:[,\.]\d{3})*[,\.]\d{2})\s*$');
    final match = pricePattern.firstMatch(line.trim());
    if (match == null) return null;

    final priceStr = match.group(1)!
        .replaceAll(RegExp(r'[^\d.]'), '')
        .replaceAll(',', '.');
    final amount = double.tryParse(priceStr);
    if (amount == null || amount <= 0) return null;

    // Extract name: everything before the price
    var name = line.substring(0, match.start).trim();
    // Clean up common prefixes
    name = name.replaceAll(RegExp(r'^[\d]+[.\s]+'), ''); // remove leading numbers
    name = name.replaceAll(RegExp(r'[.\-_]+$'), '').trim(); // trailing dots/dashes

    if (name.isEmpty) return null;
    if (name.length > 80) name = name.substring(0, 80);

    return ExtractedItem(name: name, amount: amount);
  }

  static bool _isNonItemLine(String lower) {
    const skip = [
      'total', 'subtotal', 'sub total', 'grand total',
      'tax', 'vat', 'tip', 'gratuity', 'change',
      'cash', 'credit', 'debit', 'visa', 'mastercard',
      'thank you', 'receipt', 'invoice',
      'date', 'time', 'table', 'server', 'cashier',
      'tel', 'phone', 'fax', 'www', 'http',
    ];
    for (final s in skip) {
      if (lower.startsWith(s)) return true;
    }
    return false;
  }
}
