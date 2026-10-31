"""Build `art_src/<pet>.svg` for all 24 roster pets, repairing the trace.

`pet-roster-restored.svg` is the master. This slices it (via `split_roster`)
and applies the repairs listed below, so the per-pet files are always the
sheet's content plus exactly these fixes -- which makes the run idempotent, and
makes the fix list, rather than the files, the thing to read and review.

    python fix_roster.py            # writes art_src/<pet>.svg for all 24
    python fix_roster.py --check    # fails if anything on disk is out of date

The trace left three kinds of residue behind. Only those are fixed -- this is
deliberately NOT a general denoiser, because most small blobs in this art are
drawing (a nose, a claw, an ear inset, a tail band), and a filter that could
not tell those apart would erase the art to clean up the noise.

Every repair is seeded at a single cell and flood-fills that cell's own colour.
Seeding by cell rather than by box means a patch either finds the blob it was
written for or fails loudly: `MAX_BLOB` trips if the art moves under a seed, so
a stale patch is caught rather than silently eating a neighbouring region. That
guard has already earned itself once -- the skunk's `cap` was first written as
a whole-blob repaint, and the blob turned out to be 24 cells of tail stripe.
"""
import collections
import os
import sys

import lib_roster as L
import split_roster

HERE = os.path.dirname(os.path.abspath(__file__))

# (pet, seed x, seed y, action, why)
#
#   'host'  dissolve the blob into whatever colour surrounds it -- the answer
#           for a speck stranded inside one flat region.
#   'cap'   repaint only the cells of the blob that touch the background, as
#           outline. For a nick in the ink over a region that is otherwise
#           real drawing, so the silhouette keeps its size and the drawing
#           keeps its shape.
#   'none'  erase the blob.
FIXES = [
    # --- 1. coat colour touching the background -------------------------
    # Every pet holds the rule that nothing but the outline touches the
    # background. These are the three places the trace broke it, and they
    # read as nicks in the ink.
    ('red-panda', 33, 58, 'cap',
     'orange past the tip of the black wedge between tail and haunch'),
    ('skunk', 58, 28, 'cap',
     'tail-stripe cream through the notch where the tail crosses the back'),
    # The exception: this one is not part of the silhouette at all -- three
    # navy cells adrift in the background off the right flank, touching the
    # pet only at a corner. There is nothing for it to be, so it goes.
    ('penguin', 77, 51, 'none',
     'navy fragment adrift in the background off the right flank'),

    # --- 2. one-cell slivers stranded along a colour boundary -----------
    # Classic trace residue: an antialiased edge in the reference resolved to
    # a thin run of the wrong side's colour, left behind inside the other.
    ('fennec', 76, 40, 'host',
     'black sliver down the inside of the right ear, stranded in the ear pink'),
    ('fennec', 60, 69, 'host',
     'ear-pink sliver stranded on the cream muzzle, below the mouth'),
    ('chinchilla', 57, 93, 'host',
     'inner-ear pink stranded down at the feet, nowhere near an ear'),
    ('chinchilla', 44, 93, 'host',
     'belly white stranded at the feet, detached from the belly patch'),
    ('piglet', 40, 77, 'host',
     'body pink stranded inside the black gap between the hind legs'),

    # --- 3. a hole bitten out of a belly patch --------------------------
    ('mouse', 61, 63, 'host',
     'coat grey eating a notch out of the cream belly patch'),
]

# A patch that suddenly covers a large area means the art moved under its seed.
# Every blob listed above is a sliver; `cap` blobs may legitimately be bigger,
# since only their edge is repainted.
MAX_BLOB = 24
MAX_CAP_BLOB = 64


def blob(grid, W, H, x, y):
    """The 4-connected run of grid[y][x]'s own colour containing (x, y)."""
    want = grid[y][x]
    seen, stack, out = {(x, y)}, [(x, y)], []
    while stack:
        cx, cy = stack.pop()
        out.append((cx, cy))
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nx, ny = cx + dx, cy + dy
            if (0 <= nx < W and 0 <= ny < H and (nx, ny) not in seen
                    and grid[ny][nx] == want):
                seen.add((nx, ny))
                stack.append((nx, ny))
    return want, out


