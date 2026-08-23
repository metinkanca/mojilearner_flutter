import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../constants/faces.dart';
import '../constants/shop.dart';
import '../constants/progression.dart';
import '../constants/accessories.dart';
import '../constants/bond.dart';
import '../constants/app_runtime_config.dart';
import '../utils/accessory_ownership.dart';
import '../utils/color_ownership.dart';
import '../utils/bond_progress.dart';
import '../utils/pet_recolor.dart';
import 'user_provider.dart';
import 'dart:async';
import 'dart:convert';

/// [petted] is the pet reacting to a hand on it right now, and is deliberately
/// separate from [happy]: contentment is a mood the pet wears for a while,
/// being petted is a thing happening to it this second, and they do not look
/// alike. It outranks [happy] because a rub should read through a good mood.
enum PetVisualState { sleeping, eating, petted, happy, sad, breathing }

enum SleepReason { aiIssue, night, awake }

enum PetEatingPhase { none, waiting, consuming }

class CharacterProvider extends ChangeNotifier {
  static const int _sleepStartHour = 22;
  static const int _sleepEndHour = 7;
  static const Duration _awakeDuration = Duration(minutes: 30);
  static const Duration _happyBurstDuration = Duration(seconds: 2);
  static const Duration _eatingConsumeDuration = Duration(milliseconds: 900);

  /// How long one rub of the head shows on the pet. Short on purpose: it is
  /// refreshed by every rub, so a scratch that carries on holds the reaction
  /// open, and it drops within a beat of the hand coming off.
  static const Duration _pettedDuration = Duration(milliseconds: 900);

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

  /// Appearance per character type: the coat, eyes and equipped accessories of
  /// each pet, kept side by side so switching pets restores the look that pet
  /// was last given instead of carrying one design across all of them.
  /// A type with no entry has never been customised and uses the defaults.
  final Map<String, PetDesign> _designs = {};

  // Pet Stats (0-100)
  int _hunger = 50;
  int _happiness = 70;
  int _health = 100;

  // Bond: the slow axis. Monotonic by construction — nothing in this class
  // subtracts from it. See lib/constants/bond.dart for why.
  int _bondPoints = 0;
  DateTime? _lastLearningAt;
  int _bondEarnedToday = 0;
  DateTime? _bondDay;
  late DateTime _lastUpdate;
  Timer? _decayTimer;
  StreamSubscription<RewardDef>? _rewardSubscription;
  DateTime? _awakeUntil;
  DateTime? _lastInteractionAt;
  DateTime? _lastPetAt;
  bool _aiIssueSleepMode = false;
  PetEatingPhase _eatingPhase = PetEatingPhase.none;
  DateTime? _happyBurstUntil;
  DateTime? _pettedUntil;
  int _petPayouts = 0;
  double _chatMoodSignal = 0.0;
  Timer? _eatingTimer;
  Timer? _happyBurstTimer;
  Timer? _pettedTimer;

  CharacterCustomization get customization => _customization;
  String get currentCharacterType => _customization.characterType;
  String get currentCharacterAsset =>
      'assets/svgs/${_customization.characterType}.svg';
  Set<String> get unlockedItems => _unlockedItems;
  List<String> get inventory => _inventory;

  /// The design of the pet currently out — what every appearance getter below
  /// reads and every customisation setter writes.
  PetDesign get design => designFor(_customization.characterType);

  /// The design of [type], whether or not it is the pet currently out, so the
  /// character picker can show each pet as it was last dressed.
  PetDesign designFor(String type) => _designs[type] ?? const PetDesign();

  /// Replaces the current pet's design, persists it and notifies.
  void _setDesign(PetDesign next) {
    _designs[_customization.characterType] = next;
    _savePetState();
    notifyListeners();
  }

  /// The current pet's recolour choices, for the sprite renderer + UI.
  PetColorSpec get colorSpec => colorSpecFor(_customization.characterType);

