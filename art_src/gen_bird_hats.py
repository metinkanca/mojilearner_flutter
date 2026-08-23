# Builds the bird's copies of the hats, re-pixelised smaller.
#
# The hats are drawn for the cat's head, which is a third wider than the
# chick's whole body. Translating them (gen_bird_acc.py's trick for the face)
# does nothing about that -- a top hat seated perfectly on a bird it swallows
# is still swallowing the bird.
#
# Resizing pixel art is RE-PIXELISING, never `transform: scale()`: a transform
# shrinks the accessory's pixels below the pet's 7-unit cell and the piece
# reads as a different art set. So each hat is resampled onto fewer 7u cells.
# The shipped art already carries a 1-cell outline, so the vote is taken over
# fill colours only -- feeding the outline back through the dilation would
# double it -- and a fresh 1-cell border is dilated on afterwards.
#
# Detail is lost; that is what making something smaller costs. Anything that
# survives at this size does so because it is at least a cell thick in the
# source.
#
# Re-run after any edit to the source hats. Never hand-edit the output.
import sys, os
from collections import Counter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import deseam
from deseam import VBX, VBY, VBW, VBH, shapes, rasterise, trace, emit

SVG = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'assets', 'svgs')
OUTLINE = '#1f2223'
CELL = 7                     # the pets' pixel, shared by every accessory

# Where the full-size piece sat on the bird, from _PetParts.accessoryOffsets.
# The shrunk hat keeps that seating: same outline bottom, same centre.
BASE_DX, BASE_DY = 14, 45

# scale: fraction of the original the fill is resampled to.
# dx/dy: nudges on top of the seating above, in whole cells' worth of units.
# mirror: flip left-right, for a piece that points somewhere.
#
# 0.68 is the chick's head against the cat's (91u across at the eyes, against
# 123u). Pieces that overhang the head by design -- a cowboy brim, a wizard
# brim -- go smaller still, because their overhang is measured against a head
# that is no longer there.
JOBS = [
    dict(id='beanie', scale=0.68),
    dict(id='cap', scale=0.62, mirror=True),
    dict(id='cowboyhat', scale=0.78),
    dict(id='crown', scale=0.68),
    dict(id='devilhorns', scale=0.68),
    dict(id='flowercrown', scale=0.88),
    dict(id='headphones', scale=0.86),
    dict(id='mortarboard', scale=0.75),
    dict(id='partyhat', scale=0.75),
    dict(id='tophat', scale=0.62),
    dict(id='wizardhat', scale=0.58),
]


def raster(svg):
    """(buf, order): a colour index per canvas pixel, -1 where nothing paints."""
    shp = shapes(svg)
    fills = []
    for f, _ in shp:
        if f not in fills:
            fills.append(f)
    order = sorted(fills, key=lambda f: (deseam.RANK.get(f, 5), fills.index(f)))
    buf = [-1] * (VBW * VBH)
    for f, subs in shp:
        rasterise(subs, buf, order.index(f))
    return buf, order


def shrink(svg, scale, dx, dy, mirror=False):
    buf, order = raster(svg)
    out_idx = order.index(OUTLINE) if OUTLINE in order else -1

    # Everything that is not the outline is fill: that is what gets resampled,
    # and the outline is rebuilt from scratch around the result.
    fill, whole = [], []
    for y in range(VBH):
        for x in range(VBW):
            v = buf[y * VBW + x]
            if v < 0:
                continue
            whole.append((x, y))
            if v != out_idx:
                fill.append((x, y, v))
    if not fill:
        raise SystemExit('nothing but outline')

    fx0 = min(p[0] for p in fill); fx1 = max(p[0] for p in fill) + 1
    fy0 = min(p[1] for p in fill); fy1 = max(p[1] for p in fill) + 1
    src = {(x, y): v for x, y, v in fill}

    cols = max(1, round((fx1 - fx0) * scale / CELL))
    rows = max(1, round((fy1 - fy0) * scale / CELL))

    cells = {}
    for j in range(rows):
        sy0 = fy0 + (fy1 - fy0) * j / rows
        sy1 = fy0 + (fy1 - fy0) * (j + 1) / rows
        for i in range(cols):
            sx0 = fx0 + (fx1 - fx0) * i / cols
            sx1 = fx0 + (fx1 - fx0) * (i + 1) / cols
            votes = Counter()
            total = 0
            for y in range(int(sy0), max(int(sy0) + 1, int(round(sy1)))):
                for x in range(int(sx0), max(int(sx0) + 1, int(round(sx1)))):
                    total += 1
                    v = src.get((x, y))
                    if v is not None:
                        votes[v] += 1
            if total and sum(votes.values()) / total > 0.5:
                cells[(i, j)] = votes.most_common(1)[0][0]

    if not cells:
        raise SystemExit('resample emptied the piece')

    # The cat faces the viewer, so a peak drawn to its left is just a peak. The
    # chick faces right, where the same peak reads as a cap on backwards.
    if mirror:
        cells = {(cols - 1 - i, j): v for (i, j), v in cells.items()}

    # Fresh 1-cell border, 4-neighbourhood, exactly as the v2 pipeline does.
    border = set()
    for (i, j) in cells:
        for di, dj in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            if (i + di, j + dj) not in cells:
                border.add((i + di, j + dj))

    # Seat it: the outline's bottom row and the piece's centre stay where the
    # full-size art sat, so a smaller hat still rests on the crown.
    wy1 = max(p[1] for p in whole) + 1
    wx0 = min(p[0] for p in whole); wx1 = max(p[0] for p in whole) + 1
    ox = round((wx0 + wx1) / 2 + VBX + BASE_DX + dx - cols * CELL / 2)
    oy = round(wy1 + VBY + BASE_DY + dy - CELL - rows * CELL)

    def art(i, j):
        return ox + i * CELL, oy + j * CELL

    # Paint back to front like deseam: outline first, then each fill colour
    # over it, so joins overlap instead of abutting.
    layers = [(OUTLINE, border)] if out_idx >= 0 else []
    for idx, colour in enumerate(order):
        if idx == out_idx:
            continue
        got = {c for c, v in cells.items() if v == idx}
        if got:
            layers.append((colour, got))

    body = []
    painted = set()
    for colour, group in reversed(layers):
        painted |= group
        mask = [0] * (VBW * VBH)
        for (i, j) in painted:
            ax, ay = art(i, j)
            for y in range(ay - VBY, ay - VBY + CELL):
                for x in range(ax - VBX, ax - VBX + CELL):
                    if 0 <= x < VBW and 0 <= y < VBH:
                        mask[y * VBW + x] = 1
        d = emit(trace(mask))
        if d:
            body.insert(0, '<path fill="%s" d="%s"/>' % (colour, d))

    head = svg[:svg.index('>', svg.index('<svg')) + 1]
    return (head + ''.join(body) + '</svg>\n', cols, rows)


if __name__ == '__main__':
    for job in JOBS:
        src = open(os.path.join(SVG, 'acc_%s.svg' % job['id']), encoding='utf-8').read()
        out, cols, rows = shrink(src, job['scale'], job.get('dx', 0),
                                 job.get('dy', 0), job.get('mirror', False))
        p = os.path.join(SVG, 'acc_%s_bird.svg' % job['id'])
        open(p, 'w', encoding='utf-8').write(out)
        print('acc_%-14s %2dx%-2d cells  %3dx%-3du  %5d bytes'
              % (job['id'] + '_bird.svg', cols, rows,
                 cols * CELL, rows * CELL, len(out)))
