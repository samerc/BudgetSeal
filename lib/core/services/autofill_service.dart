import '../providers/autofill_provider.dart';
import '../providers/transactions_provider.dart';

/// Data auto-filled from the last transaction with the same category.
class AutofillData {
  final String? accountId;
  final String? accountName;
  final String? title;
  final double? amount;
  final String? categoryId;
  final String? categoryName;

  const AutofillData({
    this.accountId,
    this.accountName,
    this.title,
    this.amount,
    this.categoryId,
    this.categoryName,
  });

  bool get hasData =>
      accountId != null || title != null || amount != null || categoryId != null;
}

/// Look up auto-fill data from the last transaction that used a given category.
AutofillData lookupAutofill({
  required String categoryId,
  required List<TransactionEntry> entries,
  required AutofillSettings settings,
}) {
  // Find the most recent transaction with this category
  // entries are newest-first from transactionEntriesProvider
  TransactionEntry? match;
  for (final e in entries) {
    if (e.tx.type == 'transfer') continue;
    // Check header category
    if (e.tx.categoryId == categoryId) {
      match = e;
      break;
    }
    // Check line categories
    for (final l in e.lines) {
      if (l.categoryId == categoryId) {
        match = e;
        break;
      }
    }
    if (match != null) break;
  }

  if (match == null) return const AutofillData();

  // Extract the account from the matching line or header
  String? accountId;
  String? accountName;
  if (settings.account) {
    if (match.lines.isNotEmpty) {
      // Find the line with this category
      for (final l in match.lines) {
        if (l.categoryId == categoryId && l.accountId != null) {
          accountId = l.accountId;
          accountName = match.lineAccountNames[l.accountId];
          break;
        }
      }
    }
    accountId ??= match.tx.accountId;
    accountName ??= match.accountName;
  }

  // Extract title from note
  String? title;
  if (settings.title && match.tx.note.isNotEmpty) {
    final note = match.tx.note;
    title = note.contains(' — ') ? note.split(' — ').first : note;
    if (title.isEmpty) title = null;
  }

  // Extract amount
  double? amount;
  if (settings.amount) {
    if (match.lines.isNotEmpty) {
      for (final l in match.lines) {
        if (l.categoryId == categoryId) {
          amount = l.amount;
          break;
        }
      }
    }
    amount ??= match.tx.amount;
  }

  return AutofillData(
    accountId: settings.account ? accountId : null,
    accountName: settings.account ? accountName : null,
    title: settings.title ? title : null,
    amount: settings.amount ? amount : null,
    categoryId: settings.category ? categoryId : null,
    categoryName: null,
  );
}

/// Look up auto-fill data from the last transaction that has the same title.
AutofillData lookupAutofillByTitle({
  required String title,
  required List<TransactionEntry> entries,
  required AutofillSettings settings,
}) {
  // Try exact match first, then partial (contains) match.
  // Exact matches are more reliable, so they take priority.
  final lowerTitle = title.toLowerCase();
  TransactionEntry? match;
  TransactionEntry? partialMatch;
  for (final e in entries) {
    if (e.tx.type == 'transfer') continue;
    final note = e.tx.note;
    final txTitle = note.contains(' — ') ? note.split(' — ').first : note;
    if (txTitle.isEmpty) continue;
    final lowerTx = txTitle.toLowerCase();
    if (lowerTx == lowerTitle) {
      match = e;
      break; // exact match wins immediately
    }
    if (partialMatch == null && lowerTx.contains(lowerTitle)) {
      partialMatch = e;
    }
  }
  match ??= partialMatch;

  if (match == null) return const AutofillData();

  String? accountId;
  String? accountName;
  if (settings.account) {
    if (match.lines.isNotEmpty && match.lines.first.accountId != null) {
      accountId = match.lines.first.accountId;
      accountName = match.lineAccountNames[accountId];
    }
    accountId ??= match.tx.accountId;
    accountName ??= match.accountName;
  }

  String? categoryId;
  String? categoryName;
  if (settings.category) {
    if (match.lines.isNotEmpty && match.lines.first.categoryId != null) {
      categoryId = match.lines.first.categoryId;
    }
    categoryId ??= match.tx.categoryId;
  }

  double? amount;
  if (settings.amount) {
    if (match.lines.isNotEmpty) {
      amount = match.lines.first.amount;
    }
    amount ??= match.tx.amount;
  }

  return AutofillData(
    accountId: accountId,
    accountName: accountName,
    title: null, // title is already set by the caller
    amount: amount,
    categoryId: categoryId,
    categoryName: categoryName,
  );
}
