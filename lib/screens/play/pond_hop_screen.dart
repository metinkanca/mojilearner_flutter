import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../components/boss_trial/arena_pieces.dart' show ShoutBubble;
import '../../components/character_sprite.dart';
import '../../components/play/play_props.dart';
import '../../providers/vocab_provider.dart';
import '../../utils/boss_trial.dart';
import '../../utils/boss_trial_moss.dart';
import '../../utils/play_games.dart';
import 'play_game_state.dart';

/// Pond Hop: Mossback's Stepping Stones, played across a lily pond.
///
/// The pet starts on the near bank and crosses a row of lily pads at a time.
/// A frog on the far bank calls a word in the language being learned, and
/// the pads in the next row carry meanings in the player's: the right one is
/// the one to hop onto. The pad the pet stands on — or the bank's edge, for
/// the first hop — slowly sinks, which is the clock. A wrong pad, or waiting
/// too long, gets the pet a dunking and nothing worse: it climbs back out,
/// the right pad lights up, and it hops across onto that one, so every row is
/// crossed. Two ponds make a game. See [PondHopRules].
class PondHopScreen extends StatefulWidget {
  const PondHopScreen({super.key, this.random});

  /// Fixed in tests, so the crossings are known.
  final Random? random;

  @override
  State<PondHopScreen> createState() => _PondHopScreenState();
}

enum _Stage {
  /// A beat before a pond, the pet on the near bank.
  waiting,

  /// A word called, and the next row's pads open.
  choosing,

  /// On its way onto a pad, or onto the far bank.
  hopping,

  /// Dunked: under, then climbing back out.
  splashing,

  /// Across, on the far bank by the frog.
  crossed,

  /// Off to the next pond: up out of sight, and in again from below.
  leaving,
}

/// Scene geometry for one layout: the far bank across the top with the frog
/// and its word, the near bank across the bottom, and the pond between them
/// in rows of lily pads, four lanes wide.
class _Geo {
  _Geo(this.w, this.h) {
    farBank = max(80.0, h * 0.15).roundToDouble();
    nearBank = max(64.0, h * 0.12).roundToDouble();
    pondTop = farBank;
    pondBottom = h - nearBank;
    pitch = (pondBottom - pondTop) / (PondHopRules.rowsPerPond + 0.4);
    laneW = (w - 16) / BossTrialRules.wordsPerWave;
    padW = ((laneW - 8) / 4).floorToDouble() * 4;
    padH = (min(44.0, pitch * 0.44) / 4).roundToDouble() * 4;
    petBox = min(min(pitch * 0.8, laneW * 0.95), 110.0).roundToDouble();
    frogBox = min(farBank * 0.85, 72.0).roundToDouble();
    frogX = (w - frogBox / 2 - 10).roundToDouble();
    frogFeet = farBank - 6;
    bubbleW = (w - frogBox - 34).roundToDouble();
    bubbleH = min(54.0, farBank - 14 - ShoutBubble.tailH);
  }

  static const double bubbleTop = 6;

  final double w, h;
  late final double farBank, nearBank, pondTop, pondBottom, pitch;
  late final double laneW, padW, padH, petBox;
  late final double frogBox, frogX, frogFeet, bubbleW, bubbleH;

  double laneX(int lane) => (8 + laneW * (lane + 0.5)).roundToDouble();

  /// The middle of row [row]'s pads, counted up from the near bank.
  double rowY(int row) => (pondBottom - pitch * (row + 0.7)).roundToDouble();

  Rect padRect(int row, int lane) => Rect.fromCenter(
        center: Offset(laneX(lane), rowY(row)),
        width: padW,
        height: padH,
      );

  /// Where the pet stands on the near bank, on a pad, and on the far bank.
  Offset get bankFeet => Offset((w / 2).roundToDouble(), h - nearBank * 0.4);
  Offset padFeet(int row, int lane) =>
      Offset(laneX(lane), rowY(row) + (padH * 0.15).roundToDouble());
  Offset get farFeet =>
      Offset((frogX - frogBox * 0.5 - petBox * 0.55).roundToDouble(),
          frogFeet);
}

