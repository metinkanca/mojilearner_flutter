/// The drawn pieces of a boss trial's Spells round: the word stones, the spell
/// line they are cast onto, the prompt, the boss's charge, and the bolt.
///
/// Stones are the same slabs as the Catch round's rubble — the fight is still
/// in the boss's stone — while everything that belongs to the pet's spell is
/// drawn in rune light, so it is always clear which side a thing is on.
library;

import 'package:flutter/material.dart';

import 'arena_pieces.dart';
import 'trial_particles.dart';
import 'trial_skin.dart';

const Color _parchment = Color(0xFFEEC39A);
const Color _runePanel = Color(0xFF10131F);
const Color _fizzleFace = Color(0xFFF1A7A9);

/// A word stone waiting to be cast.
class WordStone extends StatelessWidget {
  const WordStone({
    super.key,
    required this.label,
    required this.style,
    required this.onTapDown,
    this.used = false,
    this.fizzling = false,
  });

  final String label;
  final TextStyle style;
  final VoidCallback onTapDown;

  /// Already cast: an empty socket is left where it lay, so the other stones
  /// never shuffle about under the player's finger.
  final bool used;

  /// Just refused: its face flashes red.
  final bool fizzling;

  static const double height = 46;

  @override
  Widget build(BuildContext context) {
    // Sized to its word. An `alignment` on a Container would stretch the
    // stone to the full width of the table and stack the stones one per row.
    final skin = TrialSkinScope.of(context);
    final stone = ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 64),
      child: SizedBox(
        height: height,
        child: Padding(
          padding: skin == null
              ? const EdgeInsets.symmetric(horizontal: 14)
              : skin.tile.padding.copyWith(top: 0, bottom: 0),
          child: Align(
            widthFactor: 1,
            child: Text(label, maxLines: 1, style: style),
          ),
        ),
      ),
    );
    return Semantics(
      button: !used,
      label: label,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(4),
              color: Colors.black.withValues(alpha: 0.25),
            ),
          ),
          Visibility(
            visible: !used,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: used ? null : (_) => onTapDown(),
              child: CustomPaint(
                // In the boss's own look when fought under one: Amethyst's
                // gems, Sableth's cartouches.
                painter: switch (skin) {
                  final skin? => SkinTilePainter(skin, skin.tile,
                      fizzling ? TileState.flashing : TileState.plain),
                  null =>
                    SlabPainter(face: fizzling ? _fizzleFace : kSlabFace),
                },
                child: stone,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The sentence as cast so far: one socket per word, filled in rune light.
class SpellLine extends StatelessWidget {
  const SpellLine({
    super.key,
    required this.slots,
    required this.filled,
    required this.style,
    this.glow = false,
    this.textDirection = TextDirection.ltr,
  });

  final int slots;
  final List<String> filled;
  final TextStyle style;

  /// The whole line lit, the moment the spell is complete.
  final bool glow;

  /// The order sockets fill in — right to left for Arabic.
  final TextDirection textDirection;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: BoxDecoration(
        color: glow ? DebrisPalette.rune : _runePanel,
        border: Border.all(color: DebrisPalette.rune, width: 3),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Directionality(
          textDirection: textDirection,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < slots; i++)
                Container(
                  height: 30,
                  constraints: const BoxConstraints(minWidth: 40),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i < filled.length
                        ? DebrisPalette.rune.withValues(alpha: 0.22)
                        : Colors.transparent,
                    border: Border.all(
                      color: i < filled.length
                          ? DebrisPalette.runeLight
                          : DebrisPalette.rune.withValues(alpha: 0.45),
                      width: 2,
                    ),
                  ),
                  child: Text(
                    i < filled.length ? filled[i] : '',
                    maxLines: 1,
                    style: style,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// What the pet means to say, in the player's own language.
class SpellPrompt extends StatelessWidget {
  const SpellPrompt({
    super.key,
    required this.label,
    required this.meaning,
    required this.labelStyle,
    required this.meaningStyle,
  });

  final String label;
  final String meaning;
  final TextStyle labelStyle;
  final TextStyle meaningStyle;

  @override
  Widget build(BuildContext context) {
    if (TrialSkinScope.of(context) case final skin?) {
      return SkinPrompt(
        skin: skin,
        label: label,
        text: meaning,
        labelStyle: labelStyle,
        textStyle: meaningStyle,
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _parchment,
        border: Border.all(color: DebrisPalette.outline, width: 3),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: labelStyle),
          const SizedBox(height: 5),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(meaning, maxLines: 1, style: meaningStyle),
            ),
          ),
        ],
      ),
    );
  }
}

/// The boss's attack charging: full is the boulder coming down.
class ChargeBar extends StatelessWidget {
  const ChargeBar({
    super.key,
    required this.charge,
    this.color = DebrisPalette.fizzle,
  });

  final double charge;

  /// What is charging: Mossback's red, the witch's brew.
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (TrialSkinScope.of(context) case final skin?) {
      return SkinBar(skin: skin, value: charge);
    }
    // In twentieths, so it fills in visible steps like everything else.
    final stepped = (charge.clamp(0.0, 1.0) * 20).floor() / 20;
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: DebrisPalette.outline, width: 3),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: stepped,
        child: Container(color: color),
      ),
    );
  }
}

/// The finished spell on its way to the boss: a square of rune light — or,
/// in the witch's [colors], her hex on its way to the pet.
class SpellBolt extends StatelessWidget {
  const SpellBolt({super.key, this.colors = rune});

  /// Its rings, outermost first.
  final List<Color> colors;

  static const List<Color> rune = [
    DebrisPalette.outline,
    DebrisPalette.rune,
    DebrisPalette.runeLight,
    Colors.white,
  ];

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _BoltPainter(colors));
}

class _BoltPainter extends CustomPainter {
  const _BoltPainter(this.colors);

  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = false;
    final s = size.shortestSide.roundToDouble();
    final u = (s / 8).roundToDouble().clamp(1.0, 8.0);
    for (var ring = 0; ring < colors.length; ring++) {
      final inset = ring * u;
      if (2 * inset >= s) break;
      canvas.drawRect(
        Rect.fromLTWH(inset, inset, s - 2 * inset, s - 2 * inset),
        paint..color = colors[ring],
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BoltPainter old) => old.colors != colors;
}
