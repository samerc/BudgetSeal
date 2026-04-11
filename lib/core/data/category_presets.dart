/// Pre-built category packs for quick onboarding.
class CategoryPreset {
  final String name;
  final String emoji;
  final String iconFile; // Cashew PNG filename
  final String colorHex;
  final String type; // 'expense' | 'income'
  final String? parentName; // group name, null = is a group

  const CategoryPreset({
    required this.name,
    required this.emoji,
    required this.iconFile,
    required this.colorHex,
    this.type = 'expense',
    this.parentName,
  });
}

const essentialPresets = [
  // Groups
  CategoryPreset(name: 'Food & Drink', emoji: '🍕', iconFile: 'fast-food.png', colorHex: '#EF4444'),
  CategoryPreset(name: 'Transport', emoji: '🚗', iconFile: 'car.png', colorHex: '#F97316'),
  CategoryPreset(name: 'Shopping', emoji: '🛒', iconFile: 'shopping.png', colorHex: '#EC4899'),
  CategoryPreset(name: 'Bills', emoji: '💡', iconFile: 'bills.png', colorHex: '#8B5CF6'),
  CategoryPreset(name: 'Health', emoji: '💊', iconFile: 'healthcare-and-medical.png', colorHex: '#10B981'),
  CategoryPreset(name: 'Entertainment', emoji: '🎬', iconFile: 'tickets.png', colorHex: '#F59E0B'),
  CategoryPreset(name: 'Income', emoji: '💰', iconFile: 'money-bag.png', colorHex: '#10B981', type: 'income'),
  // Subcategories
  CategoryPreset(name: 'Groceries', emoji: '🛒', iconFile: 'groceries.png', colorHex: '#EF4444', parentName: 'Food & Drink'),
  CategoryPreset(name: 'Dining Out', emoji: '🍽️', iconFile: 'cutlery.png', colorHex: '#EF4444', parentName: 'Food & Drink'),
  CategoryPreset(name: 'Coffee', emoji: '☕', iconFile: 'coffee-cup.png', colorHex: '#EF4444', parentName: 'Food & Drink'),
  CategoryPreset(name: 'Fuel', emoji: '⛽', iconFile: 'fuel.png', colorHex: '#F97316', parentName: 'Transport'),
  CategoryPreset(name: 'Public Transit', emoji: '🚌', iconFile: 'tram.png', colorHex: '#F97316', parentName: 'Transport'),
  CategoryPreset(name: 'Salary', emoji: '💵', iconFile: 'money-bag.png', colorHex: '#10B981', type: 'income', parentName: 'Income'),
  CategoryPreset(name: 'Freelance', emoji: '💻', iconFile: 'laptop.png', colorHex: '#10B981', type: 'income', parentName: 'Income'),
];

const detailedPresets = [
  // All essential groups + more
  ...essentialPresets,
  // Extra groups
  CategoryPreset(name: 'Home', emoji: '🏠', iconFile: 'house.png', colorHex: '#6366F1'),
  CategoryPreset(name: 'Personal', emoji: '👤', iconFile: 'user.png', colorHex: '#14B8A6'),
  CategoryPreset(name: 'Education', emoji: '🎓', iconFile: 'graduation.png', colorHex: '#3B82F6'),
  CategoryPreset(name: 'Travel', emoji: '✈️', iconFile: 'plane.png', colorHex: '#F59E0B'),
  // Extra subcategories
  CategoryPreset(name: 'Rent', emoji: '🏠', iconFile: 'rent.png', colorHex: '#6366F1', parentName: 'Home'),
  CategoryPreset(name: 'Furniture', emoji: '🛋️', iconFile: 'furniture.png', colorHex: '#6366F1', parentName: 'Home'),
  CategoryPreset(name: 'Electricity', emoji: '⚡', iconFile: 'lightning-bolt.png', colorHex: '#8B5CF6', parentName: 'Bills'),
  CategoryPreset(name: 'Internet', emoji: '📶', iconFile: 'wifi.png', colorHex: '#8B5CF6', parentName: 'Bills'),
  CategoryPreset(name: 'Phone', emoji: '📱', iconFile: 'smartphone.png', colorHex: '#8B5CF6', parentName: 'Bills'),
  CategoryPreset(name: 'Subscriptions', emoji: '📺', iconFile: 'subscription.png', colorHex: '#8B5CF6', parentName: 'Bills'),
  CategoryPreset(name: 'Haircut', emoji: '💇', iconFile: 'haircut.png', colorHex: '#14B8A6', parentName: 'Personal'),
  CategoryPreset(name: 'Skincare', emoji: '🧴', iconFile: 'skincare.png', colorHex: '#14B8A6', parentName: 'Personal'),
  CategoryPreset(name: 'Clothing', emoji: '👕', iconFile: 'tshirt.png', colorHex: '#EC4899', parentName: 'Shopping'),
  CategoryPreset(name: 'Gifts', emoji: '🎁', iconFile: 'gift.png', colorHex: '#EC4899', parentName: 'Shopping'),
  CategoryPreset(name: 'Gym', emoji: '🏋️', iconFile: 'weight.png', colorHex: '#10B981', parentName: 'Health'),
  CategoryPreset(name: 'Pharmacy', emoji: '💊', iconFile: 'multivitamin.png', colorHex: '#10B981', parentName: 'Health'),
  CategoryPreset(name: 'Movies', emoji: '🎬', iconFile: 'tickets.png', colorHex: '#F59E0B', parentName: 'Entertainment'),
  CategoryPreset(name: 'Games', emoji: '🎮', iconFile: 'gamepad.png', colorHex: '#F59E0B', parentName: 'Entertainment'),
  CategoryPreset(name: 'Books', emoji: '📚', iconFile: 'open-book.png', colorHex: '#3B82F6', parentName: 'Education'),
  CategoryPreset(name: 'Hotels', emoji: '🏨', iconFile: 'cottage.png', colorHex: '#F59E0B', parentName: 'Travel'),
  CategoryPreset(name: 'Flights', emoji: '✈️', iconFile: 'plane.png', colorHex: '#F59E0B', parentName: 'Travel'),
];
