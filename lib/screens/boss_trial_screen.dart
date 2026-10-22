import 'dart:async' show unawaited;
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderStack;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../components/boss_trial/angler_pieces.dart';
import '../components/boss_trial/arena_pieces.dart';
import '../components/boss_trial/arena_scenery.dart';
import '../components/boss_trial/boss_motion.dart';
import '../components/boss_trial/crystal_pieces.dart';
import '../components/boss_trial/dragon_pieces.dart';
import '../components/boss_trial/hex_pieces.dart';
import '../components/boss_trial/hoothex_pieces.dart';
import '../components/boss_trial/mossback_pieces.dart';
import '../components/boss_trial/sphinx_pieces.dart';
import '../components/boss_trial/spell_pieces.dart';
import '../components/boss_trial/trial_boss.dart';
import '../components/boss_trial/trial_particles.dart';
import '../components/boss_trial/trial_skin.dart';
import '../components/character_sprite.dart';
import '../constants/boss_trial_advanced.dart';
import '../constants/boss_trial_en_tr.dart';
import '../constants/boss_trial_sentences.dart';
import '../constants/boss_trial_words.dart';
import '../constants/theme.dart';
import '../constants/progression.dart' show RewardDef, RewardType;
import '../providers/boss_progress_provider.dart';
import '../providers/character_provider.dart';
import '../providers/language_provider.dart';
import '../providers/user_provider.dart';
import '../providers/vocab_provider.dart';
import '../utils/boss_trial.dart';
import '../utils/boss_trial_angler.dart';
import '../utils/boss_trial_crystal.dart';
import '../utils/boss_trial_dragon.dart';
import '../utils/boss_trial_moss.dart';
import '../utils/boss_trial_sphinx.dart';
import '../utils/boss_trial_witch.dart';
import '../utils/fonts.dart';

part 'boss_trial_pet_moves.dart';
part 'boss_trial_mossback.dart';
part 'boss_trial_hoothex.dart';
part 'boss_trial_lanternmaw.dart';
part 'boss_trial_sableth.dart';
part 'boss_trial_pyrewing.dart';
part 'boss_trial_amethyst.dart';

/// A milestone boss trial, in two rounds, against any of [TrialBosses].
///
/// **Mossback** (trial 1, level 5):
///
/// * **Catch:** Mossback jumps and shouts a word in the language being
///   learned; its landing throws debris to the sides and shakes rubble loose,
///   each piece carrying a meaning in the player's language. The right piece
///   is pounced on and thrown back, and the damage lands on impact.
/// * **Spells**, from half patience: Mossback roars and starts charging a
///   boulder. The player gets a sentence in their own language and word
///   stones in Mossback's, and casts it by tapping the stones in order. A
///   finished spell flies at Mossback; a wrong stone fizzles and feeds its
///   charge; a full charge brings the boulder down on the pet.
///
/// **Amethyst** (trial 2, level 10), whose first round is being chosen from
/// three attacks of its own, all playable from the intro (the rules are in
/// `utils/boss_trial_crystal.dart`):
///
/// * **Crystal Spikes:** it slams the ledge and roars four words; a spike
///   carrying each grows down at the pet. Tapping a spike and the gem at the
///   pet's feet that means it, in either order, shatters the spike and the pet
///   throws the gem. A wrong pair makes the spike lurch on; the first to reach
///   the pet seals it in amethyst.
/// * **Crystal Echo:** it roars a whole sentence and three crystals rise with
///   meanings in the player's language, while amethyst creeps up the pet.
///   The right crystal is thrown back; a wrong one lets the amethyst jump on.
/// * **Shard Volley:** it hurls shards, each claiming a word means something.
///   Lies are smashed and swatted back; true ones are let through for the pet
///   to catch and throw. A lie getting through seals the pet.
/// * **Spells**, from half patience, with a crystal charging in place of the
///   boulder and two decoy stones.
///
/// **The witch** (trial 3, level 15), who flies instead of standing:
///
/// * **Hexed Scroll:** she swoops across the arena and reads out a spell — a
///   whole sentence in her language with one word hexed — while the pet is
///   shown what it should say. Tapping the hexed word breaks it and the curse
///   rebounds on her; a wrong word burns her fuse along; the fuse running out
///   fires the hex at the pet, which turns into a frog for a moment.
/// * **Brewing**, from half patience: Mossback's Spells round with her potion
///   in place of the boulder and two decoy stones spelled like the real words.
///
/// Mossback's and the witch's openers under test beside those — Shell Game,
/// Pebble Pop and Stepping Stones; Mirror Clones, Tangled Spells and Broom
/// Chase — play out in `boss_trial_mossback.dart` and `boss_trial_hoothex.dart`,
/// parts of this screen that share its clock.
///
/// **Lanternmaw** (trial 4, level 20), a deep-sea anglerfish that swims the
/// way the witch flies, with two openers under test in
/// `boss_trial_lanternmaw.dart` (the rules are in `utils/boss_trial_angler.dart`):
///
/// * **Lure:** its lantern lights a sentence with a word missing; fish swim
///   past carrying words for the gap, and the right one is hooked.
/// * **Bubbles:** it breathes out a word's meaning; letters rise off the
///   seabed in bubbles, and popping them in order spells the word.
/// * **Spells**, from half patience, with a bubble blown by its lantern in
///   place of the boulder. Anything of its that gets through traps the pet in
///   a bubble.
/// * **Shoal:** five fish carry words, four of a kind; the stray is tapped.
///
/// **Sableth** (trial 5, level 25), the sand sphinx, whose Riddle, Sealed
/// Door and Tablets play out in `boss_trial_sableth.dart`, and **Pyrewing**
/// (trial 6, level 30), the dragon, whose Parley, Flame Link, Ember
/// Paraphrase and Hoard play out in `boss_trial_pyrewing.dart`. Amethyst's
/// fourth, the Vein, is in `boss_trial_amethyst.dart`, Lanternmaw's Net
/// beside its others, and Sableth's Sandstorm beside its. Sableth's first
/// three, Pyrewing's four and the Shoal draw on content
/// written only in English and Turkish so far
/// (`constants/boss_trial_en_tr.dart`): a player on another pair fights them
/// in those two, and the intro says so.
///
/// A TESTING BUILD, reached from a debug-only badge on the home screen (see
/// `AppRuntimeConfig.bossTrial`), which opens the climb map
/// (`BossClimbScreen`): a stop on it opens this screen on that boss and level,
/// with no pickers. Its copy is English-only and nothing it does is saved. The rules live in `utils/boss_trial.dart`, the boss's
/// choreography in `components/boss_trial/`; this screen owns the clock.
///
/// Built from ordinary widgets on one game clock rather than in a game engine,
/// so the pet in the arena is the real [CharacterSprite] — its coat, its
/// accessories, its idle — and every effect, the pet included, pauses on the
/// same hit-stop.
class BossTrialScreen extends StatefulWidget {
  const BossTrialScreen({
    super.key,
    this.boss = TrialBosses.mossback,
    this.step = 0,
    this.picker = true,
  });

  /// The boss the intro opens on. The intro can switch to another, since
  /// trials are not wired to levels yet.
  final TrialBoss boss;

  /// Which of the boss's levels the intro opens on: its openings one each,
  /// then its finale.
  final int step;

  /// Whether the intro offers the boss and level pickers. Off when the screen
  /// is reached from the climb map (`BossClimbScreen`), which has chosen both.
  final bool picker;

  @override
  State<BossTrialScreen> createState() => _BossTrialScreenState();
}

enum _Phase { ready, playing, over }

/// Where the current wave is.
enum _Stage {
  /// Between waves.
  gap,

  /// The boss is in the air; the rubble has not broken loose yet.
  jumping,

  /// Rubble is falling and can be picked.
  falling,

  /// A pick was made or the rubble landed, and its consequences are playing.
  resolving,

  /// The boss roars into the next round of its finale.
  announcing,

  /// The witch's scroll is open and its fuse is burning.
  reading,

  /// Amethyst's spikes are growing down and can be paired with their gems.
  spiking,

  /// Amethyst's echo crystals are up and the amethyst is creeping up the pet.
  echoing,

  /// Amethyst's shards are in the air, and more are coming.
  volleying,

  /// Mossback's cups are up: showing, shuffling or waiting for a pick.
  shelling,

  /// Mossback's pebbles are popping up.
  popping,

  /// The pet is crossing Mossback's river.
  crossing,

  /// The witch's clones are in the air.
  cloning,

  /// The witch's tangle is falling apart, word by word.
  sorting,

  /// The pet is chasing the witch through her gates.
  chasing,

  /// Lanternmaw's lantern is lit and its fish are swimming.
  luring,

  /// Lanternmaw's letter bubbles are rising.
  bubbling,

  /// Lanternmaw's school is swimming.
  shoaling,

  /// Sableth's riddle is asked, its door sealed, or its tablets out.
  riddling,
  dooring,
  tableting,

  /// Pyrewing is talking, holding its flames apart, burning its embers, or
  /// asleep on its hoard.
  parleying,
  linking,
  embering,
  hoarding,

  /// Amethyst's wall is up; Lanternmaw's school is out; Sableth's storm is
  /// blowing.
  veining,
  netting,
  storming,

  /// A spell, a broken hex, or the boss's attack is in the air, or its
  /// aftermath is playing.
  spellResolving,
}

/// Arena geometry for one layout, shared by the build and the clock.
class _Geo {
  _Geo(this.w, this.h, this.boss) {
    art = ArenaArt.of(boss.id);
    // The ledge is as deep as its own picture draws it, scaled with the rest
    // of the art; a boss with no art keeps the painted ledge's depth.
    ledgeH = art?.ledgeUnits == null
        ? paintedLedgeH
        : (art!.ledgeUnits! * art!.cell(w)).roundToDouble();
    bossW = min(w * 0.5, h * boss.heightShare * boss.aspect);
    bossH = bossW / boss.aspect;
    // A flyer's is only its bob and swoop, which WitchMotion scales up.
    jumpPx = (bossH * (boss.flies ? 0.12 : 0.3)).roundToDouble();
    bossLeft = ((w - bossW) / 2).roundToDouble();
    swayPx = boss.flies ? ((w - bossW) / 2 * 0.8).roundToDouble() : 0;
    // A flyer hovers up where the shout bubble would be: her rounds never
    // shout, and the space below her is what the scroll needs.
    bossTop = boss.flies
        ? (bubbleTop + jumpPx + 2).roundToDouble()
        : (bubbleTop + bubbleH + jumpPx + 2).roundToDouble();
    // The feet sink a little into the moss on the ledge. A flyer has no
    // ledge, but everything below is still laid out from where it would be.
    ledgeTop = (bossTop + bossH - 6).roundToDouble();
    final groundH = (h * 0.13).clamp(44.0, 90.0);
    groundTop = (h - groundH).roundToDouble();
    petBox = min(h * 0.19, 124.0).roundToDouble();
    laneW = w / BossTrialRules.wordsPerWave;
    tileW = laneW - 6;
    tileH = (laneW * 0.55).clamp(42.0, 60.0);
    fallTop = ledgeTop + ledgeH - 4;
    fallSpan = max(0.0, groundTop - petBox * 0.9 - tileH - fallTop);

    // The Spells round, top to bottom: the charge bar under the ledge, the
    // stones, the prompt, and the spell line just above the pet.
    chargeTop = ledgeTop + ledgeH + 8;
    stonesTop = chargeTop + chargeH + 14;
    var line = groundTop - petBox * 0.95 - 8 - spellLineH;
    var prompt = line - 8 - promptH;
    if (prompt - 10 - stonesTop < WordStone.height + 16) {
      // A squat screen, an iPhone SE: stacked over the pet, the prompt would
      // sit on the stones. The spell line goes down into the ground under
      // the pet's feet instead, and the prompt takes its place.
      line = min(groundTop + 16, h - spellLineH - 2);
      prompt = groundTop - petBox * 0.95 - 8 - promptH;
    }
    spellLineTop = line;
    promptTop = prompt;
    stonesBottom = max(stonesTop + WordStone.height, promptTop - 10);

    // Amethyst's spikes hang their plates from the underside of the ledge,
    // and their shafts grow from the plates in toward the pet. Its gems lie
    // in the grass under the pet's feet, which leaves the spikes the whole
    // height.
    spikeTop = ledgeTop + ledgeH - 6;
    spikePlateH = (tileH * 0.8).roundToDouble();
    final feet = groundTop + petBox * 0.1 + 4;
    final room = max(0.0, h - 4 - feet);
    gemH = min(40.0, room).roundToDouble();
    gemTop = (feet + (room - gemH) / 2).roundToDouble();

    // Its echo's three crystals, stacked where the rubble would fall.
    final echoFrom = fallTop + 6;
    final echoTo = groundTop - petBox * 0.95 - 10;
    echoH = min(48.0, (echoTo - echoFrom - 2 * echoGap) / 3).floorToDouble();
    echoTop = echoFrom +
        ((echoTo - echoFrom - 3 * echoH - 2 * echoGap) / 2).roundToDouble();
  }

  late final double spikeTop, spikePlateH;
  late final double gemTop, gemH, echoTop, echoH;
  static const double echoGap = 8;

  /// The plate spike [lane] hangs from, just under the ledge. It never moves.
  Rect spikePlate(int lane) => Rect.fromLTWH(
        (laneCentre(lane) - tileW / 2).roundToDouble(),
        spikeTop + 8,
        tileW,
        spikePlateH,
      );

  /// Where spike [lane]'s shaft grows from: the middle of its plate's foot.
  Offset spikeRoot(int lane) =>
      Offset(laneCentre(lane), spikeTop + 8 + spikePlateH - 4);

  /// Where spike [lane] strikes: a crown round the pet where it stands in the
  /// middle, the outer lanes at its sides and the inner ones over its head,
  /// so every spike closes on the pet and none on the empty grass beside it.
  ///
  /// Round the body as drawn, which sits low in its box: the sprites leave
  /// the top of it empty.
  Offset spikeTarget(int lane) {
    const angles = [-155.0, -115.0, -65.0, -25.0];
    final a = angles[lane.clamp(0, angles.length - 1)] * pi / 180;
    final r = petBox * 0.36;
    return Offset(w / 2 + r * cos(a), groundTop - petBox * 0.3 + r * sin(a));
  }

  /// Spike [lane]'s point, [growth] of the way from its plate to the pet, in
  /// whole cells so it grows a step at a time.
  Offset spikeTip(int lane, double growth) {
    final at = Offset.lerp(
        spikeRoot(lane), spikeTarget(lane), growth.clamp(0.0, 1.0))!;
    return Offset(
      (at.dx / 4).roundToDouble() * 4,
      max(spikeRoot(lane).dy + 8, (at.dy / 4).roundToDouble() * 4),
    );
  }

  Rect gemRect(int lane) => Rect.fromLTWH(
        (laneCentre(lane) - tileW / 2).roundToDouble(),
        gemTop,
        tileW,
        gemH,
      );

  Rect echoRect(int i) => Rect.fromLTWH(
        spellInset,
        echoTop + i * (echoH + echoGap),
        w - 2 * spellInset,
        echoH,
      );

  static const double chargeH = 14;
  static const double spellLineH = 46;
  static const double promptH = 52;
  static const double spellInset = 16;

  late final double chargeTop, spellLineTop, promptTop, stonesTop, stonesBottom;

  double get chargeW => min(w * 0.6, 260);

  /// Where the pet holds a finished spell before letting it go.
  Offset petHead(double petX) => Offset(petX, groundTop - petBox * 0.9);

  static const double bubbleTop = 8;
  static const double bubbleH = 58;
  static const double bubbleInset = 16;
  /// What [LedgePainter] draws, for a boss whose arena has no art.
  static const double paintedLedgeH = 22;

  final double w, h;
  final TrialBoss boss;

  /// The scenery this arena is drawn in, or null for a boss with no art yet.
  late final ArenaArt? art;
  late final double ledgeH;
  late final double bossW, bossH, jumpPx, bossLeft, bossTop, ledgeTop;

  /// How far a flyer goes either side of the middle.
  late final double swayPx;
  late final double groundTop, petBox, laneW, tileW, tileH, fallTop, fallSpan;

  double laneCentre(int lane) => (lane + 0.5) * laneW;

  Rect tileRect(int lane, double fall) => Rect.fromLTWH(
        (laneCentre(lane) - tileW / 2).roundToDouble(),
        (fallTop + fallSpan * fall).roundToDouble(),
        tileW,
        tileH,
      );

  Offset get leftFoot => Offset(bossLeft + bossW * 0.1, ledgeTop + 4);
  Offset get rightFoot => Offset(bossLeft + bossW * 0.9, ledgeTop + 4);

  /// Debris is sized to the boss as drawn.
  double get debrisScale => (bossW / 200).clamp(0.6, 1.6);
}

class _Popup {
  _Popup(this.text, this.color, this.at);
  final String text;
  final Color color;
  final Offset at;
  double age = 0;
}

/// The right piece on its way back: it drops to the pet, which has run under
/// it, catches it, winds up and throws it up at the boss.
class _Throw {
  _Throw({
    required this.from,
    required this.lane,
    required this.earliness,
    required this.dropSeconds,
    required this.fallFrom,
    required this.fallTo,
  });

  /// Where the rubble was when it was picked.
  final Offset from;
  final int lane;
  final double earliness;

  /// Seconds for it to drop to the pet's hands: as long as the pet needs to
  /// run under it. Every other piece falls just as long, down to the ground.
  final double dropSeconds;

  /// How far the wave had fallen when the piece was picked, and how far it
  /// has to go for a piece to be on the ground, in the wave's own 0 to 1 (a
  /// little over 1: the ground is below the pet's head, where a piece that
  /// lands is stopped).
  final double fallFrom;
  final double fallTo;
  double t = 0;

  /// How far the whole wave has fallen now: the rest plunge to the ground as
  /// the picked piece drops on the pet, speeding up as they go.
  double get fallProgress {
    final k = min(1.0, t / dropSeconds);
    return fallFrom + (fallTo - fallFrom) * k * k;
  }

  /// Whether it has reached the pet yet.
  bool caught = false;

  /// When, in [t], it left the pet's hands, and from where; null while held.
  double? releasedAt;
  Offset releaseFrom = Offset.zero;
}

/// A finished spell on its way to the boss, or the boss's boulder on its way
/// to the pet.
class _Flight {
  _Flight({required this.from, required this.quickness, this.label});

  /// A word the pet has swatted back at the boss, flying instead of a bolt.
  final String? label;

  /// Where it set off from.
  final Offset from;

  /// For a spell: how much of the boss's charge was left when it was cast.
  final double quickness;
  double t = 0;
}

/// Something the pet throws at Amethyst: a gem that broke a spike, the echo
/// crystal it said, or a shard. Several can be in the air at once.
class _Shot {
  _Shot({
    required this.from,
    required this.earliness,
    this.whole = false,
    this.look = _ShotLook.crystal,
    this.to,
    this.bank,
    this.seconds,
    this.onLand,
    this.onHit,
    this.delay = 0,
    this.big = false,
  });

  final Offset from;
  final double earliness;

  /// A big spell: drawn larger, and it hits harder on the eye.
  final bool big;

  /// Seconds before it leaves [from] — unseen until then — for a throw the pet
  /// is still winding up. The game does not wait on the pet's body: the shot
  /// goes on schedule, and the pet's move is timed to match it.
  final double delay;

  /// What happens when it lands, when that is not a hit on the boss: Mossback's
  /// wrong cup, whose stone is sent at the pet.
  final void Function(_Geo geo)? onLand;

  /// Called once it has hit the boss, as well as the damage: the Shoal's stray
  /// rebounding off the belly it rammed.
  final void Function(_Geo geo)? onHit;

