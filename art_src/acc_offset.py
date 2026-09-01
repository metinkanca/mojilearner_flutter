"""Read a hand-placed `<pet>_with_<accessory>.svg` reference and report the
placement it implies, in art units on the shared pet canvas.

The reference files are made by dropping the pet art and the accessory art into
one Inkscape document and dragging the accessory where it belongs. Inkscape
rewrites the paths (mm units, relative commands, its own ids), so the placement
cannot be read off the file directly -- but every path is still the same shape
as one in the source assets, so each can be matched back and the two placements
solved for.

    python art_src/acc_offset.py art_src/dog_with_cap.svg
    python art_src/acc_offset.py art_src/*.svg

Reports the placement to feed to _PetParts in lib/components/character_sprite.dart
-- the offset, and whether the piece was worn mirrored, both of which the
renderer can follow. A reference where the accessory was also resized cannot be
followed, since the renderer only moves things; those are flagged, and reported
as the move that comes closest.
"""

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SVGS = ROOT / "assets" / "svgs"

# Every path command letter, not just the ones that are handled: a letter
# missing from here is not rejected, it is invisible -- its numbers get read
# as more arguments to the command before it, which silently invents
# vertices rather than failing. `points` raises on the ones it cannot draw.
TOKEN = re.compile(r"[AaCcHhLlMmQqSsTtVvZz]|-?\d*\.?\d+(?:[eE][-+]?\d+)?")
NUM = re.compile(r"-?\d*\.?\d+(?:[eE][-+]?\d+)?")
SHAPE = re.compile(r"<(?:path|polygon|polyline|rect)\b[^>]*>")


def attr(name, tag):
    """One attribute off a start tag.

    Anchored on a non-name character, because `id="polygon32"` contains `d="`
    and a naive search reads the id as the path data.
    """
    m = re.search(rf'(?<![\w:.-]){name}="([^"]*)"', tag)
    return m.group(1) if m else None


def straight(p0, controls, p3, tol=1e-6):
    """Whether a cubic from `p0` to `p3` is a straight line.

    The art has no curves, but it is written with some: a tracer emits
    `c 0,0 dx,dy dx,dy` and Inkscape keeps it, which is a cubic whose control
    points sit on its own chord -- a line segment spelled the long way. Those
    are safe to read as one edge. A control point off the chord would be a real
    curve, and reading only its endpoint would quietly redraw the shape.
    """
    ax, ay = p3[0] - p0[0], p3[1] - p0[1]
    reach = max(abs(ax), abs(ay))
    for cx, cy in controls:
        bx, by = cx - p0[0], cy - p0[1]
        if reach < tol:  # a curve that returns to where it started
            if max(abs(bx), abs(by)) > tol:
                return False
        elif abs(ax * by - ay * bx) > tol * reach:
            return False
    return True


def points(d):
    """Absolute points of a path, in order.

    M/L/H/V/Z, plus the cubics the art spells its straight edges with -- see
    [straight]. Anything else raises: this returns corners, and a command it
    cannot reduce to corners has to stop it rather than be approximated.
    """
    toks = TOKEN.findall(d)
    pts, cmd, i = [], None, 0
    x = y = start_x = start_y = 0.0
    ctrl = None  # the previous cubic's second control point, for S/s
    while i < len(toks):
        t = toks[i]
        if t.isalpha():
            cmd, i = t, i + 1
            if cmd in "Zz":
                x, y = start_x, start_y
                pts.append((x, y))
            continue
        rel = cmd.islower()
        if cmd in "Mm":
            nx, ny = float(toks[i]), float(toks[i + 1])
            x, y = (x + nx, y + ny) if rel else (nx, ny)
            start_x, start_y = x, y
            i += 2
            cmd = "l" if rel else "L"  # implicit lineto for extra pairs
        elif cmd in "Ll":
            nx, ny = float(toks[i]), float(toks[i + 1])
            x, y = (x + nx, y + ny) if rel else (nx, ny)
            i += 2
        elif cmd in "Hh":
            x = x + float(toks[i]) if rel else float(toks[i])
            i += 1
        elif cmd in "Vv":
            y = y + float(toks[i]) if rel else float(toks[i])
            i += 1
        elif cmd in "CcSs":
            n = 6 if cmd in "Cc" else 4
            v = [float(v) for v in toks[i:i + n]]
            ox, oy = (x, y) if rel else (0.0, 0.0)
            pairs = [(ox + v[k], oy + v[k + 1]) for k in range(0, n, 2)]
            # S/s implies a first control mirroring the last one, which for a
            # segment that did not follow a cubic is the current point.
            c1 = pairs[0] if n == 6 else (
                (2 * x - ctrl[0], 2 * y - ctrl[1]) if ctrl else (x, y))
            c2, end = pairs[-2], pairs[-1]
            if not straight((x, y), (c1, c2), end):
                raise ValueError(f"path command {cmd!r} draws a real curve")
            x, y = end
            ctrl = c2
            i += n
        else:
            raise ValueError(f"unsupported path command {cmd!r}")
        if cmd not in "CcSs":
            ctrl = None
        pts.append((x, y))
    return pts


