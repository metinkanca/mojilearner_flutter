# Builds the bird's own copies of the face accessories.
#
# Every accessory is drawn once, front-on, seated on the cat's head, and a pet
# whose head sits elsewhere just translates it (see `_PetParts.accessoryOffsets`
# in character_sprite.dart). That works for hats and neckwear on the bird. It
# cannot work for the face slot: the chick is drawn in profile with one eye, so
# a two-lens piece either covers the eye and leaves its other half hanging off
# the bird's back, or sits centred with the eye between the lenses.
#
# So the face pieces get a bird cut: keep the half of the art that holds one
# eye, mirror it (the cat faces the viewer, the chick faces right, so the arm
# has to run back over its head), and drop it on the eye. The art is reused
# rather than redrawn, which is what keeps the frame weight, the outline and
# the palette identical to the front-on originals.
#
# Re-run after any edit to the source accessories. Never hand-edit the output.
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import deseam
from deseam import VBX, VBY, VBW, VBH, shapes, rasterise, trace, emit

SVG = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'assets', 'svgs')

# The bird's eye cell, from gen_bird.py.
EYE_X0, EYE_X1, EYE_Y0, EYE_Y1 = 121, 129, 92, 107

# src: which accessory to cut up.
# cut: keep art columns >= this (the half holding the cat's right eye).
# dx/dy: where the kept half lands, applied after the mirror.
JOBS = [
    # Lens pieces: the cat's right lens plus its temple arm. Mirrored, the arm
    # runs back over the chick's head and the frame's front edge meets the beak.
    dict(name='acc_glasses_bird', src='acc_glasses', cut=133, dx=-39, dy=23),
    dict(name='acc_sunglasses_bird', src='acc_sunglasses', cut=133, dx=-39, dy=23),
    # The mask is one band across both eyes; the cut keeps the right eye hole
    # and the band's right half, which reads as a half-mask tied back.
    dict(name='acc_mask_bird', src='acc_mask', cut=119, dx=-32, dy=18),
    # Not a cut: the moustache is one centred piece, so it only moves -- down
    # and forward, to hang off the underside of the beak.
    dict(name='acc_mustache_bird', src='acc_mustache', cut=None, dx=30, dy=32),
]


def transformed(svg, cut, dx, dy, mirror=True):
    """Rasterise, keep x >= cut, mirror in place, translate, re-trace."""
    shp = shapes(svg)
    fills = []
    for f, _ in shp:
        if f not in fills:
            fills.append(f)
    order = sorted(fills, key=lambda f: (deseam.RANK.get(f, 5), fills.index(f)))

    buf = [-1] * (VBW * VBH)
    for f, subs in shp:
        rasterise(subs, buf, order.index(f))

    # Bounds of what survives the cut, in art coordinates.
    keep = [(x + VBX, y + VBY) for y in range(VBH) for x in range(VBW)
            if buf[y * VBW + x] >= 0 and (cut is None or x + VBX >= cut)]
    if not keep:
        raise SystemExit('cut removed everything')
    x0 = min(p[0] for p in keep)
    x1 = max(p[0] for p in keep) + 1

    out = [-1] * (VBW * VBH)
    for y in range(VBH):
        sy = y - dy
        if not 0 <= sy < VBH:
            continue
        for x in range(VBW):
            ax = x + VBX - dx
            # Mirror about the kept half's own centre, so it stays put.
            sax = (x0 + x1 - 1 - ax) if mirror else ax
            if cut is not None and sax < cut:
                continue
            sx = sax - VBX
            if not 0 <= sx < VBW:
                continue
            v = buf[sy * VBW + sx]
            if v >= 0:
                out[y * VBW + x] = v

    body = []
    for i, f in enumerate(order):
        mask = [1 if v >= i else 0 for v in out]
        if not any(mask):
            continue
        d = emit(trace(mask))
        if d:
            body.append('<path fill="%s" d="%s"/>' % (f, d))
    head = svg[:svg.index('>', svg.index('<svg')) + 1]
    return head + ''.join(body) + '</svg>\n'


for job in JOBS:
    src = open(os.path.join(SVG, job['src'] + '.svg'), encoding='utf-8').read()
    out = transformed(src, job['cut'], job['dx'], job['dy'],
                      mirror=job['cut'] is not None)
    p = os.path.join(SVG, job['name'] + '.svg')
    open(p, 'w', encoding='utf-8').write(out)
    print('%-24s %5d bytes  (from %s)' % (job['name'] + '.svg', len(out), job['src']))
print('\nbird eye cell: x %d..%d  y %d..%d' % (EYE_X0, EYE_X1, EYE_Y0, EYE_Y1))
