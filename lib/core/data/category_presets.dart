import '../../l10n/generated/app_localizations.dart';

/// Pre-built category packs for quick onboarding.
class CategoryPreset {
  final String nameKey; // key for i18n lookup
  final String fallbackName; // English fallback if S is unavailable
  final String emoji;
  final String iconFile; // Cashew PNG filename
  final String colorHex;
  final String type; // 'expense' | 'income'
  final String? parentKey; // parent's nameKey, null = is a group

  const CategoryPreset({
    required this.nameKey,
    required this.fallbackName,
    required this.emoji,
    required this.iconFile,
    required this.colorHex,
    this.type = 'expense',
    this.parentKey,
  });

  /// Resolve translated name from S instance.
  String translatedName(S s) => _resolveKey(s, nameKey) ?? fallbackName;
}

/// Maps nameKey to the corresponding S getter.
String? _resolveKey(S s, String key) {
  return _keyMap[key]?.call(s);
}

final Map<String, String Function(S)> _keyMap = {
  // Groups
  'food_drink': (s) => s.defcatFoodDrink,
  'transport': (s) => s.defcatTransport,
  'shopping': (s) => s.defcatShopping,
  'bills': (s) => s.defcatBills,
  'health': (s) => s.defcatHealth,
  'entertainment': (s) => s.defcatEntertainment,
  'income': (s) => s.defcatIncome,
  'home': (s) => s.defcatHome,
  'personal': (s) => s.defcatPersonal,
  'education': (s) => s.defcatEducation,
  'travel': (s) => s.defcatTravel,
  // Subcategories
  'groceries': (s) => s.defcatGroceries,
  'dining_out': (s) => s.defcatDiningOut,
  'coffee': (s) => s.defcatCoffee,
  'fuel': (s) => s.defcatFuel,
  'public_transit': (s) => s.defcatPublicTransit,
  'salary': (s) => s.defcatSalary,
  'freelance': (s) => s.defcatFreelance,
  'rent': (s) => s.defcatRent,
  'furniture': (s) => s.defcatFurniture,
  'electricity': (s) => s.defcatElectricity,
  'internet': (s) => s.defcatInternet,
  'phone': (s) => s.defcatPhone,
  'subscriptions': (s) => s.defcatSubscriptions,
  'haircut': (s) => s.defcatHaircut,
  'skincare': (s) => s.defcatSkincare,
  'clothing': (s) => s.defcatClothing,
  'gifts': (s) => s.defcatGifts,
  'gym': (s) => s.defcatGym,
  'pharmacy': (s) => s.defcatPharmacy,
  'movies': (s) => s.defcatMovies,
  'games': (s) => s.defcatGames,
  'books': (s) => s.defcatBooks,
  'hotels': (s) => s.defcatHotels,
  'flights': (s) => s.defcatFlights,
};

const essentialPresets = [
  // Groups
  CategoryPreset(nameKey: 'food_drink', fallbackName: 'Food & Drink', emoji: '🍕', iconFile: 'fast-food.png', colorHex: '#EF4444'),
  CategoryPreset(nameKey: 'transport', fallbackName: 'Transport', emoji: '🚗', iconFile: 'car.png', colorHex: '#F97316'),
  CategoryPreset(nameKey: 'shopping', fallbackName: 'Shopping', emoji: '🛒', iconFile: 'shopping.png', colorHex: '#EC4899'),
  CategoryPreset(nameKey: 'bills', fallbackName: 'Bills', emoji: '💡', iconFile: 'bills.png', colorHex: '#8B5CF6'),
  CategoryPreset(nameKey: 'health', fallbackName: 'Health', emoji: '💊', iconFile: 'healthcare-and-medical.png', colorHex: '#10B981'),
  CategoryPreset(nameKey: 'entertainment', fallbackName: 'Entertainment', emoji: '🎬', iconFile: 'tickets.png', colorHex: '#F59E0B'),
  CategoryPreset(nameKey: 'income', fallbackName: 'Income', emoji: '💰', iconFile: 'money-bag.png', colorHex: '#10B981', type: 'income'),
  // Subcategories
  CategoryPreset(nameKey: 'groceries', fallbackName: 'Groceries', emoji: '🛒', iconFile: 'groceries.png', colorHex: '#EF4444', parentKey: 'food_drink'),
  CategoryPreset(nameKey: 'dining_out', fallbackName: 'Dining Out', emoji: '🍽️', iconFile: 'cutlery.png', colorHex: '#EF4444', parentKey: 'food_drink'),
  CategoryPreset(nameKey: 'coffee', fallbackName: 'Coffee', emoji: '☕', iconFile: 'coffee-cup.png', colorHex: '#EF4444', parentKey: 'food_drink'),
  CategoryPreset(nameKey: 'fuel', fallbackName: 'Fuel', emoji: '⛽', iconFile: 'fuel.png', colorHex: '#F97316', parentKey: 'transport'),
  CategoryPreset(nameKey: 'public_transit', fallbackName: 'Public Transit', emoji: '🚌', iconFile: 'tram.png', colorHex: '#F97316', parentKey: 'transport'),
  CategoryPreset(nameKey: 'salary', fallbackName: 'Salary', emoji: '💵', iconFile: 'money-bag.png', colorHex: '#10B981', type: 'income', parentKey: 'income'),
  CategoryPreset(nameKey: 'freelance', fallbackName: 'Freelance', emoji: '💻', iconFile: 'laptop.png', colorHex: '#10B981', type: 'income', parentKey: 'income'),
];

