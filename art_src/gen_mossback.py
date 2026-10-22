"""Builds the Mossback boss sprites from the source art.

    python gen_mossback.py            # writes assets/svgs/mossback_boss*.svg
    python gen_mossback.py --map      # prints the head as a cell map

The source (`mossback-boss.svg`) is seven colour paths on a 10-unit pixel grid;
lib_boss.py says why it is rebuilt rather than drawn as-is. Emits:

  mossback_boss.svg       the sprite, one traced path per colour, each painted
                          over the union of everything above it -- no seams.
  mossback_boss_open.svg  the same with its mouth open, for the shout. Swapped
                          in whole, the way the pets' chew swaps mouth layers.

Both come out in cell units (viewBox 0 0 141 108), which keeps every
coordinate a small integer. Re-run after any edit to the source art; never
hand-edit the outputs.
"""
import sys

import lib_boss
from lib_boss import MOUTH, TONGUE

SRC = 'mossback-boss.svg'
W, H = 141, 108

K = '#11120d'   # silhouette / outline
T = '#f4d18d'   # tan jaw and belly

LETTERS = {
    K: 'K',
    '#969957': 'O',   # olive skin
    '#7e8a3e': 'M',   # moss on the shell
    '#989387': 'P',   # stone plates
    '#4f504b': 'S',   # plate seams
    '#5f6240': 'F',   # feet and neck shadows
    T: 'T',
    MOUTH: 'R',
    TONGUE: 'G',
}


def open_mouth(g):
    """The shout pose: [g] with the mouth dropped open.

    The closed mouth is a lip line across cells 113-127 on row 65 with a
    "w" dip on row 66, under the nose (117-124, rows 59-61). The open pose
    keeps the nose and the top lip and hangs a rounded mouth off the lip into
    the tan jaw, which runs well past it on every row it touches, so nothing
    outside the jaw changes. Drawn to the same 15-cell width as the lip, so
    the mouth reads as the one it replaced rather than a new feature.
    """
    return lib_boss.paint(g, 113, 66, [
        'KRRRRRRRRRRRRRK',
        'KRRRRRRRRRRRRRK',
        'KRRRRRRRRRRRRRK',
        'KRRRGGGGGGGRRRK',
        'TKRGGGGGGGGGRKT',
        'TTKKKKKKKKKKKTT',
    ], {'K': K, 'R': MOUTH, 'G': TONGUE, 'T': T}, under=(K, T))


if __name__ == '__main__':
    g = lib_boss.grid(SRC)
    if '--map' in sys.argv:
        lib_boss.print_map(g, LETTERS, 80, 30, W, 84)
        sys.exit(0)

    order = lib_boss.order(SRC, extra=(MOUTH, TONGUE))
    for name, cells in (('mossback_boss.svg', g),
                        ('mossback_boss_open.svg', open_mouth(g))):
        lib_boss.write(name, lib_boss.emit(cells, order, 0, 0, W, H))
