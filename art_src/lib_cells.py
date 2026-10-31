# Shared machinery for the pets whose master art is a cell map rather than a
# hand-separated Inkscape file.
#
# The cat, the dog and the bird were each traced by hand and arrive as SVG with
# drifted fills that gen_dog.py / gen_bird.py have to collapse. The rabbit, the
# hamster and the parrot came off a raster pixel-art reference instead, so their
# master is the grid itself: one character per art cell in art_src/<pet>_cells.txt.
# That is a source you can read and edit in a text editor, and it cannot drift.
#
# Everything here turns such a map into what the other three pets emit: integer
# coordinates in the canonical palette, on the shared canvas, run through deseam.
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import deseam  # noqa: E402  (needs the path above)

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, '..', 'assets', 'svgs')

VIEWBOX = "-20 -90 222 328"
# The ground the cat, the dog and the bird all stand on, and the axis they are
# centred about (cat 100.5, dog 96.5, bird 98.5).
GROUND_Y = 238
CENTRE_X = 99
# Art units per cell. The reference draws these three on a finer grid than the
# cat's ~8-9 units, and 6 is what keeps their sizes relative to the cat right:
# rabbit 246 tall (a shade over the cat, on account of the ears), hamster 180
# (chick-sized), parrot 270 including the tail hanging below its perch.
CELL = 6

# The tones every pet shares. MAIN, SHADE and LIGHT all answer to
# recolorBodyLayer -- MAIN becomes the player's coat, SHADE a darkened copy of
# it and LIGHT a lightened one -- and anything else a map declares is a fixed
# marking that survives a recolour untouched.
#
# LIGHT arrived with the roster pets, most of which are drawn with a pale front
# the original trio had no equivalent of; see `_bodyLightFill` in
# lib/utils/pet_recolor.dart.
OUTLINE, MAIN, SHADE, LIGHT = '#1f2223', '#959379', '#606659', '#c8c6b3'


def read_cells(pet):
    """The cell map as equal-length rows, comments stripped and border trimmed."""
    path = os.path.join(HERE, '%s_cells.txt' % pet)
    rows = [ln.rstrip('\n') for ln in open(path, encoding='utf-8')
            if not ln.startswith('#') and ln.strip()]
    w = max(len(r) for r in rows)
    rows = [r.ljust(w, '.') for r in rows]
    while rows and all(c == '.' for c in rows[0]):
        rows.pop(0)
    while rows and all(c == '.' for c in rows[-1]):
        rows.pop()
    lo = min(min(i for i, c in enumerate(r) if c != '.') for r in rows)
    hi = max(max(i for i, c in enumerate(r) if c != '.') for r in rows)
    return [r[lo:hi + 1] for r in rows]


