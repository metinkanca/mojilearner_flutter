import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/accessories.dart';
import '../constants/accessory_extents.dart';
import '../constants/pets.dart';
import '../models/models.dart' show kDefaultEyeColor1, kDefaultEyeColor2;
import '../providers/character_provider.dart';
import '../utils/pet_recolor.dart';
import '../utils/pixel_clock.dart';
import 'pet_art_cache.dart';

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
  /// An override is normally already drawn where this pet needs it, so it is
  /// placed verbatim — no [accessoryOffset] is applied on top. The exception
  /// is art borrowed from another pet, which [borrowedOffsets] moves.
  final Map<String, String> accessoryOverrides;

  /// Slot -> where [accessoryOverrides] art sits, for a pet whose overrides
  /// are another pet's cuts rather than its own drawings.
  ///
  /// The parrot is the case. It has the chick's problem exactly — a small head
  /// shown side-on, which a cat-sized hat swallows — and the chick already has
  /// seventeen drawings that solve it, on a head within 15% of the parrot's
  /// width. Borrowing them costs three offsets; drawing them again costs
  /// seventeen mock-ups to say the same thing.
  ///
  /// Per slot rather than one vector because a borrowed head and a borrowed
  /// face do not travel together: the parrot's crown sits 70 units above the
  /// chick's, its eye 77.
  ///
  /// Empty for a pet wearing art drawn for it, which is what leaves the chick
  /// placing its own cuts verbatim.
  final Map<String, Offset> borrowedOffsets;

  /// The coat with the mouth open, for a pet whose mouth is part of its
  /// silhouette rather than a layer over it.
  ///
  /// The chick's beak is cut out of its head, so there is no mouth layer to
  /// swap and no overlay that could do the job either — opening a beak takes
  /// pixels away from where they were, and a layer painted on top can only
  /// add. So the whole coat gets a second pose
  /// (art_src/gen_bird_chew.py). Null for a pet that chews with [mouthOpen].
  final String? baseOpen;

  /// Accessory id -> where this pet wears that one piece, overriding both
  /// [accessoryOffset] and [accessoryOffsets].
  ///
  /// One offset per pet only works while the pieces are all the same shape of
  /// thing. They are not: a top hat is seated by its brim, a wizard hat by a
  /// brim two cells lower, a flower crown by a band that has to clear the
  /// ears. Moving them as a group lands whichever one the offset was measured
  /// from and leaves the rest floating or sunk.
  final Map<String, _AccessoryPlacement> accessoryPlacements;

  /// The art canvas this pet's layers are drawn on, and the corner it starts
  /// at.
  ///
  /// Almost every pet shares [_kCanvas] -- one frame for the whole roster is
  /// what lets a hat drawn once be worn by thirty animals. The reworked dog is
  /// the exception: its ears and tail are wide enough that no integer cell
  /// size fits it into 222 units without shrinking it well below the pet it
  /// replaces. So it declares a wider frame, keeping the shared canvas's
  /// height, centre line and ground line -- which is what lets the accessory
  /// art, still drawn on the narrow canvas, land in the same place on it.
  final Size canvas;
  final Offset canvasOrigin;

  /// The fills this pet's beak is drawn in, which a chosen beak colour
  /// replaces. Empty for a pet without a beak, which is also what keeps the
  /// wardrobe's beak panel away from it.
  ///
  /// [kBeakFill] is the reworked bird's: a beak that follows the coat until
  /// given a colour. The parrot and penguin name their own drawn tones, and
  /// keep them until a colour is picked — the penguin's tone is shared with
  /// its feet, which is why those change with the beak.
  final List<String> beakFills;

  /// The beak's shaded tones: they take a chosen beak colour as a darker
  /// version of it, where [beakFills] take it as it is. See
  /// [recolorBodyLayer].
  final List<String> beakShadeFills;

  const _PetParts({
    required this.base,
    required this.eyes,
    this.mouth,
    this.mouthOpen,
    // Unused while the reworked pets are the placeholder: the old cat's rotated
    // tail and the old chick's coat-swap chew were their only users.
    // ignore: unused_element_parameter
    this.baseOpen,
    this.tailFrames = const [],
    // ignore: unused_element_parameter
    this.tailPivot,
    required this.eyesPivot,
    required this.eyeGeometry,
    this.accessoryOffset = Offset.zero,
    this.accessoryOffsets = const {},
    this.accessoryOverrides = const {},
    this.borrowedOffsets = const {},
    this.accessoryPlacements = const {},
    this.canvas = _kCanvas,
    this.canvasOrigin = _kCanvasOrigin,
    this.beakFills = const [],
    this.beakShadeFills = const [],
  });

  /// Where [slot]'s accessories sit on this pet.
  Offset offsetForSlot(String slot) =>
      accessoryOffsets[slot] ?? accessoryOffset;

  /// Where [def] sits on this pet: its own placement where one was measured,
  /// otherwise wherever the slot puts it.
  _AccessoryPlacement placementFor(AccessoryDef def) =>
      accessoryPlacements[def.id] ?? _AccessoryPlacement.at(offsetForSlot(def.slot));
}

/// Where one accessory sits on one pet, in canvas art units.
///
/// These numbers are not eyeballed. Each comes from a reference drawing — the
/// pet art and the accessory art dropped into one Inkscape document with the
/// accessory dragged onto the pet by hand — read back by
/// `art_src/acc_offset.py`, which matches every path in the drawing to the
/// asset it came from and solves for the translation between them. Re-run it
/// against a new `<pet>_with_<accessory>.svg` to get the pair of numbers here.
class _AccessoryPlacement {
  const _AccessoryPlacement(this._dx, this._dy,
      // Unused while the reworked dog is the placeholder: the old dog's bow tie
      // was its only user, and comes back with it.
      // ignore: unused_element_parameter
      {this.mirrored = false, this.underMuzzle = false});

  /// A placement that is only ever a move — the pet-wide and per-slot offsets,
  /// which have no reason to mirror anything or to go under a layer.
  _AccessoryPlacement.at(Offset offset)
      : _dx = offset.dx,
        _dy = offset.dy,
        mirrored = false,
        underMuzzle = false;

  final double _dx;
  final double _dy;

  /// Movement from where the art is drawn to where this pet wears it.
  Offset get offset => Offset(_dx, _dy);

  /// Flipped left-to-right before being moved, about the canvas centre — which
  /// is what [Transform.scale] with a negative `scaleX` does to a layer that
  /// fills the canvas.
  ///
  /// The dog wears the cap the other way round from the cat. There is no
  /// second asset for that: a mirrored copy of pixel art is the same pixel art.
  final bool mirrored;

