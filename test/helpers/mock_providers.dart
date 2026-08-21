import 'package:mocktail/mocktail.dart';
import 'package:mojilearner_flutter/constants/bond.dart';
import 'package:mojilearner_flutter/utils/bond_progress.dart';
import 'package:mojilearner_flutter/providers/user_provider.dart';
import 'package:mojilearner_flutter/providers/daily_reward_provider.dart';
import 'package:mojilearner_flutter/providers/character_provider.dart';
import 'package:mojilearner_flutter/providers/language_provider.dart';
import 'package:mojilearner_flutter/providers/chat_provider.dart';
import 'package:mojilearner_flutter/providers/quiz_provider.dart';
import 'package:mojilearner_flutter/providers/mistakes_provider.dart';
import 'package:mojilearner_flutter/providers/settings_provider.dart';
import 'package:mojilearner_flutter/providers/calibration_provider.dart';

/// Mock classes for all providers used in testing
/// 
/// Usage:
/// ```dart
/// final mockUserProvider = MockUserProvider();
/// when(() => mockUserProvider.coins).thenReturn(100);
/// ```

class MockUserProvider extends Mock implements UserProvider {}

class MockDailyRewardProvider extends Mock implements DailyRewardProvider {}

/// Bond is implemented rather than stubbed.
///
/// The home screen reads it on every build and the review/quiz/chat flows
/// write to it, so leaving it to `when()` would make every existing test that
/// merely renders a screen fail on a missing stub for a feature it is not
/// about. The real (trivial) arithmetic runs instead, driven by [bondPoints],
/// and [recordedLearning] gives bond-aware tests something to assert on
/// without needing `verify()`.
class MockCharacterProvider extends Mock implements CharacterProvider {
  /// Bond the pet is standing on. Set directly in tests that care.
  @override
  int bondPoints = 0;

  @override
  PetWarmth warmth = PetWarmth.warm;

  /// Petting payouts, read by the home screen on every build to decide whether
  /// to play hearts. Implemented rather than stubbed for the same reason bond
  /// is: otherwise every test that merely renders the screen fails on a
  /// missing stub for a feature it is not about.
  @override
  int petPayouts = 0;

  /// Every learning event recorded, one entry per unit, in call order.
  final List<BondSource> recordedLearning = [];

  /// Every quiz settled, as (correct, total) pairs.
  final List<({int correct, int total})> recordedQuizzes = [];

  @override
  BondStatus bondStatusFor(String? assessedLevel) => BondProgress.statusFor(
        bondPoints: bondPoints,
        tier: BondProgress.tierFromLevel(assessedLevel),
      );

  @override
  int recordLearning(BondSource source, {int units = 1}) {
    if (units <= 0) return 0;
    recordedLearning.addAll(List.filled(units, source));
    return BondProgress.pointsFor(source) * units;
  }

  @override
  int recordQuizLearning({
    required int correctAnswers,
    required int totalQuestions,
  }) {
    recordedQuizzes.add((correct: correctAnswers, total: totalQuestions));
    return BondProgress.quizPoints(
      correctAnswers: correctAnswers,
      totalQuestions: totalQuestions,
    );
  }
}

class MockLanguageProvider extends Mock implements LanguageProvider {}

class MockChatProvider extends Mock implements ChatProvider {}

class MockQuizProvider extends Mock implements QuizProvider {}

class MockMistakesProvider extends Mock implements MistakesProvider {}

class MockSettingsProvider extends Mock implements SettingsProvider {}

class MockCalibrationProvider extends Mock implements CalibrationProvider {}
