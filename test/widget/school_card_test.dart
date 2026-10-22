import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mojilearner_flutter/components/character_sprite.dart';
import 'package:mojilearner_flutter/components/scenario_city.dart';
import 'package:mojilearner_flutter/constants/entitlements.dart';
import 'package:mojilearner_flutter/screens/scenarios_screen.dart';
import 'package:mojilearner_flutter/utils/pet_recolor.dart';

import '../helpers/mock_providers.dart';
import '../helpers/pump_app.dart';

/// The school is the way into the quizzes. The pet walks to its door first, like
/// every other place; tapping it shows how many of today's quizzes have been
/// used; and the quiz starts from there.
void main() {
  late MockSettingsProvider settings;
  late MockCharacterProvider character;
  late MockUserProvider user;

  setUp(() {
    settings = MockSettingsProvider();
    when(() => settings.usePixelFont).thenReturn(true);
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
    user = MockUserProvider();
  });

  GoRouter router() => GoRouter(routes: [
        GoRoute(path: '/', builder: (_, __) => const ScenariosScreen()),
        GoRoute(
          path: '/quiz',
          builder: (_, __) => const Scaffold(body: Text('the quiz', key: ValueKey('quiz-page'))),
        ),
      ]);

  Future<void> pumpTown(WidgetTester tester, GoRouter r) => pumpAppWithRouter(
        tester,
        r,
        settingsProvider: settings,
        characterProvider: character,
        userProvider: user,
      );

  /// A tap on the school, as the map reports it. Called rather than tapped: the
  /// school is at the top of a town taller than the screen, and the map opens
  /// scrolled to its foot.
  void tapSchool(WidgetTester tester) {
    final school = tester.widget<CityBuilding>(find.byWidgetPredicate(
        (w) => w is CityBuilding && w.scenario == null));
    school.onTap();
  }

  testWidgets('the card is not there until the school is picked',
      (tester) async {
    await pumpTown(tester, router());
    await tester.pump();

    expect(find.byKey(const ValueKey('school-card')), findsNothing);
  });

  testWidgets('picking the school shows how many of today\'s quizzes are used',
      (tester) async {
    await pumpTown(tester, router());
    await tester.pump();

    await user.spendAi(AiSpend.quiz);
    tapSchool(tester);
    await tester.pump();

    expect(find.byKey(const ValueKey('school-card')), findsOneWidget);
    expect(
        find.descendant(
            of: find.byKey(const ValueKey('school-card')),
            matching: find.text('SCHOOL')),
        findsOneWidget);
    // One of the day's quizzes spent.
    expect(find.text('1 of ${user.aiLimit(AiSpend.quiz)} used today'),
        findsOneWidget);
  });

  testWidgets('a member, whose allowance is not worth counting, is told what '
      'the quiz is instead', (tester) async {
    user.isPremium = true;
    await pumpTown(tester, router());
    await tester.pump();

    tapSchool(tester);
    await tester.pump();

    expect(find.byKey(const ValueKey('school-card')), findsOneWidget);
    expect(find.textContaining('used today'), findsNothing);
    expect(find.text('Test your knowledge with active recall quizzes.'),
        findsOneWidget);
  });

  testWidgets('the door on its card starts a quiz, with the town still under it',
      (tester) async {
    final r = router();
    await pumpTown(tester, r);
    await tester.pump();

    tapSchool(tester);
    await tester.pump();
    await tester.tap(find.byIcon(LucideIcons.doorOpen));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('quiz-page')), findsOneWidget);
    // Pushed, not gone to: backing out lands in the town.
    r.pop();
    await tester.pumpAndSettle();
    expect(find.byType(ScenarioCityMap), findsOneWidget);
  });

  testWidgets('the pet walks to the school\'s door first', (tester) async {
    await pumpTown(tester, router());
    await tester.pump();

    Offset feet() {
      final at = tester.widget<Positioned>(find
          .ancestor(
              of: find.byType(CharacterSprite), matching: find.byType(Positioned))
          .first);
      // Its box is 124 square, centred on the door, standing on the paving.
      return Offset(at.left! + 62, at.top! + 124);
    }

    const layout = CityLayout(6);
    final start = feet();
    expect(start, layout.start);

    tapSchool(tester);
    await tester.pump();
    // Underway, not there: it has to walk the paths first.
    await tester.pump(const Duration(milliseconds: 400));
    expect(feet(), isNot(layout.schoolDoorSpot));
    expect(feet(), isNot(start));

    // And arrives at the door, standing on the sidewalk in front of it. A frame
    // at a time: the walk caps how far one frame can carry it.
    for (var i = 0; i < 600; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(feet().dx, closeTo(layout.schoolDoorSpot.dx, 0.5));
    expect(feet().dy, closeTo(layout.schoolDoorSpot.dy, 0.5));
  });
}
