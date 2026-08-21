import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../components/pet_hearts.dart';
import '../components/sleep_zs.dart';
import '../components/bond_meter.dart';
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

  /// Scratch-to-pet gesture state. Only meaningful between a horizontal drag
  /// start and its end.
  ///
  /// The gesture is deliberately not a swipe: it is the rubbing back and forth
  /// that reads as affection, so what is tracked is direction changes, not
  /// distance. [_scratchLegTravel] measures the current leg so a reversal only
  /// counts once the finger has actually gone somewhere.
  bool _scratchOnHead = false;
  double? _scratchLastX;
  int _scratchDirection = 0;
  double _scratchLegTravel = 0;
  int _scratchReversals = 0;

  /// Whether the pet is currently saying something.
  ///
  /// The bubble used to be permanent, which meant the pet's last remark sat
  /// over the scene forever and the idle screen always had a slab of text on
  /// it. It is speech, so it behaves like speech: it appears when there is
  /// something to say and clears itself afterwards. States the player cannot
  /// act on — asleep, reconnecting, waiting on a reply — pin it open instead,
  /// because there the bubble is the only thing explaining a dead input box.
  bool _bubbleVisible = true;
  Timer? _bubbleTimer;

  /// How long a remark stays up before the pet goes quiet again.
  static const Duration _bubbleDuration = Duration(seconds: 6);

  /// Width-over-height of the assembled pet art, whose shared viewBox is
  /// "-20 -90 222 328". The sprite box is derived from this rather than from a
  /// fraction of the scene, so the art fills its box exactly and the box can be
  /// planted on the ground.
  ///
  /// Note what growing the canvas upward does and does not do: the box is
  /// bottom-anchored and its width comes from the scene, so extra headroom
  /// makes the box taller *upward* and the pet keeps its size and its footing.
  /// It does not shrink the pet.
  static const double _kPetAspect = 222 / 328;

  /// How much of the scene's width the pet takes.
  static const double _kPetWidthFactor = 0.86;

  /// Clearance between the pet's feet and the bottom of the scene, sized to
  /// clear the bond strip floating there.
  static const double _kPetFootOffset = 52;

  /// Height of the floating top bar: a 48pt level pill inside 24pt of padding
  /// either side. What the pet's voice hangs below.
  static const double _kTopBarHeight = 96;

  /// Where carried food floats, clear of the bond strip below it. It sits over
  /// the pet's paws rather than beside the pet, which is what makes dragging it
  /// up onto the pet's face read as an offer.
  static const double _kCarriedFoodOffset = 44;

  /// Where the sun/moon hangs. Clear of the speech bubble at its tallest --
  /// the bubble starts at [_kTopBarHeight] and runs to about 130pt at four
  /// lines of text.
  static const double _kCelestialTop = 240;

  /// The sleep trail, as fractions of the pet's width so it scales with the
  /// pet rather than being pinned to one screen size.
  static const double _kSleepZsSizeFactor = 0.075;

  /// Offset from the top of the sprite box, in pet widths. The box spans 222
  /// art units across, so this is `(90 + 35.5) / 222`: it parks the trail at
  /// art y ~= -35.5, just above the ears, which is where it sat before the
  /// canvas grew. Tied to the canvas, so it has to move when the canvas does.
  static const double _kSleepZsTopFactor = 0.245;

  /// Heart size, as a fraction of the pet's width, so the reward scales with
  /// the pet the same way its sleep trail does.
  static const double _kHeartSizeFactor = 0.13;

  /// The head's slice of the sprite box, as fractions of the box height from
  /// its top. The shared viewBox is "-20 -90 222 328"; the ears start at art
  /// y = 0 and the head meets the body around y = 110, which is 0.27..0.61 of
  /// the box. Opened up a little either side, because a scratch is aimed with
  /// a fingertip at a moving target and should not need to be precise.
  static const double _kHeadTopFactor = 0.20;
  static const double _kHeadBottomFactor = 0.66;

  /// How far one sweep of a scratch has to travel, as a fraction of the pet's
  /// width. Small enough for a flick of the thumb, big enough that a finger
  /// jittering in place cannot pet the pet by holding still.
  static const double _kScratchStrokeFactor = 0.07;

  /// Direction changes that make a scratch. Two means back-and-forth-and-back:
  /// one wipe across the head is a swipe, three legs of it is a rub.
  static const int _kScratchStrokesPerPet = 2;

  @override
  void initState() {
    super.initState();
    _startSleepRefreshTimer();
    _startBubbleTimer();
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

  Future<void> _showDailyReward(DailyRewardProvider dailyRewardProvider,
      DailyRewardInfo rewardInfo) async {
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
    _bubbleTimer?.cancel();
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

  /// How long the pet will stay up before it nods off again.
  ///
  /// Tapping a sleeping pet buys 30 minutes of awake time; this counts it down.
  /// Rounded up, because the badge only refreshes once a minute and "0 min"
  /// would sit on screen for the whole of the last one.
  ///
  /// Only ever called while [CharacterProvider.isTemporarilyAwake], which is
  /// what guarantees `awakeUntil` is set and still in the future — an expired
  /// countdown takes the badge away rather than needing a string of its own.
  String _awakeForText(CharacterProvider characterProvider) {
    final until = characterProvider.awakeUntil;
    if (until == null) return '';

    final minutes = until.difference(DateTime.now()).inMinutes + 1;
    final l10n = AppLocalizations.of(context);
    return l10n?.mojiAwakeFor(minutes) ?? 'Awake for $minutes min';
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

  /// Says something, and starts the clock on it going quiet again.
  void _showBubble(String text) {
    setState(() {
      _isAwaitingReply = false;
      _lastBotMessage = text;
      _bubbleVisible = true;
    });
    _startBubbleTimer();
  }

  /// Restarts the countdown to the pet going quiet.
  ///
  /// Also runs for the opening greeting, which is a remark like any other —
  /// without this the one message the pet says unprompted would be the one
  /// that never cleared.
  void _startBubbleTimer() {
    _bubbleTimer?.cancel();
    _bubbleTimer = Timer(_bubbleDuration, () {
      if (mounted) {
        setState(() => _bubbleVisible = false);
      }
    });
  }

  /// The sleep states are derived here rather than written into
  /// [_lastBotMessage] at the call sites. The bubble can be hidden when the pet
  /// falls asleep, and a stored message would then reappear stale — deriving
  /// it means the pinned bubble always says why it is pinned.
  String _currentBubbleText(CharacterProvider characterProvider) {
    if (characterProvider.isAiIssueSleepMode) {
      return _reconnectDozingText();
    }
    if (characterProvider.isSleepingForNight) {
      return _nightSleepText();
    }
    if (_isAwaitingReply && _lastUserMessage != null) {
      final l10n = AppLocalizations.of(context);
      final you = l10n?.youLabel ?? 'You';
      return '$you: $_lastUserMessage';
    }
    return _lastBotMessage;
  }

  /// A tap on the pet wakes it, or brings its last remark back up.
  ///
  /// Deliberately does *not* pet it. Petting is the scratch — a hand moved
  /// back and forth across the head — and letting a tap pay the same reward
  /// would mean nobody ever had reason to make the motion. A poke is not
  /// affection, and the two gestures should not be worth the same.
  void _handleCharacterTap(CharacterProvider characterProvider) {
    // Nothing to say that is not already pinned in the bubble.
    if (characterProvider.isAiIssueSleepMode) {
      return;
    }

    if (characterProvider.isSleepingForNight) {
      characterProvider.wakeUp();
      _showBubble(_wakeSuccessText());
      return;
    }

    // Now that the bubble clears itself, tapping the pet is how a player
    // re-reads what they missed.
    _showBubble(_lastBotMessage);
  }

  /// Whether [point], in the pet layer's coordinates, lands on the pet's head.
  ///
  /// The sprite box is centred horizontally and planted on the ground, so it
  /// is reconstructed here from the same numbers that position it rather than
  /// measured off the widget — the art is breathing, and a hitbox that
  /// breathed with it would slide out from under the finger.
  bool _isOnPetHead(Offset point, Size sceneSize, double petWidth) {
    final boxHeight = petWidth / _kPetAspect;
    final boxLeft = (sceneSize.width - petWidth) / 2;
    if (point.dx < boxLeft || point.dx > boxLeft + petWidth) return false;

    final boxTop = sceneSize.height - _kPetFootOffset - boxHeight;
    final y = point.dy - boxTop;
    return y >= boxHeight * _kHeadTopFactor &&
        y <= boxHeight * _kHeadBottomFactor;
  }

  void _handleScratchStart(
      DragStartDetails details, Size sceneSize, double petWidth) {
    _resetScratch();
    _scratchOnHead = _isOnPetHead(details.localPosition, sceneSize, petWidth);
    _scratchLastX = details.localPosition.dx;
  }

  void _handleScratchUpdate(DragUpdateDetails details, double petWidth,
      CharacterProvider characterProvider) {
    if (!_scratchOnHead) return;

    final lastX = _scratchLastX;
    _scratchLastX = details.localPosition.dx;
    if (lastX == null) return;

    final dx = details.localPosition.dx - lastX;
    if (dx == 0) return;
    final direction = dx > 0 ? 1 : -1;

    if (direction == _scratchDirection) {
      _scratchLegTravel += dx.abs();
      return;
    }

    // Turned around. Only a leg long enough to be deliberate counts, which is
    // what keeps a slow diagonal drag from registering as frantic scratching.
    if (_scratchDirection != 0 &&
        _scratchLegTravel >= petWidth * _kScratchStrokeFactor) {
      _scratchReversals++;
      if (_scratchReversals >= _kScratchStrokesPerPet) {
        _scratchReversals = 0;
        _registerScratch(characterProvider);
      }
    }
    _scratchDirection = direction;
    _scratchLegTravel = dx.abs();
  }

  void _resetScratch() {
    _scratchOnHead = false;
    _scratchLastX = null;
    _scratchDirection = 0;
    _scratchLegTravel = 0;
    _scratchReversals = 0;
  }

  /// One registered rub of the head.
  ///
  /// Keeps petting cheap to repeat: [CharacterProvider.petThePet] restarts the
  /// happy burst every time, so a scratch that carries on keeps the reaction
  /// alive instead of playing it once and dropping back to idle mid-rub. The
  /// happiness payout stays on its own cooldown inside the provider.
  void _registerScratch(CharacterProvider characterProvider) {
    if (characterProvider.isAiIssueSleepMode) return;

    if (characterProvider.isSleepingForNight) {
      characterProvider.wakeUp();
      _showBubble(_wakeSuccessText());
      return;
    }

    HapticFeedback.selectionClick();
    characterProvider.petThePet();
  }

  /// The frame shared by every badge in the top bar.
  ///
  /// Light on purpose: 3px border and no drop shadow, against the level pill's
  /// 4px-plus-shadow. When every element on the screen wore the heavy frame
  /// there was no hierarchy left to read, and the badges are secondary to the
  /// pet by definition — they are asking for a tap, not announcing themselves.
  Widget _badgeFrame({
    required Color color,
    required Widget child,
    required String semanticLabel,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: semanticLabel,
      // The visible content is a glyph or a bare number, which tells a screen
      // reader nothing. Making this one node and hiding what is inside it is
      // what keeps the wording the chips used to show.
      container: true,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        // The gap is a Padding rather than a margin on the badge so the badge
        // itself stays exactly 40x40 — that square is the property the layout
        // test measures, and a margin would quietly fold into it.
        child: Padding(
          padding: const EdgeInsetsDirectional.only(end: 8),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: AppTheme.retroDark, width: 3),
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }

  /// Care prompt — appears only when a stat has actually crossed a threshold.
  /// A healthy pet shows nothing, so this reads as the pet asking for
  /// something rather than as a permanent set of meters.
  ///
  /// A bare "!" rather than the sentence it replaced. The sentence was a
  /// full-width red slab shouting louder than a slightly hungry pet warrants,
  /// and its longest translations ellipsised on a handset; the glyph is the
  /// same signal at a fifth of the width and is identical in every locale. The
  /// wording survives in the semantic label and in the care panel one tap away.
  Widget _buildCareBadge(
    AppLocalizations? l10n,
    TextStyle Function({
      double? fontSize,
      FontWeight? fontWeight,
      Color? color,
      double? height,
      TextDecoration? decoration,
      double? letterSpacing,
      FontStyle? fontStyle,
    }) fontFunction,
  ) {
    return Consumer<CharacterProvider>(
      builder: (context, character, _) {
        final concern = PetCareStatus.topConcern(
          hunger: character.hunger,
          happiness: character.happiness,
          health: character.health,
        );
        if (concern == null) {
          return const SizedBox.shrink();
        }

        final isCritical = concern.severity == CareSeverity.critical;
        final label = switch (concern.stat) {
          CareStat.fullness => l10n?.careNeedHungry ?? 'Moji is hungry',
          CareStat.happiness => l10n?.careNeedLonely ?? 'Moji is feeling low',
          CareStat.health => l10n?.careNeedSick ?? 'Moji is sick',
        };

        return _badgeFrame(
          color: isCritical ? AppTheme.retroPrimary : AppTheme.retroOrange,
          semanticLabel: label,
          onTap: () => PetCarePanel.show(context),
          child: Text(
            '!',
            style: fontFunction(
              fontSize: 12,
              color: isCritical ? Colors.white : AppTheme.retroDark,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }

  /// Feeding, on its own button.
  ///
  /// Feeding used to be reachable only through the care panel, behind the care
  /// badge that appears when a stat has already gone bad — so the one thing a
  /// player wants to do for a pet had no button until the pet was in trouble.
  /// This is always here, and it opens the food shelf directly rather than the
  /// stat readings: "how is my pet" and "feed my pet" are different errands.
  ///
  /// Unlike the badges either side of it this is an action, not a notification,
  /// so it takes the neutral chrome fill rather than an alert colour.
  Widget _buildFeedButton(AppLocalizations? l10n) {
    return _badgeFrame(
      color: AppTheme.retroLight,
      semanticLabel: l10n?.careFeedTitle ?? 'Feed',
      onTap: () => PetCarePanel.showFeedPicker(context),
      // An emoji rather than a pixel glyph, because every food in the shop and
      // in the player's hands is already drawn as one. A bowl here and apples
      // everywhere else would read as two different systems.
      child: const Text('🍎', style: TextStyle(fontSize: 18)),
    );
  }

  /// Review prompt — only appears when the SRS queue has something due, so it
  /// reads as a prompt rather than permanent chrome.
  ///
  /// The count alone: a number on a coloured badge is the one notification
  /// idiom that needs no translating, and it cannot overflow the way the
  /// "12 due" chip did in the longer locales.
  Widget _buildReviewBadge(
    AppLocalizations? l10n,
    TextStyle Function({
      double? fontSize,
      FontWeight? fontWeight,
      Color? color,
      double? height,
      TextDecoration? decoration,
      double? letterSpacing,
      FontStyle? fontStyle,
    }) fontFunction,
  ) {
    return Consumer2<VocabProvider, LanguageProvider>(
      builder: (context, vocab, language, _) {
        final dueCount = vocab.dueCount(
          languageCode: language.targetLanguage?.code,
        );
        if (dueCount == 0) {
          return const SizedBox.shrink();
        }

        return _badgeFrame(
          color: AppTheme.retroAccent,
          semanticLabel: l10n?.reviewDueCount(dueCount) ?? '$dueCount due',
          onTap: () => context.pushNamed('review'),
          child: Text(
            // A three-digit queue would not fit the square, and the exact
            // number stops mattering long before then.
            dueCount > 99 ? '99+' : '$dueCount',
            style: fontFunction(
              fontSize: 8,
              color: AppTheme.retroDark,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
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
        setState(() => _isAwaitingReply = false);
      } else {
        characterProvider.setAiIssueSleepMode(false);
      }
    } catch (e) {
      characterProvider.setAiIssueSleepMode(true);
      setState(() => _isAwaitingReply = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final characterProvider =
        Provider.of<CharacterProvider>(context, listen: false);

    // Both states pin the bubble with their own explanation, so there is
    // nothing to set here beyond clearing the pending flag.
    if (characterProvider.isSleepingForNight ||
        characterProvider.isAiIssueSleepMode) {
      setState(() => _isAwaitingReply = false);
      return;
    }

    _textController.clear();
    _bubbleTimer?.cancel();
    setState(() {
      _lastUserMessage = text;
      _isAwaitingReply = true;
      _bubbleVisible = true;
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

          _showBubble(botText);
        }
      } catch (e) {
        characterProvider.setAiIssueSleepMode(true);
        setState(() => _isAwaitingReply = false);
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
    // Three states pin the bubble open rather than letting it fade: the two
    // the player cannot act on, and the wait for a reply. In all three the
    // bubble is the only thing on screen explaining why the input is dead, so
    // it has to outlast the six seconds a remark gets.
    final bubbleVisible = _bubbleVisible ||
        _isAwaitingReply ||
        characterProvider.isSleeping ||
        characterProvider.isAiIssueSleepMode;

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
          final petWidth = constraints.maxWidth * _kPetWidthFactor;

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
                            // Below the speech bubble's band rather than
                            // behind it. The bubble floats over the scene now,
                            // and a moon sliced in half by a white box reads as
                            // a rendering fault; down here the pet's own head
                            // can pass in front of it, which reads as depth.
                            if (!isSunset)
                              Positioned(
                                top: _kCelestialTop,
                                left: 40,
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
              //
              // A Stack, not a Column. The chrome used to be Column rows that
              // pushed the pet down the screen and chopped the sky into bands;
              // it now floats over one continuous scene, so the sky reads as
              // sky all the way behind the top bar and the pet owns the whole
              // area above the input dock. The input bar stays docked and
              // opaque -- it is the one piece of chrome the keyboard pushes
              // around, and floating it over grass would cost legibility for
              // nothing.
              SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          // The pet layer fills the scene. Everything else in
                          // this Stack sits on top of it.
                          Positioned.fill(
                            // LayoutBuilder, because the scratch hitbox needs
                            // the pet layer's own height: `petWidth` comes
                            // from the outer scene but the sprite is planted
                            // against the bottom of *this* box, which the
                            // input dock and the safe area both shorten.
                            child: LayoutBuilder(
                                builder: (context, sceneConstraints) {
                              final sceneSize = Size(sceneConstraints.maxWidth,
                                  sceneConstraints.maxHeight);
                              return DragTarget<String>(
                                // The pet is a drop target for carried food.
                                // Hovering holds it in the `waiting` phase,
                                // which is what keeps its mouth open until the
                                // food is actually released.
                                onWillAcceptWithDetails: (details) =>
                                    details.data ==
                                    characterProvider.heldFoodId,
                                onMove: (_) =>
                                    characterProvider.setFoodHovering(true),
                                onLeave: (_) =>
                                    characterProvider.setFoodHovering(false),
                                onAcceptWithDetails: (_) {
                                  characterProvider.feedHeldFood();
                                },
                                builder: (context, candidate, rejected) {
                                  return GestureDetector(
                                    behavior: HitTestBehavior.translucent,
                                    onTap: () =>
                                        _handleCharacterTap(characterProvider),
                                    // Long-press opens the care panel. The care
                                    // badge only appears when something is
                                    // wrong, so this is how a curious player
                                    // checks on a healthy pet.
                                    onLongPress: () =>
                                        PetCarePanel.show(context),
                                    // Scratching the head back and forth pets
                                    // the pet. Horizontal only, so it does not
                                    // fight the food a player drags up onto the
                                    // pet from the paws below.
                                    onHorizontalDragStart: (details) =>
                                        _handleScratchStart(
                                            details, sceneSize, petWidth),
                                    onHorizontalDragUpdate: (details) =>
                                        _handleScratchUpdate(details, petWidth,
                                            characterProvider),
                                    onHorizontalDragEnd: (_) => _resetScratch(),
                                    onHorizontalDragCancel: _resetScratch,
                                    child: Stack(
                                      children: [
                                        Positioned(
                                          left: 0,
                                          right: 0,
                                          bottom: _kPetFootOffset + 25,
                                          child: Center(
                                            child: Container(
                                              width: 150,
                                              height: 70,
                                              decoration: BoxDecoration(
                                                color: Colors.black
                                                    .withValues(alpha: 0.22),
                                                borderRadius:
                                                    BorderRadius.circular(100),
                                              ),
                                            ),
                                          ),
                                        ),
                                        // Sized explicitly rather than by a
                                        // fraction of the scene: a fractional
                                        // box centres the art inside itself, so
                                        // the pet would drift up off the grass
                                        // as soon as the scene grew. Anchoring
                                        // the art's own box to the ground is
                                        // what keeps its feet planted at any
                                        // scene height.
                                        Positioned(
                                          left: 0,
                                          right: 0,
                                          bottom: _kPetFootOffset,
                                          child: Center(
                                            child: SizedBox(
                                              width: petWidth,
                                              height: petWidth / _kPetAspect,
                                              child: Stack(
                                                clipBehavior: Clip.none,
                                                children: [
                                                  // Positioned.fill, not a bare
                                                  // child: a Stack hands loose
                                                  // constraints to its
                                                  // non-positioned children, and
                                                  // the sprite falls back to the
                                                  // art's intrinsic viewBox size
                                                  // unless it is given tight
                                                  // ones. Left loose it shrinks
                                                  // to 222x278 and floats off
                                                  // the ground.
                                                  const Positioned.fill(
                                                    child: CharacterSprite(
                                                      width: double.infinity,
                                                      height: double.infinity,
                                                      fit: BoxFit.contain,
                                                      motionProfile:
                                                          CharacterMotionProfile
                                                              .full,
                                                    ),
                                                  ),
                                                  // The sleep trail rides the
                                                  // sprite's own box, so it stays
                                                  // by the pet's head at any
                                                  // screen size. The art's
                                                  // viewBox carries 90/328 of
                                                  // empty headroom for hats,
                                                  // which is the gap this sits
                                                  // in -- up and to the right of
                                                  // the ears.
                                                  if (characterProvider
                                                      .isSleeping)
                                                    Positioned(
                                                      right: 0,
                                                      top: petWidth *
                                                          _kSleepZsTopFactor,
                                                      child: SleepZs(
                                                        baseSize: petWidth *
                                                            _kSleepZsSizeFactor,
                                                      ),
                                                    ),
                                                  // Hearts rise out of the
                                                  // headroom above the ears --
                                                  // the same empty band of the
                                                  // viewBox the sleep trail
                                                  // uses, so they clear the
                                                  // art (and any hat) instead
                                                  // of crossing it.
                                                  Positioned(
                                                    left: 0,
                                                    right: 0,
                                                    top: 0,
                                                    child: Center(
                                                      child: PetHearts(
                                                        burstId:
                                                            characterProvider
                                                                .petPayouts,
                                                        baseSize: petWidth *
                                                            _kHeartSizeFactor,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            }),
                          ),

                          // The top bar floats over the sky rather than
                          // occupying a row above it.
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: Padding(
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
                                                      fontWeight:
                                                          FontWeight.bold,
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
                                                      fontWeight:
                                                          FontWeight.bold,
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
                                                      widthFactor: userProvider
                                                          .stats.progress,
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
                                      // The prompts and settings share the level
                                      // pill's row as compact badges. They used
                                      // to be labelled chips on a Wrap of their
                                      // own, which cost a whole line of the
                                      // screen and still ellipsised in long
                                      // locales — a glyph and a count say the
                                      // same thing in a fifth of the width and
                                      // cannot overflow in any language.
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _buildCareBadge(l10n, fontFunction),
                                          _buildReviewBadge(l10n, fontFunction),
                                          _buildFeedButton(l10n),
                                          // Settings Button — secondary chrome,
                                          // so it drops to the light frame and
                                          // lets the level pill carry the weight.
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[200],
                                              border: Border.all(
                                                  color: AppTheme.retroDark,
                                                  width: 3),
                                            ),
                                            child: IconButton(
                                              padding: EdgeInsets.zero,
                                              icon: SvgPicture.asset(
                                                'assets/svgs/icon-grid.svg',
                                                width: 18,
                                                height: 18,
                                                colorFilter:
                                                    const ColorFilter.mode(
                                                        AppTheme.retroDark,
                                                        BlendMode.srcIn),
                                              ),
                                              onPressed: () =>
                                                  _showSettingsDialog(context),
                                              // No round ink ripple inside the
                                              // square retro frame.
                                              style: const ButtonStyle(
                                                overlayColor:
                                                    WidgetStatePropertyAll(
                                                        Colors.transparent),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // The pet's voice, and the one status line the
                          // bubble cannot carry, share a column under the top
                          // bar so neither has to guess the other's height.
                          Positioned(
                            top: _kTopBarHeight,
                            left: 0,
                            right: 0,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Only the awake countdown: how long the pet
                                // will stay up is information nothing else on
                                // the screen carries. Why it fell asleep is
                                // the bubble's job, and it is pinned open
                                // there for exactly as long as it is true.
                                if (characterProvider.isTemporarilyAwake) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppTheme.retroGrass,
                                      border: Border.all(
                                          color: AppTheme.retroDark, width: 3),
                                    ),
                                    child: Text(
                                      _awakeForText(characterProvider),
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
                                  const SizedBox(height: 8),
                                ],
                                // Speech Bubble. Fades out once the pet has
                                // had its say, and is held open only while
                                // something needs explaining -- see
                                // [_bubbleVisible].
                                IgnorePointer(
                                  ignoring: !bubbleVisible,
                                  child: AnimatedOpacity(
                                    opacity: bubbleVisible ? 1 : 0,
                                    duration: const Duration(milliseconds: 220),
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Container(
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 24),
                                          padding: const EdgeInsets.all(16),
                                          constraints: const BoxConstraints(
                                              minHeight: 80),
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
                                              _currentBubbleText(
                                                  characterProvider),
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
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // The bond strip sits on the grass under the pet
                          // rather than in the top bar, because that is where
                          // it belongs emotionally: bond is what the pet
                          // feels, not a stat the player banked. Its old home
                          // above the speech bubble made the player read three
                          // cards before reaching the animal they are about.
                          const Positioned(
                            left: 0,
                            right: 0,
                            bottom: 10,
                            child: Center(child: BondMeter()),
                          ),

                          // Carried food is the last layer, so what the player
                          // is holding is never behind the pet it is being
                          // offered to. It used to sit inside the pet layer at
                          // the very bottom of the scene, which put it under
                          // the bond strip and level with the pet's feet --
                          // half of it was hidden exactly when it mattered.
                          // Renders nothing until a food is picked up.
                          const Positioned(
                            left: 0,
                            right: 0,
                            bottom: _kCarriedFoodOffset,
                            child: Center(child: CarriedFood()),
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
                                  // Always the same prompt. The field greys
                                  // out when the pet cannot talk, and the
                                  // bubble says why — restating the reason
                                  // here was the third copy of one message.
                                  hintText: typeHereText.toUpperCase(),
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
