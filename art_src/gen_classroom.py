"""Builds the quiz classroom out of the owner's four option panels.

    in   art_src/classroom-options.jpg       four 4:3 panels, OPTION 1..4
    out  art_src/classroom-editable.svg      the master you edit by hand
    then python art_src/build_classroom.py   -> assets/svgs/quiz_classroom.svg
                                             -> lib/constants/quiz_classroom_art.dart

The owner picked one part from each panel (2026-10-19):

    floor       OPTION 1     bookshelf   OPTION 2
    pot         OPTION 3     chalkboard  OPTION 4

The question is written on the board by the app, so the board's own chalk
("A B C / 1 + 2 = 3") is rubbed out and only the eraser and the stick on its
tray are kept. And it is stretched, frame and all, to fill the wall between
the shelf and the pot: a question needs room.

Reading the sheet is the scenario rooms' recipe (gen_city.py): a 3x3 median,
the nearest colour per pixel, then 3 px cells taking their commonest colour,
ink winning ties, and slivers too thin to hold a 2x2 square tidied away (ink
excepted: the floor's plank seams are slanted lines one cell wide). The
outline comes out two to three cells thick.

The room is laid out for the quiz screen, top to bottom:

    the board, up high and nearly the full width of the picture (the owner,
        2026-10-19: "keep the blackboard high up compared to everything
        else... extend it to the sides properly"), WALL_ABOVE rows from the top
        (the screen paints flat wall above the picture)
    under it the shelf and the pot, standing on the floor at the two sides,
        their tops just clear of the board's tray
    the pets' feet FEET_ABOVE_BOTTOM rows up from the bottom, at a third and
        two thirds of the width, in the space between the shelf and the pot
    the floor: panel 1's planks, one more row of them, and a last plank with
        no seams in it (the screen paints flat floor below the picture)

This is a one-time conversion. After it, edit classroom-editable.svg by hand;
this script refuses to overwrite it (so it cannot eat your edits) unless given
--force.

Usage:  python gen_classroom.py [--force] [--out path] [--preview out.png]
                                [--panels DIR]
"""
import argparse
import sys
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage as ndi

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import scene_art  # noqa: E402
from gen_city import Pal, snap, vote, tidy  # noqa: E402

SHEET = HERE / 'classroom-options.jpg'
OUT = HERE / 'classroom-editable.svg'
DART = HERE.parent / 'lib' / 'constants' / 'quiz_classroom_art.dart'
ASSET = 'assets/svgs/quiz_classroom.svg'

PALETTE = scene_art.QUIZ_CLASSROOM
WALL, WOOD, DARK, BOARD, CORAL, SKY, LEAF, FELT, INK = range(len(PALETTE))

# Sheet pixels a cell.
CELL = 3

# The sheet's own colours, measured as medians of flat areas, in the order of
# PALETTE. Snapping to these rather than to the palette's hexes reads the
# sheet better: the tool drew the wall a little yellower, the ink blacker.
# The chalk is a hair off the wall and is read as wall.
READ = Pal([
    ('wall', '#f2e1c3'), ('wood', '#c48856'), ('dark', '#a46e44'),
    ('board', '#3f6654'), ('coral', '#eb8571'), ('sky', '#a2d5eb'),
    ('leaf', '#8bbe6a'), ('felt', '#76716d'), ('ink', '#060504'),
])
NOT_FELT = [n for n in READ.names if n != 'felt']

# The eraser's grey felt is almost exactly what a wall-to-ink edge blends to,
# so grey is only read inside the eraser: panel 4's pixels (x0, y0, x1, y1).
ERASER_BOX = (4, (415, 490, 520, 527))

# Where each piece is, roughly: (panel, colours that find it, columns as
# fractions of the width, margin). The box round those colours, grown by the
# margin, is what the piece is cut out of, so the margin has to clear all of
# the piece: the board's tray reaches 15 cells past its green.
PIECES = {
    'shelf': (2, [DARK], (0.0, 0.33), 12),
    'pot': (3, [LEAF, CORAL], (0.72, 1.0), 12),
    'board': (4, [BOARD], (0.2, 0.8), 22),
}
FLOOR_PANEL = 1

# The canvas, in cells.
HEIGHT = 367            # the picture's height: 282 + 85. The extra rows are the
                        # board's: it lives above the shelf and the pot now, so it is
                        # as wide as the picture and as tall as the wall over them. 85
                        # is what 360x780 has to spare once the answers and Continue
                        # are on screen (120 clipped the second row of answers)
