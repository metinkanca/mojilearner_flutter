# -*- coding: utf-8 -*-
"""Shared machinery for the pet backgrounds drawn to the forest's grammar.

`forest-clean-tones.svg` is the reference every one of these follows: a
360x780 canvas on a strict 2-unit grid, `shape-rendering="crispEdges"`, no
gradients, strokes, opacity, transforms or groups, and one flat path per
colour named for what it is. Its composition is the part worth copying -- a
big empty band up top, every landmark packed into a mid band, and a plain
ground the pet can stand on without competing with it -- and its horizon is
y560, which is where the ground starts in all of them.

A scene here is authored as a grid of cells rather than as paths. Every
coordinate a generator writes is a cell, doubled on the way out, which is what
makes the 2-unit grid a property of the format instead of something to check
afterwards. Tracing is deseam's, so each colour leaves as a single path traced
from its own region boundary.

Generators supply the drawing and the palette; everything they have in common
is here. See `gen_cafe.py` and `gen_cafe_street.py`.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import deseam  # noqa: E402  (needs the path above)

HERE = os.path.dirname(os.path.abspath(__file__))

# The canvas, in cells. Doubled on emit: 360x780, the forest's canvas. A
# scene that is not a full screen -- one building off a street sheet, say --
# calls `canvas()` first to resize it.
COLS, ROWS, CELL = 180, 390, 2


def canvas(cols, rows):
    """Resize the grid. Import this module as a module to use it: the helpers
    read COLS and ROWS at call time, but `from lib_scene import COLS` binds a
    copy that this cannot reach."""
    global COLS, ROWS
    COLS, ROWS = cols, rows

# The forest's horizon, y560, in cells. Everything below it is ground.
GROUND = 280

# The forest scatters its ground specks here and nowhere else -- five rows,
# near the edges only, so the middle of the ground stays clear for the pet.
# Every scene reuses these exact rectangles, which is what makes their grounds
# read as one ground.
GROUND_SPECKS = [
    (8, 11, 292), (169, 172, 292), (16, 20, 305), (160, 164, 305),
    (7, 12, 322), (168, 173, 322), (15, 22, 344), (158, 165, 344),
    (6, 16, 372), (164, 174, 372),
]


# --- grid primitives -------------------------------------------------------

def blank(ch):
    return [[ch] * COLS for _ in range(ROWS)]


def rect(g, x0, y0, x1, y1, ch):
    for y in range(max(0, y0), min(ROWS, y1)):
        row = g[y]
        for x in range(max(0, x0), min(COLS, x1)):
            row[x] = ch


def box(g, x0, y0, x1, y1, fill, ink_ch='O', t=1):
    """A filled rectangle inside a `t`-cell border -- the app's one edge idiom."""
    rect(g, x0, y0, x1, y1, ink_ch)
    rect(g, x0 + t, y0 + t, x1 - t, y1 - t, fill)


def stamp(g, x, y, art, key):
    """An ASCII sprite, for the shapes that are drawn rather than measured."""
    for j, line in enumerate(art):
        for i, c in enumerate(line):
            if c in key and 0 <= y + j < ROWS and 0 <= x + i < COLS:
                g[y + j][x + i] = key[c]


def outline(g, chars, x0, y0, x1, y1, ch='O'):
    """Outlines an organic shape by dilating it, rather than drawing its edge.

    A leaf cluster has no rectangle to put a border on, so the border is every
    cell touching one -- which is also how it stays exactly one cell wide on
    every bump. Boundaries *within* `chars` are left alone, so a two-tone
    shape keeps its internal colour change unoutlined.
    """
    add = []
    for y in range(max(1, y0), min(ROWS - 1, y1)):
        for x in range(max(1, x0), min(COLS - 1, x1)):
            if g[y][x] in chars:
                continue
            if any(g[y + dy][x + dx] in chars
                   for dy, dx in ((-1, 0), (1, 0), (0, -1), (0, 1))):
                add.append((x, y))
    for x, y in add:
        g[y][x] = ch


def dome(g, cx, y0, halves, fill, ink_ch='O'):
    """A rounded silhouette from a half-width per row: domes, clocks, pots."""
    for j, h in enumerate(halves):
        y = y0 + j
        rect(g, cx - h - 1, y, cx + h + 1, y + 1, ink_ch)
        rect(g, cx - h, y, cx + h, y + 1, fill)


def blob(g, y0, spans, ch):
    """A stack of (x0, x1) runs, one per row from `y0` -- clouds and gables."""
    for j, (x0, x1) in enumerate(spans):
        rect(g, x0, y0 + j, x1, y0 + j + 1, ch)


def specks(g, ch):
    for x0, x1, y in GROUND_SPECKS:
        rect(g, x0, y, x1, y + 2, ch)


# --- emit ------------------------------------------------------------------

def paths(loops):
    """deseam's emitter, on cells: the same H/V walk, doubled to art units."""
    parts = []
    for loop in loops:
        pts = [(x * CELL, y * CELL) for x, y in loop]
        q = []
        for k, p in enumerate(pts):
            a, b = pts[k - 1], pts[(k + 1) % len(pts)]
            if (a[0] == p[0] == b[0]) or (a[1] == p[1] == b[1]):
                continue
            q.append(p)
        if len(q) < 3:
            continue
        s = 'M%d %d' % q[0]
        py = q[0][1]
        for x, y in q[1:]:
            s += 'H%d' % x if y == py else 'V%d' % y
            py = y
        parts.append(s + 'Z')
    return ''.join(parts)


def build(g, layers, bands, title, desc):
    """One path per layer, back to front, traced from the grid.

    `bands` names the layers emitted as a whole horizontal band rather than as
    the cells left showing of them -- the sky and the ground. Nothing standing
    on those can hairline against them, and their paths come out as the one
    rectangle they look like.

    A letter the grid uses but `layers` does not name is left transparent,
    which is how a building drawn on its own sheet keeps the sky behind its
    roofline rather than carrying a rectangle of it around.
    """
    deseam.VBW, deseam.VBH = COLS, ROWS
    body = []
    for name, ch, fill in layers:
        if ch in bands:
            y0, y1 = bands[ch]
            mask = [1 if y0 <= i // COLS < y1 else 0 for i in range(COLS * ROWS)]
        else:
            mask = [1 if g[i // COLS][i % COLS] == ch else 0
                    for i in range(COLS * ROWS)]
        if not any(mask):
            raise SystemExit('layer %s (%s) drew nothing' % (name, ch))
        body.append('  <path id="%s" fill="%s" d="%s"/>'
                    % (name, fill, paths(deseam.trace(mask))))
    return ('<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" '
            'viewBox="0 0 %d %d" shape-rendering="crispEdges" version="1.1">\n'
            '  <title>%s</title>\n  <desc>%s</desc>\n%s\n</svg>\n'
            % (COLS * CELL, ROWS * CELL, COLS * CELL, ROWS * CELL,
               title, desc, '\n'.join(body)))


def write(name, svg, layers):
    open(os.path.join(HERE, name), 'w', encoding='utf-8').write(svg)
    print('%-28s %6d bytes, %d layers' % (name, len(svg), len(layers)))