  /// How long it takes to land, when that is not a throw's [_throwSeconds]:
  /// the pet's headbutt, which lands at the top of its leap.
  final double? seconds;

  /// The whole of an attack's answer, worth a catch — the echo crystal — and
  /// not one of many small ones.
  final bool whole;

  final _ShotLook look;

  /// Where it is going, when that is not the boss where it stands: the witch
  /// as one of her clones.
  final Offset? to;

  /// Mossback's river crossed: the earliness of every hop, landing at once.
  final List<double>? bank;
  double t = 0;
}

/// What a shot looks like on its way.
enum _ShotLook {
  /// Amethyst's crystal.
  crystal,

  /// One of the pet's gems, in rune light.
  gem,

  /// A piece of Mossback's stone.
  rock,

  /// A bolt of the pet's own magic.
  spell,

  /// An ember the pet has caught, flung back: Pyrewing's fireball.
  ember,

  /// Nothing in the air: the pet itself is the shot, headbutting the boss.
  butt,

  /// Nothing in the air: a fish the pet has hit is the shot, swimming at the
  /// boss and ramming it.
  fish,
}

/// One of Amethyst's shards in the air, falling in [lane].
class _Shard {
  _Shard({required this.shard, required this.lane, required this.from});

  final VolleyShard shard;
  final int lane;

  /// Its mouth, when it was hurled.
  final Offset from;
  double t = 0;
}

