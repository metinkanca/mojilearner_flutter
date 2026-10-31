"""Shared machinery for the pixel-art scene backdrops (cozy room, enchanted meadow).

A backdrop is drawn in an editable, layered SVG and shipped as a flat one. The
two are different files for a reason, and this module is the bridge:

  * the editable file is built for editing: an object is an outline plus its
    fills, side by side, in named layers;
  * the app's copy is built for drawing: one path per colour, each fill grown a
    pixel under the ink around it, so no two shapes share an edge and no
    hairline shows at a fractional scale (flutter_svg ignores crispEdges).

Going from one to the other goes through pixels. The editable file is rendered
exactly as a viewer shows it, the pixels are read as palette colours, and the
app's copy is traced from them. That makes the build indifferent to how an
editor happened to save the file: curves, transforms and style attributes all
come out as the pixels they paint.

Each scene is described by a [Palette]; a tiny build script per scene
(`build_cozy_room.py`, `build_enchanted_meadow.py`) is just a palette, two paths
and a call to [main].
"""
import argparse
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage as ndi

S4 = ndi.generate_binary_structure(2, 1)
S8 = ndi.generate_binary_structure(2, 2)

# How many places to list per kind of problem before saying "and N more".
LIST_LIMIT = 6

BROWSERS = [
    r'C:\Program Files\Google\Chrome\Application\chrome.exe',
    r'C:\Program Files (x86)\Google\Chrome\Application\chrome.exe',
    r'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe',
    r'C:\Program Files\Microsoft\Edge\Application\msedge.exe',
    '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
]


class Palette:
    """A scene's colours, in the order the app's copy paints them.

    The first is the underlay (a full-canvas rect) and the last is the ink,
    which sits on everything. Class ids are positions in this list.

    `cell` is the size, in pixels, of one square of the artwork's own pixel
    grid: 1 for the cozy room, which has none, and 2 for the meadow, which is
    drawn on a 2px grid. Repairs and checks work in cells, never pixels, or a
    legitimate two-pixel detail would look like a speck.

    `touching` lists pairs of fills that are meant to meet with no outline
    between them (the meadow's flower centres), so they are not reported as
    gaps in the outline.

    `spots` is (fill, host, label, hex): in the app's copy, the regions of
    `fill` that touch `host` get a fill of their own, painted just before it.
    The artwork is still drawn in these colours alone. This is for something
    the app has to treat differently from the rest of its colour: the glade's
    cream is the stems and the spots on the caps, and at night the spots keep
    their colour while the stems go dark. Shapes of one colour cannot be told
    apart in a recolour, so they are given two. Pick a hex a hair off `fill`
    that nobody can see the difference of; it is named in the scene's tint.
    """

    def __init__(self, colours, cell=1, touching=(), speck_px=12, fringe_px=2,
                 spots=None):
        self.labels = [label for label, _ in colours]
        self.hexes = [hx.lower() for _, hx in colours]
        self.ink = len(colours) - 1
        self.cell = cell
        self.touching = {frozenset(pair) for pair in touching}
        self.speck_px = speck_px
        self.fringe_px = fringe_px
        self.spots = spots
        self.by_hex = {hx: i for i, hx in enumerate(self.hexes)}

    def __len__(self):
        return len(self.hexes)

    def for_app(self, classes):
        """The classes and the palette the app's copy is written from: these
        ones, unless a fill is split in two (see `spots`)."""
        if not self.spots:
            return classes, self
        fill, host, label, hx = self.spots
        fill, host = self.labels.index(fill), self.labels.index(host)
        if fill >= host:
            sys.exit('the %s must be painted before the %s it is split on' % (
                self.labels[fill], self.labels[host]))
        colours = list(zip(self.labels, self.hexes))
        colours.insert(host, (label, hx))
        out = classes.copy()
        out[classes >= host] += 1
        regions, _ = ndi.label(classes == fill, structure=S4)
        touching = np.unique(regions[ndi.binary_dilation(classes == host, structure=S4)])
        out[np.isin(regions, touching[touching > 0])] = host
        return out, Palette(colours, cell=self.cell)

    def rgb(self, cls):
        hx = self.hexes[cls]
        return np.array([int(hx[i:i + 2], 16) for i in (1, 3, 5)], np.int32)

    def describe(self):
        return ', '.join('%s %s' % (l, h) for l, h in zip(self.labels, self.hexes))


