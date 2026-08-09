class ShopItem {
  final String id;
  final String type; // 'food' | 'accessory' | 'background'
  final String name;
  final int price;
  final String description;
  final String icon; // Emoji character
  final int? hungerRestore;
  final int? happinessRestore;

  /// Direct health restore. Food only nudges health back up as a side effect
  /// of keeping the pet fed and happy; medicine is the deliberate cure.
  final int? healthRestore;
  final String? value; // Hex code for background, or style ID for accessory

  const ShopItem({
    required this.id,
    required this.type,
    required this.name,
    required this.price,
    required this.description,
    required this.icon,
    this.hungerRestore,
    this.happinessRestore,
    this.healthRestore,
    this.value,
  });
}

const List<ShopItem> shopItems = [
  // FOOD
  ShopItem(id: 'apple', type: 'food', name: 'Apple', price: 5, description: 'A healthy snack.', icon: '🍎', hungerRestore: 10, happinessRestore: 2),
  ShopItem(id: 'croissant', type: 'food', name: 'Croissant', price: 12, description: 'Buttery goodness.', icon: '🥐', hungerRestore: 20, happinessRestore: 5),
  ShopItem(id: 'pizza', type: 'food', name: 'Pizza Slice', price: 25, description: 'Cheesy and filling.', icon: '🍕', hungerRestore: 40, happinessRestore: 10),
  ShopItem(id: 'sushi', type: 'food', name: 'Sushi Set', price: 50, description: 'Premium fish.', icon: '🍱', hungerRestore: 60, happinessRestore: 20),

  // DRINKS
  ShopItem(id: 'coffee', type: 'food', name: 'Espresso', price: 8, description: 'Quick energy boost.', icon: '☕', hungerRestore: 5, happinessRestore: 5),

  // MEDICINE — the cure for a neglected pet. Priced as a real setback (about
  // a day of quiz income) so letting health fall actually costs the player.
  ShopItem(id: 'medicine', type: 'food', name: 'Medicine', price: 40, description: 'Nurses Moji back to health.', icon: '💊', happinessRestore: 5, healthRestore: 50),

  // BACKGROUNDS
  ShopItem(id: 'bg_blue', type: 'background', name: 'Ocean Blue', price: 100, description: 'Calming blue vibes.', icon: '🌊', value: '#1e3a8a'),
  ShopItem(id: 'bg_forest', type: 'background', name: 'Forest Green', price: 100, description: 'Natural feeling.', icon: '🌲', value: '#14532d'),
  ShopItem(id: 'bg_sunset', type: 'background', name: 'Sunset Orange', price: 150, description: 'Warm and cozy.', icon: '🌇', value: '#EA580C'),
  ShopItem(id: 'bg_galaxy', type: 'background', name: 'Galaxy Purple', price: 200, description: 'Out of this world.', icon: '🌌', value: '#4c1d95'),
];
