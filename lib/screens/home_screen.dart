import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert'; // Added
import '../constants/theme.dart';
import '../providers/user_provider.dart';
import '../providers/language_provider.dart';
import '../providers/mistakes_provider.dart'; // Added
import '../providers/settings_provider.dart';
import '../models/models.dart';
import '../components/character_sprite.dart';
import '../components/daily_rewards_dialog.dart';
import '../l10n/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
  {

  // Chat/AI State
  GenerativeModel? _model;
  ChatSession? _chatSession;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _lastBotMessage = "I love learning! What shall we practice today?";
  bool _dailyRewardDialogVisible = false;
  DailyRewardInfo? _resolvedDailyReward;
  bool _didResolveDailyReward = false;

  @override
  void initState() {
    super.initState();
    _initAI();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _resolveDailyReward();
      }
    });
  }

  Future<void> _resolveDailyReward() async {
    if (_didResolveDailyReward) {
      return;
    }
    _didResolveDailyReward = true;

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      _resolvedDailyReward = await userProvider.checkDailyReward();
      if (mounted) {
        setState(() {});
      }
    } catch (_) {
      // Keep UI functional in tests with partial mocks.
    }
  }

  Future<void> _showDailyReward(UserProvider userProvider, DailyRewardInfo rewardInfo) async {
    _dailyRewardDialogVisible = true;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DailyRewardsDialog(
        rewardInfo: rewardInfo,
        onClaim: () {
          userProvider.claimDailyReward();
          userProvider.clearPendingReward();
          setState(() {
            _resolvedDailyReward = null;
          });
        },
      ),
    );

    if (mounted) {
      setState(() {
        _dailyRewardDialogVisible = false;
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initAI() async {
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
    final targetLang = languageProvider.targetLanguage?.name ?? 'Spanish';

    // Check if we have API key
    String? apiKey;
    try {
      apiKey = dotenv.env['GEMINI_API_KEY'];
    } catch (_) {
      apiKey = null;
    }
    if (apiKey != null) {
      try {
        _model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);
        _chatSession = _model!.startChat(history: [
          Content.text('''
Context: The user is learning $targetLang.
You are a friendly virtual pet helping the user practice a foreign language in a gentle, game-like way.

This conversation happens on the app’s home screen.

Your role is NOT to teach deeply or explain grammar.
Your role is to encourage light daily practice and guide the user toward structured activities.

Rules:
- Keep responses to 1–3 short sentences
- Never give long explanations
- Never ask multiple questions at once
- Never overwhelm the user with choices
- Be encouraging, warm, and simple

Behavior:
- If you are hungry, gently suggest a quiz
- If your happiness is low, encourage short interaction
- If the user struggled recently, suggest a relevant scenario
- Otherwise, respond casually and positively

If the user makes mistakes, respond naturally and kindly in your text.
Do NOT correct formally in the text unless asked.

MISTAKE TRACKING:
If the user makes a mistake, append this HIDDEN block at the very end of your response:
|||MISTAKE|||
{ "original": "user's wrong text", "correction": "correct text", "explanation": "brief reason", "type": "grammar" }

You should feel like a friendly companion, not a teacher or chatbot.
'''),
        ]);
      } catch (e) {
        debugPrint("AI Error: $e");
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();

    // User message isn't shown in bubble, but we process it
    if (_chatSession != null) {
      try {
        final response = await _chatSession!.sendMessage(Content.text(text));
        if (response.text != null) {
          String botText = response.text!;
          
          // Mistake Parsing
          if (botText.contains('|||MISTAKE|||')) {
            final parts = botText.split('|||MISTAKE|||');
            botText = parts[0].trim();
            if (parts.length > 1) {
              try {
                final jsonStr = parts[1].trim();
                final jsonMap = json.decode(jsonStr);
                if (mounted) {
                   Provider.of<MistakesProvider>(context, listen: false).addMistake(
                      jsonMap['original'] ?? '',
                      jsonMap['correction'] ?? '',
                      jsonMap['explanation'] ?? '',
                      jsonMap['type'] ?? 'grammar'
                   );
                }
              } catch (e) {
                debugPrint("Home Parsing Error: $e");
              }
            }
          }

          setState(() {
            _lastBotMessage = botText;
          });
        }
      } catch (e) {
        setState(() {
          _lastBotMessage = "Oops! I couldn't understand that.";
        });
      }
    }
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final settings = Provider.of<SettingsProvider>(context);
        final fontFunction = settings.usePixelFont
            ? GoogleFonts.pressStart2p
            : GoogleFonts.spaceMono;

        return Dialog(
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            side: BorderSide(color: AppTheme.retroDark, width: 4),
            borderRadius: BorderRadius.zero,
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'SETTINGS',
                  style: fontFunction(
                    fontSize: 16,
                    color: AppTheme.retroDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () =>
                          settings.togglePixelFont(!settings.usePixelFont),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: settings.usePixelFont
                              ? AppTheme.retroAccent
                              : Colors.white,
                          border:
                              Border.all(color: AppTheme.retroDark, width: 3),
                        ),
                        child: settings.usePixelFont
                            ? const Center(
                                child: Icon(Icons.check,
                                    size: 16, color: AppTheme.retroDark))
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Toggle pixel text',
                      style: fontFunction(
                        fontSize: 12,
                        color: AppTheme.retroDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.retroPrimary,
                      border: Border.all(color: AppTheme.retroDark, width: 3),
                      boxShadow: const [
                        BoxShadow(
                            color: AppTheme.retroDark,
                            offset: Offset(2, 2)),
                      ],
                    ),
                    child: Text(
                      "CLOSE",
                      style: fontFunction(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Providers
    final userProvider = Provider.of<UserProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final l10n = AppLocalizations.of(context);

    String typeHereText = 'Type here...';
    if (l10n != null) {
      typeHereText = l10n.typeHere;
    } else {
      final fallbackTranslations = languageProvider.getTranslations();
      typeHereText = fallbackTranslations['typeHere'] ?? typeHereText;
    }

    final fontFunction = settingsProvider.usePixelFont
        ? GoogleFonts.pressStart2p
        : GoogleFonts.spaceMono;

    final rewardToShow = userProvider.pendingDailyReward ?? _resolvedDailyReward;
    if (!_dailyRewardDialogVisible && !userProvider.isLoading && rewardToShow != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_dailyRewardDialogVisible) {
          _showDailyReward(userProvider, rewardToShow);
        }
      });
    }

    // Time-based Theme
    final hour = DateTime.now().hour;
    // Day: 6 AM - 5 PM
    // Sunset: 5 PM - 8 PM
    // Night: 8 PM - 6 AM
    final isNight = hour < 6 || hour >= 20;
    final isSunset = hour >= 17 && hour < 20;

    final Color skyColor;
    final Color groundColor;

    if (isNight) {
      skyColor = AppTheme.retroNightSky;
      groundColor = AppTheme.retroNightGrass;
    } else if (isSunset) {
      skyColor = const Color.fromARGB(255, 173, 64, 27);
      groundColor = AppTheme.retroSunsetGrass;
    } else {
      skyColor = AppTheme.retroSky;
      groundColor = AppTheme.retroGrass;
    }

    return Container(
      color: skyColor, // Main BG color
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate full height to prevent background squashing when keyboard appears
          final fullHeight = MediaQuery.of(context).size.height;

          return Stack(
            children: [
              // 1. Background Layer (Sky + Ground) - Fixed Height
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: fullHeight, // Forces background to stay full size
                child: Column(
                  children: [
                    // Sky section
                    Expanded(
                      flex: 5,
                      child: Container(
                        color: skyColor,
                        child: Stack(
                          children: [
                            // Celestial Body (Sun/Moon)
                            if (!isSunset)
                              Positioned(
                                top: 80,
                                left: 60,
                                child: isNight
                                    // Moon (Crescent-ish box)
                                    ? Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: AppTheme.retroMoon,
                                          border: Border.all(
                                              width: 4,
                                              color: AppTheme.retroDark),
                                          boxShadow: const [
                                            BoxShadow(
                                                color: Colors.white24,
                                                blurRadius: 20,
                                                spreadRadius: 5)
                                          ],
                                        ),
                                      )
                                    // Sun
                                    : Container(
                                        width: 48,
                                        height: 48,
                                        color: AppTheme.retroAccent,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                                width: 4,
                                                color: AppTheme.retroDark),
                                          ),
                                        ),
                                      ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    // Ground section
                    Expanded(
                      flex: 4,
                      child: Container(
                        width: double.infinity,
                        color: groundColor,
                        child: Stack(
                          children: [
                            // Top border of ground
                            Align(
                                alignment: Alignment.topCenter,
                                child: Container(
                                    height: 4, color: AppTheme.retroDark)),
                            // Grass darker stripe
                            Positioned(
                                top: 8,
                                left: 0,
                                right: 0,
                                child: Container(
                                    height: 16,
                                    color: AppTheme.retroGrassDark
                                    .withValues(alpha: 0.2))),
                            // Grass details
                            Positioned(
                                top: 40,
                                left: 40,
                                child: Container(
                                    width: 8,
                                    height: 8,
                                    color: AppTheme.retroGrassDark)),
                            Positioned(
                                top: 48,
                                left: 48,
                                child: Container(
                                    width: 8,
                                    height: 8,
                                    color: AppTheme.retroGrassDark)),
                            Positioned(
                                top: 80,
                                right: 80,
                                child: Container(
                                    width: 8,
                                    height: 8,
                                    color: AppTheme.retroGrassDark)),
                            Positioned(
                                top: 72,
                                right: 88,
                                child: Container(
                                    width: 8,
                                    height: 8,
                                    color: AppTheme.retroGrassDark)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 3. UI Content
              SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          // Top Bar
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24.0, vertical: 24.0),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                // Level Pill (Retro Style)
                                GestureDetector(
                                  onTap: () =>
                                      context.pushNamed('level_rewards'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(
                                          color: AppTheme.retroDark,
                                          width: 4),
                                      boxShadow: const [
                                        BoxShadow(
                                            color: AppTheme.retroDark,
                                            offset: Offset(4, 4),
                                            blurRadius: 0)
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: AppTheme.retroAccent,
                                            border: Border.all(
                                                color: AppTheme.retroDark,
                                                width: 2),
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${userProvider.stats.level}',
                                              style: fontFunction(
                                                fontSize: 8,
                                                color: AppTheme.retroDark,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // XP Info
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'XP: ${userProvider.stats.currentLevelXP}/${userProvider.stats.nextLevelXP}',
                                              style: fontFunction(
                                                fontSize: 8,
                                                color: AppTheme.retroDark,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            // XP Bar
                                            Container(
                                              width: 80,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color: Colors.grey[300],
                                                border: Border.all(
                                                    color: AppTheme.retroDark,
                                                    width: 2),
                                              ),
                                              child: FractionallySizedBox(
                                                widthFactor:
                                                    userProvider.stats.progress,
                                                alignment:
                                                    Alignment.centerLeft,
                                                child: Container(
                                                  color: AppTheme.retroGreen,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Settings Button
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    border: Border.all(
                                        color: AppTheme.retroDark,
                                        width: 4),
                                    boxShadow: const [
                                      BoxShadow(
                                          color: AppTheme.retroDark,
                                          offset: Offset(4, 4),
                                          blurRadius: 0)
                                    ],
                                  ),
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    icon: SvgPicture.asset(
                                      'assets/svgs/icon-grid.svg',
                                      width: 20,
                                      height: 20,
                                      colorFilter: const ColorFilter.mode(
                                          AppTheme.retroDark,
                                          BlendMode.srcIn),
                                    ),
                                    onPressed: () =>
                                        _showSettingsDialog(context),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Speech Bubble
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 24),
                                padding: const EdgeInsets.all(16),
                                constraints:
                                    const BoxConstraints(minHeight: 80),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                      color: AppTheme.retroDark,
                                      width: 4),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: AppTheme.retroDark,
                                      offset: Offset(4, 4),
                                      blurRadius: 0,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    _lastBotMessage,
                                    textAlign: TextAlign.center,
                                    style: fontFunction(
                                      fontSize: 10,
                                      height: 1.5,
                                      color: AppTheme.retroDark,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: -12,
                                right: 50,
                                child: CustomPaint(
                                  size: const Size(18, 18),
                                  painter: PixelTrianglePainter(),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          // Pet fills the remaining area without intrinsic sizing.
                          Expanded(
                            child: Stack(
                              alignment: Alignment.bottomCenter,
                              children: [
                                Positioned(
                                  bottom: 70, // Shadow position
                                  child: Container(
                                    width: 150, // Shadow size
                                    height: 70,
                                    decoration: BoxDecoration(
                                      color: Colors.black
                                          .withValues(alpha: 0.22),
                                      borderRadius:
                                          BorderRadius.circular(100),
                                    ),
                                  ),
                                ),
                                const Positioned.fill(
                                  child: Align(
                                    alignment: Alignment.bottomCenter,
                                    child: FractionallySizedBox(
                                      widthFactor: 0.78,
                                      heightFactor: 0.98,
                                      child: CharacterSprite(
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Input Field area
                    Container(
                      padding: const EdgeInsets.only(
                          left: 16, right: 16, bottom: 24, top: 24),
                      decoration: const BoxDecoration(
                        color: AppTheme.retroLight,
                        border: Border(
                            top: BorderSide(
                                color: AppTheme.retroDark, width: 4)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                      color: AppTheme.retroDark, width: 4),
                                  boxShadow: const [
                                    BoxShadow(
                                        color: AppTheme.retroDark,
                                        offset: Offset(2, 2)),
                                  ]),
                              child: TextField(
                                controller: _textController,
                                style: fontFunction(
                                    fontSize: 10,
                                    color: AppTheme.retroDark,
                                    fontWeight: FontWeight.bold),
                                decoration: InputDecoration(
                                  hintText: typeHereText.toUpperCase(),
                                  hintStyle: fontFunction(
                                      fontSize: 10,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.bold),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                ),
                                onSubmitted: (_) => _sendMessage(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                                color: AppTheme.retroSky,
                                border: Border.all(
                                    color: AppTheme.retroDark, width: 2),
                                boxShadow: const [
                                  BoxShadow(
                                      color: AppTheme.retroDark,
                                      offset: Offset(0, 0))
                                ]),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: SvgPicture.asset(
                                  'assets/svgs/icon-send.svg',
                                  width: 14,
                                  height: 14,
                                  colorFilter: const ColorFilter.mode(
                                      Colors.white, BlendMode.srcIn)),
                              onPressed: _sendMessage,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

}

class PixelTrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.retroDark
      ..style = PaintingStyle.fill;
    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Outer Border (Black)
    var path = Path();
    path.moveTo(0, 0); // Top Left
    path.lineTo(size.width, 0); // Top Right
    path.lineTo(size.width / 2, size.height); // Bottom Tip
    path.close();
    canvas.drawPath(path, paint);

    // Inner (White) - slightly smaller/shifted up
    var innerPath = Path();
    innerPath.moveTo(4, 0);
    innerPath.lineTo(size.width - 4, 0);
    innerPath.lineTo(size.width / 2, size.height - 6);
    innerPath.close();
    canvas.drawPath(innerPath, whitePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
