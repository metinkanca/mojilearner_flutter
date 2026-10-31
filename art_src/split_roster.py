"""Slice `pet-roster-restored.svg` into one pet per group.

This is the *reader* half of the pipeline and writes nothing. `fix_roster.py`
is what produces `art_src/<pet>.svg`, because the per-pet files are the sheet's
content with the trace repairs applied and there is no useful state in between
-- writing the unrepaired slice first only creates an ordering hazard, where
running one script without the other leaves the artifacts back on disk.

Twenty-two of the twenty-four pets already existed as their own file; the gecko
and the chameleon were never exported, which is the only reason they were not
in the app. Rather than hand-copying those two, every pet is re-sliced from the
sheet, so the sheet stays the single source and a future pet needs no new code.

Each `<g>` on the sheet is `translate(tx ty) scale(2)` over art that is already
0-based, so a slice is just the group's own paths.

The one thing this does not preserve is the previously exported files' padding.
Those carried between 0 and 2 spare cells on each side, differing per pet,
because they were whatever the sheet's layout happened to leave; four pets
started at x=1 and the rest at x=2. Nothing reads the padding -- the app
pipeline re-origins to its own shared canvas -- so every pet is normalised
here to a uniform 2-cell margin, which makes the intermediate files
comparable to each other. Cell content is untouched.
"""
import os
import re
import lib_roster as L

HERE = os.path.dirname(os.path.abspath(__file__))
SHEET = os.path.join(HERE, 'pet-roster-restored.svg')


def groups():
    s = open(SHEET, encoding='utf-8').read()
    out = []
    for m in re.finditer(r'<g id="([^"]+)" transform="translate\((-?\d+) (-?\d+)\) scale\(2\)">'
                         r'(.*?)</g>', s, re.S):
        gid, tx, ty, body = m.group(1), int(m.group(2)), int(m.group(3)), m.group(4)
        layers = [(pm.group(1).lower(), L._rects(pm.group(2), gid))
                  for pm in re.finditer(r'<path fill="(#[0-9a-fA-F]{6})" d="([^"]+)"', body)]
        out.append((gid, tx, ty) + _normalise(layers))
    return out


MARGIN = 2


def _normalise(layers):
    """Re-origin the art to (MARGIN, MARGIN) on a canvas with that margin all
    round. -> (W, H, layers)."""
    x0 = min(r[0] for _, rs in layers for r in rs)
    y0 = min(r[1] for _, rs in layers for r in rs)
    dx, dy = MARGIN - x0, MARGIN - y0
    moved = [(f, [(a + dx, b + dy, c + dx, d + dy) for a, b, c, d in rs]) for f, rs in layers]
    W = max(r[2] for _, rs in moved for r in rs) + MARGIN
    H = max(r[3] for _, rs in moved for r in rs) + MARGIN
    return W, H, moved


def title_of(gid):
    return gid.replace('-', ' ').title()


if __name__ == '__main__':
    for gid, tx, ty, W, H, layers in groups():
        print('%-11s %dx%d  %d layers' % (gid, W, H, len(layers)))
