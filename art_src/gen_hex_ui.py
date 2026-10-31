"""Builds Hoothex's UI pieces from the owner's image-tool sheet.

    python gen_hex_ui.py                 # writes lib/components/boss_trial/hex_ui_art.dart
    python gen_hex_ui.py --map NAME      # prints one piece as a cell map
    python gen_hex_ui.py --preview DIR   # one PNG a piece, and the whole sheet
    python gen_hex_ui.py --svg [FILE]    # the pieces as the game gets them, as one SVG

See lib_sheet.py for how a sheet from the tool is read back to the cells it was
drawn on, and gen_sand_ui.py / gen_crystal_ui.py for the same job done for the
other bosses. Re-run after any edit; never hand-edit the output.
"""
import os
import sys

import lib_sheet
from lib_sheet import channel, cut, face_box, flood, halve, same_rows

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, 'hoothex-ui-sheet.jpg')
OUT = os.path.normpath(os.path.join(
    HERE, '..', 'lib', 'components', 'boss_trial', 'hex_ui_art.dart'))

# The sheet's cell, fitted to its edges (lib_sheet.fit): 11.5 pixels square.
# (240 x 133 cells.)
CELL = ((11.465, 0.2), (11.465, 5.8))

# letter -> colour. Parchment F/C/T, wood O/P/Q, the witch's purple L/V/N/M/D
# and the iron of the cauldron R/S, brew G/H/Z, flame Y/B, glass g/h. F is also
# what words are written on (W where a piece marks its face).
TONES = {
    'K': '#14120e',   # outline
    'F': '#f4dab1',   # parchment
    'C': '#f5e5c9',   # parchment, lit
    'T': '#deb27c',   # parchment in shade, and its torn edge
    'O': '#ad784b',   # wood
    'P': '#885b38',   # wood in shade
    'Q': '#643d23',   # wood, darkest
    'L': '#ccaced',   # lilac
    'V': '#ac7ed4',   # violet
    'N': '#895bb8',   # purple
    'M': '#73459a',   # purple, deeper
    'D': '#58307a',   # purple in shade
    'R': '#47305b',   # iron
    'S': '#32213f',   # iron in shade
    'G': '#66aa32',   # brew
    'H': '#86cb49',   # brew, lit
    'Z': '#488537',   # brew in shade
    'Y': '#f2bd69',   # flame
    'B': '#dc9845',   # flame, orange
    'g': '#94b1c9',   # glass
    'h': '#e8f1f7',   # glass, lit
}

# A gate's stone in the colour of the gate's state: the plain purple, a
# refused gate's red (the fizzle of the pet's spells) and a right one's rune
# light, so the gate it flies through shows how it went.
GATE_WRONG = dict(TONES, V='#f08c94', N='#d95763', M='#bf4a58', D='#a33a48',
                  R='#7d2b38')
GATE_RIGHT = dict(TONES, V='#cbf1f5', N='#6dc2ca', M='#58a8b2', D='#3f8d99',
                  R='#2c6670')


def sample():
    return lib_sheet.sample(SRC, TONES, CELL, dark=50)


def png(rows, scale, path):
    lib_sheet.png(rows, scale, path, TONES)


def interior(rows, x, y):
    """Whether a cell has a cell on every side: it is not on a piece's edge."""
    h, w = len(rows), len(rows[0])
    return all(0 <= x + dx < w and 0 <= y + dy < h
               and rows[y + dy][x + dx] != '.'
               for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))


def remap(rows, table, y0=0, y1=None, x0=0, x1=None):
    """Letters in [rows] (a box of them) changed by [table]."""
    for y in range(y0, len(rows) if y1 is None else y1):
        for x in range(x0, len(rows[y]) if x1 is None else x1):
            rows[y][x] = table.get(rows[y][x], rows[y][x])


# ---- cleaning ---------------------------------------------------------------
#
# See gen_sand_ui.py: the game stretches a piece by repeating a run of columns
# and of rows, so each run has to be the same all the way down it. And the
# owner asked that what the tool shaded heavily -- the cauldrons, the flask
# and the broom -- be flat: an outline, a body, and at most one lit tone,
# like the rest of the art.

# The wax seal sits low on the right of the scroll, where words would be
# written and the fuse runs under it. It comes off the scroll and is drawn on
# its own, where there is room.
SEAL_COLS = (79, 90)
SEAL_ROWS = (37, 51)


def take_seal(rows):
    """The seal as its own rows, and [rows] with the parchment put back."""
    (x0, x1), (y0, y1) = SEAL_COLS, SEAL_ROWS
    seal = [['.'] * (x1 - x0) for _ in range(y1 - y0)]
    for y in range(y0, y1):
        for x in range(x0, x1):
            c = rows[y][x]
            if c in 'LNMDRV' or (c == 'K' and y in (48, 50)):
                seal[y - y0][x - x0] = c
    for y in range(y0, y1):
        for x in range(x0 - 1, x1 + 1):
            if (c := rows[y][x]) in 'LNMDRV' or (c == 'K' and y in (48, 50)):
                rows[y][x] = rows[y][60] if y < len(rows) - 3 else '.'
    return seal


