"""Cuts the scenario stage's vet clinic backdrop out of the owner's art.

    python gen_clinic.py        # writes assets/svgs/scenario_doctor_backdrop.svg

The source is one whole room, `clinic-orthogonal (1).svg`, drawn far wider and
taller than the strip the chat docks above it. It is traced Inkscape output:
every edge axis-aligned, one shape per colour patch, on a 2-unit horizontal
and 1.6-unit vertical grid -- the art's pixel is 5:4, which is why the picture
looked stretched until the vertical was divided by 1.25.

Three things happen here, in this order.

1. RASTERISE.  Chrome renders the window at PPU pixels per source unit with
   `shape-rendering="crispEdges"`, so every edge lands on a whole pixel and the
   render comes back in the art's own 35 colours with no blends.  From here on
   the art is a grid, which is the only representation in which "make every
   border the same size" is a well-posed question.

2. RE-CUT THE OUTLINE.  The trace never had one outline thickness: 45% of its
   bands are 4 units and 26% are 6, in both directions, and dividing the
   vertical by 1.25 then left every horizontal band 20% thinner than every
   vertical one.  Each band is rebuilt as a fixed-width collar hanging off ONE
   of the two regions it separates -- the larger one, i.e. the wall or whatever
   sits behind.  Anchoring to a drawn edge rather than to the band's centreline
   is what keeps it crisp: the anchor edge never moves and the far edge is an
   exact chessboard offset of it, so straight stays straight and corners stay
   square.  Two details this must respect, both of which cost real damage when
   they were not:

     * Regions are labelled BEFORE the band is dissolved.  Label afterwards and
       two same-coloured shapes the outline keeps apart -- the hanging plant's
       leaves -- merge into one region, and the outline between them is erased.
     * The collar is a geodesic dilation confined to the band.  Let it dilate
       freely and it walks around the end of a band and eats the fill behind:
       the shelf board is thinner than one collar, so it fills solid.

   Bands are only ever thinned, never thickened, so no small fill can be
   swallowed -- except that horizontal bands are first dilated vertically by
   PRE, which undoes exactly what dividing the vertical by 1.25 did to them and
   is what lets the rebuild land on the art's own 4 units instead of having to
   settle for the thinnest band in the picture.  62% of the outline ends up at
   exactly 4.0 units, against 36% at the commonest value before; most of what
   is left over is corners, where a band is legitimately thicker than its run.

3. MIRROR THE DESK PLANT.  It was drawn 93% self-symmetric about its pot's
   centre and reads as lopsided because of the other 7%.  The left half is
   reflected across that axis, which squares it up without redrawing it.

The window is then run-length encoded into merged rectangles: 5.4k of them,
for about half the source's weight, because the source spends most of its bytes
on Inkscape ids, namespaces, nodetypes and separators SVG does not need.

CROP's left edge and bottom are the eye's: the wall just past the heart
picture, and a plank of floor below the desk's foot.  Its right edge is the
room's own.  What fixes the width is that a backdrop is drawn bottom-aligned
under `BoxFit.cover` and never stretched, so the aspect alone decides how much
survives on a phone: cut to 784x440, which is what the framing looks like to
the eye, and a 366x150 strip crops the top third away -- the shelf, the kit and
the awning with it.  At 2.34:1 a phone loses nothing but wall, and every
narrower or wider screen still keeps the desk, because the bottom is pinned.

Needs scipy, Pillow and Chrome.  Everything is done in a temp dir; the only
file written is the asset.
"""
import os
import shutil
import subprocess
import sys
import tempfile

import numpy as np
from PIL import Image
from scipy import ndimage

HERE = os.path.dirname(os.path.abspath(__file__))
SOURCE = os.path.join(HERE, 'clinic-orthogonal (1).svg')
TARGET = os.path.join(HERE, os.pardir, 'assets', 'svgs',
                      'scenario_doctor_backdrop.svg')

CHROME = os.environ.get('CHROME', r'C:\Program Files\Google\Chrome\Application\chrome.exe')

PPU = 5                 # raster pixels per source unit
OUTLINE = (0x13, 0x2b, 0x38)
BAND = 4.0              # every outline band ends up this thick, in source units
SOLID = 9.0             # dark runs thicker than this are solid shapes, not outline
PRE = 2                 # px of vertical pre-dilation; puts back what /1.25 took
MINCELL = 5             # px: anything too thin to hold this square is a sliver

WINDOW = (440, 0, 1672, 488)    # rasterised area, source units
CROP = (642, 24, 1672, 464)     # what the asset shows, source units. 2.34:1
PLANT_AXIS, PLANT_HW, PLANT_TOP, PLANT_BOT = 1322, 175, 880, 1295


