/// The scenario catalogue: what quests exist, and what counts as clearing one.
///
/// Objectives are deliberately *communicative goals*, not target words. The
/// app ships ~30 target languages, so per-language vocabulary lists would
/// mean authoring six scenarios times thirty languages and re-doing it for
/// every new scenario. A goal like "ask what it costs" is language-neutral,
/// authored once, and judged by the tutor.
///
/// The vocabulary side falls out for free: words captured during a scenario
/// flow into the review queue through the normal chat pipeline.
library;

import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../l10n/app_localizations.dart';

/// One goal within a scenario.
class ScenarioObjective {
  const ScenarioObjective({
    required this.id,
    required this.label,
    this.isBonus = false,
  });

  /// Stable id, unique within its scenario. This is what the tutor reports
  /// and what progress is stored against — never the label.
  final String id;

  /// Resolves the localized description.
  final String Function(AppLocalizations) label;

  /// Bonus objectives are shown and rewarded but not required to clear the
  /// scenario, so a learner isn't blocked by the hardest goal.
  final bool isBonus;
}

/// Something a scenario's host does for the player's pet, paid for in the
/// scene: the restaurant serves a meal, the doctor gives a checkup.
class ScenarioService {
  const ScenarioService({required this.objectiveId, required this.itemId});

  /// The goal that asks for it — ordering, describing the symptom. It is
  /// offered the moment the tutor reports that goal, so the sentence that
  /// earned it is the one that brings it to the table.
  final String objectiveId;

  /// The shop item it is. Price and effect are read from the shelf, so a meal
  /// at the restaurant costs and fills exactly what the same dish bought in
  /// the shop does, and food stays the coin sink the economy leans on.
  final String itemId;
}

class ScenarioDefinition {
  const ScenarioDefinition({
    required this.id,
    required this.icon,
    required this.title,
    required this.place,
    required this.objectives,
    required this.hostPet,
    this.service,
  });

  /// Stable id, e.g. 'coffee'. Persisted on the chat and on progress.
  final String id;
  final IconData icon;
  /// What the player practises here ("Ordering Coffee"): on the go button.
  final String Function(AppLocalizations) title;

  /// The building itself ("Café"): the name on its card in the town.
  final String Function(AppLocalizations) place;
  final List<ScenarioObjective> objectives;

  /// The pet playing the other side of the scene — the barista, the
  /// interviewer. A type from `kPetTypes`: it stands at the door on the city
  /// map, faces the player's pet in the chat, and is who the tutor plays.
  final String hostPet;

  /// What the host can do for the pet here, or null for a scene that is
  /// conversation only.
  final ScenarioService? service;

  /// Objectives that must be cleared for the scenario to count as complete.
  List<ScenarioObjective> get required =>
      objectives.where((o) => !o.isBonus).toList();

  int get requiredCount => required.length;

  bool hasObjective(String objectiveId) =>
      objectives.any((o) => o.id == objectiveId);

  /// This scene's service, when the goal that asks for it is among
  /// [newlyCleared] — the moment the host brings it out.
  ScenarioService? serviceOrderedBy(Iterable<String> newlyCleared) {
    final offered = service;
    if (offered == null || !newlyCleared.contains(offered.objectiveId)) {
      return null;
    }
    return offered;
  }
}

class ScenarioCatalog {
  ScenarioCatalog._();

