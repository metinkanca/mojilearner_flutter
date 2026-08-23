import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../constants/accessories.dart';
import '../providers/character_provider.dart';
import '../utils/pet_recolor.dart';

enum CharacterMotionProfile { auto, full, reduced }

/// Describes a pet that has been split into independently animatable SVG
/// layers (base body + eyes, and a muzzle and tail where the pet has them),
/// all sharing the same viewBox so they overlay pixel-perfectly. Pets without
/// an entry fall back to a single whole-sprite render that still breathes.
class _PetParts {
  final String base;
  final String eyes;

  /// Closed muzzle, drawn over the coat. Null for a pet whose face has no
  /// separate mouth to open — the bird's beak is part of its head.
  final String? mouth;

  /// Tail poses for a stepped wag: [left, centre, right]. Pets with a
  /// [tailPivot] wag by swinging the centre pose about that hinge instead, and
  /// only use the centre entry. Empty for a pet with no tail.
  final List<String> tailFrames;

  /// Hinge the tail swings about, in canvas art units. Null for a pet whose
  /// wag is baked into [tailFrames] rather than rotated.
  final Offset? tailPivot;

  /// Open-mouth pose, swapped with [mouth] frame-by-frame for the chew. Null
  /// wherever [mouth] is.
  final String? mouthOpen;

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

  /// Per-slot overrides of [accessoryOffset], for a pet whose head, face and
  /// chest are not simply the cat's shifted by one vector. A cat and a dog are
  /// the same animal drawn twice — head above chest, eyes above muzzle — so one
  /// offset lands all three slots. A chick in profile is not: its crown sits
  /// far below the cat's while its chest barely moves, so hat and neck have to
  /// travel different distances.
  final Map<String, Offset> accessoryOffsets;

  /// Accessory id -> the art this pet wears instead of the shared piece.
  ///
  /// An override is already drawn where this pet needs it, so it is placed
  /// verbatim — no [accessoryOffset] is applied on top.
  final Map<String, String> accessoryOverrides;

  const _PetParts({
    required this.base,
    required this.eyes,
    this.mouth,
    this.mouthOpen,
    this.tailFrames = const [],
    this.tailPivot,
    required this.eyesPivot,
    required this.eyeGeometry,
    this.accessoryOffset = Offset.zero,
    this.accessoryOffsets = const {},
    this.accessoryOverrides = const {},
  });

  /// Where [slot]'s accessories sit on this pet.
  Offset offsetForSlot(String slot) =>
      accessoryOffsets[slot] ?? accessoryOffset;
}

// Alignments derived from the assembled art viewBox "-20 -90 222 328"
// (widened 20px left for the tail flick + 90px top for hat headroom -- the
// witch hat alone stands 133px tall, against a 113px head):
//   eyes bottom edge ~ (118.5, 89) -> Alignment(0.248, 0.091)
//       (pivot at the bottom so the lid closes downward, top -> bottom)
//   chew swaps cat_mouth <-> cat_mouth_open (no scaling).
//   tail flicks left by swinging the rest pose 10 degrees about its hinge at
//       (38, 224), the bottom of the curl. The flick was baked as a
//       whole-unit shear for a while, to keep every edge on the pixel grid --
//       but a sheared curl steps sideways row by row, which is a staircase,
//       and this art has no diagonals anywhere else. Rotating tilts the whole
//       curl instead, which is what it did originally. The hairline holes
//       that cost it that job the first time (outline pieces no longer
//       meeting, coat showing through) are closed by [sealOutlines].
//       cat_tail_l / cat_tail_r are unused while the cat rotates.
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
    tailPivot: Offset(38, 224),
    eyesPivot: Alignment(0.248, 0.091),
    eyeGeometry: kCatEyes,
  ),
  // The dog art is 208x248 against the cat's 202x238, placed feet-on-the-same
  // ground line, which leaves its head ~30 units higher than the cat's -- hence
  // the accessory offset. Its tail is a tall straight flap rather than a curl,
  // so its wag stays a pair of baked poses -- a one-cell bend at the hinge,
  // which reads as a flap moving and keeps every edge on the pixel grid. It is
  // the cat's curl that needed rotating: a curl bent one cell at a time is a
  // staircase.
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
  // The chick is the odd one out: drawn in profile, no tail, and its beak is
  // part of the head silhouette rather than a muzzle laid over it. So its rig
  // is the coat plus one eye — it breathes and blinks, and has nothing to wag
  // or chew with. Its head is a long way below the cat's while its chest has
  // barely moved, which is why its accessories are placed per slot rather than
  // by one offset, and the face slot is its own art (see
  // art_src/gen_bird_acc.py — a second lens has nowhere to go on a head shown
  // side-on).
  'bird': _PetParts(
    base: 'assets/svgs/bird_base.svg',
    eyes: 'assets/svgs/bird_eyes.svg',
    eyesPivot: Alignment(0.306, 0.201),
    eyeGeometry: kBirdEyes,
    accessoryOffsets: {
      // Every hat has its own bird cut below, so this only catches a hat added
      // before one is generated for it: seated right, but cat-sized.
      AccessorySlots.hat: Offset(14, 45),
      AccessorySlots.neck: Offset(22, 30),
    },
    accessoryOverrides: {
      // Hats, re-pixelised smaller (art_src/gen_bird_hats.py). The cat's head
      // is wider than the whole chick, so a hat merely moved onto it swallows
      // it — a top hat came out taller than the bird.
      'beanie': 'assets/svgs/acc_beanie_bird.svg',
      'cap': 'assets/svgs/acc_cap_bird.svg',
      'cowboyhat': 'assets/svgs/acc_cowboyhat_bird.svg',
      'crown': 'assets/svgs/acc_crown_bird.svg',
      'devilhorns': 'assets/svgs/acc_devilhorns_bird.svg',
      'flowercrown': 'assets/svgs/acc_flowercrown_bird.svg',
      'headphones': 'assets/svgs/acc_headphones_bird.svg',
      'mortarboard': 'assets/svgs/acc_mortarboard_bird.svg',
      'partyhat': 'assets/svgs/acc_partyhat_bird.svg',
      'tophat': 'assets/svgs/acc_tophat_bird.svg',
      'wizardhat': 'assets/svgs/acc_wizardhat_bird.svg',
      // Face, re-cut side-on (art_src/gen_bird_acc.py).
      'glasses': 'assets/svgs/acc_glasses_bird.svg',
      'sunglasses': 'assets/svgs/acc_sunglasses_bird.svg',
      'mask': 'assets/svgs/acc_mask_bird.svg',
      'mustache': 'assets/svgs/acc_mustache_bird.svg',
    },
  ),
};

