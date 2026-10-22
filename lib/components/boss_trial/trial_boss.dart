/// The milestone bosses: who a trial is against, what its rounds ask, and the
/// few numbers the arena needs to draw it.
///
/// One trial screen runs every boss; this is everything that differs between
/// them. The copy is English-only, like the rest of the trial prototype.
library;

import '../../utils/boss_trial.dart';
import 'trial_skin.dart';

export 'trial_skin.dart' show TrialSkin;

/// What a boss asks in its first round, while it has more than half its
/// patience.
enum TrialOpener {
  /// Mossback: a shouted word, and the rubble that means it.
  catchWords,

  /// Mossback: a shouted word's meaning under one of three shuffled cups.
  shellGame,

  /// Mossback: a meaning shown, and the pebble popping up that says it.
  pebblePop,

  /// Mossback: a river crossed a row at a time, each hop a shouted word's
  /// meaning.
  steppingStones,

  /// Amethyst: four roared words growing down as spikes, each to be paired
  /// with the gem that means it.
  crystalSpikes,

  /// Amethyst: a roared sentence, and the crystal that means it.
  crystalEcho,

  /// Amethyst: a volley of shards claiming meanings, the lies to be smashed.
  shardVolley,

  /// The witch: a spoken sentence with one word hexed, and finding it.
  hexScroll,

  /// The witch: three flying owls saying near-identical sentences, and
  /// finding the one that is her.
  mirrorClones,

  /// The witch: two spells' words tangled together, and sorting them apart.
  tangledSpells,

  /// The witch: a chase through gates, each the next word of the sentence.
  broomChase,

  /// Lanternmaw: a sentence on its lantern with a word missing, and the fish
  /// carrying the word that fills it.
  lure,

  /// Lanternmaw: a word's meaning, and bubbles carrying its letters to pop in
  /// order.
  letterBubbles,

  /// Lanternmaw: a school of five words, four of a kind, and the stray.
  shoal,

  /// Sableth: a little story, a question about it, and three answers.
  riddle,

  /// Sableth: a sentence with one word in its dictionary form, and a dial of
  /// forms to turn to the right one.
  sealedDoor,

  /// Sableth: three lines of a story on shuffled tablets, to put in order.
  tablets,

  /// Pyrewing: a conversation, three turns of picking the reply that answers
  /// it.
  parley,

  /// Pyrewing: two halves of a sentence, and the linking word that joins
  /// them.
  flameLink,

  /// Pyrewing: a sentence, and three embers saying other things, one of them
  /// the same thing another way.
  paraphrase,

  /// Amethyst: a sentence traced crystal by crystal through a wall of words.
  vein,

  /// Lanternmaw: every word of a sentence netted out of a school.
  net,

  /// Sableth: a word found in a grid of letters in the sand.
  sandstorm,

  /// Pyrewing: halves of phrases on coins, to pair up.
  hoard;

  /// Whether it asks about sentences rather than words.
  bool get needsSentences => switch (this) {
        crystalEcho || hexScroll || mirrorClones => true,
        tangledSpells || broomChase || lure => true,
        catchWords || shellGame || pebblePop || steppingStones => false,
        crystalSpikes || shardVolley || letterBubbles => false,
        shoal || riddle || sealedDoor || tablets => false,
        parley || flameLink || paraphrase || hoard => false,
        vein || net => true,
        sandstorm => false,
      };

  /// Whether it draws on content written only in English and Turkish so
  /// far (`constants/boss_trial_en_tr.dart`), so that a player on any other
  /// pair fights it in those two instead.
  bool get needsEnTr => switch (this) {
        shoal || riddle || sealedDoor || tablets => true,
        parley || flameLink || paraphrase || hoard => true,
        _ => false,
      };
}

/// A first round a boss can open with, and how its intro explains it.
class TrialOpening {
  const TrialOpening({
    required this.opener,
    required this.hp,
    required this.name,
    required this.intro,
  });

  final TrialOpener opener;

  /// The boss's patience in a round of it: about half a minute of a player
  /// answering well, since its attacks take longer or shorter and hit
  /// harder or softer than other openings'. Catch, Shells, Bubbles, Riddle
  /// and Parley were timed with a scripted player; the rest are estimated
  /// from their own clocks and damage by the same measure, to be tuned by
  /// playing.
  final int hp;

