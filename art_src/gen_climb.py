# -*- coding: utf-8 -*-
"""The boss climb map: one floor a boss, built from the owner's props sheets.

The owner's image tool draws a sheet of pieces for a floor on a magenta
ground, in the cozy room's pixel style (chunky pixels, a one-pixel black
outline, flat fills). This reads the sheet, cleans every piece, and lays the
pieces out as a portrait map the way the home scenes are (864 x 1872 units): a
path of stepping stones winding up from a start stone at the bottom through
five round stops to the boss's gate at the top, with scenery either side.

    python gen_climb.py [floor ...] --write         # climb-floor-N.png/.svg/.json
    python gen_climb.py [floor ...] --preview DIR   # + the sheet as read
    python gen_climb.py [floor ...] --check         # defects left in the pieces
    python gen_climb.py --app                       # what the app loads:
                                                    # assets/svgs/climb_floor_N.svg
                                                    # and lib/constants/
                                                    # boss_climb_art.dart

The tool's sheets are not on a clean grid (each piece is a little off its
neighbours, and its outlines have gaps, its fills run over the outline, and it
shades), so reading a piece is a rebuild, not a copy:

  * its own pixel size and phase are searched from its own edges (`fit_piece`),
    on a grid that starts a cell BEFORE the piece, so a first column of outline
    is not lost;
  * the silhouette is every cell at least half covered (`silhouette`), and the
    cells on its outside edge are the outline, always: one cell thick, no gap,
    and no fill outside it (`read_piece`);
  * inside, a cell is ink if its middle is, else the nearest of the fills that
    kind of piece is allowed (`FLOORS[n]['allow']`), so no stray colour exists;
  * then tidied: lone ink cells, edge blends, one-cell pits, patches of the
    tool's shading (`tidy`), and a few pieces are redrawn properly: round stops
    as true pixel ellipses with a symmetric mark (`roundify`,
    `symmetrize_motif`), lanterns and sparkles mirrored (`mirror`).

A sheet is two dozen or so pieces in rows: [slabs, stops x2, start stone],
[gate], [props, wall pieces], [plants], [small things]; which is which is the
table's `roles`. Each sheet is drawn on a grid of its own, so each floor is
scaled to make its stop pad PAD_UNITS wide (`floor_scale`) and is as many
cells as that makes it: the pads are the same size on every floor, the pixels
a little different.
"""
import json
import math
import os
import random
import sys

import numpy as np
import scipy.ndimage as ndi
from PIL import Image

import lib_sheet as L
import scene_art as SA

HERE = os.path.dirname(os.path.abspath(__file__))
INK = '#14120e'
HOLE = ','                          # ground inside a piece (a lantern's glass)
UNITS_W, UNITS_H = 864, 1872       # a home scene's size
PAD_UNITS = 150                     # how wide a stop pad is, on every floor
# The generator's sparkle, bottom right of every sheet: (x0, y0, x1, y1).
WATERMARK = (1290, 680, 1350, 745)

# A floor is one props sheet. `roles` says which pieces on it are what, by
# their place in the sheet's reading order (`piece_boxes`: top to bottom, left
# to right by where each starts; `--preview` numbers them), and `allow` the
# fills each kind of piece is drawn in (the outline K is always allowed): the
# prompt asked for these, and a colour a piece was not asked for -- the tool's
# shading, an edge blend -- cannot appear in it. A list is one entry a piece,
# in the order of the role's list. `p` is the sheet's pixel size in its own
# pixels: the tool draws on a grid of its own, a different one on each sheet.
FLOORS = {
    1: dict(name='Mossback meadow', sheet='climb-floor1-sheet.png', p=4.28,
            ground='#5db89a',
            tones={'K': INK, 'C': '#f6f0dc', 'G': '#8cc56a', 'W': '#c58c56'},
            roles=dict(slabs=[0, 1, 2], pads=[3, 4], start=[5], gate=[6],
                       walls=[7, 8, 9], props=[10, 11, 12],
                       plants=[13, 14, 15, 16],
                       small=[17, 18, 19, 20, 21, 22, 23]),
            allow=dict(slabs='CG', pads='CG', start='C', gate='CG',
                       props='CG', walls='CG', plants='G',
                       small=['WG', 'G', 'G', 'C', 'C', 'C', 'C']),
            island=3, glass={}, star=False, mirror={}),
    2: dict(name='Amethyst cave', sheet='climb-floor2-sheet.png', p=5.72,
            ground='#70549b',
            tones={'K': INK, 'C': '#f6f0dc', 'L': '#d9c8f0', 'V': '#9a7cc8'},
            roles=dict(slabs=[2, 3, 5], pads=[0, 1], start=[4], gate=[6],
                       walls=[7, 8, 9], props=[10, 11, 12],
                       plants=[13, 14, 15, 17], small=[16, 20, 18, 19, 21]),
            allow=dict(slabs='L', pads='LC', start='L', gate='VL', props='V',
                       walls='V', plants='L',
                       small=['C', 'C', 'V', 'V', 'V']),
            island=3, glass={}, star=True,
            mirror=dict(small=['both', 'both', None, None, None]),
            bare=dict(small=[True, True, False, False, False])),
    3: dict(name='Hoothex forest', sheet='climb-floor3-sheet.png', p=4.28,
            ground='#b99cd8',
            tones={'K': INK, 'C': '#f6f0dc', 'P': '#58348d', 'O': '#fb8630',
                   'Y': '#f9df62'},
            roles=dict(slabs=[2, 3, 4, 5], pads=[0, 1], start=[6], gate=[7],
                       walls=[11, 12, 13], props=[8, 9, 10],
                       plants=[16, 19, 17, 22, 20],
                       small=[14, 15, 18, 21, 23]),
            allow=dict(slabs='C', pads='CO', start='C', gate='PY', props='P',
                       walls='P', plants='OC',
                       small=['PY', 'PY', 'C', 'C', 'C']),
            island=0, glass=dict(small=['Y', 'Y', None, None, None]),
            star=True, mirror=dict(small=['lr', 'lr', None, None, None]),
            ink=48),
    4: dict(name='Lanternmaw seabed', sheet='climb-floor4-sheet.png', p=4.28,
            ground='#a8dcef',
            tones={'K': INK, 'C': '#f6f0dc', 'J': '#5db89a', 'M': '#8fe3d0',
                   'Y': '#f9df62'},
            roles=dict(slabs=[2, 3, 4, 5], pads=[0, 1], start=[6], gate=[7],
                       walls=[9, 10, 13, 15], props=[8, 11, 12, 14],
                       plants=[16, 17, 18],
                       small=[19, 20, 21, 22, 25, 23, 24, 26, 27]),
            allow=dict(slabs='C', pads='CM', start='C', gate='CY',
                       props=['J', 'M', 'J', 'M'], walls='C',
                       plants=['J', 'J', 'M'],
                       small=['Y', 'Y', 'Y', 'C', 'C', 'C', 'C', 'C', 'C']),
            island=3, glass={}, star=False,
            mirror=dict(small=['lr', 'lr', 'lr', None, None, None, None, None,
                               None]),
            open=dict(small=[False, False, False, True, True, False, False,
                             False, False]),
            ink=110),
    5: dict(name='Sableth desert', sheet='climb-floor5-sheet.png', p=4.28,
            ground='#f2e3c6',
            tones={'K': INK, 'T': '#e0c8a0', 'B': '#c58c56', 'G': '#f0a93c',
                   'U': '#a8dcef', 'C': '#f6f0dc'},
            roles=dict(slabs=[6, 3, 4, 0], pads=[1, 2], start=[5], gate=[7],
                       walls=[9, 10], props=[8, 11, 12, 13],
                       plants=[14, 15, 16, 17],
                       small=[18, 19, 20, 21, 22, 23, 24, 25]),
            allow=dict(slabs='TGU', pads='TC', start='C', gate='BGUC',
                       props='G', walls='T', plants='G',
                       small=['C', 'BC', 'GC', 'BC', 'T', 'T', 'T', 'T']),
            island=3, glass={}, star=True, mirror={}),
    6: dict(name='Pyrewing volcano', sheet='climb-floor6-sheet.png', p=4.28,
            ground='#58348d',
            tones={'K': INK, 'L': '#b99cd8', 'O': '#fb8630', 'Y': '#f9df62'},
            roles=dict(slabs=[6, 2, 3, 4], pads=[0, 1], start=[5], gate=[7],
                       walls=[8, 10, 11], props=[9, 12, 13],
                       plants=[15, 16, 14], small=[19, 21, 23, 17, 18, 20, 22]),
            allow=dict(slabs='LO', pads='LOY', start='L', gate='LOY',
                       props='L', walls='L', plants=['O', 'O', 'OY'],
                       small=['Y', 'Y', 'Y', 'L', 'L', 'L', 'L']),
            island=3, glass={}, star=False, mirror={},
            bare=dict(small=[True, True, True, False, False, False, False])),
}
# island: the biggest patch of a fill that is only the tool's shading, left
# inside another fill, to be taken back into it (0: keep every spot -- the
# toadstools' spots are two cells). glass: a hole in a piece (a lantern's
# window) drawn as this fill, a lit window, where the hole would show the ground.
# star: the stops have a small mark in the middle, to be made symmetric.


