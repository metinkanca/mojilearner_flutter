import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../constants/theme.dart';
import '../l10n/app_localizations.dart';
import '../providers/language_provider.dart';
import '../providers/mistakes_provider.dart';
import '../providers/vocab_provider.dart';
import '../utils/fonts.dart';
import '../utils/rtl_locale.dart';

/// The two places to go back over what the player has learned, behind the
/// home screen's study button: the review queue and the list of mistakes.
///
/// Neither has a tab of its own any more, so this is how both are reached.
/// Each row carries its count as a bare number, the one notification idiom
/// that needs no translating and cannot overflow in a long language.
class StudyHub extends StatelessWidget {
  const StudyHub({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) => const StudyHub(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textDirection =
        textDirectionForLocale(Localizations.localeOf(context));
    final due = context.watch<VocabProvider>().dueCount(
          languageCode:
              context.watch<LanguageProvider>().targetLanguage?.code,
        );
    final mistakes = context.watch<MistakesProvider>().mistakes.length;

    // Popped before going, so backing out of either lands on home rather than
    // on this dialog.
    void go(String route) {
      final router = GoRouter.of(context);
      Navigator.of(context).pop();
      router.pushNamed(route);
    }

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: AppTheme.retroDark, width: 4),
        borderRadius: BorderRadius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StudyRow(
              key: const ValueKey('study-review'),
              icon: LucideIcons.layers,
              color: AppTheme.retroAccent,
              label: l10n.review,
              count: due,
              textDirection: textDirection,
              onTap: () => go('review'),
            ),
            const SizedBox(height: 12),
            _StudyRow(
              key: const ValueKey('study-mistakes'),
              icon: LucideIcons.circleAlert,
              color: AppTheme.retroPrimary,
              label: l10n.mistakes,
              count: mistakes,
              textDirection: textDirection,
              onTap: () => go('mistakes'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudyRow extends StatelessWidget {
  const _StudyRow({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.count,
    required this.textDirection,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final int count;
  final TextDirection textDirection;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      container: true,
      excludeSemantics: true,
      label: count == 0 ? label : '$label: $count',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.retroLight,
            border: Border.all(color: AppTheme.retroDark, width: 3),
            boxShadow: const [
              BoxShadow(
                  color: AppTheme.retroDark, offset: Offset(3, 3), blurRadius: 0)
            ],
          ),
          child: Row(
            textDirection: textDirection,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color,
                  border: Border.all(color: AppTheme.retroDark, width: 3),
                ),
                child: Icon(icon, color: AppTheme.retroDark, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  textDirection: textDirection,
                  style: AppFonts.pressStart2p(
                    fontSize: 10,
                    color: AppTheme.retroDark,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppTheme.retroDark, width: 2),
                  ),
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    textDirection: TextDirection.ltr,
                    style: AppFonts.pressStart2p(
                      fontSize: 8,
                      color: AppTheme.retroDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