def transform_of(tag):
    """The element's own axis-aligned (sx, sy, tx, ty).

    Rotation is not something this art set contains, and quietly dropping one
    would misreport a placement rather than fail, so it raises instead.
    """
    t = attr("transform", tag)
    if not t:
        return 1.0, 1.0, 0.0, 0.0
    sx = sy = 1.0
    tx = ty = 0.0
    for kind, args in re.findall(r"(matrix|translate|scale)\s*\(([^)]*)\)", t):
        v = [float(n) for n in NUM.findall(args)]
        if kind == "matrix":
            a, b, c, d, e, f = (v + [0.0] * 6)[:6]
            if abs(b) > 1e-9 or abs(c) > 1e-9:
                raise ValueError(f"rotated or skewed transform: {t}")
            sx, sy, tx, ty = sx * a, sy * d, tx * a + e, ty * d + f
        elif kind == "translate":
            dx, dy = (v + [0.0, 0.0])[:2]
            tx, ty = tx + dx, ty + dy
        else:
            a = v[0]
            d = v[1] if len(v) > 1 else a
            sx, sy, tx, ty = sx * a, sy * d, tx * a, ty * d
    return sx, sy, tx, ty


def dedupe(pts):
    """A ring with consecutive repeats of the same vertex collapsed to one.

    The same outline written by two tools is not the same list of points. A
    traced asset closes a ring by walking back to the start vertex and then
    closing with `Z`, so the start is written twice and this reader adds a
    third; Inkscape writes it once and closes. Nothing about the shape differs,
    but the raw lengths do -- and length is the first thing `solve` compares,
    so an identical shape reads as no match at all.
    """
    out = [pts[0]]
    for p in pts[1:]:
        if p != out[-1]:
            out.append(p)
    return out


def shapes(svg_text):
    """(fill, points) for every drawn element, in document order.

    Paths, polygons, polylines and rects all reduce to a list of corners, which
    is all the matcher needs — and the art arrives as a mix of all four. The
    shipped assets are traced paths; a border-less source drawn in Inkscape is
    whatever Inkscape wrote, transforms and all.
    """
    out = []
    for tag in SHAPE.findall(svg_text):
        kind = re.match(r"<(\w+)", tag).group(1)
        if kind == "path":
            d = attr("d", tag)
            if not d:
                continue
            pts = points(d)
        elif kind == "rect":
            x, y = float(attr("x", tag) or 0), float(attr("y", tag) or 0)
            w, h = float(attr("width", tag) or 0), float(attr("height", tag) or 0)
            pts = [(x, y), (x + w, y), (x + w, y + h), (x, y + h), (x, y)]
        else:
            v = [float(n) for n in NUM.findall(attr("points", tag) or "")]
            pts = list(zip(v[0::2], v[1::2]))
            if kind == "polygon" and pts:
                pts.append(pts[0])
        if len(pts) < 2:
            continue
        sx, sy, tx, ty = transform_of(tag)
        pts = [(x * sx + tx, y * sy + ty) for x, y in pts]
        fill = (attr("fill", tag) or attr("style", tag) or "").lower()
        m = re.search(r"#[0-9a-f]{6}", fill)
        out.append((m.group(0) if m else fill, dedupe(pts)))
    return out


def rounded(p, places=2):
    """A point at the precision two copies of the same art agree to."""
    return round(p[0], places), round(p[1], places)


def bbox(pts):
    xs = [p[0] for p in pts]
    ys = [p[1] for p in pts]
    return min(xs), max(xs), min(ys), max(ys)