COZY_ROOM = Palette([
    ('wall', '#f2e3c6'), ('wood', '#c58c56'), ('glass', '#a8dcef'),
    ('coral', '#e98a7b'), ('leaf', '#8cc56a'), ('ink', '#14120e'),
])

ENCHANTED_MEADOW = Palette([
    ('sky', '#d9c8f0'), ('ground', '#9a7cc8'), ('shade', '#70549b'),
    ('stone', '#f6f0dc'), ('gold', '#f0a93c'), ('mint', '#8fe3d0'),
    ('ink', '#14120e'),
], cell=2, touching=[(3, 4)])      # the flowers' off-white centres sit in gold

MUSHROOM_GLADE = Palette([
    ('sky', '#a8dcef'), ('moss', '#5db89a'), ('cream', '#f6f0dc'),
    ('cap', '#e8766a'), ('ink', '#14120e'),
], cell=2, touching=[(2, 3)],      # the caps' cream spots sit in the red
    spots=('cream', 'cap', 'spot', '#f6f0dd'))     # ...and are their own fill in the app

# Drawn on 3px cells (the outline is two of them). The stars are purple and the
# bubbles green straight onto the sky, with no outline, on purpose.
PUMPKIN_PATCH = Palette([
    ('sky', '#b99cd8'), ('grass', '#88ca62'), ('purple', '#58348d'),
    ('orange', '#fb8630'), ('yellow', '#f9df62'), ('ink', '#14120e'),
], cell=3, touching=[(0, 1), (0, 2)])

# The quiz classroom (gen_classroom.py). Wall, wood, coral, sky, leaf and ink
# are the cozy room's own, so the picture meets the flat wall and floor the
# quiz screen paints around it without a seam; the shelf's inside, the board
# and the eraser's felt are the owner's sheet's. One square of the art is one
# unit.
QUIZ_CLASSROOM = Palette([
    ('wall', '#f2e3c6'), ('wood', '#c58c56'), ('dark', '#a56e45'),
    ('board', '#3f6654'), ('coral', '#e98a7b'), ('sky', '#a8dcef'),
    ('leaf', '#8cc56a'), ('felt', '#76716d'), ('ink', '#14120e'),
], cell=1, speck_px=2)


# --- Reading and rasterising our own SVGs ------------------------------------
#
# Only for files this module wrote (and the cozy room's original, which uses the
# same dialect): `M h v z` paths with a fill attribute, no transforms. Anything
# an editor saves goes through the browser instead - see [render].

TOKEN = re.compile(r'([MmHhVvZz])|(-?\d+(?:\.\d+)?)')
ELEMENT = re.compile(r'<(rect|path)\b([^>]*?)/?>', re.S)


def attr(attrs, name):
    m = re.search(r'\b%s="([^"]*)"' % name, attrs)
    return m.group(1) if m else None


def read_elements(text, palette):
    """The rect / path elements in document order."""
    out = []
    for m in ELEMENT.finditer(text):
        attrs = m.group(2)
        fill = attr(attrs, 'fill').lower()
        if fill not in palette.by_hex:
            sys.exit('unexpected fill %s on %s' % (fill, attr(attrs, 'id')))
        out.append(dict(tag=m.group(1), id=attr(attrs, 'id'), cls=palette.by_hex[fill],
                        d=attr(attrs, 'd'), box=[int(attr(attrs, k) or 0) for k in
                                                 ('x', 'y', 'width', 'height')],
                        span=m.span()))
    return out


