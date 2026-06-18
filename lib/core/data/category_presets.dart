import '../../l10n/generated/app_localizations.dart';

/// Pre-built category packs for quick onboarding.
///
/// Each preset carries an [emoji], which is what gets stored in the category's
/// `icon` column. The emoji is locale-independent, so `CategoryIcon` maps it to
/// a PNG (see `_emojiIconMap` in category_icon.dart) and every language shows
/// the same icon. Keep the emojis here in sync with that map.
class CategoryPreset {
  final String nameKey; // key for i18n lookup
  final String fallbackName; // English fallback if S is unavailable
  final String emoji;
  final String colorHex;
  final String type; // 'expense' | 'income'
  final String? parentKey; // parent's nameKey, null = is a group

  const CategoryPreset({
    required this.nameKey,
    required this.fallbackName,
    required this.emoji,
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
  'income': (s) => s.typeIncome,
  'home': (s) => s.defcatHome,
  'personal': (s) => s.defcatPersonal,
  'education': (s) => s.defcatEducation,
  'travel': (s) => s.defcatTravel,
  'pets': (s) => s.defcatPets,
  'other': (s) => s.defcatOther,
  // Subcategories
  'groceries': (s) => s.defcatGroceries,
  'dining_out': (s) => s.defcatDiningOut,
  'coffee': (s) => s.defcatCoffee,
  'fuel': (s) => s.defcatFuel,
  'public_transit': (s) => s.defcatPublicTransit,
  'parking': (s) => s.defcatParkingTolls,
  'car_maintenance': (s) => s.defcatMaintenance,
  'salary': (s) => s.defcatSalary,
  'freelance': (s) => s.defcatFreelance,
  'investments': (s) => s.defcatInvestments,
  'other_income': (s) => s.defcatOtherIncome,
  'rent': (s) => s.defcatRent,
  'furniture': (s) => s.defcatFurniture,
  'electricity': (s) => s.defcatElectricity,
  'water': (s) => s.defcatWater,
  'internet': (s) => s.defcatInternet,
  'phone': (s) => s.defcatPhone,
  'subscriptions': (s) => s.defcatSubscriptions,
  'insurance': (s) => s.defcatInsurance,
  'haircut': (s) => s.defcatHaircut,
  'skincare': (s) => s.defcatSkincare,
  'clothing': (s) => s.defcatClothing,
  'electronics': (s) => s.defcatElectronics,
  'gifts': (s) => s.defcatGifts,
  'gym': (s) => s.defcatGym,
  'pharmacy': (s) => s.defcatPharmacy,
  'movies': (s) => s.defcatMovies,
  'games': (s) => s.defcatGames,
  'books': (s) => s.defcatBooks,
  'hotels': (s) => s.defcatHotels,
  'flights': (s) => s.defcatFlights,
};

// Group colors — each group has a UNIQUE color so reports/charts never show
// two groups in the same color. Subcategories inherit their parent's color.
const _cFood = '#EF4444'; // red
const _cTransport = '#F97316'; // orange
const _cShopping = '#EC4899'; // pink
const _cBills = '#8B5CF6'; // purple
const _cHealth = '#06B6D4'; // cyan
const _cEntertainment = '#F59E0B'; // amber
const _cIncome = '#10B981'; // green
const _cHome = '#6366F1'; // indigo
const _cPersonal = '#14B8A6'; // teal
const _cEducation = '#3B82F6'; // blue
const _cTravel = '#84CC16'; // lime
const _cPets = '#A855F7'; // violet
const _cOther = '#64748B'; // slate

const essentialPresets = [
  // Groups
  CategoryPreset(nameKey: 'food_drink', fallbackName: 'Food & Drink', emoji: '🍕', colorHex: _cFood),
  CategoryPreset(nameKey: 'transport', fallbackName: 'Transport', emoji: '🚗', colorHex: _cTransport),
  CategoryPreset(nameKey: 'shopping', fallbackName: 'Shopping', emoji: '🛍️', colorHex: _cShopping),
  CategoryPreset(nameKey: 'bills', fallbackName: 'Bills', emoji: '💡', colorHex: _cBills),
  CategoryPreset(nameKey: 'health', fallbackName: 'Health', emoji: '🏥', colorHex: _cHealth),
  CategoryPreset(nameKey: 'entertainment', fallbackName: 'Entertainment', emoji: '🎬', colorHex: _cEntertainment),
  CategoryPreset(nameKey: 'income', fallbackName: 'Income', emoji: '💰', colorHex: _cIncome, type: 'income'),
  // Subcategories
  CategoryPreset(nameKey: 'groceries', fallbackName: 'Groceries', emoji: '🛒', colorHex: _cFood, parentKey: 'food_drink'),
  CategoryPreset(nameKey: 'dining_out', fallbackName: 'Dining Out', emoji: '🍽️', colorHex: _cFood, parentKey: 'food_drink'),
  CategoryPreset(nameKey: 'coffee', fallbackName: 'Coffee', emoji: '☕', colorHex: _cFood, parentKey: 'food_drink'),
  CategoryPreset(nameKey: 'fuel', fallbackName: 'Fuel', emoji: '⛽', colorHex: _cTransport, parentKey: 'transport'),
  CategoryPreset(nameKey: 'public_transit', fallbackName: 'Public Transit', emoji: '🚌', colorHex: _cTransport, parentKey: 'transport'),
  CategoryPreset(nameKey: 'salary', fallbackName: 'Salary', emoji: '💵', colorHex: _cIncome, type: 'income', parentKey: 'income'),
  CategoryPreset(nameKey: 'freelance', fallbackName: 'Freelance', emoji: '💻', colorHex: _cIncome, type: 'income', parentKey: 'income'),
];

const detailedPresets = [
  // All essential groups + more
  ...essentialPresets,
  // Extra groups
  CategoryPreset(nameKey: 'home', fallbackName: 'Home', emoji: '🏠', colorHex: _cHome),
  CategoryPreset(nameKey: 'personal', fallbackName: 'Personal', emoji: '👤', colorHex: _cPersonal),
  CategoryPreset(nameKey: 'education', fallbackName: 'Education', emoji: '🎓', colorHex: _cEducation),
  CategoryPreset(nameKey: 'travel', fallbackName: 'Travel', emoji: '✈️', colorHex: _cTravel),
  CategoryPreset(nameKey: 'pets', fallbackName: 'Pets', emoji: '🐾', colorHex: _cPets),
  CategoryPreset(nameKey: 'other', fallbackName: 'Other', emoji: '📦', colorHex: _cOther),
  // Extra subcategories
  CategoryPreset(nameKey: 'parking', fallbackName: 'Parking & Tolls', emoji: '🅿️', colorHex: _cTransport, parentKey: 'transport'),
  CategoryPreset(nameKey: 'car_maintenance', fallbackName: 'Maintenance', emoji: '🔧', colorHex: _cTransport, parentKey: 'transport'),
  CategoryPreset(nameKey: 'rent', fallbackName: 'Rent', emoji: '🔑', colorHex: _cHome, parentKey: 'home'),
  CategoryPreset(nameKey: 'furniture', fallbackName: 'Furniture', emoji: '🛋️', colorHex: _cHome, parentKey: 'home'),
  CategoryPreset(nameKey: 'electricity', fallbackName: 'Electricity', emoji: '⚡', colorHex: _cBills, parentKey: 'bills'),
  CategoryPreset(nameKey: 'water', fallbackName: 'Water', emoji: '💧', colorHex: _cBills, parentKey: 'bills'),
  CategoryPreset(nameKey: 'internet', fallbackName: 'Internet', emoji: '📶', colorHex: _cBills, parentKey: 'bills'),
  CategoryPreset(nameKey: 'phone', fallbackName: 'Phone', emoji: '📱', colorHex: _cBills, parentKey: 'bills'),
  CategoryPreset(nameKey: 'subscriptions', fallbackName: 'Subscriptions', emoji: '📺', colorHex: _cBills, parentKey: 'bills'),
  CategoryPreset(nameKey: 'insurance', fallbackName: 'Insurance', emoji: '🛡️', colorHex: _cBills, parentKey: 'bills'),
  CategoryPreset(nameKey: 'haircut', fallbackName: 'Haircut', emoji: '💇', colorHex: _cPersonal, parentKey: 'personal'),
  CategoryPreset(nameKey: 'skincare', fallbackName: 'Skincare', emoji: '🧴', colorHex: _cPersonal, parentKey: 'personal'),
  CategoryPreset(nameKey: 'clothing', fallbackName: 'Clothing', emoji: '👕', colorHex: _cShopping, parentKey: 'shopping'),
  CategoryPreset(nameKey: 'electronics', fallbackName: 'Electronics', emoji: '🖥️', colorHex: _cShopping, parentKey: 'shopping'),
  CategoryPreset(nameKey: 'gifts', fallbackName: 'Gifts', emoji: '🎁', colorHex: _cShopping, parentKey: 'shopping'),
  CategoryPreset(nameKey: 'gym', fallbackName: 'Gym', emoji: '🏋️', colorHex: _cHealth, parentKey: 'health'),
  CategoryPreset(nameKey: 'pharmacy', fallbackName: 'Pharmacy', emoji: '💊', colorHex: _cHealth, parentKey: 'health'),
  CategoryPreset(nameKey: 'movies', fallbackName: 'Movies', emoji: '🍿', colorHex: _cEntertainment, parentKey: 'entertainment'),
  CategoryPreset(nameKey: 'games', fallbackName: 'Games', emoji: '🎮', colorHex: _cEntertainment, parentKey: 'entertainment'),
  CategoryPreset(nameKey: 'books', fallbackName: 'Books', emoji: '📚', colorHex: _cEducation, parentKey: 'education'),
  CategoryPreset(nameKey: 'hotels', fallbackName: 'Hotels', emoji: '🏨', colorHex: _cTravel, parentKey: 'travel'),
  CategoryPreset(nameKey: 'flights', fallbackName: 'Flights', emoji: '🛫', colorHex: _cTravel, parentKey: 'travel'),
  CategoryPreset(nameKey: 'investments', fallbackName: 'Investments', emoji: '📈', colorHex: _cIncome, type: 'income', parentKey: 'income'),
  CategoryPreset(nameKey: 'other_income', fallbackName: 'Other Income', emoji: '🪙', colorHex: _cIncome, type: 'income', parentKey: 'income'),
];
