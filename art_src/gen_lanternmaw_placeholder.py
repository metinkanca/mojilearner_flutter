"""Draws PLACEHOLDER arena art for Lanternmaw, until the owner's arrives.

    python gen_lanternmaw_placeholder.py   # writes lanternmaw-placeholder-*.svg

Lanternmaw fights in the deep sea, and every boss must stand in arena art
(test/unit/boss_arena_art_test.dart), so this draws the two source pieces the
owner's briefs ask for, in the same shape Hoothex's came in -- a backdrop the
arena's height and a third wider, and a seamless 100-wide ground strip -- and
gen_arena.py cuts them like any other. When the owner's art lands, point
gen_arena.py's 'angler' entry at it and delete this script and its outputs.

The brief it follows, so the real art can too:

  * the canvas is the arena in Lanternmaw's own cells: 268 x 482, the
    backdrop 356 wide, the seabed from row 421;
  * it swims, so no ledge; it sways across the top third, and its fish and
    bubbles fill everything between it and the seabed -- so the middle is
    open water, calm and dark enough for the fish to read on, and the props
    (rock stacks, kelp) keep to the bleed at the sides;
  * cyan, red and yellow are the UI's, so the water is navy and indigo, not
    blue-green, and nothing in it glows but the boss's own lantern.

Deterministic: a fixed seed, so a re-run writes the same files.
"""
import math
import random

import lib_boss

W, H = 356, 482           # the backdrop
ARENA_W = 268
STRIP_W, STRIP_H = 100, 61

# The water, top to bottom, and what floats in it.
WATER = ['#22385a', '#1d3151', '#192b48', '#15243f', '#111e36', '#0e192f']
SHAFT = '#263f63'
SNOW = '#3a5577'
ROCK = '#0b1324'
ROCK_EDGE = '#172642'
KELP = '#1d3b36'
KELP_LIGHT = '#2b5046'

# The seabed.
OUTLINE = '#14120e'
SAND = '#6a604c'
SAND_DARK = '#574f3d'
PEBBLE = '#8a8068'
SHELL = '#c4b594'


def backdrop():
    rng = random.Random(20)
    g = {}
    band_h = H / len(WATER)
    for y in range(H):
        # Bands with a dithered row at each change, so the water darkens in
        # steps rather than stripes.
        i = min(len(WATER) - 1, int(y / band_h))
        into = y - i * band_h
        for x in range(W):
            colour = WATER[i]
            if i > 0 and into < 2 and (x + y) % 2 == 0:
                colour = WATER[i - 1]
            g[(x, y)] = colour

    # Light from the surface: a few wide shafts leaning right, fading out
    # before the middle of the arena.
    for x0, width, reach in ((60, 16, 170), (132, 10, 120), (196, 20, 190),
                             (282, 12, 140)):
        for y in range(0, reach):
            # Narrowing a cell every so often, to a point where it ends.
            left = width * (1 - y / reach)
            x = x0 + y // 3 + (width - round(left)) // 2
            for dx in range(round(left)):
                if 0 <= x + dx < W:
                    g[(x + dx, y)] = SHAFT

    # Rock stacks rising from the seabed, only in the bleed and the outer
    # edge of the arena, their tops stepped.
    edge = (W - ARENA_W) // 2
    for x0, x1, top in ((0, edge + 22, 250), (W - edge - 26, W, 280),
                        (edge + 6, edge + 40, 350), (W - edge - 44, W - edge - 8, 330)):
        for x in range(x0, x1):
            wobble = int(6 * abs(((x - x0) / max(1, x1 - x0)) - 0.5) * 4)
            t = top + wobble + (x * 7 % 5)
            for y in range(t, H):
                g[(x, y)] = ROCK
            g[(x, t)] = ROCK_EDGE

    # Kelp: tall stepped stalks in the bleed, swaying a cell at a time.
    for x0, top in ((edge - 30, 150), (edge - 12, 210), (W - edge + 10, 170),
                    (W - edge + 26, 230), (edge + 12, 300), (W - edge - 18, 290)):
        for y in range(top, H):
            x = x0 + round(2 * math.sin(y / 9))
            for dx in range(3):
                if 0 <= x + dx < W:
                    g[(x + dx, y)] = KELP_LIGHT if dx == 1 else KELP
            if y % 14 == 0:
                for dx in range(3, 7):
                    if 0 <= x + dx < W:
                        g[(x + dx, y)] = KELP

    # Marine snow, sparse and small.
    for _ in range(90):
        x, y = rng.randrange(W), rng.randrange(8, 400)
        if g[(x, y)] in WATER or g[(x, y)] == SHAFT:
            g[(x, y)] = SNOW
    order = WATER + [SHAFT, SNOW, ROCK_EDGE, ROCK, KELP, KELP_LIGHT]
    return g, order


def ground():
    """The seabed, seamless at 100 wide: a dark top edge like every other
    arena's grass, sand below with ripples, pebbles and the odd shell."""
    rng = random.Random(7)
    g = {}
    for y in range(STRIP_H):
        for x in range(STRIP_W):
            g[(x, y)] = SAND
    for x in range(STRIP_W):
        for y in range(3):
            g[(x, y)] = OUTLINE
    # A lip of darker sand under the edge, stepped.
    for x in range(STRIP_W):
        for y in range(3, 5 + (x // 6) % 2):
            g[(x, y)] = SAND_DARK
    # Ripples: short dark dashes in staggered rows.
    for row, y in enumerate(range(12, STRIP_H - 2, 8)):
        for x in range((row * 9) % 20, STRIP_W, 20):
            for dx in range(6):
                g[((x + dx) % STRIP_W, y)] = SAND_DARK
    # Pebbles and shells, wrapping round the seam.
    for _ in range(9):
        x, y = rng.randrange(STRIP_W), rng.randrange(8, STRIP_H - 4)
        for dx in range(3):
            for dy in range(2):
                g[((x + dx) % STRIP_W, y + dy)] = PEBBLE
    for _ in range(3):
        x, y = rng.randrange(STRIP_W), rng.randrange(10, STRIP_H - 6)
        for dx, dy in ((1, 0), (0, 1), (1, 1), (2, 1), (1, 2)):
            g[((x + dx) % STRIP_W, y + dy)] = SHELL
    order = [SAND, OUTLINE, SAND_DARK, PEBBLE, SHELL]
    return g, order


def write_source(name, g, order, w, h):
    svg = lib_boss.emit(g, order, 0, 0, w, h)
    path = lib_boss.os.path.join(lib_boss.HERE, name)
    open(path, 'w', encoding='utf-8').write(svg)
    # gen_arena.py reads it back through lib_boss.grid: make sure it does.
    assert lib_boss.grid(name, 1) == g, name
    print('wrote %s' % path)


if __name__ == '__main__':
    g, order = backdrop()
    write_source('lanternmaw-placeholder-backdrop.svg', g, order, W, H)
    g, order = ground()
    write_source('lanternmaw-placeholder-ground.svg', g, order, STRIP_W, STRIP_H)
