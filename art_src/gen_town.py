"""The town, drawn with pxl (art_src/pxl/town.px.js), put on the map.

  node .claude/skills/pxl-pixel-art/bin/pxl.js build art_src/pxl/town.px.js
  python art_src/gen_town.py              # review composite -> art_src/pxl/out/town_compare.png
  python art_src/gen_town.py --ship       # SVGs into assets/svgs + the numbers for scenario_city.dart

One pixel is one 3-wu cell, so the world is 342 x 750 cells = 1026 x 2250 wu.
Every building sprite stands with its bottom row on `bottom` (the row above the
paving it faces) and its door column on `door` (a world cell, in the middle of
the door), so a lot's left edge is door - the sprite's own door column.
"""
import os
import sys

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, 'pxl', 'out')
SPR = os.path.join(OUT, 'sprites')
CELL = 3

# name: (sprite, door cell in the world, bottom row (exclusive) in the world,
#        door column inside the sprite, pavement row the pet stands on)
LAYOUT = {
    'job_interview': ('office',     77.5, 178, 75, 188),
    'school':        ('school',    265.5, 178, 76, 188),
    'restaurant':    ('restaurant', 75.5, 337, 74, 347),
    'shopping':      ('shop',      265.5, 337, 76, 347),
    'doctor':        ('clinic',     75.5, 514, 74, 517),
    'coffee':        ('cafe',      269.5, 506, 71, 517),
    'directions':    ('gazebo',    267.0, 672, 36, 677),
}


def sprite(name):
    return Image.open(os.path.join(SPR, name + '.png')).convert('RGBA')


def lots():
    out = {}
    for key, (name, door, bottom, dcol, pave) in LAYOUT.items():
        im = sprite(name)
        left = round(door - dcol - 0.5)
        out[key] = (name, left, bottom - im.height, im)
    return out


def compose():
    world = sprite('ground')
    for key, (name, x, y, im) in lots().items():
        world.alpha_composite(im, (x, y))
    return world


SVG_OUT = os.path.join(OUT, 'town')
LAWN = (0x8c, 0xc5, 0x6a)
PAVING = [(0xf4, 0xe6, 0xc8)]   # cream (the ink joints are bridged by a closing)

# Where the player's pet walks, in cells (rows of the pavement it stands on).
AVENUE_X = 171.0            # the avenue's middle, a cell boundary
PLAZA = (171, 561, 65, 57)  # centre x, y, radii of the plaza's paving
RING = (50, 46)             # the junction ring's radii, in cells
RING_STEPS = 12
FEET = {'job_interview': 188, 'school': 188, 'restaurant': 347, 'shopping': 347,
        'doctor': 517, 'coffee': 517, 'directions': 677}
START_ROW, ARMS_ROW = 710, 561


def hexof(rgb):
    return '#%02x%02x%02x' % rgb[:3]


def svg_of(im, cell=1, ink_hex='#14120e'):
    """One path per colour, traced over the union of itself and everything above
    it (abutting rects tear into hairline seams under flutter_svg)."""
    import deseam
    w, h = im.size
    px = im.load()
    cells = {}
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a:
                cells[(x, y)] = hexof((r, g, b))
    ink = ink_hex
    order = ([ink] if ink in cells.values() else []) + [
        c for c in dict.fromkeys(cells[k] for k in sorted(cells, key=lambda p: (p[1], p[0]))) if c != ink]
    deseam.VBX = deseam.VBY = 0
    deseam.VBW, deseam.VBH = w, h
    body = []
    for i, colour in enumerate(order):
        above = set(order[i:])
        mask = [False] * (w * h)
        for (x, y), c in cells.items():
            if c in above:
                mask[y * w + x] = True
        loops = [[(px_ * cell, py * cell) for px_, py in loop] for loop in deseam.trace(mask)]
        body.append('<path fill="%s" d="%s"/>' % (colour, deseam.emit(loops)))
    return ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %d %d" shape-rendering="crispEdges">%s</svg>'
            % (w, h, ''.join(body)))