def solve(target, source, tol=2e-3):
    """Axis-aligned (sx, sy, tx, ty) taking `source` onto `target`, or None.

    Derived from the two bounding boxes and then verified against the point
    sets, rather than pairing vertices off in document order. Inkscape rewrites
    a polygon as a path starting at whichever vertex it likes, so the same shape
    comes back as the same ring rotated — comparing vertex n to vertex n is how
    an identical shape reads as no match at all.

    Independent x and y scales, and both signs tried, so a mirrored or squashed
    copy is recognised rather than silently rejected — the caller decides what
    to do about it.
    """
    # Compared as point sets below, never by raw length: how many times a ring
    # names a vertex is a property of who wrote it, not of the shape. The same
    # outline comes back from Inkscape naming its start once where the traced
    # asset names it twice, and a ring that revisits a corner names it as often
    # as it passes through.
    if len(target) < 2 or len(source) < 2:
        return None
    tx0, tx1, ty0, ty1 = bbox(target)
    sx0, sx1, sy0, sy1 = bbox(source)
    tw, th, sw, sh = tx1 - tx0, ty1 - ty0, sx1 - sx0, sy1 - sy0
    if sw < 1e-9 or sh < 1e-9 or tw < 1e-9 or th < 1e-9:
        return None
    slack = tol * max(tw, th, 1)
    # Deduplicated after rounding, never before: the same vertex written once in
    # integer art units and again in millimetres does not compare equal as a
    # float, so an exact-value set keeps both copies and the counts never line
    # up.
    want = sorted(set(map(rounded, target)))
    for signx in (1, -1):
        for signy in (1, -1):
            sx, sy = signx * tw / sw, signy * th / sh
            tx = tx0 - sx * (sx0 if signx > 0 else sx1)
            ty = ty0 - sy * (sy0 if signy > 0 else sy1)
            got = sorted({rounded((sx * x + tx, sy * y + ty)) for x, y in source})
            if len(got) != len(want):
                continue
            if all(abs(a - c) <= slack and abs(b - d) <= slack
                   for (a, b), (c, d) in zip(got, want)):
                return sx, sy, tx, ty
    return None


def is_identity(t, slack=0.05):
    """Whether a solved transform means 'already in the right place'.

    Compared with slack rather than for equality: the reference is written in
    millimetres to six figures, so a shape that is genuinely where the anchor
    predicts still lands a hundredth of a unit away.
    """
    return (
        t is not None
        and abs(t[0] - 1) < 1e-3
        and abs(t[1] - 1) < 1e-3
        and abs(t[2]) < slack
        and abs(t[3]) < slack
    )


def place(composite, source):
    """How `source`'s art sits in `composite`: (transform, paths matched).

    Anchored on the source's largest path -- a small rectangle matches any
    other rectangle of the same proportions, so starting from an ambiguous
    shape is how a hat ends up 'matching' the dog's ear.
    """
    order = sorted(range(len(source)), key=lambda i: -len(source[i][1]))
    for i in order:
        fill, pts = source[i]
        for cfill, cpts in composite:
            if cfill != fill:
                continue
            t = solve(cpts, pts)
            if not t:
                continue
            # Confirm the rest of the art is there under the same transform.
            sx, sy, tx, ty = t
            moved = [
                (f, [(sx * x + tx, sy * y + ty) for x, y in p]) for f, p in source
            ]
            hits = sum(
                any(cf == f and is_identity(solve(cp, p)) for cf, cp in composite)
                for f, p in moved
            )
            # All but one, so a piece the user tidied a stray shape out of still
            # reads -- but never fewer than the one shape a source may have.
            if hits >= max(1, len(source) - 1):
                return t, hits
    return None, 0


UNIT = 25.4 / 96  # Inkscape writes mm; the art is in px at 96dpi


def mirror_axis(path):
    """The x the renderer flips a mirrored layer about, in art units.

    `Transform.scale(scaleX: -1)` turns a layer about the middle of the layer,
    and an accessory layer is the whole canvas -- so the axis is the middle of
    that asset's viewBox, not of the art drawn inside it.
    """
    m = re.search(r'viewBox="([^"]*)"', path.read_text())
    if not m:
        raise SystemExit(f"{path.name}: no viewBox, so no mirror axis")
    x, _, w, _ = [float(n) for n in NUM.findall(m.group(1))][:4]
    return x + w / 2


def art_bbox(paths):
    """The box the art in `paths` occupies, or None if none of them exist."""
    pts = [p for f in paths if f.exists()
           for _, ring in shapes(f.read_text()) for p in ring]
    return bbox(pts) if pts else None


def canvas_shift(pet, drawn):
    """How far `drawn` has to move to sit where the renderer draws `pet`.

    A reference is made by dropping in whichever single file shows the whole
    pet, and that file is not always in the canvas frame. `dog.svg` happens to
    be; `cat.svg` is the same silhouette parked at (310, 155) in a viewBox of
    its own. Read without this, a placement measured against it comes back
    three hundred units off -- a plausible-looking pair of numbers that puts
    the accessory off the canvas entirely, which is worse than an error.

    The two are the same silhouette drawn differently (one path per colour
    after `deseam.py`, versus the traced original), so they cannot be matched
    path for path -- but they cover exactly the same box, which pins the shift.
    """
    layers = [SVGS / f"{pet}_{part}.svg"
              for part in ("base", "eyes", "mouth", "tail")]
    frame = art_bbox(layers)
    if frame is None or drawn is None:
        return 0.0, 0.0
    dw = (frame[1] - frame[0]) - (drawn[1] - drawn[0])
    dh = (frame[3] - frame[2]) - (drawn[3] - drawn[2])
    if abs(dw) > 0.5 or abs(dh) > 0.5:
        raise SystemExit(
            f"{pet}: the file the reference was drawn with covers a different "
            f"box from {pet}_base.svg and friends (off by {dw:+.1f}x{dh:+.1f})"
            " -- it is not the same art, so no shift can line them up")
    return frame[0] - drawn[0], frame[2] - drawn[2]


