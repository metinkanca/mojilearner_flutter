import 'package:flutter/material.dart';

import '../../../constants/theme.dart';
import '../../../providers/language_provider.dart';
import 'onboarding_text.dart';
import 'retro_button.dart';

/// The scrollable rank of languages.
const Key languageListKey = Key('first-launch-language-list');

/// The language step's body: every UI language the app ships, as one open
/// list, over a confirm button written in whichever language is currently
/// showing.
class LanguagePanel extends StatelessWidget {
  final List<Language> languages;
  final Language? selected;
  final String confirmLabel;

  /// The locale the panel is currently written in — the tapped language, or
  /// the one the attract loop is on.
  final Locale locale;
  final TextDirection textDirection;
  final bool usePixelFont;

  final ValueChanged<Language> onLanguageTapped;

  /// Null until a language is picked, which is what holds the player here.
  final VoidCallback? onConfirm;

  const LanguagePanel({
    super.key,
    required this.languages,
    required this.selected,
    required this.confirmLabel,
    required this.locale,
    required this.textDirection,
    required this.usePixelFont,
    required this.onLanguageTapped,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            // Named so tests can reach this list rather than the pets'
            // horizontal PageView, which is also a Scrollable on screen.
            key: languageListKey,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: languages.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final language = languages[index];
              return _LanguageRow(
                language: language,
                isSelected: selected?.code == language.code,
                usePixelFont: usePixelFont,
                onTap: () => onLanguageTapped(language),
              );
            },
          ),
        ),
        // Absent until a language is picked, rather than present and dead.
        // Nothing to confirm yet, and a greyed button that has never been
        // usable reads as something broken.
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: selected == null
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: RetroButton(
                    label: confirmLabel,
                    locale: locale,
                    textDirection: textDirection,
                    usePixelFont: usePixelFont,
                    onTap: onConfirm,
                  ),
                ),
        ),
      ],
    );
  }
}

/// One language in the list: its flag and its own name, in its own script.
class _LanguageRow extends StatelessWidget {
  final Language language;
  final bool isSelected;
  final bool usePixelFont;
  final VoidCallback onTap;

  const _LanguageRow({
    required this.language,
    required this.isSelected,
    required this.usePixelFont,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.retroPrimary : Colors.white,
          // Constant border width, changing colour: a border that thickened on
          // selection would resize the row and shift the whole list under the
          // finger that just tapped it.
          border: Border.all(color: AppTheme.retroDark, width: 3),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: AppTheme.retroDark,
                    offset: Offset(4, 4),
                    blurRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Text(language.flag, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                language.name,
                // Each row is drawn in its own language, so it resolves its
                // own script's fonts rather than the app's current ones.
                style: onboardingTextStyle(
                  usePixelFont: usePixelFont,
                  locale: Locale(language.code),
                  fontSize: 10,
                  color: isSelected ? Colors.white : AppTheme.retroDark,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
