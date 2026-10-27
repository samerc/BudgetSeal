import '../../shared/utils/format_number.dart' show defaultCurrencySymbols, parseLooseAmount;

/// What a shared message, a notification or a scanned receipt says about
/// one payment (roadmap #2, "effortless capture"). Every field is a guess
/// the user confirms in the form.
class CaptureDraft {
  final double? amount;
  final String? currency;

  /// 'expense' or 'income'.
  final String type;

  /// The shop or sender ("at Spinneys", "from Sara").
  final String? merchant;

  /// Last digits of the card or account ("ending 1234").
  final String? card;
  final DateTime? date;

  const CaptureDraft({
    this.amount,
    this.currency,
    this.type = 'expense',
    this.merchant,
    this.card,
    this.date,
  });

  bool get isEmpty => amount == null && merchant == null;
}

/// Symbols and local spellings → currency code. Codes themselves (USD,
/// LBP…) are matched from the app's currency list.
const _symbols = <String, String>{
  r'$': 'USD',
  'US\$': 'USD',
  '€': 'EUR',
  '£': 'GBP',
  '¥': 'JPY',
  '₹': 'INR',
  '₺': 'TRY',
  '₦': 'NGN',
  '₩': 'KRW',
  'R\$': 'BRL',
  'ل.ل': 'LBP',
  'ل.ل.': 'LBP',
  'L.L': 'LBP',
  'L.L.': 'LBP',
  'LL': 'LBP',
  'ج.م': 'EGP',
  'د.إ': 'AED',
  'ر.س': 'SAR',
  'د.أ': 'JOD',
  'ل.س': 'SYP',
  'د.ع': 'IQD',
  'د.م.': 'MAD',
  'د.ت': 'TND',
  'FCFA': 'XOF',
  'CFA': 'XOF',
  'DH': 'MAD',
  'TL': 'TRY',
  'Rs': 'INR',
};

/// Words that say money came in; anything else reads as spending.
final _incomeWords = RegExp(
  r'\b(credited|received|deposit(ed)?|refund(ed)?|salary|incoming|'
  r'cr[ée]dit[ée]?|re[çc]u|virement re[çc]u|remboursement|salaire)\b|'
  r'إيداع|أودع|استلام|استلمت|تم استلام|حوالة واردة|راتب|استرداد|مسترد',
  caseSensitive: false,
);

/// The shop after "at", "chez", "لدى"…, up to where the sentence moves on.
/// (`\b` doesn't work around "à" or Arabic letters, so look around instead.)
final _merchant = RegExp(
  r'(?:(?<![A-Za-z])(?:at|from|to|chez|auprès de)(?![A-Za-z])|@|'
  r'(?<=\s)à(?=\s)|(?<![\u0600-\u06FF])(?:لدى|في|من|إلى)(?![\u0600-\u06FF]))'
  r'\s+([^\n.,;:()]{2,40}?)'
  r'(?=\s+(?:on|le|for|pour|with|avec|using|via|ref|card|carte|ending|'
  r'بطاقة|بتاريخ|في|عبر)(?![A-Za-z\u0600-\u06FF])|'
  r'\s*[\n.,;:()]|\s+\d{1,2}[/.-]\d|\s*$)',
  caseSensitive: false,
);

final _card = RegExp(
  r'(?:ending(?: in)?|ends with|xx+|\*{2,}|card(?: no\.?)?|carte|بطاقة|المنتهية ب)'
  r'\s*[#:]?\s*(\d{4})\b',
  caseSensitive: false,
);

final _date = RegExp(
  r'\b(\d{1,2})[/.-](\d{1,2})[/.-](\d{2,4})\b|\b(\d{4})-(\d{2})-(\d{2})\b');

const _arabicDigits = '٠١٢٣٤٥٦٧٨٩';
const _persianDigits = '۰۱۲۳۴۵۶۷۸۹';

