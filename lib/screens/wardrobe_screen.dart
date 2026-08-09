import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../components/character_sprite.dart';
import '../constants/accessories.dart';
import '../constants/theme.dart';
import '../l10n/app_localizations.dart';
import '../providers/character_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/fonts.dart';
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
            final previewSize = (constraints.maxWidth * 0.62).clamp(140.0, 240.0);
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
                  // Colours first — coat and eyes, cat only.
                  if (characterProvider.currentCharacterType == 'cat') ...[
                    _WardrobePanel(
                      title: l10n.bodyTailColor,
                      fontFunction: fontFunction,
                      textDirection: textDirection,
                      child: _SwatchRow(
                        swatches: kBodySwatches,
                        selectedHex: characterProvider.customization.bodyColor,
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
    final items = accessoriesForSlot(slot);
    final equippedId = context.select<CharacterProvider, String?>(
      (p) => p.equippedInSlot(slot),
    );

    return _WardrobePanel(
      title: title,
      fontFunction: fontFunction,
      textDirection: textDirection,
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final a in items)
            _AccessoryTile(
              accessory: a,
              equipped: equippedId == a.id,
              iconAsset: iconAssetFor(a),
              fontFunction: fontFunction,
              onTap: () =>
                  context.read<CharacterProvider>().equipAccessory(a.id),
            ),
        ],
      ),
    );
  }
}

class _AccessoryTile extends StatelessWidget {
  final AccessoryDef accessory;
  final bool equipped;
  final String iconAsset;
  final _FontFn fontFunction;
  final VoidCallback onTap;

  const _AccessoryTile({
    required this.accessory,
    required this.equipped,
    required this.iconAsset,
    required this.fontFunction,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
              child: SvgPicture.asset(iconAsset, fit: BoxFit.contain),
            ),
            const SizedBox(height: 6),
            Text(
              accessory.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: fontFunction(
                fontSize: 7,
                color: AppTheme.retroDark,
                fontWeight: equipped ? FontWeight.bold : FontWeight.normal,
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
