"""Turns the owner's town PNGs into the city's SVGs: the FIRST town.

    python art_src/gen_city_v1.py           # everything: town, buildings, rooms

Superseded on 2026-10-20 by `gen_city.py`, which cuts the town out of the
owner's single `New scenarios city map.jpg`. This one still builds the town
from the pair of 1024x1536 maps below, and writes the same files and the same
numbers into scenario_city.dart, so running it puts the first town back.

THE TOWN comes from two pictures the owner made as a pair, 1024x1536 and aligned
to the pixel:

    Cozy pixel-art pet town map.png            the town as it should look
    Ground-only town map with vacant lots.png  the same, with the buildings gone

Subtracting the second from the first leaves the buildings, so they are cut out
of the picture they were drawn in, at the pixel size of the ground they stand
on, and stand exactly where the owner put them.  The ground is the second
picture, with grass above and below it so the map is taller than any phone.

THE ROOMS are separate pictures (1942x809, drawn for the chat stage).

All of it is generated "pixel art" whose lattice is only roughly there (the
steps drift in size from one part of a picture to the next, so there is no grid
to recover -- the same finding as `cozy-room-scene`), with edges smeared into a
few thousand colours.  Shown at phone size it is 3-5x smaller than it is here,
so what has to be kept is the flat colours and the black outline:

  1. KEY.     Which pixels count: a building's silhouette, a room's every pixel.
  2. SNAP.    Every pixel becomes the nearest colour of the palette the pictures
              were drawn with (found by clustering them), after a 3x3 median to
              take the compression noise out.
  3. VOTE.    Each cell takes its commonest colour, which turns smeared edges
              back into stair-steps.
  4. TIDY.    Anything thinner than two cells is a blur between two colours (ink
              melting into orange reads as dark wood), not a drawn detail, so it
              is absorbed by its neighbour.  Same rule as `gen_clinic.despeckle`.
              The paving's mortar lines are the exception: they are one drawn
              line, and are meant to be that thin.
  5. TRACE.   One even-odd path per colour, each fill grown a cell under the ink
              and later fills around it (`scene_art.asset_svg`'s scheme, for the
              same pale-fringe reason, see cozy-room-scene), the ink painted
              last.  Re-read and compared with the picture before it is written.

Needs numpy, scipy, Pillow.  The two room pictures for the coffee shop are the
same room with a different window; the broad window (the later file) is used.
"""
import argparse
import os
import sys
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage as ndi

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import scene_art  # noqa: E402  (loops / path_data / rasterise live there)

ASSETS = HERE.parent / 'assets' / 'svgs'

GONE = -1                       # a transparent cell
S4 = ndi.generate_binary_structure(2, 1)
S8 = ndi.generate_binary_structure(2, 2)


class Pal:
    """A set of colours: paint order after the underlay, big flat fills first,
    the ink (named 'ink') last."""

    def __init__(self, colours):
        self.names = [n for n, _ in colours]
        self.hexes = [h for _, h in colours]
        self.rgb = np.array([[int(h[i:i + 2], 16) for i in (1, 3, 5)] for h in self.hexes],
                            np.float32)
        self.ink = self.names.index('ink')

    def __len__(self):
        return len(self.names)

    def index(self, *names):
        return [self.names.index(n) for n in names]


# The rooms'.
MASTER = Pal([
    ('sand', '#cfc3b1'), ('cream', '#f6eedb'), ('orange', '#f2a636'),
    ('coral', '#ef8169'), ('purple', '#8e73ce'), ('lilac', '#a880e5'),
    ('grass', '#b9e29a'), ('green', '#89bf63'), ('sky', '#8dd4f3'),
    ('blue', '#3f8fc3'), ('wood', '#ab744c'), ('dkwood', '#7f5434'),
    ('ink', '#0d0a07'),
])

# The town's: found the same way, from the two maps.  `brick` is the paving's
# mortar; `water` the pond and fountain, a lighter blue than the roofs' `blue`;
# `edge` the dark grey, softer than the ink, that outlines the paving.
TOWN = Pal([
    ('sand', '#d1c2af'), ('brick', '#c3b4a1'), ('cream', '#faeed5'),
    ('orange', '#fab238'), ('coral', '#fa8870'), ('purple', '#9e73d0'),
    ('grass', '#bde98d'), ('green', '#7fc558'), ('sky', '#8edcf7'),
    ('blue', '#339bda'), ('water', '#49b8eb'), ('wood', '#ad7445'),
    ('dkwood', '#7e5331'), ('edge', '#413f36'), ('ink', '#080806'),
])


