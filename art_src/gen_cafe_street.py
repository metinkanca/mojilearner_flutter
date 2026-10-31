# -*- coding: utf-8 -*-
"""Draws the cafe seen from the street -- `cafe-clean-tones.svg` from outside.

    python art_src/gen_cafe_street.py

`lib_scene` holds the grammar the forest sets and this follows; what is here
is the shopfront. It is laid out on the forest's lines: a big empty band up
top with two small things in it, every landmark in a mid band, and a plain
ground below the horizon at y560.

This one adds no colours at all. Every tone is already in the forest or in the
cafe interior, which is what makes the pair read as two views of one place:
the sky, the clouds and the paving are the forest's own, unchanged, down to
the ground specks being its exact rectangles; the render on the shopfront is
the interior's wall, so the building is the same colour inside and out; the
counter's three woods build the cornice, the frames and the stall riser; and
the terracotta that was the espresso machine is the awning and the pots.

Two devices are borrowed from the reference rather than invented. The clouds
sit in its cloud positions, so the empty band is filled to the same weight.
And the neighbouring buildings are painted in its distant-tree tones, which is
what a horizon is for: something cool and flat behind the landmark, to stop
the landmark from floating.

The glass is deliberately dark. A shopfront in daylight reads as reflection,
not as a lit room, and a dark pane is also what keeps the pet -- who stands
centre, right in front of the display window -- legible against it.
"""
from lib_scene import (COLS, GROUND, ROWS, blank, blob, box, build, dome,
                       outline, rect, specks, stamp, write)

OUT = 'cafe-street-clean-tones.svg'

# Where the front is divided.
SHOP = (20, 162)       # the shop's own frontage, left and right
CORNICE = 118          # the top of the building
AWNING = (152, 176)    # the awning, valance included
RISER = 248            # where the windows stop and the stall riser starts
PLINTH = 270

# Painted back to front, one path each. Sky and paving are emitted as whole
# bands; everything else is its own region.
LAYERS = [
    ('sky',            'Y', '#8dcdf3'),
    ('paving',         'F', '#e9bc70'),
    ('neighbours',     'S', '#609fa6'),
    ('glass',          'D', '#347d83'),
    ('leaves',         'P', '#488b50'),
    ('leaf-shadows',   'Q', '#286147'),
    ('paving-joints',  'G', '#ba8350'),
    ('light-wood',     'L', '#ba8350'),
    ('mid-wood',       'M', '#93643d'),
    ('dark-wood',      'K', '#6b4326'),
    ('render',         'W', '#b9d7d4'),
    ('terracotta',     'R', '#c2604d'),
    ('paint',          'C', '#fff4df'),
    ('outlines',       'O', '#2f1d14'),
]

BANDS = {'Y': (0, GROUND), 'F': (GROUND, ROWS)}

# The forest's two clouds, row by row, at the forest's own x and y.
CLOUD_L = (71, [(25, 30), (24, 31), (23, 32), (22, 32),
                (20, 34), (19, 35), (18, 36), (19, 35)])
CLOUD_R = (86, [(155, 158), (154, 159), (153, 160), (152, 161),
                (150, 163), (149, 163), (148, 164), (149, 163)])

# The sign says nothing, for the reason the interior's menu board says
# nothing: the app ships around thirty target languages.
EMBLEM = [
    '....C...C...C.....',
    '...C...C...C......',
    '....C...C...C.....',
    '..................',
    '.CCCCCCCCCCCC.....',
    '.C..........C.CCC.',
    '.C..........CCC.C.',
    '.C..........C...C.',
    '.C..........CCC.C.',
    '.C..........C.CCC.',
    '..C........C......',
    '...CCCCCCCC.......',
    '..................',
    'CCCCCCCCCCCCCCCC..',
]


def sky(g):
    for y0, spans in (CLOUD_L, CLOUD_R):
        blob(g, y0, spans, 'C')