def vertical_edges(d):
    """(x, y0, y1) for every vertical edge of a path drawn with M h v z."""
    toks = TOKEN.findall(d)
    edges, i, x, y, sx, sy = [], 0, 0, 0, 0, 0
    while i < len(toks):
        cmd = toks[i][0]
        if not cmd:
            sys.exit('implicit command in path data')
        i += 1
        if cmd in 'Zz':
            # z closes with a straight edge; the source leans on that
            if x == sx and y != sy:
                edges.append((int(x), int(min(y, sy)), int(max(y, sy))))
            elif x != sx and y != sy:
                sys.exit('diagonal closing edge')
            x, y = sx, sy
            continue
        val = float(toks[i][1]); i += 1
        if cmd in 'Mm':
            if toks[i][0] == '' and toks[i][1]:      # M takes a pair
                y2 = float(toks[i][1]); i += 1
            else:
                sys.exit('bad M')
            x, y = (val, y2) if cmd == 'M' else (x + val, y + y2)
            sx, sy = x, y
        elif cmd in 'Hh':
            x = val if cmd == 'H' else x + val
        elif cmd in 'Vv':
            ny = val if cmd == 'V' else y + val
            edges.append((int(x), int(min(y, ny)), int(max(y, ny))))
            y = ny
        else:
            sys.exit('unsupported command ' + cmd)
    return edges


def rasterise(el, shape):
    """Boolean mask of an element, even-odd, on the integer pixel grid."""
    h, w = shape
    if el['tag'] == 'rect':
        x, y, rw, rh = el['box']
        m = np.zeros(shape, bool)
        m[y:y + rh, x:x + rw] = True
        return m
    toggle = np.zeros((h, w + 1), np.uint8)
    for x, y0, y1 in vertical_edges(el['d']):
        toggle[y0:y1, x] ^= 1
    return np.cumsum(toggle, axis=1)[:, :w] % 2 == 1


def paint(elements, masks, shape):
    """What a viewer would show: later elements over earlier ones."""
    out = np.full(shape, -1, np.int8)
    for el, m in zip(elements, masks):
        out[m] = el['cls']
    return out


# --- Writing the app's copy --------------------------------------------------

def loops(mask):
    """Closed boundary loops of a mask, as vertex lists with interior on the right."""
    m = np.pad(mask, 1)
    inner = m[1:-1, 1:-1]
    nxt = {}

    def put(ys, xs, p, q):
        for y, x in zip(ys.tolist(), xs.tolist()):
            nxt.setdefault((x + p[0], y + p[1]), []).append((x + q[0], y + q[1]))

    put(*np.nonzero(inner & ~m[:-2, 1:-1]), (0, 0), (1, 0))      # top
    put(*np.nonzero(inner & ~m[1:-1, 2:]), (1, 0), (1, 1))       # right
    put(*np.nonzero(inner & ~m[2:, 1:-1]), (1, 1), (0, 1))       # bottom
    put(*np.nonzero(inner & ~m[1:-1, :-2]), (0, 1), (0, 0))      # left

    result = []
    while nxt:
        start = next(iter(nxt))
        path, cur, prev = [start], start, None
        while True:
            options = nxt[cur]
            if len(options) > 1 and prev is not None:
                # a corner-to-corner touch: take the sharpest right turn
                din = (cur[0] - prev[0], cur[1] - prev[1])
                right = (-din[1], din[0])
                options.sort(key=lambda o: -((o[0] - cur[0]) * right[0] + (o[1] - cur[1]) * right[1]))
            step = options.pop(0)
            if not options:
                del nxt[cur]
            prev, cur = cur, step
            if cur == start:
                break
            path.append(cur)
        result.append(path)
    return result


