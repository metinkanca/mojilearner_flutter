"""A floor of the boss climb map, from its pxl source to what the app loads.

    node <skill>/bin/pxl.js build art_src/pxl/climb1.px.js
    python art_src/pxl/export_climb.py          # floor 1; `... 2` for floor 2

Reads the picture pxl built (`out/scenes/floorN.png`, one pixel a cell) and
writes the app's copy through the home scenes' own writer
(`scene_art.asset_svg`): `assets/svgs/climb_floor_N.svg`, one path a colour,
each fill grown a pixel under the ink so no hairline of the ground shows at a
fractional scale, and checked to reproduce the picture. Where the five stops
are comes from the `stamp("pad", x, y)` lines of the source, and goes to
`climb_floors.json`, which `gen_climb.py --app` reads so that it writes these
floors' rows of `boss_climb_art.dart` from here instead of from a sheet.
"""
import json
import os
import re
import sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ART_SRC = os.path.normpath(os.path.join(HERE, '..'))
sys.path.insert(0, ART_SRC)
import scene_art as SA  # noqa: E402

# The floors drawn with pxl: the source, and the order the app paints that
# floor's colours in, by pxl key. The first is the underlay (the ground) and
# the ink, last, sits on top of everything.
FLOORS = {
    1: ('climb1.px.js', 'lvmswcjk'),
    2: ('climb2.px.js', 'vmzpowk'),
    3: ('climb3.px.js', 'pbjdowyk'),
    4: ('climb4.px.js', 'bwnjgtyk'),
    5: ('climb5.px.js', 'wtgcudsok'),
    6: ('climb6.px.js', 'dsmroywk'),
}
TABLE = os.path.join(HERE, 'climb_floors.json')
PAD = 23        # cells across a stop's pad, ink included


def palette_of(source):
    block = re.search(r'pal\(\{(.*?)\}\)', source, re.S).group(1)
    return {k: '#' + h for k, h in re.findall(r'(\w):\s*"#(\w{6})"', block)}


def main(floor):
    name, order = FLOORS[floor]
    source = open(os.path.join(HERE, name), encoding='utf-8').read()
    picture = os.path.join(HERE, 'out', 'scenes', 'floor%d.png' % floor)
    app_svg = os.path.normpath(os.path.join(
        ART_SRC, '..', 'assets', 'svgs', 'climb_floor_%d.svg' % floor))
    keys = palette_of(source)
    rgb = {tuple(int(h[i:i + 2], 16) for i in (1, 3, 5)): k
           for k, h in keys.items()}
    img = np.array(Image.open(picture).convert('RGB'))
    h, w, _ = img.shape
    index = {k: i for i, k in enumerate(order)}
    classes = np.zeros((h, w), np.int8)
    for y in range(h):
        for x in range(w):
            k = rgb.get(tuple(int(c) for c in img[y, x]))
            if k is None:
                sys.exit('a pixel at %d,%d is a colour the palette lacks' % (x, y))
            classes[y, x] = index[k]
    palette = SA.Palette([(k, keys[k]) for k in order])
    with open(app_svg, 'w', encoding='utf-8', newline='\n') as f:
        f.write(SA.asset_svg(classes, palette))

    centres = sorted(
        ((int(x) + PAD / 2, int(y) + PAD / 2) for x, y in
         re.findall(r'stamp\("pad", (\d+), (\d+)\)', source)),
        key=lambda p: -p[1])
    if len(centres) != 5:
        sys.exit('expected five stops, found %d' % len(centres))
    table = {}
    if os.path.exists(TABLE):
        with open(TABLE, encoding='utf-8') as f:
            table = json.load(f)
    table[str(floor)] = {
        'width': w, 'height': h, 'ground': keys[order[0]][1:].upper(),
        'pad': PAD, 'stops': centres}
    with open(TABLE, 'w', encoding='utf-8', newline='\n') as f:
        json.dump(dict(sorted(table.items())), f, indent=1)
        f.write('\n')
    print('wrote %s (%d x %d cells) and %s' % (
        os.path.relpath(app_svg, os.path.join(ART_SRC, '..')), w, h,
        os.path.relpath(TABLE, os.path.join(ART_SRC, '..'))))


if __name__ == '__main__':
    main(int(sys.argv[1]) if len(sys.argv) > 1 else 1)
