import 'package:intl/intl.dart';

/// Default map of currency codes to their display symbols.
const defaultCurrencySymbols = <String, String>{
  'USD': '\$',
  'EUR': '€',
  'GBP': '£',
  'JPY': '¥',
  'LBP': 'ل.ل',
  'AED': 'د.إ',
  'CAD': 'CA\$',
  'AUD': 'A\$',
  'CHF': 'CHF',
  'TRY': '₺',
  'SAR': '﷼',
  'EGP': 'E£',
  'INR': '₹',
  'BRL': 'R\$',
};

/// User overrides — populated from CurrencySymbolProvider at startup.
/// Call [setCurrencySymbolOverrides] to update.
Map<String, String> _userOverrides = {};

/// Set user overrides for currency symbols. Called by the app when the
/// provider state changes.
void setCurrencySymbolOverrides(Map<String, String> overrides) {
  _userOverrides = overrides;
}

/// Resolved symbols: user overrides take precedence over defaults.
String? _resolveSymbol(String code) {
  return _userOverrides[code] ?? defaultCurrencySymbols[code];
}

/// Symbols that require a space between symbol and amount.
const _defaultSpacedSymbols = <String>{'ل.ل', 'د.إ', 'CHF', '﷼'};

bool _needsSpace(String symbol) {
  if (_defaultSpacedSymbols.contains(symbol)) return true;
  // User overrides longer than 2 chars get a space (e.g. "LBP", "CHF")
  if (symbol.length > 2 && !symbol.startsWith('\$') && !symbol.startsWith('€')) {
    return true;
  }
  return false;
}

/// Format a number with comma separators and optional currency symbol.
///
/// - `formatAmount(1234.5)` → `1,234.50`
/// - `formatAmount(1234, currency: 'USD')` → `$1,234`
/// - `formatAmount(-1234, currency: 'USD')` → `-$1,234`
/// - `formatAmount(1234, currency: 'LBP')` → `ل.ل 1,234`
///
/// The sign is always placed BEFORE the currency symbol.
/// Callers should NOT manually prepend $ or sign characters.
String formatAmount(double value, {String? currency, int? decimals}) {
  final isNeg = value < 0;
  final absValue = value.abs();

  final hasDecimals = decimals != null
      ? decimals > 0
      : (absValue % 1 != 0);
  final decimalDigits = decimals ?? (hasDecimals ? 2 : 0);

  final formatter = NumberFormat.currency(
    symbol: '',
    decimalDigits: decimalDigits,
  );
  final formatted = formatter.format(absValue).trim();
  final sign = isNeg ? '-' : '';

  if (currency != null) {
    final symbol = _resolveSymbol(currency);
    if (symbol != null) {
      final space = _needsSpace(symbol) ? ' ' : '';
      return '$sign$symbol$space$formatted';
    }
    return '$sign$currency $formatted';
  }
  return '$sign$formatted';
}

/// Format with an explicit sign prefix: +$1,234 or -$1,234.
/// Use for income/expense display where you always want a sign.
String formatSignedAmount(
  double value, {
  required String currency,
  required String type,
}) {
  final absValue = value.abs();
  final sign = type == 'income' ? '+' : type == 'expense' ? '-' : '';
  final symbol = _resolveSymbol(currency);

  final hasDecimals = absValue % 1 != 0;
  final decimalDigits = hasDecimals ? 2 : 0;
  final formatter = NumberFormat.currency(symbol: '', decimalDigits: decimalDigits);
  final formatted = formatter.format(absValue).trim();

  if (symbol != null) {
    final space = _needsSpace(symbol) ? ' ' : '';
    return '$sign$symbol$space$formatted';
  }
  return '$sign$currency $formatted';
}

/// Round an exchange rate to a practical value.
double roundRate(double rate) {
  if (rate >= 10000) return (rate / 500).round() * 500.0;
  if (rate >= 1000) return (rate / 100).round() * 100.0;
  if (rate >= 100) return (rate / 10).round() * 10.0;
  if (rate >= 1) return double.parse(rate.toStringAsFixed(2));
  return double.parse(rate.toStringAsFixed(6));
}

/// Format a rate for display in a text field.
String formatRateForInput(double rate) {
  final rounded = roundRate(rate);
  if (rounded >= 100) return rounded.toStringAsFixed(0);
  if (rounded >= 1) return rounded.toStringAsFixed(2);
  return rounded.toStringAsFixed(6);
}
