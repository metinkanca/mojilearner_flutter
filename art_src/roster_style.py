"""Bring the traced roster onto the originals' six-unit drawing grid.

Works before SVG emission, so outlines remain filled, seam-free polygons.
The source canvas and animated eye boxes do not move.
"""
from collections import Counter


# Hand-cleaned silhouette, smile, throat and folded legs. No incidental shade
# flecks: this frog is three deliberate flat regions, like the original pets.
# Eyes are restored from the rig after expanding this six-unit drawing.
FROG = [
    '..........KKKK......KKKKK..',
    '.........KMMMMK....KMMMMMK.',
    '........KMMMMMK....KMMMMMMK',
    '........KMMMMMKKKKKKMMMMMMK',
    '........KMMMMMMMMMMMMMMMMMK',
    '.......KKMMMMMMMMMMMMMMMMMK',
    '......KKMMMMMMMMMMMMMMMMMMK',
    '......KMMMMMMMMMMMMMMMMMMMK',
    '......KMMMMLLKMMMMMMMMKLLMK',
    '.....KKMMMMLLLKMMMMMMKLLLKK',
    '....KKMMMMMLLLLKKKKKKLLLLK.',
    '...KKMMMMMMLLLLLLLLLLLLLKK.',
    '...KMMMMMMMMLLLLLLLLLLLKK..',
    '..KKMMMMMMMMMLLLLLLLLLKK...',
    '.KKMMMMMMMMMMLLLLLLLLKK....',
    'KKMMMMMKKMMMMLLLLLLLLK.....',
    'KMMMMMMMKMMMMKLLLLLMMK.....',
    'KMMMMMMMKMMMMKLLLLMMMK.....',
    'KMMMMMMMKMMMMKLLLMMMMK.....',
    '.KMMMMMMKMMMMKLLMMMMMK.....',
    '.KKMMMMMKMMMMKLMMMMMMKK....',
    '..KMMMMMKMMMMKKMMMMMMMK....',
    '..KKKKKKKKKKKKKKKKKKKKK....',
    '..KKKKKKKKKKKKKKKKKKKKK....',
]


def polish(rows, pet=None, step=3):
    h, w = len(rows), len(rows[0])
    source = [list(r) for r in rows]
    eyes = [(x, y) for y, row in enumerate(rows) for x, c in enumerate(row) if c == 'E']
    eye_left, eye_right = min(x for x, _ in eyes), max(x for x, _ in eyes)
    eye_bottom = max(y for _, y in eyes)
    eye_top = min(y for _, y in eyes)
    # Eyes are a separate animated layer, never input to silhouette cleanup.
    for y in range(h):
        for x in range(w):
            if source[y][x] == 'E':
                source[y][x] = 'M'
    coarse = []
    for y in range(0, h, step):
        line = []
        for x in range(0, w, step):
            counts = Counter(source[j][i] for j in range(y, min(y+step, h))
                             for i in range(x, min(x+step, w)))
            total = sum(counts.values())
            if counts['.'] > total / 2:
                value = '.'
            elif counts['K'] >= total / 3:
                value = 'K'
            else:
                counts.pop('.', None)
                value = counts.most_common(1)[0][0]
            line.append(value)
        coarse.append(line)
    ch, cw = len(coarse), len(coarse[0])
    # Most of the traced shadow color is a one-cell antialias fringe, not a
    # drawn shadow. Keep broad shadow regions (ears, tail bands, haunches),
    # dissolve only isolated thin remnants into the surrounding coat.
    seen_shade = set()
    for sy in range(ch):
        for sx in range(cw):
            if coarse[sy][sx] != 'S' or (sx, sy) in seen_shade:
                continue
            stack, cells = [(sx, sy)], []
            seen_shade.add((sx, sy))
            while stack:
                x, y = stack.pop()
                cells.append((x, y))
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x+dx, y+dy
                    if (0 <= nx < cw and 0 <= ny < ch and coarse[ny][nx] == 'S'
                            and (nx, ny) not in seen_shade):
                        seen_shade.add((nx, ny))
                        stack.append((nx, ny))
            width = max(x for x, _ in cells) - min(x for x, _ in cells) + 1
            height = max(y for _, y in cells) - min(y for _, y in cells) + 1
            if len(cells) < 4 or width == 1 or height == 1:
                for x, y in cells:
                    coarse[y][x] = 'M'
    # A complete one-cell ink contour, including concave corners and feet.
    outlined = [r[:] for r in coarse]
    for y in range(ch):
        for x in range(cw):
            if coarse[y][x] == '.':
                continue
            if any(not (0 <= x+dx < cw and 0 <= y+dy < ch) or
                   coarse[y+dy][x+dx] == '.'
                   for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                outlined[y][x] = 'K'
    # Shadows must be drawn regions, not inferred from proximity to ink:
    # ink also describes smiles, toes and nostrils, none of which casts a
    # vertical stripe. Keep the source's shading without inventing more.
    result = [[outlined[y//step][x//step] for x in range(w)] for y in range(h)]
    # Small enclosed ink components are facial drawing, not contour noise.
    # Keep their exact authored shape: resampling a two-cell mouth turns a
    # smile into a solid block and can join it to a nose.
    seen = set()
    for sy in range(h):
        for sx in range(w):
            if (sx, sy) in seen or source[sy][sx] != 'K':
                continue
            stack, cells, external = [(sx, sy)], [], False
            seen.add((sx, sy))
            while stack:
                x, y = stack.pop()
                cells.append((x, y))
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x+dx, y+dy
                    if not (0 <= nx < w and 0 <= ny < h) or source[ny][nx] == '.':
                        external = True
                    elif source[ny][nx] == 'K' and (nx, ny) not in seen:
                        seen.add((nx, ny))
                        stack.append((nx, ny))
            if external or not 8 <= len(cells) <= 200:
                continue
            x0, x1 = min(x for x, _ in cells), max(x for x, _ in cells)
            y0, y1 = min(y for _, y in cells), max(y for _, y in cells)
            if not (eye_left-6 <= (x0+x1)/2 <= eye_right+6 and
                    eye_top <= y0 and y1 <= eye_bottom+18):
                continue
            # Clear the *whole coarse tiles* touched by this feature, using
            # their majority background, then restore only its ink. Copying
            # a fine-grid bounding box restored trace debris too and left
            # one-unit color slivers along the edge of the box.
            tiles = {(x//step, y//step) for x, y in cells}
            for tx, ty in tiles:
                counts = Counter(source[y][x]
                                 for y in range(ty*step, min(h, (ty+1)*step))
                                 for x in range(tx*step, min(w, (tx+1)*step))
                                 if source[y][x] not in ('.', 'K'))
                if not counts:
                    # A tile completely inside the feature has no exposed
                    # backing once its ink is restored.
                    backing = 'M'
                else:
                    backing = counts.most_common(1)[0][0]
                for y in range(ty*step, min(h, (ty+1)*step)):
                    for x in range(tx*step, min(w, (tx+1)*step)):
                        result[y][x] = backing
            for x, y in cells:
                result[y][x] = 'K'
    if pet == 'frog':
        assert (w, h, step) == (81, 70, 3), 'frog source moved under the drawing'
        assert len(FROG) == ch and all(len(row) == cw for row in FROG)
        result = [[FROG[y//step][x//step] for x in range(w)] for y in range(h)]
    for y in range(h):
        for x in range(w):
            if rows[y][x] == 'E':
                result[y][x] = 'E'
    return [''.join(r) for r in result]
