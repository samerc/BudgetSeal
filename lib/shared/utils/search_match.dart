// Activity search: accent- and Arabic-insensitive words that must all
// match, plus amount filters (`>50`, `<20`, `>=10`, `<=5`, `=12.5`).

const _latin = {
  'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a', 'æ': 'ae',
  'ç': 'c', 'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e', 'ì': 'i', 'í': 'i',
  'î': 'i', 'ï': 'i', 'ñ': 'n', 'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o',
  'ö': 'o', 'ø': 'o', 'œ': 'oe', 'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u',
  'ý': 'y', 'ÿ': 'y', 'ß': 'ss',
};

const _arabic = {
  'أ': 'ا', 'إ': 'ا', 'آ': 'ا', 'ٱ': 'ا', 'ة': 'ه', 'ى': 'ي', 'ؤ': 'و',
  'ئ': 'ي', 'ک': 'ك', 'ی': 'ي',
};

/// Lowercase, without accents, Arabic diacritics or tatweel, with Arabic
/// letter variants (أ/إ/آ → ا, ة → ه, ى → ي…) and Arabic/Persian digits
/// folded, so "cafe" finds "Café" and "قهوة" finds "قهوه".
String foldForSearch(String s) {
  final out = StringBuffer();
  for (final r in s.toLowerCase().runes) {
    // Tashkeel, superscript alef, tatweel: dropped.
    if ((r >= 0x064B && r <= 0x0652) || r == 0x0670 || r == 0x0640) continue;
    // Arabic-Indic and Persian digits → 0-9.
    if (r >= 0x0660 && r <= 0x0669) {
      out.writeCharCode(0x30 + r - 0x0660);
      continue;
    }
    if (r >= 0x06F0 && r <= 0x06F9) {
      out.writeCharCode(0x30 + r - 0x06F0);
      continue;
    }
    // Combining accents (a decomposed é).
    if (r >= 0x0300 && r <= 0x036F) continue;
    final c = String.fromCharCode(r);
    out.write(_latin[c] ?? _arabic[c] ?? c);
  }
  return out.toString();
}

/// An amount condition from the search box.
class AmountTerm {
  final String op; // '>', '<', '>=', '<=', '='
  final double value;
  const AmountTerm(this.op, this.value);

  bool matches(double amount) {
    final a = amount.abs();
    return switch (op) {
      '>' => a > value,
      '<' => a < value,
      '>=' => a >= value,
      '<=' => a <= value,
      _ => (a - value).abs() < 0.005,
    };
  }
}

/// A parsed search: folded words (all must appear somewhere in the row's
/// text) and amount conditions (all must hold).
class SearchQuery {
  final List<String> words;
  final List<AmountTerm> amounts;
  const SearchQuery(this.words, this.amounts);

  bool get isEmpty => words.isEmpty && amounts.isEmpty;

  static final _amountRe = RegExp(r'^(>=|<=|>|<|=)(\d+(?:[.,]\d+)?)$');

  factory SearchQuery.parse(String input) {
    final words = <String>[];
    final amounts = <AmountTerm>[];
    for (final raw in foldForSearch(input).split(RegExp(r'\s+'))) {
      if (raw.isEmpty) continue;
      final m = _amountRe.firstMatch(raw);
      if (m != null) {
        amounts.add(
            AmountTerm(m[1]!, double.parse(m[2]!.replaceAll(',', '.'))));
      } else {
        words.add(raw);
      }
    }
    return SearchQuery(words, amounts);
  }

  /// [text]: the row's searchable text, already folded (title, notes,
  /// account and category names, amounts as typed). [amount]: the amount in
  /// the row's own currency.
  bool matches(String text, double amount) {
    for (final w in words) {
      if (!text.contains(w)) return false;
    }
    for (final a in amounts) {
      if (!a.matches(amount)) return false;
    }
    return true;
  }
}
