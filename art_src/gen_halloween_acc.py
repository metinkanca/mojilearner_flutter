"""Cat2-native Halloween pass wearables, re-pixelised from the owner's PNGs.

Run from any directory. The four sources are pixel-art PNGs on a magenta key
in art_src/ (the AI-drawn pixel size differs per file: about 24px for the hat,
16px for the headband and 20px for the bandana and bow). Each one is read like
this:
  1. key out the magenta and classify every pixel as ink or a fill colour;
  2. split the ink into the outer outline (any ink component that reaches the
     background) and interior detail (pumpkin face, ghost eyes), because the
     outline is re-drawn and the detail is kept;
  3. vote the fills and detail onto a grid `cells` cells wide, each cell `cell`
     units across (3, the cat's detail grid, unless a piece says otherwise);
  4. dilate a fresh one-cell outline in the cat's ink, 4-neighbourhood, so the
     outline is one cell of this piece's own grid.
Placement (`xc` centre, `yb` bottom edge, in cat2 units) was chosen from renders
against cat2, and for the hat and bandana from the owner's mock-ups, which use
each PNG at its own pixel density rather than the cat's (the bandana's cells are
2.37 units, the hat's 3.5); see HALLOWEEN_PASS.md. Paths are traced in cell
space and scaled, so a fractional `cell` costs nothing.

Shipping convention. Every accessory asset is drawn on the shared pet canvas
("-20 -90 222 328") as if worn by the old cat, and each pet moves it to its own
head with a per-slot offset; the cat's is CAT_SLOT_OFFSET, in
`_layeredPets['cat']`. These pieces were fitted straight onto cat2, so the
shipped SVGs are shifted back by that offset: the cat's own offset then lands
them exactly where they were fitted, and every other pet derives its placement
the way it does for every other piece. The previews stay in cat2 units.

The one exception is the hat. The owner's mock-up seats it low on the cat, with
the brim just above the eyes, which is right for the cat and the dog and wrong
for a pet with less head above its eyes: it would cover them. So the hat ships
at a generic seat (brim bottom at GENERIC_HAT_BOTTOM) that the rest of the
roster derives from, and the cat gets the difference as a per-piece placement,
CAT_PIECE_OFFSET, in `_layeredPets['cat'].accessoryPlacements`.

If either changes, regenerate (test/unit/halloween_accessories_test.dart fails
until you do).
Each colour is traced as a union to avoid seams in flutter_svg.
"""
from pathlib import Path
import xml.etree.ElementTree as ET
import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage as ndi
import deseam

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / 'assets/svgs'
PREVIEW = ROOT / 'art_src/halloween'
INK = '#1f2223'
COAT = '#969680'
EYES = '#f4c430'
VB = '-36.5 -114.3784 255 376.7568'
SHARED_VB = '-20 -90 222 328'
# Mirrors the cat's accessoryOffsets in lib/components/character_sprite.dart.
CAT_SLOT_OFFSET = {'hat': (11, 24), 'neck': (11, 35)}
# Where the hat's brim bottom sits on a generic head, in cat2 units. The roster
# derives from this; the cat is seated lower by the difference (see above).
GENERIC_HAT_BOTTOM = 61.0
# Per-piece placements on the cat that replace its slot offset, mirrored from
# `_layeredPets['cat'].accessoryPlacements`. Filled in below from PIECES.
CAT_PIECE_OFFSET = {}
CELL = 3
BG_RGB = (255, 0, 255)
INK_RGB = (28, 28, 28)
# Integer rasterising surface for the review sheets, encompassing the fractional
# display canvas.
deseam.VBX, deseam.VBY, deseam.VBW, deseam.VBH = -37, -115, 256, 378

