"""Builds Pyrewing's UI pieces from the owner's sprite sheet.

    python gen_fire_ui.py         # writes lib/components/boss_trial/fire_ui_art.dart
    python gen_fire_ui.py --map   # prints every piece as a cell map
    python gen_fire_ui.py --check SHEET.png
                                  # compares the cells with the sheet as
                                  # Chrome draws it, one pixel a cell

The source (`pyrewing-symmetric-grid.svg`) is a 3656x1728 sheet on a magenta
ground, drawn in Inkscape on an 8px grid: one cell is 8 of its units. Each
piece is a top-level `<g>` holding nested groups of colour paths. Every piece
comes out as rows of letters, one a cell, which `PixelSprite` draws on whole
cells at any size, the way gen_moss_ui.py does Mossback's.

The answer scroll and the rune stone are drawn symmetrical: their right
halves are their left halves mirrored, as the owner asked, not as the sheet
draws them.

The timer is drawn at half the sheet's resolution as well: at a point a cell
its groove is 26 points tall, and the bars it goes in are 12 and 14.

Re-run after any edit to the sheet; never hand-edit the output.
"""
import math
import os
import re
import sys
import xml.etree.ElementTree as ET

import deseam

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, 'pyrewing-symmetric-grid.svg')
OUT = os.path.normpath(os.path.join(
    HERE, '..', 'lib', 'components', 'boss_trial', 'fire_ui_art.dart'))

CELL = 8
SVG_NS = '{http://www.w3.org/2000/svg}'

LETTERS = {
    '#14120e': 'K',   # outline
    '#322627': 'S',   # basalt in shadow
    '#463635': 'B',   # basalt
    '#553f3e': 'R',   # basalt rim
    '#ad4f2b': 'N',   # burnt edge
    '#d25e2b': 'E',   # ember
    '#f2bd4e': 'G',   # fire gold
    '#ebd6b3': 'P',   # parchment; W where words are written
}
GROUND = '#ff00ff'

# Pieces whose right half is their left half mirrored.
MIRRORED = {'scroll-answer-tile', 'rune-stone'}

# name in Dart, the sheet's group id, the repeating middle run of columns and
# of rows (start, end) or None, the letter and a cell of the face words go on
# (or None), and whether it is built at half resolution instead.
PIECES = [
    # Between its second and third flames, clear of the cracks.
    ('firePanel', 'text-panel', (71, 102), (36, 88), None, False),
    # Between its third and fourth flames, top and bottom.
    ('fireFlamePanel', 'flame-panel', (98, 156), (22, 42), None, False),
    ('fireScroll', 'scroll-answer-tile', (63, 102), None, ('P', (82, 20)),
     False),
    ('fireRune', 'rune-stone', (35, 46), (23, 42), ('P', (40, 30)), False),
    ('fireCoin', 'gold-coin', (28, 44), (23, 27), ('G', (36, 30)), False),
    ('fireGroove', 'timer-basalt-groove', (12, 242), None, None, True),
    # One of its two flames: they are the same flame.
    ('fireFlame', 'timer-fire-fill', None, None, None, True),
    ('fireball', 'fireball', None, None, None, False),
]

# The timer's flame is one of the pair drawn side by side.
FLAME_W = 21


def rasterise(subs, evenodd):
    """Cells whose centre is inside [subs], in cells of CELL units, under
    the path's own fill rule."""
    edges = []
    for pts in subs:
        for k in range(len(pts)):
            (x1, y1), (x2, y2) = pts[k], pts[(k + 1) % len(pts)]
            if y1 != y2:
                edges.append((x1 / CELL, y1 / CELL, x2 / CELL, y2 / CELL))
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
            inside = wind % 2 if evenodd else wind
            if inside:
                for cx in range(math.floor(a), math.ceil(b)):
                    if a <= cx + 0.5 < b:
                        cells.add((cx, cy))
    return cells


def fill_of(el):
    """A path's colour: Inkscape recolours in its style, over its fill."""
    style = el.get('style') or ''
    m = re.search(r'fill:\s*(#[0-9a-fA-F]{6})', style)
    return (m.group(1) if m else el.get('fill')).lower()


def pieces(svg_text):
    """{id: {(x, y): fill}} for every top-level group, its paths painted in
    document order, nested groups and all."""
    root = ET.fromstring(svg_text)
    out = {}
    for g in root.findall(SVG_NS + 'g'):
        cells = {}
        for p in g.iter(SVG_NS + 'path'):
            evenodd = p.get('fill-rule') == 'evenodd'
            for cell in rasterise(deseam.path_subpaths(p.get('d')), evenodd):
                cells[cell] = fill_of(p)
        out[g.get('id')] = cells
    return out


