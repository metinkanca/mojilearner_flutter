"""Builds Sableth's UI pieces from the owner's image-tool sheet.

    python gen_sand_ui.py                 # writes lib/components/boss_trial/sand_ui_art.dart
    python gen_sand_ui.py --map NAME      # prints one piece as a cell map
    python gen_sand_ui.py --preview DIR   # one PNG a piece, and the whole sheet, on magenta
    python gen_sand_ui.py --svg [FILE]    # the pieces as the game gets them, as one SVG

The source (`sableth-ui-sheet.jpg`) is a 1376x768 picture from an image tool:
pixel art on a magenta ground, but upscaled by a fractional amount and saved as
a JPEG, so its cells are 5.732 pixels square with soft, noisy edges. This
reads it back to the cells it was drawn on: the grid is fitted once (the
constants below), each cell is the median colour of the middle of its block,
and every colour is snapped to a small palette -- three tones a material, the
way the rest of the art is shaded -- with every near-black folded into the one
outline colour, which is where nearly all the JPEG noise is.

Pieces are then cut out by box, cleaned where the tool drew something the game
cannot stretch (cracks and ticks that would repeat down a plain run), and
emitted as rows of letters for `PixelSprite`, like gen_moss_ui.py and
gen_fire_ui.py do for the other two bosses. Pieces that stretch name the runs
of columns and rows that repeat; where words go, the face is flood-filled from
a seed and lettered W so a tile can flash or glow without its rim going with
it.

Re-run after any edit; never hand-edit the output.
"""
import os
import sys

import lib_sheet
from lib_sheet import channel, cut, face_box, flood, same_rows

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, 'sableth-ui-sheet.jpg')
OUT = os.path.normpath(os.path.join(
    HERE, '..', 'lib', 'components', 'boss_trial', 'sand_ui_art.dart'))

# The sheet's cell, fitted to its edges (lib_sheet.fit): 87% of the picture's
# edge energy sits within a pixel of these lines, on both axes. (240 x 133
# cells.)
CELL = ((5.732, 0.2), (5.732, 2.8))

# letter -> colour. Three tones a material: gold Y/G/D, wood O/P, blue N/M,
# cream C/F and the tan T of carved stone, glass g/b. F is also what words are
# written on (W where a piece marks its face).
TONES = {
    'K': '#14120e',   # outline
    'F': '#ebd3ac',   # pale papyrus and stone
    'C': '#ecca87',   # lit cream
    'T': '#c4a475',   # tan: carved lines and rims in the stone
    'Y': '#f3c756',   # bright gold
    'G': '#d99f43',   # gold
    'D': '#bf8530',   # gold in shade
    'O': '#a3692f',   # wood
    'P': '#7b4f2b',   # wood in shade
    'N': '#324963',   # headdress blue
    'M': '#1e2f4a',   # blue in shade
    'g': '#d3e1df',   # glass
    'b': '#82b1c4',   # glass rim
}


# ---- cleaning ---------------------------------------------------------------
#
# The tool draws every piece once, at one size. The game stretches by repeating
# a run of columns and of rows, so anything in a run that is not the same down
# the run (a crack, a chip, a ragged edge, stripes of uneven widths) would be
# copied down the whole panel. Each piece is made plain along its runs here,
# and keeps what the tool drew everywhere else.

def clean_panel(rows):
    # Stripes of even widths, so a repeated run of columns stays in step:
    # gold four cells, blue six, whatever the width.
    for light, shade, gold, blue in (((6, 10), (10, 12), 'G', 'N'),
                                     ((45, 48), (48, 50), 'G', 'N')):
        for c in range(12, 84):
            on_gold = (c - 11) % 10 < 4
            for y in range(*light):
                rows[y][c] = gold if on_gold else blue
            for y in range(*shade):
                rows[y][c] = 'D' if on_gold else 'M'
    # The papyrus between its rods: straight edges down the middle, the tool's
    # torn corners kept at its top and foot.
    same_rows(rows, 18, 40, 19)


def clean_tablet(rows):
    same_rows(rows, 20, 47, 30)


def clean_door(rows):
    # The lintel's stripes at an even ten cells, gold four, slanted a cell
    # more on each row of the cornice the way the tool drew them, so the run
    # of columns that repeats keeps them in step.
    for y0, y1, shift, gold, blue in ((4, 6, 0, 'G', 'N'), (7, 9, 1, 'D', 'M'),
                                      (9, 11, 2, 'G', 'N')):
        for y in range(y0, y1):
            for c, ch in enumerate(rows[y]):
                if ch in 'NGMDY':
                    rows[y][c] = gold if (c - 7 - shift) % 10 < 4 else blue
    # One speck of shade in the doorway, and the inner frame drawn two ways
    # down the pillars: the band repeats, so it has to be one.
    for y in range(31, 45):
        for x in range(15, 20):
            rows[y][x] = rows[40][x]
        for x in range(20, 39):
            rows[y][x] = 'F'


# ---- the pieces -------------------------------------------------------------

# name in Dart, the piece's box on the sheet (cells), the repeating run of
# columns and of rows (start, end) or None, the cell of the face words go on
# (lettered W) or None, and a cleaning step.
PIECES = [
    ('sandPanel', (5, 3, 102, 59), (34, 44), (18, 40), (40, 28), clean_panel),
    ('sandTile', (109, 5, 185, 31), (14, 24), (10, 16), (30, 12), None),
    ('sandTablet', (6, 66, 47, 129), (18, 24), (20, 47), (20, 30),
     clean_tablet),
    ('sandGroove', (109, 35, 185, 51), (12, 22), (5, 9), None, None),
    ('sandDoor', (100, 63, 159, 129), (24, 34), (31, 45), (28, 40),
     clean_door),
    ('sandDial', (207, 54, 235, 88), (10, 18), (11, 23), (14, 15), None),
    ('sandCell', (165, 92, 202, 129), (10, 26), (10, 26), (18, 18), None),
    ('sandHourglass', (209, 95, 234, 129), None, None, None, None),
    # The sheet's pyramid of sand: heaped over the pet when the sand runs out.
    ('sandHeap', (189, 23, 236, 46), None, None, None, None),
]

