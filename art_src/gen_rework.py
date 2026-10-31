# Builds the layered sprite assets for the REWORKED cat, bird and rabbit
# (`cat.svg`, `bird.svg`, `rabbit.svg`). The dog's rework has its own
# generator, `gen_dog2.py`, because its master arrives with face layers of its
# own; these three do not.
#
# Their faces are holes in the coat: an eye is a patch of silhouette showing
# through, and so is the nose-and-mouth. So the face is found rather than
# named -- every outline cell with no path of outline to the pet's outer edge
# (`enclosed_outline`) -- and then split by row: the eyes are the two
# components level with each other, the nose is what sits above [MOUTH_ROW]
# and stays in the coat, the mouth is what sits below it and becomes a layer.
#
# The tail is found the same way. In both the cat and the rabbit its coat is a
# separate patch from the body's, so it is that patch plus the outline nearer
# to it than to the body. Outline equally near both -- the one-cell line the
# artist drew between them -- goes to both layers.
#
# Hidden paths in the masters (`display:none`) are skipped; they are
# unfinished markings.
#
#     python art_src/gen_rework.py
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import lib_rework as L                            # noqa: E402

RANK = {L.MAIN: 0, L.LIGHT: 1, L.SHADE: 2}       # anything else: just under red


def rank_of(layer):
    r = dict(RANK)
    for f in layer.values():
        r.setdefault(f, 3)
    r[L.RED] = 4
    r[L.OUTLINE] = 5
    return r


def near(cells):
    """Chebyshev distance from `cells`, out to four cells."""
    dist = {c: 0 for c in cells}
    front = set(cells)
    for d in range(1, 5):
        nxt = set()
        for cx, cy in front:
            for dx in (-1, 0, 1):
                for dy in (-1, 0, 1):
                    a = (cx + dx, cy + dy)
                    if a not in dist:
                        dist[a] = d
                        nxt.add(a)
        front = nxt
    return dist


# Where the old cat wears things, on the shared canvas: head centre x, skull
# top, top of the eyes, bottom of the mouth. Offsets for a reworked pet are the
# cat's own placement plus the distance from these to the same marks on it --
# the derivation the rabbit and hamster got. See the sprite's `_layeredPets`.
CAT_ANCHOR = {'x': 109.5, 'top': 34, 'eyes': 69, 'chin': 113}
CAT_PLACEMENTS = {'tophat': (-13, -23, 'hat'), 'cowboyhat': (-6, -20, 'hat'),
                  'cap': (42, -6, 'hat'), 'bowtie': (12, 2, 'neck'),
                  'collar': (-1, 10, 'neck'), 'medal': (-3, 6, 'neck')}


