# -*- coding: utf-8 -*-
"""Traces `ref_airfield_native.png` into the character grids `gen_airfield.py` uses.

This is the good path, and it exists because the reference arrived twice. The
first copy was `ref_airfield.png`: a raster at 896x1200 with thirty thousand
near-identical colours, whose own pixel lattice had to be *recovered* by
autocorrelating its colour-change signal (four pixels, so the art was natively
224x300 inside it) and then read back by majority vote — which loses a
one-cell outline at any output size below the source.

The second copy was `ref_airfield.svg`, the same picture as vectors. That
changes everything, because a vector can be rendered *onto* the native grid
rather than sampled off it:

    render_ref.py            # SVG -> 896x1200 -> box-filtered to 224x300

One source pixel is then exactly one cell, the colours are flat, and tracing
is a palette lookup rather than a vote. Nothing is guessed.

    python art_src/trace_native.py palette
    python art_src/trace_native.py grid <left> <top> <right> <bottom> [bg]
    python art_src/trace_native.py crop <left> <top> <right> <bottom> <out.png>

`bg` is `sky` (default) or `all`. The reference paints its terminals in almost
exactly the tan of the apron they stand on, so colour alone cannot separate a
building from the ground it is on — but the horizon can, and above it anything
that is not sky is a building. Crops that reach below the horizon want `all`,
which drops the apron too.
"""

import os
import sys

import numpy as np
from PIL import Image

REF = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                   'ref_airfield_native.png')

# The reference's palette, sampled from the native render, with the character
# each colour traces to. See `gen_airfield.CH` for what the characters mean.
PALETTE = [
    ('.', (0x75, 0xB8, 0xE2)),  # sky, above the horizon haze
    ('.', (0xA0, 0xD7, 0xF5)),  # sky, the haze itself
    ('.', (0x99, 0xCF, 0xED)),  # sky, between the two
    ('#', (0x00, 0x00, 0x00)),  # outline
    ('#', (0x6C, 0x6D, 0x6E)),  # the softer outline on the aircraft
    ('#', (0x71, 0x6E, 0x68)),  # the dark trim and eaves on the buildings
    ('B', (0xF1, 0xFA, 0xFC)),  # white: cloud top, building face
    ('B', (0xD8, 0xDA, 0xDC)),  # the aircraft's lit upper hull
    ('P', (0xD2, 0xEC, 0xF9)),  # a cloud's shaded underside
    ('S', (0xAF, 0xB4, 0xBA)),  # grey: wings, tail, roofs
    ('S', (0x95, 0x96, 0x97)),  # the same, shaded
    ('C', (0xB3, 0xA4, 0x94)),  # concrete, lit
    ('C', (0xBF, 0xB7, 0xAB)),  # concrete, the lighter face
    ('D', (0x8E, 0x7F, 0x77)),  # concrete, shaded
    ('D', (0x80, 0x7C, 0x75)),  # concrete, shaded further
    ('W', (0x87, 0x9F, 0xAB)),  # glazing
    ('W', (0x8C, 0xA9, 0xB7)),  # glazing, lit
    ('T', (0xE8, 0xC1, 0x5C)),  # apron paint
]

# What counts as nothing. Sky always; the apron too when a crop reaches below
# the horizon.
SKY = [(0x75, 0xB8, 0xE2), (0xA0, 0xD7, 0xF5), (0x99, 0xCF, 0xED)]
APRON = [(0xB3, 0xA4, 0x94), (0x73, 0x67, 0x65), (0x8B, 0x7E, 0x77)]


def load():
    return np.asarray(Image.open(REF).convert('RGB')).astype(int)


def nearest(px):
    best, bestd = '.', None
    for ch, col in PALETTE:
        d = sum((int(u) - int(v)) ** 2 for u, v in zip(px, col))
        if bestd is None or d < bestd:
            best, bestd = ch, d
    return best


def grid(a, box, background=None):
    """`box` as a character grid, one source pixel per cell."""
    bg = SKY if background is None else background
    left, top, right, bottom = box
    out = []
    for y in range(top, bottom):
        line = ''
        for x in range(left, right):
            px = a[y, x]
            if any(all(abs(int(u) - int(v)) <= 10 for u, v in zip(px, c))
                   for c in bg):
                line += '.'
            else:
                line += nearest(px)
        out.append(line)
    return out


def main():
    if len(sys.argv) < 2:
        raise SystemExit(__doc__)
    cmd = sys.argv[1]

    if cmd == 'palette':
        import collections
        a = load()
        counts = collections.Counter(map(tuple, a.reshape(-1, 3)))
        for col, n in counts.most_common(28):
            print('#%02X%02X%02X %6d -> %s' % (col[0], col[1], col[2], n,
                                               nearest(col)))
    elif cmd == 'crop':
        box = tuple(int(v) for v in sys.argv[2:6])
        Image.open(REF).convert('RGB').crop(box).save(sys.argv[6])
        print('wrote', sys.argv[6])
    elif cmd == 'grid':
        box = tuple(int(v) for v in sys.argv[2:6])
        which = sys.argv[6] if len(sys.argv) > 6 else 'sky'
        bg = SKY + APRON if which == 'all' else SKY
        for line in grid(load(), box, bg):
            print(line)
    else:
        raise SystemExit(__doc__)


if __name__ == '__main__':
    main()
