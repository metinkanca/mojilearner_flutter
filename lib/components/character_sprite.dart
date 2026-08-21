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

  /// Eye cell geometry for the generated (recoloured) eyes layer.
  final PetEyeGeometry eyeGeometry;

  /// Translation, in canvas art units, applied to every equipped accessory.
  ///
  /// The accessory art is drawn once, seated on the cat's head. Rather than
  /// keeping a second copy of all 22 files per pet, a pet whose head sits
  /// elsewhere on the shared canvas moves the accessories to meet it.
  final Offset accessoryOffset;

  const _PetParts({
    required this.base,
    required this.eyes,
    required this.mouth,
    required this.mouthOpen,
    required this.tailFrames,
    required this.eyesPivot,
    required this.eyeGeometry,
    this.accessoryOffset = Offset.zero,
  });
}

// Alignments derived from the assembled art viewBox "-20 -90 222 328"
// (widened 20px left for the tail flick + 90px top for hat headroom -- the
// witch hat alone stands 133px tall, against a 113px head):
//   eyes bottom edge ~ (118.5, 89) -> Alignment(0.248, 0.091)
//       (pivot at the bottom so the lid closes downward, top -> bottom)
//   chew swaps cat_mouth <-> cat_mouth_open (no scaling).
//   tail flicks left (cat_tail_l) hinged at the bottom (~38, 224), no
//       runtime rotation. cat_tail_r is unused (left-only flick).
//       The flick poses are baked as a whole-unit shear about that hinge:
//       each row steps sideways by a rounded amount, so every edge stays on
//       the pixel grid. They used to be the rest pose under an SVG
//       `rotate(+-10)`, which softened the pixels and left hairline holes
//       where the outline pieces no longer met -- the coat colour showed
//       through them, outside the outline.
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
    eyesPivot: Alignment(0.248, 0.091),
    eyeGeometry: kCatEyes,
  ),
  // The dog art is 208x248 against the cat's 202x238, placed feet-on-the-same
  // ground line, which leaves its head ~30 units higher than the cat's -- hence
  // the accessory offset. Its tail is a tall straight flap rather than a curl,
  // so the wag poses are baked as a one-cell bend at the hinge rather than the
  // cat's sheared curl -- either way the edges stay on the pixel grid, which a
  // real rotation would not.
  'dog': _PetParts(
    base: 'assets/svgs/dog_base.svg',
    eyes: 'assets/svgs/dog_eyes.svg',
    mouth: 'assets/svgs/dog_mouth.svg',
    mouthOpen: 'assets/svgs/dog_mouth_open.svg',
    tailFrames: [
      'assets/svgs/dog_tail_l.svg', // wag left
      'assets/svgs/dog_tail.svg', // centre (rest)
      'assets/svgs/dog_tail_r.svg', // wag right (unused)
    ],
    eyesPivot: Alignment(0.342, -0.067),
    eyeGeometry: kDogEyes,
    accessoryOffset: Offset(10, -25),
  ),
};

/// The art canvas every pet layer and accessory shares, in art units.
const Size _kCanvas = Size(222, 328);

/// Whether [type] is a pet that has been split into layers, and so can be
/// recoloured, blink, chew and wag. Pets without an entry fall back to a single
/// whole-sprite render that only breathes.
///
/// Exposed so the wardrobe can decide whether to offer the colour pickers
/// without keeping its own list of which pets are rigged.
bool isLayeredPet(String type) => _layeredPets.containsKey(type);

class CharacterSprite extends StatefulWidget {
  final double width;
  final double height;
  final BoxFit fit;
  final CharacterMotionProfile motionProfile;

  /// Renders this pet instead of the one currently out, in that pet's own
  /// saved design. For pickers and previews: the pet shown is not the pet
  /// being lived with, so it idles rather than mirroring the current mood —
  /// a pet in a picker has no reason to be asleep or mid-meal.
  final String? previewType;

