import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mojilearner_flutter/components/character_sprite.dart';
import 'package:mojilearner_flutter/components/pet_hearts.dart';
import 'package:mojilearner_flutter/components/quiz_stage.dart';
import 'package:mojilearner_flutter/constants/quiz_classroom_art.dart';

import '../helpers/mock_providers.dart';
import '../helpers/pump_app.dart';
import '../helpers/test_fixtures.dart';

/// The board both quiz screens are drawn on.
///
/// It exists because the onboarding quiz and the daily quiz were copies of
/// each other that had already drifted apart, so what these tests guard is
/// the shape they now share — the question chalked on the classroom's board
/// at the top, the teacher and the pet standing under it, the teacher's words
/// and the answers below, Continue at the bottom, and hearts when an answer
/// lands.
void main() {
  late MockCharacterProvider mockCharacter;

  setUp(() {
    mockCharacter = MockCharacterProvider();
    when(() => mockCharacter.currentCharacterType).thenReturn('cat');
    when(() => mockCharacter.currentCharacterAsset)
        .thenReturn('assets/svgs/cat.svg');
    when(() => mockCharacter.customization)
        .thenReturn(TestFixtures.buildCustomization());
    when(() => mockCharacter.isSleeping).thenReturn(false);
  });

  const longExplanation = 'Merhaba is how you say hello in Turkish, at any '
      'time of day, to a friend or to someone you have only just met.';

  Future<void> pumpStage(
    WidgetTester tester, {
    bool answered = false,
    int heartBurstId = 0,
    String bubbleText = 'You got this!',
    String prompt = 'Basic greeting in English',
    Size surfaceSize = kHandsetSurface,
  }) async {
    await pumpApp(
      tester,
      QuizStage(
        header: const SizedBox(key: ValueKey('header'), height: 48),
        badgeLabel: 'QUESTION 1/5',
        prompt: prompt,
        topic: 'Hello',
        options: const ['Merhaba', 'Hosca kal', 'Tesekkurler', 'Lutfen'],
        stateOf: (option) => !answered
            ? QuizOptionState.idle
            : option == 'Merhaba'
                ? QuizOptionState.correct
                : QuizOptionState.idle,
        onAnswer: answered ? null : (_) {},
        bubbleText: bubbleText,
        heartBurstId: heartBurstId,
        continueLabel: 'CONTINUE',
        onContinue: answered ? () {} : null,
      ),
      characterProvider: mockCharacter,
      surfaceSize: surfaceSize,
    );
    // Not pumpAndSettle: the pets' breathing animation never settles.
    await tester.pump(const Duration(milliseconds: 300));
  }

  /// The teacher is the only sprite drawn as a named pet; the player's pet
  /// is whatever the provider says.
  final teacherFinder = find.byWidgetPredicate(
      (w) => w is CharacterSprite && w.previewType != null);
  final learnerFinder = find.byWidgetPredicate(
      (w) => w is CharacterSprite && w.previewType == null);
  final boardFinder = find.byType(QuizChalkboard);
  // The classroom is one picture shown in two halves, cut at a row of plain
  // wall: the wall with the board on it, and the floor with the shelf, the pot
  // and the pets. A tall phone's spare height falls between them.
  final wallFinder = find.byType(QuizClassWall);
  final floorFinder = find.byType(QuizClassFloor);

  /// How many screen pixels one unit of the classroom picture is.
  double scaleOf(WidgetTester tester) =>
      tester.getSize(wallFinder).width / QuizClassroomArt.width;

  /// How much taller than the picture's own wall the wall half is drawn: the
  /// height a tall phone had spare, which the board grows into.
  double grownOf(WidgetTester tester) =>
      tester.getRect(wallFinder).height -
      QuizClassroomArt.wallCut * scaleOf(tester);

  /// Where a row of the picture is on screen. The wall half starts at the
  /// picture's top, the floor half at its cut.
  double rowOnScreen(WidgetTester tester, double row) {
    final s = scaleOf(tester);
    return row < QuizClassroomArt.wallCut
        ? tester.getRect(wallFinder).top + row * s
        : tester.getRect(floorFinder).top +
            (row - QuizClassroomArt.wallCut) * s;
  }

  testWidgets('the question is on the board, above the class and the answers',
      (tester) async {
    await pumpStage(tester);

    final wall = tester.getRect(wallFinder);
    final board = tester.getRect(boardFinder);
    final teacher = tester.getRect(teacherFinder);
    final learner = tester.getRect(learnerFinder);
    final answers = tester.getRect(find.byType(QuizOptionGrid));

    // Written on the board, which hangs at the top of the picture.
    expect(find.descendant(of: boardFinder, matching: find.text('Hello')),
        findsOneWidget);
    expect(board.top, lessThan(wall.top + wall.height * 0.2));
    // The class stands under it, the answers under them.
    expect(teacher.top, greaterThanOrEqualTo(board.bottom));
    expect(learner.top, greaterThanOrEqualTo(board.bottom));
    expect(answers.top, greaterThanOrEqualTo(learner.bottom));
    // Facing each other across the room: teacher on the left.
    expect(teacher.center.dx, lessThan(learner.center.dx));
    // And drawn at a size worth looking at, not as a footnote.
    expect(learner.height * 238 / 328, greaterThanOrEqualTo(90));
  });

  testWidgets('the writing sits on the board\'s green, from the picture\'s '
      'own numbers', (tester) async {
    await pumpStage(tester);

    final s = scaleOf(tester);
    final wall = tester.getRect(wallFinder);
    final board = tester.getRect(boardFinder);

    expect(board.left, closeTo(wall.left + QuizClassroomArt.faceLeft * s, 1));
    expect(board.right, closeTo(wall.left + QuizClassroomArt.faceRight * s, 1));
    // The green runs down as far as the board has grown.
    expect(board.bottom,
        closeTo(wall.top + QuizClassroomArt.faceBottom * s + grownOf(tester), 1));
    // The badge is centred on the frame's top edge.
    final badge = tester.getRect(find.text('QUESTION 1/5'));
    expect(badge.center.dy,
        closeTo(wall.top + QuizClassroomArt.frameTop * s, 2));
  });

  testWidgets('a long question is written smaller, not off the board',
      (tester) async {
    await pumpStage(
      tester,
      prompt: 'Which of these is the word you would use to greet a friend '
          'you meet in the street in the morning?',
    );

    final board = tester.getRect(boardFinder);
    final prompt = tester.getRect(find.textContaining('Which of these'));
    final topic = tester.getRect(find.text('Hello'));
    for (final words in [prompt, topic]) {
      expect(words.top, greaterThanOrEqualTo(board.top));
      expect(words.bottom, lessThanOrEqualTo(board.bottom + 0.5));
      expect(words.left, greaterThanOrEqualTo(board.left - 0.5));
      expect(words.right, lessThanOrEqualTo(board.right + 0.5));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('the class stands on the floor, under the board',
      (tester) async {
    await pumpStage(tester);

    final s = scaleOf(tester);
    final wall = tester.getRect(wallFinder);
    for (final pet in [teacherFinder, learnerFinder]) {
      final canvas = tester.getRect(pet);
      // Feet on the picture's standing row, below the line the wall ends at.
      expect(canvas.bottom,
          closeTo(rowOnScreen(tester, QuizClassroomArt.standRow), 1));
      expect(canvas.bottom,
          greaterThan(rowOnScreen(tester, QuizClassroomArt.floorLine)));
      // The hat headroom reaches no higher than the bottom of the writing,
      // so no hat is ever over the question.
      expect(canvas.top,
          greaterThanOrEqualTo(tester.getRect(boardFinder).bottom - 0.5));
    }
    expect(tester.getCenter(teacherFinder).dx,
        closeTo(wall.left + QuizClassroomArt.teacherX * s, 1));
    expect(tester.getCenter(learnerFinder).dx,
        closeTo(wall.left + QuizClassroomArt.learnerX * s, 1));
  });

  // The owner asked for the top of the screen to be the room, not a band of
  // empty wall over it: the board hangs straight under the header. And for
  // the shelf, the pot and the pets to come down to the answers, with the board
  // grown down to just above the shelf: a tall phone's spare height is no
  // stretch of empty floor between the teacher's words and the answers, and
  // no band of empty wall under the board either. The board takes it.
  testWidgets('the board starts under the header and grows into the spare '
      'height, down to the shelf', (tester) async {
    await pumpStage(tester, answered: true,
        surfaceSize: const Size(430, 932));

    final header = tester.getRect(find.byKey(const ValueKey('header')));
    final wall = tester.getRect(wallFinder);
    final floor = tester.getRect(floorFinder);
    final board = tester.getRect(boardFinder);
    final answers = tester.getRect(find.byType(QuizOptionGrid));
    final button = tester.getRect(find.text('CONTINUE'));
    final s = scaleOf(tester);

    // Only the header's own padding between them.
    expect(wall.top, closeTo(header.bottom + 16, 0.5));
    // The wall is taller than the picture's own, by the spare height...
    expect(grownOf(tester), greaterThan(40));
    // ...all of it board: the green ends the same distance above the wall's
    // end (and so above the shelf) as it does in the picture.
    expect(board.bottom,
        closeTo(wall.bottom - (QuizClassroomArt.wallCut - QuizClassroomArt.faceBottom) * s, 1));
    // Nothing is left between the halves, or between the teacher's words and
    // the answers, and the last row of answers ends where Continue starts.
    expect(floor.top, closeTo(wall.bottom, 0.5));
    expect(answers.top, closeTo(floor.bottom, 0.5));
    expect(button.top - answers.bottom, lessThan(40));
  });

  testWidgets('on a phone with no height to spare the board is the '
      'picture\'s own', (tester) async {
    await pumpStage(tester, surfaceSize: const Size(320, 568));

    final s = scaleOf(tester);
    expect(grownOf(tester), closeTo(0, 0.5));
    expect(tester.getRect(floorFinder).top,
        closeTo(tester.getRect(wallFinder).bottom, 0.5));
    // The halves together are the picture, whole.
    expect(
        tester.getRect(wallFinder).height +
            tester.getRect(floorFinder).height -
            QuizClassFloor.bubbleBand,
        closeTo(QuizClassroomArt.height * s, 0.5));
  });

  testWidgets('the teacher is the parrot, dressed for class', (tester) async {
    await pumpStage(tester);

    final teacher = tester.widget<CharacterSprite>(teacherFinder);
    expect(teacher.previewType, kQuizTeacherPet);
    expect(teacher.previewAccessories!.map((a) => a.id),
        containsAll(kQuizTeacherOutfit));
    // In its own colours, not the player's.
    expect(teacher.naturalCoat, isTrue);
  });

  testWidgets('a parrot learns from the stand-in teacher', (tester) async {
    when(() => mockCharacter.currentCharacterType).thenReturn('parrot');
    await pumpStage(tester);

    expect(tester.widget<CharacterSprite>(teacherFinder).previewType,
        kQuizTeacherStandIn);
    expect(quizTeacherFor('dog'), kQuizTeacherPet);
    expect(quizTeacherFor(kQuizTeacherPet), isNot(kQuizTeacherPet));
  });

  testWidgets('Continue sits below the answers, at the bottom of the screen',
      (tester) async {
    await pumpStage(tester, answered: true);

    final answers = tester.getRect(find.byType(QuizOptionGrid));
    final button = tester.getRect(find.text('CONTINUE'));
    final screen = tester.getRect(find.byType(QuizStage));

    expect(button.top, greaterThanOrEqualTo(answers.bottom));
    // Within a bar's own padding of the bottom edge. Anything more means it
    // has drifted back up into the scrolling content.
    expect(screen.bottom - button.bottom, lessThan(60));
  });

  // The button used to be inserted into the column the moment an answer
  // landed, which shoved the pet and the options upward at exactly the moment
  // the player was reading the explanation. The explanation is also longer
  // than the encouragement it replaces, and must not push anything either.
  testWidgets('answering does not move the board', (tester) async {
    await pumpStage(tester);
    final teacherBefore = tester.getRect(teacherFinder);
    final learnerBefore = tester.getRect(learnerFinder);
    final boardBefore = tester.getRect(boardFinder);
    final answersBefore = tester.getRect(find.byType(QuizOptionGrid));

    await pumpStage(tester, answered: true, bubbleText: longExplanation);

    expect(tester.getRect(teacherFinder), teacherBefore);
    expect(tester.getRect(learnerFinder), learnerBefore);
    expect(tester.getRect(boardFinder), boardBefore);
    expect(tester.getRect(find.byType(QuizOptionGrid)), answersBefore);
  });

  testWidgets('the teacher\'s words sit under the class, above the answers',
      (tester) async {
    await pumpStage(tester, answered: true, bubbleText: longExplanation);

    final words = tester.getRect(find.textContaining('Merhaba is how'));
    final floor = tester.getRect(floorFinder);
    final answers = tester.getRect(find.byType(QuizOptionGrid));

    // Below the picture, so they cover neither pet nor the board.
    expect(words.top,
        greaterThanOrEqualTo(floor.bottom - QuizClassFloor.bubbleBand));
    expect(words.bottom, lessThanOrEqualTo(answers.top));
  });

  testWidgets('hearts ride with the pet, ready to burst', (tester) async {
    await pumpStage(tester);

    final hearts = find.byType(PetHearts);
    expect(hearts, findsOneWidget);
    expect(tester.widget<PetHearts>(hearts).burstId, 0);
    // Over the player's pet, not the teacher: the hearts are its.
    expect(tester.getCenter(hearts).dx,
        closeTo(tester.getCenter(learnerFinder).dx, 1));

    // A right answer bumps the id, which is the whole trigger. Same signal
    // the home screen uses for petting.
    await pumpStage(tester, answered: true, heartBurstId: 1);
    expect(tester.widget<PetHearts>(find.byType(PetHearts)).burstId, 1);
  });

  testWidgets('the badge keeps its count on a narrow phone', (tester) async {
    await pumpStage(tester, surfaceSize: const Size(320, 568));

    // Wider than the board's green at this width; it reaches over the frame
    // instead of being cut short.
    final badge = tester.getRect(find.text('QUESTION 1/5'));
    final textWidth = tester
        .renderObject<RenderParagraph>(find.text('QUESTION 1/5'))
        .getMaxIntrinsicWidth(double.infinity);
    expect(badge.width, greaterThanOrEqualTo(textWidth - 0.5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('lays out without overflow on a short screen', (tester) async {
    await pumpStage(tester, surfaceSize: const Size(320, 568));
    expect(tester.takeException(), isNull);

    // Short enough that the board has to scroll, and the button still has to
    // be reachable underneath it rather than scrolled away with the content.
    final button = tester.getRect(find.text('CONTINUE'));
    expect(button.bottom, lessThanOrEqualTo(568));
  });

  testWidgets('lays out without overflow on a tall screen', (tester) async {
    await pumpStage(tester, surfaceSize: const Size(430, 932));
    expect(tester.takeException(), isNull);
  });
}