class Picture:
    """One room picture and how it is cut."""

    def __init__(self, name, src, out, cell=3, minthick=2):
        self.name, self.src, self.out = name, src, out
        self.cell, self.minthick = cell, minthick


PICTURES = [
    Picture('room_coffee', 'Pixel café with a broad blue window.png', 'scenario_coffee_room.svg'),
    Picture('room_restaurant', 'Warm pixel-art pizza restaurant.png', 'scenario_restaurant_room.svg'),
    Picture('room_doctor', 'Pixel-art stethoscope on examination table.png', 'scenario_doctor_room.svg'),
    Picture('room_shopping', 'Empty Pet Accessory Shop Interior.png', 'scenario_shopping_room.svg'),
    Picture('room_interview', 'Bright pixel-art interview office.png', 'scenario_job_interview_room.svg'),
    Picture('room_directions', 'Empty kiosk counter.png', 'scenario_directions_room.svg'),
]


# --- 2: snap ---------------------------------------------------------------------

def snap(rgb, pal, allowed=None):
    """Nearest palette colour per pixel, after a 3x3 median.  `allowed` limits
    the choice to some colours, by name: a roof must never come out as pond."""
    med = np.stack([ndi.median_filter(rgb[:, :, c], size=3) for c in range(3)], -1)
    flat = med.reshape(-1, 3).astype(np.float32)
    # weighted a little toward green, where the eye is most sensitive
    w = np.array([2.0, 4.0, 3.0], np.float32)
    ids = np.array(pal.index(*allowed) if allowed else range(len(pal)))
    out = np.empty(len(flat), np.int8)
    step = 400_000
    for i in range(0, len(flat), step):
        d = (((flat[i:i + step, None, :] - pal.rgb[ids][None]) ** 2) * w).sum(-1)
        out[i:i + step] = ids[d.argmin(1)]
    return out.reshape(rgb.shape[:2])


# --- 3: vote ---------------------------------------------------------------------

def vote(classes, keep, cell, ncls, prefer=None):
    """Commonest class per cell; a cell is gone when most of it is.  A tie goes
    to `prefer` (the ink): at 2 px cells a 3 px line is half a cell wider than
    the cells it covers, and without this the half loses every time and the
    line thins to nothing."""
    h, w = classes.shape
    H, W = h // cell, w // cell
    c = classes[:H * cell, :W * cell]
    k = keep[:H * cell, :W * cell]
    blocks = c.reshape(H, cell, W, cell).transpose(0, 2, 1, 3).reshape(H, W, cell * cell)
    kb = k.reshape(H, cell, W, cell).transpose(0, 2, 1, 3).reshape(H, W, cell * cell)
    counts = np.zeros((H, W, ncls), np.float32)
    for i in range(ncls):
        counts[:, :, i] = ((blocks == i) & kb).sum(-1)
    if prefer is not None:
        counts[:, :, prefer] += 0.5
    out = counts.argmax(-1).astype(np.int8)
    out[kb.sum(-1) * 2 < cell * cell] = GONE
    return out


# --- 4: tidy ---------------------------------------------------------------------

def tidy(cells, minthick, thin_ok=()):
    """Absorb every region too thin to hold a minthick x minthick square."""
    cells = cells.copy()
    sq = np.ones((minthick, minthick), bool)
    for _ in range(4):
        thin = np.zeros(cells.shape, bool)
        for cls in np.unique(cells):
            if cls == GONE or cls in thin_ok:
                continue
            m = cells == cls
            thin |= m & ~ndi.binary_opening(m, structure=sq)
        if not thin.any():
            break
        src = ndi.distance_transform_cdt(thin, metric='chessboard',
                                         return_distances=False, return_indices=True)
        filled = cells[src[0], src[1]]
        # a sliver is absorbed by a colour, never by the empty space round a
        # sprite: that would eat the outline's outer edge
        take = thin & (filled != GONE)
        if not take.any():
            break
        cells[take] = filled[take]
    return cells


# --- 5: trace --------------------------------------------------------------------

