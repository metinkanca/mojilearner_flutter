# Puts the pets' outline around the border-less art the user draws.
#
# The sources (`art_src/<id>_new.svg`) are flat-colour shapes with no outline,
# drawn at whatever size suited the drawing. Everything this does is scale one
# to the size it is meant to be worn at, seat it, and draw the outline around
# it. The shapes themselves are left alone -- the silhouette that comes out is
# the silhouette that went in.
#
# It deliberately does NOT re-pixelise onto the pets' 7-unit cell grid. Doing
# that is how you make a piece that matches the pets' resolution and no longer
# looks like the thing that was drawn: a mustache's curled tips flatten into a
# bar, a bow tie's knot disappears. The art wins that argument. What makes a
# piece belong to the set here is the outline -- same colour, same weight --
# not its cell size.
#
# Steps:
#   1. Bake element transforms and average any gradient down to one flat
#      colour, because a gradient samples into a ramp of near-identical shades
#      and the pets have flat colours.
#   2. Scale the art about its own bounding box and seat it on the canvas.
#   3. Rasterise at one art unit, dilate the silhouette by the outline weight,
#      and trace that as the outline.
#   4. Trace each colour back out as ONE path, painted over the union of
#      everything beneath it. Abutting rects tear into hairline seams under
#      flutter_svg; a single traced path has no internal edges to tear along.
#
# Neither the size nor the seating is in the source, so both are arguments: the
# size comes from a reference drawing (art_src/acc_offset.py reads it out of a
# `<pet>_with_<accessory>.svg`), and the seating is where the piece being
# replaced already hung on the cat.
#
# Sources live here rather than in assets/svgs because pubspec globs that
# folder -- a source left there ships.
#
# Re-run after any edit to a source. Never hand-edit the output.
import os
import re
import sys
from urllib.parse import unquote

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import acc_offset
from deseam import VBH, VBW, VBX, VBY, emit, rasterise, trace

HERE = os.path.dirname(os.path.abspath(__file__))
SVG = os.path.join(HERE, '..', 'assets', 'svgs')
OUTLINE = '#1f2223'

# The outline, in art units. The pets and the cell-grid accessories wear 7,
# which is one of THEIR pixels. Art drawn finer than that has pixels of its own
# a couple of units across, and 7 units of border around it reads as a black
# blob with some colour trapped inside -- so these wear 4. Matching the set
# means looking like it belongs to the set, not sharing a number with it.
WEIGHT = 4


def flat_fills(svg):
    """Gradient id -> the one flat colour it collapses to."""
    out = {}
    for m in re.finditer(r'<linearGradient\b[^>]*id="([^"]+)"(.*?)</linearGradient>',
                         svg, re.S):
        stops = re.findall(r'stop-color="(#[0-9a-fA-F]{6})"', m.group(2))
        if not stops:
            continue
        rgb = [sum(int(s[i:i + 2], 16) for s in stops) // len(stops)
               for i in (1, 3, 5)]
        out[m.group(1).lower()] = '#%02x%02x%02x' % tuple(rgb)
    return out


def source_shapes(svg):
    """[(colour, ring)] for a hand-drawn source, transforms baked, fills flat."""
    gradients = flat_fills(svg)
    out = []
    for fill, pts in acc_offset.shapes(svg):
        if fill.startswith('#'):
            colour = fill
        else:
            ref = re.search(r'url\(#([^)]+)\)', fill)
            # Inkscape percent-encodes a non-ASCII id in the url() but not on
            # the gradient itself, so the two only meet after decoding -- and
            # a source read back in the wrong encoding mangles one side of that
            # comparison, hence the fallback when there is only one to mean.
            colour = gradients.get(unquote(ref.group(1))) if ref else None
            if not colour and len(gradients) == 1:
                colour = next(iter(gradients.values()))
            if not colour:
                raise SystemExit(f'cannot resolve fill {fill!r}')
        out.append((colour, list(pts)))
    return out


def dilate(pixels, weight):
    """Every pixel within `weight` of one that is painted -- a square reach.

    Square, so a square corner in the art comes back as a square corner in the
    outline. A round reach keeps the weight exactly perpendicular everywhere,
    which sounds better and looks worse: it files every corner off, and a bow
    tie with rounded shoulders stops reading as a bow tie. This is also what the
    rest of the set has, whose outline is one cell dilated on a cell grid.

    The border being too heavy is a matter of [WEIGHT], not of the shape of the
    reach -- do not "fix" heaviness by rounding it off again.
    """
    span = range(-weight, weight + 1)
    return {(x + dx, y + dy) for x, y in pixels for dy in span for dx in span}


