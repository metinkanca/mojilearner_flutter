import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../components/character_sprite.dart';
import '../constants/accessories.dart';
import '../constants/bond.dart';
import '../constants/shop.dart';
import '../constants/theme.dart';
import '../l10n/app_localizations.dart';
import '../providers/character_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/user_provider.dart';
import '../utils/accessory_ownership.dart';
import '../utils/bond_context.dart';
import '../utils/fonts.dart';
import '../utils/shop_item_localizer.dart';
import '../utils/pet_recolor.dart';
import '../utils/rtl_locale.dart';

/// The shared subset of the two retro font helpers (pixel / mono).
typedef _FontFn = TextStyle Function({
  double? fontSize,
  FontWeight? fontWeight,
  Color? color,
  double? letterSpacing,
});

/// Wardrobe / closet: dress the pet with accessories and recolour its coat
/// and eyes. One accessory per slot (hat / neck / face); tapping an equipped
/// item takes it off.
class WardrobeScreen extends StatelessWidget {
  const WardrobeScreen({super.key});

  String _iconAsset(AccessoryDef a) => 'assets/svgs/acc_${a.id}_icon.svg';

  String _slotLabel(AppLocalizations l10n, String slot) {
    switch (slot) {
      case AccessorySlots.hat:
        return l10n.slotHat;
      case AccessorySlots.neck:
        return l10n.slotNeck;
      case AccessorySlots.face:
        return l10n.slotFace;
      default:
        return slot;
    }
  }

