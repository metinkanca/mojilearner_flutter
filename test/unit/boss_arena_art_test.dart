import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/components/boss_trial/arena_scenery.dart';
import 'package:mojilearner_flutter/components/boss_trial/trial_boss.dart';

/// The arena art and the numbers the screen hangs it on are in two places: the
/// pictures under `assets/svgs`, cut by `art_src/gen_arena.py`, and the
/// [ArenaArt] table that says how big each one is and which of its rows are the
/// ledge and the grass. Nothing at runtime notices when those two disagree —
/// the picture just lands somewhere slightly wrong, on some screens — so the
/// checks that would be silent are made loud here.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// What a layer's own viewBox says it is.
  Future<(double, double)> canvasOf(String asset) async {
    final svg = await rootBundle.loadString(asset);
    final vb = RegExp(r'viewBox="0 0 (\d+) (\d+)"').firstMatch(svg);
    expect(vb, isNotNull, reason: '$asset has no whole-cell viewBox');
    return (double.parse(vb!.group(1)!), double.parse(vb.group(2)!));
  }

  test('every boss fights in an arena that has art', () {
    for (final boss in TrialBosses.all) {
      expect(ArenaArt.of(boss.id), isNotNull,
          reason: '${boss.name} has no arena art, so it fights on flat colour');
    }
  });

  test('every layer is the size its table says, so it lands where it is put',
      () async {
    for (final boss in TrialBosses.all) {
      final art = ArenaArt.of(boss.id)!;

      final backdrop = await canvasOf(art.backdrop);
      expect(backdrop, (art.backdropWidth, art.height),
          reason: '${art.id}: the backdrop is not the canvas the table says');

      final ground = await canvasOf(art.ground);
      expect(ground, (art.width, art.groundUnits),
          reason: '${art.id}: the grass strip is not the canvas the table says');

      if (art.ledgeUnits case final units?) {
        final ledge = await canvasOf(art.ledge);
        expect(ledge, (art.width, units),
            reason: '${art.id}: the ledge is not the canvas the table says');
      }
    }
  });

  /// The backdrop is laid out at `width * backdropWidth / width` across, so it
  /// covers the screen only while it is at least as wide as the arena. Drawn
  /// narrower it would leave the sky showing down both sides.
  test('every backdrop is wide enough to cover the arena it bleeds over', () {
    for (final boss in TrialBosses.all) {
      final art = ArenaArt.of(boss.id)!;
      expect(art.backdropWidth, greaterThanOrEqualTo(art.width),
          reason: '${art.id}: the backdrop is narrower than its own arena');
    }
  });

  /// The grass strip is anchored on the ground line and runs to the foot of
  /// the canvas; the ledge hangs off the ledge line and has to end above it.
  test('the lines the art hangs on sit where the art can reach', () {
    for (final boss in TrialBosses.all) {
      final art = ArenaArt.of(boss.id)!;
      expect(art.groundLine + art.groundUnits, art.height,
          reason: '${art.id}: the grass does not reach the foot of the arena');

      expect(boss.flies, art.ledgeLine == null,
          reason: boss.flies
              ? '${art.id} flies but its arena was given a ledge'
              : '${art.id} stands on a ledge its arena does not draw');

      if (art.ledgeLine case final line?) {
        expect(line + art.ledgeUnits!, lessThan(art.groundLine),
            reason: '${art.id}: the ledge hangs into the grass');
      }
    }
  });
}
