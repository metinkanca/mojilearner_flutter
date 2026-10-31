# Shared machinery for the REWORKED pets (`cat.svg`, `bird.svg`, `rabbit.svg`
# and the dog's `dog_rework_test_2.svg`).
#
# The reworks arrive as one Inkscape file per pet: a dark silhouette path with
# flat coat paths stacked over it, all on a 4-pixel grid. Unlike the dog master,
# the cat, bird and rabbit have no face layers -- their eyes and mouths are
# holes cut in the coat, where the silhouette shows through. So everything here
# works off the art's own cell lattice: rasterise once, vote per 4x4 cell, and
# the parts come out as cell regions that a pet's generator names by hand.
#
# The output lands on the same frame `gen_dog2.py` gives the dog: CELL = 3 on a
# canvas that is the shared 222x328 one scaled up to 255 wide, feet on its
# bottom edge. One scale for every rework keeps the pets at the sizes the artist
# drew them relative to each other.
import math
import os
import re

import deseam
from lib_dog import to_points

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, '..', 'assets', 'svgs')

SRCCELL = 4
CELL = 3
SCALE = 255 / 222
VBW, VBH = 222 * SCALE, 328 * SCALE
VBX, VBY = 91 - VBW / 2, 74 - VBH / 2
GROUND = round(VBY + VBH)                       # feet sit on this line
CENTRE_X = 91                                   # the shared canvas's centre
VIEWBOX = '%s %s %s %s' % tuple(
    ('%.4f' % v).rstrip('0').rstrip('.') for v in (VBX, VBY, VBW, VBH))
HDR = ('<svg id="katman_1" xmlns="http://www.w3.org/2000/svg" version="1.1" '
       'viewBox="%s" shape-rendering="crispEdges">' % VIEWBOX)

# The canonical tones every pet is recoloured through (lib/utils/pet_recolor).
OUTLINE, MAIN, SHADE, LIGHT = '#1f2223', '#959379', '#606659', '#c8c6b3'
RED = '#6b3439'
# The beak. Drawn in its own marker fill so the player can colour it apart from
# the coat; left unchosen it renders as the coat's shade (lib/utils/pet_recolor
# `kBeakFill`).
BEAK = '#7a6f5a'
SRC_OUTLINE = '#16130e'