def rasterise(tmp):
    """Render WINDOW of the source at PPU px/unit, via headless Chrome."""
    x0, y0, x1, y1 = WINDOW
    w, h = (x1 - x0) * PPU, (y1 - y0) * PPU
    svg = open(SOURCE, encoding='utf-8').read()
    svg = svg.replace('viewBox="0 0 1672 752.8"',
                      'viewBox="%d %d %d %d"' % (x0, y0, x1 - x0, y1 - y0), 1)
    svg = svg.replace('width="1672"', 'width="%d"' % w, 1)
    svg = svg.replace('height="752.8"', 'height="%d"' % h, 1)
    open(os.path.join(tmp, 'w.svg'), 'w', encoding='utf-8').write(svg)
    open(os.path.join(tmp, 'w.html'), 'w', encoding='utf-8').write(
        '<html><body style="margin:0"><img src="w.svg" '
        'style="width:%dpx;height:%dpx;display:block"></body></html>' % (w, h))
    png = os.path.join(tmp, 'w.png')
    subprocess.run([CHROME, '--headless', '--disable-gpu',
                    '--screenshot=' + png, '--window-size=%d,%d' % (w, h),
                    '--hide-scrollbars',
                    'file:///' + os.path.join(tmp, 'w.html').replace('\\', '/')],
                   check=True, capture_output=True)
    img = np.array(Image.open(png).convert('RGB'))
    if img.shape[:2] != (h, w):
        sys.exit('chrome returned %s, wanted %s' % (img.shape[:2], (h, w)))
    return img


def label_colours(img, mask_out):
    """Connected components of equal colour, with mask_out excluded."""
    key = ((img[:, :, 0].astype(np.int64) << 16)
           | (img[:, :, 1].astype(np.int64) << 8) | img[:, :, 2])
    labels = np.zeros(img.shape[:2], np.int32)
    n = 0
    for c in np.unique(key[~mask_out]):
        lab, k = ndimage.label((key == c) & ~mask_out)
        labels = np.where(lab > 0, lab + n, labels)
        n += k
    return labels, n


