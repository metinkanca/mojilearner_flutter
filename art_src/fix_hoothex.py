"""Tidies the owner's Hoothex before she goes in the game: borders and feet.

    python fix_hoothex.py            # writes hoothex-clean-grid-fixed.svg
    python fix_hoothex.py --check    # prints the rim's numbers, writes nothing

One run, from the owner's `hoothex-clean-grid.svg` (left untouched), to
`hoothex-clean-grid-fixed.svg`, which is the master from then on, the way
`pyrewing-larger-wings-symmetric.svg` is Pyrewing's: edit that by hand, and
`gen_hoothex.py` builds the game's sprites from it. Do not run this on it.

  Borders  The outline was two cells thick for the most part, but one cell
           thick in some places (the broom's top and bottom, the hat's brim)
           and three in others (the stick's underside, the wing). It is
           rebuilt from the fills: every fill cell is ringed by the cells
           within two cells of it (a distance of up to the root of 5, which
           is two cells straight and three along a diagonal, so a diagonal
           edge is as thick as a straight one), and what was outline beyond
           that and open to the outside is dropped. Outline between fills,
           and inside them (the wing's feathers, the brows, the buckle's
           hole, the toes' gaps), is not on the rim and is left as drawn.
           A cell of background shut in on three sides is filled.

  Feet     Each was a different shape (toes 6-1-4-2-4 on the left, 6-2-3-2-4
           on the right, the left dome a row higher). Both are now one foot,
           stamped at the two feet's own middles: a dome seven cells wide at
           the top and seventeen where it meets the stick, over three toes
           5-2-3-2-5, the same either side of its own middle, and each the
           mirror of the other.

The master is written the way the owner's file is: one even-odd path a
colour, each of that colour's cells alone (so none is painted over another),
over a white rect.
"""
import math
import os
import sys
from collections import deque

import deseam
import lib_boss

SRC = 'hoothex-clean-grid.svg'
OUT = 'hoothex-clean-grid-fixed.svg'

K = '#14120e'        # outline, brows, eyes, the buckle's hole
PURPLE = '#5b3f8c'
CREAM = '#ffefcd'
GOLD = '#f0a93c'
BROWN = '#8a5a3c'

# The master's paths, in the owner's order, with the ids they gave them.
PATHS = [('outline', K), ('witch-purple', PURPLE), ('cream', CREAM),
         ('gold', GOLD), ('broom-brown', BROWN)]

W, H = 154, 128

# A fill's ring: every offset within the root of 5 of it.
RING = [(dx, dy) for dx in range(-2, 3) for dy in range(-2, 3)
        if dx * dx + dy * dy <= 5]

# ---- the foot ----

# The two feet's middles (cell columns), and the dome's top row.
FEET_X = (78, 114)
DOME_TOP = 105
# Half-widths of the dome, a row each from DOME_TOP: 7, 11, 13, 15, 17 wide.
DOME = (3, 5, 6, 7, 8)
# The toes, either side of the middle, over the rows from the stick's top to
# the bottom of the toes, and the gold's widest half-width.
TOES = ((-8, -4), (-1, 1), (4, 8))
TOE_TOP, TOE_BOTTOM, HALF = 110, 116, 8


def foot():
    """The foot's gold, as (u, y) with u from its middle."""
    gold = set()
    for i, half in enumerate(DOME):
        gold |= {(u, DOME_TOP + i) for u in range(-half, half + 1)}
    for y in range(TOE_TOP, TOE_BOTTOM + 1):
        gold |= {(u, y) for a, b in TOES for u in range(a, b + 1)}
    # The outer toes' outer corners are rounded off on the bottom row.
    gold -= {(-HALF, TOE_BOTTOM), (HALF, TOE_BOTTOM)}
    return gold


def symmetric_feet(g):
    """[g] with both feet redrawn as the same foot."""
    out = dict(g)
    gold = foot()
    for cx in FEET_X:
        cells = {(cx + u, y) for u, y in gold}
        for x, y in cells:
            for dx, dy in RING:
                out[(x + dx, y + dy)] = K
        for cell in cells:
            out[cell] = GOLD
    return out


# ---- the rim ----

def tidy_rim(g):
    """[g] with its outline two cells thick all the way round."""
    fills = {c for c, f in g.items() if f != K}
    near = set()
    for x, y in fills:
        for dx, dy in RING:
            near.add((x + dx, y + dy))
    xs = [x for x, _ in near]
    ys = [y for _, y in near]
    x0, x1 = min(xs) - 2, max(xs) + 3
    y0, y1 = min(ys) - 2, max(ys) + 3

    # The outside: what can be reached from the frame without crossing a
    # fill's ring.
    outside = set()
    queue = deque()
    for x in range(x0, x1):
        for y in (y0, y1 - 1):
            outside.add((x, y))
            queue.append((x, y))
    for y in range(y0, y1):
        for x in (x0, x1 - 1):
            if (x, y) not in outside:
                outside.add((x, y))
                queue.append((x, y))
    while queue:
        x, y = queue.popleft()
        for dx, dy in lib_boss.N4:
            c = (x + dx, y + dy)
            if (x0 <= c[0] < x1 and y0 <= c[1] < y1
                    and c not in near and c not in outside):
                outside.add(c)
                queue.append(c)

    out = {c: g.get(c, K) for c in near}
    # Outline out of any ring and not open to the outside is inside the art
    # (the buckle's hole, the eyes): left alone. The rest is the old rim's
    # excess, and goes.
    for c, f in g.items():
        if c not in near and c not in outside:
            out[c] = f
    return out


