"""Builds the three trial arenas from the owner's art.

    python gen_arena.py            # writes assets/svgs/arena_*.svg
    python gen_arena.py --map      # prints each arena's bands and lines

The owner draws an arena on a 1-unit pixel grid in the app's own palette, to
the briefs in `mimikin_art_briefs`: the canvas is the arena in that boss's
cells, the ledge sits where that boss's ledge sits, the ground where the grass
starts. Two shapes came back. Mossback arrived as ONE whole-arena picture with
its ledge and grass painted in; Amethyst and Hoothex as the briefed backdrop
plus seamless 100-wide strips.

Both are cut into the same three layers the screen draws, because the ledge
and the grass line move with the screen while the backdrop does not:

  arena_<id>_backdrop.svg   sky and scenery, with nothing where the strips go.
                            Anchored on two rows the screen knows: the ledge
                            line and the ground line.
  arena_<id>_ledge.svg      the ledge the boss stands on, arena-wide. The
                            witch flies, so she has none.
  arena_<id>_ground.svg     the grass, arena-wide, its top edge the ground
                            line.

Strips come out as wide as the ARENA rather than the 100 they were drawn at,
so the screen can stretch one picture across instead of tiling -- the seamless
strips tile exactly at 100, so the widening is invisible.

Every layer is re-emitted through lib_boss.emit rather than copied: the source
art abuts its colours, and the arena is drawn at ~1.3x and shaken, so those
joins would show as hairlines (see deseam.py). Re-run after any new art; never
hand-edit the outputs. `id` is the boss's id in trial_boss.dart, so the witch's
files are arena_witch_* though her art is named for Hoothex.

A run prints the `ArenaArt` entry each arena makes, to paste into
arena_scenery.dart: the screen hangs the pictures on those numbers, and a
picture that outgrows them just lands somewhere slightly wrong.
"""
import sys

import lib_boss

# One arena each, keyed by the boss's id in trial_boss.dart.
#
#   whole      one picture holding the whole arena, strips included
#   backdrop   scenery only, drawn wider than the arena so it can bleed
#   ledge/     seamless strips, or (row, row) bands to cut out of `whole`
#   ground
#   arena      the arena's own size in cells: what the screen scales to
ARENAS = {
    'mossback': dict(
        whole='mossback-arena-adjusted (1).svg',
        arena=(300, 540),
        ledge=(186, 213),
        ground=(471, 540),
    ),
    'amethyst': dict(
        backdrop='amethyst-balanced-backdrop.svg',
        arena=(306, 550),
        ledge='amethyst-balanced-ledge.svg',
        ground='amethyst-balanced-ground.svg',
        ledge_line=206,
    ),
    'witch': dict(
        backdrop='hoothex-backdrop.svg',
        arena=(257, 463),
        ground='hoothex-ground.svg',
    ),
    # PLACEHOLDER art from gen_lanternmaw_placeholder.py, until the owner's.
    'angler': dict(
        backdrop='lanternmaw-placeholder-backdrop.svg',
        arena=(268, 482),
        ground='lanternmaw-placeholder-ground.svg',
    ),
    # PLACEHOLDER art from gen_placeholder_arenas.py, until the owner's.
    'sphinx': dict(
        backdrop='sableth-placeholder-backdrop.svg',
        arena=(306, 550),
        ledge='sableth-placeholder-ledge.svg',
        ground='sableth-placeholder-ground.svg',
        ledge_line=206,
    ),
    'dragon': dict(
        backdrop='pyrewing-placeholder-backdrop.svg',
        arena=(306, 550),
        ledge='pyrewing-placeholder-ledge.svg',
        ground='pyrewing-placeholder-ground.svg',
        ledge_line=206,
    ),
}


def size(src):
    """The (w, h) a source SVG is drawn on, from its viewBox."""
    svg = open(lib_boss.os.path.join(lib_boss.HERE, src), encoding='utf-8')
    head = svg.read(400)
    svg.close()
    vb = lib_boss.re.search(r'viewBox="0 0 (\d+) (\d+)"', head)
    return int(vb.group(1)), int(vb.group(2))


