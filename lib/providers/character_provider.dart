import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../constants/faces.dart';
import '../constants/shop.dart';
import '../constants/progression.dart';
import '../constants/accessories.dart';
import '../utils/pet_recolor.dart';
import 'user_provider.dart';
import 'dart:async';
import 'dart:convert';

enum PetVisualState { sleeping, eating, happy, sad, breathing }

enum SleepReason { aiIssue, night, awake }

enum PetEatingPhase { none, waiting, consuming }

class CharacterProvider extends ChangeNotifier {
  static const int _sleepStartHour = 22;
  static const int _sleepEndHour = 7;
  static const Duration _awakeDuration = Duration(minutes: 30);
  static const Duration _happyBurstDuration = Duration(seconds: 2);
  static const Duration _eatingConsumeDuration = Duration(milliseconds: 900);

  /// How often petting actually pays happiness. Without this, tapping the pet
  /// is an unbounded happiness faucet that makes decay meaningless — taps
  /// during the cooldown still animate, they just don't move stats.
  static const Duration petCooldown = Duration(minutes: 10);
  static const int _petHappinessGain = 8;

  /// XP and coins are scaled by this while the pet is sick, so neglect costs
  /// progression speed rather than locking the player out of the app.
  static const double sickRewardMultiplier = 0.5;

  // Stat decay rates (points per hour).
  static const int _hungerGainPerHour = 3;
  static const int _happinessLossPerHour = 2;
  static const int _healthLossPerHour = 1;

  // Stat thresholds shared by mood, visual state and decay logic.
  static const int _lowHealth = 30; // below → sick
  static const int _criticalHunger = 80; // above → starving / health decay
  static const int _lowHappiness = 30; // below → sad
  static const int _highHappiness = 80; // above (when well fed) → happy
  static const int _wellFedHunger = 30; // below → counts as well fed
  static const int _miserableHappiness = 20; // below → health decay

  CharacterCustomization _customization = CharacterCustomization();
  final Set<String> _unlockedItems = {'apple', 'coffee'};
  final List<String> _inventory = ['apple', 'coffee']; // Owned items

  // Equipped accessories, one per slot: {'hat': id?, 'neck': id?, 'face': id?}
  final Map<String, String?> _equippedAccessories = {};

  // Pet Stats (0-100)
  int _hunger = 50;
  int _happiness = 70;
  int _health = 100;
  DateTime _lastUpdate = DateTime.now();
  Timer? _decayTimer;
  StreamSubscription<RewardDef>? _rewardSubscription;
  DateTime? _awakeUntil;
  DateTime? _lastInteractionAt;
  DateTime? _lastPetAt;
  bool _aiIssueSleepMode = false;
  PetEatingPhase _eatingPhase = PetEatingPhase.none;
  DateTime? _happyBurstUntil;
  double _chatMoodSignal = 0.0;
  Timer? _eatingTimer;
  Timer? _happyBurstTimer;

  CharacterCustomization get customization => _customization;
  String get currentCharacterType => _customization.characterType;
  String get currentCharacterAsset =>
      'assets/svgs/${_customization.characterType}.svg';
  Set<String> get unlockedItems => _unlockedItems;
  List<String> get inventory => _inventory;

  /// The pet's current recolour choices, for the sprite renderer + UI.
  PetColorSpec get colorSpec => PetColorSpec(
        bodyColor: _customization.bodyColor,
        eyeMode: eyeModeFromString(_customization.eyeMode),
        eyeColor1: _customization.eyeColor1,
        eyeColor2: _customization.eyeColor2,
      );

  // ==================== ACCESSORIES ====================

  Map<String, String?> get equippedAccessories =>
      Map.unmodifiable(_equippedAccessories);

  /// The accessory id equipped in [slot], or null.
  String? equippedInSlot(String slot) => _equippedAccessories[slot];

  bool isAccessoryEquipped(String id) =>
      _equippedAccessories.values.contains(id);

