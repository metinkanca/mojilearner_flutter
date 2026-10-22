import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../constants/theme.dart';
import '../../components/character_sprite.dart';
import '../../components/quiz_stage.dart';
import '../../components/quiz_rewards_popup.dart';
import '../../l10n/app_localizations.dart';
import '../../router.dart';
import '../../providers/character_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/offline_detector.dart';
import '../../utils/level_validator.dart';
import '../../utils/progression_utils.dart';
import '../../utils/quiz_response_parser.dart';
import '../../utils/rtl_locale.dart';
import '../../services/ai_guard.dart';
import '../../services/ai_prompt_spec.dart';
import '../../services/ai_service.dart';
import '../../../utils/fonts.dart';

class AdaptiveQuizScreen extends StatefulWidget {
  final String? aiLevel;

  const AdaptiveQuizScreen({super.key, this.aiLevel});

  @override
  State<AdaptiveQuizScreen> createState() => _AdaptiveQuizScreenState();
}

class _AdaptiveQuizScreenState extends State<AdaptiveQuizScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _questions = [];
  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _showExplanation = false;
  bool _usingLocalFallback = false;
  String? _selectedAnswer;

  /// Bumped on a right answer, which is what plays the hearts. See
  /// [QuizClassFloor.heartBurstId].
  int _heartBursts = 0;

  @override
  void initState() {
    super.initState();
    _generateQuiz();
  }

  Future<void> _generateQuiz() async {
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
    final targetLang = languageProvider.targetLanguage?.name ?? 'Spanish';
    final targetCode = languageProvider.targetLanguage?.code ?? 'es';
    final aiLevel = LevelValidator.normalizeLevel(widget.aiLevel);

    // Use mock questions if offline
    if (OfflineDetector.isOfflineMode) {
      setState(() {
        _usingLocalFallback = false;
        _questions = _getMockQuestions(targetCode, aiLevel);
        _isLoading = false;
      });
      return;
    }

    if (!AiService.instance.isAiAvailable) {
      setState(() {
        _usingLocalFallback = true;
        _questions = _getFallbackQuestions(targetLang, aiLevel);
        _isLoading = false;
      });
      return;
    }

    try {
      // 🔒 SECURITY: Rate limiting for quiz generation
      final guard = AiGuard.checkRequest(
        kind: AiRequestKind.quiz,
        source: 'adaptive_quiz',
      );
      if (!guard.allowed) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(guard.rateLimitMessage),
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      AiGuard.recordRequest('adaptive_quiz');

      // The same quiz prompt the main quiz asks for, instead of a hand-rolled
      // one that sanitized its inputs into `sanitizedAiLevel` and then
      // interpolated the raw `$aiLevel` three lines later — the one value on
      // this screen derived from what the learner typed during the chat
      // assessment, and so the one that needed it. The level now travels as
      // data and the server normalises it to one of three words.
      //
      // The AI-determined level is what the app goes on to use everywhere
      // else, so it is the level the quiz is built for; onboarding has no
      // review history to send with it.
      final aiText = await AiService.instance.generateText(
        spec: AiPromptSpec.quiz(
          targetCode: targetCode,
          nativeCode: languageProvider.nativeLanguage.code,
          level: aiLevel,
        ),
        source: 'adaptive_quiz_screen',
        // Same reasoning as the main quiz: structured JSON, no thinking.
        config: AiGenerationConfig.structuredJson,
      );

      // Validated parse: exactly four distinct options, the correct answer
      // present among them, fields capped and markers escaped. A reply that
      // survives none of that falls through to the local set rather than
      // rendering an unanswerable question.
      final parsed = aiText.isEmpty
          ? const <Map<String, dynamic>>[]
          : QuizResponseParser.parseAsMaps(aiText);

      if (parsed.isNotEmpty) {
        setState(() {
          _usingLocalFallback = false;
          _questions = parsed;
          _isLoading = false;
        });
      } else {
        setState(() {
          _usingLocalFallback = true;
          _questions = _getFallbackQuestions(targetLang, aiLevel);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error generating quiz: $e');
      // Fallback questions
      setState(() {
        _usingLocalFallback = true;
        _questions = _getFallbackQuestions(targetLang, aiLevel);
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getFallbackQuestions(String lang, String level) {
    // Simple fallback questions
    return [
      {
        "question": "Basic greeting in $lang",
        "topic": "Hello",
        "options": ["Option 1", "Option 2", "Option 3", "Option 4"],
        "correct": "Option 1",
        "explanation": "This is a basic greeting."
      },
      {
        "question": "Common word in $lang",
        "topic": "Thank you",
        "options": ["A", "B", "C", "D"],
        "correct": "A",
        "explanation": "This phrase expresses gratitude."
      },
      {
        "question": "Simple question in $lang",
        "topic": "How are you?",
        "options": ["1", "2", "3", "4"],
        "correct": "1",
        "explanation": "This is how you ask about someone's wellbeing."
      },
      {
        "question": "Basic word in $lang",
        "topic": "Goodbye",
        "options": ["X", "Y", "Z", "W"],
        "correct": "X",
        "explanation": "This is used when parting."
      },
      {
        "question": "Common phrase in $lang",
        "topic": "Please",
        "options": ["Alpha", "Beta", "Gamma", "Delta"],
        "correct": "Alpha",
        "explanation": "This is a polite way to make requests."
      },
    ];
  }

  List<Map<String, dynamic>> _getMockQuestions(
      String languageCode, String level) {
    // Mock questions for offline mode - basic questions in common languages
    final mockQuestions = <String, List<Map<String, dynamic>>>{
      'tr': [
        // Turkish
        {
          "question": "How do you say 'Hello' in Turkish?",
          "topic": "Greetings",
          "options": ["Merhaba", "Günaydın", "İyi akşamlar", "Hoşça kal"],
          "correct": "Merhaba",
          "explanation":
              "Merhaba is the general greeting for 'hello' in Turkish.",
        },
        {
          "question": "What does 'Teşekkür ederim' mean?",
          "topic": "Courtesy",
          "options": ["Thank you", "Please", "Sorry", "Goodbye"],
          "correct": "Thank you",
          "explanation": "Teşekkür ederim means 'thank you' in Turkish.",
        },
        {
          "question": "How do you say 'Yes' in Turkish?",
          "topic": "Basic Words",
          "options": ["Evet", "Hayır", "Belki", "Tamam"],
          "correct": "Evet",
          "explanation": "Evet means 'yes' in Turkish.",
        },
        {
          "question": "What is the Turkish word for 'water'?",
          "topic": "Basic Vocabulary",
          "options": ["Su", "Ekmek", "Süt", "Çay"],
          "correct": "Su",
          "explanation": "Su is the Turkish word for water.",
        },
        {
          "question": "How do you say 'Goodbye' in Turkish?",
          "topic": "Farewells",
          "options": ["Hoşça kal", "Merhaba", "Güle güle", "İyi günler"],
          "correct": "Hoşça kal",
          "explanation": "Hoşça kal means 'goodbye' (said by the one leaving).",
        },
      ],
      'es': [
        // Spanish
        {
          "question": "How do you say 'Hello' in Spanish?",
          "topic": "Greetings",
          "options": ["Hola", "Adiós", "Gracias", "Por favor"],
          "correct": "Hola",
          "explanation": "Hola is the Spanish word for 'hello'.",
        },
        {
          "question": "What does 'Gracias' mean?",
          "topic": "Courtesy",
          "options": ["Thank you", "Please", "Sorry", "Goodbye"],
          "correct": "Thank you",
          "explanation": "Gracias means 'thank you' in Spanish.",
        },
        {
          "question": "How do you say 'Yes' in Spanish?",
          "topic": "Basic Words",
          "options": ["Sí", "No", "Quizás", "Vale"],
          "correct": "Sí",
          "explanation": "Sí means 'yes' in Spanish.",
        },
        {
          "question": "What is the Spanish word for 'water'?",
          "topic": "Basic Vocabulary",
          "options": ["Agua", "Pan", "Leche", "Café"],
          "correct": "Agua",
          "explanation": "Agua is the Spanish word for water.",
        },
        {
          "question": "How do you say 'Please' in Spanish?",
          "topic": "Courtesy",
          "options": ["Por favor", "Gracias", "De nada", "Perdón"],
          "correct": "Por favor",
          "explanation": "Por favor means 'please' in Spanish.",
        },
      ],
      'fr': [
        // French
        {
          "question": "How do you say 'Hello' in French?",
          "topic": "Greetings",
          "options": ["Bonjour", "Au revoir", "Merci", "S'il vous plaît"],
          "correct": "Bonjour",
          "explanation": "Bonjour is the French word for 'hello'.",
        },
        {
          "question": "What does 'Merci' mean?",
          "topic": "Courtesy",
          "options": ["Thank you", "Please", "Sorry", "Goodbye"],
          "correct": "Thank you",
          "explanation": "Merci means 'thank you' in French.",
        },
        {
          "question": "How do you say 'Yes' in French?",
          "topic": "Basic Words",
          "options": ["Oui", "Non", "Peut-être", "D'accord"],
          "correct": "Oui",
          "explanation": "Oui means 'yes' in French.",
        },
        {
          "question": "What is the French word for 'water'?",
          "topic": "Basic Vocabulary",
          "options": ["Eau", "Pain", "Lait", "Café"],
          "correct": "Eau",
          "explanation": "Eau is the French word for water.",
        },
        {
          "question": "How do you say 'Please' in French?",
          "topic": "Courtesy",
          "options": ["S'il vous plaît", "Merci", "De rien", "Pardon"],
          "correct": "S'il vous plaît",
          "explanation": "S'il vous plaît means 'please' in French.",
        },
      ],
      'de': [
        // German
        {
          "question": "How do you say 'Hello' in German?",
          "topic": "Greetings",
          "options": ["Hallo", "Auf Wiedersehen", "Danke", "Bitte"],
          "correct": "Hallo",
          "explanation": "Hallo is the German word for 'hello'.",
        },
        {
          "question": "What does 'Danke' mean?",
          "topic": "Courtesy",
          "options": ["Thank you", "Please", "Sorry", "Goodbye"],
          "correct": "Thank you",
          "explanation": "Danke means 'thank you' in German.",
        },
        {
          "question": "How do you say 'Yes' in German?",
          "topic": "Basic Words",
          "options": ["Ja", "Nein", "Vielleicht", "Okay"],
          "correct": "Ja",
          "explanation": "Ja means 'yes' in German.",
        },
        {
          "question": "What is the German word for 'water'?",
          "topic": "Basic Vocabulary",
          "options": ["Wasser", "Brot", "Milch", "Kaffee"],
          "correct": "Wasser",
          "explanation": "Wasser is the German word for water.",
        },
        {
          "question": "How do you say 'Please' in German?",
          "topic": "Courtesy",
          "options": ["Bitte", "Danke", "Gern geschehen", "Entschuldigung"],
          "correct": "Bitte",
          "explanation": "Bitte means 'please' in German.",
        },
      ],
    };

    // Return questions for the language, or default to Spanish
    return mockQuestions[languageCode] ?? mockQuestions['es']!;
  }

  void _handleAnswer(String answer) {
    if (_showExplanation) return;

    setState(() {
      _selectedAnswer = answer;
      _showExplanation = true;
      if (answer == _questions[_currentQuestionIndex]['correct']) {
        _score++;
        _heartBursts++;
      }
    });
  }

  Future<void> _goToNextQuestion() async {
    if (_currentQuestionIndex == _questions.length - 1) {
      // Last question - show performance rewards popup, then navigate home
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final characterProvider =
          Provider.of<CharacterProvider>(context, listen: false);

      final reward = ProgressionUtils.getQuizRewardOutcome(
        correctAnswers: _score,
        totalQuestions: _questions.length,
      );

      characterProvider.applyQuizRewards(
        happinessDelta: reward.happinessDelta,
        hungerDelta: reward.hungerDelta,
      );
      await userProvider.addXp(reward.xpReward);
      // No sickness scaling during onboarding — the pet starts at full health.
      await userProvider.addCoins(reward.coinReward);

      if (!mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.transparent,
        builder: (_) => QuizRewardsPopup(
          score: _score,
          totalQuestions: _questions.length,
          level: reward.level,
          xpReward: reward.xpReward,
          coinReward: reward.coinReward,
          happinessDelta: reward.happinessDelta,
          hungerDelta: reward.hungerDelta,
          passed: reward.passed,
          onContinue: () => Navigator.of(context, rootNavigator: true).pop(),
        ),
      );

      if (!mounted) return;
      // Not home yet: the pet has one thing left to teach, and onboarding is
      // only marked complete once it has. See [petTutorialRoute].
      context.go(petTutorialRoute);
    } else {
      // More questions - go to next question
      setState(() {
        _showExplanation = false;
        _selectedAnswer = null;
        _currentQuestionIndex++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isOffline = OfflineDetector.isOfflineMode;
    final showLocalFallbackIndicator = _usingLocalFallback && !isOffline;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.retroSky,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  border: Border.all(color: AppTheme.retroDark, width: 4),
                  boxShadow: const [
                    BoxShadow(
                      color: AppTheme.retroDark,
                      offset: Offset(6, 6),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: const Center(
                  child: CharacterSprite(
                    width: 80,
                    height: 80,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isOffline
                    ? 'Loading mock quiz...'
                    : (_usingLocalFallback
                        ? 'Loading local fallback quiz...'
                        : 'Generating quiz...'),
                textDirection:
                    textDirectionForLocale(Localizations.localeOf(context)),
                textAlign: TextAlign.center,
                style: AppFonts.pressStart2p(
                  fontSize: 10,
                  color: AppTheme.retroDark,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final question = _questions[_currentQuestionIndex];
    final correct = question['correct'];

    return QuizStage(
      banner: _banner(isOffline, showLocalFallbackIndicator),
      header: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppTheme.retroDark, width: 4),
              boxShadow: const [
                BoxShadow(
                    color: AppTheme.retroDark,
                    offset: Offset(4, 4),
                    blurRadius: 0)
              ],
            ),
            child: Text(
              '${_currentQuestionIndex + 1}/${_questions.length}',
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.center,
              style: AppFonts.pressStart2p(
                fontSize: 8,
                color: AppTheme.retroDark,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
      badgeLabel: l10n.quizQuestionCounter(
        _currentQuestionIndex + 1,
        _questions.length,
      ),
      // Empty as well as absent: a generated question can come back with the
      // field present and blank, and the daily quiz already falls back on
      // both. Two quizzes, one rule.
      prompt: _orElse(question['question'], l10n.quizPickAnswer),
      topic: question['topic'] ?? '',
      options: (question['options'] as List).cast<String>(),
      stateOf: (option) {
        if (!_showExplanation) return QuizOptionState.idle;
        if (option == correct) return QuizOptionState.correct;
        if (option == _selectedAnswer) return QuizOptionState.wrong;
        return QuizOptionState.idle;
      },
      onAnswer: _showExplanation ? null : _handleAnswer,
      bubbleText: _showExplanation
          ? _orElse(question['explanation'], l10n.quizWellDone)
          : l10n.quizEncouragement,
      heartBurstId: _heartBursts,
      continueLabel: l10n.continueBtn,
      onContinue: _showExplanation ? _goToNextQuestion : null,
    );
  }

  /// [value] when it is a string with something in it, else [fallback].
  static String _orElse(Object? value, String fallback) =>
      (value is String && value.trim().isNotEmpty) ? value : fallback;

  /// The yellow strip that says the quiz did not come from where it should
  /// have. Null when it came from the AI, which is the quiet case.
  Widget? _banner(bool isOffline, bool showLocalFallback) {
    final label = isOffline
        ? 'OFFLINE MODE - USING MOCK QUIZ'
        : (showLocalFallback ? 'ONLINE MODE - LOCAL FALLBACK QUIZ' : null);
    if (label == null) return null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: const Color(0xFFFFC107),
      child: Text(
        label,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
        style: AppFonts.pressStart2p(
          fontSize: 8,
          color: AppTheme.retroDark,
          decoration: TextDecoration.none,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
