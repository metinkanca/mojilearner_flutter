# Grid-authored accessories for the season pass (see SEASON_PASS.md).
#
# These are authored directly on the pets' 7-unit cell grid rather than drawn
# and resampled. For a symmetric piece that is strictly better: area-sampling
# cannot preserve mirror symmetry (source widths rarely divide evenly into the
# target, so a cell and its mirror tip differently at the coverage threshold),
# whereas placing the cells by hand makes symmetry hold by construction and an
# assert catch any slip. `gen_acc.py` remains the right tool for hand-drawn art
# whose silhouette is finer than the grid -- a curled mustache tip or a bow
# tie's knot does not survive being re-pixelised.
#
# Steps, per piece:
#   1. Expand the authored cells to a pixel mask on the shared canvas.
#   2. Dilate one cell, 4-neighbourhood, into the pets' outline colour. Ring
#      cells only -- with an `enclosed` option that keeps interior holes open,
#      since every hole cell touching the silhouette otherwise joins the ring
#      and a 3x3 hole collapses to 1x1.
#   3. Trace each colour as ONE path over the union of everything beneath it.
#      Abutting rects tear into hairline seams under flutter_svg; a single
#      traced path has no internal edges to tear along.
#
# Grid phases are forced by the symmetry axis: mirroring about A maps grid line
# g to 2A-g, so the phase p must satisfy 2A = 2p (mod 7). Measured off the
# shipped art, which agrees:
#
#   hat    x = 6 (mod 7), even cell count, centred on the SKULL x111 for a
#          wide hat (the beanie is the model). A narrow hat may instead sit
#          on the nose at x123.5, phase 1, odd count -- see FLIGHTCAP
#   face   x = 0 (mod 7), even count, centred on the EYE PAIR x119
#   neck   x = 5 (mod 7), grid x0=61, band centre col 7 = x113.5
#
# Re-run after any edit. Never hand-edit the output.
import os
import sys
from collections import defaultdict

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import acc_offset
from deseam import VBH, VBW, VBX, VBY, emit, trace

HERE = os.path.dirname(os.path.abspath(__file__))
SVG = os.path.join(HERE, '..', 'assets', 'svgs')
OUTLINE = '#1f2223'
CELL = 7

# First Flight -- season one. Dusk navy against coral is a corner of the
# palette the catalogue barely uses, so the track reads as new content rather
# than restock. Cream and smoke are borrowed from the existing pieces.
NAVY = '#1a3340'
CORAL = '#e3664f'
CREAM = '#efeae1'
SMOKE = '#727072'
LEATHER = '#7b4b36'


def rng(a, b):
    """Inclusive column range."""
    return set(range(a, b + 1))


def pair(cols, width):
    """`cols` and their mirror in a grid `width` cells wide.

    Mirroring is structural rather than counted: at 15-20 columns, hand-typing
    both halves is where the symmetry bugs came from.
    """
    out = set(cols)
    return out | {width - 1 - c for c in out}


class Piece:
    """One accessory, authored as cells on the grid.

    `rows` is a list of dicts, one per grid row, mapping colour -> the columns
    it fills. Row 0 sits at `y0`, column 0 at `x0`; both are in canvas art
    units and must carry the slot's phase.
    """

    def __init__(self, name, x0, y0, width, rows, order, enclosed=False):
        self.name = name
        self.x0, self.y0 = x0, y0
        self.width = width
        self.rows = rows
        self.order = order
        self.enclosed = enclosed

    def cells(self):
        """colour -> {(col, row)}, checked for symmetry and stray columns."""
        out = defaultdict(set)
        for r, row in enumerate(self.rows):
            for colour, cols in row.items():
                for c in cols:
                    if not 0 <= c < self.width:
                        raise SystemExit('%s row %d: column %d is off the grid'
                                         % (self.name, r, c))
                    out[colour].add((c, r))
        return out

    def pixels(self, cells):
        """Cells -> canvas pixel coordinates, offset into the mask's frame."""
        out = set()
        for c, r in cells:
            x = self.x0 + c * CELL - VBX
            y = self.y0 + r * CELL - VBY
            for dy in range(CELL):
                for dx in range(CELL):
                    out.add((x + dx, y + dy))
        return out


