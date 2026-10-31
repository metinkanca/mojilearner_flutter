"""Cat hats drawn with pxl (art_src/pxl/<name>.px.js) -> pet-canvas SVGs.

pxl draws one pixel per 3-unit cell of cat2's grid, border included. The border
on the finished 3-unit pets (cat, dog, bird, rabbit) is 9 units, three cells, so
every hat applies pxl's one-cell `outline8` three times through a `base` chain
(see tophat.px.js). This reads each built PNG back and traces each colour as ONE
path over the union of everything beneath it -- abutting rects tear into
hairline seams under flutter_svg.

  node .claude/skills/pxl-pixel-art/bin/pxl.js build art_src/pxl/<name>.px.js
  python art_src/gen_cat_hats.py [--ship] [name ...]

Without --ship it only writes the review copy to art_src/pxl/out/. With --ship
it writes, for each hat in HATS:
  assets/svgs/acc_<name>_cat.svg   drawn in CAT2 coordinates and worn verbatim:
                                   the cat's `accessoryOverrides` places it
                                   with no offset, so nothing else changes (the
                                   other pets keep acc_<name>.svg)
  assets/svgs/acc_<name>_icon.svg  the same art cropped to its box, for the
                                   wardrobe tile
and, for review, art_src/pxl/out/acc_<name>_cat.svg.

cat2's grid is x = 2, y = 1 (mod 3); X0/Y0 must be too. A hat's `x` is its
outline box's top-left in cat2 coordinates (canvas -20 -90 222 328; the pet
canvas and cat2's share a centre, so a point has the same coordinates in both).
"""
import os
import sys

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import deseam

SVGS = os.path.join(HERE, '..', 'assets', 'svgs')
PXL_OUT = os.path.join(HERE, 'pxl', 'out')
CELL = 3
INK = '#1f2223'
VB = '-20 -90 222 328'

