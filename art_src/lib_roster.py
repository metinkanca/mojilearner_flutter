"""Shared helpers for the 24-pet roster art (`pet-roster-restored.svg`).

The roster pets are a different construction from every other pet in this
repo: each is a handful of rect-encoded `<path>`s on its own small viewBox,
one path per flat colour, painted back to front. That is compact and exact --
every cell is an integer rect -- so the whole pipeline here works on a **cell
grid** and re-emits the paths from it, rather than editing path data by hand.

Round-tripping is lossless in the only sense that matters: `emit(load(f))`
renders pixel-identically to `f` (verified by `check_roundtrip.py`). It is not
byte-identical, because the rect runs are re-packed greedily.
"""
import re

# The roster's own outline colour. Not the app's `#1f2223` -- the conversion to
# app canvas/palette happens in `gen_roster_pets.py`, not here.
OUTLINE = '#151413'


def load(path):
    """-> (W, H, [(fill, [(x0,y0,x1,y1), ...]), ...]) in paint order."""
    s = open(path, encoding='utf-8').read()
    m = re.search(r'viewBox="0 0 (\d+) (\d+)"', s)
    W, H = int(m.group(1)), int(m.group(2))
    layers = []
    for pm in re.finditer(r'<path fill="(#[0-9a-fA-F]{6})" d="([^"]+)"', s):
        layers.append((pm.group(1).lower(), _rects(pm.group(2), path)))
    return W, H, layers


def _rects(d, where):
    out = []
    for sub in d.split('Z'):
        sub = sub.strip()
        if not sub:
            continue
        m = re.fullmatch(r'M(-?\d+) (-?\d+)H(-?\d+)V(-?\d+)H(-?\d+)', sub)
        if not m:
            raise ValueError('%s: subpath is not a rect: %r' % (where, sub))
        x0, y0, x1, y1, xb = (int(g) for g in m.groups())
        if xb != x0:
            raise ValueError('%s: unclosed rect: %r' % (where, sub))
        out.append((x0, y0, x1, y1))
    return out


def raster(W, H, layers):
    """Paint the layers in order. -> grid[y][x] = fill or None."""
    g = [[None] * W for _ in range(H)]
    for fill, rects in layers:
        for x0, y0, x1, y1 in rects:
            for y in range(max(0, y0), min(H, y1)):
                row = g[y]
                for x in range(max(0, x0), min(W, x1)):
                    row[x] = fill
    return g


def grid_of(path):
    W, H, layers = load(path)
    return W, H, raster(W, H, layers)


def order_of(layers):
    """Paint order of the fills, first use wins."""
    seen, out = set(), []
    for fill, _ in layers:
        if fill not in seen:
            seen.add(fill)
            out.append(fill)
    return out


def runs(grid, W, H, fill):
    """Greedy rect cover of every cell of `fill`: maximal horizontal runs, then
    merged vertically where consecutive rows carry the identical run."""
    rows = []
    for y in range(H):
        r, x = [], 0
        while x < W:
            if grid[y][x] == fill:
                x0 = x
                while x < W and grid[y][x] == fill:
                    x += 1
                r.append((x0, x))
            else:
                x += 1
        rows.append(r)

    out, pending = [], {}          # (x0,x1) -> y0 of an open rect
    for y in range(H + 1):
        cur = set(rows[y]) if y < H else set()
        for span in sorted(set(pending) - cur):
            x0, x1 = span
            out.append((x0, pending.pop(span), x1, y))
        for span in sorted(cur - set(pending)):
            pending[span] = y
    return sorted(out, key=lambda r: (r[1], r[0]))


def emit(W, H, grid, order, title):
    """Re-emit a grid as the same flavour of SVG the roster is written in."""
    parts = ['<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" '
             'viewBox="0 0 %d %d" shape-rendering="crispEdges"><title>%s</title>'
             % (W * 2, H * 2, W, H, title)]
    for fill in order:
        rs = runs(grid, W, H, fill)
        if not rs:
            continue
        d = ''.join('M%d %dH%dV%dH%dZ' % (x0, y0, x1, y1, x0) for x0, y0, x1, y1 in rs)
        parts.append('<path fill="%s" d="%s"/>' % (fill, d))
    parts.append('</svg>')
    return ''.join(parts)


def emit_group(gid, tx, ty, W, H, grid, order):
    """The same content as one `<g>` of the roster sheet."""
    parts = ['<g id="%s" transform="translate(%d %d) scale(2)">' % (gid, tx, ty)]
    for fill in order:
        rs = runs(grid, W, H, fill)
        if not rs:
            continue
        d = ''.join('M%d %dH%dV%dH%dZ' % (x0, y0, x1, y1, x0) for x0, y0, x1, y1 in rs)
        parts.append('<path fill="%s" d="%s"/>' % (fill, d))
    parts.append('</g>')
    return ''.join(parts)


def components(grid, W, H, pred):
    """4-connected components of cells satisfying pred(fill)."""
    seen = [[False] * W for _ in range(H)]
    out = []
    for sy in range(H):
        for sx in range(W):
            if seen[sy][sx] or not pred(grid[sy][sx]):
                continue
            stack, comp = [(sx, sy)], []
            seen[sy][sx] = True
            while stack:
                x, y = stack.pop()
                comp.append((x, y))
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < W and 0 <= ny < H and not seen[ny][nx] and pred(grid[ny][nx]):
                        seen[ny][nx] = True
                        stack.append((nx, ny))
            out.append(comp)
    return out


def bbox(cells):
    xs = [c[0] for c in cells]
    ys = [c[1] for c in cells]
    return min(xs), min(ys), max(xs) + 1, max(ys) + 1