def origin(rows, cell=CELL):
    """Top-left of the art in canvas units: feet on the ground, centred.

    CENTRE_X is the axis the pets share, and it is not the canvas centre --
    the canvas runs x -20..202, whose middle is 91, and the pets sit at 99. A
    pet narrower than about 206 units never notices. A wider one, centred on
    99, would hang off the right edge and be clipped, so the placement is
    clamped to the canvas: the roster's longest animals give up the shared
    axis by a few units rather than the end of a tail.
    """
    w, h = len(rows[0]) * cell, len(rows) * cell
    vbx, _, vbw, _ = (int(float(v)) for v in VIEWBOX.split())
    if w > vbw:
        raise SystemExit('art is %d units wide; the canvas is %d' % (w, vbw))
    return max(vbx, min(CENTRE_X - w // 2, vbx + vbw - w)), GROUND_Y - h


def _runs(rows, letter, x0, y0, cell=CELL):
    """Cells of one letter, merged into horizontal runs."""
    out = []
    for j, row in enumerate(rows):
        i = 0
        while i < len(row):
            if row[i] == letter:
                k = i
                while k < len(row) and row[k] == letter:
                    k += 1
                out.append((x0 + i * cell, y0 + j * cell, (k - i) * cell, cell))
                i = k
            else:
                i += 1
    return out


def build(rows, palette, cell=CELL):
    """An SVG of every letter the rows use, painted in palette order.

    deseam rasterises and re-traces this, so a rect per run is fine: what comes
    out the far side is one path per colour with no shared edges anywhere.
    """
    x0, y0 = origin(rows, cell)
    body = []
    for letter, fill in palette.items():
        # The fill goes on every rect rather than on a wrapping group: deseam
        # reads each shape's own fill and skips anything without one.
        body += ['<rect fill="%s" x="%d" y="%d" width="%d" height="%d"/>'
                 % ((fill,) + r) for r in _runs(rows, letter, x0, y0, cell)]
    return ('<svg id="katman_1" xmlns="http://www.w3.org/2000/svg" version="1.1" '
            'viewBox="%s" shape-rendering="crispEdges">%s</svg>\n'
            % (VIEWBOX, ''.join(body)))


def subst(rows, mapping):
    """Rewrite letters; anything mapped to '.' drops out of the layer."""
    return [''.join(mapping.get(c, c) for c in r) for r in rows]


def bbox(rows, letters, cell=CELL):
    x0, y0 = origin(rows, cell)
    cells = [(i, j) for j, r in enumerate(rows)
             for i, c in enumerate(r) if c in letters]
    if not cells:
        raise SystemExit('no cells for %r' % (letters,))
    xs, ys = [c[0] for c in cells], [c[1] for c in cells]
    return (x0 + min(xs) * cell, y0 + min(ys) * cell,
            x0 + (max(xs) + 1) * cell, y0 + (max(ys) + 1) * cell)


def write(name, svg):
    open(os.path.join(OUT, name), 'w', encoding='utf-8').write(svg)
    print('%-20s %5d bytes' % (name, len(svg)))


def _report(rows, const_name, cell=CELL):
    """The geometry character_sprite.dart needs: printed, and returned.

    Returned as well as printed because the roster generator builds the Dart
    for two dozen pets rather than copying it across by hand, and a second
    copy of these formulas is a second thing to keep in step.
    """
    x0, _ = origin(rows, cell)
    cols = sorted({i for r in rows for i, c in enumerate(r) if c == 'E'})
    runs = []
    for i in cols:
        if runs and i == runs[-1][-1] + 1:
            runs[-1].append(i)
        else:
            runs.append([i])
    ex0, ey0, ex1, ey1 = bbox(rows, 'E', cell)
    vbx, vby, vbw, vbh = [float(v) for v in VIEWBOX.split()]
    geom = {
        'leftX': x0 + runs[0][0] * cell,
        'rightX': None if len(runs) == 1 else x0 + runs[-1][0] * cell,
        'y': ey0,
        'w': len(runs[0]) * cell,
        'h': ey1 - ey0,
        'pivot': (((ex0 + ex1) / 2 - (vbx + vbw / 2)) / (vbw / 2),
                  (ey1 - (vby + vbh / 2)) / (vbh / 2)),
    }
    print()
    print('%s  leftX: %d, %sy: %d, w: %d, h: %d%s'
          % (const_name, geom['leftX'],
             '' if geom['rightX'] is None else 'rightX: %d, ' % geom['rightX'],
             geom['y'], geom['w'], geom['h'],
             '   (single eye -- profile pet)' if geom['rightX'] is None else ''))
    print('eyesPivot   Alignment(%.3f, %.3f)' % geom['pivot'])
    bx0, by0, bx1, by1 = bbox(rows, set(''.join(rows)) - {'.'}, cell)
    print('full bbox   x %d..%d  y %d..%d   %dx%d units from %dx%d cells'
          % (bx0, bx1, by0, by1, bx1 - bx0, by1 - by0,
             len(rows[0]), len(rows)))
    geom['bbox'] = (bx0, by0, bx1, by1)
    return geom


def generate(pet, palette, under, const_name):
    """Emit <pet>_base.svg, <pet>_eyes.svg and <pet>.svg from <pet>_cells.txt.

    `palette` maps every letter the map may use to a fill, back-most first.
    `under` is the letter the coat continues with where an eye sits: the eye
    leaves the base entirely, because deseam merges same-coloured pieces into
    one path and an eye left in would fuse with the outline.
    """
    return generate_rows(pet, read_cells(pet), palette, under, const_name)


def generate_rows(pet, rows, palette, under, const_name, cell=CELL, base_rows=None):
    """[generate], but for a pet whose master is not a `<pet>_cells.txt`.

    The roster pets (see `gen_roster_pets.py`) come off a rect-encoded SVG
    rather than a text map, and are drawn on a finer grid, so they arrive as
    rows already in hand and at their own `cell`. Everything after that --
    canvas placement, the eye split, deseam, the printed geometry -- is the
    same work, so it is this function for all of them rather than a second
    copy that can drift from this one.
    """
    unknown = (set(''.join(rows)) - {'.'}) - set(palette)
    if unknown:
        raise SystemExit('%s: undeclared letters %s' % (pet, sorted(unknown)))
    if 'E' not in ''.join(rows):
        raise SystemExit('%s: no eye cells (E)' % pet)

    # A reference-traced face can have different markings behind each eye.
    # Its already-filled backing is passed explicitly; existing pets keep
    # their original uniform `under` behavior.
    write('%s_base.svg' % pet,
          deseam.deseam(build(base_rows if base_rows is not None else
                             subst(rows, {'E': under}), palette, cell)))
    # The sprite generates its eyes from the constants printed below rather
    # than loading this, the same as the other three -- it is the source of
    # truth those constants come from, and it keeps the layer set complete.
    write('%s_eyes.svg' % pet,
          deseam.deseam(build(subst(rows, {c: '.' for c in palette
                                           if c != 'E'}), palette, cell)))
    # Whole sprite, for anything still asking for one asset per pet.
    write('%s.svg' % pet, deseam.deseam(build(rows, palette, cell)))
    return _report(rows, const_name, cell)
