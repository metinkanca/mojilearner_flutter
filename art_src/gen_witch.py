"""Builds the witch boss sprites from the source art.

    python gen_witch.py            # writes assets/svgs/witch_boss*.svg
    python gen_witch.py --map      # prints the beak as a cell map

The PLACEHOLDER Hoothex, kept buildable: the witch owl on a broom from
`witch-owl-broom-restored-wing.svg`, eight colour paths on a 10-unit pixel
grid; lib_boss.py says why it is rebuilt rather than drawn as-is. (It
replaced an earlier stand-in, the roster frog in a witch hat.) The owner's
own art, `hoothex-clean-grid.svg`, replaced it in the game on 2026-10-20:
`gen_hoothex.py` writes the same two outputs from that, and running this
would put the placeholder back, along with its numbers in `trial_boss.dart`
(a 114 x 125 grid, mouth 78). Emits, the way gen_mossback.py does:

  witch_boss.svg       the sprite, one traced path per colour, each painted
                       over the union of everything above it -- no seams.
  witch_boss_open.svg  the same with its beak open, for casting. Swapped in
                       whole.

Both come out in cell units, cropped to the art (viewBox printed on a run).
Re-run after any edit to the source art; never hand-edit the outputs.
"""
import sys

import lib_boss
from lib_boss import MOUTH, TONGUE

SRC = 'witch-owl-broom-restored-wing.svg'

K = '#14120e'        # silhouette / outline
PLUM = '#835f6e'     # feathers
CREAM = '#ffefcd'    # face and belly
GOLD = '#f5bf42'     # hat band, beak and feet
BEAK = '#89613c'     # beak shadow, and the broomstick

LETTERS = {
    K: 'K',
    '#604281': 'H',   # violet hat
    '#3e2c53': 'h',   # hat fold
    PLUM: 'o',
    '#553c4b': 'w',   # wing shadows
    CREAM: '.',
    GOLD: 'Y',
    BEAK: 'b',
    MOUTH: 'R',
    TONGUE: 'G',
}


def open_beak(g):
    """The cast pose: [g] with the beak dropped open.

    The closed beak has no outline: gold with a brown shadow down its right,
    tapering from six cells wide on row 58 to a hooked tip on rows 61-62, in
    the cream of the face, with the chest's feather V opening just below.
    The open pose keeps the upper beak and its tip, wraps a gape round the
    tip, and hangs a lower beak under it. Drawn big: at the size she flies in
    the arena a cell is barely a pixel, and anything smaller reads as closed.
    """
    return lib_boss.paint(g, 73, 60, [
        ' RRRYYYYbRR',
        ' RRRRYYbbRR',
        ' RRRRYYbRRR',
        ' RRGGGGGGRR',
        '  RGGGGGGR ',
        '  YYYYYYYb ',
        '   YYYYYb  ',
        '    YYYb   ',
    ], {'R': MOUTH, 'G': TONGUE, 'Y': GOLD, 'b': BEAK},
        under=(PLUM, CREAM, GOLD, BEAK))


if __name__ == '__main__':
    closed = lib_boss.grid(SRC)
    if '--map' in sys.argv:
        lib_boss.print_map(closed, LETTERS, 66, 50, 90, 70)
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
    # Numbers trial_boss.dart needs, in the sprite's own cells.
    mouth = [x for (x, y), f in opened.items() if f == MOUTH]
    print('viewBox 0 0 %d %d; mouth x %.1f' % (
        w, h, (min(mouth) + max(mouth) + 1) / 2 - x0))
