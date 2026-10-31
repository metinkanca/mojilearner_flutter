# Builds the layered sprite assets for the REWORKED dog (`dog_rework_test_2.svg`).
#
# The rework arrives as one Inkscape file per pet on a shared 330x331 canvas,
# with the body drawn as three stacked flood-filled paths (silhouette, shade,
# main) and the face on its own layers. That is a different master to the three
# `gen_dog.py` reads: there the pieces were already separated by hand, here the
# body is three evenodd paths and the tail is part of the silhouette.
#
# So this generator works off the art's own pixel lattice instead. The rework is
# drawn on a 4-unit grid -- every cell of the 330x331 canvas holds one flat
# colour, bar a single stray cell in the lowest fill, which the majority vote
# below absorbs -- so rasterising it once and sampling per cell recovers the
# grid the artist actually drew on. Everything after that is grid work: the
# tail comes out as a region of cells, the hole it leaves is closed by scanning
# for exposed coat, and the wag is a whole-cell shift.
#
# Two things differ from `gen_dog.py`, both forced by the art being bigger:
#
# * **CELL = 3.** The rework is 81x81 cells against the shipped dog's 208x248
#   units. Three units a cell puts it at 243x243, which matches the old dog's
#   height -- but not its width, because the rework's ears and tail are much
#   wider. 81 cells will not fit the 222-unit shared canvas at any integer cell
#   size that keeps the pet its current size, so this pet declares a wider
#   canvas of its own (see `canvas` in `_layeredPets`). It keeps the shared
#   canvas's height and centre line, so accessories drawn for the old canvas
#   still land in the same place.
# * **The whole body is one path stack.** `deseam` is still what emits it: each
#   colour is painted over the union of everything above it, so no two shapes
#   share an edge and the breathing animation cannot open a hairline between
#   them.
#
#     python art_src/gen_dog2.py
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import deseam                                    # noqa: E402
import lib_rework                                # noqa: E402
from lib_dog import to_points                    # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, 'dog_rework_test_2.svg')
OUT = os.path.join(HERE, '..', 'assets', 'svgs')

# The master's own grid.
SRCW, SRCH = 330, 331
SRCCELL = 4
CW = CH = 83                                     # cells across the master

# This pet's canvas.
#
# The shared one is 222x328 and the rework is 243 units across at CELL = 3, so
# it does not fit. The way out is a canvas that is the shared one scaled up:
# same shape, same centre, so `BoxFit.contain` lands it in exactly the box the
# other pets get -- feet on the same ground line, headroom in the same
# proportion -- and the dog simply draws a little smaller inside it (243 units
# where the cat gets 238 of a 222-wide frame, so about 89% of the cat).
#
# Same shape matters more than it sounds. A canvas that was merely *wider*
# (264x328) is a different aspect to the pet box the home screen builds, so
# `contain` fits it by width there and the dog comes out a sixth smaller,
# floating above the grass. Scaling both axes keeps that from ever happening.
#
# Same centre matters too: it is what keeps an accessory's art coordinates
# meaning the same thing on this pet as on the cat, so the placements below
# stay readable as "where on the pet" rather than "where on the dog's canvas".
CELL = 3
SCALE = 255 / 222                                # canvas / shared canvas
VBW, VBH = 222 * SCALE, 328 * SCALE
# The shared canvas's centre, which this one keeps.
VBX, VBY = 91 - VBW / 2, 74 - VBH / 2
X0 = -33                                         # art units at cell column 0
# Feet on the bottom edge, which is where the shared canvas puts them and so
# where the box puts them.
Y0 = round(VBY + VBH) - (CH - 1) * CELL

VIEWBOX = '%s %s %s %s' % tuple(
    ('%.4f' % v).rstrip('0').rstrip('.') for v in (VBX, VBY, VBW, VBH))
HDR = ('<svg id="katman_1" xmlns="http://www.w3.org/2000/svg" version="1.1" '
       'viewBox="%s" shape-rendering="crispEdges">' % VIEWBOX)

# Rework palette -> the canonical tones every pet is recoloured through.
OUTLINE, MAIN, SHADE, RED = '#1f2223', '#959379', '#606659', '#6b3439'
PALETTE = {'#16130e': OUTLINE, '#cd822a': SHADE, '#ffb944': MAIN}
# Painted back to front, each over the union of everything above it.
RANK = {MAIN: 0, SHADE: 1, RED: 2, OUTLINE: 3}

# The tail, read off the master's cell grid: the rightmost column it occupies
# on each row it spans. The rework draws the tail into the same silhouette path
# as the body and the two touch down the dog's left flank, so there is no
# component to pull out -- this is the seam, traced by hand off the grid.
TAIL_EDGE = {38: 12, 39: 12, 40: 15, 41: 15, 42: 15, 43: 17, 44: 17, 45: 17,
             46: 17, 47: 17, 48: 17, 49: 17, 50: 15, 51: 15, 52: 17, 53: 17,
             54: 17, 55: 19, 56: 19, 57: 19, 58: 17, 59: 17, 60: 17, 61: 17,
             62: 17, 63: 17, 64: 14, 65: 14, 66: 14, 67: 14}

