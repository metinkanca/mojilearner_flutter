"""Builds Lanternmaw's UI pieces from the owner's image-tool sheet.

    python gen_sea_ui.py                 # writes lib/components/boss_trial/sea_ui_art.dart
    python gen_sea_ui.py --map NAME      # prints one piece as a cell map
    python gen_sea_ui.py --preview DIR   # one PNG a piece, and the whole sheet
    python gen_sea_ui.py --svg [FILE]    # the pieces as the game gets them, as one SVG

See lib_sheet.py for how a sheet from the tool is read back to the cells it was
drawn on, and gen_sand_ui.py / gen_crystal_ui.py / gen_hex_ui.py for the same
job done for the other bosses. Re-run after any edit; never hand-edit the
output.
"""
import os
import sys

import lib_sheet
from lib_sheet import channel, cut, face_box, flood, halve

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, 'lanternmaw-ui-sheet.jpg')
OUT = os.path.normpath(os.path.join(
    HERE, '..', 'lib', 'components', 'boss_trial', 'sea_ui_art.dart'))

# The sheet's cell, fitted to its edges (lib_sheet.fit): 11.4 pixels square.
# (238 x 136 cells.)
CELL = ((11.42, 0.6), (11.37, 10.8))

# letter -> colour. The slate glass and water in F/f/C/s/g/t/T/u/U/m, the
# gauge's deep water n, the lantern Y/y/c/b. F is what words are written on
# (W where a piece marks its face), and f is the panel's softer face.
TONES = {
    'K': '#14120e',   # outline
    'F': '#ddebe7',   # pale glass
    'f': '#bfd4d3',   # the panel's face
    'C': '#c9dddb',   # glass, between the two
    's': '#a4c3be',   # foam
    'g': '#80a8a7',   # seafoam
    't': '#5a8b96',   # water
    'T': '#456f7a',   # slate
    'u': '#345763',   # slate, deeper
    'U': '#2c4b59',   # slate, deeper still
    'm': '#233942',   # slate, nearly black
    'n': '#1a263c',   # deep water
    'Y': '#dab367',   # lantern gold
    'y': '#e7dfb4',   # lantern glass, and the light it throws
    'c': '#fef1d4',   # lantern core
    'b': '#9d6c32',   # lantern iron
}

# The panel's own softer face, where the words go: W is `f` in it, not F.
PANEL = dict(TONES, F=TONES['f'])

# The lantern when its light is out: the gold gone to dull iron and the glass
# to the water's grey.
UNLIT = dict(TONES, Y='#7d7a6a', y='#56606a', c='#8e9aa0', b='#4a4a44')


def sample():
    return lib_sheet.sample(SRC, TONES, CELL, dark=50, tinted_ground=True)


def png(rows, scale, path):
    lib_sheet.png(rows, scale, path, TONES)


def remap(rows, table, y0=0, y1=None, x0=0, x1=None):
    """Letters in [rows] (a box of them) changed by [table]."""
    for y in range(y0, len(rows) if y1 is None else y1):
        for x in range(x0, len(rows[y]) if x1 is None else x1):
            rows[y][x] = table.get(rows[y][x], rows[y][x])


# ---- cleaning ---------------------------------------------------------------
#
# See gen_sand_ui.py: the game stretches a piece by repeating a run of columns
# and of rows, so each run has to be the same all the way down it.

# Where the lantern hangs on the panel, in the panel's cells: it covers the
# panel's top left, where words would start, and throws a glow over the face
# that is partly outside the panel. It comes off the panel and is drawn on its
# own, over the Lure's board, where there is room for it.
LANTERN = (6, 30, 0, 29)


