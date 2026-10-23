import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_runtime_config.dart';
import '../constants/sample_mistakes.dart';
import '../models/models.dart';
import '../utils/secure_storage.dart';
import '../utils/vocab_extractor.dart';
import '../utils/srs_scheduler.dart';
import 'mistakes_provider.dart';

/// The app's learning memory: what the user has met, how well they know it,
/// and what's due for review.
///
/// Deliberately independent of how review is presented — the queue this
/// exposes can drive a review screen, the quiz, or pet-initiated recall in
/// chat without changing anything here.
class VocabProvider extends ChangeNotifier {
  final List<ReviewItem> _items = [];
  bool _isLoaded = false;
  StreamSubscription<Mistake>? _mistakeSubscription;

  /// Review items made from `kSampleMistakes`, which are shown and never saved.
  final Set<String> _sampleKeys = {};

  /// Cap on a single review session, so a long absence doesn't present a
  /// hundred-item backlog that the user simply abandons.
  static const int maxSessionSize = 20;

  List<ReviewItem> get items => List.unmodifiable(_items);
  bool get isLoaded => _isLoaded;

  @override
  void dispose() {
    _mistakeSubscription?.cancel();
    super.dispose();
  }

  /// Turn every recorded mistake into a review item automatically.
  void subscribeToMistakes(
    MistakesProvider mistakesProvider, {
    required String Function() languageCode,
  }) {
    _mistakeSubscription?.cancel();
    _mistakeSubscription = mistakesProvider.onMistake.listen((mistake) {
      addFromMistake(mistake, languageCode: languageCode());
    });
  }

  // ==================== LOADING / SAVING ====================

  Future<void> load() async {
    if (_isLoaded) return;

    await _loadSuggested();
    try {
      final data = await SecureStorage.readReviewItems();
      if (data != null && data.isNotEmpty) {
        _items
          ..clear()
          ..addAll(data.map(ReviewItem.fromJson));
      }
      if (AppRuntimeConfig.sampleMistakes) _addSamples();
    } catch (e) {
      debugPrint('⚠️ VOCAB: Failed to load review items - $e');
    } finally {
      // Mark loaded even on failure so a corrupt payload can't cause an
      // infinite reload loop — same guard MistakesProvider uses.
      _isLoaded = true;
      notifyListeners();
    }
  }

  /// The sample sentences as due review items, in English. Added only when
  /// they are not there already, so a launch never resets a sample's schedule.
  void _addSamples() {
    for (final sample in kSampleMistakes) {
      final key = ReviewItem.dedupeKey(
        languageCode: 'en',
        kind: ReviewItemKind.correction,
        prompt: sample.original,
      );
      if (_items.any((item) => item.key == key)) continue;
      _sampleKeys.add(key);
      _upsert(
        languageCode: 'en',
        prompt: sample.original,
        answer: sample.correction,
        context: sample.explanation,
        kind: ReviewItemKind.correction,
        flush: false,
      );
    }
  }

  // ==================== THE SUGGESTED PILE ====================

  /// Words the tutor suggested about what the learner was talking about.
  ///
  /// Kept apart from [items] on purpose. A review item is something the
  /// learner met and is being asked to remember; these are words they have not
  /// met yet. Reviewing them as if they had would bury the queue in cards they
  /// never engaged with. They exist for the games: the toy chest and the boss
  /// fights draw on [practiseItems], so practising there practises what the
  /// player was just talking about, and a word learned that way is one they
  /// have now seen. If one is met properly later, it becomes an item and
  /// leaves the pile.
  ///
  /// In prefs, not in the encrypted store: it is not private learner text, and
  /// prefs travel with the rest of a save.
  static const String _suggestedKey = 'suggested_words';

  /// The newest this many are kept; a longer pile only goes stale.
  static const int maxSuggested = 150;

  final List<ReviewItem> _suggested = [];

  List<ReviewItem> get suggestedItems => List.unmodifiable(_suggested);

  /// What a game or a fight is played with: the player's own words, then the
  /// suggested ones they do not already have.
  List<ReviewItem> get practiseItems {
    final own = items;
    final keys = {for (final item in own) item.key};
    return [
      ...own,
      for (final item in _suggested)
        if (!keys.contains(item.key)) item,
    ];
  }

