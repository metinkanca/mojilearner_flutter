"""Build the app's sprite layers for the 24 roster pets.

Contours and internal features come from pet_goal.png through goal_trace.py.
The old roster supplies the existing canvas dimensions and palette. Borders
are six art units thick, matching the original pets; reference gradients are
reduced to flat coat and marking colors. lib_cells emits deseamed SVG layers.

    python art_src/gen_roster_pets.py --sync-dart

The optional flag also updates animated eye geometry and accessory anchors.

Four things are decided here and are worth reading before changing:

**CELL = 2.** The roster is drawn about four times finer than the cat (~100
cells across a body, against the cat's ~25), and a cell has to be a whole
number of art units or the coordinates leave the pixel grid and deseam has
nothing to snap to. That leaves 1 (a pet half the cat's size -- smaller than
the chick) or 2 (~200 units across, the cat's own width). So 2, and these pets
read as wide and low next to the cat, which is what they are.

**Two pets do not fit.** The canvas is 222 units wide and every layer is
scaled by it (`_kCanvas` in character_sprite.dart), so it is a hard limit. At
CELL=2 the axolotl comes to 234 and the seal to 230 -- both are long, low
animals. They are narrowed by dropping whole columns that are identical to the
column on their left, which shortens a flat run by a cell and changes no
corner and no feature. Both have more such columns than they need to lose.

**Which fills recolour.** `recolorBodyLayer` moves MAIN to the player's coat,
SHADE to a darkened copy of it and LIGHT to a lightened one; everything else it
leaves alone. So each pet declares which of its fills are coat and which are
markings, and the markings stay -- the panda keeps its black, the penguin its
beak, the raccoon its mask. This follows the parrot (see `gen_parrot.py`), the
first pet that was deliberately not three-tone.

**Where the accessories sit.** Each pet's hat, face and neck offsets are
measured off its own art rather than eyeballed -- see `dart_for` -- and written
into the Dart this prints. They are not clamped here: the sprite does that at
the point of use, because how far a piece can move depends on how wide that
piece is drawn (`accessoryPlacementOnCanvas`).
"""
import os
import re
from pathlib import Path
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import fix_roster                      # noqa: E402
import lib_cells                       # noqa: E402
import lib_roster as L                 # noqa: E402
import split_roster                    # noqa: E402
import goal_trace                      # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))

CELL = 2
MAX_CANVAS_W = 222                     # lib_cells.VIEWBOX width

# Per pet: which of its fills are coat, as (main, shade, light). Each slot
# takes one fill, a tuple of fills, or None. Anything a pet does not name here
# stays exactly as drawn, which is how it keeps being that animal through a
# recolour -- the panda's black, the raccoon's mask, the penguin's beak.
#
# MAIN is the colour that reads as "this animal's coat", which is not always
# the one with the most cells: the penguin's white front outsizes its back, and
# the back is the penguin. SHADE has to be darker than MAIN and LIGHT paler,
# because the app derives them as darken(coat, 0.72) and lighten(coat, 0.45) --
# so a second tone on the wrong side of the coat belongs in the other slot.
#
# The comment on each line is what is being deliberately left as a marking.
ROLES = {
    #             main        shade       light       markings kept as drawn
    'fox':       ('#ff8c22', '#d77120', None),       # cream muzzle and tail tip
    'raccoon':   ('#918e86', '#49463f', '#c5c0b5'),
    'red-panda': ('#c5622c', '#94451f', None),       # cream facial markings
    'otter':     ('#b68a5c', None,      '#ffe0a7'),
    'hedgehog':  ('#62482f', None, '#8c6743'),       # pale face, lighter spines
    'chinchilla':('#aaa6b0', None,      '#d9d5dc'),  # pink ears
    'squirrel':  ('#f19330', '#b36b2c', '#ffcc83'),
    'mouse':     ('#b8b3b0', None,      '#e0d9cf'),  # pink ears and tail
    'bat':       ('#77677f', None,      None),       # pink ears
    'fennec':    ('#ffe6b4', None,      None),       # pink ears
    'skunk':     ('#383837', None, '#60605a'),       # lighter fur, white stripe
    'beaver':    ('#a87b42', '#7d5734', '#d5ab68'),  # pale teeth
    'koala':     ('#a5a5a0', '#56534e', '#dcd5c3'),
    'wombat':    ('#a57b4e', '#89613d', None),
    'panda':     ('#f5eddb', None,      None),       # the black patches
    'sloth':     ('#bc915e', '#78583b', '#f6d7a2'),
    'capybara':  ('#d69b43', ('#815832', '#b4803a'), None),
    'piglet':    ('#f7b6b0', '#db938e', None),
    'frog':      ('#91c643', '#599035', '#cde77a'),
    'axolotl':   ('#facac0', '#f096a3', None),       # the pink gill frills
    'gecko':     ('#acd970', '#79b24d', '#d7ed99'),
    'chameleon': ('#b9d444', '#8eaf32', None),
    'seal':      ('#9ca8bc', '#6b7993', '#e0ded6'),
    'penguin':   ('#292e3e', None,      None),       # cream bib, orange beak/feet
}