  @override
  Widget build(BuildContext context) {
    final characterProvider = Provider.of<CharacterProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final textDirection = textDirectionForLocale(locale);

    final _FontFn fontFunction = settingsProvider.usePixelFont
        ? AppFonts.pressStart2p
        : AppFonts.spaceMono;

    return Scaffold(
      backgroundColor: AppTheme.wardrobeWood,
      appBar: AppBar(
        title: Text(
          l10n.wardrobeTitle.toUpperCase(),
          textDirection: textDirection,
          textAlign: TextAlign.center,
          style: fontFunction(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.retroLight,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _RetroIconButton(
          icon: Icons.arrow_back,
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final previewSize =
                (constraints.maxWidth * 0.62).clamp(140.0, 240.0);
            final previewFrameHeight = (previewSize + 24).clamp(170.0, 280.0);

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Mirror: live pet preview against the closet interior.
                  _WardrobeMirror(
                    width: previewSize,
                    height: previewFrameHeight,
                  ),
                  const SizedBox(height: 20),
                  // Colours first — coat and eyes. Only the pets split into
                  // layers can be recoloured; an unrigged pet is one flat
                  // sprite with no separable coat, so it gets no pickers.
                  if (isLayeredPet(characterProvider.currentCharacterType)) ...[
                    _WardrobePanel(
                      title: l10n.bodyTailColor,
                      fontFunction: fontFunction,
                      textDirection: textDirection,
                      child: _SwatchRow(
                        swatches: kBodySwatches,
                        selectedHex: characterProvider.design.bodyColor,
                        onPick: characterProvider.updateBodyColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _EyePanel(
                      provider: characterProvider,
                      fontFunction: fontFunction,
                      textDirection: textDirection,
                      l10n: l10n,
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Accessory slots, each a "shelf" of the closet.
                  for (final slot in AccessorySlots.all) ...[
                    _SlotSection(
                      slot: slot,
                      title: _slotLabel(l10n, slot),
                      iconAssetFor: _iconAsset,
                      fontFunction: fontFunction,
                      textDirection: textDirection,
                    ),
                    const SizedBox(height: 16),
                  ],
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Back/action button with the app's retro raised-border treatment.
class _RetroIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _RetroIconButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.wardrobeShelf,
        border: Border.all(color: AppTheme.retroDark, width: 3),
        boxShadow: const [
          BoxShadow(
            color: AppTheme.retroDark,
            offset: Offset(2, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: AppTheme.retroDark, size: 20),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        // No round ink ripple inside the square retro frame.
        style: const ButtonStyle(
          overlayColor: WidgetStatePropertyAll(Colors.transparent),
        ),
      ),
    );
  }
}

/// The closet mirror: dark interior backing, brass-ish frame, pet centred.
class _WardrobeMirror extends StatelessWidget {
  final double width;
  final double height;

  const _WardrobeMirror({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.wardrobeInterior,
        border: Border.all(color: AppTheme.retroDark, width: 4),
        boxShadow: const [
          BoxShadow(
            color: AppTheme.retroDark,
            offset: Offset(5, 5),
            blurRadius: 0,
          ),
        ],
      ),
      child: Center(
        child: SizedBox(
          width: width,
          height: height,
          child: CharacterSprite(
            width: width,
            height: height,
            fit: BoxFit.contain,
            motionProfile: CharacterMotionProfile.full,
          ),
        ),
      ),
    );
  }
}

/// A titled wooden panel — the shared container for shelves and colour pickers.
class _WardrobePanel extends StatelessWidget {
  final String title;
  final _FontFn fontFunction;
  final TextDirection textDirection;
  final Widget child;

  const _WardrobePanel({
    required this.title,
    required this.fontFunction,
    required this.textDirection,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.wardrobeWoodLight,
        border: Border.all(color: AppTheme.retroDark, width: 4),
        boxShadow: const [
          BoxShadow(
            color: AppTheme.retroDark,
            offset: Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drawer-front style label bar.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: AppTheme.wardrobeShelf,
              border: Border(
                bottom: BorderSide(color: AppTheme.retroDark, width: 4),
              ),
            ),
            child: Text(
              title.toUpperCase(),
              textDirection: textDirection,
              style: fontFunction(
                fontSize: 10,
                color: AppTheme.retroDark,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _SlotSection extends StatelessWidget {
  final String slot;
  final String title;
  final String Function(AccessoryDef) iconAssetFor;
  final _FontFn fontFunction;
  final TextDirection textDirection;

  const _SlotSection({
    required this.slot,
    required this.title,
    required this.iconAssetFor,
    required this.fontFunction,
    required this.textDirection,
  });

  @override
  Widget build(BuildContext context) {
    final equippedId = context.select<CharacterProvider, String?>(
      (p) => p.equippedInSlot(slot),
    );
    // Watched rather than selected: unlockedItems hands back the provider's
    // own set, so its identity never changes and a select would never notice
    // a purchase.
    final character = context.watch<CharacterProvider>();
    final coins = context.select<UserProvider, int>((p) => p.coins);
    final stage = petStageOf(context);

    final statuses = AccessoryOwnership.statusesForSlot(
      slot,
      unlockedItemIds: character.unlockedItems,
      stage: stage,
      coins: coins,
    );

    return _WardrobePanel(
      title: title,
      fontFunction: fontFunction,
      textDirection: textDirection,
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final status in statuses)
            _AccessoryTile(
              status: status,
              equipped: equippedId == status.accessory.id,
              iconAsset: iconAssetFor(status.accessory),
              fontFunction: fontFunction,
              textDirection: textDirection,
              onTap: () => _handleTap(context, status, stage),
            ),
        ],
      ),
    );
  }

  /// One tap, three meanings: wear it, buy it, or say why neither.
  void _handleTap(
    BuildContext context,
    AccessoryStatus status,
    PetStage stage,
  ) {
    final l10n = AppLocalizations.of(context)!;

    if (status.isOwned) {
      context.read<CharacterProvider>().equipAccessory(
            status.accessory.id,
            stage: stage,
          );
      return;
    }

    if (status.isBondLocked) {
      _showWardrobeDialog(
        context: context,
        fontFunction: fontFunction,
        textDirection: textDirection,
        title: accessoryName(l10n, status.accessory),
        message: l10n.accessoryEarnedNotSold,
        detail: l10n.accessoryUnlocksAt(
          petStageName(l10n, status.accessory.requiredStage!),
        ),
      );
      return;
    }

    _confirmPurchase(context, status, stage);
  }

  void _confirmPurchase(
    BuildContext context,
    AccessoryStatus status,
    PetStage stage,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final item = accessoryShopItemById(status.accessory.id);
    if (item == null) return;

    if (!status.affordable) {
      _showWardrobeDialog(
        context: context,
        fontFunction: fontFunction,
        textDirection: textDirection,
        title: accessoryName(l10n, status.accessory),
        message: l10n.notEnoughCoinsMessage,
        detail: '${AccessoryTileIcons.coin} ${item.price}',
      );
      return;
    }

    final character = context.read<CharacterProvider>();
    final user = context.read<UserProvider>();

    showDialog<void>(
      context: context,
      builder: (dialogContext) => _BuyDialog(
        status: status,
        price: item.price,
        fontFunction: fontFunction,
        textDirection: textDirection,
        onConfirm: () async {
          Navigator.of(dialogContext).pop();
          final bought = await character.purchaseItem(item, user);
          // Straight onto the pet: the reason to buy it was to see it worn,
          // and making the player find and tap it again adds nothing.
          if (bought) {
            character.equipAccessory(status.accessory.id, stage: stage);
          }
        },
      ),
    );
  }
}

/// Glyphs used on the tiles. Kept together so the wardrobe and the shop can be
/// checked against each other at a glance.
class AccessoryTileIcons {
  AccessoryTileIcons._();

  static const String coin = '\u{1FA99}';
  static const String locked = '\u{1F512}';
}

/// Accessory display name, routed through the shared shop localizer wherever
/// there is a shop entry so the two screens cannot drift on what a hat is
/// called.
String accessoryName(AppLocalizations l10n, AccessoryDef accessory) {
  final item = accessoryShopItemById(accessory.id);
  if (item != null) return ShopItemLocalizer.localizedName(l10n, item);
  switch (accessory.id) {
    case 'cap':
      return l10n.accessoryCapName;
    case 'tophat':
      return l10n.accessoryTopHatName;
    case 'crown':
      return l10n.accessoryCrownName;
    case 'mortarboard':
      return l10n.accessoryMortarboardName;
    case 'medal':
      return l10n.accessoryMedalName;
    default:
      return accessory.name;
  }
}

/// Small retro dialog for the two "you cannot have this yet" answers.
void _showWardrobeDialog({
  required BuildContext context,
  required _FontFn fontFunction,
  required TextDirection textDirection,
  required String title,
  required String message,
  String? detail,
}) {
  showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: AppTheme.retroLight,
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: AppTheme.retroDark, width: 4),
        borderRadius: BorderRadius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title.toUpperCase(),
              textDirection: textDirection,
              textAlign: TextAlign.center,
              style: fontFunction(
                fontSize: 11,
                color: AppTheme.retroDark,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textDirection: textDirection,
              textAlign: TextAlign.center,
              style: fontFunction(fontSize: 8, color: AppTheme.retroDark),
            ),
            if (detail != null) ...[
              const SizedBox(height: 8),
              Text(
                detail,
                textDirection: textDirection,
                textAlign: TextAlign.center,
                style: fontFunction(
                  fontSize: 8,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class _BuyDialog extends StatelessWidget {
  final AccessoryStatus status;
  final int price;
  final _FontFn fontFunction;
  final TextDirection textDirection;
  final Future<void> Function() onConfirm;

  const _BuyDialog({
    required this.status,
    required this.price,
    required this.fontFunction,
    required this.textDirection,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      backgroundColor: AppTheme.retroLight,
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: AppTheme.retroDark, width: 4),
        borderRadius: BorderRadius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              status.accessory.icon,
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 12),
            Text(
              accessoryName(l10n, status.accessory).toUpperCase(),
              textDirection: textDirection,
              textAlign: TextAlign.center,
              style: fontFunction(
                fontSize: 11,
                color: AppTheme.retroDark,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${AccessoryTileIcons.coin} $price',
              textDirection: textDirection,
              style: fontFunction(
                fontSize: 10,
                color: AppTheme.retroDark,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _DialogButton(
                    label: l10n.cancel.toUpperCase(),
                    color: AppTheme.retroLight,
                    fontFunction: fontFunction,
                    textDirection: textDirection,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DialogButton(
                    label: l10n.buy.toUpperCase(),
                    color: AppTheme.retroGrass,
                    fontFunction: fontFunction,
                    textDirection: textDirection,
                    onTap: onConfirm,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  final String label;
  final Color color;
  final _FontFn fontFunction;
  final TextDirection textDirection;
  final VoidCallback onTap;

  const _DialogButton({
    required this.label,
    required this.color,
    required this.fontFunction,
    required this.textDirection,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: AppTheme.retroDark, width: 3),
          boxShadow: const [
            BoxShadow(
              color: AppTheme.retroDark,
              offset: Offset(3, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: Text(
          label,
          textDirection: textDirection,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: fontFunction(
            fontSize: 8,
            color: AppTheme.retroDark,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _AccessoryTile extends StatelessWidget {
  final AccessoryStatus status;
  final bool equipped;
  final String iconAsset;
  final _FontFn fontFunction;
  final TextDirection textDirection;
  final VoidCallback onTap;

  const _AccessoryTile({
    required this.status,
    required this.equipped,
    required this.iconAsset,
    required this.fontFunction,
    required this.textDirection,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locked = !status.isOwned;

    // The footer is rendered at a fixed height whether or not it has anything
    // to say. Letting it collapse for owned items would make buying one
    // reflow every shelf below it.
    final String footer;
    if (status.isForSale) {
      footer = '${AccessoryTileIcons.coin} ${status.accessory.price}';
    } else if (status.isBondLocked) {
      footer = '${AccessoryTileIcons.locked} '
          '${petStageName(l10n, status.accessory.requiredStage!)}';
    } else {
      footer = '';
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 88,
        // Borders are painted inside the box, so the thicker equipped border
        // is offset by less padding — the tile keeps identical outer metrics
        // and equipping never reflows the grid.
        padding: EdgeInsets.all(equipped ? 6 : 8),
        decoration: BoxDecoration(
          color: equipped
              ? AppTheme.wardrobeBrass.withValues(alpha: 0.45)
              : locked
                  ? AppTheme.retroLight.withValues(alpha: 0.55)
                  : AppTheme.retroLight,
          border: Border.all(
            color: AppTheme.retroDark,
            width: equipped ? 4 : 2,
          ),
          boxShadow: const [
            BoxShadow(
              color: AppTheme.retroDark,
              offset: Offset(3, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 48,
              child: Opacity(
                // Dimmed rather than hidden: a locked item you can see is a
                // reason to keep earning, and a blank square is not.
                opacity: locked ? 0.35 : 1.0,
                child: SvgPicture.asset(iconAsset, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              accessoryName(l10n, status.accessory),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textDirection: textDirection,
              textAlign: TextAlign.center,
              style: fontFunction(
                fontSize: 7,
                color: locked ? AppTheme.textSecondary : AppTheme.retroDark,
                fontWeight: equipped ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            SizedBox(
              height: 14,
              child: Text(
                footer,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textDirection: textDirection,
                textAlign: TextAlign.center,
                style: fontFunction(
                  fontSize: 6,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single colour swatch with the retro chunky border.
class _Swatch extends StatelessWidget {
  final String hex;
  final bool selected;
  final VoidCallback onTap;

  const _Swatch({
    required this.hex,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = hexToColor(hex);
    final checkColor =
        color.computeLuminance() > 0.5 ? AppTheme.retroDark : Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color,
          border:
              Border.all(color: AppTheme.retroDark, width: selected ? 4 : 2),
          boxShadow: const [
            BoxShadow(
              color: AppTheme.retroDark,
              offset: Offset(2, 2),
              blurRadius: 0,
            ),
          ],
        ),
        child: selected ? Icon(Icons.check, size: 20, color: checkColor) : null,
      ),
    );
  }
}

class _SwatchRow extends StatelessWidget {
  final List<PetSwatch> swatches;
  final String selectedHex;
  final ValueChanged<String> onPick;

  const _SwatchRow({
    required this.swatches,
    required this.selectedHex,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final s in swatches)
          _Swatch(
            hex: s.hex,
            selected: s.hex.toLowerCase() == selectedHex.toLowerCase(),
            onTap: () => onPick(s.hex),
          ),
      ],
    );
  }
}

class _LabeledSwatches extends StatelessWidget {
  final String label;
  final String selectedHex;
  final ValueChanged<String> onPick;
  final _FontFn fontFunction;
  final TextDirection textDirection;

  const _LabeledSwatches({
    required this.label,
    required this.selectedHex,
    required this.onPick,
    required this.fontFunction,
    required this.textDirection,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          textDirection: textDirection,
          style: fontFunction(
            fontSize: 8,
            color: AppTheme.retroDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _SwatchRow(
          swatches: kEyeSwatches,
          selectedHex: selectedHex,
          onPick: onPick,
        ),
      ],
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final _FontFn fontFunction;

  const _ModeButton({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.fontFunction,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          // Padding compensates for the thicker selected border, keeping the
          // button's height fixed across states (see _AccessoryTile).
          padding: EdgeInsets.symmetric(vertical: selected ? 8 : 9),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.wardrobeBrass.withValues(alpha: 0.45)
                : AppTheme.retroLight,
            border:
                Border.all(color: AppTheme.retroDark, width: selected ? 3 : 2),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: fontFunction(
              fontSize: 8,
              color: AppTheme.retroDark,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _EyePanel extends StatelessWidget {
  final CharacterProvider provider;
  final _FontFn fontFunction;
  final TextDirection textDirection;
  final AppLocalizations l10n;

  const _EyePanel({
    required this.provider,
    required this.fontFunction,
    required this.textDirection,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final spec = provider.colorSpec;

    Widget pickers;
    switch (spec.eyeMode) {
      case EyeMode.solid:
        pickers = _LabeledSwatches(
          label: l10n.colorLabel,
          selectedHex: spec.eyeColor1,
          onPick: (hex) =>
              provider.updateEyeColors(mode: EyeMode.solid, color1: hex),
          fontFunction: fontFunction,
          textDirection: textDirection,
        );
        break;
      case EyeMode.heterochromia:
        pickers = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _LabeledSwatches(
              label: l10n.leftEye,
              selectedHex: spec.eyeColor1,
              onPick: (hex) => provider.updateEyeColors(
                mode: EyeMode.heterochromia,
                color1: hex,
                color2: spec.eyeColor2,
              ),
              fontFunction: fontFunction,
              textDirection: textDirection,
            ),
            const SizedBox(height: 14),
            _LabeledSwatches(
              label: l10n.rightEye,
              selectedHex: spec.eyeColor2,
              onPick: (hex) => provider.updateEyeColors(
                mode: EyeMode.heterochromia,
                color1: spec.eyeColor1,
                color2: hex,
              ),
              fontFunction: fontFunction,
              textDirection: textDirection,
            ),
          ],
        );
        break;
    }

    return _WardrobePanel(
      title: l10n.eyeColor,
      fontFunction: fontFunction,
      textDirection: textDirection,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ModeButton(
                label: l10n.eyeStyleSolid.toUpperCase(),
                selected: spec.eyeMode == EyeMode.solid,
                onTap: () => provider.updateEyeColors(
                  mode: EyeMode.solid,
                  color1: spec.eyeColor1,
                  color2: spec.eyeColor2,
                ),
                fontFunction: fontFunction,
              ),
              _ModeButton(
                label: l10n.eyeStyleOddEyed.toUpperCase(),
                selected: spec.eyeMode == EyeMode.heterochromia,
                onTap: () => provider.updateEyeColors(
                  mode: EyeMode.heterochromia,
                  color1: spec.eyeColor1,
                  color2: spec.eyeColor2,
                ),
                fontFunction: fontFunction,
              ),
            ],
          ),
          const SizedBox(height: 16),
          pickers,
        ],
      ),
    );
  }
}