class _BossTrialScreenState extends State<BossTrialScreen>
    with SingleTickerProviderStateMixin {
  static const Color _ink = AppTheme.retroDark;
  static const Color _gold = AppTheme.retroAccent;
  static const Color _hurtRed = AppTheme.retroPrimary;
  static const Color _right = Color(0xFF6DC2CA);
  static const Color _muted = Color(0xFF8595A1);

  /// The least seconds for the picked piece to drop onto the pet, and every
  /// other piece to the ground: long enough to watch them plunge. The pet has
  /// to run under the picked one first, so it may take longer.
  static const double _dropSeconds = 0.55;

  /// Seconds the pet holds the piece, winding up, before it throws.
  static const double _windUpSeconds = 0.45;

  /// Seconds for the thrown piece to reach the boss.
  static const double _throwSeconds = 0.34;

  /// How fast the pet runs for a piece, in screen widths a second.
  static const double _runWidths = 1.6;

  /// How far up the top of the pet's head is from its feet, as a fraction of
  /// its size (the rest of its box is air over the ears, and a little under
  /// the feet).
  static const double _headHeight = 0.65;

  /// The weight of the right piece landing on the pet: it is pressed flat for
  /// this long, before it winds up.
  static const double _squishSeconds = 0.4;

  /// The freeze on impact — every moving thing holds for this long.
  static const double _hitStopSeconds = 0.07;

  /// The pause after a wrong pick or a landed wave before the next gap.
  static const double _aftermathSeconds = 0.45;

  /// Seconds for a spell to reach the boss.
  static const double _boltSeconds = 0.3;

  /// Seconds for the boss's boulder to come down on the pet.
  static const double _boulderSeconds = 0.5;

  /// How long the roar into the Spells round holds the stage.
  static const double _announceSeconds = 2.0;

  /// How long a refused stone flashes.
  static const double _fizzleFlashSeconds = 0.25;

  /// How long a scroll whose hex went off stays up, showing which word it
  /// was, before the next spell.
  static const double _hexAftermathSeconds = 1.3;

  /// How long a hexed pet stays a frog.
  static const double _frogSeconds = 1.6;

  /// How long a pet stays sealed in amethyst.
  static const double _encaseSeconds = 1.6;

  /// How long a pet stays trapped in Lanternmaw's bubble, and how much of that
  /// the bubble takes to swell round it.
  static const double _bubbleSeconds = 1.6;
  static const double _bubbleForms = 0.3;

  /// How long a pet stays buried in Sableth's sand, or scorched grey.
  static const double _curseSeconds = 1.6;

  /// How much of that it takes for the sand to heap over the pet, or the heat
  /// to take it.
  static const double _curseForms = 0.4;

  /// The last stretch of it, in which the pet gets free: digging itself out of
  /// the sand, shaking the ash off.
  static const double _shedSeconds = 1.0;

  /// Lanternmaw's lantern on its sprite: its middle, and how wide it is, as
  /// fractions of the sprite (from `art_src/gen_anglerfish.py`).
  static const double _lanternX = 121 / 134;
  static const double _lanternY = 26.5 / 100;
  static const double _lanternSize = 22 / 134;

  late final Ticker _ticker = createTicker(_onTick);
  final Random _rng = Random();
  final TrialParticles _particles = TrialParticles();

  /// Bumped every frame, so only the arena rebuilds at frame rate.
  final ValueNotifier<int> _frame = ValueNotifier(0);

  String? _languageCode;
  String? _nativeCode;
  late final String _petType;
  late TrialBoss _boss = widget.boss;
  List<TrialWord> _pool = const [];
  int _ownWordCount = 0;

  /// The player's own pair, as "EN → EN", when it had nothing to fight with
  /// and a stock pair is standing in for it.
  String? _ownPair;

  /// Testing affordance: fighting with the advanced English set instead of
  /// the player's own pair.
  bool _advanced = false;

  _Phase _phase = _Phase.ready;
  /// The run under way — or, on the intro, the one the level would start.
  late TrialRun _run = _plan.start();

  /// Which of the boss's levels is being fought: its openings one each,
  /// then its finale. Chosen on the climb map, or by the intro's picker where
  /// there is one.
  late int _step = widget.step;

  /// The round of the fight under way, in [_plan].
  int _round = 0;

  /// Where the last run started, so "try again" repeats a spells practice
  /// rather than dropping the player back at round 1.
  int _startRound = 0;

  /// Time since the boss started getting away, at the end of a level that
  /// is not its finale.
  double? _fleeTime;

  // ---- the clock ----
  Duration _lastElapsed = Duration.zero;
  double _time = 0;
  double _freeze = 0;
  double _shake = 0;
  double _hurtTint = 0;
  double? _endIn;
  _Geo? _geo;

  // ---- the wave ----
  _Stage _stage = _Stage.gap;
  double _stageTime = 0;
  double _gapSeconds = 0.5;
  TrialWave? _wave;
  TrialWord? _lastPrompt;
  double _fall = 0;
  double _readSeconds = 5;
  bool _shouting = false;
  bool _rubbleVisible = false;
  _Throw? _throw;

  // ---- the Spells round ----
  List<TrialSentence> _sentences = const [];

  /// The last round whose roar has been heard.
  int _announcedRound = 0;
  bool _announceLanded = false;
  _Flight? _bolt;
  _Flight? _boulder;
  int? _fizzleStone;
  double _fizzleFlash = 0;

  // ---- the Hexed Scroll ----
  HexRead? _read;
  TrialSentence? _lastScroll;
  double _fuse = 0;
  double _fuseSeconds = 6;

  /// The fuse ran out: the hexed word is shown for what it was.
  bool _hexRevealed = false;

  /// The rounds of the level being fought.
  TrialPlan get _plan => TrialPlan.forStep(_step,
      openingHp: [for (final o in _boss.openings) o.hp]);

  TrialRound get _roundPlan => _plan.rounds[min(_round, _plan.lastRound)];

  /// The boss's patience as this round's clocks read it: fresh at the start
  /// of every round, tightest at its end, however long it is.
  int get _clockPatience =>
      _plan.clockPatience(min(_round, _plan.lastRound), _run.patience);

  /// The opening a round is fought with.
  TrialOpening _openingOf(TrialRound round) => _boss.openings[round.opening];

  /// The level of the game being fought, 1 to 30.
  int get _levelNumber =>
      _boss.level - (BossTrialRules.levelsPerBoss - 1) + _step;

  /// Whether any of the level's rounds has English and Turkish content only.
  bool get _needsEnTr =>
      _plan.rounds.any((r) => _openingOf(r).opener.needsEnTr);

  // ---- Amethyst ----
  /// Gems and crystals on their way to the boss.
  final List<_Shot> _shots = [];

  SpikeRush? _spikes;
  List<TrialWord> _lastSpikeWords = const [];

  /// How far down each lane's spike has grown, and how long it takes to get
  /// all the way.
  List<double> _spikeGrowth = const [];
  List<double> _spikeSeconds = const [];

  /// The spike and gem of a wrong pair, while they flash.
  int? _flashLane;
  int? _flashGem;

  EchoListen? _echo;
  TrialSentence? _lastEcho;

  /// How far the amethyst has crept up the pet, and how long it takes.
  double _creep = 0;
  double _echoSeconds = 6;

  /// The amethyst closed: the crystal it said is shown for what it was.
  bool _echoRevealed = false;

  /// The right crystal has been picked and stays up, lit, while the pet jumps
  /// at it; it bursts when the pet's head hits it.
  bool _crystalHeld = false;

  ShardVolley? _volley;
  final List<_Shard> _inFlight = [];

  /// The next shard to hurl, and the time since the last one.
  int _volleyNext = 0;
  double _volleyClock = 0;
  double _shardSeconds = 3;
  double _shardInterval = 1.2;
  int _lastShardLane = -1;

  // ---- the boss ----
  /// Time into the boss's move: Mossback's jump, or the witch's swoop.
  double? _jumpTime;
  double? _bossHitTime;

  /// The witch's mouth open as she throws something.
  double? _cackleTime;

  /// Which side a flyer is on (-1 left, 1 right, 0 the middle before her
  /// first swoop), and the side her current swoop set off from.
  double _side = 0;
  double _swoopFrom = 0;

  // ---- Mossback's and the witch's openers under test ----
  _ShellRound? _shell;
  _PebbleRound? _pebbles;
  _CrossingRound? _crossing;

  /// The stones of a crossing just over, sinking back under the river, and
  /// seconds into doing so. The river stays; only they go.
  _CrossingRound? _leaving;
  double _leavingT = 0;
  _CloneRound? _clones;
  _TangleRound? _tangle;
  _ChaseRound? _chase;

  // ---- Lanternmaw's, Sableth's and Pyrewing's openers under test ----
  _LureRound? _lure;
  _BubbleRound? _bubbles;
  _ShoalRound? _shoal;

  /// The Shoal's stray, rebounding off the boss it rammed. It outlives the
  /// round, which a killing blow clears.
  _FishBounce? _fishBounce;
  _RiddleRound? _riddle;
  _DoorRound? _door;
  _TabletRound? _tablets;
  _ParleyRound? _parley;
  _LinkRound? _link;
  _EmberRound? _embers;
  _HoardRound? _hoard;
  _VeinRound? _vein;
  _NetRound? _net;
  _StormRound? _storm;

  /// Their English and Turkish content, when the run is in that pair.
  EnTrContent? _enTr;

  /// The player's own pair, as "ES → EN", when an opener with English and
  /// Turkish content only is standing it in.
  String? _standIn;

  /// What the last of their rounds asked — a riddle, a door, a stray — so
  /// the next never asks it again straight away.
  Object? _lastAsked;

  /// [_lastAsked], when it is something a round of type [T] asks. A finale
  /// runs one opening after another through it, so the next round finds
  /// the last one's riddle or script there, and that is no repeat of its.
  T? _lastAs<T>() {
    final last = _lastAsked;
    return last is T ? last : null;
  }

  /// The aftermath holds long enough to read what the answer was.
  bool _holdAftermath = false;

  // ---- the pet ----
  int? _petLane;
  double _petX = 0;
  double _petAway = 0;
  double _petHop = -1;
  double _petHurt = -1;

  /// Seconds left as a frog, after the witch's hex landed.
  double _frog = 0;

  /// Seconds left sealed in amethyst, after something of Amethyst's got
  /// through.
  double _encased = 0;

  /// Seconds left trapped in a bubble, after something of Lanternmaw's got
  /// through, and how high the water had drawn the pet when it was.
  double _bubbled = 0;
  double _bubbleFrom = 0;

  /// How much of the sand, or of the heat, the pet had already taken from the
  /// round's clock when the curse landed, so the curse builds on it.
  double _buriedFrom = 0;
  double _scorchFrom = 0;

  /// Seconds left buried in sand, or scorched grey, after something of
  /// Sableth's or Pyrewing's got through.
  double _buried = 0;
  double _scorched = 0;

  /// Where the pet's feet should be when not on the ground — a stepping
  /// stone, a broom in the air — and where they are, easing toward it.
  Offset? _perch;
  double? _petFeet;

  /// The pet drawn smaller: on a stone, or on a broom.
  double _petScale = 1;

  /// The pet faces left rather than right, which is how its art is drawn:
  /// turned toward the stone it hops to, and toward the boss to headbutt it.
  bool _petFacesLeft = false;

  /// The pet rides a broom.
  bool _onBroom = false;

  /// The pet is hopping off its broom: the broom is gone, but the pet is still
  /// up where it was until it has come down.
  bool _hoppingOff = false;

  /// How far the pet has sunk into Mossback's river, 0 to 1.
  double _petDunk = 0;

  /// Seconds into the small hop the pet makes coming up out of the river onto
  /// the bank, or -1 while it is not hopping.
  double _petSpring = -1;
  static const double _springSeconds = 0.5;

  /// What the pet's body is doing now, when it is doing something with it: a
  /// headbutt, a pounce, a throw, a cast, being flattened. See
  /// `boss_trial_pet_moves.dart`.
  _PetMove? _move;

  /// The pet is running for a piece of rubble, at a steady pace and with a hop
  /// to each stride, rather than easing there; and whether it moved this
  /// frame, and how far it has run, for the stride.
  bool _petRunning = false;

  /// How fast it runs, in widths of the arena a second: a hop-walk with
  /// something on its head is slower than the run at a thrown stone.
  double _petPace = _runWidths;

  /// How high the hop to every stride of its run is, in pixels: small and
  /// quiet for a tiptoe, high for a hop-walk.
  double _petHopPx = 10;

  /// How far round the pet's wobble has gone, in radians: it wobbles faster
  /// as the scroll's fuse burns.
  double _wobblePhase = 0;

  /// Whether the pet's swat has hit the hexed word yet: it stays on the scroll
  /// till it does.
  bool _wordSwatted = false;

  /// How far round the pet's shiver has gone, in radians: slower as the
  /// amethyst climbs it.
  double _shiverPhase = 0;

  /// The sand or ash it flings off as it frees itself: when it next does, and
  /// from which side.
  double _shedTick = 0;
  double _shedSide = 1;

  /// Spikes the pet is leaping at, by lane: the game time ([_time]) at which
  /// each breaks. Until then it stands, though the match is made.
  final Map<int, double> _spikeBreakAt = {};

  /// What the pet holds up over its head — a gem it scooped, a shard it
  /// caught — from when to when ([_time]).
  double _heldFrom = double.infinity;
  double _heldUntil = -1;
  bool _heldGem = true;

  /// Seconds the soot a wrong ember left on its whiskers has left to show.
  double _singed = 0;
  static const double _singeSeconds = 1.6;
  bool _petMoving = false;
  double _petStride = 0;

  /// Somewhere other than a lane the pet is running to — a gem, a coin, a
  /// cauldron — until [_petAway] runs out and it goes home.
  double? _petGoX;

  /// The witch's scroll and Sableth's door as they are drawn, to find the
  /// edge the pet leaps at.
  final GlobalKey _scrollKey = GlobalKey(debugLabel: 'witch-scroll');
  final GlobalKey _doorKey = GlobalKey(debugLabel: 'sealed-door');

  final List<_Popup> _popups = [];

  bool get _reduceMotion => MediaQuery.disableAnimationsOf(context);

  static Duration _dur(double seconds) =>
      Duration(microseconds: (seconds * 1e6).round());

  static double _secs(Duration d) => d.inMicroseconds / 1e6;

  /// [setState], for the rounds in this screen's part files.
  void _refresh([VoidCallback? change]) => setState(() => change?.call());

  @override
  void initState() {
    super.initState();
    _petType = context.read<CharacterProvider>().currentCharacterType;
    _loadContent();
    // Always running: the boss breathes behind the intro panel too.
    _ticker.start();
  }

  /// The words and sentences to fight with: the advanced English set, or the
  /// player's own pair topped up with stock.
  void _loadContent() {
    _ownPair = null;
    _standIn = null;
    _enTr = null;
    if (_advanced) {
      _languageCode = 'en';
      _nativeCode = 'en';
      _pool = TrialWordPool.build(
        items: const [],
        languageCode: 'en',
        stock: advancedEnglishWords,
      );
      _sentences = TrialSentencePool.build(advancedEnglishSentences);
      _ownWordCount = 0;
      return;
    }
    final languages = context.read<LanguageProvider>();
    var target = languages.targetLanguage?.code;
    var native = languages.nativeLanguage.code;
    final items = context.read<VocabProvider>().items;
    // An opener with English and Turkish content only fights in that pair,
    // whatever the player's is — and so does a finale with one in it, rather
    // than changing language between rounds.
    if (_needsEnTr && !isEnTrPair(target, native)) {
      _standIn = '${target?.toUpperCase() ?? 'none'} → ${native.toUpperCase()}';
      (target, native) = enTrStandIn(target);
    }
    // Every boss needs words or sentences to fight with, and the intro can
    // switch between them, so the pair fought in is the first that has both
    // — the player's own, unless it cannot: no language chosen, or the same
    // one on both sides. Then a stock pair stands in, and the intro says so,
    // rather than the trial refusing to start.
    for (final (t, n) in bossTrialFallbackPairs(target, native)) {
      _languageCode = t;
      _nativeCode = n;
      _pool = TrialWordPool.build(
        items: items,
        languageCode: t ?? '',
        stock: bossTrialStockWords(targetCode: t, nativeCode: n),
      );
      _sentences = TrialSentencePool.build(
        bossTrialStockSentences(targetCode: t, nativeCode: n),
      );
      if (TrialWordPool.isPlayable(_pool) && HexScroll.isPlayable(_sentences)) {
        break;
      }
    }
    if (_languageCode != target || _nativeCode != native) {
      _ownPair = '${target?.toUpperCase() ?? 'none'} → ${native.toUpperCase()}';
    }
    _enTr = EnTrContent.of(_languageCode, _nativeCode);
    _ownWordCount =
        TrialWordPool.build(items: items, languageCode: _languageCode ?? '')
            .length;
  }

  /// Switches the content between the player's pair and advanced English.
  void _pickAdvanced(bool advanced) {
    if (advanced == _advanced) return;
    setState(() {
      _advanced = advanced;
      _loadContent();
    });
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

    if (_freeze > 0) {
      _freeze -= dt;
      return;
    }

    _time += dt;
    _shake = max(0, _shake - dt);
    _hurtTint = max(0, _hurtTint - dt);
    _singed = max(0, _singed - dt);
    if (_stage == _Stage.reading && _read != null && !_reduceMotion) {
      _wobblePhase += dt * (9 + 30 * _fuse * _fuse);
    }
    _shiverPhase += dt * (_stage == _Stage.echoing ? 52 - 32 * _creep : 52);
    _fizzleFlash = max(0, _fizzleFlash - dt);
    _particles.update(dt, floor: geo.groundTop + 4);
    _stepPopups(dt);
    _stepFishBounce(dt);
    _stepPet(dt, geo);
    _stepBoss(dt, geo);
    if (_phase == _Phase.playing) {
      _stepShots(dt, geo);
      _animateMossRounds(dt, geo);
      _animateWitchRounds(dt, geo);
      _animateAnglerRounds(dt, geo);
      for (final round in <_ClockRound?>[
        _riddle, _door, _tablets, _storm, _parley, _link, _embers, _hoard,
        _vein, _net,
      ]) {
        round?.t += dt;
      }
      _stepSphinxFx(dt, geo);
      _stepDragonFx(dt, geo);
      _stepSpikeBreaks(geo);
      _stepWave(dt, geo);
    }

    final endIn = _endIn;
    if (endIn != null) {
      _endIn = endIn - dt;
      if (_endIn! <= 0) {
        _endIn = null;
        _finish();
      }
    }
    _frame.value++;
  }

  void _stepPopups(double dt) {
    for (final p in _popups) {
      p.age += dt;
    }
    _popups.removeWhere((p) => p.age > 0.9);
  }

  void _stepBoss(double dt, _Geo geo) {
    final flee = _fleeTime;
    if (flee != null && _dur(flee) < BossMotion.getawayEnds) {
      _fleeTime = flee + dt;
      if (_dur(flee) < BossMotion.launchAt &&
          _dur(flee + dt) >= BossMotion.launchAt) {
        _launchKick(geo);
      }
    }
    final jump = _jumpTime;
    if (jump != null) {
      _jumpTime = _dur(jump + dt) >= _moveEnds ? null : jump + dt;
    }
    final hit = _bossHitTime;
    if (hit != null) {
      _bossHitTime = _dur(hit + dt) >= BossMotion.flinch ? null : hit + dt;
    }
    final cackle = _cackleTime;
    if (cackle != null) {
      _cackleTime = _dur(cackle + dt) >= WitchMotion.cast ? null : cackle + dt;
    }
  }

  /// When the boss's mouth opens in its move.
  Duration get _shoutAt =>
      _boss.flies ? WitchMotion.castAt : BossMotion.shoutAt;

  /// When the move brings what it brings: Mossback's landing shakes the
  /// rubble loose; the witch arriving unrolls her scroll.
  Duration get _arriveAt =>
      _boss.flies ? WitchMotion.arriveAt : BossMotion.landAt;

  Duration get _moveEnds {
    if (_boss.flies) return WitchMotion.ends;
    final shoutEnds = BossMotion.shoutAt + BossMotion.shout;
    return shoutEnds > BossMotion.jumpEnds ? shoutEnds : BossMotion.jumpEnds;
  }

  void _stepPet(double dt, _Geo geo) {
    if (_petHop >= 0) _petHop = _petHop + dt > 0.3 ? -1 : _petHop + dt;
    if (_petHurt >= 0) _petHurt = _petHurt + dt > 0.35 ? -1 : _petHurt + dt;
    if (_frog > 0) {
      _frog -= dt;
      if (_frog <= 0) {
        _frog = 0;
        // Back to itself in a puff of the same smoke, and up with a hop.
        _puff(geo);
        _springUp(geo);
      }
    }
    if (_encased > 0) {
      _encased -= dt;
      if (_encased <= 0) {
        _encased = 0;
        // It breaks out, and stands up with a hop.
        if (!_reduceMotion) {
          _particles.shatter(_petRect(geo), colors: CrystalPalette.shards);
          _shake = max(_shake, 0.15);
        }
        _springUp(geo);
      }
    }
    if (_buried > 0) {
      _buried -= dt;
      if (_buried > 0 && _buried < _shedSeconds) _throwOff(geo, dt, sand: true);
      if (_buried <= 0) {
        _buried = 0;
        // It bursts out of the sand, shaking it off, and stands up with a hop.
        if (!_reduceMotion) {
          _particles.shatter(_petRect(geo), colors: SphinxPalette.dust);
          _shake = max(_shake, 0.15);
        }
        _springUp(geo);
      }
    }
    if (_scorched > 0) {
      _scorched -= dt;
      if (_scorched > 0 && _scorched < _shedSeconds) {
        _throwOff(geo, dt, sand: false);
      }
      if (_scorched <= 0) {
        _scorched = 0;
        // It shakes the ash off in a cloud of smoke, and stands up with a hop.
        if (!_reduceMotion) {
          _particles.sparks(_petRect(geo).center,
              count: 16, colors: DragonPalette.smoke);
          _shake = max(_shake, 0.15);
        }
        _springUp(geo);
      }
    }
    if (_bubbled > 0) {
      // It pops, and the pet falls out of it, from as high as it had floated.
      final lifted = _bubbleLift(_petSize(geo));
      _bubbled -= dt;
      if (_bubbled <= 0) {
        _bubbled = 0;
        _popBubble(geo, lifted);
      }
    }
    if (_petAway > 0) {
      _petAway -= dt;
      if (_petAway <= 0) {
        _petLane = null;
        _petGoX = null;
        _petPace = _runWidths;
        _petHopPx = 10;
        // Back to the middle, facing the way it runs.
        if (_petRunning) _faceToward(geo.w / 2, from: _petX);
      }
    }
    final perch = _perch;
    final target = perch?.dx ??
        _petGoX ??
        (_petLane == null ? geo.w / 2 : geo.laneCentre(_petLane!));
    _petMoving = false;
    if (_petRunning) {
      // A steady run, a hop to every stride.
      final gap = target - _petX;
      final step = geo.w * _petPace * dt;
      final moved = min(gap.abs(), step);
      _petMoving = moved > 0;
      _petStride += moved;
      _petX += gap.sign * moved;
      if (_petLane == null && _petGoX == null && gap.abs() <= step) {
        // Home: it stands as it does at the start of any phase.
        _petRunning = false;
        _petMoving = false;
        _petStride = 0;
        if (_move == null) _petFacesLeft = false;
      }
    } else {
      _petX += (target - _petX) * min(1.0, dt * 18);
    }
    final feet = _petFeet;
    if (perch != null) {
      final from = feet ?? geo.groundTop;
      _petFeet = from + (perch.dy - from) * min(1.0, dt * 18);
    } else if (feet != null) {
      final next = feet + (geo.groundTop - feet) * min(1.0, dt * 18);
      _petFeet = (next - geo.groundTop).abs() < 1 ? null : next;
    }
  }

  void _stepWave(double dt, _Geo geo) {
    _stageTime += dt;
    switch (_stage) {
      case _Stage.gap:
        if (_endIn == null && _stageTime >= _gapSeconds) _next();
      case _Stage.jumping:
        final t = _dur(_stageTime);
        if (!_shouting && t >= _shoutAt) {
          _shouting = true;
        }
        if (t >= _arriveAt) _arrive(geo);
      case _Stage.reading:
        _fuse = min(1.0, _fuse + dt / _fuseSeconds);
        if (_fuse >= 1) _hexFires(geo);
      case _Stage.falling:
        _fall = min(1.0, _fall + dt / _readSeconds);
        if (_fall >= 1) _letLand(geo);
      case _Stage.spiking:
        _stepSpikes(dt, geo);
      case _Stage.echoing:
        _creep = min(1.0, _creep + dt / _echoSeconds);
        if (_creep >= 1) _echoSeals(geo);
      case _Stage.volleying:
        _stepVolley(dt, geo);
      case _Stage.shelling:
        _stepShell(geo);
      case _Stage.popping:
        _stepPebbles(dt, geo);
      case _Stage.crossing:
        _stepCrossing(dt, geo);
      case _Stage.cloning:
        _stepClones(dt, geo);
      case _Stage.sorting:
        _stepTangle(dt, geo);
      case _Stage.chasing:
        _stepChase(dt, geo);
      case _Stage.luring:
        _stepLure(dt, geo);
      case _Stage.bubbling:
        _stepBubbles(dt, geo);
      case _Stage.shoaling:
        _stepShoal(dt, geo);
      case _Stage.riddling:
      case _Stage.dooring:
      case _Stage.tableting:
      case _Stage.storming:
        _stepSphinxRound(dt, geo);
      case _Stage.parleying:
      case _Stage.linking:
      case _Stage.embering:
      case _Stage.hoarding:
        _stepDragonRound(dt, geo);
      case _Stage.veining:
      case _Stage.netting:
        final _ClockRound? round = _vein ?? _net;
        if (round != null && !round.over) {
          round.clock = min(1.0, round.clock + dt / round.seconds);
          if (round.clock >= 1) {
            _timedOut(geo, round, switch (round) {
              _VeinRound r => r.wave.sentence,
              _NetRound r => r.wave.sentence,
              _ => throw StateError('no sentence'),
            });
          }
        }
      case _Stage.resolving:
        final thrown = _throw;
        if (thrown != null) {
          thrown.t += dt;
          if (!thrown.caught && thrown.t >= thrown.dropSeconds) {
            // The pet has it: it winds up, and throws.
            thrown.caught = true;
            _catchAndThrow(geo, thrown);
          }
          final released = thrown.releasedAt;
          if (released != null && thrown.t >= released + _throwSeconds) {
            _impact(geo, thrown);
          }
        } else if (_endIn == null &&
            _shots.isEmpty &&
            _move == null &&
            _stageTime >=
                (_echoRevealed || _holdAftermath
                    ? _hexAftermathSeconds
                    : _aftermathSeconds)) {
          _toGap();
        }
      case _Stage.announcing:
        if (!_announceLanded && _dur(_stageTime) >= _arriveAt) {
          _announceLanded = true;
          _landingShock(geo);
        }
        if (_stageTime >= _announceSeconds) {
          setState(() {
            _announcedRound = _round;
            _stage = _Stage.gap;
            _stageTime = 0;
            _gapSeconds = 0.2;
          });
        }
      case _Stage.spellResolving:
        final bolt = _bolt;
        final boulder = _boulder;
        if (bolt != null) {
          bolt.t += dt;
          if (!_reduceMotion) {
            _particles.sparks(_boltAt(geo, bolt), count: 2);
          }
          if (bolt.t >= _boltSeconds) _spellImpact(geo, bolt);
        } else if (boulder != null) {
          boulder.t += dt;
          if (_read != null && !_reduceMotion) {
            // A hex trails her sparks.
            _particles.sparks(_boulderAt(geo, boulder),
                count: 2, colors: HexPalette.sparks);
          }
          if (boulder.t >= _boulderSeconds) _boulderLands(geo);
        } else if (_endIn == null &&
            _move == null &&
            _stageTime >=
                (_hexRevealed ? _hexAftermathSeconds : _aftermathSeconds)) {
          _toGap();
        }
    }
  }

  // ---------------------------------------------------------------- flow --

  /// Starts a run at [round] of the level — its first for a real fight, or a
  /// finale's last to go straight to practising spells, which roars in as a
  /// round after the first does.
  void _start({int round = 0}) {
    _particles.clear();
    setState(() {
      _startRound = round;
      _round = round;
      _run = _plan.start(round: round);
      _firstClear = const [];
      _fleeTime = null;
      _wave = null;
      _lastPrompt = null;
      _throw = null;
      _shouting = false;
      _rubbleVisible = false;
      _announcedRound = round == 0 ? 0 : round - 1;
      _bolt = null;
      _boulder = null;
      _read = null;
      _lastScroll = null;
      _fuse = 0;
      _hexRevealed = false;
      _frog = 0;
      _encased = 0;
      _bubbled = 0;
      _buried = 0;
      _scorched = 0;
      _lastAsked = null;
      _shots.clear();
      _spikes = null;
      _lastSpikeWords = const [];
      _echo = null;
      _lastEcho = null;
      _creep = 0;
      _echoRevealed = false;
      _crystalHeld = false;
      _volley = null;
      _inFlight.clear();
      _move = null;
      _petRunning = false;
      _petGoX = null;
      _petSpring = -1;
      _clearMossRounds();
      _leaving = null;
      _clearWitchRounds();
      _clearAnglerRounds();
      _clearSphinxRounds();
      _clearDragonRounds();
      _vein = null;
      _holdAftermath = false;
      _petLane = null;
      _popups.clear();
      _endIn = null;
      _stage = _Stage.gap;
      _stageTime = 0;
      _gapSeconds = 0.5;
      _phase = _Phase.playing;
    });
  }

  /// Switches the intro to another boss.
  void _pickBoss(TrialBoss boss) {
    if (boss == _boss) return;
    _particles.clear();
    setState(() {
      _boss = boss;
      _step = 0;
      _round = 0;
      _run = _plan.start();
      _fleeTime = null;
      // The advanced set is only offered where openings are being tried, and
      // an opening with English and Turkish content only may change the
      // pair.
      _advanced = false;
      _loadContent();
      _side = 0;
      _swoopFrom = 0;
      _jumpTime = null;
      _cackleTime = null;
    });
  }

  /// Testing affordance: which of the boss's levels to fight.
  void _pickStep(int step) {
    if (step == _step) return;
    setState(() {
      final before = _needsEnTr;
      _step = step;
      _round = 0;
      _run = _plan.start();
      _fleeTime = null;
      if (_needsEnTr != before) _loadContent();
    });
  }

  /// Starts the boss's move: Mossback's jump, or a swoop across to the
  /// witch's other side.
  void _startMove() {
    _jumpTime = 0;
    if (_boss.flies) {
      _swoopFrom = _side;
      _side = _side > 0 ? -1 : 1;
    }
  }

  void _throwWave() {
    final wave = TrialWave.build(_pool, previous: _lastPrompt, random: _rng);
    if (wave == null) {
      _finish();
      return;
    }
    setState(() {
      _wave = wave;
      _lastPrompt = wave.prompt;
      _fall = 0;
      // Fixed at the throw, so a wave never speeds up mid-fall.
      _readSeconds =
          BossTrialRules.readTime(_clockPatience).inMicroseconds / 1e6;
      _stage = _Stage.jumping;
      _stageTime = 0;
      _startMove();
      _shouting = false;
      _rubbleVisible = false;
    });
  }

  void _land(_Geo geo) {
    _stage = _Stage.falling;
    _stageTime = 0;
    _rubbleVisible = true;
    _landingShock(geo);
  }

  /// The boss hitting the ledge: a thud, debris out to both sides, pebbles
  /// down the edges. The witch never lands; she arrives in a burst of her
  /// own sparks.
  void _landingShock(_Geo geo) {
    HapticFeedback.lightImpact();
    if (_reduceMotion) return;
    if (_boss.flies) {
      _particles.sparks(_bossHitPoint(geo), count: 12, colors: _flyerSparks);
      return;
    }
    _shake = 0.22;
    _particles.landing(
      left: geo.leftFoot,
      right: geo.rightFoot,
      scale: geo.debrisScale,
    );
    _particles.shakeLoose(width: geo.w, ledgeY: geo.ledgeTop + geo.ledgeH);
  }

  /// What a flyer throws off as it arrives and when it is hit: the witch's
  /// sparks, or Lanternmaw's bubbles.
  List<Color> get _flyerSparks =>
      _boss.bubblesPet ? AnglerPalette.bubbles : HexPalette.sparks;

  /// Whatever comes after a gap: in a finale, the next round once one is
  /// won, and a roar into each round after the first; then a wave of that
  /// round's opening.
  ///
  /// Falls back to waves when there are no sentences to play with, so a
  /// language without them still gets a whole fight rather than a stalled
  /// one.
  void _next() {
    if (_run.cleared && !_run.won && _round < _plan.lastRound) {
      setState(() {
        _round++;
        _run = _plan.enter(_run, _round);
      });
    }
    if (_round > _announcedRound) {
      _announce();
      return;
    }
    switch (_opener) {
      case TrialOpener.catchWords:
        _throwWave();
      case TrialOpener.crystalSpikes:
        _beginSpikes();
      case TrialOpener.crystalEcho:
        _beginEcho();
      case TrialOpener.shardVolley:
        _beginVolley();
      case TrialOpener.hexScroll:
        _beginScroll();
      case TrialOpener.shellGame:
        _beginShell();
      case TrialOpener.pebblePop:
        _beginPebbles();
      case TrialOpener.steppingStones:
        _beginCrossing();
      case TrialOpener.mirrorClones:
        _beginClones();
      case TrialOpener.tangledSpells:
        _beginTangle();
      case TrialOpener.broomChase:
        _beginChase();
      case TrialOpener.lure:
        _beginLure();
      case TrialOpener.letterBubbles:
        _beginBubbles();
      case TrialOpener.shoal:
        _beginShoal();
      case TrialOpener.riddle:
        _beginRiddle();
      case TrialOpener.sealedDoor:
        _beginDoor();
      case TrialOpener.tablets:
        _beginTablets();
      case TrialOpener.parley:
        _beginParley();
      case TrialOpener.flameLink:
        _beginLink();
      case TrialOpener.paraphrase:
        _beginEmbers();
      case TrialOpener.vein:
        _beginVein();
      case TrialOpener.net:
        _beginNet();
      case TrialOpener.sandstorm:
        _beginStorm();
      case TrialOpener.hoard:
        _beginHoard();
    }
  }

  /// What this round asks: its opening — unless it asks about sentences and
  /// this language has too few, when it falls back to Mossback's catch
  /// rather than stalling.
  TrialOpener get _opener {
    final opener = _openingOf(_roundPlan).opener;
    final playable = switch (opener) {
      TrialOpener.hexScroll => HexScroll.isPlayable(_sentences),
      TrialOpener.crystalEcho => EchoWave.isPlayable(_sentences),
      TrialOpener.mirrorClones => CloneWave.isPlayable(_sentences),
      TrialOpener.tangledSpells => TangleWave.isPlayable(_sentences),
      TrialOpener.broomChase => ChaseWave.isPlayable(_sentences),
      TrialOpener.lure => LureWave.isPlayable(_sentences),
      TrialOpener.letterBubbles => BubbleWave.isPlayable(_pool),
      TrialOpener.shoal => ShoalWave.isPlayable(_enTr?.categories ?? const {}),
      TrialOpener.riddle => RiddleWave.isPlayable(_enTr?.riddles ?? const []),
      TrialOpener.sealedDoor => DoorWave.isPlayable(_enTr?.doors ?? const []),
      TrialOpener.tablets => TabletWave.isPlayable(_enTr?.stories ?? const []),
      TrialOpener.parley =>
        ParleyWave.isPlayable(_enTr?.parleys ?? const []),
      TrialOpener.flameLink => LinkWave.isPlayable(_enTr?.links ?? const []),
      TrialOpener.paraphrase =>
        ParaphraseWave.isPlayable(_enTr?.paraphrases ?? const []),
      TrialOpener.vein => VeinWave.isPlayable(_sentences),
      TrialOpener.net => NetWave.isPlayable(_sentences),
      TrialOpener.sandstorm => StormWave.isPlayable(_pool),
      TrialOpener.hoard => HoardWave.isPlayable(_enTr?.phrases ?? const []),
      _ => true,
    };
    return playable ? opener : TrialOpener.catchWords;
  }

  /// The boss's move has arrived: what it brought appears.
  void _arrive(_Geo geo) {
    if (_read != null) {
      _unroll(geo);
    } else if (_spikes != null) {
      _raiseSpikes(geo);
    } else if (_echo != null) {
      _raiseEcho(geo);
    } else if (_volley != null) {
      _openVolley(geo);
    } else if (_shell != null) {
      _raiseShells(geo);
    } else if (_pebbles != null) {
      _openPebbles(geo);
    } else if (_crossing != null) {
      _openCrossing(geo);
    } else if (_clones != null) {
      _splitClones(geo);
    } else if (_tangle != null) {
      _openTangle(geo);
    } else if (_chase != null) {
      _openChase(geo);
    } else if (_lure != null) {
      _openLure(geo);
    } else if (_bubbles != null) {
      _openBubbles(geo);
    } else if (_shoal != null) {
      _openShoal(geo);
    } else if (_riddle != null) {
      _openClockRound(geo, _Stage.riddling);
    } else if (_door != null) {
      _openClockRound(geo, _Stage.dooring);
    } else if (_tablets != null) {
      _openClockRound(geo, _Stage.tableting);
    } else if (_parley != null) {
      _openClockRound(geo, _Stage.parleying);
    } else if (_link != null) {
      _openClockRound(geo, _Stage.linking);
    } else if (_embers != null) {
      _openClockRound(geo, _Stage.embering);
    } else if (_vein != null) {
      _openClockRound(geo, _Stage.veining);
    } else if (_net != null) {
      _openClockRound(geo, _Stage.netting);
    } else if (_storm != null) {
      _openClockRound(geo, _Stage.storming);
    } else if (_hoard != null) {
      _openClockRound(geo, _Stage.hoarding);
    } else {
      _land(geo);
    }
  }

  /// The witch swoops across and reads out a hexed spell; the scroll unrolls
  /// when she arrives.
  void _beginScroll() {
    final scroll =
        HexScroll.build(_sentences, previous: _lastScroll, random: _rng);
    if (scroll == null) {
      _throwWave();
      return;
    }
    setState(() {
      _read = HexRead(scroll);
      _lastScroll = scroll.sentence;
      _fuse = 0;
      // Fixed when the scroll is read, so a fuse never speeds up mid-burn.
      _fuseSeconds = BossTrialRules.fuseTime(
            words: scroll.words.length,
            patience: _clockPatience,
          ).inMicroseconds /
          1e6;
      _hexRevealed = false;
      _fizzleStone = null;
      _stage = _Stage.jumping;
      _stageTime = 0;
      _startMove();
      _shouting = false;
    });
  }

  void _unroll(_Geo geo) {
    setState(() {
      _stage = _Stage.reading;
      _stageTime = 0;
    });
    _landingShock(geo);
  }

  void _tapWord(int index) {
    final read = _read;
    final geo = _geo;
    if (_phase != _Phase.playing ||
        _stage != _Stage.reading ||
        read == null ||
        geo == null) {
      return;
    }

    switch (read.tap(index)) {
      case HexTap.ignored:
        return;
      case HexTap.wrong:
        HapticFeedback.lightImpact();
        setState(() {
          _run = _run.fizzle();
          _fuse = min(0.97, _fuse + BossTrialRules.hexMistakeBurn);
          _fizzleStone = index;
          _fizzleFlash = _fizzleFlashSeconds;
        });
        // It flinches: the fuse is shorter.
        if (!_reduceMotion && _move == null) _playMove(_flinch());
        _pop('wrong', _hurtRed, Offset(geo.w / 2, geo.promptTop - 16));
      case HexTap.broken:
        HapticFeedback.selectionClick();
        // The hexed word burns off the scroll and flies back at her — once the
        // pet, which jumps straight up at the scroll at the tap, has hit it.
        final centre = _scrollCentre(geo);
        final quickness = 1 - _fuse;
        setState(() {
          _stage = _Stage.spellResolving;
          _stageTime = 0;
        });
        if (_reduceMotion) {
          final bolt = _Flight(from: centre, quickness: quickness);
          setState(() => _bolt = bolt);
          _spellImpact(geo, bolt);
          return;
        }
        _wordSwatted = false;
        // It leaps up with its head cocked back and SWATS the hexed word off
        // the scroll, which goes flying up at her turning over and over.
        final word = read.scroll.hexWord;
        final (swat, _) = _swatLeap(
          geo,
          Offset(_petX, _scrollEdge(geo) - 10),
          onHit: (geo) {
            _particles.sparks(centre, count: 12);
            _refresh(() {
              _wordSwatted = true;
              _bolt = _Flight(from: centre, quickness: quickness, label: word);
            });
          },
        );
        _playMove(swat);
    }
  }

  /// The fuse is out: the hex goes off, straight from her mouth at the pet.
  void _hexFires(_Geo geo) {
    HapticFeedback.mediumImpact();
    setState(() {
      _hexRevealed = true;
      _boulder = _Flight(from: _bossMouth(geo), quickness: 0);
      _stage = _Stage.spellResolving;
      _stageTime = 0;
      _cackleTime = 0;
    });
    if (_reduceMotion) _boulderLands(geo);
  }

  void _announce() {
    HapticFeedback.mediumImpact();
    setState(() {
      _stage = _Stage.announcing;
      _stageTime = 0;
      _announceLanded = false;
      _startMove();
    });
  }

  /// Where a spell is, [bolt.t] into its flight: a shallow arc from the pet
  /// up to the boss.
  Offset _boltAt(_Geo geo, _Flight bolt) {
    final k = (bolt.t / _boltSeconds).clamp(0.0, 1.0);
    final to = _bossHitPoint(geo);
    final control =
        Offset((bolt.from.dx + to.dx) / 2 - 40, (bolt.from.dy + to.dy) / 2);
    return Offset(
      (1 - k) * (1 - k) * bolt.from.dx +
          2 * (1 - k) * k * control.dx +
          k * k * to.dx,
      (1 - k) * (1 - k) * bolt.from.dy +
          2 * (1 - k) * k * control.dy +
          k * k * to.dy,
    );
  }

  void _spellImpact(_Geo geo, _Flight bolt) {
    setState(() {
      _bolt = null;
      _read = null;
      _run = _run.hexBroken(earliness: bolt.quickness);
    });
    HapticFeedback.mediumImpact();
    _bossHitTime = 0;
    _freeze = _reduceMotion ? 0 : _hitStopSeconds;
    final centre = _bossHitPoint(geo);
    if (!_reduceMotion) {
      _shake = 0.2;
      if (_boss.flies) {
        _particles.sparks(centre, count: 10, colors: _flyerSparks);
      } else {
        _particles.impact(centre, scale: geo.debrisScale);
      }
      _particles.sparks(centre, count: 14);
    }
    _pop('-${_run.lastDamage}', _gold, centre.translate(0, -geo.bossH * 0.45));
    _pop(
      bolt.quickness > 0.5
          ? 'swift!'
          : _run.combo > 1
              ? 'combo x${_run.combo}'
              : 'broken!',
      _right,
      Offset(_petX, geo.groundTop - geo.petBox - 8),
    );
    if (_run.won) {
      if (!_reduceMotion) {
        _particles.landing(
          left: geo.leftFoot,
          right: geo.rightFoot,
          scale: geo.debrisScale * 1.3,
        );
      }
      _runWon();
    } else {
      _toGap();
    }
  }

  /// The witch's hex reaching the pet: it is a frog until the smoke takes it
  /// back.
  void _boulderLands(_Geo geo) {
    final scroll = _read?.scroll;
    setState(() {
      _boulder = null;
      if (scroll != null) {
        // The scroll stays up through the aftermath, its hex showing.
        _run = _run.hexLanded(scroll);
      }
    });
    HapticFeedback.heavyImpact();
    _hurtTint = 0.3;
    if (!_reduceMotion) {
      _shake = 0.35;
      _petHurt = 0;
    }
    if (_boss.hexesPet) {
      _frog = _frogSeconds;
      _puff(geo);
    }
    _pop(_boss.hexesPet ? 'ribbit' : 'ouch', _hurtRed,
        Offset(_petX, geo.groundTop - geo.petBox - 8));
    if (_run.isOver) _endIn = 0.8;
  }

  /// A puff of the witch's smoke round the pet, as it turns into a frog and
  /// back.
  void _puff(_Geo geo) {
    if (_reduceMotion) return;
    _particles.sparks(
      Offset(_petX, geo.groundTop - geo.petBox * 0.45),
      count: 18,
      colors: HexPalette.sparks,
    );
  }

  // ------------------------------------------------------------ Amethyst --

  /// How far along its way a spike is before its point flashes and the pet
  /// starts to tremble.
  static const double _spikeDanger = 0.78;

  /// Whether a spike still growing is nearly on the pet.
  bool get _spikeClose {
    final rush = _spikes;
    if (rush == null || _stage != _Stage.spiking) return false;
    for (var lane = 0; lane < _spikeGrowth.length; lane++) {
      if (!rush.isShattered(lane) && _spikeGrowth[lane] >= _spikeDanger) {
        return true;
      }
    }
    return false;
  }

  /// The pet's box, where it stands on the ground.
  Rect _petRect(_Geo geo) => Rect.fromLTWH(
        _petX - geo.petBox / 2,
        geo.groundTop - geo.petBox * 0.9,
        geo.petBox,
        geo.petBox,
      );

  /// The boss's attack reaching the pet in a first round: whatever this boss
  /// does to it — seals it in amethyst, turns it into a frog, or just hurts.
  void _strikePet(_Geo geo) {
    if (_boss.encasesPet) {
      _encase(geo);
      return;
    }
    if (_boss.bubblesPet) {
      _trapInBubble(geo);
      return;
    }
    if (_boss.buriesPet) {
      _bury(geo);
      return;
    }
    if (_boss.scorchesPet) {
      _scorch(geo);
      return;
    }
    HapticFeedback.heavyImpact();
    _hurtTint = 0.3;
    if (!_reduceMotion) {
      _shake = 0.35;
      _petHurt = 0;
    }
    if (_boss.hexesPet) {
      _frog = _frogSeconds;
      _puff(geo);
    }
    _pop(_boss.hexesPet ? 'ribbit' : 'ouch', _hurtRed,
        Offset(_petX, _petTop(geo) - 8));
  }

  /// The top of the pet's box, wherever it is standing.
  double _petTop(_Geo geo) =>
      (_petFeet ?? geo.groundTop) - geo.petBox * _petScale;

  /// A wrong answer in a first round that costs a heart there and then: the
  /// Catch round's jolt, shared by the openers that work the same way.
  void _wrongJolt(_Geo geo, Offset at) {
    HapticFeedback.mediumImpact();
    _hurtTint = 0.26;
    if (!_reduceMotion) {
      _shake = 0.3;
      _petHurt = 0;
    }
    _pop('wrong', _hurtRed, at);
    if (_run.isOver) _endIn = 0.8;
  }

  /// Something of Amethyst's got through: the pet is sealed in amethyst.
  void _encase(_Geo geo) {
    HapticFeedback.heavyImpact();
    _encased = _encaseSeconds;
    _hurtTint = 0.3;
    // Sealed where it stands: whatever its body was doing stops, and a run
    // stops where it had got to.
    _move = null;
    if (_petRunning || _petGoX != null || _petLane != null) {
      _petGoX = _petX;
      _petLane = null;
      _petAway = _encaseSeconds;
    }
    if (!_reduceMotion) {
      _shake = 0.35;
      _petHurt = 0;
      _particles.shatter(_petRect(geo), colors: CrystalPalette.shards);
    }
    _pop('sealed', _hurtRed, Offset(_petX, geo.groundTop - geo.petBox - 8));
  }

  static Offset _quadratic(Offset a, Offset control, Offset b, double k) =>
      Offset(
        (1 - k) * (1 - k) * a.dx + 2 * (1 - k) * k * control.dx + k * k * b.dx,
        (1 - k) * (1 - k) * a.dy + 2 * (1 - k) * k * control.dy + k * k * b.dy,
      );

  /// Where [shot] is: up and over, onto the bear.
  Offset _shotAt(_Geo geo, _Shot shot) {
    final k = ((shot.t - shot.delay) / (shot.seconds ?? _throwSeconds))
        .clamp(0.0, 1.0);
    final to = shot.to ?? _bossHitPoint(geo);
    final control =
        Offset((shot.from.dx + to.dx) / 2, min(shot.from.dy, to.dy) - 60);
    return _quadratic(shot.from, control, to, k);
  }

  /// The pet throws [shot] at the bear.
  void _shoot(_Geo geo, _Shot shot) {
    _shots.add(shot);
    if (_reduceMotion) {
      _shotLands(geo, shot);
    } else {
      _petHop = 0;
    }
  }

  void _stepShots(double dt, _Geo geo) {
    if (_shots.isEmpty) return;
    for (final shot in [..._shots]) {
      shot.t += dt;
      if (shot.t >= shot.delay + (shot.seconds ?? _throwSeconds)) {
        _shotLands(geo, shot);
      }
    }
  }

  void _shotLands(_Geo geo, _Shot shot) {
    if (!_shots.remove(shot)) return;
    final onLand = shot.onLand;
    if (onLand != null) {
      onLand(geo);
      return;
    }
    final bank = shot.bank;
    setState(() {
      _run = bank != null
          ? _run.crossed(bank)
          : shot.whole
              ? _run.answerRight(earliness: shot.earliness)
              : _run.shardHit(earliness: shot.earliness);
    });
    HapticFeedback.lightImpact();
    _bossHitTime = 0;
    _freeze = _reduceMotion ? 0 : _hitStopSeconds;
    final centre = shot.to ?? _bossHitPoint(geo);
    if (!_reduceMotion) {
      _shake = bank != null ? 0.3 : 0.12;
      switch (shot.look) {
        case _ShotLook.crystal:
          _particles.shatter(
            Rect.fromCenter(center: centre, width: 28, height: 28),
            colors: CrystalPalette.shards,
          );
        case _ShotLook.gem || _ShotLook.spell || _ShotLook.ember:
          _particles.sparks(centre,
              count: shot.big ? 26 : 12,
              colors: shot.look == _ShotLook.ember
                  ? DragonPalette.sparks
                  : null);
          if (shot.big) _shake = 0.3;
        case _ShotLook.rock || _ShotLook.butt:
          _particles.impact(centre, scale: geo.debrisScale);
        case _ShotLook.fish:
          _particles.sparks(centre, count: 14, colors: AnglerPalette.bubbles);
      }
      if (_boss.flies) {
        _particles.sparks(centre, count: 8, colors: _flyerSparks);
      }
    }
    _pop('-${_run.lastDamage}', _gold, centre.translate(0, -geo.bossH * 0.45));
    shot.onHit?.call(geo);
    if (shot.whole) {
      _pop(
        shot.earliness > 0.55
            ? 'quick!'
            : _run.combo > 1
                ? 'combo x${_run.combo}'
                : 'right',
        _right,
        Offset(_petX, geo.groundTop - geo.petBox - 8),
      );
    }
    if (_run.cleared) {
      // Whatever else was on its way is called off.
      setState(() {
        _spikes = null;
        _volley = null;
        _inFlight.clear();
        _shouting = false;
        _clearMossRounds();
        _clearWitchRounds(dismount: true);
        _clearAnglerRounds();
        _clearSphinxRounds();
        _clearDragonRounds();
        _vein = null;
      });
      if (!_run.won) {
        // A finale's round won: the next begins after the gap.
        _shots.clear();
        _toGap();
        return;
      }
      if (!_reduceMotion) {
        _particles.landing(
          left: geo.leftFoot,
          right: geo.rightFoot,
          scale: geo.debrisScale * 1.3,
        );
      }
      _runWon();
    }
  }

  /// The run's last hit has landed. A finale's boss is beaten where it
  /// stands; at any other level it gets away, leaping off the top of the
  /// arena, to be beaten for good at its finale.
  void _runWon() {
    if (_plan.isFinale) {
      _endIn = 0.9;
      return;
    }
    final getaway = _secs(BossMotion.getawayEnds);
    _fleeTime = _reduceMotion ? getaway : 0;
    _endIn = getaway + 0.3;
  }

  /// How far the boss has gone getting away: up off the top of the arena,
  /// and a flyer off to the side it is on as well.
  Offset _fleeOffset(_Geo geo) {
    final t = _fleeTime;
    if (t == null) return Offset.zero;
    final (_, away) = BossMotion.getaway(_dur(t));
    final up = (geo.bossTop + geo.bossH + 24) * away;
    final aside = _boss.flies ? (_side < 0 ? -1 : 1) * geo.w * 0.4 * away : 0;
    return Offset(aside.roundToDouble(), -up.roundToDouble());
  }

  /// The boss powering up and leaping away. A flyer powers up where it
  /// hovers.
  BossPose _getawayPose(double t) {
    final (pose, _) = BossMotion.getaway(_dur(t));
    if (!_boss.flies) return pose;
    return BossPose(
      lift: 0.5,
      drift: _side,
      scaleX: pose.scaleX,
      scaleY: pose.scaleY,
      dx: pose.dx,
      mouthOpen: pose.mouthOpen,
      flash: pose.flash,
    );
  }

  /// The leap's kick: debris off the ledge, or a flyer's burst of its own
  /// sparks.
  void _launchKick(_Geo geo) {
    if (_reduceMotion) return;
    if (_boss.flies) {
      _particles.sparks(_bossHitPoint(geo), count: 16, colors: _flyerSparks);
      return;
    }
    _shake = 0.25;
    _particles.landing(
      left: geo.leftFoot,
      right: geo.rightFoot,
      scale: geo.debrisScale * 1.4,
    );
    _particles.shakeLoose(width: geo.w, ledgeY: geo.ledgeTop + geo.ledgeH);
  }

  // ---- Crystal Spikes ----

  void _beginSpikes() {
    final wave =
        SpikeWave.build(_pool, previous: _lastSpikeWords, random: _rng);
    if (wave == null) {
      _finish();
      return;
    }
    setState(() {
      _spikes = SpikeRush(wave);
      _lastSpikeWords = wave.spikes;
      _spikeGrowth = List.filled(wave.spikes.length, 0.0);
      // Fixed when they erupt, so a spike never speeds up mid-growth.
      _spikeSeconds = [
        for (final rank in wave.ranks)
          CrystalRules.spikeTime(rank: rank, patience: _clockPatience)
                  .inMicroseconds /
              1e6,
      ];
      _flashLane = null;
      _flashGem = null;
      _stage = _Stage.jumping;
      _stageTime = 0;
      _startMove();
      _shouting = false;
    });
  }

  /// The landing: the spikes burst out from under the ledge.
  void _raiseSpikes(_Geo geo) {
    setState(() {
      _stage = _Stage.spiking;
      _stageTime = 0;
    });
    _landingShock(geo);
    if (_reduceMotion) return;
    for (var lane = 0; lane < _spikeGrowth.length; lane++) {
      _particles.sparks(
        geo.spikeRoot(lane),
        count: 5,
        colors: CrystalPalette.shards,
      );
    }
  }

  void _stepSpikes(double dt, _Geo geo) {
    final rush = _spikes;
    if (rush == null) return;
    for (var lane = 0; lane < _spikeGrowth.length; lane++) {
      if (rush.isShattered(lane)) continue;
      _spikeGrowth[lane] =
          min(1.0, _spikeGrowth[lane] + dt / _spikeSeconds[lane]);
      if (_spikeGrowth[lane] >= 1) {
        _spikeStrikes(geo, lane);
        return;
      }
    }
  }

  void _tapSpike(int lane) => _pairTap(lane, gem: false);
  void _tapGem(int gem) => _pairTap(gem, gem: true);

  /// A tap on a spike or a gem: half a pair held, or a pair tried.
  void _pairTap(int index, {required bool gem}) {
    final rush = _spikes;
    final geo = _geo;
    if (_phase != _Phase.playing ||
        _stage != _Stage.spiking ||
        rush == null ||
        geo == null) {
      return;
    }

    switch (gem ? rush.tapGem(index) : rush.tapSpike(index)) {
      case SpikeTap.ignored:
        return;
      case SpikeTap.held:
      case SpikeTap.dropped:
        HapticFeedback.selectionClick();
        setState(() {});
      case SpikeTap.mismatched:
        final (lane, wrongGem) = rush.lastPair!;
        HapticFeedback.lightImpact();
        setState(() {
          _run = _run.wordSlip(rush.wave.spikes[lane]);
          _spikeGrowth[lane] =
              min(0.97, _spikeGrowth[lane] + CrystalRules.spikeLurch);
          _flashLane = lane;
          _flashGem = wrongGem;
          _fizzleFlash = _fizzleFlashSeconds;
        });
        final plate = geo.spikePlate(lane);
        if (!_reduceMotion) {
          _shake = 0.12;
          _particles.sparks(
            geo.spikeTip(lane, _spikeGrowth[lane]),
            count: 6,
            fizzle: true,
          );
          // It cringes from the spike that lurched at it, turned to it.
          if (_move == null) {
            _faceToward(geo.laneCentre(lane), from: _petX, deadzone: 12);
            _playMove(_flinch());
          }
        }
        _pop('wrong', _hurtRed, Offset(plate.center.dx, plate.bottom + 16));
      case SpikeTap.matched:
        final (lane, rightGem) = rush.lastPair!;
        HapticFeedback.selectionClick();
        _throwGem(geo, lane, rightGem, earliness: 1 - _spikeGrowth[lane]);
        setState(() {
          if (rush.isCleared && _endIn == null) {
            _stage = _Stage.resolving;
            _stageTime = 0;
          }
        });
    }
  }

  /// A true shard reached the pet at [at]: it SQUATS to catch it, holds it up,
  /// and throws it back at the bear in a SPINNING throw — right round in the air,
  /// the shard let go as it comes round.
  void _catchShard(_Geo geo, Offset at) {
    if (_reduceMotion) {
      _shoot(geo, _Shot(from: at, earliness: 0));
      return;
    }
    final toward = _bossSide(geo, at.dx);
    final hands = _throwFrom(geo, at.dx, toward);
    final k = _Keyer();
    k.to(0.14, squash: 0.7, dy: -3);
    k.to(0.06, squash: 0.85, dy: 0);
    final caught = k.t;
    k.to(0.4, twirl: 1, dy: 16, squash: 1.05);
    final release = k.t;
    k.to(0.14, dy: 0, squash: 0.9, ease: _Ease.accelerate);
    k.to(0.1, squash: 1.0);
    // The shard goes up to the pet's hands as it squats, and is held there...
    _shots.add(_Shot(
      from: at,
      to: hands,
      earliness: 0,
      seconds: caught,
      onLand: (geo) {},
    ));
    _heldFrom = _time + caught;
    _heldUntil = _time + release;
    _heldGem = false;
    // ...and away at the bear.
    _shots.add(_Shot(from: hands, earliness: 0, delay: release));
    _petFacesLeft = toward < 0;
    // It stays where it caught it while it throws.
    _stayPut(k.t + 0.3);
    _playMove(_PetMove.keys(k.keys, faceLeft: toward < 0));
  }

  /// The pet runs to [gem], scoops it up — it arcs from the grass into the
  /// pet's hands as the pet gets there, and the pet squats to take it — and
  /// then LEAPS with it at the base of spike [lane], where it hangs from the
  /// ledge: the spike shatters and its shards fall, and the gem goes on from
  /// there at the bear. The strike is on a schedule of its own, so a second
  /// pair matched while the pet is still at it does not cost the first one its
  /// hit.
  void _throwGem(_Geo geo, int lane, int gem, {required double earliness}) {
    final from = geo.gemRect(gem).center;
    final root = geo.spikeRoot(lane);
    if (_reduceMotion) {
      _launch(geo, _Shot(from: from, earliness: earliness, look: _ShotLook.gem));
      return;
    }
    final xg = geo.laneCentre(gem);
    final run = _runTo(geo, xg, stay: 1.5);
    // Where its head has to get to, from the gem's lane: into the spike's foot.
    final aim = _withinLeap(geo, Offset(root.dx, root.dy + 8),
        most: geo.petBox * 2.6);
    final dx = aim.dx - xg;
    final dir = dx.abs() > 8 ? dx.sign : _bossSide(geo, xg);
    final up = max(0.0, _reachTo(geo, aim).dy - _stretchRise(geo, 1.15));
    final hands = _throwFrom(geo, xg, _bossSide(geo, xg));
    final k = _Keyer();
    // The run, then down on its haunches to scoop the gem...
    k.to(max(0.05, run), squash: 1.0);
    k.to(0.16, squash: 0.7, dy: -3);
    final scooped = k.t;
    // ...and up, across, at the spike's base, the gem held over its head.
    k.to(0.06, squash: 0.85, dy: -2);
    k.to(0.22 + up / 1000,
        dx: dx, dy: up, tilt: dir * 0.3, squash: 1.15, ease: _Ease.out);
    final hit = k.t;
    k.hold(0.06);
    k.to(0.4, dx: 0, dy: 0, tilt: 0, squash: 0.85, ease: _Ease.accelerate);
    k.to(0.14, squash: 1.0);
    // Up out of the grass into its hands, arriving as it squats...
    _shots.add(_Shot(
      from: from,
      to: hands,
      earliness: 0,
      look: _ShotLook.gem,
      seconds: scooped - 0.06,
      onLand: (geo) {},
    ));
    _heldFrom = _time + scooped;
    _heldUntil = _time + hit;
    _heldGem = true;
    // ...the spike breaks as it hits, and the gem goes on from its foot.
    _spikeBreakAt[lane] = _time + hit;
    _shots.add(_Shot(
      from: root,
      earliness: earliness,
      look: _ShotLook.gem,
      delay: hit,
    ));
    // It faces the gem as it runs for it, and the spike as it leaps.
    _playMove(_PetMove.keys(k.keys, faceLeft: dir < 0, faceAt: scooped));
  }

  /// A spike whose break the pet is on its way to: it still stands.
  bool _spikeStands(SpikeRush rush, int lane) =>
      !rush.isShattered(lane) ||
      (_spikeBreakAt[lane] != null && _time < _spikeBreakAt[lane]!);

  /// The spikes the pet has leapt at break, their shards falling.
  void _stepSpikeBreaks(_Geo geo) {
    if (_spikeBreakAt.isEmpty) return;
    for (final lane in [..._spikeBreakAt.keys]) {
      if (_time < _spikeBreakAt[lane]!) continue;
      _spikeBreakAt.remove(lane);
      _shake = max(_shake, 0.12);
      _shatterSpike(geo, lane);
    }
  }

  /// Spike [lane] breaking up: its plate, and its shaft as far as it has
  /// grown.
  void _shatterSpike(_Geo geo, int lane, {bool front = true}) {
    _particles.shatter(geo.spikePlate(lane), colors: CrystalPalette.shards);
    final root = geo.spikeRoot(lane);
    final tip = geo.spikeTip(lane, _spikeGrowth[lane]);
    for (final k in const [0.35, 0.7, 1.0]) {
      _particles.shatter(
        Rect.fromCenter(
          center: Offset.lerp(root, tip, k)!,
          width: 16,
          height: 16,
        ),
        colors: CrystalPalette.shards,
        front: front,
      );
    }
  }

  /// A spike reached the pet: it is sealed in, and the rest crumble.
  void _spikeStrikes(_Geo geo, int lane) {
    final rush = _spikes;
    if (rush == null) return;
    if (!_reduceMotion) {
      for (var l = 0; l < _spikeGrowth.length; l++) {
        if (!rush.isShattered(l)) _shatterSpike(geo, l, front: l == lane);
      }
    }
    setState(() {
      _run = _run.struck(rush.wave.spikes[lane]);
      _spikes = null;
      _stage = _Stage.resolving;
      _stageTime = 0;
    });
    _encase(geo);
    if (_run.isOver) _endIn = 0.8;
  }

  // ---- Crystal Echo ----

  void _beginEcho() {
    final wave = EchoWave.build(_sentences, previous: _lastEcho, random: _rng);
    if (wave == null) {
      _throwWave();
      return;
    }
    setState(() {
      _echo = EchoListen(wave);
      _lastEcho = wave.sentence;
      _creep = 0;
      // Fixed when it roars, so the amethyst never speeds up mid-climb.
      _echoSeconds = CrystalRules.echoTime(
            words: wave.sentence.tokens.length,
            patience: _clockPatience,
          ).inMicroseconds /
          1e6;
      _echoRevealed = false;
      _crystalHeld = false;
      _fizzleStone = null;
      _stage = _Stage.jumping;
      _stageTime = 0;
      _startMove();
      _shouting = false;
    });
  }

  /// The landing: the three crystals rise.
  void _raiseEcho(_Geo geo) {
    setState(() {
      _stage = _Stage.echoing;
      _stageTime = 0;
    });
    _landingShock(geo);
    if (_reduceMotion) return;
    for (var i = 0; i < CrystalRules.echoOptions; i++) {
      _particles.sparks(geo.echoRect(i).center,
          count: 6, colors: CrystalPalette.shards);
    }
  }

  void _tapEcho(int index) {
    final echo = _echo;
    final geo = _geo;
    if (_phase != _Phase.playing ||
        _stage != _Stage.echoing ||
        echo == null ||
        geo == null) {
      return;
    }

    final rect = geo.echoRect(index);
    switch (echo.tap(index)) {
      case EchoTap.ignored:
        return;
      case EchoTap.wrong:
        HapticFeedback.lightImpact();
        setState(() {
          _run = _run.fizzle();
          _creep = min(0.97, _creep + CrystalRules.echoMistakeCreep);
          _fizzleStone = index;
          _fizzleFlash = _fizzleFlashSeconds;
        });
        if (!_reduceMotion) {
          _particles.sparks(rect.center, count: 8, fizzle: true);
          // The amethyst jumps up it, and it cringes.
          if (_move == null) _playMove(_flinch());
        }
        _pop('wrong', _hurtRed, Offset(geo.w / 2, rect.top - 10));
      case EchoTap.heard:
        HapticFeedback.selectionClick();
        final earliness = 1 - _creep;
        final shot = _Shot(from: rect.center, earliness: earliness, whole: true);
        if (!_reduceMotion && _creep > 0) {
          // The amethyst round the pet falls away.
          _particles.shatter(_petRect(geo), colors: CrystalPalette.shards);
        }
        setState(() {
          _creep = 0;
          _shouting = false;
          _stage = _Stage.resolving;
          _stageTime = 0;
        });
        if (_reduceMotion) {
          _shoot(geo, shot);
          return;
        }
        // Free of the amethyst, the pet springs straight up the moment it is
        // picked and HEADBUTTS the crystal — head down into it at the top —
        // which bursts into the shot.
        _crystalHeld = true;
        final reach = _reachTo(geo, Offset(_petX, rect.bottom));
        final up = max(0.0, reach.dy - _stretchRise(geo, 1.15));
        final toward = _bossSide(geo, _petX);
        final k = _Keyer();
        k.to(0.05, squash: 0.88, dy: -2);
        k.to(0.32, dy: up, tilt: -toward * 0.15, squash: 1.15, ease: _Ease.out);
        k.to(0.06,
            tilt: toward * 0.55, dy: up + 4, squash: 1.0, ease: _Ease.linear);
        final hit = k.t;
        k.hold(0.06);
        k.to(0.38, dy: 0, tilt: 0, squash: 0.85, ease: _Ease.accelerate);
        k.to(0.14, squash: 1.0);
        _stayPut(k.t + 0.2);
        _playMove(_PetMove.keys(k.keys, events: [
          _MoveEvent(hit, (geo) {
            _refresh(() => _crystalHeld = false);
            _particles.shatter(rect, colors: CrystalPalette.shards);
            _shots.add(shot);
          }),
        ]));
    }
  }

  /// The amethyst has closed over the pet. The roar and its crystals stay up
  /// through the aftermath, the right one lit.
  void _echoSeals(_Geo geo) {
    final echo = _echo;
    if (echo == null) return;
    setState(() {
      _run = _run.castFailed(echo.wave.sentence);
      _echoRevealed = true;
      _creep = 0;
      _stage = _Stage.resolving;
      _stageTime = 0;
    });
    _encase(geo);
    if (_run.isOver) _endIn = 0.8;
  }

  // ---- Shard Volley ----

  void _beginVolley() {
    final volley = ShardVolley.build(_pool, random: _rng);
    if (volley == null) {
      _finish();
      return;
    }
    setState(() {
      _volley = volley;
      _volleyNext = 0;
      _volleyClock = 0;
      _inFlight.clear();
      // Fixed for the volley, so it never speeds up halfway through.
      _shardSeconds =
          CrystalRules.shardFlight(_clockPatience).inMicroseconds / 1e6;
      _shardInterval =
          CrystalRules.shardInterval(_clockPatience).inMicroseconds / 1e6;
      _stage = _Stage.jumping;
      _stageTime = 0;
      _startMove();
      _shouting = false;
    });
  }

  /// The landing, and the first shard with it.
  void _openVolley(_Geo geo) {
    setState(() {
      _stage = _Stage.volleying;
      _stageTime = 0;
    });
    _landingShock(geo);
    _hurl(geo);
  }

  /// The next shard leaves its mouth, for a lane other than the last one's.
  void _hurl(_Geo geo) {
    final volley = _volley;
    if (volley == null || _volleyNext >= volley.shards.length) return;
    final lanes = [
      for (var l = 0; l < BossTrialRules.wordsPerWave; l++)
        if (l != _lastShardLane) l,
    ];
    final lane = lanes[_rng.nextInt(lanes.length)];
    _inFlight.add(_Shard(
      shard: volley.shards[_volleyNext],
      lane: lane,
      from: _bossMouth(geo),
    ));
    _lastShardLane = lane;
    _volleyNext++;
    _volleyClock = 0;
    _cackleTime = 0;
  }

  void _stepVolley(double dt, _Geo geo) {
    final volley = _volley;
    if (volley == null) return;
    _volleyClock += dt;
    if (_volleyClock >= _shardInterval) _hurl(geo);
    for (final shard in [..._inFlight]) {
      shard.t += dt;
      if (shard.t >= _shardSeconds) {
        _shardArrives(geo, shard);
        // A lie got through, and that was the volley.
        if (_volley == null) return;
      }
    }
    if (_inFlight.isNotEmpty && _move == null) {
      // The pet runs to keep under whichever shard is nearest, facing the way
      // it runs — and holds its place while its body is busy catching or
      // swatting.
      final lane = _inFlight.reduce((a, b) => a.t >= b.t ? a : b).lane;
      if (_petLane != lane && !_reduceMotion) {
        _faceToward(geo.laneCentre(lane), from: _petX);
      }
      _petLane = lane;
      _petGoX = null;
      _petAway = 0.3;
      _petRunning = !_reduceMotion;
    }
    if (_volleyNext >= volley.shards.length && _inFlight.isEmpty) {
      setState(() {
        _volley = null;
        if (_endIn == null) {
          _stage = _Stage.resolving;
          _stageTime = 0;
        }
      });
    }
  }

  /// Where [shard] is: up out of the bear's mouth and over to its lane, then
  /// down the lane to the pet.
  Rect _shardRect(_Geo geo, _Shard shard) {
    const arc = 0.22;
    final k = (shard.t / _shardSeconds).clamp(0.0, 1.0);
    final top = Offset(geo.laneCentre(shard.lane), geo.fallTop + geo.tileH / 2);
    final land = Offset(
      geo.laneCentre(shard.lane),
      geo.groundTop - geo.petBox * 0.9 - geo.tileH / 2,
    );
    final Offset at;
    if (k < arc) {
      final control = Offset(
        (shard.from.dx + top.dx) / 2,
        min(shard.from.dy, top.dy) - 50,
      );
      at = _quadratic(shard.from, control, top, k / arc);
    } else {
      at = Offset.lerp(top, land, (k - arc) / (1 - arc))!;
    }
    return Rect.fromCenter(
      center: Offset(at.dx.roundToDouble(), at.dy.roundToDouble()),
      width: geo.tileW,
      height: geo.tileH,
    );
  }

  /// A shard reached the pet untouched: a true one is caught and thrown
  /// back; a lie seals the pet in and ends the volley.
  void _shardArrives(_Geo geo, _Shard shard) {
    final at = _shardRect(geo, shard);
    _inFlight.remove(shard);
    switch (ShardVolley.call(shard.shard, smashed: false)) {
      case ShardCall.caughtTruth:
        _catchShard(geo, at.center);
        _pop('true', _right, Offset(at.center.dx, at.top - 10));
      case ShardCall.lieLanded:
        if (!_reduceMotion) {
          for (final other in _inFlight) {
            _particles.shatter(
              _shardRect(geo, other),
              colors: CrystalPalette.shards,
              front: false,
            );
          }
        }
        setState(() {
          _run = _run.struck(shard.shard.word);
          _volley = null;
          _inFlight.clear();
          _stage = _Stage.resolving;
          _stageTime = 0;
        });
        _encase(geo);
        if (_run.isOver) _endIn = 0.8;
      case ShardCall.smashedLie:
      case ShardCall.smashedTruth:
        break;
    }
  }

  void _tapShard(_Shard shard) {
    final geo = _geo;
    if (_phase != _Phase.playing ||
        _stage != _Stage.volleying ||
        geo == null ||
        !_inFlight.contains(shard)) {
      return;
    }

    final at = _shardRect(geo, shard);
    setState(() => _inFlight.remove(shard));
    final lie = ShardVolley.call(shard.shard, smashed: true) == ShardCall.smashedLie;
    // A lie hangs where it was struck till the pet has swatted it.
    if (!_reduceMotion && !lie) {
      _particles.shatter(at, colors: CrystalPalette.shards);
    }
    switch (ShardVolley.call(shard.shard, smashed: true)) {
      case ShardCall.smashedLie:
        HapticFeedback.selectionClick();
        // Swatted straight back: the pet LEAPS at it — head cocked back, then
        // swept round at it — and the lie goes at the bear from where it was
        // struck.
        final earliness = 1 - shard.t / _shardSeconds;
        if (_reduceMotion) {
          _shoot(geo, _Shot(from: at.center, earliness: earliness));
        } else {
          final (swat, hit) = _swatLeap(
            geo,
            Offset(at.center.dx, geo.groundTop - geo.petBox * 0.65 - 64),
            rise: 0.16,
            fall: 0.22,
            onHit: (geo) =>
                _particles.shatter(at, colors: CrystalPalette.shards),
          );
          // Held in the air where it was struck, until the swat...
          _shots.add(_Shot(
            from: at.center,
            to: at.center,
            earliness: 0,
            seconds: hit,
            onLand: (geo) {},
          ));
          // ...and flung at the bear by it.
          _shots.add(_Shot(from: at.center, earliness: earliness, delay: hit));
          _stayPut(hit + 0.5);
          _playMove(swat);
        }
        _pop('lie!', _right, Offset(at.center.dx, at.top - 10));
      case ShardCall.smashedTruth:
        HapticFeedback.lightImpact();
        if (!_reduceMotion) {
          _particles.sparks(at.center, count: 6, fizzle: true);
          _playMove(_flinch());
        }
        setState(() => _run = _run.wordSlip(shard.shard.word));
        _pop('it was true', _hurtRed, Offset(at.center.dx, at.top - 10));
      case ShardCall.caughtTruth:
      case ShardCall.lieLanded:
        break;
    }
  }

  // ------------------------------------------------------------- Mossback --

  void _commit(int lane) {
    final wave = _wave;
    final geo = _geo;
    if (_phase != _Phase.playing ||
        _stage != _Stage.falling ||
        wave == null ||
        geo == null) {
      return;
    }

    final right = lane == wave.answerLane;
    final picked = geo.tileRect(lane, _fall);
    final earliness = 1 - _fall;

    // A wrong pick shatters the lot where it hangs. A right one lets every
    // piece plunge: the picked one onto the pet, the rest to crumble on the
    // ground.
    if (!right && !_reduceMotion) {
      for (var l = 0; l < wave.lanes.length; l++) {
        _particles.shatter(geo.tileRect(l, _fall), front: l == lane);
      }
    }

    // The pet runs for the piece it picked, at a pace it can be seen at, facing
    // the way it runs; with reduced motion it just goes.
    final run = _reduceMotion
        ? 0.0
        : (geo.laneCentre(lane) - _petX).abs() / (geo.w * _runWidths);
    _petLane = lane;
    _petRunning = !_reduceMotion;
    _faceToward(geo.laneCentre(lane), from: _petX);
    // Down to its hands as soon as it has got there.
    final drop = max(_dropSeconds, run + 0.1);
    final windUp = _squishSeconds + _windUpSeconds + _catchThrowSeconds;
    _petAway = right ? drop + windUp + _throwSeconds + 0.3 : run + 0.9;

    setState(() {
      _stage = _Stage.resolving;
      _stageTime = 0;
      _rubbleVisible = false;
      _shouting = false;
      if (right) {
        _throw = _Throw(
          from: picked.center,
          lane: lane,
          earliness: earliness,
          dropSeconds: drop,
          fallFrom: _fall,
          // Until a piece's bottom is on the ground.
          fallTo: max(
            1.0,
            (geo.groundTop - geo.tileH - geo.fallTop) / max(geo.fallSpan, 1.0),
          ),
        );
      } else {
        _run = _run.answerWrong(wave.prompt);
      }
    });

    if (right) {
      HapticFeedback.selectionClick();
      if (_reduceMotion) _impact(geo, _throw!);
      return;
    }

    HapticFeedback.mediumImpact();
    _hurtTint = 0.26;
    _pop('wrong', _hurtRed, Offset(geo.laneCentre(lane), picked.top - 12));
    if (_reduceMotion) {
      if (_run.isOver) _endIn = 0.8;
      return;
    }
    // It runs under the rubble it picked, and is flattened by it; if that was
    // the last heart, the end waits for it to be.
    if (_run.isOver) _endIn = run + 1.1;
    _playMove(_PetMove.flatten(
      delay: run,
      onImpact: (geo) {
        HapticFeedback.heavyImpact();
        _shake = 0.3;
        _petHurt = 0;
      },
      onEnd: _springUp,
    ));
  }

  /// Seconds the pet's throw takes once it has wound up: the snap forward, a
  /// beat, and coming back to rest.
  static const double _catchThrowSeconds = 0.4;

  /// Every piece has landed. The picked one lands on the pet and squishes it;
  /// the rest hit the ground and crumble. Then the pet gets out from under,
  /// leans back with the piece over its head, snaps forward and lets it go at
  /// the boss.
  void _catchAndThrow(_Geo geo, _Throw thrown) {
    final lane = geo.laneCentre(thrown.lane);
    final toward = _bossHitPoint(geo).dx >= lane ? 1.0 : -1.0;
    _petFacesLeft = toward < 0;
    final wave = _wave;
    if (wave != null && !_reduceMotion) {
      for (var l = 0; l < wave.lanes.length; l++) {
        if (l != thrown.lane) {
          _particles.shatter(geo.tileRect(l, thrown.fallTo), front: false);
        }
      }
      HapticFeedback.mediumImpact();
      _shake = 0.2;
      _freeze = _hitStopSeconds;
    }
    _playMove(_PetMove.leap(
      reach: const Offset(0, 10),
      tilt: toward * pi * 0.14,
      windTilt: -toward * pi * 0.12,
      crouch: _squishSeconds + _windUpSeconds,
      press: _squishSeconds,
      rise: 0.12,
      hold: 0.08,
      fall: 0.2,
      squash: 0.12,
      shiver: 0,
      dip: 2,
      onImpact: (geo) {
        // It leaves the pet's hands from where they have got to.
        thrown.releaseFrom = _heldRock(geo, thrown);
        thrown.releasedAt = thrown.t;
      },
    ));
  }

  /// Where the pet holds its rubble: over its head, in the lane it ran to,
  /// going down as the pet squats and across as it leans.
  Offset _heldRock(_Geo geo, _Throw thrown) {
    final move = _move;
    final o = move?.offset ?? Offset.zero;
    // (The cat's sprite sits low in its box, so its head is well under the
    // box's top.)
    final hands =
        Offset(geo.laneCentre(thrown.lane), geo.groundTop - geo.petBox * 0.78);
    return hands +
        Offset(
          o.dx + sin(move?.tilt ?? 0) * geo.petBox * 0.5,
          -o.dy + (1 - (move?.squash ?? 1)) * geo.petBox * 0.6,
        );
  }

  void _impact(_Geo geo, _Throw thrown) {
    setState(() {
      _throw = null;
      _run = _run.answerRight(earliness: thrown.earliness);
    });
    HapticFeedback.lightImpact();
    _bossHitTime = 0;
    _freeze = _reduceMotion ? 0 : _hitStopSeconds;
    final centre = _bossHitPoint(geo);
    if (!_reduceMotion) {
      _shake = 0.16;
      _particles.impact(centre, scale: geo.debrisScale);
    }

    _pop('-${_run.lastDamage}', _gold, centre.translate(0, -geo.bossH * 0.45));
    final label = thrown.earliness > 0.55
        ? 'quick!'
        : _run.combo > 1
            ? 'combo x${_run.combo}'
            : 'right';
    _pop(label, _right, Offset(_petX, geo.groundTop - geo.petBox - 8));

    if (_run.won) {
      // The last hit gets its moment before the results.
      if (!_reduceMotion) {
        _particles.landing(
          left: geo.leftFoot,
          right: geo.rightFoot,
          scale: geo.debrisScale * 1.3,
        );
      }
      _runWon();
    } else {
      _toGap();
    }
  }

  void _letLand(_Geo geo) {
    final wave = _wave;
    if (wave != null && !_reduceMotion) {
      for (var l = 0; l < wave.lanes.length; l++) {
        _particles.shatter(geo.tileRect(l, 1), front: false);
      }
    }
    setState(() {
      _run = _run.letLand();
      _stage = _Stage.resolving;
      _stageTime = 0;
      _rubbleVisible = false;
      _shouting = false;
    });
    _pop('too slow', _muted, Offset(geo.w / 2, geo.groundTop - geo.petBox - 8));
  }

  void _toGap() {
    setState(() {
      _wave = null;
      _read = null;
      _hexRevealed = false;
      _spikes = null;
      _echo = null;
      _echoRevealed = false;
      _crystalHeld = false;
      _volley = null;
      _inFlight.clear();
      _shouting = false;
      _holdAftermath = false;
      _clearMossRounds();
      _clearWitchRounds(dismount: true);
      _clearAnglerRounds();
      _clearSphinxRounds();
      _clearDragonRounds();
      _vein = null;
      _stage = _Stage.gap;
      _stageTime = 0;
      _gapSeconds = BossTrialRules.waveGap.inMicroseconds / 1e6;
    });
  }

  void _finish() {
    setState(() {
      _wave = null;
      _throw = null;
      _shouting = false;
      _rubbleVisible = false;
      _read = null;
      _bolt = null;
      _boulder = null;
      _shots.clear();
      _spikes = null;
      _echo = null;
      _echoRevealed = false;
      _crystalHeld = false;
      _creep = 0;
      _volley = null;
      _inFlight.clear();
      _move = null;
      _petRunning = false;
      _petGoX = null;
      _petSpring = -1;
      _clearMossRounds();
      _leaving = null;
      _clearWitchRounds();
      _clearAnglerRounds();
      _clearSphinxRounds();
      _clearDragonRounds();
      _vein = null;
      _stage = _Stage.gap;
      _phase = _Phase.over;
    });
    if (_run.won) unawaited(_claimFirstClear());
  }

  /// What this clear paid, when it was the level's first. Empty for a repeat.
  List<RewardDef> _firstClear = const [];

  /// Records the clear and pays it out, once: the progress provider remembers
  /// which levels have paid, so a repeat or a run that ends twice pays nothing.
  Future<void> _claimFirstClear() async {
    final progress = context.read<BossProgressProvider>();
    final user = context.read<UserProvider>();
    final paid = await progress.recordClear(
      bossId: _boss.id,
      step: _step,
      level: _levelNumber,
      finale: _plan.isFinale,
      user: user,
    );
    if (!mounted || paid.isEmpty) return;
    setState(() => _firstClear = paid);
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
                          geo.h != c.maxHeight ||
                          geo.boss != _boss) {
                        _geo = _Geo(c.maxWidth, c.maxHeight, _boss);
                        if (geo == null) _petX = c.maxWidth / 2;
                      }
                      return ValueListenableBuilder<int>(
                        valueListenable: _frame,
                        builder: (context, _, __) => _buildArena(_geo!),
                      );
                    }),
                  ),
                  if (_phase != _Phase.playing)
                    Positioned.fill(child: _buildPanel()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHud() {
    return Container(
      color: _ink,
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: 'Leave trial',
            child: GestureDetector(
              onTap: _leave,
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.retroLight,
                  border: Border.all(color: _muted, width: 2),
                ),
                child: Text('X', style: _pixel(12, _ink)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          for (var i = 0; i < BossTrialRules.maxHearts; i++)
            Container(
              width: 12,
              height: 12,
              margin: const EdgeInsetsDirectional.only(end: 5),
              decoration: BoxDecoration(
                color: i < _run.hearts ? _hurtRed : const Color(0xFF4E4A4E),
                border: Border.all(color: Colors.black, width: 2),
              ),
            ),
          const SizedBox(width: 8),
          Expanded(child: _patienceBar()),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('x${_run.combo}', style: _pixel(10, _gold)),
              const SizedBox(height: 4),
              Text(
                '${_hudSeconds().toStringAsFixed(1)}s',
                style: _pixel(7, _muted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// The boss's patience over the whole level: a finale's every round, a
  /// tick between each.
  Widget _patienceBar() {
    final plan = _plan;
    final total = plan.totalHp;
    final left = plan.hpLeft(min(_round, plan.lastRound), _run.patience);
    // Where each round after the first begins, from the bar's start.
    final ticks = <double>[];
    var after = total;
    for (final round in plan.rounds.take(plan.lastRound)) {
      after -= round.hp;
      ticks.add(after / total);
    }
    return Semantics(
      label: '${_boss.name} patience $left of $total',
      child: Container(
        height: 14,
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border.all(color: _muted, width: 2),
        ),
        child: LayoutBuilder(
          builder: (context, box) => Stack(
            children: [
              FractionallySizedBox(
                alignment: AlignmentDirectional.centerStart,
                widthFactor: (left / total).clamp(0.0, 1.0),
                child: Container(color: _hurtRed),
              ),
              for (final at in ticks)
                PositionedDirectional(
                  start: (box.maxWidth * at - 1).roundToDouble(),
                  top: 0,
                  bottom: 0,
                  width: 2,
                  child: Container(color: Colors.black),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- arena --

  /// The boss's two poses, built once per boss.
  final Map<String, List<Widget>> _bossSprites = {};

  List<Widget> _bossPoses() => _bossSprites.putIfAbsent(
        _boss.id,
        () => [
          SvgPicture.asset(_boss.asset, fit: BoxFit.fill),
          SvgPicture.asset(_boss.openAsset, fit: BoxFit.fill),
        ],
      );

  Widget? _petSprite;
  double _petSpriteSize = 0;
  Widget? _frogSprite;
  double _frogSpriteSize = 0;

  /// The pet widget, built once per size so a frame never rebuilds its rig —
  /// or, while the witch's hex holds, the frog it has been turned into.
  Widget _pet(double size) {
    if (_frog > 0) {
      if (_frogSprite == null || _frogSpriteSize != size) {
        _frogSpriteSize = size;
        _frogSprite = CharacterSprite(
          width: size,
          height: size,
          groundShadow: true,
          // Any frog, not one the player may have painted: it is the
          // witch's frog, and it has nothing on.
          previewType: 'frog',
          naturalCoat: true,
          previewAccessories: const [],
          previewState: PetVisualState.sad,
        );
      }
      return _frogSprite!;
    }
    if (_petSprite == null || _petSpriteSize != size) {
      _petSpriteSize = size;
      _petSprite = CharacterSprite(
        width: size,
        height: size,
        groundShadow: true,
        // The pet in a fight idles awake whatever its mood at home, but keeps
        // its own coat and whatever it is wearing.
        previewType: _petType,
      );
    }
    return _petSprite!;
  }

  /// The clock the HUD shows: this wave's read time, this scroll's fuse, and
  /// so on — the number worth tuning in whichever round is on.
  double _hudSeconds() {
    final patience = _clockPatience;
    final Duration clock;
    switch (_opener) {
      case TrialOpener.hexScroll:
        if (_read != null) return _fuseSeconds;
        clock = BossTrialRules.fuseTime(words: 4, patience: patience);
      case TrialOpener.crystalEcho:
        if (_echo != null) return _echoSeconds;
        clock = CrystalRules.echoTime(words: 4, patience: patience);
      case TrialOpener.crystalSpikes:
        // The first spike's: the one that sets the pace.
        clock = CrystalRules.spikeTime(rank: 0, patience: patience);
      case TrialOpener.shardVolley:
        if (_volley != null) return _shardSeconds;
        clock = CrystalRules.shardFlight(patience);
      case TrialOpener.catchWords:
        clock = BossTrialRules.readTime(patience);
      case TrialOpener.shellGame:
        clock = MossRules.revealTime(patience);
      case TrialOpener.pebblePop:
        clock = MossRules.popUp(patience);
      case TrialOpener.steppingStones:
        clock = MossRules.sinkTime(patience);
      case TrialOpener.mirrorClones:
        if (_clones case final c?) return c.fuseSeconds;
        clock = WitchRules.cloneTime(words: 4, patience: patience);
      case TrialOpener.tangledSpells:
        if (_tangle case final t?) return t.fuseSeconds;
        clock = WitchRules.tangleTime(words: 6, patience: patience);
      case TrialOpener.broomChase:
        if (_chase case final c?) return c.escapeSeconds;
        clock = WitchRules.chaseTime(words: 4, patience: patience);
      case TrialOpener.lure:
        if (_lure case final l?) return l.lightSeconds;
        clock = AnglerRules.lureTime(words: 4, patience: patience);
      case TrialOpener.letterBubbles:
        if (_bubbles case final b?) return b.gulpSeconds;
        clock = AnglerRules.gulpTime(letters: 5, patience: patience);
      case TrialOpener.shoal:
        clock = AnglerRules.shoalTime(patience);
      case TrialOpener.riddle:
        if (_riddle case final r?) return r.seconds;
        clock = SphinxRules.riddleTime(words: 20, patience: patience);
      case TrialOpener.sealedDoor:
        if (_door case final d?) return d.seconds;
        clock = SphinxRules.doorTime(words: 5, patience: patience);
      case TrialOpener.tablets:
        if (_tablets case final t?) return t.seconds;
        clock = SphinxRules.tabletTime(words: 12, patience: patience);
      case TrialOpener.parley:
        if (_parley case final p?) return p.turnSeconds;
        clock = DragonRules.parleyTime(words: 12, patience: patience);
      case TrialOpener.flameLink:
        if (_link case final l?) return l.seconds;
        clock = DragonRules.linkTime(words: 10, patience: patience);
      case TrialOpener.paraphrase:
        if (_embers case final e?) return e.seconds;
        clock = DragonRules.paraphraseTime(words: 14, patience: patience);
      case TrialOpener.vein:
        if (_vein case final v?) return v.seconds;
        clock = CrystalRules.veinTime(words: 4, patience: patience);
      case TrialOpener.net:
        if (_net case final n?) return n.seconds;
        clock = AnglerRules.netTime(fish: 6, patience: patience);
      case TrialOpener.sandstorm:
        if (_storm case final st?) return st.seconds;
        clock = SphinxRules.stormTime(letters: 5, patience: patience);
      case TrialOpener.hoard:
        clock = DragonRules.hoardTime(patience);
    }
    return clock.inMilliseconds / 1000;
  }

  BossPose _bossPose() {
    final flee = _fleeTime;
    if (flee != null && !_reduceMotion) return _getawayPose(flee);
    if (_boss.flies) return _witchPose();
    final BossPose pose;
    final hit = _bossHitTime;
    final jump = _jumpTime;
    if (hit != null) {
      pose = BossMotion.hit(_dur(hit));
    } else if (jump != null && _dur(jump) < BossMotion.jumpEnds) {
      pose = BossMotion.jump(_dur(jump));
    } else {
      // Breathing hard while it charges.
      pose = BossMotion.idle(_dur(_time));
    }
    // Open to shout at the top of a jump, or to hurl a shard.
    final mouthOpen = (jump != null &&
            _dur(jump) >= BossMotion.shoutAt &&
            _dur(jump) < BossMotion.shoutAt + BossMotion.shout) ||
        _cackleTime != null;
    if (_reduceMotion) {
      return BossPose(mouthOpen: mouthOpen, flash: pose.flash);
    }
    return BossPose(
      lift: pose.lift,
      scaleX: pose.scaleX,
      scaleY: pose.scaleY,
      dx: pose.dx,
      mouthOpen: mouthOpen,
      flash: pose.flash,
    );
  }

  /// The witch: hovering or mid-swoop, with a flinch laid over either.
  BossPose _witchPose() {
    // Bobbing faster while she brews.
    final hoverT = _dur(_time);
    final jump = _jumpTime;
    final BossPose base;
    if (jump != null) {
      base = WitchMotion.swoopFrom(
        _dur(jump),
        from: _swoopFrom,
        to: _side,
        hoverT: hoverT,
      );
    } else {
      base = BossPose(lift: WitchMotion.hover(hoverT).lift, drift: _side);
    }
    final hit = _bossHitTime;
    final flinch = hit != null ? BossMotion.hit(_dur(hit)) : BossPose.rest;
    final mouthOpen = base.mouthOpen || _cackleTime != null;
    if (_reduceMotion) {
      // Still changes sides — where she is matters — but in one step.
      return BossPose(drift: _side, mouthOpen: mouthOpen, flash: flinch.flash);
    }
    return BossPose(
      lift: base.lift,
      scaleX: base.scaleX * flinch.scaleX,
      scaleY: base.scaleY * flinch.scaleY,
      dx: flinch.dx,
      drift: base.drift,
      mouthOpen: mouthOpen,
      flash: flinch.flash,
    );
  }

  /// Where the boss's top-left corner is drawn this frame, [pose] applied.
  Offset _bossOrigin(_Geo geo, BossPose pose) =>
      Offset(
        (geo.bossLeft + pose.dx + pose.drift * geo.swayPx).roundToDouble(),
        geo.bossTop - (pose.lift * geo.jumpPx).roundToDouble(),
      ) +
      _fleeOffset(geo);

  /// Where hits land on the boss, wherever it is this frame.
  Offset _bossHitPoint(_Geo geo) {
    final at = _bossOrigin(geo, _bossPose());
    return at + Offset(geo.bossW * _boss.hitX, geo.bossH * _boss.hitY);
  }

  /// The boss's mouth, wherever it is this frame: where the shout's tail
  /// points and the witch's hex sets off from.
  Offset _bossMouth(_Geo geo) {
    final at = _bossOrigin(geo, _bossPose());
    return at + Offset(geo.bossW * _boss.mouthX, geo.bossH * 0.5);
  }

  /// The witch's scroll, laid out where the charge bar and stones would be:
  /// the Spells round's table, which it never shares.
  double _scrollTop(_Geo geo) => geo.chargeTop;
  double _scrollBottom(_Geo geo) => geo.stonesBottom;
  Offset _scrollCentre(_Geo geo) =>
      Offset(geo.w / 2, (_scrollTop(geo) + _scrollBottom(geo)) / 2);

  /// Where the scroll's lower edge is drawn. The scroll sits in the middle of
  /// its box at its own size, so that is well above the box's bottom.
  double _scrollEdge(_Geo geo) => _drawnRect(
        _scrollKey,
        Rect.fromLTRB(0, _scrollTop(geo), geo.w, _scrollBottom(geo)),
      ).bottom;

  /// Where the widget [key] is on is drawn, in the arena's own coordinates —
  /// shrunk to fit and all — or [fallback] before it has been.
  Rect _drawnRect(GlobalKey key, Rect fallback) {
    final context = key.currentContext;
    final box = context?.findRenderObject();
    final arena = context?.findAncestorRenderObjectOfType<RenderStack>();
    if (box is! RenderBox || !box.hasSize || arena == null) return fallback;
    return Rect.fromPoints(
      box.localToGlobal(Offset.zero, ancestor: arena),
      box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: arena),
    );
  }

  /// The arena's scenery, built once per layout.
  ///
  /// The clock rebuilds the arena every frame, and the scenery is the one
  /// part of it that never changes within a layout. Handing back the same
  /// widgets means the element tree skips them instead of walking four
  /// pictures sixty times a second.
  _Geo? _sceneryFor;
  late Widget _backdrop, _ledge;

  void _scenery(_Geo geo) {
    if (identical(_sceneryFor, geo)) return;
    _sceneryFor = geo;
    _backdrop = ArenaBackdrop(
      art: geo.art,
      width: geo.w,
      height: geo.h,
      ledgeTop: geo.ledgeTop,
      groundTop: geo.groundTop,
    );
    _ledge = ArenaLedge(art: geo.art);
  }

  Widget _buildArena(_Geo geo) {
    _scenery(geo);
    final pose = _bossPose();
    final origin = _bossOrigin(geo, pose);
    final shake = _shake > 0
        ? Offset((sin(_time * 90) * 6 * (_shake / 0.3)).roundToDouble(),
            (cos(_time * 70) * 3 * (_shake / 0.3)).roundToDouble())
        : Offset.zero;

    final wave = _wave;
    final children = <Widget>[
      Positioned.fill(child: _backdrop),
      // Its shadow stays on the ledge while it is in the air — not once it
      // has leapt away.
      if (!_boss.flies &&
          (_fleeTime == null || _dur(_fleeTime!) < BossMotion.launchAt))
        Positioned(
          left: geo.bossLeft + geo.bossW * (0.15 + 0.12 * pose.lift),
          width: geo.bossW * (0.7 - 0.24 * pose.lift),
          top: geo.ledgeTop - 2,
          height: 6,
          child: Container(color: Colors.black.withValues(alpha: 0.35)),
        ),
      if (_riverUp) ..._buildRiver(geo),
      if (!_bossHidden)
        Positioned(
          left: origin.dx,
          top: origin.dy,
          width: geo.bossW,
          height: geo.bossH,
          child: Transform(
            alignment: Alignment.bottomCenter,
            transform: Matrix4.diagonal3Values(pose.scaleX, pose.scaleY, 1),
            child: ColorFiltered(
              colorFilter: pose.flash
                  ? const ColorFilter.mode(Colors.white, BlendMode.srcATop)
                  : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  IndexedStack(
                    index: pose.mouthOpen ? 1 : 0,
                    sizing: StackFit.expand,
                    children: _bossPoses(),
                  ),
                  // The dragon asleep on its hoard, its eyes opening.
                  if (_hoard case final hoard?
                      when _stage != _Stage.jumping && !hoard.lost)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DragonEyelids(open: _hoardEyeOpen(hoard)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      if (!_boss.flies)
        Positioned(
          left: 0,
          right: 0,
          top: geo.ledgeTop,
          height: geo.ledgeH,
          child: _ledge,
        ),
      Positioned.fill(
        child: IgnorePointer(
          child: CustomPaint(
            painter: TrialParticlePainter(_particles, front: false),
          ),
        ),
      ),
      if (_shoutText case final said? when _shouting) _buildShout(geo, said),
      if (_read != null) ..._buildScrollBoard(geo, _read!),
      if (_spikes != null && _stage != _Stage.jumping)
        ..._buildSpikes(geo, _spikes!),
      if (_echo != null && _stage != _Stage.jumping) ..._buildEcho(geo, _echo!),
      ..._buildMossRounds(geo),
      ..._buildWitchRoundsBehind(geo),
      ..._buildAnglerRoundsBehind(geo),
      if (_fishBounce case final bounce?) _buildFishBounce(geo, bounce),
      if (_rubbleVisible && wave != null)
        for (var lane = 0; lane < wave.lanes.length; lane++)
          Positioned.fromRect(
            rect: geo.tileRect(lane, _fall),
            child: RubbleTile(
              label: wave.lanes[lane].meaning,
              style: _pixel(11, _ink, localeCode: _nativeCode),
              onTapDown: () => _commit(lane),
            ),
          ),
      // A right pick: every other piece plunges to the ground as the picked
      // one drops on the pet, to crumble there.
      if (_throw case final thrown? when !thrown.caught && wave != null)
        for (var lane = 0; lane < wave.lanes.length; lane++)
          if (lane != thrown.lane)
            Positioned.fromRect(
              rect: geo.tileRect(lane, thrown.fallProgress),
              child: RubbleTile(
                label: wave.lanes[lane].meaning,
                style: _pixel(11, _ink, localeCode: _nativeCode),
                onTapDown: () {},
              ),
            ),
      // The sphinx's and the dragon's tablets sit in a field over the pet's
      // head, and it leaps at them: in front of them, then.
      if (!_petOverField) _buildPet(geo),
      ..._buildWitchRoundsFront(geo),
      ..._buildAnglerRoundsFront(geo),
      ..._buildSphinxRounds(geo),
      ..._buildDragonRounds(geo),
      if (_petOverField) _buildPet(geo),
      ..._buildSphinxFront(geo),
      ..._buildDragonFront(geo),
      ..._buildHeldFront(geo),
      if (_vein case final round?) ..._buildVein(geo, round),
      for (final shard in _inFlight) _buildShard(geo, shard),
      for (final shot in _shots)
        if (shot.t >= shot.delay)
        switch (shot.look) {
          _ShotLook.crystal =>
            _flying(_shotAt(geo, shot), 26, const CrystalChunk()),
          _ShotLook.gem ||
          _ShotLook.spell =>
            _flying(_shotAt(geo, shot), shot.big ? 40 : 22, const SpellBolt()),
          _ShotLook.ember =>
            _flying(_shotAt(geo, shot), 30, const FireballSprite()),
          _ShotLook.rock => _flying(_shotAt(geo, shot), 28, const ThrownRock()),
          _ShotLook.butt || _ShotLook.fish => const SizedBox.shrink(),
        },
      if (_throw != null) _buildThrow(geo, _throw!),
      if (_bolt case final bolt?)
        bolt.label == null
            ? _flying(_boltAt(geo, bolt), 22, const SpellBolt())
            : _flyingWord(_boltAt(geo, bolt), bolt),
      // The hex bolt is drawn over the scroll it came off.
      if (_boulder != null) _buildFallingBoulder(geo, _boulder!),
      Positioned.fill(
        child: IgnorePointer(
          child: CustomPaint(
            painter: TrialParticlePainter(_particles, front: true),
          ),
        ),
      ),
      for (final p in _popups) _buildPopup(p),
      if (_stage == _Stage.announcing && _dur(_stageTime) >= _shoutAt)
        _buildAnnouncement(geo),
      if (_hurtTint > 0)
        Positioned.fill(
          child: IgnorePointer(
            child: Container(color: _hurtRed.withValues(alpha: 0.18)),
          ),
        ),
    ];

    return ClipRect(
      child: Transform.translate(
        offset: shake,
        // Every piece under it drawn in this boss's own look.
        child: TrialSkinScope(
          skin: _boss.skin,
          child: Stack(children: children),
        ),
      ),
    );
  }

  /// What the boss is shouting, while it shouts: the word of a wave, a shell
  /// game or a row of the river, or Amethyst's roared sentence.
  String? get _shoutText =>
      _wave?.prompt.target ??
      _echo?.wave.sentence.target ??
      _shell?.game.prompt.target ??
      _crossingShout;

  /// The boss's shout: a word, or Amethyst's roared sentence.
  Widget _buildShout(_Geo geo, String said) {
    final width = geo.w - 2 * _Geo.bubbleInset;
    final tailX =
        (_bossMouth(geo).dx - _Geo.bubbleInset).clamp(24.0, width - 24.0);
    return Positioned(
      left: _Geo.bubbleInset,
      top: _Geo.bubbleTop,
      width: width,
      height: _Geo.bubbleH + ShoutBubble.tailH,
      child: ShoutBubble(
        word: said,
        style: _pixel(18, _ink, localeCode: _languageCode),
        tailX: tailX,
      ),
    );
  }

  /// Whether the pet is drawn over the round's tablets rather than under them.
  bool get _petOverField => _boss.buriesPet || _boss.scorchesPet;

  /// How big the pet is drawn: its box, smaller on the broom, and growing back
  /// to full size as it falls from the headbutt.
  double _petSize(_Geo geo) => (geo.petBox *
          (_petScale + (1 - _petScale) * (_move?.grow ?? 0)))
      .roundToDouble();

  /// How far off where it stands the pet's body is this frame — across, up
  /// (positive) and squashed — for everything it is doing at once.
  ({double dx, double lift, double scaleX, double scaleY, double tilt})
      _petPose(double size) {
    final move = _move;
    var lift = 0.0;
    var dx = 0.0;
    var scaleX = 1.0;
    var scaleY = 1.0;
    if (_petHop >= 0) {
      lift = ((sin(_petHop / 0.3 * pi) * 18) / 2).roundToDouble() * 2;
    }
    if (_petHurt >= 0) {
      final k = _petHurt / 0.35;
      dx = (sin(_petHurt * 60) * 5 * (1 - k)).roundToDouble();
      if (_petHurt < 0.12) scaleY = 0.92;
    } else if (_spikeClose && !_reduceMotion) {
      // A spike nearly on it: it trembles.
      dx = (sin(_time * 55) * 2).roundToDouble();
    }
    // Whatever its body is doing: leaping at the boss, pouncing, throwing,
    // being squashed.
    if (move != null) {
      final o = move.offset;
      dx += o.dx;
      lift += o.dy;
      scaleY *= move.squash;
      scaleX = move.width;
    }
    // Running for the rubble: a hop to every stride, in steps.
    if (_petMoving) {
      final arc = sin(_petStride / 36 * pi).abs();
      lift += (((arc * 3).round() / 3 * _petHopPx) / 2).roundToDouble() * 2;
    }
    // A frog hops about, ribbiting, until the smoke takes it back.
    lift += _frogHop();
    // Up out of the river onto the bank with a small hop, a squat either end.
    if (_petSpring >= 0) {
      final k = _petSpring / _springSeconds;
      lift += ((sin(k * pi) * 24) / 2).roundToDouble() * 2;
      if (k < 0.12 || k > 0.88) scaleY *= 0.9;
    }
    // Sagging as the amethyst climbs it: heavier and slower.
    if (_stage == _Stage.echoing && !_reduceMotion) scaleY *= 1 - 0.1 * _creep;
    // Trembling: the amethyst creeping up it, or cracking round it.
    final shiver = _shiverNow();
    if (shiver > 0 && !_reduceMotion) {
      dx += (sin(_shiverPhase) * shiver).roundToDouble();
    }
    // Trapped in a bubble, it floats up off the seabed and bobs; before that,
    // the water pulls at it more and more as the maw closes. Buried, it sinks
    // into the sand.
    final pull = _pull();
    dx += pull.dx;
    lift += _bubbleLift(size) + pull.lift - _burySink();
    return (
      dx: dx,
      lift: lift,
      scaleX: scaleX,
      scaleY: scaleY,
      // Leaning into the wind, in the sandstorm; drawn toward the maw, at the
      // end of Lanternmaw's clock.
      tilt: pull.tilt +
          _stormLean() +
          _fuseWobble() +
          _veinLookUp() +
          _shedWobble(),
    );
  }

  Widget _buildPet(_Geo geo) {
    final move = _move;
    final size = _petSize(geo);
    final pose = _petPose(size);
    final dx = pose.dx, lift = pose.lift, scaleY = pose.scaleY;
    // Amethyst creeping up it through the echo, or sealing it in.
    final sealed = _encased > 0;
    final ash = _scorchFill();
    final amethyst = sealed
        ? 1.0
        : _stage == _Stage.echoing
            ? _creep
            : 0.0;
    final feet = _petFeet ?? geo.groundTop;
    // Sunk the pet's whole height by the end, the water line hiding the rest:
    // the box's top is a tenth of it above the feet.
    final dunk = (_petDunk * size * 0.9).roundToDouble();
    final pet = Positioned(
      left: (_petX - size / 2 + dx).roundToDouble(),
      top: feet - size + size * 0.1 - lift + dunk,
      width: size,
      height: size,
      child: Transform(
        key: const ValueKey('pet-squash'),
        alignment: Alignment.bottomCenter,
        transform: Matrix4.diagonal3Values(pose.scaleX, scaleY, 1),
        // Always the same tree, so the pet's rig is never rebuilt when the
        // amethyst comes and goes — nor when the headbutt tips it over.
        child: Transform.rotate(
          key: const ValueKey('pet-tilt'),
          angle: (move?.tilt ?? 0) + pose.tilt,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColorFiltered(
                colorFilter: sealed
                    ? ColorFilter.mode(
                        CrystalPalette.violet.withValues(alpha: 0.3),
                        BlendMode.srcATop,
                      )
                    : ash > 0
                        ? ColorFilter.mode(
                            DragonPalette.ash.withValues(alpha: 0.75 * ash),
                            BlendMode.srcATop,
                          )
                        : const ColorFilter.mode(
                            Colors.transparent, BlendMode.dst),
                // Turned about at once, like the rest of the pet's pixel moves.
                child: Transform.flip(
                  key: const ValueKey('pet-flip'),
                  flipX: _petFacesLeft,
                  child: _pet(size),
                ),
              ),
              IgnorePointer(
                child: CustomPaint(painter: CrystalCasePainter(amethyst)),
              ),
              IgnorePointer(
                child: CustomPaint(
                  painter: PetBubblePainter(_bubbleFill()),
                ),
              ),
              IgnorePointer(
                child: CustomPaint(
                  painter: SandPilePainter(_sandFill()),
                ),
              ),
              if (_singed > 0)
                IgnorePointer(
                  child: CustomPaint(
                    painter: WhiskerSootPainter(
                      fade: _singed / _singeSeconds,
                      facesLeft: _petFacesLeft,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    // The broom and the river's surface line are always in the tree, empty
    // when not wanted, for the same reason: the pet's place in it never moves.
    // Nothing here takes a tap; what is under the pet still can.
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            Positioned(
              // Bristles behind the pet, the handle out ahead of it.
              left: (_petX + dx - size * 0.85).roundToDouble(),
              top: (feet - 16 - lift).roundToDouble(),
              width: size * 1.7,
              height: 32,
              child: _onBroom
                  ? const CustomPaint(painter: BroomPainter())
                  : const SizedBox.shrink(),
            ),
            // Sinking into the river, it is cut off at the surface — where
            // its feet were on the stone — and the river shows through.
            Positioned.fill(
              child: ClipRect(
                key: const ValueKey('pet-waterline'),
                clipper: WaterlineClipper(_petDunk > 0 ? feet : null),
                child: Stack(children: [pet]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Amethyst's spikes growing down from the ledge, and the pet's gems in
  /// the grass.
  List<Widget> _buildSpikes(_Geo geo, SpikeRush rush) {
    final wave = rush.wave;
    final flashing = _fizzleFlash > 0;
    CrystalPieceState spikeState(int lane) {
      if (rush.heldSpike == lane) return CrystalPieceState.held;
      if (flashing && _flashLane == lane) return CrystalPieceState.flashing;
      return CrystalPieceState.plain;
    }

    CrystalPieceState gemState(int gem) {
      if (rush.isGemUsed(gem)) return CrystalPieceState.spent;
      if (rush.heldGem == gem) return CrystalPieceState.held;
      if (flashing && _flashGem == gem) return CrystalPieceState.flashing;
      return CrystalPieceState.plain;
    }

    final shake = flashing && !_reduceMotion
        ? (sin(_fizzleFlash * 80) * 4).roundToDouble()
        : 0.0;
    return [
      // The shafts, under their plates and behind the pet they close on.
      Positioned.fill(
        child: IgnorePointer(
          child: CustomPaint(
            painter: SpikeShaftsPainter(
              [
                for (var lane = 0; lane < wave.spikes.length; lane++)
                  if (_spikeStands(rush, lane))
                    SpikeShaft(
                      root: geo.spikeRoot(lane),
                      tip: geo.spikeTip(lane, _spikeGrowth[lane]),
                      danger: _spikeGrowth[lane] >= _spikeDanger,
                    ),
              ],
              flashOn: (_time * 6).floor().isEven,
            ),
          ),
        ),
      ),
      for (var lane = 0; lane < wave.spikes.length; lane++)
        if (_spikeStands(rush, lane))
          Positioned.fromRect(
            rect: geo
                .spikePlate(lane)
                .translate(lane == _flashLane ? shake : 0, 0),
            child: CrystalSpike(
              label: wave.spikes[lane].target,
              style: _pixel(11, _ink, localeCode: _languageCode),
              state: spikeState(lane),
              onTapDown: () => _tapSpike(lane),
            ),
          ),
      for (var gem = 0; gem < wave.gems.length; gem++)
        Positioned.fromRect(
          rect: geo.gemRect(gem).translate(gem == _flashGem ? shake : 0, 0),
          child: CrystalGem(
            label: wave.gems[gem].meaning,
            style: _pixel(10, _ink, localeCode: _nativeCode),
            state: gemState(gem),
            onTapDown: () => _tapGem(gem),
          ),
        ),
    ];
  }

  /// The three crystals Amethyst's echo raises.
  List<Widget> _buildEcho(_Geo geo, EchoListen listen) {
    final wave = listen.wave;
    CrystalPieceState stateOf(int i) {
      // Picked, it stays up, lit, until the pet's head hits it.
      if (i == wave.answer && listen.isHeard && _crystalHeld) {
        return CrystalPieceState.held;
      }
      if (i == wave.answer && listen.isHeard) return CrystalPieceState.spent;
      if (i == wave.answer && _echoRevealed) return CrystalPieceState.revealed;
      if (_fizzleFlash > 0 && i == _fizzleStone) {
        return CrystalPieceState.flashing;
      }
      if (listen.wrong.contains(i)) return CrystalPieceState.wrong;
      return CrystalPieceState.plain;
    }

    final shake = _fizzleFlash > 0 && !_reduceMotion
        ? (sin(_fizzleFlash * 80) * 4).roundToDouble()
        : 0.0;
    return [
      for (var i = 0; i < wave.options.length; i++)
        Positioned.fromRect(
          rect: geo.echoRect(i).translate(i == _fizzleStone ? shake : 0, 0),
          child: EchoCrystal(
            label: wave.options[i].meaning,
            style: _pixel(11, _ink, localeCode: _nativeCode),
            state: stateOf(i),
            onTapDown: () => _tapEcho(i),
          ),
        ),
    ];
  }

  /// One of Amethyst's shards in the air.
  Widget _buildShard(_Geo geo, _Shard shard) {
    return Positioned.fromRect(
      rect: _shardRect(geo, shard),
      child: VolleyShardTile(
        word: shard.shard.word.target,
        claim: shard.shard.claim,
        wordStyle: _pixel(11, _ink, localeCode: _languageCode),
        claimStyle: _pixel(8, _ink, localeCode: _nativeCode),
        onTapDown: () => _tapShard(shard),
      ),
    );
  }

  Widget _buildThrow(_Geo geo, _Throw thrown) {
    // Where the pet holds it: just above its head, in the picked lane — and
    // where it has gone, squatting, leaning back and snapping forward.
    final hands = _heldRock(geo, thrown);
    final Offset p;
    final double scale;
    final released = thrown.releasedAt;
    if (!thrown.caught) {
      final k = thrown.t / thrown.dropSeconds;
      p = Offset.lerp(thrown.from, hands, k * k)!;
      scale = 0.9;
    } else if (released == null) {
      p = hands;
      scale = 0.9;
    } else {
      final k = ((thrown.t - released) / _throwSeconds).clamp(0.0, 1.0);
      final from = thrown.releaseFrom;
      final to = _bossHitPoint(geo);
      final control = Offset((from.dx + to.dx) / 2, to.dy - 60);
      // A quadratic arc: up and over, onto the shell.
      p = Offset(
        (1 - k) * (1 - k) * from.dx +
            2 * (1 - k) * k * control.dx +
            k * k * to.dx,
        (1 - k) * (1 - k) * from.dy +
            2 * (1 - k) * k * control.dy +
            k * k * to.dy,
      );
      scale = 0.9 - 0.4 * k;
    }
    // Smaller as it flies away, in 4px steps.
    final size = (((geo.tileH * scale) / 4).round() * 4).toDouble();
    return Positioned(
      left: (p.dx - size / 2).roundToDouble(),
      top: (p.dy - size / 2).roundToDouble(),
      width: size,
      height: size,
      child: const IgnorePointer(child: ThrownRock()),
    );
  }

  /// The witch's scroll: the spell as she reads it, and what it should say.
  List<Widget> _buildScrollBoard(_Geo geo, HexRead read) {
    final scroll = read.scroll;
    ScrollWordState stateOf(int i) {
      if (i == scroll.hexed && read.isBroken && (_wordSwatted || _reduceMotion)) {
        return ScrollWordState.broken;
      }
      if (i == scroll.hexed && _hexRevealed) return ScrollWordState.hexed;
      if (_fizzleFlash > 0 && i == _fizzleStone) {
        return ScrollWordState.flashing;
      }
      if (read.wrong.contains(i)) return ScrollWordState.wrong;
      return ScrollWordState.plain;
    }

    final shake = _fizzleFlash > 0 && !_reduceMotion
        ? (sin(_fizzleFlash * 80) * 4).roundToDouble()
        : 0.0;
    // Nothing until she arrives and reads it out: the prompt showing early
    // would be reading time the fuse never counts.
    if (_stage == _Stage.jumping) return const [];
    return [
      Positioned(
        left: 12,
        right: 12,
        top: _scrollTop(geo),
        height: _scrollBottom(geo) - _scrollTop(geo),
        child: Center(
          child: Transform.translate(
            offset: Offset(shake, 0),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: geo.w - 24),
                child: HexScrollBoard(
                  key: _scrollKey,
                  words: scroll.words,
                  style: _pixel(11, _ink, localeCode: _languageCode),
                  stateOf: stateOf,
                  onTap: _tapWord,
                  fuse: _fuse,
                  textDirection: _languageCode == 'ar'
                      ? TextDirection.rtl
                      : TextDirection.ltr,
                ),
              ),
            ),
          ),
        ),
      ),
      Positioned(
        left: _Geo.spellInset,
        right: _Geo.spellInset,
        top: geo.promptTop,
        height: _Geo.promptH,
        child: SpellPrompt(
          label: 'WHAT IT SHOULD SAY',
          meaning: scroll.sentence.meaning,
          labelStyle: _pixel(7, const Color(0xFF7A4E2D)),
          meaningStyle: _pixel(12, _ink, localeCode: _nativeCode),
        ),
      ),
    ];
  }

  /// A [size]-pixel [child] centred on [at], on whole pixels.
  /// A word the pet swatted, turning end over end on its way to her.
  Widget _flyingWord(Offset at, _Flight flight) => Positioned(
        left: (at.dx - 52).roundToDouble(),
        top: (at.dy - 17).roundToDouble(),
        width: 104,
        height: 34,
        child: IgnorePointer(
          child: Transform.rotate(
            angle: flight.t * 20,
            child: TangleTile(
              label: flight.label!,
              style: _pixel(10, _ink, localeCode: _languageCode),
              state: HexPieceState.wrong,
            ),
          ),
        ),
      );

  Widget _flying(Offset at, double size, Widget child) => Positioned(
        left: (at.dx - size / 2).roundToDouble(),
        top: (at.dy - size / 2).roundToDouble(),
        width: size,
        height: size,
        child: IgnorePointer(child: child),
      );

  /// Where the boss's attack is, [boulder.t] into its flight: a hex flies
  /// straight at the pet; anything thrown goes up and over.
  Offset _boulderAt(_Geo geo, _Flight boulder) {
    final k = (boulder.t / _boulderSeconds).clamp(0.0, 1.0);
    final from = boulder.from;
    final to = geo.petHead(_petX);
    final control = _read != null
        ? Offset((from.dx + to.dx) / 2, (from.dy + to.dy) / 2)
        : Offset((from.dx + to.dx) / 2, from.dy - 70);
    return Offset(
      (1 - k) * (1 - k) * from.dx +
          2 * (1 - k) * k * control.dx +
          k * k * to.dx,
      (1 - k) * (1 - k) * from.dy +
          2 * (1 - k) * k * control.dy +
          k * k * to.dy,
    );
  }

  /// The witch's hex on its way to the pet.
  Widget _buildFallingBoulder(_Geo geo, _Flight boulder) =>
      _flying(_boulderAt(geo, boulder), 26, const SpellBolt(colors: HexPalette.bolt));

  /// The roar into a round after the first: the next of a finale's openings,
  /// or its last, the Spells round.
  Widget _buildAnnouncement(_Geo geo) {
    final round = _roundPlan;
    final title =
        _round == _plan.lastRound ? 'FINAL ROUND' : 'ROUND ${_round + 1}';
    final hint = _openingOf(round).name;
    final middle = (geo.stonesTop + geo.promptTop + _Geo.promptH) / 2;
    return Positioned(
      left: 24,
      right: 24,
      top: middle - 48,
      height: 96,
      child: IgnorePointer(
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _ink,
            border: Border.all(color: _gold, width: 4),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title, style: _pixel(20, _gold)),
              const SizedBox(height: 12),
              Text(hint, style: _pixel(8, AppTheme.retroLight)),
            ],
          ),
        ),
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
          style: AppFonts.pressStart2p(
            fontSize: 10,
            color: p.color,
            shadows: const [Shadow(color: Colors.black, offset: Offset(2, 2))],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- panel --

  /// Whether this boss has anything to fight with in this language.
  bool get _playable =>
      _opener.needsSentences || TrialWordPool.isPlayable(_pool);

  Widget _buildPanel() {
    final playable = _playable;
    return Container(
      color: Colors.black.withValues(alpha: 0.55),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.retroLight,
            border: Border.all(color: _ink, width: 4),
          ),
          child: SingleChildScrollView(
            child: _phase == _Phase.over
                ? _buildResults()
                : playable
                    ? _buildIntro()
                    : _buildNoWords(),
          ),
        ),
      ),
    );
  }

  Widget _buildIntro() {
    final stock = _pool.length - _ownWordCount;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.picker) ...[
          _bossPicker(),
          const SizedBox(height: 16),
        ],
        Text(
            'LEVEL $_levelNumber · '
            '${_plan.isFinale ? 'FINALE' : _openingOf(_roundPlan).name}',
            style: _pixel(8, AppTheme.retroOrange)),
        const SizedBox(height: 10),
        Text(_boss.name, style: _pixel(18, _ink)),
        if (widget.picker) ...[
          const SizedBox(height: 14),
          _stepPicker(),
        ],
        if (_boss.advancedPreview) ...[
          const SizedBox(height: 12),
          _contentPicker(),
        ],
        const SizedBox(height: 14),
        if (_plan.isFinale) ...[
          _body('Its finale: all four of its attacks, a round each, one after '
              'another. It will not get away this time.'),
        ] else ...[
          _body(_openingOf(_roundPlan).intro),
          const SizedBox(height: 8),
          _body('Wear it down and it jumps away. You beat it for good at '
              'level ${_boss.level}, its finale.'),
        ],
        if (_advanced) ...[
          const SizedBox(height: 10),
          const Text(
            'Advanced English: words and sentences a high-level learner might '
            'face, with plain-English meanings. Your own words are left out.',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: AppTheme.retroOrange,
            ),
          ),
        ],
        if (_standIn case final yours?) ...[
          const SizedBox(height: 10),
          Text(
            'This opening only has English and Turkish in it so far, so '
            'instead of your languages ($yours) this run is in '
            '${_languageCode?.toUpperCase()} with '
            '${_nativeCode?.toUpperCase()} meanings.',
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: AppTheme.retroOrange,
            ),
          ),
        ],
        if (_ownPair case final yours?) ...[
          const SizedBox(height: 10),
          Text(
            'Your languages ($yours) give it nothing to fight with — every '
            'word would be its own answer — so this run is in '
            '${_languageCode?.toUpperCase()} with '
            '${_nativeCode?.toUpperCase()} meanings.',
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: AppTheme.retroOrange,
            ),
          ),
        ],
        const SizedBox(height: 12),
        Text(
          _needsEnTr
              ? 'ENGLISH + TURKISH TEST CONTENT'
              : _opener.needsSentences
                  ? '${_sentences.length} TEST SENTENCES'
                  : '${_pool.length} WORDS · $_ownWordCount YOURS · $stock TEST',
          style: _pixel(7, _muted),
        ),
        const SizedBox(height: 18),
        _button('START TRIAL', _start),
      ],
    );
  }

  /// Testing affordance: which trial to fight, since none is wired to its
  /// level yet.
  Widget _bossPicker() {
    // Three to a row: six in one would leave each name too small to read.
    const perRow = 3;
    final rows = [
      for (var i = 0; i < TrialBosses.all.length; i += perRow)
        TrialBosses.all.sublist(i, min(i + perRow, TrialBosses.all.length)),
    ];
    return Column(
      children: [
        for (final row in rows) ...[
          if (row != rows.first) const SizedBox(height: 8),
          _bossPickerRow(row, perRow),
        ],
      ],
    );
  }

  Widget _bossPickerRow(List<TrialBoss> bosses, int slots) {
    return Row(
      children: [
        for (final boss in bosses) ...[
          if (boss != bosses.first) const SizedBox(width: 8),
          Expanded(
            child: Semantics(
              button: true,
              selected: boss == _boss,
              child: GestureDetector(
                onTap: () => _pickBoss(boss),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: boss == _boss ? _ink : Colors.white,
                    border: Border.all(color: _ink, width: 3),
                  ),
                  // The level over the name, and shrunk rather than broken
                  // mid-word: four to a row leaves LANTERNMAW no room.
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'LV ${boss.level}\n${boss.name.toUpperCase()}',
                      textAlign: TextAlign.center,
                      style: _pixel(7, boss == _boss ? _gold : _ink)
                          .copyWith(height: 1.6),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        // A short last row keeps its buttons the width of the others.
        for (var i = bosses.length; i < slots; i++) ...[
          const SizedBox(width: 8),
          const Expanded(child: SizedBox.shrink()),
        ],
      ],
    );
  }

  /// Testing affordance: what to fight with — the player's own pair, or the
  /// advanced English set — for a boss whose first round is being chosen.
  Widget _contentPicker() => _pickerRow(
        label: 'CONTENT',
        choices: [
          ('NORMAL', !_advanced, () => _pickAdvanced(false)),
          ('ADVANCED EN', _advanced, () => _pickAdvanced(true)),
        ],
      );

  /// Testing affordance: which of the boss's levels to fight — each of its
  /// openings alone, then its finale — since none is wired to the player's
  /// level yet.
  Widget _stepPicker() {
    final first = _boss.level - (BossTrialRules.levelsPerBoss - 1);
    return _pickerRow(
      label: 'LEVELS $first–${_boss.level} · PICK ONE TO TRY',
      choices: [
        for (var step = 0; step < BossTrialRules.levelsPerBoss; step++)
          (
            step < _boss.openings.length
                ? _boss.openings[step].name
                : 'FINALE',
            step == _step,
            () => _pickStep(step),
          ),
      ],
    );
  }

  /// A labelled row of buttons, the chosen one filled in amethyst.
  Widget _pickerRow({
    required String label,
    required List<(String, bool, VoidCallback)> choices,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _pixel(7, _muted)),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 0; i < choices.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: Semantics(
                  button: true,
                  selected: choices[i].$2,
                  child: GestureDetector(
                    onTap: choices[i].$3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 2),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: choices[i].$2
                            ? CrystalPalette.purple
                            : Colors.white,
                        border: Border.all(color: _ink, width: 3),
                      ),
                      // Shrunk rather than cut: five to a row on a small
                      // phone leaves PEBBLES no room.
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          choices[i].$1,
                          textAlign: TextAlign.center,
                          style:
                              _pixel(7, choices[i].$2 ? Colors.white : _ink),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildNoWords() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.picker) ...[
          _bossPicker(),
          const SizedBox(height: 16),
        ],
        Text(_boss.name, style: _pixel(18, _ink)),
        const SizedBox(height: 14),
        _body(
          'There are not enough words to fight with in this language yet. '
          'A trial needs at least ${BossTrialRules.wordsPerWave} with different '
          'meanings: review a few more words, then come back.',
        ),
        const SizedBox(height: 18),
        _button('BACK', _leave),
      ],
    );
  }

  Widget _buildResults() {
    final won = _run.won;
    final finale = _plan.isFinale;
    final grade = _run.grade.name.toUpperCase();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          won
              ? finale
                  ? 'TRIAL CLEARED'
                  : 'IT GOT AWAY!'
              : _boss.lostTitle,
          style: _pixel(13, won ? AppTheme.retroGrassDark : _hurtRed),
        ),
        if (won) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              Text('GRADE', style: _pixel(9, _muted)),
              const SizedBox(width: 10),
              Text(grade, style: _pixel(26, AppTheme.retroOrange)),
            ],
          ),
          if (_firstClear.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('FIRST CLEAR', style: _pixel(8, AppTheme.retroOrange)),
            const SizedBox(height: 6),
            Text(
              _firstClear.map((r) => r.type == RewardType.coins ? '+${r.value} coins' : r.description).join(' · '),
              style: _pixel(8, _ink),
            ),
          ],
          if (!finale) ...[
            const SizedBox(height: 10),
            _body('Level $_levelNumber done. ${_boss.name} will be back, and '
                'at level ${_boss.level} it is beaten for good.'),
          ],
        ],
        const SizedBox(height: 14),
        Text(
          '${finale ? '${_run.caught} ANSWERED' : switch (_opener) {
            TrialOpener.catchWords => '${_run.caught} CAUGHT',
            TrialOpener.crystalSpikes => '${_run.caught} SHATTERED',
            TrialOpener.crystalEcho => '${_run.caught} HEARD',
            TrialOpener.shardVolley => '${_run.caught} CALLED',
            TrialOpener.hexScroll => '${_run.broken} BROKEN',
            TrialOpener.shellGame => '${_run.caught} FOUND',
            TrialOpener.pebblePop => '${_run.caught} BONKED',
            TrialOpener.steppingStones => '${_run.caught} HOPS',
            TrialOpener.mirrorClones => '${_run.caught} UNMASKED',
            TrialOpener.tangledSpells => '${_run.caught} SORTED',
            TrialOpener.broomChase => '${_run.caught} CAUGHT UP',
            TrialOpener.lure => '${_run.caught} HOOKED',
            TrialOpener.letterBubbles => '${_run.caught} SPELLED',
            TrialOpener.shoal => '${_run.caught} STRAYS',
            TrialOpener.riddle => '${_run.caught} SOLVED',
            TrialOpener.sealedDoor => '${_run.caught} OPENED',
            TrialOpener.tablets => '${_run.caught} TOLD',
            TrialOpener.parley => '${_run.caught} REPLIES',
            TrialOpener.flameLink => '${_run.caught} JOINED',
            TrialOpener.paraphrase => '${_run.caught} MATCHED',
            TrialOpener.vein => '${_run.caught} TRACED',
            TrialOpener.net => '${_run.caught} NETTED',
            TrialOpener.sandstorm => '${_run.caught} FOUND',
            TrialOpener.hoard => '${_run.caught} PAIRED',
          }} · BEST x${_run.bestCombo}',
          style: _pixel(7, _ink),
        ),
        const SizedBox(height: 16),
        if (_run.missed.isEmpty &&
            _run.missedSentences.isEmpty &&
            _run.missedScrolls.isEmpty)
          _body(won
              ? 'A clean run: every piece you picked and every spell you cast '
                  'was right.'
              : 'No wrong picks, just too slow. Try answering sooner.')
        else ...[
          if (_run.missed.isNotEmpty) ...[
            Text('WORDS TO PRACTISE', style: _pixel(8, AppTheme.retroOrange)),
            const SizedBox(height: 10),
            for (final word in _run.missed) _missedRow(word),
          ],
          if (_run.missedScrolls.isNotEmpty) ...[
            if (_run.missed.isNotEmpty) const SizedBox(height: 10),
            Text('SCROLLS TO PRACTISE', style: _pixel(8, AppTheme.retroOrange)),
            const SizedBox(height: 10),
            for (final s in _run.missedScrolls) _missedScrollRow(s),
          ],
          if (_run.missedSentences.isNotEmpty) ...[
            if (_run.missed.isNotEmpty || _run.missedScrolls.isNotEmpty)
              const SizedBox(height: 10),
            Text('SENTENCES TO PRACTISE',
                style: _pixel(8, AppTheme.retroOrange)),
            const SizedBox(height: 10),
            for (final s in _run.missedSentences) _missedSentenceRow(s),
          ],
        ],
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _button(
                won ? 'RUN IT AGAIN' : 'TRY AGAIN',
                () => _start(round: _startRound),
              ),
            ),
            const SizedBox(width: 10),
            _button('BACK', _leave, secondary: true),
          ],
        ),
      ],
    );
  }

  /// A scroll whose hex went off: what it should have said, and the word
  /// that was slipped in.
  Widget _missedScrollRow(HexScroll scroll) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(scroll.sentence.target,
              style: _pixel(9, _ink, localeCode: _languageCode)),
          const SizedBox(height: 4),
          Text('= ${scroll.sentence.meaning}',
              style:
                  _pixel(7, AppTheme.textSecondary, localeCode: _nativeCode)),
          const SizedBox(height: 4),
          Text('HEX: ${scroll.hexWord} FOR ${scroll.trueWord}',
              style: _pixel(7, HexPalette.hex, localeCode: _languageCode)),
        ],
      ),
    );
  }

  Widget _missedSentenceRow(TrialSentence sentence) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(sentence.target,
              style: _pixel(9, _ink, localeCode: _languageCode)),
          const SizedBox(height: 4),
          Text('= ${sentence.meaning}',
              style:
                  _pixel(7, AppTheme.textSecondary, localeCode: _nativeCode)),
        ],
      ),
    );
  }

  Widget _missedRow(TrialWord word) {
    final reading = word.reading;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 4,
        children: [
          Text(word.target, style: _pixel(10, _ink, localeCode: _languageCode)),
          if (reading != null && reading.isNotEmpty)
            Text('($reading)', style: _pixel(7, _muted)),
          Text('= ${word.meaning}',
              style:
                  _pixel(8, AppTheme.textSecondary, localeCode: _nativeCode)),
        ],
      ),
    );
  }

  Widget _body(String text) => Text(
        text,
        style: const TextStyle(fontSize: 14, height: 1.45, color: _ink),
      );

  Widget _button(String label, VoidCallback onTap, {bool secondary = false}) {
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: secondary ? Colors.white : _gold,
            border: Border.all(color: _ink, width: 3),
          ),
          child: Text(label, style: _pixel(9, _ink)),
        ),
      ),
    );
  }
}