def neighbours(g):
    """Flat cool buildings either side: the street's version of a treeline."""
    for x0, x1, eaves in ((0, SHOP[0], 136), (SHOP[1], COLS, 128)):
        rect(g, x0, eaves, x1, GROUND, 'S')
        rect(g, x0, eaves, x1, eaves + 5, 'D')             # parapet coping
        for y in (eaves + 16, eaves + 56):                 # windows
            rect(g, x0 + 4, y, x1 - 4, y + 20, 'D')
        rect(g, x0, PLINTH, x1, GROUND, 'D')
    rect(g, 5, 124, 14, 138, 'S')                          # one chimney
    rect(g, 4, 124, 15, 128, 'D')


def front(g):
    """Cornice, fascia and awning: the three bands that say `shop`."""
    x0, x1 = SHOP
    rect(g, x0, CORNICE, x1, GROUND, 'W')                  # rendered wall

    rect(g, 16, CORNICE - 1, 166, 132, 'O')                # cornice
    rect(g, 17, CORNICE, 165, CORNICE + 2, 'L')
    rect(g, 17, CORNICE + 2, 165, 126, 'M')
    rect(g, 17, 126, 165, 131, 'K')

    rect(g, x0, 132, x1, 152, 'K')                         # fascia
    rect(g, x0, 149, x1, 152, 'M')
    stamp(g, 82, 134, EMBLEM, {'C': 'C'})
    for a, b in ((32, 76), (106, 150)):                    # and its two rules
        rect(g, a, 139, b, 143, 'C')

    top, foot = AWNING                                     # awning, in stripes
    for i in range(12):
        a = 19 + i * 12
        rect(g, a, top, a + 12, foot - 6, 'R' if i % 2 == 0 else 'C')
        for j, inset in enumerate((0, 0, 1, 2, 3, 4)):     # scalloped valance
            rect(g, a + inset, foot - 6 + j, a + 12 - inset, foot - 5 + j,
                 'R' if i % 2 == 0 else 'C')
    outline(g, 'RC', 16, top - 2, 166, foot + 2)


def reflections(g, x0, y0, x1, y1, starts):
    """Stair-stepped diagonals on a pane: what glass does in daylight."""
    for start, width in starts:
        for j, y in enumerate(range(y0, y1)):
            rect(g, min(start + j, x1), y, min(start + j + width, x1), y + 1, 'S')


def windows(g):
    box(g, 30, 181, 100, RISER, 'M')                       # display window
    box(g, 33, 184, 97, RISER - 3, 'D')
    reflections(g, 34, 185, 96, RISER - 4, ((37, 7), (52, 4)))
    rect(g, 34, 195, 96, 200, 'O')                         # transom bar,
    rect(g, 34, 196, 96, 199, 'M')                         # edged on the glass
    for x in (48, 74):                                     # two lamps inside
        rect(g, x + 3, 199, x + 5, 205, 'O')
        dome(g, x + 4, 205, [3, 4, 5], 'C')
    rect(g, 34, 232, 96, RISER - 4, 'K')                   # counter, in shadow
    rect(g, 26, 244, 104, 250, 'L')                        # sill

    box(g, 116, 178, 146, 274, 'M')                        # door
    box(g, 120, 182, 142, 228, 'D')
    reflections(g, 121, 183, 141, 227, ((124, 5),))
    box(g, 124, 187, 138, 196, 'C')                        # a sign in the glass
    rect(g, 126, 190, 136, 193, 'K')
    rect(g, 119, 228, 143, 236, 'M')                       # mid rail and handle
    rect(g, 137, 230, 140, 241, 'O')
    # The lower panel is the lit wood, not the dark: the stall riser either
    # side of it is dark, and two darks meeting lose the door's own edge.
    box(g, 120, 238, 142, 268, 'M')
    box(g, 123, 241, 139, 265, 'K')

    rect(g, 154, 186, 156, 193, 'O')                       # wall lamp
    dome(g, 155, 193, [3, 4, 5], 'M')
    rect(g, 150, 196, 161, 198, 'C')


