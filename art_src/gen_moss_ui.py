"""Builds Mossback's UI pieces from the owner's sprite sheet.

    python gen_moss_ui.py         # writes lib/components/boss_trial/moss_ui_art.dart
    python gen_moss_ui.py --map   # prints every piece as a cell map

The source (`mossback-sprite-sheet.svg`) is a 160x96 sheet on a magenta
ground, one `<g>` per piece, translated into place, each drawn as colour
paths on a 1-unit pixel grid. Every piece comes out as rows of letters, one a
cell, which `PixelSprite` draws on whole cells at any size.

Pieces that stretch -- the panel, the answer tile, the timer's groove, the
rubble and the stepping stone -- name the run of columns (and rows) that is
plain enough to repeat: their ends stay as drawn and only that middle run
tiles, so a moss clump or a corner stone is never smeared. Where words go,
the face they sit on is flood-filled from a seed and lettered W instead of F,
so a tile can flash red or glow without its corner stones' lit faces going
with it.

Re-run after any edit to the sheet; never hand-edit the output.
"""
import math
import os
import re
import sys

import deseam
import lib_boss

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, 'mossback-sprite-sheet.svg')
OUT = os.path.normpath(os.path.join(
    HERE, '..', 'lib', 'components', 'boss_trial', 'moss_ui_art.dart'))

LETTERS = {
    '#11120d': 'K',   # outline
    '#4f504b': 'S',   # seams and the groove
    '#7e8a3e': 'M',   # moss
    '#a7b45a': 'L',   # lit moss
    '#989387': 'P',   # stone
    '#b4ae9f': 'H',   # lit stone
    '#d9d3c2': 'F',   # pale stone; W where words are written
}
GROUND = '#ff00ff'

# name in Dart, the sheet's group id, the repeating middle run of columns and
# of rows (start, end) or None, and a cell on the face words go on.
PIECES = [
    ('mossPanel', 'text-panel', (21, 47), (9, 23), (30, 15)),
    ('mossTile', 'answer-tile', (12, 33), (3, 11), (20, 7)),
    ('mossGroove', 'timer-groove', (7, 57), None, None),
    ('mossVine', 'timer-moss-vine', (0, 8), None, None),
    ('mossRubble', 'rubble-chunk', (13, 17), None, (12, 7)),
    ('mossStone', 'stepping-stone', (12, 16), (3, 4), (15, 2)),
    ('mossCup', 'upturned-stone-cup', None, None, None),
    ('mossPebble', 'moss-pebble', None, None, None),
]


def rasterise_nonzero(subs):
    """Cells whose centre is inside [subs] under SVG's default nonzero rule:
    Inkscape's unions overlap their own subpaths, which even-odd would punch
    holes through."""
    edges = []
    for pts in subs:
        for k in range(len(pts)):
            (x1, y1), (x2, y2) = pts[k], pts[(k + 1) % len(pts)]
            if y1 != y2:
                edges.append((x1, y1, x2, y2))
    if not edges:
        return set()
    ys = [y for e in edges for y in (e[1], e[3])]
    cells = set()
    for cy in range(math.floor(min(ys)), math.ceil(max(ys))):
        sy = cy + 0.5
        hits = sorted((x1 + (sy - y1) * (x2 - x1) / (y2 - y1),
                       1 if y2 > y1 else -1)
                      for x1, y1, x2, y2 in edges
                      if (y1 <= sy < y2) or (y2 <= sy < y1))
        wind = 0
        for (a, turn), (b, _) in zip(hits, hits[1:]):
            wind += turn
            if wind:
                for cx in range(math.floor(a), math.ceil(b)):
                    if a <= cx + 0.5 < b:
                        cells.add((cx, cy))
    return cells


