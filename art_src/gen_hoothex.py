"""Builds the Hoothex boss sprites from the owner's art.

    python gen_hoothex.py            # writes assets/svgs/witch_boss*.svg
    python gen_hoothex.py --map      # prints the beak as a cell map
    python gen_hoothex.py --map --open

Hoothex, the witch owl on a broom, from `hoothex-clean-grid-fixed.svg`: the
owner's `hoothex-clean-grid.svg` with its outline two cells thick all round
and both feet the same symmetric foot (`fix_hoothex.py`, run once; the fixed
file is the master from then on). Five flat colour paths on a 1-unit grid,
each only its own cells. It replaced the placeholder
`witch-owl-broom-restored-wing.svg` (`gen_witch.py` still builds that one),
and is drawn on the set's own grid, 145 cells wide, so it is not shrunk.
lib_boss.py says why the sprite is rebuilt rather than drawn as-is. Emits,
the way gen_mossback.py does:

  witch_boss.svg       the sprite, one traced path per colour, each painted
                       over the union of everything above it -- no seams.
  witch_boss_open.svg  the same with its beak open, for casting. Swapped in
                       whole.

A run prints the numbers `trial_boss.dart` takes from the art: its cell grid,
the middle of the open beak, the middle of the belly, and where the brim
ends, for the potion she brews there.

Re-run after any edit to the source art; never hand-edit the outputs.
"""
import sys

import lib_boss
from lib_boss import MOUTH, TONGUE

SRC = 'hoothex-clean-grid-fixed.svg'

K = '#14120e'        # outline, brows, eyes, the buckle's hole
PURPLE = '#5b3f8c'   # hat, feathers
CREAM = '#ffefcd'    # belly
GOLD = '#f0a93c'     # hat band and buckle, beak, feet, the broom's head
BROWN = '#8a5a3c'    # the broomstick

LETTERS = {K: 'K', PURPLE: 'p', CREAM: '.', GOLD: 'Y', BROWN: 'b',
           MOUTH: 'R', TONGUE: 'G'}

# The beak: a hooked wedge of gold in a two-cell outline, its top row 57 and
# its tip on row 70, centred on cell 107 (its left edge 101, its right 113).
BEAK = (96, 54, 120, 80)
BEAK_X = 107


def open_beak(g):
    """The cast pose: [g] with the beak dropped open.

    The closed beak is a flat-topped wedge: five rows of gold down to a
    hooked tip at the bottom right, its lower left edge a diagonal on the
    belly's cream. The open pose keeps the upper beak's top, closes it off
    with a line under it, opens a gape of dark mouth with the tongue along
    its floor, and hangs the closed beak's tip below as the lower beak, its
    point down. Drawn big, as the witch's has always been: at the size she
    flies in the arena a cell is barely a pixel, and anything smaller reads
    as closed.
    """
    return lib_boss.paint(g, 100, 64, [
        # the upper beak's underside
        ' KKKKKKKKKKKKK ',
        # the gape, walled in the outline both sides
        ' KKRRRRRRRRRKK ',
        ' KKRRRRRRRRRKK ',
        ' KKRRGGGGGRRKK ',
        ' KKRGGGGGGGRKK ',
        # the lower beak: the closed beak's tip, dropped
        ' KKKKYYYYYYYKK ',
        '  KKKKKKYYYYKK ',
        '    KKKKKYYYKK ',
        '       KKKYYKK ',
        '        KKYKKK ',
        '        KKKKK  ',
        '         KKK   ',
    ], {'K': K, 'Y': GOLD, 'R': MOUTH, 'G': TONGUE},
        under=(PURPLE, CREAM, GOLD, K))


def belly(g):
    """The middle of the belly: the cream's bounding box."""
    cells = [(x, y) for (x, y), f in g.items() if f == CREAM]
    xs = [x for x, _ in cells]
    ys = [y for _, y in cells]
    return (min(xs) + max(xs) + 1) / 2, (min(ys) + max(ys) + 1) / 2


def brim_end(g):
    """Where the brim's right end is, for the potion she brews on it: the
    column of the hat's rightmost cell, and the top of the brim there. The
    hat's purple, outline included, is everything above the body to the
    right of the buckle, so its rightmost cell is the brim's tip."""
    tip = max(x for (x, y), f in g.items() if f == K and y < 50)
    top = min(y for (x, y), f in g.items() if f == K and x >= tip - 12)
    return tip, top


if __name__ == '__main__':
    closed = lib_boss.grid(SRC, 1)
    if '--map' in sys.argv:
        lib_boss.print_map(open_beak(closed) if '--open' in sys.argv
                           else closed, LETTERS, *BEAK)
        sys.exit(0)

    opened = open_beak(closed)
    # One frame for both poses, so the swap never shifts the sprite.
    x0, y0, x1, y1 = lib_boss.bounds(closed)
    assert lib_boss.bounds(opened) == (x0, y0, x1, y1)
    w, h = x1 - x0, y1 - y0
    order = lib_boss.order(SRC, extra=(MOUTH, TONGUE))
    for name, cells in (('witch_boss.svg', closed),
                        ('witch_boss_open.svg', opened)):
        lib_boss.write(name, lib_boss.emit(cells, order, x0, y0, w, h))
    bx, by = belly(closed)
    tx, ty = brim_end(closed)
    print('viewBox 0 0 %d %d (aspect %d / %d)' % (w, h, w, h))
    print('mouth x %.1f -> mouthX %d / %d' % (BEAK_X - x0, BEAK_X - x0, w))
    print('belly %.1f, %.1f -> hitX %.2f, hitY %.2f'
          % (bx - x0, by - y0, (bx - x0) / w, (by - y0) / h))
    print('brim tip x %d, top y %d -> chargeX %.2f, chargeBottom %.2f'
          % (tx - x0, ty - y0, (tx - x0) / w, (ty - y0) / h))
