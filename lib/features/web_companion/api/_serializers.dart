import '../../../core/database/app_database.dart';
import '../../../shared/utils/note_text.dart';
import '../../../shared/widgets/category_icon.dart';

/// Category display fields shared by every payload that shows a category.
/// `categoryIconFile` is the PNG the app draws (served at `/icons/<file>`);
/// without one the browser falls back to the emoji, then the first letter.
Map<String, dynamic> categoryFields(Category? c) => {
      'categoryId': c?.id,
      'categoryName': c?.name,
      'categoryIcon': c?.icon,
      'categoryColor': c?.colorHex,
      'categoryIconFile': c == null ? null : categoryIconFile(c.name, c.icon),
    };

/// The `[obj:ID|amount]` goal/loan tag in a note, or '' — the browser shows
/// [visibleNote] and the edit handler puts the tag back.
String noteTag(String note) =>
    RegExp(r'\s*\[obj:[^\]]*\]').firstMatch(note)?.group(0) ?? '';

Map<String, dynamic> txToJson(
  Transaction t,
  Map<String, Category> catMap,
  Map<String, Account> acctMap, {
  TransactionLine? firstLine,
  int lineCount = 0,
}) {
  // Split and single-line transactions keep the category on the line.
  final catId = t.categoryId ?? firstLine?.categoryId;
  return {
    'id': t.id,
    'type': t.type,
    'amount': t.amount,
    'currency': t.currency,
    'exchangeRateToBase': t.exchangeRateToBase,
    'note': visibleNote(t.note),
    'date': t.createdAt.toIso8601String(),
    'accountId': t.accountId,
    'accountName': acctMap[t.accountId]?.name,
    'accountCurrency': acctMap[t.accountId]?.currency,
    'destinationAccountId': t.destinationAccountId,
    'destinationAccountName': t.destinationAccountId != null
        ? acctMap[t.destinationAccountId]?.name
        : null,
    'destinationCurrency': t.destinationAccountId != null
        ? acctMap[t.destinationAccountId]?.currency
        : null,
    ...categoryFields(catId != null ? catMap[catId] : null),
    'status': t.status,
    'lineCount': lineCount,
    if (firstLine != null) ...{
      'lineCurrency': firstLine.currency,
      'lineAmount': firstLine.amount,
      'lineExchangeRate': firstLine.exchangeRateToBase,
    },
  };
}

Map<String, dynamic> lineToJson(
  TransactionLine l,
  Map<String, Category> catMap,
  Map<String, Account> acctMap,
) =>
    {
      'id': l.id,
      'amount': l.amount,
      'currency': l.currency,
      'exchangeRateToBase': l.exchangeRateToBase,
      'note': visibleNote(l.note),
      'accountId': l.accountId,
      'accountName': l.accountId != null ? acctMap[l.accountId]?.name : null,
      ...categoryFields(l.categoryId != null ? catMap[l.categoryId] : null),
    };

Map<String, dynamic> accountToJson(Account a, double balance) => {
      'id': a.id,
      'name': a.name,
      'type': a.type,
      'currency': a.currency,
      'balance': balance,
      'decimalPlaces': a.decimalPlaces,
      'isTravel': a.isTravel,
      'archived': a.archived,
    };

Map<String, dynamic> allocationToJson(
  Allocation a,
  Map<String, double> balanceByCurrency, {
  Map<String, double> spentByCurrency = const {},
  String? colorHex,
}) =>
    {
      'id': a.id,
      'name': a.name,
      'type': a.type == 'saving' ? 'flexible' : a.type,
      'icon': a.icon,
      'colorHex': colorHex,
      'periodicity': a.periodicity,
      'rollover': a.rollover,
      'targetAmount': a.targetAmount,
      'targetCurrency': a.targetCurrency,
      'balanceByCurrency': balanceByCurrency,
      'spentByCurrency': spentByCurrency,
    };

Map<String, dynamic> categoryToJson(Category c) => {
      'id': c.id,
      'name': c.name,
      'icon': c.icon,
      'iconFile': categoryIconFile(c.name, c.icon),
      'colorHex': c.colorHex,
      'transactionType': c.transactionType,
      'parentId': c.parentId,
      'allocationId': c.allocationId,
      'defaultAccountId': c.defaultAccountId,
      'archived': c.archived,
    };

Map<String, dynamic> recurringToJson(
  RecurringTransaction r,
  Map<String, Category> catMap,
  Map<String, Account> acctMap,
) =>
    {
      'id': r.id,
      'type': r.type,
      'title': r.title,
      'amount': r.amount,
      'currency': r.currency,
      'frequency': r.frequency,
      'interval': r.interval,
      'nextDueDate': r.nextDueDate.toIso8601String(),
      'endDate': r.endDate?.toIso8601String(),
      'enabled': r.enabled,
      'isSubscription': r.isSubscription,
      'priceHistory': r.priceHistory,
      'note': r.note,
      'accountId': r.accountId,
      'accountName': acctMap[r.accountId]?.name,
      'destinationAccountId': r.destinationAccountId,
      'destinationAccountName': r.destinationAccountId != null
          ? acctMap[r.destinationAccountId]?.name
          : null,
      ...categoryFields(r.categoryId != null ? catMap[r.categoryId] : null),
    };
