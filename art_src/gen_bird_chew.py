"""Builds the chick's open-beak pose, `assets/svgs/bird_base_open.svg`.

The cat and the dog chew by swapping a mouth layer laid over the muzzle. The
chick has no muzzle -- its beak is part of the head silhouette -- so there is no
layer to swap, and an overlay cannot do the job either: opening a beak means
taking pixels away from where they were, and a layer painted on top can only
add. So the whole coat gets a second pose, and the sprite swaps that instead.

The beak is a stepped wedge, three bands wide:

    x 144..150   y  92..117      at the face
    x 151..159   y  96..113
    x 160..170   y  98..107      at the tip

It opens by hinging at the face: the lower half of each band drops, by nothing
at the face and by [GAPE] at the tip. Stepping the drop by band rather than per
column is what keeps it in the art's own idiom -- a per-column drop is a
diagonal, and this art has no diagonals anywhere.

What opens up between the halves is nothing at all -- no fill and no outline.
The chick is drawn side-on, so an open beak is a hole you see the background
through, and the two mandibles face each other across it unbordered.

That is deliberate, and it is the only thing that works at this size. The tip of
the beak is ten units deep, which is a pixel and a half of the chick's own art:
put any border on both sides of the gap and they meet in the middle, and the
beak opens onto solid black. Widening the gape until it outruns two borders
instead swings the jaw clear of the chin, which reads as a broken beak rather
than an open one. So the gap is left bare, and the beak is bordered where it
meets the background and nowhere else.

For the same reason the jaw's own new edge wears [JAW] rather than the seven the
chick is outlined at: a mandible five units deep inside a seven-unit border is a
black bar with a hint of colour trapped in it. Everything that was already drawn
keeps the weight it was traced with, so the head never changes between the two
poses.

The drawn outline is kept everywhere and outline is only ADDED, around the jaw
where it swung out past the closed silhouette. Rebuilding it instead -- even
only near the beak -- redraws the head's edge as a dilation of its fill, and the
chick's outline is not a dilation of anything: it comes back a few units thinner
than it was traced, which the eye reads as the head flickering every time the
beak opens.

Re-run after `gen_bird.py`. Never hand-edit the output.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import acc_offset
import deseam
from deseam import VBH, VBW, VBX, VBY, emit, rasterise, shapes, trace

HERE = os.path.dirname(os.path.abspath(__file__))
SVG = os.path.join(HERE, '..', 'assets', 'svgs')

OUTLINE, MAIN, SHADE = '#1f2223', '#959379', '#606659'

# How far the tip of the lower mandible drops, in art units. Less and the gap
# does not read at the size the chick is drawn; more and the jaw swings clear of
# the chin and the chick looks unhinged rather than hungry.
GAPE = 11

# The border the jaw's new edge wears where it meets the background. Thinner
# than the chick's own, for the reason in the module docstring.
JAW = 4


def read(path):
    with open(path, encoding='utf-8') as f:
        return f.read()


def raster(svg):
    """(colour index per canvas pixel, colours in paint order)."""
    shp = shapes(svg)
    fills = [f for f, _ in shp]
    order = sorted(set(fills), key=lambda f: (deseam.RANK.get(f, 5), fills.index(f)))
    buf = [-1] * (VBW * VBH)
    for f, subs in shp:
        rasterise(subs, buf, order.index(f))
    return buf, order


def component(pixels, seed_box):
    """The 4-connected run of `pixels` that starts inside `seed_box`.

    The chick's wing is painted the same colour as its beak, so picking the
    beak by colour alone picks up the wing too.
    """
    x0, y0, x1, y1 = seed_box
    seeds = [p for p in pixels if x0 <= p[0] <= x1 and y0 <= p[1] <= y1]
    if not seeds:
        raise SystemExit('no beak-coloured pixels where the beak should be')
    seen, stack = set(), [seeds[0]]
    while stack:
        p = stack.pop()
        if p in seen or p not in pixels:
            continue
        seen.add(p)
        x, y = p
        stack += [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]
    return seen


def bands(beak):
    """The beak's steps, left to right: [(x0, x1, top, bottom), ...].

    A step is a run of columns the wedge is the same height through, which is
    the unit the art itself is drawn in.
    """
    cols = {}
    for x, y in beak:
        lo, hi = cols.get(x, (y, y))
        cols[x] = (min(lo, y), max(hi, y))
    out = []
    for x in sorted(cols):
        top, bot = cols[x]
        if out and out[-1][2] == top and out[-1][3] == bot and out[-1][1] == x - 1:
            out[-1][1] = x
        else:
            out.append([x, x, top, bot])
    return [tuple(b) for b in out]


def grown(pixels, by):
    span = range(-by, by + 1)
    return {(x + dx, y + dy) for x, y in pixels for dy in span for dx in span}


def build():
    buf, order = raster(read(os.path.join(SVG, 'bird_base.svg')))
    at = lambda p: buf[p[1] * VBW + p[0]]
    painted = {(x, y) for y in range(VBH) for x in range(VBW) if buf[y * VBW + x] >= 0}
    art = {p: order[at(p)] for p in painted}

    shade = {p for p in painted if art[p] == SHADE}
    # Canvas -> buffer, for the box the beak is known to sit in.
    beak = component(shade, (150 - VBX, 95 - VBY, 168 - VBX, 115 - VBY))
    steps = bands(beak)
    if len(steps) < 2:
        raise SystemExit('the beak reads as one step, so it has no hinge to open on')

    moved, gap, lifted = {}, set(), set()
    for i, (x0, x1, top, bot) in enumerate(steps):
        drop = round(GAPE * i / (len(steps) - 1))
        # Each step splits at its own waist, not the whole wedge's: the tip is
        # the shallowest part, and cutting it on the wedge's waist leaves it a
        # sliver of a lower mandible against a deep upper one.
        waist = (top + bot + 1) // 2
        for x, y in beak:
            if not x0 <= x <= x1 or y < waist:
                continue
            lifted.add((x, y))
            moved[(x, y + drop)] = SHADE
            # What opens up behind it, down to where it now starts.
            for gy in range(y, y + drop):
                gap.add((x, gy))

    # The new fill: the coat as drawn, with the lower mandible where it swung
    # to. The gap it left behind is painted by nobody.
    fill = {p: c for p, c in art.items() if c != OUTLINE}
    for p in lifted:
        del fill[p]
    fill.update(moved)
    gap -= set(moved)

    # Outline: everything drawn, plus a border around the jaw where it now
    # hangs past the closed silhouette. Limited to the jaw's reach so the rest
    # of the chick is left exactly as traced.
    near = grown(set(moved), JAW)
    added = {p for p in grown(set(fill), JAW) - set(fill) if p in near}
    outline = ({p for p in painted if art[p] == OUTLINE} | added) - gap

    out = dict.fromkeys(outline, OUTLINE)
    out.update(fill)

    body = [path({p for p in out if out[p] == OUTLINE}, OUTLINE)]
    under = set()
    for colour in (SHADE, MAIN):
        under |= {p for p in out if out[p] == colour}
        body.insert(1, path(under, colour))

    head = ('<svg id="katman_1" xmlns="http://www.w3.org/2000/svg" version="1.1" '
            'viewBox="%d %d %d %d" shape-rendering="crispEdges">'
            % (VBX, VBY, VBW, VBH))
    return head + ''.join(p for p in body if p) + '</svg>\n', steps


def path(pixels, colour):
    mask = [0] * (VBW * VBH)
    for x, y in pixels:
        if 0 <= x < VBW and 0 <= y < VBH:
            mask[y * VBW + x] = 1
    d = emit(trace(mask))
    return '<path fill="%s" d="%s"/>' % (colour, d) if d else None


if __name__ == '__main__':
    svg, steps = build()
    out = os.path.join(SVG, 'bird_base_open.svg')
    with open(out, 'w', encoding='utf-8') as f:
        f.write(svg)
    box = acc_offset.bbox([p for _, r in acc_offset.shapes(svg) for p in r])
    print('bird_base_open.svg  %d beak steps, hinged at the face, gape %du at '
          'the tip' % (len(steps), GAPE))
    print('                    art %.0fx%-.0fu at %.0f,%.0f   %d bytes'
          % (box[1] - box[0], box[3] - box[2], box[0], box[2], len(svg)))
