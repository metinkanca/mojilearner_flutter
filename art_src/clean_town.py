"""Cleans up the ORIGINAL town art (assets/svgs/city_*.svg) without redrawing it.

The owner's town was cut from a picture, so its borders wobble: outlines change
thickness along their length, windows and quoins are notched, bushes have ink
specks, doors have stray bits.  This reads each SVG back onto its cell grid,
smooths the label map (every colour is a label; transparent is one too), and
re-emits it with the same viewBox, so it is a drop-in for the same file.

  python art_src/clean_town.py            # review copies -> art_src/pxl/out/clean/
  python art_src/clean_town.py --ship     # overwrite assets/svgs/city_*.svg (keeps *.orig in art_src/town_orig/)

The smoothing is a Gaussian blur of every label's indicator followed by an argmax,
so features of two cells and more survive and 1-cell wobble does not.  Ink gets a
small extra weight so a two-cell outline keeps its width.
"""
import os
import shutil
import subprocess
import sys

import numpy as np
from PIL import Image
from scipy import ndimage as ndi

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
SVGS = os.path.join(HERE, '..', 'assets', 'svgs')
OUT = os.path.join(HERE, 'pxl', 'out', 'clean')
ORIG = os.path.join(HERE, 'town_orig')
CHROME = r'C:\Program Files\Google\Chrome\Application\chrome.exe'
NAMES = ['city_ground', 'city_office', 'city_school', 'city_restaurant', 'city_shop',
         'city_clinic', 'city_cafe', 'city_kiosk']
INK = (0x05, 0x04, 0x03)           # the original art's ink
PET_INK = (0x1f, 0x22, 0x23)       # what it is redrawn in: the pets' outline
MAGENTA = (255, 0, 255)
SCALE = 4


def viewbox(svg):
    import re
    m = re.search(r'viewBox="0 0 (\d+) (\d+)"', open(svg, encoding='utf-8').read())
    return int(m.group(1)), int(m.group(2))


def render(svg, tmp):
    """The SVG on a magenta page, 4 px to a cell; the colour at each cell's middle."""
    w, h = viewbox(svg)
    html = os.path.join(tmp, 'page.html')
    png = os.path.join(tmp, 'page.png')
    with open(html, 'w') as f:
        f.write('<html><body style="margin:0;background:#ff00ff"><img src="file:///%s" '
                'style="display:block;width:%dpx;height:%dpx"></body></html>'
                % (os.path.abspath(svg).replace('\\', '/'), w * SCALE, h * SCALE))
    if os.path.exists(png):
        os.remove(png)
    subprocess.run([CHROME, '--headless', '--disable-gpu', '--hide-scrollbars',
                    '--screenshot=' + png, '--window-size=%d,%d' % (w * SCALE, h * SCALE),
                    'file:///' + html.replace('\\', '/')], capture_output=True, check=True)
    im = np.array(Image.open(png).convert('RGB'))
    mid = SCALE // 2
    return im[mid:h * SCALE:SCALE, mid:w * SCALE:SCALE][:h, :w]


def to_labels(rgb):
    """Colour cells -> label ints (-1 transparent) and the palette."""
    flat = rgb.reshape(-1, 3)
    cols, inv = np.unique(flat, axis=0, return_inverse=True)
    pal = [tuple(int(v) for v in c) for c in cols]
    labels = inv.reshape(rgb.shape[:2]).astype(int)
    # tiny colours are antialiasing leftovers: fold them into the nearest big one
    counts = np.bincount(inv, minlength=len(pal))
    big = [i for i, n in enumerate(counts) if n >= 12 or pal[i] in (MAGENTA, INK)]
    remap = {}
    for i, c in enumerate(pal):
        if i in big:
            remap[i] = i
        else:
            remap[i] = min(big, key=lambda j: sum((a - b) ** 2 for a, b in zip(c, pal[j])))
    labels = np.vectorize(remap.get)(labels)
    return labels, pal


