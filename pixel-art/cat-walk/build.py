"""The app's cat (assets/svgs/cat2_*.svg) walking right, 8-frame cycle.

Reused VERBATIM from the shipped art, one pixel per 3-unit art cell:
- the head (ears, eyes, whiskers, mouth), still facing the viewer
- the tail, in its shipped wag poses cat2_tail_l / cat2_tail / cat2_tail_r
New, in the art's own vocabulary (same coat, 3-cell square outline, rectangles only,
legs + paws after the original's front legs): the side-on body and four legs.
`staircases()` fails any run of small steps (a diagonal) in the frames.
Run: python build.py
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
os.chdir(HERE)
sys.path.insert(0, os.path.join(HERE, "..", "..", ".claude", "skills",
                                "pixel-art-studio-main", "scripts"))
sys.path.insert(0, os.path.join(HERE, "..", "cat2-idle"))
import cellsvg  # noqa: E402
from pixelstudio import Sprite  # noqa: E402

OUTLINE, COAT_FILE = "#1f2223", "#959379"
COAT = "#969680"                  # the cat's natural coat (constants/pets.dart)
FAR = "#6c6c5c"                   # far legs: coat darkened 0.72, the app's derived shade
OT = 3                            # the art's outline thickness, in cells

L = {n: cellsvg.load("cat2_" + n) for n in
     ("base", "eyes", "mouth", "tail", "tail_l", "tail_r")}

# ---- canvas, in art cells (the original's own coordinates, shifted) --------
C0, R0 = -46, 6                   # art col/row of canvas pixel (0,0)
W, H = 116, 84
GROUND = 83                       # lowest coat row of a planted paw (the original's feet: 83)


def X(c):
    return c - C0


def Y(r):
    return r - R0


# ---- the original's head: everything above the chin ------------------------
HEAD_ROWS = 51
HEAD = {}
for n in ("base", "eyes", "mouth"):
    for (c, r), v in L[n].items():
        if r <= HEAD_ROWS:
            HEAD[(c, r)] = v

# ---- the new body ------------------------------------------------------------
RUMP, CHEST = -16, 53             # body coat, left/right columns (chest outline meets the head's)
BACK, BELLY = 47, 69              # body coat, top/bottom rows
HIP_X = {"near_back": -12, "far_back": -4, "near_front": 36, "far_front": 26}
TAIL_SHIFT = (-25, -19)           # the tail rising off the rump, root tucked under it

N = 8
MS = 110
# foot (dx forward, lift) through one stride: 5 frames planted sliding back, 3 swinging
STRIDE = [(6, 0), (3, 0), (0, 0), (-3, 0), (-6, 0), (-3, 3), (2, 5), (5, 2)]
PHASE = {"near_back": 0, "near_front": 2, "far_back": 4, "far_front": 6}   # 4-beat walk
BOB = [0, 1, 1, 0, 0, 1, 1, 0]
HEAD_BOB = [BOB[(t - 1) % N] for t in range(N)]                            # a frame late
TAIL_POSE = ["tail", "tail_l", "tail_l", "tail", "tail", "tail_r", "tail_r", "tail"]

s = Sprite(W, H)


def thick_outline():
    for _ in range(OT):
        s.outline(OUTLINE, diagonals=True)     # square corners, no chamfer


def notch(x0, y0, size):
    s.rect(x0, y0, x0 + size - 1, y0 + size - 1, None)


def leg(c0, top, dx, lift, col):
    """The original's front leg, side on: 6-cell shin, paw stepping 3 cells forward."""
    x, foot = X(c0 + dx), Y(GROUND - lift)
    s.rect(x, Y(top), x + 5, foot, col)
    s.rect(x, foot - 3, x + 8, foot, col)


def foot(name, t):
    return STRIDE[(t + PHASE[name]) % N]


def paste(cells, dc=0, dr=0):
    for (c, r), v in cells.items():
        s.px(X(c + dc), Y(r + dr), COAT if v == COAT_FILE else v)


def draw(t):
    bob, hbob = BOB[t], HEAD_BOB[t]

    s.layer("far")
    for name in ("far_back", "far_front"):
        leg(HIP_X[name], BELLY - 4 + bob, *foot(name, t), FAR)
    thick_outline()

    s.layer("tail")                                       # shipped pose, as drawn
    paste(L[TAIL_POSE[t]], TAIL_SHIFT[0], TAIL_SHIFT[1] + bob)

    s.layer("body")                                       # body + near legs, one silhouette
    s.rect(X(RUMP), Y(BACK + bob), X(CHEST), Y(BELLY + bob), COAT)
    notch(X(RUMP), Y(BACK + bob), 4)                      # rounded rump, one square step
    for name in ("near_back", "near_front"):
        leg(HIP_X[name], BELLY - 4 + bob, *foot(name, t), COAT)
    thick_outline()

    s.layer("head")                                       # the original's head, untouched
    paste(HEAD, 0, hbob)


def staircases(sprite):
    """Runs of small steps (diagonal lines): three same-kind corners in a row, each
    (1,1), (2,1) or (1,2) from the last. A single jog or notch is allowed."""
    hits = []
    for f in range(1, sprite.n_frames + 1):
        im = sprite.composite(f).load()
        colours = {im[x, y][:3] for x in range(W) for y in range(H) if im[x, y][3]}
        masks = [lambda p: p[3] > 0] + [lambda p, c=c: p[3] > 0 and p[:3] == c for c in colours]
        for m in masks:
            on = [[m(im[x, y]) for x in range(W)] for y in range(H)]
            corner = {}
            for y in range(H - 1):
                for x in range(W - 1):
                    n = on[y][x] + on[y][x + 1] + on[y + 1][x] + on[y + 1][x + 1]
                    if n in (1, 3):
                        corner[(x, y)] = n
            for (x, y), n in corner.items():
                for dx, dy in ((1, 1), (-1, 1), (2, 1), (-2, 1), (1, 2), (-1, 2)):
                    if corner.get((x + dx, y + dy)) == n == corner.get((x + 2 * dx, y + 2 * dy)):
                        hits.append((f, x, y))
    return hits


for t in range(N):
    if t:
        s.add_frame(copy=False)
    draw(t)

s.set_duration(MS, "all")
s.tag("walk", 1, N)

s.preview("preview.png", scale=3, cols=4)
s.frame(1)
s.stats()
bad = staircases(s)
print("staircases:", len(bad), sorted(set(bad))[:12])

s.save_png("cat_walk@1x.png", frame=1)
s.save_gif("cat_walk.gif", scale=4, tag="walk", bg="#e8e4da")
s.save_gif("cat_walk_transparent.gif", scale=4, tag="walk")
s.save_spritesheet("cat_walk_sheet.png", layout="row")
