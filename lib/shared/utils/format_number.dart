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
/// When the app locale is Arabic, digits are converted to Arabic-Indic (٠١٢٣٤٥٦٧٨٩).
String _formatNumber(double absValue, int decimalDigits) {
  // Use en_US for formatting structure (comma thousands, period decimal)
  // then apply user separator prefs and locale-specific digit conversion.
  final formatter = NumberFormat.currency(
    locale: 'en_US',
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

  // Convert to Arabic-Indic numerals when locale is Arabic
  if (_useArabicDigits) {
    formatted = _toArabicDigits(formatted);
  }

  return formatted;
}

/// Whether to render Arabic-Indic numerals (٠١٢٣٤٥٦٧٨٩).
bool _useArabicDigits = false;

/// Call from app.dart when locale changes.
void setUseArabicDigits(bool value) {
  _useArabicDigits = value;
}

/// Convert Western digits 0-9 to Arabic-Indic ٠-٩.
String _toArabicDigits(String input) {
  const western = '0123456789';
  const arabic  = '٠١٢٣٤٥٦٧٨٩';
  final buf = StringBuffer();
  for (final ch in input.codeUnits) {
    final idx = western.codeUnitAt(0);
    if (ch >= idx && ch <= idx + 9) {
      buf.writeCharCode(arabic.codeUnitAt(ch - idx));
    } else {
      buf.writeCharCode(ch);
    }
  }
  return buf.toString();
}

/// Format a plain number (no currency symbol) respecting user's separator prefs.
/// Useful for exchange rates, percentages, and converted amounts.
/// Handles negative values with the user's preferred negative format.
String formatNumber(double value, {int decimals = 2}) {
  final formatted = _formatNumber(value.abs(), decimals);
  return _wrapNegative(formatted, value < 0);
}

/// Wrap a formatted amount string with the negative indicator.
String _wrapNegative(String inner, bool isNeg) {
  if (!isNeg) return inner;
  return switch (_numberFormat.negative) {
    NegativeFormat.minus => '-$inner',
    NegativeFormat.parentheses => '($inner)',
  };
}

/// Known zero-decimal currencies (ISO 4217).
const _zeroDecimalCurrencies = <String>{
  'BIF', 'CLP', 'DJF', 'GNF', 'ISK', 'JPY', 'KMF', 'KRW',
  'PYG', 'RWF', 'UGX', 'UYI', 'VND', 'VUV', 'XAF', 'XOF', 'XPF',
};

/// Known three-decimal currencies (ISO 4217).
const _threeDecimalCurrencies = <String>{
  'BHD', 'IQD', 'JOD', 'KWD', 'LYD', 'OMR', 'TND',
};

/// Resolve the number of decimal places for a currency.
/// Returns [accountDecimals] if set, otherwise uses ISO 4217 defaults.
int currencyDecimals(String? currency, [int? accountDecimals]) {
  if (accountDecimals != null) return accountDecimals;
  if (currency == null) return 2;
  final upper = currency.toUpperCase();
  if (_zeroDecimalCurrencies.contains(upper)) return 0;
  if (_threeDecimalCurrencies.contains(upper)) return 3;
  return 2;
}

/// Format a number with separators and optional currency symbol.
///
/// Respects user preferences for thousands separator, decimal separator,
/// and negative format. If [decimals] is null, auto-detects from currency.
String formatAmount(double value, {String? currency, int? decimals}) {
  final isNeg = value < 0;
  final absValue = value.abs();

  // Auto-detect decimals from currency if not explicitly set
  final decimalDigits = decimals ?? currencyDecimals(currency);

  final formatted = _formatNumber(absValue, decimalDigits);

  if (currency != null) {
    final symbol = _resolveSymbol(currency);
    if (symbol != null) {
      if (_needsSpace(symbol)) {
        // Spaced symbols: "LBP -1,200,000" (sign after symbol)
        return '$symbol ${_wrapNegative(formatted, isNeg)}';
      }
      // Tight symbols: "-$1,200" (sign before symbol)
      return _wrapNegative('$symbol$formatted', isNeg);
    }
    // Code fallback: "USD -1,200" (sign after code)
    return '$currency ${_wrapNegative(formatted, isNeg)}';
  }
  return _wrapNegative(formatted, isNeg);
}

/// Format with an explicit sign prefix: +$1,234 or -$1,234.
/// Expenses display as negative using the user's negative format preference.
String formatSignedAmount(
  double value, {
  required String currency,
  required String type,
}) {
  final absValue = value.abs();
  final isExpense = type == 'expense';
  final isIncome = type == 'income';
  final symbol = _resolveSymbol(currency);

  final decimalDigits = currencyDecimals(currency);
  final formatted = _formatNumber(absValue, decimalDigits);

  String applySign(String inner) {
    if (isExpense) return _wrapNegative(inner, true);
    if (isIncome) return '+$inner';
    return inner;
  }

  if (symbol != null) {
    if (_needsSpace(symbol)) {
      return '$symbol ${applySign(formatted)}';
    }
    return applySign('$symbol$formatted');
  }
  return '$currency ${applySign(formatted)}';
}

/// Format a number for display in calculator/input fields.
/// Always uses the user's preferred separators.
String formatForDisplay(double value) {
  if (value == 0) return '0';
  final hasDecimals = value % 1 != 0;
  final decimalDigits = hasDecimals ? 2 : 0;
  return _formatNumber(value, decimalDigits);
}

/// Check if an exchange rate is real (not the default 1.0 for a foreign currency).
bool isRealRate(String lineCurrency, String baseCurrency, double rate) {
  if (lineCurrency == baseCurrency) return true;
  return (rate - 1.0).abs() >= 0.001;
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
