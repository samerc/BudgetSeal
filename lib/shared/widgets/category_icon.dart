import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Emoji with a Microsoft Fluent Emoji (Flat, MIT) PNG in
/// `assets/categories/`, named by code points without U+FE0F
/// (`1f6d2.png` = 🛒). Covers the onboarding presets and both icon pickers;
/// any other emoji falls back to the system font.
const _fluentEmoji = <String>{
  '1f17f', '1f32e', '1f331', '1f354', '1f355', '1f357', '1f35c', '1f35e',
  '1f363', '1f369', '1f370', '1f377', '1f37a', '1f37c', '1f37d', '1f37f',
  '1f381', '1f382', '1f389', '1f392', '1f393', '1f3a2', '1f3a3', '1f3a4',
  '1f3a7', '1f3a8', '1f3aa', '1f3ac', '1f3ad', '1f3ae', '1f3af', '1f3b2',
  '1f3b5', '1f3ca', '1f3cb', '1f3cd', '1f3d4', '1f3d6', '1f3d7', '1f3e0',
  '1f3e1', '1f3e2', '1f3e5', '1f3e6', '1f3e7', '1f3e8', '1f3eb', '1f3f7',
  '1f408', '1f415', '1f437', '1f43e', '1f453', '1f455', '1f457', '1f45c',
  '1f45f', '1f464', '1f476', '1f484', '1f487', '1f489', '1f48a', '1f48e',
  '1f4a1', '1f4a7', '1f4b0', '1f4b2', '1f4b3', '1f4b5', '1f4b8', '1f4bb',
  '1f4bc', '1f4c8', '1f4ca', '1f4cc', '1f4d0', '1f4d1', '1f4da', '1f4dd',
  '1f4e1', '1f4e6', '1f4f1', '1f4f6', '1f4f7', '1f4fa', '1f501', '1f50c',
  '1f511', '1f516', '1f527', '1f52c', '1f576', '1f5a5', '1f5a8', '1f5c2',
  '1f5fa', '1f64f', '1f680', '1f681', '1f686', '1f687', '1f68c', '1f695',
  '1f697', '1f6b2', '1f6b4', '1f6cb', '1f6cd', '1f6cf', '1f6d2', '1f6de',
  '1f6e1', '1f6eb', '1f6f3', '1f91d', '1f950', '1f957', '1f961', '1f964',
  '1f966', '1f9b7', '1f9c1', '1f9c3', '1f9d2', '1f9d8', '1f9f3', '1f9f4',
  '1f9f8', '1f9f9', '1f9fa', '1f9fe', '1fa79', '1fa7a', '1fa91', '1fa99',
  '2615', '267b', '26a1', '26bd', '26f7', '26fa', '26fd', '2708', '270f',
  '2764', '2b50',
};

/// Category names (English keywords, longest first so "personal care" wins
/// over "car") → emoji, for categories whose own emoji has no Fluent PNG.
const _keywordEmoji = <String, String>{
  'personal care': '🧴',
  'groceries': '🛒',
  'restaurants': '🍽',
  'subscriptions': '📺',
  'entertainment': '🎬',
  'electronics': '🖥',
  'maintenance': '🔧',
  'electricity': '⚡',
  'investment': '📈',
  'streaming': '📺',
  'education': '🎓',
  'utilities': '💡',
  'insurance': '🛡',
  'furniture': '🛋',
  'transport': '🚌',
  'freelance': '💻',
  'pharmacy': '💊',
  'mortgage': '🏠',
  'cleaning': '🧹',
  'vacation': '🏖',
  'internet': '📶',
  'donation': '❤',
  'shopping': '🛍',
  'charity': '❤',
  'clothes': '👕',
  'transit': '🚌',
  'medical': '🩺',
  'fitness': '🏋',
  'haircut': '💇',
  'laundry': '🧺',
  'hobbies': '🎨',
  'parking': '🅿',
  'savings': '🐷',
  'transfer': '🔁',
  'dining': '🍽',
  'coffee': '☕',
  'movies': '🎬',
  'health': '🏥',
  'beauty': '💄',
  'travel': '✈',
  'salary': '💰',
  'income': '💵',
  'office': '🏢',
  'sports': '⚽',
  'taxes': '🧾',
  'bills': '🧾',
  'water': '💧',
  'phone': '📱',
  'hotel': '🏨',
  'books': '📚',
  'music': '🎵',
  'games': '🎮',
  'gifts': '🎁',
  'other': '📦',
  'misc': '📦',
  'food': '🍔',
  'uber': '🚕',
  'taxi': '🚕',
  'fuel': '⛽',
  'rent': '🔑',
  'home': '🏠',
  'gym': '🏋',
  'spa': '🧴',
  'pets': '🐾',
  'kids': '🧸',
  'baby': '🍼',
  'work': '💼',
  'fees': '🧾',
  'bank': '🏦',
  'atm': '🏧',
  'cat': '🐈',
  'dog': '🐕',
  'car': '🚗',
  'gas': '⛽',
};

