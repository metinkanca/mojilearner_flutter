"""Removes hairline seams from a pet layer SVG.

Abutting shapes of the same colour each antialias against what is behind them,
so at any non-integer scale -- which is every frame of the breathing animation
-- their shared edge composites to less than full coverage and the background
shows through as a hairline. The art is full of such joins because it was
traced as many separate pieces.

The fix is to leave no shared edges at all: rasterise the layer on its own
pixel grid (the art is integer-aligned, so this is exact), then re-emit each
colour as ONE path traced from the region boundary. Colours are painted
back-to-front over the union of everything above them, so the joins between
different colours are overlaps rather than abutments too.

Usage:  python deseam.py file.svg [...]
"""
import re
import sys
from collections import defaultdict

VBX, VBY, VBW, VBH = -20, -90, 222, 328

# Painted bottom to top. Anything unlisted keeps document order after these.
RANK = {'#959379': 0, '#959279': 0, '#606659': 1, '#6b3439': 2, '#1f2223': 9}
# Both of the cat's drifted main fills collapse to the canonical one.
CANON = {'#959279': '#959379'}

NUM = re.compile(r'-?\d*\.?\d+(?:[eE][-+]?\d+)?')
TOK = re.compile(r'([MmLlHhVvZz])|(-?\d*\.?\d+(?:[eE][-+]?\d+)?)')


def path_subpaths(d):
    toks = TOK.findall(d)
    i = 0
    cmd = None
    cx = cy = sx = sy = 0.0
    subs = []
    cur = None

    def num():
        nonlocal i
        while toks[i][0]:
            i += 1
        v = float(toks[i][1])
        i += 1
        return v

    while i < len(toks):
        if toks[i][0]:
            cmd = toks[i][0]
            i += 1
            if cmd in 'Zz':
                if cur:
                    subs.append(cur)
                    cur = None
                cx, cy = sx, sy
                continue
        if i >= len(toks):
            break
        if cmd in 'Mm':
            x = num()
            y = num()
            if cmd == 'm':
                x += cx
                y += cy
            cx, cy = x, y
            sx, sy = x, y
            if cur:
                subs.append(cur)
            cur = [(cx, cy)]
            cmd = 'L' if cmd == 'M' else 'l'
        elif cmd in 'Ll':
            x = num()
            y = num()
            if cmd == 'l':
                x += cx
                y += cy
            cx, cy = x, y
            cur.append((cx, cy))
        elif cmd in 'Hh':
            x = num()
            if cmd == 'h':
                x += cx
            cx = x
            cur.append((cx, cy))
        elif cmd in 'Vv':
            y = num()
            if cmd == 'v':
                y += cy
            cy = y
            cur.append((cx, cy))
        else:
            raise SystemExit('unsupported path command %r' % cmd)
    if cur:
        subs.append(cur)
    return subs


def shapes(svg):
    """[(fill, [subpath, ...]), ...] in document order, group transforms baked."""
    out = []
    tx = ty = 0.0
    for m in re.finditer(r'<(g|rect|path|polygon|polyline|line)\b([^>]*)>', svg):
        tag, attrs = m.group(1), m.group(2)
        if tag == 'g':
            t = re.search(
                r'transform="translate\(\s*(-?[\d.]+)[ ,]+(-?[\d.]+)\s*\)"', attrs)
            if t:
                tx, ty = float(t.group(1)), float(t.group(2))
            elif 'transform=' in attrs:
                raise SystemExit('unsupported group transform: ' + attrs)
            continue
        fm = (re.search(r'fill="(#[0-9a-fA-F]{6})"', attrs)
              or re.search(r'fill:\s*(#[0-9a-fA-F]{6})', attrs))
        if not fm:
            continue                       # fill="none" -- draws nothing
        fill = CANON.get(fm.group(1).lower(), fm.group(1).lower())
        if tag == 'rect':
            def g(k):
                m2 = re.search(r'\b%s="([-\d.]+)"' % k, attrs)
                return float(m2.group(1)) if m2 else 0.0
            x, y, w, h = g('x'), g('y'), g('width'), g('height')
            subs = [[(x, y), (x + w, y), (x + w, y + h), (x, y + h)]]
        elif tag in ('polygon', 'polyline'):
            v = [float(n) for n in
                 NUM.findall(re.search(r'points="([^"]*)"', attrs).group(1))]
            subs = [list(zip(v[0::2], v[1::2]))]
        elif tag == 'path':
            subs = path_subpaths(re.search(r'\bd="([^"]*)"', attrs).group(1))
        else:
            continue
        out.append((fill, [[(x + tx, y + ty) for x, y in s] for s in subs]))
    return out


