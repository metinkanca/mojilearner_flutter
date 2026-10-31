# Draws the shop's food as pixel art on the pets' own grid.
#
# Unlike the accessories, this art has no hand-drawn source to convert: the
# food is small enough to author directly as pixels, so the source IS the
# ASCII in FOODS below -- one character per cell, '.' for empty. That keeps
# the master in a form that can be read and edited in a diff, and makes the
# whole thing idempotent, which the accessory converters are not.
#
# What it does with that:
#   1. Dilate the whole shape by one cell (4-neighbourhood) and fill the ring
#      with the pets' outline colour. Doing it here rather than by hand is
#      what makes every item's border exactly the weight the cat's is, and it
#      is why the art below is drawn border-less. A one-cell gap left inside a
#      shape becomes outline too -- that is how the apple gets its crease, the
#      donut its hole, and the espresso cup its handle hole.
#   2. Trace each colour out as ONE path. Abutting rects tear into hairline
#      seams under flutter_svg, which antialiases each rect independently; a
#      single traced path has no internal edges to tear along.
#   3. Crop the viewBox to the content, so a wide item and a tall one both
#      fill the box the UI gives them.
#
# Usage:  python art_src/gen_food.py assets/svgs

import sys
from pathlib import Path

CELL = 7  # the pets' pixel size, so food sits at the same resolution as the cat
OUTLINE = '#1f2223'  # the pets' outline colour


def trace(cells, ox, oy):
    """The union boundary of a cell set, as SVG path data.

    Each cell contributes only the sides whose neighbour is outside the set,
    as directed edges (top L->R, right T->B, bottom R->L, left B->T). Chaining
    them yields clockwise outer loops and counter-clockwise holes, so the
    default nonzero winding cuts the holes out for free.
    """
    # Sorted, so the decomposition into loops -- and therefore the bytes of
    # the file -- is the same on every run.
    edges = {}
    for x, y in sorted(cells):
        if (x, y - 1) not in cells:
            edges.setdefault((x, y), []).append((x + 1, y))
        if (x + 1, y) not in cells:
            edges.setdefault((x + 1, y), []).append((x + 1, y + 1))
        if (x, y + 1) not in cells:
            edges.setdefault((x + 1, y + 1), []).append((x, y + 1))
        if (x - 1, y) not in cells:
            edges.setdefault((x, y + 1), []).append((x, y))

    d = ''
    while edges:
        start = min(edges)
        cur = start
        loop = [cur]
        while True:
            outs = edges.get(cur)
            if not outs:
                break
            nxt = outs.pop()
            if not outs:
                del edges[cur]
            cur = nxt
            if cur == loop[0]:
                break
            loop.append(cur)

        # Drop collinear midpoints, so the path is as short as the shape allows.
        pts = []
        for i, b in enumerate(loop):
            a = loop[i - 1]
            c = loop[(i + 1) % len(loop)]
            if (a[0] == b[0] == c[0]) or (a[1] == b[1] == c[1]):
                continue
            pts.append(b)
        if len(pts) < 3:
            continue

        d += ''.join(
            f"{'M' if i == 0 else 'L'}{(x - ox) * CELL} {(y - oy) * CELL}"
            for i, (x, y) in enumerate(pts)
        ) + 'Z'
    return d


def build(rows, palette):
    h = len(rows)
    w = max(len(r) for r in rows)

    def at(x, y):
        if 0 <= y < h and 0 <= x < len(rows[y]) and rows[y][x] != '.':
            return rows[y][x]
        return None

    by_colour = {}  # hex -> cells, in first-drawn order
    outline = set()
    for y in range(-1, h + 1):
        for x in range(-1, w + 1):
            ch = at(x, y)
            if ch:
                by_colour.setdefault(palette[ch], set()).add((x, y))
            elif at(x - 1, y) or at(x + 1, y) or at(x, y - 1) or at(x, y + 1):
                outline.add((x, y))

    everything = set(outline)
    for cells in by_colour.values():
        everything |= cells
    ox = min(x for x, _ in everything)
    oy = min(y for _, y in everything)
    vw = (max(x for x, _ in everything) - ox + 1) * CELL
    vh = (max(y for _, y in everything) - oy + 1) * CELL

    # Outline first, so the fills sit on top of it the way the pets' do.
    body = f'<path fill="{OUTLINE}" d="{trace(outline, ox, oy)}"/>'
    for hex_colour, cells in by_colour.items():
        body += f'<path fill="{hex_colour}" d="{trace(cells, ox, oy)}"/>'

    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {vw} {vh}" '
        f'shape-rendering="crispEdges">{body}</svg>\n'
    )


