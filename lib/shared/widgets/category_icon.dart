import 'package:flutter/material.dart';

/// Maps common category names to their Cashew PNG icon filenames.
/// Falls back to emoji if no matching icon found.
const _categoryIconMap = <String, String>{
  'groceries': 'groceries.png',
  'dining': 'cutlery.png',
  'restaurants': 'cutlery.png',
  'food': 'fast-food.png',
  'coffee': 'coffee-cup.png',
  'shopping': 'shopping.png',
  'clothes': 'dress.png',
  'entertainment': 'tickets.png',
  'movies': 'tickets.png',
  'transit': 'tram.png',
  'transport': 'tram.png',
  'uber': 'taxi(1).png',
  'taxi': 'taxi(1).png',
  'fuel': 'fuel.png',
  'gas': 'gas-station.png',
  'bills': 'bills.png',
  'utilities': 'lightning-bolt.png',
  'electricity': 'lightning-bolt.png',
  'water': 'water-tap.png',
  'internet': 'wifi.png',
  'phone': 'smartphone.png',
  'rent': 'rent.png',
  'mortgage': 'house.png',
  'home': 'house.png',
  'insurance': 'padlock.png',
  'health': 'healthcare-and-medical.png',
  'medical': 'healthcare-and-medical.png',
  'pharmacy': 'multivitamin.png',
  'gym': 'weight.png',
  'fitness': 'weight.png',
  'beauty': 'makeup.png',
  'haircut': 'haircut.png',
  'spa': 'skincare.png',
  'gifts': 'gift.png',
  'travel': 'plane.png',
  'vacation': 'beach-umbrella.png',
  'hotel': 'cottage.png',
  'education': 'graduation.png',
  'books': 'open-book.png',
  'subscriptions': 'subscription.png',
  'streaming': 'media-content.png',
  'music': 'music.png',
  'games': 'gamepad.png',
  'pets': 'pet-bowl.png',
  'cat': 'cat.png',
  'dog': 'dog.png',
  'kids': 'teddy-bear.png',
  'baby': 'feeding-bottle.png',
  'salary': 'money-bag.png',
  'income': 'increase.png',
  'freelance': 'laptop.png',
  'investment': 'investment.png',
  'savings': 'piggy-bank.png',
  'work': 'briefcase.png',
  'office': 'clipboard.png',
  'car': 'car.png',
  'maintenance': 'gears.png',
  'parking': 'parking.png',
  'laundry': 'washing-machine.png',
  'cleaning': 'cleaning.png',
  'furniture': 'furniture.png',
  'electronics': 'desktop-computer.png',
  'personal care': 'skincare.png',
  'hobbies': 'color-palette.png',
  'sports': 'sports.png',
  'charity': 'heart.png',
  'donation': 'heart.png',
  'taxes': 'calculator.png',
  'fees': 'paper-bill.png',
  'bank': 'bank.png',
  'atm': 'atm-machine(1).png',
  'transfer': 'exchange-arrows.png',
  'other': 'folder.png',
  'misc': 'box.png',
};

/// Maps a category's stored emoji directly to a PNG icon. This is
/// locale-independent (the emoji is the same regardless of the user's
/// language), so Arabic/French users get the same icons as English users —
/// unlike [_categoryIconMap], which matches the (translated) category name.
/// Keys are the emojis used by the onboarding presets (category_presets.dart).
const _emojiIconMap = <String, String>{
  '🍕': 'fast-food.png',
  '🛒': 'groceries.png',
  '🍽': 'cutlery.png',
  '☕': 'coffee-cup.png',
  '🚗': 'car.png',
  '⛽': 'fuel.png',
  '🚌': 'tram.png',
  '🅿': 'parking.png',
  '🔧': 'gears.png',
  '🛍': 'shopping.png',
  '👕': 'tshirt.png',
  '🖥': 'desktop-computer.png',
  '🎁': 'gift.png',
  '💡': 'bills.png',
  '⚡': 'lightning-bolt.png',
  '💧': 'water-tap.png',
  '📶': 'wifi.png',
  '📱': 'smartphone.png',
  '📺': 'subscription.png',
  '🛡': 'padlock.png',
  '🏥': 'healthcare-and-medical.png',
  '🏋': 'weight.png',
  '💊': 'multivitamin.png',
  '🎬': 'tickets.png',
  '🍿': 'tickets.png',
  '🎮': 'gamepad.png',
  '💰': 'money-bag.png',
  '💵': 'money-bag.png',
  '💻': 'laptop.png',
  '📈': 'investment.png',
  '🪙': 'increase.png',
  '🏠': 'house.png',
  '🔑': 'rent.png',
  '🛋': 'furniture.png',
  '👤': 'user.png',
  '💇': 'haircut.png',
  '🧴': 'skincare.png',
  '🎓': 'graduation.png',
  '📚': 'open-book.png',
  '✈': 'plane.png',
  '🏨': 'cottage.png',
  '🛫': 'plane.png',
  '🐾': 'pet-bowl.png',
  '📦': 'box.png',
};

/// Widget that displays a category icon from the Cashew icon pack.
/// Falls back to emoji or generic icon.
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
    String? pngFile;

    // 1. Locale-independent: map the stored emoji straight to a PNG. Strip
    //    the U+FE0F variation selector so '✈️' and '✈' both match.
    final em = emoji;
    if (em != null && em.isNotEmpty) {
      pngFile = _emojiIconMap[em] ??
          _emojiIconMap[em.replaceAll('\u{FE0F}', '')];
    }

    // 2. Fallback: match the (possibly translated) name against English keywords.
    if (pngFile == null) {
      final lowerName = categoryName.toLowerCase();
      for (final entry in _categoryIconMap.entries) {
        if (lowerName.contains(entry.key)) {
          pngFile = entry.value;
          break;
        }
      }
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: circular ? null : BorderRadius.circular(size * 0.28),
        shape: circular ? BoxShape.circle : BoxShape.rectangle,
      ),
      child: Center(
        child: pngFile != null
            ? Image.asset(
                'assets/categories/$pngFile',
                width: size * 0.55,
                height: size * 0.55,
                errorBuilder: (_, __, ___) => _fallback(),
              )
            : _fallback(),
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

  Widget _fallback() {
    if (_isEmoji(emoji)) {
      return Text(emoji!, style: TextStyle(fontSize: size * 0.45));
    }
    return Text(
      categoryName.isNotEmpty ? categoryName[0].toUpperCase() : '?',
      style: TextStyle(
        color: color,
        fontSize: size * 0.4,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