def groups(svg):
    """{id: {(x, y): fill}}, each group's paths painted in document order."""
    out = {}
    for m in re.finditer(r'<g\b([^>]*)>(.*?)</g>', svg, re.S):
        attrs, body = m.group(1), m.group(2)
        gid = re.search(r'\bid="([^"]+)"', attrs).group(1)
        t = re.search(r'translate\(\s*([-\d.]+)[\s,]+([-\d.]+)\s*\)', attrs)
        tx, ty = (float(t.group(1)), float(t.group(2))) if t else (0.0, 0.0)
        cells = {}
        for p in re.finditer(r'<path\b([^>]*)/>', body):
            pa = p.group(1)
            # Inkscape recolours a path in its style, over its fill.
            fill = (re.search(r'style="[^"]*fill:(#[0-9a-fA-F]{6})', pa) or
                    re.search(r'fill="(#[0-9a-fA-F]{6})"', pa)).group(1).lower()
            d = re.search(r'\bd="([^"]*)"', pa).group(1)
            subs = [[(x + tx, y + ty) for x, y in s]
                    for s in deseam.path_subpaths(d)]
            for cell in rasterise_nonzero(subs):
                cells[cell] = fill
        out[gid] = cells
    return out


def rows_of(cells):
    """The piece cropped to its bounds, as rows of letters."""
    cells = {c: f for c, f in cells.items() if f != GROUND}
    x0, y0, x1, y1 = lib_boss.bounds(cells)
    return [''.join(LETTERS[cells[(x, y)]] if (x, y) in cells else '.'
                    for x in range(x0, x1))
            for y in range(y0, y1)]


def mark_face(rows, seed):
    """[rows] with the F cells 4-connected to [seed] lettered W."""
    grid = [list(r) for r in rows]
    sx, sy = seed
    assert grid[sy][sx] == 'F', (seed, grid[sy][sx])
    todo = [(sx, sy)]
    while todo:
        x, y = todo.pop()
        if not (0 <= y < len(grid) and 0 <= x < len(grid[y])):
            continue
        if grid[y][x] != 'F':
            continue
        grid[y][x] = 'W'
        todo += [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]
    return [''.join(r) for r in grid]


def check_run(rows, run, axis):
    """A repeating run must be inside the piece: it cannot start at 0 and
    also end at the far edge unless the whole piece repeats (the vine)."""
    a, b = run
    n = len(rows[0]) if axis == 'x' else len(rows)
    assert 0 <= a < b <= n, (run, n)


def dart(pieces):
    out = [
        '// GENERATED by art_src/gen_moss_ui.py from',
        '// art_src/mossback-sprite-sheet.svg. Re-run it after editing the',
        '// sheet; never hand-edit this file.',
        '//',
        "// Mossback's UI pieces, one letter a cell: . is empty, W the pale face",
        '// words are written on (recoloured when a tile flashes or glows).',
        '',
        "import 'package:flutter/painting.dart';",
        '',
        "import 'pixel_sprite.dart';",
        '',
        '/// The sheet'"'"'s colours, for anything drawn to match it.',
        'const Map<String, Color> mossPalette = {',
    ]
    for fill, letter in LETTERS.items():
        out.append("  '%s': Color(0xFF%s)," % (letter, fill[1:].upper()))
    out.append("  'W': Color(0xFF%s)," % '#d9d3c2'[1:].upper())
    out += ['};', '']
    for name, rows, mid_x, mid_y in pieces:
        out.append('const PixelSprite %s = PixelSprite(' % name)
        out.append('  palette: mossPalette,')
        if mid_x:
            out.append('  midX: (%d, %d),' % mid_x)
        if mid_y:
            out.append('  midY: (%d, %d),' % mid_y)
        out.append('  rows: [')
        for r in rows:
            out.append("    '%s'," % r)
        out += ['  ],', ');', '']
    return '\n'.join(out)


if __name__ == '__main__':
    svg = open(SRC, encoding='utf-8').read()
    gs = groups(svg)
    built = []
    for name, gid, mid_x, mid_y, seed in PIECES:
        rows = rows_of(gs[gid])
        if seed:
            rows = mark_face(rows, seed)
        if mid_x:
            check_run(rows, mid_x, 'x')
        if mid_y:
            check_run(rows, mid_y, 'y')
        built.append((name, rows, mid_x, mid_y))
        if '--map' in sys.argv:
            print('%s  %dx%d' % (name, len(rows[0]), len(rows)))
            print('    ' + ''.join(str(x % 10) for x in range(len(rows[0]))))
            for y, r in enumerate(rows):
                print('%3d %s' % (y, r))
    if '--map' not in sys.argv:
        with open(OUT, 'w', encoding='utf-8', newline='\n') as f:
            f.write(dart(built))
        print('wrote', OUT)
