import 'package:flutter/foundation.dart';

import '../constants/scenarios.dart';
import '../models/models.dart';
import '../utils/secure_storage.dart';

/// Tracks which scenario objectives the learner has cleared.
///
/// Mirrors [VocabProvider]'s shape deliberately: load once, mark loaded even
/// on failure so a corrupt payload can't loop, and fire-and-forget saves.
class ScenarioProvider extends ChangeNotifier {
  final Map<String, ScenarioProgress> _progress = {};
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  Map<String, ScenarioProgress> get progress => Map.unmodifiable(_progress);

  // ==================== LOADING / SAVING ====================

  Future<void> load() async {
    if (_isLoaded) return;

    try {
      final data = await SecureStorage.readScenarioProgress();
      if (data != null && data.isNotEmpty) {
        _progress.clear();
        for (final entry in data) {
          final parsed = ScenarioProgress.fromJson(entry);
          // Drop progress for scenarios that no longer exist, rather than
          // carrying dead ids forward forever.
          if (ScenarioCatalog.byId(parsed.scenarioId) != null) {
            _progress[parsed.scenarioId] = parsed;
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ SCENARIO: Failed to load progress - $e');
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  Future<void> _save() async {
    try {
      await SecureStorage.saveScenarioProgress(
        _progress.values.map((entry) => entry.toJson()).toList(),
      );
    } catch (e) {
      debugPrint('⚠️ SCENARIO: Failed to save progress - $e');
    }
  }

  // ==================== READING ====================

  ScenarioProgress forScenario(String scenarioId) =>
      _progress[scenarioId] ?? ScenarioProgress(scenarioId: scenarioId);

  /// Required objectives cleared in the current run.
  int clearedRequiredCount(ScenarioDefinition scenario) {
    final cleared = forScenario(scenario.id).clearedObjectiveIds;
    return scenario.required.where((o) => cleared.contains(o.id)).length;
  }

  /// True once every required objective in the current run is cleared.
  bool isComplete(ScenarioDefinition scenario) =>
      clearedRequiredCount(scenario) >= scenario.requiredCount;

  bool hasEverCompleted(String scenarioId) =>
      forScenario(scenarioId).hasEverCompleted;

  // ==================== WRITING ====================

  /// Marks objectives cleared. Unknown ids are ignored — the tutor reports
  /// these, so the catalogue is the authority on what exists.
  ///
  /// Returns the ids that were newly cleared by this call, so the caller can
  /// tell a fresh tick from a repeat and only celebrate the former.
  Set<String> markObjectives(
    ScenarioDefinition scenario,
    Iterable<String> objectiveIds, {
    DateTime? now,
  }) {
    final current = forScenario(scenario.id);
    final newlyCleared = objectiveIds
        .where(scenario.hasObjective)
        .where((id) => !current.clearedObjectiveIds.contains(id))
        .toSet();

    if (newlyCleared.isEmpty) return const {};

    _progress[scenario.id] = current.copyWith(
      clearedObjectiveIds: {...current.clearedObjectiveIds, ...newlyCleared},
      lastPlayedAt: now ?? DateTime.now(),
    );
    _save();
    notifyListeners();
    return newlyCleared;
  }

  /// Records a completed run and clears the board for the next one.
  ///
  /// Returns true when this was the learner's first ever clear, which is what
  /// decides the reward tier.
  bool completeRun(ScenarioDefinition scenario, {DateTime? now}) {
    final moment = now ?? DateTime.now();
    final current = forScenario(scenario.id);
    final isFirstClear = !current.hasEverCompleted;

    _progress[scenario.id] = current.copyWith(
      // Objectives reset so a replay starts from an empty checklist.
      clearedObjectiveIds: const {},
      timesCompleted: current.timesCompleted + 1,
      firstCompletedAt: current.firstCompletedAt ?? moment,
      lastPlayedAt: moment,
    );
    _save();
    notifyListeners();
    return isFirstClear;
  }

  /// Wipes the current run without recording a completion. Used when a
  /// learner restarts a scenario they abandoned part-way.
  void resetRun(String scenarioId) {
    final current = _progress[scenarioId];
    if (current == null || current.clearedObjectiveIds.isEmpty) return;

    _progress[scenarioId] = current.copyWith(clearedObjectiveIds: const {});
    _save();
    notifyListeners();
  }

  void clearAll() {
    if (_progress.isEmpty) return;
    _progress.clear();
    _save();
    notifyListeners();
  }
}
