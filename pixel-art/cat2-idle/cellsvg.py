"""Reads the generated pet layer SVGs (assets/svgs/<pet>_*.svg) back onto their cell grid.

Every coordinate in those files sits on the 3-unit lattice gen_rework.py emits, so
sampling each cell at its centre recovers the art exactly: one pixel per cell.
Paths are painted in file order, later wins (deseam's back-to-front order).
"""
import os
import re
import sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
sys.path.insert(0, os.path.join(ROOT, "art_src"))
from lib_dog import to_points  # noqa: E402

SVGS = os.path.join(ROOT, "assets", "svgs")
CELL = 3
OX, OY = 2, 1          # the lattice offset: every x is 2 mod 3, every y 1 mod 3


def _spans(subs, sy):
    """x-intervals inside the (nonzero) shape along the horizontal line y = sy."""
    xs = []
    for pts in subs:
        for k in range(len(pts)):
            (x1, y1), (x2, y2) = pts[k], pts[(k + 1) % len(pts)]
            if y1 != y2 and ((y1 <= sy < y2) or (y2 <= sy < y1)):
                xs.append((x1 + (sy - y1) * (x2 - x1) / (y2 - y1), 1 if y2 > y1 else -1))
    xs.sort()
    out, wind, start = [], 0, None
    for x, d in xs:
        if wind == 0:
            start = x
        wind += d
        if wind == 0:
            out.append((start, x))
    return out


def load(name):
    """{(col, row): '#hex'} for assets/svgs/<name>.svg; col/row are lattice cells."""
    svg = open(os.path.join(SVGS, name + ".svg"), encoding="utf-8").read()
    cells = {}
    for m in re.finditer(r"<path\b(.*?)/>", svg, re.S):
        attrs = m.group(1)
        fill = re.search(r'fill="(#[0-9a-fA-F]{6})"', attrs).group(1).lower()
        subs = to_points(re.search(r'\sd="([^"]*)"', attrs, re.S).group(1))
        ys = [y for p in subs for _, y in p]
        xs_all = [x for p in subs for x, _ in p]
        r0, r1 = int((min(ys) - OY) // CELL), int((max(ys) - OY) // CELL)
        c0, c1 = int((min(xs_all) - OX) // CELL), int((max(xs_all) - OX) // CELL)
        for r in range(r0, r1 + 1):
            sy = OY + r * CELL + CELL / 2
            for a, b in _spans(subs, sy):
                for c in range(c0, c1 + 1):
                    if a <= OX + c * CELL + CELL / 2 < b:
                        cells[(c, r)] = fill
    return cells
