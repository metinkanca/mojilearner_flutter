"""Builds the Pyrewing boss sprites from the source art.

    python gen_dragon.py            # writes assets/svgs/dragon_boss*.svg
    python gen_dragon.py --map      # prints the face as a cell map
    python gen_dragon.py --map --open

The owner's dragon from `pyrewing-larger-wings-symmetric.svg`: four flat
colour paths on a 1-unit grid, each an even-odd outline, painted in document
order (outline, fire-red, gold, cream). It replaced `pyrewing-editable.svg`
on 2026-10-09 (`gen_dragon_v1.py` still builds that one). It is drawn 136
cells wide, on the set's own grid, so it is not shrunk as the old one was:
its pixels already match the other bosses' and its arena's. lib_boss.py says
why the sprite is rebuilt rather than drawn as-is. Emits, the way
gen_mossback.py does:

  dragon_boss.svg       the sprite, one traced path per colour, each painted
                        over the union of everything above it -- no seams.
  dragon_boss_open.svg  the same with its jaws open, for the roar and the
                        fire. Swapped in whole.

A run prints the numbers `trial_boss.dart` and `dragon_pieces.dart` take from
the art: its cell grid, the middle of the open jaws, the middle of the belly,
where hits land, and the two eyes the sleeping dragon's lids close over.

Re-run after any edit to the source art; never hand-edit the outputs.
"""
import sys
from collections import deque

import lib_boss
from lib_boss import MOUTH, TONGUE

SRC = 'pyrewing-larger-wings-symmetric.svg'

K = '#14120e'        # outline, eyes, mouth line
BODY = '#cf4f2f'     # fire-red: body, wings, the tail's stump
GOLD = '#f0a93c'     # muzzle, belly plates, wing membranes, the flame
CREAM = '#fbe9bf'    # horns, claws, fangs, the flame's core

ORDER = [K, BODY, GOLD, CREAM, MOUTH, TONGUE]
LETTERS = {K: 'K', BODY: 'o', GOLD: 'y', CREAM: 'c', MOUTH: 'R', TONGUE: 'G'}

# The jaws: an oval over the closed mouth, in the gold of the muzzle. The
# mouth's own axis is the boundary between cells 103 and 104.
CX, CY, RX, RY = 104, 77, 9.5, 4
# The fangs, each two cells wide as the closed mouth draws them, hanging from
# the roof of the open jaws at the same x.
FANGS = (97, 109)
FANG_WIDTH, FANG_LENGTH = 2, 3

# Where the eyes are drawn, to find them again after any edit: the face's
# interior, which holds the two eyes and no outline.
FACE = (84, 54, 118, 68)


def _inside(x, y, rx, ry):
    return ((x + 0.5 - CX) / rx) ** 2 + ((y + 0.5 - CY) / ry) ** 2 <= 1


def open_jaws(g):
    """The roar: [g] with the jaws open.

    The closed mouth is a box of outline across the gold muzzle with a cream
    fang hanging from each end of it. The open pose draws over it an oval maw
    in the art's two-cell outline, with a fang down from each side of its
    roof, flat at the tip, and the tongue along its floor.
    """
    out = dict(g)
    ring = [(x, y) for x in range(int(CX - RX) - 3, int(CX + RX) + 4)
            for y in range(int(CY - RY) - 3, int(CY + RY) + 4)
            if _inside(x, y, RX + 2, RY + 2)]
    for cell in ring:
        assert g.get(cell) in (K, GOLD, CREAM), (cell, g.get(cell))
        out[cell] = K
    for x, y in ring:
        if _inside(x, y, RX, RY):
            out[(x, y)] = TONGUE if y >= CY + 1.5 else MOUTH
    for x0 in FANGS:
        cols = range(x0, x0 + FANG_WIDTH)
        roof = {x: min(y for (cx, y), f in out.items()
                       if cx == x and f in (MOUTH, TONGUE)) for x in cols}
        tip = max(roof.values()) + FANG_LENGTH - 1
        for x in cols:
            for y in range(roof[x], tip + 1):
                out[(x, y)] = CREAM
    return out


def belly(g):
    """The middle of the belly plates: the gold under the muzzle, right of
    the tail."""
    cells = [(x, y) for (x, y), f in g.items()
             if f == GOLD and y > 85 and x > 70]
    xs = [x for x, _ in cells]
    ys = [y for _, y in cells]
    return (min(xs) + max(xs) + 1) / 2, (min(ys) + max(ys) + 1) / 2


def eyes(g):
    """[(x, y, w, h)] for each eye with its brow: the outline cells inside
    FACE that touch one another, left to right."""
    fx0, fy0, fx1, fy1 = FACE
    left = {(x, y) for (x, y), f in g.items()
            if f == K and fx0 <= x < fx1 and fy0 <= y < fy1}
    found = []
    while left:
        queue = deque([left.pop()])
        blob = list(queue)
        while queue:
            x, y = queue.popleft()
            for dx, dy in lib_boss.N8:
                if (x + dx, y + dy) in left:
                    left.remove((x + dx, y + dy))
                    queue.append((x + dx, y + dy))
                    blob.append((x + dx, y + dy))
        xs = [x for x, _ in blob]
        ys = [y for _, y in blob]
        found.append((min(xs), min(ys), max(xs) - min(xs) + 1,
                      max(ys) - min(ys) + 1))
    assert len(found) == 2, found
    return sorted(found)


if __name__ == '__main__':
    closed = lib_boss.grid(SRC, 1)
    if '--map' in sys.argv:
        lib_boss.print_map(open_jaws(closed) if '--open' in sys.argv
                           else closed, LETTERS, 76, 50, 132, 92)
        sys.exit(0)

    opened = open_jaws(closed)
    x0, y0, x1, y1 = lib_boss.bounds(closed)
    assert lib_boss.bounds(opened) == (x0, y0, x1, y1)
    w, h = x1 - x0, y1 - y0
    for name, cells in (('dragon_boss.svg', closed),
                        ('dragon_boss_open.svg', opened)):
        lib_boss.write(name, lib_boss.emit(cells, ORDER, x0, y0, w, h))
    bx, by = belly(closed)
    # CX is a coordinate, not a cell: the jaws' middle already.
    print('viewBox 0 0 %d %d; mouth x %.1f' % (w, h, CX - x0))
    print('belly %.1f, %.1f -> hitX %.2f, hitY %.2f'
          % (bx - x0, by - y0, (bx - x0) / w, (by - y0) / h))
    print('eyes (left, top, width, height): %s'
          % ', '.join('(%d, %d, %d, %d)' % (x - x0, y - y0, ew, eh)
                      for x, y, ew, eh in eyes(closed)))
