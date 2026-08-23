# Builds the bird sprite assets from the hand-separated Inkscape source in
# art_src/bird_base.svg, bringing it onto the same footing as the cat and the
# dog: shared canvas, canonical fills, integer pixel coords.
#
# The bird is a side-profile chick with no tail and no separate muzzle, so its
# rig is smaller than the other two: a coat layer plus a generated eye. The eye
# has to come out of the coat because it is recoloured and blinks, and because
# deseam merges every same-coloured piece into one path -- an eye left in the
# base would fuse with the outline.
#
# Re-run after any edit to art_src/bird_base.svg. Never hand-edit the output.
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lib_dog import parse_svg, to_points

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, 'bird_base.svg')
OUT = os.path.join(HERE, '..', 'assets', 'svgs')

VIEWBOX = "-20 -90 222 328"
# Lands the feet on the cat's ground line (y=238) and centres the art on the same
# axis as the cat and the dog, which also snaps the art's .96/.44 offsets to
# whole pixels.
DX, DY = -303.96, -147.44

# The one shape that is not coat: the eye. Everything else is the body.
EYE = 'polygon10'

CANON_OUTLINE, CANON_MAIN, CANON_SHADE = '#1f2223', '#959379', '#606659'
# The chick was traced with six drifted browns for the outline and three for
# the shading, the same way the dog was. They all collapse, so the bird reads
# as a sibling of the other two pets and answers to the same recolour code.
OUTLINE = {'#4b3017', '#4c2f16', '#4f3115', '#4e3015', '#4d3016', '#472d16',
           '#462c16', '#472c16'}
MAIN = {'#fcc249'}
SHADE = {'#c47b31', '#cc8536', '#b87531', '#995d27', '#ba7431', '#d48c3b'}


def canon(hex_):
    h = (hex_ or '').lower()
    if h in OUTLINE: return CANON_OUTLINE
    if h in MAIN: return CANON_MAIN
    if h in SHADE: return CANON_SHADE
    raise SystemExit('unknown fill ' + str(hex_))


def snap(sub):
    """Round onto the pixel grid, then drop duplicate and collinear vertices."""
    pts = [(round(x + DX), round(y + DY)) for x, y in sub]
    q = [pts[0]]
    for p in pts[1:]:
        if p != q[-1]: q.append(p)
    if len(q) > 1 and q[0] == q[-1]: q.pop()
    changed = True
    while changed and len(q) > 2:
        changed = False
        out = []
        for i in range(len(q)):
            a, b, c = q[i - 1], q[i], q[(i + 1) % len(q)]
            if a == b or (a[0] == b[0] == c[0]) or (a[1] == b[1] == c[1]):
                changed = True
                continue
            out.append(b)
        q = out
    return q


def emit(subs):
    out = []
    for q in subs:
        if len(q) < 3:
            continue
        s = 'M%d %d' % q[0]
        px, py = q[0]
        for x, y in q[1:]:
            if y == py: s += 'H%d' % x
            elif x == px: s += 'V%d' % y
            else: raise SystemExit('diagonal after snap: %s -> %s' % ((px, py), (x, y)))
            px, py = x, y
        out.append(s + 'Z')
    return ''.join(out)


HEAD = ('<svg id="katman_1" xmlns="http://www.w3.org/2000/svg" version="1.1" '
        'viewBox="%s" shape-rendering="crispEdges">' % VIEWBOX)

recs = parse_svg(SRC)
shapes = {}          # id -> (fill, [snapped subpath, ...])
for r in recs:
    subs = [s for s in (snap(s) for s in to_points(r['d'])) if len(s) >= 3]
    if subs:
        shapes[r['id']] = (canon(r['fill']), subs)

if EYE not in shapes:
    raise SystemExit('eye shape %s missing from %s' % (EYE, SRC))


def build(ids):
    return HEAD + ''.join(
        '<path fill="%s" d="%s"/>' % (shapes[i][0], emit(shapes[i][1]))
        for i in ids) + '</svg>\n'


def bbox(ids):
    pts = [p for i in ids for s in shapes[i][1] for p in s]
    return (min(p[0] for p in pts), min(p[1] for p in pts),
            max(p[0] for p in pts), max(p[1] for p in pts))


# Seams: abutting pieces antialias against the background at the non-integer
# scales the breathing animation runs at, so every coat layer gets the same
# back-to-front repaint the cat's and dog's layers get.
sys.argv = [sys.argv[0]]
import deseam

order = [i for i in shapes]
body_ids = [i for i in order if i != EYE]


def write(name, svg):
    p = os.path.join(OUT, name)
    open(p, 'w', encoding='utf-8').write(svg)
    print('%-18s %5d bytes' % (name, len(svg)))


# The coat layer the sprite actually draws, and recolours.
write('bird_base.svg', deseam.deseam(build(body_ids)))
# The eye on its own. The sprite generates its eye from kBirdEyes rather than
# loading this, the same as the cat and dog -- it is here as the source of
# truth those constants are lifted from, and so the layer set is complete.
write('bird_eyes.svg', build([EYE]))
# Whole sprite, for anything still asking for one asset per pet (the pet
# picker's fallback, tooling). Same palette, eye included.
write('bird.svg', deseam.deseam(build(order)))

# --- geometry the Dart side needs -----------------------------------------
ex0, ey0, ex1, ey1 = bbox([EYE])
vbx, vby, vbw, vbh = [float(v) for v in VIEWBOX.split()]
cx, by = (ex0 + ex1) / 2, ey1
print()
print('kBirdEyes  leftX: %d, y: %d, w: %d, h: %d  (single eye)'
      % (ex0, ey0, ex1 - ex0, ey1 - ey0))
print('eyesPivot  Alignment(%.3f, %.3f)'
      % ((cx - (vbx + vbw / 2)) / (vbw / 2), (by - (vby + vbh / 2)) / (vbh / 2)))
bx0, by0, bx1, by1 = bbox(order)
print('full bbox  x %d..%d  y %d..%d   crown y=%d   feet y=%d'
      % (bx0, bx1, by0, by1, by0, by1))
