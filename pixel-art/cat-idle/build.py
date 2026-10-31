"""Sitting cat, front view, 32x32 idle loop.

Breathing (body squash, head follows one frame late), tail sway, ear twitch, blink.
Run: python build.py  -> preview.png, cat_idle.gif, cat_idle@1x.png, sheet
"""
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", ".claude", "skills",
                                "pixel-art-studio-main", "scripts"))
from pixelstudio import Sprite, ramp  # noqa: E402

os.chdir(HERE)

# ---- palette -------------------------------------------------------------
COAT = ramp("#e8913a", 5, hue_shift=16)[:3] + ["#f7b566"]  # stripe, shadow, base, warm highlight
CREAM = ["#e9c9a0", "#fbeedb"]                # shade, light
INK = "#3b2330"                               # outline / eyes / stripes
PINK = "#e8798f"
WHITE = "#fffaf0"
SHADOW = (59, 35, 48, 72)                     # deliberate soft floor shadow

N = 12
MS = 150
# body squash: breathe in (0) / out (1)
BREATH = [0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0]
# head follows the body one frame late
HEAD = [BREATH[(i - 1) % N] for i in range(N)]
# tail tip sways sideways
TAIL = [round(2 * math.sin(2 * math.pi * i / N)) for i in range(N)]
BLINK = {9}
EAR_TWITCH = {5}

s = Sprite(32, 32)


def draw_shadow():
    s.layer("shadow")
    s.ellipse(8, 27, 23, 30, SHADOW)


def draw_tail(sway):
    s.layer("tail")
    # quadratic bezier from the hip, round the right side, up to the tip
    p0, p1, p2 = (19, 26), (26, 28), (24 + sway, 15)
    for k in range(25):
        t = k / 24
        x = (1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * p1[0] + t * t * p2[0]
        y = (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * p1[1] + t * t * p2[1]
        s.circle(round(x), round(y), 1, COAT[1], fill=True)
    # lit ridge on the upper-left of the curl
    for k in range(10, 25):
        t = k / 24
        x = (1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * p1[0] + t * t * p2[0]
        y = (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * p1[1] + t * t * p2[1]
        s.px(round(x) - 1, round(y), COAT[2], only="opaque")
    s.outline(INK)


def draw_body(sq):
    s.layer("body")
    s.ellipse(10 - sq, 16 + sq, 21 + sq, 28, COAT[1])
    s.ellipse(9 - sq, 15 + sq, 19 + sq, 26, COAT[2], only="opaque")
    # cream chest
    s.ellipse(13, 19 + sq, 18, 27, CREAM[0], only="opaque")
    s.ellipse(13, 19 + sq, 17, 25, CREAM[1], only="opaque")
    # front paws
    for x0 in (11, 17):
        s.ellipse(x0, 25, x0 + 3, 28, CREAM[1])
        s.px(x0 + 2, 28, CREAM[0])
        s.px(x0 + 3, 27, CREAM[0])
    s.line(15, 26, 15, 28, INK)          # gap between paws
    s.line(16, 26, 16, 28, INK)
    s.outline(INK)


def draw_head(dy, blink, twitch):
    s.layer("head")
    # ears (drawn first so the head overlaps their base)
    lt = (6, 2) if twitch else (8, 1)
    s.polygon([(7, 10 + dy), (lt[0], lt[1] + dy), (14, 5 + dy)], COAT[1])
    s.polygon([(24, 10 + dy), (23, 1 + dy), (17, 5 + dy)], COAT[1])
    lti = (8, 5) if twitch else (9, 4)
    s.polygon([(9, 8 + dy), (lti[0], lti[1] + dy), (12, 6 + dy)], PINK)
    s.polygon([(22, 8 + dy), (22, 4 + dy), (19, 6 + dy)], PINK)
    # skull: shifted-shape cel shading, light from top-left
    s.ellipse(5, 4 + dy, 26, 20 + dy, COAT[1])
    s.ellipse(5, 4 + dy, 24, 18 + dy, COAT[2], only=COAT[1])
    s.ellipse(8, 5 + dy, 13, 8 + dy, COAT[3], only=COAT[2])
    # forehead stripes
    for x, top, bot in ((13, 5, 7), (15, 4, 8), (16, 4, 8), (18, 5, 7)):
        s.line(x, top + dy, x, bot + dy, COAT[0])
    # cheek stripes
    s.line(6, 13 + dy, 7, 13 + dy, COAT[0])
    s.line(24, 13 + dy, 25, 13 + dy, COAT[0])
    # muzzle
    s.ellipse(11, 13 + dy, 20, 19 + dy, CREAM[1])
    s.line(12, 19 + dy, 19, 19 + dy, CREAM[0], only=CREAM[1])
    # eyes
    for ex in (9, 19):
        if blink:
            s.line(ex, 12 + dy, ex + 2, 12 + dy, INK)
            s.px(ex, 11 + dy, INK) if ex == 9 else s.px(ex + 2, 11 + dy, INK)
        else:
            s.rect(ex, 10 + dy, ex + 2, 13 + dy, INK)
            s.px(ex, 10 + dy, WHITE)
    # blush
    s.px(8, 15 + dy, PINK)
    s.px(23, 15 + dy, PINK)
    # nose + mouth
    s.line(15, 14 + dy, 16, 14 + dy, PINK)
    s.px(13, 15 + dy, INK)
    s.px(14, 16 + dy, INK)
    s.px(18, 15 + dy, INK)
    s.px(17, 16 + dy, INK)
    s.line(15, 15 + dy, 16, 15 + dy, INK)
    s.outline(INK)


for f in range(N):
    if f > 0:
        s.add_frame(copy=False)
    draw_shadow()
    draw_tail(TAIL[f])
    draw_body(BREATH[f])
    draw_head(HEAD[f], f in BLINK, f in EAR_TWITCH)

s.set_duration(MS, "all")
s.set_duration(90, [10])          # blink is quick
s.tag("idle", 1, N)

s.preview("preview.png", scale=8)
s.frame(1)
s.save_silhouette("silhouette.png")
s.stats()

s.save_png("cat_idle@1x.png", frame=1)
s.save_png("cat_idle@8x.png", frame=1, scale=8)
s.save_gif("cat_idle.gif", scale=8, tag="idle")
s.save_spritesheet("cat_idle_sheet.png", layout="row")

s.zoom("zoom_face.png", 4, 0, 28, 31, frame=1, scale=16)