/// Clips everything below [line]: the pond's surface, for a pet going under.
class _AboveLine extends CustomClipper<Rect> {
  const _AboveLine(this.line);

  final double line;

  @override
  Rect getClip(Size size) => Rect.fromLTRB(0, 0, size.width, line);

  @override
  bool shouldReclip(covariant _AboveLine old) => old.line != line;
}

class _PondHopScreenState extends PlayGameState<PondHopScreen> {
  static const double _firstWait = 0.9;
  static const double _hopSeconds = 0.32;
  static const double _dunkSeconds = 0.75;
  static const double _showRight = 0.45;
  static const double _crossedHold = 1.2;
  static const double _leaveSeconds = 0.8;

  List<TrialWord> _pool = const [];
  _Geo? _geo;

  _Stage _stage = _Stage.waiting;
  double _stageTime = 0;
  double _time = 0;

  Crossing? _crossing;
  double _sinkSeconds = 5;

  /// The row to hop onto next; the near bank is before row 0.
  int _row = 0;

  /// The lane of the pad the pet stands on, or null on a bank.
  int? _onLane;

  /// This hop's clock: the pad under the pet sinking, 0 to 1.
  double _sink = 0;

  /// The hop under way: from where, to where, and what it is for.
  Offset _hopFrom = Offset.zero;
  Offset _hopTo = Offset.zero;
  int? _hopLane;
  bool _hopWrong = false;
  bool _hopAcross = false;

  /// The pad picked wrong in this row, which takes the pet under with it.
  int? _wrongLane;

  /// Whether this row has gone wrong, so the right pad is lit and the pet
  /// is shown the way across.
  bool _missed = false;

  /// Where a dunking happened, and whether the pet went under there — off
  /// a pad it did; on the bank, the tide only splashes it.
  Offset _splashAt = Offset.zero;
  bool _splashDunks = false;

  double _frogHop = -1;

  late final Widget _frog = const CharacterSprite(
    width: double.infinity,
    height: double.infinity,
    groundShadow: true,
    // Any frog, not one the player may have painted: it is the pond's.
    previewType: 'frog',
    naturalCoat: true,
    previewAccessories: [],
  );

  @override
  Random? get seed => widget.random;

  @override
  int get rounds => PondHopRules.rowsPerGame;

  @override
  double get particleFloor => _geo?.h ?? 0;

  @override
  bool loadContent() {
    final words = playWords(
      items: context.read<VocabProvider>().items,
      targetCode: targetCode,
      nativeCode: nativeCode,
    );
    _pool = words.pool;
    targetCode = words.targetCode;
    nativeCode = words.nativeCode;
    return TrialWordPool.isPlayable(_pool);
  }

  @override
  void resetGame() => _newPond();

  void _newPond() {
    _crossing = Crossing.build(_pool,
        random: rng, rows: PondHopRules.rowsPerPond);
    _row = 0;
    _onLane = null;
    _sink = 0;
    _wrongLane = null;
    _missed = false;
    _stage = _Stage.waiting;
    _stageTime = 0;
  }

  CrossingRow? get _currentRow {
    final crossing = _crossing;
    if (crossing == null || _row >= crossing.rows.length) return null;
    return crossing.rows[_row];
  }