PET_SPAN = 141          # rows from the top of the pets' canvas to their feet. Fixed,
                        # not tied to the board: the pets are the size they were
WALL_ABOVE = 4          # plain wall over the board (the owner wanted the board up
                        # high, 2026-10-19: no empty wall over it)
EDGE = 4                # wall between the shelf or the pot and the picture's side
BOARD_EDGE = 6          # wall between the board and the picture's sides
FEET_ABOVE_BOTTOM = 14  # floor under the pets' feet, for their shadows
LAST_PLANK = 19         # the plain plank the floor ends in
GAP = 8                 # wall between the board's tray and the tops of the shelf and the pot

GONE = -1


# --- reading the sheet -----------------------------------------------------------

def read_panels():
    """Each panel as cells of PALETTE classes."""
    sheet = np.asarray(Image.open(SHEET).convert('RGB')).astype(np.int32)
    out = {}
    for k, (x0, y0, x1, y1) in panel_boxes(sheet).items():
        part = sheet[y0:y1, x0:x1]
        classes = snap(part, READ, NOT_FELT)
        panel, (ex0, ey0, ex1, ey1) = ERASER_BOX
        if k == panel:
            classes[ey0:ey1, ex0:ex1] = snap(part[ey0:ey1, ex0:ex1], READ)
        cells = vote(classes, np.ones(classes.shape, bool), CELL, len(READ), prefer=INK)
        out[k] = tidy(cells, 2, thin_ok=(INK,))
    return out


def panel_boxes(sheet):
    """The four panels, (x0, y0, x1, y1), found from the black frame and the
    dividers between them."""
    dark = sheet.sum(2) < 150

    def runs(frac):
        found, start = [], None
        for i, f in enumerate(frac):
            if f > 0.8 and start is None:
                start = i
            elif f <= 0.8 and start is not None:
                found.append((start, i))
                start = None
        if start is not None:
            found.append((start, len(frac)))
        return found

    def split(found):
        # the frame at either end, and the divider: the thickest run between.
        # The floor's plank lines run dark right across both panels too, but
        # they are thinner than the divider.
        middle = max(found[1:-1], key=lambda r: r[1] - r[0])
        return found[0][1], middle[0], middle[1], found[-1][0]

    x0, x1, x2, x3 = split(runs(dark.mean(0)))
    y0, y1, y2, y3 = split(runs(dark.mean(1)))
    return {1: (x0, y0, x1, y1), 2: (x2, y0, x3, y1),
            3: (x0, y2, x1, y3), 4: (x2, y2, x3, y3)}


# --- the floor -------------------------------------------------------------------

def floor_line(cells):
    """(top, bottom) rows of the ink line where the wall meets the floor: the
    first long ink line with wall over it and none under it. (The board's tray
    is a long ink line too, but it has wall under it.)"""
    ink = (cells == INK).mean(1)
    wall = (cells == WALL).mean(1)
    for top in range(6, len(ink) - 8):
        if ink[top] > 0.5 and wall[top - 6:top].mean() > 0.4 and \
                wall[top + 3:top + 8].mean() < 0.05:
            bottom = top
            while ink[bottom + 1] > 0.5:
                bottom += 1
            return top, bottom + 1
    sys.exit('no floor line found')


def plank_lines(cells, below):
    """(top, bottom) of each plank line under row `below`: rows of ink right
    across the floor."""
    ink = (cells == INK).mean(1)
    lines, r = [], below
    while r < len(ink):
        if ink[r] > 0.9:
            top = r
            while r + 1 < len(ink) and ink[r + 1] > 0.9:
                r += 1
            lines.append((top, r + 1))
        r += 1
    return lines


def seams_only(band):
    """A row of planks with only its seams left: a seam runs the full height of
    its row, and the legs and feet of what stood on it do not."""
    out = band.copy()
    lab, n = ndi.label(band == INK, structure=scene_art.S8)
    seams = [k for k in range(1, n + 1) if (lab[0] == k).any() and (lab[-1] == k).any()]
    out[~np.isin(lab, seams)] = WOOD
    return out


def floor_rows(cells):
    """The floor, from the top of its line down: panel 1's two whole plank
    rows with what stood on them wiped, a third (the first again, mirrored, so
    the seams do not line up), and the plain last plank."""
    f0, f1 = floor_line(cells)
    lines = plank_lines(cells, f1)
    if len(lines) < 2:
        sys.exit('expected two plank lines under the floor line, found %d' % len(lines))
    (a0, a1), (b0, b1) = lines[:2]
    w = cells.shape[1]

    def line(n):
        return np.full((n, w), INK, np.int8)

    first = seams_only(cells[f1:a0])
    second = seams_only(cells[a1:b0])
    return np.vstack([
        line(f1 - f0), first, line(a1 - a0), second, line(b1 - b0),
        first[:, ::-1], line(a1 - a0),
        np.full((LAST_PLANK, w), WOOD, np.int8),
    ])


