import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';
import '../constants/theme.dart';
import '../constants/shop.dart';
import '../providers/user_provider.dart';
import '../providers/character_provider.dart';
import '../providers/language_provider.dart';
import '../providers/mistakes_provider.dart';
import '../providers/settings_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  // Chat/AI State
  GenerativeModel? _model;
  ChatSession? _chatSession;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _lastBotMessage = "I love learning! What shall we practice today?";

  @override
  void initState() {
    super.initState();
    // Floating Animation
    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: 0, end: -10).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _initAI();
  }

  @override
  void dispose() {
    _floatController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initAI() async {
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
    final targetLang = languageProvider.targetLanguage?.name ?? 'Spanish';

    // Check if we have API key
    final apiKey = dotenv.env['GEMINI_API_KEY'];
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
    final characterProvider = Provider.of<CharacterProvider>(context);
    final langProvider = Provider.of<LanguageProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final texts = langProvider.getTranslations();

    final fontFunction = settingsProvider.usePixelFont
        ? GoogleFonts.pressStart2p
        : GoogleFonts.spaceMono;

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
                                        .withOpacity(0.2))),
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
                      child: CustomScrollView(
                        physics: const ClampingScrollPhysics(),
                        slivers: [
                          SliverFillRemaining(
                            hasScrollBody: false,
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
                                                          color: AppTheme
                                                              .retroDark,
                                                          width: 2),
                                                    ),
                                                    child: FractionallySizedBox(
                                                      widthFactor: userProvider.stats.progress,
                                                      alignment:
                                                          Alignment.centerLeft,
                                                      child: Container(
                                                        color:
                                                            AppTheme.retroGreen,
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
                                          onPressed: () => _showSettingsDialog(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const Spacer(),

                                // Speech Bubble
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 40),
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
                                      bottom: -16,
                                      right: 60,
                                      child: CustomPaint(
                                        size: const Size(20, 20),
                                        painter: PixelTrianglePainter(),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 20),

                                // Floating Avatar
                                AnimatedBuilder(
                                  animation: _floatAnimation,
                                  builder: (context, child) {
                                    return Transform.translate(
                                      offset: Offset(0, _floatAnimation.value),
                                      child: child,
                                    );
                                  },
                                  child: GestureDetector(
                                    onTap: () => _showFeedDialog(context),
                                    child: Column(
                                      children: [
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 8.0),
                                          child: SvgPicture.asset(
                                            'assets/svgs/pet.svg',
                                            width: 160,
                                            height: 160,
                                          ),
                                        ),
                                        // Shadow
                                        Container(
                                          width: 96,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(100),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 32),

                                // Stats (Hearts & Smile)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 60),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.8),
                                      border: Border.all(
                                          color: AppTheme.retroDark, width: 4),
                                      boxShadow: const [
                                        BoxShadow(
                                            color: AppTheme.retroDark,
                                            offset: Offset(4, 4),
                                            blurRadius: 0)
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        _buildStatRow(
                                            'assets/svgs/icon-stat-red.svg',
                                            AppTheme.retroPrimary,
                                            (100 - characterProvider.hunger) / 100), // Full bar = Not hungry
                                        const SizedBox(height: 12),
                                        _buildStatRow(
                                            'assets/svgs/icon-stat-green.svg',
                                            AppTheme.retroGrass,
                                            characterProvider.happiness / 100), // Full bar = Happy
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 32),

                        // Story & Mistakes Buttons
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 48),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildPixelButton(
                                svgPath: 'assets/svgs/icon-story.svg',
                                label: texts['story'] ?? 'Story',
                                onTap: () => context.push('/scenarios'),
                              ),
                              const SizedBox(width: 24),
                              _buildPixelButton(
                                svgPath: 'assets/svgs/icon-mistake.svg',
                                label: texts['drills'] ?? 'Drills',
                                onTap: () => context.push('/mistakes'),
                              ),
                            ],
                          ),
                        ),

                                const Spacer(),
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
                                  hintText: (texts['typeHere'] ?? "TYPE HERE...")
                                      .toUpperCase(),
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

  Widget _buildStatRow(String svgPath, Color color, double percent) {
    return Row(
      children: [
        SizedBox(
          width: 28,
          child: Center(
            child: SvgPicture.asset(svgPath, width: 14, height: 14),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 16,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              border: Border.all(color: AppTheme.retroDark, width: 2),
            ),
            child: Row(
              // Using Row for easy fraction
              children: [
                Expanded(
                  flex: (percent * 100).toInt(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      border: const Border(
                          right:
                              BorderSide(color: AppTheme.retroDark, width: 2)),
                    ),
                  ),
                ),
                Expanded(
                  flex: 100 - (percent * 100).toInt(),
                  child: const SizedBox(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  void _showFeedDialog(BuildContext context) {
    final characterProvider = Provider.of<CharacterProvider>(context, listen: false);
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    final fontFunction = settingsProvider.usePixelFont
        ? GoogleFonts.pressStart2p
        : GoogleFonts.spaceMono;

    showDialog(
      context: context,
      builder: (context) => Dialog(
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
                'FEED YOUR PET',
                style: fontFunction(
                  fontSize: 14,
                  color: AppTheme.retroDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              if (characterProvider.inventory.isEmpty) ...[
                Text(
                  'No food items!\\nBuy some from the shop.',
                  textAlign: TextAlign.center,
                  style: fontFunction(
                    fontSize: 10,
                    color: AppTheme.retroDark,
                  ),
                ),
              ] else ...[
                ...characterProvider.inventory.map((itemId) {
                  final item = shopItems.firstWhere(
                    (i) => i.id == itemId,
                    orElse: () => shopItems.first,
                  );
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: GestureDetector(
                      onTap: () {
                        characterProvider.feedPet(itemId);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Fed ${item.name}!'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.retroAccent,
                          border: Border.all(color: AppTheme.retroDark, width: 3),
                        ),
                        child: Row(
                          children: [
                            Text(
                              item.icon,
                              style: const TextStyle(fontSize: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: fontFunction(
                                      fontSize: 10,
                                      color: AppTheme.retroDark,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '❤️ +${item.happinessRestore} 🍔 -${item.hungerRestore}',
                                    style: fontFunction(
                                      fontSize: 8,
                                      color: AppTheme.retroDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ],
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.retroPrimary,
                    border: Border.all(color: AppTheme.retroDark, width: 3),
                    boxShadow: const [
                      BoxShadow(color: AppTheme.retroDark, offset: Offset(2, 2)),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildPixelButton(
      {required String svgPath,
      required String label,
      required VoidCallback onTap}) {
    final settings = Provider.of<SettingsProvider>(context);
    final fontFunction = settings.usePixelFont
        ? GoogleFonts.pressStart2p
        : GoogleFonts.spaceMono;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100, height: 100, // Fixed size from design
        decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppTheme.retroDark, width: 4),
            boxShadow: const [
              BoxShadow(
                  color: AppTheme.retroDark,
                  offset: Offset(4, 4),
                  blurRadius: 0),
            ]),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              svgPath,
              width: 40,
              height: 40,
            ),
            const SizedBox(height: 8),
            Text(
              label.toUpperCase(),
              style: fontFunction(
                fontSize: 10,
                color: AppTheme.retroDark,
                letterSpacing: 1.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
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
