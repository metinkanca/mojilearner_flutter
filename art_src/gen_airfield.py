# -*- coding: utf-8 -*-
"""Authors the Departures scene's drawings and writes them into scenes.dart.

The scene itself is a palette and a decor list, not a picture — see
`lib/constants/scenes.dart`. Most decor is loose rectangles placed by
fraction, which is right for grass and wave crests and hopeless for anything
that has to hold a shape. Those are `SceneMotif`s: a cluster anchored once and
laid out in its own pixels, so it scales as one drawing.

Hand-writing a hundred rectangle coordinates is how you get an aircraft that
reads as a plus sign — the first attempt did — so the shapes are authored here
on a character grid instead, one character per cell. Each character names an
ink; the ink's *colour* is chosen per time of day by the palette, so one
drawing flies in daylight, silhouettes at sunset and shows a lit cabin at
night without being redrawn.

Run it after editing any grid below:

    python art_src/gen_airfield.py

It rewrites the block between the two markers in scenes.dart and nothing else.
`preview_airfield.py` renders the same table straight to a PNG, which is the
loop to iterate the art in — a `flutter test` round trip is minutes.
"""

import io
import os

# Ink order. Index into `ScenePalette.motifInks`, so the palettes in
# scenes.dart list their colours in exactly this order.
INKS = ['line', 'body', 'shade', 'glass', 'trim', 'shadow', 'pale',
        'stone', 'stoneShade', 'haze']
CH = {
    '.': None,
    '#': 0,  # line       — the dark outline every object here carries
    'B': 1,  # body       — the aircraft's white upper fuselage
    'S': 2,  # shade      — its wings, tail and engine
    'W': 3,  # glass      — cabin windows, terminal glazing, the tower cab
    'T': 4,  # trim       — the one saturated accent
    'X': 5,  # shadow     — cast on the apron, and nothing else
    'P': 6,  # pale       — a cloud's underside, and the haze at the horizon
    'C': 7,  # stone      — building concrete, lit
    'D': 8,  # stoneShade — building concrete, shaded
    'H': 9,  # haze       — the band of sky sitting on the horizon
}

# --- The drawings ------------------------------------------------------------
#
# All of it is traced from `ref_airfield.svg` by `trace_native.py`, at the
# reference's own 224x300 grid, where one source pixel is exactly one cell.
# Re-run that rather than editing coordinates here; the grids below are its
# output, region-inked and cleaned.
#
# The buildings keep their traced detail — the terminal's glazing band, its
# jet bridge, the tower's cab — because the trace is clean enough to. The
# aircraft does not: see its note.

