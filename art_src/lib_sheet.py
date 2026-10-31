"""Reading a UI sheet from the owner's image tool, shared by gen_sand_ui.py,
gen_crystal_ui.py and the sheets to come.

The tool draws pixel art on a magenta ground, but upscales it by a fractional
amount and saves a JPEG (it cannot save a PNG): the cells come out 5 to 12
pixels square with soft, noisy edges, and each sheet's size differs. A sheet's
cell is found once with `fit` (the edges of the picture line up on it), written
into the sheet's script as constants, and then `sample` reads every cell as the
median colour of the middle of its block and snaps it to the sheet's palette
-- with every near-black folded into the outline colour, which is where nearly
all the JPEG noise is.

The rest is what every sheet does with the cells: cut a piece out, flood-fill
the face words are written on, and mimic how the game stretches a piece
(`stretch`, the same as `PixelSprite._source`) so it can be looked at before
Flutter is run.
"""
import numpy as np
from PIL import Image

GROUND = '.'


def hex_rgb(h):
    return tuple(int(h[i:i + 2], 16) for i in (1, 3, 5))


def _magenta(a):
    return (a[..., 0] > 200) & (a[..., 1] < 90) & (a[..., 2] > 200)


def fit(path):
    """The sheet's cell: ((width, offset), (height, offset)) in pixels, found
    by searching for the spacing and phase at which the most of the picture's
    edge energy falls on cell boundaries. Slow (a minute); run once and keep
    the answer."""
    a = np.asarray(Image.open(path).convert('RGB')).astype(float)
    a[_magenta(a)] = 0
    energy = (np.abs(np.diff(a, axis=1)).sum(axis=2).sum(axis=0),
              np.abs(np.diff(a, axis=0)).sum(axis=2).sum(axis=1))

    def score(g, p, o):
        n = len(g)
        idx = np.round(o + p * np.arange(int((n - o) / p) + 1)).astype(int) - 1
        idx = idx[(idx >= 0) & (idx < n)]
        near = np.zeros(n, bool)
        for d in (-1, 0, 1):
            j = idx + d
            near[j[(j >= 0) & (j < n)]] = True
        return g[near].sum() / g.sum()

    out = []
    for g in energy:
        # Coarse, with the share a random grid would score taken off, then
        # fine round the best.
        coarse = max((max(score(g, p, o) for o in np.arange(0, p, .5)) - 3 / p,
                      p) for p in np.arange(3., 16., .05))[1]
        best = max((score(g, p, o), p, o)
                   for p in np.arange(coarse - .12, coarse + .12, .005)
                   for o in np.arange(0, coarse, .2))
        out.append((round(best[1], 3), round(best[2], 1), round(best[0], 3)))
    return out


def sample(path, tones, cell, dark=48, tinted_ground=False):
    """The sheet as rows of letters, one a cell; GROUND where it is magenta.
    [cell] is ((width, x offset), (height, y offset)) from `fit`; [tones]
    maps a letter to its colour, and K must be the outline's. With
    [tinted_ground], a cell whose colour is mostly magenta -- a soft glow the
    tool drew over the ground, which blends to pink -- is ground too."""
    (cw, ox), (ch, oy) = cell
    a = np.asarray(Image.open(path).convert('RGB')).astype(float)
    h, w, _ = a.shape
    mag = _magenta(a)
    letters = list(tones)
    rgb_of = np.array([hex_rgb(tones[k]) for k in letters], float)
    grid = []
    for j in range(int((h - oy) / ch)):
        line = []
        for i in range(int((w - ox) / cw)):
            xa, xb = int(ox + (i + .25) * cw), int(ox + (i + .75) * cw) + 1
            ya, yb = int(oy + (j + .25) * ch), int(oy + (j + .75) * ch) + 1
            blk = a[ya:yb, xa:xb]
            if blk.size == 0 or mag[ya:yb, xa:xb].mean() > .5:
                line.append(GROUND)
                continue
            rgb = np.median(blk.reshape(-1, 3), axis=0)
            if tinted_ground and rgb[0] > 150 and rgb[2] > 150 and rgb[1] < 125:
                line.append(GROUND)
                continue
            if rgb.max() < dark:
                line.append('K')
            else:
                line.append(letters[int(((rgb_of - rgb) ** 2).sum(1).argmin())])
        grid.append(line)
    return grid