def report(path):
    path = Path(path)
    m = re.fullmatch(r"(.+?)_with_(.+)", path.stem)
    if not m:
        raise SystemExit(f"{path.name}: expected <pet>_with_<accessory>.svg")
    pet, acc = m.group(1), m.group(2)
    comp = shapes(path.read_text())

    found = {}
    for role, stem in (("pet", pet), ("accessory", acc)):
        for cand in assets_for(stem):
            t, hits = place(comp, shapes(cand.read_text()))
            if t:
                found[role] = (cand, t, hits)
                break
        else:
            print(f"{path.name}: no asset matched the {role} art ({stem})")
            return None

    (pf, (psx, psy, ptx, pty), phits) = found["pet"]
    (af, (asx, asy, atx, aty), ahits) = found["accessory"]
    art = shapes(af.read_text())
    shift = canvas_shift(pet, art_bbox([pf]))
    dx = (atx - ptx) / psx + shift[0]
    dy = (aty - pty) / psy + shift[1]
    scale = (asx / psx, asy / psy)
    # A mirrored piece is flipped before it is moved, so the move is measured
    # from where the flip left it, not from where the art is drawn.
    mirrored = scale[0] < 0
    if mirrored:
        dx -= 2 * mirror_axis(af)

    print(f"{path.name}")
    print(f"    {pf.name} x{phits} + {af.name} x{ahits}"
          f"{'' if phits + ahits == len(comp) else f'  ({len(comp) - phits - ahits} path(s) unaccounted for)'}")
    print(f"    Offset({dx:+.0f}, {dy:+.0f}){' mirrored' if mirrored else ''}"
          f"    raw ({dx:+.3f}, {dy:+.3f})")
    if abs(abs(scale[0]) - 1) > 0.005 or abs(scale[1] - 1) > 0.005:
        print(f"    !! accessory is scaled x{abs(scale[0]):.4f} y{scale[1]:.4f}"
              " -- translation alone cannot reproduce this")
        cx, cy = centred(art, (asx, asy, atx, aty), (psx, psy, ptx, pty), shift,
                         mirror_axis(af) if mirrored else None)
        print(f"    Offset({cx:+.0f}, {cy:+.0f}) puts the unresized piece where"
              f" the resized one sits    raw ({cx:+.3f}, {cy:+.3f})")
    return dx, dy, scale


def centred(art, placed, pet, shift, axis=None):
    """The move that lands unresized art where a resized reference put it.

    A reference where the accessory was also scaled is not a placement the
    renderer can follow -- it only translates. Rather than report nothing and
    leave the number to be guessed at, this centres the piece at its drawn
    size on the middle of the box the reference gave it, which is the closest
    a move alone gets. Where the piece needed resizing to fit, the fix is the
    art, not the offset.
    """
    asx, asy, atx, aty = placed
    psx, psy, ptx, pty = pet
    own = bbox([p for _, ring in art for p in ring])
    # The drawn box, brought back from the reference into canvas units.
    got = bbox([((asx * x + atx - ptx) / psx + shift[0],
                 (asy * y + aty - pty) / psy + shift[1])
                for _, ring in art for x, y in ring])
    dy = ((got[2] + got[3]) - (own[2] + own[3])) / 2
    if axis is None:
        return ((got[0] + got[1]) - (own[0] + own[1])) / 2, dy
    # Mirrored, so the piece to move is the flipped one, whose centre sits as
    # far the other side of the axis as the drawn art's centre sits this side.
    return ((got[0] + got[1]) + (own[0] + own[1])) / 2 - 2 * axis, dy


def assets_for(stem):
    """Asset files whose art might appear in the reference, by name."""
    flat = stem.replace("_", "")
    # `<name>_new.svg` is a border-less source the user has drawn but that has
    # not been through art_src/gen_acc.py yet — a reference made against one is
    # still a placement, so it is worth reading.
    named = [f"{stem}.svg", f"{flat}.svg", f"acc_{flat}.svg",
             f"{flat}_new.svg", f"{stem}_new.svg"]
    # Every candidate, not just the first that exists on disk: a reference may
    # have been drawn against either the shipped piece or its raw source.
    out = [SVGS / n for n in named if (SVGS / n).exists()]
    out += [p for p in sorted(SVGS.glob(f"*{flat}*.svg")) if p not in out]
    return out


if __name__ == "__main__":
    args = sys.argv[1:] or sorted(str(p) for p in ROOT.glob("art_src/*_with_*.svg"))
    for a in args:
        report(a)
