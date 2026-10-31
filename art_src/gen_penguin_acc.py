# Builds the penguin's own copies of the accessories that cannot be made to fit
# by moving them.
#
# Every accessory is drawn once, front-on, for the cat's 130-unit head and its
# 61-unit eye spacing, and a pet whose head sits elsewhere just translates it
# (see `_PetParts.accessoryPlacements` in character_sprite.dart). The penguin
# takes that for all but five pieces:
#
#   glasses, sunglasses, goggles, mask -- the eyes are 46 units apart, not 61.
#       A lens centred on one eye has its neighbour's lens sitting off the
#       other, and no translation fixes both. So each is cut: cells come out
#       of the lenses and the bridge, which brings the lenses onto the eyes
#       and leaves the bill clear between them, and the temple on the far side
#       of the face comes off, because the penguin's head ends where the cat's
#       face was still going.
#   cap -- worn mirrored, since the penguin looks to the viewer's right. The
#       shared art is mirrored by the sprite at draw time, and the move to the
#       penguin's head is then clamped to 31 units, which leaves the dome 17
#       units left of the skull. A cut is drawn verbatim and clamps nothing. The
#       peak also comes in by two cells: at the head's real position it would
#       run off the canvas.
#
# The art is reused rather than redrawn -- same cells, same outline, same
# palette -- by dropping whole 7-unit columns that repeat the column beside
# them, so no edge or corner moves relative to its neighbours. The far-side
# temple on each lens piece is the one thing taken off the end instead. Each job
# names the art-space columns to remove rather than a count, because which
# columns repeat is a fact about that piece (see each job's note).
#
# Re-run after any edit to the source accessories, then `gen_acc_extents.py`.
# Never hand-edit the output.
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import deseam
from deseam import VBX, VBY, VBW, VBH, shapes, rasterise, trace, emit

SVG = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'assets', 'svgs')

# The penguin's face, on the shared canvas (gen_rework.py prints the eye cells):
# eyes x 90..98 and 136..144, y 140..154. The pair is centred on x=117, and
# lens centres want to land on 94 and 140.

# drop: art-space x ranges, inclusive, removed before anything else.
# mirror: flip about the canvas centre (x=91) after the drop.
# dx, dy: where the piece lands, applied last.
# dome: (cx, y0, y1) -- instead of dx, solve dx so the occupied span of rows
#       y0..y1 is centred on cx. For a hat whose brim is lopsided.
JOBS = [
    # Art columns are 7 units wide, column c at x = 56 + 7c. The cat's lens is
    # 5 cells across; the penguin's eye is 8 units, so two cells of lens
    # interior is plenty, and the narrower frame leaves the bill (20 units)
    # clear between the lenses. One cell comes out of the 4-cell bridge, which
    # puts the lenses 49 apart against the eyes' 46. The far-side arm goes.
    dict(name='acc_glasses_penguin', src='acc_glasses',
         drop=[(77, 83), (112, 118), (140, 146), (168, 181)], dx=9, dy=71),
    # Its lens is 6 cells across with a 4-cell interior; each loses two.
    dict(name='acc_sunglasses_penguin', src='acc_sunglasses',
         drop=[(77, 90), (112, 118), (147, 160), (175, 181)], dx=16, dy=71),
    # One band, a 5-cell lens at each side of a 4-cell bridge. The band's
    # right end stays: dropped, it would leave the strap open. The lens is
    # opaque, so the band only has to cover the eyes -- and the eyes sit level
    # with the top of the bill, so it rides 6 units high to leave the bill's
    # lower half showing, as the cat's leaves its nose.
    dict(name='acc_goggles_penguin', src='acc_goggles',
         drop=[(84, 90), (112, 118), (147, 153)], dx=9, dy=65),
    # The mask's holes are 3 cells across and its middle is a run of purple
    # between them; the two cells beside the centre stud come out of it. It
    # covers the bill: the holes have to sit on the eyes, and the band under
    # them reaches 14 units further, past the bill's foot.
    dict(name='acc_mask_penguin', src='acc_mask',
         drop=[(105, 111), (126, 132)], dx=5, dy=68),
    # The brim is the flat run 18..45 on the cat's left; two cells come out
    # of it, which is as much as the peak can keep and still stay on the canvas
    # with the dome on the skull. Mirrored, it points where the penguin looks.
    dict(name='acc_cap_penguin', src='acc_cap',
         drop=[(25, 38)], mirror=True, dome=(109, -28, 21), dy=64),
]


def transformed(svg, drop, mirror, dx, dy, dome):
    shp = shapes(svg)
    fills = []
    for f, _ in shp:
        if f not in fills:
            fills.append(f)
    order = sorted(fills, key=lambda f: (deseam.RANK.get(f, 5), fills.index(f)))

    buf = [-1] * (VBW * VBH)
    for f, subs in shp:
        rasterise(subs, buf, order.index(f))
    rows = [buf[y * VBW:(y + 1) * VBW] for y in range(VBH)]

    # Close up the dropped columns, leaving everything left of them where it
    # was.
    gone = {x for a, b in drop for x in range(a, b + 1)}
    kept = [x for x in range(VBW) if (x + VBX) not in gone]
    first = kept[0]
    closed = []
    for row in rows:
        out = [-1] * VBW
        for j, x in enumerate(kept):
            out[first + j] = row[x]
        closed.append(out)
    rows = closed

    if mirror:
        # Pixel x covers [x, x+1); the canvas centre is x=91, so it lands on
        # 181 - x.
        rows = [[r[VBW - 1 - i] for i in range(VBW)] for r in rows]

    if dome:
        cx, y0, y1 = dome
        span = [i + VBX for y in range(y0 - VBY, y1 - VBY + 1)
                for i in range(VBW) if rows[y][i] >= 0]
        dx = round(cx - (min(span) + max(span) + 1) / 2)

    out = [-1] * (VBW * VBH)
    lost = 0
    for y in range(VBH):
        for x in range(VBW):
            v = rows[y][x]
            if v < 0:
                continue
            nx, ny = x + dx, y + dy
            if 0 <= nx < VBW and 0 <= ny < VBH:
                out[ny * VBW + nx] = v
            else:
                lost += 1
    if lost:
        raise SystemExit('%d pixels land off the canvas (dx %d, dy %d)' % (lost, dx, dy))

    body = []
    for i, f in enumerate(order):
        mask = [1 if v >= i else 0 for v in out]
        if not any(mask):
            continue
        d = emit(trace(mask))
        if d:
            body.append('<path fill="%s" d="%s"/>' % (f, d))
    head = svg[:svg.index('>', svg.index('<svg')) + 1]
    return head + ''.join(body) + '</svg>\n', dx


for job in JOBS:
    src = open(os.path.join(SVG, job['src'] + '.svg'), encoding='utf-8').read()
    out, dx = transformed(src, job['drop'], job.get('mirror', False),
                          job.get('dx', 0), job['dy'], job.get('dome'))
    p = os.path.join(SVG, job['name'] + '.svg')
    open(p, 'w', encoding='utf-8').write(out)
    print('%-26s %5d bytes  (from %s, dx %d, dy %d)'
          % (job['name'] + '.svg', len(out), job['src'], dx, job['dy']))
