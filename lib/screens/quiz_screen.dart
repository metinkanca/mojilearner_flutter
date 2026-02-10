import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../constants/theme.dart';
import '../providers/user_provider.dart';
import '../providers/quiz_provider.dart';
import '../providers/character_provider.dart';

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

  List<Map<String, dynamic>> get _questions => _stockQuestions;

  @override
  void initState() {
    super.initState();
    // Check for saved progress
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final quizProvider = Provider.of<QuizProvider>(context, listen: false);
      if (quizProvider.hasSavedProgress) {
        setState(() {
          _currentQuestionIndex = quizProvider.savedQuestionIndex ?? 0;
          _score = quizProvider.savedScore ?? 0;
        });
        // Clear saved progress once loaded so we don't reload it if they finish properly
        quizProvider.clearProgress(); 
      }
    });
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

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      
      if (_currentQuestionIndex < _questions.length - 1) {
        setState(() {
          _currentQuestionIndex++;
          _showExplanation = false;
          _selectedAnswer = null;
        });
      } else {
        // Quiz Finished
        final quizProvider = Provider.of<QuizProvider>(context, listen: false);
        final characterProvider = Provider.of<CharacterProvider>(context, listen: false);
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        
        final passed = _score >= (_questions.length * 0.6); // 60% pass rate
        characterProvider.rewardQuiz(passed);
        
        // Award XP
        if (passed) {
          userProvider.addXp(25); // 25 XP for passing quiz
        } else {
          userProvider.addXp(10); // 10 XP for attempting quiz
        }
        
        quizProvider.clearProgress();
        context.go('/result', extra: {
           'score': _score, 
           'totalQuestions': _questions.length,
           'level': 'A1' // Dynamic later
        }); 
      }
    });
  }

  Widget _pixel(Color color) {
    return Container(width: 8, height: 8, color: color);
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    
    // Safety check just in case
    if (_questions.isEmpty) return const SizedBox.shrink();

    final questionData = _questions[_currentQuestionIndex];
    final mainTopic = questionData['topic'] ?? '';
    final subText = questionData['question'] ?? 'Select the correct option';
    final options = (questionData['options'] as List).cast<String>();
    
    // Bubble logic
    final bubbleText = _showExplanation 
        ? (questionData['explanation'] ?? "Great job!")
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
                        Positioned(top: 8, left: 0, right: 0, child: Container(height: 16, color: AppTheme.retroGrassDark.withOpacity(0.2))),
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
                                          style: GoogleFonts.pressStart2p(fontSize: 8, color: AppTheme.retroDark)
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'XP: ${userProvider.stats.currentLevelXP}/${userProvider.stats.nextLevelXP}',
                                          style: GoogleFonts.pressStart2p(fontSize: 8, color: AppTheme.retroDark),
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
                                                "PAUSED",
                                                style: GoogleFonts.pressStart2p(
                                                  fontSize: 16,
                                                  color: AppTheme.retroDark,
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                "Continue quiz or exit?",
                                                textAlign: TextAlign.center,
                                                style: GoogleFonts.pressStart2p(
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
                                                        "PLAY",
                                                        style: GoogleFonts.pressStart2p(fontSize: 8, color: AppTheme.retroDark),
                                                      ),
                                                    ),
                                                  ),
                                                  // Pause Button
                                                  GestureDetector(
                                                    onTap: () async {
                                                      final quizProvider = Provider.of<QuizProvider>(context, listen: false);
                                                      await quizProvider.saveProgress(_currentQuestionIndex, _score);
                                                      if (context.mounted) {
                                                        Navigator.pop(context); // Close dialog
                                                        context.go('/'); // Go home
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
                                                        "PAUSE",
                                                        style: GoogleFonts.pressStart2p(fontSize: 8, color: AppTheme.retroDark),
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
                                                        "EXIT",
                                                        style: GoogleFonts.pressStart2p(fontSize: 8, color: Colors.white),
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
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.pressStart2p(
                                        fontSize: 10,
                                        height: 1.8,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      mainTopic, // e.g. "Greetings"
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.pressStart2p(
                                        fontSize: 20,
                                        height: 1.4,
                                        color: AppTheme.retroDark,
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
                                    "QUESTION ${_currentQuestionIndex + 1}/${_questions.length}",
                                    style: GoogleFonts.pressStart2p(
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
                        const Spacer(flex: 1),

                        // Options Grid
                        // Options Grid (Custom Wrap/Column to avoid ShrinkWrappingViewport issues)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                          child: Column(
                            children: [
                              for (int i = 0; i < options.length; i += 2)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
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
                        const Spacer(flex: 2),

                        // Character & Speech Bubble
                        Padding(
                          padding: const EdgeInsets.only(right: 24, bottom: 24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                               // Speech Bubble
                               Container(
                                 padding: const EdgeInsets.all(12),
                                 margin: const EdgeInsets.only(bottom: 60, right: 8), 
                                 constraints: const BoxConstraints(maxWidth: 180),
                                 decoration: BoxDecoration(
                                   color: Colors.white,
                                   border: Border.all(color: AppTheme.retroDark, width: 3),
                                   boxShadow: const [BoxShadow(color: AppTheme.retroDark, offset: Offset(3, 3), blurRadius: 0)],
                                 ),
                                 child: Text(
                                   bubbleText,
                                   style: GoogleFonts.pressStart2p(fontSize: 8, height: 1.5, color: AppTheme.retroDark),
                                 ),
                               ),
                               // Pet Avatar
                               SvgPicture.asset(
                                'assets/svgs/pet.svg',
                                width: 96,
                                height: 96,
                               ),
                            ],
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

  Widget _buildOption(String opt, Map<String, dynamic> questionData) {
    bool isSelected = _selectedAnswer == opt;
    bool isCorrect = opt == questionData['correct'];
    Color bgColor = Colors.white;
    
    if (_showExplanation) {
      if (isCorrect) bgColor = AppTheme.retroGrass;
      else if (isSelected) bgColor = Colors.grey.shade300;
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
            textAlign: TextAlign.center,
            style: GoogleFonts.pressStart2p(
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
