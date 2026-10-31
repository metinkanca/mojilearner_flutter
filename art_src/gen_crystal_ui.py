"""Builds Amethyst's UI pieces from the owner's image-tool sheet.

    python gen_crystal_ui.py                 # writes lib/components/boss_trial/crystal_ui_art.dart
    python gen_crystal_ui.py --map NAME      # prints one piece as a cell map
    python gen_crystal_ui.py --preview DIR   # one PNG a piece, and the whole sheet
    python gen_crystal_ui.py --svg [FILE]    # the pieces as the game gets them, as one SVG

See lib_sheet.py for how a sheet from the tool is read back to the cells it was
drawn on, and gen_sand_ui.py for the same job done for Sableth. Re-run after
any edit; never hand-edit the output.
"""
import os
import sys

import lib_sheet
from lib_sheet import channel, cut, face_box, flood, halve, same_rows

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, 'amethyst-ui-sheet.jpg')
OUT = os.path.normpath(os.path.join(
    HERE, '..', 'lib', 'components', 'boss_trial', 'crystal_ui_art.dart'))

# The sheet's cell, fitted to its edges (lib_sheet.fit): 11.5 pixels square.
# (235 x 134 cells.)
CELL = ((11.525, 0.6), (11.56, 8.8))

# letter -> colour. The crystal's three tones are L/V/P, with E the lit lilac of
# a bevel and D its shade; the plum stone of the frame R/S/T; B and A the dark
# of the base the tool stood its crystals on. F is also what words are written
# on (W where a piece marks its face).
TONES = {
    'K': '#11120e',   # outline
    'F': '#f2e5f6',   # pale face
    'E': '#e6d6e7',   # lit lilac
    'L': '#d4bad8',   # pale violet
    'V': '#bf94d7',   # violet
    'P': '#8359a7',   # purple
    'D': '#6e4489',   # purple in shade
    'R': '#876682',   # plum stone, lit
    'S': '#533c4d',   # plum stone
    'T': '#402d42',   # plum stone in shade
    'B': '#512351',   # the base under a crystal; an inner bevel line
    'A': '#3b1d3c',   # the groove's channel, darker still
}

# The pet's gems are Amethyst's gem in the pet's own colour, the rune light of
# its spells, so it is always clear whose piece is whose.
PET = {
    'K': '#11120e', 'F': '#e6f7f9', 'E': '#cbf1f5', 'L': '#a7dfe5',
    'V': '#6dc2ca', 'P': '#4d9ea9', 'D': '#356f7a', 'B': '#2b5560',
    'R': '#4d9ea9', 'S': '#356f7a', 'T': '#2b5560', 'A': '#2b5560',
}


def sample():
    return lib_sheet.sample(SRC, TONES, CELL)


def png(rows, scale, path):
    lib_sheet.png(rows, scale, path, TONES)


# ---- cleaning ---------------------------------------------------------------
#
# See gen_sand_ui.py: the game stretches a piece by repeating a run of columns
# and of rows, so each run has to be the same all the way down it.

def clean_panel(rows):
    # The vertical frame had seams at uneven heights, and chips: one plain
    # course, so the run can repeat.
    same_rows(rows, 16, 46, 30)


def clean_gem(rows):
    # The inner line under the top bevel is one colour; the tool dithered it
    # between two.
    for x in range(13, 65):
        if rows[4][x] in 'BD':
            rows[4][x] = 'B'


def clean_groove(rows):
    # Specks of outline inside the channel.
    for y in range(3, 13):
        for x in range(14, len(rows[y]) - 14):
            if rows[y][x] == 'K':
                rows[y][x] = 'A'


def clean_cluster(rows):
    # The tool stood its crystals on a puddle of dark. This one is charged
    # over the bear's head and thrown, so it has no ground: the puddle goes and
    # the crystals close with their own outline.
    del rows[51:]
    for r in rows:
        for x, c in enumerate(r):
            if c in 'BA':
                r[x] = 'K'


# The timer's fill, which the sheet does not draw (the tool's one small
# crystal is standing on a base): a bar of violet with crystals growing out of
# it, twelve cells wide so it repeats, eight tall like the groove's channel.
FILL = [
    '....E.......',
    '...LVP...E..',
    '...LVP..LVP.',
    '..LLVPP.LVP.',
    'VVVVVVVVVVVV',
    'VVVVVVVVVVVV',
    'PPPPPPPPPPPP',
    'DDDDDDDDDDDD',
]