def path_data(mask, origin=(0, 0)):
    """Compact M/h/v/z data for a mask, even-odd. `origin` shifts the start
    point, for an element that lives in a translated group."""
    parts = []
    for pts in loops(mask):
        n = len(pts)
        # keep only the corners: a vertex where the edge direction changes
        keep = []
        for i in range(n):
            a, b, c = pts[i - 1], pts[i], pts[(i + 1) % n]
            if (b[0] - a[0]) * (c[1] - b[1]) != (b[1] - a[1]) * (c[0] - b[0]):
                keep.append(b)
        if not keep:
            continue
        # start at the top-left-most corner so the output is deterministic
        i0 = min(range(len(keep)), key=lambda i: (keep[i][1], keep[i][0]))
        keep = keep[i0:] + keep[:i0]
        s = 'M%d %d' % (keep[0][0] - origin[0], keep[0][1] - origin[1])
        # the last edge back to the start is implied by the z
        for a, b in zip(keep, keep[1:]):
            dx, dy = b[0] - a[0], b[1] - a[1]
            s += ('h%d' % dx) if dy == 0 else ('v%d' % dy)
        parts.append(s + 'z')
    return ' '.join(parts)


BLEED = np.ones((3, 3), bool)


def asset_svg(classes, palette):
    """The app's copy of a class image: one path per colour, painted in the
    palette's order over the first colour as the underlay, the ink last.

    Shapes that merely touched would show a hairline of whatever is beneath
    them at a fractional scale, so each fill is grown by one pixel into the
    ink around it and into any fill it meets directly, and the ink is drawn
    over the top. The grown part is always hidden by what is painted over it.

    It is grown by one pixel and no more, and only into the ink and into fills
    painted after it. Painting each colour under *everything* above it is the
    simpler scheme and an easy one to get wrong: it puts every fill under every
    outline, so the topmost fill shows through the antialiased edge of every
    line. A thin outline covers only part of a screen pixel at phone size, so
    that was a pale fringe along all of them (the crystals' mint, which at
    night is nearly white).

    Re-reads its own output and checks it reproduces `classes`, so a tracing
    bug cannot ship quietly.
    """
    h, w = classes.shape
    shapes = ['<rect width="%d" height="%d" fill="%s"/>' % (w, h, palette.hexes[0])]
    for cls in range(1, len(palette)):
        region = classes == cls
        if cls != palette.ink:
            region |= ndi.binary_dilation(region, structure=BLEED) & (classes >= cls)
        shapes.append('<path fill="%s" fill-rule="evenodd" d="%s"/>' % (
            palette.hexes[cls], path_data(region)))
    text = ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %d %d" '
            'shape-rendering="crispEdges">%s</svg>\n' % (w, h, ''.join(shapes)))
    els = read_elements(text, palette)
    if not (paint(els, [rasterise(e, classes.shape) for e in els], classes.shape) == classes).all():
        sys.exit('app output does not reproduce the image')
    return text


# --- Rendering an editor's SVG -----------------------------------------------

def find_browser():
    for candidate in [os.environ.get('BROWSER', '')] + BROWSERS + [
            shutil.which(n) or '' for n in ('chrome', 'google-chrome', 'chromium', 'msedge')]:
        if candidate and Path(candidate).exists():
            return candidate
    sys.exit('no Chrome or Edge found to render the SVG with; set BROWSER=<path to chrome.exe>')


def view_size(text):
    m = re.search(r'<svg\b[^>]*\bviewBox="\s*[-\d.]+[ ,]+[-\d.]+[ ,]+([\d.]+)[ ,]+([\d.]+)"', text)
    if not m:
        m = re.search(r'<svg\b[^>]*\bwidth="([\d.]+)(?:px)?"[^>]*\bheight="([\d.]+)(?:px)?"', text)
    if not m:
        sys.exit('cannot find the size of the picture (no viewBox on the <svg>)')
    return round(float(m.group(1))), round(float(m.group(2)))


