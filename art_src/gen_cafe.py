# -*- coding: utf-8 -*-
"""Draws the cafe interior pet background, a sibling of `forest-clean-tones.svg`.

    python art_src/gen_cafe.py

`lib_scene` holds the grammar the forest sets and this follows; what is here
is the room. Its composition is laid out on the forest's lines -- a big empty
band up top with two small things hung in it, every landmark packed into a mid
band, a plain ground below the horizon at y560, and the ground specks in the
forest's own places, so the two grounds read as one floor of the world.

The palette is the forest's, moved from woodland to room. Nine of its ten
colours are here unchanged: the sky's hue becomes the wall, the trunk browns
become the counter, the sand becomes the floorboards, its speck tone becomes
the seams in them, and the leaf greens come back on the chalkboard and the
plants. Three are added, and each earns it -- a pale wall tone, a darker wood
for the counter front, and one terracotta, because a room of woods and sages
has nothing to look at in it. The outline ink shifts from the forest's green
to a brown of the same weight, since what it is drawing here is wood.
"""
from lib_scene import (COLS, GROUND, ROWS, blank, box, build, dome, outline,
                       rect, specks, stamp, write)

OUT = 'cafe-clean-tones.svg'

# Where the room is divided. GROUND is the forest's horizon, y560.
COUNTER = 212          # the slab the props stand on
TILES = 182            # the splashback behind it

# Painted back to front, one path each. The wall and the floor are emitted as
# whole bands; everything else is its own region, which is what the forest's
# own layers are.
LAYERS = [
    ('wall',             'W', '#b9d7d4'),
    ('floor',            'F', '#e9bc70'),
    ('window-daylight',  'B', '#8dcdf3'),
    ('tiles',            'S', '#609fa6'),
    ('tile-grout',       'D', '#347d83'),
    ('leaves',           'P', '#488b50'),
    ('leaf-shadows',     'Q', '#286147'),
    ('floorboard-seams', 'G', '#ba8350'),
    ('light-wood',       'L', '#ba8350'),
    ('mid-wood',         'M', '#93643d'),
    ('dark-wood',        'K', '#6b4326'),
    ('terracotta',       'R', '#c2604d'),
    ('porcelain',        'C', '#fff4df'),
    ('outlines',         'O', '#2f1d14'),
]

BANDS = {'W': (0, GROUND), 'F': (GROUND, ROWS)}


# --- the room --------------------------------------------------------------

CUP = [
    'OOOOOO..',
    'OCCCCO..',
    'OCCCCOOO',
    'OCCCCO.O',
    'OCCCCOOO',
    'OCCCCO..',
    '.OCCCO..',
    '..OOO...',
]

LEAVES = [
    '....PP......PP......',
    '...PPPP....PPPP.....',
    '...PQPP...PPQPP.....',
    '....PPPP.PPPP.......',
    '.....PPPPPPPP.......',
    '..PP...PPPP...PP....',
    '.PPPPP..PP..PPPPP...',
    '.PQPPP..PP..PPPQP...',
    '..PPPP..PP..PPPP....',
    '....P...PP...P......',
    '........PP..........',
]


def lamp(g, cx, bottom):
    """A pendant hung where the forest puts a cloud, and read at that size."""
    top = bottom - 15
    rect(g, cx, 0, cx + 1, top, 'O')                       # flex
    rect(g, cx - 4, top - 1, cx + 5, top, 'O')             # ceiling rose
    for r in range(15):
        h = 3 + min(r, 11) // 2
        y = top + r
        rect(g, cx - h - 1, y, cx + h + 1, y + 1, 'O')
        rect(g, cx - h, y, cx + h, y + 1,
             'O' if r == 14 else 'C' if r >= 12 else 'M')