  /// [colorSpec] for any pet, so a picker can preview each one as it was
  /// dressed rather than in the un-customised source art.
  PetColorSpec colorSpecFor(String type) {
    final d = designFor(type);
    return PetColorSpec(
      bodyColor: d.bodyColor,
      eyeMode: eyeModeFromString(d.eyeMode),
      eyeColor1: d.eyeColor1,
      eyeColor2: d.eyeColor2,
    );
  }

  // ==================== ACCESSORIES ====================

  /// What the pet currently out is wearing, by slot.
  Map<String, String?> get equippedAccessories =>
      Map.unmodifiable(design.accessories);

  /// The accessory id equipped in [slot], or null.
  String? equippedInSlot(String slot) => design.accessories[slot];

  bool isAccessoryEquipped(String id) => design.accessories.values.contains(id);

  /// Asset paths of every accessory the current pet is wearing (for the
  /// sprite), drawn in slot order so the hat layers above the neck/face.
  List<String> get equippedAccessoryAssets =>
      equippedAccessoryAssetsFor(_customization.characterType);

  /// [equippedAccessoryAssets] for any pet, for the same reason as
  /// [colorSpecFor].
  List<String> equippedAccessoryAssetsFor(String type) =>
      [for (final def in equippedAccessoriesFor(type)) def.asset];

  /// Every accessory [type] is wearing, in slot order so the hat layers above
  /// the neck/face.
  ///
  /// The sprite needs the whole definition rather than just the asset: which
  /// slot a piece is in decides where it sits on a pet whose head is not the
  /// cat's, and which piece it is decides whether that pet wears its own cut
  /// of the art instead.
  List<AccessoryDef> equippedAccessoriesFor(String type) {
    final accessories = designFor(type).accessories;
    final defs = <AccessoryDef>[];
    for (final slot in AccessorySlots.all) {
      final def = accessoryById(accessories[slot]);
      if (def != null) defs.add(def);
    }
    return defs;
  }

  /// Whether [id] is wearable: a free starter, one that has been bought, or
  /// one whose bond stage has been reached.
  ///
  /// [stage] comes from the caller because bond stages depend on the assessed
  /// level, which is per-language and lives in CalibrationProvider — see
  /// [bondStatusFor].
  bool ownsAccessory(String id, {required PetStage stage}) {
    final def = accessoryById(id);
    if (def == null) return false;
    return AccessoryOwnership.isOwned(
      def,
      unlockedItemIds: _unlockedItems,
      stage: stage,
    );
  }

  /// Equip an accessory, or toggle it off if it is already on in its slot.
  ///
  /// Returns false and changes nothing when the accessory is not owned. The
  /// guard lives here rather than only in the wardrobe so no future caller can
  /// dress the pet in something the player has not earned or paid for.
  bool equipAccessory(String id, {required PetStage stage}) {
    final def = accessoryById(id);
    if (def == null) return false;

    // Taking something off is always allowed, whatever its current status —
    // otherwise a retuned catalogue could leave a player stuck wearing it.
    if (design.accessories[def.slot] == id) {
      _setDesign(design.withSlot(def.slot, null));
      return true;
    }

    if (!ownsAccessory(id, stage: stage)) return false;

    _setDesign(design.withSlot(def.slot, id));
    return true;
  }

  void unequipSlot(String slot) {
    if (design.accessories[slot] != null) {
      _setDesign(design.withSlot(slot, null));
    }
  }