def fill_dents(g):
    """Background shut in on three sides, or squeezed between two cells of
    art, takes the outline's colour: it is a one-cell notch in the rim."""
    out = dict(g)
    xs = [x for x, _ in g]
    ys = [y for _, y in g]
    for x in range(min(xs) - 1, max(xs) + 2):
        for y in range(min(ys) - 1, max(ys) + 2):
            if (x, y) in g:
                continue
            n = [(x + dx, y + dy) in g for dx, dy in lib_boss.N4]
            right, left, down, up = n
            if sum(n) >= 3 or (right and left) or (down and up):
                out[(x, y)] = K
    return out


def tidy(g):
    return fill_dents(tidy_rim(symmetric_feet(g)))


# ---- checks ----

def rim_runs(g):
    """{thickness: count} of outline run lengths in from the outside, one
    per rim cell and direction. A diagonal edge counts its stair-steps, so
    the numbers run above two where the art is right; the point of them is
    that the ones and the long ones go."""
    runs = {}
    for (x, y), f in g.items():
        if f != K:
            continue
        for dx, dy in lib_boss.N4:
            if (x - dx, y - dy) in g:
                continue
            n, c = 0, (x, y)
            while g.get(c) == K:
                n += 1
                c = (c[0] + dx, c[1] + dy)
            runs[n] = runs.get(n, 0) + 1
    return dict(sorted(runs.items()))


def bare(g):
    """Cells of fill touching the outside: there should be none."""
    return sorted((x, y) for (x, y), f in g.items() if f != K and any(
        (x + dx, y + dy) not in g for dx, dy in lib_boss.N4))


def ring_off(g):
    """(thin, thick): cells within the ring of the outside that are not
    outline, and outline in the ring beyond it that is not part of a line
    running in."""
    thin = thick = 0
    for c, f in g.items():
        d2 = min((dx * dx + dy * dy
                  for dx in range(-4, 5) for dy in range(-4, 5)
                  if (dx or dy) and (c[0] + dx, c[1] + dy) not in g),
                 default=99)
        if d2 <= 5 and f != K:
            thin += 1
        if 5 < d2 <= 10 and f == K:
            thick += 1
    return thin, thick


# ---- the master ----

def write_master(g, path):
    deseam.VBX, deseam.VBY, deseam.VBW, deseam.VBH = 0, 0, W, H
    body = []
    for name, fill in PATHS:
        mask = [1 if g.get((x, y)) == fill else 0
                for y in range(H) for x in range(W)]
        d = deseam.emit(deseam.trace(mask))
        body.append('  <path id="%s" fill="%s" fill-rule="evenodd" d="%s"/>\n'
                    % (name, fill, d))
    svg = (
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<svg xmlns="http://www.w3.org/2000/svg" width="1386" height="1152"'
        ' viewBox="0 0 %d %d" shape-rendering="crispEdges">\n'
        '  <title>Hoothex — clean pixel grid, borders and feet fixed'
        '</title>\n'
        '  <desc>The owner\'s hoothex-clean-grid.svg with its outline two '
        'cells thick all round and both feet the same symmetric foot '
        '(fix_hoothex.py). Five flat colours, one path each, each its own '
        'cells only.</desc>\n'
        '  <rect id="background" width="%d" height="%d" fill="#ffffff"/>\n'
        % (W, H, W, H)
        + ''.join(body) + '</svg>\n')
    with open(path, 'w', encoding='utf-8') as f:
        f.write(svg)


def main():
    old = lib_boss.grid(SRC, 1)
    new = tidy(old)
    print('rim runs  before %s' % rim_runs(old))
    print('          after  %s' % rim_runs(new))
    print('fill on the outside: before %d, after %d'
          % (len(bare(old)), len(bare(new))))
    print('thin / thick rim cells: before %s, after %s'
          % (ring_off(old), ring_off(new)))
    if '--check' in sys.argv:
        return
    path = os.path.join(lib_boss.HERE, OUT)
    write_master(new, path)
    print('wrote %s' % path)
    # The file must read back as exactly this art.
    back = lib_boss.grid(OUT, 1)
    assert back == new, 'master does not round-trip'
    print('round-trips: %d cells' % len(back))


if __name__ == '__main__':
    main()
