"""Draws PLACEHOLDER arena art for Sableth and Pyrewing, until the owner's.

    python gen_placeholder_arenas.py   # writes sableth-/pyrewing-placeholder-*.svg

Every boss must stand in arena art (test/unit/boss_arena_art_test.dart), so
this draws the three source pieces the briefs ask for -- a backdrop the
arena's height and a third wider, a seamless 100-wide ledge strip and a
seamless 100-wide ground strip -- in the shape Amethyst's came in, and
gen_arena.py cuts them like any other. When the owner's art lands, point
gen_arena.py's entries at it and delete this script and its outputs.

Both bosses stand on a ledge and are drawn at Amethyst's cell size, so both
arenas are Amethyst's canvas: 306 x 550, the backdrop 408 wide, the ledge's
top edge on row 206, the ground from row 478. The brief's rules, so the real
art can follow them too:

  * the play field between the ledge and the ground is where every round's
    pieces go, so it is calm, and its props keep to the bleed at the sides;
  * cyan, red and yellow are the UI's: the desert is a dusk of indigo and
    mauve, not sunset orange; the volcano's lava stays small and far off,
    because the dragon itself is orange;
  * Pyrewing's Gaze orders "touch the rock I sit on" and "touch the ground",
    so its ledge and its ground must read as a rock and as ground.

Deterministic: fixed seeds, so a re-run writes the same files.
"""
import math
import random

import lib_boss

W, H = 408, 550
ARENA_W = 306
LEDGE_LINE, GROUND_LINE = 206, 478
STRIP_W, LEDGE_H, GROUND_H = 100, 17, 72
OUTLINE = '#14120e'


def bands(g, colours, top, bottom):
    """Horizontal bands from [top] to [bottom], a dithered row where each
    changes."""
    band_h = (bottom - top) / len(colours)
    for y in range(top, bottom):
        i = min(len(colours) - 1, int((y - top) / band_h))
        into = (y - top) - i * band_h
        for x in range(W):
            c = colours[i]
            if i > 0 and into < 2 and (x + y) % 2 == 0:
                c = colours[i - 1]
            g[(x, y)] = c


def write_source(name, g, order, w, h):
    svg = lib_boss.emit(g, order, 0, 0, w, h)
    path = lib_boss.os.path.join(lib_boss.HERE, name)
    open(path, 'w', encoding='utf-8').write(svg)
    assert lib_boss.grid(name, 1) == g, name
    print('wrote %s' % path)


# ---- Sableth: a desert at dusk ------------------------------------------------

SKY = ['#1f1d3a', '#29264a', '#35305a', '#443a66', '#56466f', '#6a5577']
STAR = '#b9b3d6'
MOON = '#e8e0d0'
DUNE_FAR = '#3b3552'
DUNE = '#4e4460'
PYRAMID = '#2e2944'
PYRAMID_LIT = '#3d3656'
SAND = '#a88a5c'
SAND_DARK = '#8c7148'
STONE = '#c2a574'
STONE_DARK = '#9c8057'
SEAM = '#6e5638'


def sableth_backdrop():
    rng = random.Random(25)
    g = {}
    bands(g, SKY, 0, H)
    for _ in range(70):
        x, y = rng.randrange(W), rng.randrange(0, 200)
        g[(x, y)] = STAR
    # A moon high on the left, clear of where the boss stands.
    for y in range(22, 46):
        for x in range(40, 64):
            if (x - 51.5) ** 2 + (y - 33.5) ** 2 <= 12 ** 2:
                g[(x, y)] = MOON
    # Distant pyramids behind the ledge, in the bleed and the outer edges.
    edge = (W - ARENA_W) // 2
    for cx, half, base in ((edge - 10, 44, 420), (W - edge + 16, 52, 430),
                           (edge + 26, 24, 430), (W - edge - 30, 28, 430)):
        # A triangle standing on the dunes: a cell wider every row down.
        for y in range(base - half, base):
            span = y - (base - half)
            for x in range(cx - span, cx + span):
                if 0 <= x < W:
                    g[(x, y)] = PYRAMID_LIT if x < cx else PYRAMID
    # Dunes rolling across the bottom of the play field.
    for y in range(360, H):
        for x in range(W):
            far = 390 + 10 * math.sin(x / 37) + 6 * math.sin(x / 13)
            near = 430 + 12 * math.sin(x / 51 + 1) + 5 * math.sin(x / 17)
            if y >= near:
                g[(x, y)] = DUNE
            elif y >= far:
                g[(x, y)] = DUNE_FAR
    order = SKY + [STAR, MOON, PYRAMID, PYRAMID_LIT, DUNE_FAR, DUNE]
    return g, order


def sableth_ledge():
    """The sphinx's plinth: dressed sandstone blocks, a dark top edge."""
    g = {}
    for y in range(LEDGE_H):
        for x in range(STRIP_W):
            g[(x, y)] = STONE
    for x in range(STRIP_W):
        for y in (0, 1):
            g[(x, y)] = OUTLINE
        g[(x, LEDGE_H - 1)] = OUTLINE
        g[(x, 2)] = STONE_DARK
    # Two courses of blocks, their joins staggered.
    for x in range(STRIP_W):
        g[(x, 9)] = SEAM
    for x in range(0, STRIP_W, 25):
        for y in range(3, 9):
            g[(x, y)] = SEAM
        for y in range(10, LEDGE_H - 1):
            g[((x + 12) % STRIP_W, y)] = SEAM
    return g, [STONE, OUTLINE, STONE_DARK, SEAM]