  /// Drawn under the muzzle layer instead of over everything.
  ///
  /// An accessory is normally the last thing painted, which is right for a hat
  /// and wrong for anything the pet's own face should overlap. The dog's jaw
  /// hangs over the top of its bow tie — the reference drawing has the bow's
  /// wings sitting under the muzzle paths, which is not something a placement
  /// on top of the stack can express at any offset.
  final bool underMuzzle;
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
  // PLACEHOLDER, like the dog below: the reworked cat, bird and rabbit
  // (art_src/gen_rework.py off art_src/cat.svg, bird.svg and rabbit.svg), on
  // the reworked dog's canvas. The old `cat_*`, `bird_*` and `rabbit_*` art is
  // still shipped and nothing points at it while these are here; the previous
  // entries are in git.
  //
  // The tail wags as baked poses: the whole tail turned about its root on the
  // pixel grid (lib_rework.rotate_tail), so every cell moves and the art stays
  // crisp, rather than rotated live like the old cat's. All the reworked
  // tails are posed this way. The chew is the dog's: a pocket opened under
  // the mouth line.
  //
  // Accessories are derived, not drawn: the old cat's placement plus the
  // distance from its head, eyes and chin to the rework's, as the rabbit and
  // hamster got. The rework heads are bigger than the cat the pieces were
  // drawn for, so expect them to sit roughly right and read a little small.
  'cat': _PetParts(
    base: 'assets/svgs/cat2_base.svg',
    eyes: 'assets/svgs/cat2_eyes.svg',
    mouth: 'assets/svgs/cat2_mouth.svg',
    mouthOpen: 'assets/svgs/cat2_mouth_open.svg',
    tailFrames: [
      'assets/svgs/cat2_tail_l.svg', // wag left
      'assets/svgs/cat2_tail.svg', // centre (rest)
      'assets/svgs/cat2_tail_r.svg', // wag right (unused)
    ],
    canvas: Size(255, 376.7568),
    canvasOrigin: Offset(-36.5, -114.3784),
    eyesPivot: Alignment(0.231, 0.281),
    eyeGeometry: kCat2Eyes,
    accessoryOffsets: {
      AccessorySlots.hat: Offset(11, 24),
      AccessorySlots.neck: Offset(11, 35),
      AccessorySlots.face: Offset(11, 37),
    },
    // Drawn for this cat, on its own 3-unit grid, and worn exactly as drawn
    // (art_src/gen_cat_hats.py); every other pet keeps the shared piece.
    accessoryOverrides: {
      'bandana': 'assets/svgs/acc_bandana_cat.svg',
      'batchoker': 'assets/svgs/acc_batchoker_cat.svg',
      'beanie': 'assets/svgs/acc_beanie_cat.svg',
      'bowtie': 'assets/svgs/acc_bowtie_cat.svg',
      'cap': 'assets/svgs/acc_cap_cat.svg',
      'collar': 'assets/svgs/acc_collar_cat.svg',
      'cowboyhat': 'assets/svgs/acc_cowboyhat_cat.svg',
      'crown': 'assets/svgs/acc_crown_cat.svg',
      'devilband': 'assets/svgs/acc_devilband_cat.svg',
      'flightscarf': 'assets/svgs/acc_flightscarf_cat.svg',
      'flowercrown': 'assets/svgs/acc_flowercrown_cat.svg',
      'ghostbandana': 'assets/svgs/acc_ghostbandana_cat.svg',
      'glasses': 'assets/svgs/acc_glasses_cat.svg',
      'goggles': 'assets/svgs/acc_goggles_cat.svg',
      'mask': 'assets/svgs/acc_mask_cat.svg',
      'medal': 'assets/svgs/acc_medal_cat.svg',
      'mortarboard': 'assets/svgs/acc_mortarboard_cat.svg',
      'mustache': 'assets/svgs/acc_mustache_cat.svg',
      'necklace': 'assets/svgs/acc_necklace_cat.svg',
      'partyhat': 'assets/svgs/acc_partyhat_cat.svg',
      'pumpkinwitch': 'assets/svgs/acc_pumpkinwitch_cat.svg',
      'scarf': 'assets/svgs/acc_scarf_cat.svg',
      'sunglasses': 'assets/svgs/acc_sunglasses_cat.svg',
      'tophat': 'assets/svgs/acc_tophat_cat.svg',
      'wizardhat': 'assets/svgs/acc_wizardhat_cat.svg',
    },
  ),
  // The dog art is 208x248 against the cat's 202x238, placed feet-on-the-same
  // ground line, which leaves its head ~30 units higher than the cat's -- hence
  // the accessory offset.
  // PLACEHOLDER: this entry now draws the reworked art (art_src/gen_dog2.py
  // off art_src/dog_rework_test_2.svg) rather than the hand-separated dog
  // above. The old `dog_*.svg` files are still shipped and still generated by
  // gen_dog.py -- nothing points at them while this is here, so reverting is a
  // matter of putting the asset names and the three numbers below back.
  //
  // The accessory placements are the old dog's, shifted by the 16 units the
  // rework's face sits lower and the 2 it sits left. That is a translation of
  // measurements taken against different art, so it seats the pieces roughly
  // rather than exactly; each wants its own reference drawing (see
  // [_AccessoryPlacement]) once the rework is settled.
  'dog': _PetParts(
    base: 'assets/svgs/dog2_base.svg',
    eyes: 'assets/svgs/dog2_eyes.svg',
    mouth: 'assets/svgs/dog2_mouth.svg',
    mouthOpen: 'assets/svgs/dog2_mouth_open.svg',
    tailFrames: [
      'assets/svgs/dog2_tail_l.svg', // wag left
      'assets/svgs/dog2_tail.svg', // centre (rest)
      'assets/svgs/dog2_tail_r.svg', // wag right (unused)
    ],
    canvas: Size(255, 376.7568),
    canvasOrigin: Offset(-36.5, -114.3784),
    eyesPivot: Alignment(0.286, 0.154),
    eyeGeometry: kDog2Eyes,
    // The fallback, for pieces no reference drawing has been made for yet.
    accessoryOffset: Offset(8, 15),
    // Measured, one drawing per piece — see [_AccessoryPlacement].
    accessoryPlacements: {
      'tophat': _AccessoryPlacement(-6, 3),
      'cowboyhat': _AccessoryPlacement(6, 2),
      'partyhat': _AccessoryPlacement(7, 3),
      'wizardhat': _AccessoryPlacement(3, -4),
      'flowercrown': _AccessoryPlacement(0, -17),
      'cap': _AccessoryPlacement(36, 2, mirrored: true),
      'medal': _AccessoryPlacement(-1, 27),
      'mustache': _AccessoryPlacement(38, 28),
      // Witching Hour: read off the owner's cat-and-dog mock-ups rather than a
      // reference drawing, as the difference between where each piece sits on
      // the cat and on the dog. The hat is seated by its brim, the bandana by
      // its middle, because the mock-up draws the dog's a touch smaller.
      'pumpkinwitch': _AccessoryPlacement(16, 17),
      'ghostbandana': _AccessoryPlacement(17, 19),
      // No entry for the bow tie, and no override either. The dog's own cut
      // (`acc_bowtie_dog.svg`) is notched for the jaw of the art above, which
      // hangs nowhere near the rework's chest, so it would read as a bow with
      // a bite out of it. Until the rework gets a cut of its own the shared
      // bow on the neck offset is the honest placeholder.
    },
  ),
  // The reworked bird faces front with both eyes, and its beak is drawn in
  // its own orange over the coat -- so, unlike the chick it replaces, it chews
  // with a mouth layer (the lower half of the beak drops) rather than a second
  // coat, and wears the cat's pieces at derived offsets rather than the chick's
  // side-on cuts, which were drawn for a head in a different place.
  'bird': _PetParts(
    base: 'assets/svgs/bird2_base.svg',
    eyes: 'assets/svgs/bird2_eyes.svg',
    mouth: 'assets/svgs/bird2_mouth.svg',
    mouthOpen: 'assets/svgs/bird2_mouth_open.svg',
    canvas: Size(255, 376.7568),
    canvasOrigin: Offset(-36.5, -114.3784),
    eyesPivot: Alignment(0.271, 0.377),
    eyeGeometry: kBird2Eyes,
    beakFills: [kBeakFill],
    accessoryOffsets: {
      AccessorySlots.hat: Offset(16, 48),
      AccessorySlots.neck: Offset(16, 50),
      AccessorySlots.face: Offset(16, 55),
    },
    accessoryPlacements: {
      'tophat': _AccessoryPlacement(3, 25),
      'cowboyhat': _AccessoryPlacement(10, 28),
      'cap': _AccessoryPlacement(58, 42, mirrored: true),
      'bowtie': _AccessoryPlacement(28, 52),
      'collar': _AccessoryPlacement(15, 60),
      'medal': _AccessoryPlacement(13, 56),
    },
  ),
  // ------------------------------------------------------------------
  // The three cell-map pets (art_src/<pet>_cells.txt, see lib_cells.py).
  //
  // All three rig the same way and more simply than the trio above: a coat
  // and a pair of eyes, and nothing else. None has a muzzle drawn as its own
  // layer, so none can chew yet — an eating pose is still to be drawn for
  // them — and none has a tail that is separate from its body, so there is
  // nothing to wag. What they do have is everything the body-level motion
  // gives for free: they breathe, they blink, and they settle and rock under
  // a hand.
  //
  // Their accessory numbers are derived rather than drawn: each is the cat's
  // own placement plus the distance from the cat's head, face or chest to
  // this pet's, measured off the rendered art. That works here and did not
  // for the chick because these heads are the cat's size — the rabbit's is
  // 120 art units across and the hamster's 132, against the cat's 130 — so a
  // hat that fits the cat fits them, which is the whole thing a redrawn cut
  // was for.
  // ------------------------------------------------------------------