# The natural coat each pet is born in, so a fox arrives orange rather than in
# the house grey. Read by the app as that pet's default `bodyColor`; a player
# who recolours overrides it, and the roster's own MAIN is the honest default.
NATURAL_COAT = {pet: roles[0] for pet, roles in ROLES.items()}

# Pets whose eye pair the detector below gets wrong, and what they really are.
# `None` for the second box means the pet shows one eye.
#
# The panda's eyes are inside its black eye patches, and the detector finds the
# patches; blinking a whole patch would be a pet shutting two black ovals. The
# capybara's head is turned far enough that only one eye shows -- what the
# detector pairs up on its muzzle is a pair of nostrils.
EYE_OVERRIDES = {
    'panda': ((39, 33, 5, 7), (66, 33, 5, 7)),
    'capybara': ((64, 26, 5, 10), None),
}


def _cols(grid, W, H):
    return [tuple(grid[y][x] for y in range(H)) for x in range(W)]


def narrow(grid, W, H, drop):
    """Remove `drop` columns that duplicate the column to their left.

    Spread out, so a long body loses a cell here and a cell there rather than
    a visible pinch in one place. Raises if the art has too few to give.
    """
    cols = _cols(grid, W, H)
    dup = [i for i in range(1, len(cols)) if cols[i] == cols[i - 1]]
    if len(dup) < drop:
        raise SystemExit('needs to lose %d columns but only %d duplicate' % (drop, len(dup)))
    step = len(dup) / float(drop)
    take = {dup[int(i * step)] for i in range(drop)}
    while len(take) < drop:                       # rounding collisions
        take |= {c for c in dup if c not in take}
        take = set(sorted(take)[:drop])
    keep = [i for i in range(len(cols)) if i not in take]
    out = [[grid[y][x] for x in keep] for y in range(H)]
    return out, len(keep)


def find_eyes(grid, W, H):
    """The pet's eye cells, as one or two boxes.

    An eye in this art is a blob of outline colour that no background touches,
    sitting on the face with coat all round it. Nose and mouth are blobs too,
    but they are one blob low on the face, while the eyes are a matched pair
    side by side at the same height -- so the pair is what identifies them.
    """
    import collections
    cands = []
    for comp in L.components(grid, W, H, lambda f: f == L.OUTLINE):
        if not (20 <= len(comp) <= 70):
            continue
        x0, y0, x1, y1 = L.bbox(comp)
        if y0 > H * 0.62:
            continue
        s = set(comp)
        nb = collections.Counter()
        for x, y in comp:
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if (nx, ny) not in s:
                    nb[grid[ny][nx] if 0 <= nx < W and 0 <= ny < H else None] += 1
        if None in nb:                       # touches the outside: silhouette
            continue
        if len(comp) / float((x1 - x0) * (y1 - y0)) < 0.70:
            continue                         # not a solid cell: nose or mouth
        cands.append((x0, y0, x1 - x0, y1 - y0))
    cands.sort()
    for i in range(len(cands)):
        for j in range(len(cands) - 1, i, -1):
            a, b = cands[i], cands[j]
            if abs(a[1] - b[1]) <= 1 and abs(a[3] - b[3]) <= 1 and b[0] > a[0] + a[2]:
                return a, b
    if len(cands) == 1:
        return cands[0], None
    raise SystemExit('no eye pair found among %s' % (cands,))


