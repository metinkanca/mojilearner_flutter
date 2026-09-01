"""Builds the bird's accessories from its reference drawings, as drawn.

`art_src/bird_with_<id>.svg` is a finished mock-up: the chick at 1:1 on the
shared canvas, wearing the piece at the size and in the place it belongs. That
is the art, not a hint about it -- so this lifts the piece straight out rather
than deriving anything.

That replaces re-pixelising the cat's copy onto the chick's 7-unit cell grid,
which was the earlier approach and which loses the piece: resampled to a
handful of cells a top hat's brim and band collapse into the crown and it stops
reading as a top hat, and no scale avoids that, because the detail is finer than
the cells it is being resampled onto. A drawing already solves the problem the
resampler was there to solve -- how big should this be on a bird -- so there is
nothing left for it to do.

The one thing that does need fixing is the border. The drawings scale the
front-on art down, and its outline scales with it: what was 7 units around the
cat's piece is 3 to 5 around the chick's, against a chick still outlined at 7.
So the silhouette is grown outward to [WEIGHT] in the outline colour, under the
art. Grown rather than redrawn, so the outline INSIDE the piece -- the line
under a top hat's band, the gaps between a crown's points -- is left exactly as
drawn; stripping the outline colour and re-dilating loses all of it.

Growing the edge makes the piece a few units bigger than the drawing. That is
the cost of a matching border and it is the smaller error: a piece 4 units wide
of nobody's business, against a piece visibly outlined at half the weight of
everything it sits next to.

Re-run after editing a drawing. Never hand-edit the output.
"""

import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import acc_offset
import deseam
from deseam import VBH, VBW, VBX, VBY, emit, rasterise, trace

HERE = os.path.dirname(os.path.abspath(__file__))
SVG = os.path.join(HERE, '..', 'assets', 'svgs')
OUTLINE = '#1f2223'

# The outline every pet and every cell-grid accessory wears, in art units.
WEIGHT = 7

# Drawings whose piece is NOT lifted, and why.
#
# The bow tie is drawn finer than the 7-unit cell -- art_src/gen_acc.py builds
# it from `bowtie_new.svg` at a 4-unit outline, and it wears that weight on
# every pet. Lifting it here would put the cell grid's border on it and lose the
# knot the finer drawing exists for. Its bird copy is a job in gen_acc.py.
SKIP = {'bowtie'}


def read(path):
    with open(path, encoding='utf-8') as f:
        return f.read()


def worn(ref_svg, coat):
    """[(colour, subpaths)] for everything in the drawing that is not the chick.

    Matched by shape rather than by position in the file, since a drawing is
    free to order or re-id its layers however Inkscape left them.
    """
    out = []
    for (fill, subs), (_, ring) in zip(deseam.shapes(ref_svg),
                                       acc_offset.shapes(ref_svg)):
        if any(acc_offset.is_identity(acc_offset.solve(c, ring)) for c in coat):
            continue
        if not fill.startswith('#'):
            raise SystemExit('a path in the drawing is painted %r, not a flat '
                             'colour' % fill)
        out.append((fill, subs))
    return out


def grown(painted, by):
    """Every pixel within `by` of a painted one -- a square reach.

    Square for the same reason gen_acc.py's is: a square corner in the art has
    to come back as a square corner in the outline, and a round reach files
    every corner off.
    """
    span = range(-by, by + 1)
    return {(x + dx, y + dy) for x, y in painted for dy in span for dx in span}


def build(art, weight=WEIGHT):
    """The shipped asset for one lifted piece: the same art, border brought up.

    `art` is already on the canvas where it is worn, so nothing here moves or
    resizes it.
    """
    order = []
    for colour, _ in art:
        if colour not in order:
            order.append(colour)

    buf = [-1] * (VBW * VBH)
    for colour, subs in art:
        rasterise(subs, buf, order.index(colour))
    painted = {(x, y) for y in range(VBH) for x in range(VBW)
               if buf[y * VBW + x] >= 0}
    if not painted:
        raise SystemExit('the drawing paints nothing on the canvas')

    def path(pixels, colour):
        mask = [0] * (VBW * VBH)
        for x, y in pixels:
            if 0 <= x < VBW and 0 <= y < VBH:
                mask[y * VBW + x] = 1
        d = emit(trace(mask))
        return '<path fill="%s" d="%s"/>' % (colour, d) if d else None

    # How much border the drawing already has, measured where the piece is
    # widest so a sloped edge does not read as a thick one.
    have = border_of(buf, order, painted)
    body = []
    if weight > have:
        body.append(path(grown(painted, weight - have), OUTLINE))

    # Then the art itself, back to front, each colour over the union of
    # everything beneath it: abutting shapes tear into hairline seams under
    # flutter_svg, a single traced path has no internal edge to tear along.
    under = set()
    for colour in reversed(order):
        idx = order.index(colour)
        under |= {(x, y) for x, y in painted if buf[y * VBW + x] == idx}
        body.insert(1 if weight > have else 0, path(under, colour))

    head = ('<svg id="katman_1" xmlns="http://www.w3.org/2000/svg" version="1.1" '
            'viewBox="%d %d %d %d" shape-rendering="crispEdges">'
            % (VBX, VBY, VBW, VBH))
    return head + ''.join(p for p in body if p) + '</svg>\n', have


def border_of(buf, order, painted):
    """The drawing's own border weight, in whole art units.

    Read across the piece's widest row rather than around its edge: the run of
    outline before the first fill is the border there, and on the widest row
    that edge is closest to vertical, where the run is the weight rather than
    the weight stretched along a slope.
    """
    oi = order.index(OUTLINE) if OUTLINE in order else -1
    if oi < 0:
        return 0
    best = (0, 0)
    rows = {}
    for x, y in painted:
        rows.setdefault(y, []).append(x)
    for y, xs in rows.items():
        if len(xs) > best[0]:
            best = (len(xs), y)
    xs = sorted(rows[best[1]])
    n = 0
    for x in xs:
        if buf[best[1] * VBW + x] == oi:
            n += 1
        else:
            break
    return n


def main():
    coat = [ring for _, ring in acc_offset.shapes(read(os.path.join(SVG, 'bird.svg')))]
    names = sorted(f for f in os.listdir(HERE)
                   if re.fullmatch(r'bird_with_.+\.svg', f))
    for name in names:
        acc = re.fullmatch(r'bird_with_(.+)\.svg', name).group(1).replace('_', '')
        if acc in SKIP:
            continue
        art = worn(read(os.path.join(HERE, name)), coat)
        if not art:
            raise SystemExit('%s is the chick and nothing else' % name)
        svg, have = build(art)
        out = os.path.join(SVG, 'acc_%s_bird.svg' % acc)
        with open(out, 'w', encoding='utf-8') as f:
            f.write(svg)
        box = acc_offset.bbox([p for _, r in acc_offset.shapes(svg) for p in r])
        print('acc_%-22s %3.0fx%-3.0fu at %4.0f,%-4.0f  border %du -> %du  %5d bytes'
              % (acc + '_bird.svg', box[1] - box[0], box[3] - box[2],
                 box[0], box[2], have, max(have, WEIGHT), len(svg)))


if __name__ == '__main__':
    main()