def bounds(cells):
    xs = [x for x, _ in cells]
    ys = [y for _, y in cells]
    return min(xs), min(ys), max(xs) + 1, max(ys) + 1


def rows_of(cells):
    """The piece cropped to its bounds, as rows of letters."""
    x0, y0, x1, y1 = bounds(cells)
    return [''.join(LETTERS[cells[(x, y)]] if (x, y) in cells else '.'
                    for x in range(x0, x1))
            for y in range(y0, y1)]


def mirror_left(rows):
    """[rows] with the right half replaced by the left half, mirrored; an
    odd middle column stays as drawn."""
    w = len(rows[0])
    half = w // 2
    return [r[:w - half] + r[:half][::-1] for r in rows]


def halve(rows):
    """[rows] at half resolution: each 2x2 block becomes the letter most of
    it is, the outline winning ties so lines never break, then anything
    over empty. An odd last row or column is padded with empty first, so the
    outline along it survives."""
    if len(rows[0]) % 2:
        rows = [r + '.' for r in rows]
    if len(rows) % 2:
        rows = rows + ['.' * len(rows[0])]
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
            elif len(best) > 1 and '.' in best:
                row += [c for c in best if c != '.'][0]
            else:
                row += best[0]
        out.append(row)
    return out


def mark_face(rows, seed, letter):
    """[rows] with the [letter] cells 4-connected to [seed] lettered W."""
    grid = [list(r) for r in rows]
    sx, sy = seed
    assert grid[sy][sx] == letter, (seed, grid[sy][sx])
    todo = [(sx, sy)]
    while todo:
        x, y = todo.pop()
        if not (0 <= y < len(grid) and 0 <= x < len(grid[y])):
            continue
        if grid[y][x] != letter:
            continue
        grid[y][x] = 'W'
        todo += [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]
    return [''.join(r) for r in grid]