  // The reworked rabbit: a puff tail lifted out like the cat's, wagging one
  // cell rather than two, and the same pocket chew. See the cat's entry.
  'rabbit': _PetParts(
    base: 'assets/svgs/rabbit2_base.svg',
    eyes: 'assets/svgs/rabbit2_eyes.svg',
    mouth: 'assets/svgs/rabbit2_mouth.svg',
    mouthOpen: 'assets/svgs/rabbit2_mouth_open.svg',
    tailFrames: [
      'assets/svgs/rabbit2_tail_l.svg', // wag left
      'assets/svgs/rabbit2_tail.svg', // centre (rest)
      'assets/svgs/rabbit2_tail_r.svg', // wag right (unused)
    ],
    canvas: Size(255, 376.7568),
    canvasOrigin: Offset(-36.5, -114.3784),
    eyesPivot: Alignment(0.212, 0.393),
    eyeGeometry: kRabbit2Eyes,
    accessoryOffsets: {
      AccessorySlots.hat: Offset(8, 66),
      AccessorySlots.neck: Offset(8, 56),
      AccessorySlots.face: Offset(8, 55),
    },
    accessoryPlacements: {
      'tophat': _AccessoryPlacement(-5, 43),
      'cowboyhat': _AccessoryPlacement(2, 46),
      'cap': _AccessoryPlacement(50, 60, mirrored: true),
      'bowtie': _AccessoryPlacement(20, 58),
      'collar': _AccessoryPlacement(7, 66),
      'medal': _AccessoryPlacement(5, 62),
    },
  ),
  // Head x 33..165 (centre 99), skull top y=70 with the ears just above it.
  // The neck offset is the one that is not the head's: a hamster has no neck,
  // so its collar hangs where the cheeks stop rather than a fixed distance
  // under the chin, which put it across the mouth.
  'hamster': _PetParts(
    base: 'assets/svgs/hamster_base.svg',
    eyes: 'assets/svgs/hamster_eyes.svg',
    eyesPivot: Alignment(0.126, 0.268),
    eyeGeometry: kHamsterEyes,
    accessoryOffsets: {
      AccessorySlots.hat: Offset(-11, 40),
      AccessorySlots.neck: Offset(-11, 26),
      AccessorySlots.face: Offset(-14, 37),
    },
    accessoryPlacements: {
      'tophat': _AccessoryPlacement(-24, 17),
      'cowboyhat': _AccessoryPlacement(-17, 20),
      'cap': _AccessoryPlacement(31, 34, mirrored: true),
      'bowtie': _AccessoryPlacement(1, 28),
      'collar': _AccessoryPlacement(-12, 36),
      'medal': _AccessoryPlacement(-14, 32),
    },
  ),
  // The one that does not get the cat's pieces: a head 66 units across, shown
  // side-on, perched a long way up its stand. That is the chick's situation
  // exactly, and the chick's seventeen cuts are drawn for a head within 15%
  // of this one's — so the parrot wears those, moved by [borrowedOffsets],
  // rather than seventeen drawings of its own.
  //
  // The six pieces the chick has no cut for (the pass's flight set, and the
  // withheld necklace and scarf) fall through to the cat art at cat size, via
  // the slot offsets below. They are as oversized here as they already are on
  // the chick; the fix for both is a drawing, not a number.
  'parrot': _PetParts(
    base: 'assets/svgs/parrot_base.svg',
    eyes: 'assets/svgs/parrot_eyes.svg',
    eyesPivot: Alignment(0.261, -0.280),
    eyeGeometry: kParrotEyes,
    // Its beak tone in art_src/gen_parrot.py ('T'). The shaded side ('W') is
    // left alone: the toes over the perch are drawn in it too.
    beakFills: ['#e9c289'],
    accessoryOffsets: {
      AccessorySlots.hat: Offset(5, -48),
      AccessorySlots.neck: Offset(-5, -81),
      AccessorySlots.face: Offset(2, -53),
    },
    // Chick head top y=56 against the parrot's -14; chick eye y=92 against
    // the parrot's 16. Hence a hat that travels 70 units and a lens that
    // travels 77.
    borrowedOffsets: {
      AccessorySlots.hat: Offset(-7, -70),
      AccessorySlots.neck: Offset(-7, -70),
      AccessorySlots.face: Offset(-5, -77),
    },
    accessoryOverrides: {
      'beanie': 'assets/svgs/acc_beanie_bird.svg',
      'cap': 'assets/svgs/acc_cap_bird.svg',
      'cowboyhat': 'assets/svgs/acc_cowboyhat_bird.svg',
      'crown': 'assets/svgs/acc_crown_bird.svg',
      'flowercrown': 'assets/svgs/acc_flowercrown_bird.svg',
      'headphones': 'assets/svgs/acc_headphones_bird.svg',
      'mortarboard': 'assets/svgs/acc_mortarboard_bird.svg',
      'partyhat': 'assets/svgs/acc_partyhat_bird.svg',
      'tophat': 'assets/svgs/acc_tophat_bird.svg',
      'wizardhat': 'assets/svgs/acc_wizardhat_bird.svg',
      'collar': 'assets/svgs/acc_collar_bird.svg',
      'medal': 'assets/svgs/acc_medal_bird.svg',
      'bowtie': 'assets/svgs/acc_bowtie_bird.svg',
      'glasses': 'assets/svgs/acc_glasses_bird.svg',
      'sunglasses': 'assets/svgs/acc_sunglasses_bird.svg',
      'mask': 'assets/svgs/acc_mask_bird.svg',
      'mustache': 'assets/svgs/acc_mustache_bird.svg',
    },
  ),