# --- the pieces ------------------------------------------------------------------

def locate(cells, classes, columns, above, pad):
    """Box round the cells of `classes` in a band of columns, above row
    `above`, grown by `pad` cells of whatever is round it."""
    h, w = cells.shape
    x0, x1 = int(columns[0] * w), int(columns[1] * w)
    m = np.isin(cells, classes)
    m[:, :x0] = False
    m[:, x1:] = False
    m[above:] = False
    ys, xs = np.nonzero(m)
    return (max(0, xs.min() - pad), max(0, ys.min() - pad),
            min(w, xs.max() + 1 + pad), min(h, above + 24))


def cut_out(cells, box):
    """The piece in `box` (x0, y0, x1, y1) as its own little array, GONE round
    it, and where its corner was: what its outline closes off from the wall
    and floor about it, with the outline itself. The box needs a margin of
    wall or floor all round."""
    x0, y0, x1, y1 = box
    part = cells[y0:y1, x0:x1]
    open_ = part != INK
    lab, _ = ndi.label(open_, structure=scene_art.S4)
    rim = np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))
    outside = np.isin(lab, rim[rim > 0])
    inside = open_ & ~outside
    # the outline is the ink within an outline's width of the inside. This
    # keeps a few cells of the floor line where it meets a leg, which is
    # harmless: the piece is set down on a floor line in the same rows.
    outline = ~open_ & ndi.binary_dilation(inside, structure=scene_art.S8, iterations=4)
    mask = ndi.binary_fill_holes(inside | outline)
    piece = np.where(mask, part, GONE).astype(np.int8)
    ys, xs = np.nonzero(mask)
    return (piece[ys.min():ys.max() + 1, xs.min():xs.max() + 1],
            (x0 + xs.min(), y0 + ys.min()))


def face_of(cells):
    """(top, bottom, left, right) of the board's green, inclusive: the biggest
    patch of it."""
    green = cells == BOARD
    lab, n = ndi.label(green, structure=scene_art.S4)
    biggest = int(np.argmax(ndi.sum(green, lab, range(1, n + 1)))) + 1
    ys, xs = np.nonzero(lab == biggest)
    return ys.min(), ys.max(), xs.min(), xs.max()


def rub_out_chalk(board):
    """The board with its writing gone: everything on the green that does not
    stand on the bottom of it. The eraser and the stick do, and are kept."""
    top, bottom, left, right = face_of(board)
    out = board.copy()
    face = out[top:bottom + 1, left:right + 1]
    lab, _ = ndi.label(face != BOARD, structure=scene_art.S8)
    rubbed = 0
    for i, sl in enumerate(ndi.find_objects(lab), 1):
        if sl[0].stop >= face.shape[0] - 1:
            continue
        face[lab == i] = BOARD
        rubbed += 1
    # The eraser's top is a tan the sheet's colours read as coral; a wooden
    # back reads better as an eraser on a wooden tray, and keeps the room's
    # colours down.
    out[out == CORAL] = WOOD
    return out, rubbed


def stretch(board, width, height):
    """The board grown to `width` x `height` cells by repeating one column and
    one row through its green. The frame, the tray with its stepped corners,
    and what stands on the tray keep their sizes; the eraser stays by the left
    end and the stick by the right."""
    top, bottom, left, right = face_of(board)
    h, w = board.shape
    if width < w or height < h:
        sys.exit('the board can only grow: it is %dx%d, asked for %dx%d' % (w, h, width, height))
    face = board[top:bottom + 1, left:right + 1] != BOARD
    # a row above everything standing on the tray, a column in the widest
    # gap between the things standing there
    rows = np.nonzero(face.any(1))[0]
    row = top + (rows.min() if len(rows) else bottom - top) // 2
    cols = np.concatenate([[-1], np.nonzero(face.any(0))[0], [right - left + 1]])
    i = int(np.argmax(np.diff(cols)))
    col = left + (cols[i] + cols[i + 1]) // 2
    board = np.concatenate([board[:, :col], np.repeat(board[:, col:col + 1], width - w + 1, 1),
                            board[:, col + 1:]], 1)
    return np.concatenate([board[:row], np.repeat(board[row:row + 1], height - h + 1, 0),
                           board[row + 1:]], 0)