def widen(g, src_w, w):
    """[g], a strip drawn [src_w] wide, repeated out to [w]."""
    return {(x, y): g[(x % src_w, y)] for y in {y for _, y in g}
            for x in range(w) if (x % src_w, y) in g}


def build(bid, spec):
    """The arena's three layers as {name: (grid, order, w, h)}, and its lines.

    A whole-arena picture is cut on its band rows; a backdrop plus strips is
    already cut, and only the strips are widened. Either way the ledge line is
    the row the ledge's top edge lands on, and the ground line the row the
    grass starts at -- both in backdrop cells, which is how the screen anchors
    the picture against a ledge and a grass line that move.
    """
    aw, ah = spec['arena']
    layers = {}

    if 'whole' in spec:
        src = spec['whole']
        lib_boss.CELL = 1
        g = lib_boss.grid(src)
        order = lib_boss.order(src)
        ledge_line, ground_line = spec['ledge'][0], spec['ground'][0]
        bands = [('ledge', spec['ledge']), ('ground', spec['ground'])]
        cut = dict(g)
        for name, (y0, y1) in bands:
            band = {(x, y - y0): f for (x, y), f in g.items() if y0 <= y < y1}
            layers[name] = (band, order, aw, y1 - y0)
            for cell in [c for c in cut if y0 <= c[1] < y1]:
                del cut[cell]
        layers['backdrop'] = (cut, order, aw, ah)
        return layers, aw, ledge_line, ground_line

    src = spec['backdrop']
    bw, bh = size(src)
    lib_boss.CELL = 1
    layers['backdrop'] = (lib_boss.grid(src), lib_boss.order(src), bw, bh)

    ground_line = None
    for name in ('ledge', 'ground'):
        if name not in spec:
            continue
        sw, sh = size(spec[name])
        g = widen(lib_boss.grid(spec[name]), sw, aw)
        layers[name] = (g, lib_boss.order(spec[name]), aw, sh)
        if name == 'ground':
            ground_line = bh - sh
    return layers, bw, spec.get('ledge_line'), ground_line


def table(bid, spec, layers, bw, ledge_line, ground_line):
    """The ArenaArt entry this run's numbers make, to paste into
    arena_scenery.dart -- the screen hangs the art on these, and nothing at
    run time would notice them drifting from the pictures."""
    aw, ah = spec['arena']
    rows = ["    id: '%s'," % bid, '    width: %d,' % aw, '    height: %d,' % ah,
            '    backdropWidth: %d,' % bw]
    if ledge_line is not None:
        rows += ['    ledgeLine: %d,' % ledge_line,
                 '    ledgeUnits: %d,' % layers['ledge'][3]]
    rows += ['    groundLine: %d,' % ground_line,
             '    groundUnits: %d,' % layers['ground'][3]]
    body = '\n'.join(rows)
    return '  static const ArenaArt %s = ArenaArt._(\n%s\n  );' % (bid, body)


def main():
    show = '--map' in sys.argv
    entries = []
    for bid, spec in ARENAS.items():
        layers, bw, ledge_line, ground_line = build(bid, spec)
        aw, ah = spec['arena']
        entries.append(table(bid, spec, layers, bw, ledge_line, ground_line))
        print('%s: arena %dx%d, backdrop %d wide, ledge line %s, ground line %d'
              % (bid, aw, ah, bw, ledge_line, ground_line))
        for name in ('backdrop', 'ledge', 'ground'):
            if name not in layers:
                continue
            g, order, w, h = layers[name]
            print('  %-8s %3dx%-3d %d colours' % (name, w, h, len(set(g.values()))))
            if show and name != 'backdrop':
                lib_boss.print_map(g, {f: f[1] for f in order}, 0, 0, min(w, 100), h)
            if not show:
                lib_boss.write('arena_%s_%s.svg' % (bid, name),
                               lib_boss.emit(g, order, 0, 0, w, h))

    print('\nArenaArt, for lib/components/boss_trial/arena_scenery.dart:\n')
    print('\n\n'.join(entries))


if __name__ == '__main__':
    main()