def host_of(grid, W, H, cells):
    """The colour that most surrounds `cells`, background not counted."""
    s = set(cells)
    n = collections.Counter()
    for x, y in cells:
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nx, ny = x + dx, y + dy
            if (nx, ny) in s:
                continue
            n[grid[ny][nx] if 0 <= nx < W and 0 <= ny < H else None] += 1
    n.pop(None, None)
    return n.most_common(1)[0][0] if n else None


def _touching_background(grid, W, H, cells):
    out = []
    for x, y in cells:
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nx, ny = x + dx, y + dy
            if not (0 <= nx < W and 0 <= ny < H) or grid[ny][nx] is None:
                out.append((x, y))
                break
    return out


def apply_to(pet, grid, W, H):
    changed = []
    for name, x, y, how, why in FIXES:
        if name != pet:
            continue
        if not (0 <= x < W and 0 <= y < H) or grid[y][x] is None:
            raise SystemExit('%s: seed (%d,%d) is off the art -- patch is stale' % (pet, x, y))
        was, cells = blob(grid, W, H, x, y)
        cap = MAX_CAP_BLOB if how == 'cap' else MAX_BLOB
        if len(cells) > cap:
            raise SystemExit('%s: seed (%d,%d) floods %d cells (max %d) -- patch is stale'
                             % (pet, x, y, len(cells), cap))
        if how == 'host':
            to = host_of(grid, W, H, cells)
            if to is None:
                raise SystemExit('%s: seed (%d,%d) has no host colour' % (pet, x, y))
        elif how == 'cap':
            to = L.OUTLINE
            cells = _touching_background(grid, W, H, cells)
            if not cells:
                raise SystemExit('%s: seed (%d,%d) touches no background -- patch is stale'
                                 % (pet, x, y))
        elif how == 'none':
            to = None
        else:
            raise SystemExit('%s: unknown action %r' % (pet, how))
        for cx, cy in cells:
            grid[cy][cx] = to
        changed.append((x, y, was, to, len(cells), why))
    return changed


def build():
    """-> {pet: (path, svg, [fix, ...])} for all 24, repaired."""
    out = {}
    for gid, _tx, _ty, W, H, layers in split_roster.groups():
        grid = L.raster(W, H, layers)
        changed = apply_to(gid, grid, W, H)
        order = L.order_of(layers)
        for _, _, _, to, _, _ in changed:
            if to is not None and to not in order:
                order.append(to)
        svg = L.emit(W, H, grid, order, split_roster.title_of(gid))
        out[gid] = (os.path.join(HERE, gid + '.svg'), svg, changed)
    return out


def main(argv):
    check = '--check' in argv
    built = build()
    seen_fixes, stale = 0, []
    for gid in sorted(built):
        path, svg, changed = built[gid]
        old = open(path, encoding='utf-8').read() if os.path.exists(path) else None
        if old != svg:
            stale.append(gid)
            if not check:
                open(path, 'w', encoding='utf-8').write(svg)
        if changed:
            seen_fixes += len(changed)
            print('%-11s %d fix(es)%s' % (gid, len(changed), '' if old == svg else ' *'))
            for x, y, was, to, n, why in changed:
                print('    (%3d,%3d) %-7s -> %-7s %2d cell(s)  %s'
                      % (x, y, was, to or 'erased', n, why))
    unfixed = len(built) - len({f[0] for f in FIXES})
    print('\n%d pets, %d repairs, %d pets untouched' % (len(built), seen_fixes, unfixed))
    if check and stale:
        print('OUT OF DATE: %s' % ', '.join(stale))
        return 1
    if stale:
        print('wrote: %s' % ', '.join(stale))
    else:
        print('all files already up to date')
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