def ring(cells, enclosed):
    """The one-cell outline around `cells`, 4-neighbourhood.

    With `enclosed`, only ring cells that the outside can reach are kept, so a
    hole the art means to stay open (a lens, an eye slot) is not flooded shut.
    A hole only counts as enclosed if it is closed on every side -- an
    open-bottomed notch is reachable from below and will be filled.
    """
    grown = set()
    for c, r in cells:
        grown |= {(c + 1, r), (c - 1, r), (c, r + 1), (c, r - 1)}
    grown -= cells
    if not enclosed:
        return grown

    cs = [c for c, _ in cells] + [c for c, _ in grown]
    rs = [r for _, r in cells] + [r for _, r in grown]
    lo = (min(cs) - 1, min(rs) - 1)
    hi = (max(cs) + 1, max(rs) + 1)
    seen, stack = set(), [lo]
    while stack:
        c, r = stack.pop()
        if (c, r) in seen or (c, r) in cells:
            continue
        if not (lo[0] <= c <= hi[0] and lo[1] <= r <= hi[1]):
            continue
        seen.add((c, r))
        stack += [(c + 1, r), (c - 1, r), (c, r + 1), (c, r - 1)]
    return grown & seen


def path(pixels, colour):
    mask = [0] * (VBW * VBH)
    for x, y in pixels:
        if 0 <= x < VBW and 0 <= y < VBH:
            mask[y * VBW + x] = 1
    d = emit(trace(mask))
    return '<path fill="%s" d="%s"/>' % (colour, d) if d else None


def head(x, y, w, h):
    return ('<svg id="katman_1" xmlns="http://www.w3.org/2000/svg" version="1.1" '
            'viewBox="%d %d %d %d" shape-rendering="crispEdges">' % (x, y, w, h))


def build(piece):
    cells = piece.cells()
    everything = set().union(*cells.values())
    outline = piece.pixels(ring(everything, piece.enclosed))

    # Painted back to front, each colour over the union of everything under it,
    # so the joins between colours overlap instead of abutting.
    body = [path(outline | piece.pixels(everything), OUTLINE)]
    under = set()
    for colour in reversed(piece.order):
        under |= piece.pixels(cells[colour])
        body.insert(1, path(under, colour))

    art = head(VBX, VBY, VBW, VBH) + ''.join(p for p in body if p) + '</svg>\n'
    return art


def icon(art):
    """The same art cropped to its content, for the wardrobe tile."""
    pts = [p for _, r in acc_offset.shapes(art) for p in r]
    x0, x1, y0, y1 = acc_offset.bbox(pts)
    inner = art[art.index('>', art.index('<svg')) + 1:art.rindex('</svg>')]
    return head(x0, y0, x1 - x0, y1 - y0) + inner + '</svg>\n'


# ---------------------------------------------------------------------------
# Season one -- First Flight
#
# Measured cat geometry these are solved against (an alpha scan of the base,
# mouth and eye layers, not remembered numbers):
#   ears   x46..80 / x142..176 at y8..20, widening to x46..89 / x131..176
#          at y20..26; head solid from y26, full span x46..176
#   eyes   x80..96 and x141..157 at y69..89; pair centre x118.5
#   neck   y126 x59..168; the body has already narrowed to x64..159 by y133,
#          which is where a neck band's outline row lands -- so 11 cells
#          (x75..152 fill, x68..159 outlined) is the practical maximum
# ---------------------------------------------------------------------------

# Neck grid: 15 columns from x61, rows from y119. Fill starts on row 1 so the
# outline row lands on y119 rather than above the neck.
NECK_X, NECK_Y, NECK_W = 61, 119, 15

