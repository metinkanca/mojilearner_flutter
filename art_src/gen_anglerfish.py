"""Builds the Lanternmaw boss sprites from the source art.

    python gen_anglerfish.py            # writes assets/svgs/angler_boss*.svg
    python gen_anglerfish.py --map      # prints the mouth as a cell map

The owner's deep-sea anglerfish from `anglerfish-boss.svg`, eight colour
paths drawn straight on their pixel grid (one unit a cell, where the first
three bosses' art was on a 10-unit grid); lib_boss.py says why it is rebuilt
rather than drawn as-is. Emits, the way gen_mossback.py does:

  angler_boss.svg       the sprite, one traced path per colour, each painted
                        over the union of everything above it -- no seams.
  angler_boss_open.svg  the same with its maw gaping, for the gulp. Swapped
                        in whole.

Both come out in cell units, cropped to the art (viewBox printed on a run).
Re-run after any edit to the source art; never hand-edit the outputs.
"""
import math
import sys

import lib_boss
from lib_boss import MOUTH, TONGUE

SRC = 'anglerfish-boss.svg'
UNIT = 1

K = '#14120e'       # silhouette / outline
BODY = '#376c79'    # slate-teal body
FIN = '#58909c'     # blue fin planes (and the face)
BELLY = '#83aaa8'   # seafoam belly
SEAM = '#659194'    # belly separation
TOOTH = '#fff0c9'   # cream lantern core and teeth

LETTERS = {
    K: 'K',
    BODY: 'o',
    '#274853': 'd',   # dark fin planes
    FIN: 'b',
    BELLY: '.',
    SEAM: ',',
    '#e3b65d': 'Y',   # gold lantern
    TOOTH: 'c',
    MOUTH: 'R',
    TONGUE: 'G',
}

# The gape: an oval under the eyes, over the closed smile.
CX, CY, RX, RY = 97, 66.5, 21, 7.5


def _inside(x, y, rx, ry):
    return ((x + 0.5 - CX) / rx) ** 2 + ((y + 0.5 - CY) / ry) ** 2 <= 1


def open_maw(g):
    """The gulp: [g] with the maw dropped wide open.

    The closed mouth is a smile two cells thick, from its corners at cells
    76 and 118 on rows 61-63 down to row 67 in the middle, with two cream
    fangs hanging off it at 81-85 and 110-113. The open pose draws over all
    of it an oval gape in the art's own two-cell outline, the smile's width,
    with fangs top and bottom and the tongue in its floor. Drawn big: at the
    size it swims in the arena a cell is barely a pixel and a half.
    """
    out = dict(g)
    ring = [(x, y) for x in range(CX - RX - 3, CX + RX + 3)
            for y in range(int(CY - RY) - 3, int(CY + RY) + 4)
            if _inside(x, y, RX + 2, RY + 2)]
    for cell in ring:
        # Only ever over the fish: the gape never reaches its edge.
        assert g.get(cell) is not None, cell
        out[cell] = K
    for x, y in ring:
        if _inside(x, y, RX, RY):
            floor = y >= CY + 3 and abs(x + 0.5 - CX) < 11
            out[(x, y)] = TONGUE if floor else MOUTH
    # Fangs, three cells tapering to one: two hanging from the top of the
    # gape, two standing up from its floor.
    def open_rows(x):
        return [y for (cx, y), f in out.items()
                if cx == x and f in (MOUTH, TONGUE)]

    for x0, down in ((85, True), (106, True), (89, False), (102, False)):
        for dx in range(3):
            rows = open_rows(x0 + dx)
            # Longest in the middle column: a point, not a block.
            length = 3 if dx == 1 else 2
            edge = min(rows) if down else max(rows)
            for i in range(length):
                out[(x0 + dx, edge + i if down else edge - i)] = TOOTH
    return out


if __name__ == '__main__':
    closed = lib_boss.grid(SRC, UNIT)
    opened = open_maw(closed)
    if '--map' in sys.argv:
        which = opened if '--open' in sys.argv else closed
        lib_boss.print_map(which, LETTERS, 70, 48, 130, 80)
        sys.exit(0)

    # One frame for both poses, so the swap never shifts the sprite.
    x0, y0, x1, y1 = lib_boss.bounds(closed)
    assert lib_boss.bounds(opened) == (x0, y0, x1, y1)
    w, h = x1 - x0, y1 - y0
    order = lib_boss.order(SRC, extra=(MOUTH, TONGUE))
    for name, cells in (('angler_boss.svg', closed),
                        ('angler_boss_open.svg', opened)):
        lib_boss.write(name, lib_boss.emit(cells, order, x0, y0, w, h))
    # Numbers trial_boss.dart needs, in the sprite's own cells.
    lure = [(x, y) for (x, y), f in closed.items() if f == '#e3b65d']
    print('viewBox 0 0 %d %d; mouth x %.1f y %.1f; lure centre %.1f, %.1f' % (
        w, h, CX + 0.5 - x0, CY + 0.5 - y0,
        (min(x for x, _ in lure) + max(x for x, _ in lure) + 1) / 2 - x0,
        (min(y for _, y in lure) + max(y for _, y in lure) + 1) / 2 - y0))
