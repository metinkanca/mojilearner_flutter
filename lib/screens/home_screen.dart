import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:convert'; // Added
import 'dart:async';
import '../constants/theme.dart';
import '../providers/user_provider.dart';
import '../providers/daily_reward_provider.dart';
import '../providers/language_provider.dart';
import '../providers/mistakes_provider.dart'; // Added
import '../providers/settings_provider.dart';
import '../components/pet_care_panel.dart';
import '../components/carried_food.dart';
import '../utils/pet_care_status.dart';
import '../providers/character_provider.dart';
import '../providers/vocab_provider.dart';
import '../models/models.dart';
import '../components/character_sprite.dart';
import '../components/daily_rewards_dialog.dart';
import '../l10n/app_localizations.dart';
import '../services/ai_service.dart';
import '../utils/fonts.dart';
import '../utils/rtl_locale.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Chat/AI State
  String? _aiSessionId;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _lastBotMessage = "I love learning! What shall we practice today?";
  String? _lastUserMessage;
  bool _isAwaitingReply = false;
  bool _dailyRewardDialogVisible = false;
  DailyRewardInfo? _resolvedDailyReward;
  bool _didResolveDailyReward = false;
  Timer? _sleepRefreshTimer;

  @override
  void initState() {
    super.initState();
    _startSleepRefreshTimer();
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
      final dailyRewardProvider =
          Provider.of<DailyRewardProvider>(context, listen: false);
      _resolvedDailyReward = await dailyRewardProvider.checkDailyReward();
      if (mounted) {
        setState(() {});
      }
    } catch (_) {
      // Keep UI functional in tests with partial mocks.
    }
  }

  Future<void> _showDailyReward(
      DailyRewardProvider dailyRewardProvider, DailyRewardInfo rewardInfo) async {
    _dailyRewardDialogVisible = true;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DailyRewardsDialog(
        rewardInfo: rewardInfo,
        onClaim: () {
          dailyRewardProvider.claimDailyReward();
          dailyRewardProvider.clearPendingReward();
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
    _sleepRefreshTimer?.cancel();
    if (_aiSessionId != null) {
      AiService.instance.disposeSession(_aiSessionId!);
    }
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startSleepRefreshTimer() {
    _sleepRefreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  String _awakeForText(CharacterProvider characterProvider) {
    final until = characterProvider.awakeUntil;
    if (until == null) return '';

    final minutes = until.difference(DateTime.now()).inMinutes;
    if (minutes <= 0) return 'Sleepy time again';
    return 'Awake for ${minutes + 1} min';
  }

  String _reconnectDozingText() {
    final l10n = AppLocalizations.of(context);
    return l10n?.mojiSleepReconnect ??
        'Zzz... Moji is dozing while the language link reconnects. Try again soon.';
  }

  String _nightSleepText() {
    final l10n = AppLocalizations.of(context);
    return l10n?.mojiSleepNight ??
        'Shhh... Moji is sleeping. Tap Moji to wake up.';
  }

  String _wakeSuccessText() {
    final l10n = AppLocalizations.of(context);
    return l10n?.mojiWakeSuccess ??
        'Yawn... Moji is awake now. Let\'s practice!';
  }

  String _sleepHintText(bool isAiIssueSleepMode) {
    final l10n = AppLocalizations.of(context);
    if (isAiIssueSleepMode) {
      return l10n?.mojiSleepHintReconnect ??
          'MOJI IS DOZING... LANGUAGE LINK RECONNECTING';
    }
    return l10n?.mojiSleepHintNight ?? 'MOJI IS SLEEPING... TAP TO WAKE';
  }

  String _sleepBadgeText(CharacterProvider characterProvider) {
    final l10n = AppLocalizations.of(context);
    if (characterProvider.isAiIssueSleepMode) {
      return l10n?.mojiSleepReasonReconnect ??
          'Moji is dozing while the language link reconnects.';
    }
    if (characterProvider.isSleepingForNight) {
      return l10n?.mojiSleepReasonNight ?? 'Moji is sleeping. Tap to wake up.';
    }
    return _awakeForText(characterProvider);
  }

  String _currentBubbleText() {
    if (_isAwaitingReply && _lastUserMessage != null) {
      final l10n = AppLocalizations.of(context);
      final you = l10n?.youLabel ?? 'You';
      return '$you: $_lastUserMessage';
    }
    return _lastBotMessage;
  }

  void _handleCharacterTap(CharacterProvider characterProvider) {
    if (characterProvider.isAiIssueSleepMode) {
      setState(() {
        _isAwaitingReply = false;
        _lastBotMessage = _reconnectDozingText();
      });
      return;
    }

    if (characterProvider.isSleepingForNight) {
      characterProvider.wakeUp();
      setState(() {
        _isAwaitingReply = false;
        _lastBotMessage = _wakeSuccessText();
      });
      return;
    }

    characterProvider.petThePet();
  }

  Future<void> _initAI() async {
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
    final characterProvider =
        Provider.of<CharacterProvider>(context, listen: false);
    final targetLang = languageProvider.targetLanguage?.name ?? 'Spanish';

    try {
      final systemInstruction = '''
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
''';

      _aiSessionId = await AiService.instance.createSession(
        systemInstruction: systemInstruction,
        source: 'home_screen',
      );

      if (!AiService.instance.isAiAvailable) {
        characterProvider.setAiIssueSleepMode(true);
        setState(() {
          _isAwaitingReply = false;
          _lastBotMessage = _reconnectDozingText();
        });
      } else {
        characterProvider.setAiIssueSleepMode(false);
      }
    } catch (e) {
      characterProvider.setAiIssueSleepMode(true);
      setState(() {
        _isAwaitingReply = false;
        _lastBotMessage = _reconnectDozingText();
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final characterProvider =
        Provider.of<CharacterProvider>(context, listen: false);

    if (characterProvider.isSleepingForNight) {
      setState(() {
        _isAwaitingReply = false;
        _lastBotMessage = _nightSleepText();
      });
      return;
    }

    if (characterProvider.isAiIssueSleepMode) {
      setState(() {
        _isAwaitingReply = false;
        _lastBotMessage = _reconnectDozingText();
      });
      return;
    }

    _textController.clear();
    setState(() {
      _lastUserMessage = text;
      _isAwaitingReply = true;
    });

    if (_aiSessionId != null) {
      try {
        final response = await AiService.instance.sendSessionMessage(
          sessionId: _aiSessionId!,
          message: text,
          source: 'home_screen',
        );

        if (AiService.instance.isUnavailableResponse(response)) {
          characterProvider.setAiIssueSleepMode(true);
          setState(() {
            _isAwaitingReply = false;
            _lastBotMessage = _reconnectDozingText();
          });
          return;
        }

        characterProvider.setAiIssueSleepMode(false);
        characterProvider.registerInteraction();

        if (response.isNotEmpty) {
          String botText = response;

          // Mistake Parsing
          if (botText.contains('|||MISTAKE|||')) {
            final parts = botText.split('|||MISTAKE|||');
            botText = parts[0].trim();
            if (parts.length > 1) {
              try {
                final jsonStr = parts[1].trim();
                final jsonMap = json.decode(jsonStr);
                if (mounted) {
                  Provider.of<MistakesProvider>(context, listen: false)
                      .addMistake(
                          jsonMap['original'] ?? '',
                          jsonMap['correction'] ?? '',
                          jsonMap['explanation'] ?? '',
                          jsonMap['type'] ?? 'grammar');
                }
              } catch (e) {
                debugPrint("Home Parsing Error: $e");
              }
            }
          }

          setState(() {
            _isAwaitingReply = false;
            _lastBotMessage = botText;
          });
        }
      } catch (e) {
        characterProvider.setAiIssueSleepMode(true);
        setState(() {
          _isAwaitingReply = false;
          _lastBotMessage = _reconnectDozingText();
        });
      }
    }
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final settings = Provider.of<SettingsProvider>(context);
        final l10n = AppLocalizations.of(context);
        final fontFunction =
            settings.usePixelFont ? AppFonts.pressStart2p : AppFonts.spaceMono;

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
                const SizedBox(height: 16),

                // Reminders. Ticking this is what triggers the OS permission
                // prompt — it is never asked for at startup.
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => settings.setNotificationsEnabled(
                          !settings.notificationsEnabled),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: settings.notificationsEnabled
                              ? AppTheme.retroAccent
                              : Colors.white,
                          border:
                              Border.all(color: AppTheme.retroDark, width: 3),
                        ),
                        child: settings.notificationsEnabled
                            ? const Center(
                                child: Icon(Icons.check,
                                    size: 16, color: AppTheme.retroDark))
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        l10n?.notificationsEnable ?? 'Remind me about Moji',
                        style: fontFunction(
                          fontSize: 12,
                          color: AppTheme.retroDark,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                // Only shown after a refusal, so the switch never looks
                // broken without explanation.
                if (settings.notificationsDenied) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n?.notificationsBlocked ??
                        'Notifications are turned off in your device settings.',
                    style: fontFunction(
                      fontSize: 8,
                      height: 1.6,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
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
                            color: AppTheme.retroDark, offset: Offset(2, 2)),
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
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final characterProvider = Provider.of<CharacterProvider>(context);
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final textDirection = textDirectionForLocale(locale);
    final textAlign = textAlignForLocale(locale);

    final String typeHereText = l10n?.typeHere ?? 'Type here...';

    final fontFunction = settingsProvider.usePixelFont
        ? AppFonts.pressStart2p
        : AppFonts.spaceMono;

    final canChat = !characterProvider.isSleeping &&
        !characterProvider.isAiIssueSleepMode &&
        _aiSessionId != null;
    final showSleepBadge =
        characterProvider.isSleeping || characterProvider.isTemporarilyAwake;

    final dailyRewardProvider = Provider.of<DailyRewardProvider>(context);
    final rewardToShow =
        dailyRewardProvider.pendingDailyReward ?? _resolvedDailyReward;
    if (!_dailyRewardDialogVisible &&
        !userProvider.isLoading &&
        rewardToShow != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_dailyRewardDialogVisible) {
          _showDailyReward(dailyRewardProvider, rewardToShow);
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
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
                                              color: AppTheme.retroDark, width: 4),
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
                                                  '${l10n?.xp ?? 'XP'}: ${userProvider.stats.currentLevelXP}/${userProvider.stats.nextLevelXP}',
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
                                                    alignment: Alignment.centerLeft,
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
                                            color: AppTheme.retroDark, width: 4),
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
                                              AppTheme.retroDark, BlendMode.srcIn),
                                        ),
                                        onPressed: () =>
                                            _showSettingsDialog(context),
                                        // No round ink ripple inside the square
                                        // retro frame.
                                        style: const ButtonStyle(
                                          overlayColor: WidgetStatePropertyAll(
                                              Colors.transparent),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                // The prompts get a line of their own rather
                                // than competing with the level pill for one
                                // row. Both chips together always exceed a
                                // handset width, and the longest translation
                                // of a single chip comes close on its own, so
                                // sharing the row forced every label down to
                                // an ellipsis. A Wrap lets a crowded pair fall
                                // to a second line instead.
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 8,
                                  children: [
                                    // Care prompt — appears only when a stat has
                                    // actually crossed a threshold. A healthy pet
                                    // shows nothing, so this reads as the pet
                                    // asking for something rather than as a
                                    // permanent set of meters.
                                    Consumer<CharacterProvider>(
                                      builder: (context, character, _) {
                                        final concern =
                                            PetCareStatus.topConcern(
                                          hunger: character.hunger,
                                          happiness: character.happiness,
                                          health: character.health,
                                        );
                                        if (concern == null) {
                                          return const SizedBox.shrink();
                                        }

                                        final isCritical = concern.severity ==
                                            CareSeverity.critical;
                                        final label = switch (concern.stat) {
                                          CareStat.fullness =>
                                            l10n?.careNeedHungry ?? 'Moji is hungry',
                                          CareStat.happiness => l10n
                                                  ?.careNeedLonely ??
                                              'Moji is feeling low',
                                          CareStat.health =>
                                            l10n?.careNeedSick ?? 'Moji is sick',
                                        };

                                        return GestureDetector(
                                          onTap: () =>
                                              PetCarePanel.show(context),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 12),
                                            decoration: BoxDecoration(
                                              color: isCritical
                                                  ? AppTheme.retroPrimary
                                                  : AppTheme.retroOrange,
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
                                            child: Text(
                                              label,
                                              style: fontFunction(
                                                fontSize: 8,
                                                color: isCritical
                                                    ? Colors.white
                                                    : AppTheme.retroDark,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    // Review Button — only appears when the SRS
                                    // queue has something due, so it reads as a
                                    // prompt rather than permanent chrome.
                                    Consumer2<VocabProvider, LanguageProvider>(
                                      builder: (context, vocab, language, _) {
                                        final dueCount = vocab.dueCount(
                                          languageCode:
                                              language.targetLanguage?.code,
                                        );
                                        if (dueCount == 0) {
                                          return const SizedBox.shrink();
                                        }
                                        return GestureDetector(
                                          onTap: () =>
                                              context.pushNamed('review'),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 12),
                                            decoration: BoxDecoration(
                                              color: AppTheme.retroAccent,
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
                                            child: Text(
                                              l10n?.reviewDueCount(dueCount) ??
                                                  '$dueCount due',
                                              style: fontFunction(
                                                fontSize: 8,
                                                color: AppTheme.retroDark,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
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
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 24),
                                padding: const EdgeInsets.all(16),
                                constraints:
                                    const BoxConstraints(minHeight: 80),
                                decoration: BoxDecoration(
                                  color: Colors.white,
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
                                child: Center(
                                  child: Text(
                                    _currentBubbleText(),
                                    textDirection: textDirection,
                                    textAlign: textAlignForLocale(
                                      locale,
                                      ltr: TextAlign.center,
                                      rtl: TextAlign.center,
                                    ),
                                    maxLines: 4,
                                    overflow: TextOverflow.ellipsis,
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
                                if (characterProvider.isAiIssueSleepMode)
                                  Positioned(
                                    top: 4,
                                    left: 0,
                                    right: 0,
                                    child: _InfiniteTickerBar(
                                      text: _sleepBadgeText(characterProvider),
                                      textStyle: fontFunction(
                                        fontSize: 8,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.none,
                                      ),
                                      backgroundColor: AppTheme.retroPrimary,
                                      borderColor: AppTheme.retroDark,
                                      height: 30,
                                    ),
                                  )
                                else if (showSleepBadge)
                                  Positioned(
                                    top: 4,
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth:
                                            MediaQuery.of(context).size.width -
                                                72,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: characterProvider.isSleeping
                                              ? AppTheme.retroPrimary
                                              : AppTheme.retroGrass,
                                          border: Border.all(
                                              color: AppTheme.retroDark,
                                              width: 3),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: AppTheme.retroDark,
                                              offset: Offset(2, 2),
                                              blurRadius: 0,
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          _sleepBadgeText(characterProvider),
                                          textDirection: textDirection,
                                          textAlign: textAlign,
                                          maxLines: 1,
                                          softWrap: false,
                                          overflow: TextOverflow.ellipsis,
                                          style: fontFunction(
                                            fontSize: 8,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            decoration: TextDecoration.none,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                Positioned(
                                  bottom: 70, // Shadow position
                                  child: Container(
                                    width: 150, // Shadow size
                                    height: 70,
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.black.withValues(alpha: 0.22),
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                  ),
                                ),
                                const Positioned.fill(
                                  child: SizedBox.expand(),
                                ),
                                // The pet is a drop target for carried food.
                                // Hovering holds it in the `waiting` phase,
                                // which is what keeps its mouth open until the
                                // food is actually released.
                                Positioned.fill(
                                  child: DragTarget<String>(
                                    onWillAcceptWithDetails: (details) =>
                                        details.data ==
                                        characterProvider.heldFoodId,
                                    onMove: (_) =>
                                        characterProvider.setFoodHovering(true),
                                    onLeave: (_) => characterProvider
                                        .setFoodHovering(false),
                                    onAcceptWithDetails: (_) {
                                      characterProvider.feedHeldFood();
                                    },
                                    builder: (context, candidate, rejected) {
                                      return GestureDetector(
                                        behavior: HitTestBehavior.translucent,
                                        onTap: () => _handleCharacterTap(
                                            characterProvider),
                                        // Long-press opens the care panel. The
                                        // care chip only appears when something
                                        // is wrong, so this is how a curious
                                        // player checks on a healthy pet.
                                        onLongPress: () =>
                                            PetCarePanel.show(context),
                                        child: const Align(
                                          alignment: Alignment.bottomCenter,
                                          child: FractionallySizedBox(
                                            widthFactor: 0.78,
                                            heightFactor: 0.98,
                                            child: CharacterSprite(
                                              width: double.infinity,
                                              height: double.infinity,
                                              fit: BoxFit.contain,
                                              motionProfile:
                                                  CharacterMotionProfile.full,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),

                                // Sits below the pet, and renders nothing
                                // unless food has been picked up.
                                const Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 4,
                                  child: Center(child: CarriedFood()),
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
                                enabled: canChat,
                                textDirection: textDirection,
                                textAlign: textAlign,
                                style: fontFunction(
                                    fontSize: 10,
                                    color: AppTheme.retroDark,
                                    fontWeight: FontWeight.bold),
                                decoration: InputDecoration(
                                  hintText: canChat
                                      ? typeHereText.toUpperCase()
                                      : _sleepHintText(
                                          characterProvider.isAiIssueSleepMode,
                                        ),
                                  hintStyle: fontFunction(
                                      fontSize: 10,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.bold),
                                  hintTextDirection: textDirection,
                                  hintMaxLines: 1,
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                ),
                                maxLines: 1,
                                onSubmitted: (_) {
                                  if (canChat) {
                                    _sendMessage();
                                  }
                                },
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
                              onPressed: canChat ? _sendMessage : null,
                              // No round ink ripple inside the square retro
                              // frame.
                              style: const ButtonStyle(
                                overlayColor:
                                    WidgetStatePropertyAll(Colors.transparent),
                              ),
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

class _InfiniteTickerBar extends StatefulWidget {
  const _InfiniteTickerBar({
    required this.text,
    required this.textStyle,
    required this.backgroundColor,
    required this.borderColor,
    required this.height,
  });

  final String text;
  final TextStyle textStyle;
  final Color backgroundColor;
  final Color borderColor;
  final double height;

  @override
  State<_InfiniteTickerBar> createState() => _InfiniteTickerBarState();
}

class _InfiniteTickerBarState extends State<_InfiniteTickerBar>
    with SingleTickerProviderStateMixin {
  static const double _gap = 36;
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _measureTextWidth(BuildContext context) {
    final painter = TextPainter(
      text: TextSpan(text: widget.text, style: widget.textStyle),
      maxLines: 1,
      textDirection: Directionality.of(context),
    )..layout();
    return painter.width;
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final textDirection = textDirectionForLocale(locale);
    final textAlign = textAlignForLocale(locale);

    return Container(
      height: widget.height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        border: Border(
          top: BorderSide(color: widget.borderColor, width: 3),
          bottom: BorderSide(color: widget.borderColor, width: 3),
        ),
      ),
      child: ClipRect(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final textWidth = _measureTextWidth(context);
            final loopWidth = textWidth + _gap;

            return AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final x = -(_controller.value * loopWidth);

                return Stack(
                  children: [
                    Positioned(
                      left: x,
                      top: 0,
                      bottom: 0,
                      child: SizedBox(
                        width: textWidth,
                        child: Center(
                          child: Text(
                            widget.text,
                            textDirection: textDirection,
                            textAlign: textAlign,
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.visible,
                            style: widget.textStyle,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: x + loopWidth,
                      top: 0,
                      bottom: 0,
                      child: SizedBox(
                        width: textWidth,
                        child: Center(
                          child: Text(
                            widget.text,
                            textDirection: textDirection,
                            textAlign: textAlign,
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.visible,
                            style: widget.textStyle,
                          ),
                        ),
                      ),
                    ),
                    if (textWidth < constraints.maxWidth)
                      Positioned(
                        left: x + (2 * loopWidth),
                        top: 0,
                        bottom: 0,
                        child: SizedBox(
                          width: textWidth,
                          child: Center(
                            child: Text(
                              widget.text,
                              textDirection: textDirection,
                              textAlign: textAlign,
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.visible,
                              style: widget.textStyle,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            );
          },
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
