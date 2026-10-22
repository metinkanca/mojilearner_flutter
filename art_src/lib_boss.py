"""Shared machinery for the trial bosses whose master art is a colour-path SVG.

Mossback, Amethyst and the witch owl each arrive as a handful of colour paths
on a 10-unit pixel grid, each an even-odd outline, painted in document order
with the full silhouette first. Drawn as-is in the app their colours abut, so
at any non-integer scale -- every frame of a jump's squash and stretch -- the
joins show hairlines (see deseam.py), and each has only the one pose.

So a boss generator rasterises the art onto its own cell grid, which is exact,
edits the grid for its extra poses, and emits each pose with `emit`: one traced
path per colour, each painted over the union of everything above it, in cell
units so every coordinate is a small integer.

Art drawn on a finer grid than the set's (Pyrewing's) is brought down to it
with `shrink`, which needs numpy and Pillow; nothing else here does.
"""
import math
import os
import re

import deseam

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.normpath(os.path.join(HERE, '..', 'assets', 'svgs'))

CELL = 10

# The shout's colours, shared so every boss's open mouth reads as the same
# feature: the dog's mouth interior, and AppTheme.retroPrimary for the tongue.
MOUTH = '#6b3439'
TONGUE = '#d95763'


def source_paths(src):
    """[(fill, subpaths)] in document order."""
    svg = open(os.path.join(HERE, src), encoding='utf-8').read()
    out = []
    for m in re.finditer(r'<path\b([^>]*)/>', svg):
        attrs = m.group(1)
        fill = re.search(r'fill="(#[0-9a-fA-F]{6})"', attrs).group(1).lower()
        d = re.search(r'\bd="([^"]*)"', attrs).group(1)
        out.append((fill, deseam.path_subpaths(d)))
    return out


def rasterise_evenodd(subs, unit=None):
    """Cells whose centre is inside [subs] under the even-odd rule.

    [unit] is the source's grid unit: 10 for the first three bosses, 1 for
    art drawn straight on its pixel grid (Lanternmaw on).
    """
    unit = unit or CELL
    edges = []
    for pts in subs:
        for k in range(len(pts)):
            (x1, y1), (x2, y2) = pts[k], pts[(k + 1) % len(pts)]
            if y1 != y2:
                edges.append((x1 / unit, y1 / unit, x2 / unit, y2 / unit))
    ys = [y for e in edges for y in (e[1], e[3])]
    cells = set()
    for cy in range(math.floor(min(ys)), math.ceil(max(ys))):
        sy = cy + 0.5
        xs = sorted(x1 + (sy - y1) * (x2 - x1) / (y2 - y1)
                    for x1, y1, x2, y2 in edges
                    if (y1 <= sy < y2) or (y2 <= sy < y1))
        for a, b in zip(xs[0::2], xs[1::2]):
            for cx in range(math.floor(a), math.ceil(b)):
                if a <= cx + 0.5 < b:
                    cells.add((cx, cy))
    return cells


def grid(src, unit=None):
    """{(x, y): fill} with later paths painted over earlier ones."""
    g = {}
    for fill, subs in source_paths(src):
        for cell in rasterise_evenodd(subs, unit):
            g[cell] = fill
    return g


def class_grid(src):
    """[grid] for art whose paths take their colour from a CSS class in the
    file's own <style> (`.brick { fill: #a84c3e; }`), as an editor's layered
    export does, on a 1-unit grid."""
    svg = open(os.path.join(HERE, src), encoding='utf-8').read()
    fills = {name: fill.lower() for name, fill in
             re.findall(r'\.([\w-]+)\s*\{\s*fill:\s*(#[0-9a-fA-F]{6})', svg)}
    g = {}
    for m in re.finditer(r'<path\b([^>]*)/>', svg):
        attrs = m.group(1)
        fill = fills[re.search(r'class="([\w-]+)"', attrs).group(1)]
        d = re.search(r'\bd="([^"]*)"', attrs).group(1)
        for cell in rasterise_evenodd(deseam.path_subpaths(d), 1):
            g[cell] = fill
    return g


N4 = ((1, 0), (-1, 0), (0, 1), (0, -1))
N8 = N4 + ((1, 1), (1, -1), (-1, 1), (-1, -1))


def shrink(g, cells_w, outline, blur=3.0):
    """[g] redrawn [cells_w] cells wide, for art drawn on a finer grid than
    the set's: every boss is shown at much the same size, so more cells
    would mean smaller pixels and a thinner outline than the rest.

    Each source cell becomes an 8px block; each colour's mask is blurred by
    [blur] px and the strongest colour kept, which rounds off the source's
    stair-steps instead of sampling them into uneven ones; then every cell
    takes the colour covering most of it. The outline is rebuilt two cells
    thick all round, as the set has it, and lone cells are folded into
    their neighbours.
    """
    import numpy as np
    from PIL import Image, ImageFilter

    up = 8
    x0, y0, x1, y1 = bounds(g)
    fills = sorted(set(g.values()))
    lab = np.full((y1 - y0, x1 - x0), -1, int)
    for (x, y), f in g.items():
        lab[y - y0, x - x0] = fills.index(f)
    lab = np.kron(lab, np.ones((up, up), int))
    masks = [np.asarray(Image.fromarray(((lab == v) * 255).astype(np.uint8))
                        .filter(ImageFilter.GaussianBlur(blur)), float)
             for v in range(-1, len(fills))]
    lab = np.argmax(np.stack(masks), 0) - 1

    cell = lab.shape[1] / cells_w
    cells_h = round(lab.shape[0] / cell)
    out = {}
    for cy in range(cells_h):
        for cx in range(cells_w):
            block = lab[int(cy * cell):int((cy + 1) * cell),
                        int(cx * cell):int((cx + 1) * cell)]
            vals, counts = np.unique(block, return_counts=True)
            if vals[counts.argmax()] >= 0:
                out[(cx, cy)] = fills[vals[counts.argmax()]]
    return _strays(_outline(out, outline), outline)