# The timer's fill, which the sheet does not draw: a strip of the heap's sand,
# eight cells wide so it repeats along the groove, seven tall like the
# groove's channel. Lit along its top, specks of shade through it.
FILL = [
    'CCCCCCCC',
    'YYYYYYYY',
    'YYDYYYYY',
    'YYYYYYYD',
    'YDYYYYYY',
    'YYYYDYYY',
    'GGGGGGGG',
]


def sample():
    return lib_sheet.sample(SRC, TONES, CELL)


def png(rows, scale, path):
    lib_sheet.png(rows, scale, path, TONES)


def build(sheet):
    """{name: (rows, midX, midY)} with every piece cleaned and its face
    lettered."""
    out = {}
    for name, box, mid_x, mid_y, seed, clean in PIECES:
        rows = cut(sheet, box)
        if clean:
            clean(rows)
        if seed:
            flood(rows, seed)
        out[name] = (rows, mid_x, mid_y)
    out['sandFill'] = ([list(r) for r in FILL], (0, 8), None)
    return out


# ---- the game's stretch, to see a piece at the size it is drawn ------------

def dart(pieces):
    out = [
        '// GENERATED by art_src/gen_sand_ui.py from',
        '// art_src/sableth-ui-sheet.jpg. Re-run it after editing the sheet;',
        '// never hand-edit this file.',
        '//',
        "// Sableth's UI pieces, one letter a cell: . is empty, W the pale face",
        '// words are written on (recoloured when a tile flashes or glows).',
        "// The `...Face` insets are how many cells in from a piece's edges its",
        '// words go.',
        '',
        "import 'package:flutter/painting.dart';",
        '',
        "import 'pixel_sprite.dart';",
        '',
        "/// The sheet's colours, for anything drawn to match it.",
        'const Map<String, Color> sandPalette = {',
    ]
    for letter, fill in TONES.items():
        out.append("  '%s': Color(0xFF%s)," % (letter, fill[1:].upper()))
    out.append("  'W': Color(0xFF%s)," % TONES['F'][1:].upper())
    out += ['};', '']
    faces = {'sandPanel': 'sandPanelFace', 'sandTile': 'sandTileFace',
             'sandTablet': 'sandTabletFace', 'sandDoor': 'sandDoorFace',
             'sandDial': 'sandDialFace', 'sandCell': 'sandCellFace'}
    for name, (rows, mid_x, mid_y) in pieces.items():
        w, h = len(rows[0]), len(rows)
        out.append('const PixelSprite %s = PixelSprite(' % name)
        out.append('  palette: sandPalette,')
        if mid_x:
            out.append('  midX: (%d, %d),' % mid_x)
        if mid_y:
            out.append('  midY: (%d, %d),' % mid_y)
        out.append('  rows: [')
        for r in rows:
            out.append("    '%s'," % ''.join(r))
        out += ['  ],', ');', '']
        if name in faces:
            l, t, r_, b = face_box(rows)
            out += ['const EdgeInsets %s = EdgeInsets.fromLTRB(%d, %d, %d, %d);'
                    % (faces[name], l, t, w - r_, h - b), '']
    top, bottom, side = channel(pieces['sandGroove'])
    out += [
        "/// The groove's channel, which the timer's sand fills: the rows from its",
        '/// top, and from its foot, that are rim, and the columns in from either end.',
        'const int sandChannelTop = %d;' % top,
        'const int sandChannelBottom = %d;' % bottom,
        'const int sandChannelSide = %d;' % side,
        '',
    ]
    return '\n'.join(out)


if __name__ == '__main__':
    sheet = sample()
    pieces = build(sheet)
    if '--map' in sys.argv:
        want = sys.argv[sys.argv.index('--map') + 1]
        rows, mid_x, mid_y = pieces[want]
        print('%s  %dx%d  midX %s  midY %s' % (want, len(rows[0]), len(rows),
                                               mid_x, mid_y))
        print('    ' + ''.join(str(x % 10) for x in range(len(rows[0]))))
        for y, r in enumerate(rows):
            print('%3d %s' % (y, ''.join(r)))
    elif '--svg' in sys.argv:
        i = sys.argv.index('--svg') + 1
        path = (sys.argv[i] if i < len(sys.argv)
                else os.path.join(HERE, 'sableth-ui-cells.svg'))
        items = [(name, rows, TONES, 'repeats: columns %s, rows %s' % (mx, my)
                  if mx or my else '')
                 for name, (rows, mx, my) in pieces.items()]
        with open(path, 'w', encoding='utf-8', newline='\n') as f:
            f.write(lib_sheet.cells_svg(items))
        print('wrote', path)
    elif '--preview' in sys.argv:
        out = sys.argv[sys.argv.index('--preview') + 1]
        os.makedirs(out, exist_ok=True)
        png([''.join(r) for r in sheet], 6, os.path.join(out, 'sheet.png'))
        for name, (rows, _, _) in pieces.items():
            png([''.join(r) for r in rows], 10, os.path.join(out, name + '.png'))
        print('wrote previews to', out)
    else:
        with open(OUT, 'w', encoding='utf-8', newline='\n') as f:
            f.write(dart(pieces))
        print('wrote', OUT)
