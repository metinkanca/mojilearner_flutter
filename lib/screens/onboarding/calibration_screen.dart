import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../constants/theme.dart';
import '../../components/character_sprite.dart';
import '../../components/quiz_rewards_popup.dart';
import '../../providers/character_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/level_validator.dart';
import '../../utils/progression_utils.dart';
import '../../utils/quiz_response_parser.dart';
import '../../utils/rtl_locale.dart';
import '../../services/ai_guard.dart';
import '../../services/ai_prompt_spec.dart';
import '../../services/ai_service.dart';
import '../../../utils/fonts.dart';

class CalibrationScreen extends StatefulWidget {
  const CalibrationScreen({super.key});

  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _questions = [];
  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _showExplanation = false;
  String? _selectedAnswer;

  @override
  void initState() {
    super.initState();
    _startCalibration();
  }

  Future<void> _startCalibration() async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);

    try {
      final guard = AiGuard.checkRequest(
        kind: AiRequestKind.quiz,
        source: 'calibration_screen',
      );
      if (!guard.allowed) {
        setState(() => _isLoading = false);
        return;
      }
      AiGuard.recordRequest('calibration_screen');

      // The same quiz prompt the main quiz asks for. What this screen sent
      // before was four indented lines with no question count, no level, no
      // option count and no "JSON only" rule — it relied on an example to
      // imply the shape and on the model to guess the rest. Onboarding has no
      // review history yet, so no review data goes with it.
      final aiText = await AiService.instance.generateText(
        spec: AiPromptSpec.quiz(
          targetCode: languageProvider.targetLanguage?.code,
          nativeCode: languageProvider.nativeLanguage.code,
          level: LevelValidator.beginner,
        ),
        source: 'calibration_screen',
        // Structured JSON: no thinking, low randomness.
        config: AiGenerationConfig.structuredJson,
      );

      if (aiText.isNotEmpty) {
        // Validated parse: exactly four distinct options, the correct answer
        // present among them, fields capped and markers escaped.
        final parsed = QuizResponseParser.parseAsMaps(aiText);
        if (parsed.isNotEmpty) {
          setState(() {
            _questions = parsed;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error generating quiz: $e');
      setState(() {
        _questions = [
          {
            "question": "Comment dit-on...",
            "topic": "Cat?", 
            "options": ["Chien", "Chat", "Oiseau", "Lapin"],
            "correct": "Chat",
            "explanation": "Chat means Cat."
          },
          {
            "question": "Comment dit-on...",
            "topic": "Dog?",
            "options": ["Chien", "Chat", "Cheval", "Souris"],
            "correct": "Chien",
            "explanation": "Chien means Dog."
          }
        ];
        _isLoading = false;
      });
    }
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

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      
      if (_currentQuestionIndex < _questions.length - 1) {
        setState(() {
          _currentQuestionIndex++;
          _showExplanation = false;
          _selectedAnswer = null;
        });
      } else {
        _finishCalibration();
      }
    });
  }

  Future<void> _finishCalibration() async {
    final characterProvider = Provider.of<CharacterProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

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
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final textDirection = textDirectionForLocale(locale);

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.retroSky,
        body: Center(child: CircularProgressIndicator(color: AppTheme.retroDark)),
      );
    }

    final userProvider = Provider.of<UserProvider>(context);
    final questionData = _questions[_currentQuestionIndex];
    final questionText = questionData['question'] ?? 'Translate';
    final mainTopic = questionData['topic'] ?? ''; 
    final fullQuestion = mainTopic.isNotEmpty ? mainTopic : questionText;
    final subText = mainTopic.isNotEmpty ? questionText : "Select the correct option";
    final options = (questionData['options'] as List).cast<String>();

    return Scaffold(
      backgroundColor: Colors.transparent, 
      body: Stack(
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
                                  style: AppFonts.pressStart2p(fontSize: 8, color: AppTheme.retroDark)
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'XP: ${userProvider.stats.currentLevelXP}/${userProvider.stats.nextLevelXP}',
                                  textDirection: TextDirection.ltr,
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
                          // No round ink ripple inside the square retro frame.
                          style: const ButtonStyle(
                            overlayColor:
                                WidgetStatePropertyAll(Colors.transparent),
                          ),
                          icon: const Icon(Icons.pause, color: AppTheme.retroDark),
                          onPressed: () => context.go('/'),
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
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 16),
                            Text(
                              subText,
                              textDirection: textDirection,
                              textAlign: TextAlign.center,
                              style: AppFonts.pressStart2p(fontSize: 10, color: Colors.grey),
                            ),

                            const SizedBox(height: 16),
                            Text(
                              fullQuestion,
                              textDirection: textDirection,
                              textAlign: TextAlign.center,
                              style: AppFonts.pressStart2p(fontSize: 20, color: AppTheme.retroDark, height: 1.5),
                            ),
                          ],
                        ),
                      ),
                      // Floating Label
                      Positioned(
                        top: -16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.retroPrimary,
                            border: Border.all(color: AppTheme.retroDark, width: 4),
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
                      // Corner bits
                      Positioned(top: 8, left: 8, child: _pixel(AppTheme.retroDark)),
                      Positioned(top: 8, right: 8, child: _pixel(AppTheme.retroDark)),
                      Positioned(bottom: 8, left: 8, child: _pixel(AppTheme.retroDark)),
                      Positioned(bottom: 8, right: 8, child: _pixel(AppTheme.retroDark)),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Answers Grid
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.5,
                      children: options.map((opt) {
                        final isSelected = _selectedAnswer == opt;
                        final isCorrect = opt == questionData['correct'];
                        
                        Color bgColor = Colors.white;
                        if (_showExplanation) {
                          if (isCorrect) {
                            bgColor = AppTheme.retroGrass;
                          } else if (isSelected) {
                            // Wrong answer colour could be red, but primary is
                            // already reddish.
                            bgColor = AppTheme.retroPrimary;
                          }
                        }
                        
                        return GestureDetector(
                          onTap: () => _handleAnswer(opt),
                          child: Container(
                            decoration: BoxDecoration(
                              color: bgColor,
                              border: Border.all(color: AppTheme.retroDark, width: 4),
                              boxShadow: const [BoxShadow(color: AppTheme.retroDark, offset: Offset(4, 4), blurRadius: 0)],
                            ),
                            child: Center(
                              child: Text(
                                opt,
                                textDirection: textDirection,
                                style: AppFonts.pressStart2p(
                                  fontSize: 10,
                                  color: AppTheme.retroDark
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                
                const SizedBox(height: 100),
              ],
            ),
          ),

          // 3. Floating Character
          Positioned(
            bottom: 120, 
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Speech Bubble
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppTheme.retroDark, width: 2),
                        boxShadow: const [BoxShadow(color: AppTheme.retroDark, offset: Offset(2, 2), blurRadius: 0)],
                      ),
                      child: Text("You got this!", style: AppFonts.pressStart2p(fontSize: 8, color: AppTheme.retroDark)),
                    ),
                     Positioned(
                      bottom: -6, 
                      right: 16,
                      child: CustomPaint(
                        size: const Size(10, 6),
                        painter: PixelTrianglePainter(), 
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                 const CharacterSprite(
                   width: 100,
                   height: 100,
                 ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pixel(Color color) {
    return Container(width: 8, height: 8, color: color);
  }
}

class PixelTrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppTheme.retroDark..style = PaintingStyle.fill;
    final whitePaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    
    var path = Path();
    path.moveTo(0, 0);       
    path.lineTo(size.width, 0); 
    path.lineTo(size.width / 2, size.height); 
    path.close();
    canvas.drawPath(path, paint);

    var innerPath = Path();
    innerPath.moveTo(2, 0);
    innerPath.lineTo(size.width - 2, 0);
    innerPath.lineTo(size.width / 2, size.height - 3);
    innerPath.close();
    canvas.drawPath(innerPath, whitePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}