def renormalise(img):
    """Re-cut every outline band to BAND units. See step 2 in the docstring."""
    H, W, _ = img.shape
    sq = lambda r: np.ones((2 * r + 1, 2 * r + 1), bool)
    dark = np.all(img == np.array(OUTLINE, np.uint8), axis=2)
    if PRE:
        dark = ndimage.binary_dilation(dark, structure=np.ones((2 * PRE + 1, 1), bool))
        img = img.copy()
        img[dark] = OUTLINE

    solid = ndimage.binary_opening(dark, structure=sq(int(SOLID * PPU) // 2))
    band = dark & ~solid
    labels, n = label_colours(img, band)

    idx = ndimage.distance_transform_cdt(band, metric='chessboard',
                                         return_distances=False, return_indices=True)
    flat = img[idx[0], idx[1]]

    areas = np.bincount(labels.ravel(), minlength=n + 1)
    boxes = ndimage.find_objects(labels)
    steps = int(round(BAND * PPU))
    one = np.ones((3, 3), bool)
    newband = np.zeros((H, W), bool)
    claimed = np.zeros((H, W), bool)
    for r in sorted(range(1, n + 1), key=lambda i: -areas[i]):
        sl = boxes[r - 1]
        if sl is None:
            continue
        y0 = max(0, sl[0].start - steps - 1); y1 = min(H, sl[0].stop + steps + 1)
        x0 = max(0, sl[1].start - steps - 1); x1 = min(W, sl[1].stop + steps + 1)
        seed = labels[y0:y1, x0:x1] == r
        # a cross-section another region already anchored is off limits
        taken = ndimage.binary_dilation(newband[y0:y1, x0:x1], structure=one)
        road = band[y0:y1, x0:x1] & ~claimed[y0:y1, x0:x1] & ~taken
        reach = np.zeros_like(seed)
        front = seed
        for _ in range(steps):
            front = ndimage.binary_dilation(front, structure=one) & road & ~reach
            if not front.any():
                break
            reach |= front
        newband[y0:y1, x0:x1] |= reach
        claimed[y0:y1, x0:x1] |= seed | reach

    # a band that separates nothing -- a dead-end notch -- keeps its pixels
    comp, ncomp = ndimage.label(band, structure=one)
    touched = np.zeros(ncomp + 1, bool)
    touched[comp[newband]] = True

    out = flat.copy()
    out[newband] = OUTLINE
    out[solid] = OUTLINE
    out[band & ~touched[comp]] = OUTLINE
    return despeckle(out)


def despeckle(img):
    """Absorb hairline slivers left where a fill got squeezed by the re-cut."""
    H, W, _ = img.shape
    sq = lambda r: np.ones((2 * r + 1, 2 * r + 1), bool)
    key = ((img[:, :, 0].astype(np.int64) << 16)
           | (img[:, :, 1].astype(np.int64) << 8) | img[:, :, 2])
    for _ in range(4):
        labels = np.zeros((H, W), np.int32)
        n = 0
        for c in np.unique(key):
            lab, k = ndimage.label(key == c)
            labels = np.where(lab > 0, lab + n, labels)
            n += k
        thin = [r for r, sl in enumerate(ndimage.find_objects(labels), start=1)
                if sl is not None
                and not ndimage.binary_erosion(labels[sl] == r,
                                               structure=sq(MINCELL // 2)).any()]
        if not thin:
            break
        sliver = np.isin(labels, thin)
        src = ndimage.distance_transform_cdt(sliver, metric='chessboard',
                                             return_distances=False,
                                             return_indices=True)
        key = key[src[0], src[1]]
    return np.stack([(key >> 16) & 255, (key >> 8) & 255, key & 255],
                    axis=2).astype(np.uint8)


def mirror_plant(img):
    """Reflect the desk plant's left half across its pot centre."""
    ax = (PLANT_AXIS - WINDOW[0]) * PPU
    img[PLANT_TOP:PLANT_BOT, ax:ax + PLANT_HW] = \
        img[PLANT_TOP:PLANT_BOT, ax - PLANT_HW:ax][:, ::-1]
    return img


def to_svg(img):
    """Run-length encode CROP into merged rectangles, one path per colour."""
    x0, y0, x1, y1 = CROP
    sub = img[y0 * PPU:y1 * PPU, (x0 - WINDOW[0]) * PPU:(x1 - WINDOW[0]) * PPU]
    H, W, _ = sub.shape
    key = ((sub[:, :, 0].astype(np.int64) << 16)
           | (sub[:, :, 1].astype(np.int64) << 8) | sub[:, :, 2])
    bg = np.bincount(key.ravel()).argmax()

    rects, open_runs = [], {}
    for y in range(H):
        row = key[y]
        cut = np.flatnonzero(np.diff(row)) + 1
        cur = {(int(s), int(e), int(row[s])): True
               for s, e in zip(np.concatenate(([0], cut)),
                               np.concatenate((cut, [W])))
               if int(row[s]) != bg}
        for k in list(open_runs):
            if k not in cur:
                rects.append((k[0], open_runs.pop(k), k[1], y, k[2]))
        for k in cur:
            open_runs.setdefault(k, y)
    for k, yy in open_runs.items():
        rects.append((k[0], yy, k[1], H, k[2]))

    num = lambda v: (('%.1f' % (v / PPU)).rstrip('0').rstrip('.')) or '0'
    by = {}
    for rx0, ry0, rx1, ry1, c in rects:
        by.setdefault(c, []).append((rx0, ry0, rx1, ry1))
    out = ['<?xml version="1.0" encoding="UTF-8"?>',
           '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %s %s" '
           'shape-rendering="crispEdges">' % (num(W), num(H)),
           '<rect width="%s" height="%s" fill="#%06x"/>' % (num(W), num(H), bg)]
    for c, rs in sorted(by.items(), key=lambda kv: -len(kv[1])):
        out.append('<path fill="#%06x" d="%s"/>' % (c, ''.join(
            'M%s %sh%sv%sh-%sz' % (num(a), num(b), num(cc - a), num(d - b), num(cc - a))
            for a, b, cc, d in rs)))
    out.append('</svg>')
    return '\n'.join(out), len(rects)


def main():
    tmp = tempfile.mkdtemp(prefix='gen_clinic_')
    try:
        img = rasterise(tmp)
        img = renormalise(img)
        img = mirror_plant(img)
        svg, n = to_svg(img)
    finally:
        shutil.rmtree(tmp, ignore_errors=True)
    with open(TARGET, 'w', encoding='utf-8') as fh:
        fh.write(svg)
    print('%s\n  %dx%d units, aspect %.2f, %d rects, %.1f KB'
          % (os.path.normpath(TARGET), CROP[2] - CROP[0], CROP[3] - CROP[1],
             (CROP[2] - CROP[0]) / (CROP[3] - CROP[1]), n, len(svg) / 1024))


if __name__ == '__main__':
    main()