  @override
  void step(double dt) {
    _time += dt;
    _stageTime += dt;
    if (_frogHop >= 0) _frogHop = _frogHop + dt > 0.3 ? -1 : _frogHop + dt;
    switch (_stage) {
      case _Stage.waiting:
        if (_stageTime >= _firstWait) {
          if (_crossing == null) {
            finish();
            return;
          }
          _call();
        }
      case _Stage.choosing:
        _sink = min(1.0, _sink + dt / _sinkSeconds);
        if (_sink >= 1) _splash(wrongLane: null);
      case _Stage.hopping:
        if (_stageTime >= _hopSeconds) _landed();
      case _Stage.splashing:
        if (_stageTime >= _dunkSeconds + _showRight) _showTheWay();
      case _Stage.crossed:
        if (_stageTime >= _crossedHold) {
          if (score.played >= rounds) {
            finish();
          } else {
            refresh(() {
              _stage = _Stage.leaving;
              _stageTime = 0;
            });
          }
        }
      case _Stage.leaving:
        if (_stageTime >= _leaveSeconds) {
          refresh(() {
            _newPond();
            // Straight on: the pet is already on the bank.
            _stageTime = _firstWait;
          });
        }
    }
  }

  /// The frog calls the next row's word.
  void _call() {
    refresh(() {
      // Fixed for the hop, so the pad never sinks faster halfway.
      _sinkSeconds = PondHopRules.sinkTime(score.combo).inMicroseconds / 1e6;
      _sink = 0;
      _wrongLane = null;
      _missed = false;
      _stage = _Stage.choosing;
      _stageTime = 0;
    });
    if (!reduceMotion) _frogHop = 0;
  }

  void _tapPad(int row, int stone) {
    final line = _currentRow, geo = _geo;
    if (_stage != _Stage.choosing || line == null || geo == null) return;
    if (row != _row) return;
    final lane = line.lanes[stone];
    final wrong = stone != line.answer;
    if (wrong) refresh(() => _wrongLane = lane);
    _hop(geo.padFeet(row, lane), lane: lane, wrong: wrong);
  }

  void _hop(Offset to, {int? lane, bool wrong = false, bool across = false}) {
    final geo = _geo!;
    refresh(() {
      _hopFrom = _feet(geo);
      _hopTo = to;
      _hopLane = lane;
      _hopWrong = wrong;
      _hopAcross = across;
      _stage = _Stage.hopping;
      _stageTime = 0;
    });
  }

  void _landed() {
    final geo = _geo!;
    final line = _currentRow;
    if (_hopAcross) {
      // On the far bank, by the frog.
      refresh(() {
        _onLane = null;
        _stage = _Stage.crossed;
        _stageTime = 0;
      });
      if (!reduceMotion) {
        _frogHop = 0;
        petHop = 0;
      }
      return;
    }
    if (!reduceMotion) {
      particles.sparks(_hopTo, count: 6, colors: PondPainter.splash);
    }
    if (_hopWrong) {
      // The pad goes under, and the pet with it.
      _splash(wrongLane: _hopLane);
      return;
    }
    if (line != null && !_missed) {
      scoreRight(
          at: _hopTo.translate(0, -geo.petBox * 0.7), petBox: geo.petBox);
    }
    refresh(() {
      _onLane = _hopLane;
      _row++;
      _sink = 0;
    });
    if (_row >= PondHopRules.rowsPerPond) {
      _hop(geo.farFeet, across: true);
    } else {
      _call();
    }
  }

  /// A dunking: from a wrong pad going under, or from waiting too long.
  void _splash({required int? wrongLane}) {
    final line = _currentRow, geo = _geo;
    if (line == null || geo == null) return;
    final at = _feet(geo);
    scoreMissed(PlayPractice.word(line.prompt));
    bonk();
    if (!reduceMotion) {
      particles.sparks(at, count: 14, colors: PondPainter.splash);
    }
    refresh(() {
      _splashAt = at;
      _splashDunks = wrongLane != null || _standingOnPad;
      _missed = true;
      _wrongLane = wrongLane;
      // The pad it was on bobs back up as it goes under.
      _sink = 0;
      _stage = _Stage.splashing;
      _stageTime = 0;
    });
  }

