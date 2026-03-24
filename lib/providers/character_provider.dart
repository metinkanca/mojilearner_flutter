import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../constants/faces.dart';
import '../constants/shop.dart';
import '../constants/progression.dart';
import 'user_provider.dart';
import 'dart:async';

class CharacterProvider extends ChangeNotifier {
  CharacterCustomization _customization = CharacterCustomization();
  final Set<String> _unlockedItems = {'apple', 'coffee'};
  final List<String> _inventory = ['apple', 'coffee']; // Owned items
  
  // Pet Stats (0-100)
  int _hunger = 50;
  int _happiness = 70;
  int _health = 100;
  DateTime _lastUpdate = DateTime.now();
  Timer? _decayTimer;
  StreamSubscription<RewardDef>? _rewardSubscription;

  CharacterCustomization get customization => _customization;
  String get currentCharacterType => _customization.characterType;
  String get currentCharacterAsset => 'assets/svgs/${_customization.characterType}.svg';
  Set<String> get unlockedItems => _unlockedItems;
  List<String> get inventory => _inventory;
  
  // Pet state getters
  int get hunger => _hunger;
  int get happiness => _happiness;
  int get health => _health;
  
  // Pet mood based on stats
  String get mood {
    if (_health < 30) return 'sick';
    if (_hunger > 80) return 'starving';
    if (_happiness < 30) return 'sad';
    if (_happiness > 80 && _hunger < 30) return 'happy';
    return 'neutral';
  }

  // Animation state (e.g., idle, talking, thinking)
  String _animationState = 'idle';
  String get animationState => _animationState;

  CharacterProvider() {
    _loadPetState();
    _startDecayTimer();
  }
  
  /// Call this to set up reward subscription from UserProvider
  void subscribeToRewards(UserProvider userProvider) {
    _rewardSubscription?.cancel(); // Cancel if already subscribed
    _rewardSubscription = userProvider.onReward.listen(_handleReward);
  }
  
  void _handleReward(RewardDef reward) {
    if (reward.itemId == null) return;
    
    final quantity = reward.value > 0 ? reward.value : 1;
    
    // Add items to inventory (for food items)
    if (reward.type == RewardType.item) {
      for (int i = 0; i < quantity; i++) {
        _inventory.add(reward.itemId!);
      }
    }
    
    // Add to unlocked items (for backgrounds and cosmetics)
    if (reward.type == RewardType.unlock || reward.type == RewardType.cosmetic) {
      _unlockedItems.add(reward.itemId!);
    }
    
    _savePetState();
    notifyListeners();
  }

  @override
  void dispose() {
    _decayTimer?.cancel();
    _rewardSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadPetState() async {
    final prefs = await SharedPreferences.getInstance();
    _hunger = prefs.getInt('pet_hunger') ?? 50;
    _happiness = prefs.getInt('pet_happiness') ?? 70;
    _health = prefs.getInt('pet_health') ?? 100;
    final lastUpdateMs = prefs.getInt('pet_last_update');
    if (lastUpdateMs != null) {
      _lastUpdate = DateTime.fromMillisecondsSinceEpoch(lastUpdateMs);
      _applyOfflineDecay();
    }
    // Load unlocked items & inventory if present
    final unlocked = prefs.getStringList('unlocked_items');
    if (unlocked != null) {
      _unlockedItems.clear();
      _unlockedItems.addAll(unlocked);
    }
    final inv = prefs.getStringList('inventory');
    if (inv != null) {
      _inventory.clear();
      _inventory.addAll(inv);
    }

    final savedCharacterType = prefs.getString('character_type') ?? 'cat';
    _customization = CharacterCustomization(
      characterType: {'dog', 'cat', 'bird'}.contains(savedCharacterType)
          ? savedCharacterType
          : 'cat',
      openFace: _customization.openFace,
      closedFace: _customization.closedFace,
      color: _customization.color,
      backgroundColor: _customization.backgroundColor,
    );

    notifyListeners();
  }

  Future<void> _savePetState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('pet_hunger', _hunger);
    await prefs.setInt('pet_happiness', _happiness);
    await prefs.setInt('pet_health', _health);
    await prefs.setInt('pet_last_update', _lastUpdate.millisecondsSinceEpoch);
    await prefs.setString('character_type', _customization.characterType);
    // persist unlocked items and inventory
    await prefs.setStringList('unlocked_items', _unlockedItems.toList());
    await prefs.setStringList('inventory', _inventory);
  }

