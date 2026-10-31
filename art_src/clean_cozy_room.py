"""Cleans the black outlines of cozy-room-selected.svg and ships it as a scene.

The room was traced from a bitmap, and the trace kept the bitmap's faults:

  * a ring of stray honey / coral / green pixels sitting OUTSIDE the outline,
    where the original's antialiasing was quantised to the nearest of six
    colours;
  * one-pixel nubs, dents and sub-steps along otherwise straight edges;
  * hairline cracks in the strokes, and a few joints where two outline blocks
    meet corner to corner so a fill leaks straight through into the wall.

There is no hidden pixel grid to snap to (the edges are not periodic), so this
repairs the faults in place rather than re-quantising the drawing. Everything
stays on the original integer pixel grid and in the original six colours.

The file only uses `M h v z`, so it is rasterised here exactly, with no browser
in the loop. Each cleaned pixel keeps the named element it belonged to, which
is what lets the layered copy keep the wall / window / curtains / ... groups.

Writes two files:

  cozy-room-clean.svg      the editable master: same layers and ids as the source
  ../assets/svgs/cozy_room.svg   what the app loads: one path per colour

This is a one-time polish. After it, edit cozy-room-clean.svg by hand and run
build_cozy_room.py to rebuild the app copy; this script refuses to overwrite
the master (so it cannot eat your edits) unless given --force.

The app copy is written by scene_art.asset_svg: one path per colour, each fill
grown a pixel under the ink around it, so joins are overlaps rather than
abutments and no hairline shows at a fractional scale (flutter_svg ignores
crispEdges). It is deliberately NOT `deseam.py`'s scheme of painting each colour
over the union of everything above it: that puts the topmost fill under every
outline, and it shows through the edge of every thin line.

Usage:  python clean_cozy_room.py [source.svg] [--force]
"""
import re
import sys
from pathlib import Path

import numpy as np
from scipy import ndimage as ndi

from scene_art import (COZY_ROOM, S4, S8, asset_svg, paint, path_data, rasterise,
                       read_elements)

HERE = Path(__file__).resolve().parent
SRC = HERE / 'cozy-room-selected.svg'
OUT_LAYERED = HERE / 'cozy-room-clean.svg'
OUT_ASSET = HERE.parent / 'assets' / 'svgs' / 'cozy_room.svg'

# Class ids are positions in the shared palette, which is also the order the
# app asset paints them (bottom to top): the wall is the underlay and the
# outline sits on everything.
WALL, WOOD, GLASS, CORAL, LEAF, INK = range(6)
FILLS = (WOOD, GLASS, CORAL, LEAF)

SQ3 = np.ones((3, 3), bool)

# A pocket or bump this long or shorter, and this deep or shallower, in an
# otherwise straight edge is jitter. Deeper or longer than that is drawing.
JOG_LENGTH, JOG_DEPTH = 24, 2
# A crack in a stroke is a few pixels. A long thin gap between two outlines
# (the honey sliver between the shelf and the pet bed) is art and must stay.
GAP_AREA = 16
SPECK_AREA = 12


# --- Cleaning ----------------------------------------------------------------

def nearest_fill(cls, free, trusted):
    """Give every pixel in `free` the class of the nearest `trusted` pixel."""
    _, (iy, ix) = ndi.distance_transform_edt(~trusted, return_indices=True)
    out = cls.copy()
    out[free] = cls[iy[free], ix[free]]
    return out


def drop_fringe(c):
    """Remove thin stray colour that touches a different colour, then specks.

    A fringe pixel is one a 3x3 square cannot sit inside (so it is 1-2px thin)
    AND that touches another non-black colour: that is the signature of a
    quantised antialiasing rim. A thin wedge tip between two outline strokes
    touches only black and is left alone.
    """
    for _ in range(3):
        fringe = np.zeros(c.shape, bool)
        for ci in (WALL,) + FILLS:
            m = c == ci
            thin = m & ~ndi.binary_opening(m, structure=SQ3)
            other = np.zeros(c.shape, bool)
            for cj in (WALL,) + FILLS:
                if cj != ci:
                    other |= ndi.binary_dilation(c == cj, structure=S8)
            fringe |= thin & other
        if not fringe.any():
            break
        c = nearest_fill(c, fringe, (c != INK) & ~fringe)
    # a handful of pixels sealed inside the outline is a pinhole, not a region
    for ci in FILLS:
        lab, k = ndi.label(c == ci, structure=S8)
        for i in np.nonzero(ndi.sum(c == ci, lab, range(1, k + 1)) <= SPECK_AREA)[0]:
            comp = lab == i + 1
            ring = ndi.binary_dilation(comp, structure=S8) & ~comp
            if (c[ring] == INK).all():
                c[comp] = INK
    return c


def _runs(row):
    d = np.diff(np.concatenate(([0], row.astype(np.int8), [0])))
    return np.nonzero(d == 1)[0], np.nonzero(d == -1)[0] - 1