def sableth_ground():
    rng = random.Random(5)
    g = {}
    for y in range(GROUND_H):
        for x in range(STRIP_W):
            g[(x, y)] = SAND
    for x in range(STRIP_W):
        for y in range(3):
            g[(x, y)] = OUTLINE
        for y in range(3, 5 + (x // 7) % 2):
            g[(x, y)] = SAND_DARK
    for row, y in enumerate(range(14, GROUND_H - 2, 10)):
        for x in range((row * 11) % 24, STRIP_W, 24):
            for dx in range(7):
                g[((x + dx) % STRIP_W, y)] = SAND_DARK
    for _ in range(7):
        x, y = rng.randrange(STRIP_W), rng.randrange(10, GROUND_H - 4)
        for dx in range(3):
            for dy in range(2):
                g[((x + dx) % STRIP_W, y + dy)] = STONE_DARK
    return g, [SAND, OUTLINE, SAND_DARK, STONE_DARK]


# ---- Pyrewing: a volcanic peak at night ---------------------------------------

ASH_SKY = ['#1a1418', '#221a1f', '#2b2027', '#35262e', '#3f2c34', '#4a3239']
EMBER = '#8a5a4a'
PEAK = '#241b20'
PEAK_LIT = '#2f2329'
LAVA = '#b8562f'
LAVA_GLOW = '#6e3a30'
SMOKE = '#3a3035'
BASALT = '#3b3538'
BASALT_LIGHT = '#524a4c'
CRACK = '#9a4a2c'
ASH = '#4a4244'
ASH_DARK = '#3a3335'


def pyrewing_backdrop():
    rng = random.Random(30)
    g = {}
    bands(g, ASH_SKY, 0, H)
    # Embers drifting up, sparse.
    for _ in range(60):
        x, y = rng.randrange(W), rng.randrange(0, 420)
        g[(x, y)] = EMBER
    # Two far volcanoes in the bleed, lava trickling from their tops.
    edge = (W - ARENA_W) // 2
    for cx, top, half in ((edge - 16, 330, 70), (W - edge + 14, 350, 64)):
        for y in range(top, H):
            span = int((y - top) * 0.55) + 6
            for x in range(cx - span, cx + span):
                if 0 <= x < W:
                    g[(x, y)] = PEAK_LIT if x < cx - 4 else PEAK
        for y in range(top, top + 40):
            x = cx + round(3 * math.sin(y / 5))
            for dx in range(2):
                if 0 <= x + dx < W:
                    g[(x + dx, y)] = LAVA if y < top + 20 else LAVA_GLOW
        # Smoke off the crater.
        for y in range(top - 60, top):
            wide = (top - y) // 6 + 3
            x0 = cx + (top - y) // 4
            for x in range(x0 - wide, x0 + wide):
                if 0 <= x < W and (x + y) % 3:
                    g[(x, y)] = SMOKE
    order = ASH_SKY + [EMBER, SMOKE, PEAK, PEAK_LIT, LAVA_GLOW, LAVA]
    return g, order


def pyrewing_ledge():
    """The dragon's perch: a slab of basalt with lava in its cracks."""
    g = {}
    for y in range(LEDGE_H):
        for x in range(STRIP_W):
            g[(x, y)] = BASALT
    for x in range(STRIP_W):
        for y in (0, 1):
            g[(x, y)] = OUTLINE
        g[(x, LEDGE_H - 1)] = OUTLINE
        if (x // 5) % 3 == 0:
            g[(x, 2)] = BASALT_LIGHT
    for x0 in (8, 41, 73):
        for i in range(10):
            g[((x0 + i // 2) % STRIP_W, 4 + i)] = CRACK
    return g, [BASALT, OUTLINE, BASALT_LIGHT, CRACK]


def pyrewing_ground():
    rng = random.Random(3)
    g = {}
    for y in range(GROUND_H):
        for x in range(STRIP_W):
            g[(x, y)] = ASH
    for x in range(STRIP_W):
        for y in range(3):
            g[(x, y)] = OUTLINE
        for y in range(3, 5 + (x // 9) % 2):
            g[(x, y)] = ASH_DARK
    for _ in range(12):
        x, y = rng.randrange(STRIP_W), rng.randrange(9, GROUND_H - 4)
        for dx in range(4):
            for dy in range(2):
                g[((x + dx) % STRIP_W, y + dy)] = BASALT_LIGHT
    for _ in range(4):
        x, y = rng.randrange(STRIP_W), rng.randrange(12, GROUND_H - 4)
        for i in range(5):
            g[((x + i) % STRIP_W, y + i // 2)] = CRACK
    return g, [ASH, OUTLINE, ASH_DARK, BASALT_LIGHT, CRACK]


if __name__ == '__main__':
    for prefix, parts in (
        ('sableth', (sableth_backdrop, sableth_ledge, sableth_ground)),
        ('pyrewing', (pyrewing_backdrop, pyrewing_ledge, pyrewing_ground)),
    ):
        backdrop, ledge, ground = parts
        g, order = backdrop()
        write_source('%s-placeholder-backdrop.svg' % prefix, g, order, W, H)
        g, order = ledge()
        write_source('%s-placeholder-ledge.svg' % prefix, g, order,
                     STRIP_W, LEDGE_H)
        g, order = ground()
        write_source('%s-placeholder-ground.svg' % prefix, g, order,
                     STRIP_W, GROUND_H)
