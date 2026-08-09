import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../constants/theme.dart';
import '../../components/character_sprite.dart';
import '../../providers/calibration_provider.dart';
import '../../providers/language_provider.dart';
import '../../models/models.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/rtl_locale.dart';
import '../../../utils/fonts.dart';

class MockConversationalAssessmentScreen extends StatefulWidget {
  const MockConversationalAssessmentScreen({super.key});

  @override
  State<MockConversationalAssessmentScreen> createState() =>
      _MockConversationalAssessmentScreenState();
}

class _MockConversationalAssessmentScreenState
    extends State<MockConversationalAssessmentScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatAssessmentMessage> _messages = [];
  bool _isLoading = false;
  bool _assessmentComplete = false;
  bool _showContinueButton = false;
  int _questionCount = 0;
  String _selfAssessedLevel = 'beginner';

  // Mock responses based on question count
  final Map<int, List<String>> _mockResponses = {
    1: [
      'Merhaba! Nasılsın?',
      '¡Hola! ¿Cómo estás?',
      'Bonjour! Comment ça va?',
      'Hallo! Wie geht\'s?',
    ],
    2: [
      'Hoşgeldin! Ne yapmayı seversin?',
      '¿Qué te gusta hacer?',
      'Qu\'est-ce que tu aimes faire?',
      'Was machst du gerne?',
    ],
    3: [
      'Harika! Hangi renkleri seversin?',
      '¡Genial! ¿Qué colores te gustan?',
      'Super! Quelles couleurs aimes-tu?',
      'Toll! Welche Farben magst du?',
    ],
    4: [
      'Çok iyi! Bugün hava nasıl?',
      '¡Muy bien! ¿Cómo está el tiempo hoy?',
      'Très bien! Quel temps fait-il aujourd\'hui?',
      'Sehr gut! Wie ist das Wetter heute?',
    ],
    5: [
      'Teşekkürler! Bu çok yardımcı oldu.',
      '¡Gracias! Esto fue muy útil.',
      'Merci! C\'était très utile.',
      'Danke! Das war sehr hilfreich.',
    ],
  };

  @override
  void initState() {
    super.initState();
    _initializeMockChat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeMockChat() {
    final languageCode = Provider.of<LanguageProvider>(context, listen: false)
        .targetLanguage
        ?.code ??
        'en';

    final proficiency = Provider.of<CalibrationProvider>(context, listen: false)
        .getLanguageProficiency(languageCode);
    _selfAssessedLevel = proficiency?.selfAssessedLevel ?? 'beginner';

    // Add initial mock message
    _addMessage(
      ChatAssessmentMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: _mockResponses[1]![0],
        sender: 'ai',
        timestamp: DateTime.now(),
      ),
    );
  }

  void _addMessage(ChatAssessmentMessage message) {
    setState(() {
      _messages.add(message);
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading || _assessmentComplete) return;

    // Add user message
    final userMessage = ChatAssessmentMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: text,
      sender: 'user',
      timestamp: DateTime.now(),
    );
    _addMessage(userMessage);
    _controller.clear();

    setState(() {
      _isLoading = true;
      _questionCount++;
    });

    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Get mock AI response
    final responses = _mockResponses[_questionCount + 1] ?? _mockResponses[5]!;
    final mockResponse = responses[0];

    final aiMessage = ChatAssessmentMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: mockResponse,
      sender: 'ai',
      timestamp: DateTime.now(),
    );
    _addMessage(aiMessage);

    // Check if we should end assessment (after 5 Q&A pairs = 11 messages total)
    // This ensures we stop after the 5th AI response (6th AI message including initial greeting)
    if (_messages.length >= 11) {
      setState(() {
        _showContinueButton = true;
        _assessmentComplete = true;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _completeAssessment() async {
    // Mock: determine level based on self-assessment with slight variation
    String determinedLevel = _selfAssessedLevel;
    
    // Simulate AI "adjustment" - randomly keep same or adjust by one level
    final mockVariation = _questionCount % 3;
    if (mockVariation == 0 && _selfAssessedLevel == 'beginner') {
      determinedLevel = 'intermediate';
    } else if (mockVariation == 1 && _selfAssessedLevel == 'advanced') {
      determinedLevel = 'intermediate';
    }

    // Save mock assessment results
    final languageCode = Provider.of<LanguageProvider>(context, listen: false)
        .targetLanguage?.code ?? 'en';
    
    final calibrationProvider =
        Provider.of<CalibrationProvider>(context, listen: false);
    final existingProf =
        calibrationProvider.getLanguageProficiency(languageCode) ??
        LanguageProficiency(
          languageCode: languageCode,
          selfAssessedLevel: _selfAssessedLevel,
        );
    
    // Update with mock AI-determined level
    await calibrationProvider.saveLanguageProficiency(
      existingProf.copyWith(
        aiDeterminedLevel: determinedLevel,
        assessmentConversation: List.from(_messages),
      ),
    );

    // Navigate to quiz-intro
    if (mounted) {
      context.go('/onboarding/quiz-intro?aiLevel=$determinedLevel');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final textDirection = textDirectionForLocale(locale);
    final textAlign = textAlignForLocale(locale);
    
    return Scaffold(
      backgroundColor: AppTheme.retroSky,
      body: SafeArea(
        child: Column(
          children: [
            // Offline mode indicator
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: const Color(0xFFFFC107),
              child: Text(
                'OFFLINE MODE - USING MOCK AI',
                textDirection: textDirection,
                textAlign: TextAlign.center,
                style: AppFonts.pressStart2p(
                  fontSize: 8,
                  color: AppTheme.retroDark,
                ),
              ),
            ),
            // Progress indicator
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Text(
                    '6/8',
                    textDirection: TextDirection.ltr,
                    style: AppFonts.pressStart2p(
                      fontSize: 10,
                      color: AppTheme.retroDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppTheme.retroDark, width: 2),
                      ),
                      child: FractionallySizedBox(
                        widthFactor: 6 / 8,
                        alignment: Alignment.centerLeft,
                        child: Container(
                          color: AppTheme.retroAccent,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Header with MOCK badge
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFC107),
                      border: Border.all(color: AppTheme.retroDark, width: 2),
                    ),
                    child: Text(
                      'MOCK',
                      textDirection: textDirection,
                      textAlign: textAlign,
                      style: AppFonts.pressStart2p(
                        fontSize: 8,
                        color: AppTheme.retroDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.chatAssessment,
                    textDirection: textDirection,
                    textAlign: textAlign,
                    style: AppFonts.pressStart2p(
                      fontSize: 12,
                      color: AppTheme.retroDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Chat messages
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final isUser = message.sender == 'user';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      mainAxisAlignment: isUser
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // AI pet icon
                        if (!isUser) ...[
                          const CharacterSprite(
                            width: 40,
                            height: 40,
                          ),
                          const SizedBox(width: 8),
                        ],
                        // Message bubble with arrow
                        Flexible(
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.65,
                                ),
                                decoration: BoxDecoration(
                                  color: isUser
                                      ? AppTheme.retroPrimary
                                      : Colors.white,
                                  border: Border.all(
                                      color: AppTheme.retroDark, width: 3),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: AppTheme.retroDark,
                                      offset: Offset(3, 3),
                                      blurRadius: 0,
                                    ),
                                  ],
                                ),
                                child: Text(
                                  message.content,
                                  textDirection: textDirection,
                                  textAlign: textAlign,
                                  style: AppFonts.pressStart2p(
                                    fontSize: 8,
                                    color: isUser
                                        ? Colors.white
                                        : AppTheme.retroDark,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                              // Arrow pointer
                              Positioned(
                                bottom: 12,
                                left: isUser ? null : -12,
                                right: isUser ? -12 : null,
                                child: CustomPaint(
                                  size: const Size(16, 16),
                                  painter: PixelTrianglePainter(
                                    color: isUser
                                        ? AppTheme.retroPrimary
                                        : Colors.white,
                                    pointingRight: isUser,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Loading indicator
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  l10n.mojiIsTyping,
                  textDirection: textDirection,
                  textAlign: textAlign,
                  style: AppFonts.pressStart2p(
                    fontSize: 8,
                    color: AppTheme.retroDark.withValues(alpha: 0.7),
                  ),
                ),
              ),

            // Input field or Continue button
            if (_showContinueButton)
              // Show Continue button after chat is complete
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: GestureDetector(
                  onTap: _completeAssessment,
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
                      l10n.continueBtn,
                      textDirection: textDirection,
                      textAlign: TextAlign.center,
                      style: AppFonts.pressStart2p(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              )
            else
              // Show input field during assessment
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: AppTheme.retroDark, width: 2),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.retroSky,
                          border: Border.all(color: AppTheme.retroDark, width: 2),
                        ),
                        child: TextField(
                          controller: _controller,
                          enabled: !_assessmentComplete,
                          textDirection: textDirection,
                          textAlign: textAlign,
                          style: AppFonts.pressStart2p(
                            fontSize: 10,
                            color: AppTheme.retroDark,
                          ),
                          decoration: InputDecoration(
                            hintText: l10n.typeYourAnswer,
                            hintTextDirection: textDirection,
                            hintStyle: AppFonts.pressStart2p(
                              fontSize: 8,
                              color: AppTheme.retroDark.withValues(alpha: 0.5),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(12),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _sendMessage,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.retroPrimary,
                          border: Border.all(color: AppTheme.retroDark, width: 2),
                          boxShadow: const [
                            BoxShadow(
                              color: AppTheme.retroDark,
                              offset: Offset(2, 2),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: Text(
                          l10n.send,
                          textDirection: textDirection,
                          textAlign: TextAlign.center,
                          style: AppFonts.pressStart2p(
                            fontSize: 8,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Pixel triangle painter for chat bubble arrows
class PixelTrianglePainter extends CustomPainter {
  final Color color;
  final bool pointingRight;

  PixelTrianglePainter({
    required this.color,
    this.pointingRight = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = AppTheme.retroDark
      ..style = PaintingStyle.fill;
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    if (pointingRight) {
      // Arrow pointing right (for user messages)
      // Border triangle
      var borderPath = Path();
      borderPath.moveTo(0, 0);
      borderPath.lineTo(size.width, size.height / 2);
      borderPath.lineTo(0, size.height);
      borderPath.close();
      canvas.drawPath(borderPath, borderPaint);

      // Inner fill triangle
      var fillPath = Path();
      fillPath.moveTo(0, 3);
      fillPath.lineTo(size.width - 3, size.height / 2);
      fillPath.lineTo(0, size.height - 3);
      fillPath.close();
      canvas.drawPath(fillPath, fillPaint);
    } else {
      // Arrow pointing left (for AI messages)
      // Border triangle
      var borderPath = Path();
      borderPath.moveTo(size.width, 0);
      borderPath.lineTo(0, size.height / 2);
      borderPath.lineTo(size.width, size.height);
      borderPath.close();
      canvas.drawPath(borderPath, borderPaint);

      // Inner fill triangle
      var fillPath = Path();
      fillPath.moveTo(size.width, 3);
      fillPath.lineTo(3, size.height / 2);
      fillPath.lineTo(size.width, size.height - 3);
      fillPath.close();
      canvas.drawPath(fillPath, fillPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
