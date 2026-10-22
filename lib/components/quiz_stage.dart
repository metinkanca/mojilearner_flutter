/// The chrome of a quiz round, owned in one place.
///
/// Two screens ask questions — the onboarding calibration quiz and the daily
/// one — and they were built as copies of each other. Copies drift, and these
/// had: options were centred on one screen and flush-left on the other, the
/// Continue button floated at a different height in each, and only one of
/// them said "PREPARING...". A player who met the pet through onboarding and
/// then opened a real quiz was looking at two slightly different games.
///
/// So everything a player sees of a question lives here, and the two screens
/// supply only what actually differs between them: where the questions came
/// from, what the top bar carries, and what happens on Continue.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/accessories.dart';
import '../constants/quiz_classroom_art.dart';
import '../constants/theme.dart';
import '../l10n/app_localizations.dart';
import '../providers/character_provider.dart';
import '../utils/fonts.dart';
import '../utils/rtl_locale.dart';
import 'character_sprite.dart';
import 'pet_hearts.dart';
import 'rasterized_svg.dart';
import 'spare_height_column.dart';
import 'speech_bubble_tail.dart';
import 'tutorial/retro_showcase.dart';

/// The quiz tour's steps, in the order it visits them.
///
/// Here rather than on the screen because this is where the pieces are built.
/// The onboarding placement quiz uses the same stage and simply leaves
/// [QuizStage.showcase] off, so nothing about it changes.
final GlobalKey quizHeaderShowcaseKey = GlobalKey();
final GlobalKey quizQuestionShowcaseKey = GlobalKey();
final GlobalKey quizOptionsShowcaseKey = GlobalKey();
final GlobalKey quizContinueShowcaseKey = GlobalKey();

/// How an option should be drawn, once the answer is in.
enum QuizOptionState {
  /// No answer yet, or this option was neither picked nor correct.
  idle,

  /// The right answer, revealed.
  correct,

  /// What the player picked, and it was wrong.
  wrong,
}

/// Who teaches the class: the parrot, the one animal famous for repeating
/// words back, in a game about learning to say them.
const String kQuizTeacherPet = 'parrot';

/// Who teaches instead when the player's own pet is a parrot. Two of the same
/// animal facing each other read as a mirror, not as a lesson.
const String kQuizTeacherStandIn = 'koala';

/// What makes a pet the teacher rather than a classmate. Shared wardrobe
/// pieces, so every pet already wears them properly.
const List<String> kQuizTeacherOutfit = ['glasses', 'bowtie'];

/// The teacher for a player whose pet is [learnerType].
String quizTeacherFor(String learnerType) =>
    learnerType == kQuizTeacherPet ? kQuizTeacherStandIn : kQuizTeacherPet;

/// The classroom's colours.
///
/// The wall and floor are the cozy room's own fills, and the classroom picture
/// is drawn in them too: the screen paints flat wall above the picture and
/// flat floor below it, and the seams would otherwise show.
abstract final class QuizClassroom {
  static const Color wall = Color(0xFFF2E3C6);
  static const Color floor = Color(0xFFC58C56);

  /// The chalkboard's green, the picture's own. Drawn by the stand-in board
  /// that shows until the picture has loaded.
  static const Color board = Color(0xFF3F6653);

  /// The question, written large.
  static const Color chalk = Color(0xFFF6F0DC);

  /// The instruction line above it, rubbed half out.
  static const Color chalkFaint = Color(0xFFCFE3D8);
}

/// The question, chalked on the classroom's board: the badge across the top
/// of the frame, the instruction line, and the thing being asked about.
///
/// It has no board of its own. [QuizClassWall] lays it over the picture's
/// board, from the badge's top down to the bottom of the clear green, and a
/// question too long for that is written smaller rather than spilling off.
class QuizChalkboard extends StatelessWidget {
  const QuizChalkboard({
    super.key,
    required this.badgeLabel,
    required this.prompt,
    required this.topic,
  });

  /// The pill across the frame's top edge, e.g. "QUESTION 3/5".
  final String badgeLabel;

  /// The small instruction line.
  final String prompt;

