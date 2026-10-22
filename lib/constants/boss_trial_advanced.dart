/// An advanced English set for a boss trial: what a high-proficiency tier
/// might throw at Amethyst, to try its attacks against something harder than
/// the stock nouns.
///
/// A TESTING PREVIEW, like the stock sets, and hand-written. The direction is
/// that content comes from the player's tier and the AI generates it; this is
/// a fixed sample of that top tier, reached from a switch on Amethyst's intro.
///
/// The meanings are plain English, not a translation: an advanced learner is
/// tested on register — "postponed" against "delayed", "reluctant" against
/// "did not want to" — the way a monolingual dictionary would, and it needs no
/// row per native language. Glosses are chosen to be clearly different from
/// one another, since a shard claiming a near-synonym would be a lie that is
/// arguably true.
library;

import '../utils/boss_trial.dart';

/// Words above the everyday, each with a plain gloss that fits a tile.
const List<TrialWord> advancedEnglishWords = [
  TrialWord(target: 'ephemeral', meaning: 'short-lived'),
  TrialWord(target: 'ubiquitous', meaning: 'everywhere'),
  TrialWord(target: 'meticulous', meaning: 'very careful'),
  TrialWord(target: 'candid', meaning: 'honest'),
  TrialWord(target: 'benevolent', meaning: 'kind'),
  TrialWord(target: 'obsolete', meaning: 'out of date'),
  TrialWord(target: 'reluctant', meaning: 'unwilling'),
  TrialWord(target: 'ambiguous', meaning: 'unclear'),
  TrialWord(target: 'lucid', meaning: 'clear'),
  TrialWord(target: 'scrutinize', meaning: 'examine'),
  TrialWord(target: 'mitigate', meaning: 'lessen'),
  TrialWord(target: 'frugal', meaning: 'not wasteful'),
  TrialWord(target: 'verbose', meaning: 'wordy'),
  TrialWord(target: 'eloquent', meaning: 'well-spoken'),
  TrialWord(target: 'elated', meaning: 'overjoyed'),
  TrialWord(target: 'conceal', meaning: 'hide'),
  TrialWord(target: 'deteriorate', meaning: 'get worse'),
  TrialWord(target: 'pragmatic', meaning: 'practical'),
  TrialWord(target: 'inevitable', meaning: 'unavoidable'),
  TrialWord(target: 'hostile', meaning: 'unfriendly'),
  TrialWord(target: 'trivial', meaning: 'unimportant'),
  TrialWord(target: 'novice', meaning: 'beginner'),
  TrialWord(target: 'adversary', meaning: 'enemy'),
  TrialWord(target: 'solace', meaning: 'comfort'),
  TrialWord(target: 'zenith', meaning: 'peak'),
  TrialWord(target: 'arduous', meaning: 'very hard'),
  TrialWord(target: 'scarce', meaning: 'rare'),
];

TrialSentence _sentence(
  List<String> tokens,
  String meaning,
  Set<String> concepts,
) =>
    TrialSentence(
      tokens: tokens,
      target: tokens.join(' '),
      meaning: meaning,
      concepts: concepts,
    );

/// Sentences in families that share who, what and to what, so the echo's
/// wrong meanings are near misses — "the minister postponed the reform"
/// offered beside the minister abandoning it and the council postponing
/// something else.
final List<TrialSentence> advancedEnglishSentences = [
  // Officials and decisions.
  _sentence(['the', 'council', 'postponed', 'the', 'ceremony'],
      'the leaders delayed the event', {'council', 'postpone', 'ceremony'}),
  _sentence(['the', 'council', 'approved', 'the', 'proposal'],
      'the leaders accepted the plan', {'council', 'approve', 'proposal'}),
  _sentence(['the', 'minister', 'rejected', 'the', 'proposal'],
      'the official turned down the plan', {'minister', 'reject', 'proposal'}),
  _sentence(['the', 'minister', 'postponed', 'the', 'reform'],
      'the official delayed the change', {'minister', 'postpone', 'reform'}),
  _sentence(['the', 'minister', 'abandoned', 'the', 'reform'],
      'the official gave up the change', {'minister', 'abandon', 'reform'}),
  // Willingness.
  _sentence(['she', 'was', 'reluctant', 'to', 'intervene'],
      'she did not want to step in', {'she', 'reluctant', 'intervene'}),
  _sentence(['she', 'was', 'eager', 'to', 'intervene'],
      'she really wanted to step in', {'she', 'eager', 'intervene'}),
  _sentence(['she', 'refused', 'to', 'intervene'], 'she would not step in',
      {'she', 'refuse', 'intervene'}),
  _sentence(['he', 'was', 'reluctant', 'to', 'concede'],
      'he did not want to give in', {'he', 'reluctant', 'concede'}),
  _sentence(['he', 'refused', 'to', 'concede'], 'he would not give in',
      {'he', 'refuse', 'concede'}),
  // How things changed.
  _sentence(['the', 'tension', 'gradually', 'subsided'],
      'the stress slowly went away', {'tension', 'gradual', 'subside'}),
  _sentence(['the', 'tension', 'abruptly', 'escalated'],
      'the stress suddenly got worse', {'tension', 'sudden', 'escalate'}),
  _sentence(['the', 'storm', 'abruptly', 'subsided'],
      'the storm suddenly died down', {'storm', 'sudden', 'subside'}),
  _sentence(['the', 'storm', 'gradually', 'intensified'],
      'the storm slowly got stronger', {'storm', 'gradual', 'intensify'}),
];