def convert(svg, scale, left, top, weight=WEIGHT):
    """The shipped art for a source: the same shapes, scaled, seated, outlined.

    `scale` is applied about the art's own bounding box. [left, top] is where
    the outlined piece's top-left corner goes, in canvas art units -- the
    outline included, since that is the edge you can see and line up against.
    """
    shp = source_shapes(svg)
    x0, x1, y0, y1 = acc_offset.bbox([p for _, ring in shp for p in ring])

    # Seat it: the art's top-left goes one outline-width inside the corner the
    # caller asked for.
    ox, oy = left + weight, top + weight

    def put(p):
        return (ox + (p[0] - x0) * scale, oy + (p[1] - y0) * scale)

    order = []
    for colour, _ in shp:
        if colour not in order:
            order.append(colour)

    buf = [-1] * (VBW * VBH)
    for colour, ring in shp:
        rasterise([[put(p) for p in ring]], buf, order.index(colour))

    painted = {(x, y) for y in range(VBH) for x in range(VBW)
               if buf[y * VBW + x] >= 0}
    if not painted:
        raise SystemExit('the source paints nothing on the canvas')

    def path(pixels, colour):
        mask = [0] * (VBW * VBH)
        for x, y in pixels:
            if 0 <= x < VBW and 0 <= y < VBH:
                mask[y * VBW + x] = 1
        d = emit(trace(mask))
        return '<path fill="%s" d="%s"/>' % (colour, d) if d else None

    # Painted back to front, each colour over the union of everything under it,
    # so the joins between colours overlap instead of abutting.
    body = [path(dilate(painted, weight), OUTLINE)]
    under = set()
    for colour in reversed(order):
        idx = order.index(colour)
        under |= {(x, y) for x, y in painted if buf[y * VBW + x] == idx}
        body.insert(1, path(under, colour))

    head = ('<svg id="katman_1" xmlns="http://www.w3.org/2000/svg" version="1.1" '
            'viewBox="%d %d %d %d" shape-rendering="crispEdges">'
            % (VBX, VBY, VBW, VBH))
    return head + ''.join(p for p in body if p) + '</svg>\n'


def icon(art):
    """The same art cropped to its content, for the wardrobe tile."""
    pts = [p for _, ring in acc_offset.shapes(art) for p in ring]
    x0, x1, y0, y1 = acc_offset.bbox(pts)
    body = art[art.index('>', art.index('<svg')) + 1:art.rindex('</svg>')]
    head = ('<svg id="katman_1" xmlns="http://www.w3.org/2000/svg" version="1.1" '
            'viewBox="%d %d %d %d" shape-rendering="crispEdges">'
            % (x0, y0, x1 - x0, y1 - y0))
    return head + body + '</svg>\n'


# src: the drawing to convert, `art_src/<src>.svg`.
# out: what it becomes, `assets/svgs/acc_<out>.svg`. A bare accessory id is the
#   shared piece and gets a wardrobe icon cut from it; an `<id>_<pet>` name is
#   that pet's own copy, registered in `_PetParts.accessoryOverrides` and shown
#   in the wardrobe by the shared piece's icon, so it needs none of its own.
# scale: how far the source is scaled, read off the reference drawing.
# left/top: the outlined piece's top-left corner on the canvas. The shared piece
#   is seated on the cat, centred on where the piece it replaces already hung. A
#   pet's own copy is seated where that pet wears it, since an override is drawn
#   exactly where it lands with no offset applied.
JOBS = [
    dict(src='mustache_new', out='mustache', scale=0.5620, left=72, top=91),
    dict(src='bowtie_new', out='bowtie', scale=0.3307, left=75, top=125),
    # The dog's own cut: the same bow with the right wing clipped where the
    # muzzle crosses it, drawn to size already, so it only needs seating.
    dict(src='bowtie_new_for_dog', out='bowtie_dog', scale=1.0, left=104, top=101),
    # The chick's, sized and seated from art_src/bird_with_bowtie.svg: the same
    # bow at three quarters, because the chick's chest is that much narrower
    # than the cat's. The chick's other pieces are lifted straight out of their
    # drawings by art_src/gen_bird_worn.py; this one is rebuilt here instead so
    # it keeps the 4-unit outline the finer art wears, rather than the 7-unit
    # one that generator brings every piece up to.
    dict(src='bowtie_new', out='bowtie_bird', scale=0.2437, left=112, top=120),
]


if __name__ == '__main__':
    for job in JOBS:
        with open(os.path.join(HERE, '%s.svg' % job['src']), encoding='utf-8') as f:
            src = f.read()
        art = convert(src, job['scale'], job['left'], job['top'])
        files = [('acc_%s.svg' % job['out'], art)]
        if '_' not in job['out']:
            files.append(('acc_%s_icon.svg' % job['out'], icon(art)))
        for name, text in files:
            with open(os.path.join(SVG, name), 'w', encoding='utf-8') as f:
                f.write(text)
        box = acc_offset.bbox([p for _, r in acc_offset.shapes(art) for p in r])
        print('acc_%-14s scale %.4f   %3.0fx%-3.0fu outlined at %d,%d   %5d bytes'
              % (job['out'] + '.svg', job['scale'], box[1] - box[0], box[3] - box[2],
                 box[0], box[2], len(art)))