# The airliner, from x 65-167, y 38-81.
#
# Re-inked to four colours from the trace's six. That is what
# 'overdone' was: the reference shades every surface lit and
# shaded, and at two logical pixels a cell it reads as speckle
# rather than as form — and at night thirteen cabin windows light
# up as a dotted line. Hull, grey, glass, line; six windows and a
# door. The silhouette is the reference's exactly, including the
# engine slung under the wing, which is the detail that was lost
# when this was drawn by hand.
PLANE = r"""
..........................................................................................#########...
.........................................................................................#SSSSSSSS#...
.........................................................................................#SSSSSSSS#...
........................................................................................#SSSSSSSSS#...
......................................................................................##SSSSSSSSSS#...
......................................................................................#SSSSSSSSSSS#...
.....................................................................................#SSSSSSSSSSS#....
.....................................................................................#SSSSSSSSSSS#....
....................................................................................#SSSSSSSSSSSS#....
...................................................................................#SSSSSSSSSSSS##....
..................................................................................#SSSSSSSSSSSS#......
.................................................................................#SSSSSSSSSSSSS#......
.................................................................................#SSSSSSSSSSSSS#......
...............................................................................##SSSSSSSSSSSSSS#......
..............................................................................#SSSSSSSSSSSSSSS#.......
..............................................................................#SSSSSSSSSSSSSSS#.......
............................................................................##SSSSSSSSSSSSSSSS#.......
..........................................................................##SSSSSSSSSSSSSSSSSS#.......
.......................................................................###SSSSSSSSSSSSSSSSSSS#........
.......................................................................#SSSSSSSSSSSSSSSSSSSS#.........
..........#############################################################SSSSSSSSSSSSSSSSSSSSS#.........
........##BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBSSSSSSSSSSSSSSSSSSSSSSS##.......
........#BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBSSSSSSSSSSSSSSSSSSSSSSSS#.......
.....###BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBSSSSSSSSSSSSSSSSSSSSSSSSS#......
....#BBBBBWBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBSSSSSSSSSSSSSSSSSSSSSSSSSS####..
...#BBBBBBWBBBWBBBBBBBWBBBBBBBWBBBBBBBWBBBBBBBWBBBBBBBWBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB#.
...#BBBBBBWBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB###
.##BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSBBBBBBBBBBBBBBBBBB#BBBB#...
#BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSBBBBBBBBBBBBBBBBB#.####....
#BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSBBBBBBBBBBBBB####..........
#BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSBBBBBBBBB####..............
#BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSBBBBBBBB#..................
#BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSBBB#####...................
.##BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS#####........................
...#SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS#.............................
....####SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS#####..............................
........##############################SSSSSSSSSSSSSSSSSSSSSSSS#####...................................
......................................#SSSSSSSSSSSSSSSSSSSSS##........................................
......................................#SSSSSSSSSSSSSSSSSSSS#..........................................
......................................#SSSSSSSSSSSSSSSSS####..........................................
......................................#SSSSSSSSSSSSS####..............................................
.......................................#SSSSSSSSSSS#..................................................
........................................############..................................................
"""

# The control tower — the one tall thing on an airfield, and the
# whole reason the horizon reads as an airport.
TOWER = r"""
..........
..........
..........
....#.....
....#.....
....#.....
....#.....
#.#.#.....
######....
#SSSSS#...
#CCCCC#...
#######...
##W#W##...
##W#W##...
######....
#SSS#.....
#SSS#.....
#SSS#.....
#SCC#.....
#SCC#.....
#SCC#.....
#SCC#.....
#SCC#.....
#SCC#.....
#SCC#.....
#SCC#.....
#SCC#.....
#SCC#.....
#SCC#.....
#SCC#.....
#SCC#.....
#SCC#.....
#SCC#....#
#SCC#....#
#DD#######
##########
"""

# The terminal: a stepped roofline over a glazed storey, with a
# jet bridge reaching off the right-hand end.
TERMINAL = r"""
..........................................................................
..........................................................................
....#########........##################......##############...............
....#CCCCCCC##########CCCCCCCCCCCCCCCC########CCCCCCCCCCCC#...............
....##CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC##...............
...#.###################################################D#................
.....#C#DDDD#DDDD#DDDDD#DDDD#DDDD#DDDDD#DDDD#DDDDD#DDDD#C#................
.....#C#DDDD#DDDD#DDDDD#DDDD#DDDD#DDDDD#DDDD#DDDDD#DDDD#C#.........###....
.....#C#WWWW#WWWW#WWWWW#WWWW#WWWW#WWWWW#WWWWDWWWWW#WWWW#C#........SCP#....
.....#C#################################################CD##.....SSCP#....
.....#C#SDCCCCCCCCCCCCDCDDDCCCCCCCCCDCCCSCCCCCCCCCCCCCCCC##D#####DCCW#....
.....#C#C##CCCCCCCCCCCDCD#D###C######DC###S#####C#######CSCCCCCCCCCC##....
.....#C#C#################D###C#######C###S#####C#######C####S##S###......
########C######C######D#######C#######C###S#####C#######CSS#SS#SWWWW######
##########################################################################
"""

# The second, lower building at the left-hand end of the field.
LEFTBLDG = r"""
..............................
..............................
...###########################
...#CCCCCCCCCCCCCCCCCCCCCCSSS#
...#CWWWWSSSSSSWWWDWWWWDWWWWC#
...#CWWWWSWWWW#WWW#WWWW#WWWWC#
...#CWWWWSWWWW#WWW#WWWW#WWWWC#
...#CCCCCCCCCCCCCCCCCCCCCCCCC#
########DDDDDDDDDDDDDDDDDDDDD#
##############################
"""

