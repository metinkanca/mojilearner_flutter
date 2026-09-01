import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../constants/theme.dart';
import '../../components/character_sprite.dart';
import '../../constants/ads.dart';
import '../../providers/ads_provider.dart';
import '../../providers/user_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/rtl_locale.dart';
import '../../../utils/fonts.dart';

class UsernameScreen extends StatefulWidget {
  const UsernameScreen({super.key});

  @override
  State<UsernameScreen> createState() => _UsernameScreenState();
}

class _UsernameScreenState extends State<UsernameScreen> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _birthYearController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  /// Shown under the year field once a typed year has been rejected.
  String? _birthYearError;

  @override
  void dispose() {
    _controller.dispose();
    _birthYearController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Whether both answers are filled in enough to be worth submitting.
  ///
  /// Only a shape check — whether the year is a *sensible* one is
  /// [audienceForBirthYear]'s call, and judging that before the player has
  /// finished typing would flag "20" on the way to "2015".
  bool get _canContinue =>
      _controller.text.trim().isNotEmpty &&
      _birthYearController.text.trim().length == 4;

  Future<void> _continue() async {
    final username = _controller.text.trim();
    if (username.isEmpty) return;

    final l10n = AppLocalizations.of(context)!;
    final year = int.tryParse(_birthYearController.text.trim());

    // The year is required rather than skippable. An unanswered age question
    // means the conservative ad treatment for everybody, which costs real
    // revenue on every adult — and a field most people skip is not the age
    // screen Play's Families policy is asking for either.
    if (audienceForBirthYear(year, DateTime.now()) == AdAudience.unknown) {
      setState(() => _birthYearError = l10n.onboardingBirthYearInvalid);
      return;
    }

    final adsProvider = Provider.of<AdsProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    await userProvider.updateUsername(username);
    await adsProvider.setBirthYear(year!);

    if (!mounted) return;
    context.go('/onboarding/target-language');
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
            // Progress indicator
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Text(
                    '2/8',
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
                        widthFactor: 2 / 8,
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

            const SizedBox(height: 40),
            // Scrollable so the two fields and the on-screen keyboard
            // cannot squeeze the layout past the bottom of a short
            // screen -- the name field autofocuses, so the keyboard is up
            // from the moment this screen opens.
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        children: [
                          Text(
                            l10n.whatsYourName,
                            textDirection: textDirection,
                            style: AppFonts.pressStart2p(
                              fontSize: 12,
                              color: AppTheme.retroDark,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 60),

                    // Character
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        border: Border.all(color: AppTheme.retroDark, width: 4),
                        boxShadow: const [
                          BoxShadow(
                            color: AppTheme.retroDark,
                            offset: Offset(6, 6),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: CharacterSprite(
                          width: 90,
                          height: 90,
                        ),
                      ),
                    ),

                    const SizedBox(height: 60),

                    // Input field
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border:
                              Border.all(color: AppTheme.retroDark, width: 4),
                          boxShadow: const [
                            BoxShadow(
                              color: AppTheme.retroDark,
                              offset: Offset(4, 4),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          autofocus: true,
                          textDirection: textDirection,
                          textAlign: textAlign,
                          style: AppFonts.pressStart2p(
                            fontSize: 16,
                            color: AppTheme.retroDark,
                          ),
                          decoration: InputDecoration(
                            hintText: l10n.enterYourName,
                            hintTextDirection: textDirection,
                            hintStyle: AppFonts.pressStart2p(
                              fontSize: 10,
                              color: AppTheme.retroDark.withValues(alpha: 0.5),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 20,
                            ),
                          ),
                          onSubmitted: (_) => _continue(),
                        ),
                      ),
                    ),

                    // The age question, asked here because this screen is already
                    // the "tell us about you" step -- the opening before it is one
                    // continuous flow around meeting the pet, and a form field in
                    // the middle of that would break the thing it was built to do.
                    //
                    // Neutral by design: it asks for a year rather than "are you
                    // over 13?", which signals the answer that unlocks more and is
                    // not an age screen Play's Families policy accepts.
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border:
                              Border.all(color: AppTheme.retroDark, width: 4),
                          boxShadow: const [
                            BoxShadow(
                              color: AppTheme.retroDark,
                              offset: Offset(4, 4),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _birthYearController,
                          textDirection: textDirection,
                          textAlign: textAlign,
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          style: AppFonts.pressStart2p(
                            fontSize: 16,
                            color: AppTheme.retroDark,
                          ),
                          decoration: InputDecoration(
                            hintText: l10n.onboardingBirthYearHint,
                            hintTextDirection: textDirection,
                            hintStyle: AppFonts.pressStart2p(
                              fontSize: 10,
                              color: AppTheme.retroDark.withValues(alpha: 0.5),
                            ),
                            border: InputBorder.none,
                            counterText: '',
                            errorText: _birthYearError,
                            errorStyle: AppFonts.pressStart2p(
                              fontSize: 8,
                              color: AppTheme.retroPrimary,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 20,
                            ),
                          ),
                          onChanged: (_) {
                            if (_birthYearError != null) {
                              setState(() => _birthYearError = null);
                            }
                          },
                          onSubmitted: (_) => _continue(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Text(
                        l10n.onboardingBirthYearWhy,
                        textDirection: textDirection,
                        textAlign: TextAlign.center,
                        style: AppFonts.pressStart2p(
                          fontSize: 7,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Continue button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: AnimatedBuilder(
                // Both fields are required now, so the button watches both.
                animation:
                    Listenable.merge([_controller, _birthYearController]),
                builder: (context, child) {
                  final hasText = _canContinue;
                  return GestureDetector(
                    onTap: () {
                      if (hasText) {
                        _continue();
                      }
                    },
                    child: Opacity(
                      opacity: hasText ? 1.0 : 0.5,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.retroPrimary,
                          border:
                              Border.all(color: AppTheme.retroDark, width: 4),
                          boxShadow: hasText
                              ? [
                                  const BoxShadow(
                                    color: AppTheme.retroDark,
                                    offset: Offset(4, 4),
                                    blurRadius: 0,
                                  ),
                                ]
                              : null,
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
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
