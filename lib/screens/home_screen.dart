import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'dart:async';
import '../constants/app_runtime_config.dart';
import '../constants/scenes.dart';
import '../constants/theme.dart';
import '../providers/ads_provider.dart';
import '../providers/user_provider.dart';
import '../providers/daily_reward_provider.dart';
import '../providers/language_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/tutorial_provider.dart';
import '../components/scene_backdrop.dart';
import '../components/scene_motif.dart';
import '../components/home_action_bar.dart';
import '../components/pet_care_panel.dart';
import '../components/carried_food.dart';
import '../components/pet_hearts.dart';
import '../components/play/toy_chest.dart';
import '../components/sleep_zs.dart';
import '../components/study_hub.dart';
import '../components/speech_bubble_tail.dart';
import '../utils/pet_care_status.dart';
import '../providers/character_provider.dart';
import '../providers/vocab_provider.dart';
import '../models/models.dart';
import '../components/character_sprite.dart';
import '../components/daily_rewards_dialog.dart';
import '../l10n/app_localizations.dart';
import '../utils/fonts.dart';
import '../utils/head_scratch.dart';
import '../utils/intro_handoff.dart';
import '../utils/rtl_locale.dart';
import '../constants/tutorials.dart';
import '../components/tutorial/retro_showcase.dart';
import '../components/tutorial/tutorial_offer_host.dart';
import '../components/navigation_wrapper.dart';

/// The level and XP pill on the home screen's top row.
const Key levelPillKey = Key('home-level-pill');

/// The grid button on that same row, which opens the settings dialog.
///
/// Named for the same reason the pill is: it is singular, addressable app
/// furniture, and the tests that reach the settings behind it have to be able
/// to pick it out from the other icon button on the screen.
const Key homeSettingsButtonKey = Key('home-settings-button');

