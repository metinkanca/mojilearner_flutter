import 'package:mocktail/mocktail.dart';
import 'package:mojilearner_flutter/constants/bond.dart';
import 'package:mojilearner_flutter/constants/gold.dart';
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

/// Coin awards are implemented rather than stubbed.
///
/// The review, quiz and scenario flows all pay out through
/// [awardLearningGold], so leaving it to `when()` would make every test that
/// merely grades a card fail on a missing stub for the economy — the same
/// reason bond is implemented on [MockCharacterProvider]. It pays in full
/// here: the taper and the source caps have their own tests
/// (`test/unit/constants/gold_test.dart`), and screen tests should not have
/// to know today's ledger to assert on a payout.
///
/// [awardedGold] records every call for tests that do care.
class MockUserProvider extends Mock implements UserProvider {
  /// Every coin award, in call order.
  final List<({int raw, GoldSource source})> awardedGold = [];

  @override
  Future<GoldAward> awardLearningGold(int raw, GoldSource source) async {
    awardedGold.add((raw: raw, source: source));
    return GoldAward(paid: raw, raw: raw);
  }

  /// Coins awarded from [source] across the test so far.
  int goldFrom(GoldSource source) => awardedGold
      .where((a) => a.source == source)
      .fold(0, (sum, a) => sum + a.raw);

  /// Untapered coin grants, in call order.
  ///
  /// Implemented for the same reason [awardLearningGold] is, and kept
  /// separate from it on purpose: this is the path a rewarded ad pays
  /// through, and the two lists staying distinct is what lets a test assert
  /// that ad coins never went near the learning ledger. See
  /// `constants/ads.dart`.
  final List<int> addedCoins = [];

  @override
  Future<void> addCoins(int amount) async => addedCoins.add(amount);

  /// Today's pre-taper learning coins, derived from [awardedGold].
  ///
  /// Implemented rather than stubbed because the rewarded-ad offer is gated
  /// on it: a screen test that merely renders the shop should not have to
  /// stub the economy to say whether the player has studied today.
  @override
  int get learningGoldEarnedToday =>
      awardedGold.fold(0, (sum, a) => sum + a.raw);

  /// Membership. A plain field so a test can flip it without a stub.
  @override
  bool isPremium = false;
}

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