def _magenta(a):
    return (a[..., 0] > 170) & (a[..., 2] > 170) & (a[..., 1] < 110)


# ---------------------------------------------------------------- reading
def piece_boxes(a, mag):
    """Pixel boxes (x0, y0, x1, y1) of the separate pieces, trimmed."""
    solid = ~mag
    solid = ndi.binary_opening(solid, structure=np.ones((3, 3)))
    lab, _ = ndi.label(ndi.binary_dilation(solid, iterations=4),
                       structure=np.ones((3, 3)))
    boxes = []
    for i, sl in enumerate(ndi.find_objects(lab), 1):
        m = solid[sl] & (lab[sl] == i)
        if m.sum() < 250:
            continue
        ys, xs = np.nonzero(m)
        boxes.append((sl[1].start + xs.min(), sl[0].start + ys.min(),
                      sl[1].start + xs.max() + 1, sl[0].start + ys.max() + 1))
    return boxes


def _score(g, p, o):
    n = len(g)
    idx = np.round(o + p * np.arange(int((n - o) / p) + 1)).astype(int) - 1
    idx = idx[(idx >= 0) & (idx < n)]
    near = np.zeros(n, bool)
    for d in (-1, 0, 1):
        j = idx + d
        near[j[(j >= 0) & (j < n)]] = True
    return g[near].sum() / max(g.sum(), 1)


def fit_piece(a, mag, box, p0):
    """(p, ox, oy) putting the most of this piece's edges on cell borders."""
    x0, y0, x1, y1 = box
    sub = a[y0:y1, x0:x1].copy()
    sub[mag[y0:y1, x0:x1]] = 0
    gx = np.abs(np.diff(sub, axis=1)).sum(axis=2).sum(axis=0)
    gy = np.abs(np.diff(sub, axis=0)).sum(axis=2).sum(axis=1)
    best = None
    for p in np.arange(p0 - .45, p0 + .451, .03):
        sx, ox = max((_score(gx, p, o), o) for o in np.arange(0, p, .25))
        sy, oy = max((_score(gy, p, o), o) for o in np.arange(0, p, .25))
        # A smaller cell catches more edges by chance (3 cells in p are within
        # a pixel of a grid line), so the chance share is taken off.
        v = sx + sy - 6 / p
        if best is None or v > best[0]:
            best = (v, p, ox, oy)
    return best[1:]


def _mag2(a):
    """The ground, and its blends with the outline (dark magenta)."""
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    return (r > 90) & (b > 90) & (g < .45 * np.minimum(r, b))


def _n4(m):
    """The four neighbours of every cell (up, down, left, right), False
    outside."""
    q = np.pad(m, 1)
    return q[:-2, 1:-1], q[2:, 1:-1], q[1:-1, :-2], q[1:-1, 2:]


def measure(a, box, fit, tones, ink_max=80):
    """The piece on its own grid, one cell at a time: its coverage (how much of
    the cell is the piece, not the ground), how much of its middle is ink, and
    the median colour of its middle's non-ink pixels. The grid starts a cell
    before the box, so a first column of outline that sits half over the box's
    edge is whole."""
    p, ox, oy = fit
    x0, y0, x1, y1 = box
    ground = _mag2(a)
    ink = a.max(axis=2) < ink_max
    gx, gy = x0 + ox - p, y0 + oy - p
    nx, ny = int(math.ceil((x1 - gx) / p)), int(math.ceil((y1 - gy) / p))
    cov = np.zeros((ny, nx))
    dark = np.zeros((ny, nx))
    med = np.full((ny, nx, 3), np.nan)
    H, W = ground.shape

    def rect(i, j, m=0.):
        xa, xb = int(round(gx + (i + m) * p)), int(round(gx + (i + 1 - m) * p))
        ya, yb = int(round(gy + (j + m) * p)), int(round(gy + (j + 1 - m) * p))
        return max(xa, 0), min(max(xb, xa + 1), W), max(ya, 0), min(max(yb, ya + 1), H)

    for j in range(ny):
        for i in range(nx):
            xa, xb, ya, yb = rect(i, j)
            if xb > xa and yb > ya:
                cov[j, i] = 1 - ground[ya:yb, xa:xb].mean()
            xa, xb, ya, yb = rect(i, j, .18)
            if xb > xa and yb > ya:
                k, g = ink[ya:yb, xa:xb], ground[ya:yb, xa:xb]
                dark[j, i] = k.mean()
                px = a[ya:yb, xa:xb][~k & ~g]
                if len(px) >= max(2, .2 * k.size):
                    med[j, i] = np.median(px, axis=0)
    return cov, dark, med