# name -> (x, y): top-left of the outline box in cat2 coordinates.
HATS = {
    # 58 x 43 cells = 174 x 129 units. Skull-centred: cat2's head is x38..176,
    # centre 107 -> 20 + 87 = 107. Brim's bottom edge y73, 9 below where the
    # old top hat sat (63 + the old (-2, +1) placement = 64), owner: "a bit
    # lower", then once more "just a little bit" (one cell). Right edge 194 <= 202, so nothing is cut by the viewBox.
    'tophat': (20, -56),
    # 56 x 29 cells = 168 x 87 units: a 40-cell dome 6 units left of the skull
    # centre (x101, so x32 + 9 + 60) to leave room for a straight 10-cell peak
    # reaching x191 on the face side. The dome's border spans x32..170, so with
    # the peak's border it covers the head's x38..176. Right edge 200 <= 202.
    # Dome and peak both end at fill y67, border to y79.
    'cap': (32, -8),
    # 62 x 32 cells = 186 x 96 units: skull-centred (x107 = 14 + 93), brim's
    # bottom border at y79, 6 units lower than the top hat's (owner: "lower the
    # hat a bit more onto the cat's head"). Brim ends at x14 and x200.
    'cowboyhat': (14, -17),
    # 46 x 30 cells = 138 x 90 units, fitted to the head (x38..176 with its
    # border) and mirror-symmetric about the skull centre x107 = 38 + 69. Owner
    # picked this over centring on the face: that version hung 24 units past the
    # head on one side ("now it doesn't make sense"), a narrower one left an ear
    # out, and a three-quarter one broke the mirroring. Bottom border y79, level
    # with the cap and the cowboy hat.
    'crown': (38, -11),
    # 24 x 33 cells = 72 x 99 units: a cone between the ears, axis on the skull
    # centre x107 = 71 + 36. Bottom border y76, tucked a little into the head.
    'partyhat': (71, -23),
    # 46 x 33 cells = 138 x 99 units: fitted to the head (x38..176 with its border,
    # skull axis x107 = 38 + 69) so it covers both ears. Bottom border y79, level
    # with the cap, cowboy hat and crown.
    'beanie': (38, -20),
    # 54 x 22 cells = 162 x 66 units: a 48-cell board centred on the skull axis
    # x107 = 26 + 81, over a band that is exactly the head's span. Bottom border
    # y79, level with the cap, cowboy hat, crown and beanie. Right edge 188.
    'mortarboard': (26, 13),
    # 58 x 37 cells = 174 x 111 units: an arch round the head. Legs one border
    # outside the head (outer x20..194, centred on the skull axis x107 = 20 + 87),
    # so their border ends where the ears' fill begins; the top bar's outer edge
    # is y-8 and the band's lower border y22, 9 units above the ear tips (y28).
    # Bottom border y103: the eyes start at y106.
    'headphones': (20, -8),
    'hp_a': (17, -20), 'hp_b': (17, -20), 'hp_c': (17, -20), 'hp_d': (17, -20),
    # 62 x 46 cells = 186 x 138 units: a cone through the ear notch on a wide brim,
    # centred on the skull axis x107 = 14 + 93, as tall as the original (tip top
    # y-56 against its -55). The brim's top (fill y55) stays put so the ear tips
    # keep 18 units showing; its bottom border is y82, 3 units below the cap,
    # cowboy hat, crown and beanie.
    'wizardhat': (14, -56),
    'pumpkinwitch': (14, -56),
    # 46 x 14 cells = 138 x 42 units: head-wide (x38..176 with its border), skull
    # axis x107 = 38 + 69. A garland sits ON the head, not over the ears: its top
    # border is y46, so the ears' tips (y28) stay in view above it; the vine's
    # bottom border is y88.
    'flowercrown': (38, 46),
    # 46 x 24 cells = 138 x 72 units: head-wide (x38..176 with its border, skull
    # axis x107 = 38 + 69). The band sits on the head's top (fill y58..67) under the
    # ear tips, and the horns stand inside the ears. Bottom border y76.
    'devilband': (38, 4),
    # --- neck. The cat has no neck: the face ends at y~146 and the body outline
    # is x44..173 from y152, centre 107. Pieces are small (26 cells of fill, 30 with
    # the TWO-cell border: x62..152 = 62 + 45, centred on 107) and sit just under
    # the chin, top border y157, fill from y163 (owner: the first cut was "too
    # thick and big"; the hats keep their three-cell border).
    'collar': (62, 157),
    'bandana': (62, 157),
    'scarf': (62, 157),
    'necklace': (62, 157),
    'medal': (62, 157),
    # The Witching Hour pair, reworked in the same style: x62..152.
    'ghostbandana': (62, 157),
    # --- face. The eyes are x83..95 and x146..158, y106..127 (4 x 7 cells); their
    # midpoint, the face centre, is x120.5. Glasses and sunglasses have no border
    # (the frame is the ink).
    'glasses': (62, 97),
    'sunglasses': (62, 97),
    'mask': (56, 88),
    'goggles': (62, 94),
    'mustache': (83, 133),
    # Face redesign round (2026-10-28). Masks: fill origin x62 y94 (C: y67), box = fill - 6.
    'mask_n': (56, 88), 'mask_o': (56, 88),
    'mask_k': (56, 88), 'mask_l': (56, 88), 'mask_m': (56, 88),
    'mask_h': (56, 88), 'mask_i': (56, 88), 'mask_j': (56, 88),
    'mask_e': (56, 88), 'mask_f': (56, 88), 'mask_g': (56, 88),
    'mask_a': (56, 88), 'mask_b': (56, 88), 'mask_c': (56, 88), 'mask_d': (56, 88),
    # Mustaches centred on the nose, x125: fill x86 (C: x104), box = fill - 6.
    'mustache_a': (80, 127), 'mustache_b': (83, 133), 'mustache_c': (80, 127), 'mustache_d': (86, 127),
    'batchoker_big': (44, 157),   # 42 cells wide: x44..170, centred on 107; the bigger bat
    'batchoker': (53, 157),   # 36 cells wide: x53..161, centred on 107
    # 44 cells wide: the wrap plus a tail rising up the LEFT, 18 units higher than the rest; left edge 17.
    'flightscarf': (17, 139),
    # The bow's knot is on the face centre (x122), so the whole bow sits right of
    # the body's centre: 24 x 15 cells = 72 x 45 units, x86..158.
    'bowtie': (86, 157),
    # Four bow tie designs to choose from, 24 cells of fill + the border = 28: x80..164, knot on x122.
    'bowtie_a': (80, 157),
    'bowtie_b': (80, 157),
    'bowtie_c': (80, 157),
    'bowtie_d': (80, 157),
    # Second round, after the owner's reference sheet: butterfly bows, 26 cells of fill + border = 30, x77..167.
    'bowtie_f': (77, 157),
    'bowtie_g': (77, 157),
}


