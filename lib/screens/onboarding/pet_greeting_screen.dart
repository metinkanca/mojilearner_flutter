import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../constants/theme.dart';
import '../../components/character_sprite.dart';
import '../../providers/user_provider.dart';
import '../../providers/language_provider.dart';
import '../../services/ai_service.dart';
import '../../utils/offline_detector.dart';
import '../../utils/rtl_locale.dart';
import '../../../utils/fonts.dart';

class PetGreetingScreen extends StatefulWidget {
  const PetGreetingScreen({super.key});

  @override
  State<PetGreetingScreen> createState() => _PetGreetingScreenState();
}

class _PetGreetingScreenState extends State<PetGreetingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _bounceAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getGreeting(String languageCode, String username) {
    final greetings = {
      'en': 'Hi $username! I\'m Moji!',
      'es': '¡Hola $username! ¡Soy Moji!',
      'fr': 'Salut $username! Je suis Moji!',
      'de': 'Hallo $username! Ich bin Moji!',
      'it': 'Ciao $username! Sono Moji!',
      'pt': 'Olá $username! Sou Moji!',
      'ru': 'Привет $username! Я Моджи!',
      'ja': 'こんにちは$username！モジです！',
      'zh': '你好$username！我是Moji！',
      'ko': '안녕$username! 나는 Moji야!',
      'ar': 'مرحبا $username! أنا موجي!',
      'hi': 'नमस्ते $username! मैं मोजी हूं!',
      'tr': 'Merhaba $username! Ben Moji!',
      'nl': 'Hoi $username! Ik ben Moji!',
      'sv': 'Hej $username! Jag är Moji!',
      'pl': 'Cześć $username! Jestem Moji!',
      'vi': 'Xin chào $username! Tôi là Moji!',
      'th': 'สวัสดี $username! ฉันคือโมจิ!',
      'el': 'Γεια $username! Είμαι ο Moji!',
      'da': 'Hej $username! Jeg er Moji!',
      'fi': 'Hei $username! Olen Moji!',
      'no': 'Hei $username! Jeg er Moji!',
      'cs': 'Ahoj $username! Jsem Moji!',
    };
    return greetings[languageCode] ?? greetings['en']!;
  }

  void _continue() {
    if (OfflineDetector.shouldUseConversationalAssessment) {
      context.go('/onboarding/conversational-assessment');
    } else {
      context.go('/onboarding/mock-conversational-assessment');
    }
  }

  void _continueMock() {
    context.go('/onboarding/mock-conversational-assessment');
  }

  @override
  Widget build(BuildContext context) {
    final username = Provider.of<UserProvider>(context).username;
    final languageCode =
        Provider.of<LanguageProvider>(context).targetLanguage?.code ?? 'en';
    final locale = Localizations.localeOf(context);
    final textDirection = textDirectionForLocale(locale);
    final greeting = _getGreeting(languageCode, username);
    final isOffline = OfflineDetector.isOfflineMode;
    final useConversational = OfflineDetector.shouldUseConversationalAssessment;
    final isAiAvailable = AiService.instance.isAiAvailable;
    final showLocalFallbackIndicator = useConversational && !isAiAvailable;

    return Scaffold(
      backgroundColor: AppTheme.retroSky,
      body: SafeArea(
        child: Column(
          children: [
            // Offline mode indicator
            if (isOffline)
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
            if (showLocalFallbackIndicator)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                color: const Color(0xFFFFC107),
                child: Text(
                  'ONLINE MODE - LOCAL SAFE FALLBACK',
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
                    '5/8',
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
                        widthFactor: 5 / 8,
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

            const Spacer(),

            // Animated pet character
            ScaleTransition(
              scale: _bounceAnimation,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  border: Border.all(color: AppTheme.retroDark, width: 4),
                  boxShadow: const [
                    BoxShadow(
                      color: AppTheme.retroDark,
                      offset: Offset(8, 8),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: const Center(
                  child: CharacterSprite(
                    width: 120,
                    height: 120,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Speech bubble
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
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
                  greeting,
                  textDirection: textDirection,
                  textAlign: TextAlign.center,
                  style: AppFonts.pressStart2p(
                    fontSize: 12,
                    color: AppTheme.retroDark,
                    height: 1.5,
                  ),
                ),
              ),
            ),

            const Spacer(),

            // Continue button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  // Show mock button only if NOT offline (offline auto-uses mock)
                  if (!isOffline) ...[
                    GestureDetector(
                      onTap: _continueMock,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFC107),
                          border:
                              Border.all(color: AppTheme.retroDark, width: 3),
                          boxShadow: const [
                            BoxShadow(
                              color: AppTheme.retroDark,
                              offset: Offset(3, 3),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: Text(
                          'MOCK MODE (NO API)',
                          textDirection: textDirection,
                          textAlign: TextAlign.center,
                          style: AppFonts.pressStart2p(
                            fontSize: 10,
                            color: AppTheme.retroDark,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Main continue button
                  GestureDetector(
                    onTap: _continue,
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
                        isOffline
                            ? 'START ASSESSMENT (MOCK)'
                            : (showLocalFallbackIndicator
                                ? 'START ASSESSMENT (LOCAL)'
                                : 'NICE TO MEET YOU!'),
                        textDirection: textDirection,
                        textAlign: TextAlign.center,
                        style: AppFonts.pressStart2p(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