def render(src):
    """The file as a viewer shows it, one pixel per viewBox unit, no smoothing."""
    text = src.read_text(encoding='utf-8')
    w, h = view_size(text)
    root = re.search(r'<svg\b[^>]*>', text).group(0)
    if 'shape-rendering' not in root:
        # an editor may drop the attribute; without it the edges antialias
        text = text.replace('<svg', '<svg shape-rendering="crispEdges"', 1)
    with tempfile.TemporaryDirectory(prefix='scene_art_') as tmp:
        tmp = Path(tmp)
        (tmp / 'room.svg').write_text(text, encoding='utf-8')
        (tmp / 'page.html').write_text(
            '<html><body style="margin:0"><img src="room.svg" '
            'style="display:block;width:%dpx;height:%dpx"></body></html>' % (w, h))
        shot = tmp / 'shot.png'
        subprocess.run(
            [find_browser(), '--headless', '--disable-gpu', '--hide-scrollbars',
             '--force-device-scale-factor=1', '--user-data-dir=' + str(tmp / 'profile'),
             '--screenshot=' + str(shot), '--window-size=%d,%d' % (w, h),
             (tmp / 'page.html').as_uri()],
            capture_output=True, timeout=120)
        if not shot.exists():
            sys.exit('the browser produced no picture')
        img = Image.open(shot).convert('RGB')
        if img.size != (w, h):
            sys.exit('rendered %dx%d, expected %dx%d' % (img.size + (w, h)))
        return np.array(img)


def quantise(rgb, palette, snap):
    """Pixels -> palette classes. Returns None, after saying why, if any are strangers."""
    classes = np.full(rgb.shape[:2], -1, np.int8)
    for cls in range(len(palette)):
        classes[(rgb == palette.rgb(cls)).all(-1)] = cls
    stray = classes < 0
    if not stray.any():
        return classes
    if snap:
        d = np.stack([((rgb[stray].astype(np.int32) - palette.rgb(c)) ** 2).sum(-1)
                      for c in range(len(palette))])
        classes[stray] = d.argmin(0)
        print('snapped %d off-palette pixels to the nearest scene colour' % stray.sum())
        return classes
    colours, counts = np.unique(rgb[stray].reshape(-1, 3), axis=0, return_counts=True)
    print("STOPPED: %d pixels are not one of the scene's %d colours." % (stray.sum(), len(palette)))
    for i in np.argsort(-counts)[:5]:
        mask = (rgb == colours[i]).all(-1)
        ys, xs = np.nonzero(mask)
        print('  #%02x%02x%02x  %d px, first at x=%d y=%d' % (*colours[i], counts[i], xs[0], ys[0]))
    print('Use only: %s.\nOr pass --snap to round strays to the nearest one.' % palette.describe())
    return None


# --- Checking an edit --------------------------------------------------------

def find_leaks(cells, palette):
    """Cells either side of a fill-to-fill contact with no outline between,
    other than the contacts the scene means to have."""
    leak = np.zeros(cells.shape, bool)
    h, w = cells.shape
    for dy, dx in ((0, 1), (1, 0)):
        a, b = cells[:h - dy, :w - dx], cells[dy:, dx:]
        hit = (a != b) & (a != palette.ink) & (b != palette.ink)
        if palette.touching:
            hit &= ~np.isin(a * len(palette) + b, [
                x * len(palette) + y for p in palette.touching for x in p for y in p if x != y])
        leak[:h - dy, :w - dx] |= hit
        leak[dy:, dx:] |= hit
    return leak


def find_fringe(cells, palette):
    """Thin stray colour that touches a different non-ink colour: the signature
    of an antialiasing rim that got quantised."""
    size = palette.fringe_px // palette.cell + 1
    square = np.ones((size, size), bool)
    fringe = np.zeros(cells.shape, bool)
    for cls in range(len(palette) - 1):
        m = cells == cls
        thin = m & ~ndi.binary_opening(m, structure=square)
        other = np.zeros(cells.shape, bool)
        for cj in range(len(palette) - 1):
            if cj != cls and frozenset((cls, cj)) not in palette.touching:
                other |= ndi.binary_dilation(cells == cj, structure=S8)
        fringe |= thin & other
    return fringe