  // ------------------------------------------------------------------
  // The roster set, built by `art_src/gen_roster_pets.py` from the sheet
  // `art_src/pet-roster-restored.svg`. Everything below this line --
  // the eye pivot, the eye geometry and all three accessory offsets --
  // is measured off the art by that script and pasted in, never typed.
  //
  // Seating is arithmetic: each offset is where the cat wears the piece
  // plus the distance from the cat's anchor to this pet's. The anchors
  // are in the comment above each entry. That is the same derivation the
  // rabbit and hamster got by hand, and it reproduces their numbers.
  //
  // None of them has a mouth layer or a tail layer, so none chews or
  // wags; they breathe, blink and squint. An eating pose is a drawing
  // job, not a wiring one.
  // ------------------------------------------------------------------
  // Head centred x 139, skull top y 76; eyes y 112; muzzle ends y 160.
  'fox': _PetParts(
    base: 'assets/svgs/fox_base.svg',
    eyes: 'assets/svgs/fox_eyes.svg',
    eyesPivot: Alignment(0.514, 0.341),
    eyeGeometry: kFoxEyes,
    accessoryOffsets: {
      AccessorySlots.hat: Offset(30, 42),
      AccessorySlots.neck: Offset(30, 47),
      AccessorySlots.face: Offset(30, 43),
    },
  ),
  // PLACEHOLDER, like the cat at the top: the reworked raccoon
  // (art_src/gen_rework.py off art_src/raccoon.svg) on the reworked pets'
  // canvas. Unlike the roster entries around it, it has its own mouth and tail
  // layers, so it chews and wags. The old `raccoon_*` art is still shipped, and
  // the previous entry is in git. Accessory numbers are derived the cat's way.
  'raccoon': _PetParts(
    base: 'assets/svgs/raccoon2_base.svg',
    eyes: 'assets/svgs/raccoon2_eyes.svg',
    mouth: 'assets/svgs/raccoon2_mouth.svg',
    mouthOpen: 'assets/svgs/raccoon2_mouth_open.svg',
    tailFrames: [
      'assets/svgs/raccoon2_tail_l.svg', // wag left
      'assets/svgs/raccoon2_tail.svg', // centre (rest)
      'assets/svgs/raccoon2_tail_r.svg', // wag right (unused)
    ],
    canvas: Size(255, 376.7568),
    canvasOrigin: Offset(-36.5, -114.3784),
    eyesPivot: Alignment(0.298, 0.212),
    eyeGeometry: kRaccoon2Eyes,
    accessoryOffsets: {
      AccessorySlots.hat: Offset(20, 2),
      AccessorySlots.neck: Offset(20, 27),
      AccessorySlots.face: Offset(20, 25),
    },
    accessoryPlacements: {
      'tophat': _AccessoryPlacement(7, -21),
      'cowboyhat': _AccessoryPlacement(14, -18),
      'cap': _AccessoryPlacement(62, -4, mirrored: true),
      'bowtie': _AccessoryPlacement(32, 29),
      'collar': _AccessoryPlacement(19, 37),
      'medal': _AccessoryPlacement(17, 33),
    },
  ),
  // Head centred x 133, skull top y 74; eyes y 118; muzzle ends y 154.
  'red-panda': _PetParts(
    base: 'assets/svgs/red-panda_base.svg',
    eyes: 'assets/svgs/red-panda_eyes.svg',
    eyesPivot: Alignment(0.459, 0.390),
    eyeGeometry: kRedPandaEyes,
    accessoryOffsets: {
      AccessorySlots.hat: Offset(24, 40),
      AccessorySlots.neck: Offset(24, 41),
      AccessorySlots.face: Offset(24, 49),
    },
  ),
  // Head centred x 126, skull top y 66; eyes y 102; muzzle ends y 142.
  'otter': _PetParts(
    base: 'assets/svgs/otter_base.svg',
    eyes: 'assets/svgs/otter_eyes.svg',
    eyesPivot: Alignment(0.396, 0.280),
    eyeGeometry: kOtterEyes,
    accessoryOffsets: {
      AccessorySlots.hat: Offset(16, 32),
      AccessorySlots.neck: Offset(16, 29),
      AccessorySlots.face: Offset(16, 33),
    },
  ),
  // Head centred x 136, skull top y 102; eyes y 162; muzzle ends y 196.
  'hedgehog': _PetParts(
    base: 'assets/svgs/hedgehog_base.svg',
    eyes: 'assets/svgs/hedgehog_eyes.svg',
    eyesPivot: Alignment(0.486, 0.634),
    eyeGeometry: kHedgehogEyes,
    accessoryOffsets: {
      AccessorySlots.hat: Offset(26, 68),
      AccessorySlots.neck: Offset(26, 83),
      AccessorySlots.face: Offset(26, 93),
    },
  ),
  // Head centred x 123, skull top y 86; eyes y 120; muzzle ends y 156.
  'chinchilla': _PetParts(
    base: 'assets/svgs/chinchilla_base.svg',
    eyes: 'assets/svgs/chinchilla_eyes.svg',
    eyesPivot: Alignment(0.369, 0.378),
    eyeGeometry: kChinchillaEyes,
    accessoryOffsets: {
      AccessorySlots.hat: Offset(14, 52),
      AccessorySlots.neck: Offset(14, 43),
      AccessorySlots.face: Offset(14, 51),
    },
  ),
  // Head centred x 148, skull top y 94; eyes y 128; muzzle ends y 160.
  'squirrel': _PetParts(
    base: 'assets/svgs/squirrel_base.svg',
    eyes: 'assets/svgs/squirrel_eyes.svg',
    eyesPivot: Alignment(0.595, 0.427),
    eyeGeometry: kSquirrelEyes,
    accessoryOffsets: {
      AccessorySlots.hat: Offset(38, 60),
      AccessorySlots.neck: Offset(38, 47),
      AccessorySlots.face: Offset(38, 59),
    },
  ),
  // Head centred x 126, skull top y 110; eyes y 140; muzzle ends y 186.
  'mouse': _PetParts(
    base: 'assets/svgs/mouse_base.svg',
    eyes: 'assets/svgs/mouse_eyes.svg',
    eyesPivot: Alignment(0.396, 0.500),
    eyeGeometry: kMouseEyes,
    accessoryOffsets: {
      AccessorySlots.hat: Offset(16, 76),
      AccessorySlots.neck: Offset(16, 73),
      AccessorySlots.face: Offset(16, 71),
    },
  ),
  // Head centred x 119, skull top y 98; eyes y 132; muzzle ends y 162.
  'bat': _PetParts(
    base: 'assets/svgs/bat_base.svg',
    eyes: 'assets/svgs/bat_eyes.svg',
    eyesPivot: Alignment(0.333, 0.463),
    eyeGeometry: kBatEyes,
    accessoryOffsets: {
      AccessorySlots.hat: Offset(10, 64),
      AccessorySlots.neck: Offset(10, 49),
      AccessorySlots.face: Offset(10, 63),
    },
  ),
  // Head centred x 100, skull top y 104; eyes y 136; muzzle ends y 170.
  'fennec': _PetParts(
    base: 'assets/svgs/fennec_base.svg',
    eyes: 'assets/svgs/fennec_eyes.svg',
    eyesPivot: Alignment(0.162, 0.476),
    eyeGeometry: kFennecEyes,
    accessoryOffsets: {
      AccessorySlots.hat: Offset(-10, 70),
      AccessorySlots.neck: Offset(-10, 57),
      AccessorySlots.face: Offset(-10, 67),
    },
  ),
  // Head centred x 152, skull top y 88; eyes y 130; muzzle ends y 162.
  'skunk': _PetParts(
    base: 'assets/svgs/skunk_base.svg',
    eyes: 'assets/svgs/skunk_eyes.svg',
    eyesPivot: Alignment(0.631, 0.439),
    eyeGeometry: kSkunkEyes,
    accessoryOffsets: {
      AccessorySlots.hat: Offset(42, 54),
      AccessorySlots.neck: Offset(42, 49),
      AccessorySlots.face: Offset(42, 61),
    },
  ),
  // Head centred x 142, skull top y 80; eyes y 112; muzzle ends y 156.
  'beaver': _PetParts(
    base: 'assets/svgs/beaver_base.svg',
    eyes: 'assets/svgs/beaver_eyes.svg',
    eyesPivot: Alignment(0.541, 0.329),
    eyeGeometry: kBeaverEyes,
    accessoryOffsets: {
      AccessorySlots.hat: Offset(32, 46),
      AccessorySlots.neck: Offset(32, 43),
      AccessorySlots.face: Offset(32, 43),
    },
  ),
  // Head centred x 102, skull top y 74; eyes y 120; muzzle ends y 196.
  'koala': _PetParts(
    base: 'assets/svgs/koala_base.svg',
    eyes: 'assets/svgs/koala_eyes.svg',
    eyesPivot: Alignment(0.180, 0.378),
    eyeGeometry: kKoalaEyes,
    accessoryOffsets: {
      AccessorySlots.hat: Offset(-8, 40),
      AccessorySlots.neck: Offset(-8, 83),
      AccessorySlots.face: Offset(-8, 51),
    },
  ),
  // Head centred x 127, skull top y 86; eyes y 134; muzzle ends y 174.
  'wombat': _PetParts(
    base: 'assets/svgs/wombat_base.svg',
    eyes: 'assets/svgs/wombat_eyes.svg',
    eyesPivot: Alignment(0.405, 0.463),
    eyeGeometry: kWombatEyes,
    accessoryOffsets: {
      AccessorySlots.hat: Offset(18, 52),
      AccessorySlots.neck: Offset(18, 61),
      AccessorySlots.face: Offset(18, 65),
    },
  ),
  // Head centred x 106, skull top y 66; eyes y 110; muzzle ends y 166.
  'panda': _PetParts(
    base: 'assets/svgs/panda_base.svg',
    eyes: 'assets/svgs/panda_eyes.svg',
    eyesPivot: Alignment(0.216, 0.305),
    eyeGeometry: kPandaEyes,
    accessoryOffsets: {
      AccessorySlots.hat: Offset(-4, 32),
      AccessorySlots.neck: Offset(-4, 53),
      AccessorySlots.face: Offset(-4, 41),
    },
  ),
  // Head centred x 119, skull top y 64; eyes y 108; muzzle ends y 138.
  'sloth': _PetParts(
    base: 'assets/svgs/sloth_base.svg',
    eyes: 'assets/svgs/sloth_eyes.svg',
    eyesPivot: Alignment(0.333, 0.305),
    eyeGeometry: kSlothEyes,
    accessoryOffsets: {
      AccessorySlots.hat: Offset(10, 30),
      AccessorySlots.neck: Offset(10, 25),
      AccessorySlots.face: Offset(10, 39),
    },
  ),
  // Head centred x 103, skull top y 76; eyes y 106; muzzle ends y 122.
  'capybara': _PetParts(
    base: 'assets/svgs/capybara_base.svg',
    eyes: 'assets/svgs/capybara_eyes.svg',
    eyesPivot: Alignment(0.189, 0.293),
    eyeGeometry: kCapybaraEyes,
    accessoryOffsets: {
      AccessorySlots.hat: Offset(-6, 42),
      AccessorySlots.neck: Offset(-6, 9),
      AccessorySlots.face: Offset(-6, 37),
    },
  ),
  // Head centred x 128, skull top y 92; eyes y 130; muzzle ends y 160.
  'piglet': _PetParts(
    base: 'assets/svgs/piglet_base.svg',
    eyes: 'assets/svgs/piglet_eyes.svg',
    eyesPivot: Alignment(0.414, 0.427),
    eyeGeometry: kPigletEyes,
    accessoryOffsets: {
      AccessorySlots.hat: Offset(18, 58),
      AccessorySlots.neck: Offset(18, 47),
      AccessorySlots.face: Offset(18, 61),
    },
  ),
  // Head centred x 114, skull top y 112; eyes y 116; muzzle ends y 158.
  'frog': _PetParts(
    base: 'assets/svgs/frog_base.svg',
    eyes: 'assets/svgs/frog_eyes.svg',
    eyesPivot: Alignment(0.288, 0.354),
    eyeGeometry: kFrogEyes,
    accessoryOffsets: {
      AccessorySlots.hat: Offset(4, 78),
      AccessorySlots.neck: Offset(4, 45),
      AccessorySlots.face: Offset(4, 47),
    },
  ),
  // PLACEHOLDER, like the raccoon: the reworked axolotl (art_src/gen_rework.py
  // off art_src/axolotl.svg) on the reworked pets' canvas. It has a mouth
  // layer, so it chews; its tail is part of the coat, so it does not wag. The
  // old `axolotl_*` art is still shipped, and the previous entry is in git.
  // Accessory numbers are derived the cat's way.
  'axolotl': _PetParts(
    base: 'assets/svgs/axolotl2_base.svg',
    eyes: 'assets/svgs/axolotl2_eyes.svg',
    mouth: 'assets/svgs/axolotl2_mouth.svg',
    mouthOpen: 'assets/svgs/axolotl2_mouth_open.svg',
    canvas: Size(255, 376.7568),
    canvasOrigin: Offset(-36.5, -114.3784),
    eyesPivot: Alignment(0.361, 0.425),
    eyeGeometry: kAxolotl2Eyes,
    accessoryOffsets: {
      AccessorySlots.hat: Offset(28, 58),
      AccessorySlots.neck: Offset(28, 55),
      AccessorySlots.face: Offset(28, 61),
    },
    accessoryPlacements: {
      'tophat': _AccessoryPlacement(15, 35),
      'cowboyhat': _AccessoryPlacement(22, 38),
      'cap': _AccessoryPlacement(70, 52, mirrored: true),
      'bowtie': _AccessoryPlacement(40, 57),
      'collar': _AccessoryPlacement(27, 65),
      'medal': _AccessoryPlacement(25, 61),
    },
  ),
  // Head centred x 142, skull top y 78; eyes y 112; muzzle ends y 150.
  'gecko': _PetParts(
    base: 'assets/svgs/gecko_base.svg',
    eyes: 'assets/svgs/gecko_eyes.svg',
    eyesPivot: Alignment(0.541, 0.341),
    eyeGeometry: kGeckoEyes,
    accessoryOffsets: {
      AccessorySlots.hat: Offset(32, 44),
      AccessorySlots.neck: Offset(32, 37),
      AccessorySlots.face: Offset(32, 43),
    },
  ),
  // Head centred x 155, skull top y 88; eyes y 130; muzzle ends y 162.
  'chameleon': _PetParts(
    base: 'assets/svgs/chameleon_base.svg',
    eyes: 'assets/svgs/chameleon_eyes.svg',
    eyesPivot: Alignment(0.658, 0.451),
    eyeGeometry: kChameleonEyes,
    accessoryOffsets: {
      AccessorySlots.hat: Offset(46, 54),
      AccessorySlots.neck: Offset(46, 49),
      AccessorySlots.face: Offset(46, 61),
    },
  ),
  // Head centred x 132, skull top y 84; eyes y 118; muzzle ends y 158.
  'seal': _PetParts(
    base: 'assets/svgs/seal_base.svg',
    eyes: 'assets/svgs/seal_eyes.svg',
    eyesPivot: Alignment(0.450, 0.366),
    eyeGeometry: kSealEyes,
    accessoryOffsets: {
      AccessorySlots.hat: Offset(22, 50),
      AccessorySlots.neck: Offset(22, 45),
      AccessorySlots.face: Offset(22, 49),
    },
  ),
  // The final penguin (art_src/gen_rework.py off art_src/penguin-compact.svg),
  // on the reworked pets' canvas; the roster penguin it replaces is still
  // shipped as `penguin_*`. Only the navy back takes a coat colour: the cream
  // face and bib and the orange bill and feet are markings, as they were. The
  // bill is part of the face rather than a muzzle over it, so there is no
  // mouth layer to chew with, and there is no tail to wag; it breathes, blinks
  // and squints.
  //
  // The bill and feet share two oranges, and a chosen beak colour repaints
  // both -- the shaded one as a darker version of the colour, so the bill
  // stays two-toned.
  //
  // Accessories are placed piece by piece, each checked on the penguin through
  // the real renderer. Its head is 100 units across against the cat's 130 and
  // its eyes 46 apart against 61, so the cat's front-on art goes on as it is
  // where it only has to sit -- hats, neckwear, the moustache -- and is cut
  // where it has to line up: the four lens pieces, and the cap, which is worn
  // mirrored. Those five come from art_src/gen_penguin_acc.py and are drawn
  // verbatim.
  'penguin': _PetParts(
    base: 'assets/svgs/penguin2_base.svg',
    eyes: 'assets/svgs/penguin2_eyes.svg',
    canvas: Size(255, 376.7568),
    canvasOrigin: Offset(-36.5, -114.3784),
    eyesPivot: Alignment(0.204, 0.425),
    eyeGeometry: kPenguin2Eyes,
    // The bill and feet in art_src/penguin-compact.svg, which gen_rework.py
    // keeps as drawn.
    beakFills: ['#ffa11c'],
    beakShadeFills: ['#c76a09'],
    // The fallback for a piece with no placement below.
    accessoryOffsets: {
      AccessorySlots.hat: Offset(-2, 64),
      AccessorySlots.neck: Offset(-4, 53),
      AccessorySlots.face: Offset(0, 71),
    },
    accessoryPlacements: {
      // Hats seat on the skull, whose centre is x 108.5 -- the face is turned
      // right of it, the way the cat's is. The head is round, so a hat that
      // fits it tightly sits lower than one that perches.
      'tophat': _AccessoryPlacement(-12, 64),
      'cowboyhat': _AccessoryPlacement(-6, 64),
      'crown': _AccessoryPlacement(-2, 64),
      'partyhat': _AccessoryPlacement(-2, 64),
      'beanie': _AccessoryPlacement(-2, 84),
      'mortarboard': _AccessoryPlacement(-2, 82),
      'headphones': _AccessoryPlacement(-2, 72),
      'wizardhat': _AccessoryPlacement(-2, 64),
      'flowercrown': _AccessoryPlacement(-2, 68),
      'flightcap': _AccessoryPlacement(-2, 74),
      'pumpkinwitch': _AccessoryPlacement(3, 64),
      'devilband': _AccessoryPlacement(8, 64),
      // Neckwear goes on the head-and-body join at y ~178, where the
      // silhouette pinches in on the right.
      'bowtie': _AccessoryPlacement(9, 42),
      'necklace': _AccessoryPlacement(2, 68),
      'collar': _AccessoryPlacement(-3, 53),
      'medal': _AccessoryPlacement(-5, 53),
      'scarf': _AccessoryPlacement(-6, 53),
      'bandana': _AccessoryPlacement(-5, 53),
      'flightscarf': _AccessoryPlacement(-20, 53),
      'ghostbandana': _AccessoryPlacement(6, 56),
      'batchoker': _AccessoryPlacement(4, 57),
      // Under the bill.
      'mustache': _AccessoryPlacement(4, 71),
    },
    // Drawn in place: no placement, no clamp.
    accessoryOverrides: {
      'cap': 'assets/svgs/acc_cap_penguin.svg',
      'glasses': 'assets/svgs/acc_glasses_penguin.svg',
      'sunglasses': 'assets/svgs/acc_sunglasses_penguin.svg',
      'goggles': 'assets/svgs/acc_goggles_penguin.svg',
      'mask': 'assets/svgs/acc_mask_penguin.svg',
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

/// Whether [type] has a beak the player can colour.
bool petHasBeak(String type) =>
    _layeredPets[type]?.beakFills.isNotEmpty ?? false;

/// The colour [type]'s beak shows with no colour chosen, for a pet wearing
/// [bodyColor] — so the wardrobe's "natural" swatch shows what it will give.
/// Null for a pet without a beak.
String? naturalBeakFor(String type, String bodyColor) {
  final fills = _layeredPets[type]?.beakFills ?? const <String>[];
  if (fills.isEmpty) return null;
  if (fills.first != kBeakFill) return fills.first;
  final tones = naturalTonesFor(type, bodyColor);
  return tones?.beak ?? tones?.shade ?? darken(bodyColor, 0.72);
}

/// The point [type]'s eye layer is scaled about, so a blink and the petting
/// squint close the lid downward rather than sliding it.
///
/// Exposed so a test can find that layer. The eyes are the only thing in the
/// sprite scaled about a point on the face — everything else is anchored at
/// the pet's feet or is a plain translation — which makes this pivot the
/// handle on the reaction, and the alternative is a golden file per pet.
Alignment eyesPivotFor(String type) =>
    _layeredPets[type]?.eyesPivot ?? const Alignment(0.248, 0.091);

/// The art [type] wears for [def]: its own cut of the piece where it has one,
/// otherwise the shared front-on art.
///
/// Exposed so a test can check that every pet/accessory pair resolves to an
/// asset that actually ships — a mistyped override would otherwise show up as
/// a pet wearing nothing, and only on that one pet with that one item.
/// The art a pet wears for [def].
///
/// A palette variant resolves to its source's art — including the source's
/// own per-pet cut — so a recoloured hat inherits the bird drawing and the dog
/// placement that were made for the shape once. The colour is applied when the
/// layer is built, not here.
String accessoryAssetFor(String type, AccessoryDef def) {
  final art = artSourceFor(def);
  return _layeredPets[type]?.accessoryOverrides[art.id] ?? art.asset;
}

/// The accessory whose drawings [def] uses: itself, or the piece it recolours.
///
/// Resolves one hop only. A variant of a variant would make the source of a
/// piece a question with more than one answer, which is exactly the sort of
/// thing that ends up mis-tinting a hat nobody can trace.
AccessoryDef artSourceFor(AccessoryDef def) {
  final recolor = def.recolor;
  if (recolor == null) return def;
  return accessoryById(recolor.sourceId) ?? def;
}

/// Where [type] moves [def]'s art to, before the canvas clamp — or null when
/// the pet wears its own cut of the piece, which is drawn in place and moved
/// by nothing.
///
/// Exposed so a test can check that every pet/accessory pair actually lands on
/// the canvas. The alternative is a golden image per pair, which is 30 pets
/// times 22 pieces of pictures to answer a question about two numbers.
Offset? accessoryOffsetFor(String type, AccessoryDef def) {
  final parts = _layeredPets[type];
  if (parts == null) return null;
  final source = artSourceFor(def);
  if (parts.accessoryOverrides.containsKey(source.id)) {
    return parts.borrowedOffsets[source.slot];
  }
  return parts.placementFor(source).offset;
}

/// Whether [type] wears [def] flipped left-to-right — the dog's cap, and the
/// pets that borrowed its placement. Mirroring changes which end of the art
/// has to fit on the canvas, so the clamp needs it.
bool accessoryIsMirrored(String type, AccessoryDef def) {
  final parts = _layeredPets[type];
  if (parts == null) return false;
  final source = artSourceFor(def);
  if (parts.accessoryOverrides.containsKey(source.id)) return false;
  return parts.placementFor(source).mirrored;
}

/// [offset], reduced where it would carry [asset] off the side of the canvas.
///
/// The accessory art was drawn on the cat, whose head is near the middle,
/// and the widest pieces are nearly as wide as the canvas — the wizard hat
/// spans 182 of its 222 units. A pet whose head sits off to one side has to
/// move a hat sideways to wear it, and past a certain point the brim leaves
/// the canvas and is cut off, which is what the roster's off-centre animals
/// (the skunk's head is 38 units right of the cat's) were doing.
///
/// Clamping rather than refusing to move, because a wide hat over a small
/// head has slack: 20 units off-centre still covers it, and reads as a hat
/// worn at an angle. A sliced brim reads as a bug. Narrow pieces have room
/// to move the whole way and are not clamped at all, so a party hat still
/// lands exactly where the pet asked for it.
///
/// Vertical is left alone: the canvas has 90 units of headroom above the
/// pets for exactly this, and nothing has come close to using it.
Offset accessoryPlacementOnCanvas(Offset offset, String asset,
    {required bool mirrored}) {
  final extent = kAccessoryExtents[asset];
  if (extent == null) return offset;
  // Mirroring reflects the art about the canvas centre before the move, so
  // the piece that has to fit is the reflection.
  final centre = _kCanvasOrigin.dx + _kCanvas.width / 2;
  final left = mirrored ? 2 * centre - extent.right : extent.left;
  final right = mirrored ? 2 * centre - extent.left : extent.right;
  final lo = _kCanvasOrigin.dx - left;
  final hi = (_kCanvasOrigin.dx + _kCanvas.width) - right;
  if (lo > hi) return offset; // wider than the canvas: nothing to choose
  return Offset(offset.dx.clamp(lo, hi), offset.dy);
}

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

  /// Dresses the pet in these instead of whatever it is actually wearing.
  ///
  /// For a fitting room: the season pass shows a piece the player does not own
  /// yet, and the wardrobe is the only other place a pet gets dressed. Passing
  /// a list here changes nothing that is saved — an empty list is a stripped
  /// pet, and null (the default) is the pet as it really is.
  final List<AccessoryDef>? previewAccessories;

  /// Draws the pet in the coat and eyes it was drawn with, whatever the player
  /// has chosen for their own pet of that type.
  ///
  /// For a pet that is not the player's: a scenario's fox barista is *a* fox,
  /// and should not turn up in the colours the player painted theirs.
  final bool naturalCoat;

  /// What a previewed pet is doing instead of idling: a scene can have it eat
  /// the meal it just bought without the pet at home doing the same. Ignored
  /// without [previewType], where the pet's real state is what shows.
  final PetVisualState? previewState;

  /// Casts the pet's own silhouette on the ground in front of its feet,
  /// hat and all.
  ///
  /// Drawn here rather than by the caller because only this widget knows the
  /// shape: the scene used to draw a fixed ellipse, which is the same oval
  /// under a cat, a chick and a parrot on a perch, and matched none of them.
  /// It is also the only place that can keep the shadow in step — the pose is
  /// sampled once a frame and used twice, so the shadow rocks and breathes
  /// with the pet instead of running its own loop a few frames out of phase.
  ///
  /// Off by default: a pet in a carousel tile or a wardrobe preview is not
  /// standing on anything.
  final bool groundShadow;

  const CharacterSprite({
    super.key,
    required this.width,
    required this.height,
    this.fit = BoxFit.contain,
    this.motionProfile = CharacterMotionProfile.auto,
    this.previewType,
    this.previewAccessories,
    this.naturalCoat = false,
    this.previewState,
    this.groundShadow = false,
  });

  @override
  State<CharacterSprite> createState() => _CharacterSpriteState();
}

class _CharacterSpriteState extends State<CharacterSprite> {
  /// The idle motion is stepped by [PixelClock]: [_frame] counts its steps
  /// since the sprite appeared, and the breath, tail flick, chew and petting
  /// rock are all read off it. [_pose] is what the sprite rebuilds on.
  late final PixelClockListener _clock = PixelClockListener(_step);
  final ValueNotifier<int> _pose = ValueNotifier(0);
  int _frame = 0;

  /// Where the blink is in [_blinkFrames], or -1 between blinks, and how many
  /// steps until the next one.
  int _blinkAt = -1;
  late int _stepsToBlink = _nextBlinkSteps();

  final math.Random _rng = math.Random();
  bool _reduceMotion = false;

  /// What was last drawn, whole: every layer parsed and ready. A change to the
  /// pet -- a new hat, another coat -- builds its replacement off to the side
  /// and swaps it in only once every layer of it is ready, so the pet is
  /// never seen half changed. Null until the first one is ready, and the
  /// sprite draws nothing until then rather than a pet missing its parts.
  _Look? _look;

  /// The load in flight for the look that is wanted, so a rebuild while it
  /// runs does not start another.
  Future<void>? _loading;

  // Pixel-style stepping: idle motion advances one [PixelClock] step at a time
  // (8 a second) and is snapped to a few discrete levels, so the pet moves in
  // chunky frames rather than interpolating smoothly.
  //
  // One breath, in steps: 2.75 s, the 2.8 s it always took rounded to whole
  // steps.
  static const int _breathFrames = 22;
  static const int _breathSteps = 2; // signed snap -> 5 poses (incl. rest)

  /// A blink, one pose a step: half shut, shut, half shut, open. The three
  /// poses it always snapped between, each held for one step of the clock.
  static const List<double> _blinkFrames = [0.5, 1.0, 0.5, 0.0];
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

  /// The ground shadow: how far the silhouette is laid down in front of the
  /// feet, as a fraction of the pet's own height, and how dark it lands.
  ///
  /// A projection rather than a squash in place, so the pet's shape survives
  /// the flattening — a cat squashed onto its own feet is an oval again, and
  /// an oval is what this replaced. Laid forward, the feet stay at the foot
  /// line and the head and hat reach away from it, which is the part a player
  /// can actually read as belonging to their pet.
  ///
  /// 0.13 is what keeps the far end inside the clearance the scene leaves
  /// under the pet, for the tallest thing it can wear: a wizard hat puts the
  /// silhouette 317 art units tall against the cat's own 238.
  static const double _kShadowDepth = 0.13;
  static const int _kShadowAlpha = 0x42; // ~26%

  /// Snaps a 0..1 value to (levels + 1) discrete steps.
  double _quantize(double v, int levels) =>
      (v * levels).roundToDouble() / levels;

  @override
  void initState() {
    super.initState();
    // The clock is joined in didChangeDependencies, once reduce-motion and the
    // route's ticker mode can be read.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Just the one flag: MediaQuery.maybeOf would rebuild every sprite on
    // screen on every frame of the keyboard sliding in.
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduce != _reduceMotion) {
      _reduceMotion = reduce;
      // Stopped mid-blink, the eyes would stay half shut.
      if (reduce) _blinkAt = -1;
    }
    _clock.update(context, animate: !_reduceMotion);
  }

  @override
  void dispose() {
    _clock.dispose();
    _pose.dispose();
    super.dispose();
  }

  /// Steps until the next blink: idle pets blink every ~2.2-5.8s.
  int _nextBlinkSteps() =>
      ((2200 + _rng.nextInt(3600)) / PixelClock.step.inMilliseconds).round();

  /// One step of the clock: the next frame of the breath, and of the blink
  /// when one is due.
  void _step() {
    _frame++;
    if (_blinkAt >= 0) {
      _blinkAt++;
      if (_blinkAt == _blinkFrames.length) {
        // Occasionally twice in a row.
        _blinkAt = _rng.nextDouble() < 0.2 ? 0 : -1;
        if (_blinkAt < 0) _stepsToBlink = _nextBlinkSteps();
      }
    } else if (--_stepsToBlink <= 0) {
      _blinkAt = 0;
    }
    _pose.value = _frame;
  }

  /// How far shut the eyes are mid-blink: 0 open, 0.5 half, 1 shut.
  double get _blinkStep => _blinkAt < 0 ? 0.0 : _blinkFrames[_blinkAt];

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

  /// One equipped accessory, moved to where [type] wears it. [svg] is the
  /// piece's drawing, already recoloured and sealed (see [_Look]).
  ///
  /// A pet with its own cut of the piece is the exception: that art was drawn
  /// against this pet already, so it goes down untouched.
  Widget _accessoryLayer(_PetParts parts, String type, AccessoryDef def,
      String svg, double unit) {
    final source = artSourceFor(def);
    // Every accessory is drawn on the shared canvas and fits itself to the
    // box, so on a pet that carries a canvas of its own -- a bigger frame in
    // the same box, which is how the reworked dog is drawn smaller without
    // changing the box -- the piece comes out at the wrong size for the pet
    // under it. Both frames are centred on the same point, so one scale about
    // the centre puts the accessory back on the pet's own scale.
    final canvasScale = _kCanvas.height / parts.canvas.height;
    Widget art = PetPicture(svg, fit: widget.fit);
    if (canvasScale != 1.0) {
      art = Transform.scale(scale: canvasScale, child: art);
    }
    // Placement follows the *source*, because that is the shape being seated:
    // a recoloured top hat sits exactly where the top hat sits.
    if (parts.accessoryOverrides.containsKey(source.id)) {
      // Its own drawing goes down untouched; a cut borrowed from another pet
      // is moved onto this one.
      final borrowed = parts.borrowedOffsets[source.slot];
      return borrowed == null
          ? art
          : Transform.translate(offset: borrowed * unit, child: art);
    }
    final placement = parts.placementFor(source);
    if (placement.mirrored) {
      art = Transform.scale(scaleX: -1, child: art);
    }
    final moved = accessoryPlacementOnCanvas(
      placement.offset,
      accessoryAssetFor(type, def),
      mirrored: placement.mirrored,
    );
    return Transform.translate(offset: moved * unit, child: art);
  }



  /// Swings the tail layer about its hinge. [pivot] is in canvas art units.
  /// BoxFit.contain centres the art in the layer's box, so the canvas centre
  /// is the box centre — which is where [Transform.rotate] measures `origin`
  /// from, leaving the hinge as an art-space offset from it.
  Widget _tail(Widget layer, double angle, Offset? pivot, double unit,
      Size canvas, Offset canvasOrigin) {
    if (angle == 0.0 || pivot == null) return layer;
    final origin = (pivot - canvas.center(canvasOrigin)) * unit;
    return Transform.rotate(angle: angle, origin: origin, child: layer);
  }

  PetColorSpec _safeColorSpec(CharacterProvider provider, String type) {
    if (widget.naturalCoat) {
      return PetColorSpec(
        bodyColor: naturalCoatFor(type),
        eyeMode: EyeMode.solid,
        eyeColor1: kDefaultEyeColor1,
        eyeColor2: kDefaultEyeColor2,
      );
    }
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
    final preview = widget.previewAccessories;
    if (preview != null) return preview;
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
    final w = widget.width.isFinite ? widget.width : null;
    final h = widget.height.isFinite ? widget.height : null;

    // The pet is drawn from a [_Look]: every layer of it, parsed and ready.
    // Until the one wanted now is ready the last whole one stays up, and
    // before there is any the box stays empty -- a pet that arrives all at
    // once, rather than coat, then tail, then eyes, then hat.
    final look = _lookFor(provider);
    if (look == null) {
      // Empty, but the size the pet will be: a sprite given no size takes the
      // art's own, and the screen around it should not jump when it arrives.
      return SizedBox(
        width: w,
        height: h,
        child: const CustomPaint(size: _kCanvas),
      );
    }
    final type = look.type;
    final parts = look.parts;

    return SizedBox(
      width: w,
      height: h,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final profile = _effectiveProfile(constraints);
          final fullMotion = profile == CharacterMotionProfile.full;
          final motionGain = _motionGain(constraints);

          return AnimatedBuilder(
            animation: _pose,
            builder: (context, _) {
              // A previewed pet idles, unless the screen showing it says
              // otherwise: it is not the one whose mood the screen is about.
              final state = preview != null
                  ? (widget.previewState ?? PetVisualState.breathing)
                  : _safeVisualState(provider);

              // The breathing loop, read off the clock's steps, so motion
              // advances in chunky frames instead of every render.
              final frame = _frame;
              // Time through the breath, snapped to the step grid.
              final tStep = (frame % _breathFrames) / _breathFrames;
              // Signed breath: +1 = peak inhale, -1 = deepest exhale, 0 = rest.
              final breath =
                  _quantize(math.sin(tStep * 2 * math.pi), _breathSteps);
              final inhale = math.max(0.0, breath);
              final exhale = math.max(0.0, -breath);

              // Body holds still while eating, so only the mouth + tail move
              // — but only for a pet that has a mouth to move. The three
              // cell-map pets have no chew pose yet, and freezing the breath
              // as well would leave them completely motionless through a
              // meal, which reads as the app having hung rather than as a pet
              // eating.
              final eating = state == PetVisualState.eating;
              final chews = parts == null ||
                  parts.mouthOpen != null ||
                  parts.baseOpen != null;
              final petted = state == PetVisualState.petted;
              double inhaleAmp = _breatheAmpFor(state);
              inhaleAmp *= motionGain * (fullMotion ? 1.0 : 0.5);
              if (_reduceMotion || (eating && chews)) inhaleAmp = 0.0;
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
              final canvas = parts?.canvas ?? _kCanvas;
              final canvasOrigin = parts?.canvasOrigin ?? _kCanvasOrigin;
              final boxW = constraints.maxWidth.isFinite
                  ? constraints.maxWidth
                  : (w ?? canvas.width);
              final boxH = constraints.maxHeight.isFinite
                  ? constraints.maxHeight
                  : (h ?? canvas.height);
              final unit = math.min(
                boxW / canvas.width,
                boxH / canvas.height,
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

              /// [art] with its own silhouette laid on the ground under it.
              ///
              /// The same widget twice: once flipped about the foot line,
              /// flattened and filled black, and once as the pet. It goes
              /// inside [posed], so whatever the body is doing this frame the
              /// shadow does with it.
              Widget grounded(Widget art) {
                if (!widget.groundShadow) return art;
                return Stack(
                  // passthrough, not the default: a Stack hands *loose*
                  // constraints to a non-positioned child, and the sprite
                  // falls back to the art's intrinsic 222x328 viewBox
                  // whenever its constraints are not tight — so wrapping the
                  // pet in a plain Stack silently shrinks it and leaves the
                  // shadow behind on the ground below. That regression has
                  // happened here before.
                  fit: StackFit.passthrough,
                  // The projection reaches past the foot line, which is the
                  // bottom of the art's own box — that is the whole point of
                  // it, so nothing here may clip.
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: Transform(
                        alignment: Alignment.bottomCenter,
                        transform: Matrix4.diagonal3Values(
                            1.0, -_kShadowDepth, 1.0),
                        // srcIn keeps the art's alpha and throws its colour
                        // away, so what lands is the outline of everything
                        // drawn — coat, tail, hat — as one flat shape. A
                        // translucent black does it in one pass, where a
                        // solid fill plus an Opacity would cost a second
                        // save layer every frame.
                        child: ColorFiltered(
                          colorFilter: const ColorFilter.mode(
                              Color(_kShadowAlpha << 24), BlendMode.srcIn),
                          child: art,
                        ),
                      ),
                    ),
                    art,
                  ],
                );
              }

              // Whole-sprite render, for any pet not split into layers.
              if (parts == null) {
                return posed(
                  grounded(PetPicture(look.whole!, fit: widget.fit)),
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
              final blinkStep = sleeping ? 1.0 : _blinkStep; // 0, 0.5, 1.0
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

              // Chew: open and close on the fps grid, held open while food is
              // hovering (waiting phase) rather than alternating.
              //
              // A previewed pet has no eating phase of its own — the
              // provider's belongs to the pet at home — so it always chews.
              final phase = preview != null
                  ? PetEatingPhase.consuming
                  : _safeEatingPhase(provider);
              final chewing = eating &&
                  !_reduceMotion &&
                  (phase != PetEatingPhase.consuming || frame.isEven);
              // Whichever the pet chews with: a mouth laid over the muzzle, or
              // a second coat for a beak that is part of the head.
              final mouthSvg =
                  chewing && look.mouth != null ? look.mouthOpen : look.mouth;
              final baseSvg =
                  chewing ? (look.baseOpen ?? look.base!) : look.base!;

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
              final accessories = look.accessories;

              final stack = Stack(
                fit: StackFit.passthrough,
                children: [
                  PetPicture(baseSvg, fit: widget.fit),
                  if (look.tails.isNotEmpty)
                    _tail(
                      PetPicture(look.tails[tailIdx], fit: widget.fit),
                      tailAngle,
                      parts.tailPivot,
                      unit,
                      canvas,
                      canvasOrigin,
                    ),
                  for (var i = 0; i < accessories.length; i++)
                    if (parts.placementFor(accessories[i]).underMuzzle)
                      _accessoryLayer(
                          parts, type, accessories[i], look.accessorySvgs[i], unit),
                  if (mouthSvg != null) PetPicture(mouthSvg, fit: widget.fit),
                  Transform(
                    alignment: parts.eyesPivot,
                    transform: Matrix4.diagonal3Values(1.0, eyeScaleY, 1.0),
                    child: PetPicture(look.eyes!, fit: widget.fit),
                  ),
                  for (var i = 0; i < accessories.length; i++)
                    if (!parts.placementFor(accessories[i]).underMuzzle)
                      _accessoryLayer(
                          parts, type, accessories[i], look.accessorySvgs[i], unit),
                ],
              );

              return posed(grounded(stack));
            },
          );
        },
      ),
    );
  }