# --- the room --------------------------------------------------------------------

def compose(cells):
    width = cells[FLOOR_PANEL].shape[1]
    floor = floor_rows(cells[FLOOR_PANEL])
    floor_top = HEIGHT - len(floor)
    canvas = np.full((HEIGHT, width), WALL, np.int8)
    canvas[floor_top:] = floor

    pieces = {}
    for name, (panel, colours, columns, pad) in PIECES.items():
        line, _ = floor_line(cells[panel])
        piece, (x, y) = cut_out(cells[panel],
                                locate(cells[panel], colours, columns, line, pad))
        pieces[name] = (piece, x, y - line)        # y: rows below its floor line

    # The shelf and the pot out by the sides, under the board.
    shelf, _, shelf_dy = pieces['shelf']
    pot, _, pot_dy = pieces['pot']
    sx, px = EDGE, width - EDGE - pot.shape[1]
    tops = []
    for piece, x, dy in ((shelf, sx, shelf_dy), (pot, px, pot_dy)):
        y = floor_top + dy
        tops.append(y)
        h, w = piece.shape
        view = canvas[y:y + h, x:x + w]
        view[piece >= 0] = piece[piece >= 0]

    # The board: across the top, down to just above the highest of them.
    board_bottom = min(tops) - GAP
    board, rubbed = rub_out_chalk(pieces['board'][0])
    board = stretch(board, width - 2 * BOARD_EDGE, board_bottom - WALL_ABOVE)
    h, w = board.shape
    view = canvas[WALL_ABOVE:WALL_ABOVE + h, BOARD_EDGE:BOARD_EDGE + w]
    view[board >= 0] = board[board >= 0]
    return canvas, rubbed


# --- where things are, for the screen ----------------------------------------------

def measure(cells):
    """The numbers the quiz screen lays itself out by, in cells (= the
    picture's viewBox units), read off the finished picture so they stay true
    after a hand edit."""
    h, w = cells.shape
    top, bottom, left, right = face_of(cells)
    mid = (left + right) // 2

    # what stands on the tray (the eraser, the stick): the clear green ends
    # at the top of the tallest of them
    face = cells[top:bottom + 1, left:right + 1]
    standing = np.nonzero((face != BOARD).any(1))[0]
    face_bottom = top + (standing.min() if len(standing) else bottom + 1 - top)

    col = cells[:, mid]
    frame_top = top
    while frame_top > 0 and col[frame_top - 1] != WALL:
        frame_top -= 1
    board_bottom = bottom + 1
    while board_bottom < h and col[board_bottom] != WALL:
        board_bottom += 1

    floor = board_bottom
    while floor < h and not (col[floor] == INK and col[floor - 1] == WALL):
        floor += 1
    if floor >= h:
        sys.exit('no floor line under the board')

    # The screen cuts the picture here and slides everything under the cut down
    # on a tall phone, so the cut needs a row of plain wall right across: the
    # middle of the first such run under the board's tray.
    clear = [r for r in range(board_bottom, floor) if (cells[r] == WALL).all()]
    if not clear:
        sys.exit('no row of plain wall between the board and the things under it')
    run_end = clear[0]
    while run_end + 1 in clear:
        run_end += 1
    wall_cut = (clear[0] + run_end + 1) // 2

    # The screen grows the board on a tall phone by repeating one row of its
    # clear green (the picture's own stretch does the same), so the row has to
    # be one of a run of identical rows: the middle of the longest run of them
    # in the face, with a row of the same on each side for the overlap.
    best = (0, top)
    start = top
    for r in range(top + 1, face_bottom + 1):
        if r == face_bottom or not (cells[r] == cells[start]).all():
            if r - start > best[0]:
                best = (r - start, start)
            start = r
    if best[0] < 3:
        sys.exit('no run of identical rows in the board\'s green to grow it by')
    grow_row = best[1] + best[0] // 2

    return dict(
        width=w, height=h,
        faceLeft=left, faceTop=top, faceRight=right + 1, faceBottom=face_bottom,
        frameTop=frame_top, boardBottom=board_bottom, wallCut=wall_cut,
        growRow=grow_row, floorLine=floor, standRow=h - FEET_ABOVE_BOTTOM, petsTop=h - FEET_ABOVE_BOTTOM - PET_SPAN,
        teacherX=w / 3, learnerX=2 * w / 3,
    )