FOODS = {
    # A red apple. Three flat colours and no shading -- the gaps either side of
    # the stem become outline under the dilation, and that crease is the whole
    # silhouette. The base is flat: a notched bottom put a second piece of
    # detail on a shape that only wants one.
    'apple': (
        {'r': '#d94452', 'g': '#6abe30', 's': '#7a4a2b'},
        [
            '.gg.ss....',
            'ggg.ss....',
            '.rr.ss.rr.',
            'rrrrrrrrrr',
            'rrrrrrrrrr',
            'rrrrrrrrrr',
            'rrrrrrrrrr',
            '.rrrrrrrr.',
            '.rrrrrrrr.',
        ],
    ),

    # An iced donut. This replaced a croissant, which never read as one: a
    # crescent plus segment lines is more information than 14 cells and a
    # one-cell outline can carry, and it kept coming out as a bread roll.
    #
    # The hole is the whole silhouette, and it has to be drawn generously --
    # the outline dilation eats a cell all the way around it, so this 6x5
    # empty patch is what leaves a 4x3 hole you can actually see.
    #
    # The one row where the icing dips into the dough is the whole difference
    # between an iced donut and a ball painted two colours.
    'donut': (
        {'p': '#f08cb4', 'd': '#c98a4b', 'X': '#fbf236'},
        [
            '....pppppp....',
            '..ppXppppXpp..',
            '.pppppppppppp.',
            'pXppppppppppXp',
            'pppp......pppp',
            'pppp......pppp',
            'dppd......dppd',
            'dddd......dddd',
            'dddd......dddd',
            'dddddddddddddd',
            '.dddddddddddd.',
            '..dddddddddd..',
            '....dddddd....',
        ],
    ),

    # A slice, point down, narrowing one cell a side every other row.
    'pizza': (
        {'d': '#b9762f', 'c': '#e0a45a', 'e': '#f7c95c', 'p': '#cc3344'},
        [
            'dddddddddddd',
            'cccccccccccc',
            '.eeeeeeeeee.',
            '.eppeeeeppe.',
            '..ppeeeepp..',
            '..eeeeeeee..',
            '...eeeeee...',
            '...eeppee...',
            '....eppe....',
            '....eeee....',
            '.....ee.....',
            '.....ee.....',
        ],
    ),

    # Salmon nigiri, banded with nori. There is no outline between the fish and
    # the rice: two flat colours meeting is how the pets' own internal
    # boundaries are drawn.
    'sushi': (
        {'s': '#ef7a4a', 'S': '#ffb489', 'w': '#f5efe0',
         'W': '#ded5c0', 'n': '#38493c'},
        [
            '...ssnnnss...',
            '.ssssnnnssss.',
            '.sSsSnnnSsSs.',
            '.ssssnnnssss.',
            '..wwwnnnwww..',
            '.wwwwnnnwwww.',
            '.wwwwnnnWWWW.',
            '..wwwnnnWWW..',
        ],
    ),

    # A straight-sided cup, no saucer and no crema: two flat colours and a
    # handle. The single empty cell inside the handle becomes outline, which
    # is the hole.
    'coffee': (
        {'c': '#f4f0e6', 'b': '#4a2c1a'},
        [
            '.cccccccc...',
            '.cbbbbbbc...',
            '.cbbbbbbccc.',
            '.cccccccc.c.',
            '.cccccccc.c.',
            '.cccccccccc.',
            '.cccccccc...',
        ],
    ),

    # A capsule, in exactly two flat colours: the halves are the whole design,
    # so shading either of them only muddies the one thing it has to say.
    'medicine': (
        {'p': '#e04c5a', 'w': '#f2f2f2'},
        [
            '..pppppwwwww..',
            '.ppppppwwwwww.',
            'pppppppwwwwwww',
            'pppppppwwwwwww',
            '.ppppppwwwwww.',
            '..pppppwwwww..',
        ],
    ),
}


def main():
    out = Path(sys.argv[1] if len(sys.argv) > 1 else 'assets/svgs')
    for food_id, (palette, rows) in FOODS.items():
        path = out / f'food_{food_id}.svg'
        path.write_text(build(rows, palette), encoding='utf-8')
        print(f'{path}  {path.stat().st_size}b')


if __name__ == '__main__':
    main()
