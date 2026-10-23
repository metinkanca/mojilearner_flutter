import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../components/boss_trial/arena_pieces.dart';
import '../components/boss_trial/trial_particles.dart';
import '../components/character_sprite.dart';
import '../components/play/play_kit.dart';
import '../components/pet_hearts.dart' show PixelHeartPainter;
import '../components/play_toy.dart' show BeachBallPainter;
import '../constants/theme.dart';
import '../l10n/app_localizations.dart';
import '../providers/character_provider.dart';
import '../providers/language_provider.dart';
import '../providers/user_provider.dart';
import '../providers/vocab_provider.dart';
import '../utils/boss_trial.dart';
import '../utils/fonts.dart';
import '../utils/play_catch.dart';
import '../utils/play_games.dart';

/// Catch, played with the pet at home.
///
/// The ball sits on its spot across the grass from the pet. The pet calls out
/// a word in the language being learned, the ball is thrown to it, and while
/// it is in the air the player picks what the word means. Right, and the pet
/// leaps up to meet the ball, knocks it back to its spot and drops back onto
/// the grass. Wrong — or no answer by the time it arrives — and the pet never
/// jumps: the ball bonks off its head and bounces away, and a new one rolls
/// in. See [PlayCatchRules] for the numbers.
///
/// The ball is the clock: there is no timer on screen, just how far it has
/// still to go. That is also most of the game's personality, so the pet reacts
/// to every throw — a hop to call the word, a jump and hearts for a good
/// answer, a squash and dizzy stars for a bonk.
///
/// Deliberately almost wordless. A number, a row of squares and a heart say
/// how the game went in every language the app ships, so the only new strings
/// are the labels a screen reader needs.
class PlayCatchScreen extends StatefulWidget {
  const PlayCatchScreen({super.key, this.random});

  /// Fixed in tests, so the throws are known.
  final Random? random;

  @override
  State<PlayCatchScreen> createState() => _PlayCatchScreenState();
}

enum _Stage {
  /// The ball rests on its spot before the next throw.
  ready,

  /// Thrown, and the answers are open.
  flying,

  /// Caught: headed back to its spot, landing with a bounce.
  returning,

  /// Not caught: bounced off the pet's head and away.
  bouncing,

  /// A new ball rolling in to replace the one that got away.
  rollingIn,

  /// The game is finished and its results are up.
  over,
}

enum _Answer { none, right, wrong }

/// Arena geometry for one layout, shared by the build and the clock.
///
/// Sky over the top half, with the pet left of centre on the horizon facing
/// the ball's spot on the right — the way every pet's art faces. A throw goes
/// high, using the sky, and comes down on the pet's head from above and to the
/// right. The word it calls hangs up and to the left, ending no further right
/// than the pet itself, so the ball's way in never crosses it. The answers sit
/// on the grass below, where the thumb is.
class _Geo {
  _Geo(this.w, this.h) {
    horizon = (h * 0.5).roundToDouble();
    petBox = min(min(h * 0.22, w * 0.4), 150.0).roundToDouble();
    petX = (w * 0.4).roundToDouble();
    petTop = (horizon - petBox * 0.9).roundToDouble();
    // Whole cells of the ball's pixel grid, so it never draws half a pixel.
    ball = max(
      BeachBallPainter.cols * 2.0,
      (min(petBox * 0.26, 40.0) / BeachBallPainter.cols).floorToDouble() *
          BeachBallPainter.cols,
    );
    spot = Offset((w * 0.85).roundToDouble(), horizon - ball / 2 + 2);
    // Where a throw meets a pet that stayed put: the top of the head, a
    // little forward.
    head = Offset(petX + petBox * 0.1, petTop + petBox * 0.33);
    // What the pet lifts off the grass to meet a ball in the air: its own
    // head, at the point on the throw's arc it jumps for.
    headAnchor = Offset(petX + petBox * 0.1, petTop + petBox * 0.3);
    // Up to about a fifth of the way from the top of the sky.
    throwArc = max(petBox * 0.9, (spot.dy + head.dy) / 2 - horizon * 0.22);
    returnArc = petBox * 0.6;
    bubbleTip = petTop + petBox * 0.14;
    // Never past the pet, unless the screen is too narrow for a word at all.
    bubbleWidth = max(petX - bubbleLeft, 120.0);

    final fieldTop = horizon + 28;
    final fieldBottom = h - 16;
    tileW = (w - 2 * tileInset - tileGap) / 2;
    tileH = min(60.0, (fieldBottom - fieldTop - tileGap) / 2);
    gridTop = fieldTop +
        max(0.0, (fieldBottom - fieldTop) - (2 * tileH + tileGap)) / 2;
  }

