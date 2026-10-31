# -*- coding: utf-8 -*-
"""Draws the Departures scene the way the app does, straight to a PNG.

A `flutter test` round trip is minutes; this is under a second, which is the
difference between iterating on the art and guessing at it.

It has no art or colours of its own. The drawings come from the same
`gen_airfield.MOTIFS` table that is generated into scenes.dart, and the
palettes are read back out of scenes.dart itself — so there is no second copy
to drift, and a preview that looks right is the shipping scene looking right.
What it does reimplement is the two things `SceneThumbnail` does: bands at
5:4, and decor scaled by tile width over `kSceneDesignWidth`.

    python art_src/preview_airfield.py out_dir
"""

import os
import re
import sys

from PIL import Image, ImageDraw

import gen_airfield as art

DESIGN_WIDTH = 360.0
# Mirrors `SceneTheme.horizon` for the airfield.
HORIZON = 0.78
SCENES = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                      'lib', 'constants', 'scenes.dart')

# The two colours scenes.dart names rather than spells out.
NAMED = {'AppTheme.retroMoon': '#E8E8E8', 'AppTheme.retroAccent': '#F4D03F'}


def read_palettes():
    """The `_airfield` scene's three palettes, straight out of the Dart.

    Comments are stripped first, and that is not fussiness: a comment that
    mentions a colour by its literal — explaining why an ink was changed, say
    — is otherwise read as an extra entry, and every ink after it shifts by
    one. The symptom is a scene that renders in the wrong colours entirely.
    """
    src = re.sub('//[^\n]*', '', open(SCENES, encoding='utf-8').read())
    start = src.index('const SceneTheme _airfield = SceneTheme(')
    body = src[start:src.index('\n);', start)]

    out = {}
    for time in ('day', 'sunset', 'night'):
        m = re.search(r'\n  %s: ScenePalette\((.*?)\n  \),' % time, body,
                      re.S)
        if not m:
            raise SystemExit('no %s palette in scenes.dart' % time)
        block = m.group(1)

        def one(field):
            f = re.search(r'\b%s: (?:Color\(0xFF([0-9A-Fa-f]{6})\)'
                          r'|(AppTheme\.\w+))' % field, block)
            if not f:
                return None
            return '#' + f.group(1) if f.group(1) else NAMED[f.group(2)]

        inks = re.search(r'motifInks: \[(.*?)\]', block, re.S)
        out[time] = dict(
            sky=one('sky'), ground=one('ground'),
            detail=one('groundDetail'), celestial=one('celestial'),
            inks=['#' + c for c in
                  re.findall(r'0xFF([0-9A-Fa-f]{6})', inks.group(1))],
        )
    return out


def read_apron():
    """`_apron`, as (x, y, w, h, opacity) tuples."""
    src = open(SCENES, encoding='utf-8').read()
    block = src[src.index('const List<SceneSpeck> _apron = ['):]
    block = block[:block.index('\n];')]
    specks = []
    for line in re.findall(r'SceneSpeck\(([^)]*)\)', block):
        args = [a.strip() for a in line.split(',')]
        pos = [float(a) for a in args if ':' not in a]
        kw = dict(a.split(':') for a in args if ':' in a)
        specks.append((pos[0], pos[1],
                       float(kw.get('width', 8)), float(kw.get('height', 8)),
                       float(kw.get('opacity', 1.0))))
    return specks


def hexrgb(h):
    h = h.lstrip('#')
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def blend(fg, bg, alpha):
    return tuple(int(round(f * alpha + b * (1 - alpha))) for f, b in zip(fg, bg))


def align(value, extent, child):
    """Flutter's Alignment, one axis."""
    return (extent - child) / 2.0 + value * (extent - child) / 2.0


def render(palette, apron, size, path):
    inks = [hexrgb(c) for c in palette['inks']]
    scale = size / DESIGN_WIDTH

    img = Image.new('RGB', (int(size), int(size)), hexrgb(palette['sky']))
    d = ImageDraw.Draw(img)
    sky_h = size * HORIZON
    ground_h = size - sky_h
    d.rectangle([0, sky_h, size, size], fill=hexrgb(palette['ground']))

    d.rectangle([0, sky_h, size, sky_h + max(1, 4 * scale)], fill=(43, 43, 51))
    detail = hexrgb(palette['detail'])
    for sx, sy, sw, sh, op in apron:
        w, h = max(1.0, sw * scale), max(1.0, sh * scale)
        x0 = align(sx, size, w)
        y0 = sky_h + align(sy, ground_h, h)
        d.rectangle([x0, y0, x0 + w, y0 + h],
                    fill=blend(detail, hexrgb(palette['ground']), op))

    bands = {'sky': (0, sky_h), 'ground': (sky_h, ground_h)}
    for _name, grid, cell, ax, ay, band, _doc in art.MOTIFS:
        top, height = bands[band]
        blocks, cols, rows = art.parse(grid)
        cw, ch = cell if isinstance(cell, tuple) else (cell, cell)
        sx, sy = cw * scale, ch * scale
        ox = align(float(ax), size, cols * sx)
        oy = top + align(float(ay), height, rows * sy)
        for bx, by, bw, bh, ink in blocks:
            if ink >= len(inks):
                continue
            x0, y0 = ox + bx * sx, oy + by * sy
            x1 = x0 + max(1.0, bw * sx)
            y1 = y0 + max(1.0, bh * sy)
            # Clipped to the band, because Flutter's `Stack` clips and the
            # motifs that have to span a screen are authored to overflow one.
            # Without this the apron's slab joints run up into the sky here
            # and nowhere else, which is a preview that lies.
            y0, y1 = max(y0, top), min(y1, top + height)
            if y1 <= y0:
                continue
            d.rectangle([max(x0, 0), y0, min(x1, size), y1], fill=inks[ink])

    if palette['celestial']:
        c = size * 0.13
        cx, cy = align(-0.62, size, c), align(-0.66, sky_h, c)
        d.rectangle([cx, cy, cx + c, cy + c],
                    fill=hexrgb(palette['celestial']),
                    outline=(43, 43, 51), width=max(1, int(size * 0.011)))

    img.resize((int(size * 3), int(size * 3)), Image.NEAREST).save(path)


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else '.'
    os.makedirs(out, exist_ok=True)
    palettes, apron = read_palettes(), read_apron()
    for time, palette in palettes.items():
        for size in (360, 88):
            render(palette, apron, size,
                   os.path.join(out, 'airfield_%s_%d.png' % (time, size)))
    print('wrote previews to', out)


if __name__ == '__main__':
    main()