PLUM, PLUM2, PUMPKIN, EMBER, BONE = '#663b72', '#72427e', '#f5951a', '#f07d1e', '#f6ead2'
# fills: name -> (reference RGB sampled from the PNG, output colour). The first
# fill is the base: it is traced under every other fill so adjacent colours
# cannot show a seam.
PIECES = [
    dict(id='pumpkinwitch', src='Pixel witch hat with tip-hung pumpkin bell.png',
         fills={'plum': ((102, 66, 114), PLUM), 'pumpkin': ((246, 150, 24), PUMPKIN)},
         slot='hat', cells=46, cell=3.5, xc=116.5, yb=96.4, generic_bottom=GENERIC_HAT_BOTTOM),
    dict(id='devilband', src='Retro pixel devil-horn headband.png',
         fills={'plum': ((102, 54, 114), PLUM), 'ember': ((246, 126, 30), EMBER)},
         slot='hat', cells=42, xc=111, yb=102),
    dict(id='ghostbandana', src='Retro pixel ghost bandana.png',
         fills={'plum': ((102, 54, 114), PLUM), 'plum2': ((114, 66, 126), PLUM2),
                'bone': ((246, 234, 210), BONE)},
         slot='neck', cells=67, cell=2.366, xc=114.2, yb=229.1),
    dict(id='batchoker', src='Flat-color bat bow on magenta.png',
         fills={'plum': ((102, 54, 114), PLUM), 'ember': ((234, 126, 30), EMBER)},
         slot='neck', cells=34, xc=114, yb=186),
]


def repixelise(piece, detail=0.30, solid=0.5):
    """Return {(cx, cy): fill name or 'ink'} on the 3-unit grid, outline excluded."""
    rgb = np.asarray(Image.open(ROOT / 'art_src' / piece['src']).convert('RGB')).astype(float)
    refs = [('bg', BG_RGB), ('ink', INK_RGB)] + [(n, c[0]) for n, c in piece['fills'].items()]
    dist = np.stack([np.sqrt(((rgb - np.array(c)) ** 2).sum(axis=2)) for _, c in refs], axis=2)
    lab = dist.argmin(axis=2)
    names = [n for n, _ in refs]
    present = ndi.binary_opening(lab != 0, iterations=2)
    ys, xs = np.where(present)
    lab = lab[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
    bg, ink = lab == 0, lab == 1
    comp, _ = ndi.label(ink, structure=np.ones((3, 3)))
    reaches_bg = np.unique(comp[ndi.binary_dilation(bg, iterations=4) & ink])
    interior = ink & ~np.isin(comp, reaches_bg[reaches_bg > 0])
    fill = lab >= 2
    height, width = lab.shape
    step = width / piece['cells']
    rows = int(round(height / step))
    cells = {}
    for cy in range(rows):
        for cx in range(piece['cells']):
            ya, yb = int(round(cy * step)), int(round((cy + 1) * step))
            xa, xb = int(round(cx * step)), int(round((cx + 1) * step))
            f, k = fill[ya:yb, xa:xb].mean(), interior[ya:yb, xa:xb].mean()
            if f + k <= solid and k <= detail:
                continue
            if k > detail and k >= f * 0.6:
                cells[(cx, cy)] = 'ink'
            else:
                block = lab[ya:yb, xa:xb]
                block = block[block >= 2]
                cells[(cx, cy)] = names[np.bincount(block).argmax()] if block.size else 'ink'
    return cells


def ring_of(cells):
    return {(x + dx, y + dy) for x, y in cells for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))} - set(cells)


def origin(cells, piece):
    """Unit origin of cell (0, 0) that centres the outlined piece on xc and rests it on yb."""
    c = piece.get('cell', CELL)
    every = list(cells) + list(ring_of(cells))
    x0, x1 = min(p[0] for p in every), max(p[0] for p in every) + 1
    y1 = max(p[1] for p in every) + 1
    ox, oy = piece['xc'] - (x0 + (x1 - x0) / 2) * c, piece['yb'] - y1 * c
    # A whole-unit cell keeps the old integer paths; a fractional one is placed exactly.
    return (round(ox), round(oy)) if float(c).is_integer() else (ox, oy)


def num(v):
    text = ('%.2f' % v).rstrip('0').rstrip('.')
    return '0' if text in ('', '-0') else text


