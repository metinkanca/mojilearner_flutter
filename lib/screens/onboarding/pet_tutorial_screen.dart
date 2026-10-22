import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../components/character_sprite.dart';
import '../../components/pet_hearts.dart';
import '../../components/speech_bubble_tail.dart';
import '../../constants/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/character_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/fonts.dart';
import '../../utils/head_scratch.dart';
import '../../utils/intro_handoff.dart';
import '../../utils/rtl_locale.dart';

/// The last screen of onboarding: the pet, alone, and the one gesture the
/// game is actually built around.
///
/// Everything before this taught the player about themselves — their name,
/// their language, their level. This teaches them about the pet, and it is
/// the only screen in the opening that asks for something back. Petting is
/// the core loop; a player who reaches the home screen without knowing the
/// head responds to a rub has been handed a tamagotchi they cannot touch.
///
/// The gesture is the real one, not a mime of it: [HeadScratchDetector] is
/// the same object the home screen arms, on the same hitbox, at the same
/// thresholds. What is learned here keeps working tomorrow.
class PetTutorialScreen extends StatefulWidget {
  const PetTutorialScreen({super.key});

  @override
  State<PetTutorialScreen> createState() => _PetTutorialScreenState();
}

class _PetTutorialScreenState extends State<PetTutorialScreen> {
  /// How wide the pet is drawn, as a fraction of the scene. Larger than the
  /// home screen's, because here it is the only thing on screen and the
  /// gesture is being taught rather than remembered — a bigger head is an
  /// easier first target.
  static const double _petWidthFactor = 0.78;

  /// Clearance between the pet's feet and the bottom of the scene.
  static const double _footOffset = 24;

  /// How long the player is left alone with the hint before Continue turns up
  /// regardless.
  ///
  /// The screen wants to be finished by petting, but it must not be a lock.
  /// A player on a device where the drag does not land, or who simply does
  /// not want to, still has to be able to reach their app.
  static const Duration _escapeHatch = Duration(seconds: 15);

  late final HeadScratchDetector _scratch =
      HeadScratchDetector(onScratch: _registerScratch);

  Timer? _escapeTimer;

  /// The pet's sprite box, so its exact pose can be handed to the home
  /// screen on the way out. See [IntroHandoff].
  final GlobalKey _petKey = GlobalKey();

  /// Set while the screen is bowing out: the bubble and the button go first,
  /// so the pet is alone on the grass at the moment of the handover and the
  /// two screens differ by nothing the eye can catch.
  bool _leaving = false;

  /// Whether the player has managed the gesture at least once. Stops the
  /// hand, brings up the pet's welcome, and reveals Continue.
  ///
  /// There is deliberately no written instruction alongside the hand. A
  /// pixel hand rubbing a pixel cat is not ambiguous, and a line of text
  /// telling the player to do the thing the animation is already doing reads
  /// as a manual rather than as a game.
  bool _petted = false;

  /// Bumped per registered rub, so hearts play every single time here.
  ///
  /// The home screen ties hearts to the happiness payout, which is on a
  /// cooldown — right, there, because a heart is a promise of a reward. In
  /// the tutorial the reward being promised is the reaction itself, and a
  /// second rub that produced nothing would read as the gesture having
  /// broken.
  int _heartBursts = 0;

  /// Continue is shown once there is a reason to, or once [_escapeHatch] has
  /// run out.
  bool _canContinue = false;

  @override
  void initState() {
    super.initState();
    _escapeTimer = Timer(_escapeHatch, () {
      if (mounted) setState(() => _canContinue = true);
    });
  }

  @override
  void dispose() {
    _escapeTimer?.cancel();
    super.dispose();
  }

  void _registerScratch() {
    HapticFeedback.selectionClick();
    Provider.of<CharacterProvider>(context, listen: false).petThePet();
    setState(() {
      _heartBursts++;
      _petted = true;
      _canContinue = true;
    });
  }

  /// How long the bubble and the button take to clear off before the
  /// handover, leaving the pet alone on the grass.
  static const Duration _kBowOut = Duration(milliseconds: 180);

  Future<void> _continue() async {
    if (_leaving) return;
    setState(() => _leaving = true);
    await Future<void>.delayed(_kBowOut);
    if (!mounted) return;

    // The pose goes down before the flag goes up. Marking onboarding
    // complete notifies the router, whose redirect then carries the player
    // home on the spot -- so anything home needs has to already be waiting
    // for it. See [IntroHandoff].
    final pose = _measurePet();
    if (pose != null) IntroHandoff.leave(pose);

    // Onboarding is marked complete *here* rather than at the end of the
    // quiz. The router sends anyone who has finished onboarding away from
    // every /onboarding/ route, so completing it a screen early would bounce
    // the player straight past this one.
    await Provider.of<UserProvider>(context, listen: false)
        .markOnboardingComplete();
    if (!mounted) return;

    // Belt and braces. The redirect above has almost certainly moved us
    // already, in which case this is a no-op on the location we are on.
    context.go('/');
  }