# name in Dart, the piece's box on the sheet (cells), the repeating run of
# columns and of rows (start, end) or None, the cell of the face words go on
# (lettered W) or None, a cleaning step, and where words go as cells in from
# the piece's edges (left, top, right, bottom) where that is not the face's
# own box.
PIECES = [
    ('crystalPanel', (5, 4, 111, 69), (40, 60), (16, 46), (50, 30),
     clean_panel, None),
    ('crystalGem', (124, 5, 204, 36), (16, 64), (12, 19), (40, 15),
     clean_gem, None),
    # Two roots of crystal dip into the face from the top edge; the words go
    # under them.
    ('crystalPlate', (9, 76, 88, 128), (40, 48), (20, 40), (30, 30), None,
     (3, 18, 3, 5)),
    ('crystalGroove', (118, 46, 232, 62), (30, 50), (5, 11), None,
     clean_groove, None),
    # A teardrop, its top a hill: no run of columns is plain, so it is not
    # stretched but scaled whole. Words go in its body, clear of the point.
    ('crystalShard', (102, 82, 174, 128), None, None, (30, 24), None,
     (5, 12, 20, 12)),
    ('crystalCluster', (182, 71, 231, 130), None, None, None,
     clean_cluster, None),
]


def build(sheet):
    """{name: (rows, midX, midY, inset)}: every piece cleaned, its face
    lettered, and where its words go."""
    out = {}
    for name, box, mid_x, mid_y, seed, clean, inset in PIECES:
        rows = cut(sheet, box)
        if clean:
            clean(rows)
        if seed:
            flood(rows, seed)
            if inset is None:
                l, t, r_, b = face_box(rows)
                inset = (l, t, len(rows[0]) - r_, len(rows) - b)
        out[name] = (rows, mid_x, mid_y, inset)
    out['crystalFill'] = ([list(r) for r in FILL], (0, 12), None, None)
    out['crystalPetGem'] = out['crystalGem']
    # The cluster is thrown at 26 points and charged at 24 to 80: at half
    # resolution while a cell would be under a point.
    cluster = out['crystalCluster']
    out['crystalClusterHalf'] = (
        [list(r) for r in halve([''.join(r) for r in cluster[0]])],
        None, None, None)
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


def dart(pieces):
    out = [
        '// GENERATED by art_src/gen_crystal_ui.py from',
        '// art_src/amethyst-ui-sheet.jpg. Re-run it after editing the sheet;',
        '// never hand-edit this file.',
        '//',
        "// Amethyst's UI pieces, one letter a cell: . is empty, W the pale face",
        '// words are written on (recoloured when a tile flashes or glows).',
        "// The `...Face` insets are how many cells in from a piece's edges its",
        '// words go.',
        '',
        "import 'package:flutter/painting.dart';",
        '',
        "import 'pixel_sprite.dart';",
        '',
    ]
    out += palette_dart('crystalPalette', "/// The sheet's colours.", TONES)
    out += palette_dart('crystalPetPalette',
                        "/// The same letters in the pet's colour.", PET)
    faces = {'crystalPanel': 'crystalPanelFace', 'crystalGem': 'crystalGemFace',
             'crystalPlate': 'crystalPlateFace',
             'crystalShard': 'crystalShardFace'}
    for name, (rows, mid_x, mid_y, inset) in pieces.items():
        pal = 'crystalPetPalette' if name == 'crystalPetGem' else 'crystalPalette'
        out += sprite_dart(name, rows, mid_x, mid_y, pal)
        if name in faces:
            out += ['const EdgeInsets %s = EdgeInsets.fromLTRB(%d, %d, %d, %d);'
                    % ((faces[name],) + tuple(inset)), '']
    top, bottom, side = channel(pieces['crystalGroove'], 'A')
    out += [
        "/// The groove's channel, which the timer's crystal fills: the rows from its",
        '/// top, and from its foot, that are rim, and the columns in from either end.',
        'const int crystalChannelTop = %d;' % top,
        'const int crystalChannelBottom = %d;' % bottom,
        'const int crystalChannelSide = %d;' % side,
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
                else os.path.join(HERE, 'amethyst-ui-cells.svg'))
        items = [(name, rows,
                  PET if name == 'crystalPetGem' else TONES,
                  'repeats: columns %s, rows %s' % (mx, my) if mx or my else '')
                 for name, (rows, mx, my, _) in pieces.items()]
        with open(path, 'w', encoding='utf-8', newline='\n') as f:
            f.write(lib_sheet.cells_svg(items))
        print('wrote', path)
    elif '--preview' in sys.argv:
        out = sys.argv[sys.argv.index('--preview') + 1]
        os.makedirs(out, exist_ok=True)
        png([''.join(r) for r in sheet], 6, os.path.join(out, 'sheet.png'))
        for name, (rows, _, _, _) in pieces.items():
            png([''.join(r) for r in rows], 10, os.path.join(out, name + '.png'))
        print('wrote previews to', out)
    else:
        with open(OUT, 'w', encoding='utf-8', newline='\n') as f:
            f.write(dart(pieces))
        print('wrote', OUT)
