# Builds the layered dog sprite assets from the hand-separated Inkscape sources
# in art_src/, mirroring the cat rig: shared canvas, canonical fills, integer
# pixel coords, pre-baked tail poses.
import sys, os, re
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lib_dog import *

SRC = r"C:/Users/genso/Documents/mojilearner_flutter/art_src"
OUT = r"C:/Users/genso/Documents/mojilearner_flutter/assets/svgs"

VIEWBOX = "-20 -90 222 328"
DX, DY = -22.32, -31.3        # feet onto the cat's ground line, art centred
HDR = ('<svg id="katman_1" xmlns="http://www.w3.org/2000/svg" version="1.1" '
       'viewBox="%s" shape-rendering="crispEdges">' % VIEWBOX)

master = {r['id']: r for r in parse_svg(os.path.join(SRC, 'dog_base.svg'))}
order  = [r['id'] for r in parse_svg(os.path.join(SRC, 'dog_base.svg'))]
openm  = {r['id']: r for r in parse_svg(os.path.join(SRC, 'dog_mouth_open.svg'))}
open_order = [r['id'] for r in parse_svg(os.path.join(SRC, 'dog_mouth_open.svg'))]

EYES  = ['rect8', 'polygon9']
MOUTH = ['polyline6', 'polygon7', 'polygon8', 'rect10']
TAIL  = ['polygon2', 'polygon4']
DROP  = ['path2']             # degenerate zero-width leftover
BASE  = [i for i in order if i not in EYES + MOUTH + TAIL + DROP]

def body(ids, src=master):
    out = []
    for i in ids:
        r = src[i]
        out.append('<path fill="%s" d="%s"/>' % (canon(r['fill']), emit(to_points(r['d']), DX, DY)))
    return ''.join(out)

def write(name, inner):
    p = os.path.join(OUT, name)
    open(p, 'w', encoding='utf-8').write(HDR + inner + '</svg>\n')
    print('%-24s %5d bytes' % (name, os.path.getsize(p)))

# --- body / face -----------------------------------------------------------
write('dog_base.svg',  body(BASE))
write('dog_eyes.svg',  body(EYES))
write('dog_mouth.svg', body(MOUTH))
write('dog_mouth_open.svg',
      body([i for i in open_order if i in MOUTH + ['path3']], src=openm))

# --- tail ------------------------------------------------------------------
# The cat bakes its wag as a rotation, which works on a small curled tail. The
# dog's is a tall straight flap: any rotation lands its edges off the pixel
# grid and the slab reads as a vector shape rather than pixel art. So the wag
# is baked as an axis-aligned bend instead -- everything above HINGE_Y shifts
# one cell sideways, with the crossing edges split so the join stays a square
# jog. Every coordinate remains an integer, so the poses are as crisp as rest.
HINGE_Y = 158.0
SWING   = 8            # one pixel cell

def bend(subs, dx):
    """Shift every vertex above HINGE_Y by dx, squaring off the crossing edges."""
    out = []
    for pts in subs:
        q = []
        n = len(pts)
        for k in range(n):
            ax, ay = pts[k]
            bx, by = pts[(k + 1) % n]
            q.append((ax + dx, ay) if ay < HINGE_Y else (ax, ay))
            if (ay < HINGE_Y) != (by < HINGE_Y):
                # Axis-aligned art: a crossing edge is vertical, so the jog is
                # a single horizontal step at the hinge line.
                if ay < HINGE_Y:
                    q += [(ax + dx, HINGE_Y), (ax, HINGE_Y)]
                else:
                    q += [(ax, HINGE_Y), (ax + dx, HINGE_Y)]
        out.append(q)
    return out

def tail(dx):
    parts = []
    for i in TAIL:
        r = master[i]
        subs = to_points(r['d'])
        if dx:
            subs = bend([[(x + DX, y + DY) for x, y in s] for s in subs], dx)
            parts.append('<path fill="%s" d="%s"/>' % (canon(r['fill']), emit(subs, 0, 0)))
        else:
            parts.append('<path fill="%s" d="%s"/>' % (canon(r['fill']), emit(subs, DX, DY)))
    return ''.join(parts)

write('dog_tail.svg',   tail(0))
write('dog_tail_l.svg', tail(-SWING))
write('dog_tail_r.svg', tail(SWING))

# --- whole-sprite render --------------------------------------------------
# `dog.svg` is no longer what the sprite draws (it composites the layers), but
# it is still the pet-picker thumbnail, so it has to carry the same palette.
# Cropped to its own content like `cat.svg`, so both thumbnails fill their tile.
def bbox_of(ids, src=master):
    xs, ys = [], []
    for i in ids:
        for sub in to_points(src[i]['d']):
            for x, y in sub:
                xs.append(round(x + DX)); ys.append(round(y + DY))
    return min(xs), min(ys), max(xs), max(ys)

flat_ids = [i for i in order if i not in DROP]
bx0, by0, bx1, by1 = bbox_of(flat_ids)
flat = ('<svg id="katman_1" xmlns="http://www.w3.org/2000/svg" version="1.1" '
        'viewBox="%d %d %d %d" shape-rendering="crispEdges">%s</svg>'
        % (bx0, by0, bx1 - bx0, by1 - by0, body(flat_ids)))
open(os.path.join(OUT, 'dog.svg'), 'w', encoding='utf-8').write(flat)
print('%-24s %5d bytes  viewBox %d %d %d %d'
      % ('dog.svg', len(flat), bx0, by0, bx1 - bx0, by1 - by0))

# --- geometry the Dart side needs -----------------------------------------
def bbox(ids, src=master):
    xs, ys = [], []
    for i in ids:
        for sub in to_points(src[i]['d']):
            for x, y in sub:
                xs.append(x + DX); ys.append(y + DY)
    return min(xs), min(ys), max(xs), max(ys)

print()
for i in EYES:
    x0, y0, x1, y1 = bbox([i])
    print('eye %-9s x=%g y=%g w=%g h=%g' % (i, x0, y0, x1 - x0, y1 - y0))
x0, y0, x1, y1 = bbox(EYES)
cx, by = (x0 + x1) / 2, y1
vbx, vby, vbw, vbh = [float(v) for v in VIEWBOX.split()]
print('eyes pivot Alignment(%.3f, %.3f)  (centre %g, bottom %g)'
      % ((cx - (vbx + vbw / 2)) / (vbw / 2), (by - (vby + vbh / 2)) / (vbh / 2), cx, by))
print('full bbox', bbox([i for i in order if i not in DROP]))
