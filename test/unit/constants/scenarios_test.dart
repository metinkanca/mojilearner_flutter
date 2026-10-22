import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/constants/pets.dart';
import 'package:mojilearner_flutter/constants/scenarios.dart';
import 'package:mojilearner_flutter/constants/shop.dart';
import 'package:mojilearner_flutter/services/ai_prompt_spec.dart';

void main() {
  test('every scenario is hosted by a pet that ships art', () {
    for (final scenario in ScenarioCatalog.all) {
      expect(isKnownPetType(scenario.hostPet), isTrue,
          reason: '${scenario.id} is hosted by "${scenario.hostPet}"');
    }
  });

  group('services', () {
    test('each is ordered by a goal of its own scene, and is shop food', () {
      for (final scenario in ScenarioCatalog.all) {
        final service = scenario.service;
        if (service == null) continue;
        expect(scenario.hasObjective(service.objectiveId), isTrue,
            reason: '${scenario.id} orders on "${service.objectiveId}"');
        expect(shopItemById(service.itemId)?.type, 'food',
            reason: '${scenario.id} serves "${service.itemId}"');
      }
    });

    test('the restaurant serves a meal and the doctor medicine', () {
      expect(ScenarioCatalog.byId('restaurant')!.service?.itemId, 'pizza');
      expect(ScenarioCatalog.byId('doctor')!.service?.itemId, 'medicine');
    });

    test('come out only when the goal that orders them lands', () {
      final restaurant = ScenarioCatalog.byId('restaurant')!;

      expect(restaurant.serviceOrderedBy({'table'}), isNull);
      expect(restaurant.serviceOrderedBy({'table', 'order'})?.itemId, 'pizza');
      expect(ScenarioCatalog.byId('coffee')!.serviceOrderedBy({'order'}),
          isNull,
          reason: 'a scene without a service never offers one');
    });
  });

  group('AiPromptSpec.chat host', () {
    test('rides along with the scenario it hosts', () {
      final spec = AiPromptSpec.chat(
        targetCode: 'es',
        nativeCode: 'en',
        scenarioTitle: 'Ordering coffee',
        scenarioHost: 'fox',
      );

      expect(spec.params['scenario'],
          equals({'title': 'Ordering coffee', 'host': 'fox'}));
    });

    test('is left out when the scenario has none', () {
      final spec = AiPromptSpec.chat(
        targetCode: 'es',
        nativeCode: 'en',
        scenarioTitle: 'At the market',
      );

      expect(spec.params['scenario'], equals({'title': 'At the market'}));
    });
  });
}