  /// The look to draw now: the one wanted, if every layer of it is ready,
  /// otherwise the last whole one (null on the very first draw).
  ///
  /// What is wanted is read off the provider on every build, and a change to
  /// it -- the pet's hat, its coat, which pet it is -- is prepared off to the
  /// side. Only the moment all of it is parsed does the sprite swap, so a
  /// change appears all at once rather than one layer at a time.
  _Look? _lookFor(CharacterProvider provider) {
    final preview = widget.previewType;
    // A sprite that reads the saved pet must wait for it: before the save is
    // read the provider holds a default cat in the default coat with nothing
    // on, which is the very half-dressed pet this is here to prevent. A
    // preview in its natural coat with its own accessories reads none of it.
    final readsSave = !(widget.naturalCoat && widget.previewAccessories != null);
    if (readsSave && !_safeIsLoaded(provider)) return _look;

    final type = preview ?? _safeCurrentCharacterType(provider);
    final wholeAsset = preview != null
        ? 'assets/svgs/$preview.svg'
        : _safeCurrentCharacterAsset(provider);
    final spec = _safeColorSpec(provider, type);
    final accessories = _safeEquippedAccessories(provider, type);

    final current = _look;
    if (current != null && current.isFor(type, spec, accessories, wholeAsset)) {
      return current;
    }

    final missing = [
      for (final asset in _lookAssets(type, accessories, wholeAsset))
        if (PetArt.raw(asset) == null) asset,
    ];
    if (missing.isNotEmpty) {
      _load(PetArt.loadRaw(missing));
      return current;
    }
    final next = _resolveLook(type, spec, accessories, wholeAsset);
    if (next.svgs.every(PetArt.has)) return _look = next;
    _load(PetArt.prepare(next.svgs));
    return current;
  }