class Master:
    """One rework master rasterised onto its cell lattice.

    `palette` maps each visible source fill to the tone it is emitted as; a
    fill it does not name is kept as drawn (a beak, an ear's pink). Paths the
    artist has hidden (`display:none`) are skipped -- they are unfinished.
    """

    def __init__(self, name, palette, srccell=SRCCELL, outline=SRC_OUTLINE):
        self.srccell = srccell
        self.src = os.path.join(HERE, name)
        svg = open(self.src, encoding='utf-8').read()
        w, h = re.search(r'viewBox="0 0 (\d+) (\d+)"', svg).groups()
        self.w, self.h = int(w), int(h)
        self.cw, self.ch = -(-self.w // srccell), -(-self.h // srccell)
        # The picture flattened pixel by pixel, top layer wins, as layer index.
        tones = []
        pixels = bytearray(self.w * self.h)      # 0 = bare, else index + 1
        for m in re.finditer(r'<path\b(.*?)/>', svg, re.S):
            attrs = m.group(1)
            if 'display:none' in attrs:
                continue
            fill = re.search(r'\bfill="(#[0-9a-fA-F]{6})"', attrs).group(1).lower()
            rule = (re.search(r'fill-rule="(\w+)"', attrs) or (None, 'nonzero'))[1]
            subs = to_points(re.search(r'\sd="([^"]*)"', attrs, re.S).group(1))
            tones.append(OUTLINE if fill == outline else palette.get(fill, fill))
            mask = self._raster(subs, rule)
            for i, v in enumerate(mask):
                if v:
                    pixels[i] = len(tones)
        self.flat = self._vote(pixels, tones)

    def narrow(self, drop):
        """Removes `drop` columns that repeat the column to their left.

        For a master wider than the canvas at a whole-number cell: a repeated
        column only shortens a flat run by a cell, so no corner or feature
        moves. Spread along the pet, so it loses a cell here and there rather
        than showing a pinch. The roster's `gen_roster_pets.narrow`, on cells.
        """
        cols = [tuple(self.flat.get((x, y)) for y in range(self.ch))
                for x in range(self.cw)]
        dup = [x for x in range(1, self.cw)
               if cols[x] == cols[x - 1] and any(cols[x])]
        if len(dup) < drop:
            raise SystemExit('%s: needs to lose %d columns, only %d repeat'
                             % (self.src, drop, len(dup)))
        step = len(dup) / float(drop)
        take = {dup[int(i * step)] for i in range(drop)}
        keep = [x for x in range(self.cw) if x not in take]
        self.flat = {(nx, y): f for nx, x in enumerate(keep)
                     for y in range(self.ch)
                     for f in [self.flat.get((x, y))] if f}
        self.cw = len(keep)
        return self

    def _vote(self, pixels, tones):
        """Each cell takes the colour covering most of it.

        Voted on the flattened picture rather than per layer. Per layer, a
        cell split evenly between two shapes -- a beak edge on a 2-pixel step
        -- belongs to neither, and falls through to the silhouette under both,
        which draws a dark line the art does not have. A tie goes to bare
        canvas first, so the outer edge is what it always was; then to
        outline, so a line drawn two pixels wide (the cat's inner ear) is kept;
        and otherwise to the layer drawn later.
        """
        outline = {i + 1 for i, t in enumerate(tones) if t == OUTLINE}
        flat = {}
        S = self.srccell
        for cy in range(self.ch):
            for cx in range(self.cw):
                count = {}
                for y in range(cy * S, min(cy * S + S, self.h)):
                    for x in range(cx * S, min(cx * S + S, self.w)):
                        k = pixels[y * self.w + x]
                        count[k] = count.get(k, 0) + 1
                best = max(count, key=lambda k: (count[k], k == 0,
                                                 k in outline, k))
                if best:
                    flat[(cx, cy)] = tones[best - 1]
        return flat

    def _raster(self, subs, rule):
        edges = []
        for pts in subs:
            for k in range(len(pts)):
                (x1, y1), (x2, y2) = pts[k], pts[(k + 1) % len(pts)]
                if y1 != y2:
                    edges.append((x1, y1, x2, y2))
        W, H = self.w, self.h
        mask = bytearray(W * H)
        for py in range(H):
            sy = py + 0.5
            xs = sorted((x1 + (sy - y1) * (x2 - x1) / (y2 - y1),
                         1 if y2 > y1 else -1)
                        for x1, y1, x2, y2 in edges
                        if (y1 <= sy < y2) or (y2 <= sy < y1))
            spans = []
            if rule == 'evenodd':
                spans = [(xs[k][0], xs[k + 1][0]) for k in range(0, len(xs) - 1, 2)]
            else:
                wind, start = 0, None
                for x, d in xs:
                    if wind == 0:
                        start = x
                    wind += d
                    if wind == 0:
                        spans.append((start, x))
            for a, b in spans:
                for px in range(max(0, int(a)), min(W, int(b) + 2)):
                    if a <= px + 0.5 < b:
                        mask[py * W + px] = 1
        return mask

    def ascii(self, marks=None):
        key = {OUTLINE: '#', MAIN: '.', SHADE: 's', LIGHT: 'l'}
        rows = []
        for cy in range(self.ch):
            row = ''
            for cx in range(self.cw):
                t = self.flat.get((cx, cy))
                ch = ' ' if t is None else key.get(t, 'o')
                if marks and (cx, cy) in marks:
                    ch = marks[(cx, cy)]
                row += ch
            rows.append('%3d %s' % (cy, row))
        head = '    ' + ''.join(str(x // 10 % 10) if x % 10 == 0 else ' '
                                for x in range(self.cw))
        return head + '\n' + '\n'.join(rows)


class Frame:
    """Where a master's cells land on the canvas.

    The art is centred on the canvas's centre line by its bounding box and its
    lowest cell sits on [GROUND]. `pad` is room on the trace grid for layers
    that move off the master's lattice (a swung tail).
    """

    def __init__(self, master, pad=2, cell=CELL):
        self.cell = cell
        xs = [c[0] for c in master.flat]
        ys = [c[1] for c in master.flat]
        self.pad = pad
        self.gw, self.gh = master.cw + 2 * pad, master.ch + 2 * pad
        self.cw, self.ch = master.cw, master.ch
        self.x0 = round(CENTRE_X - (min(xs) + max(xs) + 1) * cell / 2)
        self.y0 = GROUND - (max(ys) + 1) * cell

    def emit(self, layer, rank):
        """`layer` is {(cx, cy): fill}; returns the SVG body, deseamed.

        Each fill is painted over the union of every fill ranked above it, so
        no two shapes share an edge for the breathing animation to open.
        """
        deseam.VBW, deseam.VBH = self.gw, self.gh
        order = sorted({f for f in layer.values()}, key=lambda f: rank[f])
        pos = {f: i for i, f in enumerate(order)}
        body = []
        for i, fill in enumerate(order):
            mask = [0] * (self.gw * self.gh)
            for (cx, cy), f in layer.items():
                if pos[f] >= i:
                    mask[(cy + self.pad) * self.gw + cx + self.pad] = 1
            d = ''.join(self._path(loop) for loop in deseam.trace(mask)
                        if len(loop) >= 3)
            if d:
                body.append('<path fill="%s" d="%s"/>' % (fill, d))
        return ''.join(body)

    def _path(self, loop):
        p = self.pad
        pts = [((x - p) * self.cell + self.x0, (y - p) * self.cell + self.y0)
               for x, y in loop]
        q = [pt for k, pt in enumerate(pts)
             if not (pts[k - 1][0] == pt[0] == pts[(k + 1) % len(pts)][0]
                     or pts[k - 1][1] == pt[1] == pts[(k + 1) % len(pts)][1])]
        if len(q) < 3:
            return ''
        s = 'M%d %d' % q[0]
        py = q[0][1]
        for x, y in q[1:]:
            s += 'H%d' % x if y == py else 'V%d' % y
            py = y
        return s + 'Z'

    def write(self, name, layer, rank):
        path = os.path.join(OUT, name)
        open(path, 'w', encoding='utf-8').write(HDR + self.emit(layer, rank) + '</svg>\n')
        print('%-26s %5d bytes' % (name, os.path.getsize(path)))

    def seal(self, layer, thick=1, within=None):
        """Outline for coat left with bare canvas beside it, `thick` cells deep.

        Without `within`, grown only from exposed coat through bare canvas, so
        outlines the art already has stay as drawn.

        With `within` -- the cells a lifted tail vacated -- it grows through
        outline as well, and fills only those cells. That is the flank behind
        a tail: the art's own line there may be one cell thick, which is fine
        while the tail sits on it and a gap the moment a wag swings it clear.
        Filling only vacated cells leaves the rest pose exactly as drawn,
        since the tail covers them.
        """
        sealed = dict(layer)
        front = {c for c, f in layer.items() if f != OUTLINE}
        seen = set(front)
        p = self.pad
        for _ in range(thick):
            grown = set()
            for cx, cy in front:
                for a in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
                    if a in seen or not (-p <= a[0] < self.cw + p
                                         and -p <= a[1] < self.ch + p):
                        continue
                    if within is None:
                        if a in sealed:
                            continue
                    elif not (a in within or sealed.get(a) == OUTLINE):
                        continue
                    seen.add(a)
                    sealed.setdefault(a, OUTLINE)
                    grown.add(a)
            front = grown
        return sealed

    def box(self, cells):
        xs, ys = [c[0] for c in cells], [c[1] for c in cells]
        c = self.cell
        return (min(xs) * c + self.x0, min(ys) * c + self.y0,
                (max(xs) - min(xs) + 1) * c, (max(ys) - min(ys) + 1) * c)

    def report(self, eyes):
        """The numbers the Dart side needs, for one or two eye cell sets."""
        boxes = [self.box(e) for e in eyes]
        lx, ly, lw, lh = boxes[0]
        right = boxes[1][0] if len(boxes) > 1 else None
        # A right eye cut shorter than the left (the bird's, above its beak).
        rh = boxes[1][3] if len(boxes) > 1 else lh
        print('\nPetEyeGeometry(leftX: %d, %sy: %d, w: %d, h: %d, %sviewBox: %r)'
              % (lx, '' if right is None else 'rightX: %d, ' % right, ly, lw, lh,
                 '' if rh == lh else 'rightH: %d, ' % rh, VIEWBOX))
        cx = (lx + (right if right is not None else lx) + lw) / 2
        by = ly + max(lh, rh)
        print('eyesPivot Alignment(%.3f, %.3f)'
              % ((cx - (VBX + VBW / 2)) / (VBW / 2), (by - (VBY + VBH / 2)) / (VBH / 2)))


def tail_root(tail, body):
    """Where the tail joins the body: the centre of the tail cells touching it.

    `body` is every pet cell that is not the tail's. Rotating about this point
    keeps the join where it is while the rest of the tail swings.
    """
    touching = [(cx, cy) for cx, cy in tail
                if any((cx + dx, cy + dy) in body
                       for dx in (-1, 0, 1) for dy in (-1, 0, 1))]
    if not touching:
        touching = list(tail)
    return (sum(x for x, _ in touching) / len(touching) + 0.5,
            sum(y for _, y in touching) / len(touching) + 0.5)


def tail_angle(tail, root, reach):
    """The angle, in radians, that moves the tail's farthest cell `reach` cells."""
    far = max(math.hypot(cx + 0.5 - root[0], cy + 0.5 - root[1]) for cx, cy in tail)
    return math.atan2(reach, far)


def rotate_tail(tail, root, angle):
    """The whole tail turned `angle` radians about `root`, on the cell grid.

    Every cell moves -- barely at the root, most at the tip -- which is what a
    wag looks like. The old pose moved only the rows above a hinge, so a third
    of the tail stood still under a block that slid sideways.

    Sampled backwards: each cell of the result looks up the cell that turns
    onto it, so the posed tail has no holes and stays one flat colour per cell.
    """
    if not angle:
        return dict(tail)
    cos, sin = math.cos(-angle), math.sin(-angle)
    px, py = root
    xs = [c[0] for c in tail]
    ys = [c[1] for c in tail]
    far = int(max(math.hypot(x + 0.5 - px, y + 0.5 - py) for x, y in tail)) + 2
    posed = {}
    for cy in range(int(py) - far, int(py) + far + 1):
        for cx in range(int(px) - far, int(px) + far + 1):
            dx, dy = cx + 0.5 - px, cy + 0.5 - py
            sx = math.floor(px + cos * dx - sin * dy)
            sy = math.floor(py + sin * dx + cos * dy)
            if min(xs) <= sx <= max(xs) and min(ys) <= sy <= max(ys):
                f = tail.get((sx, sy))
                if f is not None:
                    posed[(cx, cy)] = f
    return posed


def wag_left(tail, root, angle):
    """The sign of `angle` that sends the tip of the tail leftward."""
    tip = min(tail, key=lambda c: c[1])
    for a in (angle, -angle):
        dx, dy = tip[0] + 0.5 - root[0], tip[1] + 0.5 - root[1]
        if root[0] + math.cos(a) * dx - math.sin(a) * dy < tip[0] + 0.5:
            return a
    return angle


def close_notches(base, posed):
    """Outline for bare cells a swung tail leaves pinched against the flank.

    A cell with pet on three of its four sides is a notch, not background --
    the seal cannot see it because it is next to outline, not coat. Filled in
    the tail's layer, since it is the tail's pose that makes it.
    """
    posed = dict(posed)
    xs = [c[0] for c in posed]
    ys = [c[1] for c in posed]
    while True:
        filled = False
        for cy in range(min(ys) - 1, max(ys) + 2):
            for cx in range(min(xs) - 1, max(xs) + 2):
                c = (cx, cy)
                if c in posed or c in base:
                    continue
                around = sum(a in posed or a in base for a in
                             ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)))
                if around >= 3:
                    posed[c] = OUTLINE
                    filled = True
        if not filled:
            return trim_spurs(base, posed)