  /// Its name on the intro's picker, for a boss with more than one.
  final String name;

  /// The intro's paragraph about it.
  final String intro;
}

class TrialBoss {
  const TrialBoss({
    required this.id,
    required this.name,
    required this.number,
    required this.level,
    required this.openings,
    required this.asset,
    required this.openAsset,
    required this.aspect,
    required this.heightShare,
    required this.hitX,
    required this.hitY,
    required this.mouthX,
    required this.lostTitle,
    required this.skin,
    this.decoyStones = BossTrialRules.decoyStones,
    this.nearMissDecoys = false,
    this.flies = false,
    this.hexesPet = false,
    this.encasesPet = false,
    this.bubblesPet = false,
    this.buriesPet = false,
    this.scorchesPet = false,
    this.advancedPreview = false,
  });

  final String id;
  final String name;

  /// Which trial it is, first to sixth, and the level it proves.
  final int number;
  final int level;

  /// What it can open with. The first is what it opens with; more than one
  /// is a boss whose first round is still being chosen, and the intro offers
  /// them all.
  final List<TrialOpening> openings;

  TrialOpener get opener => openings.first.opener;

  /// Decoy stones in the Spells round, and whether they are chosen to look
  /// like the real words.
  final int decoyStones;
  final bool nearMissDecoys;

  /// Hovers and swoops from side to side instead of standing on the ledge.
  final bool flies;

  /// A hit on the pet turns it into a frog for a moment.
  final bool hexesPet;

  /// A hit on the pet seals it in amethyst for a moment.
  final bool encasesPet;

  /// A hit on the pet traps it in a bubble for a moment.
  final bool bubblesPet;

  /// A hit on the pet buries it in sand for a moment.
  final bool buriesPet;

  /// A hit on the pet scorches it grey for a moment.
  final bool scorchesPet;

  /// Testing affordance: whether its intro offers the advanced English set,
  /// which was written for this boss's rounds.
  final bool advancedPreview;

  // ---- art ----

  final String asset;

  /// The same sprite with its mouth open: shouting, casting, cackling.
  final String openAsset;

  /// Width over height, from the sprite's cell grid.
  final double aspect;

  /// The share of the arena's height the sprite may take.
  final double heightShare;

  /// Where hits land, as fractions of the sprite.
  final double hitX;
  final double hitY;

  /// The mouth, as a fraction across the sprite: where the shout's tail
  /// points.
  final double mouthX;

  // ---- copy ----

  /// The results heading when the boss wins.
  final String lostTitle;

  /// The look of its prompts, timers and answer tiles.
  final TrialSkin skin;
}

class TrialBosses {
  TrialBosses._();

  /// Trial 1, level 5. The stone tortoise.
  static const TrialBoss mossback = TrialBoss(
    id: 'mossback',
    name: 'Mossback',
    number: 1,
    level: 5,
    openings: [
      TrialOpening(
        opener: TrialOpener.catchWords,
        hp: 210,
        name: 'CATCH',
        intro: 'Mossback only speaks the language you are learning. When it '
            'shouts, tap the rubble that says what it means, and your pet '
            'throws it back.',
      ),
      TrialOpening(
        opener: TrialOpener.shellGame,
        hp: 115,
        name: 'SHELLS',
        intro: 'Mossback shouts a word in the language you are learning, and '
            'three stone cups show meanings for a moment before they flip '
            'and shuffle. Keep your eye on the right one, and tap it once '
            'they stop.',
      ),
      TrialOpening(
        opener: TrialOpener.pebblePop,
        hp: 165,
        name: 'PEBBLES',
        intro: 'A word in your language is shown, and pebbles pop up out of '
            'the moss carrying words in the one you are learning. Bonk the '
            'pebble that says it before it ducks back down.',
      ),
      TrialOpening(
        opener: TrialOpener.steppingStones,
        hp: 145,
        name: 'STONES',
        intro: 'Your pet crosses the river to Mossback one row at a time. '
            'For each row it shouts a word: hop onto the stone that says '
            'what it means before the one you are on sinks. Reach the far '
            'side and your pet headbutts it.',
      ),
    ],
    asset: 'assets/svgs/mossback_boss.svg',
    openAsset: 'assets/svgs/mossback_boss_open.svg',
    // Its cell grid, from `art_src/gen_mossback.py`.
    aspect: 141 / 108,
    heightShare: 0.2,
    // The middle of the shell.
    hitX: 0.43,
    hitY: 0.5,
    // The open mouth, cells 113-127 of 141.
    mouthX: 120 / 141,
    lostTitle: 'MOSSBACK HELD ITS GROUND',
    skin: TrialSkin.moss,
  );