  /// Rebuilds once [work] is done, to look again at what is ready. One load at
  /// a time: a rebuild while one runs would only ask for the same layers.
  void _load(Future<void> work) {
    if (_loading != null) return;
    _loading = work.whenComplete(() {
      _loading = null;
      if (mounted) setState(() {});
    });
  }

  bool _safeIsLoaded(CharacterProvider provider) {
    try {
      return provider.isLoaded;
    } catch (_) {
      return true;
    }
  }
}

/// Everything one pet, in one coat and one outfit, is drawn from: the SVG text
/// of each of its layers, recoloured and sealed, ready to be looked up in
/// [PetArt]. Built whole, and swapped in whole.
class _Look {
  const _Look({
    required this.type,
    required this.parts,
    required this.spec,
    required this.accessories,
    required this.wholeAsset,
    this.whole,
    this.base,
    this.baseOpen,
    this.mouth,
    this.mouthOpen,
    this.tails = const [],
    this.eyes,
    this.accessorySvgs = const [],
  });

  final String type;

  /// Null for a pet that is one drawing rather than a set of layers; then
  /// only [whole] is set.
  final _PetParts? parts;
  final PetColorSpec spec;
  final List<AccessoryDef> accessories;

  /// The asset a whole-sprite pet is drawn from. Part of what the look is
  /// *for*, so the sprite knows to rebuild when the asset it wants changes.
  final String wholeAsset;