def riser(g):
    for x0, x1 in ((SHOP[0], 116), (146, SHOP[1])):
        rect(g, x0, RISER, x1, PLINTH, 'K')
    for x in (26, 56, 86, 149):
        box(g, x, 253, x + (10 if x == 149 else 26), 265, 'M')
    rect(g, 16, PLINTH, 166, GROUND, 'K')                  # plinth
    rect(g, 16, PLINTH, 166, PLINTH + 2, 'O')
    rect(g, 0, GROUND - 2, COLS, GROUND, 'O')              # contact line
    box(g, 110, 272, 152, 284, 'L')                        # the step, projecting


def a_board(g):
    """The pavement sign, at the edge: the exterior's answer to the menu board."""
    box(g, 4, 236, 26, 268, 'M')
    box(g, 7, 239, 23, 265, 'Q')
    rect(g, 10, 243, 20, 246, 'C')
    for y, w in ((251, 8), (257, 11)):
        rect(g, 10, y, 10 + w, y + 3, 'C')
    for j, (a, b) in enumerate(((6, 9), (5, 8), (4, 7))):  # splayed legs
        rect(g, a, 266 + j * 6, b, 272 + j * 6, 'M')
        rect(g, 30 - b, 266 + j * 6, 30 - a, 272 + j * 6, 'M')
    outline(g, 'M', 2, 264, 28, 286)


def bay_tree(g):
    """A clipped tree in a pot, the other edge. The pet walks between them."""
    dome(g, 163, 212, [5, 8, 10, 11, 12, 13, 13, 14, 14, 14, 15, 15,
                       15, 15, 14, 14, 14, 13, 13, 12, 11, 10, 8, 5], 'P')
    for x, y, h in ((152, 222, 8), (170, 228, 7), (157, 230, 5)):
        rect(g, x, y, x + 6, y + h, 'Q')                   # shading in the mass
    box(g, 160, 234, 166, 262, 'M')                        # trunk
    box(g, 152, 258, 174, 264, 'R')                        # pot: rim,
    for j, inset in enumerate((0, 0, 0, 0, 1, 1, 1, 1,
                               2, 2, 2, 2, 3, 3, 3)):      # then a gentle body
        rect(g, 154 + inset, 264 + j, 172 - inset, 265 + j, 'R')
        rect(g, 153 + inset, 264 + j, 154 + inset, 265 + j, 'O')
        rect(g, 172 - inset, 264 + j, 173 - inset, 265 + j, 'O')
    rect(g, 156, 279, 170, 280, 'O')


def edges(g):
    """The outlines that objects drawn as flat masses do not get for free.

    Everything the shopfront is built from is boxed, so it carries its own
    edge already. Two things did not: the neighbouring buildings and the
    clouds. Both are inherited conventions rather than oversights -- the
    forest leaves its distant trees and its clouds unoutlined, which is how it
    pushes them back -- but on a street that makes a neighbour read as a flat
    area of colour beside a fully drawn shopfront, so here every object is
    edged the way the pets are.

    Run last, and only over the strips the neighbours occupy: `S` and `D` are
    the shopfront's own reflections and glass everywhere else, and dilating
    across the whole canvas would edge those too.
    """
    for x0, x1 in ((0, SHOP[0] + 2), (SHOP[1] - 2, COLS)):
        outline(g, 'D', x0, 120, x1, GROUND)               # copings, windows
        outline(g, 'SD', x0, 120, x1, GROUND)              # then the mass
    outline(g, 'C', 0, 0, COLS, CORNICE - 2)               # the clouds


def scene():
    g = blank('Y')
    rect(g, 0, GROUND, COLS, ROWS, 'F')
    specks(g, 'G')            # the forest's ground specks, as paving joints
    sky(g)
    neighbours(g)
    front(g)
    windows(g)
    riser(g)
    a_board(g)
    bay_tree(g)
    edges(g)
    return g


def main():
    write(OUT, build(scene(), LAYERS, BANDS, 'Cafe street pet background',
                     'Flat fills on a 2-unit grid, in the forest background&apos;s '
                     'palette and bands: horizon y560, paving marks at its '
                     'spacing, pet zone clear.'), LAYERS)


if __name__ == '__main__':
    main()
