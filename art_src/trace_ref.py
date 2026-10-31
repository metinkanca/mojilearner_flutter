# -*- coding: utf-8 -*-
"""Traces objects out of `ref_airfield.png` into character grids.

The reference is a rendered pixel-art image, not a spec: it is 896x1200, its
edges are smeared by compression into thirty thousand near-identical colours,
and its own pixel lattice does not survive that. So this does not try to
recover the original grid. It quantises to the handful of colours the picture
actually uses, then majority-votes each cell of a chosen output grid — which
gives the *shape* exactly and at the resolution we want, rather than the one
the reference happened to be saved at.

    python art_src/trace_ref.py palette
    python art_src/trace_ref.py grid  <left> <top> <right> <bottom> <cols> <rows>
    python art_src/trace_ref.py structure <l> <t> <r> <b> <cols> <rows>
    python art_src/trace_ref.py shape   <left> <top> <right> <bottom> <cols> <rows>
    python art_src/trace_ref.py skyline <left> <top> <right> <bottom> <cols> <rows>
    python art_src/trace_ref.py crop <left> <top> <right> <bottom> <out.png>

`grid` traces every colour; `shape` traces a silhouette with a clean outline
and a light/mid/dark interior (B, S and outline), which is what you want for anything that has
to survive being three logical pixels per cell. Both print in
`gen_airfield.py`'s own alphabet. Trace, then edit by hand: a traced
silhouette is a far better starting point than a guess, and still wants
cleaning up.
"""

import os
import sys

import numpy as np
from PIL import Image, ImageFilter

REF = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                   'ref_airfield.png')

# The reference's real palette, recovered by clustering (see `palette`), with
# the character each colour traces to. Sky and tarmac trace to '.', which is
# what makes a crop come back as a silhouette rather than as a rectangle.
PALETTE = [
    ('.', (0x68, 0xAF, 0xDD)),  # sky, high
    ('.', (0x7D, 0xBD, 0xE7)),  # sky, middle
    ('.', (0xA0, 0xD7, 0xF6)),  # sky, at the horizon
    ('.', (0xB4, 0xA4, 0x94)),  # apron concrete
    ('.', (0x74, 0x66, 0x65)),  # apron, the darker slabs
    ('B', (0xEF, 0xF9, 0xFD)),  # white: cloud top, fuselage, building face
    ('P', (0xBD, 0xE2, 0xF5)),  # the pale underside of a cloud
    ('S', (0xA0, 0xA4, 0xA5)),  # grey: wings, tail, roofs
    ('S', (0xB7, 0xCF, 0xD2)),  # the cooler grey on the buildings
    ('#', (0x2A, 0x2A, 0x30)),  # outline
    ('#', (0x65, 0x5E, 0x5C)),  # the softer dark, mostly shadow
    ('W', (0x3D, 0x5A, 0x73)),  # glazing
    ('T', (0xE8, 0xB9, 0x3C)),  # apron paint
    ('T', (0xC0, 0x39, 0x2B)),  # the red on the fuel truck
]


def load(smooth=5):
    """The reference, median-filtered.

    Compression speckle is the whole difficulty here: a flat white fuselage
    arrives as a hundred near-whites, half of which fall closer to the grey
    than to the white and trace as noise. A median filter is the right tool
    because it removes that without moving an edge, which a blur would.
    """
    im = Image.open(REF).convert('RGB')
    if smooth:
        im = im.filter(ImageFilter.MedianFilter(smooth))
    return np.asarray(im).astype(int)


def cluster(a, tol=18):
    """The colours the picture actually uses, merged within `tol`."""
    flat = a.reshape(-1, 3)
    cols, counts = np.unique(flat, axis=0, return_counts=True)
    order = np.argsort(-counts)
    kept = []
    for i in order:
        c, n = cols[i], counts[i]
        for j, (kc, kn) in enumerate(kept):
            if np.abs(kc - c).max() <= tol:
                kept[j] = (kc, kn + n)
                break
        else:
            kept.append((c, n))
    kept.sort(key=lambda t: -t[1])
    return kept


