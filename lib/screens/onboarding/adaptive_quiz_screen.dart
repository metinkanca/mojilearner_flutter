import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../constants/theme.dart';
import '../../components/character_sprite.dart';
import '../../components/quiz_rewards_popup.dart';
import '../../providers/calibration_provider.dart';
import '../../providers/character_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/offline_detector.dart';
import '../../utils/input_sanitizer.dart';
import '../../utils/level_validator.dart';
import '../../utils/progression_utils.dart';
import '../../utils/rtl_locale.dart';
import '../../services/ai_guard.dart';
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

  @override
  void initState() {
    super.initState();
    _generateQuiz();
  }

  String _getDifficultyDescription(String level) {
    switch (level.toLowerCase()) {
      case 'beginner':
        return 'basic vocabulary and simple grammar';
      case 'intermediate':
        return 'common phrases, grammar rules, and sentence construction';
      case 'advanced':
        return 'complex grammar, idioms, and nuanced expressions';
      default:
        return 'basic vocabulary and simple grammar';
    }
  }

  Future<void> _generateQuiz() async {
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
    final targetLang = languageProvider.targetLanguage?.name ?? 'Spanish';
    final targetCode = languageProvider.targetLanguage?.code ?? 'es';
    final aiLevel = LevelValidator.normalizeLevel(widget.aiLevel);

    // Get self-assessed level from proficiency
    final calibrationProvider =
        Provider.of<CalibrationProvider>(context, listen: false);
    final proficiency = calibrationProvider.getLanguageProficiency(targetCode);
    final selfLevel =
        LevelValidator.normalizeLevel(proficiency?.selfAssessedLevel);

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

    final difficulty = _getDifficultyDescription(aiLevel);

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

      // 🔒 SECURITY: Sanitize language inputs
      final sanitizedTargetLang =
          InputSanitizer.sanitizeLanguageName(targetLang) ?? 'Spanish';
      final sanitizedAiLevel =
          InputSanitizer.sanitizeLanguageName(aiLevel) ?? 'beginner';
      final sanitizedSelfLevel =
          InputSanitizer.sanitizeLanguageName(selfLevel) ?? 'beginner';
      final prompt =
          '''Generate exactly 5 multiple-choice questions to test $sanitizedTargetLang proficiency at $sanitizedAiLevel level.

User's self-assessment: $sanitizedSelfLevel
AI's assessment from chat: $sanitizedAiLevel

Focus on: $difficulty

Rules:
1. Generate questions matching $aiLevel difficulty
2. Each question should have 4 options
3. Include a brief explanation for the correct answer
4. Return ONLY valid JSON, no markdown code blocks
5. Make questions practical and useful

Format:
[
  {
    "question": "How do you say 'Hello' in $targetLang?",
    "topic": "Greeting",
    "options": ["Option1", "Option2", "Option3", "Option4"],
    "correct": "Option1",
    "explanation": "Brief explanation why this is correct"
  }
]

Generate 5 questions now:''';

      final aiText = await AiService.instance.generateText(
        prompt: prompt,
        source: 'adaptive_quiz_screen',
        // Same reasoning as the main quiz: structured JSON, no thinking.
        config: AiGenerationConfig.structuredJson,
      );

      if (aiText.isNotEmpty) {
        String jsonText = aiText.trim();
        // Remove markdown code blocks if present
        jsonText =
            jsonText.replaceAll('```json', '').replaceAll('```', '').trim();

        final List<dynamic> data = json.decode(jsonText);
        setState(() {
          _usingLocalFallback = false;
          _questions = data.cast<Map<String, dynamic>>();
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
      await userProvider.markOnboardingComplete();

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
      context.go('/');
    } else {
      // More questions - go to next question
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

  Widget _buildOption(String opt, Map<String, dynamic> questionData) {
    bool isSelected = _selectedAnswer == opt;
    bool isCorrect = opt == questionData['correct'];
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
            boxShadow: const [
              BoxShadow(
                  color: AppTheme.retroDark,
                  offset: Offset(4, 4),
                  blurRadius: 0)
            ],
          ),
          child: Text(
            opt,
            textDirection:
                textDirectionForLocale(Localizations.localeOf(context)),
            textAlign: textAlignForLocale(Localizations.localeOf(context)),
            style: AppFonts.pressStart2p(
              fontSize: 10,
              color: AppTheme.retroDark,
              height: 1.5,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOffline = OfflineDetector.isOfflineMode;
    final showLocalFallbackIndicator = _usingLocalFallback && !isOffline;
    final locale = Localizations.localeOf(context);
    final textDirection = textDirectionForLocale(locale);
    final textAlign = textAlignForLocale(locale);

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
                textDirection: textDirection,
                textAlign: textAlign,
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
    final mainTopic = question['topic'] ?? '';
    final subText = question['question'] ?? 'Select the correct option';
    final options = (question['options'] as List).cast<String>();

    // Bubble logic
    final bubbleText = _showExplanation
        ? (question['explanation'] ?? "Great job!")
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
                          top: 40,
                          left: 30,
                          child: Container(
                              width: 48,
                              height: 48,
                              color: AppTheme.retroAccent,
                              child: Container(
                                  decoration: BoxDecoration(
                                      border: Border.all(
                                          width: 4,
                                          color: AppTheme.retroDark))))),
                      Positioned(
                          top: 70,
                          right: 40,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                  width: 64,
                                  height: 32,
                                  decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(
                                          color: AppTheme.retroDark,
                                          width: 4))),
                              Transform.translate(
                                  offset: const Offset(-16, -16),
                                  child: Container(
                                      width: 48,
                                      height: 32,
                                      decoration: BoxDecoration(
                                          color: Colors.white,
                                          border: Border.all(
                                              color: AppTheme.retroDark,
                                              width: 4)))),
                            ],
                          )),
                      // Offline mode indicator (positioned in sky)
                      if (isOffline)
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            color: const Color(0xFFFFC107),
                            child: Text(
                              'OFFLINE MODE - USING MOCK QUIZ',
                              textDirection: textDirection,
                              textAlign: textAlign,
                              style: AppFonts.pressStart2p(
                                fontSize: 8,
                                color: AppTheme.retroDark,
                                decoration: TextDecoration.none,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      if (showLocalFallbackIndicator)
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            color: const Color(0xFFFFC107),
                            child: Text(
                              'ONLINE MODE - LOCAL FALLBACK QUIZ',
                              textDirection: textDirection,
                              textAlign: textAlign,
                              style: AppFonts.pressStart2p(
                                fontSize: 8,
                                color: AppTheme.retroDark,
                                decoration: TextDecoration.none,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
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
                      Align(
                          alignment: Alignment.topCenter,
                          child:
                              Container(height: 4, color: AppTheme.retroDark)),
                      Positioned(
                          top: 8,
                          left: 0,
                          right: 0,
                          child: Container(
                              height: 16,
                              color: AppTheme.retroGrassDark.withValues(alpha: 0.2))),
                      Positioned(
                          top: 40,
                          left: 40,
                          child: _pixel(AppTheme.retroGrassDark)),
                      Positioned(
                          top: 48,
                          left: 48,
                          child: _pixel(AppTheme.retroGrassDark)),
                      Positioned(
                          top: 80,
                          right: 80,
                          child: _pixel(AppTheme.retroGrassDark)),
                      Positioned(
                          top: 150,
                          left: 100,
                          child: _pixel(AppTheme.retroGrassDark)),
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
                    padding: const EdgeInsets.only(
                        bottom: 16), // Bottom padding for scrolling
                    child: Column(
                      children: [
                        // Top Bar
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // Progress indicator only
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                      color: AppTheme.retroDark, width: 4),
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
                                constraints:
                                    const BoxConstraints(minHeight: 180),
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                      color: AppTheme.retroDark, width: 4),
                                  boxShadow: const [
                                    BoxShadow(
                                        color: AppTheme.retroDark,
                                        offset: Offset(6, 6),
                                        blurRadius: 0)
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    const SizedBox(
                                        height: 32), // Space for header overlap
                                    Text(
                                      subText, // e.g. "How do you say..."
                                      textDirection: textDirection,
                                      textAlign: textAlign,
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
                                      textAlign: textAlign,
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
                              // "Question X/Y" Header
                              Positioned(
                                top: -16,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.retroPrimary,
                                    border: Border.all(
                                        color: AppTheme.retroDark, width: 4),
                                  ),
                                  child: Text(
                                    "QUESTION ${_currentQuestionIndex + 1}/${_questions.length}",
                                    textDirection: TextDirection.ltr,
                                    textAlign: TextAlign.center,
                                    style: AppFonts.pressStart2p(
                                      fontSize: 10,
                                      color: Colors.white,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                ),
                              ),
                              // Corner dots
                              Positioned(
                                  top: 8,
                                  left: 8,
                                  child: _pixel(AppTheme.retroDark)),
                              Positioned(
                                  top: 8,
                                  right: 8,
                                  child: _pixel(AppTheme.retroDark)),
                              Positioned(
                                  bottom: 8,
                                  left: 8,
                                  child: _pixel(AppTheme.retroDark)),
                              Positioned(
                                  bottom: 8,
                                  right: 8,
                                  child: _pixel(AppTheme.retroDark)),
                            ],
                          ),
                        ),

                        // Fixed spacing to prevent layout shift
                        const SizedBox(height: 12),

                        // Options Grid (2x2 layout)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          child: Column(
                            children: [
                              for (int i = 0; i < options.length; i += 2)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                          child: _buildOption(
                                              options[i], question)),
                                      const SizedBox(width: 16),
                                      if (i + 1 < options.length)
                                        Expanded(
                                            child: _buildOption(
                                                options[i + 1], question))
                                      else
                                        const Spacer(),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Fixed spacing to prevent layout shift
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
                                constraints:
                                    const BoxConstraints(maxWidth: 180),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                      color: AppTheme.retroDark, width: 3),
                                  boxShadow: const [
                                    BoxShadow(
                                        color: AppTheme.retroDark,
                                        offset: Offset(3, 3),
                                        blurRadius: 0)
                                  ],
                                ),
                                child: Text(
                                  bubbleText,
                                  textDirection: textDirection,
                                  textAlign: textAlign,
                                  style: AppFonts.pressStart2p(
                                    fontSize: 8,
                                    height: 1.5,
                                    color: AppTheme.retroDark,
                                    decoration: TextDecoration.none,
                                  ),
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
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  color: AppTheme.retroPrimary,
                                  border: Border.all(
                                      color: AppTheme.retroDark, width: 4),
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
}
