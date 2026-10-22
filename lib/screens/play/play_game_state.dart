import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../components/boss_trial/trial_particles.dart';
import '../../components/character_sprite.dart';
import '../../components/pet_hearts.dart' show PixelHeartPainter;
import '../../components/play/play_kit.dart';
import '../../constants/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/character_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/play_games.dart';

/// What every toy chest game after Catch is built on: one clock, the pet and
/// how it reacts, the score, and how a game ends and pays.
///
/// A game supplies its content, its rounds and its scene, and moves itself
/// on in [step]; everything around that is here, so the four games differ
/// only in what is actually different about them. Catch predates this and
/// keeps its own loop — its ball flight and jump are most of its code — but
/// ends on the same results card and pays the same way.
///
/// Like Catch, a game is a fixed number of rounds with nothing to lose: a
/// miss costs the streak, the right answer is shown, and what got away is
/// listed at the end.
abstract class PlayGameState<T extends StatefulWidget> extends State<T>
    with SingleTickerProviderStateMixin {
  static const Color ink = AppTheme.retroDark;
  static const Color gold = AppTheme.retroAccent;

  /// The heart colours a right answer sparkles in.
  static const List<Color> cheerSparks = [
    AppTheme.retroAccent,
    Color(0xFFFFF3B0),
  ];

  /// What a wrong answer knocks loose.
  static const List<Color> bonkSparks = [
    AppTheme.retroAccent,
    AppTheme.retroLight,
  ];

  static const double heartSeconds = 0.95;
  static const double bonkSeconds = 0.9;
  static const double happySeconds = 0.7;
  static const double hopSeconds = 0.3;

  // ------------------------------------------------------------ the game --

  /// Fixed in tests, so the rounds are known.
  Random? get seed;

  /// Rounds in a game.
  int get rounds;

  /// Loads the game's words or sentences, setting [targetCode] and
  /// [nativeCode] to the pair they ended up in. False when there is nothing
  /// to play — which the pools' fallbacks make a broken stock table, not a
  /// player's thin vocabulary.
  bool loadContent();

  /// Clears the game's own state for a fresh game. Called before the first
  /// game and on every replay.
  void resetGame();

  /// Moves the game on by [dt] seconds. Not called once the game is over.
  void step(double dt);

  /// The scene, laid out in [box]. Rebuilt every frame.
  Widget buildScene(BoxConstraints box);

  /// Where particles land, in the scene's coordinates.
  double get particleFloor;

  // ---------------------------------------------------------- the shared --

  late final Ticker _ticker;
  late final Random rng = seed ?? Random();
  final TrialParticles particles = TrialParticles();

  /// Bumped every frame, so only the scene rebuilds at frame rate.
  final ValueNotifier<int> _frame = ValueNotifier(0);
  Duration _lastElapsed = Duration.zero;

  String? targetCode;
  String? nativeCode;

  PlayScore score = const PlayScore();
  bool over = false;

  /// What the finished game paid.
  int paidHappiness = 0;
  int paidXp = 0;

  /// The pet, built once in each look: a frame swaps between them, it never
  /// rebuilds a rig. The air ones have no shadow under their feet — a pet in
  /// the air leaves its shadow on the ground.
  late final Widget petIdle;
  late final Widget petHappy;
  late final Widget petSad;
  late final Widget petIdleAir;
  late final Widget petHappyAir;
  late final String petType;

  /// Seconds into the pet's hop, bonk and glee, or -1 / 0 when not.
  double petHop = -1;
  double petBonk = -1;
  double petGlee = 0;

  final List<PlayPopup> popups = [];
  final List<PlayHeart> hearts = [];

  bool get reduceMotion => MediaQuery.disableAnimationsOf(context);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);

    final languages = context.read<LanguageProvider>();
    targetCode = languages.targetLanguage?.code;
    nativeCode = languages.nativeLanguage.code;

    // Awake whatever its mood at home, in its own coat and outfit.
    petType = context.read<CharacterProvider>().currentCharacterType;
    Widget sprite(PetVisualState? state, {bool shadow = true}) =>
        CharacterSprite(
          width: double.infinity,
          height: double.infinity,
          groundShadow: shadow,
          previewType: petType,
          previewState: state,
        );
    petIdle = sprite(null);
    // Petted is the squint-and-wiggle: the closest thing the rig has to glee.
    petHappy = sprite(PetVisualState.petted);
    petSad = sprite(PetVisualState.sad);
    petIdleAir = sprite(null, shadow: false);
    petHappyAir = sprite(PetVisualState.petted, shadow: false);

    if (!loadContent()) {
      // The pools end on a stock pairing that always fills a game, so this
      // means the stock table itself is broken. Say so, rather than opening
      // and closing in one frame.
      debugPrint('$runtimeType: nothing to play for $targetCode/$nativeCode');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) leave();
      });
      return;
    }
    resetGame();
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frame.dispose();
    particles.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    // A frame is never more than 50ms of game, so a stall is a pause rather
    // than a skipped round.
    final dt =
        ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastElapsed = elapsed;

    particles.update(dt, floor: particleFloor);
    for (final p in popups) {
      p.age += dt;
    }
    popups.removeWhere((p) => p.age > 0.9);
    for (final heart in hearts) {
      heart.age += dt;
    }
    hearts.removeWhere((h) => h.age > heartSeconds);
    if (petHop >= 0) petHop = petHop + dt > hopSeconds ? -1 : petHop + dt;
    if (petBonk >= 0) petBonk = petBonk + dt > bonkSeconds ? -1 : petBonk + dt;
    petGlee = max(0.0, petGlee - dt);

    if (!over) step(dt);
    _frame.value++;
  }

  /// Rebuilds outside the frame: for state the HUD shows.
  void refresh([VoidCallback? change]) => setState(change ?? () {});

  // ------------------------------------------------------------- scoring --

  /// A round won, celebrated at [at] by a pet [petBox] tall.
  void scoreRight({required Offset at, required double petBox}) {
    refresh(() => score = score.scored());
    cheer(at: at, petBox: petBox);
  }

  /// A round lost, with [item] to practise.
  void scoreMissed(PlayPractice item) {
    refresh(() => score = score.missed(item));
  }

  /// A slip inside a round: the streak goes, [item] is listed, and a jolt.
  void slip(PlayPractice item, {required Offset at}) {
    HapticFeedback.lightImpact();
    refresh(() => score = score.slipped(item));
    if (!reduceMotion) particles.sparks(at, count: 8, fizzle: true);
  }

  /// The pet pleased: a squint, hearts off [at], the streak popping up.
  void cheer({required Offset at, required double petBox}) {
    HapticFeedback.selectionClick();
    petGlee = happySeconds;
    if (!reduceMotion) {
      if (petHop < 0) petHop = 0;
      particles.sparks(at, count: 6, colors: cheerSparks);
      for (var i = 0; i < 3; i++) {
        hearts.add(PlayHeart(
          at: at.translate(petBox * (0.1 + 0.13 * i), -petBox * 0.1),
          // Staggered, so they leave one at a time.
          age: -0.12 * i,
          drift: (i - 0.5) * 0.5,
        ));
      }
    }
    pop(score.combo > 1 ? 'x${score.combo}' : '+1', gold,
        at.translate(petBox * 0.35, -petBox * 0.2));
  }

  /// The pet let down: a squash, a shake and dizzy stars.
  void bonk({Offset? at}) {
    HapticFeedback.mediumImpact();
    petBonk = 0;
    if (at != null && !reduceMotion) {
      particles.sparks(at, count: 6, colors: bonkSparks);
    }
  }

  void pop(String text, Color color, Offset at) =>
      popups.add(PlayPopup(text, color, at));

  // ------------------------------------------------------------- the end --

  /// Ends the game and pays for it: happiness on the shared cooldown, XP
  /// under the games' daily cap. Both are shown as paid, not as earned.
  Future<void> finish() async {
    if (over) return;
    final character = context.read<CharacterProvider>();
    final user = context.read<UserProvider>();
    final right = score.right;
    final played = score.played;
    final gained = character.rewardPlay(right: right, rounds: played);
    // Every game in the language is a moment the pet was not forgotten, paid
    // or not — the same as a chat or a quiz.
    if (right > 0) character.recordLearningMoment();
    refresh(() {
      over = true;
      paidHappiness = gained;
      paidXp = 0;
    });
    final xp =
        await user.awardPlayXp(PlayRewards.xp(right: right, rounds: played));
    if (mounted && xp > 0) refresh(() => paidXp = xp);
  }

  void restart() {
    particles.clear();
    setState(() {
      score = const PlayScore();
      over = false;
      paidHappiness = 0;
      paidXp = 0;
      popups.clear();
      hearts.clear();
      petHop = -1;
      petBonk = -1;
      petGlee = 0;
      resetGame();
    });
  }

  void leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  // ------------------------------------------------------------ the pet --

  /// The pet's look this frame: let down, pleased, or itself.
  Widget petSprite({bool air = false}) {
    if (petBonk >= 0) return petSad;
    if (petGlee > 0) return air ? petHappyAir : petHappy;
    return air ? petIdleAir : petIdle;
  }

  /// How far its hop has lifted it, in whole steps of two pixels.
  double get hopLift => petHop < 0
      ? 0
      : ((sin(petHop / hopSeconds * pi) * 14) / 2).roundToDouble() * 2;

  /// A bonked pet's squash and head shake: (sideways shift, vertical scale).
  (double, double) get bonkPose {
    if (petBonk < 0 || reduceMotion) return (0, 1);
    if (petBonk < 0.1) return (0, 0.88);
    if (petBonk < 0.5) {
      return ((sin(petBonk * 40) * 3 * (1 - petBonk / 0.5)).roundToDouble(), 1);
    }
    return (0, 1);
  }

  /// The pet in a [size] box with its feet at [feet], hopping, squashed or
  /// shaking as it is; [lift] and [dx] move it further, and [scaleY] squashes
  /// it on top of a bonk.
  Widget positionedPet({
    required Offset feet,
    required double size,
    double lift = 0,
    double dx = 0,
    double scaleY = 1,
    bool air = false,
  }) {
    final (shake, squash) = bonkPose;
    return Positioned(
      left: (feet.dx - size / 2 + dx + shake).roundToDouble(),
      top: (feet.dy - size - lift - hopLift).roundToDouble(),
      width: size,
      height: size,
      child: IgnorePointer(
        child: Transform(
          alignment: Alignment.bottomCenter,
          transform: Matrix4.diagonal3Values(1, squash * scaleY, 1),
          child: petSprite(air: air),
        ),
      ),
    );
  }

  /// Stars circling a bonked pet's head, centred on [head], a stepped orbit.
  List<Widget> dizzyStars(Offset head, double petBox) {
    if (petBonk < 0.1 || reduceMotion) return const [];
    const positions = 8;
    final stepIndex = (petBonk / 0.08).floor();
    final star = (petBox * 0.07 / 5).roundToDouble().clamp(1.0, 3.0) * 5;
    return [
      for (var i = 0; i < 3; i++)
        Builder(builder: (_) {
          final angle =
              (stepIndex + i * positions / 3) * (2 * pi / positions);
          final at = head +
              Offset(cos(angle) * petBox * 0.22, sin(angle) * petBox * 0.06);
          return Positioned(
            left: (at.dx - star / 2).roundToDouble(),
            top: (at.dy - star / 2).roundToDouble(),
            width: star,
            height: star,
            child: const IgnorePointer(
              child: CustomPaint(painter: PixelStarPainter()),
            ),
          );
        }),
    ];
  }

  /// Hearts rising off a pleased pet, for a pet [petBox] tall.
  List<Widget> buildHearts(double petBox) => [
        for (final heart in hearts)
          if (heart.age > 0)
            Builder(builder: (_) {
              final k = (heart.age / heartSeconds).clamp(0.0, 1.0);
              final size = petBox * 0.2 * (k > 0.7 ? (1 - k) / 0.3 : 1);
              final at = Offset(
                heart.at.dx + heart.drift * heart.age * 30,
                heart.at.dy - (k * petBox * 0.5 / 2).roundToDouble() * 2,
              );
              return Positioned(
                left: (at.dx - size / 2).roundToDouble(),
                top: at.dy.roundToDouble(),
                width: size,
                height: size * 8 / 9,
                child: const IgnorePointer(
                  child: CustomPaint(painter: PixelHeartPainter()),
                ),
              );
            }),
      ];

  List<Widget> buildPopups() => [
        for (final p in popups)
          Positioned(
            left: p.at.dx - 80,
            top: p.at.dy -
                (reduceMotion ? 0.0 : ((p.age * 34) / 2).roundToDouble() * 2),
            width: 160,
            child: IgnorePointer(
              child: Text(
                p.text,
                textAlign: TextAlign.center,
                textDirection: TextDirection.ltr,
                style: playPixel(12, p.color).copyWith(
                  shadows: const [
                    Shadow(color: Colors.black, offset: Offset(2, 2)),
                  ],
                ),
              ),
            ),
          ),
      ];

  /// Particles behind the pet, or in front of it.
  Widget particleLayer({required bool front}) => Positioned.fill(
        child: IgnorePointer(
          child: CustomPaint(
            painter: TrialParticlePainter(particles, front: front),
          ),
        ),
      );

  TextStyle pixelTarget(double size, Color color) =>
      playPixel(size, color, localeCode: targetCode);

  TextStyle pixelNative(double size, Color color) =>
      playPixel(size, color, localeCode: nativeCode);

  /// The order letters and words run in the language being learned.
  TextDirection get targetDirection =>
      targetCode == 'ar' ? TextDirection.rtl : TextDirection.ltr;

  // ---------------------------------------------------------------- build --

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: ink,
      body: SafeArea(
        child: Column(
          children: [
            PlayHud(
              results: score.results,
              total: rounds,
              current: over ? null : score.played,
              combo: score.combo,
              onClose: leave,
            ),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: LayoutBuilder(
                      builder: (context, box) => ValueListenableBuilder<int>(
                        valueListenable: _frame,
                        builder: (context, _, __) =>
                            ClipRect(child: buildScene(box)),
                      ),
                    ),
                  ),
                  if (over)
                    Positioned.fill(
                      child: PlayResultsPanel(
                        results: score.results,
                        total: rounds,
                        happiness: paidHappiness,
                        xp: paidXp,
                        xpLabel: l10n.xp,
                        toPractise: score.toPractise,
                        targetCode: targetCode,
                        nativeCode: nativeCode,
                        againLabel: l10n.playCatchAgain,
                        onAgain: restart,
                        onClose: leave,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A number or a word rising off something that just happened.
class PlayPopup {
  PlayPopup(this.text, this.color, this.at);
  final String text;
  final Color color;
  final Offset at;
  double age = 0;
}

/// One heart on its way up from a pleased pet.
class PlayHeart {
  PlayHeart({required this.at, required this.age, required this.drift});

  final Offset at;

  /// Starts negative for the ones that leave a beat later.
  double age;

  /// Sideways drift, so three hearts do not rise in one column.
  final double drift;
}
