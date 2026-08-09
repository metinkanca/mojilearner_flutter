import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../providers/character_provider.dart';
import '../utils/pet_recolor.dart';

enum CharacterMotionProfile { auto, full, reduced }

/// Describes a pet that has been split into independently animatable SVG
/// layers (base body + eyes + muzzle), all sharing the same viewBox so they
/// overlay pixel-perfectly. Pets without an entry fall back to a single
/// whole-sprite render that still breathes.
class _PetParts {
  final String base;
  final String eyes;
  final String mouth;

  /// Pre-baked tail poses for a stepped wag: [left, centre, right]. Swapping
  /// baked poses avoids runtime rotation, which would soften the pixels.
  final List<String> tailFrames;

  /// Open-mouth pose, swapped with [mouth] frame-by-frame for the chew.
  final String mouthOpen;

  /// Pivot (in [Alignment] space) at the vertical centre of the eyes, so a
  /// blink squashes them in place instead of sliding them.
  final Alignment eyesPivot;

  const _PetParts({
    required this.base,
    required this.eyes,
    required this.mouth,
    required this.mouthOpen,
    required this.tailFrames,
    required this.eyesPivot,
  });
}

// Alignments derived from the assembled art viewBox "-20 -40 222 278"
// (widened 20px left for the tail flick + 40px top for hat headroom):
//   eyes bottom edge ~ (118.5, 89) -> Alignment(0.248, -0.072)
//       (pivot at the bottom so the lid closes downward, top -> bottom)
//   chew swaps cat_mouth <-> cat_mouth_open (no scaling).
//   tail flicks left (cat_tail_l) hinged at the bottom (~38, 224), no
//       runtime rotation. cat_tail_r is unused (left-only flick).
const Map<String, _PetParts> _layeredPets = {
  'cat': _PetParts(
    base: 'assets/svgs/cat_base.svg',
    eyes: 'assets/svgs/cat_eyes.svg',
    mouth: 'assets/svgs/cat_mouth.svg',
    mouthOpen: 'assets/svgs/cat_mouth_open.svg',
    tailFrames: [
      'assets/svgs/cat_tail_l.svg', // wag left
      'assets/svgs/cat_tail.svg', // centre (rest)
      'assets/svgs/cat_tail_r.svg', // wag right (unused)
    ],
    eyesPivot: Alignment(0.248, -0.072),
  ),
};

class CharacterSprite extends StatefulWidget {
  final double width;
  final double height;
  final BoxFit fit;
  final CharacterMotionProfile motionProfile;

  const CharacterSprite({
    super.key,
    required this.width,
    required this.height,
    this.fit = BoxFit.contain,
    this.motionProfile = CharacterMotionProfile.auto,
  });

  @override
  State<CharacterSprite> createState() => _CharacterSpriteState();
}