  /// Asset paths of every currently equipped accessory (for the sprite),
  /// drawn in slot order so the hat layers above the neck/face.
  List<String> get equippedAccessoryAssets {
    final assets = <String>[];
    for (final slot in AccessorySlots.all) {
      final def = accessoryById(_equippedAccessories[slot]);
      if (def != null) assets.add(def.asset);
    }
    return assets;
  }

  /// Equip an accessory, or toggle it off if it's already on in its slot.
  void equipAccessory(String id) {
    final def = accessoryById(id);
    if (def == null) return;
    if (_equippedAccessories[def.slot] == id) {
      _equippedAccessories[def.slot] = null;
    } else {
      _equippedAccessories[def.slot] = id;
    }
    _saveAccessories();
    notifyListeners();
  }

  void unequipSlot(String slot) {
    if (_equippedAccessories[slot] != null) {
      _equippedAccessories[slot] = null;
      _saveAccessories();
      notifyListeners();
    }
  }

  Future<void> _saveAccessories() async {
    final prefs = await SharedPreferences.getInstance();
    final data = <String, String>{};
    _equippedAccessories.forEach((slot, id) {
      if (id != null) data[slot] = id;
    });
    await prefs.setString('equipped_accessories', jsonEncode(data));
  }

  Future<void> _loadAccessories() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString('equipped_accessories');
    if (str == null) return;
    try {
      final map = jsonDecode(str) as Map<String, dynamic>;
      map.forEach((slot, id) {
        if (id is String && accessoryById(id) != null) {
          _equippedAccessories[slot] = id;
        }
      });
    } catch (_) {
      // Ignore corrupt cosmetic data.
    }
  }

  // Pet state getters
  int get hunger => _hunger;
  int get happiness => _happiness;
  int get health => _health;

  // Pet mood based on stats
  String get mood {
    if (isSleeping) return 'sleeping';
    if (_health < _lowHealth) return 'sick';
    if (_hunger > _criticalHunger) return 'starving';
    if (_happiness < _lowHappiness) return 'sad';
    if (_happiness > _highHappiness && _hunger < _wellFedHunger) return 'happy';
    return 'neutral';
  }

  bool get isCriticalMood =>
      isSick || _hunger > _criticalHunger || _happiness < _lowHappiness;

  /// A neglected pet gets sick. Sickness doesn't lock the player out — it
  /// halves XP and coin income (see [scaleReward]) until they nurse the pet
  /// back up with food or medicine.
  bool get isSick => _health < _lowHealth;

  /// Applies the sickness penalty to an XP or coin reward. Call this at the
  /// point rewards are granted so neglect has a visible, recoverable cost.
  int scaleReward(int amount) {
    if (!isSick) return amount;
    return (amount * sickRewardMultiplier).round();
  }
  PetEatingPhase get eatingPhase => _eatingPhase;
  double get chatMoodSignal => _chatMoodSignal;
  bool get isFoodHovering => _eatingPhase == PetEatingPhase.waiting;

  /// The food the player has picked up and is carrying toward the pet.
  ///
  /// Null when nothing is in hand. Kept here rather than in the home screen's
  /// state so the care panel can put something in the player's hand and then
  /// dismiss itself.
  String? _heldFoodId;
  String? get heldFoodId => _heldFoodId;
  bool get isCarryingFood => _heldFoodId != null;

  PetVisualState get visualState {
    if (_eatingPhase != PetEatingPhase.none) {
      return PetVisualState.eating;
    }
    if (isSleeping) {
      return PetVisualState.sleeping;
    }
    if (_isHappyBurstActive) {
      return PetVisualState.happy;
    }
    if (isCriticalMood) {
      return PetVisualState.sad;
    }
    if (_happiness > _highHappiness && _hunger < _wellFedHunger) {
      return PetVisualState.happy;
    }
    return PetVisualState.breathing;
  }

  // Animation state (e.g., idle, talking, thinking)
  String _animationState = 'idle';
  String get animationState => _animationState;

  bool get isAiIssueSleepMode => _aiIssueSleepMode;

  bool get isNightHours {
    final hour = DateTime.now().hour;
    return hour >= _sleepStartHour || hour < _sleepEndHour;
  }

  bool get isTemporarilyAwake {
    if (_awakeUntil == null) return false;
    return DateTime.now().isBefore(_awakeUntil!);
  }

  bool get isSleepingForNight {
    return isNightHours && !isTemporarilyAwake;
  }

  bool get isSleeping {
    return _aiIssueSleepMode || isSleepingForNight;
  }

  DateTime? get awakeUntil => _awakeUntil;

  /// Why the pet is (or isn't) sleeping. The UI maps this to a localized
  /// string (l10n keys: mojiDozingReconnect / mojiSleepingTapWake /
  /// mojiAwakeReady).
  SleepReason get sleepReason {
    if (_aiIssueSleepMode) return SleepReason.aiIssue;
    if (isSleepingForNight) return SleepReason.night;
    return SleepReason.awake;
  }

  /// [startDecayTimer] exists for widget tests. The periodic decay timer runs
  /// forever by design, and `testWidgets` fails any test that leaves a timer
  /// pending — so a test that needs a real provider would otherwise fail on
  /// the timer rather than on anything it was actually checking.
  CharacterProvider({bool startDecayTimer = true}) {
    _loadPetState();
    if (startDecayTimer) _startDecayTimer();
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
    if (reward.type == RewardType.unlock ||
        reward.type == RewardType.cosmetic) {
      _unlockedItems.add(reward.itemId!);
    }

    _savePetState();
    notifyListeners();
  }

  @override
  void dispose() {
    _decayTimer?.cancel();
    _rewardSubscription?.cancel();
    _eatingTimer?.cancel();
    _happyBurstTimer?.cancel();
    super.dispose();
  }

  bool get _isHappyBurstActive {
    if (_happyBurstUntil == null) {
      return false;
    }
    return DateTime.now().isBefore(_happyBurstUntil!);
  }

  void _forceWakeForInteraction() {
    final now = DateTime.now();
    _aiIssueSleepMode = false;
    _lastInteractionAt = now;
    _awakeUntil = now.add(_awakeDuration);
  }

  void _startHappyBurst({Duration duration = _happyBurstDuration}) {
    _happyBurstTimer?.cancel();
    _happyBurstUntil = DateTime.now().add(duration);
    _happyBurstTimer = Timer(duration, () {
      _happyBurstUntil = null;
      notifyListeners();
    });
  }

  void _startEatingConsumeAnimation() {
    _eatingTimer?.cancel();
    _eatingPhase = PetEatingPhase.consuming;
    _eatingTimer = Timer(_eatingConsumeDuration, () {
      _eatingPhase = PetEatingPhase.none;
      notifyListeners();
    });
  }

  void setFoodHovering(bool hovering) {
    if (hovering) {
      if (isSleeping) {
        _forceWakeForInteraction();
        _savePetState();
      }
      if (_eatingPhase != PetEatingPhase.waiting) {
        _eatingPhase = PetEatingPhase.waiting;
        notifyListeners();
      }
      return;
    }

    if (_eatingPhase == PetEatingPhase.waiting) {
      _eatingPhase = PetEatingPhase.none;
      notifyListeners();
    }
  }

  void applyChatMoodSignal(double signal,
      {Duration burstDuration = _happyBurstDuration}) {
    _chatMoodSignal = signal.clamp(-1.0, 1.0);
    if (_chatMoodSignal > 0.2) {
      _startHappyBurst(duration: burstDuration);
    }
    notifyListeners();
  }

  /// Picks food out of the inventory so it can be carried to the pet.
  ///
  /// Returns false when the item is gone, so the caller does not put a
  /// phantom item in the player's hand.
  bool pickUpFood(String itemId) {
    if (!_inventory.contains(itemId)) return false;
    _heldFoodId = itemId;
    notifyListeners();
    return true;
  }

  /// Puts carried food back, cancelling any anticipation the pet was showing.
  void putDownFood() {
    if (_heldFoodId == null && !isFoodHovering) return;
    _heldFoodId = null;
    setFoodHovering(false);
    notifyListeners();
  }

  /// Gives the carried food to the pet. Returns false when there is nothing
  /// in hand or the item has since been consumed.
  bool feedHeldFood() {
    final itemId = _heldFoodId;
    if (itemId == null) return false;

    _heldFoodId = null;
    final fed = consumeFoodAndAnimate(itemId);
    if (!fed) {
      // Nothing was eaten, so clear the anticipation pose rather than
      // leaving the pet holding its mouth open at nothing.
      setFoodHovering(false);
    }
    notifyListeners();
    return fed;
  }

  /// How long the pet eyes the food before eating it.
  static const Duration foodAnticipation = Duration(milliseconds: 450);

  /// Offers food to the pet: a beat of anticipation, then the chew.
  ///
  /// [PetEatingPhase.waiting] existed with no caller, and feeding jumped
  /// straight to chewing. Going through the hover phase is what makes the pet
  /// look like it noticed the food rather than teleporting into eating it.
  ///
  /// [anticipation] is injectable so tests don't have to wait it out.
  Future<bool> offerFood(
    String itemId, {
    Duration? anticipation,
  }) async {
    if (!_inventory.contains(itemId)) return false;

    setFoodHovering(true);
    await Future<void>.delayed(anticipation ?? foodAnticipation);

    // The item can disappear during the pause — a second tap, or a reward
    // consuming it — so re-check rather than trusting the earlier read.
    if (!_inventory.contains(itemId)) {
      setFoodHovering(false);
      return false;
    }
    return consumeFoodAndAnimate(itemId);
  }

  bool consumeFoodAndAnimate(String itemId) {
    final hadItem = _inventory.contains(itemId);
    if (!hadItem) {
      return false;
    }
    feedPet(itemId);
    return true;
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
    final savedAwakeUntilMs = prefs.getInt('pet_awake_until');
    if (savedAwakeUntilMs != null) {
      _awakeUntil = DateTime.fromMillisecondsSinceEpoch(savedAwakeUntilMs);
    }
    final savedLastInteractionMs = prefs.getInt('pet_last_interaction');
    if (savedLastInteractionMs != null) {
      _lastInteractionAt =
          DateTime.fromMillisecondsSinceEpoch(savedLastInteractionMs);
    }
    // Persisted so a restart can't be used to reset the petting cooldown.
    final savedLastPetMs = prefs.getInt('pet_last_petted');
    if (savedLastPetMs != null) {
      _lastPetAt = DateTime.fromMillisecondsSinceEpoch(savedLastPetMs);
    }
    _customization = _customization.copyWith(
      characterType: {'dog', 'cat', 'bird'}.contains(savedCharacterType)
          ? savedCharacterType
          : 'cat',
      bodyColor: prefs.getString('pet_body_color'),
      eyeMode: prefs.getString('pet_eye_mode'),
      eyeColor1: prefs.getString('pet_eye_color1'),
      eyeColor2: prefs.getString('pet_eye_color2'),
    );

    await _loadAccessories();

    notifyListeners();
  }

  Future<void> _savePetState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('pet_hunger', _hunger);
    await prefs.setInt('pet_happiness', _happiness);
    await prefs.setInt('pet_health', _health);
    await prefs.setInt('pet_last_update', _lastUpdate.millisecondsSinceEpoch);
    if (_awakeUntil != null) {
      await prefs.setInt(
          'pet_awake_until', _awakeUntil!.millisecondsSinceEpoch);
    } else {
      await prefs.remove('pet_awake_until');
    }
    if (_lastInteractionAt != null) {
      await prefs.setInt(
          'pet_last_interaction', _lastInteractionAt!.millisecondsSinceEpoch);
    }
    if (_lastPetAt != null) {
      await prefs.setInt('pet_last_petted', _lastPetAt!.millisecondsSinceEpoch);
    }
    await prefs.setString('character_type', _customization.characterType);
    await prefs.setString('pet_body_color', _customization.bodyColor);
    await prefs.setString('pet_eye_mode', _customization.eyeMode);
    await prefs.setString('pet_eye_color1', _customization.eyeColor1);
    await prefs.setString('pet_eye_color2', _customization.eyeColor2);
    // persist unlocked items and inventory
    await prefs.setStringList('unlocked_items', _unlockedItems.toList());
    await prefs.setStringList('inventory', _inventory);
  }

  void _startDecayTimer() {
    _decayTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _applyDecay();
    });
  }

  /// Applies whole hours of decay accrued since [_lastUpdate], both for
  /// offline gaps and while the app is running. [_lastUpdate] advances only
  /// by the hours consumed, so partial hours keep accruing across timer
  /// ticks and app restarts. Returns true when any stat changed.
  bool _applyElapsedDecay(DateTime now) {
    final hours = now.difference(_lastUpdate).inHours;
    if (hours <= 0) return false;

    final oldHunger = _hunger;
    final oldHappiness = _happiness;
    final oldHealth = _health;

    _hunger = (_hunger + hours * _hungerGainPerHour).clamp(0, 100);
    _happiness = (_happiness - hours * _happinessLossPerHour).clamp(0, 100);
    if (_hunger > _criticalHunger || _happiness < _miserableHappiness) {
      _health = (_health - hours * _healthLossPerHour).clamp(0, 100);
    }
    _lastUpdate = _lastUpdate.add(Duration(hours: hours));

    return _hunger != oldHunger ||
        _happiness != oldHappiness ||
        _health != oldHealth;
  }

  void _applyOfflineDecay() {
    if (_applyElapsedDecay(DateTime.now())) {
      _savePetState();
    }
  }

  void _applyDecay() {
    final now = DateTime.now();
    var changed = _applyElapsedDecay(now);

    if (_awakeUntil != null && now.isAfter(_awakeUntil!)) {
      _awakeUntil = null;
      changed = true;
    }

    // Only persist and notify when something actually changed — the timer
    // fires every minute but stats move at most once per hour.
    if (changed) {
      _savePetState();
      notifyListeners();
    }
  }

  void wakeUp() {
    if (_aiIssueSleepMode) {
      return;
    }
    final now = DateTime.now();
    _lastInteractionAt = now;
    _awakeUntil = now.add(_awakeDuration);
    _savePetState();
    notifyListeners();
  }

  void registerInteraction() {
    if (_aiIssueSleepMode) {
      return;
    }
    final now = DateTime.now();
    _lastInteractionAt = now;

    if (isNightHours) {
      _awakeUntil = now.add(_awakeDuration);
    }

    _savePetState();
    notifyListeners();
  }

  void setAiIssueSleepMode(bool enabled) {
    if (_aiIssueSleepMode == enabled) {
      return;
    }

    _aiIssueSleepMode = enabled;
    if (enabled) {
      _awakeUntil = null;
      _eatingPhase = PetEatingPhase.none;
    }
    _savePetState();
    notifyListeners();
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
    applyChatMoodSignal(0.35);
    registerInteraction();
  }

  void rewardScenario() {
    _happiness = (_happiness + 10).clamp(0, 100);
    _hunger = (_hunger + 5).clamp(0, 100); // Scenarios are tiring!
    applyChatMoodSignal(0.4);
    registerInteraction();
  }

  void rewardQuiz(bool passed) {
    if (passed) {
      _happiness = (_happiness + 15).clamp(0, 100);
      applyChatMoodSignal(0.45);
    } else {
      _happiness = (_happiness - 5).clamp(0, 100);
      applyChatMoodSignal(-0.2);
    }
    _hunger = (_hunger + 10).clamp(0, 100);
    registerInteraction();
  }

  void applyQuizRewards({
    required int happinessDelta,
    required int hungerDelta,
  }) {
    _happiness = (_happiness + happinessDelta).clamp(0, 100);
    _hunger = (_hunger + hungerDelta).clamp(0, 100);
    registerInteraction();
  }

  void feedPet(String itemId) {
    if (!_inventory.contains(itemId)) return;

    // An id with no matching shop item is stale inventory from an older
    // build — drop it rather than silently feeding a substitute.
    final matches = shopItems.where((i) => i.id == itemId);
    if (matches.isEmpty) {
      _inventory.remove(itemId);
      _savePetState();
      notifyListeners();
      return;
    }
    final item = matches.first;

    if (isSleeping) {
      _forceWakeForInteraction();
    }
    _hunger = (_hunger - (item.hungerRestore ?? 0)).clamp(0, 100);
    _happiness = (_happiness + (item.happinessRestore ?? 0)).clamp(0, 100);

    // Medicine heals directly; ordinary food only nudges health back up as a
    // side effect of keeping the pet fed and happy.
    _health = (_health + (item.healthRestore ?? 0)).clamp(0, 100);
    if (item.healthRestore == null && _hunger < 50 && _happiness > 50) {
      _health = (_health + 5).clamp(0, 100);
    }

    _inventory.remove(itemId);
    _startEatingConsumeAnimation();
    registerInteraction();
  }

  /// Whether petting would currently pay happiness, or is still on cooldown.
  bool get canEarnFromPetting {
    if (_lastPetAt == null) return true;
    return DateTime.now().difference(_lastPetAt!) >= petCooldown;
  }

  /// Time until petting pays out again, or [Duration.zero] when it's ready.
  Duration get petCooldownRemaining {
    if (_lastPetAt == null) return Duration.zero;
    final elapsed = DateTime.now().difference(_lastPetAt!);
    final remaining = petCooldown - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Pets the pet. Always plays the happy reaction so the tap feels alive,
  /// but only grants happiness once per [petCooldown]. Returns true when
  /// happiness was actually granted.
  bool petThePet() {
    // A pet dozing through an AI outage shouldn't perk up — registerInteraction
    // ignores it too, so the burst would never be cleared by a notify.
    if (_aiIssueSleepMode) return false;

    _startHappyBurst();

    if (!canEarnFromPetting) {
      registerInteraction();
      return false;
    }

    _lastPetAt = DateTime.now();
    _happiness = (_happiness + _petHappinessGain).clamp(0, 100);
    registerInteraction();
    return true;
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
          case 'sleeping':
            return Faces.sleeping.first.open;
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
    _customization = _customization.copyWith(
      openFace: openFace,
      closedFace: closedFace ?? _customization.closedFace,
    );
    notifyListeners();
  }

  void updateColor(String color) {
    _customization = _customization.copyWith(color: color);
    notifyListeners();
  }

  void updateBackgroundColor(String color) {
    _customization = _customization.copyWith(backgroundColor: color);
    notifyListeners();
  }

  /// Sets the body + tail coat colour (always shared between the two).
  void updateBodyColor(String hex) {
    if (_customization.bodyColor == hex) return;
    _customization = _customization.copyWith(bodyColor: hex);
    _savePetState();
    notifyListeners();
  }

  /// Updates the eye colouring. [color2] is only meaningful for the
  /// heterochromia (right eye) and dichroic (pupil) modes.
  void updateEyeColors({
    required EyeMode mode,
    required String color1,
    String? color2,
  }) {
    _customization = _customization.copyWith(
      eyeMode: eyeModeToString(mode),
      eyeColor1: color1,
      eyeColor2: color2 ?? _customization.eyeColor2,
    );
    _savePetState();
    notifyListeners();
  }

  Future<void> updateCharacterType(String type) async {
    const validTypes = {'dog', 'cat', 'bird'};
    if (!validTypes.contains(type)) return;

    if (_customization.characterType == type) return;

    _customization = _customization.copyWith(characterType: type);
    await _savePetState();
    notifyListeners();
  }

  /// Purchases an item: deducts the total cost from [userProvider],
  /// unlocks the item, adds food items to the inventory, and persists
  /// state. Returns false without side effects if coins are insufficient.
  Future<bool> purchaseItem(ShopItem item, UserProvider userProvider,
      {int quantity = 1}) async {
    final totalCost = item.price * quantity;
    if (userProvider.coins < totalCost) {
      return false;
    }
    await userProvider.spendCoins(totalCost);
    _unlockedItems.add(item.id);
    if (item.type == 'food') {
      for (int i = 0; i < quantity; i++) {
        _inventory.add(item.id);
      }
    }
    await _savePetState();
    notifyListeners();
    return true;
  }
}
