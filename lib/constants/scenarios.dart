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
import 'package:lucide_icons/lucide_icons.dart';

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

class ScenarioDefinition {
  const ScenarioDefinition({
    required this.id,
    required this.icon,
    required this.title,
    required this.objectives,
  });

  /// Stable id, e.g. 'coffee'. Persisted on the chat and on progress.
  final String id;
  final IconData icon;
  final String Function(AppLocalizations) title;
  final List<ScenarioObjective> objectives;

  /// Objectives that must be cleared for the scenario to count as complete.
  List<ScenarioObjective> get required =>
      objectives.where((o) => !o.isBonus).toList();

  int get requiredCount => required.length;

  bool hasObjective(String objectiveId) =>
      objectives.any((o) => o.id == objectiveId);
}

class ScenarioCatalog {
  ScenarioCatalog._();

  static const List<ScenarioDefinition> all = [
    ScenarioDefinition(
      id: 'coffee',
      icon: LucideIcons.coffee,
      title: _coffeeTitle,
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
      icon: LucideIcons.briefcase,
      title: _interviewTitle,
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
      icon: LucideIcons.map,
      title: _directionsTitle,
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
      icon: LucideIcons.stethoscope,
      title: _doctorTitle,
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
      icon: LucideIcons.store,
      title: _shoppingTitle,
      objectives: [
        ScenarioObjective(id: 'find', label: _objShoppingFind),
        ScenarioObjective(id: 'size', label: _objShoppingSize),
        ScenarioObjective(id: 'price', label: _objShoppingPrice),
        ScenarioObjective(id: 'pay', label: _objShoppingPay, isBonus: true),
      ],
    ),
    ScenarioDefinition(
      id: 'restaurant',
      icon: LucideIcons.utensils,
      title: _restaurantTitle,
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
