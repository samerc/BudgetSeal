import 'app_database.dart';

extension TransferAmounts on Transaction {
  /// What a transfer delivered to its destination, in the destination
  /// account's currency. The rate is only the fallback for a row an older
  /// phone just synced, until `normalizeTransactions()` fills the column.
  double get receivedAmount => destinationAmount ?? amount * exchangeRateToBase;
}