  /// Trial 2, level 10. The crystal bear, on PLACEHOLDER art.
  ///
  /// Its first round is being chosen: it has three attacks of its own, all
  /// playable from the intro so they can be tried side by side, and the first
  /// is only first because a list needs one. Whatever it opens with, anything
  /// that gets through seals the pet in amethyst.
  static const TrialBoss amethyst = TrialBoss(
    id: 'amethyst',
    name: 'Amethyst',
    number: 2,
    level: 10,
    openings: [
      TrialOpening(
        opener: TrialOpener.crystalSpikes,
        hp: 160,
        name: 'SPIKES',
        intro: 'Amethyst slams the ledge and roars four words in the language '
            'you are learning, and a crystal spike grows down at your pet for '
            'each. Tap a spike, then the gem that says what it means, and '
            'your pet smashes it. The first spike to get through seals your '
            'pet in amethyst.',
      ),
      TrialOpening(
        opener: TrialOpener.crystalEcho,
        hp: 145,
        name: 'ECHO',
        intro: 'Amethyst roars a whole sentence in the language you are '
            'learning, and three crystals rise with meanings in yours. Tap '
            'the one it said before the amethyst closes over your pet.',
      ),
      TrialOpening(
        opener: TrialOpener.shardVolley,
        hp: 165,
        name: 'VOLLEY',
        intro: 'Amethyst hurls shards, each claiming a word means something. '
            'Smash the ones that lie. Let the true ones through, and your pet '
            'catches them and throws them back. A lie that gets through seals '
            'your pet in amethyst.',
      ),
      TrialOpening(
        opener: TrialOpener.vein,
        hp: 120,
        name: 'VEIN',
        intro: 'A sentence in your language, and a wall of crystals carved '
            'with words in the one you are learning. Start at the glowing '
            'crystal and follow the vein, crystal to crystal, word by word, '
            'before the amethyst closes over your pet.',
      ),
    ],
    decoyStones: 2,
    encasesPet: true,
    advancedPreview: true,
    asset: 'assets/svgs/amethyst_boss.svg',
    openAsset: 'assets/svgs/amethyst_boss_open.svg',
    // Its cell grid, from `art_src/gen_amethyst.py`.
    aspect: 122 / 121,
    heightShare: 0.22,
    // The chest.
    hitX: 0.55,
    hitY: 0.6,
    // The open mouth, centred on cell 91.5 of 122.
    mouthX: 91.5 / 122,
    lostTitle: 'AMETHYST WOULD NOT BUDGE',
    skin: TrialSkin.crystal,
  );