  void _startDecayTimer() {
    _decayTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _applyDecay();
    });
  }

  void _applyOfflineDecay() {
    final elapsed = DateTime.now().difference(_lastUpdate);
    final hours = elapsed.inHours;
    
    if (hours > 0) {
      // Hunger increases by 3 per hour
      _hunger = (_hunger + (hours * 3)).clamp(0, 100);
      // Happiness decreases by 2 per hour
      _happiness = (_happiness - (hours * 2)).clamp(0, 100);
      // Health decreases if hunger or happiness are critical
      if (_hunger > 80 || _happiness < 20) {
        _health = (_health - (hours * 1)).clamp(0, 100);
      }
    }
    _lastUpdate = DateTime.now();
    _savePetState();
  }

  void _applyDecay() {
    final now = DateTime.now();
    final elapsed = now.difference(_lastUpdate);
    
    if (elapsed.inMinutes >= 1) {
      // Every 1 minute = 1/60th of an hour
      final hourFraction = 1 / 60.0;
      _hunger = ((_hunger + 3 * hourFraction).round()).clamp(0, 100);
      _happiness = ((_happiness - 2 * hourFraction).round()).clamp(0, 100);
      
      if (_hunger > 80 || _happiness < 20) {
        _health = (_health - 1).clamp(0, 100);
      }
      
      _lastUpdate = now;
      _savePetState();
      notifyListeners();
    }
  }

  void setAnimationState(String state) {
    if (_animationState != state) {
      _animationState = state;
      notifyListeners();
    }
  }

  // Activity rewards - called when user completes activities
  void rewardChat() {
    _happiness = (_happiness + 5).clamp(0, 100);
    _savePetState();
    notifyListeners();
  }

  void rewardScenario() {
    _happiness = (_happiness + 10).clamp(0, 100);
    _hunger = (_hunger + 5).clamp(0, 100); // Scenarios are tiring!
    _savePetState();
    notifyListeners();
  }

  void rewardQuiz(bool passed) {
    if (passed) {
      _happiness = (_happiness + 15).clamp(0, 100);
    } else {
      _happiness = (_happiness - 5).clamp(0, 100);
    }
    _hunger = (_hunger + 10).clamp(0, 100);
    _savePetState();
    notifyListeners();
  }

  void applyQuizRewards({
    required int happinessDelta,
    required int hungerDelta,
  }) {
    _happiness = (_happiness + happinessDelta).clamp(0, 100);
    _hunger = (_hunger + hungerDelta).clamp(0, 100);
    _savePetState();
    notifyListeners();
  }

  void feedPet(String itemId) {
    final item = shopItems.firstWhere(
      (i) => i.id == itemId,
      orElse: () => shopItems.first,
    );
    
    if (_inventory.contains(itemId)) {
      _hunger = (_hunger - (item.hungerRestore ?? 0)).clamp(0, 100);
      _happiness = (_happiness + (item.happinessRestore ?? 0)).clamp(0, 100);
      
      // Restore health if well-fed and happy
      if (_hunger < 50 && _happiness > 50) {
        _health = (_health + 5).clamp(0, 100);
      }
      
      _inventory.remove(itemId);
      _savePetState();
      notifyListeners();
    }
  }

  void petThePet() {
    _happiness = (_happiness + 8).clamp(0, 100);
    _savePetState();
    notifyListeners();
  }

  String get currentAsciiFace {
    // Simple mapping based on animation state
    switch (_animationState) {
      case 'talking':
        return _customization.openFace;
      case 'thinking':
        return Faces.thinking.first.open;
      case 'happy':
        return Faces.happy.first.open;
      case 'confusion':
         return Faces.confused.first.open;
      default:
        // Check mood before returning customization face
        switch (mood) {
          case 'sick':
            return Faces.confused.first.open;
          case 'starving':
            return Faces.sad.first.open;
          case 'sad':
            return Faces.sad.first.open;
          case 'happy':
            return Faces.happy.first.open;
          case 'neutral':
          default:
            return _customization.openFace;
        }
    }
  }

  void updateFace(String openFace, {String? closedFace}) {
    _customization = CharacterCustomization(
      characterType: _customization.characterType,
      openFace: openFace,
      closedFace: closedFace ?? _customization.closedFace,
      color: _customization.color,
      backgroundColor: _customization.backgroundColor,
    );
    notifyListeners();
  }

  void updateColor(String color) {
    _customization = CharacterCustomization(
      characterType: _customization.characterType,
      openFace: _customization.openFace,
      closedFace: _customization.closedFace,
      color: color,
      backgroundColor: _customization.backgroundColor,
    );
    notifyListeners();
  }

  void updateBackgroundColor(String color) {
    _customization = CharacterCustomization(
      characterType: _customization.characterType,
      openFace: _customization.openFace,
      closedFace: _customization.closedFace,
      color: _customization.color,
      backgroundColor: color,
    );
    notifyListeners();
  }

  Future<void> updateCharacterType(String type) async {
    const validTypes = {'dog', 'cat', 'bird'};
    if (!validTypes.contains(type)) return;

    if (_customization.characterType == type) return;

    _customization = CharacterCustomization(
      characterType: type,
      openFace: _customization.openFace,
      closedFace: _customization.closedFace,
      color: _customization.color,
      backgroundColor: _customization.backgroundColor,
    );
    await _savePetState();
    notifyListeners();
  }

  bool purchaseItem(ShopItem item, int userCoins, {int quantity = 1}) {
    final totalCost = item.price * quantity;
    if (userCoins >= totalCost) {
      _unlockedItems.add(item.id);
      if (item.type == 'food') {
        // Add the item quantity times to inventory
        for (int i = 0; i < quantity; i++) {
          _inventory.add(item.id);
        }
      }
      _savePetState();
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Unlocks an item if the user has enough coins. This will deduct
  /// the cost from the provided [userProvider], persist state and
  /// return true on success.
  Future<bool> unlockItem(ShopItem item, UserProvider userProvider) async {
    if (userProvider.coins >= item.price) {
      // Deduct coins via UserProvider
      await userProvider.spendCoins(item.price);
      _unlockedItems.add(item.id);
      if (item.type == 'food') {
        _inventory.add(item.id);
      }
      await _savePetState();
      notifyListeners();
      return true;
    }
    return false;
  }
}