def clean_scroll(rows):
    pass


def clean_gate(rows):
    # The crown's stones carry a rune each, at different heights: the run of
    # columns that repeats is plain stone, and the posts keep one rune a block.
    remap(rows, {'F': 'N', 'D': 'N', 'M': 'N', 'R': 'N'}, 2, 9, 25, 33)


def clean_cauldron(rows):
    # Flat iron, flat brew. The tool shaded the pot in four tones and let its
    # deepest fall into the outline's black; the body is one iron colour with
    # an outline one cell thick.
    remap(rows, {'Z': 'G', 'O': 'K', 'S': 'R', 'M': 'R'})
    body = next(y for y, r in enumerate(rows) if r.count('R') >= 6)
    for y in range(body, len(rows)):
        for x in range(len(rows[y])):
            if rows[y][x] == 'K' and interior(rows, x, y):
                rows[y][x] = 'R'


def clean_broom(rows):
    # Handle: lit above, shaded below. Bristles: straw and its shade. The
    # binding: wood. The tool had four browns running through all of them.
    for y, r in enumerate(rows):
        for x, c in enumerate(r):
            if c not in 'OPQTB':
                continue
            if x < 42:
                r[x] = 'O' if y <= 8 else 'P'
            elif x < 53:
                r[x] = 'O' if c in 'PQT' else c
            else:
                r[x] = 'B'
    # The tool drew its broom head to the right; the game has the bristles
    # behind the pet, on the left.
    for r in rows:
        r.reverse()


def clean_potion(rows):
    # Cork in two browns, glass in one tint and a highlight, brew in one green
    # with its lit top.
    remap(rows, {'B': 'O', 'Q': 'P', 'L': 'g', 'N': 'g', 'Z': 'G'})
    remap(rows, {'H': 'G'}, 20)


# The timer's fuse, which the sheet draws as one wavy rope: a straight rope
# four cells thick that repeats along the groove's channel, in the sheet's
# browns, and the ash behind the flame in its iron.
ROPE = [
    'OOOOOOOO',
    'OPOOPOOP',
    'POOPOOPO',
    'QQQQQQQQ',
]
ASH = [
    'RRRRRRRR',
    'RSRRSRRS',
    'SRRSRRSR',
    'SSSSSSSS',
]


def take(sheet, box):
    return cut(sheet, box)


# name in Dart, the piece's box on the sheet (cells), the repeating run of
# columns and of rows (start, end) or None, the cell of the face words go on
# (lettered W) or None, a cleaning step, and where words go as cells in from
# the piece's edges (left, top, right, bottom) where that is not the face's
# own box.
PIECES = [
    ('hexScroll', (9, 4, 115, 57), (32, 62), (20, 34), (50, 25), clean_scroll,
     (16, 10, 16, 7)),
    ('hexTag', (130, 7, 206, 35), (20, 50), (15, 20), (30, 10), None,
     (5, 4, 8, 5)),
    ('hexGroove', (8, 61, 116, 77), (30, 70), None, None, None, None),
    ('hexSpark', (152, 43, 167, 59), None, None, None, None, None),
    ('hexGate', (142, 66, 200, 103), (25, 33), (22, 29), (29, 25), clean_gate,
     (16, 17, 16, 2)),
    ('hexCauldronLow', (8, 92, 45, 128), None, None, None, clean_cauldron,
     None),
    ('hexCauldronMid', (51, 88, 88, 128), None, None, None, clean_cauldron,
     None),
    ('hexCauldronFull', (94, 86, 133, 128), None, None, None, clean_cauldron,
     None),
    ('hexBroom', (139, 109, 206, 127), (27, 41), None, None, clean_broom,
     None),
    ('hexPotion', (211, 96, 233, 128), None, None, None, clean_potion, None),
]

# The bubble is cut in two: the body, which stretches to its words, and the
# tail, which is drawn in the middle of its foot at any width.
BUBBLE = (177, 39, 232, 65)
TAIL_COLS = (23, 32)