class _CharacterSpriteState extends State<CharacterSprite>
    with TickerProviderStateMixin {
  late final AnimationController _breath;
  late final AnimationController _blink;
  Timer? _blinkTimer;
  final math.Random _rng = math.Random();
  bool _reduceMotion = false;

  // Recolouring works on the raw SVG text: each layer is loaded once, then the
  // flat coat/eye fills are swapped per [PetColorSpec] and rendered via
  // SvgPicture.string. Until the raw strings arrive we fall back to the
  // original asset render (the un-customised look).
  final Map<String, String> _rawSvg = {};
  bool _rawLoaded = false;
  final Map<String, String> _tintCache = {};
  PetColorSpec? _tintCacheSpec;

  // Pixel-style stepping: idle motion is sampled on a low-fps grid and snapped
  // to a few discrete levels, so the pet moves in chunky frames rather than
  // interpolating smoothly.
  static const int _idleFps = 8;
  static const int _breathSteps = 2; // signed snap -> 5 poses (incl. rest)
  static const double _exhaleFactor = 1.5; // exhale dips lower than inhale rises

  /// Snaps a 0..1 value to (levels + 1) discrete steps.
  double _quantize(double v, int levels) =>
      (v * levels).roundToDouble() / levels;

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _scheduleBlink();
    _loadRawLayers();
  }

  /// Loads the raw text of every recolourable cat layer once, so it can be
  /// tinted on demand. The eyes layer is generated from scratch (see
  /// [buildEyesLayer]) and is not loaded here.
  Future<void> _loadRawLayers() async {
    final parts = _layeredPets['cat'];
    if (parts == null) return;
    final assets = <String>{
      parts.base,
      parts.mouth,
      parts.mouthOpen,
      ...parts.tailFrames,
    };
    for (final asset in assets) {
      try {
        _rawSvg[asset] = await rootBundle.loadString(asset);
      } catch (_) {
        // Missing/unreadable asset: that layer keeps its plain asset render.
      }
    }
    if (mounted) setState(() => _rawLoaded = true);
  }

  /// Recolours [asset]'s coat fills for [spec], memoised per spec. Layers
  /// without coat fills (the mouth) pass through unchanged.
  String? _tintedBody(String asset, PetColorSpec spec) {
    if (!_rawLoaded) return null;
    final raw = _rawSvg[asset];
    if (raw == null) return null;
    if (_tintCacheSpec != spec) {
      _tintCache.clear();
      _tintCacheSpec = spec;
    }
    return _tintCache[asset] ??= recolorBodyLayer(raw, spec.bodyColor);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduce == _reduceMotion) return;
    _reduceMotion = reduce;
    if (reduce) {
      _breath.stop();
      _blinkTimer?.cancel();
      _blink.value = 0.0;
    } else {
      _breath.repeat();
      _scheduleBlink();
    }
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _breath.dispose();
    _blink.dispose();
    super.dispose();
  }

  void _scheduleBlink() {
    if (_reduceMotion) return;
    // Idle pets blink every ~2.2-5.8s, occasionally twice in a row.
    final delayMs = 2200 + _rng.nextInt(3600);
    _blinkTimer = Timer(Duration(milliseconds: delayMs), () async {
      if (!mounted || _reduceMotion) return;
      await _playBlink();
      if (mounted && !_reduceMotion && _rng.nextDouble() < 0.2) {
        await _playBlink();
      }
      if (mounted) _scheduleBlink();
    });
  }

  Future<void> _playBlink() async {
    try {
      await _blink.forward();
      if (mounted) await _blink.reverse();
    } on TickerCanceled {
      // Widget disposed mid-blink; nothing to do.
    }
  }

  CharacterMotionProfile _effectiveProfile(BoxConstraints constraints) {
    if (widget.motionProfile != CharacterMotionProfile.auto) {
      return widget.motionProfile;
    }

    final width =
        constraints.maxWidth.isFinite ? constraints.maxWidth : widget.width;
    final height =
        constraints.maxHeight.isFinite ? constraints.maxHeight : widget.height;
    final minSide = math.min(width, height);

    if (!minSide.isFinite || minSide <= 0) {
      return CharacterMotionProfile.full;
    }
    if (minSide < 64) {
      return CharacterMotionProfile.reduced;
    }
    return CharacterMotionProfile.full;
  }

  double _motionGain(BoxConstraints constraints) {
    final width =
        constraints.maxWidth.isFinite ? constraints.maxWidth : widget.width;
    final height =
        constraints.maxHeight.isFinite ? constraints.maxHeight : widget.height;
    final minSide = math.min(width, height);

    if (!minSide.isFinite || minSide <= 0) return 1.0;
    if (minSide >= 120) return 1.0;
    return (120 / minSide).clamp(1.0, 2.0).toDouble();
  }

  String _safeCurrentCharacterType(CharacterProvider provider) {
    try {
      return provider.currentCharacterType;
    } catch (_) {
      return 'cat';
    }
  }

  String _safeCurrentCharacterAsset(CharacterProvider provider) {
    try {
      return provider.currentCharacterAsset;
    } catch (_) {
      return 'assets/svgs/cat.svg';
    }
  }

  PetVisualState _safeVisualState(CharacterProvider provider) {
    try {
      return provider.visualState;
    } catch (_) {
      return PetVisualState.breathing;
    }
  }

  PetEatingPhase _safeEatingPhase(CharacterProvider provider) {
    try {
      return provider.eatingPhase;
    } catch (_) {
      return PetEatingPhase.none;
    }
  }

  /// Breathing amplitude for a given mood. Returns the peak extra vertical
  /// scale (e.g. 0.022 -> body stretches up to 2.2% taller on the inhale).
  double _breatheAmpFor(PetVisualState state) {
    switch (state) {
      case PetVisualState.happy:
        return 0.030;
      case PetVisualState.sad:
        return 0.010;
      case PetVisualState.sleeping:
        return 0.016;
      case PetVisualState.eating:
        return 0.018;
      case PetVisualState.breathing:
        return 0.022;
    }
  }

  Widget _svgLayer(String asset, double? w, double? h) {
    return SvgPicture.asset(asset, width: w, height: h, fit: widget.fit);
  }

  /// Renders a recoloured coat layer (base / tail / mouth). Falls back to the
  /// plain asset until the raw text has loaded.
  Widget _coatLayer(String asset, double? w, double? h, PetColorSpec spec) {
    final tinted = _tintedBody(asset, spec);
    if (tinted == null) return _svgLayer(asset, w, h);
    return SvgPicture.string(tinted, width: w, height: h, fit: widget.fit);
  }

  PetColorSpec _safeColorSpec(CharacterProvider provider) {
    try {
      return provider.colorSpec;
    } catch (_) {
      return const PetColorSpec(
        bodyColor: '#959379',
        eyeMode: EyeMode.solid,
        eyeColor1: '#F4C430',
        eyeColor2: '#5AA0E0',
      );
    }
  }

  List<String> _safeEquippedAccessoryAssets(CharacterProvider provider) {
    try {
      return provider.equippedAccessoryAssets;
    } catch (_) {
      return const <String>[];
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CharacterProvider>();
    final type = _safeCurrentCharacterType(provider);
    final parts = _layeredPets[type];
    final spec = _safeColorSpec(provider);

    final w = widget.width.isFinite ? widget.width : null;
    final h = widget.height.isFinite ? widget.height : null;

    return SizedBox(
      width: w,
      height: h,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final profile = _effectiveProfile(constraints);
          final fullMotion = profile == CharacterMotionProfile.full;
          final motionGain = _motionGain(constraints);

          return AnimatedBuilder(
            animation: Listenable.merge([_breath, _blink]),
            builder: (context, _) {
              final state = _safeVisualState(provider);

              // Sample the breathing loop on a low-fps grid so motion advances
              // in chunky frames instead of every render.
              final breathMs = _breath.duration?.inMilliseconds ?? 2800;
              final loopFrames =
                  math.max(1, (breathMs * _idleFps / 1000).round());
              final frame = (_breath.value * loopFrames).floor();
              final tStep = frame / loopFrames; // time snapped to the fps grid
              // Signed breath: +1 = peak inhale, -1 = deepest exhale, 0 = rest.
              final breath =
                  _quantize(math.sin(tStep * 2 * math.pi), _breathSteps);
              final inhale = math.max(0.0, breath);
              final exhale = math.max(0.0, -breath);

              // Body holds still while eating (only the mouth + tail move).
              final eating = state == PetVisualState.eating;
              double inhaleAmp = _breatheAmpFor(state);
              inhaleAmp *= motionGain * (fullMotion ? 1.0 : 0.5);
              if (_reduceMotion || eating) inhaleAmp = 0.0;
              final exhaleAmp = inhaleAmp * _exhaleFactor;

              // Squash & stretch anchored at the feet: stretch up on the inhale,
              // dip lower on the exhale, with a slight width pinch for volume.
              // Rest (1.0) is held whenever the breath quantises to zero.
              final scaleY = 1.0 + inhaleAmp * inhale - exhaleAmp * exhale;
              final scaleX =
                  1.0 - inhaleAmp * 0.35 * inhale + exhaleAmp * 0.35 * exhale;

              // Whole-sprite render (dog/bird, or any unsplit pet).
              if (parts == null) {
                return Transform(
                  alignment: Alignment.bottomCenter,
                  transform: Matrix4.diagonal3Values(scaleX, scaleY, 1.0),
                  child: _svgLayer(_safeCurrentCharacterAsset(provider), w, h),
                );
              }

              // Layered render (cat): stepped blink + stepped chew.
              // Blink is a 3-frame sequence (open -> half -> shut); the eye
              // pivot is at the bottom, so the lid closes downward.
              final blinkStep = _quantize(_blink.value, 2); // 0, 0.5, 1.0
              final eyeScaleY = _reduceMotion ? 1.0 : (1.0 - 0.88 * blinkStep);

              // Chew: swap closed <-> open mouth on the fps grid. Mouth is held
              // open while food is hovering (waiting phase).
              String mouthAsset = parts.mouth;
              if (!_reduceMotion && eating) {
                if (_safeEatingPhase(provider) == PetEatingPhase.consuming) {
                  mouthAsset = frame.isEven ? parts.mouthOpen : parts.mouth;
                } else {
                  mouthAsset = parts.mouthOpen;
                }
              }

              // Tail wag: swap between pre-baked poses (left/centre/right) on
              // the fps grid -- no runtime rotation, so the pixels stay crisp.
              // Wags in every state except a hard stop (reduce-motion), so it
              // still flicks while the pet is "dozing" (AI offline). Quicker
              // when happy, slower/idle otherwise.
              // Tail flicks to the LEFT (outward, away from the body) and back
              // to rest, rather than swinging both ways. 0 = left pose, 1 = rest.
              int tailIdx = 1; // centre / rest
              if (!_reduceMotion) {
                final freq = state == PetVisualState.happy ? 3.5 : 2.5;
                final wag = math.sin(tStep * 2 * math.pi * freq);
                tailIdx = wag < -0.4 ? 0 : 1; // dip left, else rest
              }

              // Equipped accessories overlay on top of the pet (hat/neck/face),
              // pre-positioned on the pet canvas so they ride the breath too.
              final accessoryAssets = _safeEquippedAccessoryAssets(provider);

              final stack = Stack(
                fit: StackFit.passthrough,
                children: [
                  _coatLayer(parts.base, w, h, spec),
                  _coatLayer(parts.tailFrames[tailIdx], w, h, spec),
                  _coatLayer(mouthAsset, w, h, spec),
                  Transform(
                    alignment: parts.eyesPivot,
                    transform: Matrix4.diagonal3Values(1.0, eyeScaleY, 1.0),
                    child: SvgPicture.string(
                      buildEyesLayer(spec),
                      width: w,
                      height: h,
                      fit: widget.fit,
                    ),
                  ),
                  for (final asset in accessoryAssets) _svgLayer(asset, w, h),
                ],
              );

              return Transform(
                alignment: Alignment.bottomCenter,
                transform: Matrix4.diagonal3Values(scaleX, scaleY, 1.0),
                child: stack,
              );
            },
          );
        },
      ),
    );
  }
}