# The wag: the whole tail turns about where it joins the body, its tip
# travelling this many cells (see `lib_rework.rotate_tail`).
REACH = 3

# The trace grid: the master's cells plus room either side for a turned tail.
PAD = 12
GW, GH = CW + 2 * PAD, CH + 2 * PAD


# --------------------------------------------------------------------------
# The master, rasterised onto its own lattice.
# --------------------------------------------------------------------------
def read_master():
    """[(id, canonical fill, cell set), ...] in document order."""
    svg = open(SRC, encoding='utf-8').read()
    out = []
    for m in re.finditer(r'<path\b([^>]*?)/>', svg, re.S):
        attrs = m.group(1)
        pid = re.search(r'\bid="([^"]*)"', attrs).group(1)
        fill = re.search(r'\bfill="(#[0-9a-fA-F]{6})"', attrs).group(1).lower()
        rule = (re.search(r'fill-rule="(\w+)"', attrs) or (None, 'nonzero'))[1]
        subs = to_points(re.search(r'\bd="([^"]*)"', attrs, re.S).group(1))
        out.append((pid, PALETTE[fill], raster(subs, rule)))
    return out


def raster(subs, rule):
    """The master pixels a path covers, sampled at pixel centres."""
    edges = []
    for pts in subs:
        for k in range(len(pts)):
            (x1, y1), (x2, y2) = pts[k], pts[(k + 1) % len(pts)]
            if y1 != y2:
                edges.append((x1, y1, x2, y2))
    mask = bytearray(SRCW * SRCH)
    for py in range(SRCH):
        sy = py + 0.5
        xs = sorted((x1 + (sy - y1) * (x2 - x1) / (y2 - y1),
                     1 if y2 > y1 else -1)
                    for x1, y1, x2, y2 in edges
                    if (y1 <= sy < y2) or (y2 <= sy < y1))
        spans = []
        if rule == 'evenodd':
            spans = [(xs[k][0], xs[k + 1][0]) for k in range(0, len(xs) - 1, 2)]
        else:
            wind, start = 0, None
            for x, d in xs:
                if wind == 0:
                    start = x
                wind += d
                if wind == 0:
                    spans.append((start, x))
        for a, b in spans:
            for px in range(max(0, int(a)), min(SRCW, int(b) + 2)):
                if a <= px + 0.5 < b:
                    mask[py * SRCW + px] = 1
    return mask


def to_cells(mask):
    """The cells a master mask covers, by majority of the 4x4 block."""
    cells = set()
    for cy in range(CH):
        for cx in range(CW):
            hit = sum(mask[y * SRCW + x]
                      for y in range(cy * SRCCELL, min(cy * SRCCELL + SRCCELL, SRCH))
                      for x in range(cx * SRCCELL, min(cx * SRCCELL + SRCCELL, SRCW)))
            if hit * 2 > SRCCELL * SRCCELL:
                cells.add((cx, cy))
    return cells


# --------------------------------------------------------------------------
# Emitting a cell layer.
# --------------------------------------------------------------------------
def emit(layer):
    """`layer` is {(cx, cy): fill}; returns the SVG body, deseamed.

    Traced on a grid padded by [SWING] on every side, because a wag pose puts
    the tail one or two cells off the master's own grid and an index that falls
    off the left edge of a flat buffer reappears on the right of the row above.
    """
    deseam.VBW, deseam.VBH = GW, GH
    order = sorted({f for f in layer.values()}, key=lambda f: RANK[f])
    rank = {f: i for i, f in enumerate(order)}
    body = []
    for i, fill in enumerate(order):
        mask = [0] * (GW * GH)
        for (cx, cy), f in layer.items():
            if rank[f] >= i:
                mask[(cy + PAD) * GW + cx + PAD] = 1
        loops = deseam.trace(mask)
        d = ''.join(
            path(loop) for loop in loops if len(loop) >= 3)
        if d:
            body.append('<path fill="%s" d="%s"/>' % (fill, d))
    return ''.join(body)


def path(loop):
    """One traced cell loop as an integer path in canvas units."""
    pts = [((x - PAD) * CELL + X0, (y - PAD) * CELL + Y0) for x, y in loop]
    q = [p for k, p in enumerate(pts)
         if not (pts[k - 1][0] == p[0] == pts[(k + 1) % len(pts)][0]
                 or pts[k - 1][1] == p[1] == pts[(k + 1) % len(pts)][1])]
    if len(q) < 3:
        return ''
    s = 'M%d %d' % q[0]
    py = q[0][1]
    for x, y in q[1:]:
        s += 'H%d' % x if y == py else 'V%d' % y
        py = y
    return s + 'Z'