def take_lantern(rows):
    """The lantern as its own rows and where it hung, and [rows] with the
    panel put back under it."""
    x0, x1, y0, y1 = LANTERN
    mid = 40                       # a clean column: the panel is plain along it
    foot = 40                      # a clean row: so is the left rim, down there
    was = [list(r) for r in rows]
    for y in range(y0, y1):
        for x in range(x0, x1):
            if y <= 1:
                rows[y][x] = '.'
            elif y <= 7 or x >= 9:
                # The top rim and the face under the lantern.
                rows[y][x] = was[y][mid]
            elif y <= 22:
                # The left rim, which its glow had lit.
                rows[y][x] = was[foot][x]
    # Its cells: whatever changed, less the glow, which is the pale yellow
    # that reaches the edge of the region or the panel round it. The glass
    # inside the lantern's frame is the same colour, but shut in. Nothing
    # left of its outline is the lantern's: that is glow on the rim.
    differs = {(x, y) for y in range(y0, y1) for x in range(9, x1)
               if was[y][x] != rows[y][x]
               and was[y][x] in ('K' if x == 9 else 'YycbK')}
    glow, todo = set(), []
    for (x, y) in differs:
        if was[y][x] == 'y' and any(
                (x + dx, y + dy) not in differs
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
            todo.append((x, y))
    while todo:
        x, y = todo.pop()
        if (x, y) in glow:
            continue
        glow.add((x, y))
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            n = (x + dx, y + dy)
            if n in differs and was[n[1]][n[0]] == 'y' and n not in glow:
                todo.append(n)
    cells = differs - glow
    xs = [x for x, _ in cells]
    ys = [y for _, y in cells]
    left, top = min(xs), min(ys)
    lantern = [['.'] * (max(xs) - left + 1) for _ in range(max(ys) - top + 1)]
    for (x, y) in cells:
        lantern[y - top][x - left] = was[y][x]
    return lantern, (left, top)


def clean_pill(rows):
    # The ends' straight sides were shaded from light to dark as they went
    # down; the run of rows that repeats is one shade.
    for y in range(13, 21):
        rows[y][:9] = rows[15][:9]
        rows[y][-9:] = rows[15][-9:]


def clean_ring(rows):
    # The tool's bubble has a glass wall a quarter of its width thick, which
    # would cover most of a pet trapped inside it: the wall is thinned to six
    # cells, with its own outline on the inner edge, and the opening is wide.
    h, w = len(rows), len(rows[0])
    # The corner of the groove's end cap, which reaches into this piece's box.
    for y in range(4):
        rows[y][:10] = ['.'] * 10
    rows[2][14] = '.'
    cx, cy = (w - 1) / 2, (h - 1) / 2
    inner = RING_WALL_FROM
    for y in range(h):
        for x in range(w):
            r = ((x - cx) ** 2 + (y - cy) ** 2) ** .5
            if r < inner - 1:
                rows[y][x] = '.'
            elif r < inner and rows[y][x] != '.':
                rows[y][x] = 'K'


# How far from the middle the thinned wall starts, in cells: the bubble is 27
# cells to its rim.
RING_WALL_FROM = 21


def clean_fish(rows):
    # The back and belly along the middle of the body are an ellipse, drawn
    # a row higher at each step; the run of columns that repeats is one
    # straight stretch of it, cut from the column in its middle.
    for y in range(len(rows)):
        for x in range(FISH_BAND[0], FISH_BAND[1]):
            rows[y][x] = rows[y][FISH_BAND[2]]


FISH_BAND = (70, 80, 75)


# The timer's water, which the sheet draws as two tiles with one wave and one
# bubble each, neither of which repeats: a crest of foam that does, five cells
# deep like the groove's channel, twelve wide, with a bubble in it.
WATER = [
    '..ss....sss.',
    'gggggggggggg',
    'ttttttttfftt',
    'ttttttttfgtt',
    'tttttttttttt',
]

# The net the pet casts, which the sheet draws as one lattice that is not quite
# even: one cell of an even one, ten cells square, so it covers a fish of any
# length. Cords three cells thick crossing at a knot, in the sheet's slates.
NET = [
    '....KTK...',
    '....KTK...',
    '....KTK...',
    '...KKTKK..',
    'KKKKuTuKKK',
    'TTTTTuTTTT',
    'KKKKuTuKKK',
    '...KKTKK..',
    '....KTK...',
    '....KTK...',
]


# name in Dart, the piece's box on the sheet (cells), the repeating run of
# columns and of rows (start, end) or None, the cell of the face words go on
# and the letter it is (lettered W) or None, a cleaning step, and where words go
# as cells in from the piece's edges (left, top, right, bottom) where that is
# not the face's own box.
PIECES = [
    ('seaPanel', (5, 4, 118, 62), (40, 70), (29, 38), (50, 30, 'f'), None,
     None),
    ('seaPill', (125, 5, 233, 40), (40, 80), (14, 21), (60, 17, 'F'),
     clean_pill, (9, 6, 9, 6)),
    ('seaGroove', (8, 66, 115, 82), (30, 80), None, None, None, None),
    ('seaFish', (5, 86, 100, 128), FISH_BAND[:2], None, (50, 20, 'F'),
     clean_fish, (24, 8, 14, 8)),
    ('seaBubble', (204, 44, 233, 74), None, None, (14, 14, 'F'), None,
     (6, 6, 6, 6)),
    ('seaRing', (105, 78, 159, 132), None, None, None, clean_ring, None),
]


def build(sheet):
    """{name: (rows, midX, midY, inset)}: every piece cleaned, its face
    lettered, and where its words go."""
    out = {}
    lantern = at = None
    for name, box, mid_x, mid_y, seed, clean, inset in PIECES:
        rows = cut(sheet, box)
        if name == 'seaPanel':
            lantern, at = take_lantern(rows)
        if clean:
            clean(rows)
        if seed:
            flood(rows, seed[:2], src=seed[2])
            if inset is None:
                l, t, r_, b = face_box(rows)
                inset = (l, t, len(rows[0]) - r_, len(rows) - b)
        out[name] = (rows, mid_x, mid_y, inset)
    out['seaLantern'] = (lantern, None, None, None)
    out['seaLanternUnlit'] = (lantern, None, None, None)
    out['seaWater'] = ([list(r) for r in WATER], (0, 12), None, None)
    out['seaNet'] = ([list(r) for r in NET], (0, 10), (0, 10), None)
    ring = out['seaRing']
    out['seaRingHalf'] = ([list(r) for r in halve([''.join(r) for r in ring[0]])],
                          None, None, None)
    out['_lanternAt'] = at
    return out


def sprite_dart(name, rows, mid_x, mid_y, palette):
    out = ['const PixelSprite %s = PixelSprite(' % name,
           '  palette: %s,' % palette]
    if mid_x:
        out.append('  midX: (%d, %d),' % mid_x)
    if mid_y:
        out.append('  midY: (%d, %d),' % mid_y)
    out.append('  rows: [')
    out += ["    '%s'," % ''.join(r) for r in rows]
    out += ['  ],', ');', '']
    return out


def palette_dart(name, doc, tones):
    out = [doc, 'const Map<String, Color> %s = {' % name]
    out += ["  '%s': Color(0xFF%s)," % (k, v[1:].upper())
            for k, v in tones.items()]
    out += ["  'W': Color(0xFF%s)," % tones['F'][1:].upper(), '};', '']
    return out


PALETTES = {'seaPanel': 'seaPanelPalette',
            'seaLanternUnlit': 'seaUnlitPalette'}


def tones_for(name):
    return {'seaPanel': PANEL, 'seaLanternUnlit': UNLIT}.get(name, TONES)


def dart(pieces):
    out = [
        '// GENERATED by art_src/gen_sea_ui.py from',
        '// art_src/lanternmaw-ui-sheet.jpg. Re-run it after editing the sheet;',
        '// never hand-edit this file.',
        '//',
        "// Lanternmaw's UI pieces, one letter a cell: . is empty, W the pale face",
        '// words are written on (recoloured when a tile flashes or glows).',
        "// The `...Face` insets are how many cells in from a piece's edges its",
        '// words go.',
        '',
        "import 'package:flutter/painting.dart';",
        '',
        "import 'pixel_sprite.dart';",
        '',
    ]
    out += palette_dart('seaPalette', "/// The sheet's colours.", TONES)
    out += palette_dart('seaPanelPalette',
                        "/// The same, with the panel's softer face.", PANEL)
    out += palette_dart('seaUnlitPalette',
                        '/// The lantern with its light out.', UNLIT)
    faces = {'seaPanel': 'seaPanelFace', 'seaPill': 'seaPillFace',
             'seaFish': 'seaFishFace', 'seaBubble': 'seaBubbleFace'}
    for name, piece in pieces.items():
        if name.startswith('_'):
            continue
        rows, mid_x, mid_y, inset = piece
        out += sprite_dart(name, rows, mid_x, mid_y,
                           PALETTES.get(name, 'seaPalette'))
        if name in faces:
            out += ['const EdgeInsets %s = EdgeInsets.fromLTRB(%d, %d, %d, %d);'
                    % ((faces[name],) + tuple(inset)), '']
    left, top = pieces['_lanternAt']
    out += [
        "/// Where the lantern hung on the sheet's panel, in cells from the panel's",
        '/// top left: the chain goes above the panel, the body over its corner.',
        'const int seaLanternLeft = %d;' % left,
        'const int seaLanternTop = %d;' % top,
        '',
    ]
    top, bottom, side = channel(pieces['seaGroove'], 'n')
    out += [
        "/// The groove's channel, which the water fills: the rows from its top, and",
        '/// from its foot, that are rim, and the columns in from either end.',
        'const int seaChannelTop = %d;' % top,
        'const int seaChannelBottom = %d;' % bottom,
        'const int seaChannelSide = %d;' % side,
        '',
    ]
    return '\n'.join(out)


if __name__ == '__main__':
    sheet = sample()
    pieces = build(sheet)
    if '--map' in sys.argv:
        want = sys.argv[sys.argv.index('--map') + 1]
        rows, mid_x, mid_y, inset = pieces[want]
        print('%s  %dx%d  midX %s  midY %s  words %s' % (
            want, len(rows[0]), len(rows), mid_x, mid_y, inset))
        print('    ' + ''.join(str(x % 10) for x in range(len(rows[0]))))
        for y, r in enumerate(rows):
            print('%3d %s' % (y, ''.join(r)))
    elif '--svg' in sys.argv:
        i = sys.argv.index('--svg') + 1
        path = (sys.argv[i] if i < len(sys.argv)
                else os.path.join(HERE, 'lanternmaw-ui-cells.svg'))
        items = [(name, p[0], tones_for(name),
                  'repeats: columns %s, rows %s' % (p[1], p[2])
                  if p[1] or p[2] else '')
                 for name, p in pieces.items() if not name.startswith('_')]
        with open(path, 'w', encoding='utf-8', newline='\n') as f:
            f.write(lib_sheet.cells_svg(items))
        print('wrote', path)
    elif '--preview' in sys.argv:
        out = sys.argv[sys.argv.index('--preview') + 1]
        os.makedirs(out, exist_ok=True)
        png([''.join(r) for r in sheet], 6, os.path.join(out, 'sheet.png'))
        for name, p in pieces.items():
            if name.startswith('_'):
                continue
            lib_sheet.png([''.join(r) for r in p[0]], 10,
                          os.path.join(out, name + '.png'), tones_for(name))
        print('wrote previews to', out)
    else:
        with open(OUT, 'w', encoding='utf-8', newline='\n') as f:
            f.write(dart(pieces))
        print('wrote', OUT)