def trace(cells, geom, shift, shipped):
    """One path, in units, for the union of `cells`; geom is (ox, oy, cell size)."""
    ox, oy, c = geom
    sx, sy = shift
    minx, miny = min(p[0] for p in cells), min(p[1] for p in cells)
    w = max(p[0] for p in cells) - minx + 3
    h = max(p[1] for p in cells) - miny + 3
    mask = [0] * (w * h)
    for cx, cy in cells:
        x, y = ox + cx * c - sx, oy + cy * c - sy
        assert -36.5 <= x and x + c <= 218.5, 'piece leaves the canvas sideways'
        assert -114.3784 <= y and y + c <= 262.3784, 'piece leaves the canvas vertically'
        if shipped:
            assert -20 <= x and x + c <= 202, 'piece leaves the shared canvas sideways'
            assert -90 <= y and y + c <= 238, 'piece leaves the shared canvas vertically'
        mask[(cy - miny + 1) * w + (cx - minx + 1)] = 1
    saved = deseam.VBW, deseam.VBH
    deseam.VBW, deseam.VBH = w, h
    try:
        loops = deseam.trace(mask)
    finally:
        deseam.VBW, deseam.VBH = saved

    def at(gx, gy):
        return ox + (gx - 1 + minx) * c - sx, oy + (gy - 1 + miny) * c - sy

    parts = []
    for loop in loops:
        n = len(loop)
        keep = [pt for k, pt in enumerate(loop)
                if not (loop[k - 1][0] == pt[0] == loop[(k + 1) % n][0]
                        or loop[k - 1][1] == pt[1] == loop[(k + 1) % n][1])]
        if len(keep) < 3:
            continue
        x, y = at(*keep[0])
        text = 'M%s %s' % (num(x), num(y))
        row = keep[0][1]
        for gx, gy in keep[1:]:
            x, y = at(gx, gy)
            text += 'H' + num(x) if gy == row else 'V' + num(y)
            row = gy
        parts.append(text + 'Z')
    return ''.join(parts)


def svg(viewbox, content):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{viewbox}" '
            f'shape-rendering="crispEdges">{content}</svg>\n')


def build(piece):
    """Write the shipped asset, its icon and the cat2 preview; return the fitted body."""
    cells = repixelise(piece)
    c = piece.get('cell', CELL)
    ox, oy = origin(cells, piece)
    geom = (ox, oy, c)
    shift = CAT_SLOT_OFFSET[piece['slot']]
    if 'generic_bottom' in piece:
        # Ship at the generic seat; the cat's placement carries the difference.
        lift = piece['yb'] - piece['generic_bottom']
        shift = (shift[0], shift[1] + lift)
        CAT_PIECE_OFFSET[piece['id']] = (shift[0], round(shift[1], 2))
    base = next(iter(piece['fills']))
    groups = [(INK, list(cells) + list(ring_of(cells))),
              (piece['fills'][base][1], [c for c, n in cells.items() if n != 'ink'])]
    for name, (_, colour) in list(piece['fills'].items())[1:]:
        groups.append((colour, [c for c, n in cells.items() if n == name]))

    def paths(offset, shipped):
        return ''.join(f'<path fill="{colour}" d="{trace(members, geom, offset, shipped)}"/>'
                       for colour, members in groups if members)

    fitted = paths((0, 0), False)
    worn = paths(shift, True)
    name = piece['id']
    (OUT / f'acc_{name}.svg').write_text(svg(SHARED_VB, worn), encoding='utf-8')
    every = [(ox + cx * c - shift[0], oy + cy * c - shift[1]) for cx, cy in groups[0][1]]
    x0, y0 = min(r[0] for r in every) - 3, min(r[1] for r in every) - 3
    x1, y1 = max(r[0] for r in every) + c + 3, max(r[1] for r in every) + c + 3
    (OUT / f'acc_{name}_icon.svg').write_text(
        svg(f'{num(x0)} {num(y0)} {num(x1 - x0)} {num(y1 - y0)}', worn), encoding='utf-8')
    cat = ET.parse(OUT / 'cat2.svg').getroot()
    cat_body = ''.join(ET.tostring(p, encoding='unicode') for p in cat).replace('#959379', COAT)
    cat_body += f'<path fill="{EYES}" d="M83 106H95V127H83ZM146 106H158V127H146Z"/>'
    (PREVIEW / f'cat2_with_{name}.svg').write_text(svg(VB, cat_body + fitted), encoding='utf-8')
    return name, fitted, (round(x1 - x0), round(y1 - y0))