  /// Where the pet is standing right now, in global coordinates.
  ///
  /// Null if the box cannot be measured, which is the honest answer when
  /// there is nothing on screen to measure — the home screen then simply
  /// opens without the walk-in rather than animating from a guess.
  IntroHandoff? _measurePet() {
    final box = _petKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    return IntroHandoff(box.localToGlobal(Offset.zero) & box.size);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textDirection =
        textDirectionForLocale(Localizations.localeOf(context));

    return Scaffold(
      backgroundColor: AppTheme.retroSky,
      body: Stack(
        children: [
          const _Scenery(),
          SafeArea(
            child: Column(
              children: [
                Expanded(child: _buildStage()),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: IgnorePointer(
                    ignoring: !_canContinue || _leaving,
                    child: AnimatedOpacity(
                      opacity: _canContinue && !_leaving ? 1 : 0,
                      duration: _kBowOut,
                      child: GestureDetector(
                        onTap: _continue,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: AppTheme.retroPrimary,
                            border:
                                Border.all(color: AppTheme.retroDark, width: 4),
                            boxShadow: const [
                              BoxShadow(
                                color: AppTheme.retroDark,
                                offset: Offset(4, 4),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: Text(
                            l10n.continueBtn,
                            textDirection: textDirection,
                            textAlign: TextAlign.center,
                            style: AppFonts.pressStart2p(
                              fontSize: 12,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The pet, its hearts, and the hand hint — all in one coordinate space, so
  /// the hitbox and the hand are aimed at the same head.
  Widget _buildStage() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sceneSize = Size(constraints.maxWidth, constraints.maxHeight);
        final petWidth = constraints.maxWidth * _petWidthFactor;
        final boxHeight = petWidth / HeadScratchDetector.petAspect;
        final boxTop = sceneSize.height - _footOffset - boxHeight;

        return GestureDetector(
          // Opaque, so the drag is caught anywhere in the scene and the
          // detector — not the hit test — decides whether it landed on the
          // head. A finger that slips off the ear mid-rub keeps petting.
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (details) => _scratch.start(
            details.localPosition,
            sceneSize: sceneSize,
            petWidth: petWidth,
            footOffset: _footOffset,
          ),
          onHorizontalDragUpdate: (details) =>
              _scratch.update(details.localPosition, petWidth: petWidth),
          onHorizontalDragEnd: (_) => _scratch.reset(),
          onHorizontalDragCancel: _scratch.reset,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: _footOffset + boxHeight * 0.06,
                child: Center(
                  child: Container(
                    width: petWidth * 0.62,
                    height: petWidth * 0.28,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: _footOffset,
                child: Center(
                  child: SizedBox(
                    key: _petKey,
                    width: petWidth,
                    height: boxHeight,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Positioned.fill, not a bare child: a Stack hands
                        // loose constraints to a non-positioned child, and
                        // the sprite would fall back to the art's own viewBox
                        // size instead of the box it was given.
                        const Positioned.fill(
                          child: CharacterSprite(
                            width: double.infinity,
                            height: double.infinity,
                            motionProfile: CharacterMotionProfile.full,
                          ),
                        ),
                        // Hearts rise through the empty headroom the art
                        // carries above the ears, the band hats sit in.
                        Positioned(
                          left: 0,
                          right: 0,
                          top: 0,
                          child: Center(
                            child: PetHearts(
                              burstId: _heartBursts,
                              baseSize: petWidth * 0.13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Anchored by its *bottom* edge just above the ears, so a
              // long translation grows upward into empty sky instead of
              // pushing its own tail off the pet's head.
              if (_petted)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: sceneSize.height -
                      (boxTop +
                          boxHeight * HeadScratchDetector.headTopFactor),
                  // Fades rather than vanishing, in step with the button
                  // below it, so the screen empties out around the pet
                  // instead of losing its furniture a piece at a time.
                  child: AnimatedOpacity(
                    opacity: _leaving ? 0 : 1,
                    duration: _kBowOut,
                    child: _WelcomeBubble(
                      text: AppLocalizations.of(context)!.petTutorialWelcome(
                        Provider.of<UserProvider>(context).username,
                      ),
                    ),
                  ),
                ),
              if (!_petted)
                Positioned(
                  left: 0,
                  right: 0,
                  // Parked over the middle of the head band, which
                  // HeadScratchDetector puts between 0.20 and 0.66 of the
                  // sprite box. Aiming the hand anywhere else would teach a
                  // gesture the detector then refuses.
                  top: boxTop +
                      boxHeight *
                          (HeadScratchDetector.headTopFactor +
                              HeadScratchDetector.headBottomFactor) /
                          2,
                  child: Center(
                    child: _ScratchHint(sweep: petWidth * 0.22),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// What the pet says once it has been petted, in a bubble with a tail rather
/// than a caption in a box.
///
/// The distinction is the whole point of the screen: a box under the pet is
/// the app talking about the pet, and a bubble over its head is the pet
/// talking to the player. This is the moment the player is supposed to start
/// reading it as somebody.
class _WelcomeBubble extends StatelessWidget {
  const _WelcomeBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final textDirection =
        textDirectionForLocale(Localizations.localeOf(context));

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
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
          child: Text(
            text,
            textDirection: textDirection,
            textAlign: TextAlign.center,
            style: AppFonts.pressStart2p(
              fontSize: 10,
              height: 1.6,
              color: AppTheme.retroDark,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // Centred, unlike the home screen's, which is offset to the right to
        // clear the chrome beside it. Here the pet is centred and so is the
        // bubble, so the tail points straight down at the head.
        const Positioned(
          bottom: -12,
          left: 0,
          right: 0,
          child: Center(
            child: CustomPaint(
              size: Size(18, 18),
              painter: PixelTrianglePainter(),
            ),
          ),
        ),
      ],
    );
  }
}

/// A hand that rubs back and forth where the player's should.
///
/// Drawn rather than set as a glyph, for the same reason [PetHearts] paints
/// its hearts: the pixel font carries no hand, and an emoji one would be the
/// only smooth-edged thing on the screen.
class _ScratchHint extends StatefulWidget {
  const _ScratchHint({required this.sweep});

  /// Half the travel, in pixels, either side of centre.
  final double sweep;

  @override
  State<_ScratchHint> createState() => _ScratchHintState();
}

class _ScratchHintState extends State<_ScratchHint>
    with SingleTickerProviderStateMixin {
  /// One rub across and back. Slow enough to be copied rather than watched —
  /// the point is that the player's finger follows it.
  static const Duration _period = Duration(milliseconds: 1500);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _period,
  )..repeat();

  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          if (_reduceMotion) {
            // Parked and pulsing instead of travelling. The hint still reads
            // as "here, and it is a gesture", without anything sliding across
            // the screen.
            final pulse =
                0.9 + 0.1 * (1 - (_controller.value * 2 - 1).abs());
            return Transform.scale(scale: pulse, child: child);
          }
          final t = _controller.value * 2 * math.pi;
          // Sine across, half-rate cosine down: the hand presses into the
          // head at each end of the stroke rather than gliding over it.
          final dx = widget.sweep * math.sin(t);
          final dy = 3 * math.cos(t * 2);
          return Transform.translate(offset: Offset(dx, dy), child: child);
        },
        child: const CustomPaint(
          size: Size(36, 40),
          painter: _PixelHand(),
        ),
      ),
    );
  }
}

/// A pointing hand, on the same pixel grid the hearts use.
class _PixelHand extends CustomPainter {
  const _PixelHand();

  /// '#' outline, 'o' fill, '.' empty. Read top-down.
  static const List<String> _pattern = [
    '....##....',
    '...#oo#...',
    '...#oo#...',
    '...#oo#...',
    '..##oo##..',
    '.#oooooo#.',
    '#oooooooo#',
    '#oooooooo#',
    '#oooooooo#',
    '.########.',
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / _pattern.first.length;
    final fill = Paint()..color = Colors.white;
    final outline = Paint()..color = AppTheme.retroDark;

    for (var row = 0; row < _pattern.length; row++) {
      for (var col = 0; col < _pattern[row].length; col++) {
        final glyph = _pattern[row][col];
        if (glyph == '.') continue;
        canvas.drawRect(
          // Overdrawn by a hair: adjacent cells rounded to different device
          // pixels leave hairline gaps through the shape otherwise.
          Rect.fromLTWH(col * cell, row * cell, cell + 0.5, cell + 0.5),
          glyph == '#' ? outline : fill,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_PixelHand oldDelegate) => false;
}

/// Sky over grass, the same scene the home screen opens onto.
///
/// The point of ending onboarding here is that the next screen the player
/// sees is not a new place — it is this one, with the app's furniture on it.
class _Scenery extends StatelessWidget {
  const _Scenery();

  static Widget _blade() =>
      Container(width: 8, height: 8, color: AppTheme.retroGrassDark);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 5,
          child: Container(
            color: AppTheme.retroSky,
            child: Stack(
              children: [
                Positioned(
                  top: 60,
                  left: 40,
                  child: Container(
                    width: 48,
                    height: 48,
                    color: AppTheme.retroAccent,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(width: 4, color: AppTheme.retroDark),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Container(
            width: double.infinity,
            color: AppTheme.retroGrass,
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(height: 4, color: AppTheme.retroDark),
                ),
                Positioned(
                  top: 8,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 16,
                    color: AppTheme.retroGrassDark.withValues(alpha: 0.2),
                  ),
                ),
                Positioned(top: 40, left: 40, child: _blade()),
                Positioned(top: 48, left: 48, child: _blade()),
                Positioned(top: 80, right: 80, child: _blade()),
                Positioned(top: 72, right: 88, child: _blade()),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
