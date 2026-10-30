import 'dart:math' as math;

import 'package:intl/intl.dart';

import '../../core/providers/number_format_provider.dart';

/// Currency codes → their native display symbols. Use
/// [defaultCurrencySymbols] (language-aware) for display.
const _nativeCurrencySymbols = <String, String>{
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

final _arabicScript = RegExp(r'[؀-ۿﷰ-﷿]');

/// The default symbol of each currency for the app's language: a symbol in
/// Arabic script (ل.ل, د.إ, ﷼) is only used in Arabic; other languages show
/// the code ("LBP 1,200,000"). Users can still pick any symbol in
/// Settings › Currency symbols.
Map<String, String> get defaultCurrencySymbols {
  final arabic = (Intl.defaultLocale ?? '').startsWith('ar');
  if (arabic) return _nativeCurrencySymbols;
  return {
    for (final e in _nativeCurrencySymbols.entries)
      e.key: _arabicScript.hasMatch(e.value) ? e.key : e.value,
  };
}

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

/// The current amount-format settings, for clients that format amounts
/// themselves (the Web Companion mirrors [formatAmount] in JavaScript).
Map<String, Object> numberFormatSpec() => {
      'thousands': _numberFormat.thousands.char,
      'decimal': _numberFormat.decimal.char,
      'parens': _numberFormat.negative == NegativeFormat.parentheses,
      'arabicDigits': _useArabicDigits,
      'symbols': {...defaultCurrencySymbols, ..._userOverrides},
    };

/// The user's preferred decimal separator ('.' or ','), for display only
/// (e.g. the calculator's decimal key). Parsing always uses '.'.
String get decimalSeparatorChar =>
    _numberFormat.decimal == DecimalSeparator.comma ? ',' : '.';

/// Resolved symbols: user overrides take precedence over defaults.
String? _resolveSymbol(String code) {
  final override = _userOverrides[code];
  if (override != null) return override;
  final native = _nativeCurrencySymbols[code];
  if (native == null) return null;
  // Arabic-script symbols only in Arabic; elsewhere the code.
  if (_arabicScript.hasMatch(native) &&
      !(Intl.defaultLocale ?? '').startsWith('ar')) {
    return code;
  }
  return native;
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
/// A signed amount ("-$450", "+$200", "($5)") reads left to right even
/// inside Arabic text: a leading left-to-right mark keeps the sign in front
/// (without it "-$450.00" renders as "$450.00-"). No-op in LTR locales.
String bidiSafeAmount(String amount) =>
    (Intl.defaultLocale ?? '').startsWith('ar') ? '‎$amount' : amount;

String _wrapNegative(String inner, bool isNeg) {
  if (!isNeg) return inner;
  return switch (_numberFormat.negative) {
    NegativeFormat.minus => '-$inner',
    NegativeFormat.parentheses => '($inner)',
  };
}

/// Zero-decimal currencies: ISO 4217's, plus LBP, SYP, IRR and IQD (their
/// minor units are long gone — prices are whole thousands).
const _zeroDecimalCurrencies = <String>{
  'BIF', 'CLP', 'DJF', 'GNF', 'ISK', 'JPY', 'KMF', 'KRW',
  'PYG', 'RWF', 'UGX', 'UYI', 'VND', 'VUV', 'XAF', 'XOF', 'XPF',
  'LBP', 'SYP', 'IRR', 'IQD',
};

/// Known three-decimal currencies (ISO 4217).
const _threeDecimalCurrencies = <String>{
  'BHD', 'JOD', 'KWD', 'LYD', 'OMR', 'TND',
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
  return isNeg
      ? bidiSafeAmount(_formatAmount(value, currency, decimals))
      : _formatAmount(value, currency, decimals);
}

String _formatAmount(double value, String? currency, int? decimals) {
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

  final String out;
  if (symbol != null) {
    out = _needsSpace(symbol)
        ? '$symbol ${applySign(formatted)}'
        : applySign('$symbol$formatted');
  } else {
    out = '$currency ${applySign(formatted)}';
  }
  return isExpense || isIncome ? bidiSafeAmount(out) : out;
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

/// Arabic-Indic (٠-٩) and Persian (۰-۹) digits as 0-9, the Arabic decimal
/// mark ٫ as '.' and the Arabic thousands mark ٬ as ','. What an Arabic or
/// Persian keyboard types, read like ASCII.
String asciiDigits(String s) {
  final out = StringBuffer();
  for (final r in s.runes) {
    if (r >= 0x0660 && r <= 0x0669) {
      out.writeCharCode(0x30 + r - 0x0660);
    } else if (r >= 0x06F0 && r <= 0x06F9) {
      out.writeCharCode(0x30 + r - 0x06F0);
    } else if (r == 0x066B) {
      out.write('.');
    } else if (r == 0x066C) {
      out.write(',');
    } else {
      out.writeCharCode(r);
    }
  }
  return out.toString();
}

/// [v] rounded to [decimals] places (a currency's minor units).
double roundToDecimals(double v, int decimals) {
  if (!v.isFinite) return v;
  final f = math.pow(10, decimals).toDouble();
  return (v * f).roundToDouble() / f;
}

/// Typed or imported amounts in either convention: `1,234.56`, `1.234,56`, `12,50`,
/// `-5`, `12.50-`, `(5.00)` (negative), with or without a currency symbol or
/// code around it, in ASCII, Arabic-Indic or Persian digits. A lone comma
/// followed by exactly three digits is a thousands separator (`1,234`);
/// otherwise it is the decimal mark. Not an amount (null): no digits, two
/// marks in a row (`1..2`), or anything but digits, marks and spaces between
/// the digits (a date `2026-01-15`, `1/2`, `12abc3`).
double? parseLooseAmount(String raw) {
  final s = asciiDigits(raw).trim();
  final first = s.indexOf(RegExp(r'[0-9]'));
  if (first < 0) return null;
  final last = s.lastIndexOf(RegExp(r'[0-9]'));
  // A mark right before the first digit belongs to the number (".5").
  final coreStart = first > 0 && '.,'.contains(s[first - 1]) ? first - 1 : first;
  final prefix = s.substring(0, coreStart);
  final suffix = s.substring(last + 1);
  var core = s.substring(coreStart, last + 1);
  // Spaces (also no-break) and apostrophes group digits: 1 234, 1'234.
  if (core.contains(RegExp(r"[^0-9.,\s\u00a0\u202f']"))) return null;
  core = core.replaceAll(RegExp(r"[\s\u00a0\u202f']"), '');
  if (core.contains(RegExp(r'[.,]{2,}'))) return null;
  final negative = prefix.contains('-') ||
      prefix.contains('\u2212') ||
      suffix.startsWith('-') ||
      (prefix.contains('(') && suffix.contains(')'));
  final lastComma = core.lastIndexOf(',');
  final lastDot = core.lastIndexOf('.');
  String normalized;
  if (lastComma >= 0 && lastDot >= 0) {
    // Both present: whichever comes last is the decimal mark.
    final dec = lastComma > lastDot ? ',' : '.';
    final thou = dec == ',' ? '.' : ',';
    if (dec.allMatches(core).length > 1) return null; // 1.234.5,6
    normalized = core.replaceAll(thou, '').replaceAll(dec, '.');
  } else if (lastComma >= 0) {
    final commas = ','.allMatches(core).length;
    final decimals = core.length - lastComma - 1;
    normalized = commas == 1 && decimals != 3
        ? core.replaceAll(',', '.')
        : core.replaceAll(',', '');
  } else if ('.'.allMatches(core).length > 1) {
    normalized = core.replaceAll('.', ''); // 1.234.567
  } else {
    normalized = core;
  }
  final v = double.tryParse(normalized);
  if (v == null) return null;
  return negative ? -v : v;
}