def build(name, master, mouth_row=None, beak=None, tail=False, reach=3,
          skull_row=None, eating=None, cell=L.CELL, bill=None, backing=()):
    # Room on the trace grid for a tail turned off the master's lattice.
    fr = L.Frame(master, pad=12, cell=cell)
    flat = master.flat
    face = L.enclosed_outline(master)
    comps = L.components(face)
    eyes = sorted(comps[:2], key=lambda c: min(x for x, _ in c))
    rest = set().union(*comps[2:]) if len(comps) > 2 else set()

    # --- the face ---------------------------------------------------------
    base = dict(flat)
    fill_holes(base, eyes[0] | eyes[1], backing)
    if bill is not None:
        # A bill that is only a marking in the coat (the penguin's): nothing
        # lifts out but the eyes, so there is no mouth layer and no chew. The
        # bill's cells are kept for the chin anchor below.
        mouth, mouth_open, nose = {}, {}, set()
        chin = {c for c, f in flat.items() if f in bill}
    elif beak is None:
        nose = {c for c in rest if c[1] <= mouth_row}
        mouth = {c: L.OUTLINE for c in rest if c[1] > mouth_row}
        fill_holes(base, set(mouth))
        mouth_open = open_mouth(mouth, depth=round(12 / cell))
        chin = set(mouth)
    else:
        # The bird's beak becomes the mouth layer, in the beak marker fill: the
        # coat's shade until the player picks a beak colour of its own. The
        # master's outline flecks around it (`rest`) are dropped: they read as
        # a black border.
        beak_cells = {c for c, f in flat.items() if f == beak}
        mouth = {c: L.BEAK for c in beak_cells}
        for c in beak_cells | rest:
            base[c] = L.MAIN
        # The chew is drawn: `eating` is the same bird with its beak open. The
        # coat under the beak is already filled, so the open pose is only its
        # beak cells -- wherever the beak has opened, the coat shows through.
        # Anything else that differs would be lost, so it is refused.
        changed = {c for c in set(flat) | set(eating.flat)
                   if flat.get(c) != eating.flat.get(c)}
        eating_beak = {c for c, f in eating.flat.items() if f == beak}
        stray = changed - beak_cells - eating_beak
        if stray:
            sys.exit('%s: the eating pose differs outside the beak at %s'
                     % (name, sorted(stray)[:8]))
        mouth_open = {c: L.BEAK for c in eating_beak}
        nose = set()
        chin = set(mouth)

    # --- the tail ---------------------------------------------------------
    has_tail, tail = tail, {}
    if has_tail:
        coat = {c for c, f in flat.items() if f != L.OUTLINE}
        patches = L.components(coat)
        tail_coat = min(patches, key=lambda p: sum(x for x, _ in p) / len(p))
        other = coat - tail_coat
        d_tail, d_body = near(tail_coat), near(other)
        mine = {c for c, f in flat.items() if c in tail_coat
                or (f == L.OUTLINE and c in d_tail
                    and d_tail[c] <= d_body.get(c, 99))}
        tail = {c: flat[c] for c in mine}
        # All of it leaves the coat, the shared line included: kept, it would
        # be the flank's only outline, one cell thick, and a wag swings the
        # tail clear of it. The seal rebuilds that flank, deep enough to meet
        # the tail's own edge at the full swing.
        for c in mine:
            del base[c]
        base = fr.seal(base, thick=reach + 3, within=mine)
        root = L.tail_root(tail, set(flat) - mine)
        # `reach` is how far the tip travels, in cells.
        angle = L.wag_left(tail, root, L.tail_angle(tail, root, reach))

    pre = name
    fr.write('%s_base.svg' % pre, base, rank_of(base))
    fr.write('%s_eyes.svg' % pre, {c: L.OUTLINE for c in eyes[0] | eyes[1]},
             rank_of({}))
    if bill is None:
        fr.write('%s_mouth.svg' % pre, mouth, rank_of(mouth))
        fr.write('%s_mouth_open.svg' % pre, mouth_open, rank_of(mouth_open))
    if tail:
        for suffix, a in (('', 0), ('_l', angle), ('_r', -angle)):
            posed = L.close_notches(base, fr.seal(L.rotate_tail(tail, root, a)))
            fr.write('%s_tail%s.svg' % (pre, suffix), posed, rank_of(posed))
    # The flat sprite, assembled from the layers so it carries their fixes
    # (the bird's beak in coat tone, with no border).
    whole = dict(base)
    whole.update(tail)
    whole.update(mouth)
    whole.update({c: L.OUTLINE for c in eyes[0] | eyes[1]})
    fr.write('%s.svg' % pre, whole, rank_of(whole))

    # --- numbers for the Dart side ----------------------------------------
    fr.report(eyes)
    ex, ey, ew, eh = fr.box(eyes[0] | eyes[1])
    mx, my, mw, mh = fr.box(chin)
    anchor = {'x': ex + ew / 2, 'top': fr.cell * skull_row + fr.y0,
              'eyes': ey, 'chin': my + mh}
    slot = {
        'hat': (anchor['x'] - CAT_ANCHOR['x'], anchor['top'] - CAT_ANCHOR['top']),
        'face': (anchor['x'] - CAT_ANCHOR['x'], anchor['eyes'] - CAT_ANCHOR['eyes']),
        'neck': (anchor['x'] - CAT_ANCHOR['x'], anchor['chin'] - CAT_ANCHOR['chin']),
    }
    print('accessoryOffsets: ' + ', '.join(
        '%s: Offset(%d, %d)' % (k, round(v[0]), round(v[1])) for k, v in slot.items()))
    print('accessoryPlacements: ' + ', '.join(
        "'%s': (%d, %d)" % (k, dx + round(slot[s][0]), dy + round(slot[s][1]))
        for k, (dx, dy, s) in CAT_PLACEMENTS.items()))
    print()