def paint_order(cells, pal):
    """Classes present, by area, big first, the ink last."""
    ids, counts = np.unique(cells[cells != GONE], return_counts=True)
    order = [int(i) for i in ids[np.argsort(-counts)] if i != pal.ink]
    if pal.ink in ids:
        order.append(pal.ink)
    return order


def to_svg(cells, pal):
    h, w = cells.shape
    order = paint_order(cells, pal)
    rank = {c: i for i, c in enumerate(order)}
    rk = np.full(cells.shape, -1, np.int16)
    for c, i in rank.items():
        rk[cells == c] = i
    solid = not (cells == GONE).any()

    parts, els = [], []
    for i, c in enumerate(order):
        region = cells == c
        if i == 0 and solid:
            parts.append('<rect width="%d" height="%d" fill="%s"/>' % (w, h, pal.hexes[c]))
            els.append(None)
            continue
        if c != pal.ink:
            region |= ndi.binary_dilation(region, structure=np.ones((3, 3), bool)) & (rk > i)
        d = scene_art.path_data(region)
        parts.append('<path fill="%s" fill-rule="evenodd" d="%s"/>' % (pal.hexes[c], d))
        els.append(dict(tag='path', d=d, cls=i))
    text = ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %d %d" '
            'shape-rendering="crispEdges">%s</svg>\n' % (w, h, ''.join(parts)))

    # re-read: painting the paths in order must give the picture back
    back = np.full(cells.shape, -1, np.int16)
    if solid:
        back[:] = 0
    for e in els:
        if e is not None:
            back[scene_art.rasterise(e, cells.shape)] = e['cls']
    if not (back == rk).all():
        bad = np.argwhere(back != rk)
        sys.exit('traced svg does not reproduce the picture (%d cells, first at x=%d y=%d)'
                 % (len(bad), bad[0][1], bad[0][0]))
    return text, order


def content_box(cells):
    """(row0, row1, col0, col1) of the cells that are not gone."""
    ys, xs = np.nonzero(cells != GONE)
    return ys.min(), ys.max() + 1, xs.min(), xs.max() + 1


def drop_islands(cells, min_cells=40):
    """Floating bits of a silhouette: crumbs of the edge."""
    alive = cells != GONE
    lab, n = ndi.label(alive, structure=S8)
    if n == 0:
        return cells
    size = ndi.sum(alive, lab, range(1, n + 1))
    out = cells.copy()
    for i, s in enumerate(size, 1):
        if s < min_cells:
            out[lab == i] = GONE
    return out


def preview(cells, path, pal):
    h, w = cells.shape
    img = np.zeros((h, w, 4), np.uint8)
    for i, rgb in enumerate(pal.rgb.astype(np.uint8)):
        img[cells == i] = (*rgb, 255)
    Image.fromarray(img, 'RGBA').save(path)


# --- the rooms ---------------------------------------------------------------------

def build(pic, preview_dir):
    rgb = np.asarray(Image.open(HERE / pic.src).convert('RGB'))
    cells = vote(snap(rgb, MASTER), np.ones(rgb.shape[:2], bool), pic.cell, len(MASTER))
    cells = tidy(cells, pic.minthick)
    text, order = to_svg(cells, MASTER)
    (ASSETS / pic.out).write_text(text, encoding='utf-8')
    h, w = cells.shape
    print('%-16s %4dx%-4d cells  %3d KB  %s -> %s' % (
        pic.name, w, h, len(text) // 1024,
        ' '.join(MASTER.names[c] for c in order), pic.out))
    if preview_dir:
        preview(cells, Path(preview_dir) / (pic.name + '_cells.png'), MASTER)


# --- the town ----------------------------------------------------------------------
#
# Everything here is in wu (the app's world unit), which is a pixel of the two
# maps: they are 1024 wide and so is the world.  A cell of the town is CELL wu.
# Positions are in the maps' own coordinates until `PAD` is added.

COZY = 'Cozy pixel-art pet town map.png'
GROUND = 'Ground-only town map with vacant lots.png'
CELL = 2                    # px of the maps per cell: a 6 px outline is 3 cells
W_WU, MAP_H = 1024, 1536    # the maps
PAD = 360                   # wu of forest added above the map and of meadow below
H_WU = MAP_H + 2 * PAD      # tall enough that a tall phone shows a screen of town
AVENUE_X = 512              # the avenue's middle: the world's

