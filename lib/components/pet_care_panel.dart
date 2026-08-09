import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../constants/shop.dart';
import '../constants/theme.dart';
import '../l10n/app_localizations.dart';
import '../providers/character_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/fonts.dart';
import '../utils/pet_care_status.dart';
import '../utils/shop_item_localizer.dart';
import '../utils/rtl_locale.dart';

/// The pet's status, and the actions that change it.
///
/// This is deliberately not a read-only stat screen. Until now the player
/// could buy food and never eat it — [CharacterProvider.consumeFoodAndAnimate]
/// had no caller outside tests — so hunger only ever rose and every pet
/// drifted permanently sick. Showing bars without the verb would just let
/// people watch that happen, so feeding lives here.
class PetCarePanel extends StatelessWidget {
  const PetCarePanel({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) => const PetCarePanel(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final fontFunction = AppFonts.getFont(settings.usePixelFont);
    final locale = Localizations.localeOf(context);
    final textDirection = textDirectionForLocale(locale);

    return Consumer<CharacterProvider>(
      builder: (context, character, _) {
        final readings = PetCareStatus.readings(
          hunger: character.hunger,
          happiness: character.happiness,
          health: character.health,
        );
        final concern = PetCareStatus.topConcern(
          hunger: character.hunger,
          happiness: character.happiness,
          health: character.health,
        );

        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          shape: const RoundedRectangleBorder(
            side: BorderSide(color: AppTheme.retroDark, width: 4),
            borderRadius: BorderRadius.zero,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.careTitle.toUpperCase(),
                    textDirection: textDirection,
                    textAlign: TextAlign.center,
                    style: fontFunction(
                      fontSize: 12,
                      color: AppTheme.retroDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    concern == null
                        ? l10n.careAllWell
                        : _headline(l10n, concern.stat),
                    textDirection: textDirection,
                    textAlign: TextAlign.center,
                    style: fontFunction(
                      fontSize: 8,
                      height: 1.6,
                      color: concern == null
                          ? AppTheme.retroGrassDark
                          : AppTheme.retroPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  for (final reading in readings) ...[
                    _StatBar(
                      label: _statLabel(l10n, reading.stat),
                      reading: reading,
                      fontFunction: fontFunction,
                      textDirection: textDirection,
                    ),
                    const SizedBox(height: 12),
                  ],

                  // The sick tax is otherwise invisible: rewards silently
                  // halve with nothing on screen to explain it.
                  if (character.isSick) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.retroAccent.withValues(alpha: 0.25),
                        border:
                            Border.all(color: AppTheme.retroDark, width: 3),
                      ),
                      child: Text(
                        l10n.careSickPenalty,
                        textDirection: textDirection,
                        style: fontFunction(
                          fontSize: 8,
                          height: 1.6,
                          color: AppTheme.retroDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  _FeedSection(
                    fontFunction: fontFunction,
                    textDirection: textDirection,
                  ),

                  const SizedBox(height: 16),
                  _PetButton(
                    fontFunction: fontFunction,
                    textDirection: textDirection,
                  ),

                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.retroLight,
                        border:
                            Border.all(color: AppTheme.retroDark, width: 3),
                      ),
                      child: Text(
                        l10n.careClose.toUpperCase(),
                        textDirection: textDirection,
                        textAlign: TextAlign.center,
                        style: fontFunction(
                          fontSize: 10,
                          color: AppTheme.retroDark,
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
      },
    );
  }

  static String _statLabel(AppLocalizations l10n, CareStat stat) {
    switch (stat) {
      case CareStat.fullness:
        return l10n.careStatFullness;
      case CareStat.happiness:
        return l10n.careStatHappiness;
      case CareStat.health:
        return l10n.careStatHealth;
    }
  }

  static String _headline(AppLocalizations l10n, CareStat stat) {
    switch (stat) {
      case CareStat.fullness:
        return l10n.careNeedHungry;
      case CareStat.happiness:
        return l10n.careNeedLonely;
      case CareStat.health:
        return l10n.careNeedSick;
    }
  }
}

/// A labelled segmented bar. Colour tracks severity so a glance is enough.
class _StatBar extends StatelessWidget {
  const _StatBar({
    required this.label,
    required this.reading,
    required this.fontFunction,
    required this.textDirection,
  });

  final String label;
  final CareReading reading;
  final TextStyle Function({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    TextDecoration? decoration,
    double? letterSpacing,
    FontStyle? fontStyle,
  }) fontFunction;
  final TextDirection textDirection;

  Color get _color {
    switch (reading.severity) {
      case CareSeverity.critical:
        return AppTheme.retroPrimary;
      case CareSeverity.low:
        return AppTheme.retroOrange;
      case CareSeverity.fine:
        return AppTheme.retroGrass;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                textDirection: textDirection,
                style: fontFunction(
                  fontSize: 8,
                  color: AppTheme.retroDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              '${reading.value}%',
              textDirection: TextDirection.ltr,
              style: fontFunction(fontSize: 8, color: AppTheme.retroDark),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 16,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppTheme.retroDark, width: 3),
          ),
          child: FractionallySizedBox(
            widthFactor: reading.fraction,
            alignment: textDirection == TextDirection.rtl
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: Container(color: _color),
          ),
        ),
      ],
    );
  }
}

/// Lists the food the player owns and lets them use it.
class _FeedSection extends StatelessWidget {
  const _FeedSection({
    required this.fontFunction,
    required this.textDirection,
  });

  final TextStyle Function({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    TextDecoration? decoration,
    double? letterSpacing,
    FontStyle? fontStyle,
  }) fontFunction;
  final TextDirection textDirection;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final character = context.watch<CharacterProvider>();

    // Inventory holds ids and may contain duplicates; collapse to counts so
    // three apples read as "Apple x3" rather than three identical rows.
    final counts = <String, int>{};
    for (final id in character.inventory) {
      counts[id] = (counts[id] ?? 0) + 1;
    }

    final entries = counts.entries
        .map((e) => MapEntry(_itemById(e.key), e.value))
        .where((e) => e.key != null)
        .map((e) => MapEntry(e.key!, e.value))
        .where((e) => e.key.hungerRestore != null ||
            e.key.happinessRestore != null ||
            e.key.healthRestore != null)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.careFeedTitle.toUpperCase(),
          textDirection: textDirection,
          style: fontFunction(
            fontSize: 9,
            color: AppTheme.retroDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (entries.isEmpty) ...[
          Text(
            l10n.careNoFood,
            textDirection: textDirection,
            style: fontFunction(
              fontSize: 8,
              height: 1.6,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
              context.pushNamed('shop');
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.retroSkyLight,
                border: Border.all(color: AppTheme.retroDark, width: 3),
              ),
              child: Text(
                l10n.careGoToShop.toUpperCase(),
                textDirection: textDirection,
                textAlign: TextAlign.center,
                style: fontFunction(
                  fontSize: 9,
                  color: AppTheme.retroDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ] else
          for (final entry in entries) ...[
            _FoodRow(
              item: entry.key,
              count: entry.value,
              fontFunction: fontFunction,
              textDirection: textDirection,
            ),
            const SizedBox(height: 8),
          ],
      ],
    );
  }

  static ShopItem? _itemById(String id) {
    for (final item in shopItems) {
      if (item.id == id) return item;
    }
    return null;
  }
}

class _FoodRow extends StatelessWidget {
  const _FoodRow({
    required this.item,
    required this.count,
    required this.fontFunction,
    required this.textDirection,
  });

  final ShopItem item;
  final int count;
  final TextStyle Function({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    TextDecoration? decoration,
    double? letterSpacing,
    FontStyle? fontStyle,
  }) fontFunction;
  final TextDirection textDirection;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = ShopItemLocalizer.localizedName(l10n, item);

    return GestureDetector(
      onTap: () {
        // Puts the food in the player's hand and gets out of the way, rather
        // than feeding directly: the pet's anticipation and chew animations
        // play on the sprite behind this dialog, so feeding from here would
        // hide the whole payoff behind an opaque panel.
        final character =
            Provider.of<CharacterProvider>(context, listen: false);
        if (!character.pickUpFood(item.id)) return;
        Navigator.of(context).pop();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.retroLight,
          border: Border.all(color: AppTheme.retroDark, width: 3),
        ),
        child: Row(
          children: [
            Text(item.icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                count > 1 ? '$name x$count' : name,
                textDirection: textDirection,
                style: fontFunction(
                  fontSize: 9,
                  color: AppTheme.retroDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // What this actually does, in the same units as the bars above.
            if (item.hungerRestore != null)
              Text(
                '+${item.hungerRestore}%',
                textDirection: TextDirection.ltr,
                style: fontFunction(
                  fontSize: 8,
                  color: AppTheme.retroGrassDark,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PetButton extends StatelessWidget {
  const _PetButton({
    required this.fontFunction,
    required this.textDirection,
  });

  final TextStyle Function({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    TextDecoration? decoration,
    double? letterSpacing,
    FontStyle? fontStyle,
  }) fontFunction;
  final TextDirection textDirection;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final character = context.watch<CharacterProvider>();
    final canEarn = character.canEarnFromPetting;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: canEarn ? character.petThePet : null,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: canEarn ? AppTheme.retroGrass : AppTheme.retroLight,
              border: Border.all(color: AppTheme.retroDark, width: 3),
            ),
            child: Text(
              l10n.carePlay.toUpperCase(),
              textDirection: textDirection,
              textAlign: TextAlign.center,
              style: fontFunction(
                fontSize: 10,
                color: canEarn ? AppTheme.retroDark : Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        // Explains a button that would otherwise look broken.
        if (!canEarn) ...[
          const SizedBox(height: 6),
          Text(
            l10n.carePlayCooldown,
            textDirection: textDirection,
            textAlign: TextAlign.center,
            style: fontFunction(
              fontSize: 7,
              height: 1.6,
              color: Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }
}
