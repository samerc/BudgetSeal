import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../shared/utils/ocr_service.dart';
import '../../shared/utils/receipt_helper.dart';
import '../database/app_database.dart';
import '../services/last_used_service.dart';
import 'text_reader.dart';

/// Something shared into BudgetSeal from another app: a bank message's
/// text, and/or a receipt photo or screenshot (copied into the cache by
/// `MainActivity.kt`).
class SharedItem {
  final String text;
  final List<String> files;
  const SharedItem(this.text, this.files);
}

/// Share into BudgetSeal (roadmap #2, Android): the native side keeps the
/// share until Dart takes it — the one that launched the app, and later
/// ones while it runs. The app turns [incoming] into a prefilled add form
/// ([shareFormArgs]).
class ShareIntake {
  static const _channel = MethodChannel('budgetseal/share');

  /// The latest share not yet opened (the app clears it).
  static final incoming = ValueNotifier<SharedItem?>(null);

  static Future<void> init() async {
    if (!Platform.isAndroid) return;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'arrived') await _take();
    });
    await _take();
  }

  static Future<void> _take() async {
    try {
      final raw = await _channel.invokeMethod<Map<Object?, Object?>>('take');
      if (raw == null) return;
      incoming.value = SharedItem(
        raw['text'] as String? ?? '',
        [for (final f in raw['files'] as List? ?? const []) f as String],
      );
    } catch (e) {
      debugPrint('[Share] Taking the share failed: $e');
    }
  }
}

/// The `/add-transaction` extra for a shared [item]: its text (and a
/// photo's text, read on the phone) through [readCapturedText], the photo
/// kept as the receipt, an account in the payment's currency (the last one
/// used when it fits). Null when nothing was shared.
Future<Map<String, dynamic>?> shareFormArgs(
  SharedItem item, {
  required AppDatabase db,
  required String householdId,
  required String baseCurrency,
}) async {
  var text = item.text;
  double? receiptTotal;
  String? receiptShop;
  final receipts = <String>[];
  for (final path in item.files.take(1)) {
    try {
      final ocr = await OcrService.scanReceipt(path);
      text = [text, ocr.rawText].where((t) => t.trim().isNotEmpty).join('\n');
      receiptTotal = ocr.receiptTotal;
      // A receipt usually starts with the shop's name.
      receiptShop = ocr.rawText
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.length >= 3 && !RegExp(r'\d').hasMatch(l))
          .firstOrNull;
    } catch (e) {
      debugPrint('[Share] Reading the photo failed: $e');
    }
    final saved = await saveReceiptFromPath(path);
    if (saved != null) receipts.add(saved);
  }
  if (text.trim().isEmpty && receipts.isEmpty) return null;

  final draft = readCapturedText(text, fallbackCurrency: baseCurrency);
  // A receipt's TOTAL line beats the first number in its text (an item).
  final amount = receiptTotal ?? draft.amount;
  final accounts = await (db.select(db.accounts)
        ..where((a) =>
            a.householdId.equals(householdId) &
            a.archived.equals(false) &
            a.deleted.equals(false)))
      .get();
  final currency = draft.currency ?? baseCurrency;
  final last = await LastUsedService.defaultAccount(accounts);
  final inCurrency = accounts.where((a) => a.currency == currency).toList();
  final account = inCurrency.where((a) => a.id == last).firstOrNull ??
      inCurrency.firstOrNull;
  final now = DateTime.now();
  final date = draft.date == null
      ? null
      : DateTime(draft.date!.year, draft.date!.month, draft.date!.day,
          now.hour, now.minute);

  return {
    'editType': draft.type,
    'editNote': draft.merchant ?? receiptShop ?? '',
    if (date != null && !date.isAfter(now)) 'editDate': date,
    'editLines': [
      {
        'amount': amount ?? 0.0,
        'currency': currency,
        'accountId': account?.id,
        'categoryId': null,
        'note': '',
      },
    ],
    if (receipts.isNotEmpty) 'editReceipts': receipts,
  };
}