  /// Trial 3, level 15. The witch owl, from the owner's art.
  static const TrialBoss witch = TrialBoss(
    id: 'witch',
    name: 'Hoothex',
    number: 3,
    level: 15,
    openings: [
      TrialOpening(
        opener: TrialOpener.hexScroll,
        hp: 135,
        name: 'SCROLL',
        intro: 'Hoothex only speaks the language you are learning, and she '
            'cheats. Every spell she reads has one wrong word slipped in: tap '
            'it before the fuse burns down, and the curse rebounds on her.',
      ),
      TrialOpening(
        opener: TrialOpener.mirrorClones,
        hp: 125,
        name: 'CLONES',
        intro: 'Hoothex splits into three owls, each saying a sentence in the '
            'language you are learning. Only the real one says what is shown '
            'in yours: tap her before the fuse burns down. The clones burst '
            'into smoke.',
      ),
      TrialOpening(
        opener: TrialOpener.tangledSpells,
        hp: 250,
        name: 'TANGLE',
        intro: 'Hoothex tangles two spells together. As each word falls out, '
            'drop it into the cauldron of the spell it belongs to, before '
            'her fuse burns down.',
      ),
      TrialOpening(
        opener: TrialOpener.broomChase,
        hp: 75,
        name: 'CHASE',
        intro: 'Your pet chases Hoothex on a broom. Fly through the gate with '
            'the next word of the sentence shown in your language, not the '
            'one spelled like it, and fire the whole spell at her before she '
            'gets away.',
      ),
    ],
    decoyStones: BossTrialRules.nearMissDecoyStones,
    nearMissDecoys: true,
    flies: true,
    hexesPet: true,
    asset: 'assets/svgs/witch_boss.svg',
    openAsset: 'assets/svgs/witch_boss_open.svg',
    // Its cell grid, from `art_src/gen_hoothex.py`.
    aspect: 145 / 122,
    heightShare: 0.27,
    // The belly.
    hitX: 0.68,
    hitY: 0.66,
    // The open beak, centred on cell 103 of 145.
    mouthX: 103 / 145,
    lostTitle: 'HOOTHEX FLEW OFF CACKLING',
    skin: TrialSkin.hex,
  );

  /// Trial 4, level 20. The deep-sea anglerfish, in the sea.
  ///
  /// Its first round is being chosen, like Amethyst's was: both its attacks
  /// are playable from the intro. Whatever it opens with, anything that gets
  /// through traps the pet in a bubble.
  static const TrialBoss angler = TrialBoss(
    id: 'angler',
    name: 'Lanternmaw',
    number: 4,
    level: 20,
    openings: [
      TrialOpening(
        opener: TrialOpener.lure,
        hp: 155,
        name: 'LURE',
        intro: 'Lanternmaw lights up a sentence in the language you are '
            'learning with one word missing, and you are shown all of it in '
            'yours. Fish swim past carrying words: tap the one that fills the '
            'gap before its lantern goes out.',
      ),
      TrialOpening(
        opener: TrialOpener.letterBubbles,
        hp: 100,
        name: 'BUBBLES',
        intro: 'Lanternmaw breathes out a word in your language, and bubbles '
            'rise off the seabed carrying letters. Pop them in order to spell '
            'it in the language you are learning before it gulps. Two of the '
            'letters are not in the word.',
      ),
      TrialOpening(
        opener: TrialOpener.shoal,
        hp: 145,
        name: 'SHOAL',
        intro: 'A school of five fish swims in, each carrying a word in the '
            'language you are learning. Four of them belong together. Tap the '
            'one that does not before it gulps the lot.',
      ),
      TrialOpening(
        opener: TrialOpener.net,
        hp: 120,
        name: 'NET',
        intro: 'A sentence in your language, and a school of fish carrying '
            'words in the one you are learning. Net every fish whose word is '
            'in it, and none of the others, before it gulps the lot.',
      ),
    ],
    decoyStones: 2,
    flies: true,
    bubblesPet: true,
    asset: 'assets/svgs/angler_boss.svg',
    openAsset: 'assets/svgs/angler_boss_open.svg',
    // Its cell grid, from `art_src/gen_anglerfish.py`.
    aspect: 134 / 100,
    heightShare: 0.22,
    // The belly.
    hitX: 0.6,
    hitY: 0.66,
    // The open maw, centred on cell 95.5 of 134.
    mouthX: 95.5 / 134,
    lostTitle: 'LANTERNMAW SANK BACK INTO THE DARK',
    skin: TrialSkin.sea,
  );

