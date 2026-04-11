/// Abstract FX rate provider.
/// Swap implementations without touching the engine or UI.
abstract class FxProvider {
  /// Fetch the exchange rate from [from] to [to] currency.
  /// Returns the rate (e.g. 1 USD = 89500 LBP → rate = 89500).
  Future<double> getRate(String from, String to);

  /// Whether this provider supports live rates.
  bool get isLive;
}
