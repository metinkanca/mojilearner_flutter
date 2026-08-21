import 'dart:async';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../components/character_carousel.dart';
import '../../constants/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/character_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/fonts.dart';
import '../../utils/rtl_locale.dart';
import '../../services/account_service.dart';
import 'first_launch/language_panel.dart';
import 'first_launch/login_panel.dart';
import 'first_launch/onboarding_text.dart';
import 'first_launch/retro_button.dart';

/// The steps of the opening, in order.
enum FirstLaunchPhase { language, pet, login }

/// Where the opening hands over once a pet has been chosen.
const String afterPetRoute = '/onboarding/username';

/// The app's first screen: pick a UI language, then a pet, without ever
/// cutting away.
///
/// One route rather than three, because the pets have to stay on screen while
/// they grow. Across a route boundary the sprites would unmount and rebuild
/// mid-zoom — a visible flicker at exactly the moment the flow is meant to be
/// seamless. Here a single carousel is resized and slid down the screen.
class FirstLaunchScreen extends StatefulWidget {
  const FirstLaunchScreen({super.key});

  /// Carousel order, left to right — the same rank the in-app pet-changer
  /// shows, so the pet a player met here is where they left it.
  static const petTypes = <String>['dog', 'cat', 'bird'];

  /// How long each language holds the question before the next one takes over.
  static const cycleInterval = Duration(seconds: 2);

  @override
  State<FirstLaunchScreen> createState() => _FirstLaunchScreenState();
}

class _FirstLaunchScreenState extends State<FirstLaunchScreen> {
  /// Pet size as a fraction of the screen width: while the pets are a plain
  /// row over the language list, and once they are the rank being chosen from.
  ///
  /// The header figure is capped by the row being *flat*. With every pet at
  /// full size, the outer two stick out half a tile past their page centres,
  /// so staying on screen needs `tile <= width * (1 - 2 * viewportFraction)`
  /// — 0.29 here. The pet figure can be larger precisely because its
  /// neighbours are shrunk to 0.66 by the emphasis.
  static const double _headerTileFraction = 0.28;
  static const double _petTileFraction = 0.38;

  /// Page width as a fraction of the screen, which is what spaces the pets
  /// apart. Just over a third fits all three on screen whole — the 0.46 the
  /// pet-changer uses deliberately runs the outer two off both edges.
  ///
  /// Paired with [_petTileFraction]: a neighbour is drawn at 0.66 and the
  /// centre at 1.2, so a page has to clear (1.2 + 0.66) / 2 = 0.93 tile widths
  /// to keep the enlarged centre from touching its neighbours.
  static const double _viewportFraction = 0.355;

  /// Room reserved at the top for the question.
  static const double _questionHeight = 76;

  /// Breathing room between the pets and whatever is under them.
  static const double _petGap = 16;

  /// Never let the panel be squeezed below this, however short the screen —
  /// the confirm button has to stay reachable.
  static const double _minPanelHeight = 132;

  static const Duration _zoom = Duration(milliseconds: 420);

  FirstLaunchPhase _phase = FirstLaunchPhase.language;

  /// Held locally rather than written straight to CharacterProvider: swiping
  /// past a pet must not adopt it, only confirming does.
  late String _selectedPet;

  /// Null until the player taps a language, which is also what stops the
  /// question cycling.
  Language? _selectedLanguage;