# Ink plugs, per hat: (x, y, w, h) in SPRITE cells; every transparent cell inside
# becomes ink. For a notch the cat's ear would otherwise show through. The
# cowboy hat's crown sits 3 cells right of its brim's middle, which opens a slot
# between the left wing and the crown exactly where the left ear's tip is
# (sprite cols 10..17, rows 15+).
PLUGS = {}

# Windows cut into a piece AFTER its border is drawn, in SPRITE cells: (x, y, w, h,
# rim, rim colour). Every cell inside becomes transparent, and the rim cells round it
# take the rim colour. A border pxl draws round an opening would shrink it by the border's width a
# side, which closes an eye in, so these are cut by hand instead.
HOLES = {
    # fill cols 6..11 and 27..32, rows 2..10, plus the two-cell border offset; the
    # rim is gold
    'mask': [(9, 6, 4, 7, 0, '#1f2223'), (30, 6, 4, 7, 0, '#1f2223')],
    'mask_n': [(9, 6, 4, 7, 0, '#1f2223'), (30, 6, 4, 7, 0, '#1f2223')],
    'mask_o': [(9, 6, 4, 7, 0, '#1f2223'), (30, 6, 4, 7, 0, '#1f2223')],
    'mask_k': [(9, 6, 4, 7, 0, '#1f2223'), (30, 6, 4, 7, 0, '#1f2223')],
    'mask_l': [(9, 6, 4, 7, 0, '#1f2223'), (30, 6, 4, 7, 0, '#1f2223')],
    'mask_m': [(9, 6, 4, 7, 0, '#1f2223'), (30, 6, 4, 7, 0, '#1f2223')],
    'mask_h': [(9, 6, 4, 7, 0, '#1f2223'), (30, 6, 4, 7, 0, '#1f2223')],
    'mask_i': [(9, 6, 4, 7, 0, '#1f2223'), (30, 6, 4, 7, 0, '#1f2223')],
    'mask_j': [(9, 6, 4, 7, 0, '#1f2223'), (30, 6, 4, 7, 0, '#1f2223')],
    'mask_e': [(8, 7, 6, 5, 1, '#8e949e'), (9, 6, 4, 7, 1, '#8e949e'), (29, 7, 6, 5, 1, '#8e949e'), (30, 6, 4, 7, 1, '#8e949e')],
    'mask_f': [(9, 6, 4, 7, 0, '#1f2223'), (30, 6, 4, 7, 0, '#1f2223')],
    'mask_g': [(8, 7, 6, 5, 1, '#1f2223'), (9, 6, 4, 7, 1, '#1f2223'), (29, 7, 6, 5, 1, '#1f2223'), (30, 6, 4, 7, 1, '#1f2223')],
    'mask_a': [(9, 6, 4, 7, 0, '#1f2223'), (30, 6, 4, 7, 0, '#1f2223')],
    'mask_b': [(9, 6, 4, 7, 0, '#1f2223'), (30, 6, 4, 7, 0, '#1f2223')],
    'mask_c': [(9, 6, 4, 7, 0, '#1f2223'), (30, 6, 4, 7, 0, '#1f2223')],
    'mask_d': [(9, 6, 4, 7, 0, '#1f2223'), (30, 6, 4, 7, 0, '#1f2223')],
}


def read(name):
    im = Image.open(os.path.join(PXL_OUT, 'sprites', name + '.png')).convert('RGBA')
    w, h = im.size
    cells = {}
    for y in range(h):
        for x in range(w):
            r, g, b, a = im.getpixel((x, y))
            if a:
                cells[(x, y)] = '#%02x%02x%02x' % (r, g, b)
    for hx, hy, hw, hh, rim, rim_colour in HOLES.get(name, []):
        for y in range(hy - rim, hy + hh + rim):
            for x in range(hx - rim, hx + hw + rim):
                inside = hx <= x < hx + hw and hy <= y < hy + hh
                if inside:
                    cells.pop((x, y), None)
                elif (x, y) in cells:
                    cells[(x, y)] = rim_colour
    if name in PLUGS:
        px, py, pw, ph = PLUGS[name]
        for y in range(py, py + ph):
            for x in range(px, px + pw):
                cells.setdefault((x, y), INK)
    return w, h, fill_pockets(w, h, cells)