/// The home tour's steps, in the order it visits them.
///
/// File-level because a showcase key is a registry id rather than a widget
/// key — since showcaseview 5 it is never attached to an element, so it can
/// safely outlive the widget it names.
///
/// The tour carries on past the last of these into the nav bar, whose keys
/// live with the bar in `components/navigation_wrapper.dart`.
final GlobalKey homePetShowcaseKey = GlobalKey();
final GlobalKey homeLevelShowcaseKey = GlobalKey();
final GlobalKey homeCareShowcaseKey = GlobalKey();
final GlobalKey homeStudyShowcaseKey = GlobalKey();
final GlobalKey homeFeedShowcaseKey = GlobalKey();
final GlobalKey homeSettingsShowcaseKey = GlobalKey();

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.introHandoff});

  /// Set only when the player has just come off the meet-your-pet screen.
  /// Carries where that screen left the pet, so this one can start it there
  /// and walk it into place instead of cutting. See [IntroHandoff].
  final IntroHandoff? introHandoff;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  String _lastBotMessage = "I love learning! What shall we practice today?";
  bool _dailyRewardDialogVisible = false;
  DailyRewardInfo? _resolvedDailyReward;
  bool _didResolveDailyReward = false;
  bool _didBootstrapAds = false;
  Timer? _sleepRefreshTimer;

  /// Runs once, and only when arriving from onboarding: the pet walks from
  /// the pose the tutorial left it in to its own, while the chrome that was
  /// not there a moment ago slides and fades in around it.
  ///
  /// Null on every ordinary visit, which is also the switch every piece of
  /// the arrival is written against — no controller, no wrappers, nothing to
  /// pay for on the screen the player opens a thousand times.
  AnimationController? _arrival;
  Animation<double>? _arrivalCurve;

  /// Captured in [initState] rather than read off the widget each build. The
  /// route builder claims the pose once, so a later rebuild hands this widget
  /// a null one — and reading that mid-flight would drop the pet on the spot.
  IntroHandoff? _handoff;

  /// Whether the pet has finished walking into place.
  ///
  /// The tour is offered on the first home screen a player ever sees, which
  /// is exactly the visit that plays the arrival: start it any earlier and
  /// the first step measures a pet that is still mid-stride, and lands its
  /// highlight where the pet used to be.
  bool _arrivalDone = true;

  /// Scratch-to-pet gesture. The rules live in [HeadScratchDetector] so the
  /// onboarding tutorial can teach exactly the motion this screen accepts.
  late final HeadScratchDetector _scratch =
      HeadScratchDetector(onScratch: _registerScratch);

  /// Whether the pet is currently saying something.
  ///
  /// The bubble used to be permanent, which meant the pet's last remark sat
  /// over the scene forever and the idle screen always had a slab of text on
  /// it. It is speech, so it behaves like speech: it appears when there is
  /// something to say and clears itself afterwards. Asleep, it is pinned open
  /// instead, because there the bubble is the only thing saying why the pet
  /// is not answering.
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
  static const double _kPetAspect = HeadScratchDetector.petAspect;

  /// How much of the scene's width the pet takes.
  ///
  /// Three quarters of the 0.86 it used to be. At that size the pet was most
  /// of the screen and the world it stands in was a strip of grass behind it;
  /// backing it off is what gives the scene, the shadow and the things that
  /// hang around the pet room to read.
  static const double _kPetWidthFactor = 0.645;

  /// Clearance between the pet's feet and the bottom of the scene.
  ///
  /// It used to be 52, which put the feet too near the bottom for a pet that
  /// lays its silhouette forward across the grass rather than a shadow
  /// ellipse centred on its own foot line. 88 leaves the deepest of those
  /// clear: a cat in a wizard hat, whose silhouette is 317 art units tall
  /// against the cat's own 238.
  static const double _kPetFootOffset = 88;

  /// Height of the floating top bar: a 48pt level pill inside 24pt of padding
  /// either side. What the pet's voice hangs below.
  static const double _kTopBarHeight = 96;

  /// Where carried food floats, above the foot of the scene. It sits over
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

  /// How long the pet takes to settle. Long enough to read as the pet
  /// walking into its spot, short enough that nobody is waiting on it.
  static const Duration _kArrival = Duration(milliseconds: 620);

  @override
  void initState() {
    super.initState();
    _handoff = widget.introHandoff;
    if (_handoff != null) {
      final controller = AnimationController(vsync: this, duration: _kArrival);
      _arrival = controller;
      _arrivalCurve =
          CurvedAnimation(parent: controller, curve: Curves.easeOutCubic);
      _arrivalDone = false;
      controller.forward().whenComplete(() {
        if (mounted) setState(() => _arrivalDone = true);
      });
    }
    _startSleepRefreshTimer();
    _startBubbleTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _resolveDailyReward();
        _bootstrapAds();
      }
    });
  }

  /// Starts the ad SDK once, on the first home screen of the session.
  ///
  /// Here rather than in `main` for two reasons: the UMP consent form is a
  /// native dialog that needs an activity on screen to appear over, and the
  /// home screen is only reachable once onboarding is done — so the form can
  /// never land on top of the opening, which is the one flow in the app that
  /// has to stay uninterrupted.
  void _bootstrapAds() {
    if (_didBootstrapAds) return;
    _didBootstrapAds = true;

    unawaited(Provider.of<AdsProvider>(context, listen: false).bootstrap());
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
    _arrival?.dispose();
    _sleepRefreshTimer?.cancel();
    _bubbleTimer?.cancel();
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


  /// The night-sleep state is derived here rather than written into
  /// [_lastBotMessage] at the call site. The bubble can be hidden when the pet
  /// falls asleep, and a stored message would then reappear stale — deriving
  /// it means the pinned bubble always says why it is pinned.
  String _currentBubbleText(CharacterProvider characterProvider) {
    if (characterProvider.isSleepingForNight) {
      return _nightSleepText();
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
    if (characterProvider.isSleepingForNight) {
      characterProvider.wakeUp();
      _showBubble(_wakeSuccessText());
      return;
    }

    // Now that the bubble clears itself, tapping the pet is how a player
    // re-reads what they missed.
    _showBubble(_lastBotMessage);
  }

  /// One registered rub of the head.
  ///
  /// Keeps petting cheap to repeat: [CharacterProvider.petThePet] restarts the
  /// happy burst every time, so a scratch that carries on keeps the reaction
  /// alive instead of playing it once and dropping back to idle mid-rub. The
  /// happiness payout stays on its own cooldown inside the provider.
  void _registerScratch() {
    final characterProvider =
        Provider.of<CharacterProvider>(context, listen: false);
    if (characterProvider.isSleepingForNight) {
      characterProvider.wakeUp();
      _showBubble(_wakeSuccessText());
      return;
    }

    HapticFeedback.selectionClick();
    characterProvider.petThePet();
  }

  /// Chrome that was not on screen a moment ago, faded up on arrival.
  ///
  /// Returns [child] untouched on an ordinary visit, so the widget tree the
  /// player normally sees carries none of this.
  Widget _arriving(Widget child) {
    final curve = _arrivalCurve;
    if (curve == null) return child;
    return FadeTransition(opacity: curve, child: child);
  }

  /// The pet's walk-in.
  ///
  /// A paint-time transform rather than an animated layout: the pet is built
  /// once, at its resting size, and the transform maps that box onto the one
  /// the tutorial left behind and then releases it. Nothing in the subtree
  /// rebuilds, which matters because the subtree is an SVG already breathing
  /// on its own clock.
  ///
  /// [layerTop] is the pet layer's distance from the top of the screen and
  /// [layerHeight] its own height; together they turn the handoff's global
  /// rectangle into this layer's coordinates.
  Widget _arrivingPet({
    required Widget child,
    required double layerTop,
    required double layerHeight,
    required double petWidth,
  }) {
    final curve = _arrivalCurve;
    final handoff = _handoff;
    if (curve == null || handoff == null || petWidth <= 0) return child;

    // Where the pet's box was, and where it is going, in this layer.
    final startBottom = handoff.petRect.bottom - layerTop;
    final restBottom = layerHeight - _kPetFootOffset;

    final startScale = handoff.petRect.width / petWidth;
    final dy = startBottom - restBottom;

    // Both screens centre the pet horizontally and stand it on its bottom
    // edge, so scaling about that edge and then sliding it is the whole
    // mapping between the two poses.
    final anchor = FractionalOffset(0.5, restBottom / layerHeight);

    return AnimatedBuilder(
      animation: curve,
      // Hoisted: this is what keeps the sprite from rebuilding per frame.
      child: child,
      builder: (context, built) {
        final t = curve.value;
        return Transform.translate(
          offset: Offset(0, dy * (1 - t)),
          child: Transform.scale(
            scale: startScale + (1 - startScale) * t,
            alignment: anchor,
            child: built,
          ),
        );
      },
    );
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
        //
        // 6 rather than 8: three of these plus the settings square leave the
        // level pill 168pt, and "経験値: 72/100" at the 10px CJK face wants
        // 174. Six points across the row is what keeps the XP numbers from
        // ellipsising in the CJK locales.
        child: Padding(
          padding: const EdgeInsetsDirectional.only(end: 6),
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

        // Wrapped here rather than at the call site: on the branch above
        // this badge is a zero-size box, and a showcase step registered
        // against that would point at nothing instead of being skipped.
        return RetroShowcase(
          showcaseKey: homeCareShowcaseKey,
          description: l10n?.tutorialHomeCare ??
              'This appears when your Mimikin needs something.',
          child: _badgeFrame(
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
    return RetroShowcase(
      showcaseKey: homeFeedShowcaseKey,
      description: l10n?.tutorialHomeFeed ??
          'Your food. Pick a snack, then drag it onto your Mimikin.',
      child: _badgeFrame(
        color: AppTheme.retroLight,
        semanticLabel: l10n?.careFeedTitle ?? 'Feed',
        onTap: () => PetCarePanel.showFeedPicker(context),
        // The shop's own apple art, not an emoji: food is drawn on the pet's
        // pixel grid everywhere else now, and a platform emoji here would read
        // as a second art set sitting next to the first.
        child: SvgPicture.asset(
          'assets/svgs/food_apple.svg',
          width: 20,
          height: 20,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  /// The study button: the way into the review queue and the list of mistakes,
  /// which no longer have a tab of their own. Always here, because the mistakes
  /// are worth a visit whether or not anything is due; what is due shows as a
  /// count on its corner, so it still reads as a prompt when there is something
  /// to do.
  ///
  /// The count alone: a number on a coloured badge is the one notification
  /// idiom that needs no translating, and it cannot overflow the way the
  /// "12 due" chip did in the longer locales.
  Widget _buildStudyButton(
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

        return RetroShowcase(
          showcaseKey: homeStudyShowcaseKey,
          description: l10n?.tutorialHomeReview ??
              'Study: review what is due and look back at your mistakes.',
          child: _badgeFrame(
            color: dueCount > 0 ? AppTheme.retroAccent : AppTheme.retroLight,
            semanticLabel: dueCount > 0
                ? (l10n?.reviewDueCount(dueCount) ?? '$dueCount due')
                : (l10n?.review ?? 'Review'),
            onTap: () => StudyHub.show(context),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(LucideIcons.bookOpen,
                    size: 20, color: AppTheme.retroDark),
                if (dueCount > 0)
                  PositionedDirectional(
                    end: 0,
                    bottom: 0,
                    child: Container(
                      key: const ValueKey('study-due'),
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      constraints: const BoxConstraints(minWidth: 14),
                      color: AppTheme.retroPrimary,
                      child: Text(
                        // A three-digit queue would not fit the square, and
                        // the exact number stops mattering long before then.
                        dueCount > 99 ? '99+' : '$dueCount',
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.ltr,
                        style: fontFunction(
                          fontSize: 7,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
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
                const SizedBox(height: 20),

                // Puts every page tour back on offer. The tours are offered
                // once and retired on any answer, so a player who tapped SKIP
                // by reflex on the first screen they ever saw would otherwise
                // have no way back to them.
                GestureDetector(
                  onTap: () async {
                    await Provider.of<TutorialProvider>(context, listen: false)
                        .resetAll();
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.retroUi,
                      border: Border.all(color: AppTheme.retroDark, width: 3),
                      boxShadow: const [
                        BoxShadow(
                            color: AppTheme.retroDark, offset: Offset(2, 2)),
                      ],
                    ),
                    child: Text(
                      l10n?.tutorialReplay ?? 'Replay tutorials',
                      textAlign: TextAlign.center,
                      style: fontFunction(
                        fontSize: 10,
                        color: AppTheme.retroDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
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

    final fontFunction = settingsProvider.usePixelFont
        ? AppFonts.pressStart2p
        : AppFonts.spaceMono;

    /// Digits and other Latin inside an otherwise translated string.
    ///
    /// A [TextStyle] carries one size for the whole run, so a string like
    /// "経験値: 72/100" would draw its numbers at the size the kanji were
    /// scaled to — see [AppFonts.nonLatinOpticalScale]. Press Start 2P draws
    /// those digits, and Press Start 2P is what the scale is measured
    /// against, so they belong at the size the caller asked for.
    TextStyle latinStyle(
            {required double fontSize, Color? color, FontWeight? fontWeight}) =>
        settingsProvider.usePixelFont
            ? AppFonts.pressStart2p(
                fontSize: fontSize,
                color: color,
                fontWeight: fontWeight,
                locale: const Locale('en'),
              )
            : AppFonts.spaceMono(
                fontSize: fontSize, color: color, fontWeight: fontWeight);

    // Asleep, the bubble is pinned open rather than left to fade: with the
    // pet out cold it is the only thing on screen saying why, so it has to
    // outlast the six seconds a remark gets.
    final bubbleVisible = _bubbleVisible || characterProvider.isSleeping;

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

    // Where the pet lives: one of the free scenes, or whichever the player
    // bought. Each scene carries its own day / sunset / night palette, so
    // changing worlds never costs the player the time-of-day cycle — see
    // constants/scenes.dart.
    final scene = characterProvider.scene;
    final palette = scene.paletteFor(sceneTimeAt(DateTime.now()));

    return TutorialOfferHost(
      id: TutorialId.home,
      // Held back until the pet has landed and the daily reward has been
      // dealt with. Both are first-visit events, and the first visit is
      // exactly when this tour runs.
      enabled: _arrivalDone && !_dailyRewardDialogVisible,
      // Resolved when the tour starts, not now: the care badge is
      // usually absent on a new save, and the sequence skips it when it is
      // not on screen at that moment.
      steps: () => [
        homePetShowcaseKey,
        homeLevelShowcaseKey,
        homeCareShowcaseKey,
        homeStudyShowcaseKey,
        homeFeedShowcaseKey,
        homeSettingsShowcaseKey,
        navTownShowcaseKey,
        navChatShowcaseKey,
        navShopShowcaseKey,
        navProfileShowcaseKey,
      ],
      child: Container(
        color: palette.sky, // Main BG color
        child: LayoutBuilder(
          builder: (context, constraints) {
            final petWidth = constraints.maxWidth * _kPetWidthFactor;
            // How far the scene reaches up past the pet layer to stay full
            // bleed behind the status bar. See the scene layers below.
            final sceneTopInset = MediaQuery.of(context).padding.top;

            return Stack(
              children: [
                // The UI content.
                //
                // A Stack, not a Column. The chrome used to be Column rows that
                // pushed the pet down the screen and chopped the sky into bands;
                // it now floats over one continuous scene, so the sky reads as
                // sky all the way behind the top bar and the pet owns the whole
                // area above the nav bar.
                SafeArea(
                  child: Column(
                    children: [
                      Expanded(
                        // Clip.none so the scene below can reach up behind the
                        // status bar; nothing else in here overflows.
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // The banded scene, always. A world that names an
                            // SVG draws it over the top of this — see
                            // [SceneBackdrop] — so the bands are what is on
                            // screen while the picture loads and what stays
                            // there if it is missing.
                            //
                            // Bounded by the pet layer, not by the window. The
                            // horizon is a fraction of the scene's height, so a
                            // scene sized to the whole window buries its ground
                            // band behind the nav bar and
                            // leaves the pet standing on the skyline. Sized to
                            // the box the pet is planted in, the ground ends
                            // where the pet's feet do and the pet stands in it.
                            //
                            // The negative top is the status bar: the sky still
                            // runs full bleed behind the level pill, which is
                            // what [Clip.none] above is for.
                            Positioned(
                              top: -sceneTopInset,
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: Column(
                                children: [
                                  // Sky section. The split is the scene's, not
                                  // the screen's — see [SceneTheme.horizon].
                                  Expanded(
                                    flex: (scene.horizon * 1000).round(),
                                    child: Container(
                                      color: palette.sky,
                                      child: Stack(
                                        children: [
                                          // Stars, where the scene has them: at
                                          // night in most worlds, around the
                                          // clock in the galaxy.
                                          for (final speck in palette.skySpecks)
                                            _SceneSpeckBox(
                                              speck: speck,
                                              color: palette.skySpeckColor,
                                            ),
                                          // Sky drawings — the airfield's
                                          // departing plane, and nothing else
                                          // so far. Above the stars and below
                                          // the sun, which is where a plane
                                          // belongs in both.
                                          for (final motif in palette.skyMotifs)
                                            SceneMotifBox(
                                              motif: motif,
                                              inks: palette.motifInks,
                                            ),
                                          // Celestial Body (Sun/Moon) Below the
                                          // speech bubble's band rather than
                                          // behind it. The bubble floats over
                                          // the scene now, and a moon sliced in
                                          // half by a white box reads as a
                                          // rendering fault; down here the
                                          // pet's own head can pass in front of
                                          // it, which reads as depth.
                                          if (palette.celestial != null)
                                            Positioned(
                                              top: _kCelestialTop,
                                              left: 40,
                                              child: Container(
                                                width: 48,
                                                height: 48,
                                                decoration: BoxDecoration(
                                                  color: palette.celestial,
                                                  border: Border.all(
                                                      width: 4,
                                                      color:
                                                          AppTheme.retroDark),
                                                  // The moon's halo. A sun gets
                                                  // none: it is a flat block of
                                                  // pixels, and a glow on it
                                                  // read as a smudge.
                                                  boxShadow: palette
                                                          .celestialGlow
                                                      ? const [
                                                          BoxShadow(
                                                              color: Colors
                                                                  .white24,
                                                              blurRadius: 20,
                                                              spreadRadius: 5)
                                                        ]
                                                      : null,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Ground section
                                  Expanded(
                                    flex: 1000 - (scene.horizon * 1000).round(),
                                    child: Container(
                                      width: double.infinity,
                                      color: palette.ground,
                                      child: Stack(
                                        children: [
                                          // Top border of ground
                                          Align(
                                              alignment: Alignment.topCenter,
                                              child: Container(
                                                  height: 4,
                                                  color: AppTheme.retroDark)),
                                          // Shading just under the horizon
                                          Positioned(
                                              top: 8,
                                              left: 0,
                                              right: 0,
                                              child: Container(
                                                  height: 16,
                                                  color: palette.groundDetail
                                                      .withValues(alpha: 0.2))),
                                          // Ground details: tufts, waves, dunes
                                          // or craters, whichever this world is
                                          // made of.
                                          for (final speck
                                              in palette.groundSpecks)
                                            _SceneSpeckBox(
                                              speck: speck,
                                              color: palette.groundDetail,
                                            ),
                                          // Over the paint, because the one
                                          // thing drawn down here is an
                                          // aircraft's shadow and a shadow
                                          // falls on the markings too.
                                          for (final motif
                                              in palette.groundMotifs)
                                            SceneMotifBox(
                                              motif: motif,
                                              inks: palette.motifInks,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // The scene's own picture, where it has one.
                            // Anchored where the scene asks: the bottom unless
                            // its top is the point. The horizon and the ground
                            // are what the pet stands in, so sky is what a tall
                            // screen crops by default.
                            if (scene.asset != null)
                              Positioned(
                                top: -sceneTopInset,
                                left: 0,
                                right: 0,
                                bottom: 0,
                                child: SceneBackdrop(
                                  scene: scene,
                                  time: sceneTimeAt(DateTime.now()),
                                  alignment: scene.homeAlignment,
                                  // Drawn once, not replayed each time the
                                  // pet moves. See [SceneBackdrop.rasterize].
                                  rasterize: true,
                                ),
                              ),

                            // The pet layer fills the scene. Everything else in
                            // this Stack sits on top of it.
                            Positioned.fill(
                              // LayoutBuilder, because the scratch hitbox needs
                              // the pet layer's own height: `petWidth` comes
                              // from the outer scene but the sprite is planted
                              // against the bottom of *this* box, which the
                              // safe area shortens.
                              child: LayoutBuilder(
                                  builder: (context, sceneConstraints) {
                                final sceneSize = Size(
                                    sceneConstraints.maxWidth,
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
                                      onTap: () => _handleCharacterTap(
                                          characterProvider),
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
                                          _scratch.start(details.localPosition,
                                              sceneSize: sceneSize,
                                              petWidth: petWidth,
                                              footOffset: _kPetFootOffset),
                                      onHorizontalDragUpdate: (details) =>
                                          _scratch.update(details.localPosition,
                                              petWidth: petWidth),
                                      onHorizontalDragEnd: (_) =>
                                          _scratch.reset(),
                                      onHorizontalDragCancel: _scratch.reset,
                                      // The hitbox stays at the resting pose
                                      // while the pet walks in. For the half
                                      // second that costs, the pet is moving
                                      // and nobody is trying to scratch it.
                                      child: _arrivingPet(
                                        layerTop:
                                            MediaQuery.of(context).padding.top,
                                        layerHeight: sceneSize.height,
                                        petWidth: petWidth,
                                        child: Stack(
                                          children: [
                                            // No contact shadow here any more.
                                            // It was a fixed ellipse, which is
                                            // the same oval under a cat, a
                                            // chick and a parrot on a perch and
                                            // the shape of none of them. The
                                            // sprite now lays its own
                                            // silhouette down instead, hat
                                            // included — it is the only thing
                                            // that knows the outline, and the
                                            // only thing that can keep the
                                            // shadow in step with the pose.
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
                                                // The tour points at the art's own
                                                // box. The gesture layer above is
                                                // Positioned.fill, so highlighting
                                                // that would just dim the screen
                                                // and cut a hole the shape of it.
                                                child: RetroShowcase(
                                                  showcaseKey:
                                                      homePetShowcaseKey,
                                                  description: l10n
                                                          ?.tutorialHomePet ??
                                                      'This is Moji. Tap it, or '
                                                          'drag across its head to '
                                                          'scratch.',
                                                  isFirst: true,
                                                  targetPadding:
                                                      EdgeInsets.zero,
                                                  child: SizedBox(
                                                    width: petWidth,
                                                    height:
                                                        petWidth / _kPetAspect,
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
                                                          child:
                                                              CharacterSprite(
                                                            width:
                                                                double.infinity,
                                                            height:
                                                                double.infinity,
                                                            fit: BoxFit.contain,
                                                            motionProfile:
                                                                CharacterMotionProfile
                                                                    .full,
                                                            // The pet's own
                                                            // silhouette on
                                                            // the grass —
                                                            // see below for
                                                            // what it
                                                            // replaced.
                                                            groundShadow: true,
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
                                            ),
                                          ],
                                        ),
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
                              child: _arriving(Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24.0, vertical: 24.0),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Level Pill (Retro Style)
                                        //
                                        // Flexible because the XP label is the
                                        // one piece of this row that translates:
                                        // in the CJK locales it is drawn at the
                                        // 10px face floor and pushed the row 9px
                                        // off the side of a handset. It gives way
                                        // now instead of overflowing.
                                        Flexible(
                                          child: RetroShowcase(
                                            showcaseKey: homeLevelShowcaseKey,
                                            description:
                                                l10n?.tutorialHomeLevel ??
                                                    'Your level and XP.',
                                            child: GestureDetector(
                                              key: levelPillKey,
                                              onTap: () => context
                                                  .pushNamed('level_rewards'),
                                              child: Container(
                                                // 10 rather than 12 for the same
                                                // reason as the badge gaps below.
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 8),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  border: Border.all(
                                                      color: AppTheme.retroDark,
                                                      width: 4),
                                                  boxShadow: const [
                                                    BoxShadow(
                                                        color:
                                                            AppTheme.retroDark,
                                                        offset: Offset(4, 4),
                                                        blurRadius: 0)
                                                  ],
                                                ),
                                                child: Row(
                                                  // Hugs its contents. Left to
                                                  // fill, the pill stretched to
                                                  // whatever the badges did not
                                                  // use, which on a screen with
                                                  // no care badge is most of
                                                  // the row: a short
                                                  // "XP: 0/100" adrift in white.
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Container(
                                                      width: 24,
                                                      height: 24,
                                                      decoration: BoxDecoration(
                                                        color: AppTheme
                                                            .retroAccent,
                                                        border: Border.all(
                                                            color: AppTheme
                                                                .retroDark,
                                                            width: 2),
                                                      ),
                                                      child: Center(
                                                        child: Text(
                                                          '${userProvider.stats.level}',
                                                          style: fontFunction(
                                                            fontSize: 8,
                                                            color: AppTheme
                                                                .retroDark,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    // XP Info
                                                    Flexible(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text.rich(
                                                            TextSpan(children: [
                                                              TextSpan(
                                                                text:
                                                                    l10n?.xp ??
                                                                        'XP',
                                                                style:
                                                                    fontFunction(
                                                                  fontSize: 8,
                                                                  color: AppTheme
                                                                      .retroDark,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                              ),
                                                              TextSpan(
                                                                text:
                                                                    ': ${userProvider.stats.currentLevelXP}/${userProvider.stats.nextLevelXP}',
                                                                style:
                                                                    latinStyle(
                                                                  fontSize: 8,
                                                                  color: AppTheme
                                                                      .retroDark,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                              ),
                                                            ]),
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                          const SizedBox(
                                                              height: 4),
                                                          // XP Bar
                                                          //
                                                          // 72 is how wide "XP:
                                                          // 72/100" is at the size
                                                          // above it, so the bar
                                                          // ends where its own
                                                          // label does rather than
                                                          // running past it.
                                                          Container(
                                                            width: 72,
                                                            height: 8,
                                                            decoration:
                                                                BoxDecoration(
                                                              color: Colors
                                                                  .grey[300],
                                                              border: Border.all(
                                                                  color: AppTheme
                                                                      .retroDark,
                                                                  width: 2),
                                                            ),
                                                            child:
                                                                FractionallySizedBox(
                                                              widthFactor:
                                                                  userProvider
                                                                      .stats
                                                                      .progress,
                                                              alignment: Alignment
                                                                  .centerLeft,
                                                              child: Container(
                                                                color: AppTheme
                                                                    .retroGreen,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
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
                                            _buildStudyButton(
                                                l10n, fontFunction),
                                            _buildFeedButton(l10n),
                                            // Settings Button — secondary chrome,
                                            // so it drops to the light frame and
                                            // lets the level pill carry the weight.
                                            RetroShowcase(
                                              showcaseKey:
                                                  homeSettingsShowcaseKey,
                                              description:
                                                  l10n?.tutorialHomeSettings ??
                                                      'Settings.',
                                              child: Container(
                                                key: homeSettingsButtonKey,
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
                                                      _showSettingsDialog(
                                                          context),
                                                  // No round ink ripple inside the
                                                  // square retro frame.
                                                  style: const ButtonStyle(
                                                    overlayColor:
                                                        WidgetStatePropertyAll(
                                                            Colors.transparent),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              )),
                            ),

                            // The pet's voice, and the one status line the
                            // bubble cannot carry, share a column under the top
                            // bar so neither has to guess the other's height.
                            Positioned(
                              top: _kTopBarHeight,
                              left: 0,
                              right: 0,
                              child: _arriving(Column(
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
                                            color: AppTheme.retroDark,
                                            width: 3),
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
                                      duration:
                                          const Duration(milliseconds: 220),
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
                                          const Positioned(
                                            bottom: -12,
                                            right: 50,
                                            child: CustomPaint(
                                              size: Size(18, 18),
                                              painter: PixelTrianglePainter(),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              )),
                            ),

                            // The toys, the mistakes and the climb, standing around
                            // the pet on the ground: nothing behind them, so they
                            // are part of the room. The layer is the whole scene
                            // but only the drawings take taps.
                            Positioned.fill(
                              child: _arriving(HomeActionBar(
                                // No language check: every game always has
                                // words to play with — see `playWords`.
                                canPlay: !characterProvider.isSleeping,
                                onToys: () => ToyChestPicker.show(context),
                                onMistakes: () => context.pushNamed('mistakes'),
                                onClimb: AppRuntimeConfig.bossTrial
                                    ? () => context.pushNamed('boss_trial')
                                    : null,
                              )),
                            ),

                            // Carried food is the last layer, so what the player
                            // is holding is never behind the pet it is being
                            // offered to. It used to sit inside the pet layer at
                            // the very bottom of the scene, which put it level
                            // with the pet's feet -- half of it was hidden
                            // exactly when it mattered.
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
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// One block of scene decor — a grass tuft, a wave crest, a star.
///
/// Fractional alignment rather than a fixed offset, so the same speck list
/// lands in the same place on a handset and a tablet; a fixed size, so it
/// stays a chunky pixel rather than scaling with the screen.
class _SceneSpeckBox extends StatelessWidget {
  const _SceneSpeckBox({required this.speck, required this.color});

  final SceneSpeck speck;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment(speck.x, speck.y),
      child: SizedBox(
        width: speck.width,
        height: speck.height,
        child: ColoredBox(
          color: speck.opacity == 1.0
              ? color
              : color.withValues(alpha: speck.opacity),
        ),
      ),
    );
  }
}