  static const List<ScenarioDefinition> all = [
    ScenarioDefinition(
      id: 'coffee',
      hostPet: 'fox',
      icon: LucideIcons.coffee,
      title: _coffeeTitle,
      place: _cafePlace,
      objectives: [
        ScenarioObjective(id: 'order', label: _objCoffeeOrder),
        ScenarioObjective(id: 'customize', label: _objCoffeeCustomize),
        ScenarioObjective(id: 'price', label: _objCoffeePrice),
        ScenarioObjective(
            id: 'small_talk', label: _objCoffeeSmallTalk, isBonus: true),
      ],
    ),
    ScenarioDefinition(
      id: 'job_interview',
      hostPet: 'rabbit',
      icon: LucideIcons.briefcase,
      title: _interviewTitle,
      place: _townHallPlace,
      objectives: [
        ScenarioObjective(id: 'greet', label: _objInterviewGreet),
        ScenarioObjective(id: 'experience', label: _objInterviewExperience),
        ScenarioObjective(id: 'strength', label: _objInterviewStrength),
        ScenarioObjective(
            id: 'ask_back', label: _objInterviewAsk, isBonus: true),
      ],
    ),
    ScenarioDefinition(
      id: 'directions',
      hostPet: 'dog',
      icon: LucideIcons.map,
      title: _directionsTitle,
      place: _gazeboPlace,
      objectives: [
        ScenarioObjective(id: 'ask', label: _objDirectionsAsk),
        ScenarioObjective(id: 'clarify', label: _objDirectionsClarify),
        ScenarioObjective(id: 'distance', label: _objDirectionsDistance),
        ScenarioObjective(
            id: 'thank', label: _objDirectionsThank, isBonus: true),
      ],
    ),
    ScenarioDefinition(
      id: 'doctor',
      hostPet: 'cat',
      service: ScenarioService(objectiveId: 'symptom', itemId: 'medicine'),
      icon: LucideIcons.stethoscope,
      title: _doctorTitle,
      place: _hospitalPlace,
      objectives: [
        ScenarioObjective(id: 'symptom', label: _objDoctorSymptom),
        ScenarioObjective(id: 'duration', label: _objDoctorDuration),
        ScenarioObjective(id: 'question', label: _objDoctorQuestion),
        ScenarioObjective(
            id: 'allergy', label: _objDoctorAllergy, isBonus: true),
      ],
    ),
    ScenarioDefinition(
      id: 'shopping',
      hostPet: 'hamster',
      icon: LucideIcons.store,
      title: _shoppingTitle,
      place: _shopPlace,
      objectives: [
        ScenarioObjective(id: 'find', label: _objShoppingFind),
        ScenarioObjective(id: 'size', label: _objShoppingSize),
        ScenarioObjective(id: 'price', label: _objShoppingPrice),
        ScenarioObjective(id: 'pay', label: _objShoppingPay, isBonus: true),
      ],
    ),
    ScenarioDefinition(
      id: 'restaurant',
      hostPet: 'axolotl',
      service: ScenarioService(objectiveId: 'order', itemId: 'pizza'),
      icon: LucideIcons.utensils,
      title: _restaurantTitle,
      place: _restaurantPlace,
      objectives: [
        ScenarioObjective(id: 'table', label: _objRestaurantTable),
        ScenarioObjective(id: 'order', label: _objRestaurantOrder),
        ScenarioObjective(id: 'drink', label: _objRestaurantDrink),
        ScenarioObjective(id: 'bill', label: _objRestaurantBill, isBonus: true),
      ],
    ),
  ];

  static ScenarioDefinition? byId(String? id) {
    if (id == null) return null;
    for (final scenario in all) {
      if (scenario.id == id) return scenario;
    }
    return null;
  }
}

// Tear-offs, so the catalogue above can stay `const`.
String _coffeeTitle(AppLocalizations l) => l.orderingCoffee;
String _interviewTitle(AppLocalizations l) => l.jobInterview;
String _directionsTitle(AppLocalizations l) => l.askingDirections;
String _doctorTitle(AppLocalizations l) => l.atTheDoctor;
String _shoppingTitle(AppLocalizations l) => l.shopping;
String _restaurantTitle(AppLocalizations l) => l.restaurant;

String _cafePlace(AppLocalizations l) => l.placeCafe;
String _townHallPlace(AppLocalizations l) => l.placeTownHall;
String _gazeboPlace(AppLocalizations l) => l.placeGazebo;
String _hospitalPlace(AppLocalizations l) => l.placeHospital;
String _shopPlace(AppLocalizations l) => l.placeShop;
String _restaurantPlace(AppLocalizations l) => l.restaurant;

String _objCoffeeOrder(AppLocalizations l) => l.objCoffeeOrder;
String _objCoffeeCustomize(AppLocalizations l) => l.objCoffeeCustomize;
String _objCoffeePrice(AppLocalizations l) => l.objCoffeePrice;
String _objCoffeeSmallTalk(AppLocalizations l) => l.objCoffeeSmallTalk;

String _objInterviewGreet(AppLocalizations l) => l.objInterviewGreet;
String _objInterviewExperience(AppLocalizations l) => l.objInterviewExperience;
String _objInterviewStrength(AppLocalizations l) => l.objInterviewStrength;
String _objInterviewAsk(AppLocalizations l) => l.objInterviewAsk;

String _objDirectionsAsk(AppLocalizations l) => l.objDirectionsAsk;
String _objDirectionsClarify(AppLocalizations l) => l.objDirectionsClarify;
String _objDirectionsDistance(AppLocalizations l) => l.objDirectionsDistance;
String _objDirectionsThank(AppLocalizations l) => l.objDirectionsThank;

String _objDoctorSymptom(AppLocalizations l) => l.objDoctorSymptom;
String _objDoctorDuration(AppLocalizations l) => l.objDoctorDuration;
String _objDoctorQuestion(AppLocalizations l) => l.objDoctorQuestion;
String _objDoctorAllergy(AppLocalizations l) => l.objDoctorAllergy;

String _objShoppingFind(AppLocalizations l) => l.objShoppingFind;
String _objShoppingSize(AppLocalizations l) => l.objShoppingSize;
String _objShoppingPrice(AppLocalizations l) => l.objShoppingPrice;
String _objShoppingPay(AppLocalizations l) => l.objShoppingPay;

String _objRestaurantTable(AppLocalizations l) => l.objRestaurantTable;
String _objRestaurantOrder(AppLocalizations l) => l.objRestaurantOrder;
String _objRestaurantDrink(AppLocalizations l) => l.objRestaurantDrink;
String _objRestaurantBill(AppLocalizations l) => l.objRestaurantBill;