def fill_holes(layer, holes, backing=()):
    """Paints `holes` (lifted eyes, a lifted mouth) in the colour around them.

    `backing` names extra fills that may back a hole besides the coat tones:
    the penguin's cream face is a marking, not a coat tone, and its eyes sit
    in it.

    Grown in from the edge, each cell taking the commonest coat tone beside
    it, so an eye set in the raccoon's dark mask is backed by mask rather than
    by coat -- the backing is what shows while the lid is shut.
    """
    todo = set(holes)
    for c in todo:
        layer.pop(c, None)
    while todo:
        done = {}
        for cx, cy in todo:
            seen = {}
            for a in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
                f = layer.get(a)
                # Coat tones only: the bird's eye sits on its beak, which is
                # lifted out too and must not back the eye.
                if f in (L.MAIN, L.SHADE, L.LIGHT, *backing) and a not in todo:
                    seen[f] = seen.get(f, 0) + 1
            if seen:
                done[(cx, cy)] = max(seen, key=seen.get)
        if not done:                              # walled in by outline
            for c in todo:
                layer[c] = L.MAIN
            return
        layer.update(done)
        todo -= set(done)


def open_mouth(mouth, depth=4):
    """The closed line with a pocket opened under it -- the dog's chew.

    `depth` is in cells, so a pet on a finer cell opens as far as the rest.
    """
    xs = [c[0] for c in mouth]
    ys = [c[1] for c in mouth]
    x0, x1, y1 = min(xs), max(xs), max(ys)
    out = dict(mouth)
    for cy in range(y1, y1 + depth):
        for cx in range(x0 + 2, x1 - 1):
            out[(cx, cy)] = L.RED
        out[(x0 + 1, cy)] = L.OUTLINE
        out[(x1 - 1, cy)] = L.OUTLINE
    for cx in range(x0 + 1, x1):
        out[(cx, y1 + depth)] = L.OUTLINE
    return out


# With names on the command line (`python gen_rework.py penguin2`) only those
# pets are rebuilt; with none, all of them are.
ONLY = set(sys.argv[1:])


def want(name):
    return not ONLY or name in ONLY


if want('cat2'):
    cat = L.Master('cat.svg', {'#969680': L.MAIN})
    build('cat2', cat, mouth_row=37, tail=True, skull_row=11)

if want('bird2'):
    BIRD_PALETTE = {'#ffd33b': L.MAIN, '#e6a42c': L.SHADE}
    bird = L.Master('bird.svg', BIRD_PALETTE)
    build('bird2', bird, beak='#f29422', skull_row=1,
          eating=L.Master('bird_eating.svg', BIRD_PALETTE))

if want('rabbit2'):
    rabbit = L.Master('rabbit.svg', {'#dcb47b': L.MAIN})
    build('rabbit2', rabbit, mouth_row=53, tail=True, reach=2, skull_row=34)

# The raccoon is drawn on a 10-pixel grid at four times the others' detail, so
# it takes two units a cell to come out the cat's size. Its mask, tail rings
# and paws are the coat's shade and its cream markings the light tone, as the
# old raccoon's were -- all three move with the coat.
if want('raccoon2'):
    raccoon = L.Master('raccoon.svg',
                       {'#a49d93': L.MAIN, '#504d48': L.SHADE, '#fbe8c5': L.LIGHT},
                       srccell=10, outline='#100f0c')
    build('raccoon2', raccoon, mouth_row=54, tail=True, reach=5, skull_row=7,
          cell=2)

# The axolotl is on the raccoon's 10-pixel grid, but at 139 cells it is 278
# units wide at two a cell against a 255-unit canvas, so it loses twelve
# repeated columns first. Its tail's coat runs on into the body's, so there is
# no patch to lift off as a wag layer: the tail stays in the coat, as the old
# axolotl's did. The coral gills and fin are markings, kept as drawn; the
# hidden rose shading is unfinished and skipped.
if want('axolotl2'):
    axolotl = L.Master('axolotl.svg', {'#fac4c6': L.MAIN, '#fbe1d5': L.LIGHT},
                       srccell=10, outline='#15120d').narrow(12)
    build('axolotl2', axolotl, mouth_row=41, skull_row=11, cell=2)

# The penguin (`penguin-compact.svg`, the final art) is on the same 10-pixel
# grid. Only its navy back takes the coat: the cream face and bib, the orange
# bill and feet and the bill's shading are markings, kept as drawn, which is
# what the roster penguin it replaces did too. The bill is part of the face
# rather than a muzzle laid over it, so there is no mouth layer and no chew;
# the eyes are holes in the cream, and cream backs them while a lid is shut.
# There is no tail to wag. The hidden blue-grey flipper path is unfinished
# and skipped.
PENGUIN_BILL = ('#ffa11c', '#c76a09')
if want('penguin2'):
    penguin = L.Master('penguin-compact.svg', {'#283d5c': L.MAIN},
                       srccell=10, outline='#120f0a')
    build('penguin2', penguin, bill=PENGUIN_BILL, backing=('#ffedc8',),
          skull_row=1, cell=2)