String _westernDigits(String s) {
  final b = StringBuffer();
  for (final ch in s.runes.map(String.fromCharCode)) {
    final a = _arabicDigits.indexOf(ch), p = _persianDigits.indexOf(ch);
    b.write(a >= 0
        ? '$a'
        : p >= 0
            ? '$p'
            : ch == '٫'
                ? '.'
                : ch == '٬'
                    ? ','
                    : ch);
  }
  return b.toString();
}

/// Reads [text] — a bank SMS or notification, a payment app's share, a
/// receipt's text — in any bank's wording (English, French, Arabic): the
/// amount next to a currency, whether it went out or came in, the shop,
/// the card's last digits and a date. [fallbackCurrency] is used when an
/// amount has no currency beside it. Returns what it could find.
CaptureDraft readCapturedText(String text, {String? fallbackCurrency}) {
  final s = _westernDigits(text).replaceAll('\u00a0', ' ');

  // Amounts beside a currency (a code, or a symbol / local spelling).
  final codes = {...defaultCurrencySymbols.keys};
  final tokens = <String, String>{
    for (final c in codes) c: c,
    ..._symbols,
  };
  final tokenAlt = (tokens.keys.toList()..sort((a, b) => b.length - a.length))
      .map(RegExp.escape)
      .join('|');
  const number = r'(\d{1,3}(?:[ ,.\u202f]\d{3})+(?:[.,]\d{1,3})?|\d+(?:[.,]\d{1,3})?)';
  final before = RegExp('(?<![A-Za-z])($tokenAlt)\\s?$number');
  final after = RegExp('$number\\s?($tokenAlt)(?![A-Za-z])');

  double? amount;
  String? currency;
  final found = <(int, double, String)>[];
  for (final m in before.allMatches(s)) {
    final v = parseLooseAmount(m.group(2)!.replaceAll(RegExp(r'[ \u202f]'), ''));
    if (v != null && v > 0) found.add((m.start, v, tokens[m.group(1)!]!));
  }
  for (final m in after.allMatches(s)) {
    final v = parseLooseAmount(m.group(1)!.replaceAll(RegExp(r'[ \u202f]'), ''));
    if (v != null && v > 0) found.add((m.start, v, tokens[m.group(2)!]!));
  }
  found.sort((a, b) => a.$1.compareTo(b.$1));
  // The first one is the payment; later ones are usually the balance.
  if (found.isNotEmpty) {
    amount = found.first.$2;
    currency = found.first.$3;
  } else {
    // A bare amount: the first number with decimals, or after "amount".
    final bare = RegExp(
            r'(?:amount|montant|المبلغ|total)\s*[:=]?\s*' + number,
            caseSensitive: false)
        .firstMatch(s) ??
        RegExp(r'\b(\d{1,3}(?:,\d{3})*\.\d{2}|\d+\.\d{2})\b').firstMatch(s);
    if (bare != null) {
      amount = parseLooseAmount(bare.group(1)!);
      currency = fallbackCurrency;
    }
  }

  final merchantMatch = _merchant.firstMatch(s);
  var merchant = merchantMatch?.group(1)?.trim();
  // "to" / "from" followed by an amount or a card isn't a shop.
  if (merchant != null &&
      (RegExp(r'^\d').hasMatch(merchant) ||
          RegExp(r'\b(card|account|carte|compte)\b|حساب|بطاقة',
                  caseSensitive: false)
              .hasMatch(merchant))) {
    merchant = null;
  }

  DateTime? date;
  final d = _date.firstMatch(s);
  if (d != null) {
    final (y, mo, da) = d.group(4) != null
        ? (int.parse(d.group(4)!), int.parse(d.group(5)!), int.parse(d.group(6)!))
        : (int.parse(d.group(3)!), int.parse(d.group(2)!), int.parse(d.group(1)!));
    final year = y < 100 ? 2000 + y : y;
    if (mo >= 1 && mo <= 12 && da >= 1 && da <= 31) {
      date = DateTime(year, mo, da);
    }
  }

  return CaptureDraft(
    amount: amount,
    currency: currency,
    type: _incomeWords.hasMatch(s) ? 'income' : 'expense',
    merchant: merchant,
    card: _card.firstMatch(s)?.group(1),
    date: date,
  );
}
