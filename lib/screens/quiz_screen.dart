import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../components/ai_limit_sheet.dart';
import '../constants/entitlements.dart';
import '../constants/gold.dart';
import '../constants/theme.dart';
import '../components/quiz_stage.dart';
import '../components/tutorial/tutorial_offer_host.dart';
import '../constants/tutorials.dart';
import '../components/quiz_rewards_popup.dart';
import '../providers/ads_provider.dart';
import '../providers/user_provider.dart';
import '../providers/quiz_provider.dart';
import '../providers/character_provider.dart';
import '../providers/language_provider.dart';
import '../providers/vocab_provider.dart';
import '../providers/calibration_provider.dart';
import '../utils/progression_utils.dart';
import '../services/ai_guard.dart';
import '../services/ai_prompt_spec.dart';
import '../services/ai_service.dart';
import '../utils/srs_quiz_builder.dart';
import '../utils/review_selection.dart';
import '../utils/quiz_response_parser.dart';
import '../utils/quiz_cache.dart';
import '../utils/srs_scheduler.dart';
import '../utils/rtl_locale.dart';
import '../../utils/fonts.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final List<Map<String, dynamic>> _stockQuestions = [
    {
      "question": "How do you say 'Hello' in Spanish?",
      "topic": "Greetings",
      "options": ["Adiós", "Hola", "Gracias", "Por favor"],
      "correct": "Hola",
      "explanation": "Hola is the standard greeting for 'Hello' in Spanish."
    },
    {
      "question": "Which word means 'Cat'?",
      "topic": "Animals",
      "options": ["Perro", "Gato", "Pájaro", "Conejo"],
      "correct": "Gato",
      "explanation": "Gato means Cat. Perro is Dog, Pájaro is Bird."
    },
    {
      "question": "What is 'Red' in Spanish?",
      "topic": "Colors",
      "options": ["Rojo", "Azul", "Verde", "Amarillo"],
      "correct": "Rojo",
      "explanation": "Rojo is the color Red. Azul is Blue."
    },
    {
      "question": "How do you ask 'How are you?'",
      "topic": "Phrases",
      "options": ["¿Cómo estás?", "¿Qué tal?", "¿Quién eres?", "¿Dónde estás?"],
      "correct": "¿Cómo estás?",
      "explanation": "¿Cómo estás? literally translates to 'How are you?'."
    },
     {
      "question": "Translate: 'Good Morning'",
      "topic": "Greetings",
      "options": ["Buenas noches", "Buenas tardes", "Buenos días", "Hola"],
      "correct": "Buenos días",
      "explanation": "Buenos días consists of 'Good' (Buenos) and 'Days' (Días)."
    }
  ];

  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _showExplanation = false;
  String? _selectedAnswer;

  /// Bumped on a right answer, which is what plays the hearts. See
  /// [QuizClassFloor.heartBurstId].
  int _heartBursts = 0;

  /// Questions built from the review queue. Empty until
  /// [_buildSrsQuestions] runs, and left empty when the queue is too thin
  /// to build a fair set.
  List<QuizQuestion> _srsQuestions = [];

  late final List<QuizQuestion> _stockFallback =
      _stockQuestions.map(QuizQuestion.fromStock).toList();

  List<QuizQuestion> get _questions =>
      _srsQuestions.isNotEmpty ? _srsQuestions : _stockFallback;

  /// True while the AI is being asked for a quiz. The stock set is showing
  /// underneath, so this only drives a subtle indicator rather than blocking
  /// the screen.
  bool _isGenerating = false;

  /// Whether the review schedule actually had something due when this quiz
  /// was sourced. Drives the coin payout, not the questions.
  ///
  /// Deliberately not "are these SRS questions": an AI set is briefed on the
  /// due queue, and a cached set is fingerprinted on it, so both come back
  /// unchanged for a learner whose queue is empty — and re-taking the same
  /// cached quiz would otherwise pay full price every time. What the payout
  /// should follow is whether the schedule had work for the player today.
  bool _drawnFromDueQueue = false;

  /// Set when the day's AI quiz allowance turned the generation away.
  ///
  /// Surfaced once the local quiz has settled rather than at the moment of the
  /// refusal, so the player sees the quiz they can take before being told what
  /// they cannot have. A wall shown over an empty screen reads as a door.
  bool _aiQuizLimitReached = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadQuestions();
    });
  }

  /// Sources a quiz, best first.
  ///
  /// 1. AI, briefed on the learner's level and review queue — the only source
  ///    that can test grammar and usage rather than recognition alone.
  /// 2. Questions built locally from the review queue — works offline, but
  ///    can only ask "what does this mean".
  /// 3. The stock set, for a learner who has met nothing yet.
  Future<void> _loadQuestions() async {
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
    final vocab = Provider.of<VocabProvider>(context, listen: false);
    final code =
        Provider.of<LanguageProvider>(context, listen: false).targetLanguage?.code;

    // Show the locally-built quiz immediately so the screen is never empty
    // while the request is in flight.
    final local = _buildSrsQuestions();
    setState(() {
      _drawnFromDueQueue = vocab.nextSession(languageCode: code).isNotEmpty;
      _srsQuestions = local;
      _isGenerating = true;
      _restoreProgress(quizProvider);
    });

    final generated = await _generateWithAi();

    if (!mounted) return;
    setState(() {
      _isGenerating = false;
      if (generated.isNotEmpty) {
        _srsQuestions = generated;
        // A new set invalidates a saved position from the previous one.
        _currentQuestionIndex = 0;
        _score = 0;
        _showExplanation = false;
        _selectedAnswer = null;
      }
    });

    if (_aiQuizLimitReached) {
      _aiQuizLimitReached = false;
      await AiLimitSheet.show(context, AiSpend.quiz);
    }
  }

  void _restoreProgress(QuizProvider quizProvider) {
    if (!quizProvider.hasSavedProgress) return;
    // The queue may have shrunk since the quiz was paused, so a saved index
    // can point past the end of the new set.
    final total = _questions.length;
    _currentQuestionIndex =
        (quizProvider.savedQuestionIndex ?? 0).clamp(0, total - 1);
    _score = (quizProvider.savedScore ?? 0).clamp(0, total);
    // Don't clear progress here - it will be cleared when quiz is completed or explicitly exited
  }

  /// Asks the tutor for a quiz aimed at this learner.
  ///
  /// Returns an empty list on any failure — unavailable AI, rate limit,
  /// malformed JSON — so the caller silently keeps the local quiz. A learner
  /// who is offline should get a quiz, not an error.
  Future<List<QuizQuestion>> _generateWithAi() async {
    final language = Provider.of<LanguageProvider>(context, listen: false);
    final vocab = Provider.of<VocabProvider>(context, listen: false);
    final calibration =
        Provider.of<CalibrationProvider>(context, listen: false);
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);

    final code = language.targetLanguage?.code;
    if (code == null) return const [];

    final level =
        calibration.getLanguageProficiency(code)?.aiDeterminedLevel ??
            'beginner';
    final troubleSpots = vocab.troubleSpots(languageCode: code);
    final dueItems = vocab.nextSession(languageCode: code);

    // Reuse today's set when the learner's state hasn't moved. Checked before
    // the availability and rate-limit gates so a cached quiz still works
    // offline, and so bouncing in and out of the screen costs nothing.
    final fingerprint = QuizCache.fingerprint(
      languageCode: code,
      level: level,
      troubleSpots: troubleSpots,
      dueItems: dueItems,
    );
    final cached = quizProvider.usableCachedQuiz(
      languageCode: code,
      fingerprint: fingerprint,
    );
    if (cached != null) return cached.questions;

    if (!AiService.instance.isAiAvailable) return const [];

    // The daily allowance, checked after the cache so revisiting a quiz the
    // player already paid for costs nothing, and before the request so the
    // call is never made. Returning empty leaves the locally-built SRS quiz
    // on screen, which is the whole reason a cap is defensible here: the
    // player is stopped from *generating*, never from studying.
    final user = Provider.of<UserProvider>(context, listen: false);
    if (!user.canSpendAi(AiSpend.quiz)) {
      _aiQuizLimitReached = true;
      return const [];
    }

    final guard = AiGuard.checkRequest(
      kind: AiRequestKind.quiz,
      source: 'quiz_screen',
    );
    if (!guard.allowed) return const [];
    AiGuard.recordRequest('quiz_screen');

    // Trimmed here, then rendered into a prompt by the server. This side
    // picks which items are worth testing; `server/src/prompts.js` writes the
    // brief and caps the lists again.
    final briefed = ReviewSelection.select(
      troubleSpots: troubleSpots,
      dueItems: dueItems,
    );

    try {
      final response = await AiService.instance.generateText(
        spec: AiPromptSpec.quiz(
          targetCode: code,
          nativeCode: language.nativeLanguage.code,
          level: level,
          troubleSpots: briefed.trouble,
          dueItems: briefed.due,
        ),
        source: 'quiz_screen',
        // A fixed JSON schema gains nothing from the model reasoning first,
        // and that reasoning bills at the output rate.
        config: AiGenerationConfig.structuredJson,
      );
      if (response.isEmpty ||
          AiService.instance.isUnavailableResponse(response)) {
        return const [];
      }

      final questions = QuizResponseParser.parse(
        response,
        // Only ids the model was actually shown may reschedule an item.
        allowedReviewItemIds: briefed.offeredIds,
      );

      // Charged on a generation that produced something, not on the attempt.
      // A call that failed or came back unusable still cost the provider, but
      // the player did not get a quiz out of it, and taking their allowance
      // for the app's bad day is how a cap starts feeling arbitrary. The
      // proxy's own budget ledger is what bounds the money.
      if (questions.isNotEmpty) {
        await user.spendAi(AiSpend.quiz);
      }

      if (questions.isNotEmpty) {
        await quizProvider.cacheQuiz(CachedQuiz(
          languageCode: code,
          fingerprint: fingerprint,
          generatedAt: DateTime.now(),
          questions: questions,
        ));
      }
      return questions;
    } catch (e) {
      debugPrint('⚠️ QUIZ: AI generation failed, using local quiz - $e');
      return const [];
    }
  }

  /// Builds the quiz from what's due for review. Returns an empty list when
  /// the learner hasn't met enough words yet, in which case the stock set
  /// stands in.
  List<QuizQuestion> _buildSrsQuestions() {
    final vocab = Provider.of<VocabProvider>(context, listen: false);
    final language = Provider.of<LanguageProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;
    final code = language.targetLanguage?.code;

    return SrsQuizBuilder.build(
      due: vocab.nextSession(languageCode: code),
      pool: vocab.items
          .where((item) => code == null || item.languageCode == code)
          .toList(),
      vocabularyPrompt: l10n.reviewVocabularyPrompt,
      correctionPrompt: l10n.reviewCorrectionPrompt,
    );
  }

  void _handleAnswer(String answer) {
    if (_showExplanation) return;

    final question = _questions[_currentQuestionIndex];
    final isCorrect = answer == question.correct;

    setState(() {
      _selectedAnswer = answer;
      _showExplanation = true;
      if (isCorrect) {
        _score++;
        _heartBursts++;
      }
    });

    // Feed the answer back into the schedule. A recognition question is
    // easier than the review screen's free recall, so a hit only earns
    // "good" — never "easy" — while a miss is a genuine lapse.
    final reviewItemId = question.reviewItemId;
    if (reviewItemId != null) {
      Provider.of<VocabProvider>(context, listen: false).grade(
        reviewItemId,
        isCorrect ? ReviewGrade.good : ReviewGrade.again,
      );
    }
  }

  /// Out of the quiz, the way it was come in: back to the town, with the pet
  /// where it was left, at the school's door. Reached some other way, with no
  /// town under it, it goes to the town rather than home -- the quizzes live
  /// there now.
  void _leaveQuiz(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/scenarios');
    }
  }

  Future<void> _goToNextQuestion() async {
    if (_currentQuestionIndex == _questions.length - 1) {
      // Last question - show rewards popup
      final quizProvider = Provider.of<QuizProvider>(context, listen: false);
      final characterProvider = Provider.of<CharacterProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final adsProvider = Provider.of<AdsProvider>(context, listen: false);

      final reward = ProgressionUtils.getQuizRewardOutcome(
        correctAnswers: _score,
        totalQuestions: _questions.length,
      );

      // Scale before applying the pet deltas, while the pet is still in its
      // pre-quiz condition — a sick pet earns half.
      final wasSick = characterProvider.isSick;
      // XP is not scaled by sickness, unlike the coins and the happiness
      // bump below. The pet's bond stage is projected from XP, and a quiz
      // taken with a hungry pet still counts as learning together.
      final grantedXp = reward.xpReward;

      // A quiz the spaced-repetition schedule did not ask for pays a
      // fraction. The schedule already knows how much there is worth studying
      // today; this lets it pace the coin economy too, instead of the
      // player's patience for the same five questions. See `gold.dart`.
      final rawCoins = _drawnFromDueQueue
          ? reward.coinReward
          : (reward.coinReward * GoldConstants.repeatQuizRate).round();

      characterProvider.applyQuizRewards(
        happinessDelta: reward.happinessDelta,
        hungerDelta: reward.hungerDelta,
      );
      characterProvider.recordLearningMoment();
      await userProvider.addXp(grantedXp);
      final coinAward = await userProvider.awardLearningGold(
        characterProvider.scaleReward(rawCoins),
        GoldSource.quiz,
      );
      final grantedCoins = coinAward.paid;

      quizProvider.clearProgress();

      if (!mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.transparent,
        builder: (_) => QuizRewardsPopup(
          score: _score,
          totalQuestions: _questions.length,
          level: reward.level,
          xpReward: grantedXp,
          coinReward: grantedCoins,
          happinessDelta: reward.happinessDelta,
          hungerDelta: reward.hungerDelta,
          passed: reward.passed,
          sickPenaltyApplied: wasSick,
          onContinue: () => Navigator.of(context, rootNavigator: true).pop(),
        ),
      );

      // After the reward popup, never before it: the payoff for the work
      // must not be the thing that gets interrupted. Does nothing when the
      // hour cooldown has not elapsed, or the player holds a membership --
      // the guard lives in AdsProvider so both completion screens ask the
      // same question.
      if (!mounted) return;
      await adsProvider.maybeShowInterstitial();

      if (!mounted) return;
      _leaveQuiz(context);
    } else {
      setState(() {
        _showExplanation = false;
        _selectedAnswer = null;
        _currentQuestionIndex++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final l10n = AppLocalizations.of(context)!;
    final textDirection =
        textDirectionForLocale(Localizations.localeOf(context));

    // Safety check just in case
    final questionData =
        _questions.isEmpty ? null : _questions[_currentQuestionIndex];

    return TutorialOfferHost(
      id: TutorialId.quiz,
      // Nothing worth pointing at until a real question is on screen: while
      // the tailored set is being written the card says "PREPARING..." and
      // the options are placeholders.
      enabled: questionData != null && !_isGenerating,
      steps: () => [
        quizHeaderShowcaseKey,
        quizQuestionShowcaseKey,
        quizOptionsShowcaseKey,
        quizContinueShowcaseKey,
      ],
      child: questionData == null
          ? const SizedBox.shrink()
          : QuizStage(
            showcase: true,
            // No level here: it is a number about the player, and this is a
            // lesson. The meter takes the room so Pause stays at the end even
            // when the meter is hidden.
            header: Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: _allowanceMeter(userProvider, l10n, textDirection),
                  ),
                ),
                _pauseButton(l10n, textDirection),
              ],
            ),
            // While the tailored quiz is still being written, say so rather than
            // counting questions that are about to be replaced.
            badgeLabel: _isGenerating
                ? l10n.quizPreparing
                : l10n.quizQuestionCounter(
                    _currentQuestionIndex + 1, _questions.length),
            prompt: questionData.question.isEmpty
                ? l10n.quizPickAnswer
                : questionData.question,
            topic: questionData.topic,
            options: questionData.options,
            stateOf: (option) {
              if (!_showExplanation) return QuizOptionState.idle;
              if (option == questionData.correct) return QuizOptionState.correct;
              if (option == _selectedAnswer) return QuizOptionState.wrong;
              return QuizOptionState.idle;
            },
            onAnswer: _showExplanation ? null : _handleAnswer,
            bubbleText: _showExplanation
                ? (questionData.explanation.isEmpty
                    ? l10n.quizWellDone
                    : questionData.explanation)
                : l10n.quizEncouragement,
            heartBurstId: _heartBursts,
            continueLabel: l10n.continueBtn,
            onContinue: _showExplanation ? _goToNextQuestion : null,
          ),
    );
  }

  /// Today's AI quizzes, spent against the allowance.
  ///
  /// Added because without it the wall was the first time anyone learned a
  /// limit existed — a rule you only meet by breaking it reads as the app
  /// changing its mind, not as a rule. A player who can see two of three left
  /// is being told what to expect; one who cannot is being ambushed.
  ///
  /// Hidden for members, who have enough that counting is noise rather than
  /// information, and hidden once the meter is spent — at that point the sheet
  /// has already said it, and a zero sitting in the header while the player
  /// works through the local quiz is a reproach for studying.
  Widget _allowanceMeter(
    UserProvider userProvider,
    AppLocalizations l10n,
    TextDirection textDirection,
  ) {
    final remaining = userProvider.aiRemaining(AiSpend.quiz);
    if (userProvider.isPremium || remaining <= 0) {
      return const SizedBox.shrink();
    }

    final total = userProvider.aiLimit(AiSpend.quiz);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        l10n.aiLimitUsage(total - remaining, total),
        textDirection: textDirection,
        textAlign: TextAlign.center,
        style: AppFonts.pressStart2p(
          fontSize: 8,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }

  Widget _pauseButton(AppLocalizations l10n, TextDirection textDirection) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppTheme.retroUi,
        border: Border.all(color: AppTheme.retroDark, width: 4),
        boxShadow: const [
          BoxShadow(
              color: AppTheme.retroDark, offset: Offset(4, 4), blurRadius: 0)
        ],
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        // No round ink ripple inside the square retro frame.
        style: const ButtonStyle(
          overlayColor: WidgetStatePropertyAll(Colors.transparent),
        ),
        icon: const Icon(Icons.pause, color: AppTheme.retroDark),
        onPressed: () => _showPauseDialog(l10n, textDirection),
      ),
    );
  }

  void _showPauseDialog(AppLocalizations l10n, TextDirection textDirection) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.quizPausedTitle.toUpperCase(),
              textDirection: textDirection,
              textAlign: TextAlign.center,
              style: AppFonts.pressStart2p(
                fontSize: 16,
                color: AppTheme.retroDark,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.quizPausedPrompt,
              textDirection: textDirection,
              textAlign: TextAlign.center,
              style: AppFonts.pressStart2p(
                fontSize: 10,
                height: 1.5,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _pauseAction(
                  label: l10n.quizPlay.toUpperCase(),
                  color: AppTheme.retroGreen,
                  textColor: AppTheme.retroDark,
                  textDirection: textDirection,
                  onTap: () => Navigator.pop(context),
                ),
                _pauseAction(
                  label: l10n.quizPause.toUpperCase(),
                  color: AppTheme.retroAccent,
                  textColor: AppTheme.retroDark,
                  textDirection: textDirection,
                  onTap: () async {
                    // Save current progress and exit to home.
                    final quizProvider =
                        Provider.of<QuizProvider>(context, listen: false);
                    await quizProvider.saveProgress(
                        _currentQuestionIndex, _score);
                    if (context.mounted) {
                      Navigator.pop(context);
                      // Progress will be restored next time.
                      _leaveQuiz(context);
                    }
                  },
                ),
                _pauseAction(
                  label: l10n.quizExit.toUpperCase(),
                  color: AppTheme.retroPrimary,
                  textColor: Colors.white,
                  textDirection: textDirection,
                  onTap: () async {
                    final quizProvider =
                        Provider.of<QuizProvider>(context, listen: false);
                    await quizProvider.clearProgress();
                    if (context.mounted) {
                      Navigator.pop(context);
                      _leaveQuiz(context);
                    }
                  },
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _pauseAction({
    required String label,
    required Color color,
    required Color textColor,
    required TextDirection textDirection,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: AppTheme.retroDark, width: 2),
          boxShadow: const [
            BoxShadow(color: AppTheme.retroDark, offset: Offset(2, 2))
          ],
        ),
        child: Text(
          label,
          textDirection: textDirection,
          textAlign: TextAlign.center,
          style: AppFonts.pressStart2p(fontSize: 8, color: textColor),
        ),
      ),
    );
  }
}
