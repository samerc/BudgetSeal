import '../../../core/database/app_database.dart';

Map<String, dynamic> txToJson(
  Transaction t,
  Map<String, Category> catMap,
  Map<String, Account> acctMap,
) =>
    {
      'id': t.id,
      'type': t.type,
      'amount': t.amount,
      'currency': t.currency,
      'exchangeRateToBase': t.exchangeRateToBase,
      'note': t.note,
      'date': t.createdAt.toIso8601String(),
      'accountId': t.accountId,
      'accountName': acctMap[t.accountId]?.name,
      'destinationAccountId': t.destinationAccountId,
      'destinationAccountName': t.destinationAccountId != null
          ? acctMap[t.destinationAccountId]?.name
          : null,
      'categoryId': t.categoryId,
      'categoryName': t.categoryId != null ? catMap[t.categoryId]?.name : null,
      'categoryIcon': t.categoryId != null ? catMap[t.categoryId]?.icon : null,
      'categoryColor':
          t.categoryId != null ? catMap[t.categoryId]?.colorHex : null,
      'status': t.status,
    };

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
      'note': l.note,
      'accountId': l.accountId,
      'accountName': l.accountId != null ? acctMap[l.accountId]?.name : null,
      'categoryId': l.categoryId,
      'categoryName': l.categoryId != null ? catMap[l.categoryId]?.name : null,
      'categoryIcon': l.categoryId != null ? catMap[l.categoryId]?.icon : null,
      'categoryColor':
          l.categoryId != null ? catMap[l.categoryId]?.colorHex : null,
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
  Map<String, double> balanceByCurrency,
) =>
    {
      'id': a.id,
      'name': a.name,
      'type': a.type,
      'icon': a.icon,
      'periodicity': a.periodicity,
      'rollover': a.rollover,
      'targetAmount': a.targetAmount,
      'targetCurrency': a.targetCurrency,
      'balanceByCurrency': balanceByCurrency,
    };

Map<String, dynamic> categoryToJson(Category c) => {
      'id': c.id,
      'name': c.name,
      'icon': c.icon,
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
      'categoryId': r.categoryId,
      'categoryName': r.categoryId != null ? catMap[r.categoryId]?.name : null,
      'categoryIcon': r.categoryId != null ? catMap[r.categoryId]?.icon : null,
    };