def write(name, layer):
    p = os.path.join(OUT, name)
    open(p, 'w', encoding='utf-8').write(HDR + emit(layer) + '</svg>\n')
    print('%-24s %5d bytes' % (name, os.path.getsize(p)))


def seal(layer, thick=1):
    """Outline cells for any coat cell left with bare canvas beside it.

    Lifting the tail out of the silhouette takes the dog's left flank with it,
    and bending the tail for a wag opens the same kind of hole along its own
    edge. Both are found the same way -- scan for coat with nothing next to it
    -- rather than named, so the seal stays right if the art or the swing
    changes.

    `thick` grows the seal that many cells out through bare canvas, starting
    only from exposed coat, so outlines the art already has stay as drawn. The
    flank needs it: a wag swings the tail's own three-cell outline two cells
    clear of the body, and a one-cell seal there shows as a hairline with the
    background leaking through it.
    """
    sealed = dict(layer)
    front = {(cx, cy) for (cx, cy), fill in layer.items() if fill != OUTLINE}
    for _ in range(thick):
        grown = set()
        for cx, cy in front:
            for ax, ay in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
                if ((ax, ay) not in sealed
                        and -PAD <= ax < CW + PAD and -PAD <= ay < CH + PAD):
                    sealed[(ax, ay)] = OUTLINE
                    grown.add((ax, ay))
        front = grown
    return sealed


# --------------------------------------------------------------------------
master = read_master()
cells = {pid: to_cells(mask) for pid, _, mask in master}
fill_of = {pid: fill for pid, fill, _ in master}

# The coat, as one cell map: the three body paths in the order they are drawn.
coat = {}
for pid in ('dog-silhouette', 'dog-fill-2', 'dog-fill-1'):
    for c in cells[pid]:
        coat[c] = fill_of[pid]

tail = {c: f for c, f in coat.items() if c[1] in TAIL_EDGE and c[0] <= TAIL_EDGE[c[1]]}
base = seal({c: f for c, f in coat.items() if c not in tail}, thick=REACH + 1)
for c in cells['dog-nose-shape']:
    base[c] = OUTLINE

write('dog2_base.svg', base)
write('dog2_eyes.svg',
      {c: OUTLINE for c in cells['dog-eye-left'] | cells['dog-eye-right']})
write('dog2_mouth.svg', {c: OUTLINE for c in cells['dog-mouth-shape']})

# The chew. The rework's mouth is a closed line under the muzzle, so the open
# pose is that line with a pocket opened below it -- the same trick the shipped
# dog uses, where the red is the only thing the swap actually shows.
mouth_open = {c: OUTLINE for c in cells['dog-mouth-shape']}
for cy in range(38, 42):
    for cx in range(52, 61):
        mouth_open[(cx, cy)] = RED
for cy in range(38, 42):
    mouth_open[(51, cy)] = OUTLINE
    mouth_open[(61, cy)] = OUTLINE
for cx in range(51, 62):
    mouth_open[(cx, 42)] = OUTLINE
write('dog2_mouth_open.svg', mouth_open)


ROOT = lib_rework.tail_root(tail, set(coat) - set(tail))
ANGLE = lib_rework.wag_left(tail, ROOT, lib_rework.tail_angle(tail, ROOT, REACH))


def wag(angle):
    """The whole tail turned `angle` radians about its root."""
    return lib_rework.close_notches(
        base, seal(lib_rework.rotate_tail(tail, ROOT, angle)))


write('dog2_tail.svg', wag(0))
write('dog2_tail_l.svg', wag(ANGLE))
write('dog2_tail_r.svg', wag(-ANGLE))

# The flat sprite, for anywhere a pet is drawn without its rig.
flat = dict(base)
flat.update(tail)
for c in cells['dog-eye-left'] | cells['dog-eye-right'] | cells['dog-mouth-shape']:
    flat[c] = OUTLINE
write('dog2.svg', flat)

# --- the geometry the Dart side needs -------------------------------------
eye_l, eye_r = cells['dog-eye-left'], cells['dog-eye-right']


def box(cs):
    xs, ys = [c[0] for c in cs], [c[1] for c in cs]
    return (min(xs) * CELL + X0, min(ys) * CELL + Y0,
            (max(xs) - min(xs) + 1) * CELL, (max(ys) - min(ys) + 1) * CELL)


lx, ly, lw, lh = box(eye_l)
rx, _, _, _ = box(eye_r)
print('\nPetEyeGeometry(leftX: %d, rightX: %d, y: %d, w: %d, h: %d)'
      % (lx, rx, ly, lw, lh))
cx = (lx + rx + lw) / 2
by = ly + lh
print('eyesPivot Alignment(%.3f, %.3f)'
      % ((cx - (VBX + VBW / 2)) / (VBW / 2), (by - (VBY + VBH / 2)) / (VBH / 2)))
print('canvas Size(%.4f, %.4f) origin Offset(%.4f, %.4f)'
      % (VBW, VBH, VBX, VBY))
print('art bbox', box(flat))