def nearest(px, palette=None):
    best, bestd = '.', None
    for ch, col in (palette or PALETTE):
        d = sum((int(u) - int(v)) ** 2 for u, v in zip(px, col))
        if bestd is None or d < bestd:
            best, bestd = ch, d
    return best


def grid(a, box, cols, rows, palette=None):
    """Majority-vote `box` down to a cols x rows character grid."""
    left, top, right, bottom = box
    out = []
    for gy in range(rows):
        line = ''
        for gx in range(cols):
            y0 = top + (bottom - top) * gy // rows
            y1 = max(y0 + 1, top + (bottom - top) * (gy + 1) // rows)
            x0 = left + (right - left) * gx // cols
            x1 = max(x0 + 1, left + (right - left) * (gx + 1) // cols)
            tally = {}
            for px in a[y0:y1, x0:x1].reshape(-1, 3):
                ch = nearest(px, palette)
                tally[ch] = tally.get(ch, 0) + 1
            line += max(tally.items(), key=lambda kv: kv[1])[0]
        out.append(line)
    return out


# What counts as nothing: the sky's three bands and the two apron greys. An
# object is whatever is not one of these.
SKY = [(0x68, 0xAF, 0xDD), (0x7D, 0xBD, 0xE7), (0xA0, 0xD7, 0xF6)]
# Cloud counts as sky when tracing the skyline: it is behind the buildings,
# not one of them.
CLOUD = [(0xF1, 0xFA, 0xFF), (0xD2, 0xEC, 0xFB), (0xB7, 0xE2, 0xF5),
         (0xD6, 0xDB, 0xDF)]
APRON = [(0xB3, 0xA3, 0x94), (0x74, 0x66, 0x65), (0x8A, 0x7C, 0x73)]
BACKGROUND = SKY + APRON


# Ground structures again, but by colour rather than by luminance.
#
# `shape` asks how light a cell is, which is the right question for an
# aircraft against the sky and the wrong one for a terminal: the reference
# paints its concrete at luminance 167 and its glazing at 178, so a building
# traced that way comes back as one flat mass. These are the colours those
# two things actually are.
STRUCTURE = [
    ('.', (0x68, 0xAF, 0xDD)),  # sky, high
    ('.', (0x7D, 0xBD, 0xE7)),  # sky, middle
    ('.', (0xA0, 0xD7, 0xF6)),  # sky, at the horizon
    ('.', (0xF1, 0xFA, 0xFF)),  # cloud, which is behind the buildings
    ('.', (0xD2, 0xEC, 0xFB)),  # cloud, underside
    ('B', (0xB4, 0xA4, 0x94)),  # concrete, lit
    ('S', (0x8A, 0x7C, 0x73)),  # concrete, shaded
    ('S', (0x9F, 0x8F, 0x82)),  # concrete, the middle tone
    ('#', (0x74, 0x66, 0x65)),  # the dark trim and the eaves
    ('#', (0x2A, 0x2A, 0x30)),  # outline
    ('W', (0xAB, 0xB4, 0xBB)),  # glazing, lit
    ('W', (0x92, 0xA6, 0xB1)),  # glazing, shaded
    ('W', (0xB7, 0xCF, 0xD2)),  # glazing, the cool highlight
    ('W', (0x49, 0x4F, 0x5D)),  # glazing, in shadow
    ('B', (0xEF, 0xF9, 0xFD)),  # white trim
    ('T', (0xE8, 0xC1, 0x5C)),  # apron paint
]


def _near(px, col, tol):
    return all(abs(int(u) - int(v)) <= tol for u, v in zip(px, col))


def shape(a, box, cols, rows, tol=26, dark=90, mid=205, background=None):
    """`box` as a silhouette with a clean outline and a two-tone interior.

    `grid` traces every colour the reference uses, which is the honest answer
    and the wrong one here: the reference shades a fuselage in three greys,
    and at three logical pixels per cell that shading is noise rather than
    form — it comes back as speckle. So this asks two questions instead. Is
    the cell part of the object, and is it light, mid or dark? That is the
    whole vocabulary a shape this size can carry.

    The outline is recomputed from the silhouette rather than traced, because
    a traced one is one cell thick in some places and two in others wherever
    the reference happened to be resampled.
    """
    bg = BACKGROUND if background is None else background
    left, top, right, bottom = box
    lum, filled = [], []
    for gy in range(rows):
        lrow, frow = [], []
        for gx in range(cols):
            y0 = top + (bottom - top) * gy // rows
            y1 = max(y0 + 1, top + (bottom - top) * (gy + 1) // rows)
            x0 = left + (right - left) * gx // cols
            x1 = max(x0 + 1, left + (right - left) * (gx + 1) // cols)
            cell = a[y0:y1, x0:x1].reshape(-1, 3)
            hits = sum(1 for px in cell
                       if not any(_near(px, c, tol) for c in bg))
            frow.append(hits * 2 >= len(cell))
            fg = [px for px in cell
                  if not any(_near(px, c, tol) for c in bg)]
            src = fg if fg else list(cell)
            lrow.append(sum(0.299 * p[0] + 0.587 * p[1] + 0.114 * p[2]
                            for p in src) / len(src))
        lum.append(lrow)
        filled.append(frow)

    # Lone cells are compression, not art.
    for _ in range(2):
        nxt = [row[:] for row in filled]
        for y in range(rows):
            for x in range(cols):
                n = sum(filled[y + dy][x + dx]
                        for dy in (-1, 0, 1) for dx in (-1, 0, 1)
                        if 0 <= y + dy < rows and 0 <= x + dx < cols
                        and (dy or dx))
                if filled[y][x] and n <= 2:
                    nxt[y][x] = False
                elif not filled[y][x] and n >= 6:
                    nxt[y][x] = True
        filled = nxt

    out = []
    for y in range(rows):
        line = ''
        for x in range(cols):
            if not filled[y][x]:
                edge = any(filled[y + dy][x + dx]
                           for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1))
                           if 0 <= y + dy < rows and 0 <= x + dx < cols)
                line += '#' if edge else '.'
            else:
                v = lum[y][x]
                line += '#' if v < dark else 'S' if v < mid else 'B'
        out.append(line)
    return out


def main():
    if len(sys.argv) < 2:
        raise SystemExit(__doc__)
    a = load()
    cmd = sys.argv[1]

    if cmd == 'palette':
        for col, n in cluster(a)[:20]:
            print('#%02X%02X%02X' % tuple(col), n, '->', nearest(col))
    elif cmd == 'crop':
        box = tuple(int(v) for v in sys.argv[2:6])
        Image.open(REF).convert('RGB').crop(box).save(sys.argv[6])
        print('wrote', sys.argv[6])
    elif cmd == 'grid':
        left, top, right, bottom, cols, rows = (int(v) for v in sys.argv[2:8])
        for line in grid(a, (left, top, right, bottom), cols, rows):
            print(line)
    elif cmd == 'structure':
        left, top, right, bottom, cols, rows = (int(v) for v in sys.argv[2:8])
        for line in grid(a, (left, top, right, bottom), cols, rows,
                         STRUCTURE):
            print(line)
    elif cmd in ('shape', 'skyline'):
        left, top, right, bottom, cols, rows = (int(v) for v in sys.argv[2:8])
        rest = [int(v) for v in sys.argv[8:]]
        # `skyline` treats only the sky as nothing. The reference paints its
        # terminals in almost exactly the tan of the apron they stand on, so
        # colour cannot separate them — but the horizon can, and above it
        # anything that is not sky is a building.
        bg = SKY + CLOUD if cmd == 'skyline' else None
        for line in shape(a, (left, top, right, bottom), cols, rows, *rest,
                          background=bg):
            print(line)
    else:
        raise SystemExit(__doc__)


if __name__ == '__main__':
    main()