def window(g):
    """The forest, seen from inside: the reason the two palettes are one."""
    x0, y0, x1, y1 = 6, 124, 54, 166
    box(g, x0, y0, x1, y1, 'M')                            # frame
    gx0, gy0, gx1, gy1 = x0 + 4, y0 + 4, x1 - 4, y1 - 4    # glass

    rect(g, gx0, gy0, gx1, gy1, 'B')
    rect(g, 14, 133, 21, 135, 'C')                         # cloud
    rect(g, 15, 132, 20, 133, 'C')
    for x, h in ((gx0, 6), (14, 9), (19, 5), (24, 8), (30, 11),
                 (35, 7), (41, 10), (46, 6)):              # far treeline
        rect(g, x, gy1 - h - 6, min(x + 6, gx1), gy1 - 6, 'S')
    for x, h in ((gx0, 8), (13, 11), (20, 7), (26, 12), (33, 8),
                 (39, 11), (45, 8)):                       # near canopy
        rect(g, x, gy1 - h, min(x + 7, gx1), gy1, 'P')
    rect(g, gx0, gy1 - 3, gx1, gy1, 'Q')

    rect(g, 29, gy0, 32, gy1, 'M')                         # muntins
    rect(g, gx0, 143, gx1, 146, 'M')

    rect(g, 3, y1, 57, y1 + 6, 'L')                        # sill
    rect(g, 3, y1 + 5, 57, y1 + 6, 'O')
    rect(g, 3, y1, 4, y1 + 6, 'O')
    rect(g, 56, y1, 57, y1 + 6, 'O')


def chalkboard(g):
    """A menu with no words on it: the app ships thirty languages."""
    box(g, 64, 126, 114, 164, 'L')
    box(g, 67, 129, 111, 161, 'Q')

    stamp(g, 70, 132, [                                    # a cup, in chalk
        '..C.C.C..',
        '..C.C.C..',
        '.........',
        'CCCCCCC..',
        'C.....C.C',
        'C.....CC.',
        'C.....C.C',
        '.CCCCC...',
    ], {'C': 'C'})
    rect(g, 83, 133, 105, 135, 'C')                        # heading rule
    for y, w in ((143, 22), (149, 17), (155, 24)):         # items and prices
        rect(g, 71, y, 71 + w, y + 2, 'C')
        rect(g, 99, y, 107, y + 2, 'C')


def shelves(g):
    """Open shelving, run off the right edge the way the treeline runs off both."""
    for y, h in ((124, 5), (148, 5), (166, 6)):
        rect(g, 116, y, COLS, y + h, 'L')
        rect(g, 116, y, COLS, y + 1, 'O')
        rect(g, 116, y + h - 1, COLS, y + h, 'O')
    for x in (118, 172):
        box(g, x, 124, x + 5, 172, 'M')

    box(g, 124, 133, 138, 148, 'C')                        # jar
    box(g, 123, 132, 139, 137, 'M')
    rect(g, 126, 140, 136, 147, 'M')
    for x in (141, 151, 161):                              # cups
        stamp(g, x, 140, CUP, {'O': 'O', 'C': 'C'})

    box(g, 124, 154, 142, 166, 'M')                        # sack of beans
    rect(g, 127, 153, 139, 156, 'O')
    rect(g, 129, 158, 137, 163, 'C')

    dome(g, 158, 153, [3, 5, 6, 6, 7, 7, 7, 7, 7, 6, 6, 5, 3], 'M')
    dome(g, 158, 155, [3, 4, 4, 5, 5, 5, 5, 4, 4, 3], 'C')  # clock face
    rect(g, 158, 157, 159, 160, 'O')
    rect(g, 158, 159, 162, 160, 'O')


def machine(g):
    """The landmark, where the forest puts its one edited trunk."""
    for x in (77, 89, 101):                                # cups warming on top
        box(g, x, 170, x + 7, 176, 'C')

    box(g, 72, 176, 112, 182, 'M')                         # warmer tray
    box(g, 74, 181, 110, 204, 'R')                         # body
    box(g, 83, 184, 101, 190, 'C')                         # badge
    rect(g, 89, 186, 95, 188, 'R')
    box(g, 77, 194, 107, 201, 'C')                         # control panel
    for x in (80, 86, 96, 102):
        rect(g, x, 196, x + 2, 199, 'K')
    for arm, elbow in ((71, 70), (111, 107)):              # steam wands, each
        rect(g, arm, 191, arm + 3, 204, 'O')               # joined to the body
        rect(g, elbow, 190, elbow + 7, 193, 'O')           # by an elbow

    box(g, 74, 203, 110, 212, 'K')                         # base
    for x in (80, 94):                                     # groups, and a cup under each
        rect(g, x, 205, x + 10, 209, 'O')
        box(g, x + 2, 208, x + 8, 212, 'C')