  /// Out of the water, and shown across: onto the right pad.
  void _showTheWay() {
    final line = _currentRow, geo = _geo;
    if (line == null || geo == null) return;
    final lane = line.lanes[line.answer];
    // Back where it went in from, then over.
    refresh(() {
      _wrongLane = null;
      _sink = 0;
    });
    _hop(geo.padFeet(_row, lane), lane: lane);
  }

  /// Whether the pet is standing on a pad, rather than a bank.
  bool get _standingOnPad =>
      _onLane != null && _row > 0 && _stage != _Stage.crossed;

  /// Where the pet's feet are when it is standing still.
  Offset _restingFeet(_Geo geo) {
    if (_stage == _Stage.crossed) return geo.farFeet;
    final lane = _onLane;
    if (lane == null || _row == 0) return geo.bankFeet;
    return geo.padFeet(_row - 1, lane);
  }

  /// How far under the pet is, 0 to 1: down where it went in, then — if it
  /// has a pad to climb back onto — up out of the water on that.
  double get _dunk {
    if (_stage != _Stage.splashing || !_splashDunks) return 0;
    final k = _stageTime / _dunkSeconds;
    if (k >= 1) return 0;
    final d = k < 0.5 ? k * 2 : (_standingOnPad ? (1 - k) * 2 : 0.0);
    return (d * 4).round() / 4;
  }

  /// Where the pet's feet are this frame, and how high off them it is.
  Offset _feet(_Geo geo) => _petAt(geo).$1;

  (Offset, double) _petAt(_Geo geo) {
    switch (_stage) {
      case _Stage.hopping:
        final k = (_stageTime / _hopSeconds).clamp(0.0, 1.0);
        final at = Offset.lerp(_hopFrom, _hopTo, k)!;
        final lift = geo.pitch * 0.55 * 4 * k * (1 - k);
        return (_stepped(at), (lift / 2).roundToDouble() * 2);
      case _Stage.leaving:
        final from = geo.farFeet;
        final half = _leaveSeconds / 2;
        if (_stageTime < half) {
          // Up and out over the top.
          final k = _stageTime / half;
          return (_stepped(Offset(from.dx, from.dy - k * (geo.h * 0.4))), 0);
        }
        // In again from below, onto the near bank.
        final k = Curves.easeOut.transform((_stageTime - half) / half);
        final to = geo.bankFeet;
        return (
          _stepped(Offset(to.dx, to.dy + (1 - k) * (geo.nearBank + geo.petBox))),
          0,
        );
      case _Stage.splashing:
        final under = _splashDunks && _stageTime < _dunkSeconds / 2;
        return (_stepped(under ? _splashAt : _restingFeet(geo)), 0);
      default:
        final rest = _restingFeet(geo);
        // Standing on a pad, it goes down as the pad does.
        final onPad = _stage == _Stage.choosing && _onLane != null && _row > 0;
        final sinking = onPad ? _padSunk(_sink) * geo.padH : 0.0;
        return (_stepped(rest.translate(0, sinking)), 0);
    }
  }

  static Offset _stepped(Offset at) =>
      Offset((at.dx / 2).roundToDouble() * 2, (at.dy / 2).roundToDouble() * 2);

  /// How far a pad under the pet has gone down with [sink] of the clock
  /// spent: not at all for the first half, then steadily under.
  static double _padSunk(double sink) => max(0.0, (sink - 0.4) / 0.6) * 0.6;

  // ---------------------------------------------------------------- build --

