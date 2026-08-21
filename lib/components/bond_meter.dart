import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/bond.dart';
import '../constants/theme.dart';
import '../l10n/app_localizations.dart';
import '../providers/character_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/bond_context.dart';
import '../utils/bond_progress.dart';
import '../utils/fonts.dart';
import '../utils/rtl_locale.dart';

/// The three things the bond can say, in order of what the player most needs
/// to hear: that the pet noticed an absence, that their language is now the
/// thing holding the pet back, or simply how far to the next stage.
///
/// Shared by the strip and the sheet so the one-line headline and the detail
/// view can never disagree about which of the three is currently true.
String? bondCaption(
  AppLocalizations? l10n,
  PetWarmth warmth,
  BondStatus status,
) {
  if (warmth != PetWarmth.warm) {
    return warmth == PetWarmth.lonely
        ? (l10n?.bondLonely ?? 'Moji has been waiting for you')
        : (l10n?.bondMissesYou ?? 'Moji misses you');
  }
  if (status.isFluencyBlocked) {
    return l10n?.bondKeepLearning ?? 'Keep learning to grow closer';
  }
  if (!status.isFinalStage) {
    final next = petStageName(l10n, status.nextGate!.stage);
    return l10n?.bondToNextStage(status.pointsToNextStage, next) ??
        '${status.pointsToNextStage} to $next';
  }
  return null;
}

/// The bond strip: the pet's side of the relationship, on the home screen.
///
/// Deliberately unlike the care badges above it. Those appear only when
/// something is wrong and disappear when it is fixed; this is always present
/// and only ever goes up, because it is the thing the game is actually about.
///
/// It used to be a full-width bordered card carrying a label, a stage name, a
/// bar and a caption — four lines of permanent chrome for a number that moves
/// about once a week. Bond is slow data, so it earns a glance, not a panel:
/// the stage ladder shows as five pips and the rest lives one tap away in
/// [BondDetailsSheet]. That is what gives the height back to the pet.
///
/// Reads the assessed level from [CalibrationProvider] rather than letting
/// [CharacterProvider] hold a copy — proficiency is per-language and belongs
/// to the calibration flow, and two stored answers to one question drift.
class BondMeter extends StatelessWidget {
  const BondMeter({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final textDirection = textDirectionForLocale(locale);
    final settings = context.watch<SettingsProvider>();
    final fontFunction = AppFonts.getFont(settings.usePixelFont);

    final character = context.watch<CharacterProvider>();
    final status = bondStatusOf(context);

    // An absence outranks the stage name in the one line there is. A pet that
    // noticed you were gone is the more useful thing to say than the rung it
    // happens to be sitting on, and the rung is still in the pips either way.
    final isAbsent = character.warmth != PetWarmth.warm;
    final label = isAbsent
        ? (character.warmth == PetWarmth.lonely
            ? (l10n?.bondLonely ?? 'Moji has been waiting for you')
            : (l10n?.bondMissesYou ?? 'Moji misses you'))
        : petStageName(l10n, status.stage);

    return Semantics(
      button: true,
      label: '${l10n?.bondLabel ?? 'BOND'}: $label',
      // One node, so the pips do not read out as five unlabelled boxes ahead
      // of the line that actually says what they mean.
      container: true,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => BondDetailsSheet.show(context),
        child: Container(
          // A content-width pill rather than a stretched card: the strip has
          // to stay legible against both the day grass and the night grass,
          // so it keeps a backing, but it only claims the width it uses.
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppTheme.retroDark, width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StagePips(
                stage: status.stage,
                isFluencyBlocked: status.isFluencyBlocked,
              ),
              const SizedBox(width: 8),
              // Flexible so a long stage name in a long locale ellipsises
              // instead of pushing the pill past a handset.
              Flexible(
                child: Text(
                  label,
                  textDirection: textDirection,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: fontFunction(
                    fontSize: 8,
                    color:
                        isAbsent ? AppTheme.textSecondary : AppTheme.retroDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The stage ladder as five squares — one per [PetStage], filled up to the
/// stage currently held.
///
/// Pips rather than a bar because the ladder is what the player is climbing;
/// the fractional progress across the current rung is detail, and detail
/// belongs in [BondDetailsSheet]. A 4%-full bar, which is where every new
/// player starts, reads as a broken widget.
class _StagePips extends StatelessWidget {
  const _StagePips({required this.stage, required this.isFluencyBlocked});

  final PetStage stage;
  final bool isFluencyBlocked;

  @override
  Widget build(BuildContext context) {
    final filled = stage.index + 1;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < PetStage.values.length; i++) ...[
          if (i > 0) const SizedBox(width: 3),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: i < filled
                  // A fluency-blocked pet is not stalled by neglect, so the
                  // last earned pip changes colour rather than the row just
                  // looking stuck. Same signal the bar used to carry.
                  ? (isFluencyBlocked && i == filled - 1
                      ? AppTheme.retroAccent
                      : AppTheme.retroSky)
                  : Colors.grey[300],
              border: Border.all(color: AppTheme.retroDark, width: 2),
            ),
          ),
        ],
      ],
    );
  }
}

/// Everything the old bond card used to show, now behind a tap: the stage, the
/// bar across it, and whichever of the three captions is currently true.
class BondDetailsSheet extends StatelessWidget {
  const BondDetailsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) => const BondDetailsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final textDirection = textDirectionForLocale(locale);
    final settings = context.watch<SettingsProvider>();
    final fontFunction = AppFonts.getFont(settings.usePixelFont);

    final character = context.watch<CharacterProvider>();
    final status = bondStatusOf(context);
    final caption = bondCaption(l10n, character.warmth, status);

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: AppTheme.retroDark, width: 4),
        borderRadius: BorderRadius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n?.bondLabel ?? 'BOND',
              textDirection: textDirection,
              style: fontFunction(
                fontSize: 8,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              petStageName(l10n, status.stage),
              textDirection: textDirection,
              style: fontFunction(
                fontSize: 12,
                color: AppTheme.retroDark,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 12,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                border: Border.all(color: AppTheme.retroDark, width: 2),
              ),
              child: FractionallySizedBox(
                widthFactor: status.progress,
                alignment: textDirection == TextDirection.rtl
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  // A fluency-blocked bar sits full and still. Colouring it
                  // differently is what stops that reading as a bug.
                  color: status.isFluencyBlocked
                      ? AppTheme.retroAccent
                      : AppTheme.retroSky,
                ),
              ),
            ),
            if (caption != null) ...[
              const SizedBox(height: 12),
              Text(
                caption,
                textDirection: textDirection,
                style: fontFunction(
                  fontSize: 8,
                  height: 1.6,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