def build(sheet):
    """{name: (rows, midX, midY, inset)}: every piece cleaned, its face
    lettered, and where its words go."""
    out = {}
    for name, box, mid_x, mid_y, seed, clean, inset in PIECES:
        rows = cut(sheet, box)
        if name == 'hexScroll':
            seal = take_seal(rows)
        if clean:
            clean(rows)
        if seed:
            flood(rows, seed)
            if inset is None:
                l, t, r_, b = face_box(rows)
                inset = (l, t, len(rows[0]) - r_, len(rows) - b)
        out[name] = (rows, mid_x, mid_y, inset)
    out['hexSeal'] = (_crop(seal), None, None, None)

    bubble = cut(sheet, BUBBLE)
    # The rim along the foot is dithered between two purples; it is one.
    remap(bubble, {'N': 'M'}, 20, 21, 5, 50)
    x0, x1 = TAIL_COLS
    tail = [['.'] * (x1 - x0 + 1) for _ in range(len(bubble) - 19)]
    for y in range(19, len(bubble)):
        for x in range(x0, x1 + 1):
            tail[y - 19][x - x0] = bubble[y][x]
    # The body's foot where the tail was: its own rim, as at the cell beside.
    for y in range(19, 22):
        for x in range(x0, x1 + 1):
            bubble[y][x] = bubble[y][x0 - 4]
    del bubble[22:]
    flood(bubble, (27, 10))
    for r in tail:
        for x, c in enumerate(r):
            if c == 'F':
                r[x] = 'W'
    l, t, r_, b = face_box(bubble)
    out['hexBubble'] = (bubble, (10, 45), (5, 16),
                        (l + 2, t + 1, len(bubble[0]) - r_ + 2, 4))
    out['hexBubbleTail'] = (tail, None, None, None)

    out['hexRope'] = ([list(r) for r in ROPE], (0, 8), None, None)
    out['hexAsh'] = ([list(r) for r in ASH], (0, 8), None, None)
    potion = out['hexPotion']
    out['hexPotionHalf'] = (
        [list(r) for r in halve([''.join(r) for r in potion[0]])],
        None, None, None)
    gate = out['hexGate']
    out['hexGateWrong'] = gate
    out['hexGateRight'] = gate
    return out


def _crop(rows):
    """[rows] without the empty rows and columns round them."""
    ys = [y for y, r in enumerate(rows) if any(c != '.' for c in r)]
    xs = [x for r in rows for x, c in enumerate(r) if c != '.']
    return [r[min(xs):max(xs) + 1] for r in rows[min(ys):max(ys) + 1]]


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


PALETTES = {'hexGateWrong': 'hexGateWrongPalette',
            'hexGateRight': 'hexGateRightPalette'}
TONES_OF = {'hexGateWrong': GATE_WRONG, 'hexGateRight': GATE_RIGHT}


def dart(pieces):
    out = [
        '// GENERATED by art_src/gen_hex_ui.py from',
        '// art_src/hoothex-ui-sheet.jpg. Re-run it after editing the sheet;',
        '// never hand-edit this file.',
        '//',
        "// Hoothex's UI pieces, one letter a cell: . is empty, W the pale face",
        '// words are written on (recoloured when a tile flashes or glows).',
        "// The `...Face` insets are how many cells in from a piece's edges its",
        '// words go.',
        '',
        "import 'package:flutter/painting.dart';",
        '',
        "import 'pixel_sprite.dart';",
        '',
    ]
    out += palette_dart('hexPalette', "/// The sheet's colours.", TONES)
    out += palette_dart('hexGateWrongPalette',
                        "/// A refused gate's stone, in the pet's fizzle.",
                        GATE_WRONG)
    out += palette_dart('hexGateRightPalette',
                        "/// A right gate's stone, in the pet's rune light.",
                        GATE_RIGHT)
    faces = {'hexScroll': 'hexScrollFace', 'hexTag': 'hexTagFace',
             'hexBubble': 'hexBubbleFace', 'hexGate': 'hexGateFace'}
    for name, (rows, mid_x, mid_y, inset) in pieces.items():
        out += sprite_dart(name, rows, mid_x, mid_y,
                           PALETTES.get(name, 'hexPalette'))
        if name in faces:
            out += ['const EdgeInsets %s = EdgeInsets.fromLTRB(%d, %d, %d, %d);'
                    % ((faces[name],) + tuple(inset)), '']
    top, bottom, side = channel(pieces['hexGroove'], 'M')
    out += [
        "/// The groove's channel, which the fuse is laid along: the rows from its",
        '/// top, and from its foot, that are rim, and the columns in from either end.',
        'const int hexChannelTop = %d;' % top,
        'const int hexChannelBottom = %d;' % bottom,
        'const int hexChannelSide = %d;' % side,
        '',
    ]
    return '\n'.join(out)


def tones_for(name):
    return TONES_OF.get(name, TONES)


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
                else os.path.join(HERE, 'hoothex-ui-cells.svg'))
        items = [(name, rows, tones_for(name),
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
            lib_sheet.png([''.join(r) for r in rows], 10,
                          os.path.join(out, name + '.png'), tones_for(name))
        print('wrote previews to', out)
    else:
        with open(OUT, 'w', encoding='utf-8', newline='\n') as f:
            f.write(dart(pieces))
        print('wrote', OUT)