def find_jogs(ink):
    """Shallow dents and bumps along the *horizontal* edges of the outline.

    A dent is a run of non-ink bounded by ink on both sides, floored by ink a
    pixel or two further on, and open on the other side to an edge that
    carries on level beside it. The open side is what separates a notch in a
    straight edge from the bottom of a narrow closed region (a book spine, a
    table leg), which must not be touched. A bump is the same thing inverted
    and must rest on a wider base, so a free-standing thin line never counts.
    Returns (ink to add, ink to remove).
    """
    h, w = ink.shape
    add = np.zeros_like(ink)
    drop = np.zeros_like(ink)
    for y in range(h):
        s, e = _runs(~ink[y])
        for a, b in zip(s, e):
            if a == 0 or b == w - 1 or b - a + 1 > JOG_LENGTH:
                continue
            if not (ink[y, a - 1] and ink[y, b + 1]):
                continue
            for step in (1, -1):
                yo = y - step
                if yo < 0 or yo >= h or ink[yo, a - 1] or ink[yo, b + 1] \
                        or ink[yo, a:b + 1].any():
                    continue
                depth, floored = 0, False
                while depth < JOG_DEPTH:
                    yy = y + step * (depth + 1)
                    if yy < 0 or yy >= h:
                        break
                    seg = ink[yy, a:b + 1]
                    if seg.all():
                        floored = True
                        depth += 1
                        break
                    if seg.any() or not (ink[yy, a - 1] and ink[yy, b + 1]):
                        break
                    depth += 1
                if floored:
                    for k in range(depth):
                        add[y + step * k, a:b + 1] = True
                    break
        s, e = _runs(ink[y])
        for a, b in zip(s, e):
            if a == 0 or b == w - 1 or b - a + 1 > JOG_LENGTH:
                continue
            if ink[y, a - 1] or ink[y, b + 1]:
                continue
            for step in (1, -1):                 # toward the base
                yo = y - step
                if yo < 0 or yo >= h or ink[yo, a:b + 1].any():
                    continue
                height, based = 0, False
                while height < JOG_DEPTH:
                    yy = y + step * height
                    if yy < 0 or yy >= h or not ink[yy, a:b + 1].all():
                        break
                    if not ink[yy, a - 1] and not ink[yy, b + 1]:
                        height += 1
                        continue
                    based = True
                    break
                if based and 1 <= height <= JOG_DEPTH:
                    for k in range(height):
                        drop[y + step * k, a:b + 1] = True
                    break
    return add, drop


def restore_bridges(ink_ref, ink_new):
    """Put back removed pixels that were the only link between two pieces."""
    ink = ink_new.copy()
    for _ in range(6):
        lab, _n = ndi.label(ink, structure=S8)
        removed, count = ndi.label(ink_ref & ~ink, structure=S8)
        grew = False
        for i, sl in enumerate(ndi.find_objects(removed), 1):
            sl = tuple(slice(max(s.start - 1, 0), s.stop + 1) for s in sl)
            comp = removed[sl] == i
            near = ndi.binary_dilation(comp, structure=S8) & ink[sl]
            if len(set(lab[sl][near].tolist())) >= 2:
                ink[sl] |= comp
                grew = True
        if not grew:
            break
    return ink


def set_ink(c, old, new):
    """Move the outline from `old` to `new`; freed pixels take the nearest fill."""
    out = c.copy()
    out[new] = INK
    freed = old & ~new
    return nearest_fill(out, freed, (out != INK) & ~freed)


def smooth_jogs(c):
    for _ in range(3):
        ink = c == INK
        new = ink.copy()
        for transposed in (False, True):
            add, drop = find_jogs(ink.T.copy() if transposed else ink)
            if transposed:
                add, drop = add.T, drop.T
            new |= add
            new &= ~drop
        new = restore_bridges(ink, new)
        if (new == ink).all():
            break
        c = set_ink(c, ink, new)
    return c


def close_cracks(c):
    """Drop 1-2px nubs, then bridge hairline cracks in the strokes."""
    ink = c == INK
    kept = restore_bridges(ink, ndi.binary_opening(ink, structure=SQ3))
    padded = np.pad(kept, 5)
    added = ndi.binary_closing(padded, structure=np.ones((5, 5), bool))[5:-5, 5:-5] & ~kept
    lab, k = ndi.label(added, structure=S8)
    small = np.zeros(k + 1, bool)
    small[1:] = ndi.sum(added, lab, range(1, k + 1)) <= GAP_AREA
    return set_ink(c, ink, kept | small[lab])


def find_leaks(c):
    """Pixels either side of a fill-to-fill contact with no outline between."""
    leak = np.zeros(c.shape, bool)
    h, w = c.shape
    for dy, dx in ((0, 1), (1, 0)):
        a, b = c[:h - dy, :w - dx], c[dy:, dx:]
        hit = (a != b) & (a != INK) & (b != INK)
        leak[:h - dy, :w - dx] |= hit
        leak[dy:, dx:] |= hit
    return leak