# An airliner at a stand, tail-on, with a light mast beside it.
# Traced rather than drawn this time: the hand-drawn one read as a
# lump because everything identifying it lived in cells a phone
# does not have. At the reference's own resolution it is an
# aircraft.
STANDRIGHT = r"""
..........................###...........
...........................#............
................##.........#............
................#SS........#....########
....#...........#SSS.......#....#CCCCCC#
....##..........#SSSS......#....#C######
....#C############SSS##############DDWW#
....#CCCCCCCCCC#BBBBBBBBBBBBBBBBBBBBSWD#
####WWDDDDDDDDSS###BBBSDBSBBBBBSSSBBSWD#
#...#S################SSWW####SSSSSSSS##
.#####...............######SBB########..
......##................#.####....#.....
........####........................#...
"""

# Clouds. Three silhouettes, placed five times — the eye catches a
# repeated cloud long before it catches a shape. The trace
# separates the lit top from the shaded underside on its own,
# which is what stops a cloud reading as a white blob.
CLOUD_BIG = r"""
......................BBBBBBBB.............
....................BBBBBBBBBBB............
....................BBBBBBBBBBBP...........
.............BBBP.PBBBBBBBBBBBBBB..........
.............BBBP.PBBBBBBBBBBBBBB..........
...........BBBBBBBBBBBBBBBBBBBBBBBBBBBB....
...........BBBBBBBBBBBBBBBBBBBBBBBBBBBB....
.........BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB..
.........BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB..
.....BBBBBBBBBBPPBBBBBBBBBPPPPBPPBBBBBBBBBB
.....BBBBBBBBBBPPBBBBBBBBBPPPPBPPBBBBBBBBBB
PPP..PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP.
PPP..PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP..
.....PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP..
...........................................
"""


CLOUD_MID = r"""
..........PBBBBB..........
.........BBBBBBBBB........
.........BBBBBBBBB........
.......BBBBBBBBBBBBBBB....
.......BBBBBBBBBBBBBBB....
.....BBBBBBBBBBBBBBBBBBB..
.....BBBBBBBBBBBBBBBBBBB..
.PPPPBBBBPPPBBBBBBBBPPPPP.
.PPPPBBBBPPPBBBBBBBBPPPPP.
...PPPPPPPPPPPPPPPPPPP....
...PPPPPPPPPPPPPPPPPPP....
"""


CLOUD_SMALL = r"""
...........................
............BBB............
...........BBBBP...........
..........BBBBBBBB.........
......BBBBBBBBBBBBBBBB.....
......BBBBBBBBBBBBBBBB.....
....BBBBBBBBBBBBBBBBBBBB...
....BBBBBBBBBBBBBBBBBBBB...
BBBBBBPPPBBBBPPBBBPPPPPPPP.
BBBBBBPPPBBBBPPBBBPPPPPPPP.
..PPPPPPPPPPPPPPPPPPPPPP...
..PPPPPPPPPPPPPPPPPPPPPP...
"""

# The haze the reference lays along its horizon: its sky steps from a deep
# blue overhead to almost white at the skyline, and a scene painted in one
# flat blue loses the depth that step was doing.
#
# Far wider than the design width, and deliberately: every other motif is an
# object and wants a fixed size, but this one is background. At 360 it spanned
# a phone and floated as a stripe in the middle of a tablet. The band clips.
HAZE = r"""
HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH
HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH
HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH
PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP
PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP
PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP
"""

# One dash of white apron paint. Placed several times below rather than drawn
# as a row, so each can be kept clear of where the pet stands.
DASH = r"""
BBBBBBBB
"""

# The aircraft's shadow on the apron, and the only thing drawn in the shadow
# ink. Drawn from above rather than as a squashed copy of the side view,
# because that is the one thing a shadow on flat ground actually is.
SHADOW = r"""
.........XXXXXX.....
.......XXXXXXX......
......XXXXXXX.......
XXXXXXXXXXXXXXXXXX..
XXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXX..
......XXXXXXX.......
.......XXXXXXX......
.........XXXXXX.....
"""


