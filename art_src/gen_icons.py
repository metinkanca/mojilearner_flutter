# Draws the pixel-art icons the UI needs that are not food and not the coin --
# `assets/svgs/gift.svg` and `assets/svgs/flame.svg`.
#
# Both are built by `gen_food.build` on purpose: that function is where the art
# set actually lives. It dilates the shape by one cell and fills the ring with
# the pets' ink, traces each colour as a single path so flutter_svg has no
# internal edges to tear along, and crops the viewBox to the content.
# Reimplementing any of that here would produce icons that looked *nearly*
# like the rest of the set, which is worse than ones that looked nothing like
# it. So the sources below are the same ASCII form the food is authored in --
# one character per cell, '.' for empty, drawn border-less because the outline
# is added for you.
#
# Usage:  python art_src/gen_icons.py assets/svgs

import sys
from pathlib import Path

from gen_food import build

# The wrapped present: what a reward looks like when the catalogue has no
# picture of the thing itself.
#
# In the app's own retro palette rather than invented for this one file. The
# box is the Arne blue the sky already uses, its lid a cell lighter, and the
# ribbon the accent yellow every "this is yours now" surface is painted in.
#
# Blue is also the one hue no food in the set uses, which matters more than it
# sounds: this icon's whole job is to stand for a reward the catalogue has no
# art for, so it must not be mistaken for a specific item at 22pt.
GIFT_PALETTE = {
    'b': '#5b6ee1',  # box
    'l': '#639bff',  # lid, lit one step
    'r': '#fbf236',  # ribbon and bow
}

# Twelve cells square, which lands at 14x14 once the outline ring is added --
# the same footprint as the pizza slice, so the present does not tower over
# the food when the two sit in the same row of reward boxes.
#
# The bow is three rows and the box nine, because the bow is the entire reason
# this reads as a present rather than as a crate: at the size these are drawn
# the box is four flat bands and the bow is the only silhouette. The gap
# between the two loops is left empty rather than drawn, so the dilation fills
# it with ink and the loops separate for free -- the same trick that gives the
# apple its crease and the donut its hole.
#
# The lid runs the full width and the box is inset a cell either side, which
# is what makes the lid overhang read. Nothing is shaded: the food is flat,
# and a shaded present would be the smoothest object in the set.
GIFT = [
    '..rr....rr..',
    '.rrrr..rrrr.',
    '..rrrrrrrr..',
    'lllllrrlllll',
    'lllllrrlllll',
    'lllllrrlllll',
    '.bbbbrrbbbb.',
    '.bbbbrrbbbb.',
    '.bbbbrrbbbb.',
    '.bbbbrrbbbb.',
    '.bbbbrrbbbb.',
    '.bbbbrrbbbb.',
]

# The streak's flame, which stands on the daily dialog's accent-yellow pill.
#
# That background is the constraint the palette is chosen around: a fire drawn
# the obvious way runs yellow at its heart, and a yellow heart on `#fbf236`
# would read as a hole punched through the flame. So the ramp runs red at the
# edge, orange through the middle, and finishes at the coin's own highlight --
# a pale cream that reads as the hottest part precisely because it is *not*
# the yellow behind it.
FLAME_PALETTE = {
    'r': '#d33b28',  # the cooler outer edge
    'o': '#f2913a',  # the body of the fire
    'y': '#ffe9a8',  # the white-hot heart, borrowed from coin.svg
}

# Nine by twelve, so the flame stands taller than it is wide -- a fire that
# fits in a square reads as a leaf.
#
# Symmetrical, like the apple and the capsule. A leaning tip is the livelier
# drawing, but this is a static icon a few pixels across, and asymmetry at
# that size reads as a mistake rather than as motion.
#
# The three bands are nested rather than stacked: the pale heart sits low and
# small, the orange wraps it on every side, and the red is only ever the
# outermost cell. That ordering is what makes it a fire instead of a striped
# teardrop -- heat is hottest inside, and the eye knows it.
#
# The heart is a teardrop in its own right, one cell at the top over three
# below. Pinching its bottom row too made it a neat plus sign, which at 72px
# read as a medical cross; the small flame inside the big one does not.
FLAME = [
    '....r....',
    '...rrr...',
    '...rrr...',
    '..rrorr..',
    '..rooor..',
    '.rrooorr.',
    '.rooyoor.',
    'rroyyyorr',
    'rroyyyorr',
    'rroyyyorr',
    '.rrooorr.',
    '..rrrrr..',
]

ICONS = {
    'gift': (GIFT_PALETTE, GIFT),
    'flame': (FLAME_PALETTE, FLAME),
}


def main():
    out = Path(sys.argv[1] if len(sys.argv) > 1 else 'assets/svgs')
    for name, (palette, rows) in ICONS.items():
        # A ragged row would silently shift every cell after it, and these
        # shapes are only legible as a block of text, so check the block is a
        # block before trusting what it draws.
        width = len(rows[0])
        ragged = [i for i, row in enumerate(rows) if len(row) != width]
        if ragged:
            raise SystemExit(
                '%s rows %s are not %d cells wide' % (name, ragged, width))

        path = out / ('%s.svg' % name)
        path.write_text(build(rows, palette), encoding='utf-8')
        print('%s  %db' % (path, path.stat().st_size))


if __name__ == '__main__':
    main()
