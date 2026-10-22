import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/constants/entitlements.dart';
import 'package:mojilearner_flutter/providers/user_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The daily model allowance as the app actually holds it: persisted, rolled
/// over on the local calendar day, and re-read on the tier the player is on
/// right now rather than the one they were on when the day started.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<UserProvider> buildProvider() async {
    final provider = UserProvider();
    await Future.delayed(const Duration(milliseconds: 50));
    return provider;
  }

  test('a new player has the free allowance', () async {
    final provider = await buildProvider();

    expect(provider.aiAllowance, EntitlementConstants.free);
    expect(
      provider.aiRemaining(AiSpend.quiz),
      EntitlementConstants.free.quizzes,
    );
  });

  test('spending draws the meter down and persists it', () async {
    final provider = await buildProvider();
    expect(await provider.spendAi(AiSpend.quiz), isTrue);

    expect(
      provider.aiRemaining(AiSpend.quiz),
      EntitlementConstants.free.quizzes - 1,
    );

    final reloaded = await buildProvider();
    expect(
      reloaded.aiRemaining(AiSpend.quiz),
      EntitlementConstants.free.quizzes - 1,
    );
  });

  // A caller that forgets to ask must still not be able to overspend, because
  // the thing on the other side of the meter costs money.
  test('spending past the meter is refused rather than recorded', () async {
    final provider = await buildProvider();
    for (var i = 0; i < EntitlementConstants.free.quizzes; i++) {
      expect(await provider.spendAi(AiSpend.quiz), isTrue);
    }

    expect(provider.canSpendAi(AiSpend.quiz), isFalse);
    expect(await provider.spendAi(AiSpend.quiz), isFalse);
    expect(provider.aiRemaining(AiSpend.quiz), 0);
  });

  test('the two meters are independent', () async {
    final provider = await buildProvider();
    for (var i = 0; i < EntitlementConstants.free.quizzes; i++) {
      await provider.spendAi(AiSpend.quiz);
    }

    expect(provider.canSpendAi(AiSpend.quiz), isFalse);
    expect(provider.canSpendAi(AiSpend.message), isTrue);
  });

  test('subscribing opens the meter without touching what was spent',
      () async {
    final provider = await buildProvider();
    for (var i = 0; i < EntitlementConstants.free.quizzes; i++) {
      await provider.spendAi(AiSpend.quiz);
    }
    expect(provider.canSpendAi(AiSpend.quiz), isFalse);

    await provider.setPremium(true);

    expect(provider.aiAllowance, EntitlementConstants.premium);
    expect(provider.canSpendAi(AiSpend.quiz), isTrue);
    expect(
      provider.aiRemaining(AiSpend.quiz),
      EntitlementConstants.premium.quizzes - EntitlementConstants.free.quizzes,
    );
  });

  test('a rewarded ad buys a way past the wall, and it persists', () async {
    final provider = await buildProvider();
    for (var i = 0; i < EntitlementConstants.free.quizzes; i++) {
      await provider.spendAi(AiSpend.quiz);
    }
    expect(provider.canSpendAi(AiSpend.quiz), isFalse);

    await provider.addRewardedQuiz();

    expect(provider.canSpendAi(AiSpend.quiz), isTrue);
    expect(provider.aiBonusQuizzesToday,
        EntitlementConstants.quizzesPerRewardedAd);

    final reloaded = await buildProvider();
    expect(reloaded.canSpendAi(AiSpend.quiz), isTrue);
  });

  group('the day turning over', () {
    // Closing the app must not be a way to get the allowance back early.
    test('a spent day survives a restart', () async {
      final provider = await buildProvider();
      for (var i = 0; i < EntitlementConstants.free.quizzes; i++) {
        await provider.spendAi(AiSpend.quiz);
      }

      final reloaded = await buildProvider();

      expect(reloaded.canSpendAi(AiSpend.quiz), isFalse);
    });

    test('yesterday\'s spend does not count against today', () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      SharedPreferences.setMockInitialValues({
        'ai_day': yesterday.millisecondsSinceEpoch,
        'ai_spent_quiz': EntitlementConstants.free.quizzes,
        'ai_spent_message': EntitlementConstants.free.messages,
        'ai_bonus_quizzes': 3,
      });

      final provider = await buildProvider();

      expect(
        provider.aiRemaining(AiSpend.quiz),
        EntitlementConstants.free.quizzes,
      );
      expect(
        provider.aiRemaining(AiSpend.message),
        EntitlementConstants.free.messages,
      );
      // An ad bought a quiz for that day, not a credit to carry over.
      expect(provider.aiBonusQuizzesToday, 0);
    });
  });

  /// The bank, as the app holds it rather than as arithmetic: written to
  /// disk, and filled only while the membership that pays for it is on.
  group('carrying unused quizzes forward', () {
    const premium = EntitlementConstants.premium;

    /// A member whose ledger closed [days] ago having spent [spent] quizzes.
    Future<UserProvider> memberAfter({
      required int days,
      required int spent,
      int banked = 0,
      bool stillAMember = true,
    }) async {
      SharedPreferences.setMockInitialValues({
        'is_premium': stillAMember,
        'ai_day': DateTime.now()
            .subtract(Duration(days: days))
            .millisecondsSinceEpoch,
        'ai_spent_quiz': spent,
        'ai_banked_quizzes': banked,
      });
      return buildProvider();
    }

    test('a member keeps what a quiet day did not use', () async {
      final provider = await memberAfter(days: 1, spent: 4);

      expect(provider.aiBankedQuizzes, premium.quizzes - 4);
      expect(
        provider.aiLimit(AiSpend.quiz),
        premium.quizzes + (premium.quizzes - 4),
      );
    });

    test('a free player does not bank', () async {
      final provider = await memberAfter(
        days: 1,
        spent: 0,
        stillAMember: false,
      );

      expect(provider.aiBankedQuizzes, 0);
      expect(provider.aiLimit(AiSpend.quiz), EntitlementConstants.free.quizzes);
    });

    test('the bank is written to disk once anything is spent', () async {
      final provider = await memberAfter(days: 1, spent: 4);
      expect(await provider.spendAi(AiSpend.quiz), isTrue);

      final reloaded = await buildProvider();

      expect(reloaded.aiBankedQuizzes, premium.quizzes - 4);
      expect(reloaded.aiRemaining(AiSpend.quiz),
          provider.aiRemaining(AiSpend.quiz));
    });

    // Nothing persists a rollover on its own — the getters that trigger one
    // cannot await — so relaunching has to land on the same answer rather
    // than banking the same day twice.
    test('a rollover nothing saved is not banked again on the next launch',
        () async {
      final first = await memberAfter(days: 1, spent: 4);
      final banked = first.aiBankedQuizzes;

      final second = await buildProvider();

      expect(second.aiBankedQuizzes, banked);
    });

    test('the bank pays only once the day and its ads are gone', () async {
      final provider = await memberAfter(days: 1, spent: premium.quizzes);
      expect(provider.aiBankedQuizzes, 0);

      // A day opens with ten of its own; the bank is untouched until they are.
      for (var i = 0; i < premium.quizzes; i++) {
        expect(await provider.spendAi(AiSpend.quiz), isTrue);
      }

      expect(provider.canSpendAi(AiSpend.quiz), isFalse);
    });
  });
}