def rasterise(subs, buf, value):
    """Scanline fill (nonzero) at pixel centres. Exact for integer-aligned art."""
    edges = []
    for pts in subs:
        for k in range(len(pts)):
            (x1, y1), (x2, y2) = pts[k], pts[(k + 1) % len(pts)]
            if y1 != y2:
                edges.append((x1, y1, x2, y2))
    if not edges:
        return
    for py in range(VBH):
        sy = VBY + py + 0.5
        xs = []
        for x1, y1, x2, y2 in edges:
            if (y1 <= sy < y2) or (y2 <= sy < y1):
                xs.append((x1 + (sy - y1) * (x2 - x1) / (y2 - y1),
                           1 if y2 > y1 else -1))
        if not xs:
            continue
        xs.sort()
        w = 0
        start = None
        for x, d in xs:
            if w == 0:
                start = x
            w += d
            if w == 0 and start is not None:
                for px in range(VBW):
                    c = VBX + px + 0.5
                    if start <= c < x:
                        buf[py * VBW + px] = value
                start = None


def trace(mask):
    """Boundary contours of a boolean mask, oriented for the nonzero rule."""
    def inside(x, y):
        return 0 <= x < VBW and 0 <= y < VBH and mask[y * VBW + x]

    out = defaultdict(list)
    for y in range(VBH):
        for x in range(VBW):
            if not mask[y * VBW + x]:
                continue
            if not inside(x, y - 1):
                out[(x, y)].append((x + 1, y))
            if not inside(x + 1, y):
                out[(x + 1, y)].append((x + 1, y + 1))
            if not inside(x, y + 1):
                out[(x + 1, y + 1)].append((x, y + 1))
            if not inside(x - 1, y):
                out[(x, y + 1)].append((x, y))

    loops = []
    while out:
        start = next(iter(out))
        cur, d = start, None
        loop = [start]
        while True:
            nxts = out.get(cur)
            if not nxts:
                break
            if len(nxts) > 1 and d is not None:
                # Diagonal touch: take the clockwise-most turn so the two
                # regions stay separate, as they are in the source art.
                nxts.sort(key=lambda n, c=cur, dd=d:
                          -(dd[0] * (n[1] - c[1]) - dd[1] * (n[0] - c[0])))
            nxt = nxts.pop(0)
            if not out[cur]:
                del out[cur]
            d = (nxt[0] - cur[0], nxt[1] - cur[1])
            cur = nxt
            if cur == start:
                break
            loop.append(cur)
        loops.append(loop)
    return loops


def emit(loops):
    parts = []
    for loop in loops:
        pts = [(x + VBX, y + VBY) for x, y in loop]
        q = []
        for k, p in enumerate(pts):
            a, b = pts[k - 1], pts[(k + 1) % len(pts)]
            if (a[0] == p[0] == b[0]) or (a[1] == p[1] == b[1]):
                continue               # collinear
            q.append(p)
        if len(q) < 3:
            continue
        s = 'M%d %d' % q[0]
        py = q[0][1]
        for x, y in q[1:]:
            s += 'H%d' % x if y == py else 'V%d' % y
            py = y
        parts.append(s + 'Z')
    return ''.join(parts)


def deseam(svg):
    shp = shapes(svg)
    fills = []
    for f, _ in shp:
        if f not in fills:
            fills.append(f)
    order = sorted(fills, key=lambda f: (RANK.get(f, 5), fills.index(f)))

    buf = [-1] * (VBW * VBH)
    for f, subs in shp:
        rasterise(subs, buf, order.index(f))

    body = []
    for i, f in enumerate(order):
        mask = [1 if v >= i else 0 for v in buf]
        if not any(mask):
            continue
        d = emit(trace(mask))
        if d:
            body.append('<path fill="%s" d="%s"/>' % (f, d))
    head = svg[:svg.index('>', svg.index('<svg')) + 1]
    return head + ''.join(body) + '</svg>\n'


if __name__ == '__main__':
    for p in sys.argv[1:]:
        src = open(p, encoding='utf-8').read()
        # Build the whole result before touching the file: an unsupported
        # construct raises, and opening for write first would truncate the
        # source on the way out.
        out = deseam(src)
        open(p, 'w', encoding='utf-8').write(out)
        print('deseamed %s' % p)