def square_up(a, b):
    """One size and one height for the pair, so a blink scales them together.

    `PetEyeGeometry` carries a single w/h for both eyes, and the trace left
    some pairs a cell apart. Growing the smaller to match is the house rule --
    on a face, symmetry beats faithfulness to the reference.
    """
    if b is None:
        return a, None, a[2], a[3], a[1]
    y = min(a[1], b[1])
    h = max(a[1] + a[3], b[1] + b[3]) - y
    w = max(a[2], b[2])
    return (a[0], y, w, h), (b[0], y, w, h), w, h, y


def _as_set(v):
    if v is None:
        return set()
    return {v} if isinstance(v, str) else set(v)


def rows_for(pet, grid, W, H, eyes):
    """The cell map lib_cells wants: one letter per cell, '.' for nothing."""
    main, shade, light = ROLES[pet]
    roles = [('M', _as_set(main), lib_cells.MAIN),
             ('S', _as_set(shade), lib_cells.SHADE),
             ('L', _as_set(light), lib_cells.LIGHT)]

    letters = {L.OUTLINE: 'K'}
    palette = {'K': lib_cells.OUTLINE, 'E': lib_cells.OUTLINE}
    for letter, fills, canonical in roles:
        if not fills:
            continue
        palette[letter] = canonical
        for f in fills:
            letters[f] = letter

    present = {grid[y][x] for y in range(H) for x in range(W)} - {None}
    missing = set().union(*(f for _, f, _ in roles)) - present
    if _as_set(main) & missing:
        raise SystemExit('%s: ROLES names %s, which the art does not use'
                         % (pet, sorted(missing)))

    # Whatever is left is a marking, and keeps the colour it was drawn in.
    marks = 'ABCDF'
    for i, fill in enumerate(sorted(present - set(letters))):
        letters[fill] = marks[i]
        palette[marks[i]] = fill

    rows = [[('.' if grid[y][x] is None else letters[grid[y][x]]) for x in range(W)]
            for y in range(H)]
    for box in eyes:
        if box is None:
            continue
        x0, y0, w, h = box
        for y in range(y0, y0 + h):
            for x in range(x0, x0 + w):
                rows[y][x] = 'E'
    # Back-most first, so deseam paints coat under markings under outline.
    order = [c for c in 'MSL' if c in palette] + \
            [c for c in palette if c in marks] + ['K', 'E']
    return [''.join(r) for r in rows], {c: palette[c] for c in order}


def const_name(pet):
    return 'k%sEyes' % ''.join(p.capitalize() for p in pet.split('-'))


def dart_name(pet):
    return ''.join(p.capitalize() for p in pet.split('-'))


# Where the cat -- the pet all the accessory art was drawn on -- keeps the
# three things an accessory is seated against. From `pet-sprite-render-loop`
# and kCatEyes: head x 45..174, skull top y=34 (its ears run above that and a
# wide hat simply covers them), eyes y 69..89 at x 80..157, mouth y 89..113,
# chest top y=141.
CAT_HEAD_CX = 109.5
CAT_SKULL_TOP = 34
CAT_EYE_CX = 118.5
CAT_EYE_TOP = 69
CAT_MOUTH_BOTTOM = 113
CAT_CHEST_TOP = 141
# The cat's face sits right of its head's centre -- the family look, not a bug
# (see the rabbit's note in `cell-map-pets`). Used to read a head's centre back
# out of where its eyes are.
CAT_FACE_OFFSET = CAT_EYE_CX - CAT_HEAD_CX