  final String? whole;
  final String? base;
  final String? baseOpen;
  final String? mouth;
  final String? mouthOpen;
  final List<String> tails;
  final String? eyes;

  /// One per entry of [accessories], in the same order.
  final List<String> accessorySvgs;

  bool isFor(String type, PetColorSpec spec, List<AccessoryDef> accessories,
          String wholeAsset) =>
      type == this.type &&
      spec == this.spec &&
      wholeAsset == this.wholeAsset &&
      listEquals(accessories, this.accessories);

  /// Every drawing this look can put on screen, in any pose.
  Iterable<String> get svgs sync* {
    if (whole != null) yield whole!;
    if (base != null) yield base!;
    if (baseOpen != null) yield baseOpen!;
    if (mouth != null) yield mouth!;
    if (mouthOpen != null) yield mouthOpen!;
    yield* tails;
    if (eyes != null) yield eyes!;
    yield* accessorySvgs;
  }
}

/// Recoloured, sealed documents, kept so that a look is rebuilt from text that
/// is already made. They are bounded loosely: a coat is a few documents, and a
/// player trying on thirty of them is the only way to reach the limit.
final Map<String, String> _tintCache = {};
final Map<String, String> _sealCache = {};
final Map<(PetColorSpec, PetEyeGeometry), String> _eyesCache = {};
const int _kDocumentCacheLimit = 240;

