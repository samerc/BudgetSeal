import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../shared/utils/ocr_service.dart';
import '../../shared/utils/receipt_helper.dart';
import '../../shared/utils/format_number.dart' show roundRate;
import '../database/app_database.dart';
import '../engine/allocation_engine.dart';
import '../fx/fx_service.dart';
import '../services/last_used_service.dart';
import 'bank_alerts.dart';
import 'capture_rules.dart';
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
  return captureFormArgs(
    text: text,
    receiptTotal: receiptTotal,
    receiptShop: receiptShop,
    receipts: receipts,
    db: db,
    householdId: householdId,
    baseCurrency: baseCurrency,
  );
}

/// The `/add-transaction` extra for a bank alert in "To review": dated
/// when it arrived, read the way this bank's messages were learned, and
/// tied to the alert (saving it removes it from the inbox).
Future<Map<String, dynamic>> alertFormArgs(
  AlertItem item, {
  required AppDatabase db,
  required String householdId,
  required String baseCurrency,
}) async =>
    captureFormArgs(
      text: item.fullText,
      when: item.at,
      amountIndex: await BankAlerts.amountIndex(item.app),
      capture: {'alertId': item.id, 'app': item.app},
      db: db,
      householdId: householdId,
      baseCurrency: baseCurrency,
    );

/// The form's extra for a captured payment: [readCapturedText], a rule
/// for its shop (category, account, title), an account in its currency
/// (the rule's, else the last one used, else the first). The extra's
/// `capture` (shop, alert, app, text) goes back to [captureSaved].
Future<Map<String, dynamic>> captureFormArgs({
  required String text,
  double? receiptTotal,
  String? receiptShop,
  List<String> receipts = const [],
  DateTime? when,
  int amountIndex = 0,
  Map<String, Object?> capture = const {},
  required AppDatabase db,
  required String householdId,
  required String baseCurrency,
}) async {
  final draft = readCapturedText(text,
      fallbackCurrency: baseCurrency, amountIndex: amountIndex);
  // A receipt's TOTAL line beats the first number in its text (an item).
  final amount = receiptTotal ?? draft.amount;
  final accounts = await (db.select(db.accounts)
        ..where((a) =>
            a.householdId.equals(householdId) &
            a.archived.equals(false) &
            a.deleted.equals(false)))
      .get();
  final currency = draft.currency ?? baseCurrency;
  final shop = draft.merchant ?? receiptShop;
  // A rule for this shop or message: its category, account and title.
  final rule = await findCaptureRule(
      db, householdId, [if (shop != null) shop, text].join('\n'));
  final last = await LastUsedService.defaultAccount(accounts);
  final inCurrency = accounts.where((a) => a.currency == currency).toList();
  final account = inCurrency.where((a) => a.id == rule?.accountId).firstOrNull ??
      inCurrency.where((a) => a.id == last).firstOrNull ??
      inCurrency.firstOrNull;
  final now = DateTime.now();
  final date = when ??
      (draft.date == null
          ? null
          : DateTime(draft.date!.year, draft.date!.month, draft.date!.day,
              now.hour, now.minute));

  return {
    'editType': draft.type,
    'editNote': rule?.title ?? shop ?? '',
    // Back to captureSaved() when it's saved.
    'capture': {...capture, if (shop != null) 'shop': shop, 'text': text},
    if (date != null && !date.isAfter(now)) 'editDate': date,
    'editLines': [
      {
        'amount': amount ?? 0.0,
        'currency': currency,
        'accountId': account?.id,
        'categoryId': rule?.categoryId,
        'note': '',
      },
    ],
    if (receipts.isNotEmpty) 'editReceipts': receipts,
  };
}

/// A captured payment ([capture], from the form's extra) was saved as
/// [amount] with [categoryId] / [accountId]: its shop becomes a rule
/// (learned), a bank alert leaves "To review", and if the amount was
/// another one in the alert's text, that bank's wording is learned.
Future<void> captureSaved(
  AppDatabase db, {
  required String householdId,
  required Map<String, dynamic> capture,
  required double amount,
  required String? categoryId,
  required String? accountId,
}) async {
  final shop = capture['shop'] as String?;
  if (shop != null) {
    await learnCaptureRule(db,
        householdId: householdId,
        shop: shop,
        categoryId: categoryId,
        accountId: accountId);
  }
  final alertId = capture['alertId'] as String?;
  if (alertId != null) await BankAlerts.remove(alertId);
  final app = capture['app'] as String?;
  final text = capture['text'] as String?;
  if (app != null && text != null) {
    await BankAlerts.learnAmount(app, text, amount);
  }
}

/// To review's swipe right: saves a bank alert as it was read — the
/// account, category, note and date the form would start with — then
/// learns from it like the form does ([captureSaved]). Returns the new
/// transaction's id, or null when the form is needed instead: no amount,
/// no category for the shop yet, no account in its currency, or no rate.
Future<String?> saveAlertAsRead(
  AlertItem item, {
  required AppDatabase db,
  required AllocationEngine engine,
  required FxService fx,
  required String householdId,
  required String baseCurrency,
}) async {
  final args = await alertFormArgs(item,
      db: db, householdId: householdId, baseCurrency: baseCurrency);
  final line = (args['editLines'] as List).first as Map<String, dynamic>;
  final amount = line['amount'] as double;
  final currency = line['currency'] as String;
  final categoryId = line['categoryId'] as String?;
  final accountId = line['accountId'] as String?;
  if (amount <= 0 || categoryId == null || accountId == null) return null;
  var rateToBase = 1.0;
  if (currency != baseCurrency) {
    try {
      final rate = roundRate(await fx.getRateWithCache(baseCurrency, currency));
      if (rate <= 0) return null;
      rateToBase = 1.0 / rate;
    } catch (e) {
      debugPrint('[Capture] No rate for $currency: $e');
      return null;
    }
  }
  final txId = await engine.recordTransaction(
    householdId: householdId,
    accountId: accountId,
    type: args['editType'] as String,
    lines: [
      TxLine(
          amount: amount,
          currency: currency,
          categoryId: categoryId,
          accountId: accountId,
          exchangeRateToBase: rateToBase),
    ],
    baseCurrency: baseCurrency,
    note: args['editNote'] as String,
    date: args['editDate'] as DateTime?,
  );
  await LastUsedService.rememberAccount(accountId);
  await captureSaved(db,
      householdId: householdId,
      capture: (args['capture'] as Map).cast<String, dynamic>(),
      amount: amount,
      categoryId: categoryId,
      accountId: accountId);
  return txId;
}