def measure(grid, W, H, eyes, cell, x0, y0):
    """The three seating anchors, in canvas art units.

    Returns (head centre x, skull top y, eye centre x, eye top y, mouth bottom
    y). The skull top is read straight up the column between the eyes, which
    finds the top of the head rather than the top of an ear -- ears on these
    pets are out at the sides, and a hat covers them as it does the cat's.
    """
    a, b = eyes
    ex0 = a[0]
    ex1 = (b[0] + b[2]) if b else (a[0] + a[2])
    eye_cx_cells = (ex0 + ex1) / 2.0

    col = int(round(eye_cx_cells))
    col = max(0, min(W - 1, col))
    skull = next((y for y in range(H) if grid[y][col] is not None), 0)

    # The muzzle: the outline blob under the eyes that is not a solid cell.
    eye_bottom = a[1] + a[3]
    mouth = eye_bottom
    for comp in L.components(grid, W, H, lambda f: f == L.OUTLINE):
        if not (8 <= len(comp) <= 200):
            continue
        bx0, by0, bx1, by1 = L.bbox(comp)
        if by0 < eye_bottom or by0 > H * 0.8:
            continue
        if not (ex0 - 6 <= (bx0 + bx1) / 2 <= ex1 + 6):
            continue
        if any(not (0 <= x + dx < W and 0 <= y + dy < H) or grid[y + dy][x + dx] is None
               for x, y in comp for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
            continue
        mouth = max(mouth, by1)

    # A thicker mouth may join the cheek outline, so it is no longer an
    # isolated component. Read the central muzzle band in that case.
    if mouth == eye_bottom:
        left = max(0, int(eye_cx_cells - max(3, (ex1-ex0)*.25)))
        right = min(W, int(eye_cx_cells + max(3, (ex1-ex0)*.25)) + 1)
        bottom = min(H, eye_bottom + max(6, round(H*.18)))
        ink_rows = [y for y in range(eye_bottom, bottom)
                    if any(grid[y][x] == L.OUTLINE for x in range(left, right))]
        if ink_rows:
            mouth = max(ink_rows) + 1

    eye_cx = x0 + eye_cx_cells * cell
    return (eye_cx - CAT_FACE_OFFSET,          # head centre, read off the face
            y0 + skull * cell,
            eye_cx,
            y0 + a[1] * cell,
            y0 + mouth * cell)


def dart_eyes(pet, geom, note):
    """The `PetEyeGeometry` constant for pet_recolor.dart."""
    right = ('' if geom['rightX'] is None
             else 'rightX: %d, ' % geom['rightX'])
    return ('/// %s\nconst PetEyeGeometry %s =\n'
            '    PetEyeGeometry(leftX: %d, %sy: %d, w: %d, h: %d);'
            % (note, const_name(pet), geom['leftX'], right,
               geom['y'], geom['w'], geom['h']))


def dart_for(pet, anchors, geom):
    """The `_PetParts` entry and eye constant, derived from the measurements.

    Seating is arithmetic, not taste: an accessory sits where the cat wears it
    plus the distance from the cat's anchor to this pet's. That is exactly how
    the rabbit's and hamster's numbers were arrived at, and re-deriving the
    rabbit's this way reproduces its hat and face offsets to the unit.

    The neck is the one that is not a direct measurement -- a collar is not
    seated against anything you can point at -- so it hangs the same distance
    under the muzzle as the cat's does. On these mostly neckless animals that
    puts it where the cheeks stop, which is the note the hamster carries.
    """
    head_cx, skull, eye_cx, eye_top, mouth_bottom = anchors
    hat = (head_cx - CAT_HEAD_CX, skull - CAT_SKULL_TOP)
    face = (eye_cx - CAT_EYE_CX, eye_top - CAT_EYE_TOP)
    neck = (head_cx - CAT_HEAD_CX,
            (mouth_bottom + (CAT_CHEST_TOP - CAT_MOUTH_BOTTOM)) - CAT_CHEST_TOP)

    def off(v):
        return 'Offset(%d, %d)' % (round(v[0]), round(v[1]))

    return '\n'.join([
        "  // Head centred x %d, skull top y %d; eyes y %d; muzzle ends y %d."
        % (round(head_cx), round(skull), round(eye_top), round(mouth_bottom)),
        "  '%s': _PetParts(" % pet,
        "    base: 'assets/svgs/%s_base.svg'," % pet,
        "    eyes: 'assets/svgs/%s_eyes.svg'," % pet,
        "    eyesPivot: Alignment(%.3f, %.3f)," % geom['pivot'],
        "    eyeGeometry: %s," % const_name(pet),
        "    accessoryOffsets: {",
        "      AccessorySlots.hat: %s," % off(hat),
        "      AccessorySlots.neck: %s," % off(neck),
        "      AccessorySlots.face: %s," % off(face),
        "    },",
        "  ),",
    ])


DART_OUT = os.path.join(HERE, 'generated_roster_dart.txt')
HERE_NOTE = """// Generated by art_src/gen_roster_pets.py -- do not hand-edit these numbers.
// Re-run with --sync-dart after changes to pet_goal.png or goal_trace.py.
"""


def sync_dart(eyes, parts):
    """Replace only generated roster entries; validate both files first."""
    root = Path(HERE).parent
    updates = []
    for relative, blocks, kind in (
        ('lib/utils/pet_recolor.dart', eyes, 'eyes'),
        ('lib/components/character_sprite.dart', parts, 'parts'),
    ):
        path = root / relative
        source = path.read_text(encoding='utf-8')
        for pet, block in zip(ROLES, blocks):
            if kind == 'eyes':
                name = const_name(pet)
                pattern = r'///[^\n]*\nconst PetEyeGeometry ' + name + r'\s*=\s*PetEyeGeometry\([^;]*\);'
            else:
                pattern = r'[ \t]*// Head centred[^\n]*\n[ \t]*' + re.escape("'%s': _PetParts(" % pet) + r'.*?\n  \),'
            source, count = re.subn(pattern, lambda match: block.strip('\n'), source, count=0, flags=re.S)
            if count != 1:
                raise ValueError(f'{relative}: expected one entry for {pet}, found {count}')
        updates.append((path, source))
    for path, source in updates:
        path.write_text(source, encoding='utf-8')


def main():
    eyes_dart, parts_dart, coats = [], [], []
    for gid, _tx, _ty, W, H, layers in split_roster.groups():
        if gid not in ROLES:
            raise SystemExit('%s has no entry in ROLES' % gid)
        grid = L.raster(W, H, layers)
        fix_roster.apply_to(gid, grid, W, H)

        # Trim the slice margin, then narrow if the canvas cannot hold it.
        xs = [x for y in range(H) for x in range(W) if grid[y][x]]
        ys = [y for y in range(H) for x in range(W) if grid[y][x]]
        bx0, bx1, by0, by1 = min(xs), max(xs) + 1, min(ys), max(ys) + 1
        grid = [[grid[y][x] for x in range(bx0, bx1)] for y in range(by0, by1)]
        W, H = bx1 - bx0, by1 - by0
        dropped = 0
        if W * CELL > MAX_CANVAS_W:
            dropped = -(-(W * CELL - MAX_CANVAS_W) // CELL)
            grid, W = narrow(grid, W, H, dropped)

        grid, eye_boxes = goal_trace.trace(gid, W, H,
                                          L.order_of(layers), ROLES[gid])
        a = eye_boxes[0]
        b = eye_boxes[1] if len(eye_boxes) == 2 else None
        base_rows, _ = rows_for(gid, grid, W, H, ())
        rows, palette = rows_for(gid, grid, W, H, (a, b))

        print('=== %s  %dx%d cells -> %dx%d units%s'
              % (gid, W, H, W * CELL, H * CELL,
                 '  (%d duplicate column(s) dropped to fit)' % dropped if dropped else ''))
        geom = lib_cells.generate_rows(gid, rows, palette, under='M',
                                       const_name=const_name(gid), cell=CELL,
                                       base_rows=base_rows)
        ox, oy = lib_cells.origin(rows, CELL)
        anchors = measure(grid, W, H, (a, b), CELL, ox, oy)

        note = ('%s eyes: %s %dx%d cell%s.'
                % (gid.replace('-', ' ').capitalize(),
                   'one' if geom['rightX'] is None else 'two',
                   geom['w'], geom['h'],
                   '' if geom['rightX'] is None else 's'))
        if geom['rightX'] is None:
            note += ' Drawn side-on, so there is no second cell.'
        eyes_dart.append(dart_eyes(gid, geom, note))
        parts_dart.append(dart_for(gid, anchors, geom))
        coats.append("  '%s': '%s'," % (gid, NATURAL_COAT[gid].upper()))
        print()

    sections = [
        HERE_NOTE,
        '// ---- pet_recolor.dart: eye geometry ----',
        '\n\n'.join(eyes_dart),
        '// ---- character_sprite.dart: _layeredPets entries ----',
        '\n'.join(parts_dart),
        '// ---- pets.dart: natural coats ----',
        '\n'.join(coats),
    ]
    with open(DART_OUT, 'w', encoding='utf-8') as fh:
        fh.write('\n\n'.join(sections) + '\n')
    if '--sync-dart' in sys.argv:
        sync_dart(eyes_dart, parts_dart)
    print('%d pets built; Dart written to %s' % (len(parts_dart), DART_OUT))


if __name__ == '__main__':
    main()