  @override
  Widget buildScene(BoxConstraints box) {
    final old = _geo;
    final geo = old != null && old.w == box.maxWidth && old.h == box.maxHeight
        ? old
        : _geo = _Geo(box.maxWidth, box.maxHeight);
    final crossing = _crossing;
    final line = _currentRow;
    final (feet, lift) = _petAt(geo);

    final dunk = _dunk;

    return Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: geo.pondTop,
          bottom: geo.nearBank,
          child: CustomPaint(painter: PondPainter(_time)),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: geo.farBank,
          child: const CustomPaint(painter: BankPainter(down: true)),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: geo.nearBank,
          child: const CustomPaint(painter: BankPainter(down: false)),
        ),
        // The first hop's clock: the tide creeping up the bank to the pet.
        if (_stage == _Stage.choosing && _row == 0)
          Positioned(
            left: 0,
            right: 0,
            top: geo.pondBottom,
            height: ((geo.bankFeet.dy - geo.pondBottom) * _sink / 4)
                    .floorToDouble() *
                4,
            child: CustomPaint(
              painter: PondPainter(_time),
              child: const Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  height: 4,
                  width: double.infinity,
                  child: ColoredBox(color: PondPainter.glint),
                ),
              ),
            ),
          ),
        if (crossing != null) ..._buildPads(geo, crossing),
        particleLayer(front: false),
        // The frog, on the far bank.
        Positioned(
          left: geo.frogX - geo.frogBox / 2,
          top: geo.frogFeet -
              geo.frogBox -
              (_frogHop < 0
                  ? 0
                  : ((sin(_frogHop / 0.3 * pi) * 10) / 2).roundToDouble() * 2),
          width: geo.frogBox,
          height: geo.frogBox,
          child: IgnorePointer(child: _frog),
        ),
        Positioned.fill(
          child: ClipRect(
            clipper: dunk > 0
                ? _AboveLine(feet.dy + 2)
                : const _AboveLine(double.infinity),
            child: Stack(
              children: [
                positionedPet(
                  feet: feet.translate(0, dunk * geo.petBox * 0.55),
                  size: geo.petBox,
                  lift: lift,
                  air: lift > 2,
                ),
              ],
            ),
          ),
        ),
        ...dizzyStars(feet.translate(0, -geo.petBox * 0.8), geo.petBox),
        ...buildHearts(geo.petBox),
        if (line != null &&
            (_stage == _Stage.choosing || _stage == _Stage.splashing))
          Positioned(
            left: 10,
            top: _Geo.bubbleTop,
            width: geo.bubbleW,
            height: geo.bubbleH + ShoutBubble.tailH,
            child: IgnorePointer(
              child: ShoutBubble(
                word: line.prompt.target,
                style: pixelTarget(16, PlayGameState.ink),
                tailX: geo.bubbleW - 20,
              ),
            ),
          ),
        particleLayer(front: true),
        ...buildPopups(),
      ],
    );
  }

  List<Widget> _buildPads(_Geo geo, Crossing crossing) {
    final open = _stage == _Stage.choosing ||
        _stage == _Stage.splashing ||
        (_stage == _Stage.hopping && !_hopAcross);
    final labelStyle = pixelNative(10, PlayGameState.ink);
    return [
      for (var r = 0; r < crossing.rows.length; r++)
        for (var s = 0; s < crossing.rows[r].stones.length; s++)
          Builder(builder: (_) {
            final row = crossing.rows[r];
            final lane = row.lanes[s];
            final current = r == _row && open;
            final state = !current
                ? PropState.plain
                : lane == _wrongLane
                    ? PropState.wrong
                    : _missed && s == row.answer
                        ? PropState.right
                        : PropState.plain;
            var sunk = 0.0;
            if (r == _row - 1 && lane == _onLane && _stage == _Stage.choosing) {
              sunk = _padSunk(_sink);
            } else if (current && lane == _wrongLane &&
                _stage == _Stage.splashing) {
              sunk = (_stageTime / (_dunkSeconds / 2)).clamp(0.0, 1.0);
            }
            return Positioned.fromRect(
              rect: geo.padRect(r, lane),
              child: LilyPad(
                label: current ? row.stones[s].meaning : null,
                style: state == PropState.wrong
                    ? pixelNative(10, propInk(state))
                    : labelStyle,
                state: state,
                sunk: sunk,
                onTapDown: current && _stage == _Stage.choosing
                    ? () => _tapPad(r, s)
                    : null,
              ),
            );
          }),
    ];
  }
}