def parse(grid):
    """A character grid to a list of (col, row, cols, rows, ink) rectangles.

    Runs are merged along the row and then down the column, so a flat area
    costs one rectangle rather than one per cell. Purely an output-size
    concern: the widget draws a ColoredBox per rectangle, and an unmerged
    terminal is six hundred of them.
    """
    rows = grid.strip('\n').split('\n')
    width = max(len(r) for r in rows)
    rows = [r.ljust(width, '.') for r in rows]

    cells = {}
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch not in CH:
                raise ValueError('unknown cell %r at %d,%d' % (ch, x, y))
            if CH[ch] is not None:
                cells[(x, y)] = CH[ch]

    runs = []
    for y in range(len(rows)):
        x = 0
        while x < width:
            ink = cells.get((x, y))
            if ink is None:
                x += 1
                continue
            end = x
            while cells.get((end + 1, y)) == ink:
                end += 1
            runs.append([x, y, end - x + 1, 1, ink])
            x = end + 1

    by_row = {}
    for run in runs:
        by_row.setdefault(run[1], []).append(run)

    merged, used = [], set()
    for run in runs:
        if id(run) in used:
            continue
        used.add(id(run))
        x, y, w, h, ink = run
        while True:
            below = [r for r in by_row.get(y + h, [])
                     if r[0] == x and r[2] == w and r[4] == ink
                     and id(r) not in used]
            if not below:
                break
            used.add(id(below[0]))
            h += 1
        merged.append((x, y, w, h, ink))

    return merged, width, len(rows)


# --- The scene ---------------------------------------------------------------
#
# name, grid, cell size, anchor x, anchor y, band, doc. The anchors are
# Flutter `Alignment` values inside their band, so -1 is left/top and 1 is
# right/bottom, and `y: 1.0` in the sky band puts a building's feet exactly on
# the horizon.
#
# The sun sits upper-left in every scene, so everything up there stays right
# of it and the low cloud stays under it.

MOTIFS = [
    # Anchors are Flutter `Alignment` values inside their band, so -1 is
    # left/top and 1 is right/bottom, and `y: 1.0` in the sky band stands a
    # building's feet exactly on the horizon.
    #
    # Every horizontal anchor below is the reference's own: the object's
    # centre as a fraction of its 224 cells, mapped to an alignment. What
    # cannot be carried across is the vertical framing — the reference is a
    # tall portrait whose horizon sits four fifths down and this scene's is at
    # five ninths — so heights are judged.
    #
    # Everything is drawn on a two-pixel cell, putting the scene at about
    # 1.24x the reference's proportions (224 cells at 2px against a 360-wide
    # design). Uniformly, so the objects keep their sizes relative to each
    # other; what changes is how close the viewer stands.
    ('_haze', HAZE, 6, '0.0', '1.0', 'sky',
     ['The pale band along the horizon.']),
    ('_cloudA', CLOUD_MID, 2, '-0.78', '-0.76', 'sky',
     ['Cloud, small and high on the left.']),
    ('_cloudB', CLOUD_SMALL, 2, '0.74', '-0.9', 'sky',
     ['Cloud, high on the right.']),
    ('_cloudC', CLOUD_BIG, 2, '-0.9', '-0.04', 'sky',
     ['Cloud, large, on the left.']),
    ('_cloudD', CLOUD_MID, 2, '0.94', '0.3', 'sky',
     ['Cloud, low on the right.']),
    ('_cloudE', CLOUD_SMALL, 2, '0.24', '0.62', 'sky',
     ['Cloud, lowest of the five, just above the roofline. Five clouds at',
      'three sizes is what gives a flat sky depth: the big ones read as',
      'near, the small ones as far, and no two are the same shape.']),
    ('_plane', PLANE, 2, '0.04', '-0.5', 'sky',
     ['The airliner, and the subject of the scene.']),
    ('_leftBuilding', LEFTBLDG, 2, '-0.92', '1.0', 'sky',
     ['The low building at the left-hand end of the field.']),
    ('_tower', TOWER, 2, '-0.66', '1.0', 'sky',
     ['The control tower, standing on the horizon.']),
    ('_terminal', TERMINAL, 2, '-0.16', '1.0', 'sky',
     ['The terminal.']),
    ('_standAircraft', STANDRIGHT, 2, '0.95', '1.0', 'sky',
     ['An airliner at a stand, off to the right.']),
    ('_dashA', DASH, 2, '-0.42', '-0.62', 'ground',
     ['Apron paint, in white. The reference marks its apron in two colours',
      'and a `SceneSpeck` can only carry one, so the yellow is specks and',
      'the white is these.']),
    ('_dashB', DASH, 2, '0.46', '-0.3', 'ground',
     ['']),
    ('_dashC', DASH, 2, '-0.5', '0.24', 'ground',
     ['']),
    ('_dashD', DASH, 2, '0.5', '0.62', 'ground',
     ['']),
    ('_planeShadow', SHADOW, 3, '-0.4', '-0.5', 'ground',
     ["The aircraft's shadow, thrown across the apron."]),
]


