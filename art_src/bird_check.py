"""Compare each shipped bird accessory with the box its reference drawing gave it.

The drawings are the specification -- this says how close the generated art
lands. A hat is re-pixelised onto whole 7-unit cells and re-outlined at a full
cell, while the drawing scaled the front-on art (outline and all) by a fraction,
so the two never match to the unit; what matters is that the piece sits in the
same place at about the same size. Anything more than a cell out is a seating
mistake, not rounding.

    python art_src/bird_check.py
"""

import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import acc_offset

HERE = os.path.dirname(os.path.abspath(__file__))
SVG = os.path.join(HERE, '..', 'assets', 'svgs')

# accessory id -> (reference stem, the art the pet actually wears)
WORN = {
    'beanie': ('bird_with_beanie', 'acc_beanie_bird'),
    'cap': ('bird_with_cap', 'acc_cap_bird'),
    'cowboyhat': ('bird_with_cowboy_hat', 'acc_cowboyhat_bird'),
    'crown': ('bird_with_crown', 'acc_crown_bird'),
    'flowercrown': ('bird_with_flower_crown', 'acc_flowercrown_bird'),
    'headphones': ('bird_with_headphones', 'acc_headphones_bird'),
    'mortarboard': ('bird_with_mortarboard', 'acc_mortarboard_bird'),
    'partyhat': ('bird_with_party_hat', 'acc_partyhat_bird'),
    'tophat': ('bird_with_tophat', 'acc_tophat_bird'),
    'wizardhat': ('bird_with_wizard_hat', 'acc_wizardhat_bird'),
    # Neckwear, from the same drawings.
    'bowtie': ('bird_with_bowtie', 'acc_bowtie_bird'),
    'collar': ('bird_with_collar', 'acc_collar_bird'),
    'medal': ('bird_with_medal', 'acc_medal_bird'),
}

# The bird wears every piece above exactly as drawn, so nothing here is moved
# by an offset. Kept as a hook for a piece that ever is.
PLACED = {}


def read(path):
    with open(path, encoding='utf-8') as f:
        return f.read()


def drawn_box(ref_svg, bird):
    """The box the drawing gives the accessory, in canvas units."""
    comp = acc_offset.shapes(ref_svg)
    coat = [ring for _, ring in acc_offset.shapes(bird)]
    # Tested a ring at a time: a ring either is one of the chick's or is not.
    pts = []
    for _, ring in comp:
        if any(acc_offset.is_identity(acc_offset.solve(c, ring)) for c in coat):
            continue
        pts += list(ring)
    return acc_offset.bbox(pts)


def main():
    bird = read(os.path.join(SVG, 'bird.svg'))
    worst = 0.0
    for acc, (ref, asset) in WORN.items():
        want = drawn_box(read(os.path.join(HERE, ref + '.svg')), bird)
        art = acc_offset.shapes(read(os.path.join(SVG, asset + '.svg')))
        dx, dy = PLACED.get(acc, (0, 0))
        got = acc_offset.bbox([(x + dx, y + dy) for _, r in art for x, y in r])
        off = max(abs(a - b) for a, b in zip(want, got))
        worst = max(worst, off)
        print('%-12s wants %5.1fx%-5.1f at %6.1f,%-6.1f  '
              'gets %5.1fx%-5.1f at %6.1f,%-6.1f  worst edge %+5.1fu%s'
              % (acc, want[1] - want[0], want[3] - want[2], want[0], want[2],
                 got[1] - got[0], got[3] - got[2], got[0], got[2], off,
                 '  <<' if off > 7 else ''))
    print('\nlargest edge error: %.1fu (%.1f cells)' % (worst, worst / 7))


if __name__ == '__main__':
    main()