# What each building is, where it is in the cozy map (to pick it out of the
# pieces the difference leaves), where its door is (measured off the picture: the
# arch, the double doors, the kiosk's counter) and the paving its pets stand on.
# door x and pavement y are in the maps' own px.
BUILDINGS = [
    # scenario, art, a point inside it, door x, pavement y, its colours: only
    # these, so the grass it stands on never fringes its outline green
    ('job_interview', 'city_office', (510, 190), 510, 395,
     ['blue', 'sand', 'sky', 'cream', 'dkwood', 'ink']),
    ('restaurant', 'city_restaurant', (235, 570), 232, 757,
     ['coral', 'cream', 'sky', 'wood', 'orange', 'dkwood', 'ink']),
    ('shopping', 'city_shop', (790, 575), 793, 757,
     ['purple', 'cream', 'sky', 'wood', 'orange', 'dkwood', 'ink']),
    ('doctor', 'city_clinic', (245, 925), 240, 1073,
     ['green', 'cream', 'sky', 'wood', 'coral', 'dkwood', 'ink']),
    ('coffee', 'city_cafe', (785, 925), 805, 1073,
     ['orange', 'wood', 'cream', 'sky', 'dkwood', 'ink']),
    ('directions', 'city_kiosk', (780, 1260), 782, 1370,
     ['orange', 'wood', 'cream', 'dkwood', 'ink']),
]
GROUND_COLOURS = ['sand', 'brick', 'cream', 'orange', 'coral', 'grass', 'green',
                  'water', 'wood', 'edge', 'ink']


def maps():
    cozy = np.asarray(Image.open(HERE / COZY).convert('RGB'))
    ground = np.asarray(Image.open(HERE / GROUND).convert('RGB'))
    return cozy, ground


def building_masks(cozy, ground):
    """Each building's silhouette in the cozy map, full size: what the ground-only
    map does not have.  Edges of trees differ a pixel or two between the maps
    (they were generated, not copied), so only blobs survive the opening."""
    diff = np.abs(cozy.astype(int) - ground.astype(int)).sum(-1)
    diff = ndi.median_filter(diff, size=5)
    m = diff > 60
    m = ndi.binary_opening(m, structure=np.ones((5, 5), bool))
    m = ndi.binary_closing(m, structure=np.ones((9, 9), bool))
    m = ndi.binary_fill_holes(m)
    lab, n = ndi.label(m, structure=S8)
    out = {}
    for scenario, art, (x, y), door, pave, colours in BUILDINGS:
        i = lab[y, x]
        if i == 0:
            sys.exit('no building at (%d, %d) for %s: the maps no longer differ there' % (x, y, art))
        out[art] = lab == i
    return out


def building_cells(cozy, mask, colours):
    """A building as cells, cropped to its silhouette: (cells, row0, col0)."""
    cls = snap(cozy, TOWN, colours)
    cells = vote(cls, mask, CELL, len(TOWN), prefer=[TOWN.ink])
    cells = drop_islands(tidy(cells, 2))
    r0, r1, c0, c1 = content_box(cells)
    return cells[r0:r1, c0:c1], r0, c0


def ground_cells(ground):
    """The ground, as cells, with the mortar lines kept."""
    cls = snap(ground, TOWN, GROUND_COLOURS)
    cells = vote(cls, np.ones(cls.shape, bool), CELL, len(TOWN),
                 prefer=TOWN.index('ink', 'edge'))
    return tidy(cells, 2, thin_ok=set(TOWN.index('brick', 'edge')))


def cut_objects(cells):
    """The trees, bushes and flower beds standing free on the ground, as
    cut-outs, to put in the meadow and forest added above and below.  Anything
    not grass that is not joined to the paving; padded by two cells so an outline
    is never clipped.  Each is a dict: its cells and where it stood, in px."""
    n = {nm: i for i, nm in enumerate(TOWN.names)}
    non = cells != n['grass']
    lab, k = ndi.label(non, structure=S8)
    size = ndi.sum(non, lab, range(1, k + 1))
    road = lab == (int(np.argmax(size)) + 1)
    out = []
    for i, sl in enumerate(ndi.find_objects(lab), 1):
        m = lab[sl] == i
        if m.sum() < 80 or (m & road[sl]).any():
            continue
        crop = np.where(m, cells[sl], GONE).astype(np.int8)
        out.append(dict(x=sl[1].start * CELL, y=sl[0].start * CELL,
                        cells=np.pad(crop, 2, constant_values=GONE)))
    return out


