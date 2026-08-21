import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../constants/theme.dart';
import '../components/character_sprite.dart';
import '../components/quiz_rewards_popup.dart';
import '../providers/user_provider.dart';
import '../providers/quiz_provider.dart';
import '../providers/character_provider.dart';
import '../providers/language_provider.dart';
import '../providers/vocab_provider.dart';
import '../providers/calibration_provider.dart';
import '../utils/progression_utils.dart';
import '../services/ai_guard.dart';
import '../services/ai_service.dart';
import '../utils/srs_quiz_builder.dart';
import '../utils/quiz_briefing.dart';
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

    // Show the locally-built quiz immediately so the screen is never empty
    // while the request is in flight.
    final local = _buildSrsQuestions();
    setState(() {
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

    final guard = AiGuard.checkRequest(
      kind: AiRequestKind.quiz,
      source: 'quiz_screen',
    );
    if (!guard.allowed) return const [];
    AiGuard.recordRequest('quiz_screen');

    final prompt = QuizBriefing.build(
      targetLanguage: language.targetLanguage?.name ?? 'Spanish',
      nativeLanguage: language.nativeLanguage.name,
      level: level,
      troubleSpots: troubleSpots,
      dueItems: dueItems,
      languageCode: code,
    );

    try {
      final response = await AiService.instance.generateText(
        prompt: prompt,
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
        allowedReviewItemIds: QuizBriefing.offeredIds(
          troubleSpots: troubleSpots,
          dueItems: dueItems,
        ),
      );

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

  Future<void> _goToNextQuestion() async {
    if (_currentQuestionIndex == _questions.length - 1) {
      // Last question - show rewards popup
      final quizProvider = Provider.of<QuizProvider>(context, listen: false);
      final characterProvider = Provider.of<CharacterProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      final reward = ProgressionUtils.getQuizRewardOutcome(
        correctAnswers: _score,
        totalQuestions: _questions.length,
      );

      // Scale before applying the pet deltas, while the pet is still in its
      // pre-quiz condition — a sick pet earns half.
      final wasSick = characterProvider.isSick;
      final grantedXp = characterProvider.scaleReward(reward.xpReward);
      final grantedCoins = characterProvider.scaleReward(reward.coinReward);

      characterProvider.applyQuizRewards(
        happinessDelta: reward.happinessDelta,
        hungerDelta: reward.hungerDelta,
      );
      // Bond, unlike the happiness bump above, is not scaled by sickness and
      // not spendable — a quiz taken with a hungry pet still counts as
      // learning together.
      characterProvider.recordQuizLearning(
        correctAnswers: _score,
        totalQuestions: _questions.length,
      );
      await userProvider.addXp(grantedXp);
      await userProvider.addCoins(grantedCoins);

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

      if (!mounted) return;
      context.go('/');
    } else {
      setState(() {
        _showExplanation = false;
        _selectedAnswer = null;
        _currentQuestionIndex++;
      });
    }
  }

  Widget _pixel(Color color) {
    return Container(width: 8, height: 8, color: color);
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final textDirection = textDirectionForLocale(locale);
    final textAlign = textAlignForLocale(locale);
    
    // Safety check just in case
    if (_questions.isEmpty) return const SizedBox.shrink();

    final questionData = _questions[_currentQuestionIndex];
    final mainTopic = questionData.topic;
    final subText = questionData.question.isEmpty
        ? 'Select the correct option'
        : questionData.question;
    final options = questionData.options;
    
    // Bubble logic
    final bubbleText = _showExplanation 
        ? (questionData.explanation.isEmpty
            ? "Great job!"
            : questionData.explanation)
        : "You got this!";

    return Container(
      color: AppTheme.retroSky, // Consistent BG
      child: Stack(
        children: [
          // 1. Background Layer
          Column(
            children: [
              Expanded(
                flex: 5,
                child: Container(
                  color: AppTheme.retroSky,
                  child: Stack(
                    children: [
                       Positioned(
                         top: 40, left: 30,
                         child: Container(
                           width: 48, height: 48, 
                           color: AppTheme.retroAccent, 
                           child: Container(decoration: BoxDecoration(border: Border.all(width: 4, color: AppTheme.retroDark)))
                         )
                      ),
                      Positioned(
                         top: 70, right: 40,
                         child: Row(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                              Container(width: 64, height: 32, decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppTheme.retroDark, width: 4))),
                              Transform.translate(offset: const Offset(-16, -16), child: Container(width: 48, height: 32, decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppTheme.retroDark, width: 4)))),
                           ],
                         )
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 4, 
                child: Container(
                  width: double.infinity,
                  color: AppTheme.retroGrass,
                  child: Stack(
                    children: [
                        Align(alignment: Alignment.topCenter, child: Container(height: 4, color: AppTheme.retroDark)),
                        Positioned(top: 8, left: 0, right: 0, child: Container(height: 16, color: AppTheme.retroGrassDark.withValues(alpha: 0.2))),
                        Positioned(top: 40, left: 40, child: _pixel(AppTheme.retroGrassDark)),
                        Positioned(top: 48, left: 48, child: _pixel(AppTheme.retroGrassDark)),
                        Positioned(top: 80, right: 80, child: _pixel(AppTheme.retroGrassDark)),
                        Positioned(top: 150, left: 100, child: _pixel(AppTheme.retroGrassDark)),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 2. Main Content
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false, 
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16), // Bottom padding for scrolling
                    child: Column(
                      children: [
                        // Top Bar
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Level Pill (Matched to Home Screen)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: AppTheme.retroDark, width: 4),
                                  boxShadow: const [BoxShadow(color: AppTheme.retroDark, offset: Offset(4, 4), blurRadius: 0)],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 24, height: 24,
                                      decoration: BoxDecoration(
                                        color: AppTheme.retroAccent,
                                        border: Border.all(color: AppTheme.retroDark, width: 2),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${userProvider.stats.level}', 
                                          textDirection: TextDirection.ltr,
                                          textAlign: TextAlign.left,
                                          style: AppFonts.pressStart2p(fontSize: 8, color: AppTheme.retroDark)
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${l10n.xp}: ${userProvider.stats.currentLevelXP}/${userProvider.stats.nextLevelXP}',
                                          textDirection: TextDirection.ltr,
                                          textAlign: TextAlign.left,
                                          style: AppFonts.pressStart2p(fontSize: 8, color: AppTheme.retroDark),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          width: 80, height: 8,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[300],
                                            border: Border.all(color: AppTheme.retroDark, width: 2),
                                          ),
                                          child: FractionallySizedBox(
                                            alignment: Alignment.centerLeft,
                                            widthFactor: userProvider.stats.progress,
                                            child: Container(color: AppTheme.retroPrimary),
                                          ),
                                        )
                                      ],
                                    )
                                  ],
                                ),
                              ),
                              // Pause Button
                              Container(
                                width: 48, height: 48,
                                decoration: BoxDecoration(
                                  color: AppTheme.retroUi,
                                  border: Border.all(color: AppTheme.retroDark, width: 4),
                                  boxShadow: const [BoxShadow(color: AppTheme.retroDark, offset: Offset(4, 4), blurRadius: 0)],
                                ),
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  // No round ink ripple inside the square
                                  // retro frame.
                                  style: const ButtonStyle(
                                    overlayColor: WidgetStatePropertyAll(
                                        Colors.transparent),
                                  ),
                                  icon: const Icon(Icons.pause, color: AppTheme.retroDark),
                                  onPressed: () {
                                     // Use standard dialog
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
                                                  // Play Button
                                                  GestureDetector(
                                                    onTap: () => Navigator.pop(context),
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                      decoration: BoxDecoration(
                                                        color: AppTheme.retroGreen,
                                                        border: Border.all(color: AppTheme.retroDark, width: 2),
                                                        boxShadow: const [BoxShadow(color: AppTheme.retroDark, offset: Offset(2, 2))],
                                                      ),
                                                      child: Text(
                                                        l10n.quizPlay.toUpperCase(),
                                                        textDirection: textDirection,
                                                        textAlign: TextAlign.center,
                                                        style: AppFonts.pressStart2p(fontSize: 8, color: AppTheme.retroDark),
                                                      ),
                                                    ),
                                                  ),
                                                  // Pause Button
                                                  GestureDetector(
                                                    onTap: () async {
                                                      // Save current progress and exit to home
                                                      final quizProvider = Provider.of<QuizProvider>(context, listen: false);
                                                      await quizProvider.saveProgress(_currentQuestionIndex, _score);
                                                      if (context.mounted) {
                                                        Navigator.pop(context); // Close dialog
                                                        context.go('/'); // Go home - progress will be restored next time
                                                      }
                                                    },
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                      decoration: BoxDecoration(
                                                        color: AppTheme.retroAccent,
                                                        border: Border.all(color: AppTheme.retroDark, width: 2),
                                                        boxShadow: const [BoxShadow(color: AppTheme.retroDark, offset: Offset(2, 2))],
                                                      ),
                                                      child: Text(
                                                        l10n.quizPause.toUpperCase(),
                                                        textDirection: textDirection,
                                                        textAlign: TextAlign.center,
                                                        style: AppFonts.pressStart2p(fontSize: 8, color: AppTheme.retroDark),
                                                      ),
                                                    ),
                                                  ),
                                                  // Exit Button
                                                  GestureDetector(
                                                    onTap: () async {
                                                       final quizProvider = Provider.of<QuizProvider>(context, listen: false);
                                                       await quizProvider.clearProgress();
                                                       if (context.mounted) {
                                                         Navigator.pop(context);
                                                         context.go('/');
                                                       }
                                                    }, 
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                      decoration: BoxDecoration(
                                                        color: AppTheme.retroPrimary,
                                                        border: Border.all(color: AppTheme.retroDark, width: 2),
                                                        boxShadow: const [BoxShadow(color: AppTheme.retroDark, offset: Offset(2, 2))],
                                                      ),
                                                      child: Text(
                                                        l10n.quizExit.toUpperCase(),
                                                        textDirection: textDirection,
                                                        textAlign: TextAlign.center,
                                                        style: AppFonts.pressStart2p(fontSize: 8, color: Colors.white),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              )
                                            ],
                                          ),
                                        ),
                                     );
                                  }, 
                                ),
                              )
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Question Box
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.topCenter,
                            children: [
                              Container(
                                width: double.infinity,
                                constraints: const BoxConstraints(minHeight: 180),
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: AppTheme.retroDark, width: 4),
                                  boxShadow: const [BoxShadow(color: AppTheme.retroDark, offset: Offset(6, 6), blurRadius: 0)],
                                ),
                                child: Column(
                                  children: [
                                    const SizedBox(height: 32), // Space for header overlap
                                    Text(
                                      subText, // e.g. "How do you say..."
                                      textDirection: textDirection,
                                      textAlign: TextAlign.center,
                                      style: AppFonts.pressStart2p(
                                        fontSize: 10,
                                        height: 1.8,
                                        color: Colors.grey[600],
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      mainTopic, // e.g. "Greetings"
                                      textDirection: textDirection,
                                      textAlign: TextAlign.center,
                                      style: AppFonts.pressStart2p(
                                        fontSize: 20,
                                        height: 1.4,
                                        color: AppTheme.retroDark,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // "Question X/10" Header
                              Positioned(
                                top: -16,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.retroPrimary,
                                    border: Border.all(color: AppTheme.retroDark, width: 4),
                                  ),
                                  child: Text(
                                    // While the tailored quiz is still being
                                    // written, say so rather than counting
                                    // questions that are about to be replaced.
                                    _isGenerating
                                        ? "PREPARING..."
                                        : "QUESTION ${_currentQuestionIndex + 1}/${_questions.length}",
                                    textDirection: TextDirection.ltr,
                                    textAlign: TextAlign.left,
                                    style: AppFonts.pressStart2p(
                                      fontSize: 10,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              // Corner dots
                              Positioned(top: 8, left: 8, child: _pixel(AppTheme.retroDark)),
                              Positioned(top: 8, right: 8, child: _pixel(AppTheme.retroDark)),
                              Positioned(bottom: 8, left: 8, child: _pixel(AppTheme.retroDark)),
                              Positioned(bottom: 8, right: 8, child: _pixel(AppTheme.retroDark)),
                            ],
                          ),
                        ),

                        // Spacer to push content down gently, but collapses on small screens
                        const SizedBox(height: 12),

                        // Options Grid
                        // Options Grid (Custom Wrap/Column to avoid ShrinkWrappingViewport issues)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          child: Column(
                            children: [
                              for (int i = 0; i < options.length; i += 2)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: Row(
                                    children: [
                                      Expanded(child: _buildOption(options[i], questionData)),
                                      const SizedBox(width: 16),
                                      if (i + 1 < options.length)
                                        Expanded(child: _buildOption(options[i + 1], questionData))
                                      else
                                        const Spacer(),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        
                        // Spacer pushes the Pet to the bottom
                        const SizedBox(height: 24),

                        // Character & Speech Bubble
                        Padding(
                          padding: const EdgeInsets.only(right: 24, bottom: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                               // Speech Bubble
                               Container(
                                 padding: const EdgeInsets.all(12),
                                 margin: const EdgeInsets.only(right: 8), 
                                 constraints: const BoxConstraints(maxWidth: 180),
                                 decoration: BoxDecoration(
                                   color: Colors.white,
                                   border: Border.all(color: AppTheme.retroDark, width: 3),
                                   boxShadow: const [BoxShadow(color: AppTheme.retroDark, offset: Offset(3, 3), blurRadius: 0)],
                                 ),
                                 child: Text(
                                   bubbleText,
                                   textDirection: textDirection,
                                   textAlign: textAlign,
                                   style: AppFonts.pressStart2p(fontSize: 8, height: 1.5, color: AppTheme.retroDark),
                                 ),
                               ),
                               // Pet Avatar
                               const CharacterSprite(
                                width: 96,
                                height: 96,
                               ),
                            ],
                          ),
                        ),

                        // Continue Button (appears after answer is selected)
                        if (_showExplanation)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: GestureDetector(
                              onTap: _goToNextQuestion,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  color: AppTheme.retroPrimary,
                                  border: Border.all(color: AppTheme.retroDark, width: 4),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: AppTheme.retroDark,
                                      offset: Offset(4, 4),
                                      blurRadius: 0,
                                    ),
                                  ],
                                ),
                                child: Text(
                                  'CONTINUE',
                                  textDirection: textDirection,
                                  textAlign: TextAlign.center,
                                  style: AppFonts.pressStart2p(
                                    fontSize: 12,
                                    color: Colors.white,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOption(String opt, QuizQuestion questionData) {
    bool isSelected = _selectedAnswer == opt;
    bool isCorrect = opt == questionData.correct;
    Color bgColor = Colors.white;
    
    if (_showExplanation) {
      if (isCorrect) {
        bgColor = AppTheme.retroGrass;
      } else if (isSelected) {
        bgColor = AppTheme.retroPrimary;
      }
    }

    return GestureDetector(
      onTap: () => _handleAnswer(opt),
      child: AspectRatio(
        aspectRatio: 1.4,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.all(color: AppTheme.retroDark, width: 4),
            boxShadow: const [BoxShadow(color: AppTheme.retroDark, offset: Offset(4, 4), blurRadius: 0)],
          ),
          child: Text(
            opt,
            textDirection: textDirectionForLocale(Localizations.localeOf(context)),
            textAlign: TextAlign.center,
            style: AppFonts.pressStart2p(
              fontSize: 10,
              color: AppTheme.retroDark,
              height: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