def build():
    svg = open(SRC, encoding='utf-8').read()
    gs = pieces(svg)
    built = []
    for name, gid, mid_x, mid_y, seed, half in PIECES:
        cells = {c: f for c, f in gs[gid].items() if f != GROUND}
        rows = rows_of(cells)
        if gid == 'timer-fire-fill':
            rows = [r[:FLAME_W] for r in rows]
        if gid in MIRRORED:
            rows = mirror_left(rows)
        if seed:
            letter, at = seed
            rows = mark_face(rows, at, letter)
        if half:
            rows = halve(rows)
            mid_x = mid_x and (mid_x[0] // 2, mid_x[1] // 2)
        built.append((name, rows, mid_x, mid_y))
    return built


def timer_geometry(svg_text, groove):
    """Where the flames go in the groove, as the sheet lays them out: how far
    down from its top they stand, and how far in from its ends the channel
    they burn in starts; both in the groove's half-resolution cells."""
    gs = pieces(svg_text)
    top = (bounds(gs['timer-fire-fill'])[1]
           - bounds(gs['timer-basalt-groove'])[1]) // 2
    middle = groove[len(groove) // 2]
    inset = next(x for x in range(1, len(middle))
                 if middle[x] == 'K' and middle[x - 1] == 'R')
    return top, inset


def sub_bounds(svg_text, gid):
    """The bounds of the nested group [gid], in cells."""
    root = ET.fromstring(svg_text)
    g = next(e for e in root.iter(SVG_NS + 'g') if e.get('id') == gid)
    cells = set()
    for p in g.iter(SVG_NS + 'path'):
        cells |= rasterise(deseam.path_subpaths(p.get('d')),
                           p.get('fill-rule') == 'evenodd')
    return bounds(cells)


def panel_insets(svg_text):
    """How thick each panel's frame is round the face words go on, and how
    far the flame panel's flames stand off its frame, top and bottom."""
    gs = pieces(svg_text)

    def inset(outer, face):
        return (face[0] - outer[0], face[1] - outer[1],
                outer[2] - face[2], outer[3] - face[3])

    text = inset(bounds(gs['text-panel']),
                 sub_bounds(svg_text, 'text-panel-text-face'))
    whole = bounds(gs['flame-panel'])
    frame = sub_bounds(svg_text, 'flame-panel-frame')
    overhang = (frame[1] - whole[1], whole[3] - frame[3])
    assert overhang[0] == overhang[1], overhang
    flame = inset(frame, sub_bounds(svg_text, 'flame-panel-text-face'))
    return text, flame, overhang[0]


def palette_for(seed):
    """The palette a piece is drawn in: W, its words' face, in the colour of
    the face it was lettered from."""
    return 'fireCoinPalette' if seed and seed[0] == 'G' else 'firePalette'


def dart(built, seeds, top, inset, panels):
    colours = {letter: fill for fill, letter in LETTERS.items()}
    text, flame, overhang = panels
    out = [
        '// GENERATED by art_src/gen_fire_ui.py from',
        '// art_src/pyrewing-symmetric-grid.svg. Re-run it after editing the',
        '// sheet; never hand-edit this file.',
        '//',
        "// Pyrewing's UI pieces, one letter a cell: . is empty, W the face words",
        '// are written on (recoloured when a tile flashes or glows).',
        '',
        "import 'package:flutter/painting.dart';",
        '',
        "import 'pixel_sprite.dart';",
        '',
    ]
    for name, face in (('firePalette', 'P'), ('fireCoinPalette', 'G')):
        doc = ('The sheet\'s colours, for anything drawn to match it.'
               if face == 'P' else
               'The same, its words written on gold: the coin\'s.')
        out += ['/// ' + doc, 'const Map<String, Color> %s = {' % name]
        for letter, fill in colours.items():
            out.append("  '%s': Color(0xFF%s)," % (letter, fill[1:].upper()))
        out.append("  'W': Color(0xFF%s)," % colours[face][1:].upper())
        out += ['};', '']
    out += [
        '/// How far down the groove its flames stand, and how far in from its',
        '/// ends the channel they burn in starts, in its cells.',
        'const int fireFlameTop = %d;' % top,
        'const int fireChannelInset = %d;' % inset,
        '',
        '/// How thick the text panel\'s frame is round its face, flames and all,',
        '/// in its cells.',
        'const EdgeInsets firePanelFrame = EdgeInsets.fromLTRB(%d, %d, %d, %d);'
        % text,
        '',
        '/// How thick the flame panel\'s frame is round its face, in its cells;',
        '/// its flames stand [fireFlamePanelOverhang] off the frame, top and',
        '/// bottom.',
        'const EdgeInsets fireFlamePanelFrame ='
        ' EdgeInsets.fromLTRB(%d, %d, %d, %d);' % flame,
        'const int fireFlamePanelOverhang = %d;' % overhang,
        '',
    ]
    for name, rows, mid_x, mid_y in built:
        out.append('const PixelSprite %s = PixelSprite(' % name)
        out.append('  palette: %s,' % palette_for(seeds[name]))
        if mid_x:
            out.append('  midX: (%d, %d),' % mid_x)
        if mid_y:
            out.append('  midY: (%d, %d),' % mid_y)
        out.append('  rows: [')
        for r in rows:
            out.append("    '%s'," % r)
        out += ['  ],', ');', '']
    return '\n'.join(out)


def check(png):
    """How many cells differ from Chrome's drawing of the sheet."""
    from PIL import Image
    im = Image.open(png).convert('RGB')
    gs = pieces(open(SRC, encoding='utf-8').read())
    for gid, cells in gs.items():
        bad = [(c, f) for c, f in cells.items()
               if '#%02x%02x%02x' % im.getpixel(c) != f]
        print('%-22s %5d cells, %d differ %s'
              % (gid, len(cells), len(bad), bad[:4]))


if __name__ == '__main__':
    if '--check' in sys.argv:
        check(sys.argv[sys.argv.index('--check') + 1])
        sys.exit(0)
    built = build()
    if '--map' in sys.argv:
        only = [a for a in sys.argv[1:] if not a.startswith('--')]
        for name, rows, _, _ in built:
            if only and name not in only:
                continue
            print('%s  %dx%d' % (name, len(rows[0]), len(rows)))
            print('    ' + ''.join(str(x // 10 % 10) if x % 10 == 0 else ' '
                                   for x in range(len(rows[0]))))
            for y, r in enumerate(rows):
                print('%3d %s' % (y, r))
        sys.exit(0)
    seeds = {name: seed for name, _, _, _, seed, _ in PIECES}
    groove = next(rows for name, rows, _, _ in built if name == 'fireGroove')
    svg_text = open(SRC, encoding='utf-8').read()
    top, inset = timer_geometry(svg_text, groove)
    with open(OUT, 'w', encoding='utf-8', newline='\n') as f:
        f.write(dart(built, seeds, top, inset, panel_insets(svg_text)))
    print('wrote', OUT)
