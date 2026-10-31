"""Builds the Pyrewing boss sprites from the source art.

    python gen_dragon.py            # writes assets/svgs/dragon_boss*.svg
    python gen_dragon.py --map      # prints the face as a cell map
    python gen_dragon.py --map --open

The owner's dragon from `pyrewing-editable.svg`: layered paths on a 1-unit
grid, coloured by the CSS classes in the file's own <style>. It replaced
`fiery-dragon-boss.svg` on 2026-10-01. It is drawn about 225 cells wide,
half as fine again as the set, so it is shrunk to the set's 148 (see
`lib_boss.shrink`): its pixels then match the other bosses' and its arena's,
and its outline is as heavy as theirs. lib_boss.py says why the sprite is
rebuilt rather than drawn as-is. Emits, the way gen_mossback.py does:

  dragon_boss.svg       the sprite, one traced path per colour, each painted
                        over the union of everything above it -- no seams.
  dragon_boss_open.svg  the same with its jaws open, for the roar and the
                        fire. Swapped in whole.

A run prints the numbers `trial_boss.dart` takes from the art: its cell
grid, the middle of the open jaws, and the middle of the belly, where hits
land.

Re-run after any edit to the source art; never hand-edit the outputs.

SUPERSEDED 2026-10-09 by gen_dragon.py, which builds the game's dragon from
`pyrewing-larger-wings-symmetric.svg`. Kept so the earlier dragon can be
rebuilt: running this writes the same dragon_boss*.svg outputs, and the
numbers in trial_boss.dart and dragon_pieces.dart would then need setting
back (148 x 115 cells, jaws on cell 130, eyes in `_EyelidPainter`).
"""
import sys

import lib_boss
from lib_boss import MOUTH, TONGUE

SRC = 'pyrewing-editable.svg'

# The set's width in cells: what the old dragon was drawn at, and within a
# few cells of the tortoise and the sphinx.
CELLS_W = 148

K = '#14120e'        # outline, eyes, mouth line
BODY = '#a84c3e'     # brick-red body and wing bones
SHADOW = '#6f3238'   # wing membranes and the far side of everything
GOLD = '#f3bd60'     # muzzle, belly plates, the flame's middle
CREAM = '#f7e3ac'    # horns, claws, fangs, the flame's core
EMBER = '#dc5a30'    # the flame's edge

ORDER = [K, BODY, SHADOW, GOLD, CREAM, EMBER, MOUTH, TONGUE]
LETTERS = {K: 'K', BODY: 'o', SHADOW: 's', GOLD: 'y', CREAM: 'c',
           EMBER: 'e', MOUTH: 'R', TONGUE: 'G'}

# The jaws: an oval over the mouth line, in the gold of the muzzle.
CX, CY, RX, RY = 130, 46.5, 8.5, 3.5
# The fangs, each three cells wide, hanging from the roof of the open jaws
# where the closed mouth shows them.
FANGS = (124, 133)


def _inside(x, y, rx, ry):
    return ((x + 0.5 - CX) / rx) ** 2 + ((y + 0.5 - CY) / ry) ** 2 <= 1


def open_jaws(g):
    """The roar: [g] with the jaws open.

    The closed mouth is a line across the gold muzzle with two cream fangs
    hanging from it, under the eyes and inside the muzzle's outline. The
    open pose draws over it an oval maw in the art's two-cell outline, with
    a fang down from each side of its roof and the tongue along its floor.
    """
    out = dict(g)
    ring = [(x, y) for x in range(int(CX - RX) - 3, int(CX + RX) + 4)
            for y in range(int(CY - RY) - 3, int(CY + RY) + 4)
            if _inside(x, y, RX + 2, RY + 2)]
    for cell in ring:
        assert g.get(cell) in (K, GOLD, CREAM), (cell, g.get(cell))
        out[cell] = K
    for x, y in ring:
        if _inside(x, y, RX, RY):
            out[(x, y)] = TONGUE if y >= CY + 1.5 else MOUTH
    for x0 in FANGS:
        for dx, length in ((0, 2), (1, 3), (2, 2)):
            rows = [y for (cx, y), f in out.items()
                    if cx == x0 + dx and f in (MOUTH, TONGUE)]
            for i in range(length):
                out[(x0 + dx, min(rows) + i)] = CREAM
    return out


def belly(g):
    """The middle of the belly plates: the gold under the head, right of the
    tail's flame."""
    cells = [(x, y) for (x, y), f in g.items()
             if f == GOLD and y > 55 and x > 80]
    xs = [x for x, _ in cells]
    ys = [y for _, y in cells]
    return (min(xs) + max(xs) + 1) / 2, (min(ys) + max(ys) + 1) / 2


if __name__ == '__main__':
    closed = lib_boss.shrink(lib_boss.class_grid(SRC), CELLS_W, K)
    if '--map' in sys.argv:
        lib_boss.print_map(open_jaws(closed) if '--open' in sys.argv
                           else closed, LETTERS, 100, 25, 148, 60)
        sys.exit(0)

    opened = open_jaws(closed)
    x0, y0, x1, y1 = lib_boss.bounds(closed)
    assert lib_boss.bounds(opened) == (x0, y0, x1, y1)
    w, h = x1 - x0, y1 - y0
    for name, cells in (('dragon_boss.svg', closed),
                        ('dragon_boss_open.svg', opened)):
        lib_boss.write(name, lib_boss.emit(cells, ORDER, x0, y0, w, h))
    bx, by = belly(closed)
    # CX is a coordinate, not a cell: the jaws' middle already.
    print('viewBox 0 0 %d %d; mouth x %.1f' % (w, h, CX - x0))
    print('belly %.1f, %.1f -> hitX %.2f, hitY %.2f'
          % (bx - x0, by - y0, (bx - x0) / w, (by - y0) / h))
