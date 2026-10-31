"""Idle loop for the app's ACTUAL cat (assets/svgs/cat2_*.svg), one pixel per art cell.

Nothing is redrawn: every frame is the shipped layers, moved with pixel-safe ops only.
- breathing: delete / duplicate whole rows where the art repeats (a 1px squash with
  the feet planted); the head follows the torso one frame late
- blink: the eye closes top-down (the app's downward blink)
- ear flick: the left ear dips by dropping rows it repeats (the SVG rig can't do this)
- tail: the shipped wag poses cat2_tail_l / cat2_tail / cat2_tail_r
Run: python build.py
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
os.chdir(HERE)
sys.path.insert(0, os.path.join(HERE, "..", "..", ".claude", "skills",
                                "pixel-art-studio-main", "scripts"))
import cellsvg  # noqa: E402
from pixelstudio import Sprite  # noqa: E402

OUTLINE, COAT_FILE = "#1f2223", "#959379"
COAT = "#969680"                 # the cat's natural coat (constants/pets.dart)
EYE = OUTLINE                    # eyes as drawn; the app paints them the player's eye colour

L = {n: cellsvg.load("cat2_" + n) for n in
     ("base", "eyes", "mouth", "tail", "tail_l", "tail_r")}

# ---- canvas: bbox of every layer + margin, feet on the bottom row ----------
every = set().union(*(set(v) for v in L.values()))
C0 = min(c for c, _ in every) - 2
R0 = min(r for _, r in every) - 3          # headroom for the ear flick / row inserts
W = max(c for c, _ in every) + 3 - C0
H = max(r for _, r in every) + 1 - R0

# ---- landmarks, in lattice rows/cols (read off the ASCII map) --------------
TORSO_ROW = 73       # identical to row 72: deleting it squashes the body 1px
NECK_ROW = 62        # identical to row 61: dup/delete here moves everything above it
EAR_ROWS = range(9, 19)                    # tip .. just above where it meets the skull
EAR_REPEATS = [16, 13]                     # ear rows identical to the row above: safe to drop
EAR_COLS = range(10, 31)                   # left ear only (cols 13..31)
eye_rows = sorted({r for _, r in L["eyes"]})

N = 16
MS = 125
# R rest | A torso down, head lagging | D all down | U torso back up, head lagging
BREATH = "RRRRADDDDDURRRRR"
TAIL = ["tail", "tail", "tail_l", "tail_l", "tail", "tail", "tail_r", "tail_r"] * 2
BLINK = {12: 0.5, 13: 1.0, 14: 0.5}       # frame -> how far the lid is down
EAR_FLICK = {5: 2, 6: 1}                   # frame -> cells the ear dips (snap down, ease back)


def compose(f):
    """The frame as {(col,row): colour} before the breathing row ops."""
    img = {}
    for layer in ("base", TAIL[f], "mouth"):
        img.update(L[layer])
    lid = BLINK.get(f, 0.0)
    top, bot = eye_rows[0], eye_rows[-1]
    shut_to = top + round(lid * (bot - top))  # rows above this are covered by lid
    for (c, r), _ in L["eyes"].items():
        if lid and r < shut_to:
            img[(c, r)] = COAT_FILE           # eyelid = coat
        elif lid == 1.0 and r == bot:
            img[(c, r)] = OUTLINE             # closed: just the lash line
        else:
            img[(c, r)] = EYE
    if f in EAR_FLICK:
        # drop rows the ear repeats and let the tip fall into the gap: the ear
        # shortens without a single pixel of it being redrawn
        drop = EAR_REPEATS[:EAR_FLICK[f]]
        ear = {(c, r): v for (c, r), v in img.items() if r in EAR_ROWS and c in EAR_COLS}
        for k in ear:
            del img[k]
        for (c, r), v in ear.items():
            if r not in drop:
                img[(c, r + sum(1 for d in drop if d > r))] = v
    return img


def to_rows(img):
    return [[img.get((C0 + x, R0 + y)) for x in range(W)] for y in range(H)]


def delete_row(rows, r):
    """Drop art row r; everything above slides down 1 (feet stay put)."""
    i = r - R0
    return [[None] * W] + rows[:i] + rows[i + 1:]


def dup_row(rows, r):
    """Repeat art row r; everything above slides up 1."""
    i = r - R0
    return rows[1:i + 1] + [list(rows[i])] + rows[i + 1:]


def breathe(rows, state):
    if state == "A":        # torso squashed, head not yet: squash low, stretch the neck
        return dup_row(delete_row(rows, TORSO_ROW), NECK_ROW)  # orig row 61, now at 62
    if state == "D":        # head has caught up
        return delete_row(rows, TORSO_ROW)
    if state == "U":        # torso back up, head still down
        return delete_row(rows, NECK_ROW)
    return rows


s = Sprite(W, H)
for f in range(N):
    if f:
        s.add_frame(copy=False)
    rows = breathe(to_rows(compose(f)), BREATH[f])
    assert all(v is None for v in rows[0]), "art pushed off the top edge"
    for y, row in enumerate(rows):
        for x, v in enumerate(row):
            if v:
                s.px(x, y, COAT if v == COAT_FILE else v)

s.set_duration(MS, "all")
s.set_duration(70, [13, 14, 15])            # blink is quick
s.tag("idle", 1, N)

s.preview("preview.png", scale=3, cols=8)
s.frame(1)
s.stats()
s.save_png("cat2_idle@1x.png", frame=1)
s.save_gif("cat2_idle.gif", scale=4, tag="idle")
s.save_gif("cat2_idle_on_bg.gif", scale=4, tag="idle", bg="#e8e4da")
s.save_spritesheet("cat2_idle_sheet.png", layout="grid")