def main():
    PREVIEW.mkdir(exist_ok=True)
    built = [build(p) for p in PIECES]
    names = [n for n, _, _ in built]
    cards = ''.join(f'<figure><img src="cat2_with_{n}.svg"><figcaption>{n}</figcaption>'
                    f'<img class="icon" src="../../assets/svgs/acc_{n}_icon.svg"></figure>' for n in names)
    (PREVIEW / 'index.html').write_text('<!doctype html><meta charset="utf-8"><title>Halloween cat2 fitting</title>'
        '<style>body{background:#eee8e0;font:18px system-ui;display:flex;gap:16px;padding:20px}'
        'figure{margin:0;background:white;padding:12px;text-align:center;border-radius:12px}'
        'img{display:block;width:255px;height:377px}.icon{width:64px;height:64px;margin:12px auto}</style>'
        + cards, encoding='utf-8')
    # Exact scanline render of the same orthogonal SVG paths, for a portable
    # review sheet that does not require a browser or an SVG native library.
    sheet = Image.new('RGB', (1120, 510), '#eee8e0')
    size_sheet = Image.new('RGB', (800, 620), '#fbf7f3')
    size_draw = ImageDraw.Draw(size_sheet)
    size_draw.rectangle((0, 310, 799, 619), fill='#1a1c2c')
    labels = ImageDraw.Draw(sheet)
    for i, name in enumerate(names):
        pixels = ['#ffffff'] * (256 * 378)
        for label, text in (('cat2', (OUT / 'cat2.svg').read_text(encoding='utf-8')),
                            ('piece', svg(VB, built[i][1]))):
            for colour, subs in deseam.shapes(text):
                if label == 'cat2' and colour == '#959379':
                    colour = COAT
                deseam.rasterise(subs, pixels, colour)
            if label == 'cat2':
                for x0 in (83, 146):
                    for x in range(x0, x0 + 12):
                        for y in range(106, 127):
                            pixels[(y + 115) * 256 + x + 37] = EYES
        image = Image.new('RGB', (256, 378))
        image.putdata([tuple(bytes.fromhex(c[1:])) for c in pixels])
        sheet.paste(image, (12 + i * 280, 20))
        labels.text((12 + i * 280, 410), name, fill=INK)
        for row, background in enumerate(('#fbf7f3', '#1a1c2c')):
            small = image.copy().convert('RGBA')
            small.putdata([(*p[:3], 0 if p[:3] == (255, 255, 255) else 255)
                           for p in small.get_flattened_data()])
            small = small.resize((153, 227), Image.Resampling.NEAREST)
            size_sheet.paste(small, (23 + i * 200, 20 + row * 310), small)
            size_draw.text((15 + i * 200, 265 + row * 310), name,
                           fill=INK if row == 0 else '#fbf7f3')
        # Neither eye may be painted over by any piece.
        wear = [None] * (256 * 378)
        for colour, subs in deseam.shapes(svg(VB, built[i][1])):
            deseam.rasterise(subs, wear, colour)
        for x0 in (83, 146):
            for x in range(x0, x0 + 12):
                for y in range(106, 127):
                    assert wear[(y + 115) * 256 + x + 37] is None, f'{name} covers an eye'
    sheet.save(PREVIEW / 'fit.png')
    size_sheet.save(PREVIEW / 'fit-display-size.png')
    for name, _, (w, h) in built:
        print(f'{name}: icon crop {w}x{h} units')
    for name, offset in CAT_PIECE_OFFSET.items():
        print(f"cat placement for {name}: _AccessoryPlacement({offset[0]}, {offset[1]})")
    print('Generated four pieces on the shared canvas, icons and cat2 fitted references.')


if __name__ == '__main__':
    main()