def write_dart(cells, out=DART):
    """The whole of the screen's table, from the finished picture."""
    m = measure(cells)
    v = {k: '%.1f' % val for k, val in m.items()}
    out.write_text('''// GENERATED by art_src/gen_classroom.py - do not edit by hand.
//
// Rewritten by art_src/build_classroom.py from the finished picture each time
// it is built, so the numbers follow a hand edit of classroom-editable.svg.
//
// Where things are in the classroom picture, in its viewBox units.
abstract final class QuizClassroomArt {
  static const String asset = '%(asset)s';

  /// The picture's viewBox.
  static const double width = %(width)s;
  static const double height = %(height)s;

  /// The board's clear green face, where the question is written: inside the
  /// frame, down to the top of the eraser standing on the tray.
  static const double faceLeft = %(faceLeft)s;
  static const double faceTop = %(faceTop)s;
  static const double faceRight = %(faceRight)s;
  static const double faceBottom = %(faceBottom)s;

  /// The top of the board's frame, which the question badge sits across.
  static const double frameTop = %(frameTop)s;

  /// The bottom of the board's tray. The pets stand below it.
  static const double boardBottom = %(boardBottom)s;

  /// A row of plain wall across the whole picture, between the board and the
  /// shelf and pot. The screen cuts the picture here: the board stays at the
  /// top and everything below the cut moves down by whatever height the phone
  /// has spare.
  static const double wallCut = %(wallCut)s;

  /// One row of the board's clear green, with identical rows on both sides of
  /// it. On a tall phone the screen repeats it, which makes the board taller:
  /// the frame above and the tray with its eraser below keep their sizes.
  static const double growRow = %(growRow)s;

  /// The top of the line where the wall meets the floor.
  static const double floorLine = %(floorLine)s;

  /// Where the pets' feet are, the top of the canvas they are drawn in (the
  /// hat headroom over the ears is empty), and the middles of the two of them.
  static const double standRow = %(standRow)s;
  static const double petsTop = %(petsTop)s;
  static const double teacherX = %(teacherX)s;
  static const double learnerX = %(learnerX)s;
}
''' % dict(v, asset=ASSET), encoding='utf-8', newline='\n')
    return m


# --- output ----------------------------------------------------------------------

def write_master(cells, out):
    """The editable SVG: the wall as a rect, then one path per other colour,
    disjoint and exact (what you edit is exactly what you see)."""
    h, w = cells.shape
    parts = ['<rect id="%s" width="%d" height="%d" fill="%s"/>' % (
        PALETTE.labels[0], w, h, PALETTE.hexes[0])]
    for cls in range(1, len(PALETTE)):
        if (cells == cls).any():
            parts.append('<path id="%s" fill="%s" fill-rule="evenodd" d="%s"/>' % (
                PALETTE.labels[cls], PALETTE.hexes[cls],
                scene_art.path_data(cells == cls)))
    out.write_text(
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %d %d" '
        'shape-rendering="crispEdges">\n%s\n</svg>\n' % (w, h, '\n'.join(parts)),
        encoding='utf-8', newline='\n')


def preview(cells, path, scale=3):
    colours = np.array([[int(hx[i:i + 2], 16) for i in (1, 3, 5)]
                        for hx in PALETTE.hexes] + [[255, 0, 255]], np.uint8)
    Image.fromarray(colours[cells]).resize(
        (cells.shape[1] * scale, cells.shape[0] * scale), Image.NEAREST).save(path)


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--out', type=Path, default=OUT)
    ap.add_argument('--force', action='store_true',
                    help='overwrite the master even though it may hold hand edits')
    ap.add_argument('--preview', type=Path,
                    help='also write the result as a PNG, 3x, to look at')
    ap.add_argument('--panels', type=Path,
                    help='also write each panel as read, to this folder')
    opts = ap.parse_args()
    if opts.out.exists() and not opts.force:
        sys.exit('%s exists and may hold hand edits; pass --force to replace it'
                 % opts.out.name)

    cells = read_panels()
    if opts.panels:
        for k, c in cells.items():
            preview(c, opts.panels / ('panel%d_cells.png' % k))
    canvas, rubbed = compose(cells)
    write_master(canvas, opts.out)
    print('wrote %s: %d x %d cells, %d chalk marks rubbed out' % (
        opts.out.name, canvas.shape[1], canvas.shape[0], rubbed))
    for k, v in measure(canvas).items():
        print('  %-12s %g' % (k, v))
    for what, spots in scene_art.lint(canvas, PALETTE):
        print('  heads up: %d %s: %s' % (len(spots), what, ', '.join(spots[:8])))
    if opts.preview:
        preview(canvas, opts.preview)
    print('now: python art_src/build_classroom.py')


if __name__ == '__main__':
    main()