  const CharacterSprite({
    super.key,
    required this.width,
    required this.height,
    this.fit = BoxFit.contain,
    this.motionProfile = CharacterMotionProfile.auto,
    this.previewType,
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
  static const double _exhaleFactor =
      1.5; // exhale dips lower than inhale rises

  /// Being-petted motion. The pet presses down into the hand by up to 8% of
  /// its height, rocks +/- 6 art units under it, and half-shuts its eyes.
  /// Sized to be obvious at a glance — the whole point is that this reads as
  /// a reaction from across the room, unlike the breath it replaces.
  static const double _kPetSquash = 0.92;
  static const double _kPetSwayUnits = 6.0;
  static const double _kPetSquintScale = 0.30;

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

  /// Loads the raw text of every recolourable coat layer once, so it can be
  /// tinted on demand. Every layered pet is loaded, not just the one on screen,
  /// because the pet can be switched at any time and a half-loaded sprite would
  /// show one frame of the un-recoloured art. The eyes layer is generated from
  /// scratch (see [buildEyesLayer]) and is not loaded here.
  Future<void> _loadRawLayers() async {
    final assets = <String>{
      for (final parts in _layeredPets.values) ...[
        parts.base,
        parts.mouth,
        parts.mouthOpen,
        ...parts.tailFrames,
      ],
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

  /// Whether the pet is asleep — night sleep or a reconnect doze, the same
  /// predicate the home screen gates its "z z z" trail on.
  ///
  /// Deliberately not [PetVisualState.sleeping], which eating outranks: a pet
  /// fed while it is asleep would then open its eyes under a sleep trail that
  /// is still drawn. One predicate for both is what keeps them agreeing.
  bool _safeIsSleeping(CharacterProvider provider) {
    try {
      return provider.isSleeping;
    } catch (_) {
      return false;
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
      case PetVisualState.petted:
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

  PetColorSpec _safeColorSpec(CharacterProvider provider, String type) {
    try {
      return provider.colorSpecFor(type);
    } catch (_) {
      return const PetColorSpec(
        bodyColor: '#959379',
        eyeMode: EyeMode.solid,
        eyeColor1: '#F4C430',
        eyeColor2: '#5AA0E0',
      );
    }
  }

  List<String> _safeEquippedAccessoryAssets(
      CharacterProvider provider, String type) {
    try {
      return provider.equippedAccessoryAssetsFor(type);
    } catch (_) {
      return const <String>[];
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CharacterProvider>();
    final preview = widget.previewType;
    final type = preview ?? _safeCurrentCharacterType(provider);
    final parts = _layeredPets[type];
    final spec = _safeColorSpec(provider, type);

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
              // A previewed pet idles: it is not the one whose mood the
              // screen is about.
              final state = preview != null
                  ? PetVisualState.breathing
                  : _safeVisualState(provider);

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
              final petted = state == PetVisualState.petted;
              double inhaleAmp = _breatheAmpFor(state);
              inhaleAmp *= motionGain * (fullMotion ? 1.0 : 0.5);
              if (_reduceMotion || eating) inhaleAmp = 0.0;
              final exhaleAmp = inhaleAmp * _exhaleFactor;

              // Squash & stretch anchored at the feet: stretch up on the inhale,
              // dip lower on the exhale, with a slight width pinch for volume.
              // Rest (1.0) is held whenever the breath quantises to zero.
              var scaleY = 1.0 + inhaleAmp * inhale - exhaleAmp * exhale;
              var scaleX =
                  1.0 - inhaleAmp * 0.35 * inhale + exhaleAmp * 0.35 * exhale;

              // Being petted: the pet presses up into the hand and rocks under
              // it. The breath alone could never carry this — it moves the
              // body by two percent, which is nothing you can see across a
              // room, and a petting reaction nobody notices is not a reaction.
              //
              // So the rub gets its own motion: a settle down into the hand
              // (squash, held for as long as the hand is there) and a rock
              // side to side on a faster grid than the breath, snapped to
              // three poses so it stays chunky rather than sliding.
              var swayUnits = 0.0;
              if (petted && !_reduceMotion) {
                // Stepped off the frame index rather than sampled from a sine.
                // A sine fast enough to read as a rub aliases badly against
                // the 8fps grid — it came out holding each pose for a quarter
                // of a second, which looks like the pet leaning, not being
                // rubbed. Four frames, half a second a cycle: left, centre,
                // right, centre.
                const rock = [-1.0, 0.0, 1.0, 0.0];
                final phase = rock[frame % rock.length];
                swayUnits = phase * _kPetSwayUnits * motionGain;

                // Bobs as it rocks: deepest as the hand passes over the middle
                // of the stroke, easing off at the ends.
                final press = phase == 0 ? 1.0 : 0.45;
                final squash = 1.0 - (1.0 - _kPetSquash) * press;
                scaleY *= squash;
                scaleX *= 1.0 + (1.0 - squash) * 0.6;
              }

              // One art unit in widget pixels, under BoxFit.contain against the
              // shared canvas -- what converts art-space offsets (the pet's
              // accessory anchor, the petting sway) into real translations at
              // whatever size the sprite is drawn.
              final boxW = constraints.maxWidth.isFinite
                  ? constraints.maxWidth
                  : (w ?? _kCanvas.width);
              final boxH = constraints.maxHeight.isFinite
                  ? constraints.maxHeight
                  : (h ?? _kCanvas.height);
              final unit = math.min(
                boxW / _kCanvas.width,
                boxH / _kCanvas.height,
              );

              /// Plants the body on its feet and applies whatever the body is
              /// doing this frame — the breath, and the rock under a hand.
              Widget posed(Widget child) => Transform.translate(
                    offset: Offset(swayUnits * unit, 0),
                    child: Transform(
                      alignment: Alignment.bottomCenter,
                      transform: Matrix4.diagonal3Values(scaleX, scaleY, 1.0),
                      child: child,
                    ),
                  );

              // Whole-sprite render (dog/bird, or any unsplit pet).
              if (parts == null) {
                return posed(
                  _svgLayer(
                    preview != null
                        ? 'assets/svgs/$preview.svg'
                        : _safeCurrentCharacterAsset(provider),
                    w,
                    h,
                  ),
                );
              }

              // Layered render (cat): stepped blink + stepped chew.
              // Blink is a 3-frame sequence (open -> half -> shut); the eye
              // pivot is at the bottom, so the lid closes downward.
              //
              // A sleeping pet holds the shut frame instead of sampling the
              // blink loop. Shut eyes are a state, not motion, so this is one
              // of the few things reduce-motion does not switch off — a
              // wide-eyed pet with a "Zzz" beside it would just read as a bug.
              final sleeping = preview == null && _safeIsSleeping(provider);
              final blinkStep =
                  sleeping ? 1.0 : _quantize(_blink.value, 2); // 0, 0.5, 1.0
              var eyeScaleY =
                  (_reduceMotion && !sleeping) ? 1.0 : (1.0 - 0.88 * blinkStep);

              // A pet being petted screws its eyes half shut. Like the shut
              // eyes of a sleeping pet this is a state rather than motion, so
              // reduce-motion keeps it: the squint is most of what makes the
              // reaction legible, and dropping it would leave that setting
              // with no petting reaction at all.
              if (petted && !sleeping) {
                eyeScaleY = math.min(eyeScaleY, _kPetSquintScale);
              }

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
                final freq =
                    petted ? 5.0 : (state == PetVisualState.happy ? 3.5 : 2.5);
                final wag = math.sin(tStep * 2 * math.pi * freq);
                tailIdx = wag < -0.4 ? 0 : 1; // dip left, else rest
              }

              // Equipped accessories overlay on top of the pet (hat/neck/face),
              // pre-positioned on the pet canvas so they ride the breath too.
              final accessoryAssets =
                  _safeEquippedAccessoryAssets(provider, type);

              final accessoryShift = parts.accessoryOffset * unit;

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
                      buildEyesLayer(spec, parts.eyeGeometry),
                      width: w,
                      height: h,
                      fit: widget.fit,
                    ),
                  ),
                  for (final asset in accessoryAssets)
                    Transform.translate(
                      offset: accessoryShift,
                      child: _svgLayer(asset, w, h),
                    ),
                ],
              );

              return posed(stack);
            },
          );
        },
      ),
    );
  }
}