def plug_leaks(c):
    """Seal the places where outline blocks meet corner to corner.

    The plug is grown a pixel so the joint is a solid block, not a hairline.
    """
    leak = find_leaks(c)
    out = c.copy()
    out[ndi.binary_dilation(leak, structure=SQ3)] = INK
    return out


def clean_once(c):
    c = drop_fringe(c.copy())
    c = smooth_jogs(c)
    c = close_cracks(c)
    c = smooth_jogs(c)       # closing can expose new jogs
    return plug_leaks(c)


def clean(c):
    """Repeat until nothing changes: each pass can expose a nub the last hid."""
    for _ in range(5):
        out = clean_once(c)
        if (out == c).all():
            break
        c = out
    return c


# --- Writing the SVG ---------------------------------------------------------

def main():
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    force = '--force' in sys.argv
    src = Path(args[0]) if args else SRC
    if OUT_LAYERED.exists() and src.resolve() != OUT_LAYERED.resolve() and not force:
        sys.exit(
            '%s already exists, and it is the file you edit by hand: running this\n'
            'would replace your edits with a fresh clean of %s.\n'
            '  to rebuild the app from your edits:   python build_cozy_room.py\n'
            '  to throw the edits away and start over: python clean_cozy_room.py --force'
            % (OUT_LAYERED.name, SRC.name))
    text = src.read_text(encoding='utf-8')
    elements = read_elements(text, COZY_ROOM)
    w, h = [int(v) for v in re.search(r'width="(\d+)" height="(\d+)"', text).groups()]
    shape = (h, w)

    masks = [rasterise(el, shape) for el in elements]
    before = paint(elements, masks, shape)
    if (before < 0).any():
        sys.exit('the source leaves pixels unpainted')
    owner = np.full(shape, -1, np.int32)
    for i, m in enumerate(masks):
        owner[m] = i

    after = clean(before.astype(np.int8))

    # Each cleaned pixel keeps the element of the nearest same-colour pixel of
    # the source, so a repaired curtain edge stays in the curtain's layer.
    new_owner = np.full(shape, -1, np.int32)
    for cls in range(len(COZY_ROOM)):
        _, (iy, ix) = ndi.distance_transform_edt(~(before == cls), return_indices=True)
        pick = after == cls
        new_owner[pick] = owner[iy[pick], ix[pick]]

    # --- layered copy: same text, new path data
    pieces, last = [], 0
    new_masks = []
    for i, el in enumerate(elements):
        mine = new_owner == i
        rect_ok = el['tag'] == 'rect' and not (
            (new_owner[rasterise(el, shape)] < i) & (new_owner[rasterise(el, shape)] >= 0)).any()
        new_masks.append(rasterise(el, shape) if rect_ok else mine)
        pieces.append(text[last:el['span'][0]])
        last = el['span'][1]
        tag = text[el['span'][0]:el['span'][1]]
        if rect_ok:
            pieces.append(tag)
        elif mine.any():
            body = re.sub(r'<rect\b', '<path', tag) if el['tag'] == 'rect' else tag
            body = re.sub(r'\s(x|y|width|height)="[^"]*"', '', body) if el['tag'] == 'rect' else body
            body = re.sub(r'\sd="[^"]*"', '', body)
            body = body.replace('<path', '<path d="%s"' % path_data(mine), 1)
            pieces.append(body)
        # an element that owns no pixels any more is simply dropped
    pieces.append(text[last:])
    layered = ''.join(pieces)
    layered = layered.replace(
        '</desc>',
        ' Outlines cleaned by art_src/clean_cozy_room.py. THIS IS THE FILE TO EDIT: save it, then run '
        '`python art_src/build_cozy_room.py` to rebuild the app copy (assets/svgs/cozy_room.svg).</desc>', 1)

    kept = [(el, m) for el, m in zip(elements, new_masks) if m.any()]
    if not (paint([e for e, _ in kept], [m for _, m in kept], shape) == after).all():
        sys.exit('layered output does not reproduce the cleaned image')
    OUT_LAYERED.write_text(layered, encoding='utf-8')

    # --- app copy
    asset = asset_svg(after, COZY_ROOM)
    OUT_ASSET.parent.mkdir(parents=True, exist_ok=True)
    OUT_ASSET.write_text(asset, encoding='utf-8')

    ink0, ink1 = before == INK, after == INK
    print('changed %d px; outline %d -> %d px' % ((before != after).sum(), ink0.sum(), ink1.sum()))
    print('leaks %d -> %d; ink pieces %d -> %d' % (
        find_leaks(before).sum(), find_leaks(after).sum(),
        ndi.label(ink0, structure=S8)[1], ndi.label(ink1, structure=S8)[1]))
    print('wrote %s (%d bytes)' % (OUT_LAYERED.name, OUT_LAYERED.stat().st_size))
    try:
        shown = OUT_ASSET.relative_to(HERE.parent)
    except ValueError:                  # written somewhere else on request
        shown = OUT_ASSET
    print('wrote %s (%d bytes)' % (shown, OUT_ASSET.stat().st_size))


if __name__ == '__main__':
    main()
