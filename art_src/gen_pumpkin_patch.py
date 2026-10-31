"""Turns the owner's pumpkin-patch PNG into the scene's editable SVG.

    in   art_src/Crooked witch house and pumpkin border.png
         (the second version; the first, "Pixel Halloween House with Smiling
         Pumpkins.png", is the same scene with fuller pumpkin drifts)
    out  art_src/pumpkin-patch-editable.svg      the master you edit by hand
    then python art_src/build_pumpkin_patch.py   -> assets/svgs/pumpkin_patch.svg

The PNG is pixel art that was drawn by a model and then scaled up, and it shows:
the edges are soft, and there is no grid to recover. Its "pixels" run from
about 5.7 to 7.1 px across, drifting from one part of the picture to the next
(checked: the best-fitting lattice differs in every quarter of it), so snapping
to the lattice it seems to have is a bet that loses somewhere. What it does
have is six colours, and a black line about two of our 3px cells thick. So:

  1. Every pixel is read as a mix of two palette colours (the soft edge between
     lavender and black is not the purple of the house, though it is nearest to
     it), and takes the colour it is mostly made of. A pixel that is at least
     two fifths ink is ink: at this size a line that loses its soft edge to
     the neighbours is a line that thins to nothing.
  2. The picture is cut into 3px cells and each cell takes its most common
     colour, ink winning ties. That is what removes the blur: the fringe is a
     minority in every cell it touches.
  3. Single stray cells are absorbed into what surrounds them, and a fill that
     meets another fill with no outline between (the second PNG has a few
     places where a pumpkin's line simply stops at a leaf) gets the outline
     back, drawn on the leaf's side so the pumpkin keeps its shape. Nothing
     else is "tidied": the fine strokes (leaf veins, the jack-o'-lanterns'
     noses, curling tendrils) are the art, and a smoothing pass would eat them.

The scene is therefore six colours on a 3px grid, 852 x 1845, which is what
`scene_art.PUMPKIN_PATCH` describes and `build_pumpkin_patch.py` checks.

The outline is the project's usual ink (`#14120e`), not the PNG's own
near-black: every picture scene shares one so that no time of day recolours it
(see `_ink` in lib/constants/scenes.dart).

This is a one-time conversion. After it, edit pumpkin-patch-editable.svg by
hand; this script refuses to overwrite it (so it cannot eat your edits) unless
given --force.

Usage:  python gen_pumpkin_patch.py [source.png] [--force] [--preview out.png]
"""
import argparse
import sys
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage as ndi

import scene_art

HERE = Path(__file__).resolve().parent
SRC = HERE / 'Crooked witch house and pumpkin border.png'
OUT = HERE / 'pumpkin-patch-editable.svg'

PALETTE = scene_art.PUMPKIN_PATCH
INK = PALETTE.ink

# The PNG's own colours, as measured (the median of flat areas of the second
# version). Only used to read the PNG; the SVG is drawn in PALETTE, which is the
# first version's colours: the two differ by a few units a channel, which is
# the model's rendering noise and not a change anyone can see, and the night
# tint names these fills by value. The ink differs too: the PNG's black is
# #060504.
SOURCE_COLOURS = ['#b998db', '#86cf60', '#573191', '#fe882a', '#fde360', '#060504']

# The share of ink at which a blended pixel becomes ink, and how much a cell
# prefers ink when it is a close call. Both lean the same way, on purpose.
INK_SHARE = 0.4
INK_CELL_WEIGHT = 1.25

CELL = PALETTE.cell


def classify(rgb):
    """Each pixel's colour, reading soft edges as mixes of two palette colours.

    A pixel is explained either as one colour or as a blend of two; whichever
    fits better wins, and a blend takes the colour it has more of.
    """
    h, w, _ = rgb.shape
    flat = rgb.reshape(-1, 3).astype(np.float32)
    pal = np.array([[int(hx[i:i + 2], 16) for i in (1, 3, 5)]
                    for hx in SOURCE_COLOURS], np.float32)
    n = len(pal)
    best = np.full(len(flat), np.inf, np.float32)
    cls = np.zeros(len(flat), np.int8)
    for i in range(n):
        d = ((flat - pal[i]) ** 2).sum(1)
        better = d < best
        best[better], cls[better] = d[better], i
    for i in range(n):
        for j in range(i + 1, n):
            v = pal[j] - pal[i]
            t = np.clip(((flat - pal[i]) @ v) / (v * v).sum(), 0, 1)
            residual = ((flat - (pal[i] + t[:, None] * v)) ** 2).sum(1)
            # a real mix, and a clearly better explanation than any one colour
            take = (t > 0.02) & (t < 0.98) & (residual + 30 < best)
            if j == INK:
                winner = np.where(t >= INK_SHARE, j, i)
            elif i == INK:
                winner = np.where(1 - t >= INK_SHARE, i, j)
            else:
                winner = np.where(t > 0.5, j, i)
            best[take], cls[take] = residual[take], winner[take]
    return cls.reshape(h, w)