  /// Reads the per-pet designs, migrating the single shared design older
  /// installs saved. Accessory ids are checked against the catalogue here, so
  /// a retired item never reaches the sprite.
  Future<void> _loadDesigns(SharedPreferences prefs) async {
    final raw = prefs.getString('pet_designs');
    if (raw != null) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        map.forEach((type, value) {
          if (value is Map<String, dynamic>) {
            _designs[type] = _sanitizeDesign(PetDesign.fromJson(value));
          }
        });
      } catch (_) {
        // Ignore corrupt cosmetic data.
      }
    } else {
      // Legacy save: one coat, one set of eyes and one outfit shared by every
      // pet. It belongs to whichever pet was out when it was saved; the others
      // start from the defaults.
      final accessories = <String, String?>{};
      final legacy = prefs.getString('equipped_accessories');
      if (legacy != null) {
        try {
          final map = jsonDecode(legacy) as Map<String, dynamic>;
          map.forEach((slot, id) {
            if (id is String) accessories[slot] = id;
          });
        } catch (_) {
          // Ignore corrupt cosmetic data.
        }
      }
      _designs[_customization.characterType] = _sanitizeDesign(PetDesign(
        bodyColor: prefs.getString('pet_body_color') ?? kDefaultBodyColor,
        eyeMode: prefs.getString('pet_eye_mode') ?? kDefaultEyeMode,
        eyeColor1: prefs.getString('pet_eye_color1') ?? kDefaultEyeColor1,
        eyeColor2: prefs.getString('pet_eye_color2') ?? kDefaultEyeColor2,
        accessories: accessories,
      ));
    }

    // Every accessory used to be free, so players who already dressed their
    // pet have no purchase record for what it is wearing. Treat whatever is on
    // as owned rather than stripping it at the next launch and asking them to
    // buy it back.
    var grandfathered = false;
    for (final d in _designs.values) {
      for (final id in d.accessories.values) {
        if (id != null) grandfathered = _unlockedItems.add(id) || grandfathered;
      }
    }
    // Written back rather than re-derived every launch, so taking the item off
    // does not also lose the ownership just inferred from it — and so a
    // migrated legacy design is stored in the new shape straight away.
    if (grandfathered || raw == null) await _savePetState();
  }

  /// Drops accessories whose id is no longer in the catalogue.
  PetDesign _sanitizeDesign(PetDesign design) {
    final kept = <String, String?>{};
    design.accessories.forEach((slot, id) {
      if (id != null && accessoryById(id) != null) kept[slot] = id;
    });
    return design.copyWith(accessories: kept);
  }

  // Pet state getters
  int get hunger => _hunger;
  int get happiness => _happiness;
  int get health => _health;

  /// Total bond ever earned. Only ever goes up.
  int get bondPoints => _bondPoints;

  /// When the player last did something in the target language, or null if
  /// they never have.
  DateTime? get lastLearningAt => _lastLearningAt;

  /// Time since the last learning event, or null if there has never been one.
  Duration? get sinceLastLearning {
    final last = _lastLearningAt;
    if (last == null) return null;
    final elapsed = _now().difference(last);
    return elapsed.isNegative ? Duration.zero : elapsed;
  }

  /// Whether the pet reads as missing the player. Costs nothing — see
  /// [PetWarmth].
  PetWarmth get warmth => BondProgress.warmthFor(sinceLastLearning);

  /// Bond earned so far today, against [BondConstants.dailyCap].
  int get bondEarnedToday =>
      _isSameDay(_bondDay, _now()) ? _bondEarnedToday : 0;

  /// Bond the rest of today can still pay.
  int get bondRemainingToday => (BondConstants.dailyCap - bondEarnedToday)
      .clamp(0, BondConstants.dailyCap);

  /// The pet's stage and its distance from the next one.
  ///
  /// Takes the level rather than reading it, because proficiency belongs to
  /// [CalibrationProvider] and is per-language — duplicating it here would
  /// give the app two answers to the same question. Pass the assessed level
  /// for the language currently being learned; null reads as beginner.
  BondStatus bondStatusFor(String? assessedLevel) => BondProgress.statusFor(
        bondPoints: _bondPoints,
        tier: BondProgress.tierFromLevel(assessedLevel),
      );

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
    if (isBeingPetted) {
      return PetVisualState.petted;
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
    final hour = _now().hour;
    return hour >= _sleepStartHour || hour < _sleepEndHour;
  }

  bool get isTemporarilyAwake {
    if (_awakeUntil == null) return false;
    return _now().isBefore(_awakeUntil!);
  }

  bool get isSleepingForNight {
    if (AppRuntimeConfig.keepPetAwake) return false;
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
  ///
  /// [now] exists for the same reason, one layer down. The pet's night is a
  /// wall-clock fact — [isNightHours] is true between 22:00 and 07:00 — so a
  /// test that renders the pet passes or fails depending on what time of day
  /// it is run. Pin this and the pet's day is the test's to decide.
  CharacterProvider({bool startDecayTimer = true, DateTime Function()? now})
      : _now = now ?? DateTime.now {
    _lastUpdate = _now();
    _loadPetState();
    if (startDecayTimer) _startDecayTimer();
  }

  /// The clock this pet lives by. Every "what time is it" in this class goes
  /// through here rather than [DateTime.now] directly.
  final DateTime Function() _now;

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
    _pettedTimer?.cancel();
    super.dispose();
  }

  bool get _isHappyBurstActive {
    if (_happyBurstUntil == null) {
      return false;
    }
    return _now().isBefore(_happyBurstUntil!);
  }

  void _forceWakeForInteraction() {
    final now = _now();
    _aiIssueSleepMode = false;
    _lastInteractionAt = now;
    _awakeUntil = now.add(_awakeDuration);
  }

  /// Whether a hand is on the pet right now, as far as the art is concerned.
  ///
  /// Public because it is a visible state the pet is in, not an implementation
  /// detail of one screen — anything drawing the pet can ask.
  bool get isBeingPetted {
    final until = _pettedUntil;
    if (until == null) return false;
    return _now().isBefore(until);
  }

  /// How many times petting has actually paid happiness this session.
  ///
  /// Carries no meaning beyond changing — it is what the hearts key off, and
  /// living here rather than in the home screen is what makes them fire
  /// wherever the petting came from, the care panel included.
  int get petPayouts => _petPayouts;

  void _startPettedReaction() {
    _pettedTimer?.cancel();
    _pettedUntil = _now().add(_pettedDuration);
    _pettedTimer = Timer(_pettedDuration, () {
      _pettedUntil = null;
      notifyListeners();
    });
  }

  void _startHappyBurst({Duration duration = _happyBurstDuration}) {
    _happyBurstTimer?.cancel();
    _happyBurstUntil = _now().add(duration);
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
    _bondPoints = prefs.getInt('pet_bond_points') ?? 0;
    final lastLearningMs = prefs.getInt('pet_last_learning');
    if (lastLearningMs != null) {
      _lastLearningAt = DateTime.fromMillisecondsSinceEpoch(lastLearningMs);
    }
    // The daily cap is stored with the day it belongs to, so a restart cannot
    // be used to clear it and a stale count from an earlier day is ignored.
    final bondDayMs = prefs.getInt('pet_bond_day');
    if (bondDayMs != null) {
      _bondDay = DateTime.fromMillisecondsSinceEpoch(bondDayMs);
      _bondEarnedToday = prefs.getInt('pet_bond_today') ?? 0;
    }
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
    );

    // After the character type, since a legacy design migrates onto whichever
    // pet was out at the time.
    await _loadDesigns(prefs);

    notifyListeners();
  }

  Future<void> _savePetState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('pet_hunger', _hunger);
    await prefs.setInt('pet_happiness', _happiness);
    await prefs.setInt('pet_health', _health);
    await prefs.setInt('pet_bond_points', _bondPoints);
    if (_lastLearningAt != null) {
      await prefs.setInt(
          'pet_last_learning', _lastLearningAt!.millisecondsSinceEpoch);
    }
    if (_bondDay != null) {
      await prefs.setInt('pet_bond_day', _bondDay!.millisecondsSinceEpoch);
      await prefs.setInt('pet_bond_today', _bondEarnedToday);
    }
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
    // One entry per pet. The legacy `pet_body_color` / `pet_eye_*` /
    // `equipped_accessories` keys are left untouched: they are only read when
    // `pet_designs` is absent, and keeping them means a half-finished
    // migration can still be re-run.
    await prefs.setString(
      'pet_designs',
      jsonEncode({
        for (final e in _designs.entries) e.key: e.value.toJson(),
      }),
    );
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
    if (_applyElapsedDecay(_now())) {
      _savePetState();
    }
  }

  void _applyDecay() {
    final now = _now();
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
    final now = _now();
    _lastInteractionAt = now;
    _awakeUntil = now.add(_awakeDuration);
    _savePetState();
    notifyListeners();
  }

  void registerInteraction() {
    if (_aiIssueSleepMode) {
      return;
    }
    _touchInteraction();

    // Unconditional, and it has to stay that way: rewardChat, rewardScenario,
    // rewardQuiz and applyQuizRewards all move happiness and hunger and then
    // lean on this call to persist them.
    _savePetState();
    notifyListeners();
  }

  /// The state half of [registerInteraction], without the save.
  ///
  /// Returns whether anything worth persisting moved. Only the night-time
  /// wake window qualifies: [_lastInteractionAt] is written to disk and read
  /// back on launch, but nothing consults it — absence is measured by
  /// [warmth], which runs off `_lastLearningAt`.
  bool _touchInteraction() {
    final now = _now();
    _lastInteractionAt = now;

    if (!isNightHours) return false;
    _awakeUntil = now.add(_awakeDuration);
    return true;
  }

  void setAiIssueSleepMode(bool enabled) {
    if (AppRuntimeConfig.keepPetAwake) {
      enabled = false;
    }
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

  // ---------------------------------------------------------------------------
  // Bond
  //
  // Kept separate from the activity rewards below on purpose. Those move the
  // fast survival stats and are called from anywhere something nice happened;
  // these are only ever called for something the player did in the target
  // language, so the ledger stays readable.
  // ---------------------------------------------------------------------------

  static bool _isSameDay(DateTime? a, DateTime b) =>
      a != null && a.year == b.year && a.month == b.month && a.day == b.day;

  /// Credits a learning event to the bond and returns the points actually
  /// awarded, which is 0 once [BondConstants.dailyCap] is reached.
  ///
  /// [units] is how many of the thing happened — messages exchanged, cards
  /// corrected — so callers can settle a whole session in one call.
  int recordLearning(BondSource source, {int units = 1}) {
    if (units <= 0) return 0;
    return _awardBond(BondProgress.pointsFor(source) * units);
  }

  /// Bond for a finished quiz, which is worth more the better it went.
  int recordQuizLearning({
    required int correctAnswers,
    required int totalQuestions,
  }) {
    return _awardBond(BondProgress.quizPoints(
      correctAnswers: correctAnswers,
      totalQuestions: totalQuestions,
    ));
  }

  /// Adds [raw] bond, trimmed to what today has left.
  ///
  /// [_lastLearningAt] advances even when the cap pays nothing: the player did
  /// learn, and the pet has no business acting like it missed them because
  /// they studied too much.
  int _awardBond(int raw) {
    final now = _now();
    if (!_isSameDay(_bondDay, now)) {
      _bondDay = now;
      _bondEarnedToday = 0;
    }

    final awarded = raw.clamp(0, bondRemainingToday);
    _bondPoints += awarded;
    _bondEarnedToday += awarded;
    _lastLearningAt = now;

    _savePetState();
    notifyListeners();
    return awarded;
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
    return _now().difference(_lastPetAt!) >= petCooldown;
  }

  /// Time until petting pays out again, or [Duration.zero] when it's ready.
  Duration get petCooldownRemaining {
    if (_lastPetAt == null) return Duration.zero;
    final elapsed = _now().difference(_lastPetAt!);
    final remaining = petCooldown - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Pets the pet. Always plays the reaction, however often it is asked for:
  /// petting is free and unlimited, and a pet that stopped responding to a
  /// hand after the first rub would read as broken. Only the *payout* is
  /// rationed, once per [petCooldown].
  ///
  /// Returns whether happiness was actually granted, which is what callers
  /// use to decide about hearts — the reward feedback belongs to the reward,
  /// not to the rub.
  bool petThePet() {
    // A pet dozing through an AI outage shouldn't perk up — registerInteraction
    // ignores it too, so the burst would never be cleared by a notify.
    if (_aiIssueSleepMode) return false;

    // Two reactions with different lifetimes: the rub itself, which lasts
    // about as long as the hand is there, and the contentment it leaves
    // behind, which outlives it.
    _startPettedReaction();
    _startHappyBurst();

    if (!canEarnFromPetting) {
      // The hot path, and the reason it does not just call
      // registerInteraction: petting is deliberately unlimited, so a single
      // sustained scratch lands here dozens of times. Nothing persisted has
      // changed — no stats, no bond, and the reaction above is in-memory
      // animation state — so the only save worth making is the one that
      // moves the wake window.
      if (_touchInteraction()) _savePetState();
      notifyListeners();
      return false;
    }

    _lastPetAt = _now();
    _happiness = (_happiness + _petHappinessGain).clamp(0, 100);
    _petPayouts++;
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

  /// Whether [swatch] is wearable — free, or already bought.
  bool ownsSwatch(PetSwatch swatch) =>
      ColorOwnership.isOwned(swatch, unlockedItemIds: _unlockedItems);

  /// Buys a coat or eye colour. Returns false without side effects when the
  /// swatch is free, already owned, or unaffordable.
  ///
  /// The colour is unlocked but not applied: buying and wearing are separate
  /// so the caller decides whether a purchase also repaints the pet (the
  /// wardrobe does, matching what buying a hat does there).
  Future<bool> purchaseSwatch(
    PetSwatch swatch,
    UserProvider userProvider,
  ) async {
    final price = swatch.price;
    if (price == null) return false;
    if (_unlockedItems.contains(swatch.id)) return false;
    if (userProvider.coins < price) return false;

    await userProvider.spendCoins(price);
    _unlockedItems.add(swatch.id);
    await _savePetState();
    notifyListeners();
    return true;
  }

  /// Sets the body + tail coat colour (always shared between the two) of the
  /// pet currently out. Other pets keep their own coat.
  ///
  /// A coat that has not been bought is ignored rather than applied, so the
  /// gate holds even if a caller skips the wardrobe's own check.
  void updateBodyColor(String hex) {
    if (design.bodyColor == hex) return;
    if (!ColorOwnership.isHexAllowed(
      hex,
      kAllBodySwatches,
      unlockedItemIds: _unlockedItems,
    )) {
      return;
    }
    _setDesign(design.copyWith(bodyColor: hex));
  }

  /// Updates the eye colouring of the pet currently out. [color2] is only
  /// meaningful for the heterochromia (right eye) mode.
  ///
  /// Rejected outright if either colour is unowned — including the mode
  /// switch, since a switch carries both colours and half-applying it would
  /// leave the eyes in a state the player did not ask for.
  void updateEyeColors({
    required EyeMode mode,
    required String color1,
    String? color2,
  }) {
    final second = color2 ?? design.eyeColor2;
    for (final hex in [color1, second]) {
      if (!ColorOwnership.isHexAllowed(
        hex,
        kAllEyeSwatches,
        unlockedItemIds: _unlockedItems,
      )) {
        return;
      }
    }
    _setDesign(design.copyWith(
      eyeMode: eyeModeToString(mode),
      eyeColor1: color1,
      eyeColor2: second,
    ));
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