  static const double bubbleH = 54;
  static const double bubbleLeft = 12;
  static const double tileInset = 16;
  static const double tileGap = 12;

  final double w, h;
  late final double horizon, petBox, petX, petTop, ball;
  late final Offset spot, head, headAnchor;
  late final double throwArc, returnArc, bubbleTip, bubbleWidth;
  late final double tileW, tileH, gridTop;

  /// The four answers, two by two.
  Rect tileRect(int lane) => Rect.fromLTWH(
        (tileInset + (lane % 2) * (tileW + tileGap)).roundToDouble(),
        (gridTop + (lane ~/ 2) * (tileH + tileGap)).roundToDouble(),
        tileW.roundToDouble(),
        tileH.roundToDouble(),
      );
}

class _Popup {
  _Popup(this.text, this.color, this.at);
  final String text;
  final Color color;
  final Offset at;
  double age = 0;
}

class _PlayCatchScreenState extends State<PlayCatchScreen>
    with SingleTickerProviderStateMixin {
  static const Color _sky = AppTheme.retroSky;
  static const Color _grass = AppTheme.retroGrass;
  static const Color _ink = AppTheme.retroDark;
  static const Color _gold = AppTheme.retroAccent;

  /// Block faces once a throw is answered: the right meaning lit in full
  /// green, a wrong pick in full red, the rest stepping well back. Pale tints
  /// read as nothing at arm's length, so these are the flat colours the rest
  /// of the game is drawn in, with the label flipped to stay legible on them.
  static const Color _openFace = AppTheme.retroLight;
  static const Color _rightFace = AppTheme.retroGrass;
  static const Color _wrongFace = AppTheme.retroPrimary;
  static const Color _dimFace = Color(0xFF9E9A92);

  /// One toy colour per answer block.
  static final List<SlabPalette> _lanes = [
    SlabPalette.tinted(const Color(0xFFD95763)),
    SlabPalette.tinted(const Color(0xFFDF7126)),
    SlabPalette.tinted(const Color(0xFF76428A)),
    SlabPalette.tinted(const Color(0xFF37946E)),
  ];

  static const List<Color> _hitSparks = [
    AppTheme.retroAccent,
    Color(0xFFFFF3B0),
  ];

  /// Hearts for a ball knocked back, rising off the pet.
  static const int _heartCount = 3;
  static const double _heartSeconds = 0.95;
  static const List<Color> _bonkSparks = [
    AppTheme.retroAccent,
    AppTheme.retroLight,
  ];
  static const List<Color> _dust = [
    Color(0xFF4B8F1D),
    Color(0xFFC9C3B1),
  ];

  static const double _firstGap = 0.9;
  static const double _gap = 0.5;

  /// An answered ball stops waiting: it covers what is left of its flight in
  /// this long, so knowing the word early is rewarded with the next one. It is
  /// also how long the pet's jump takes to reach the top, so the two meet.
  static const double _rushSeconds = 0.36;

  /// How far along its arc a ball is met by a jumping pet — short of the head,
  /// out in the air.
  static const double _hitProgress = 0.9;

  /// Answered later than this, there is no room left to jump: the pet stays
  /// down and knocks the ball back where it stands.
  static const double _jumpCutoff = 0.8;

  /// The jump: a crouch, the rise to [_rushSeconds], a drop, and a squash as
  /// it lands.
  static const double _jumpCrouch = 0.06;
  static const double _jumpLands = 0.58;
  static const double _jumpSeconds = 0.62;
  static const double _returnSeconds = 0.6;
  static const double _landSeconds = 0.35;
  static const double _rollSeconds = 0.55;
  static const double _bonkSeconds = 0.9;
  static const double _happySeconds = 0.7;

  /// A bonked ball pops up off the head and back over the pet, and falls out
  /// of sight on the far side.
  static const Offset _bounceVelocity = Offset(-220, -560);
  static const double _gravity = 1500;

  /// How long each quarter turn of a spinning ball holds.
  static const double _spinStep = 0.1;

  late final Ticker _ticker;
  late final Random _rng = widget.random ?? Random();
  final TrialParticles _particles = TrialParticles();

  /// Bumped every frame, so only the arena rebuilds at frame rate.
  final ValueNotifier<int> _frame = ValueNotifier(0);

  String? _targetCode;
  String? _nativeCode;
  List<TrialWord> _pool = const [];

  /// Built once each: a frame of the game swaps between them, it never
  /// rebuilds a rig.
  late final Widget _petIdle;
  late final Widget _petHappy;
  late final Widget _petSad;

  /// The same two without the silhouette the sprite lays on the ground: a pet
  /// in the air keeps its shadow on the grass, not under its feet.
  late final Widget _petIdleAir;
  late final Widget _petHappyAir;

  CatchGame _game = const CatchGame();
  _Stage _stage = _Stage.ready;
  double _stageTime = 0;
  double _gapSeconds = _firstGap;
  Duration _lastElapsed = Duration.zero;
  _Geo? _geo;

  TrialWave? _wave;
  TrialWord? _lastPrompt;
  _Answer _answer = _Answer.none;
  int? _picked;

  /// How far along its flight the thrown ball is: 0 on its spot, 1 at the
  /// pet's head.
  double _progress = 0;
  double _progressAtAnswer = 0;
  double _flightSeconds = 6;
  /// Where the ball was met — the head, or a point out in the air.
  Offset _contact = Offset.zero;

  /// How far along the arc this throw ends: the head, or where a jumping pet
  /// reaches it.
  double _hitTarget = 1;
  double _spin = 0;
  bool _landed = false;

  double _petHop = -1;
  double _bonk = -1;
  double _happy = 0;

  /// The jump, from the crouch to the landing squash, and where its top is.
  double _jump = -1;
  Offset _jumpTo = Offset.zero;
  bool _jumpLanded = false;

  final List<_Popup> _popups = [];
  final List<_Heart> _hearts = [];

  /// What the finished game added to the pet's happiness, and to the
  /// player's XP.
  int _happiness = 0;
  int _xp = 0;

  bool get _reduceMotion => MediaQuery.disableAnimationsOf(context);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);

    final languages = context.read<LanguageProvider>();
    _targetCode = languages.targetLanguage?.code;
    _nativeCode = languages.nativeLanguage.code;

    // Awake whatever its mood at home, in its own coat and outfit.
    final petType = context.read<CharacterProvider>().currentCharacterType;
    Widget sprite(PetVisualState? state, {bool shadow = true}) =>
        CharacterSprite(
          width: double.infinity,
          height: double.infinity,
          groundShadow: shadow,
          previewType: petType,
          previewState: state,
        );
    _petIdle = sprite(null);
    // Petted is the squint-and-wiggle: the closest thing the rig has to glee.
    _petHappy = sprite(PetVisualState.petted);
    _petSad = sprite(PetVisualState.sad);
    _petIdleAir = sprite(null, shadow: false);
    _petHappyAir = sprite(PetVisualState.petted, shadow: false);

    _pool = playCatchWords(
      items: context.read<VocabProvider>().practiseItems,
      targetCode: _targetCode,
      nativeCode: _nativeCode,
    );
    if (!TrialWordPool.isPlayable(_pool)) {
      // [playCatchWords] ends on a stock pairing that always fills a throw, so
      // this means the stock table itself is broken. Say so, rather than
      // opening and closing in one frame.
      debugPrint('PlayCatch: no playable words for $_targetCode/$_nativeCode');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _leave();
      });
      return;
    }
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frame.dispose();
    _particles.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- clock --

  void _onTick(Duration elapsed) {
    final dt = ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastElapsed = elapsed;
    final geo = _geo;
    if (geo == null) return;

    _particles.update(dt, floor: geo.horizon + 6);
    for (final p in _popups) {
      p.age += dt;
    }
    _popups.removeWhere((p) => p.age > 0.9);
    if (_petHop >= 0) _petHop = _petHop + dt > 0.3 ? -1 : _petHop + dt;
    if (_bonk >= 0) _bonk = _bonk + dt > _bonkSeconds ? -1 : _bonk + dt;
    _happy = max(0.0, _happy - dt);
    _stepJump(dt, geo);
    for (final heart in _hearts) {
      heart.age += dt;
    }
    _hearts.removeWhere((h) => h.age > _heartSeconds);

    _stageTime += dt;
    switch (_stage) {
      case _Stage.ready:
        if (_stageTime >= _gapSeconds) _throwBall();
      case _Stage.flying:
        _spin += dt;
        final step = _answer == _Answer.none
            ? dt / _flightSeconds
            : max(dt / _flightSeconds,
                dt * (_hitTarget - _progressAtAnswer) / _rushSeconds);
        _progress = min(_hitTarget, _progress + step);
        if (_progress >= _hitTarget) _arrive(geo);
      case _Stage.returning:
        if (_stageTime < _returnSeconds) {
          _spin += dt;
        } else if (!_landed) {
          _touchDown(geo);
        }
        if (_stageTime >= _returnSeconds + _landSeconds) _afterThrow();
      case _Stage.bouncing:
        _spin += dt;
        final at = _bounceAt(_stageTime);
        if (at.dx < -geo.ball || at.dy > geo.h + geo.ball) {
          setState(() {
            _stage = _Stage.rollingIn;
            _stageTime = 0;
          });
        }
      case _Stage.rollingIn:
        _spin += dt;
        if (_stageTime >= _rollSeconds) _afterThrow();
      case _Stage.over:
        break;
    }
    _frame.value++;
  }

  // ---------------------------------------------------------------- flow --

  void _throwBall() {
    final wave = TrialWave.build(_pool, previous: _lastPrompt, random: _rng);
    if (wave == null) {
      _finish();
      return;
    }
    setState(() {
      _wave = wave;
      _lastPrompt = wave.prompt;
      _answer = _Answer.none;
      _picked = null;
      _progress = 0;
      _progressAtAnswer = 0;
      _hitTarget = 1;
      // Fixed at the throw, so a ball never speeds up mid-flight on its own.
      _flightSeconds =
          PlayCatchRules.readTime(_game.combo).inMicroseconds / 1e6;
      _stage = _Stage.flying;
      _stageTime = 0;
    });
    // The pet calls for the word as the ball leaves.
    if (!_reduceMotion) _petHop = 0;
  }

  void _choose(int lane) {
    final wave = _wave;
    if (_stage != _Stage.flying || wave == null || _answer != _Answer.none) {
      return;
    }
    final right = lane == wave.answerLane;
    // Answered in time, the pet goes up for it, and the ball is met out in
    // the air rather than on its head. Left too late, there is no room to
    // jump and it knocks the ball back where it stands.
    final jumps = right && !_reduceMotion && _progress < _jumpCutoff;
    setState(() {
      _picked = lane;
      _answer = right ? _Answer.right : _Answer.wrong;
      _progressAtAnswer = _progress;
      _hitTarget = jumps ? _hitProgress : 1;
      _game = right ? _game.caughtIt() : _game.missed(wave.prompt);
    });
    if (jumps) _startJump(_geo!);
    if (right) {
      HapticFeedback.selectionClick();
    } else {
      HapticFeedback.mediumImpact();
    }
  }

  /// Sends the pet up to where the ball will be.
  void _startJump(_Geo geo) {
    final meetsAt = _arc(geo.spot, geo.head, geo.throwArc, _hitProgress);
    _jump = 0;
    _jumpLanded = false;
    // Its head, just under the ball.
    _jumpTo = Offset(
      meetsAt.dx - geo.headAnchor.dx,
      meetsAt.dy + geo.ball * 0.4 - geo.headAnchor.dy,
    );
  }

  void _stepJump(double dt, _Geo geo) {
    if (_jump < 0) return;
    _jump += dt;
    if (!_jumpLanded && _jump >= _jumpLands) {
      _jumpLanded = true;
      if (!_reduceMotion) {
        _particles.sparks(Offset(geo.petX, geo.horizon), count: 5,
            colors: _dust);
      }
    }
    if (_jump > _jumpSeconds) _jump = -1;
  }

  /// How far off the grass the pet is, as a share of its jump: a quick rise to
  /// the top as the ball gets there, then a drop.
  double _jumpPhase() {
    if (_jump < _jumpCrouch) return 0;
    if (_jump < _rushSeconds) {
      return sin((_jump - _jumpCrouch) / (_rushSeconds - _jumpCrouch) * pi / 2);
    }
    if (_jump < _jumpLands) {
      return cos((_jump - _rushSeconds) / (_jumpLands - _rushSeconds) * pi / 2);
    }
    return 0;
  }

  /// The ball reaches the pet's head.
  void _arrive(_Geo geo) {
    final wave = _wave;
    if (wave == null) return;

    final contact = _ballCentre(geo);
    if (_answer == _Answer.right) {
      // Knocked straight back to its spot.
      HapticFeedback.lightImpact();
      _happy = _happySeconds;
      if (!_reduceMotion) {
        if (_jump < 0) _petHop = 0;
        _particles.sparks(contact, count: 6, colors: _hitSparks);
        for (var i = 0; i < _heartCount; i++) {
          _hearts.add(_Heart(
            // Clear of the ball and to its right, away from the word.
            at: contact.translate(
                geo.petBox * (0.22 + 0.13 * i), -geo.petBox * 0.16),
            // Staggered, so they leave one at a time.
            age: -0.12 * i,
            drift: (i - 0.5) * 0.5,
          ));
        }
      }
      _pop(_game.combo > 1 ? 'x${_game.combo}' : '+1', _gold,
          Offset(contact.dx + geo.petBox * 0.35, contact.dy));
      setState(() {
        _contact = contact;
        _stage = _Stage.returning;
        _stageTime = 0;
        _landed = false;
      });
      return;
    }

    // Wrong, or never answered: bonk.
    HapticFeedback.mediumImpact();
    if (!_reduceMotion) {
      _particles.sparks(contact, count: 6, colors: _bonkSparks);
    }
    setState(() {
      if (_answer == _Answer.none) _game = _game.dropped(wave.prompt);
      _bonk = 0;
      _contact = contact;
      _stage = _Stage.bouncing;
      _stageTime = 0;
    });
  }

  /// A headed ball lands back on its spot.
  void _touchDown(_Geo geo) {
    _landed = true;
    if (!_reduceMotion) {
      _particles.sparks(Offset(geo.spot.dx, geo.horizon), count: 5,
          colors: _dust);
    }
  }

  /// The throw is over, whichever way it went: clear the answers, and throw
  /// again or end the game.
  void _afterThrow() {
    setState(() {
      _wave = null;
      _answer = _Answer.none;
      _picked = null;
      _stage = _Stage.ready;
      _stageTime = 0;
      _gapSeconds = _gap;
    });
    if (_game.isOver) _finish();
  }

  Future<void> _finish() async {
    final character = context.read<CharacterProvider>();
    final user = context.read<UserProvider>();
    final caught = _game.caught, thrown = _game.thrown;
    final gained = character.rewardPlay(right: caught, rounds: thrown);
    // Every game in the language is a moment the pet was not forgotten, paid
    // or not — the same as a chat or a quiz.
    if (caught > 0) character.recordLearningMoment();
    setState(() {
      _wave = null;
      _stage = _Stage.over;
      _happiness = gained;
      _xp = 0;
    });
    // Under the toy chest's daily cap, shown as paid rather than as earned.
    final xp =
        await user.awardPlayXp(PlayRewards.xp(right: caught, rounds: thrown));
    if (mounted && xp > 0) setState(() => _xp = xp);
  }

  void _restart() {
    _particles.clear();
    setState(() {
      _game = const CatchGame();
      _wave = null;
      _lastPrompt = null;
      _answer = _Answer.none;
      _picked = null;
      _popups.clear();
      _hearts.clear();
      _happiness = 0;
      _xp = 0;
      _bonk = -1;
      _happy = 0;
      _jump = -1;
      _stage = _Stage.ready;
      _stageTime = 0;
      _gapSeconds = _firstGap;
    });
  }

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  void _pop(String text, Color color, Offset at) =>
      _popups.add(_Popup(text, color, at));

  // ------------------------------------------------------------- the ball --

  /// A point on a thrown arc: straight from [from] to [to], lifted by up to
  /// [lift] in the middle.
  static Offset _arc(Offset from, Offset to, double lift, double t) => Offset(
        from.dx + (to.dx - from.dx) * t,
        from.dy + (to.dy - from.dy) * t - lift * 4 * t * (1 - t),
      );

  Offset _bounceAt(double t) =>
      _contact +
      Offset(
        _bounceVelocity.dx * t,
        _bounceVelocity.dy * t + 0.5 * _gravity * t * t,
      );

  Offset _ballCentre(_Geo geo) {
    switch (_stage) {
      case _Stage.flying:
        return _arc(geo.spot, geo.head, geo.throwArc, _progress);
      case _Stage.returning:
        final t = _stageTime / _returnSeconds;
        if (t < 1) return _arc(_contact, geo.spot, geo.returnArc, t);
        // Two small bounces as it settles, stepped.
        final since = _stageTime - _returnSeconds;
        final hop = since < 0.12
            ? geo.ball * 0.3
            : since >= 0.2 && since < 0.27
                ? geo.ball * 0.1
                : 0.0;
        return geo.spot.translate(0, -hop.roundToDouble());
      case _Stage.bouncing:
        return _bounceAt(_stageTime);
      case _Stage.rollingIn:
        final k = Curves.easeOut
            .transform((_stageTime / _rollSeconds).clamp(0.0, 1.0));
        final start = geo.w + geo.ball;
        return Offset(start + (geo.spot.dx - start) * k, geo.spot.dy);
      case _Stage.ready:
      case _Stage.over:
        return geo.spot;
    }
  }

  // ---------------------------------------------------------------- build --

  TextStyle _pixel(double size, Color color, {String? localeCode}) =>
      AppFonts.pressStart2p(
        fontSize: size,
        color: color,
        locale: localeCode == null ? null : Locale(localeCode),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ink,
      body: SafeArea(
        child: Column(
          children: [
            _buildHud(),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: LayoutBuilder(builder: (context, c) {
                      final geo = _geo;
                      if (geo == null ||
                          geo.w != c.maxWidth ||
                          geo.h != c.maxHeight) {
                        _geo = _Geo(c.maxWidth, c.maxHeight);
                      }
                      return ValueListenableBuilder<int>(
                        valueListenable: _frame,
                        builder: (context, _, __) => _buildArena(_geo!),
                      );
                    }),
                  ),
                  if (_stage == _Stage.over)
                    Positioned.fill(child: _buildResults()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHud() => PlayHud(
        results: _results,
        total: PlayCatchRules.throwsPerGame,
        current: _stage == _Stage.over ? null : _game.thrown,
        combo: _game.combo,
        onClose: _leave,
      );

  /// Every throw so far as the toy chest keeps score: caught or not.
  List<bool> get _results =>
      [for (final r in _game.results) r == CatchResult.caught];

  Widget _buildArena(_Geo geo) {
    final wave = _wave;

    return ClipRect(
      child: Stack(
        children: [
          Positioned.fill(child: Container(color: _sky)),
          Positioned(
            left: 0,
            right: 0,
            top: geo.horizon,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: _grass,
                border: Border(top: BorderSide(color: _ink, width: 4)),
              ),
            ),
          ),
          if (_stage != _Stage.over) _buildBallShadow(geo),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: TrialParticlePainter(_particles, front: false),
              ),
            ),
          ),
          if (wave != null)
            for (var lane = 0; lane < wave.lanes.length; lane++)
              Positioned.fromRect(
                rect: geo.tileRect(lane),
                child: RubbleTile(
                  label: wave.lanes[lane].meaning,
                  style: _pixel(11, _labelFor(wave, lane),
                      localeCode: _nativeCode),
                  palette: _lanes[lane],
                  face: _faceFor(wave, lane),
                  onTapDown: () => _choose(lane),
                ),
              ),
          if (_jump >= 0) _buildPetShadow(geo),
          _buildPet(geo),
          ..._buildDizzyStars(geo),
          // The ball passes behind the word, never over it: a bonked ball
          // flies back over the pet's head and must not blot out what it
          // called.
          if (_stage != _Stage.over) _buildBall(geo),
          if (wave != null) _buildBubble(geo, wave.prompt),
          // In front of the ball they came off, so none is hidden behind it.
          for (final heart in _hearts)
            if (heart.age > 0) _buildHeart(geo, heart),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: TrialParticlePainter(_particles, front: true),
              ),
            ),
          ),
          for (final p in _popups) _buildPopup(p),
        ],
      ),
    );
  }

  Color _faceFor(TrialWave wave, int lane) {
    if (_stage == _Stage.flying && _answer == _Answer.none) return _openFace;
    if (lane == wave.answerLane) return _rightFace;
    if (lane == _picked) return _wrongFace;
    return _dimFace;
  }

  /// The label's ink, which has to change with the face under it: dark on the
  /// open and green ones, light on the red, and faded on the ones that no
  /// longer matter.
  Color _labelFor(TrialWave wave, int lane) {
    final face = _faceFor(wave, lane);
    if (face == _wrongFace) return AppTheme.retroLight;
    if (face == _dimFace) return const Color(0xFF55524D);
    return _ink;
  }

  Widget _buildPet(_Geo geo) {
    final size = geo.petBox;
    var lift = 0.0;
    var dx = 0.0;
    var scaleY = 1.0;
    if (_petHop >= 0) {
      lift = ((sin(_petHop / 0.3 * pi) * 14) / 2).roundToDouble() * 2;
    }
    if (_jump >= 0) {
      // Up to meet the ball and back down, in whole steps of two pixels.
      final phase = _jumpPhase();
      lift = -(_jumpTo.dy * phase / 2).roundToDouble() * 2;
      dx += (_jumpTo.dx * phase / 2).roundToDouble() * 2;
      // Crouched before it goes, squashed as it lands.
      if (_jump < _jumpCrouch || (_jump >= _jumpLands && _jump < _jumpSeconds)) {
        scaleY = 0.86;
      }
    }
    if (_bonk >= 0 && !_reduceMotion) {
      if (_bonk < 0.1) {
        // Squashed by the hit.
        scaleY = 0.88;
      } else if (_bonk < 0.5) {
        // Then a shake of the head, settling.
        dx = (sin(_bonk * 40) * 3 * (1 - _bonk / 0.5)).roundToDouble();
      }
    }
    final airborne = _jump >= 0 && _jumpPhase() > 0.02;
    final Widget sprite;
    if (_bonk >= 0) {
      sprite = _petSad;
    } else if (_happy > 0) {
      sprite = airborne ? _petHappyAir : _petHappy;
    } else {
      sprite = airborne ? _petIdleAir : _petIdle;
    }
    return Positioned(
      left: (geo.petX - size / 2 + dx).roundToDouble(),
      top: geo.petTop - lift,
      width: size,
      height: size,
      child: Transform(
        alignment: Alignment.bottomCenter,
        transform: Matrix4.diagonal3Values(1, scaleY, 1),
        child: sprite,
      ),
    );
  }

  /// Stars circling the pet's head after a bonk, a stepped orbit.
  List<Widget> _buildDizzyStars(_Geo geo) {
    if (_bonk < 0.1 || _reduceMotion) return const [];
    const positions = 8;
    final step = (_bonk / 0.08).floor();
    final centre = Offset(geo.petX, geo.petTop + geo.petBox * 0.2);
    final star = (geo.petBox * 0.07 / 5).roundToDouble().clamp(1.0, 3.0) * 5;
    return [
      for (var i = 0; i < 3; i++)
        Builder(builder: (_) {
          final angle =
              (step + i * positions / 3) * (2 * pi / positions);
          final at = centre +
              Offset(cos(angle) * geo.petBox * 0.22,
                  sin(angle) * geo.petBox * 0.06);
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

  /// The jumping pet's shadow, left behind on the grass.
  Widget _buildPetShadow(_Geo geo) {
    final phase = _jumpPhase();
    final width = (geo.petBox * 0.42 * (1 - 0.45 * phase) / 4).round() * 4.0;
    return Positioned(
      left: (geo.petX - width / 2).roundToDouble(),
      top: geo.horizon + 2,
      width: width,
      height: 5,
      child: const IgnorePointer(
        child: ColoredBox(color: Color(0x33000000)),
      ),
    );
  }

  /// A heart rising off a ball knocked back, shrinking as it goes.
  Widget _buildHeart(_Geo geo, _Heart heart) {
    final k = (heart.age / _heartSeconds).clamp(0.0, 1.0);
    final size = geo.petBox * 0.2 * (k > 0.7 ? (1 - k) / 0.3 : 1);
    final at = Offset(
      heart.at.dx + heart.drift * heart.age * 30,
      heart.at.dy - (k * geo.petBox * 0.5 / 2).roundToDouble() * 2,
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
  }

  /// The word the pet wants, over its head.
  Widget _buildBubble(_Geo geo, TrialWord prompt) {
    final width = geo.bubbleWidth;
    final tailX = (geo.petX - _Geo.bubbleLeft - 8)
        .clamp(24.0, max(24.0, width - 24.0))
        .toDouble();
    return Positioned(
      left: _Geo.bubbleLeft,
      top: geo.bubbleTip - _Geo.bubbleH - ShoutBubble.tailH,
      width: width,
      height: _Geo.bubbleH + ShoutBubble.tailH,
      child: IgnorePointer(
        child: ShoutBubble(
          word: prompt.target,
          style: _pixel(18, _ink, localeCode: _targetCode),
          tailX: tailX,
        ),
      ),
    );
  }

  Widget _buildBall(_Geo geo) {
    final centre = _ballCentre(geo);
    final size = geo.ball;
    final spinning = !_reduceMotion &&
        _stage != _Stage.ready &&
        !(_stage == _Stage.returning && _stageTime >= _returnSeconds);
    final turns = spinning ? (_spin / _spinStep).floor() % 4 : 0;
    // A squash as it touches down on its spot.
    final landing = _stage == _Stage.returning &&
        _stageTime >= _returnSeconds &&
        _stageTime < _returnSeconds + 0.06 &&
        !_reduceMotion;
    return Positioned(
      left: (centre.dx - size / 2).roundToDouble(),
      top: (centre.dy - size / 2).roundToDouble(),
      width: size,
      height: size,
      child: IgnorePointer(
        child: Transform(
          alignment: Alignment.bottomCenter,
          transform: Matrix4.diagonal3Values(
              landing ? 1.15 : 1, landing ? 0.8 : 1, 1),
          child: Transform.rotate(
            angle: turns * pi / 2,
            child: const CustomPaint(
              painter: BeachBallPainter(withShadow: false),
            ),
          ),
        ),
      ),
    );
  }

  /// The ball's shadow on the grass, smaller the higher it flies.
  Widget _buildBallShadow(_Geo geo) {
    final centre = _ballCentre(geo);
    final above = (geo.horizon - (centre.dy + geo.ball / 2)).clamp(0.0, 400.0);
    final k = 1 - (above / 300).clamp(0.0, 0.6);
    final width = max(4.0, (geo.ball * 0.9 * k / 4).round() * 4.0);
    return Positioned(
      left: (centre.dx - width / 2).roundToDouble(),
      top: geo.horizon + 2,
      width: width,
      height: 4,
      child: const IgnorePointer(
        child: ColoredBox(color: Color(0x40000000)),
      ),
    );
  }

  Widget _buildPopup(_Popup p) {
    final rise = _reduceMotion ? 0.0 : ((p.age * 34) / 2).roundToDouble() * 2;
    return Positioned(
      left: p.at.dx - 80,
      top: p.at.dy - rise,
      width: 160,
      child: IgnorePointer(
        child: Text(
          p.text,
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
          style: AppFonts.pressStart2p(
            fontSize: 12,
            color: p.color,
            shadows: const [Shadow(color: Colors.black, offset: Offset(2, 2))],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------- results --

  Widget _buildResults() {
    final l10n = AppLocalizations.of(context)!;
    return PlayResultsPanel(
      results: _results,
      total: PlayCatchRules.throwsPerGame,
      happiness: _happiness,
      xp: _xp,
      xpLabel: l10n.xp,
      toPractise: [for (final w in _game.toPractise) PlayPractice.word(w)],
      targetCode: _targetCode,
      nativeCode: _nativeCode,
      againLabel: l10n.playCatchAgain,
      onAgain: _restart,
      onClose: _leave,
    );
  }
}

/// One heart on its way up from a ball knocked back.
class _Heart {
  _Heart({required this.at, required this.age, required this.drift});

  final Offset at;

  /// Starts negative for the ones that leave a beat later.
  double age;

  /// Sideways drift, so three hearts do not rise in one column.
  final double drift;
}