def silhouette(cov):
    """Which cells are the piece: at least half covered, without specks, with
    its one-cell dents and pinholes filled (a dent is a cell of ground with
    the piece on three sides and open ground, wide open, on the fourth; a
    channel between two blades is left alone)."""
    S = cov >= .5
    lab, n = ndi.label(S, structure=np.ones((3, 3)))
    for k in range(1, n + 1):
        if (lab == k).sum() < 6:
            S[lab == k] = False
    for _ in range(3):
        q = np.pad(S, 2)
        changed = False
        for y, x in zip(*np.nonzero(~S)):
            Y, X = y + 2, x + 2
            sides = [(Y - 1, X), (Y + 1, X), (Y, X - 1), (Y, X + 1)]
            have = [q[t] for t in sides]
            if sum(have) == 4:
                S[y, x] = changed = True
            elif sum(have) == 3:
                (oy_, ox_), = [t for t, h in zip(sides, have) if not h]
                dy, dx = oy_ - Y, ox_ - X
                lateral = [(oy_ + dx, ox_ + dy), (oy_ - dx, ox_ - dy)]
                if not any(q[t] for t in lateral):
                    S[y, x] = changed = True
        if not changed:
            break
    return S


def outside(S):
    """The ground that is outside the piece: reached from beyond its box
    without crossing it. What is left (a lantern's glass, the slits between a
    gate's posts) is a hole, drawn as ground but not outside."""
    q = np.pad(~S, 1, constant_values=True)
    lab, _ = ndi.label(q)
    return (lab == lab[0, 0])[1:-1, 1:-1] & ~S


def read_piece(a, mag, box, p0, tones, allow=None, glass=None, island=0,
               ink_max=80, outline=True, hole_ring=True):
    """The piece as rows of letters, with its outline built rather than read:
    the silhouette is every cell that is at least half the piece; the cells on
    its outside edge are the outline, always, so it is one cell thick and has
    no gap; a fill is never left outside it. Inside, a cell is ink if its
    middle is, else the fill of its middle that is nearest of [allow]. A hole
    (ground inside the piece) of a few cells is filled in; a bigger one is
    ringed with outline like the outside (unless [hole_ring] is off: a bubble),
    or drawn as the fill [glass]. [ink_max] is how bright the darkest pixel of
    an ink cell can be. With [outline] off the piece is drawn as it is, with no
    outline forced round it (a sparkle, an ember: all outline at that size)."""
    fit = fit_piece(a, mag, box, p0)
    cov, dark, med = measure(a, box, fit, tones, ink_max)
    S = silhouette(cov)
    out = outside(S)
    up, down, left, right = _n4(~out)
    # the outline: cells of the piece (or of its holes) next to the outside
    full = ~out
    ring = full & ~(_n4(full)[0] & _n4(full)[1] & _n4(full)[2] & _n4(full)[3])
    ring &= S
    if not outline:
        ring[:] = False
    holes = ~S & ~out
    lab, n = ndi.label(holes)
    small = np.zeros_like(holes)
    for k in range(1, n + 1):
        if (lab == k).sum() <= 6:
            small |= lab == k
    big = holes & ~small
    if glass is None and hole_ring and outline:
        hu, hd, hl, hr = _n4(big)
        ring |= S & (hu | hd | hl | hr)
    ru, rd, rl, rr = _n4(ring)
    by_ring = ring | ru | rd | rl | rr
    letters = [k for k in tones if k != 'K' and (allow is None or k in allow)]
    frgb = np.array([L.hex_rgb(tones[k]) for k in letters], float)
    ny, nx = S.shape
    rows = []
    for y in range(ny):
        line = []
        for x in range(nx):
            if out[y, x]:
                line.append(L.GROUND)
            elif big[y, x] and glass is not None:
                line.append(glass)
            elif big[y, x]:
                line.append(HOLE)
            elif small[y, x]:
                line.append('?')       # filled below, from what is round it
            elif ring[y, x]:
                line.append('K')
            elif dark[y, x] >= (.65 if by_ring[y, x] else .5)                     or np.isnan(med[y, x, 0]):
                line.append('K')
            else:
                line.append(letters[int(((frgb - med[y, x]) ** 2).sum(1).argmin())])
        rows.append(line)
    return trim(tidy(rows, island))