def rebuild(labels, pal, width=2, speck=20, sigma=0.9):
    """Re-derive the ink: fill every outline with the colour beside it (so the
    boundary falls down the middle of the old line), then draw one even line of
    `width` cells wherever the old art had one; keep interior lines (the same
    colour on both sides: window bars, joints) minus the specks."""
    ink_id = pal.index(INK)
    clear_id = pal.index(MAGENTA) if MAGENTA in pal else -2
    obj = labels != clear_id
    ink = labels == ink_id
    # big dark masses (a door's shadow) are drawn that way on purpose: keep their core
    deep = ndi.distance_transform_edt(ink) >= 2.5
    mass = ndi.binary_dilation(deep, iterations=2) & ink
    solid = obj & ~ink
    idx = ndi.distance_transform_edt(~solid, return_indices=True)[1]
    reg = labels[idx[0], idx[1]]
    reg[~obj] = clear_id
    if sigma:
        ids = np.unique(reg)
        stack = [ndi.gaussian_filter((reg == i).astype(float), sigma, mode='nearest') for i in ids]
        reg = ids[np.argmax(np.stack(stack), axis=0)]
        obj = reg != clear_id
    h, w = reg.shape
    pad = np.pad(reg, 1, mode="edge")
    differs = np.zeros(reg.shape, bool)
    for dy, dx in ((-1, 0), (1, 0), (0, -1), (0, 1)):
        differs |= pad[1 + dy:1 + dy + h, 1 + dx:1 + dx + w] != reg
    near_ink = ndi.binary_dilation(ink, iterations=2)
    # boundaries between two coloured regions: one cell each side, where the old art had ink
    edge_in = differs & obj & near_ink
    outside = np.zeros_like(obj)
    for dy, dx in ((-1, 0), (1, 0), (0, -1), (0, 1)):
        outside |= (pad[1 + dy:1 + dy + h, 1 + dx:1 + dx + w] == clear_id)
    rim = obj & outside
    new_ink = edge_in | rim
    if width >= 2:
        # the silhouette gets its second cell inside (nothing outside to take it)
        new_ink |= ndi.binary_dilation(rim, structure=ndi.generate_binary_structure(2, 1)) & obj
    # interior lines: old ink with the same colour either side (the filled map is
    # constant in a 5x5 window round it): window bars, steps, paving joints
    lo = ndi.minimum_filter(reg, size=5)
    hi = ndi.maximum_filter(reg, size=5)
    kept = ink & (lo == hi)
    interior = np.zeros_like(ink)
    lab2, n2 = ndi.label(kept, structure=np.ones((3, 3)))
    if n2:
        sizes = ndi.sum(kept, lab2, range(1, n2 + 1))
        for k, sz in enumerate(sizes, start=1):
            if sz >= speck:
                interior |= lab2 == k
    final = reg.copy()
    final[new_ink | interior | mass] = ink_id
    final[~obj] = clear_id
    return final


def to_image(labels, pal):
    h, w = labels.shape
    out = np.zeros((h, w, 4), np.uint8)
    for i, c in enumerate(pal):
        if c == MAGENTA:
            continue
        out[labels == i, :3] = PET_INK if c == INK else c
        out[labels == i, 3] = 255
    return Image.fromarray(out, 'RGBA')


def ink_runs(labels, pal):
    """Histogram of horizontal+vertical ink run lengths, to measure line weight."""
    if INK not in pal:
        return {}
    ink = labels == pal.index(INK)
    runs = {}
    for arr in (ink, ink.T):
        for row in arr:
            n = 0
            for v in list(row) + [False]:
                if v:
                    n += 1
                elif n:
                    runs[n] = runs.get(n, 0) + 1
                    n = 0
    return runs


def clean(name, tmp, sigma, ink_weight, passes):
    svg = os.path.join(ORIG if os.path.exists(os.path.join(ORIG, name + '.svg')) else SVGS, name + '.svg')
    rgb = render(svg, tmp)
    labels, pal = to_labels(rgb)
    before = ink_runs(labels, pal)
    labels = rebuild(labels, pal)
    after = ink_runs(labels, pal)
    return labels, pal, before, after


def main():
    import tempfile
    from gen_town import svg_of
    ship = '--ship' in sys.argv
    sigma = 0.95
    os.makedirs(OUT, exist_ok=True)
    only = [a for a in sys.argv[1:] if not a.startswith('--')]
    with tempfile.TemporaryDirectory() as tmp:
        for name in (only or NAMES):
            labels, pal, before, after = clean(name, tmp, sigma, 1.25, 1)
            im = to_image(labels, pal)
            text = svg_of(im, ink_hex='#1f2223')
            path = os.path.join(OUT, name + '.svg')
            with open(path, 'w', encoding='utf-8') as f:
                f.write(text)
            im.save(os.path.join(OUT, name + '.png'))
            top = lambda d: sorted(d.items(), key=lambda kv: -kv[1])[:4]
            print('%-16s %4d x %-4d  ink runs before %s  after %s  %d bytes'
                  % (name, im.width, im.height, top(before), top(after), len(text)))
            if ship:
                os.makedirs(ORIG, exist_ok=True)
                keep = os.path.join(ORIG, name + '.svg')
                if not os.path.exists(keep):
                    shutil.copy(os.path.join(SVGS, name + '.svg'), keep)
                shutil.copy(path, os.path.join(SVGS, name + '.svg'))


if __name__ == '__main__':
    main()