def counter_props(g):
    dome(g, 29, 187, [3, 5, 7, 8, 9, 9, 9], 'C')           # frosting
    rect(g, 29, 181, 30, 184, 'Q')                         # cherry, and its stem
    dome(g, 29, 184, [1, 2, 2], 'R')
    rect(g, 19, 194, 40, 203, 'O')                         # sponge
    rect(g, 20, 194, 39, 203, 'L')
    rect(g, 20, 197, 39, 200, 'R')                         # the jam layer
    box(g, 14, 203, 45, 206, 'L')                          # stand: plate,
    box(g, 25, 206, 34, 210, 'L')                          # stem,
    box(g, 20, 209, 39, 212, 'L')                          # foot

    for x0, x1, y in ((48, 62, 208), (49, 61, 204), (50, 60, 200)):
        box(g, x0, y, x1, y + 4, 'C')                      # stacked saucers

    box(g, 122, 194, 138, 212, 'S')                        # jar of beans
    rect(g, 125, 204, 135, 211, 'K')                       # beans, half full
    rect(g, 125, 197, 127, 202, 'C')                       # glass highlight
    box(g, 121, 190, 139, 196, 'M')

    stamp(g, 146, 192, LEAVES, {'P': 'P', 'Q': 'Q'})       # potted plant
    outline(g, 'PQ', 144, 190, 168, 205)
    box(g, 148, 203, 164, 206, 'R')                        # rim, then the pot
    for j, inset in enumerate((0, 0, 1, 1, 2, 2)):
        rect(g, 150 + inset, 206 + j, 162 - inset, 207 + j, 'R')
        rect(g, 149 + inset, 206 + j, 150 + inset, 207 + j, 'O')
        rect(g, 162 - inset, 206 + j, 163 - inset, 207 + j, 'O')
    rect(g, 151, 211, 161, 212, 'O')


def counter(g):
    rect(g, 0, TILES, COLS, COUNTER, 'S')                  # splashback
    rect(g, 0, TILES, COLS, TILES + 1, 'D')
    for course, y in enumerate(range(TILES + 1, COUNTER, 10)):
        rect(g, 0, y + 9, COLS, y + 10, 'D')
        for x in range(8 * (course % 2), COLS + 1, 16):
            rect(g, x, y, x + 1, y + 9, 'D')

    rect(g, 0, COUNTER, COLS, COUNTER + 1, 'O')            # slab
    rect(g, 0, COUNTER + 1, COLS, COUNTER + 6, 'L')
    rect(g, 0, COUNTER + 6, COLS, COUNTER + 9, 'M')
    rect(g, 0, COUNTER + 9, COLS, COUNTER + 10, 'O')
    rect(g, 0, COUNTER + 10, COLS, GROUND - 4, 'K')         # front
    rect(g, 0, GROUND - 4, COLS, GROUND, 'O')                # base line

    # Four panels with the gap on the centre line, so what is directly behind
    # the pet is plain dark wood -- the forest's trick for keeping it readable.
    # Each is a lit frame around a recessed centre rather than a filled
    # rectangle, which is what keeps them from reading as four doors.
    for x in (11, 53, 95, 137):
        box(g, x, 232, x + 32, 264, 'M')
        box(g, x + 4, 236, x + 28, 260, 'K')


def scene():
    g = blank('W')
    rect(g, 0, GROUND, COLS, ROWS, 'F')
    specks(g, 'G')            # the forest's ground specks, as board seams
    lamp(g, 27, 79)
    lamp(g, 155, 94)
    window(g)
    chalkboard(g)
    shelves(g)
    counter(g)
    machine(g)
    counter_props(g)
    return g


def main():
    write(OUT, build(scene(), LAYERS, BANDS, 'Cafe pet background',
                     'Flat fills on a 2-unit grid, in the forest background&apos;s '
                     'palette and bands: horizon y560, floor marks at its spacing, '
                     'pet zone clear.'), LAYERS)


if __name__ == '__main__':
    main()
