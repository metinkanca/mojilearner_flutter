# -*- coding: utf-8 -*-
"""Builds `assets/svgs/coin.svg` — the gold coin the economy is counted in.

Generated rather than drawn for the same reason `gen_dog.py` and `gen_bird.py`
are: the shape is a rule (a disc, its outline, a lit rim, a struck paw), and a
rule stays symmetrical where hand-placed rects drift. Re-run after any edit
here; never hand-edit the output.

Construction notes, which are what keep it looking like the same art set as
the pets:

* **The pets' outline colour, `#1f2223`.** Every other line in the app is that
  ink, and a coin outlined in brown would read as a sticker laid on the game
  rather than a thing inside it.
* **A 24x24 cell grid, axis-aligned rects, integer coordinates.** The same
  discipline as the sprite layers, so the coin stays crisp at the sizes it is
  actually drawn at (16 px in the balance chip, ~40 px on a shop row). 24 and
  not 16: at 16 the face is ten cells across, and a paw that fits in ten cells
  has no clear cell between its toes and the rim, so the two fuse into one
  blob.
* **Four gold tones and nothing else.** The pets are flat fill plus one shade.
  Metal needs a little more than that to read as metal, but a long ramp would
  make the coin the smoothest object on screen and give it away as clip art.
* **Lit from the upper left**, which is the direction the pets' own single
  shade tone already implies.
* **A struck mark rather than a printed symbol.** Whatever is on the face is
  filled in the rim tone rather than outlined, the way a real coin's relief is
  the same metal as the face it stands on. See [MARK].
* **One rect per run of same-coloured cells**, merged along x. Fewer shapes
  than a per-cell raster, and — the reason it matters — cells within a run
  cannot antialias against each other and show the seams `art_src/deseam.py`
  exists to remove.
"""

import io
import math
import os

# The pets' ink. Shared deliberately; see the module docstring.
OUTLINE = '#1f2223'

RIM = '#d68f21'
FACE = '#f5c344'
HIGHLIGHT = '#ffe9a8'
SHADOW = '#a86a17'

SIZE = 24
CENTRE = SIZE / 2.0
RADIUS = 11.2

# How many cells thick the rim band is, measured inward from the outline.
#
# Thickness rather than a radius. A radius test compares against the *ideal*
# circle while the outline is a rasterised one, so at the top and bottom of the
# coin — where the raster edge sits furthest inside the ideal curve — face
# cells reach almost to the ink and punch a bright notch through the rim. A
# band peeled inward from the outline itself is uniform everywhere by
# construction.
RIM_THICKNESS = 2

# How far round the rim the highlight and the shadow reach, measured on the
# upper-left/lower-right diagonal. Symmetrical, so the coin is lit rather than
# lopsided.
LIT_ARC = 5.0

# The paw, drawn rather than described in coordinates — at this size the shape
# is the whole point, and a table of row ranges is unreadable next to the thing
# it draws.
#
# What is struck on the face. See `_mark` for the shapes, and the note there
# about the one that had to be thrown away.
MARK = 'ring'

# The paw that is not used, kept because it is the obvious idea and someone
# will have it again. Four toes over a pad, arched, tapering — and at this size
# it reads as a *face*: the outer toes become eyes, the inner ones a nose, and
# the pad a mouth. Shaping the pad does not fix it; the arrangement is the
# problem, and a face on the currency is not a thing to ship by accident.
PAW = [
    '....##.##...',
    '.##.##.##.##',
    '.##.##.##.##',
    '.##.......##',
    '..########..',
    '.##########.',
    '.##########.',
    '..########..',
    '...######...',
]

PAW_ORIGIN = (6, 7)

# The struck ring, as radii from the coin's centre. One cell thick at this
# size: two reads as a target rather than as relief.
RING_INNER = 3.4
RING_OUTER = 4.6

# Half-width of the struck diamond, measured on the pixel diagonal.
DIAMOND_RADIUS = 3.5


def _distance(x, y):
    """Distance from the coin's centre to the centre of cell (x, y)."""
    return math.hypot(x + 0.5 - CENTRE, y + 0.5 - CENTRE)