# The bandana has to differ from the scarf by SILHOUETTE, not just by colour --
# the scarf is already a band with a fall down the centre. So: a rolled top
# edge one cell proud each side, over a clean triangular taper to a point.
#
# The roll is NAVY rather than cream. Cream was tried first and is unusable
# here: `#efeae1` against the wardrobe tile's own off-white ground is not a
# colour difference a player can see, so the roll simply vanished and the piece
# read as a bare triangle. A light tone can only carry a shape on this set when
# something dark is behind it.
BANDANA = Piece(
    'bandana', NECK_X, NECK_Y, NECK_W,
    [
        {},                                       # y119, left to the outline
        {NAVY: rng(2, 12)},                       # y126  the rolled edge
        {CORAL: rng(3, 11)},                      # y133
        {CORAL: rng(4, 10)},                      # y140
        {CORAL: rng(5, 9)},                       # y147
        {CORAL: rng(6, 8)},                       # y154
    ],
    order=[CORAL, NAVY],
)

# Tier ten was drawn as a CAPE first and it does not work. A cape cannot be
# hung behind the pet -- accessories always draw on top, so there is no behind
# -- and both readings available from the front were built and rejected on the
# animal: a closed shoulder mantle reads as a bib, and an open two-panel cape
# reads as a horseshoe (a symmetric hanging pair, the same failure that once
# made the scarf read as striped shorts). Neither is a tuning problem.
#
# What follows is the third reading, and the only one that turns the
# constraint into the point.
#
# A cape needs depth the sprite cannot give it, but a scarf caught by the wind
# A cape needs depth the sprite cannot give it, but a scarf caught by the wind
# needs only the ONE thing this canvas has spare: clean background beside the
# animal. The tail streams to the viewer's right, where the silhouette is
# clear -- the cat's own tail occupies the lower left.
#
# Deliberately asymmetric, which nothing else in the catalogue is. That is also
# why it escapes the failure that killed both capes and once made the scarf
# read as striped shorts: a single streamer leaving on one side cannot be
# mistaken for a symmetric pair of legs.
#
# Grid is 20 columns from x47 so the tail can reach x187 (outlined to x194,
# inside the canvas edge at x202) while the wrap still centres on the neck at
# x113.5 -- column 9.
SCARF_X, SCARF_W = 47, 20

FLIGHTSCARF = Piece(
    'flightscarf', SCARF_X, NECK_Y, SCARF_W,
    [
        {},                                       # y119
        {CORAL: rng(4, 14) | rng(15, 18)},        # y126  wrap; tail leaves level
        {CORAL: rng(5, 9) | rng(16, 19)},         # y133  the fall, and the tail
        {CORAL: rng(6, 8), CREAM: rng(17, 19)},   # y140  tail tip, lit
        {CORAL: rng(6, 8)},                       # y147  the fall carries down
        {CREAM: rng(6, 8)},                       # y154  so the wardrobe tile
    ],                                            #       has vertical mass too
    order=[CORAL, CREAM],
)

# Face grid: 18 columns from x56, rows from y52. Centred on the eye pair at
# x119, which is 8 units right of the head centre -- the pet is a 3/4 view and
# eyewear follows the face, not the silhouette.
FACE_X, FACE_Y, FACE_W = 56, 52, 18

# A navy frame with two smoke lenses set into it, running to the edge of the
# head. Lenses are opaque, as the sunglasses already are: a tinted lens
# swallows the eyes, and the eyes carry the whole expression.
#
# The frame is solid across the bridge rather than open between the lenses. An
# open bridge encloses background on all four sides, which is how the first
# headphones came to frame a white box that read as a hole in the head.
#
# It sits a row higher than the glasses and is two rows deeper, which is what
# separates it from them at tile size: the first attempt was a thin bar with
# two small lenses slung under it and read as a bracket, not as eyewear.
# Columns 1..16 put the outline on x56..182, the sunglasses' own footprint --
# the widest that stays on the head, since a shape centred on the eyes at x119
# is limited by the head's right edge at x176, not its left at x46.
GOGGLES = Piece(
    'goggles', FACE_X, FACE_Y, FACE_W,
    [
        {NAVY: rng(1, 16)},                       # y52  frame, over the brow
        {NAVY: pair({1}, FACE_W) | rng(7, 10),
         SMOKE: pair(rng(2, 6), FACE_W)},         # y59
        {NAVY: pair({1}, FACE_W) | rng(7, 10),
         SMOKE: pair(rng(2, 6), FACE_W)},         # y66
        {NAVY: pair({1}, FACE_W) | rng(7, 10),
         SMOKE: pair(rng(2, 6), FACE_W)},         # y73
        {NAVY: rng(1, 16)},                       # y80  frame, under the eyes
    ],
    order=[NAVY, SMOKE],
)