def find_object(objects, x, y):
    """The cut-out that stood nearest (x, y) in the map, px."""
    return min(objects, key=lambda o: abs(o['x'] - x) + abs(o['y'] - y))['cells']


def put(world, obj, x, feet, flip=False):
    """Set a cut-out on the ground: left edge at x wu, feet at `feet` wu."""
    if flip:
        obj = obj[:, ::-1]
    h, w = obj.shape
    r0, c0 = feet // CELL - h, x // CELL
    sr0, sc0 = max(0, -r0), max(0, -c0)
    er, ec = min(h, world.shape[0] - r0), min(w, world.shape[1] - c0)
    if er <= sr0 or ec <= sc0:
        return
    sub = obj[sr0:er, sc0:ec]
    dst = world[r0 + sr0:r0 + er, c0 + sc0:c0 + ec]
    dst[sub != GONE] = sub[sub != GONE]


def size_wu(obj):
    return obj.shape[1] * CELL, obj.shape[0] * CELL


def overlap(a, b):
    w = min(a[2], b[2]) - max(a[0], b[0])
    h = min(a[3], b[3]) - max(a[1], b[1])
    return w * h if w > 0 and h > 0 else 0


def scatter(world, kit, clear, rng):
    """Trees, bushes and flowers on the grass the map does not cover: the forest
    above it and the meadow below.

    `kit` is (kind, cut-out) pairs.  Candidates are drawn at random and kept if
    they fit: inside the world, clear of the avenue, and not on top of anything
    already down by more than a quarter of the smaller one -- trees may crowd, so
    a forest overlaps like a canopy, but a bush is never buried.  A fixed seed:
    the same town every time.
    """
    placed = []
    plan = [('tree', 34, (0, 20, W_WU, PAD - 10)),
            ('tree', 30, (0, PAD + MAP_H + 20, W_WU, H_WU)),
            ('bush', 12, (0, 20, W_WU, PAD - 10)),
            ('bush', 12, (0, PAD + MAP_H + 20, W_WU, H_WU)),
            ('flower', 8, (0, PAD + MAP_H + 20, W_WU, H_WU))]
    for kind, tries, (x0, y0, x1, y1) in plan:
        pool = [o for k, o in kit if k == kind]
        kept = 0
        for _ in range(tries * 8):
            obj = pool[rng.integers(len(pool))]
            w, h = size_wu(obj)
            x = int(rng.uniform(x0, max(x0, x1 - w)))
            feet = int(rng.uniform(y0 + h, y1))
            box = (x, feet - h, x + w, feet)
            if box[2] > W_WU or feet > H_WU or any(overlap(box, c) for c in clear):
                continue
            if any(overlap(box, p) > 0.25 * min(w * h, (p[2] - p[0]) * (p[3] - p[1]))
                   for p, _ in placed):
                continue
            placed.append((box, (obj, x, feet, bool(rng.integers(2)))))
            kept += 1
            if kept >= tries:
                break
    for box, (obj, x, feet, flip) in sorted(placed, key=lambda p: p[1][2]):
        put(world, obj, x, feet, flip)