/// The art canvas every pet layer and accessory shares, in art units, and the
/// corner it starts at -- the shared viewBox is "-20 -90 222 328", so art
/// coordinates are not canvas offsets until that corner is taken off them.
const Size _kCanvas = Size(222, 328);
const Offset _kCanvasOrigin = Offset(-20, -90);

/// Whether [type] is a pet that has been split into layers, and so can be
/// recoloured, blink, chew and wag. Pets without an entry fall back to a single
/// whole-sprite render that only breathes.
///
/// Exposed so the wardrobe can decide whether to offer the colour pickers
/// without keeping its own list of which pets are rigged.
bool isLayeredPet(String type) => _layeredPets.containsKey(type);

/// The eye cells [type] is drawn with, for UI that has to know how many there
/// are: a pet in profile shows one eye, so odd-eyed has nothing to act on.
///
/// Exposed for the same reason as [isLayeredPet] — the wardrobe should not
/// keep its own copy of which pet is drawn which way.
PetEyeGeometry eyeGeometryFor(String type) =>
    _layeredPets[type]?.eyeGeometry ?? kCatEyes;

/// The art [type] wears for [def]: its own cut of the piece where it has one,
/// otherwise the shared front-on art.
///
/// Exposed so a test can check that every pet/accessory pair resolves to an
/// asset that actually ships — a mistyped override would otherwise show up as
/// a pet wearing nothing, and only on that one pet with that one item.
String accessoryAssetFor(String type, AccessoryDef def) =>
    _layeredPets[type]?.accessoryOverrides[def.id] ?? def.asset;

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
  final Map<String, String> _sealCache = {};
  final Set<String> _rawPending = {};
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

  /// How far a rotating tail swings out on the flick: 10 degrees, the angle
  /// the art was originally drawn flicked at.
  static const double _kTailFlickRadians = 10 * math.pi / 180;

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
        if (parts.mouth != null) parts.mouth!,
        if (parts.mouthOpen != null) parts.mouthOpen!,
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

  /// Loads one asset's raw text on demand, for the layers that are not known
  /// up front: the equipped accessories, and whole-sprite pets. Both are drawn
  /// from the raw string so their outlines can be sealed like the coat's.
  void _loadRawAsset(String asset) {
    if (_rawSvg.containsKey(asset) || !_rawPending.add(asset)) return;
    rootBundle.loadString(asset).then((raw) {
      if (!mounted) return;
      setState(() => _rawSvg[asset] = raw);
    }).catchError((_) {
      // Missing/unreadable asset: it keeps its plain asset render.
    });
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
    return _tintCache[asset] ??=
        sealOutlines(recolorBodyLayer(raw, spec.bodyColor));
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

  /// Renders an asset that is not recoloured (an accessory, or a whole-sprite
  /// pet), with its outline sealed. Falls back to the plain asset render until
  /// the raw text has loaded — one frame of a faint edge rather than no pet.
  Widget _svgLayer(String asset, double? w, double? h) {
    final raw = _rawSvg[asset];
    if (raw == null) {
      _loadRawAsset(asset);
      return SvgPicture.asset(asset, width: w, height: h, fit: widget.fit);
    }
    return SvgPicture.string(
      _sealCache[asset] ??= sealOutlines(raw),
      width: w,
      height: h,
      fit: widget.fit,
    );
  }

  /// Renders a recoloured coat layer (base / tail / mouth). Falls back to the
  /// plain asset until the raw text has loaded.
  Widget _coatLayer(String asset, double? w, double? h, PetColorSpec spec) {
    final tinted = _tintedBody(asset, spec);
    if (tinted == null) return _svgLayer(asset, w, h);
    return SvgPicture.string(tinted, width: w, height: h, fit: widget.fit);
  }

  /// Swings the tail layer about its hinge. [pivot] is in canvas art units.
  /// BoxFit.contain centres the art in the layer's box, so the canvas centre
  /// is the box centre — which is where [Transform.rotate] measures `origin`
  /// from, leaving the hinge as an art-space offset from it.
  Widget _tail(Widget layer, double angle, Offset? pivot, double unit) {
    if (angle == 0.0 || pivot == null) return layer;
    final origin = (pivot - _kCanvas.center(_kCanvasOrigin)) * unit;
    return Transform.rotate(angle: angle, origin: origin, child: layer);
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

  List<AccessoryDef> _safeEquippedAccessories(
      CharacterProvider provider, String type) {
    try {
      return provider.equippedAccessoriesFor(type);
    } catch (_) {
      return const <AccessoryDef>[];
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

              // Whole-sprite render, for any pet not split into layers.
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

              // Layered render: stepped blink + stepped chew.
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
              // open while food is hovering (waiting phase). A pet with no
              // separate mouth layer (the bird's beak is part of its head)
              // simply has nothing to swap.
              String? mouthAsset = parts.mouth;
              if (mouthAsset != null && !_reduceMotion && eating) {
                if (_safeEatingPhase(provider) == PetEatingPhase.consuming) {
                  mouthAsset = frame.isEven ? parts.mouthOpen : parts.mouth;
                } else {
                  mouthAsset = parts.mouthOpen;
                }
              }

              // Tail wag: stepped on the fps grid, so the tail holds a pose
              // rather than sweeping through one. Wags in every state except a
              // hard stop (reduce-motion), so it still flicks while the pet is
              // "dozing" (AI offline). Quicker when happy, slower/idle
              // otherwise. Flicks to the LEFT (outward, away from the body) and
              // back to rest, rather than swinging both ways.
              //
              // A pet with a [tailPivot] holds the rest pose and swings it
              // about the hinge; the others swap baked poses (0 = left, 1 =
              // rest).
              var flicked = false;
              if (!_reduceMotion) {
                final freq =
                    petted ? 5.0 : (state == PetVisualState.happy ? 3.5 : 2.5);
                final wag = math.sin(tStep * 2 * math.pi * freq);
                flicked = wag < -0.4;
              }
              final rotates = parts.tailPivot != null;
              final tailIdx = (flicked && !rotates) ? 0 : 1;
              // Negative is anticlockwise on screen, which swings the top of
              // the tail out to the left.
              final tailAngle =
                  (flicked && rotates) ? -_kTailFlickRadians : 0.0;

              // Equipped accessories overlay on top of the pet (hat/neck/face),
              // pre-positioned on the pet canvas so they ride the breath too.
              // A pet that wears its own cut of a piece takes it verbatim; the
              // shared art is shifted to wherever that slot sits on this pet.
              final accessories = _safeEquippedAccessories(provider, type);

              final stack = Stack(
                fit: StackFit.passthrough,
                children: [
                  _coatLayer(parts.base, w, h, spec),
                  if (parts.tailFrames.isNotEmpty)
                    _tail(
                      _coatLayer(parts.tailFrames[tailIdx], w, h, spec),
                      tailAngle,
                      parts.tailPivot,
                      unit,
                    ),
                  if (mouthAsset != null) _coatLayer(mouthAsset, w, h, spec),
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
                  for (final def in accessories)
                    Transform.translate(
                      offset: parts.accessoryOverrides.containsKey(def.id)
                          ? Offset.zero
                          : parts.offsetForSlot(def.slot) * unit,
                      child: _svgLayer(accessoryAssetFor(type, def), w, h),
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