def trim_spurs(base, posed):
    """Drops the one-cell nubs of outline a rotation leaves on the tail's edge.

    Turning a line that is a cell wide steps it, and a step can leave a lone
    outline cell hanging off the side, joined to the pet by one edge. It is
    only removed when that edge is outline too, so trimming can never leave
    coat against bare canvas.
    """
    posed = dict(posed)
    while True:
        spurs = []
        for c, f in posed.items():
            if f != OUTLINE or c in base:
                continue
            around = [a for a in ((c[0] + 1, c[1]), (c[0] - 1, c[1]),
                                  (c[0], c[1] + 1), (c[0], c[1] - 1))
                      if a in posed or a in base]
            if len(around) == 1 and (posed.get(around[0]) or base.get(around[0])) == OUTLINE:
                spurs.append(c)
        if not spurs:
            return posed
        for c in spurs:
            del posed[c]


def enclosed_outline(master):
    """Outline cells not 4-connected to the pet's outer edge: eyes, mouths, noses."""
    dark = {c for c, f in master.flat.items() if f == OUTLINE}
    outer = set()
    stack = [c for c in dark
             if any(a not in master.flat for a in
                    ((c[0] + 1, c[1]), (c[0] - 1, c[1]), (c[0], c[1] + 1), (c[0], c[1] - 1)))]
    while stack:
        c = stack.pop()
        if c in outer:
            continue
        outer.add(c)
        for a in ((c[0] + 1, c[1]), (c[0] - 1, c[1]), (c[0], c[1] + 1), (c[0], c[1] - 1)):
            if a in dark and a not in outer:
                stack.append(a)
    return dark - outer


def components(cells):
    cells, out = set(cells), []
    while cells:
        stack, comp = [cells.pop()], set()
        while stack:
            c = stack.pop()
            comp.add(c)
            for a in ((c[0] + 1, c[1]), (c[0] - 1, c[1]), (c[0], c[1] + 1), (c[0], c[1] - 1)):
                if a in cells:
                    cells.remove(a)
                    stack.append(a)
        out.append(comp)
    return sorted(out, key=lambda c: (min(y for _, y in c), min(x for x, _ in c)))