def path_network(doors):
    """(nodes, links) in wu, like gen_city.path_network: the avenue, the sidewalks, the arms and
    stubs, a ring round the fountain.  doors: {scenario: (x_wu, y_wu)}."""
    import math
    ax = AVENUE_X * CELL
    row = lambda r: round((r + 0.5) * CELL)
    nodes = {'top': (ax, row(FEET['job_interview'])), 'walk': (ax, row(FEET['restaurant'])),
             'gate': (ax, row(FEET['directions'])), 'start': (ax, START_ROW * CELL)}
    cx, cy = PLAZA[0] * CELL, row(PLAZA[1])
    for k in range(RING_STEPS):
        a = 2 * math.pi * k / RING_STEPS
        nodes['ring%d' % k] = (round(cx + RING[0] * CELL * math.sin(a)), round(cy - RING[1] * CELL * math.cos(a)))
    east, west = RING_STEPS // 4, 3 * RING_STEPS // 4
    for k, v in doors.items():
        nodes[k] = v
    nodes['arm_w'] = (doors['doctor'][0], cy)
    nodes['arm_e'] = (doors['coffee'][0], cy)
    links = [('top', 'job_interview'), ('top', 'school'), ('top', 'walk'), ('walk', 'restaurant'),
             ('walk', 'shopping'), ('walk', 'ring0'), ('gate', 'directions'), ('gate', 'start'),
             ('gate', 'ring%d' % (RING_STEPS // 2)), ('ring%d' % west, 'arm_w'), ('arm_w', 'doctor'),
             ('ring%d' % east, 'arm_e'), ('arm_e', 'coffee')]
    links += [('ring%d' % k, 'ring%d' % ((k + 1) % RING_STEPS)) for k in range(RING_STEPS)]
    return nodes, links


def check_paths(ground, nodes, links):
    """Every point of every link on the paving (cream, or the ink of a joint), at least 6 cells in."""
    import numpy as np
    from scipy import ndimage as ndi
    a = np.array(ground.convert('RGB'))
    cream = np.zeros(a.shape[:2], bool)
    for col in PAVING:
        cream |= (a == np.array(col)).all(axis=2)
    walkable = ndi.binary_closing(cream, structure=np.ones((5, 5), bool))
    far = ndi.distance_transform_edt(walkable)
    worst = 1e9
    for u, v in links:
        (x0, y0), (x1, y1) = nodes[u], nodes[v]
        n = max(2, int(((x1 - x0) ** 2 + (y1 - y0) ** 2) ** 0.5 // 4))
        for i in range(n + 1):
            x, y = x0 + (x1 - x0) * i / n, y0 + (y1 - y0) * i / n
            r, c = int(y) // CELL, int(x) // CELL
            if not walkable[r, c]:
                print('  !! path %s-%s leaves the paving at (%d, %d) wu' % (u, v, x, y))
                return False
            worst = min(worst, far[r, c])
    print('  paths: %d junctions, %d links, all on the paving, %.1f cells in at the edge'
          % (len(nodes), len(links), worst))
    return worst >= 6


def chip_dy(im):
    """Rows (wu) from the top of the sprite to its roof near the right-hand end."""
    a = im.split()[3].load()
    best = im.height
    for x in range(im.width - 18, im.width - 6):
        for y in range(im.height):
            if a[x, y]:
                best = min(best, y)
                break
    return best * CELL


def dart_numbers(placed):
    ids = {'job_interview': 'job_interview', 'school': 'school'}
    lines = []
    doors = {}
    for key, (name, x, y, im) in placed.items():
        door_x = round(LAYOUT[key][1] * CELL)
        pave = round((FEET[key] + 0.5) * CELL)
        doors[key] = (door_x, pave)
        lines.append("    '%s': _CitySpot(art: 'city_%s', bounds: Rect.fromLTWH(%d, %d, %d, %d), "
                     "doorX: %d, pavement: %d, chipDy: %d)," % (
                         key, name, x * CELL, y * CELL, im.width * CELL, im.height * CELL,
                         door_x, pave, chip_dy(im)))
    return lines, doors


def main():
    world = compose()
    path = os.path.join(OUT, 'town_compare.png')
    world.resize((world.width * 2, world.height * 2), Image.NEAREST).convert('RGB').save(path)
    print('wrote', path, world.size)
    placed = lots()
    ground = sprite('ground')
    lines, doors = dart_numbers(placed)
    nodes, links = path_network(doors)
    ok = check_paths(ground, nodes, links)
    print('\n'.join(lines))
    print('world %d x %d wu, avenue %d, start %s, fountain %s' % (
        ground.width * CELL, ground.height * CELL, AVENUE_X * CELL, nodes['start'],
        (PLAZA[0] * CELL, round((PLAZA[1] + 0.5) * CELL))))
    if '--svg' in sys.argv:
        os.makedirs(SVG_OUT, exist_ok=True)
        pieces = {'ground': ground}
        for key, (name, x, y, im) in placed.items():
            pieces['city_' + name] = im
        for name, im in pieces.items():
            text = svg_of(im)
            with open(os.path.join(SVG_OUT, name + '.svg'), 'w', encoding='utf-8') as f:
                f.write(text)
            print('  %-16s %4d x %-4d cells  %6d bytes' % (name, im.width, im.height, len(text)))
    if not ok:
        sys.exit(1)


if __name__ == '__main__':
    main()