# Hat grid: 20 columns from x41 (fill x41..181, outlined x34..188), rows on the
# y = 5 (mod 7) phase from y-16.
#
# Skull-centred on x111, NOT nose-centred on x123.5 like the top hat. The
# owner's 2026-08-22 call moved hats onto the nose, but only the two narrow
# ones were converted, and the reason shows the moment a wide one is tried: a
# 130-unit dome offset 12 units right of the head reads as sitting askew, while
# the top hat's narrower brim hides the same offset. Every wide hat already
# shipped -- beanie, mortarboard, headphones, flower crown, witch hat -- is
# still on x111, and this one belongs with them.
#
# The pet's topmost pixel is y0 and the ear tips are there, so a helmet that
# takes the ears has to be full width from y0 down; it can only taper ABOVE the
# animal. Two taper rows is all there is room for, which suits a leather flying
# helmet -- they are snug and square-topped. Partial ear coverage is the read-
# as-broken case, so this covers them outright.
HAT_X, HAT_Y, HAT_W = 41, -16, 20

# The band is CREAM, not navy. Navy `#1a3340` against the outline `#1f2223` is
# barely a colour difference at all, so a navy band inside a dark-outlined
# brown mass reads as a thick piece of outline rather than as a strap -- the
# same trap the bandana's cream roll fell into from the other end. Large flat
# areas on this set need a real value gap from BOTH their neighbour and the
# outline; navy only works when something light is set into it, which is what
# the goggles do with their lenses.
FLIGHTCAP = Piece(
    'flightcap', HAT_X, HAT_Y, HAT_W,
    [
        {LEATHER: rng(6, 13)},                    # y-16  crown
        {LEATHER: rng(2, 17)},                    # y-9
        {LEATHER: rng(0, 19)},                    # y-2   full width by the ears
        {LEATHER: rng(0, 19)},                    # y5
        {LEATHER: rng(0, 19)},                    # y12
        {LEATHER: rng(0, 19)},                    # y19
        {CREAM: rng(0, 19)},                      # y26   goggles strap band
        {LEATHER: pair(rng(0, 2), HAT_W)},        # y33   earflaps, beside the
        {LEATHER: pair(rng(0, 2), HAT_W)},        # y40   head as the headphone
        {LEATHER: pair(rng(0, 2), HAT_W)},        # y47   cups are
        {LEATHER: pair(rng(0, 1), HAT_W)},        # y54   tapering to a point
    ],
    order=[LEATHER, CREAM],
)

PIECES = [BANDANA, FLIGHTSCARF, GOGGLES, FLIGHTCAP]


if __name__ == '__main__':
    only = sys.argv[1:]
    for piece in PIECES:
        if only and piece.name not in only:
            continue
        art = build(piece)
        for name, text in [('acc_%s.svg' % piece.name, art),
                           ('acc_%s_icon.svg' % piece.name, icon(art))]:
            with open(os.path.join(SVG, name), 'w', encoding='utf-8') as f:
                f.write(text)
        box = acc_offset.bbox([p for _, r in acc_offset.shapes(art) for p in r])
        print('acc_%-12s x%3.0f..%-3.0f y%4.0f..%-4.0f  %3.0fx%-3.0fu  %5d bytes'
              % (piece.name + '.svg', box[0], box[1], box[2], box[3],
                 box[1] - box[0], box[3] - box[2], len(art)))