def build_ground(cozy, ground):
    """The whole ground, cells: grass above, the owner's map, meadow below."""
    n = {nm: i for i, nm in enumerate(TOWN.names)}
    g = ground_cells(ground)
    pad = PAD // CELL
    top = np.full((pad, g.shape[1]), n['grass'], np.int8)
    # below: grass, with the avenue carried on south from the map's last row
    bottom = np.full((pad, g.shape[1]), n['grass'], np.int8)
    last = g[-1]
    road = np.isin(last, [n['sand'], n['brick'], n['edge'], n['ink']])
    lo = hi = AVENUE_X // CELL           # the run of paving through the middle
    while road[lo - 1]:
        lo -= 1
    while road[hi]:
        hi += 1
    # the avenue on south: the width the map ends at, outlined the same, paved
    # in the same running bond (the map's own last row, repeated, would stripe)
    ew = [int(np.argmax(last[lo:hi] == n['sand'])),
          int(np.argmax(last[lo:hi][::-1] == n['sand']))]
    bottom[:, lo:lo + ew[0]] = n['edge']
    bottom[:, hi - ew[1]:hi] = n['edge']
    bottom[:, lo + ew[0]:hi - ew[1]] = n['sand']
    COURSE, BRICK = 13, 38              # cells: the map's bricks are about 26 x 76 px
    for r in range(pad):
        course, row = divmod(r, COURSE)
        for c in range(lo + ew[0], hi - ew[1]):
            if row == 0 or (c - (course % 2) * BRICK // 2) % BRICK == 0:
                bottom[r, c] = n['brick']
    # two bushes beside the avenue are cut off by the map's own edge; they would
    # end in a flat line above the meadow, so they go (the meadow has its own)
    g = g.copy()
    side = np.ones(g.shape[1], bool)
    side[lo:hi] = False
    g[-24:, side & (np.arange(g.shape[1]) > 150) & (np.arange(g.shape[1]) < 370)] = n['grass']
    world = np.vstack([top, g, bottom])

    objects = cut_objects(g)
    tree = [('tree', find_object(objects, x, y)) for x, y in
            ((20, 25), (812, 12), (175, 215), (765, 215), (8, 340), (930, 370))]
    bush = [('bush', find_object(objects, x, y)) for x, y in ((210, 55), (735, 55))]
    flower = [('flower', find_object(objects, x, y)) for x, y in
              ((75, 300), (825, 305), (255, 1140), (255, 1420), (660, 1415))]
    avenue = [(lo * CELL - 6, 0, hi * CELL + 6, H_WU)]
    scatter(world, tree + bush + flower, avenue, np.random.default_rng(5))
    return world


def chip_dy(cells):
    """Where the roof is at the building's right-hand end, wu down from the top
    of its box: the top of the first opaque cell in the last 12% of columns."""
    k = max(2, int(cells.shape[1] * 0.12))
    rows = np.nonzero((cells[:, -k:] != GONE).any(1))[0]
    return int(rows.min()) * CELL


def lot_rects(masks_cells):
    """Each building's box in wu: (left, top, width, height), with the pad added."""
    out = {}
    for art, (cells, r0, c0) in masks_cells.items():
        h, w = cells.shape
        out[art] = (c0 * CELL, r0 * CELL + PAD, w * CELL, h * CELL)
    return out


def world_preview(ground, sprites, lots, path):
    """The whole town at 1 px per wu, with each building and its pets."""
    from PIL import ImageDraw
    img = np.zeros((ground.shape[0] * CELL, ground.shape[1] * CELL, 4), np.uint8)
    for i, rgb in enumerate(TOWN.rgb.astype(np.uint8)):
        img[np.kron(ground == i, np.ones((CELL, CELL), bool))] = (*rgb, 255)
    im = Image.fromarray(img, 'RGBA')
    d = ImageDraw.Draw(im)
    for scenario, art, point, door, pave, colours in BUILDINGS:
        cells = sprites[art][0]
        left, top, w, h = lots[art]
        spr = np.zeros(cells.shape + (4,), np.uint8)
        for i, rgb in enumerate(TOWN.rgb.astype(np.uint8)):
            spr[cells == i] = (*rgb, 255)
        spr = np.kron(spr, np.ones((CELL, CELL, 1), np.uint8))
        im.alpha_composite(Image.fromarray(spr, 'RGBA'), (left, top))
        d.rectangle([left, top, left + w, top + h], outline=(255, 0, 255, 255))
        d.line([door, top, door, top + h], fill=(255, 0, 0, 255))
        py = pave + PAD
        for off, colour in ((-50, (0, 0, 255, 255)), (50, (255, 0, 0, 255))):
            d.ellipse([door + off - 45, py - 124, door + off + 45, py], outline=colour, width=3)
    im.save(path)


def build_town(preview_dir):
    cozy, ground = maps()
    masks = building_masks(cozy, ground)
    sprites = {}
    for scenario, art, point, door, pave, colours in BUILDINGS:
        sprites[art] = building_cells(cozy, masks[art], colours)
        cells = sprites[art][0]
        text, order = to_svg(cells, TOWN)
        (ASSETS / (art + '.svg')).write_text(text, encoding='utf-8')
        h, w = cells.shape
        print('%-16s %4dx%-4d cells  %3d KB  %s -> %s.svg' % (
            art, w, h, len(text) // 1024, ' '.join(TOWN.names[c] for c in order), art))
    world = build_ground(cozy, ground)
    text, order = to_svg(world, TOWN)
    (ASSETS / 'city_ground.svg').write_text(text, encoding='utf-8')
    h, w = world.shape
    print('%-16s %4dx%-4d cells  %3d KB  -> city_ground.svg  (%d x %d wu)' % (
        'ground', w, h, len(text) // 1024, w * CELL, h * CELL))
    lots = lot_rects(sprites)
    chips = {art: chip_dy(sprites[art][0]) for art in sprites}
    print_layout(lots)
    sync_dart(lots, chips)
    if preview_dir:
        world_preview(world, sprites, lots, str(Path(preview_dir) / 'town.png'))


FOUNTAIN = (AVENUE_X, 1265 + PAD)               # the middle of the plaza
START = (AVENUE_X, MAP_H + PAD + PAD // 2)      # where the player's pet waits: the
                                                # avenue, south of the plaza
DART = HERE.parent / 'lib' / 'components' / 'scenario_city.dart'


def print_layout(lots):
    """The numbers `CityLayout` is built from, as the Dart that holds them."""
    print('  world %d x %d, avenue x %d, fountain %s, start %s' % (
        W_WU, H_WU, AVENUE_X, FOUNTAIN, START))
    for scenario, art, point, door, pave, colours in BUILDINGS:
        left, top, w, h = lots[art]
        print("    '%s': %s at (%d, %d) %dx%d, door %d, pavement %d" % (
            scenario, art, left, top, w, h, door, pave + PAD))


def sync_dart(lots, chips):
    """Write those numbers into `CityLayout` in scenario_city.dart, and nothing
    else, so the two cannot be pasted wrong.  Fails loudly if the file has
    changed shape."""
    import re
    raw = DART.read_bytes().decode('utf-8')
    crlf = '\r\n' in raw
    text = raw.replace('\r\n', '\n')

    def swap(pattern, repl, what):
        nonlocal text
        text, n = re.subn(pattern, repl, text, count=1)
        if n != 1:
            sys.exit('scenario_city.dart: cannot find %s to update' % what)

    swap(r'static const Size mapSize = Size\([\d.]+, [\d.]+\);',
         'static const Size mapSize = Size(%d, %d);' % (W_WU, H_WU), 'mapSize')
    swap(r'static const double avenueX = [\d.]+;',
         'static const double avenueX = %d;' % AVENUE_X, 'avenueX')
    swap(r'Offset get start => const Offset\(avenueX, [\d.]+\);',
         'Offset get start => const Offset(avenueX, %d);' % START[1], 'start')
    swap(r'Offset get fountain => const Offset\([\d.]+, [\d.]+\);',
         'Offset get fountain => const Offset(%d, %d);' % FOUNTAIN, 'fountain')
    for scenario, art, point, door, pave, colours in BUILDINGS:
        left, top, w, h = lots[art]
        swap(r"('%s': _CitySpot\(\n      art: ')\w+(',\n      bounds: Rect\.fromLTWH\()[^)]*"
             r"(\),\n      doorX: )[\d.]+(,\n      pavement: )[\d.]+"
             r"(,\n      chipDy: )[\d.]+" % scenario,
             lambda m: '%s%s%s%d, %d, %d, %d%s%d%s%d%s%d' % (
                 m.group(1), art, m.group(2), left, top, w, h, m.group(3), door,
                 m.group(4), pave + PAD, m.group(5), chips[art]),
             "the '%s' place" % scenario)
    if crlf:
        text = text.replace('\n', '\r\n')
    if text != raw:
        DART.write_bytes(text.encode('utf-8'))
        print('updated the numbers in lib/components/scenario_city.dart')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('names', nargs='*')
    ap.add_argument('--preview', metavar='DIR')
    opts = ap.parse_args()
    if opts.preview:
        os.makedirs(opts.preview, exist_ok=True)
    for pic in PICTURES:
        if opts.names and pic.name not in opts.names:
            continue
        build(pic, opts.preview)
    if not opts.names or 'ground' in opts.names:
        build_town(opts.preview)


if __name__ == '__main__':
    main()
