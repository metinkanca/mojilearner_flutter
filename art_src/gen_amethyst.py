"""Builds the Amethyst boss sprites from the source art.

    python gen_amethyst.py            # writes assets/svgs/amethyst_boss*.svg
    python gen_amethyst.py --map      # prints the muzzle as a cell map

A PLACEHOLDER until the owner's final art: the crystal bear from
`amethyst-boss.svg`, six colour paths on a 10-unit pixel grid; lib_boss.py
says why it is rebuilt rather than drawn as-is. Emits, the way
gen_mossback.py does:

  amethyst_boss.svg       the sprite, one traced path per colour, each painted
                          over the union of everything above it -- no seams.
  amethyst_boss_open.svg  the same with its mouth open, for the roar. Swapped
                          in whole.

Both come out in cell units, cropped to the art (viewBox printed on a run).
Re-run after any edit to the source art; never hand-edit the outputs.
"""
import sys

import lib_boss
from lib_boss import MOUTH, TONGUE

SRC = 'amethyst-boss.svg'

K = '#11120e'   # silhouette / outline
P = '#d7c1d8'   # pale muzzle and chest

LETTERS = {
    K: 'K',
    '#704e69': 'o',   # plum fur
    '#493644': 'n',   # nose, paws and neck shadow
    P: 'p',
    '#bc93d8': 'C',   # amethyst crystals
    '#654584': 'c',   # crystal facets
    MOUTH: 'R',
    TONGUE: 'G',
}


def open_mouth(g):
    """The roar: [g] with the mouth dropped open.

    The closed mouth hangs under the nose (rows 45-54): a philtrum down to a
    two-row lip line across cells 86-98 on rows 58-59, with a "w" on row 60,
    all inside the pale muzzle, which runs well past it on every row it
    touches. The open pose keeps the nose, the philtrum and the top lip and
    hangs a rounded mouth off the lip in the art's own two-cell outline, the
    lip's width, so it reads as the mouth it replaced.
    """
    return lib_boss.paint(g, 86, 60, [
        'KKRRRRRRRRRKK',
        'KKRRRRRRRRRKK',
        'KKRRRRRRRRRKK',
        'KKRRGGGGGRRKK',
        'pKKGGGGGGGKKp',
        ' pKKKKKKKKKp ',
        '   KKKKKKK   ',
    ], {'K': K, 'R': MOUTH, 'G': TONGUE, 'p': P}, under=(K, P))


if __name__ == '__main__':
    closed = lib_boss.grid(SRC)
    if '--map' in sys.argv:
        lib_boss.print_map(closed, LETTERS, 70, 44, 110, 72)
        sys.exit(0)

    opened = open_mouth(closed)
    # One frame for both poses, so the swap never shifts the sprite.
    x0, y0, x1, y1 = lib_boss.bounds(closed)
    assert lib_boss.bounds(opened) == (x0, y0, x1, y1)
    w, h = x1 - x0, y1 - y0
    order = lib_boss.order(SRC, extra=(MOUTH, TONGUE))
    for name, cells in (('amethyst_boss.svg', closed),
                        ('amethyst_boss_open.svg', opened)):
        lib_boss.write(name, lib_boss.emit(cells, order, x0, y0, w, h))
    # Numbers trial_boss.dart needs, in the sprite's own cells.
    mouth = [x for (x, y), f in opened.items() if f == MOUTH]
    print('viewBox 0 0 %d %d; mouth x %.1f' % (
        w, h, (min(mouth) + max(mouth) + 1) / 2 - x0))