V _remember<K, V>(Map<K, V> cache, K key, V Function() make) {
  final known = cache[key];
  if (known != null) return known;
  if (cache.length >= _kDocumentCacheLimit) cache.clear();
  return cache[key] = make();
}

/// The assets whose text a look for these needs. Whole-sprite pets are one.
List<String> _lookAssets(
    String type, List<AccessoryDef> accessories, String wholeAsset) {
  final parts = _layeredPets[type];
  if (parts == null) return [wholeAsset];
  return [
    parts.base,
    if (parts.baseOpen != null) parts.baseOpen!,
    if (parts.mouth != null) parts.mouth!,
    if (parts.mouthOpen != null) parts.mouthOpen!,
    ...parts.tailFrames,
    for (final def in accessories) accessoryAssetFor(type, def),
  ];
}

/// [asset]'s text with its outlines sealed, for art that is not recoloured.
String _sealedAsset(String asset) =>
    _remember(_sealCache, asset, () => sealOutlines(PetArt.raw(asset)!));

/// [asset]'s coat fills recoloured for [spec], and sealed. Layers without coat
/// fills (the mouth) pass through unchanged.
String _tintedCoat(
    String asset, String type, PetColorSpec spec, _PetParts parts) {
  final key = '$asset|$type|${spec.bodyColor}|${spec.beakColor}';
  return _remember(_tintCache, key, () {
    // In its natural coat a pet is painted in the tones it was drawn in.
    final tones = naturalTonesFor(type, spec.bodyColor);
    return sealOutlines(recolorBodyLayer(
      PetArt.raw(asset)!,
      spec.bodyColor,
      beakColor: spec.beakColor,
      beakFills: parts.beakFills,
      beakShadeFills: parts.beakShadeFills,
      shadeColor: tones?.shade,
      lightColor: tones?.light,
      naturalBeak: tones?.beak,
    ));
  });
}

/// One accessory's drawing for [type], recoloured if the piece is a palette
/// variant of another.
String _accessorySvg(String type, AccessoryDef def) {
  final asset = accessoryAssetFor(type, def);
  final recolor = def.recolor?.fills;
  if (recolor == null || recolor.isEmpty) return _sealedAsset(asset);
  // Keyed on the asset *and* the palette, so two variants of one drawing do
  // not share a cache entry and hand each other their colours.
  final key =
      '$asset#${recolor.entries.map((e) => '${e.key}>${e.value}').join(',')}';
  return _remember(_sealCache, key,
      () => sealOutlines(recolorAccessory(PetArt.raw(asset)!, recolor)));
}

/// The look for these, built from text that must already be loaded (see
/// [_lookAssets]).
_Look _resolveLook(String type, PetColorSpec spec,
    List<AccessoryDef> accessories, String wholeAsset) {
  final parts = _layeredPets[type];
  if (parts == null) {
    return _Look(
      type: type,
      parts: null,
      spec: spec,
      accessories: accessories,
      wholeAsset: wholeAsset,
      whole: _sealedAsset(wholeAsset),
    );
  }
  String coat(String asset) => _tintedCoat(asset, type, spec, parts);
  return _Look(
    type: type,
    parts: parts,
    spec: spec,
    accessories: accessories,
    wholeAsset: wholeAsset,
    base: coat(parts.base),
    baseOpen: parts.baseOpen == null ? null : coat(parts.baseOpen!),
    mouth: parts.mouth == null ? null : coat(parts.mouth!),
    mouthOpen: parts.mouthOpen == null ? null : coat(parts.mouthOpen!),
    tails: [for (final tail in parts.tailFrames) coat(tail)],
    eyes: _remember(_eyesCache, (spec, parts.eyeGeometry),
        () => buildEyesLayer(spec, parts.eyeGeometry)),
    accessorySvgs: [for (final def in accessories) _accessorySvg(type, def)],
  );
}

/// Reads and parses the pet that is out, so the first screen to show it shows
/// it whole. Called while the splash is still up. Never throws: a pet that
/// pops in a moment late is no reason to stop the app.
Future<void> warmPetArt(CharacterProvider provider) async {
  try {
    final type = provider.currentCharacterType;
    final accessories = provider.equippedAccessoriesFor(type);
    final wholeAsset = provider.currentCharacterAsset;
    await PetArt.loadRaw(_lookAssets(type, accessories, wholeAsset));
    final look = _resolveLook(
        type, provider.colorSpecFor(type), accessories, wholeAsset);
    await PetArt.prepare(look.svgs);
  } catch (_) {
    // Whatever was missed is loaded by the sprite that wants it.
  }
}