/// The asset name for [emoji] (`1f6d2.png`), or null when it isn't bundled.
String? _fluentFile(String emoji) {
  final key = emoji.runes
      .where((r) => r != 0xFE0F)
      .map((r) => r.toRadixString(16))
      .join('-');
  return _fluentEmoji.contains(key) ? '$key.png' : null;
}

/// One emoji drawn as its Fluent PNG when bundled, else as text. Use this
/// wherever a category/envelope/goal emoji is shown, so icons look the same
/// on every device. [size] is the glyph's box in logical pixels.
class EmojiGlyph extends StatelessWidget {
  final String emoji;
  final double size;

  const EmojiGlyph(this.emoji, {super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    final file = _fluentFile(emoji);
    if (file == null) {
      return Text(emoji, style: TextStyle(fontSize: size * 0.85, height: 1.15));
    }
    return Image.asset('assets/categories/$file', width: size, height: size);
  }
}

/// The PNG (in `assets/categories/`) drawn for a category, or null when it
/// falls back to its emoji or first letter. Also used by the Web Companion.
String? categoryIconFile(String categoryName, String? emoji) {
  // 1. The category's own emoji (locale-independent).
  if (emoji != null && emoji.isNotEmpty) {
    final file = _fluentFile(emoji);
    if (file != null) return file;
  }
  // 2. Fallback: match the (possibly translated) name against English keywords.
  // A keyword must start a word: "cat" inside "Uncategorized" or
  // "Education", "rent" inside "Parents" or "atm" inside "Treatment" isn't one.
  final lowerName = categoryName.toLowerCase();
  for (final entry in _keywordEmoji.entries) {
    if (RegExp('(^|[^a-z])${entry.key}').hasMatch(lowerName)) {
      return _fluentFile(entry.value);
    }
  }
  return null;
}

/// Widget that displays a category icon (Fluent Emoji PNG).
/// Falls back to the system emoji or the first letter.
class CategoryIcon extends StatelessWidget {
  final String categoryName;
  final String? emoji;
  final Color color;
  final double size;
  final bool circular;

  const CategoryIcon({
    super.key,
    required this.categoryName,
    this.emoji,
    required this.color,
    this.size = 56,
    this.circular = false,
  });

  @override
  Widget build(BuildContext context) {
    final pngFile = categoryIconFile(categoryName, emoji);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        // Cashew: solid pastel of the category color, not a faint tint.
        color: AppColors.pastel(context, color, light: 0.55, dark: 0.35),
        borderRadius: circular ? null : BorderRadius.circular(size * 0.28),
        shape: circular ? BoxShape.circle : BoxShape.rectangle,
      ),
      child: Center(
        child: pngFile != null
            ? Image.asset(
                'assets/categories/$pngFile',
                width: size * 0.57,
                height: size * 0.57,
                errorBuilder: (_, __, ___) => _fallback(context),
              )
            : _fallback(context),
      ),
    );
  }

  /// Check if a string is likely an emoji (short, non-ASCII).
  static bool _isEmoji(String? s) {
    if (s == null || s.isEmpty || s == 'category') return false;
    // Emojis are typically 1-2 characters (up to 4 UTF-16 code units)
    // and contain non-ASCII codepoints.
    return s.length <= 4 && s.codeUnits.any((c) => c > 127);
  }

  Widget _fallback(BuildContext context) {
    if (_isEmoji(emoji)) {
      return Text(emoji!, style: TextStyle(fontSize: size * 0.48));
    }
    return Text(
      categoryName.isNotEmpty ? categoryName[0].toUpperCase() : '?',
      style: TextStyle(
        color: AppColors.pastel(context, color,
            light: 0.6, dark: 0.5, inverse: true),
        fontSize: size * 0.4,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