const detailedPresets = [
  // All essential groups + more
  ...essentialPresets,
  // Extra groups
  CategoryPreset(nameKey: 'home', fallbackName: 'Home', emoji: '🏠', iconFile: 'house.png', colorHex: '#6366F1'),
  CategoryPreset(nameKey: 'personal', fallbackName: 'Personal', emoji: '👤', iconFile: 'user.png', colorHex: '#14B8A6'),
  CategoryPreset(nameKey: 'education', fallbackName: 'Education', emoji: '🎓', iconFile: 'graduation.png', colorHex: '#3B82F6'),
  CategoryPreset(nameKey: 'travel', fallbackName: 'Travel', emoji: '✈️', iconFile: 'plane.png', colorHex: '#F59E0B'),
  // Extra subcategories
  CategoryPreset(nameKey: 'rent', fallbackName: 'Rent', emoji: '🏠', iconFile: 'rent.png', colorHex: '#6366F1', parentKey: 'home'),
  CategoryPreset(nameKey: 'furniture', fallbackName: 'Furniture', emoji: '🛋️', iconFile: 'furniture.png', colorHex: '#6366F1', parentKey: 'home'),
  CategoryPreset(nameKey: 'electricity', fallbackName: 'Electricity', emoji: '⚡', iconFile: 'lightning-bolt.png', colorHex: '#8B5CF6', parentKey: 'bills'),
  CategoryPreset(nameKey: 'internet', fallbackName: 'Internet', emoji: '📶', iconFile: 'wifi.png', colorHex: '#8B5CF6', parentKey: 'bills'),
  CategoryPreset(nameKey: 'phone', fallbackName: 'Phone', emoji: '📱', iconFile: 'smartphone.png', colorHex: '#8B5CF6', parentKey: 'bills'),
  CategoryPreset(nameKey: 'subscriptions', fallbackName: 'Subscriptions', emoji: '📺', iconFile: 'subscription.png', colorHex: '#8B5CF6', parentKey: 'bills'),
  CategoryPreset(nameKey: 'haircut', fallbackName: 'Haircut', emoji: '💇', iconFile: 'haircut.png', colorHex: '#14B8A6', parentKey: 'personal'),
  CategoryPreset(nameKey: 'skincare', fallbackName: 'Skincare', emoji: '🧴', iconFile: 'skincare.png', colorHex: '#14B8A6', parentKey: 'personal'),
  CategoryPreset(nameKey: 'clothing', fallbackName: 'Clothing', emoji: '👕', iconFile: 'tshirt.png', colorHex: '#EC4899', parentKey: 'shopping'),
  CategoryPreset(nameKey: 'gifts', fallbackName: 'Gifts', emoji: '🎁', iconFile: 'gift.png', colorHex: '#EC4899', parentKey: 'shopping'),
  CategoryPreset(nameKey: 'gym', fallbackName: 'Gym', emoji: '🏋️', iconFile: 'weight.png', colorHex: '#10B981', parentKey: 'health'),
  CategoryPreset(nameKey: 'pharmacy', fallbackName: 'Pharmacy', emoji: '💊', iconFile: 'multivitamin.png', colorHex: '#10B981', parentKey: 'health'),
  CategoryPreset(nameKey: 'movies', fallbackName: 'Movies', emoji: '🎬', iconFile: 'tickets.png', colorHex: '#F59E0B', parentKey: 'entertainment'),
  CategoryPreset(nameKey: 'games', fallbackName: 'Games', emoji: '🎮', iconFile: 'gamepad.png', colorHex: '#F59E0B', parentKey: 'entertainment'),
  CategoryPreset(nameKey: 'books', fallbackName: 'Books', emoji: '📚', iconFile: 'open-book.png', colorHex: '#3B82F6', parentKey: 'education'),
  CategoryPreset(nameKey: 'hotels', fallbackName: 'Hotels', emoji: '🏨', iconFile: 'cottage.png', colorHex: '#F59E0B', parentKey: 'travel'),
  CategoryPreset(nameKey: 'flights', fallbackName: 'Flights', emoji: '✈️', iconFile: 'plane.png', colorHex: '#F59E0B', parentKey: 'travel'),
];