  /// Whether [term] is already a word the learner has, or has been suggested.
  bool knowsVocabulary(String languageCode, String term) {
    final key = ReviewItem.dedupeKey(
      languageCode: languageCode,
      kind: ReviewItemKind.vocabulary,
      prompt: term,
    );
    return items.any((item) => item.key == key) ||
        _suggested.any((item) => item.key == key);
  }

  /// Adds suggested words to the pile, skipping any already known.
  List<ReviewItem> addSuggested(
    Iterable<ExtractedVocab> entries, {
    required String languageCode,
  }) {
    final added = <ReviewItem>[];
    for (final entry in entries) {
      if (knowsVocabulary(languageCode, entry.term)) continue;
      final item = ReviewItem(
        id: 'sg_${DateTime.now().microsecondsSinceEpoch}_${_suggested.length}',
        languageCode: languageCode,
        prompt: entry.term,
        answer: entry.meaning,
        context: entry.example,
        reading: entry.reading,
      );
      _suggested.add(item);
      added.add(item);
    }
    if (added.isEmpty) return added;
    if (_suggested.length > maxSuggested) {
      _suggested.removeRange(0, _suggested.length - maxSuggested);
    }
    unawaited(_saveSuggested());
    notifyListeners();
    return added;
  }

  Future<void> _loadSuggested() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_suggestedKey);
      if (raw == null) return;
      _suggested
        ..clear()
        ..addAll([
          for (final json in jsonDecode(raw) as List)
            ReviewItem.fromJson(Map<String, dynamic>.from(json as Map)),
        ]);
    } catch (e) {
      debugPrint('⚠️ VOCAB: Failed to load suggested words - $e');
    }
  }

  Future<void> _saveSuggested() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _suggestedKey,
        jsonEncode([for (final item in _suggested) item.toJson()]),
      );
    } catch (e) {
      debugPrint('⚠️ VOCAB: Failed to save suggested words - $e');
    }
  }

  Future<void> _save() async {
    try {
      await SecureStorage.saveReviewItems(
        _items
            .where((item) => !_sampleKeys.contains(item.key))
            .map((item) => item.toJson())
            .toList(),
      );
    } catch (e) {
      debugPrint('⚠️ VOCAB: Failed to save review items - $e');
    }
  }

  // ==================== CAPTURE ====================

  /// Records a word or phrase the learner has met. Re-adding a known item
  /// leaves its schedule alone — meeting a word again shouldn't reset the
  /// progress the learner has already built on it.
  ReviewItem addVocabulary({
    required String languageCode,
    required String prompt,
    required String answer,
    String? context,
    String? reading,
  }) {
    return _upsert(
      languageCode: languageCode,
      prompt: prompt,
      answer: answer,
      context: context,
      reading: reading,
      kind: ReviewItemKind.vocabulary,
    );
  }

  /// Records every word from one AI reply — one save and one notify, however
  /// many words came back.
  ///
  /// The AI hands over a handful of terms at a time, and calling
  /// [addVocabulary] in a loop re-encoded the learner's entire item list once
  /// per word, on the main isolate. A learner a few hundred words in was
  /// paying that several times per message. It is also what would make this
  /// the most expensive path in the app once this state syncs to a backend,
  /// where each of those saves is a billed write rather than just a slow one.
  List<ReviewItem> addVocabularyBatch(
    Iterable<ExtractedVocab> entries, {
    required String languageCode,
  }) {
    final added = <ReviewItem>[];
    for (final entry in entries) {
      added.add(_upsert(
        languageCode: languageCode,
        prompt: entry.term,
        answer: entry.meaning,
        context: entry.example,
        reading: entry.reading,
        kind: ReviewItemKind.vocabulary,
        flush: false,
      ));
    }
    if (added.isNotEmpty) {
      _save();
      notifyListeners();
    }
    return added;
  }

  /// Records a correction the learner should internalise.
  ReviewItem addFromMistake(Mistake mistake, {required String languageCode}) {
    return _upsert(
      languageCode: languageCode,
      prompt: mistake.original,
      answer: mistake.correction,
      context: mistake.explanation,
      kind: ReviewItemKind.correction,
      // Repeating a mistake means it isn't learned — pull it back to the
      // front of the queue even if it was scheduled far out.
      resetScheduleOnDuplicate: true,
    );
  }

  /// [flush] is what [addVocabularyBatch] turns off: a save and a notify per
  /// word is wrong when the words arrive together.
  ReviewItem _upsert({
    required String languageCode,
    required String prompt,
    required String answer,
    required ReviewItemKind kind,
    String? context,
    String? reading,
    bool resetScheduleOnDuplicate = false,
    bool flush = true,
  }) {
    final key = ReviewItem.dedupeKey(
      languageCode: languageCode,
      kind: kind,
      prompt: prompt,
    );

    final existingIndex = _items.indexWhere((item) => item.key == key);
    if (existingIndex != -1) {
      final existing = _items[existingIndex];
      final updated = resetScheduleOnDuplicate
          ? existing.copyWith(
              answer: answer,
              context: context,
              reading: reading,
              repetitions: 0,
              intervalDays: SrsScheduler.firstIntervalDays,
              dueAt: DateTime.now(),
            )
          : existing.copyWith(
              answer: answer, context: context, reading: reading);
      _items[existingIndex] = updated;
      if (flush) {
        _save();
        notifyListeners();
      }
      return updated;
    }

    // A word that was only suggested, now met properly: it leaves the pile.
    if (_suggested.any((s) => s.key == key)) {
      _suggested.removeWhere((s) => s.key == key);
      unawaited(_saveSuggested());
    }

    final item = ReviewItem(
      id: '${DateTime.now().microsecondsSinceEpoch}_${_items.length}',
      languageCode: languageCode,
      prompt: prompt,
      answer: answer,
      context: context,
      reading: reading,
      kind: kind,
    );
    _items.add(item);
    if (flush) {
      _save();
      notifyListeners();
    }
    return item;
  }

  // ==================== THE QUEUE ====================

  /// Everything currently due, most overdue first. Pass [languageCode] to
  /// scope the queue to the language being studied.
  List<ReviewItem> dueItems({String? languageCode, DateTime? now}) {
    final moment = now ?? DateTime.now();
    final due = _items
        .where((item) => item.isDue(now: moment))
        .where((item) =>
            languageCode == null || item.languageCode == languageCode)
        .toList()
      ..sort((a, b) => a.dueAt.compareTo(b.dueAt));
    return due;
  }

  /// The next review session: due items, oldest first, capped at
  /// [maxSessionSize].
  List<ReviewItem> nextSession({String? languageCode, DateTime? now}) {
    final due = dueItems(languageCode: languageCode, now: now);
    return due.length <= maxSessionSize
        ? due
        : due.sublist(0, maxSessionSize);
  }

  /// When the next item falls due, or null when there are no items at all.
  ///
  /// Returns a past time when something is already overdue. Used to schedule
  /// review reminders.
  DateTime? nextDueAt({String? languageCode}) {
    DateTime? earliest;
    for (final item in _items) {
      if (languageCode != null && item.languageCode != languageCode) continue;
      if (earliest == null || item.dueAt.isBefore(earliest)) {
        earliest = item.dueAt;
      }
    }
    return earliest;
  }

  int dueCount({String? languageCode, DateTime? now}) =>
      dueItems(languageCode: languageCode, now: now).length;

  /// Items the learner keeps forgetting — their genuine problem spots.
  List<ReviewItem> troubleSpots({String? languageCode, int limit = 5}) {
    final candidates = _items
        .where((item) => item.lapses > 0)
        .where((item) =>
            languageCode == null || item.languageCode == languageCode)
        .toList()
      ..sort((a, b) => b.lapses.compareTo(a.lapses));
    return candidates.length <= limit
        ? candidates
        : candidates.sublist(0, limit);
  }

  int learnedCount({String? languageCode}) => _items
      .where((item) => item.isLearned)
      .where(
          (item) => languageCode == null || item.languageCode == languageCode)
      .length;

  ReviewItem? byId(String id) {
    for (final item in _items) {
      if (item.id == id) return item;
    }
    return null;
  }

  // ==================== REVIEWING ====================

  /// Grades an item and reschedules it. Returns the updated item, or null if
  /// the id is unknown.
  ReviewItem? grade(String id, ReviewGrade grade, {DateTime? now}) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1) return null;

    final updated = _items[index].reviewed(grade, now: now);
    _items[index] = updated;
    _save();
    notifyListeners();
    return updated;
  }

  void remove(String id) {
    final before = _items.length;
    _items.removeWhere((item) => item.id == id);
    if (_items.length != before) {
      _save();
      notifyListeners();
    }
  }

  void clearAll() {
    if (_items.isEmpty) return;
    _items.clear();
    _save();
    notifyListeners();
  }
}