  /// The thing being asked about, set large.
  final String topic;

  /// How far the badge reaches above the frame's top edge, and below it.
  static const double badgeHalf = 11;

  /// Room left between the writing and the frame on every side.
  static const double _margin = 6;

  @override
  Widget build(BuildContext context) {
    final textDirection =
        textDirectionForLocale(Localizations.localeOf(context));

    return Column(
      children: [
        // As wide as its words, not as the green: on a narrow phone the label
        // is wider than the board's face, and it reaches out over the frame
        // rather than losing its count.
        SizedBox(
          height: 2 * badgeHalf,
          child: OverflowBox(
            maxWidth: double.infinity,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: AppTheme.retroPrimary,
                border: Border.all(color: AppTheme.retroDark, width: 3),
              ),
              // Centred down the badge's height, but only as wide as the
              // words: anything that fills its width would fill the overflow.
              child: Align(
                widthFactor: 1,
                child: Text(
                  badgeLabel,
                  textDirection: textDirection,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: AppFonts.pressStart2p(
                    fontSize: 8,
                    color: Colors.white,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(_margin),
            child: LayoutBuilder(
              builder: (context, constraints) => Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: SizedBox(
                    width: constraints.maxWidth,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          prompt,
                          textDirection: textDirection,
                          textAlign: TextAlign.center,
                          style: AppFonts.pressStart2p(
                            fontSize: 8,
                            height: 1.5,
                            color: QuizClassroom.chalkFaint,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          topic,
                          textDirection: textDirection,
                          textAlign: TextAlign.center,
                          style: AppFonts.pressStart2p(
                            fontSize: 14,
                            height: 1.3,
                            color: QuizClassroom.chalk,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The answers, two to a row.
class QuizOptionGrid extends StatelessWidget {
  const QuizOptionGrid({
    super.key,
    required this.options,
    required this.stateOf,
    required this.onAnswer,
  });

  final List<String> options;

  /// How to draw each option, given the answer state the screen is holding.
  final QuizOptionState Function(String option) stateOf;

  /// Null while an answer is being shown, so a revealed board is inert.
  final ValueChanged<String>? onAnswer;

  Color _colorFor(QuizOptionState state) => switch (state) {
        QuizOptionState.idle => Colors.white,
        QuizOptionState.correct => AppTheme.retroGrass,
        QuizOptionState.wrong => AppTheme.retroPrimary,
      };

  Widget _tile(BuildContext context, String option) {
    final onAnswer = this.onAnswer;

    return GestureDetector(
      onTap: onAnswer == null ? null : () => onAnswer(option),
      // A floor rather than a fixed shape. The tiles used to be squarish, and
      // with the class standing above the board there is no longer the height
      // for that; a long answer grows its row instead of being cut off.
      child: Container(
        constraints: const BoxConstraints(minHeight: 60),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: _colorFor(stateOf(option)),
          border: Border.all(color: AppTheme.retroDark, width: 4),
          boxShadow: const [
            BoxShadow(
              color: AppTheme.retroDark,
              offset: Offset(4, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: Text(
          option,
          textDirection:
              textDirectionForLocale(Localizations.localeOf(context)),
          // Centred, not start-aligned: the tile is a target with the answer
          // alone in it, and text pinned to one edge of it read as a
          // misalignment rather than as a reading direction.
          textAlign: TextAlign.center,
          style: AppFonts.pressStart2p(
            fontSize: 10,
            color: AppTheme.retroDark,
            height: 1.5,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        children: [
          for (int i = 0; i < options.length; i += 2)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              // Both tiles of a row as tall as the taller one.
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _tile(context, options[i])),
                    const SizedBox(width: 16),
                    if (i + 1 < options.length)
                      Expanded(child: _tile(context, options[i + 1]))
                    else
                      const Spacer(),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The classroom's wall: the top of the picture with the question written on
/// its board.
///
/// The classroom is one picture, but it is shown in two halves cut at
/// [QuizClassroomArt.wallCut], a row of plain wall between the board and the
/// shelf and the pot. This is the half over the cut; [QuizClassFloor] is the
/// half under it. On a phone with height to spare the shelf, the pot and the
/// pets come down to the answers, and this half takes the height they left:
/// the board grows into it, down to the same small gap above the shelf it has
/// on a phone with none to spare.
///
/// It grows by repeating one row of its clear green — the picture's own
/// stretch does the same — so the wall is shown in three slices: what is over
/// that row, the row itself, drawn as tall as it needs to be, and what is
/// under it, the tray with its eraser.
///
/// Everything is placed by the picture's own numbers ([QuizClassroomArt],
/// written by `art_src/gen_classroom.py`) scaled to the width it is drawn at,
/// so the writing lands on the board on any phone.
class QuizClassWall extends StatelessWidget {
  const QuizClassWall({super.key, required this.board});

  /// What is written on the board — a [QuizChalkboard], possibly wrapped in a
  /// coach mark. Laid over the board from the top of its badge to the bottom
  /// of the clear green, which is as tall as the board has grown.
  final Widget board;

  static const double _rows = QuizClassroomArt.height;

  /// The slice over the grown row, the row itself, and the slice under it up
  /// to the cut, as fractions of the picture's height.
  static const Rect _over =
      Rect.fromLTRB(0, 0, 1, QuizClassroomArt.growRow / _rows);
  static const Rect _row = Rect.fromLTRB(0, QuizClassroomArt.growRow / _rows, 1,
      (QuizClassroomArt.growRow + 1) / _rows);
  static const Rect _under = Rect.fromLTRB(
      0,
      (QuizClassroomArt.growRow + 1) / _rows,
      1,
      QuizClassroomArt.wallCut / _rows);

  /// How far the grown row reaches over the slices it joins, in pixels. Two
  /// slices that only meet, at a fractional pixel, let the wall behind show
  /// through their soft edges as a line across the board; the row is drawn
  /// under both and a little past them, so the join is always over green.
  static const double _overlap = 1;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final s = width / QuizClassroomArt.width;
        final natural = QuizClassroomArt.wallCut * s;
        // What the parent has spare is its minimum: [SpareHeightColumn].
        final height = math.max(natural, constraints.minHeight);
        final grown = height - natural;

        final boardTop =
            QuizClassroomArt.frameTop * s - QuizChalkboard.badgeHalf;
        final rowTop = QuizClassroomArt.growRow * s;

        // Drawn once into an image, not replayed as paths every frame. See
        // [RasterizedSvg]. Each box has its slice's own shape, so filling it
        // stretches nothing.
        Widget slice(Rect window, double fromRow) => RasterizedSvg.asset(
              QuizClassroomArt.asset,
              fit: BoxFit.fill,
              window: window,
              placeholder: CustomPaint(painter: _StandInRoom(fromRow)),
            );

        return SizedBox(
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // The row first, so the slices over and under it cover its ends.
              // Drawn one row tall and scaled up, so the image is the same
              // whatever the phone has spare, and not made again for each.
              Positioned(
                left: 0,
                top: rowTop - _overlap,
                width: width,
                height: s + grown + 2 * _overlap,
                child: FittedBox(
                  fit: BoxFit.fill,
                  child: SizedBox(
                    width: width,
                    height: s,
                    child: slice(_row, QuizClassroomArt.growRow),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: 0,
                width: width,
                height: rowTop,
                child: slice(_over, 0),
              ),
              Positioned(
                left: 0,
                top: rowTop + s + grown,
                width: width,
                height: natural - rowTop - s,
                child: slice(_under, QuizClassroomArt.growRow + 1),
              ),
              Positioned(
                left: QuizClassroomArt.faceLeft * s,
                width:
                    (QuizClassroomArt.faceRight - QuizClassroomArt.faceLeft) *
                        s,
                top: boardTop,
                height: QuizClassroomArt.faceBottom * s + grown - boardTop,
                child: board,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// The classroom's floor: the shelf and the pot, the teacher on the left and
/// the player's pet on the right standing on the boards, and the teacher's
/// words in a box on the floor below the picture.
///
/// The bottom half of the picture, from [QuizClassroomArt.wallCut] down. See
/// [QuizClassWall] for why it is a half.
///
/// The teacher talks — encouragement while the player thinks, the explanation
/// once they have answered — and the player's pet throws hearts for a right
/// answer. The quiz is a lesson the two of them are in together.
class QuizClassFloor extends StatelessWidget {
  const QuizClassFloor({
    super.key,
    required this.bubbleText,
    required this.heartBurstId,
  });

  final String bubbleText;

  /// Bumped by the screen when an answer lands correct. Its value means
  /// nothing; the change is what plays the burst.
  ///
  /// Same signal the home screen uses for petting, on purpose. Hearts mean
  /// one thing in this game — the pet is pleased with you — and a right
  /// answer should read as the same reward as a scratch behind the ears.
  final int heartBurstId;

  /// The band under the picture the teacher's words are drawn in, tail
  /// included: four lines of an explanation at full size.
  static const double bubbleBand = 88;

  /// How far the bubble's tail reaches above the bubble.
  static const double _tail = 12;

  /// The part of the picture under the cut, as fractions of its height.
  static const Rect window = Rect.fromLTRB(
      0, QuizClassroomArt.wallCut / QuizClassroomArt.height, 1, 1);

  /// The art canvas the sprite draws into, in units: the shared pet viewBox is
  /// "-20 -90 222 328", where the top 90 is hat headroom the pet itself never
  /// occupies. So the body is 238 units of a 328-unit canvas.
  static const double _artHeight = 328;
  static const double _artWidth = 222;
  static const double _bodyHeight = _artHeight - 90;

  /// How tall each pet is drawn, ears to feet, in the picture's units.
  ///
  /// The canvas runs from the feet up to [QuizClassroomArt.petsTop]: the
  /// board is up on the wall above the pets and has nothing to do with their
  /// size, and the hat headroom over the ears is empty.
  static double get petHeightInArt =>
      (QuizClassroomArt.standRow - QuizClassroomArt.petsTop) *
      _bodyHeight /
      _artHeight;

  /// The player's pet type, or the cat when the provider cannot say — the
  /// same fallback the sprite itself makes.
  static String _learnerType(BuildContext context) {
    try {
      return context.read<CharacterProvider>().currentCharacterType;
    } catch (_) {
      return 'cat';
    }
  }

  @override
  Widget build(BuildContext context) {
    final textDirection =
        textDirectionForLocale(Localizations.localeOf(context));

    final teacher = CharacterSprite(
      width: double.infinity,
      height: double.infinity,
      groundShadow: true,
      previewType: quizTeacherFor(_learnerType(context)),
      previewAccessories: [
        for (final id in kQuizTeacherOutfit) accessoryById(id)!,
      ],
      naturalCoat: true,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final s = width / QuizClassroomArt.width;
        // Everything below is measured from the cut, which is this half's top.
        final pictureHeight =
            (QuizClassroomArt.height - QuizClassroomArt.wallCut) * s;

        final canvasTop =
            (QuizClassroomArt.petsTop - QuizClassroomArt.wallCut) * s;
        final canvasHeight = QuizClassroomArt.standRow * s -
            QuizClassroomArt.wallCut * s -
            canvasTop;
        final canvasWidth = canvasHeight * _artWidth / _artHeight;
        final petHeight = canvasHeight * _bodyHeight / _artHeight;
        final teacherX = QuizClassroomArt.teacherX * s;
        final learnerX = QuizClassroomArt.learnerX * s;

        // The bubble hangs from the top of its band, under the tail.
        final bubbleTop = pictureHeight + _tail + 2;

        return SizedBox(
          height: pictureHeight + bubbleBand,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // The floor from the bottom of the picture on down, a screen's
              // height past this box: it is what the answers stand on, however
              // tall the screen is. A pixel up under the picture too:
              // same-coloured boxes that only meet, at a fractional pixel, let
              // the wall show through their soft edges as a line.
              Positioned(
                left: 0,
                right: 0,
                top: pictureHeight - 1,
                bottom: -MediaQuery.sizeOf(context).height,
                child: const ColoredBox(color: QuizClassroom.floor),
              ),
              // Drawn once into an image, not replayed as paths every frame
              // the pets breathe. See [RasterizedSvg].
              Positioned(
                left: 0,
                top: 0,
                width: width,
                height: pictureHeight,
                child: RasterizedSvg.asset(
                  QuizClassroomArt.asset,
                  fit: BoxFit.fill,
                  window: window,
                  placeholder: const CustomPaint(
                      painter: _StandInRoom(QuizClassroomArt.wallCut)),
                ),
              ),
              Positioned(
                left: teacherX - canvasWidth / 2,
                top: canvasTop,
                width: canvasWidth,
                height: canvasHeight,
                child: teacher,
              ),
              Positioned(
                left: learnerX - canvasWidth / 2,
                top: canvasTop,
                width: canvasWidth,
                height: canvasHeight,
                // Mirrored: the art faces right, and the pet faces back across
                // the room at the teacher.
                child: Transform.flip(
                  flipX: true,
                  child: const CharacterSprite(
                    width: double.infinity,
                    height: double.infinity,
                    groundShadow: true,
                  ),
                ),
              ),
              // Hearts rise out of the empty headroom the art carries above
              // the ears — the band hats sit in — so they clear the pet
              // instead of crossing it.
              Positioned(
                left: learnerX - canvasWidth / 2,
                width: canvasWidth,
                top: canvasTop,
                child: Center(
                  child: PetHearts(
                    burstId: heartBurstId,
                    baseSize: petHeight * 0.16,
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: bubbleTop,
                height: bubbleBand - (bubbleTop - pictureHeight) - 4,
                child: CustomSingleChildLayout(
                  delegate: _BubbleLayout(preferredLeft: teacherX - 40),
                  child: _TeacherBubble(
                    text: bubbleText,
                    textDirection: textDirection,
                  ),
                ),
              ),
              // The tail is the scene's, not the bubble's: the bubble slides
              // sideways to fit its words, and the tail stays under the
              // teacher, pointing up at it. Its base overlaps the bubble's
              // top edge so the white runs through the border.
              Positioned(
                left: teacherX - 9,
                top: bubbleTop - _tail,
                child: Transform.flip(
                  flipY: true,
                  child: const CustomPaint(
                    size: Size(18, 18),
                    painter: PixelTrianglePainter(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// The room as plain shapes — wall, the floor and its line, the board's frame
/// and green — from the picture's numbers. Shown until the picture has been
/// drawn, so the question is never written on empty wall.
///
/// Draws the part of the room from [fromRow] (in the picture's units) down,
/// into a box that is exactly that part: the wall shows the room from its top,
/// the floor the room from the cut.
class _StandInRoom extends CustomPainter {
  const _StandInRoom(this.fromRow);

  final double fromRow;

  /// How far the board's frame reaches outside its clear green, in the
  /// picture's units.
  static const double _frame = 13;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / QuizClassroomArt.width;
    final ink = Paint()..color = AppTheme.retroDark;
    final line = 3 * s;
    canvas
      ..clipRect(Offset.zero & size)
      ..translate(0, -fromRow * s);
    final roomBottom = QuizClassroomArt.height * s;

    // Wall and floor side by side, not one painted over the other: under the
    // floor, wall would bleed through the soft bottom edge of the box.
    final floorTop = QuizClassroomArt.floorLine * s;
    canvas.drawRect(Rect.fromLTRB(0, 0, size.width, floorTop),
        Paint()..color = QuizClassroom.wall);
    canvas.drawRect(Rect.fromLTRB(0, floorTop, size.width, roomBottom),
        Paint()..color = QuizClassroom.floor);
    canvas.drawRect(
        Rect.fromLTRB(0, floorTop, size.width, floorTop + line), ink);

    final frame = Rect.fromLTRB(
      (QuizClassroomArt.faceLeft - _frame) * s,
      QuizClassroomArt.frameTop * s,
      (QuizClassroomArt.faceRight + _frame) * s,
      QuizClassroomArt.boardBottom * s,
    );
    canvas.drawRect(frame, ink);
    canvas.drawRect(frame.deflate(line), Paint()..color = QuizClassroom.floor);
    final face = Rect.fromLTRB(
      QuizClassroomArt.faceLeft * s,
      QuizClassroomArt.faceTop * s,
      QuizClassroomArt.faceRight * s,
      frame.bottom - _frame * s,
    );
    canvas.drawRect(face.inflate(line), ink);
    canvas.drawRect(face, Paint()..color = QuizClassroom.board);
  }

  @override
  bool shouldRepaint(_StandInRoom oldDelegate) =>
      oldDelegate.fromRow != fromRow;
}

/// Hangs the teacher's bubble from the top of its band, left edge under the
/// teacher — or as far left of that as the words need to fit on the screen,
/// so a long explanation gets the whole width before it gets smaller.
class _BubbleLayout extends SingleChildLayoutDelegate {
  const _BubbleLayout({required this.preferredLeft});

  final double preferredLeft;

  static const double _margin = 16;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints(
        maxWidth: constraints.maxWidth - 2 * _margin,
        maxHeight: constraints.maxHeight,
      );

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final room = size.width - _margin - childSize.width;
    final left = preferredLeft < room ? preferredLeft : room;
    return Offset(left < _margin ? _margin : left, 0);
  }

  @override
  bool shouldRelayout(_BubbleLayout oldDelegate) =>
      oldDelegate.preferredLeft != preferredLeft;
}

/// What the teacher is saying.
///
/// Sized to its words and pinned by its bottom edge, so a short line is a
/// small bubble over the teacher's head and a long explanation grows up and
/// across the room. Words that would outgrow the band are shrunk to fit it
/// rather than pushing the class down the screen while the player reads.
class _TeacherBubble extends StatelessWidget {
  const _TeacherBubble({
    required this.text,
    required this.textDirection,
  });

  final String text;
  final TextDirection textDirection;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        // Border and padding, both sides.
        const inset = 2 * (4 + 8);

        final words = Text(
          text,
          textDirection: textDirection,
          textAlign: TextAlign.center,
          style: AppFonts.pressStart2p(
            fontSize: 8,
            height: 1.5,
            color: AppTheme.retroDark,
            decoration: TextDecoration.none,
          ),
        );

        return Container(
          // Wide enough to always reach over the tail, which the scene draws
          // 40 in from the bubble's preferred left edge.
          constraints: const BoxConstraints(minWidth: 88),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppTheme.retroDark, width: 4),
            boxShadow: const [
              BoxShadow(
                color: AppTheme.retroDark,
                offset: Offset(4, 4),
                blurRadius: 0,
              ),
            ],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth - inset),
              child: words,
            ),
          ),
        );
      },
    );
  }
}

/// The bottom bar, and the reason the Continue button no longer moves.
///
/// The slot is always laid out, even with nothing in it. Both screens used to
/// insert the button into the column the moment an answer was picked, which
/// shoved the pet and the options upward at exactly the moment the player was
/// reading the explanation. Reserving the height costs one empty strip of
/// floor and buys a board that holds still.
class QuizContinueBar extends StatelessWidget {
  const QuizContinueBar({
    super.key,
    required this.label,
    required this.onContinue,
  });

  final String label;

  /// Null until there is something to continue to.
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final visible = onContinue != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: IgnorePointer(
        ignoring: !visible,
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: const Duration(milliseconds: 150),
          child: GestureDetector(
            onTap: onContinue,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppTheme.retroPrimary,
                border: Border.all(color: AppTheme.retroDark, width: 4),
                boxShadow: const [
                  BoxShadow(
                    color: AppTheme.retroDark,
                    offset: Offset(4, 4),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Text(
                label,
                textDirection:
                    textDirectionForLocale(Localizations.localeOf(context)),
                textAlign: TextAlign.center,
                style: AppFonts.pressStart2p(
                  fontSize: 12,
                  color: Colors.white,
                  decoration: TextDecoration.none,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One quiz question, whole.
///
/// Top to bottom: the header on the classroom wall, the classroom picture
/// with the question chalked on its board and the teacher and pet standing
/// under it, the teacher's words, the answers on the floor, and Continue
/// pinned under everything.
///
/// The layout rule worth knowing: the classroom starts right under the header,
/// so the board is at the top of the screen, and the shelf, the pot, the pets
/// and the answers stay together at the bottom, right above Continue, however
/// tall the screen is. That is what the [SpareHeightColumn] under a
/// [ConstrainedBox] is doing — it is given a minimum height of the viewport
/// but an unbounded maximum, so it grows to the taller of its content and the
/// screen, and the leftover space goes to the board ([QuizClassWall]), which
/// grows down towards the shelf. On a short screen there is no leftover space
/// and the whole thing scrolls instead.
class QuizStage extends StatelessWidget {
  const QuizStage({
    super.key,
    required this.header,
    required this.badgeLabel,
    required this.prompt,
    required this.topic,
    required this.options,
    required this.stateOf,
    required this.onAnswer,
    required this.bubbleText,
    required this.heartBurstId,
    required this.continueLabel,
    required this.onContinue,
    this.banner,
    this.showcase = false,
  });

  /// Whatever the screen wants across the top — a level pill and a pause
  /// button on the daily quiz, a progress count during onboarding.
  final Widget header;

  final String badgeLabel;
  final String prompt;
  final String topic;
  final List<String> options;
  final QuizOptionState Function(String option) stateOf;
  final ValueChanged<String>? onAnswer;
  final String bubbleText;
  final int heartBurstId;
  final String continueLabel;
  final VoidCallback? onContinue;

  /// A full-width strip above everything, for the offline and fallback
  /// notices. Inside the safe area, so it cannot hide under a notch.
  final Widget? banner;

  /// Whether to hang the quiz tour's coach marks on this stage. Only the
  /// daily quiz does — the placement quiz during onboarding is already being
  /// explained by the screen before it.
  final bool showcase;

  /// Hangs a coach mark on [child], or hands it back untouched when this
  /// stage is not being toured.
  Widget _step(
    Widget child, {
    required GlobalKey key,
    required String? description,
    bool isFirst = false,
    bool isLast = false,
  }) {
    if (!showcase || description == null) return child;
    return RetroShowcase(
      showcaseKey: key,
      description: description,
      isFirst: isFirst,
      isLast: isLast,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // The wall is the backdrop of the screen — the status bar, the banner, the
    // header and any height a tall phone has spare — and the class floor
    // paints the floor from the bottom of its picture down, so the room meets
    // itself wherever the screen ends.
    return Container(
      color: QuizClassroom.wall,
      child: SafeArea(
        // The floor runs on under the home indicator, so the bottom inset is
        // padded inside the Continue bar's strip rather than left as wall.
        bottom: false,
        child: Column(
          children: [
            if (banner != null) banner!,
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: SpareHeightColumn(
                      top: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                        child: _step(
                          header,
                          key: quizHeaderShowcaseKey,
                          description: l10n?.tutorialQuizHeader,
                          isFirst: true,
                        ),
                      ),
                      // The wall with the board on it, which grows into
                      // whatever height the screen has spare.
                      middle: QuizClassWall(
                        board: _step(
                          QuizChalkboard(
                            badgeLabel: badgeLabel,
                            prompt: prompt,
                            topic: topic,
                          ),
                          key: quizQuestionShowcaseKey,
                          description: l10n?.tutorialQuizQuestion,
                        ),
                      ),
                      // The shelf, the pot and the pets, and the answers on the
                      // floor the picture lays down under them.
                      bottom: Column(
                        children: [
                          QuizClassFloor(
                            bubbleText: bubbleText,
                            heartBurstId: heartBurstId,
                          ),
                          _step(
                            QuizOptionGrid(
                              options: options,
                              stateOf: stateOf,
                              onAnswer: onAnswer,
                            ),
                            key: quizOptionsShowcaseKey,
                            description: l10n?.tutorialQuizOptions,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            ColoredBox(
              color: QuizClassroom.floor,
              child: Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.paddingOf(context).bottom),
                child: _step(
                  QuizContinueBar(
                    label: continueLabel,
                    onContinue: onContinue,
                  ),
                  key: quizContinueShowcaseKey,
                  description: l10n?.tutorialQuizContinue,
                  isLast: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