def pieces_of(sheet, min_cells=25):
    """The boxes (x0, y0, x1, y1, cells) of the separate pieces on the sheet,
    top to bottom: runs of cells that touch, corners included."""
    h, w = len(sheet), len(sheet[0])
    seen = set()
    boxes = []
    for y in range(h):
        for x in range(w):
            if sheet[y][x] == GROUND or (x, y) in seen:
                continue
            todo, pts = [(x, y)], []
            seen.add((x, y))
            while todo:
                cx, cy = todo.pop()
                pts.append((cx, cy))
                for dx in (-1, 0, 1):
                    for dy in (-1, 0, 1):
                        n = (cx + dx, cy + dy)
                        if (0 <= n[0] < w and 0 <= n[1] < h and n not in seen
                                and sheet[n[1]][n[0]] != GROUND):
                            seen.add(n)
                            todo.append(n)
            if len(pts) >= min_cells:
                xs, ys = [p[0] for p in pts], [p[1] for p in pts]
                boxes.append((min(xs), min(ys), max(xs) + 1, max(ys) + 1,
                              len(pts)))
    return sorted(boxes, key=lambda b: (b[1] // 40, b[0]))


def cut(sheet, box):
    """The piece in [box] (cells x0, y0, x1, y1) as rows of letters."""
    x0, y0, x1, y1 = box[:4]
    return [list(''.join(sheet[y][x0:x1])) for y in range(y0, y1)]


def flood(rows, seed, src='F', dst='W'):
    """[rows] with the [src] cells 4-connected to [seed] lettered [dst]."""
    sx, sy = seed
    assert rows[sy][sx] == src, (seed, rows[sy][sx])
    todo = [(sx, sy)]
    while todo:
        x, y = todo.pop()
        if not (0 <= y < len(rows) and 0 <= x < len(rows[y])):
            continue
        if rows[y][x] != src:
            continue
        rows[y][x] = dst
        todo += [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]


def face_box(rows):
    """Where the W cells are: (left, top, right, bottom) in cells."""
    xs = [x for r in rows for x, c in enumerate(r) if c == 'W']
    ys = [y for y, r in enumerate(rows) if 'W' in r]
    return min(xs), min(ys), max(xs) + 1, max(ys) + 1


def same_rows(rows, a, b, template):
    """Rows [a, b) all made like row [template]."""
    for y in range(a, b):
        rows[y] = list(rows[template])


def source(d, to, n, mid):
    """Which of its n columns (or rows) draws column d of to: the same as
    PixelSprite._source."""
    if to == n:
        return d
    if mid is None:
        return min(max(d * n // to, 0), n - 1)
    a, b = mid
    tail = n - b
    if to < a + tail:
        left = round(to * a / (a + tail))
        return d if d < left else n - (to - d)
    if d < a:
        return d
    if d >= to - tail:
        return n - (to - d)
    return a + (d - a) % (b - a)


def stretch(piece, cols, rows):
    """The piece, a (rows, midX, midY), drawn [cols] by [rows] cells."""
    r, mid_x, mid_y = piece
    n_w, n_h = len(r[0]), len(r)
    return [''.join(r[source(y, rows, n_h, mid_y)][source(x, cols, n_w, mid_x)]
                    for x in range(cols))
            for y in range(rows)]


def whole(n, size, mid):
    """[n] cells cut back to where the piece's repeating run of [mid] has
    repeated a whole number of times: PixelSprite.paintTiled(wholeX: true)."""
    if mid is None:
        return n
    a, b = mid
    ends = size - (b - a)
    return n if n <= ends else ends + (n - ends) // (b - a) * (b - a)


def png(rows, scale, path, tones, ground=(255, 0, 255)):
    """[rows] as a PNG, [scale] pixels a cell."""
    rgb = {k: hex_rgb(v) for k, v in tones.items()}
    rgb['W'] = rgb['F']
    rgb[GROUND] = ground
    im = Image.new('RGB', (len(rows[0]), len(rows)))
    for y, r in enumerate(rows):
        for x, c in enumerate(r):
            im.putpixel((x, y), rgb[c])
    im.resize((im.width * scale, im.height * scale),
              Image.NEAREST).save(path)


def channel(groove, outline='K'):
    """Where a timer's fill goes in its groove, in cells: the rows of
    channel at the groove's middle column, from its top and from its foot,
    and the column the channel's narrowest row starts at. One cell of the
    channel is left round the fill on every side."""
    rows = groove[0]
    mid = len(rows[0]) // 2
    first = last = len(rows) // 2
    assert rows[first][mid] == outline, 'the groove has no channel at its middle'
    while rows[first - 1][mid] == outline:
        first -= 1
    while rows[last + 1][mid] == outline:
        last += 1
    top, bottom = first + 1, len(rows) - last
    side = max(r.index(outline, 3) for r in rows[top:last]) + 1
    return top, bottom, side


def halve(rows):
    """[rows] (strings) at half resolution: each 2x2 block becomes the letter
    most of it is, the outline K winning ties so lines never break, then
    anything over empty. An odd last row or column is padded with empty first,
    so the outline along it survives. (gen_fire_ui.py's, for a sheet's piece
    that is drawn smaller than the sheet draws it.)"""
    if len(rows[0]) % 2:
        rows = [r + GROUND for r in rows]
    if len(rows) % 2:
        rows = rows + [GROUND * len(rows[0])]
    h, w = len(rows), len(rows[0])
    out = []
    for y in range(0, h - 1, 2):
        row = ''
        for x in range(0, w - 1, 2):
            block = [rows[y][x], rows[y][x + 1],
                     rows[y + 1][x], rows[y + 1][x + 1]]
            counts = {c: block.count(c) for c in block}
            top = max(counts.values())
            best = [c for c, n in counts.items() if n == top]
            if len(best) > 1 and 'K' in best:
                row += 'K'
            elif len(best) > 1 and GROUND in best:
                row += [c for c in best if c != GROUND][0]
            else:
                row += best[0]
        out.append(row)
    return out


def cells_svg(items, scale=8, wrap=200, gap=4, ground='#ff00ff'):
    """A sheet of pieces as an SVG, one cell a unit: each item, a (name,
    rows, tones, note), is a `<g id=name>` of one path a colour, laid out in
    rows of at most [wrap] cells with [gap] between, on a ground of the
    magenta the tool draws on. Cells are drawn as runs so the pieces stay
    crisp at any zoom; W is drawn as F, the face. [note] goes in the group's
    `<desc>`, for what an editor cannot see (where a piece repeats)."""
    placed, x, y, row_h, width = [], gap, gap, 0, 0
    for name, rows, tones, note in items:
        w, h = len(rows[0]), len(rows)
        if x + w + gap > wrap and x > gap:
            x, y, row_h = gap, y + row_h + gap, 0
        placed.append((name, rows, tones, note, x, y))
        x += w + gap
        row_h = max(row_h, h)
        width = max(width, x)
    height = y + row_h + gap
    out = ['<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %d %d" '
           'width="%d" height="%d" shape-rendering="crispEdges">'
           % (width, height, width * scale, height * scale),
           '<rect id="ground" width="%d" height="%d" fill="%s"/>'
           % (width, height, ground)]
    for name, rows, tones, note, ox, oy in placed:
        colours = dict(tones)
        colours['W'] = tones['F']
        paths = {}
        for cy, r in enumerate(rows):
            cx = 0
            while cx < len(r):
                c = r[cx]
                run = 1
                while cx + run < len(r) and r[cx + run] == c:
                    run += 1
                if c != GROUND:
                    paths.setdefault(colours[c], []).append(
                        'M%d %dh%dv1h-%dz' % (cx, cy, run, run))
                cx += run
        out.append('<g id="%s" transform="translate(%d %d)">' % (name, ox, oy))
        if note:
            out.append('<desc>%s</desc>' % note)
        for fill, d in paths.items():
            out.append('<path fill="%s" d="%s"/>' % (fill, ''.join(d)))
        out.append('</g>')
    out.append('</svg>')
    return '\n'.join(out) + '\n'
