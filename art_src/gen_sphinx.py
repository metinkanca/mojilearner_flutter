"""Builds the Sableth boss sprites from the source art.

    python gen_sphinx.py            # writes assets/svgs/sphinx_boss*.svg
    python gen_sphinx.py --map      # prints the muzzle as a cell map

The owner's sand sphinx from `sableth-clean-grid-symmetric.svg`, four colour
paths drawn straight on their pixel grid (their `sableth-clean-grid.svg`, with
the left paw's first toe line redrawn to match the other three); lib_boss.py
says why it is rebuilt rather than drawn as-is. Emits, the way
gen_mossback.py does:

  sphinx_boss.svg       the sprite, one traced path per colour, each painted
                        over the union of everything above it -- no seams.
  sphinx_boss_open.svg  the same with its mouth open, for the roar. Swapped
                        in whole.

Both come out in cell units, cropped to the art (viewBox printed on a run).
Re-run after any edit to the source art; never hand-edit the outputs.
"""
import sys

import lib_boss
from lib_boss import MOUTH, TONGUE

SRC = 'sableth-clean-grid-symmetric.svg'

K = '#14120e'       # silhouette / outline, eyes and frown
GOLD = '#d8963a'    # sandstone
CREAM = '#f7dca5'   # muzzle, chest and inner ears

LETTERS = {
    K: 'K',
    GOLD: 'o',
    CREAM: '.',
    '#304b68': 'b',   # headdress bands and tail tuft
    MOUTH: 'R',
    TONGUE: 'G',
}


def open_mouth(g):
    """The roar: [g] with the mouth dropped open.

    The closed mouth is a cat's "w" under the nose: the philtrum down rows
    45-46 at cells 88-89, a bar across 86-90 on row 47, and its corners
    curling up to 82-86 and 90-93 on row 48, all inside the cream muzzle,
    which runs well past it on every row. The open pose keeps the nose and
    the philtrum and hangs a mouth off them, a little wider than the "w" and
    in the face's own one-cell line so it reads at arena size.
    """
    return lib_boss.paint(g, 82, 47, [
        ' KKKKKKKKKK ',
        'KKRRRRRRRRKK',
        'KRRRRRRRRRRK',
        'KRRRRRRRRRRK',
        'KRRGGGGGGRRK',
        ' KRGGGGGGRK ',
        '  KKKKKKKK  ',
    ], {'K': K, 'R': MOUTH, 'G': TONGUE}, under=(K, CREAM, GOLD))


if __name__ == '__main__':
    closed = lib_boss.grid(SRC, 1)
    if '--map' in sys.argv:
        lib_boss.print_map(open_mouth(closed) if '--open' in sys.argv
                           else closed, LETTERS, 60, 30, 110, 62)
        sys.exit(0)

    opened = open_mouth(closed)
    x0, y0, x1, y1 = lib_boss.bounds(closed)
    assert lib_boss.bounds(opened) == (x0, y0, x1, y1)
    w, h = x1 - x0, y1 - y0
    order = lib_boss.order(SRC, extra=(MOUTH, TONGUE))
    for name, cells in (('sphinx_boss.svg', closed),
                        ('sphinx_boss_open.svg', opened)):
        lib_boss.write(name, lib_boss.emit(cells, order, x0, y0, w, h))
    mouth = [x for (x, y), f in opened.items() if f == MOUTH]
    print('viewBox 0 0 %d %d; mouth x %.1f' % (
        w, h, (min(mouth) + max(mouth) + 1) / 2 - x0))
