import 'package:intl/intl.dart';

import '../../core/providers/number_format_provider.dart';

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

/// User overrides for currency symbols.
Map<String, String> _userOverrides = {};

/// Number format preferences — set from provider at startup.
NumberFormatPrefs _numberFormat = const NumberFormatPrefs();

/// Set user overrides for currency symbols.
void setCurrencySymbolOverrides(Map<String, String> overrides) {
  _userOverrides = overrides;
}

/// Set number format preferences.
void setNumberFormatPrefs(NumberFormatPrefs prefs) {
  _numberFormat = prefs;
}

/// Resolved symbols: user overrides take precedence over defaults.
String? _resolveSymbol(String code) {
  return _userOverrides[code] ?? defaultCurrencySymbols[code];
}

const _defaultSpacedSymbols = <String>{'ل.ل', 'د.إ', 'CHF', '﷼'};

bool _needsSpace(String symbol) {
  if (_defaultSpacedSymbols.contains(symbol)) return true;
  if (symbol.length > 2 &&
      !symbol.startsWith('\$') &&
      !symbol.startsWith('€')) {
    return true;
  }
  return false;
}

/// Format the raw number with the user's preferred separators.
String _formatNumber(double absValue, int decimalDigits) {
  // Use intl to get the base formatted number (always comma + period)
  final formatter = NumberFormat.currency(
    symbol: '',
    decimalDigits: decimalDigits,
  );
  var formatted = formatter.format(absValue).trim();

  // Now replace separators based on user preferences.
  // The intl formatter uses ',' for thousands and '.' for decimals by default.
  final wantThousands = _numberFormat.thousands.char;
  final wantDecimal = _numberFormat.decimal.char;

  if (wantThousands != ',' || wantDecimal != '.') {
    // Step 1: Replace the default separators with placeholders
    formatted = formatted.replaceAll(',', '\x01').replaceAll('.', '\x02');
    // Step 2: Replace placeholders with desired separators
    formatted =
        formatted.replaceAll('\x01', wantThousands).replaceAll('\x02', wantDecimal);
  }

  return formatted;
}

/// Wrap a formatted amount string with the negative indicator.
String _wrapNegative(String inner, bool isNeg) {
  if (!isNeg) return inner;
  if (_numberFormat.negative == NegativeFormat.parentheses) {
    return '($inner)';
  }
  return '-$inner';
}

/// Format a number with separators and optional currency symbol.
///
/// Respects user preferences for thousands separator, decimal separator,
/// and negative format.
String formatAmount(double value, {String? currency, int? decimals}) {
  final isNeg = value < 0;
  final absValue = value.abs();

  final hasDecimals =
      decimals != null ? decimals > 0 : (absValue % 1 != 0);
  final decimalDigits = decimals ?? (hasDecimals ? 2 : 0);

  final formatted = _formatNumber(absValue, decimalDigits);

  if (currency != null) {
    final symbol = _resolveSymbol(currency);
    if (symbol != null) {
      final space = _needsSpace(symbol) ? ' ' : '';
      return _wrapNegative('$symbol$space$formatted', isNeg);
    }
    return _wrapNegative('$currency $formatted', isNeg);
  }
  return _wrapNegative(formatted, isNeg);
}

/// Format with an explicit sign prefix: +$1,234 or -$1,234.
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
  final formatted = _formatNumber(absValue, decimalDigits);

  // For signed amounts, always use sign prefix (not parentheses)
  if (symbol != null) {
    final space = _needsSpace(symbol) ? ' ' : '';
    return '$sign$symbol$space$formatted';
  }
  return '$sign$currency $formatted';
}

/// Format a number for display in calculator/input fields.
/// Always uses the user's preferred separators.
String formatForDisplay(double value) {
  if (value == 0) return '0';
  final hasDecimals = value % 1 != 0;
  final decimalDigits = hasDecimals ? 2 : 0;
  return _formatNumber(value, decimalDigits);
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
