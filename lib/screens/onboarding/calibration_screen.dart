import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../constants/theme.dart';
import '../../providers/language_provider.dart';
import '../../providers/user_provider.dart';

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
    final targetLang = languageProvider.targetLanguage?.name ?? 'Spanish';

    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception("API Key not found");
      }

      final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);
      final prompt = '''
        Context: Create a test for $targetLang.
        Rules: Keep questions clear. One concept per question.
        Format: JSON array of objects.
        Example: [{"question": "Translate 'Hello'", "topic": "Hello", "options": ["Hola", "Adios"], "correct": "Hola", "explanation": "..."}]
        Important: Include a short 'topic' field (max 1-2 words) which will be shown big (e.g. 'Cat?'). 'question' field should be the prompt (e.g. 'How do you say...').
      ''';

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      
      if (response.text != null) {
        String jsonText = response.text!.trim();
        if (jsonText.startsWith('```json')) {
          jsonText = jsonText.replaceAll('```json', '').replaceAll('```', '');
        } else if (jsonText.startsWith('```')) {
          jsonText = jsonText.replaceAll('```', '');
        }
        
        final List<dynamic> data = json.decode(jsonText);
        setState(() {
          _questions = data.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
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

  void _finishCalibration() {
    final percentage = _score / _questions.length;
    String level = 'A1';
    if (percentage > 0.8) level = 'B1';
    else if (percentage > 0.4) level = 'A2';

    context.goNamed('result', extra: {
      'score': _score,
      'totalQuestions': _questions.length,
      'level': level,
    });
  }

  @override
  Widget build(BuildContext context) {
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
                            Text(subText, style: GoogleFonts.pressStart2p(fontSize: 10, color: Colors.grey)),
                            const SizedBox(height: 16),
                            Text(
                              fullQuestion, 
                              textAlign: TextAlign.center,
                              style: GoogleFonts.pressStart2p(fontSize: 20, color: AppTheme.retroDark, height: 1.5),
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
                            style: GoogleFonts.pressStart2p(fontSize: 10, color: Colors.white),
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
                          if (isCorrect) bgColor = AppTheme.retroGrass;
                          else if (isSelected) bgColor = AppTheme.retroPrimary; // Wrong answer color could be red but primary is redish
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
                                style: GoogleFonts.pressStart2p(
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
                      child: Text("You got this!", style: GoogleFonts.pressStart2p(fontSize: 8, color: AppTheme.retroDark)),
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
                 SvgPicture.asset(
                   'assets/svgs/pet.svg',
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