# -*- coding: utf-8 -*-
"""Draws a trial arena's scenery the way the app does, straight to a PNG.

A `flutter test` round trip is minutes; this is a couple of seconds, which is
the difference between iterating on the art and guessing at it.

It reimplements two things and nothing else: `_Geo`, for the ledge and ground
lines the screen puts the art against, and `ArenaScenery`, for how the three
layers are laid on them -- a backdrop stretched between its two anchor rows,
and strips scaled by arena width. Every device below is drawn, because the
whole point of anchoring is that the art holds together at aspects the owner
did not draw it at.

    python art_src/preview_arena.py out_dir [boss ...]

Chrome is the rasteriser (see the pet render loop); it honours crispEdges and
flutter_svg does not, so edges here are harder than the app's.
"""

import os
import subprocess
import sys

import gen_arena

HERE = os.path.dirname(os.path.abspath(__file__))
SVGS = os.path.normpath(os.path.join(HERE, '..', 'assets', 'svgs'))
CHROME = os.environ.get(
    'CHROME', r'C:\Program Files\Google\Chrome\Application\chrome.exe')

SKY = '#1a1c2c'
GRASS = '#2e573f'

# name, arena width, arena height. The arena is the screen under the HUD, so
# these are real devices minus their safe areas and the 52pt bar.
DEVICES = [
    ('iphone15', 393, 707),     # what the art was drawn for
    ('iphonese', 375, 595),     # squattest phone
    ('pixel7', 412, 791),       # tallest phone
    ('ipad', 820, 1084),        # far outside the brief
]

# Mirrors TrialBosses: aspect, heightShare, flies.
BOSSES = {
    'mossback': (141 / 108, 0.20, False),
    'amethyst': (122 / 121, 0.22, False),
    'witch': (114 / 125, 0.27, True),
    'angler': (134 / 100, 0.22, True),
    'sphinx': (113 / 81, 0.18, False),
    'dragon': (148 / 115, 0.22, False),
}


def geo(w, h, bid):
    """`_Geo`'s ledge and ground lines, and the boss box on them."""
    aspect, share, flies = BOSSES[bid]
    boss_w = min(w * 0.5, h * share * aspect)
    boss_h = boss_w / aspect
    jump = round(boss_h * (0.12 if flies else 0.3))
    boss_top = round(8 + jump + 2) if flies else round(8 + 58 + jump + 2)
    ledge_top = round(boss_top + boss_h - 6)
    ground_top = round(h - min(max(h * 0.13, 44), 90))
    return ledge_top, ground_top, boss_top, boss_w, boss_h


def html(bid, w, h):
    layers, backdrop_w, ledge_line, ground_line = gen_arena.build(
        bid, gen_arena.ARENAS[bid])
    arena_w, arena_h = gen_arena.ARENAS[bid]['arena']
    ledge_top, ground_top, boss_top, boss_w, boss_h = geo(w, h, bid)
    cell = w / arena_w

    out = ['<html><body style="margin:0;background:%s">' % SKY,
           '<div style="position:relative;width:%dpx;height:%dpx;'
           'overflow:hidden;image-rendering:pixelated">' % (w, h)]

    def band(y0, y1, sy0, sy1):
        """Art rows [y0, y1) drawn into screen rows [sy0, sy1)."""
        pw = w * backdrop_w / arena_w
        ph = (sy1 - sy0) * arena_h / (y1 - y0)
        out.append(
            '<div style="position:absolute;left:0;top:%.2fpx;width:%dpx;'
            'height:%.2fpx;overflow:hidden">'
            '<img src="%s/arena_%s_backdrop.svg" style="position:absolute;'
            'left:%.2fpx;top:%.2fpx;width:%.2fpx;height:%.2fpx"></div>'
            % (sy0, w, sy1 - sy0, SVGS.replace('\\', '/'), bid,
               (w - pw) / 2, -y0 / arena_h * ph, pw, ph))

    if ledge_line is not None:
        band(0, ledge_line, 0, ledge_top)
        band(ledge_line, ground_line, ledge_top, ground_top)
    else:
        band(0, ground_line, 0, ground_top)

    out.append('<div style="position:absolute;left:0;top:%dpx;width:%dpx;'
               'height:%dpx;background:%s"></div>'
               % (ground_top, w, h - ground_top, GRASS))
    for name, top in (('ledge', ledge_top), ('ground', ground_top)):
        if name not in layers:
            continue
        units = layers[name][3]
        out.append(
            '<div style="position:absolute;left:0;top:%dpx;width:%dpx;'
            'height:%dpx;overflow:hidden">'
            '<img src="%s/arena_%s_%s.svg" style="width:%dpx;height:%.2fpx">'
            '</div>' % (top, w, h - top, SVGS.replace('\\', '/'), bid, name,
                        w, units * cell))

    # The boss box and the pet's feet, so a drift off the ledge is obvious.
    out.append('<div style="position:absolute;left:%.1fpx;top:%.1fpx;'
               'width:%.1fpx;height:%.1fpx;border:1px dashed #6dc2ca;'
               'box-sizing:border-box"></div>'
               % ((w - boss_w) / 2, boss_top, boss_w, boss_h))
    out.append('</div></body></html>')
    return ''.join(out)


def main():
    out_dir = sys.argv[1] if len(sys.argv) > 1 else HERE
    bosses = sys.argv[2:] or list(BOSSES)
    os.makedirs(out_dir, exist_ok=True)
    for bid in bosses:
        for name, w, h in DEVICES:
            page = os.path.join(out_dir, 'arena_%s_%s.html' % (bid, name))
            png = os.path.join(out_dir, 'arena_%s_%s.png' % (bid, name))
            open(page, 'w', encoding='utf-8').write(html(bid, w, h))
            subprocess.run([CHROME, '--headless', '--disable-gpu',
                            '--hide-scrollbars', '--screenshot=%s' % png,
                            '--window-size=%d,%d' % (w, h),
                            'file:///%s' % page.replace('\\', '/')],
                           check=True, capture_output=True)
            print('wrote %s' % png)


if __name__ == '__main__':
    main()