def fill_pockets(w, h, cells, biggest=12):
    """Fill transparent pockets the border has closed off, with ink.

    Under a three-cell border a gap of 7 cells closes to a single open cell and
    the pet shows through it as a stray dot (the cowboy hat's notch did exactly
    that once its crown moved). A pocket is any transparent region the outside
    cannot reach; the ones of `biggest` cells or fewer are ink, since that is
    what the border would have made of them anyway. Larger ones are left alone.
    """
    outside, stack = set(), [(x, y) for x in range(w) for y in (0, h - 1)] +                            [(x, y) for y in range(h) for x in (0, w - 1)]
    while stack:
        x, y = stack.pop()
        if not (0 <= x < w and 0 <= y < h) or (x, y) in outside or (x, y) in cells:
            continue
        outside.add((x, y))
        stack += [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]
    seen, filled = set(), 0
    for y in range(h):
        for x in range(w):
            if (x, y) in cells or (x, y) in outside or (x, y) in seen:
                continue
            region, todo = [], [(x, y)]
            while todo:
                c = todo.pop()
                if c in seen or c in cells or c in outside or not (0 <= c[0] < w and 0 <= c[1] < h):
                    continue
                seen.add(c); region.append(c)
                todo += [(c[0] + 1, c[1]), (c[0] - 1, c[1]), (c[0], c[1] + 1), (c[0], c[1] - 1)]
            if len(region) <= biggest:
                for c in region:
                    cells[c] = INK
                filled += len(region)
    if filled:
        print('  filled %d enclosed cell(s) with ink' % filled)
    return cells


def paths(w, h, cells, x0, y0):
    # Paint order: ink first, then the fills in order of first appearance;
    # each path covers its own cells plus every colour painted after it.
    order = [INK] + [c for c in dict.fromkeys(cells[k] for k in sorted(cells, key=lambda p: (p[1], p[0])))
                     if c != INK]
    deseam.VBX = deseam.VBY = 0
    deseam.VBW, deseam.VBH = w, h
    out = []
    for i, colour in enumerate(order):
        above = set(order[i:])
        mask = [False] * (w * h)
        for (x, y), c in cells.items():
            if c in above:
                mask[y * w + x] = True
        loops = [[(px * CELL + x0, py * CELL + y0) for px, py in loop]
                 for loop in deseam.trace(mask)]
        out.append('<path fill="%s" d="%s"/>' % (colour, deseam.emit(loops)))
    return ''.join(out)


def build(name, ship):
    x0, y0 = HATS[name]
    assert x0 % 3 == 2 and y0 % 3 == 1, '%s is off cat2\'s grid' % name
    w, h, cells = read(name)
    body = paths(w, h, cells, x0, y0)
    head = '<svg xmlns="http://www.w3.org/2000/svg" version="1.1" viewBox="%s" shape-rendering="crispEdges">'
    full = head % VB + body + '</svg>'
    icon = head % ('%d %d %d %d' % (x0, y0, w * CELL, h * CELL)) + body + '</svg>'
    right, bottom = x0 + w * CELL, y0 + h * CELL
    assert -20 <= x0 and right <= 202, '%s runs off the canvas' % name
    outs = [(os.path.join(PXL_OUT, 'acc_%s_cat.svg' % name), full)]
    if ship:
        outs += [(os.path.join(SVGS, 'acc_%s_cat.svg' % name), full),
                 (os.path.join(SVGS, 'acc_%s_icon.svg' % name), icon)]
    for path, text in outs:
        with open(path, 'w', encoding='utf-8') as f:
            f.write(text)
    print('%-10s %dx%d cells  x%d..%d y%d..%d  %d colours  %d bytes'
          % (name, w, h, x0, right, y0, bottom, len(set(cells.values())), len(full)))


if __name__ == '__main__':
    args = sys.argv[1:]
    ship = '--ship' in args
    for n in ([a for a in args if a != '--ship'] or HATS):
        build(n, ship)