  Timer? _cycleTimer;
  int _cycleIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedPet = context.read<CharacterProvider>().currentCharacterType;
    if (!FirstLaunchScreen.petTypes.contains(_selectedPet)) {
      _selectedPet = FirstLaunchScreen.petTypes.first;
    }
    _cycleTimer = Timer.periodic(FirstLaunchScreen.cycleInterval, (_) {
      if (!mounted) return;
      setState(() => _cycleIndex++);
    });
  }

  @override
  void dispose() {
    _cycleTimer?.cancel();
    super.dispose();
  }

  /// The languages offered, straight from the provider so every catalogue the
  /// app ships is reachable — an earlier hardcoded list had drifted and left
  /// four translated languages unpickable.
  List<Language> _languages(BuildContext context) =>
      context.read<LanguageProvider>().availableLanguages;

  /// The language the question and the button are currently written in: the
  /// one the player picked, or — until they do — whichever the attract loop
  /// is showing.
  Language _displayLanguage(List<Language> languages) =>
      _selectedLanguage ?? languages[_cycleIndex % languages.length];

  void _onLanguageTapped(Language language) {
    // Locking on the first tap is the confirmation that the tap registered:
    // the question and the button snap into their language and stay there.
    _cycleTimer?.cancel();
    _cycleTimer = null;
    setState(() => _selectedLanguage = language);
  }

  Future<void> _confirmLanguage() async {
    final language = _selectedLanguage;
    if (language == null) return;
    await context.read<LanguageProvider>().setNativeLanguage(language);
    if (!mounted) return;
    setState(() => _phase = FirstLaunchPhase.pet);
  }

  Future<void> _confirmPet() async {
    // Resolved before the await: after it the State may be gone, and reaching
    // back through `context` for the router would be reading a dead tree.
    final router = GoRouter.of(context);
    final account = context.read<AccountService?>();
    // The swipe only moved the rank; this is where the pet is adopted.
    await context.read<CharacterProvider>().updateCharacterType(_selectedPet);
    if (!mounted) return;

    // No account layer means cloud sync never started, so there is no uid to
    // upgrade and nothing an offer to sign in could actually do. Skipping the
    // step beats showing one whose buttons cannot work.
    if (account == null) {
      router.go(afterPetRoute);
      return;
    }
    setState(() => _phase = FirstLaunchPhase.login);
  }

  void _finishOpening() => GoRouter.of(context).go(afterPetRoute);

  /// How far into the zoom the pets are: 0 while they are a header over
  /// something else, 1 while they are the thing being chosen.
  ///
  /// The login step returns to 0, which is what makes the chosen pet zoom
  /// back out — the same animation as the way in, run backwards.
  double get _zoomTarget => _phase == FirstLaunchPhase.pet ? 1.0 : 0.0;

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final languages = _languages(context);
    final displayLanguage = _displayLanguage(languages);
    final displayLocale = Locale(displayLanguage.code);

    // Written in the language being offered, not the app's current one, so
    // the whole screen reads as that language before it has been adopted.
    final strings = lookupAppLocalizations(displayLocale);
    final textDirection = textDirectionForLocale(displayLocale);

    final CarouselFontFn fontFunction =
        settings.usePixelFont ? AppFonts.pressStart2p : AppFonts.spaceMono;

    return Scaffold(
      backgroundColor: AppTheme.retroSky,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: _zoomTarget),
              duration: _zoom,
              curve: Curves.easeInOut,
              builder: (context, t, _) {
                final tileWidth = lerpDouble(
                  constraints.maxWidth * _headerTileFraction,
                  constraints.maxWidth * _petTileFraction,
                  t,
                )!;
                final stageHeight =
                    CharacterCarousel.stageHeight(tileWidth, framed: false);

                // Under the question while the pets are only a header; dead
                // centre of the screen once they are what is being chosen.
                final petTop = lerpDouble(
                  _questionHeight,
                  (constraints.maxHeight - stageHeight) / 2,
                  t,
                )!
                    .clamp(0.0, constraints.maxHeight);

                final panelTop = (petTop + stageHeight + _petGap)
                    .clamp(0.0, constraints.maxHeight - _minPanelHeight);

                return Stack(
                  children: [
                    Positioned(
                      top: panelTop,
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: _buildPanel(
                        languages: languages,
                        strings: strings,
                        locale: displayLocale,
                        textDirection: textDirection,
                        usePixelFont: settings.usePixelFont,
                      ),
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: _questionHeight,
                      child: _buildQuestion(
                        strings: strings,
                        locale: displayLocale,
                        textDirection: textDirection,
                        usePixelFont: settings.usePixelFont,
                      ),
                    ),
                    Positioned(
                      top: petTop,
                      left: 0,
                      right: 0,
                      height: stageHeight,
                      child: IgnorePointer(
                        // The pets are only a header until they are what the
                        // player is choosing between.
                        ignoring: _phase != FirstLaunchPhase.pet,
                        child: CharacterCarousel(
                          types: FirstLaunchScreen.petTypes,
                          tileWidth: tileWidth,
                          // A plain row until the pets are what is being
                          // chosen, then a rank: no singled-out centre and no
                          // position dots on the language step.
                          emphasis: t,
                          // The art carries the screen; three names under it
                          // would only crowd them.
                          labelForType: null,
                          framed: false,
                          // The rank wraps, so there is no dead end to
                          // swipe into on a screen with only three pets.
                          looping: true,
                          viewportFraction: _viewportFraction,
                          fontFunction: fontFunction,
                          textDirection: textDirection,
                          initialType: _selectedPet,
                          onSelected: (type) => _selectedPet = type,
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

  Widget _buildQuestion({
    required AppLocalizations strings,
    required Locale locale,
    required TextDirection textDirection,
    required bool usePixelFont,
  }) {
    final text = switch (_phase) {
      FirstLaunchPhase.language => strings.onboardingLanguageQuestion,
      FirstLaunchPhase.pet => strings.onboardingPetQuestion,
      // The login step carries its own heading, so the row above the pets is
      // left empty rather than repeating it.
      FirstLaunchPhase.login => '',
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: Text(
          text,
          // Keyed on the text so the switcher cross-fades when the language
          // changes but not when an unrelated rebuild happens.
          key: ValueKey(text),
          textDirection: textDirection,
          textAlign: TextAlign.center,
          style: onboardingTextStyle(
            usePixelFont: usePixelFont,
            locale: locale,
            fontSize: 12,
            color: AppTheme.retroDark,
          ),
        ),
      ),
    );
  }

  Widget _buildPanel({
    required List<Language> languages,
    required AppLocalizations strings,
    required Locale locale,
    required TextDirection textDirection,
    required bool usePixelFont,
  }) {
    switch (_phase) {
      case FirstLaunchPhase.language:
        return LanguagePanel(
          languages: languages,
          selected: _selectedLanguage,
          confirmLabel: strings.onboardingLanguageConfirm,
          locale: locale,
          textDirection: textDirection,
          usePixelFont: usePixelFont,
          onLanguageTapped: _onLanguageTapped,
          onConfirm: _selectedLanguage == null ? null : _confirmLanguage,
        );
      case FirstLaunchPhase.pet:
        // The pets themselves are the body of this step — they are already on
        // screen, centred and full size. All that is left under them is the
        // button that adopts whichever one settled in the middle.
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              RetroButton(
                label: strings.onboardingPetConfirm,
                locale: locale,
                textDirection: textDirection,
                usePixelFont: usePixelFont,
                onTap: _confirmPet,
              ),
            ],
          ),
        );
      case FirstLaunchPhase.login:
        final account = context.read<AccountService?>();
        // _confirmPet only reaches this phase when the service exists.
        if (account == null) return const SizedBox.shrink();
        return LoginPanel(
          account: account,
          strings: strings,
          locale: locale,
          textDirection: textDirection,
          usePixelFont: usePixelFont,
          onDone: _finishOpening,
        );
    }
  }
}