def _depth(g):
    """Every cell's distance in from the outside, the edge cells being 1."""
    from collections import deque
    d, q = {}, deque()
    for x, y in g:
        if any((x + dx, y + dy) not in g for dx, dy in N8):
            d[(x, y)] = 1
            q.append((x, y))
    while q:
        x, y = q.popleft()
        for dx, dy in N8:
            c = (x + dx, y + dy)
            if c in g and c not in d:
                d[c] = d[(x, y)] + 1
                q.append(c)
    return d


def _fill_near(g, cell, outline):
    """The commonest colour other than the outline round [cell]."""
    x, y = cell
    near = [g[(x + dx, y + dy)] for dx in range(-2, 3) for dy in range(-2, 3)
            if g.get((x + dx, y + dy), outline) != outline]
    return max(set(near), key=near.count) if near else outline


def _outline(g, outline):
    """The two outer rings in the outline colour. Outline in the third ring
    only thickens it, unless it leads on inward as a line, and goes back to
    the fill."""
    out = dict(g)
    d = _depth(g)
    for c, k in d.items():
        if k <= 2:
            out[c] = outline
    for (x, y), k in d.items():
        if k == 3 and g[(x, y)] == outline and not any(
                d.get((x + dx, y + dy), 0) >= 4
                and g[(x + dx, y + dy)] == outline for dx, dy in N4):
            out[(x, y)] = _fill_near(g, (x, y), outline)
    return out


def _strays(g, outline):
    """Lone cells, touching nothing of their own colour, take their
    neighbours' colour; the outline's diagonal steps are left alone."""
    out = dict(g)
    for (x, y), v in g.items():
        if any(g.get((x + dx, y + dy)) == v for dx, dy in N4):
            continue
        if v == outline and any(g.get((x + dx, y + dy)) == v for dx, dy in N8):
            continue
        out[(x, y)] = _fill_near(g, (x, y), outline)
    return out


def order(src, extra=()):
    """Back to front: the source's own document order, which paints the full
    silhouette first, then [extra] colours on top."""
    out = []
    for fill, _ in source_paths(src):
        if fill not in out:
            out.append(fill)
    return out + [f for f in extra if f not in out]


def bounds(g):
    xs = [x for x, _ in g]
    ys = [y for _, y in g]
    return min(xs), min(ys), max(xs) + 1, max(ys) + 1


def print_map(g, letters, x0, y0, x1, y1):
    print('     ' + ''.join(str(x // 10 % 10) if x % 10 == 0 else ' '
                           for x in range(x0, x1)))
    for y in range(y0, y1):
        row = ''.join(letters.get(g.get((x, y)), '.') for x in range(x0, x1))
        print('%4d %s' % (y, row))


def paint(g, x0, y0, rows, colours, under):
    """[g] with [rows] painted in from (x0, y0), one letter per cell.

    Every cell painted must currently be one of [under], so a pose edit can
    only ever change what it was drawn against. A space leaves a cell alone.
    """
    out = dict(g)
    for dy, row in enumerate(rows):
        for dx, ch in enumerate(row):
            if ch == ' ':
                continue
            cell = (x0 + dx, y0 + dy)
            assert g.get(cell) in under, (cell, g.get(cell))
            out[cell] = colours[ch]
    return out


def emit(g, order, x0, y0, w, h):
    """The SVG for [g] in the frame (x0, y0, w, h), cells as units."""
    deseam.VBX, deseam.VBY, deseam.VBW, deseam.VBH = 0, 0, w, h
    used = set(g.values())
    index = {f: i for i, f in enumerate(f for f in order if f in used)}
    buf = [-1] * (w * h)
    for (x, y), f in g.items():
        buf[(y - y0) * w + (x - x0)] = index[f]
    body = []
    for f, i in index.items():
        mask = [1 if v >= i else 0 for v in buf]
        if not any(mask):
            continue
        d = deseam.emit(deseam.trace(mask))
        if d:
            body.append('<path fill="%s" d="%s"/>' % (f, d))
    return ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %d %d" '
            'shape-rendering="crispEdges">' % (w, h)) + ''.join(body) + '</svg>\n'


def write(name, svg):
    path = os.path.join(OUT, name)
    open(path, 'w', encoding='utf-8').write(svg)
    print('wrote %s' % path)