def emit(name, grid, cell, x, y, doc):
    blocks, cols, rows = parse(grid)
    # A cell is usually square, and for anything drawn it has to be. The
    # exception is the apron's slab joints: four hundred pixels long and one
    # across, which no square cell can say. Those pass a (across, down) pair.
    cw, ch = cell if isinstance(cell, tuple) else (cell, cell)
    lines = ['/// %s' % line for line in doc]
    lines.append('///')
    lines.append('/// Generated by `art_src/gen_airfield.py`. Edit the grid')
    lines.append('/// there, not the numbers here.')
    lines.append('const SceneMotif %s = SceneMotif(' % name)
    lines.append('  x: %s,' % x)
    lines.append('  y: %s,' % y)
    lines.append('  width: %d,' % (cols * cw))
    lines.append('  height: %d,' % (rows * ch))
    lines.append('  blocks: [')
    for bx, by, bw, bh, ink in blocks:
        args = '%d, %d, %d, %d' % (bx * cw, by * ch, bw * cw, bh * ch)
        if ink:
            args += ', ink: %d' % ink
        lines.append('    SceneMotifBlock(%s),' % args)
    lines.append('  ],')
    lines.append(');')
    return '\n'.join(lines), len(blocks)


def main():
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    parts, total = [], 0
    for name, grid, cell, x, y, _band, doc in MOTIFS:
        src, n = emit(name, grid, cell, x, y, doc)
        parts.append(src)
        total += n

    sky = [m[0] for m in MOTIFS if m[5] == 'sky']
    ground = [m[0] for m in MOTIFS if m[5] == 'ground']
    parts.append(
        '/// Everything in the sky, back to front: cloud, aircraft, then the\n'
        '/// buildings standing on the horizon.\n'
        'const List<SceneMotif> _airfieldSky = [\n'
        + ''.join('  %s,\n' % n for n in sky) + '];')
    parts.append(
        '/// Everything on the apron.\n'
        'const List<SceneMotif> _airfieldGround = [\n'
        + ''.join('  %s,\n' % n for n in ground) + '];')

    path = os.path.join(root, 'lib', 'constants', 'scenes.dart')
    s = io.open(path, encoding='utf-8').read()
    start = '// --- BEGIN GENERATED: art_src/gen_airfield.py ---'
    end = '// --- END GENERATED ---'
    if start not in s or end not in s:
        raise SystemExit('markers missing from %s' % path)
    head = s[:s.index(start) + len(start)]
    tail = s[s.index(end):]
    io.open(path, 'w', encoding='utf-8', newline='\n').write(
        head + '\n\n' + '\n\n'.join(parts) + '\n\n' + tail)
    print('wrote %d rectangles across %d motifs' % (total, len(MOTIFS)))


if __name__ == '__main__':
    main()
