import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mojilearner_flutter/components/character_sprite.dart';
import 'package:mojilearner_flutter/components/scenario_stage.dart';
import 'package:mojilearner_flutter/components/shop_item_icon.dart';
import 'package:mojilearner_flutter/constants/scenarios.dart';
import 'package:mojilearner_flutter/constants/shop.dart';
import 'package:mojilearner_flutter/utils/pet_recolor.dart';

import '../helpers/mock_providers.dart';
import '../helpers/pump_app.dart';

/// The scene above a scenario chat, as far as buying a service goes: the
/// ticket on the table, and the pet eating what was paid for.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockCharacterProvider character;
  final restaurant = ScenarioCatalog.byId('restaurant')!;
  final pizza = shopItemById('pizza')!;

  setUp(() {
    character = MockCharacterProvider();
    when(() => character.currentCharacterType).thenReturn('cat');
    when(() => character.currentCharacterAsset)
        .thenReturn('assets/svgs/cat.svg');
    when(() => character.colorSpecFor(any())).thenReturn(const PetColorSpec(
      bodyColor: '#959379',
      eyeMode: EyeMode.solid,
      eyeColor1: '#F4C430',
      eyeColor2: '#5AA0E0',
    ));
    when(() => character.equippedAccessoriesFor(any())).thenReturn(const []);
  });

  Widget stage({
    ShopItem? offer,
    bool canAfford = true,
    VoidCallback? onPay,
    VoidCallback? onDecline,
    ShopItem? lastBought,
    int bought = 0,
  }) =>
      Column(children: [
        ScenarioStage(
          scenario: restaurant,
          learnerTurns: 1,
          hostTurns: 1,
          hostThinking: false,
          offer: offer,
          canAffordOffer: canAfford,
          onPay: onPay,
          onDecline: onDecline,
          lastBought: lastBought,
          servicesBought: bought,
        ),
      ]);

  testWidgets('an offer shows the dish, its price and the way to pay',
      (tester) async {
    var paid = 0;
    await pumpApp(tester, stage(offer: pizza, onPay: () => paid++),
        characterProvider: character);

    expect(find.text('PIZZA SLICE'), findsOneWidget);
    expect(find.text('${pizza.price}'), findsOneWidget);

    await tester.tap(find.text('BUY'));
    expect(paid, 1);
  });

  testWidgets('a dish the player cannot afford says so', (tester) async {
    await pumpApp(tester, stage(offer: pizza, canAfford: false),
        characterProvider: character);

    expect(find.text('BUY'), findsNothing);
    expect(find.text('TOO POOR'), findsOneWidget);
  });

  testWidgets('the offer can be turned down', (tester) async {
    var declined = 0;
    await pumpApp(tester, stage(offer: pizza, onDecline: () => declined++),
        characterProvider: character);

    await tester.tap(find.byIcon(Icons.close));
    expect(declined, 1);
  });

  testWidgets('paying plays the pet eating, then puts the dish away',
      (tester) async {
    await pumpApp(tester, stage(), characterProvider: character);
    expect(find.byType(ShopItemIcon), findsNothing);

    await pumpApp(tester, stage(lastBought: pizza, bought: 1),
        characterProvider: character);
    await tester.pump(const Duration(milliseconds: 100));

    CharacterSprite learner() => tester
        .widgetList<CharacterSprite>(find.byType(CharacterSprite))
        .firstWhere((sprite) => sprite.previewType == 'cat');

    expect(find.byType(ShopItemIcon), findsOneWidget);
    expect(learner().previewState, isNotNull);

    await tester.pump(const Duration(milliseconds: 1500));

    expect(find.byType(ShopItemIcon), findsNothing);
    expect(learner().previewState, isNull);
  });
}