  /// Trial 5, level 25. The sand sphinx.
  ///
  /// Its first round is being chosen: all four of its attacks are playable
  /// from the intro. Whatever it opens with, anything that gets through buries
  /// the pet in sand.
  static const TrialBoss sphinx = TrialBoss(
    id: 'sphinx',
    name: 'Sableth',
    number: 5,
    level: 25,
    openings: [
      TrialOpening(
        opener: TrialOpener.riddle,
        hp: 115,
        name: 'RIDDLE',
        intro: 'Sableth tells you a little story in the language you are '
            'learning and asks you a question about it. Tap the right answer '
            'before its sand runs out.',
      ),
      TrialOpening(
        opener: TrialOpener.sealedDoor,
        hp: 140,
        name: 'DOOR',
        intro: 'A sealed door, and a sentence with one word left as the '
            'dictionary has it. Turn the dial on the door to the form the '
            'sentence needs, then push the door open.',
      ),
      TrialOpening(
        opener: TrialOpener.tablets,
        hp: 105,
        name: 'TABLETS',
        intro: 'Three lines of a story are carved on tablets and shuffled. '
            'Lift them in the order the story happens.',
      ),
      TrialOpening(
        opener: TrialOpener.sandstorm,
        hp: 130,
        name: 'STORM',
        intro: 'A word in your language, and a grid of letters in the sand. '
            'Swipe across the letters that spell it in the language you are '
            'learning — along a row or down a column — before the storm '
            'buries them.',
      ),
    ],
    decoyStones: BossTrialRules.nearMissDecoyStones,
    nearMissDecoys: true,
    buriesPet: true,
    asset: 'assets/svgs/sphinx_boss.svg',
    openAsset: 'assets/svgs/sphinx_boss_open.svg',
    // Its cell grid, from `art_src/gen_sphinx.py`. Drawn on a coarser grid
    // than the rest of the set (113 cells wide, not ~140), so the share is
    // lower than theirs to keep it about as wide on screen as it was.
    aspect: 113 / 81,
    heightShare: 0.18,
    // The chest.
    hitX: 0.68,
    hitY: 0.68,
    // The open mouth, centred on cell 84 of 113.
    mouthX: 84 / 113,
    lostTitle: 'SABLETH WAS NOT IMPRESSED',
    skin: TrialSkin.sand,
  );

  /// Trial 6, level 30, the last. The fiery dragon.
  ///
  /// Its first round is being chosen: all four of its attacks are playable
  /// from the intro. Whatever it opens with, anything that gets through
  /// scorches the pet.
  static const TrialBoss dragon = TrialBoss(
    id: 'dragon',
    name: 'Pyrewing',
    number: 6,
    level: 30,
    openings: [
      TrialOpening(
        opener: TrialOpener.parley,
        hp: 155,
        name: 'PARLEY',
        intro: 'Pyrewing talks to you in the language you are learning. After '
            'each thing it says, pick the reply that answers it before its '
            'fire gets loose. Get through the whole conversation for a big '
            'hit.',
      ),
      TrialOpening(
        opener: TrialOpener.flameLink,
        hp: 145,
        name: 'LINK',
        intro: 'Pyrewing breathes two halves of a sentence, one in each '
            'flame. Runes drift between them, each a linking word. Throw the '
            'one that joins the halves into sense before the flames die.',
      ),
      TrialOpening(
        opener: TrialOpener.paraphrase,
        hp: 115,
        name: 'EMBERS',
        intro: 'Pyrewing says something, and three embers rise, each saying '
            'something else. One of them means the same thing another way. '
            'Tap it before it burns out — they go out one by one.',
      ),
      TrialOpening(
        opener: TrialOpener.hoard,
        hp: 145,
        name: 'HOARD',
        intro: 'Its hoard is full of coins, each carrying half of an everyday '
            'phrase. Tap two halves that go together to pair them before it '
            'wakes.',
      ),
    ],
    decoyStones: BossTrialRules.nearMissDecoyStones,
    nearMissDecoys: true,
    scorchesPet: true,
    asset: 'assets/svgs/dragon_boss.svg',
    openAsset: 'assets/svgs/dragon_boss_open.svg',
    // Its cell grid, from `art_src/gen_dragon.py`.
    aspect: 136 / 117,
    heightShare: 0.22,
    // The belly.
    hitX: 0.69,
    hitY: 0.79,
    // The open jaws, centred on cell 102 of 136.
    mouthX: 102 / 136,
    lostTitle: 'PYREWING WENT BACK TO SLEEP ON ITS GOLD',
    skin: TrialSkin.fire,
  );

  /// Every boss built so far, in trial order.
  static const List<TrialBoss> all = [
    mossback,
    amethyst,
    witch,
    angler,
    sphinx,
    dragon,
  ];
}