def to_cells(classes):
    """One colour per CELL-px cell: the commonest, ink winning close calls."""
    h, w = classes.shape
    nx, ny = round(w / CELL), round(h / CELL)
    xs = np.round(np.linspace(0, w, nx + 1)).astype(int)
    ys = np.round(np.linspace(0, h, ny + 1)).astype(int)
    out = np.zeros((ny, nx), np.int8)
    for j in range(ny):
        for i in range(nx):
            votes = np.bincount(classes[ys[j]:ys[j + 1], xs[i]:xs[i + 1]].ravel(),
                                minlength=len(PALETTE)).astype(float)
            votes[INK] *= INK_CELL_WEIGHT
            out[j, i] = votes.argmax()
    return out


def absorb_strays(cells):
    """Single cells of a fill, alone in a different colour, take that colour.

    Only fills: a lone ink cell is a nose or a door knob as often as it is
    noise, and the PNG's own detail is the point of the picture.
    """
    out = cells.copy()
    taken = 0
    for cls in range(len(PALETTE)):
        if cls == INK:
            continue
        lab, n = ndi.label(cells == cls, structure=scene_art.S4)
        size = ndi.sum(cells == cls, lab, range(1, n + 1))
        for idx in np.nonzero(size <= 1)[0] + 1:
            y, x = (int(a[0]) for a in np.nonzero(lab == idx))
            ring = cells[max(0, y - 1):y + 2, max(0, x - 1):x + 2].ravel()
            ring = ring[ring != cls]
            if len(ring):
                out[y, x] = np.bincount(ring).argmax()
                taken += 1
    return out, taken


def close_gaps(cells):
    """Gives a missing outline back: where two fills touch with no ink between
    them (other than the pairs the scene means to have touching, the stars and
    bubbles on the sky), the grass side of the contact becomes ink, or the
    later-painted fill's side when neither is grass.
    """
    grass = PALETTE.labels.index('grass')
    allowed = {frozenset(pair) for pair in PALETTE.touching}
    out = cells.copy()
    closed = 0
    h, w = cells.shape
    for dy, dx in ((0, 1), (1, 0)):
        a, b = cells[:h - dy, :w - dx], cells[dy:, dx:]
        for y, x in zip(*np.nonzero((a != b) & (a != INK) & (b != INK))):
            ca, cb = int(a[y, x]), int(b[y, x])
            if frozenset((ca, cb)) in allowed:
                continue
            first = ca == grass or (cb != grass and ca > cb)
            at = (y, x) if first else (y + dy, x + dx)
            if out[at] != INK:
                out[at] = INK
                closed += 1
    return out, closed


def write_master(cells, out):
    """The editable SVG: the sky as a rect, then one path per other colour.

    Disjoint and exact (no bleed under neighbours), unlike the app's copy: this
    is the file to edit, and what you edit should be exactly what you see.
    """
    pixels = np.kron(cells, np.ones((CELL, CELL), np.int8))
    h, w = pixels.shape
    parts = ['<rect id="%s" width="%d" height="%d" fill="%s"/>' % (
        PALETTE.labels[0], w, h, PALETTE.hexes[0])]
    for cls in range(1, len(PALETTE)):
        parts.append('<path id="%s" fill="%s" fill-rule="evenodd" d="%s"/>' % (
            PALETTE.labels[cls], PALETTE.hexes[cls],
            scene_art.path_data(pixels == cls)))
    out.write_text(
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %d %d" '
        'shape-rendering="crispEdges">\n%s\n</svg>\n' % (w, h, '\n'.join(parts)),
        encoding='utf-8')
    return pixels


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('png', nargs='?', type=Path, default=SRC)
    ap.add_argument('--out', type=Path, default=OUT)
    ap.add_argument('--force', action='store_true',
                    help='overwrite the master even though it may hold hand edits')
    ap.add_argument('--preview', type=Path,
                    help='also write the result as a PNG, 3x, to look at')
    opts = ap.parse_args()
    if opts.out.exists() and not opts.force:
        sys.exit('%s exists and may hold hand edits; pass --force to replace it'
                 % opts.out.name)

    rgb = np.array(Image.open(opts.png).convert('RGB'))
    cells, taken = absorb_strays(to_cells(classify(rgb)))
    cells, closed = close_gaps(cells)
    pixels = write_master(cells, opts.out)
    print('wrote %s: %d x %d cells of %dpx, %d stray cells absorbed, '
          '%d outline cells restored' % (
              opts.out.name, cells.shape[1], cells.shape[0], CELL, taken, closed))
    for what, spots in scene_art.lint(pixels, PALETTE):
        print('  heads up: %d %s' % (len(spots), what))
    if opts.preview:
        colours = np.array([[int(hx[i:i + 2], 16) for i in (1, 3, 5)]
                            for hx in PALETTE.hexes], np.uint8)
        Image.fromarray(colours[pixels]).resize(
            (pixels.shape[1] * 3, pixels.shape[0] * 3), Image.NEAREST).save(opts.preview)


if __name__ == '__main__':
    main()