def tidy(rows, island=0):
    """What is left to do inside the outline: a lone ink cell with no ink
    near it is noise, and a fill cell with no neighbour of its own colour that
    touches the ink takes the fill round it (a blend of the outline and a
    fill); an ink 2x2 that is not part of a solid black area is two lines drawn
    on top of each other, and the inner cells go back to the fill."""
    h, w = len(rows), len(rows[0])
    g = lambda r, y, x: r[y][x] if 0 <= y < h and 0 <= x < w else L.GROUND

    def fill_round(r, y, x):
        """The fill most of a cell's four neighbours are, else of its eight."""
        for near in (((-1, 0), (1, 0), (0, -1), (0, 1)),
                     tuple((dy, dx) for dy in (-1, 0, 1) for dx in (-1, 0, 1)
                           if dx or dy)):
            n = [g(r, y + dy, x + dx) for dy, dx in near]
            n = [c for c in n if c not in ('K', L.GROUND, HOLE)]
            if n:
                return max(set(n), key=n.count)
        return None

    for _ in range(6):                       # pockets: the fill round them
        left = [(y, x) for y in range(h) for x in range(w) if rows[y][x] == '?']
        if not left:
            break
        for y, x in left:
            f = fill_round(rows, y, x)
            if f:
                rows[y][x] = f
    for y in range(h):
        for x in range(w):
            if rows[y][x] == '?':
                rows[y][x] = 'K'
    for _ in range(3):
        out = [r[:] for r in rows]
        for y in range(h):
            for x in range(w):
                c = rows[y][x]
                four = [g(rows, y - 1, x), g(rows, y + 1, x),
                        g(rows, y, x - 1), g(rows, y, x + 1)]
                if c == 'K':
                    near = [g(rows, y + dy, x + dx) for dy in (-1, 0, 1)
                            for dx in (-1, 0, 1) if dx or dy]
                    if 'K' not in near and L.GROUND not in four:
                        f = fill_round(rows, y, x)
                        if f:
                            out[y][x] = f
                elif c != L.GROUND and c not in four and 'K' in four:
                    f = fill_round(rows, y, x)
                    if f:
                        out[y][x] = f
        rows = out
    # ink 2x2s outside solid areas
    K = np.array([[c == 'K' for c in r] for r in rows])
    solid = ndi.binary_dilation(ndi.binary_erosion(K, structure=np.ones((3, 3)),
                                                   border_value=0),
                                structure=np.ones((3, 3)))
    outer = (L.GROUND, HOLE)
    ring = np.array([[c not in outer and any(t in outer for t in (
        g(rows, y - 1, x), g(rows, y + 1, x), g(rows, y, x - 1),
        g(rows, y, x + 1))) for x, c in enumerate(r)]
        for y, r in enumerate(rows)])
    for y in range(h - 1):
        for x in range(w - 1):
            blk = [(y, x), (y, x + 1), (y + 1, x), (y + 1, x + 1)]
            if all(K[t] and not solid[t] for t in blk):
                inner = [t for t in blk if not ring[t]]
                if inner:
                    t = inner[0]
                    f = fill_round(rows, *t)
                    if f:
                        rows[t[0]][t[1]] = f
                        K[t] = False
    if island:
        rows = drop_islands(rows, island)
    return fill_pits(rows)


def fill_pits(rows):
    """A single fill cell shut in by ink on three or four sides, with no
    neighbour of its own colour, is a pit in the outline, not a colour."""
    h, w = len(rows), len(rows[0])
    g = lambda y, x: rows[y][x] if 0 <= y < h and 0 <= x < w else L.GROUND
    for y in range(h):
        for x in range(w):
            c = rows[y][x]
            if c in ('K', L.GROUND, HOLE):
                continue
            four = [g(y - 1, x), g(y + 1, x), g(y, x - 1), g(y, x + 1)]
            if c not in four and four.count('K') >= 3:
                rows[y][x] = 'K'
    return rows


def drop_islands(rows, size):
    """A patch of a fill of [size] cells or fewer whose every neighbour that is
    not ink is one other fill goes back into that fill."""
    h, w = len(rows), len(rows[0])
    for letter in {c for r in rows for c in r} - {'K', L.GROUND, HOLE}:
        mask = np.array([[c == letter for c in r] for r in rows])
        lab, n = ndi.label(mask, structure=np.ones((3, 3)))
        for k in range(1, n + 1):
            cells = list(zip(*np.nonzero(lab == k)))
            if len(cells) > size:
                continue
            around = set()
            for y, x in cells:
                for dy, dx in ((-1, 0), (1, 0), (0, -1), (0, 1)):
                    yy, xx = y + dy, x + dx
                    c = rows[yy][xx] if 0 <= yy < h and 0 <= xx < w else L.GROUND
                    if c != letter:
                        around.add(c)
            around -= {'K'}
            if len(around) == 1 and not around & {L.GROUND, HOLE}:
                for y, x in cells:
                    rows[y][x] = next(iter(around))
    return rows


def defects(rows, open_holes=False):
    """What is wrong with a piece's pixels, by kind, as lists of (x, y): a fill
    cell that touches the ground (colour seeping out of the outline), a notch
    in the silhouette, an outline cell that ends (a gap), an ink 2x2 that is
    not solid black, a lone ink cell inside, a fill cell with no neighbour of
    its colour touching the ink (a blend). A hole inside the piece is outside
    like the ground, unless [open_holes] (a bubble's: its middle is open)."""
    h, w = len(rows), len(rows[0])
    g = lambda y, x: rows[y][x] if 0 <= y < h and 0 <= x < w else L.GROUND
    outer = (L.GROUND,) if open_holes else (L.GROUND, HOLE)
    K = np.array([[c == 'K' for c in r] for r in rows])
    solid = ndi.binary_dilation(ndi.binary_erosion(K, structure=np.ones((3, 3)),
                                                   border_value=0),
                                structure=np.ones((3, 3)))
    out = {k: [] for k in ('exposed', 'notch', 'gap', 'thick', 'lone', 'blend')}
    ring = set()
    for y in range(h):
        for x in range(w):
            c = rows[y][x]
            four = [g(y - 1, x), g(y + 1, x), g(y, x - 1), g(y, x + 1)]
            if c == L.GROUND:
                if sum(f != L.GROUND for f in four) == 3:
                    (oy_, ox_), = [(y + dy, x + dx) for dy, dx, f in zip(
                        (-1, 1, 0, 0), (0, 0, -1, 1), four) if f == L.GROUND]
                    dy, dx = oy_ - y, ox_ - x
                    side = [g(oy_ + dx, ox_ + dy), g(oy_ - dx, ox_ - dy)]
                    if all(t == L.GROUND for t in side):
                        out['notch'].append((x, y))
                continue
            if c == HOLE:
                continue
            if any(t in outer for t in four):
                ring.add((x, y))
                if c != 'K':
                    out['exposed'].append((x, y))
    for x, y in ring:
        near = [(x + dx, y + dy) for dy in (-1, 0, 1) for dx in (-1, 0, 1)
                if (dx or dy)]
        if sum(t in ring for t in near) < 2:
            out['gap'].append((x, y))
    for y in range(h):
        for x in range(w):
            c = rows[y][x]
            if c == L.GROUND:
                continue
            four = [g(y - 1, x), g(y + 1, x), g(y, x - 1), g(y, x + 1)]
            if c == 'K' and (x, y) not in ring:
                near = [g(y + dy, x + dx) for dy in (-1, 0, 1)
                        for dx in (-1, 0, 1) if dx or dy]
                if 'K' not in near:
                    out['lone'].append((x, y))
            if c != 'K' and c not in four and 'K' in four:
                out['blend'].append((x, y))
            if (x + 1 < w and y + 1 < h and K[y, x] and K[y, x + 1]
                    and K[y + 1, x] and K[y + 1, x + 1]
                    and not solid[y, x] and not solid[y + 1, x + 1]):
                out['thick'].append((x, y))
    return out