def _disc():
    return {
        (x, y)
        for y in range(SIZE)
        for x in range(SIZE)
        if _distance(x, y) <= RADIUS
    }


def _mark():
    """The cells struck into the face, in the rim tone."""
    if MARK == 'none':
        return set()
    if MARK == 'ring':
        return {
            (x, y)
            for y in range(SIZE)
            for x in range(SIZE)
            if RING_INNER < _distance(x, y) <= RING_OUTER
        }
    if MARK == 'diamond':
        return {
            (x, y)
            for y in range(SIZE)
            for x in range(SIZE)
            if abs(x + 0.5 - CENTRE) + abs(y + 0.5 - CENTRE) <= DIAMOND_RADIUS
        }
    if MARK == 'paw':
        ox, oy = PAW_ORIGIN
        return {
            (ox + x, oy + y)
            for y, row in enumerate(PAW)
            for x, cell in enumerate(row)
            if cell == '#'
        }
    raise SystemExit('unknown mark: %s' % MARK)


NEIGHBOURS = ((1, 0), (-1, 0), (0, 1), (0, -1))


def _depths(disc):
    """How many cells in from the coin's edge each cell sits.

    0 is the outline itself, 1 the ring inside it, and so on. Peeled rather
    than measured, so every ring is one cell thick wherever it runs.
    """
    depths = {}
    remaining = set(disc)
    depth = 0
    while remaining:
        edge = {
            c for c in remaining
            if any((c[0] + dx, c[1] + dy) not in remaining for dx, dy in NEIGHBOURS)
        }
        for c in edge:
            depths[c] = depth
        remaining -= edge
        depth += 1
    return depths


def _colour_of(x, y, depths, mark):
    """The tone one cell is struck in, or None when it is off the coin."""
    depth = depths.get((x, y))
    if depth is None:
        return None
    if depth == 0:
        return OUTLINE

    if depth <= RIM_THICKNESS:
        # The rim: lit on the upper-left arc, shaded on the lower-right, rim
        # tone across the two quarters between them.
        diagonal = (x + 0.5) + (y + 0.5) - SIZE
        if diagonal <= -LIT_ARC:
            return HIGHLIGHT
        if diagonal >= LIT_ARC:
            return SHADOW
        return RIM

    return RIM if (x, y) in mark else FACE


def _runs(row_colours):
    """Merges a row of cell colours into (x, width, colour) runs."""
    runs = []
    x = 0
    while x < SIZE:
        colour = row_colours[x]
        if colour is None:
            x += 1
            continue
        end = x
        while end + 1 < SIZE and row_colours[end + 1] == colour:
            end += 1
        runs.append((x, end - x + 1, colour))
        x = end + 1
    return runs


def build():
    disc = _disc()
    depths = _depths(disc)
    mark = _mark()

    # The mark is struck in the rim tone, so a marked cell touching the rim
    # band fuses the two into one blob. Every cell of the mark must therefore
    # keep a face cell between itself and the rim, in all four directions.
    def on_face(cell):
        return depths.get(cell, 0) > RIM_THICKNESS

    stray = [
        c for c in mark
        if not on_face(c)
        or not all(on_face((c[0] + dx, c[1] + dy)) for dx, dy in NEIGHBOURS)
    ]
    if stray:
        raise SystemExit('the mark touches the rim at: %s' % sorted(stray))

    out = io.StringIO()
    out.write(
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %d %d" ' % (SIZE, SIZE) +
        
        'shape-rendering="crispEdges">\n'
    )
    out.write('  <!-- Generated by art_src/gen_coin.py. Do not hand-edit. -->\n')
    for y in range(SIZE):
        row = [_colour_of(x, y, depths, mark) for x in range(SIZE)]
        for x, width, colour in _runs(row):
            out.write(
                '  <rect x="%d" y="%d" width="%d" height="1" fill="%s"/>\n'
                % (x, y, width, colour)
            )
    out.write('</svg>\n')
    return out.getvalue()


def main():
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    path = os.path.join(root, 'assets', 'svgs', 'coin.svg')
    svg = build()
    io.open(path, 'w', encoding='utf-8', newline='\n').write(svg)
    print('wrote %s (%d rects)' % (path, svg.count('<rect')))


if __name__ == '__main__':
    main()
