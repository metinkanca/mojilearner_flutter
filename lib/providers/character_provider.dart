import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../constants/faces.dart';
import '../constants/shop.dart';

class CharacterProvider extends ChangeNotifier {
  CharacterCustomization _customization = CharacterCustomization();
  final Set<String> _unlockedItems = {'apple', 'coffee'};
  int _coins = 100; // Mock coins

  CharacterCustomization get customization => _customization;
  Set<String> get unlockedItems => _unlockedItems;
  int get coins => _coins;

  // Animation state (e.g., idle, talking, thinking)
  String _animationState = 'idle';
  String get animationState => _animationState;

  void setAnimationState(String state) {
    if (_animationState != state) {
      _animationState = state;
      notifyListeners();
    }
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
        // Use the selected closed face for idle sometimes? 
        // For now just return open face or strictly idle if we had one
        return _customization.openFace;
    }
  }

  void updateFace(String openFace, {String? closedFace}) {
    _customization = CharacterCustomization(
      openFace: openFace,
      closedFace: closedFace ?? _customization.closedFace,
      color: _customization.color,
      backgroundColor: _customization.backgroundColor,
    );
    notifyListeners();
  }

  void updateColor(String color) {
    _customization = CharacterCustomization(
      openFace: _customization.openFace,
      closedFace: _customization.closedFace,
      color: color,
      backgroundColor: _customization.backgroundColor,
    );
    notifyListeners();
  }

  void updateBackgroundColor(String color) {
    _customization = CharacterCustomization(
      openFace: _customization.openFace,
      closedFace: _customization.closedFace,
      color: _customization.color,
      backgroundColor: color,
    );
    notifyListeners();
  }

  bool unlockItem(ShopItem item) {
    if (_coins >= item.price) {
      _coins -= item.price;
      _unlockedItems.add(item.id);
      notifyListeners();
      return true;
    }
    return false;
  }
}