def trim(rows):
    keep = [y for y, r in enumerate(rows) if any(c != L.GROUND for c in r)]
    cols = [x for x in range(len(rows[0]))
            if any(r[x] != L.GROUND for r in rows)]
    return [[r[x] for x in range(cols[0], cols[-1] + 1)]
            for r in rows[keep[0]:keep[-1] + 1]]


def roundify(rows):
    """A round stop drawn as a true pixel ellipse of its own size: the tool's
    circles are lumpy (runs of uneven lengths, a bulge on one side). The
    outline is rebuilt on the ellipse; what is inside, the moss or the star,
    stays where it was, taken from the same cell of the original. Left alone
    if the shape is not close to an ellipse."""
    h, w = len(rows), len(rows[0])
    src = np.array([[c != L.GROUND for c in r] for r in rows])
    yy, xx = np.mgrid[0:h, 0:w]
    M = (((xx + .5 - w / 2) / (w / 2)) ** 2
         + ((yy + .5 - h / 2) / (h / 2)) ** 2) <= 1.0
    if (M & src).sum() / (M | src).sum() < .9:
        return rows
    up, down, left, right = _n4(M)
    ring = M & ~(up & down & left & right)
    fills = [c for r in rows for c in r if c not in ('K', L.GROUND, HOLE)]
    common = max(set(fills), key=fills.count)
    out = [[L.GROUND] * w for _ in range(h)]
    for y in range(h):
        for x in range(w):
            if not M[y, x]:
                continue
            if ring[y, x]:
                out[y][x] = 'K'
                continue
            c = rows[y][x]
            if c == L.GROUND or (c == 'K' and any(
                    not src[yy_, xx_] or False for yy_, xx_ in ())):
                c = None
            if c in (None, L.GROUND, HOLE):
                near = [rows[j][i] for j in range(max(y - 2, 0), min(y + 3, h))
                        for i in range(max(x - 2, 0), min(x + 3, w))
                        if rows[j][i] not in ('K', L.GROUND, HOLE)]
                c = max(set(near), key=near.count) if near else common
            out[y][x] = c
    # where the original had its outline, inside the new one, that outline is
    # a thicker line than it should be: only ink the original had away from
    # its edge stays ink (the star's lines)
    old_up, old_down, old_left, old_right = _n4(src)
    old_ring = src & ~(old_up & old_down & old_left & old_right)
    for y in range(h):
        for x in range(w):
            if out[y][x] == 'K' and not ring[y, x] and old_ring[y, x]:
                near = [out[j][i] for j in range(max(y - 2, 0), min(y + 3, h))
                        for i in range(max(x - 2, 0), min(x + 3, w))
                        if out[j][i] not in ('K', L.GROUND)]
                out[y][x] = max(set(near), key=near.count) if near else common
    return out


def symmetrize_motif(rows):
    """The mark in the middle of a stop (a diamond, a star with spikes) made
    mirror-symmetric, up and down and left and right. The tool draws it nearly
    so, with a stray cell on one side; the half with fewer cells is the one
    without the stray, and is copied over the other."""
    h, w = len(rows), len(rows[0])
    cy, cx = h // 2, w // 2
    fills = [c for r in rows for c in r if c not in ('K', L.GROUND, HOLE)]
    base = max(set(fills), key=fills.count)
    R = 10
    ys = range(max(cy - R, 0), min(cy + R + 1, h))
    xs = range(max(cx - R, 0), min(cx + R + 1, w))
    motif = {(x, y) for y in ys for x in xs if rows[y][x] != base}
    # Only a small mark in one piece at the middle: not moss out by the edge.
    if not motif or any(abs(x - cx) > 7 or abs(y - cy) > 7 for x, y in motif):
        return rows
    m = np.zeros((h, w), bool)
    for x, y in motif:
        m[y, x] = True
    if ndi.label(m, structure=np.ones((3, 3)))[1] != 1:
        return rows
    rows = [r[:] for r in rows]

    def axis(count, centre):
        return max(count, key=lambda k: (count[k], -abs(k - centre)))

    rc, cc = {}, {}
    for x, y in motif:
        rc[y] = rc.get(y, 0) + 1
        cc[x] = cc.get(x, 0) + 1
    ay, ax = axis(rc, cy), axis(cc, cx)
    if abs(ay - cy) > 1 or abs(ax - cx) > 1:
        return rows
    for horizontal in (False, True):
        a = ax if horizontal else ay
        lo = {(x, y) for x, y in motif if (x if horizontal else y) < a}
        hi = {(x, y) for x, y in motif if (x if horizontal else y) > a}
        if len(lo) == len(hi):
            continue
        for d in range(1, R + 1):
            for t in (ys if horizontal else xs):
                if horizontal:
                    src, dst = (a - d, t), (a + d, t)
                else:
                    src, dst = (t, a - d), (t, a + d)
                if len(lo) > len(hi):
                    src, dst = dst, src          # the fuller half is the one copied over
                (sx, sy), (dx, dy) = src, dst
                if 0 <= sx < w and 0 <= sy < h and 0 <= dx < w and 0 <= dy < h:
                    rows[dy][dx] = rows[sy][sx]
    return rows