def blobs(mask, structure, scale):
    """Where each blob of `mask` starts, in pixels, as 'x=.. y=..' strings."""
    lab, _ = ndi.label(mask, structure=structure)
    return ['x=%d y=%d' % (sl[1].start * scale, sl[0].start * scale)
            for sl in ndi.find_objects(lab)]


def lint(classes, palette):
    """What looks wrong in an image, as (description, [places]) pairs."""
    k = palette.cell
    found = []
    h, w = classes.shape
    if k > 1:
        quads = classes[:h // k * k, :w // k * k].reshape(h // k, k, w // k, k).transpose(0, 2, 1, 3)
        quads = quads.reshape(h // k, w // k, k * k)
        mixed = (quads != quads[..., :1]).any(-1)
        if mixed.any():
            found.append(('pixels off the %dpx grid the artwork is drawn on' % k,
                          blobs(mixed, S8, k)))
        cells = quads[..., 0]
    else:
        cells = classes
    leaks = blobs(find_leaks(cells, palette), S8, k)
    if leaks:
        found.append(('outline gaps (a fill touches another colour with no ink between)', leaks))
    limit = max(1, palette.speck_px // (k * k))
    for cls, label in enumerate(palette.labels):
        mask = cells == cls
        lab, n = ndi.label(mask, structure=S4)
        small = set((np.nonzero(ndi.sum(mask, lab, range(1, n + 1)) <= limit)[0] + 1).tolist())
        spots = ['x=%d y=%d' % (sl[1].start * k, sl[0].start * k)
                 for i, sl in enumerate(ndi.find_objects(lab), 1) if i in small]
        if spots:
            found.append(('stray %s specks (tiny isolated bits)' % label, spots))
    fringe = blobs(find_fringe(cells, palette), S8, k)
    if fringe:
        found.append(('stray colour fringe next to an outline', fringe))
    return found


# --- The command line --------------------------------------------------------

def build(src, out, palette, snap, after=None):
    started = time.time()
    classes = quantise(render(src), palette, snap)
    if classes is None:
        return False
    problems = lint(classes, palette)
    asset = asset_svg(*palette.for_app(classes))
    changed = not out.exists() or out.read_text(encoding='utf-8') != asset
    if changed:
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(asset, encoding='utf-8')
    for what, spots in problems:
        shown = ', '.join(spots[:LIST_LIMIT]) + (' and %d more' % (len(spots) - LIST_LIMIT)
                                                  if len(spots) > LIST_LIMIT else '')
        print('  heads up: %d %s: %s' % (len(spots), what, shown))
    print('%s %s (%d bytes) from %s in %.1fs%s' % (
        'wrote' if changed else 'unchanged:', out.name, len(asset.encode()), src.name,
        time.time() - started, '' if problems else '; no outline problems found'))
    if after is not None:
        after(classes)
    return True


def main(palette, default_src, default_out, what, after=None):
    """`after`, if given, is called with the built picture's classes after
    every build: for a scene whose numbers something else reads."""
    ap = argparse.ArgumentParser(description="Rebuild the app's %s from the SVG you edit." % what)
    ap.add_argument('svg', nargs='?', type=Path, default=default_src, help='the file you edit')
    ap.add_argument('--out', type=Path, default=default_out, help='where to write the app copy')
    ap.add_argument('--watch', action='store_true', help='rebuild every time the file is saved')
    ap.add_argument('--snap', action='store_true', help='round stray colours to the nearest palette colour')
    opts = ap.parse_args()
    src, out = opts.svg, opts.out
    if not src.exists():
        sys.exit('%s not found' % src)

    built = build(src, out, palette, opts.snap, after)
    if not opts.watch:
        sys.exit(0 if built else 1)
    print('watching %s - save it to rebuild, Ctrl+C to stop' % src.name)
    seen = src.stat().st_mtime
    try:
        while True:
            time.sleep(0.7)
            now = src.stat().st_mtime
            if now != seen:
                time.sleep(0.5)             # let the editor finish writing
                seen = src.stat().st_mtime
                build(src, out, palette, opts.snap, after)
    except KeyboardInterrupt:
        print('stopped')