def mirror(rows, mode):
    """A piece that is meant to be symmetric (a lantern, a sparkle) made so:
    'lr' copies one half over the other left to right, 'ud' top to bottom,
    'both' does both. The half copied is the one with fewer ink cells, the
    cleaner of the two."""
    rows = [r[:] for r in rows]
    h, w = len(rows), len(rows[0])
    if mode in ('lr', 'both'):
        left = sum(rows[y][x] == 'K' for y in range(h) for x in range(w // 2))
        right = sum(rows[y][w - 1 - x] == 'K' for y in range(h)
                    for x in range(w // 2))
        for y in range(h):
            for x in range(w // 2):
                if left <= right:
                    rows[y][w - 1 - x] = rows[y][x]
                else:
                    rows[y][x] = rows[y][w - 1 - x]
    if mode in ('ud', 'both'):
        top = sum(rows[y][x] == 'K' for y in range(h // 2) for x in range(w))
        bottom = sum(rows[h - 1 - y][x] == 'K' for y in range(h // 2)
                     for x in range(w))
        for y in range(h // 2):
            for x in range(w):
                if top <= bottom:
                    rows[h - 1 - y][x] = rows[y][x]
                else:
                    rows[y][x] = rows[h - 1 - y][x]
    return rows


def layout(boxes, f):
    """The pieces of a floor by what they are, from the table: [roles] lists
    each kind's pieces by their place in the sheet's reading order."""
    out = {}
    for role, ids in f['roles'].items():
        for i in ids:
            assert i < len(boxes), ('the sheet has %d pieces, no %d (%s)'
                                    % (len(boxes), i, role))
        out[role] = [boxes[i] for i in ids]
    used = sorted(i for ids in f['roles'].values() for i in ids)
    assert len(used) == len(set(used)), 'a piece has two roles'
    return out


_SHEETS = {}


def read_sheet(floor, verbose=False):
    """The parts of a floor (by kind, each a list of pieces as rows of letters)
    and every piece read, with its box on the sheet. Cached: reading is the slow
    part."""
    if floor not in _SHEETS:
        _SHEETS[floor] = _read_sheet(floor, verbose)
    return _SHEETS[floor]


def option(spec, role, k):
    """A piece's entry in one of the table's options: a role's entry is one
    value for all its pieces, or a list with one for each."""
    v = spec.get(role)
    return v[k] if isinstance(v, list) else v


def load_sheet(f):
    """The sheet's pixels, with the generator's sparkle painted out: it is
    paler than the ground it sits on, so it would be read as a piece."""
    im = Image.open(os.path.join(HERE, f['sheet'])).convert('RGB')
    a = np.asarray(im).astype(float)
    x0, y0, x1, y1 = WATERMARK
    sub = a[y0:y1, x0:x1]
    sparkle = ((sub[..., 0] > 230) & (sub[..., 2] > 220)
               & (sub[..., 1] > 105) & (sub[..., 1] < 200))
    sub[sparkle] = (255, 0, 255)
    return a


def _read_sheet(floor, verbose=False):
    f = FLOORS[floor]
    a = load_sheet(f)
    mag = _magenta(a)
    roles = layout(piece_boxes(a, mag), f)
    parts, pieces = {}, []
    for role, boxes in roles.items():
        got = []
        for k, box in enumerate(boxes):
            allow = option(f['allow'], role, k)
            glass = option(f['glass'], role, k)
            rows = read_piece(
                a, mag, box, f['p'], f['tones'], allow, glass, f['island'],
                ink_max=f.get('ink', 80),
                outline=not option(f.get('bare', {}), role, k),
                hole_ring=not option(f.get('open', {}), role, k))
            how = option(f['mirror'], role, k)
            if how:
                rows = mirror(rows, how)
            if role == 'pads':
                rows = roundify(rows)
                if f['star']:
                    rows = symmetrize_motif(rows)
            got.append(rows)
            pieces.append((box, rows, role, k))
        parts[role] = got
    if verbose:
        print('floor', floor, {k: len(v) for k, v in parts.items()})
    parts['start'], parts['gate'] = parts['start'][0], parts['gate'][0]
    return parts, pieces


# --------------------------------------------------------------- the map
def spline(pts, n=40):
    """A smooth line through [pts] (Catmull-Rom), as a dense list of points."""
    p = [pts[0]] + list(pts) + [pts[-1]]
    out = []
    for i in range(1, len(p) - 2):
        for k in range(n):
            t = k / n
            a, b, c, d = p[i - 1], p[i], p[i + 1], p[i + 2]
            out.append(tuple(
                .5 * (2 * b[j] + (-a[j] + c[j]) * t
                      + (2 * a[j] - 5 * b[j] + 4 * c[j] - d[j]) * t * t
                      + (-a[j] + 3 * b[j] - 3 * c[j] + d[j]) * t ** 3)
                for j in (0, 1)))
    out.append(pts[-1])
    return out


def floor_scale(floor):
    """Units a pixel is on this floor. The sheets are drawn on grids of their
    own, so a stop pad is a different number of pixels on each; scaling the
    pixels so that it is PAD_UNITS wide on all of them keeps every floor's
    stones the same size, and costs only a slightly different pixel."""
    parts, _ = read_sheet(floor)
    pad = max(max(len(p[0]), len(p)) for p in parts['pads'])
    return PAD_UNITS / pad


def canvas_of(floor):
    """The floor's picture in cells: a home scene's 864 x 1872 units."""
    scale = floor_scale(floor)
    return math.ceil(UNITS_W / scale), math.ceil(UNITS_H / scale)


def build(floor, seed=7):
    """The floor as rows of letters (one cell a pixel) and the centre of each
    of its five stops, bottom to top, in cells."""
    rnd = random.Random(seed * 10 + floor)
    parts, _ = read_sheet(floor)
    scale = floor_scale(floor)
    W, H = canvas_of(floor)
    grid = [[L.GROUND] * W for _ in range(H)]

    def stamp(rows, cx, bottom):
        h, w = len(rows), len(rows[0])
        x0, y0 = int(round(cx - w / 2)), int(round(bottom - h))
        for j, r in enumerate(rows):
            for i, c in enumerate(r):
                x, y = x0 + i, y0 + j
                if c not in (L.GROUND, HOLE) and 0 <= x < W and 0 <= y < H:
                    grid[y][x] = c
        return x0, y0, x0 + w, y0 + h

    u = lambda v: v / scale                  # units to cells
    mid = u(UNITS_W / 2)
    stops = [(mid - u(90), u(1560)), (mid + u(100), u(1300)),
             (mid - u(100), u(1040)), (mid + u(95), u(780)),
             (mid - u(60), u(520))]
    line = spline([(mid, u(1800))] + stops + [(mid, u(350))])
    dist = [0.]
    for a, b in zip(line, line[1:]):
        dist.append(dist[-1] + math.hypot(b[0] - a[0], b[1] - a[1]))

    def at(s):
        i = min(max(next((k for k, d in enumerate(dist) if d >= s),
                         len(dist) - 1), 1), len(line) - 1)
        a, b = line[i - 1], line[i]
        n = math.hypot(b[0] - a[0], b[1] - a[1]) or 1
        return b, ((b[0] - a[0]) / n, (b[1] - a[1]) / n)

    def corridor(x, y):
        return min(math.hypot(x - p[0], y - p[1]) for p in line[::3])

    # The wall behind the gate, then the gate.
    # The wall: blocks side by side. They are stacks with stepped edges, so
    # touching at their boxes leaves slits and pockets. Each block is put as far
    # right as it can go with no gap in any row against what is already there:
    # in the loosest row it shares one column of outline with the last block, in
    # the others it overlaps it, and its own outline is drawn over (the later
    # block closes the joint).
    right = {}                                   # row -> rightmost column used

    def place_wall(rows, bottom, at):
        y0 = int(round(bottom - len(rows)))
        firsts = [next((i for i, c in enumerate(r) if c not in (L.GROUND, HOLE)),
                       None) for r in rows]
        limits = [right[y0 + j] - f for j, f in enumerate(firsts)
                  if f is not None and (y0 + j) in right]
        x0 = min(limits) if limits else at
        for j, r in enumerate(rows):
            y = y0 + j
            if not 0 <= y < H:
                continue
            for i, c in enumerate(r):
                x = x0 + i
                if c not in (L.GROUND, HOLE) and 0 <= x < W:
                    grid[y][x] = c
                    right[y] = max(right.get(y, -10 ** 6), x)
        return x0 + len(rows[0])

    nxt = -u(60)
    while nxt < W + u(60):
        w = rnd.choice(parts['walls'])
        end = place_wall(w, u(300), int(round(nxt))) - 1
        nxt = end
    stamp(parts['gate'], mid, u(370))

    # Slabs in each gap of the line between one stop and the next: the line's
    # arclength at every stop, then the slabs that fit between the pads' edges,
    # the group centred in the gap.
    pad_w = max(len(p[0]) for p in parts['pads'])
    along = [0.] + [dist[min(range(len(line)), key=lambda i: math.hypot(
        line[i][0] - sx, line[i][1] - sy))] for sx, sy in stops] + [dist[-1]]
    reach = [len(parts['start']) / 2 + 1] + [pad_w / 2 + 1] * len(stops) + [0]
    for k in range(len(along) - 1):
        a, b = along[k] + reach[k], along[k + 1] - reach[k + 1]
        mid_s = (a + b) / 2
        (_, _), (tx, ty) = at(mid_s)
        ext = lambda sl: abs(tx) * len(sl[0]) + abs(ty) * len(sl)
        chosen, used = [], 0.
        for _ in range(8):
            fits = [sl for sl in parts['slabs']
                    if used + ext(sl) + 2 * (len(chosen) > 0) <= b - a]
            if not fits:
                break
            sl = rnd.choice(fits)
            used += ext(sl) + 2 * (len(chosen) > 0)
            chosen.append(sl)
        s = a + (b - a - used) / 2
        for sl in chosen:
            (px, py), _ = at(s + ext(sl) / 2)
            stamp(sl, px + rnd.randint(-1, 1), py + len(sl) / 2)
            s += ext(sl) + 2
    centres = []                         # where each pad really ended up, in cells
    for k, (sx, sy) in enumerate(stops):
        pad = parts['pads'][k % 2]
        x0, y0, x1, y1 = stamp(pad, sx, sy + len(pad) / 2)
        centres.append(((x0 + x1) / 2, (y0 + y1) / 2))
    stamp(parts['start'], mid, u(1850))

    # Scenery either side, never on the path, never on each other.
    taken = []
    free = lambda b: all(b[2] + 2 <= t[0] or t[2] + 2 <= b[0]
                         or b[3] + 2 <= t[1] or t[3] + 2 <= b[1]
                         for t in taken)
    if parts['props'] and parts['plants']:
        want = (parts['props'] + [rnd.choice(parts['props'])] + parts['plants']
                + [rnd.choice(parts['plants']), rnd.choice(parts['plants'])]
                + parts['small'])
    else:                                    # a floor with no scenery
        want = []
    rnd.shuffle(want)
    placed = []
    for rows in want:
        h, w = len(rows), len(rows[0])
        for _ in range(80):
            cx = rnd.uniform(w * .3, W - w * .3)
            by = rnd.uniform(u(430), H - 2)
            if min(corridor(cx + dx, by - dy)
                   for dx in (-w / 2, 0, w / 2) for dy in (0, h / 2, h)) < u(100):
                continue
            box = (cx - w / 2, by - h, cx + w / 2, by)
            if free(box):
                taken.append(box)
                placed.append((by, rows, cx))
                break
    for by, rows, cx in sorted(placed, key=lambda t: t[0]):
        stamp(rows, cx, by)
    seal_pockets(grid)
    fill_pits(grid)
    return grid, centres


def seal_pockets(grid, size=4):
    """A bit of ground shut in between pieces that meet (the little diamond
    where two rounded blocks touch) is a hole in the picture: ink fills it."""
    g = np.array([[c == L.GROUND for c in r] for r in grid])
    lab, n = ndi.label(g)
    edge = set(np.unique(np.concatenate(
        [lab[0], lab[-1], lab[:, 0], lab[:, -1]])))
    for k in range(1, n + 1):
        if k not in edge and (lab == k).sum() <= size:
            for y, x in zip(*np.nonzero(lab == k)):
                grid[y][x] = 'K'


# -------------------------------------------------------------- the output
def colours(floor):
    f = FLOORS[floor]
    return dict(f['tones']), f['ground']


def preview_scale(floor):
    """Whole pixels to a cell, for the previews."""
    return max(1, round(floor_scale(floor)))


def write_png(rows, floor, path, scale=None):
    scale = scale or preview_scale(floor)
    tones, ground = colours(floor)
    rgb = {k: L.hex_rgb(v) for k, v in tones.items()}
    rgb[L.GROUND] = L.hex_rgb(ground)
    im = Image.new('RGB', (len(rows[0]), len(rows)))
    for y, r in enumerate(rows):
        for x, c in enumerate(r):
            im.putpixel((x, y), rgb[c])
    im.resize((im.width * scale, im.height * scale), Image.NEAREST).save(path)


def write_svg(rows, floor, path, scale=None):
    scale = scale or preview_scale(floor)
    tones, ground = colours(floor)
    paths = {}
    for y, r in enumerate(rows):
        x = 0
        while x < len(r):
            c, run = r[x], 1
            while x + run < len(r) and r[x + run] == c:
                run += 1
            if c != L.GROUND:
                paths.setdefault(tones[c], []).append(
                    'M%d %dh%dv%dh-%dz' % (x * scale, y * scale, run * scale,
                                           scale, run * scale))
            x += run
    w, h = len(rows[0]) * scale, len(rows) * scale
    with open(path, 'w', encoding='utf-8', newline='\n') as f:
        f.write('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %d %d" '
                'shape-rendering="crispEdges"><rect width="%d" height="%d" '
                'fill="%s"/>' % (w, h, w, h, ground))
        for fill, d in paths.items():
            f.write('<path fill="%s" d="%s"/>' % (fill, ''.join(d)))
        f.write('</svg>\n')


APP_ASSETS = os.path.normpath(os.path.join(HERE, '..', 'assets', 'svgs'))
APP_DART = os.path.normpath(os.path.join(
    HERE, '..', 'lib', 'constants', 'boss_climb_art.dart'))


def app_svg(rows, floor):
    """The floor as the app's copy: through the home scenes' own writer
    (`scene_art.asset_svg`), one path a colour with each fill grown a pixel
    under the ink and the fills painted after it, so that no hairline of the
    ground shows between two colours at a fractional scale; it also reads its
    own output back and checks it reproduces the picture."""
    tones, ground = colours(floor)
    fills = [k for k in tones if k != 'K']
    palette = SA.Palette(
        [('ground', ground)] + [(k, tones[k]) for k in fills]
        + [('ink', tones['K'])])
    index = {L.GROUND: 0, **{k: i for i, k in enumerate(fills, 1)},
             'K': len(fills) + 1}
    classes = np.array([[index[c] for c in r] for r in rows], np.int8)
    return SA.asset_svg(classes, palette)


DART_HEAD = """\
// GENERATED by art_src/gen_climb.py --app. Do not edit by hand: change the art
// or the script and run it again.

/// One floor of the boss climb map: its picture, and where its five stops are
/// on it.
///
/// Everything is in the picture's own cells (one pixel of the art), so a
/// screen of any width lays the stops over it by scaling as the picture does.
class ClimbFloorArt {
  const ClimbFloorArt({
    required this.asset,
    required this.width,
    required this.height,
    required this.ground,
    required this.pad,
    required this.stops,
  });

  final String asset;
  final double width;
  final double height;

  /// Its ground colour, 0xAARRGGBB: what shows before the picture has loaded.
  final int ground;

  /// How wide its widest stop pad is.
  final double pad;

  /// Where each stop's pad is centred, bottom to top: the floor's first fight
  /// to its finale.
  final List<(double, double)> stops;
}

/// The floors of the climb, first (the bottom) to last.
const List<ClimbFloorArt> climbFloorArt = [
"""


def dart_source(floors):
    """`lib/constants/boss_climb_art.dart`: where each floor's picture is and
    where its five stops sit on it, in the picture's own cells."""
    out = [DART_HEAD]
    for n in floors:
        grid, stops = build(n)
        parts, _ = read_sheet(n)
        pad = max(max(len(p[0]), len(p)) for p in parts['pads'])
        _, ground = colours(n)
        points = ''.join('      (%.1f, %.1f),\n' % s for s in stops)
        out.append(
            "  ClimbFloorArt(\n"
            "    asset: 'assets/svgs/climb_floor_%d.svg',\n"
            "    width: %d,\n"
            "    height: %d,\n"
            "    ground: 0xFF%s,\n"
            "    pad: %d,\n"
            "    stops: [\n%s    ],\n"
            "  ),\n" % (n, len(grid[0]), len(grid), ground[1:].upper(), pad,
                        points))
    out.append('];\n')
    return ''.join(out)


def sheet_preview(floor, path):
    """The sheet as read, on magenta, in piece order."""
    parts, pieces = read_sheet(floor)
    tones, _ = colours(floor)
    rgb = {k: L.hex_rgb(v) for k, v in tones.items()}
    rgb[L.GROUND] = (255, 0, 255)
    rgb[HOLE] = (255, 120, 255)
    W = max(b[2] for b, *_ in pieces) // 4 + 20
    H = max(b[3] for b, *_ in pieces) // 4 + 20
    im = Image.new('RGB', (W, H), (255, 0, 255))
    for box, rows, *_ in pieces:
        for j, r in enumerate(rows):
            for i, c in enumerate(r):
                x, y = box[0] // 4 + i, box[1] // 4 + j
                if c != L.GROUND and x < W and y < H:
                    im.putpixel((x, y), rgb[c])
    im.resize((W * 3, H * 3), Image.NEAREST).save(path)


def check(floors):
    """Read every piece of every floor and report what defects() finds."""
    total = 0
    for n in floors:
        _, pieces = read_sheet(n)
        for box, rows, role, k in pieces:
            d = {t: v for t, v in defects(
                rows, option(FLOORS[n].get('open', {}), role, k)).items() if v}
            if option(FLOORS[n].get('bare', {}), role, k):
                d.pop('exposed', None)
                d.pop('gap', None)
            total += sum(len(v) for v in d.values())
            if d:
                print('floor %d %-6s %d (%dx%d): %s' % (
                    n, role, k, len(rows[0]), len(rows),
                    ', '.join('%s %d' % (t, len(v)) for t, v in d.items())))
    print('defects in total:', total)


def main(argv):
    floors = [int(a) for a in argv if a.isdigit()] or list(FLOORS)
    if '--check' in argv:
        return check(floors)
    out = argv[argv.index('--preview') + 1] if '--preview' in argv else None
    for n in floors:
        if out:
            os.makedirs(out, exist_ok=True)
            sheet_preview(n, os.path.join(out, 'sheet%d.png' % n))
        grid, stops = build(n)
        if '--app' in argv:
            with open(os.path.join(APP_ASSETS, 'climb_floor_%d.svg' % n), 'w',
                      encoding='utf-8', newline='\n') as f:
                f.write(app_svg([''.join(r) for r in grid], n))
        rows = [''.join(r) for r in grid]
        tones, _ = colours(n)
        used = {c for r in rows for c in r} - {L.GROUND}
        print('floor %d %s: %d x %d cells at %.2f units, colours %s' % (
            n, FLOORS[n]['name'], len(rows[0]), len(rows), floor_scale(n),
            sorted(used)))
        if out:
            write_png(rows, n, os.path.join(out, 'floor%d.png' % n))
        if '--write' in argv:
            write_png(rows, n, os.path.join(HERE, 'climb-floor-%d.png' % n))
            write_svg(rows, n, os.path.join(HERE, 'climb-floor-%d.svg' % n))
            with open(os.path.join(HERE, 'climb-floor-%d.json' % n), 'w',
                      encoding='utf-8', newline='\n') as f:
                unit = floor_scale(n)
                json.dump({'cells': [len(rows[0]), len(rows)],
                           'units_a_cell': round(unit, 3),
                           'stops': [[round(x * unit), round(y * unit)]
                                     for x, y in stops]},
                          f)
                f.write('\n')
    if '--app' in argv:
        with open(APP_DART, 'w', encoding='utf-8', newline='\n') as f:
            f.write(dart_source(sorted(FLOORS)))
        print('wrote assets/svgs/climb_floor_N.svg and',
              os.path.relpath(APP_DART, os.path.join(HERE, '..')))


if __name__ == '__main__':
    main(sys.argv[1:])
